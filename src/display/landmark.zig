const std = @import("std");
const mediapipe = @cImport({
    @cInclude("mediapipe.h");
});
const cv = @import("zigcv");

const resource_dir = "/opt/homebrew/opt/libmediapipe/lib/data";

const Self = @This();
const InitConfig = struct {
    id: u8 = 0,
};

webcam: cv.VideoCapture,
frame: cv.Mat,
instance: *mediapipe.mp_instance,
pose_landmarks_poller: *mediapipe.mp_poller,
face_landmarks_poller: *mediapipe.mp_poller,

pub fn init(config: InitConfig) !Self {
    var webcam = try cv.VideoCapture.init();
    try webcam.openDevice(config.id);

    mediapipe.mp_set_resource_dir(resource_dir);
    const builder = mediapipe.mp_create_instance_builder(resource_dir ++ "/mediapipe/modules/holistic_landmark/holistic_landmark_gpu.binarypb", "image");
    mediapipe.mp_add_side_packet(builder, "num_poses", mediapipe.mp_create_packet_int(1));
    mediapipe.mp_add_side_packet(builder, "model_complexity", mediapipe.mp_create_packet_int(2));
    mediapipe.mp_add_side_packet(builder, "refine_face_landmarks", mediapipe.mp_create_packet_bool(true));
    mediapipe.mp_add_side_packet(builder, "use_prev_landmarks", mediapipe.mp_create_packet_bool(true));

    const instance = mediapipe.mp_create_instance(builder);
    checkNull(instance);

    const pose_landmarks_poller = mediapipe.mp_create_poller(instance, "pose_landmarks");
    checkNull(pose_landmarks_poller);

    const face_landmarks_poller = mediapipe.mp_create_poller(instance, "face_landmarks");

    checkNull(face_landmarks_poller);
    checkBool(mediapipe.mp_start(instance));

    return Self{
        .webcam = webcam,
        .instance = instance.?,
        .pose_landmarks_poller = pose_landmarks_poller.?,
        .face_landmarks_poller = face_landmarks_poller.?,
        .frame = try cv.Mat.init(),
    };
}

pub fn deinit(self: *Self) void {
    mediapipe.mp_destroy_poller(self.pose_landmarks_poller);
    mediapipe.mp_destroy_poller(self.face_landmarks_poller);
    _ = mediapipe.mp_destroy_instance(self.instance);
    self.frame.deinit();
    self.webcam.deinit();
}

pub const Result = struct {
    head_x: f32 = 0,
    head_y: f32 = 0,
    head_z: f32 = 0,
    body_pos_x: f32 = 0,
    body_pos_y: f32 = 0,
    body_rot_x: f32 = 0,
    body_rot_z: f32 = 0,
};

pub fn poll(self: *Self) !Result {
    var frame = self.frame;
    var result = Result{};

    self.webcam.read(&frame) catch {
        std.debug.print("capture failed", .{});
        std.posix.exit(1);
    };

    if (frame.isEmpty())
        return error.EmptyFrame;

    cv.cvtColor(frame, &frame, .bgr_to_bgra);

    const image = mediapipe.mp_image{
        .data = @ptrCast(frame.toBytes()),
        .width = frame.cols(),
        .height = frame.rows(),
        .format = mediapipe.mp_image_format_srgba,
    };

    const image_packet = mediapipe.mp_create_packet_image(image);
    checkBool(mediapipe.mp_process(self.instance, image_packet));
    checkBool(mediapipe.mp_wait_until_idle(self.instance));

    if (mediapipe.mp_get_queue_size(self.pose_landmarks_poller) > 0) {
        const packet = mediapipe.mp_poll_packet(self.pose_landmarks_poller);
        defer mediapipe.mp_destroy_packet(packet);
        const landmarks = mediapipe.mp_get_norm_landmarks(packet);
        defer mediapipe.mp_destroy_landmarks(landmarks);
        // do pose landmark logic
        const left_shulder = landmarks.*.elements[11];
        const right_shulder = landmarks.*.elements[12];
        result.body_pos_x = ((left_shulder.x + right_shulder.x) / 2 - 0.5) * 2;
        result.body_pos_y = ((left_shulder.y + right_shulder.y) / 2 - 0.8) * 2;
        result.body_rot_x = -std.math.atan2(left_shulder.y - right_shulder.y, left_shulder.x - right_shulder.x);
        //result.body_rot_z = std.math.atan2(left_shulder.x - right_shulder.x, left_shulder.z - right_shulder.z) - 1.570795;
    }

    if (mediapipe.mp_get_queue_size(self.face_landmarks_poller) > 0) {
        const packet = mediapipe.mp_poll_packet(self.face_landmarks_poller);
        defer mediapipe.mp_destroy_packet(packet);
        const landmarks = mediapipe.mp_get_norm_landmarks(packet);
        defer mediapipe.mp_destroy_landmarks(landmarks);
        const nose = landmarks.*.elements[116];
        const cheek = landmarks.*.elements[345];
        const forehead = landmarks.*.elements[8];
        result.head_x = std.math.atan2(cheek.y - nose.y, cheek.x - nose.x);
        result.head_y = std.math.atan2(forehead.z - nose.z, forehead.y - nose.y) + 2.513272;
        result.head_y = @min(1, result.head_y);
        result.head_y = @max(-1, result.head_y);
        result.head_z = std.math.atan2(cheek.x - nose.x, cheek.z - nose.z) - 1.5707963;
    }

    return result;
}

fn checkNull(result: anytype) void {
    if (result == null) checkBool(false);
}
fn checkBool(result: bool) void {
    if (!result) {
        std.log.err("[Mediapipe] {s}", .{mediapipe.mp_get_last_error()});
        std.posix.exit(1);
    }
}

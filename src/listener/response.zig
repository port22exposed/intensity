const zap = @import("zap");

pub fn denyRequest(r: zap.Request) void {
    r.setStatus(.bad_request);
    r.sendBody("400 - Bad Request") catch unreachable;
    return;
}

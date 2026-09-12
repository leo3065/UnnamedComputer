function automatic logic [31:0] lane_merge (
        logic [31:0] old, nxt, logic [3:0] sel);
    for (int i = 0; i < 4; i++) begin
        lane_merge[i*8 +: 8] = sel[i] ? nxt[i*8 +: 8] : old[i*8 +: 8];
    end
endfunction

function automatic logic [31:0] lane_w1c (
        logic [31:0] old, nxt, logic [3:0] sel);
    for (int i = 0; i < 4; i++)
    lane_w1c[i*8 +: 8] = sel[i] ? (old[i*8 +: 8] & ~nxt[i*8 +: 8])
                                :  old[i*8 +: 8];
endfunction

function automatic logic [31:0] lane_sel (logic [3:0] sel);
    lane_sel[i*8 +: 8] = sel[i] ? '1: '0;
endfunction

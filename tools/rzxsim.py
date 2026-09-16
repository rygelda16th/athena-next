"""Replay an RZX recording on SkoolKit's C simulator, with hooks.

skoolkit.rzxplay plays a recording and offers a whole-run trace or a whole-run
code map. The gates need finer control: a hook on every port write, a hook at
every frame's end, and an instruction trace switched on for chosen frames only
(a Python call per instruction costs roughly a hundred times the simulation, so
tracing all 119,655 frames is out of the question, but a few hundred is cheap).

The frame loop below follows skoolkit/rzxplay.py's process_block() (SkoolKit
10.1, GPL-3.0-or-later, (c) Richard Dymond) for the C simulator with playback
flags 0 - the path rzxwalk.py uses through rzxplay itself - and must stay
behaviourally identical to it: tools/bankexec.py cross-checks the frame count
and the final machine state against rzxplay's.
"""

from skoolkit import CSimulator, rzxplay
from skoolkit.simutils import from_snapshot


class Replay:
    """One pass over a recording.

    on_port_write(frame, port, value, pc)   every OUT, after the port is written
    on_frame_end(frame)                      after each frame's instructions
    trace_frames: set of frame numbers       on_instruction(frame, pc, out7ffd)
                                             is called before each instruction
                                             of those frames
    """

    def __init__(self, path):
        blocks = rzxplay.parse_rzx(path)
        snapshots = [b.obj for b in blocks if not isinstance(b.obj, rzxplay.InputRecording)]
        recordings = [b.obj for b in blocks if isinstance(b.obj, rzxplay.InputRecording)]
        if len(snapshots) != 1 or len(recordings) != 1:
            raise ValueError("expected one snapshot and one input block")
        self.snapshot = snapshots[0]
        self.recording = recordings[0]
        self.on_port_write = None
        self.on_frame_end = None
        self.on_instruction = None
        self.trace_frames = frozenset()

    def run(self):
        replay = self
        context = rzxplay.RZXContext(None)
        context.snapshot = self.snapshot
        context.total_frames = len(self.recording.frames)
        sim = from_snapshot(CSimulator, self.snapshot, config={"int_active": 0})
        context.simulator = sim

        class Tracer(rzxplay.RZXTracer):
            def write_port(self, registers, port, value, offset):
                super().write_port(registers, port, value, offset)
                if replay.on_port_write:
                    replay.on_port_write(context.frame_count, port, value, registers[24])

        tracer = Tracer(context, self.recording)
        sim.set_tracer(tracer)
        self.context, self.simulator, self.tracer = context, sim, tracer

        registers = sim.registers
        memory = sim.memory
        accept_interrupt = sim.accept_interrupt

        def trace(fetch_counter, pc):
            replay.on_instruction(context.frame_count, pc, tracer.out7ffd)

        fetch_counter = tracer.next_frame()
        while fetch_counter >= 0:
            frame = context.frame_count
            use_trace = trace if (self.on_instruction and frame in self.trace_frames) else None
            pc = sim.exec_frame(fetch_counter, None, use_trace)
            tracer.border[:] = [(0, tracer.border[-1][1])]
            if self.on_frame_end:
                self.on_frame_end(frame)
            registers[25] = 0
            fetch_counter = tracer.next_frame()
            if registers[26]:
                if memory[pc] == 0x76:
                    # Advance PC if the CPU was halted (as rzxplay does)
                    registers[24] = (registers[24] + 1) % 65536
                accept_interrupt(registers, memory, 0)
        return context.frame_count + 1

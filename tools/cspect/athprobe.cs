// AthProbe - a CSpect plugin that watches athena.nex from outside the machine.
//
// Off unless ATHPROBE_LOG names a log file, so it can sit in CSpect's folder beside
// the other projects' probes without touching a play session. Once a second it logs
// PC, SP, interrupt state, the MMU slots, NextReg $8C and $07, and two bytes the
// title changes ($F253, its colour counter, and $5807, an attribute it cycles);
// after ATHPROBE_SECONDS (default 8) it writes the ULA screen (6,912 bytes)
// to <log>.scr (read through $4000, where the game keeps bank 5) and quits CSpect.
//
// Build: mcs -target:library -r:<CSpect>/Plugin.dll -out:<CSpect>/AthProbe.dll athprobe.cs
using System;
using System.Collections.Generic;
using System.IO;
using Plugin;

namespace AthProbe
{
    public class Probe : iPlugin
    {
        iCSpect CSpect;
        StreamWriter log;
        string logPath;
        bool off = true;
        long ticks = 0;
        int seconds = 0, maxSeconds = 8;

        public List<sIO> Init(iCSpect _CSpect)
        {
            CSpect = _CSpect;
            logPath = Environment.GetEnvironmentVariable("ATHPROBE_LOG");
            if (string.IsNullOrEmpty(logPath)) return new List<sIO>();
            off = false;
            log = new StreamWriter(logPath);
            log.AutoFlush = true;
            string m = Environment.GetEnvironmentVariable("ATHPROBE_SECONDS");
            if (!string.IsNullOrEmpty(m)) int.TryParse(m, out maxSeconds);
            log.WriteLine("# athprobe up");
            return new List<sIO>();
        }

        public void Tick()
        {
            if (off) return;
            if (++ticks % 50 != 0) return;
            seconds++;
            Z80Regs r = CSpect.GetRegs();
            var sb = new System.Text.StringBuilder();
            sb.AppendFormat("t={0}s PC=${1:X4} SP=${2:X4} IFF1={3} IM={4} I=${5:X2} MMU=",
                            seconds, r.PC, r.SP, r.IFF1 ? 1 : 0, r.IM, r.I);
            for (int i = 0; i < 8; i++) sb.AppendFormat("{0} ", CSpect.GetNextRegister((byte)(0x50 + i), -1));
            sb.AppendFormat("8C=${0:X2} 07=${1:X2} F253=${2:X2} 5807=${3:X2}",
                            CSpect.GetNextRegister(0x8C, -1), CSpect.GetNextRegister(0x07, -1),
                            CSpect.Peek((ushort)0xF253), CSpect.Peek((ushort)0x5807));
            log.WriteLine(sb.ToString());
            if (seconds >= maxSeconds)
            {
                using (var f = new FileStream(logPath + ".scr", FileMode.Create))
                    for (int i = 0; i < 6912; i++) f.WriteByte(CSpect.Peek((ushort)(0x4000 + i)));
                log.WriteLine("# screen written");
                CSpect.SetGlobal(eGlobal.DoQuit, true);
            }
        }

        public void OSTick() { }
        public bool Write(eAccess _t, int _p, int _id, byte _v) { return false; }
        public byte Read(eAccess _t, int _p, int _id, out bool _valid) { _valid = false; return 0; }
        public bool KeyPressed(int _id) { return false; }
        public void Reset() { }
        public void Quit() { if (log != null) log.Close(); }
    }
}

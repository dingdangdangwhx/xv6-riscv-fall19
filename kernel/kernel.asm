
kernel/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000b117          	auipc	sp,0xb
    80000004:	80010113          	addi	sp,sp,-2048 # 8000a800 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <junk>:
    8000001a:	a001                	j	8000001a <junk>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	0000a617          	auipc	a2,0xa
    8000004e:	fb660613          	addi	a2,a2,-74 # 8000a000 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	eb478793          	addi	a5,a5,-332 # 80005f10 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd47a3>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	c8a78793          	addi	a5,a5,-886 # 80000d30 <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  timerinit();
    800000c4:	00000097          	auipc	ra,0x0
    800000c8:	f58080e7          	jalr	-168(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000cc:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000d0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000d2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000d4:	30200073          	mret
}
    800000d8:	60a2                	ld	ra,8(sp)
    800000da:	6402                	ld	s0,0(sp)
    800000dc:	0141                	addi	sp,sp,16
    800000de:	8082                	ret

00000000800000e0 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(struct file *f, int user_dst, uint64 dst, int n)
{
    800000e0:	7159                	addi	sp,sp,-112
    800000e2:	f486                	sd	ra,104(sp)
    800000e4:	f0a2                	sd	s0,96(sp)
    800000e6:	eca6                	sd	s1,88(sp)
    800000e8:	e8ca                	sd	s2,80(sp)
    800000ea:	e4ce                	sd	s3,72(sp)
    800000ec:	e0d2                	sd	s4,64(sp)
    800000ee:	fc56                	sd	s5,56(sp)
    800000f0:	f85a                	sd	s6,48(sp)
    800000f2:	f45e                	sd	s7,40(sp)
    800000f4:	f062                	sd	s8,32(sp)
    800000f6:	ec66                	sd	s9,24(sp)
    800000f8:	e86a                	sd	s10,16(sp)
    800000fa:	1880                	addi	s0,sp,112
    800000fc:	8aae                	mv	s5,a1
    800000fe:	8a32                	mv	s4,a2
    80000100:	89b6                	mv	s3,a3
  uint target;
  int c;
  char cbuf;

  target = n;
    80000102:	00068b1b          	sext.w	s6,a3
  acquire(&cons.lock);
    80000106:	00012517          	auipc	a0,0x12
    8000010a:	6fa50513          	addi	a0,a0,1786 # 80012800 <cons>
    8000010e:	00001097          	auipc	ra,0x1
    80000112:	9b0080e7          	jalr	-1616(ra) # 80000abe <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000116:	00012497          	auipc	s1,0x12
    8000011a:	6ea48493          	addi	s1,s1,1770 # 80012800 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    8000011e:	00012917          	auipc	s2,0x12
    80000122:	77a90913          	addi	s2,s2,1914 # 80012898 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    80000126:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000128:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    8000012a:	4ca9                	li	s9,10
  while(n > 0){
    8000012c:	07305863          	blez	s3,8000019c <consoleread+0xbc>
    while(cons.r == cons.w){
    80000130:	0984a783          	lw	a5,152(s1)
    80000134:	09c4a703          	lw	a4,156(s1)
    80000138:	02f71463          	bne	a4,a5,80000160 <consoleread+0x80>
      if(myproc()->killed){
    8000013c:	00002097          	auipc	ra,0x2
    80000140:	8ac080e7          	jalr	-1876(ra) # 800019e8 <myproc>
    80000144:	591c                	lw	a5,48(a0)
    80000146:	e7b5                	bnez	a5,800001b2 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    80000148:	85a6                	mv	a1,s1
    8000014a:	854a                	mv	a0,s2
    8000014c:	00002097          	auipc	ra,0x2
    80000150:	072080e7          	jalr	114(ra) # 800021be <sleep>
    while(cons.r == cons.w){
    80000154:	0984a783          	lw	a5,152(s1)
    80000158:	09c4a703          	lw	a4,156(s1)
    8000015c:	fef700e3          	beq	a4,a5,8000013c <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    80000160:	0017871b          	addiw	a4,a5,1
    80000164:	08e4ac23          	sw	a4,152(s1)
    80000168:	07f7f713          	andi	a4,a5,127
    8000016c:	9726                	add	a4,a4,s1
    8000016e:	01874703          	lbu	a4,24(a4)
    80000172:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000176:	077d0563          	beq	s10,s7,800001e0 <consoleread+0x100>
    cbuf = c;
    8000017a:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000017e:	4685                	li	a3,1
    80000180:	f9f40613          	addi	a2,s0,-97
    80000184:	85d2                	mv	a1,s4
    80000186:	8556                	mv	a0,s5
    80000188:	00002097          	auipc	ra,0x2
    8000018c:	290080e7          	jalr	656(ra) # 80002418 <either_copyout>
    80000190:	01850663          	beq	a0,s8,8000019c <consoleread+0xbc>
    dst++;
    80000194:	0a05                	addi	s4,s4,1
    --n;
    80000196:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000198:	f99d1ae3          	bne	s10,s9,8000012c <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000019c:	00012517          	auipc	a0,0x12
    800001a0:	66450513          	addi	a0,a0,1636 # 80012800 <cons>
    800001a4:	00001097          	auipc	ra,0x1
    800001a8:	982080e7          	jalr	-1662(ra) # 80000b26 <release>

  return target - n;
    800001ac:	413b053b          	subw	a0,s6,s3
    800001b0:	a811                	j	800001c4 <consoleread+0xe4>
        release(&cons.lock);
    800001b2:	00012517          	auipc	a0,0x12
    800001b6:	64e50513          	addi	a0,a0,1614 # 80012800 <cons>
    800001ba:	00001097          	auipc	ra,0x1
    800001be:	96c080e7          	jalr	-1684(ra) # 80000b26 <release>
        return -1;
    800001c2:	557d                	li	a0,-1
}
    800001c4:	70a6                	ld	ra,104(sp)
    800001c6:	7406                	ld	s0,96(sp)
    800001c8:	64e6                	ld	s1,88(sp)
    800001ca:	6946                	ld	s2,80(sp)
    800001cc:	69a6                	ld	s3,72(sp)
    800001ce:	6a06                	ld	s4,64(sp)
    800001d0:	7ae2                	ld	s5,56(sp)
    800001d2:	7b42                	ld	s6,48(sp)
    800001d4:	7ba2                	ld	s7,40(sp)
    800001d6:	7c02                	ld	s8,32(sp)
    800001d8:	6ce2                	ld	s9,24(sp)
    800001da:	6d42                	ld	s10,16(sp)
    800001dc:	6165                	addi	sp,sp,112
    800001de:	8082                	ret
      if(n < target){
    800001e0:	0009871b          	sext.w	a4,s3
    800001e4:	fb677ce3          	bgeu	a4,s6,8000019c <consoleread+0xbc>
        cons.r--;
    800001e8:	00012717          	auipc	a4,0x12
    800001ec:	6af72823          	sw	a5,1712(a4) # 80012898 <cons+0x98>
    800001f0:	b775                	j	8000019c <consoleread+0xbc>

00000000800001f2 <consputc>:
  if(panicked){
    800001f2:	0002a797          	auipc	a5,0x2a
    800001f6:	e267a783          	lw	a5,-474(a5) # 8002a018 <panicked>
    800001fa:	c391                	beqz	a5,800001fe <consputc+0xc>
    for(;;)
    800001fc:	a001                	j	800001fc <consputc+0xa>
{
    800001fe:	1141                	addi	sp,sp,-16
    80000200:	e406                	sd	ra,8(sp)
    80000202:	e022                	sd	s0,0(sp)
    80000204:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000206:	10000793          	li	a5,256
    8000020a:	00f50a63          	beq	a0,a5,8000021e <consputc+0x2c>
    uartputc(c);
    8000020e:	00000097          	auipc	ra,0x0
    80000212:	5cc080e7          	jalr	1484(ra) # 800007da <uartputc>
}
    80000216:	60a2                	ld	ra,8(sp)
    80000218:	6402                	ld	s0,0(sp)
    8000021a:	0141                	addi	sp,sp,16
    8000021c:	8082                	ret
    uartputc('\b'); uartputc(' '); uartputc('\b');
    8000021e:	4521                	li	a0,8
    80000220:	00000097          	auipc	ra,0x0
    80000224:	5ba080e7          	jalr	1466(ra) # 800007da <uartputc>
    80000228:	02000513          	li	a0,32
    8000022c:	00000097          	auipc	ra,0x0
    80000230:	5ae080e7          	jalr	1454(ra) # 800007da <uartputc>
    80000234:	4521                	li	a0,8
    80000236:	00000097          	auipc	ra,0x0
    8000023a:	5a4080e7          	jalr	1444(ra) # 800007da <uartputc>
    8000023e:	bfe1                	j	80000216 <consputc+0x24>

0000000080000240 <consolewrite>:
{
    80000240:	715d                	addi	sp,sp,-80
    80000242:	e486                	sd	ra,72(sp)
    80000244:	e0a2                	sd	s0,64(sp)
    80000246:	fc26                	sd	s1,56(sp)
    80000248:	f84a                	sd	s2,48(sp)
    8000024a:	f44e                	sd	s3,40(sp)
    8000024c:	f052                	sd	s4,32(sp)
    8000024e:	ec56                	sd	s5,24(sp)
    80000250:	0880                	addi	s0,sp,80
    80000252:	89ae                	mv	s3,a1
    80000254:	84b2                	mv	s1,a2
    80000256:	8ab6                	mv	s5,a3
  acquire(&cons.lock);
    80000258:	00012517          	auipc	a0,0x12
    8000025c:	5a850513          	addi	a0,a0,1448 # 80012800 <cons>
    80000260:	00001097          	auipc	ra,0x1
    80000264:	85e080e7          	jalr	-1954(ra) # 80000abe <acquire>
  for(i = 0; i < n; i++){
    80000268:	03505e63          	blez	s5,800002a4 <consolewrite+0x64>
    8000026c:	00148913          	addi	s2,s1,1
    80000270:	fffa879b          	addiw	a5,s5,-1
    80000274:	1782                	slli	a5,a5,0x20
    80000276:	9381                	srli	a5,a5,0x20
    80000278:	993e                	add	s2,s2,a5
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000027a:	5a7d                	li	s4,-1
    8000027c:	4685                	li	a3,1
    8000027e:	8626                	mv	a2,s1
    80000280:	85ce                	mv	a1,s3
    80000282:	fbf40513          	addi	a0,s0,-65
    80000286:	00002097          	auipc	ra,0x2
    8000028a:	1e8080e7          	jalr	488(ra) # 8000246e <either_copyin>
    8000028e:	01450b63          	beq	a0,s4,800002a4 <consolewrite+0x64>
    consputc(c);
    80000292:	fbf44503          	lbu	a0,-65(s0)
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	f5c080e7          	jalr	-164(ra) # 800001f2 <consputc>
  for(i = 0; i < n; i++){
    8000029e:	0485                	addi	s1,s1,1
    800002a0:	fd249ee3          	bne	s1,s2,8000027c <consolewrite+0x3c>
  release(&cons.lock);
    800002a4:	00012517          	auipc	a0,0x12
    800002a8:	55c50513          	addi	a0,a0,1372 # 80012800 <cons>
    800002ac:	00001097          	auipc	ra,0x1
    800002b0:	87a080e7          	jalr	-1926(ra) # 80000b26 <release>
}
    800002b4:	8556                	mv	a0,s5
    800002b6:	60a6                	ld	ra,72(sp)
    800002b8:	6406                	ld	s0,64(sp)
    800002ba:	74e2                	ld	s1,56(sp)
    800002bc:	7942                	ld	s2,48(sp)
    800002be:	79a2                	ld	s3,40(sp)
    800002c0:	7a02                	ld	s4,32(sp)
    800002c2:	6ae2                	ld	s5,24(sp)
    800002c4:	6161                	addi	sp,sp,80
    800002c6:	8082                	ret

00000000800002c8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c8:	1101                	addi	sp,sp,-32
    800002ca:	ec06                	sd	ra,24(sp)
    800002cc:	e822                	sd	s0,16(sp)
    800002ce:	e426                	sd	s1,8(sp)
    800002d0:	e04a                	sd	s2,0(sp)
    800002d2:	1000                	addi	s0,sp,32
    800002d4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d6:	00012517          	auipc	a0,0x12
    800002da:	52a50513          	addi	a0,a0,1322 # 80012800 <cons>
    800002de:	00000097          	auipc	ra,0x0
    800002e2:	7e0080e7          	jalr	2016(ra) # 80000abe <acquire>

  switch(c){
    800002e6:	47d5                	li	a5,21
    800002e8:	0af48663          	beq	s1,a5,80000394 <consoleintr+0xcc>
    800002ec:	0297ca63          	blt	a5,s1,80000320 <consoleintr+0x58>
    800002f0:	47a1                	li	a5,8
    800002f2:	0ef48763          	beq	s1,a5,800003e0 <consoleintr+0x118>
    800002f6:	47c1                	li	a5,16
    800002f8:	10f49a63          	bne	s1,a5,8000040c <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002fc:	00002097          	auipc	ra,0x2
    80000300:	1c8080e7          	jalr	456(ra) # 800024c4 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00012517          	auipc	a0,0x12
    80000308:	4fc50513          	addi	a0,a0,1276 # 80012800 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	81a080e7          	jalr	-2022(ra) # 80000b26 <release>
}
    80000314:	60e2                	ld	ra,24(sp)
    80000316:	6442                	ld	s0,16(sp)
    80000318:	64a2                	ld	s1,8(sp)
    8000031a:	6902                	ld	s2,0(sp)
    8000031c:	6105                	addi	sp,sp,32
    8000031e:	8082                	ret
  switch(c){
    80000320:	07f00793          	li	a5,127
    80000324:	0af48e63          	beq	s1,a5,800003e0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000328:	00012717          	auipc	a4,0x12
    8000032c:	4d870713          	addi	a4,a4,1240 # 80012800 <cons>
    80000330:	0a072783          	lw	a5,160(a4)
    80000334:	09872703          	lw	a4,152(a4)
    80000338:	9f99                	subw	a5,a5,a4
    8000033a:	07f00713          	li	a4,127
    8000033e:	fcf763e3          	bltu	a4,a5,80000304 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000342:	47b5                	li	a5,13
    80000344:	0cf48763          	beq	s1,a5,80000412 <consoleintr+0x14a>
      consputc(c);
    80000348:	8526                	mv	a0,s1
    8000034a:	00000097          	auipc	ra,0x0
    8000034e:	ea8080e7          	jalr	-344(ra) # 800001f2 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000352:	00012797          	auipc	a5,0x12
    80000356:	4ae78793          	addi	a5,a5,1198 # 80012800 <cons>
    8000035a:	0a07a703          	lw	a4,160(a5)
    8000035e:	0017069b          	addiw	a3,a4,1
    80000362:	0006861b          	sext.w	a2,a3
    80000366:	0ad7a023          	sw	a3,160(a5)
    8000036a:	07f77713          	andi	a4,a4,127
    8000036e:	97ba                	add	a5,a5,a4
    80000370:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000374:	47a9                	li	a5,10
    80000376:	0cf48563          	beq	s1,a5,80000440 <consoleintr+0x178>
    8000037a:	4791                	li	a5,4
    8000037c:	0cf48263          	beq	s1,a5,80000440 <consoleintr+0x178>
    80000380:	00012797          	auipc	a5,0x12
    80000384:	5187a783          	lw	a5,1304(a5) # 80012898 <cons+0x98>
    80000388:	0807879b          	addiw	a5,a5,128
    8000038c:	f6f61ce3          	bne	a2,a5,80000304 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000390:	863e                	mv	a2,a5
    80000392:	a07d                	j	80000440 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000394:	00012717          	auipc	a4,0x12
    80000398:	46c70713          	addi	a4,a4,1132 # 80012800 <cons>
    8000039c:	0a072783          	lw	a5,160(a4)
    800003a0:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a4:	00012497          	auipc	s1,0x12
    800003a8:	45c48493          	addi	s1,s1,1116 # 80012800 <cons>
    while(cons.e != cons.w &&
    800003ac:	4929                	li	s2,10
    800003ae:	f4f70be3          	beq	a4,a5,80000304 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003b2:	37fd                	addiw	a5,a5,-1
    800003b4:	07f7f713          	andi	a4,a5,127
    800003b8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ba:	01874703          	lbu	a4,24(a4)
    800003be:	f52703e3          	beq	a4,s2,80000304 <consoleintr+0x3c>
      cons.e--;
    800003c2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c6:	10000513          	li	a0,256
    800003ca:	00000097          	auipc	ra,0x0
    800003ce:	e28080e7          	jalr	-472(ra) # 800001f2 <consputc>
    while(cons.e != cons.w &&
    800003d2:	0a04a783          	lw	a5,160(s1)
    800003d6:	09c4a703          	lw	a4,156(s1)
    800003da:	fcf71ce3          	bne	a4,a5,800003b2 <consoleintr+0xea>
    800003de:	b71d                	j	80000304 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e0:	00012717          	auipc	a4,0x12
    800003e4:	42070713          	addi	a4,a4,1056 # 80012800 <cons>
    800003e8:	0a072783          	lw	a5,160(a4)
    800003ec:	09c72703          	lw	a4,156(a4)
    800003f0:	f0f70ae3          	beq	a4,a5,80000304 <consoleintr+0x3c>
      cons.e--;
    800003f4:	37fd                	addiw	a5,a5,-1
    800003f6:	00012717          	auipc	a4,0x12
    800003fa:	4af72523          	sw	a5,1194(a4) # 800128a0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fe:	10000513          	li	a0,256
    80000402:	00000097          	auipc	ra,0x0
    80000406:	df0080e7          	jalr	-528(ra) # 800001f2 <consputc>
    8000040a:	bded                	j	80000304 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000040c:	ee048ce3          	beqz	s1,80000304 <consoleintr+0x3c>
    80000410:	bf21                	j	80000328 <consoleintr+0x60>
      consputc(c);
    80000412:	4529                	li	a0,10
    80000414:	00000097          	auipc	ra,0x0
    80000418:	dde080e7          	jalr	-546(ra) # 800001f2 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000041c:	00012797          	auipc	a5,0x12
    80000420:	3e478793          	addi	a5,a5,996 # 80012800 <cons>
    80000424:	0a07a703          	lw	a4,160(a5)
    80000428:	0017069b          	addiw	a3,a4,1
    8000042c:	0006861b          	sext.w	a2,a3
    80000430:	0ad7a023          	sw	a3,160(a5)
    80000434:	07f77713          	andi	a4,a4,127
    80000438:	97ba                	add	a5,a5,a4
    8000043a:	4729                	li	a4,10
    8000043c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000440:	00012797          	auipc	a5,0x12
    80000444:	44c7ae23          	sw	a2,1116(a5) # 8001289c <cons+0x9c>
        wakeup(&cons.r);
    80000448:	00012517          	auipc	a0,0x12
    8000044c:	45050513          	addi	a0,a0,1104 # 80012898 <cons+0x98>
    80000450:	00002097          	auipc	ra,0x2
    80000454:	eee080e7          	jalr	-274(ra) # 8000233e <wakeup>
    80000458:	b575                	j	80000304 <consoleintr+0x3c>

000000008000045a <consoleinit>:

void
consoleinit(void)
{
    8000045a:	1141                	addi	sp,sp,-16
    8000045c:	e406                	sd	ra,8(sp)
    8000045e:	e022                	sd	s0,0(sp)
    80000460:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000462:	00008597          	auipc	a1,0x8
    80000466:	cb658593          	addi	a1,a1,-842 # 80008118 <userret+0x88>
    8000046a:	00012517          	auipc	a0,0x12
    8000046e:	39650513          	addi	a0,a0,918 # 80012800 <cons>
    80000472:	00000097          	auipc	ra,0x0
    80000476:	53e080e7          	jalr	1342(ra) # 800009b0 <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	32a080e7          	jalr	810(ra) # 800007a4 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00022797          	auipc	a5,0x22
    80000486:	66678793          	addi	a5,a5,1638 # 80022ae8 <devsw>
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c5670713          	addi	a4,a4,-938 # 800000e0 <consoleread>
    80000492:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000494:	00000717          	auipc	a4,0x0
    80000498:	dac70713          	addi	a4,a4,-596 # 80000240 <consolewrite>
    8000049c:	ef98                	sd	a4,24(a5)
}
    8000049e:	60a2                	ld	ra,8(sp)
    800004a0:	6402                	ld	s0,0(sp)
    800004a2:	0141                	addi	sp,sp,16
    800004a4:	8082                	ret

00000000800004a6 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a6:	7179                	addi	sp,sp,-48
    800004a8:	f406                	sd	ra,40(sp)
    800004aa:	f022                	sd	s0,32(sp)
    800004ac:	ec26                	sd	s1,24(sp)
    800004ae:	e84a                	sd	s2,16(sp)
    800004b0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004b2:	c219                	beqz	a2,800004b8 <printint+0x12>
    800004b4:	08054663          	bltz	a0,80000540 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b8:	2501                	sext.w	a0,a0
    800004ba:	4881                	li	a7,0
    800004bc:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004c2:	2581                	sext.w	a1,a1
    800004c4:	00008617          	auipc	a2,0x8
    800004c8:	52460613          	addi	a2,a2,1316 # 800089e8 <digits>
    800004cc:	883a                	mv	a6,a4
    800004ce:	2705                	addiw	a4,a4,1
    800004d0:	02b577bb          	remuw	a5,a0,a1
    800004d4:	1782                	slli	a5,a5,0x20
    800004d6:	9381                	srli	a5,a5,0x20
    800004d8:	97b2                	add	a5,a5,a2
    800004da:	0007c783          	lbu	a5,0(a5)
    800004de:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004e2:	0005079b          	sext.w	a5,a0
    800004e6:	02b5553b          	divuw	a0,a0,a1
    800004ea:	0685                	addi	a3,a3,1
    800004ec:	feb7f0e3          	bgeu	a5,a1,800004cc <printint+0x26>

  if(sign)
    800004f0:	00088b63          	beqz	a7,80000506 <printint+0x60>
    buf[i++] = '-';
    800004f4:	fe040793          	addi	a5,s0,-32
    800004f8:	973e                	add	a4,a4,a5
    800004fa:	02d00793          	li	a5,45
    800004fe:	fef70823          	sb	a5,-16(a4)
    80000502:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000506:	02e05763          	blez	a4,80000534 <printint+0x8e>
    8000050a:	fd040793          	addi	a5,s0,-48
    8000050e:	00e784b3          	add	s1,a5,a4
    80000512:	fff78913          	addi	s2,a5,-1
    80000516:	993a                	add	s2,s2,a4
    80000518:	377d                	addiw	a4,a4,-1
    8000051a:	1702                	slli	a4,a4,0x20
    8000051c:	9301                	srli	a4,a4,0x20
    8000051e:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000522:	fff4c503          	lbu	a0,-1(s1)
    80000526:	00000097          	auipc	ra,0x0
    8000052a:	ccc080e7          	jalr	-820(ra) # 800001f2 <consputc>
  while(--i >= 0)
    8000052e:	14fd                	addi	s1,s1,-1
    80000530:	ff2499e3          	bne	s1,s2,80000522 <printint+0x7c>
}
    80000534:	70a2                	ld	ra,40(sp)
    80000536:	7402                	ld	s0,32(sp)
    80000538:	64e2                	ld	s1,24(sp)
    8000053a:	6942                	ld	s2,16(sp)
    8000053c:	6145                	addi	sp,sp,48
    8000053e:	8082                	ret
    x = -xx;
    80000540:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000544:	4885                	li	a7,1
    x = -xx;
    80000546:	bf9d                	j	800004bc <printint+0x16>

0000000080000548 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000548:	1101                	addi	sp,sp,-32
    8000054a:	ec06                	sd	ra,24(sp)
    8000054c:	e822                	sd	s0,16(sp)
    8000054e:	e426                	sd	s1,8(sp)
    80000550:	1000                	addi	s0,sp,32
    80000552:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000554:	00012797          	auipc	a5,0x12
    80000558:	3607a623          	sw	zero,876(a5) # 800128c0 <pr+0x18>
  printf("panic: ");
    8000055c:	00008517          	auipc	a0,0x8
    80000560:	bc450513          	addi	a0,a0,-1084 # 80008120 <userret+0x90>
    80000564:	00000097          	auipc	ra,0x0
    80000568:	02e080e7          	jalr	46(ra) # 80000592 <printf>
  printf(s);
    8000056c:	8526                	mv	a0,s1
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	024080e7          	jalr	36(ra) # 80000592 <printf>
  printf("\n");
    80000576:	00008517          	auipc	a0,0x8
    8000057a:	c3a50513          	addi	a0,a0,-966 # 800081b0 <userret+0x120>
    8000057e:	00000097          	auipc	ra,0x0
    80000582:	014080e7          	jalr	20(ra) # 80000592 <printf>
  panicked = 1; // freeze other CPUs
    80000586:	4785                	li	a5,1
    80000588:	0002a717          	auipc	a4,0x2a
    8000058c:	a8f72823          	sw	a5,-1392(a4) # 8002a018 <panicked>
  for(;;)
    80000590:	a001                	j	80000590 <panic+0x48>

0000000080000592 <printf>:
{
    80000592:	7131                	addi	sp,sp,-192
    80000594:	fc86                	sd	ra,120(sp)
    80000596:	f8a2                	sd	s0,112(sp)
    80000598:	f4a6                	sd	s1,104(sp)
    8000059a:	f0ca                	sd	s2,96(sp)
    8000059c:	ecce                	sd	s3,88(sp)
    8000059e:	e8d2                	sd	s4,80(sp)
    800005a0:	e4d6                	sd	s5,72(sp)
    800005a2:	e0da                	sd	s6,64(sp)
    800005a4:	fc5e                	sd	s7,56(sp)
    800005a6:	f862                	sd	s8,48(sp)
    800005a8:	f466                	sd	s9,40(sp)
    800005aa:	f06a                	sd	s10,32(sp)
    800005ac:	ec6e                	sd	s11,24(sp)
    800005ae:	0100                	addi	s0,sp,128
    800005b0:	8a2a                	mv	s4,a0
    800005b2:	e40c                	sd	a1,8(s0)
    800005b4:	e810                	sd	a2,16(s0)
    800005b6:	ec14                	sd	a3,24(s0)
    800005b8:	f018                	sd	a4,32(s0)
    800005ba:	f41c                	sd	a5,40(s0)
    800005bc:	03043823          	sd	a6,48(s0)
    800005c0:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c4:	00012d97          	auipc	s11,0x12
    800005c8:	2fcdad83          	lw	s11,764(s11) # 800128c0 <pr+0x18>
  if(locking)
    800005cc:	020d9b63          	bnez	s11,80000602 <printf+0x70>
  if (fmt == 0)
    800005d0:	040a0263          	beqz	s4,80000614 <printf+0x82>
  va_start(ap, fmt);
    800005d4:	00840793          	addi	a5,s0,8
    800005d8:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005dc:	000a4503          	lbu	a0,0(s4)
    800005e0:	14050f63          	beqz	a0,8000073e <printf+0x1ac>
    800005e4:	4981                	li	s3,0
    if(c != '%'){
    800005e6:	02500a93          	li	s5,37
    switch(c){
    800005ea:	07000b93          	li	s7,112
  consputc('x');
    800005ee:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f0:	00008b17          	auipc	s6,0x8
    800005f4:	3f8b0b13          	addi	s6,s6,1016 # 800089e8 <digits>
    switch(c){
    800005f8:	07300c93          	li	s9,115
    800005fc:	06400c13          	li	s8,100
    80000600:	a82d                	j	8000063a <printf+0xa8>
    acquire(&pr.lock);
    80000602:	00012517          	auipc	a0,0x12
    80000606:	2a650513          	addi	a0,a0,678 # 800128a8 <pr>
    8000060a:	00000097          	auipc	ra,0x0
    8000060e:	4b4080e7          	jalr	1204(ra) # 80000abe <acquire>
    80000612:	bf7d                	j	800005d0 <printf+0x3e>
    panic("null fmt");
    80000614:	00008517          	auipc	a0,0x8
    80000618:	b1c50513          	addi	a0,a0,-1252 # 80008130 <userret+0xa0>
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	f2c080e7          	jalr	-212(ra) # 80000548 <panic>
      consputc(c);
    80000624:	00000097          	auipc	ra,0x0
    80000628:	bce080e7          	jalr	-1074(ra) # 800001f2 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000062c:	2985                	addiw	s3,s3,1
    8000062e:	013a07b3          	add	a5,s4,s3
    80000632:	0007c503          	lbu	a0,0(a5)
    80000636:	10050463          	beqz	a0,8000073e <printf+0x1ac>
    if(c != '%'){
    8000063a:	ff5515e3          	bne	a0,s5,80000624 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063e:	2985                	addiw	s3,s3,1
    80000640:	013a07b3          	add	a5,s4,s3
    80000644:	0007c783          	lbu	a5,0(a5)
    80000648:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000064c:	cbed                	beqz	a5,8000073e <printf+0x1ac>
    switch(c){
    8000064e:	05778a63          	beq	a5,s7,800006a2 <printf+0x110>
    80000652:	02fbf663          	bgeu	s7,a5,8000067e <printf+0xec>
    80000656:	09978863          	beq	a5,s9,800006e6 <printf+0x154>
    8000065a:	07800713          	li	a4,120
    8000065e:	0ce79563          	bne	a5,a4,80000728 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000662:	f8843783          	ld	a5,-120(s0)
    80000666:	00878713          	addi	a4,a5,8
    8000066a:	f8e43423          	sd	a4,-120(s0)
    8000066e:	4605                	li	a2,1
    80000670:	85ea                	mv	a1,s10
    80000672:	4388                	lw	a0,0(a5)
    80000674:	00000097          	auipc	ra,0x0
    80000678:	e32080e7          	jalr	-462(ra) # 800004a6 <printint>
      break;
    8000067c:	bf45                	j	8000062c <printf+0x9a>
    switch(c){
    8000067e:	09578f63          	beq	a5,s5,8000071c <printf+0x18a>
    80000682:	0b879363          	bne	a5,s8,80000728 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000686:	f8843783          	ld	a5,-120(s0)
    8000068a:	00878713          	addi	a4,a5,8
    8000068e:	f8e43423          	sd	a4,-120(s0)
    80000692:	4605                	li	a2,1
    80000694:	45a9                	li	a1,10
    80000696:	4388                	lw	a0,0(a5)
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	e0e080e7          	jalr	-498(ra) # 800004a6 <printint>
      break;
    800006a0:	b771                	j	8000062c <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006a2:	f8843783          	ld	a5,-120(s0)
    800006a6:	00878713          	addi	a4,a5,8
    800006aa:	f8e43423          	sd	a4,-120(s0)
    800006ae:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006b2:	03000513          	li	a0,48
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	b3c080e7          	jalr	-1220(ra) # 800001f2 <consputc>
  consputc('x');
    800006be:	07800513          	li	a0,120
    800006c2:	00000097          	auipc	ra,0x0
    800006c6:	b30080e7          	jalr	-1232(ra) # 800001f2 <consputc>
    800006ca:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006cc:	03c95793          	srli	a5,s2,0x3c
    800006d0:	97da                	add	a5,a5,s6
    800006d2:	0007c503          	lbu	a0,0(a5)
    800006d6:	00000097          	auipc	ra,0x0
    800006da:	b1c080e7          	jalr	-1252(ra) # 800001f2 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006de:	0912                	slli	s2,s2,0x4
    800006e0:	34fd                	addiw	s1,s1,-1
    800006e2:	f4ed                	bnez	s1,800006cc <printf+0x13a>
    800006e4:	b7a1                	j	8000062c <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e6:	f8843783          	ld	a5,-120(s0)
    800006ea:	00878713          	addi	a4,a5,8
    800006ee:	f8e43423          	sd	a4,-120(s0)
    800006f2:	6384                	ld	s1,0(a5)
    800006f4:	cc89                	beqz	s1,8000070e <printf+0x17c>
      for(; *s; s++)
    800006f6:	0004c503          	lbu	a0,0(s1)
    800006fa:	d90d                	beqz	a0,8000062c <printf+0x9a>
        consputc(*s);
    800006fc:	00000097          	auipc	ra,0x0
    80000700:	af6080e7          	jalr	-1290(ra) # 800001f2 <consputc>
      for(; *s; s++)
    80000704:	0485                	addi	s1,s1,1
    80000706:	0004c503          	lbu	a0,0(s1)
    8000070a:	f96d                	bnez	a0,800006fc <printf+0x16a>
    8000070c:	b705                	j	8000062c <printf+0x9a>
        s = "(null)";
    8000070e:	00008497          	auipc	s1,0x8
    80000712:	a1a48493          	addi	s1,s1,-1510 # 80008128 <userret+0x98>
      for(; *s; s++)
    80000716:	02800513          	li	a0,40
    8000071a:	b7cd                	j	800006fc <printf+0x16a>
      consputc('%');
    8000071c:	8556                	mv	a0,s5
    8000071e:	00000097          	auipc	ra,0x0
    80000722:	ad4080e7          	jalr	-1324(ra) # 800001f2 <consputc>
      break;
    80000726:	b719                	j	8000062c <printf+0x9a>
      consputc('%');
    80000728:	8556                	mv	a0,s5
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	ac8080e7          	jalr	-1336(ra) # 800001f2 <consputc>
      consputc(c);
    80000732:	8526                	mv	a0,s1
    80000734:	00000097          	auipc	ra,0x0
    80000738:	abe080e7          	jalr	-1346(ra) # 800001f2 <consputc>
      break;
    8000073c:	bdc5                	j	8000062c <printf+0x9a>
  if(locking)
    8000073e:	020d9163          	bnez	s11,80000760 <printf+0x1ce>
}
    80000742:	70e6                	ld	ra,120(sp)
    80000744:	7446                	ld	s0,112(sp)
    80000746:	74a6                	ld	s1,104(sp)
    80000748:	7906                	ld	s2,96(sp)
    8000074a:	69e6                	ld	s3,88(sp)
    8000074c:	6a46                	ld	s4,80(sp)
    8000074e:	6aa6                	ld	s5,72(sp)
    80000750:	6b06                	ld	s6,64(sp)
    80000752:	7be2                	ld	s7,56(sp)
    80000754:	7c42                	ld	s8,48(sp)
    80000756:	7ca2                	ld	s9,40(sp)
    80000758:	7d02                	ld	s10,32(sp)
    8000075a:	6de2                	ld	s11,24(sp)
    8000075c:	6129                	addi	sp,sp,192
    8000075e:	8082                	ret
    release(&pr.lock);
    80000760:	00012517          	auipc	a0,0x12
    80000764:	14850513          	addi	a0,a0,328 # 800128a8 <pr>
    80000768:	00000097          	auipc	ra,0x0
    8000076c:	3be080e7          	jalr	958(ra) # 80000b26 <release>
}
    80000770:	bfc9                	j	80000742 <printf+0x1b0>

0000000080000772 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000772:	1101                	addi	sp,sp,-32
    80000774:	ec06                	sd	ra,24(sp)
    80000776:	e822                	sd	s0,16(sp)
    80000778:	e426                	sd	s1,8(sp)
    8000077a:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000077c:	00012497          	auipc	s1,0x12
    80000780:	12c48493          	addi	s1,s1,300 # 800128a8 <pr>
    80000784:	00008597          	auipc	a1,0x8
    80000788:	9bc58593          	addi	a1,a1,-1604 # 80008140 <userret+0xb0>
    8000078c:	8526                	mv	a0,s1
    8000078e:	00000097          	auipc	ra,0x0
    80000792:	222080e7          	jalr	546(ra) # 800009b0 <initlock>
  pr.locking = 1;
    80000796:	4785                	li	a5,1
    80000798:	cc9c                	sw	a5,24(s1)
}
    8000079a:	60e2                	ld	ra,24(sp)
    8000079c:	6442                	ld	s0,16(sp)
    8000079e:	64a2                	ld	s1,8(sp)
    800007a0:	6105                	addi	sp,sp,32
    800007a2:	8082                	ret

00000000800007a4 <uartinit>:
#define ReadReg(reg) (*(Reg(reg)))
#define WriteReg(reg, v) (*(Reg(reg)) = (v))

void
uartinit(void)
{
    800007a4:	1141                	addi	sp,sp,-16
    800007a6:	e422                	sd	s0,8(sp)
    800007a8:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007aa:	100007b7          	lui	a5,0x10000
    800007ae:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, 0x80);
    800007b2:	f8000713          	li	a4,-128
    800007b6:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007ba:	470d                	li	a4,3
    800007bc:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c0:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, 0x03);
    800007c4:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, 0x07);
    800007c8:	471d                	li	a4,7
    800007ca:	00e78123          	sb	a4,2(a5)

  // enable receive interrupts.
  WriteReg(IER, 0x01);
    800007ce:	4705                	li	a4,1
    800007d0:	00e780a3          	sb	a4,1(a5)
}
    800007d4:	6422                	ld	s0,8(sp)
    800007d6:	0141                	addi	sp,sp,16
    800007d8:	8082                	ret

00000000800007da <uartputc>:

// write one output character to the UART.
void
uartputc(int c)
{
    800007da:	1141                	addi	sp,sp,-16
    800007dc:	e422                	sd	s0,8(sp)
    800007de:	0800                	addi	s0,sp,16
  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & (1 << 5)) == 0)
    800007e0:	10000737          	lui	a4,0x10000
    800007e4:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    800007e8:	0207f793          	andi	a5,a5,32
    800007ec:	dfe5                	beqz	a5,800007e4 <uartputc+0xa>
    ;
  WriteReg(THR, c);
    800007ee:	0ff57513          	andi	a0,a0,255
    800007f2:	100007b7          	lui	a5,0x10000
    800007f6:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>
}
    800007fa:	6422                	ld	s0,8(sp)
    800007fc:	0141                	addi	sp,sp,16
    800007fe:	8082                	ret

0000000080000800 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000800:	1141                	addi	sp,sp,-16
    80000802:	e422                	sd	s0,8(sp)
    80000804:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000806:	100007b7          	lui	a5,0x10000
    8000080a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000080e:	8b85                	andi	a5,a5,1
    80000810:	cb91                	beqz	a5,80000824 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000812:	100007b7          	lui	a5,0x10000
    80000816:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000081a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000081e:	6422                	ld	s0,8(sp)
    80000820:	0141                	addi	sp,sp,16
    80000822:	8082                	ret
    return -1;
    80000824:	557d                	li	a0,-1
    80000826:	bfe5                	j	8000081e <uartgetc+0x1e>

0000000080000828 <uartintr>:

// trap.c calls here when the uart interrupts.
void
uartintr(void)
{
    80000828:	1101                	addi	sp,sp,-32
    8000082a:	ec06                	sd	ra,24(sp)
    8000082c:	e822                	sd	s0,16(sp)
    8000082e:	e426                	sd	s1,8(sp)
    80000830:	1000                	addi	s0,sp,32
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000832:	54fd                	li	s1,-1
    80000834:	a029                	j	8000083e <uartintr+0x16>
      break;
    consoleintr(c);
    80000836:	00000097          	auipc	ra,0x0
    8000083a:	a92080e7          	jalr	-1390(ra) # 800002c8 <consoleintr>
    int c = uartgetc();
    8000083e:	00000097          	auipc	ra,0x0
    80000842:	fc2080e7          	jalr	-62(ra) # 80000800 <uartgetc>
    if(c == -1)
    80000846:	fe9518e3          	bne	a0,s1,80000836 <uartintr+0xe>
  }
}
    8000084a:	60e2                	ld	ra,24(sp)
    8000084c:	6442                	ld	s0,16(sp)
    8000084e:	64a2                	ld	s1,8(sp)
    80000850:	6105                	addi	sp,sp,32
    80000852:	8082                	ret

0000000080000854 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000854:	1101                	addi	sp,sp,-32
    80000856:	ec06                	sd	ra,24(sp)
    80000858:	e822                	sd	s0,16(sp)
    8000085a:	e426                	sd	s1,8(sp)
    8000085c:	e04a                	sd	s2,0(sp)
    8000085e:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000860:	03451793          	slli	a5,a0,0x34
    80000864:	ebb9                	bnez	a5,800008ba <kfree+0x66>
    80000866:	84aa                	mv	s1,a0
    80000868:	00029797          	auipc	a5,0x29
    8000086c:	7f478793          	addi	a5,a5,2036 # 8002a05c <end>
    80000870:	04f56563          	bltu	a0,a5,800008ba <kfree+0x66>
    80000874:	47c5                	li	a5,17
    80000876:	07ee                	slli	a5,a5,0x1b
    80000878:	04f57163          	bgeu	a0,a5,800008ba <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    8000087c:	6605                	lui	a2,0x1
    8000087e:	4585                	li	a1,1
    80000880:	00000097          	auipc	ra,0x0
    80000884:	302080e7          	jalr	770(ra) # 80000b82 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000888:	00012917          	auipc	s2,0x12
    8000088c:	04090913          	addi	s2,s2,64 # 800128c8 <kmem>
    80000890:	854a                	mv	a0,s2
    80000892:	00000097          	auipc	ra,0x0
    80000896:	22c080e7          	jalr	556(ra) # 80000abe <acquire>
  r->next = kmem.freelist;
    8000089a:	01893783          	ld	a5,24(s2)
    8000089e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    800008a0:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    800008a4:	854a                	mv	a0,s2
    800008a6:	00000097          	auipc	ra,0x0
    800008aa:	280080e7          	jalr	640(ra) # 80000b26 <release>
}
    800008ae:	60e2                	ld	ra,24(sp)
    800008b0:	6442                	ld	s0,16(sp)
    800008b2:	64a2                	ld	s1,8(sp)
    800008b4:	6902                	ld	s2,0(sp)
    800008b6:	6105                	addi	sp,sp,32
    800008b8:	8082                	ret
    panic("kfree");
    800008ba:	00008517          	auipc	a0,0x8
    800008be:	88e50513          	addi	a0,a0,-1906 # 80008148 <userret+0xb8>
    800008c2:	00000097          	auipc	ra,0x0
    800008c6:	c86080e7          	jalr	-890(ra) # 80000548 <panic>

00000000800008ca <freerange>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    800008da:	6785                	lui	a5,0x1
    800008dc:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    800008e0:	94aa                	add	s1,s1,a0
    800008e2:	757d                	lui	a0,0xfffff
    800008e4:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    800008e6:	94be                	add	s1,s1,a5
    800008e8:	0095ee63          	bltu	a1,s1,80000904 <freerange+0x3a>
    800008ec:	892e                	mv	s2,a1
    kfree(p);
    800008ee:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    800008f0:	6985                	lui	s3,0x1
    kfree(p);
    800008f2:	01448533          	add	a0,s1,s4
    800008f6:	00000097          	auipc	ra,0x0
    800008fa:	f5e080e7          	jalr	-162(ra) # 80000854 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    800008fe:	94ce                	add	s1,s1,s3
    80000900:	fe9979e3          	bgeu	s2,s1,800008f2 <freerange+0x28>
}
    80000904:	70a2                	ld	ra,40(sp)
    80000906:	7402                	ld	s0,32(sp)
    80000908:	64e2                	ld	s1,24(sp)
    8000090a:	6942                	ld	s2,16(sp)
    8000090c:	69a2                	ld	s3,8(sp)
    8000090e:	6a02                	ld	s4,0(sp)
    80000910:	6145                	addi	sp,sp,48
    80000912:	8082                	ret

0000000080000914 <kinit>:
{
    80000914:	1141                	addi	sp,sp,-16
    80000916:	e406                	sd	ra,8(sp)
    80000918:	e022                	sd	s0,0(sp)
    8000091a:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    8000091c:	00008597          	auipc	a1,0x8
    80000920:	83458593          	addi	a1,a1,-1996 # 80008150 <userret+0xc0>
    80000924:	00012517          	auipc	a0,0x12
    80000928:	fa450513          	addi	a0,a0,-92 # 800128c8 <kmem>
    8000092c:	00000097          	auipc	ra,0x0
    80000930:	084080e7          	jalr	132(ra) # 800009b0 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000934:	45c5                	li	a1,17
    80000936:	05ee                	slli	a1,a1,0x1b
    80000938:	00029517          	auipc	a0,0x29
    8000093c:	72450513          	addi	a0,a0,1828 # 8002a05c <end>
    80000940:	00000097          	auipc	ra,0x0
    80000944:	f8a080e7          	jalr	-118(ra) # 800008ca <freerange>
}
    80000948:	60a2                	ld	ra,8(sp)
    8000094a:	6402                	ld	s0,0(sp)
    8000094c:	0141                	addi	sp,sp,16
    8000094e:	8082                	ret

0000000080000950 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000950:	1101                	addi	sp,sp,-32
    80000952:	ec06                	sd	ra,24(sp)
    80000954:	e822                	sd	s0,16(sp)
    80000956:	e426                	sd	s1,8(sp)
    80000958:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    8000095a:	00012497          	auipc	s1,0x12
    8000095e:	f6e48493          	addi	s1,s1,-146 # 800128c8 <kmem>
    80000962:	8526                	mv	a0,s1
    80000964:	00000097          	auipc	ra,0x0
    80000968:	15a080e7          	jalr	346(ra) # 80000abe <acquire>
  r = kmem.freelist;
    8000096c:	6c84                	ld	s1,24(s1)
  if(r)
    8000096e:	c885                	beqz	s1,8000099e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000970:	609c                	ld	a5,0(s1)
    80000972:	00012517          	auipc	a0,0x12
    80000976:	f5650513          	addi	a0,a0,-170 # 800128c8 <kmem>
    8000097a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    8000097c:	00000097          	auipc	ra,0x0
    80000980:	1aa080e7          	jalr	426(ra) # 80000b26 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000984:	6605                	lui	a2,0x1
    80000986:	4595                	li	a1,5
    80000988:	8526                	mv	a0,s1
    8000098a:	00000097          	auipc	ra,0x0
    8000098e:	1f8080e7          	jalr	504(ra) # 80000b82 <memset>
  return (void*)r;
}
    80000992:	8526                	mv	a0,s1
    80000994:	60e2                	ld	ra,24(sp)
    80000996:	6442                	ld	s0,16(sp)
    80000998:	64a2                	ld	s1,8(sp)
    8000099a:	6105                	addi	sp,sp,32
    8000099c:	8082                	ret
  release(&kmem.lock);
    8000099e:	00012517          	auipc	a0,0x12
    800009a2:	f2a50513          	addi	a0,a0,-214 # 800128c8 <kmem>
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	180080e7          	jalr	384(ra) # 80000b26 <release>
  if(r)
    800009ae:	b7d5                	j	80000992 <kalloc+0x42>

00000000800009b0 <initlock>:

uint64 ntest_and_set;

void
initlock(struct spinlock *lk, char *name)
{
    800009b0:	1141                	addi	sp,sp,-16
    800009b2:	e422                	sd	s0,8(sp)
    800009b4:	0800                	addi	s0,sp,16
  lk->name = name;
    800009b6:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    800009b8:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    800009bc:	00053823          	sd	zero,16(a0)
}
    800009c0:	6422                	ld	s0,8(sp)
    800009c2:	0141                	addi	sp,sp,16
    800009c4:	8082                	ret

00000000800009c6 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    800009c6:	1101                	addi	sp,sp,-32
    800009c8:	ec06                	sd	ra,24(sp)
    800009ca:	e822                	sd	s0,16(sp)
    800009cc:	e426                	sd	s1,8(sp)
    800009ce:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800009d0:	100024f3          	csrr	s1,sstatus
    800009d4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800009d8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800009da:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    800009de:	00001097          	auipc	ra,0x1
    800009e2:	fee080e7          	jalr	-18(ra) # 800019cc <mycpu>
    800009e6:	5d3c                	lw	a5,120(a0)
    800009e8:	cf89                	beqz	a5,80000a02 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    800009ea:	00001097          	auipc	ra,0x1
    800009ee:	fe2080e7          	jalr	-30(ra) # 800019cc <mycpu>
    800009f2:	5d3c                	lw	a5,120(a0)
    800009f4:	2785                	addiw	a5,a5,1
    800009f6:	dd3c                	sw	a5,120(a0)
}
    800009f8:	60e2                	ld	ra,24(sp)
    800009fa:	6442                	ld	s0,16(sp)
    800009fc:	64a2                	ld	s1,8(sp)
    800009fe:	6105                	addi	sp,sp,32
    80000a00:	8082                	ret
    mycpu()->intena = old;
    80000a02:	00001097          	auipc	ra,0x1
    80000a06:	fca080e7          	jalr	-54(ra) # 800019cc <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000a0a:	8085                	srli	s1,s1,0x1
    80000a0c:	8885                	andi	s1,s1,1
    80000a0e:	dd64                	sw	s1,124(a0)
    80000a10:	bfe9                	j	800009ea <push_off+0x24>

0000000080000a12 <pop_off>:

void
pop_off(void)
{
    80000a12:	1141                	addi	sp,sp,-16
    80000a14:	e406                	sd	ra,8(sp)
    80000a16:	e022                	sd	s0,0(sp)
    80000a18:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000a1a:	00001097          	auipc	ra,0x1
    80000a1e:	fb2080e7          	jalr	-78(ra) # 800019cc <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000a22:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000a26:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000a28:	eb9d                	bnez	a5,80000a5e <pop_off+0x4c>
    panic("pop_off - interruptible");
  c->noff -= 1;
    80000a2a:	5d3c                	lw	a5,120(a0)
    80000a2c:	37fd                	addiw	a5,a5,-1
    80000a2e:	0007871b          	sext.w	a4,a5
    80000a32:	dd3c                	sw	a5,120(a0)
  if(c->noff < 0)
    80000a34:	02074d63          	bltz	a4,80000a6e <pop_off+0x5c>
    panic("pop_off");
  if(c->noff == 0 && c->intena)
    80000a38:	ef19                	bnez	a4,80000a56 <pop_off+0x44>
    80000a3a:	5d7c                	lw	a5,124(a0)
    80000a3c:	cf89                	beqz	a5,80000a56 <pop_off+0x44>
  asm volatile("csrr %0, sie" : "=r" (x) );
    80000a3e:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    80000a42:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    80000a46:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000a4a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000a4e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000a52:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000a56:	60a2                	ld	ra,8(sp)
    80000a58:	6402                	ld	s0,0(sp)
    80000a5a:	0141                	addi	sp,sp,16
    80000a5c:	8082                	ret
    panic("pop_off - interruptible");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	6fa50513          	addi	a0,a0,1786 # 80008158 <userret+0xc8>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ae2080e7          	jalr	-1310(ra) # 80000548 <panic>
    panic("pop_off");
    80000a6e:	00007517          	auipc	a0,0x7
    80000a72:	70250513          	addi	a0,a0,1794 # 80008170 <userret+0xe0>
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	ad2080e7          	jalr	-1326(ra) # 80000548 <panic>

0000000080000a7e <holding>:
{
    80000a7e:	1101                	addi	sp,sp,-32
    80000a80:	ec06                	sd	ra,24(sp)
    80000a82:	e822                	sd	s0,16(sp)
    80000a84:	e426                	sd	s1,8(sp)
    80000a86:	1000                	addi	s0,sp,32
    80000a88:	84aa                	mv	s1,a0
  push_off();
    80000a8a:	00000097          	auipc	ra,0x0
    80000a8e:	f3c080e7          	jalr	-196(ra) # 800009c6 <push_off>
  r = (lk->locked && lk->cpu == mycpu());
    80000a92:	409c                	lw	a5,0(s1)
    80000a94:	ef81                	bnez	a5,80000aac <holding+0x2e>
    80000a96:	4481                	li	s1,0
  pop_off();
    80000a98:	00000097          	auipc	ra,0x0
    80000a9c:	f7a080e7          	jalr	-134(ra) # 80000a12 <pop_off>
}
    80000aa0:	8526                	mv	a0,s1
    80000aa2:	60e2                	ld	ra,24(sp)
    80000aa4:	6442                	ld	s0,16(sp)
    80000aa6:	64a2                	ld	s1,8(sp)
    80000aa8:	6105                	addi	sp,sp,32
    80000aaa:	8082                	ret
  r = (lk->locked && lk->cpu == mycpu());
    80000aac:	6884                	ld	s1,16(s1)
    80000aae:	00001097          	auipc	ra,0x1
    80000ab2:	f1e080e7          	jalr	-226(ra) # 800019cc <mycpu>
    80000ab6:	8c89                	sub	s1,s1,a0
    80000ab8:	0014b493          	seqz	s1,s1
    80000abc:	bff1                	j	80000a98 <holding+0x1a>

0000000080000abe <acquire>:
{
    80000abe:	1101                	addi	sp,sp,-32
    80000ac0:	ec06                	sd	ra,24(sp)
    80000ac2:	e822                	sd	s0,16(sp)
    80000ac4:	e426                	sd	s1,8(sp)
    80000ac6:	1000                	addi	s0,sp,32
    80000ac8:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000aca:	00000097          	auipc	ra,0x0
    80000ace:	efc080e7          	jalr	-260(ra) # 800009c6 <push_off>
  if(holding(lk))
    80000ad2:	8526                	mv	a0,s1
    80000ad4:	00000097          	auipc	ra,0x0
    80000ad8:	faa080e7          	jalr	-86(ra) # 80000a7e <holding>
    80000adc:	e901                	bnez	a0,80000aec <acquire+0x2e>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000ade:	4685                	li	a3,1
     __sync_fetch_and_add(&ntest_and_set, 1);
    80000ae0:	00029717          	auipc	a4,0x29
    80000ae4:	54070713          	addi	a4,a4,1344 # 8002a020 <ntest_and_set>
    80000ae8:	4605                	li	a2,1
    80000aea:	a829                	j	80000b04 <acquire+0x46>
    panic("acquire");
    80000aec:	00007517          	auipc	a0,0x7
    80000af0:	68c50513          	addi	a0,a0,1676 # 80008178 <userret+0xe8>
    80000af4:	00000097          	auipc	ra,0x0
    80000af8:	a54080e7          	jalr	-1452(ra) # 80000548 <panic>
     __sync_fetch_and_add(&ntest_and_set, 1);
    80000afc:	0f50000f          	fence	iorw,ow
    80000b00:	04c7302f          	amoadd.d.aq	zero,a2,(a4)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000b04:	87b6                	mv	a5,a3
    80000b06:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000b0a:	2781                	sext.w	a5,a5
    80000b0c:	fbe5                	bnez	a5,80000afc <acquire+0x3e>
  __sync_synchronize();
    80000b0e:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000b12:	00001097          	auipc	ra,0x1
    80000b16:	eba080e7          	jalr	-326(ra) # 800019cc <mycpu>
    80000b1a:	e888                	sd	a0,16(s1)
}
    80000b1c:	60e2                	ld	ra,24(sp)
    80000b1e:	6442                	ld	s0,16(sp)
    80000b20:	64a2                	ld	s1,8(sp)
    80000b22:	6105                	addi	sp,sp,32
    80000b24:	8082                	ret

0000000080000b26 <release>:
{
    80000b26:	1101                	addi	sp,sp,-32
    80000b28:	ec06                	sd	ra,24(sp)
    80000b2a:	e822                	sd	s0,16(sp)
    80000b2c:	e426                	sd	s1,8(sp)
    80000b2e:	1000                	addi	s0,sp,32
    80000b30:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000b32:	00000097          	auipc	ra,0x0
    80000b36:	f4c080e7          	jalr	-180(ra) # 80000a7e <holding>
    80000b3a:	c115                	beqz	a0,80000b5e <release+0x38>
  lk->cpu = 0;
    80000b3c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000b40:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000b44:	0f50000f          	fence	iorw,ow
    80000b48:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000b4c:	00000097          	auipc	ra,0x0
    80000b50:	ec6080e7          	jalr	-314(ra) # 80000a12 <pop_off>
}
    80000b54:	60e2                	ld	ra,24(sp)
    80000b56:	6442                	ld	s0,16(sp)
    80000b58:	64a2                	ld	s1,8(sp)
    80000b5a:	6105                	addi	sp,sp,32
    80000b5c:	8082                	ret
    panic("release");
    80000b5e:	00007517          	auipc	a0,0x7
    80000b62:	62250513          	addi	a0,a0,1570 # 80008180 <userret+0xf0>
    80000b66:	00000097          	auipc	ra,0x0
    80000b6a:	9e2080e7          	jalr	-1566(ra) # 80000548 <panic>

0000000080000b6e <sys_ntas>:

uint64
sys_ntas(void)
{
    80000b6e:	1141                	addi	sp,sp,-16
    80000b70:	e422                	sd	s0,8(sp)
    80000b72:	0800                	addi	s0,sp,16
  return ntest_and_set;
}
    80000b74:	00029517          	auipc	a0,0x29
    80000b78:	4ac53503          	ld	a0,1196(a0) # 8002a020 <ntest_and_set>
    80000b7c:	6422                	ld	s0,8(sp)
    80000b7e:	0141                	addi	sp,sp,16
    80000b80:	8082                	ret

0000000080000b82 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000b82:	1141                	addi	sp,sp,-16
    80000b84:	e422                	sd	s0,8(sp)
    80000b86:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000b88:	ca19                	beqz	a2,80000b9e <memset+0x1c>
    80000b8a:	87aa                	mv	a5,a0
    80000b8c:	1602                	slli	a2,a2,0x20
    80000b8e:	9201                	srli	a2,a2,0x20
    80000b90:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000b94:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000b98:	0785                	addi	a5,a5,1
    80000b9a:	fee79de3          	bne	a5,a4,80000b94 <memset+0x12>
  }
  return dst;
}
    80000b9e:	6422                	ld	s0,8(sp)
    80000ba0:	0141                	addi	sp,sp,16
    80000ba2:	8082                	ret

0000000080000ba4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000ba4:	1141                	addi	sp,sp,-16
    80000ba6:	e422                	sd	s0,8(sp)
    80000ba8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000baa:	ca05                	beqz	a2,80000bda <memcmp+0x36>
    80000bac:	fff6069b          	addiw	a3,a2,-1
    80000bb0:	1682                	slli	a3,a3,0x20
    80000bb2:	9281                	srli	a3,a3,0x20
    80000bb4:	0685                	addi	a3,a3,1
    80000bb6:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000bb8:	00054783          	lbu	a5,0(a0)
    80000bbc:	0005c703          	lbu	a4,0(a1)
    80000bc0:	00e79863          	bne	a5,a4,80000bd0 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000bc4:	0505                	addi	a0,a0,1
    80000bc6:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000bc8:	fed518e3          	bne	a0,a3,80000bb8 <memcmp+0x14>
  }

  return 0;
    80000bcc:	4501                	li	a0,0
    80000bce:	a019                	j	80000bd4 <memcmp+0x30>
      return *s1 - *s2;
    80000bd0:	40e7853b          	subw	a0,a5,a4
}
    80000bd4:	6422                	ld	s0,8(sp)
    80000bd6:	0141                	addi	sp,sp,16
    80000bd8:	8082                	ret
  return 0;
    80000bda:	4501                	li	a0,0
    80000bdc:	bfe5                	j	80000bd4 <memcmp+0x30>

0000000080000bde <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000bde:	1141                	addi	sp,sp,-16
    80000be0:	e422                	sd	s0,8(sp)
    80000be2:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000be4:	02a5e563          	bltu	a1,a0,80000c0e <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000be8:	fff6069b          	addiw	a3,a2,-1
    80000bec:	ce11                	beqz	a2,80000c08 <memmove+0x2a>
    80000bee:	1682                	slli	a3,a3,0x20
    80000bf0:	9281                	srli	a3,a3,0x20
    80000bf2:	0685                	addi	a3,a3,1
    80000bf4:	96ae                	add	a3,a3,a1
    80000bf6:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000bf8:	0585                	addi	a1,a1,1
    80000bfa:	0785                	addi	a5,a5,1
    80000bfc:	fff5c703          	lbu	a4,-1(a1)
    80000c00:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000c04:	fed59ae3          	bne	a1,a3,80000bf8 <memmove+0x1a>

  return dst;
}
    80000c08:	6422                	ld	s0,8(sp)
    80000c0a:	0141                	addi	sp,sp,16
    80000c0c:	8082                	ret
  if(s < d && s + n > d){
    80000c0e:	02061713          	slli	a4,a2,0x20
    80000c12:	9301                	srli	a4,a4,0x20
    80000c14:	00e587b3          	add	a5,a1,a4
    80000c18:	fcf578e3          	bgeu	a0,a5,80000be8 <memmove+0xa>
    d += n;
    80000c1c:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000c1e:	fff6069b          	addiw	a3,a2,-1
    80000c22:	d27d                	beqz	a2,80000c08 <memmove+0x2a>
    80000c24:	02069613          	slli	a2,a3,0x20
    80000c28:	9201                	srli	a2,a2,0x20
    80000c2a:	fff64613          	not	a2,a2
    80000c2e:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000c30:	17fd                	addi	a5,a5,-1
    80000c32:	177d                	addi	a4,a4,-1
    80000c34:	0007c683          	lbu	a3,0(a5)
    80000c38:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000c3c:	fef61ae3          	bne	a2,a5,80000c30 <memmove+0x52>
    80000c40:	b7e1                	j	80000c08 <memmove+0x2a>

0000000080000c42 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000c42:	1141                	addi	sp,sp,-16
    80000c44:	e406                	sd	ra,8(sp)
    80000c46:	e022                	sd	s0,0(sp)
    80000c48:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000c4a:	00000097          	auipc	ra,0x0
    80000c4e:	f94080e7          	jalr	-108(ra) # 80000bde <memmove>
}
    80000c52:	60a2                	ld	ra,8(sp)
    80000c54:	6402                	ld	s0,0(sp)
    80000c56:	0141                	addi	sp,sp,16
    80000c58:	8082                	ret

0000000080000c5a <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000c5a:	1141                	addi	sp,sp,-16
    80000c5c:	e422                	sd	s0,8(sp)
    80000c5e:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000c60:	ce11                	beqz	a2,80000c7c <strncmp+0x22>
    80000c62:	00054783          	lbu	a5,0(a0)
    80000c66:	cf89                	beqz	a5,80000c80 <strncmp+0x26>
    80000c68:	0005c703          	lbu	a4,0(a1)
    80000c6c:	00f71a63          	bne	a4,a5,80000c80 <strncmp+0x26>
    n--, p++, q++;
    80000c70:	367d                	addiw	a2,a2,-1
    80000c72:	0505                	addi	a0,a0,1
    80000c74:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000c76:	f675                	bnez	a2,80000c62 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000c78:	4501                	li	a0,0
    80000c7a:	a809                	j	80000c8c <strncmp+0x32>
    80000c7c:	4501                	li	a0,0
    80000c7e:	a039                	j	80000c8c <strncmp+0x32>
  if(n == 0)
    80000c80:	ca09                	beqz	a2,80000c92 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000c82:	00054503          	lbu	a0,0(a0)
    80000c86:	0005c783          	lbu	a5,0(a1)
    80000c8a:	9d1d                	subw	a0,a0,a5
}
    80000c8c:	6422                	ld	s0,8(sp)
    80000c8e:	0141                	addi	sp,sp,16
    80000c90:	8082                	ret
    return 0;
    80000c92:	4501                	li	a0,0
    80000c94:	bfe5                	j	80000c8c <strncmp+0x32>

0000000080000c96 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000c96:	1141                	addi	sp,sp,-16
    80000c98:	e422                	sd	s0,8(sp)
    80000c9a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000c9c:	872a                	mv	a4,a0
    80000c9e:	8832                	mv	a6,a2
    80000ca0:	367d                	addiw	a2,a2,-1
    80000ca2:	01005963          	blez	a6,80000cb4 <strncpy+0x1e>
    80000ca6:	0705                	addi	a4,a4,1
    80000ca8:	0005c783          	lbu	a5,0(a1)
    80000cac:	fef70fa3          	sb	a5,-1(a4)
    80000cb0:	0585                	addi	a1,a1,1
    80000cb2:	f7f5                	bnez	a5,80000c9e <strncpy+0x8>
    ;
  while(n-- > 0)
    80000cb4:	86ba                	mv	a3,a4
    80000cb6:	00c05c63          	blez	a2,80000cce <strncpy+0x38>
    *s++ = 0;
    80000cba:	0685                	addi	a3,a3,1
    80000cbc:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000cc0:	fff6c793          	not	a5,a3
    80000cc4:	9fb9                	addw	a5,a5,a4
    80000cc6:	010787bb          	addw	a5,a5,a6
    80000cca:	fef048e3          	bgtz	a5,80000cba <strncpy+0x24>
  return os;
}
    80000cce:	6422                	ld	s0,8(sp)
    80000cd0:	0141                	addi	sp,sp,16
    80000cd2:	8082                	ret

0000000080000cd4 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000cd4:	1141                	addi	sp,sp,-16
    80000cd6:	e422                	sd	s0,8(sp)
    80000cd8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000cda:	02c05363          	blez	a2,80000d00 <safestrcpy+0x2c>
    80000cde:	fff6069b          	addiw	a3,a2,-1
    80000ce2:	1682                	slli	a3,a3,0x20
    80000ce4:	9281                	srli	a3,a3,0x20
    80000ce6:	96ae                	add	a3,a3,a1
    80000ce8:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000cea:	00d58963          	beq	a1,a3,80000cfc <safestrcpy+0x28>
    80000cee:	0585                	addi	a1,a1,1
    80000cf0:	0785                	addi	a5,a5,1
    80000cf2:	fff5c703          	lbu	a4,-1(a1)
    80000cf6:	fee78fa3          	sb	a4,-1(a5)
    80000cfa:	fb65                	bnez	a4,80000cea <safestrcpy+0x16>
    ;
  *s = 0;
    80000cfc:	00078023          	sb	zero,0(a5)
  return os;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <strlen>:

int
strlen(const char *s)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000d0c:	00054783          	lbu	a5,0(a0)
    80000d10:	cf91                	beqz	a5,80000d2c <strlen+0x26>
    80000d12:	0505                	addi	a0,a0,1
    80000d14:	87aa                	mv	a5,a0
    80000d16:	4685                	li	a3,1
    80000d18:	9e89                	subw	a3,a3,a0
    80000d1a:	00f6853b          	addw	a0,a3,a5
    80000d1e:	0785                	addi	a5,a5,1
    80000d20:	fff7c703          	lbu	a4,-1(a5)
    80000d24:	fb7d                	bnez	a4,80000d1a <strlen+0x14>
    ;
  return n;
}
    80000d26:	6422                	ld	s0,8(sp)
    80000d28:	0141                	addi	sp,sp,16
    80000d2a:	8082                	ret
  for(n = 0; s[n]; n++)
    80000d2c:	4501                	li	a0,0
    80000d2e:	bfe5                	j	80000d26 <strlen+0x20>

0000000080000d30 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000d30:	1141                	addi	sp,sp,-16
    80000d32:	e406                	sd	ra,8(sp)
    80000d34:	e022                	sd	s0,0(sp)
    80000d36:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000d38:	00001097          	auipc	ra,0x1
    80000d3c:	c84080e7          	jalr	-892(ra) # 800019bc <cpuid>
    virtio_disk_init(minor(ROOTDEV)); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000d40:	00029717          	auipc	a4,0x29
    80000d44:	2e870713          	addi	a4,a4,744 # 8002a028 <started>
  if(cpuid() == 0){
    80000d48:	c139                	beqz	a0,80000d8e <main+0x5e>
    while(started == 0)
    80000d4a:	431c                	lw	a5,0(a4)
    80000d4c:	2781                	sext.w	a5,a5
    80000d4e:	dff5                	beqz	a5,80000d4a <main+0x1a>
      ;
    __sync_synchronize();
    80000d50:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000d54:	00001097          	auipc	ra,0x1
    80000d58:	c68080e7          	jalr	-920(ra) # 800019bc <cpuid>
    80000d5c:	85aa                	mv	a1,a0
    80000d5e:	00007517          	auipc	a0,0x7
    80000d62:	44250513          	addi	a0,a0,1090 # 800081a0 <userret+0x110>
    80000d66:	00000097          	auipc	ra,0x0
    80000d6a:	82c080e7          	jalr	-2004(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000d6e:	00000097          	auipc	ra,0x0
    80000d72:	1ea080e7          	jalr	490(ra) # 80000f58 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000d76:	00002097          	auipc	ra,0x2
    80000d7a:	890080e7          	jalr	-1904(ra) # 80002606 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000d7e:	00005097          	auipc	ra,0x5
    80000d82:	1d2080e7          	jalr	466(ra) # 80005f50 <plicinithart>
  }

  scheduler();        
    80000d86:	00001097          	auipc	ra,0x1
    80000d8a:	140080e7          	jalr	320(ra) # 80001ec6 <scheduler>
    consoleinit();
    80000d8e:	fffff097          	auipc	ra,0xfffff
    80000d92:	6cc080e7          	jalr	1740(ra) # 8000045a <consoleinit>
    printfinit();
    80000d96:	00000097          	auipc	ra,0x0
    80000d9a:	9dc080e7          	jalr	-1572(ra) # 80000772 <printfinit>
    printf("\n");
    80000d9e:	00007517          	auipc	a0,0x7
    80000da2:	41250513          	addi	a0,a0,1042 # 800081b0 <userret+0x120>
    80000da6:	fffff097          	auipc	ra,0xfffff
    80000daa:	7ec080e7          	jalr	2028(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000dae:	00007517          	auipc	a0,0x7
    80000db2:	3da50513          	addi	a0,a0,986 # 80008188 <userret+0xf8>
    80000db6:	fffff097          	auipc	ra,0xfffff
    80000dba:	7dc080e7          	jalr	2012(ra) # 80000592 <printf>
    printf("\n");
    80000dbe:	00007517          	auipc	a0,0x7
    80000dc2:	3f250513          	addi	a0,a0,1010 # 800081b0 <userret+0x120>
    80000dc6:	fffff097          	auipc	ra,0xfffff
    80000dca:	7cc080e7          	jalr	1996(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000dce:	00000097          	auipc	ra,0x0
    80000dd2:	b46080e7          	jalr	-1210(ra) # 80000914 <kinit>
    kvminit();       // create kernel page table
    80000dd6:	00000097          	auipc	ra,0x0
    80000dda:	30c080e7          	jalr	780(ra) # 800010e2 <kvminit>
    kvminithart();   // turn on paging
    80000dde:	00000097          	auipc	ra,0x0
    80000de2:	17a080e7          	jalr	378(ra) # 80000f58 <kvminithart>
    procinit();      // process table
    80000de6:	00001097          	auipc	ra,0x1
    80000dea:	b06080e7          	jalr	-1274(ra) # 800018ec <procinit>
    trapinit();      // trap vectors
    80000dee:	00001097          	auipc	ra,0x1
    80000df2:	7f0080e7          	jalr	2032(ra) # 800025de <trapinit>
    trapinithart();  // install kernel trap vector
    80000df6:	00002097          	auipc	ra,0x2
    80000dfa:	810080e7          	jalr	-2032(ra) # 80002606 <trapinithart>
    plicinit();      // set up interrupt controller
    80000dfe:	00005097          	auipc	ra,0x5
    80000e02:	13c080e7          	jalr	316(ra) # 80005f3a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000e06:	00005097          	auipc	ra,0x5
    80000e0a:	14a080e7          	jalr	330(ra) # 80005f50 <plicinithart>
    binit();         // buffer cache
    80000e0e:	00002097          	auipc	ra,0x2
    80000e12:	006080e7          	jalr	6(ra) # 80002e14 <binit>
    iinit();         // inode cache
    80000e16:	00002097          	auipc	ra,0x2
    80000e1a:	69c080e7          	jalr	1692(ra) # 800034b2 <iinit>
    fileinit();      // file table
    80000e1e:	00004097          	auipc	ra,0x4
    80000e22:	878080e7          	jalr	-1928(ra) # 80004696 <fileinit>
    virtio_disk_init(minor(ROOTDEV)); // emulated hard disk
    80000e26:	4501                	li	a0,0
    80000e28:	00005097          	auipc	ra,0x5
    80000e2c:	25c080e7          	jalr	604(ra) # 80006084 <virtio_disk_init>
    userinit();      // first user process
    80000e30:	00001097          	auipc	ra,0x1
    80000e34:	e2c080e7          	jalr	-468(ra) # 80001c5c <userinit>
    __sync_synchronize();
    80000e38:	0ff0000f          	fence
    started = 1;
    80000e3c:	4785                	li	a5,1
    80000e3e:	00029717          	auipc	a4,0x29
    80000e42:	1ef72523          	sw	a5,490(a4) # 8002a028 <started>
    80000e46:	b781                	j	80000d86 <main+0x56>

0000000080000e48 <walk>:
//   21..39 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..12 -- 12 bits of byte offset within the page.
static pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000e48:	7139                	addi	sp,sp,-64
    80000e4a:	fc06                	sd	ra,56(sp)
    80000e4c:	f822                	sd	s0,48(sp)
    80000e4e:	f426                	sd	s1,40(sp)
    80000e50:	f04a                	sd	s2,32(sp)
    80000e52:	ec4e                	sd	s3,24(sp)
    80000e54:	e852                	sd	s4,16(sp)
    80000e56:	e456                	sd	s5,8(sp)
    80000e58:	e05a                	sd	s6,0(sp)
    80000e5a:	0080                	addi	s0,sp,64
    80000e5c:	84aa                	mv	s1,a0
    80000e5e:	89ae                	mv	s3,a1
    80000e60:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000e62:	57fd                	li	a5,-1
    80000e64:	83e9                	srli	a5,a5,0x1a
    80000e66:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000e68:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000e6a:	04b7f263          	bgeu	a5,a1,80000eae <walk+0x66>
    panic("walk");
    80000e6e:	00007517          	auipc	a0,0x7
    80000e72:	34a50513          	addi	a0,a0,842 # 800081b8 <userret+0x128>
    80000e76:	fffff097          	auipc	ra,0xfffff
    80000e7a:	6d2080e7          	jalr	1746(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000e7e:	060a8663          	beqz	s5,80000eea <walk+0xa2>
    80000e82:	00000097          	auipc	ra,0x0
    80000e86:	ace080e7          	jalr	-1330(ra) # 80000950 <kalloc>
    80000e8a:	84aa                	mv	s1,a0
    80000e8c:	c529                	beqz	a0,80000ed6 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000e8e:	6605                	lui	a2,0x1
    80000e90:	4581                	li	a1,0
    80000e92:	00000097          	auipc	ra,0x0
    80000e96:	cf0080e7          	jalr	-784(ra) # 80000b82 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000e9a:	00c4d793          	srli	a5,s1,0xc
    80000e9e:	07aa                	slli	a5,a5,0xa
    80000ea0:	0017e793          	ori	a5,a5,1
    80000ea4:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80000ea8:	3a5d                	addiw	s4,s4,-9
    80000eaa:	036a0063          	beq	s4,s6,80000eca <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80000eae:	0149d933          	srl	s2,s3,s4
    80000eb2:	1ff97913          	andi	s2,s2,511
    80000eb6:	090e                	slli	s2,s2,0x3
    80000eb8:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80000eba:	00093483          	ld	s1,0(s2)
    80000ebe:	0014f793          	andi	a5,s1,1
    80000ec2:	dfd5                	beqz	a5,80000e7e <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80000ec4:	80a9                	srli	s1,s1,0xa
    80000ec6:	04b2                	slli	s1,s1,0xc
    80000ec8:	b7c5                	j	80000ea8 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80000eca:	00c9d513          	srli	a0,s3,0xc
    80000ece:	1ff57513          	andi	a0,a0,511
    80000ed2:	050e                	slli	a0,a0,0x3
    80000ed4:	9526                	add	a0,a0,s1
}
    80000ed6:	70e2                	ld	ra,56(sp)
    80000ed8:	7442                	ld	s0,48(sp)
    80000eda:	74a2                	ld	s1,40(sp)
    80000edc:	7902                	ld	s2,32(sp)
    80000ede:	69e2                	ld	s3,24(sp)
    80000ee0:	6a42                	ld	s4,16(sp)
    80000ee2:	6aa2                	ld	s5,8(sp)
    80000ee4:	6b02                	ld	s6,0(sp)
    80000ee6:	6121                	addi	sp,sp,64
    80000ee8:	8082                	ret
        return 0;
    80000eea:	4501                	li	a0,0
    80000eec:	b7ed                	j	80000ed6 <walk+0x8e>

0000000080000eee <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
static void
freewalk(pagetable_t pagetable)
{
    80000eee:	7179                	addi	sp,sp,-48
    80000ef0:	f406                	sd	ra,40(sp)
    80000ef2:	f022                	sd	s0,32(sp)
    80000ef4:	ec26                	sd	s1,24(sp)
    80000ef6:	e84a                	sd	s2,16(sp)
    80000ef8:	e44e                	sd	s3,8(sp)
    80000efa:	e052                	sd	s4,0(sp)
    80000efc:	1800                	addi	s0,sp,48
    80000efe:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80000f00:	84aa                	mv	s1,a0
    80000f02:	6905                	lui	s2,0x1
    80000f04:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80000f06:	4985                	li	s3,1
    80000f08:	a821                	j	80000f20 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80000f0a:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80000f0c:	0532                	slli	a0,a0,0xc
    80000f0e:	00000097          	auipc	ra,0x0
    80000f12:	fe0080e7          	jalr	-32(ra) # 80000eee <freewalk>
      pagetable[i] = 0;
    80000f16:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80000f1a:	04a1                	addi	s1,s1,8
    80000f1c:	03248163          	beq	s1,s2,80000f3e <freewalk+0x50>
    pte_t pte = pagetable[i];
    80000f20:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80000f22:	00f57793          	andi	a5,a0,15
    80000f26:	ff3782e3          	beq	a5,s3,80000f0a <freewalk+0x1c>
    } else if(pte & PTE_V){
    80000f2a:	8905                	andi	a0,a0,1
    80000f2c:	d57d                	beqz	a0,80000f1a <freewalk+0x2c>
      panic("freewalk: leaf");
    80000f2e:	00007517          	auipc	a0,0x7
    80000f32:	29250513          	addi	a0,a0,658 # 800081c0 <userret+0x130>
    80000f36:	fffff097          	auipc	ra,0xfffff
    80000f3a:	612080e7          	jalr	1554(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    80000f3e:	8552                	mv	a0,s4
    80000f40:	00000097          	auipc	ra,0x0
    80000f44:	914080e7          	jalr	-1772(ra) # 80000854 <kfree>
}
    80000f48:	70a2                	ld	ra,40(sp)
    80000f4a:	7402                	ld	s0,32(sp)
    80000f4c:	64e2                	ld	s1,24(sp)
    80000f4e:	6942                	ld	s2,16(sp)
    80000f50:	69a2                	ld	s3,8(sp)
    80000f52:	6a02                	ld	s4,0(sp)
    80000f54:	6145                	addi	sp,sp,48
    80000f56:	8082                	ret

0000000080000f58 <kvminithart>:
{
    80000f58:	1141                	addi	sp,sp,-16
    80000f5a:	e422                	sd	s0,8(sp)
    80000f5c:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000f5e:	00029797          	auipc	a5,0x29
    80000f62:	0d27b783          	ld	a5,210(a5) # 8002a030 <kernel_pagetable>
    80000f66:	83b1                	srli	a5,a5,0xc
    80000f68:	577d                	li	a4,-1
    80000f6a:	177e                	slli	a4,a4,0x3f
    80000f6c:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f6e:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f72:	12000073          	sfence.vma
}
    80000f76:	6422                	ld	s0,8(sp)
    80000f78:	0141                	addi	sp,sp,16
    80000f7a:	8082                	ret

0000000080000f7c <walkaddr>:
  if(va >= MAXVA)
    80000f7c:	57fd                	li	a5,-1
    80000f7e:	83e9                	srli	a5,a5,0x1a
    80000f80:	00b7f463          	bgeu	a5,a1,80000f88 <walkaddr+0xc>
    return 0;
    80000f84:	4501                	li	a0,0
}
    80000f86:	8082                	ret
{
    80000f88:	1141                	addi	sp,sp,-16
    80000f8a:	e406                	sd	ra,8(sp)
    80000f8c:	e022                	sd	s0,0(sp)
    80000f8e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80000f90:	4601                	li	a2,0
    80000f92:	00000097          	auipc	ra,0x0
    80000f96:	eb6080e7          	jalr	-330(ra) # 80000e48 <walk>
  if(pte == 0)
    80000f9a:	c105                	beqz	a0,80000fba <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80000f9c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80000f9e:	0117f693          	andi	a3,a5,17
    80000fa2:	4745                	li	a4,17
    return 0;
    80000fa4:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80000fa6:	00e68663          	beq	a3,a4,80000fb2 <walkaddr+0x36>
}
    80000faa:	60a2                	ld	ra,8(sp)
    80000fac:	6402                	ld	s0,0(sp)
    80000fae:	0141                	addi	sp,sp,16
    80000fb0:	8082                	ret
  pa = PTE2PA(*pte);
    80000fb2:	00a7d513          	srli	a0,a5,0xa
    80000fb6:	0532                	slli	a0,a0,0xc
  return pa;
    80000fb8:	bfcd                	j	80000faa <walkaddr+0x2e>
    return 0;
    80000fba:	4501                	li	a0,0
    80000fbc:	b7fd                	j	80000faa <walkaddr+0x2e>

0000000080000fbe <kvmpa>:
{
    80000fbe:	1101                	addi	sp,sp,-32
    80000fc0:	ec06                	sd	ra,24(sp)
    80000fc2:	e822                	sd	s0,16(sp)
    80000fc4:	e426                	sd	s1,8(sp)
    80000fc6:	1000                	addi	s0,sp,32
    80000fc8:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    80000fca:	1552                	slli	a0,a0,0x34
    80000fcc:	03455493          	srli	s1,a0,0x34
  pte = walk(kernel_pagetable, va, 0);
    80000fd0:	4601                	li	a2,0
    80000fd2:	00029517          	auipc	a0,0x29
    80000fd6:	05e53503          	ld	a0,94(a0) # 8002a030 <kernel_pagetable>
    80000fda:	00000097          	auipc	ra,0x0
    80000fde:	e6e080e7          	jalr	-402(ra) # 80000e48 <walk>
  if(pte == 0)
    80000fe2:	cd09                	beqz	a0,80000ffc <kvmpa+0x3e>
  if((*pte & PTE_V) == 0)
    80000fe4:	6108                	ld	a0,0(a0)
    80000fe6:	00157793          	andi	a5,a0,1
    80000fea:	c38d                	beqz	a5,8000100c <kvmpa+0x4e>
  pa = PTE2PA(*pte);
    80000fec:	8129                	srli	a0,a0,0xa
    80000fee:	0532                	slli	a0,a0,0xc
}
    80000ff0:	9526                	add	a0,a0,s1
    80000ff2:	60e2                	ld	ra,24(sp)
    80000ff4:	6442                	ld	s0,16(sp)
    80000ff6:	64a2                	ld	s1,8(sp)
    80000ff8:	6105                	addi	sp,sp,32
    80000ffa:	8082                	ret
    panic("kvmpa");
    80000ffc:	00007517          	auipc	a0,0x7
    80001000:	1d450513          	addi	a0,a0,468 # 800081d0 <userret+0x140>
    80001004:	fffff097          	auipc	ra,0xfffff
    80001008:	544080e7          	jalr	1348(ra) # 80000548 <panic>
    panic("kvmpa");
    8000100c:	00007517          	auipc	a0,0x7
    80001010:	1c450513          	addi	a0,a0,452 # 800081d0 <userret+0x140>
    80001014:	fffff097          	auipc	ra,0xfffff
    80001018:	534080e7          	jalr	1332(ra) # 80000548 <panic>

000000008000101c <mappages>:
{
    8000101c:	715d                	addi	sp,sp,-80
    8000101e:	e486                	sd	ra,72(sp)
    80001020:	e0a2                	sd	s0,64(sp)
    80001022:	fc26                	sd	s1,56(sp)
    80001024:	f84a                	sd	s2,48(sp)
    80001026:	f44e                	sd	s3,40(sp)
    80001028:	f052                	sd	s4,32(sp)
    8000102a:	ec56                	sd	s5,24(sp)
    8000102c:	e85a                	sd	s6,16(sp)
    8000102e:	e45e                	sd	s7,8(sp)
    80001030:	0880                	addi	s0,sp,80
    80001032:	8aaa                	mv	s5,a0
    80001034:	8b3a                	mv	s6,a4
  a = PGROUNDDOWN(va);
    80001036:	777d                	lui	a4,0xfffff
    80001038:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000103c:	167d                	addi	a2,a2,-1
    8000103e:	00b609b3          	add	s3,a2,a1
    80001042:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001046:	893e                	mv	s2,a5
    80001048:	40f68a33          	sub	s4,a3,a5
    a += PGSIZE;
    8000104c:	6b85                	lui	s7,0x1
    8000104e:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001052:	4605                	li	a2,1
    80001054:	85ca                	mv	a1,s2
    80001056:	8556                	mv	a0,s5
    80001058:	00000097          	auipc	ra,0x0
    8000105c:	df0080e7          	jalr	-528(ra) # 80000e48 <walk>
    80001060:	c51d                	beqz	a0,8000108e <mappages+0x72>
    if(*pte & PTE_V)
    80001062:	611c                	ld	a5,0(a0)
    80001064:	8b85                	andi	a5,a5,1
    80001066:	ef81                	bnez	a5,8000107e <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001068:	80b1                	srli	s1,s1,0xc
    8000106a:	04aa                	slli	s1,s1,0xa
    8000106c:	0164e4b3          	or	s1,s1,s6
    80001070:	0014e493          	ori	s1,s1,1
    80001074:	e104                	sd	s1,0(a0)
    if(a == last)
    80001076:	03390863          	beq	s2,s3,800010a6 <mappages+0x8a>
    a += PGSIZE;
    8000107a:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000107c:	bfc9                	j	8000104e <mappages+0x32>
      panic("remap");
    8000107e:	00007517          	auipc	a0,0x7
    80001082:	15a50513          	addi	a0,a0,346 # 800081d8 <userret+0x148>
    80001086:	fffff097          	auipc	ra,0xfffff
    8000108a:	4c2080e7          	jalr	1218(ra) # 80000548 <panic>
      return -1;
    8000108e:	557d                	li	a0,-1
}
    80001090:	60a6                	ld	ra,72(sp)
    80001092:	6406                	ld	s0,64(sp)
    80001094:	74e2                	ld	s1,56(sp)
    80001096:	7942                	ld	s2,48(sp)
    80001098:	79a2                	ld	s3,40(sp)
    8000109a:	7a02                	ld	s4,32(sp)
    8000109c:	6ae2                	ld	s5,24(sp)
    8000109e:	6b42                	ld	s6,16(sp)
    800010a0:	6ba2                	ld	s7,8(sp)
    800010a2:	6161                	addi	sp,sp,80
    800010a4:	8082                	ret
  return 0;
    800010a6:	4501                	li	a0,0
    800010a8:	b7e5                	j	80001090 <mappages+0x74>

00000000800010aa <kvmmap>:
{
    800010aa:	1141                	addi	sp,sp,-16
    800010ac:	e406                	sd	ra,8(sp)
    800010ae:	e022                	sd	s0,0(sp)
    800010b0:	0800                	addi	s0,sp,16
    800010b2:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800010b4:	86ae                	mv	a3,a1
    800010b6:	85aa                	mv	a1,a0
    800010b8:	00029517          	auipc	a0,0x29
    800010bc:	f7853503          	ld	a0,-136(a0) # 8002a030 <kernel_pagetable>
    800010c0:	00000097          	auipc	ra,0x0
    800010c4:	f5c080e7          	jalr	-164(ra) # 8000101c <mappages>
    800010c8:	e509                	bnez	a0,800010d2 <kvmmap+0x28>
}
    800010ca:	60a2                	ld	ra,8(sp)
    800010cc:	6402                	ld	s0,0(sp)
    800010ce:	0141                	addi	sp,sp,16
    800010d0:	8082                	ret
    panic("kvmmap");
    800010d2:	00007517          	auipc	a0,0x7
    800010d6:	10e50513          	addi	a0,a0,270 # 800081e0 <userret+0x150>
    800010da:	fffff097          	auipc	ra,0xfffff
    800010de:	46e080e7          	jalr	1134(ra) # 80000548 <panic>

00000000800010e2 <kvminit>:
{
    800010e2:	1101                	addi	sp,sp,-32
    800010e4:	ec06                	sd	ra,24(sp)
    800010e6:	e822                	sd	s0,16(sp)
    800010e8:	e426                	sd	s1,8(sp)
    800010ea:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    800010ec:	00000097          	auipc	ra,0x0
    800010f0:	864080e7          	jalr	-1948(ra) # 80000950 <kalloc>
    800010f4:	00029797          	auipc	a5,0x29
    800010f8:	f2a7be23          	sd	a0,-196(a5) # 8002a030 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    800010fc:	6605                	lui	a2,0x1
    800010fe:	4581                	li	a1,0
    80001100:	00000097          	auipc	ra,0x0
    80001104:	a82080e7          	jalr	-1406(ra) # 80000b82 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001108:	4699                	li	a3,6
    8000110a:	6605                	lui	a2,0x1
    8000110c:	100005b7          	lui	a1,0x10000
    80001110:	10000537          	lui	a0,0x10000
    80001114:	00000097          	auipc	ra,0x0
    80001118:	f96080e7          	jalr	-106(ra) # 800010aa <kvmmap>
  kvmmap(VIRTION(0), VIRTION(0), PGSIZE, PTE_R | PTE_W);
    8000111c:	4699                	li	a3,6
    8000111e:	6605                	lui	a2,0x1
    80001120:	100015b7          	lui	a1,0x10001
    80001124:	10001537          	lui	a0,0x10001
    80001128:	00000097          	auipc	ra,0x0
    8000112c:	f82080e7          	jalr	-126(ra) # 800010aa <kvmmap>
  kvmmap(VIRTION(1), VIRTION(1), PGSIZE, PTE_R | PTE_W);
    80001130:	4699                	li	a3,6
    80001132:	6605                	lui	a2,0x1
    80001134:	100025b7          	lui	a1,0x10002
    80001138:	10002537          	lui	a0,0x10002
    8000113c:	00000097          	auipc	ra,0x0
    80001140:	f6e080e7          	jalr	-146(ra) # 800010aa <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    80001144:	4699                	li	a3,6
    80001146:	6641                	lui	a2,0x10
    80001148:	020005b7          	lui	a1,0x2000
    8000114c:	02000537          	lui	a0,0x2000
    80001150:	00000097          	auipc	ra,0x0
    80001154:	f5a080e7          	jalr	-166(ra) # 800010aa <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001158:	4699                	li	a3,6
    8000115a:	00400637          	lui	a2,0x400
    8000115e:	0c0005b7          	lui	a1,0xc000
    80001162:	0c000537          	lui	a0,0xc000
    80001166:	00000097          	auipc	ra,0x0
    8000116a:	f44080e7          	jalr	-188(ra) # 800010aa <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000116e:	00008497          	auipc	s1,0x8
    80001172:	e9248493          	addi	s1,s1,-366 # 80009000 <initcode>
    80001176:	46a9                	li	a3,10
    80001178:	80008617          	auipc	a2,0x80008
    8000117c:	e8860613          	addi	a2,a2,-376 # 9000 <_entry-0x7fff7000>
    80001180:	4585                	li	a1,1
    80001182:	05fe                	slli	a1,a1,0x1f
    80001184:	852e                	mv	a0,a1
    80001186:	00000097          	auipc	ra,0x0
    8000118a:	f24080e7          	jalr	-220(ra) # 800010aa <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000118e:	4699                	li	a3,6
    80001190:	4645                	li	a2,17
    80001192:	066e                	slli	a2,a2,0x1b
    80001194:	8e05                	sub	a2,a2,s1
    80001196:	85a6                	mv	a1,s1
    80001198:	8526                	mv	a0,s1
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	f10080e7          	jalr	-240(ra) # 800010aa <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800011a2:	46a9                	li	a3,10
    800011a4:	6605                	lui	a2,0x1
    800011a6:	00007597          	auipc	a1,0x7
    800011aa:	e5a58593          	addi	a1,a1,-422 # 80008000 <trampoline>
    800011ae:	04000537          	lui	a0,0x4000
    800011b2:	157d                	addi	a0,a0,-1
    800011b4:	0532                	slli	a0,a0,0xc
    800011b6:	00000097          	auipc	ra,0x0
    800011ba:	ef4080e7          	jalr	-268(ra) # 800010aa <kvmmap>
}
    800011be:	60e2                	ld	ra,24(sp)
    800011c0:	6442                	ld	s0,16(sp)
    800011c2:	64a2                	ld	s1,8(sp)
    800011c4:	6105                	addi	sp,sp,32
    800011c6:	8082                	ret

00000000800011c8 <uvmunmap>:
{
    800011c8:	715d                	addi	sp,sp,-80
    800011ca:	e486                	sd	ra,72(sp)
    800011cc:	e0a2                	sd	s0,64(sp)
    800011ce:	fc26                	sd	s1,56(sp)
    800011d0:	f84a                	sd	s2,48(sp)
    800011d2:	f44e                	sd	s3,40(sp)
    800011d4:	f052                	sd	s4,32(sp)
    800011d6:	ec56                	sd	s5,24(sp)
    800011d8:	e85a                	sd	s6,16(sp)
    800011da:	e45e                	sd	s7,8(sp)
    800011dc:	0880                	addi	s0,sp,80
    800011de:	8a2a                	mv	s4,a0
    800011e0:	8b36                	mv	s6,a3
  a = PGROUNDDOWN(va);
    800011e2:	77fd                	lui	a5,0xfffff
    800011e4:	00f5f933          	and	s2,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800011e8:	167d                	addi	a2,a2,-1
    800011ea:	00b609b3          	add	s3,a2,a1
    800011ee:	00f9f9b3          	and	s3,s3,a5
    if(PTE_FLAGS(*pte) == PTE_V)
    800011f2:	4b85                	li	s7,1
    a += PGSIZE;
    800011f4:	6a85                	lui	s5,0x1
    800011f6:	a831                	j	80001212 <uvmunmap+0x4a>
      panic("uvmunmap: not a leaf");
    800011f8:	00007517          	auipc	a0,0x7
    800011fc:	ff050513          	addi	a0,a0,-16 # 800081e8 <userret+0x158>
    80001200:	fffff097          	auipc	ra,0xfffff
    80001204:	348080e7          	jalr	840(ra) # 80000548 <panic>
    *pte = 0;
    80001208:	0004b023          	sd	zero,0(s1)
    if(a == last)
    8000120c:	03390e63          	beq	s2,s3,80001248 <uvmunmap+0x80>
    a += PGSIZE;
    80001210:	9956                	add	s2,s2,s5
    if((pte = walk(pagetable, a, 0)) == 0){
    80001212:	4601                	li	a2,0
    80001214:	85ca                	mv	a1,s2
    80001216:	8552                	mv	a0,s4
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	c30080e7          	jalr	-976(ra) # 80000e48 <walk>
    80001220:	84aa                	mv	s1,a0
    80001222:	d56d                	beqz	a0,8000120c <uvmunmap+0x44>
    if((*pte & PTE_V) == 0){
    80001224:	611c                	ld	a5,0(a0)
    if(PTE_FLAGS(*pte) == PTE_V)
    80001226:	3ff7f713          	andi	a4,a5,1023
    8000122a:	fd7707e3          	beq	a4,s7,800011f8 <uvmunmap+0x30>
    if(do_free && ((*pte & PTE_V) != 0)){
    8000122e:	fc0b0de3          	beqz	s6,80001208 <uvmunmap+0x40>
    if((*pte & PTE_V) == 0){
    80001232:	0017f713          	andi	a4,a5,1
    if(do_free && ((*pte & PTE_V) != 0)){
    80001236:	db69                	beqz	a4,80001208 <uvmunmap+0x40>
      pa = PTE2PA(*pte);
    80001238:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    8000123a:	00c79513          	slli	a0,a5,0xc
    8000123e:	fffff097          	auipc	ra,0xfffff
    80001242:	616080e7          	jalr	1558(ra) # 80000854 <kfree>
    80001246:	b7c9                	j	80001208 <uvmunmap+0x40>
}
    80001248:	60a6                	ld	ra,72(sp)
    8000124a:	6406                	ld	s0,64(sp)
    8000124c:	74e2                	ld	s1,56(sp)
    8000124e:	7942                	ld	s2,48(sp)
    80001250:	79a2                	ld	s3,40(sp)
    80001252:	7a02                	ld	s4,32(sp)
    80001254:	6ae2                	ld	s5,24(sp)
    80001256:	6b42                	ld	s6,16(sp)
    80001258:	6ba2                	ld	s7,8(sp)
    8000125a:	6161                	addi	sp,sp,80
    8000125c:	8082                	ret

000000008000125e <uvmcreate>:
{
    8000125e:	1101                	addi	sp,sp,-32
    80001260:	ec06                	sd	ra,24(sp)
    80001262:	e822                	sd	s0,16(sp)
    80001264:	e426                	sd	s1,8(sp)
    80001266:	1000                	addi	s0,sp,32
  pagetable = (pagetable_t) kalloc();
    80001268:	fffff097          	auipc	ra,0xfffff
    8000126c:	6e8080e7          	jalr	1768(ra) # 80000950 <kalloc>
  if(pagetable == 0)
    80001270:	cd11                	beqz	a0,8000128c <uvmcreate+0x2e>
    80001272:	84aa                	mv	s1,a0
  memset(pagetable, 0, PGSIZE);
    80001274:	6605                	lui	a2,0x1
    80001276:	4581                	li	a1,0
    80001278:	00000097          	auipc	ra,0x0
    8000127c:	90a080e7          	jalr	-1782(ra) # 80000b82 <memset>
}
    80001280:	8526                	mv	a0,s1
    80001282:	60e2                	ld	ra,24(sp)
    80001284:	6442                	ld	s0,16(sp)
    80001286:	64a2                	ld	s1,8(sp)
    80001288:	6105                	addi	sp,sp,32
    8000128a:	8082                	ret
    panic("uvmcreate: out of memory");
    8000128c:	00007517          	auipc	a0,0x7
    80001290:	f7450513          	addi	a0,a0,-140 # 80008200 <userret+0x170>
    80001294:	fffff097          	auipc	ra,0xfffff
    80001298:	2b4080e7          	jalr	692(ra) # 80000548 <panic>

000000008000129c <uvminit>:
{
    8000129c:	7179                	addi	sp,sp,-48
    8000129e:	f406                	sd	ra,40(sp)
    800012a0:	f022                	sd	s0,32(sp)
    800012a2:	ec26                	sd	s1,24(sp)
    800012a4:	e84a                	sd	s2,16(sp)
    800012a6:	e44e                	sd	s3,8(sp)
    800012a8:	e052                	sd	s4,0(sp)
    800012aa:	1800                	addi	s0,sp,48
  if(sz >= PGSIZE)
    800012ac:	6785                	lui	a5,0x1
    800012ae:	04f67863          	bgeu	a2,a5,800012fe <uvminit+0x62>
    800012b2:	8a2a                	mv	s4,a0
    800012b4:	89ae                	mv	s3,a1
    800012b6:	84b2                	mv	s1,a2
  mem = kalloc();
    800012b8:	fffff097          	auipc	ra,0xfffff
    800012bc:	698080e7          	jalr	1688(ra) # 80000950 <kalloc>
    800012c0:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800012c2:	6605                	lui	a2,0x1
    800012c4:	4581                	li	a1,0
    800012c6:	00000097          	auipc	ra,0x0
    800012ca:	8bc080e7          	jalr	-1860(ra) # 80000b82 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800012ce:	4779                	li	a4,30
    800012d0:	86ca                	mv	a3,s2
    800012d2:	6605                	lui	a2,0x1
    800012d4:	4581                	li	a1,0
    800012d6:	8552                	mv	a0,s4
    800012d8:	00000097          	auipc	ra,0x0
    800012dc:	d44080e7          	jalr	-700(ra) # 8000101c <mappages>
  memmove(mem, src, sz);
    800012e0:	8626                	mv	a2,s1
    800012e2:	85ce                	mv	a1,s3
    800012e4:	854a                	mv	a0,s2
    800012e6:	00000097          	auipc	ra,0x0
    800012ea:	8f8080e7          	jalr	-1800(ra) # 80000bde <memmove>
}
    800012ee:	70a2                	ld	ra,40(sp)
    800012f0:	7402                	ld	s0,32(sp)
    800012f2:	64e2                	ld	s1,24(sp)
    800012f4:	6942                	ld	s2,16(sp)
    800012f6:	69a2                	ld	s3,8(sp)
    800012f8:	6a02                	ld	s4,0(sp)
    800012fa:	6145                	addi	sp,sp,48
    800012fc:	8082                	ret
    panic("inituvm: more than a page");
    800012fe:	00007517          	auipc	a0,0x7
    80001302:	f2250513          	addi	a0,a0,-222 # 80008220 <userret+0x190>
    80001306:	fffff097          	auipc	ra,0xfffff
    8000130a:	242080e7          	jalr	578(ra) # 80000548 <panic>

000000008000130e <uvmdealloc>:
{
    8000130e:	1101                	addi	sp,sp,-32
    80001310:	ec06                	sd	ra,24(sp)
    80001312:	e822                	sd	s0,16(sp)
    80001314:	e426                	sd	s1,8(sp)
    80001316:	1000                	addi	s0,sp,32
    return oldsz;
    80001318:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000131a:	00b67d63          	bgeu	a2,a1,80001334 <uvmdealloc+0x26>
    8000131e:	84b2                	mv	s1,a2
  uint64 newup = PGROUNDUP(newsz);
    80001320:	6785                	lui	a5,0x1
    80001322:	17fd                	addi	a5,a5,-1
    80001324:	00f60733          	add	a4,a2,a5
    80001328:	76fd                	lui	a3,0xfffff
    8000132a:	8f75                	and	a4,a4,a3
  if(newup < PGROUNDUP(oldsz))
    8000132c:	97ae                	add	a5,a5,a1
    8000132e:	8ff5                	and	a5,a5,a3
    80001330:	00f76863          	bltu	a4,a5,80001340 <uvmdealloc+0x32>
}
    80001334:	8526                	mv	a0,s1
    80001336:	60e2                	ld	ra,24(sp)
    80001338:	6442                	ld	s0,16(sp)
    8000133a:	64a2                	ld	s1,8(sp)
    8000133c:	6105                	addi	sp,sp,32
    8000133e:	8082                	ret
    uvmunmap(pagetable, newup, oldsz - newup, 1);
    80001340:	4685                	li	a3,1
    80001342:	40e58633          	sub	a2,a1,a4
    80001346:	85ba                	mv	a1,a4
    80001348:	00000097          	auipc	ra,0x0
    8000134c:	e80080e7          	jalr	-384(ra) # 800011c8 <uvmunmap>
    80001350:	b7d5                	j	80001334 <uvmdealloc+0x26>

0000000080001352 <uvmalloc>:
  if(newsz < oldsz)
    80001352:	0ab66163          	bltu	a2,a1,800013f4 <uvmalloc+0xa2>
{
    80001356:	7139                	addi	sp,sp,-64
    80001358:	fc06                	sd	ra,56(sp)
    8000135a:	f822                	sd	s0,48(sp)
    8000135c:	f426                	sd	s1,40(sp)
    8000135e:	f04a                	sd	s2,32(sp)
    80001360:	ec4e                	sd	s3,24(sp)
    80001362:	e852                	sd	s4,16(sp)
    80001364:	e456                	sd	s5,8(sp)
    80001366:	0080                	addi	s0,sp,64
    80001368:	8aaa                	mv	s5,a0
    8000136a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000136c:	6985                	lui	s3,0x1
    8000136e:	19fd                	addi	s3,s3,-1
    80001370:	95ce                	add	a1,a1,s3
    80001372:	79fd                	lui	s3,0xfffff
    80001374:	0135f9b3          	and	s3,a1,s3
  for(; a < newsz; a += PGSIZE){
    80001378:	08c9f063          	bgeu	s3,a2,800013f8 <uvmalloc+0xa6>
  a = oldsz;
    8000137c:	894e                	mv	s2,s3
    mem = kalloc();
    8000137e:	fffff097          	auipc	ra,0xfffff
    80001382:	5d2080e7          	jalr	1490(ra) # 80000950 <kalloc>
    80001386:	84aa                	mv	s1,a0
    if(mem == 0){
    80001388:	c51d                	beqz	a0,800013b6 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000138a:	6605                	lui	a2,0x1
    8000138c:	4581                	li	a1,0
    8000138e:	fffff097          	auipc	ra,0xfffff
    80001392:	7f4080e7          	jalr	2036(ra) # 80000b82 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001396:	4779                	li	a4,30
    80001398:	86a6                	mv	a3,s1
    8000139a:	6605                	lui	a2,0x1
    8000139c:	85ca                	mv	a1,s2
    8000139e:	8556                	mv	a0,s5
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	c7c080e7          	jalr	-900(ra) # 8000101c <mappages>
    800013a8:	e905                	bnez	a0,800013d8 <uvmalloc+0x86>
  for(; a < newsz; a += PGSIZE){
    800013aa:	6785                	lui	a5,0x1
    800013ac:	993e                	add	s2,s2,a5
    800013ae:	fd4968e3          	bltu	s2,s4,8000137e <uvmalloc+0x2c>
  return newsz;
    800013b2:	8552                	mv	a0,s4
    800013b4:	a809                	j	800013c6 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800013b6:	864e                	mv	a2,s3
    800013b8:	85ca                	mv	a1,s2
    800013ba:	8556                	mv	a0,s5
    800013bc:	00000097          	auipc	ra,0x0
    800013c0:	f52080e7          	jalr	-174(ra) # 8000130e <uvmdealloc>
      return 0;
    800013c4:	4501                	li	a0,0
}
    800013c6:	70e2                	ld	ra,56(sp)
    800013c8:	7442                	ld	s0,48(sp)
    800013ca:	74a2                	ld	s1,40(sp)
    800013cc:	7902                	ld	s2,32(sp)
    800013ce:	69e2                	ld	s3,24(sp)
    800013d0:	6a42                	ld	s4,16(sp)
    800013d2:	6aa2                	ld	s5,8(sp)
    800013d4:	6121                	addi	sp,sp,64
    800013d6:	8082                	ret
      kfree(mem);
    800013d8:	8526                	mv	a0,s1
    800013da:	fffff097          	auipc	ra,0xfffff
    800013de:	47a080e7          	jalr	1146(ra) # 80000854 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800013e2:	864e                	mv	a2,s3
    800013e4:	85ca                	mv	a1,s2
    800013e6:	8556                	mv	a0,s5
    800013e8:	00000097          	auipc	ra,0x0
    800013ec:	f26080e7          	jalr	-218(ra) # 8000130e <uvmdealloc>
      return 0;
    800013f0:	4501                	li	a0,0
    800013f2:	bfd1                	j	800013c6 <uvmalloc+0x74>
    return oldsz;
    800013f4:	852e                	mv	a0,a1
}
    800013f6:	8082                	ret
  return newsz;
    800013f8:	8532                	mv	a0,a2
    800013fa:	b7f1                	j	800013c6 <uvmalloc+0x74>

00000000800013fc <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800013fc:	1101                	addi	sp,sp,-32
    800013fe:	ec06                	sd	ra,24(sp)
    80001400:	e822                	sd	s0,16(sp)
    80001402:	e426                	sd	s1,8(sp)
    80001404:	1000                	addi	s0,sp,32
    80001406:	84aa                	mv	s1,a0
    80001408:	862e                	mv	a2,a1
  uvmunmap(pagetable, 0, sz, 1);
    8000140a:	4685                	li	a3,1
    8000140c:	4581                	li	a1,0
    8000140e:	00000097          	auipc	ra,0x0
    80001412:	dba080e7          	jalr	-582(ra) # 800011c8 <uvmunmap>
  freewalk(pagetable);
    80001416:	8526                	mv	a0,s1
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	ad6080e7          	jalr	-1322(ra) # 80000eee <freewalk>
}
    80001420:	60e2                	ld	ra,24(sp)
    80001422:	6442                	ld	s0,16(sp)
    80001424:	64a2                	ld	s1,8(sp)
    80001426:	6105                	addi	sp,sp,32
    80001428:	8082                	ret

000000008000142a <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000142a:	ca45                	beqz	a2,800014da <uvmcopy+0xb0>
{
    8000142c:	715d                	addi	sp,sp,-80
    8000142e:	e486                	sd	ra,72(sp)
    80001430:	e0a2                	sd	s0,64(sp)
    80001432:	fc26                	sd	s1,56(sp)
    80001434:	f84a                	sd	s2,48(sp)
    80001436:	f44e                	sd	s3,40(sp)
    80001438:	f052                	sd	s4,32(sp)
    8000143a:	ec56                	sd	s5,24(sp)
    8000143c:	e85a                	sd	s6,16(sp)
    8000143e:	e45e                	sd	s7,8(sp)
    80001440:	0880                	addi	s0,sp,80
    80001442:	8aaa                	mv	s5,a0
    80001444:	8b2e                	mv	s6,a1
    80001446:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001448:	4481                	li	s1,0
    8000144a:	a029                	j	80001454 <uvmcopy+0x2a>
    8000144c:	6785                	lui	a5,0x1
    8000144e:	94be                	add	s1,s1,a5
    80001450:	0744f963          	bgeu	s1,s4,800014c2 <uvmcopy+0x98>
    if((pte = walk(old, i, 0)) == 0)
    80001454:	4601                	li	a2,0
    80001456:	85a6                	mv	a1,s1
    80001458:	8556                	mv	a0,s5
    8000145a:	00000097          	auipc	ra,0x0
    8000145e:	9ee080e7          	jalr	-1554(ra) # 80000e48 <walk>
    80001462:	d56d                	beqz	a0,8000144c <uvmcopy+0x22>
      // panic("uvmcopy: pte should exist");
      continue;
    if((*pte & PTE_V) == 0)
    80001464:	6118                	ld	a4,0(a0)
    80001466:	00177793          	andi	a5,a4,1
    8000146a:	d3ed                	beqz	a5,8000144c <uvmcopy+0x22>
      // panic("uvmcopy: page not present");
      continue;
    pa = PTE2PA(*pte);
    8000146c:	00a75593          	srli	a1,a4,0xa
    80001470:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001474:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    80001478:	fffff097          	auipc	ra,0xfffff
    8000147c:	4d8080e7          	jalr	1240(ra) # 80000950 <kalloc>
    80001480:	89aa                	mv	s3,a0
    80001482:	c515                	beqz	a0,800014ae <uvmcopy+0x84>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001484:	6605                	lui	a2,0x1
    80001486:	85de                	mv	a1,s7
    80001488:	fffff097          	auipc	ra,0xfffff
    8000148c:	756080e7          	jalr	1878(ra) # 80000bde <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001490:	874a                	mv	a4,s2
    80001492:	86ce                	mv	a3,s3
    80001494:	6605                	lui	a2,0x1
    80001496:	85a6                	mv	a1,s1
    80001498:	855a                	mv	a0,s6
    8000149a:	00000097          	auipc	ra,0x0
    8000149e:	b82080e7          	jalr	-1150(ra) # 8000101c <mappages>
    800014a2:	d54d                	beqz	a0,8000144c <uvmcopy+0x22>
      kfree(mem);
    800014a4:	854e                	mv	a0,s3
    800014a6:	fffff097          	auipc	ra,0xfffff
    800014aa:	3ae080e7          	jalr	942(ra) # 80000854 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i, 1);
    800014ae:	4685                	li	a3,1
    800014b0:	8626                	mv	a2,s1
    800014b2:	4581                	li	a1,0
    800014b4:	855a                	mv	a0,s6
    800014b6:	00000097          	auipc	ra,0x0
    800014ba:	d12080e7          	jalr	-750(ra) # 800011c8 <uvmunmap>
  return -1;
    800014be:	557d                	li	a0,-1
    800014c0:	a011                	j	800014c4 <uvmcopy+0x9a>
  return 0;
    800014c2:	4501                	li	a0,0
}
    800014c4:	60a6                	ld	ra,72(sp)
    800014c6:	6406                	ld	s0,64(sp)
    800014c8:	74e2                	ld	s1,56(sp)
    800014ca:	7942                	ld	s2,48(sp)
    800014cc:	79a2                	ld	s3,40(sp)
    800014ce:	7a02                	ld	s4,32(sp)
    800014d0:	6ae2                	ld	s5,24(sp)
    800014d2:	6b42                	ld	s6,16(sp)
    800014d4:	6ba2                	ld	s7,8(sp)
    800014d6:	6161                	addi	sp,sp,80
    800014d8:	8082                	ret
  return 0;
    800014da:	4501                	li	a0,0
}
    800014dc:	8082                	ret

00000000800014de <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800014de:	1141                	addi	sp,sp,-16
    800014e0:	e406                	sd	ra,8(sp)
    800014e2:	e022                	sd	s0,0(sp)
    800014e4:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800014e6:	4601                	li	a2,0
    800014e8:	00000097          	auipc	ra,0x0
    800014ec:	960080e7          	jalr	-1696(ra) # 80000e48 <walk>
  if(pte == 0)
    800014f0:	c901                	beqz	a0,80001500 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800014f2:	611c                	ld	a5,0(a0)
    800014f4:	9bbd                	andi	a5,a5,-17
    800014f6:	e11c                	sd	a5,0(a0)
}
    800014f8:	60a2                	ld	ra,8(sp)
    800014fa:	6402                	ld	s0,0(sp)
    800014fc:	0141                	addi	sp,sp,16
    800014fe:	8082                	ret
    panic("uvmclear");
    80001500:	00007517          	auipc	a0,0x7
    80001504:	d4050513          	addi	a0,a0,-704 # 80008240 <userret+0x1b0>
    80001508:	fffff097          	auipc	ra,0xfffff
    8000150c:	040080e7          	jalr	64(ra) # 80000548 <panic>

0000000080001510 <fill_user_addr>:

int 
fill_user_addr(uint64 addr, int len){
  uint64 va0, va1;

  if(len < 0) return -1;
    80001510:	0c05c463          	bltz	a1,800015d8 <fill_user_addr+0xc8>
fill_user_addr(uint64 addr, int len){
    80001514:	7139                	addi	sp,sp,-64
    80001516:	fc06                	sd	ra,56(sp)
    80001518:	f822                	sd	s0,48(sp)
    8000151a:	f426                	sd	s1,40(sp)
    8000151c:	f04a                	sd	s2,32(sp)
    8000151e:	ec4e                	sd	s3,24(sp)
    80001520:	e852                	sd	s4,16(sp)
    80001522:	e456                	sd	s5,8(sp)
    80001524:	e05a                	sd	s6,0(sp)
    80001526:	0080                	addi	s0,sp,64
    80001528:	892a                	mv	s2,a0
    8000152a:	8a2e                	mv	s4,a1
  struct proc *p = myproc();
    8000152c:	00000097          	auipc	ra,0x0
    80001530:	4bc080e7          	jalr	1212(ra) # 800019e8 <myproc>
    80001534:	89aa                	mv	s3,a0

  va0 = PGROUNDDOWN(addr);
    80001536:	777d                	lui	a4,0xfffff
    80001538:	00e974b3          	and	s1,s2,a4
  va1 = PGROUNDUP(addr + len);
    8000153c:	6785                	lui	a5,0x1
    8000153e:	17fd                	addi	a5,a5,-1
    80001540:	993e                	add	s2,s2,a5
    80001542:	9a4a                	add	s4,s4,s2
    80001544:	00ea7a33          	and	s4,s4,a4

  while(va0 < va1) {
    80001548:	0944fa63          	bgeu	s1,s4,800015dc <fill_user_addr+0xcc>
    8000154c:	6905                	lui	s2,0x1
    8000154e:	9926                	add	s2,s2,s1
    if(walkaddr(p->pagetable, va0) == 0) {
      if (va0 >= p->sz || va0 < PGROUNDDOWN(p->tf->sp)){
    80001550:	7afd                	lui	s5,0xfffff
    80001552:	a039                	j	80001560 <fill_user_addr+0x50>
  while(va0 < va1) {
    80001554:	6785                	lui	a5,0x1
    80001556:	94be                	add	s1,s1,a5
    80001558:	97ca                	add	a5,a5,s2
    8000155a:	07497463          	bgeu	s2,s4,800015c2 <fill_user_addr+0xb2>
    8000155e:	893e                	mv	s2,a5
    if(walkaddr(p->pagetable, va0) == 0) {
    80001560:	85a6                	mv	a1,s1
    80001562:	0509b503          	ld	a0,80(s3) # fffffffffffff050 <end+0xffffffff7ffd4ff4>
    80001566:	00000097          	auipc	ra,0x0
    8000156a:	a16080e7          	jalr	-1514(ra) # 80000f7c <walkaddr>
    8000156e:	f17d                	bnez	a0,80001554 <fill_user_addr+0x44>
      if (va0 >= p->sz || va0 < PGROUNDDOWN(p->tf->sp)){
    80001570:	0489b783          	ld	a5,72(s3)
    80001574:	fef4f0e3          	bgeu	s1,a5,80001554 <fill_user_addr+0x44>
    80001578:	0589b783          	ld	a5,88(s3)
    8000157c:	7b9c                	ld	a5,48(a5)
    8000157e:	00faf7b3          	and	a5,s5,a5
    80001582:	fcf4e9e3          	bltu	s1,a5,80001554 <fill_user_addr+0x44>
        va0 += PGSIZE;
        continue;
      }
      char *mem = kalloc();
    80001586:	fffff097          	auipc	ra,0xfffff
    8000158a:	3ca080e7          	jalr	970(ra) # 80000950 <kalloc>
    8000158e:	8b2a                	mv	s6,a0
      if(mem == 0){
    80001590:	c921                	beqz	a0,800015e0 <fill_user_addr+0xd0>
        return -1;
      }
      memset(mem, 0, PGSIZE);
    80001592:	6605                	lui	a2,0x1
    80001594:	4581                	li	a1,0
    80001596:	fffff097          	auipc	ra,0xfffff
    8000159a:	5ec080e7          	jalr	1516(ra) # 80000b82 <memset>
      if(mappages(p->pagetable, va0, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000159e:	4779                	li	a4,30
    800015a0:	86da                	mv	a3,s6
    800015a2:	6605                	lui	a2,0x1
    800015a4:	85a6                	mv	a1,s1
    800015a6:	0509b503          	ld	a0,80(s3)
    800015aa:	00000097          	auipc	ra,0x0
    800015ae:	a72080e7          	jalr	-1422(ra) # 8000101c <mappages>
    800015b2:	d14d                	beqz	a0,80001554 <fill_user_addr+0x44>
        kfree(mem);
    800015b4:	855a                	mv	a0,s6
    800015b6:	fffff097          	auipc	ra,0xfffff
    800015ba:	29e080e7          	jalr	670(ra) # 80000854 <kfree>
        return -1;
    800015be:	557d                	li	a0,-1
    800015c0:	a011                	j	800015c4 <fill_user_addr+0xb4>
      }

    }
    va0 += PGSIZE;
  }
  return 0;
    800015c2:	4501                	li	a0,0
}
    800015c4:	70e2                	ld	ra,56(sp)
    800015c6:	7442                	ld	s0,48(sp)
    800015c8:	74a2                	ld	s1,40(sp)
    800015ca:	7902                	ld	s2,32(sp)
    800015cc:	69e2                	ld	s3,24(sp)
    800015ce:	6a42                	ld	s4,16(sp)
    800015d0:	6aa2                	ld	s5,8(sp)
    800015d2:	6b02                	ld	s6,0(sp)
    800015d4:	6121                	addi	sp,sp,64
    800015d6:	8082                	ret
  if(len < 0) return -1;
    800015d8:	557d                	li	a0,-1
}
    800015da:	8082                	ret
  return 0;
    800015dc:	4501                	li	a0,0
    800015de:	b7dd                	j	800015c4 <fill_user_addr+0xb4>
        return -1;
    800015e0:	557d                	li	a0,-1
    800015e2:	b7cd                	j	800015c4 <fill_user_addr+0xb4>

00000000800015e4 <copyout>:
// Copy from kernel to user.
// Copy len bytes from src to virtual address dstva in a given page table.
// Return 0 on success, -1 on error.
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
    800015e4:	711d                	addi	sp,sp,-96
    800015e6:	ec86                	sd	ra,88(sp)
    800015e8:	e8a2                	sd	s0,80(sp)
    800015ea:	e4a6                	sd	s1,72(sp)
    800015ec:	e0ca                	sd	s2,64(sp)
    800015ee:	fc4e                	sd	s3,56(sp)
    800015f0:	f852                	sd	s4,48(sp)
    800015f2:	f456                	sd	s5,40(sp)
    800015f4:	f05a                	sd	s6,32(sp)
    800015f6:	ec5e                	sd	s7,24(sp)
    800015f8:	e862                	sd	s8,16(sp)
    800015fa:	e466                	sd	s9,8(sp)
    800015fc:	1080                	addi	s0,sp,96
    800015fe:	8baa                	mv	s7,a0
    80001600:	8a2e                	mv	s4,a1
    80001602:	8ab2                	mv	s5,a2
    80001604:	89b6                	mv	s3,a3
  uint64 n, va0, pa0;

  if(fill_user_addr(dstva, len) != 0)
    80001606:	0006859b          	sext.w	a1,a3
    8000160a:	8552                	mv	a0,s4
    8000160c:	00000097          	auipc	ra,0x0
    80001610:	f04080e7          	jalr	-252(ra) # 80001510 <fill_user_addr>
    80001614:	e921                	bnez	a0,80001664 <copyout+0x80>
    80001616:	8caa                	mv	s9,a0
    return -1;

  while(len > 0){
    80001618:	04098963          	beqz	s3,8000166a <copyout+0x86>
    va0 = PGROUNDDOWN(dstva);
    8000161c:	7c7d                	lui	s8,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000161e:	6b05                	lui	s6,0x1
    80001620:	a015                	j	80001644 <copyout+0x60>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001622:	9552                	add	a0,a0,s4
    80001624:	0004861b          	sext.w	a2,s1
    80001628:	85d6                	mv	a1,s5
    8000162a:	41250533          	sub	a0,a0,s2
    8000162e:	fffff097          	auipc	ra,0xfffff
    80001632:	5b0080e7          	jalr	1456(ra) # 80000bde <memmove>

    len -= n;
    80001636:	409989b3          	sub	s3,s3,s1
    src += n;
    8000163a:	9aa6                	add	s5,s5,s1
    dstva = va0 + PGSIZE;
    8000163c:	01690a33          	add	s4,s2,s6
  while(len > 0){
    80001640:	02098563          	beqz	s3,8000166a <copyout+0x86>
    va0 = PGROUNDDOWN(dstva);
    80001644:	018a7933          	and	s2,s4,s8
    pa0 = walkaddr(pagetable, va0);
    80001648:	85ca                	mv	a1,s2
    8000164a:	855e                	mv	a0,s7
    8000164c:	00000097          	auipc	ra,0x0
    80001650:	930080e7          	jalr	-1744(ra) # 80000f7c <walkaddr>
    if(pa0 == 0)
    80001654:	c911                	beqz	a0,80001668 <copyout+0x84>
    n = PGSIZE - (dstva - va0);
    80001656:	414904b3          	sub	s1,s2,s4
    8000165a:	94da                	add	s1,s1,s6
    if(n > len)
    8000165c:	fc99f3e3          	bgeu	s3,s1,80001622 <copyout+0x3e>
    80001660:	84ce                	mv	s1,s3
    80001662:	b7c1                	j	80001622 <copyout+0x3e>
    return -1;
    80001664:	5cfd                	li	s9,-1
    80001666:	a011                	j	8000166a <copyout+0x86>
      return -1;
    80001668:	5cfd                	li	s9,-1
  }
  return 0;
}
    8000166a:	8566                	mv	a0,s9
    8000166c:	60e6                	ld	ra,88(sp)
    8000166e:	6446                	ld	s0,80(sp)
    80001670:	64a6                	ld	s1,72(sp)
    80001672:	6906                	ld	s2,64(sp)
    80001674:	79e2                	ld	s3,56(sp)
    80001676:	7a42                	ld	s4,48(sp)
    80001678:	7aa2                	ld	s5,40(sp)
    8000167a:	7b02                	ld	s6,32(sp)
    8000167c:	6be2                	ld	s7,24(sp)
    8000167e:	6c42                	ld	s8,16(sp)
    80001680:	6ca2                	ld	s9,8(sp)
    80001682:	6125                	addi	sp,sp,96
    80001684:	8082                	ret

0000000080001686 <copyin>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    80001686:	711d                	addi	sp,sp,-96
    80001688:	ec86                	sd	ra,88(sp)
    8000168a:	e8a2                	sd	s0,80(sp)
    8000168c:	e4a6                	sd	s1,72(sp)
    8000168e:	e0ca                	sd	s2,64(sp)
    80001690:	fc4e                	sd	s3,56(sp)
    80001692:	f852                	sd	s4,48(sp)
    80001694:	f456                	sd	s5,40(sp)
    80001696:	f05a                	sd	s6,32(sp)
    80001698:	ec5e                	sd	s7,24(sp)
    8000169a:	e862                	sd	s8,16(sp)
    8000169c:	e466                	sd	s9,8(sp)
    8000169e:	1080                	addi	s0,sp,96
    800016a0:	8baa                	mv	s7,a0
    800016a2:	8aae                	mv	s5,a1
    800016a4:	8a32                	mv	s4,a2
    800016a6:	89b6                	mv	s3,a3
  uint64 n, va0, pa0;

  if(fill_user_addr(srcva, len) != 0)
    800016a8:	0006859b          	sext.w	a1,a3
    800016ac:	8532                	mv	a0,a2
    800016ae:	00000097          	auipc	ra,0x0
    800016b2:	e62080e7          	jalr	-414(ra) # 80001510 <fill_user_addr>
    800016b6:	e929                	bnez	a0,80001708 <copyin+0x82>
    800016b8:	8caa                	mv	s9,a0
    return -1;

  while(len > 0){
    800016ba:	04098a63          	beqz	s3,8000170e <copyin+0x88>
    va0 = PGROUNDDOWN(srcva);
    800016be:	7c7d                	lui	s8,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800016c0:	6b05                	lui	s6,0x1
    800016c2:	a01d                	j	800016e8 <copyin+0x62>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800016c4:	014505b3          	add	a1,a0,s4
    800016c8:	0004861b          	sext.w	a2,s1
    800016cc:	412585b3          	sub	a1,a1,s2
    800016d0:	8556                	mv	a0,s5
    800016d2:	fffff097          	auipc	ra,0xfffff
    800016d6:	50c080e7          	jalr	1292(ra) # 80000bde <memmove>

    len -= n;
    800016da:	409989b3          	sub	s3,s3,s1
    dst += n;
    800016de:	9aa6                	add	s5,s5,s1
    srcva = va0 + PGSIZE;
    800016e0:	01690a33          	add	s4,s2,s6
  while(len > 0){
    800016e4:	02098563          	beqz	s3,8000170e <copyin+0x88>
    va0 = PGROUNDDOWN(srcva);
    800016e8:	018a7933          	and	s2,s4,s8
    pa0 = walkaddr(pagetable, va0);
    800016ec:	85ca                	mv	a1,s2
    800016ee:	855e                	mv	a0,s7
    800016f0:	00000097          	auipc	ra,0x0
    800016f4:	88c080e7          	jalr	-1908(ra) # 80000f7c <walkaddr>
    if(pa0 == 0)
    800016f8:	c911                	beqz	a0,8000170c <copyin+0x86>
    n = PGSIZE - (srcva - va0);
    800016fa:	414904b3          	sub	s1,s2,s4
    800016fe:	94da                	add	s1,s1,s6
    if(n > len)
    80001700:	fc99f2e3          	bgeu	s3,s1,800016c4 <copyin+0x3e>
    80001704:	84ce                	mv	s1,s3
    80001706:	bf7d                	j	800016c4 <copyin+0x3e>
    return -1;
    80001708:	5cfd                	li	s9,-1
    8000170a:	a011                	j	8000170e <copyin+0x88>
      return -1;
    8000170c:	5cfd                	li	s9,-1
  }
  return 0;
}
    8000170e:	8566                	mv	a0,s9
    80001710:	60e6                	ld	ra,88(sp)
    80001712:	6446                	ld	s0,80(sp)
    80001714:	64a6                	ld	s1,72(sp)
    80001716:	6906                	ld	s2,64(sp)
    80001718:	79e2                	ld	s3,56(sp)
    8000171a:	7a42                	ld	s4,48(sp)
    8000171c:	7aa2                	ld	s5,40(sp)
    8000171e:	7b02                	ld	s6,32(sp)
    80001720:	6be2                	ld	s7,24(sp)
    80001722:	6c42                	ld	s8,16(sp)
    80001724:	6ca2                	ld	s9,8(sp)
    80001726:	6125                	addi	sp,sp,96
    80001728:	8082                	ret

000000008000172a <copyinstr>:
  int got_null = 0;

  // if(fill_user_addr(srcva, max) != 0)
  //   return -1;

  while(got_null == 0 && max > 0){
    8000172a:	c6c5                	beqz	a3,800017d2 <copyinstr+0xa8>
{
    8000172c:	715d                	addi	sp,sp,-80
    8000172e:	e486                	sd	ra,72(sp)
    80001730:	e0a2                	sd	s0,64(sp)
    80001732:	fc26                	sd	s1,56(sp)
    80001734:	f84a                	sd	s2,48(sp)
    80001736:	f44e                	sd	s3,40(sp)
    80001738:	f052                	sd	s4,32(sp)
    8000173a:	ec56                	sd	s5,24(sp)
    8000173c:	e85a                	sd	s6,16(sp)
    8000173e:	e45e                	sd	s7,8(sp)
    80001740:	0880                	addi	s0,sp,80
    80001742:	8a2a                	mv	s4,a0
    80001744:	8b2e                	mv	s6,a1
    80001746:	8bb2                	mv	s7,a2
    80001748:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000174a:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000174c:	6985                	lui	s3,0x1
    8000174e:	a035                	j	8000177a <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001750:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001754:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001756:	0017b793          	seqz	a5,a5
    8000175a:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000175e:	60a6                	ld	ra,72(sp)
    80001760:	6406                	ld	s0,64(sp)
    80001762:	74e2                	ld	s1,56(sp)
    80001764:	7942                	ld	s2,48(sp)
    80001766:	79a2                	ld	s3,40(sp)
    80001768:	7a02                	ld	s4,32(sp)
    8000176a:	6ae2                	ld	s5,24(sp)
    8000176c:	6b42                	ld	s6,16(sp)
    8000176e:	6ba2                	ld	s7,8(sp)
    80001770:	6161                	addi	sp,sp,80
    80001772:	8082                	ret
    srcva = va0 + PGSIZE;
    80001774:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001778:	c8a9                	beqz	s1,800017ca <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000177a:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000177e:	85ca                	mv	a1,s2
    80001780:	8552                	mv	a0,s4
    80001782:	fffff097          	auipc	ra,0xfffff
    80001786:	7fa080e7          	jalr	2042(ra) # 80000f7c <walkaddr>
    if(pa0 == 0)
    8000178a:	c131                	beqz	a0,800017ce <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    8000178c:	41790833          	sub	a6,s2,s7
    80001790:	984e                	add	a6,a6,s3
    if(n > max)
    80001792:	0104f363          	bgeu	s1,a6,80001798 <copyinstr+0x6e>
    80001796:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001798:	955e                	add	a0,a0,s7
    8000179a:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000179e:	fc080be3          	beqz	a6,80001774 <copyinstr+0x4a>
    800017a2:	985a                	add	a6,a6,s6
    800017a4:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017a6:	41650633          	sub	a2,a0,s6
    800017aa:	14fd                	addi	s1,s1,-1
    800017ac:	9b26                	add	s6,s6,s1
    800017ae:	00f60733          	add	a4,a2,a5
    800017b2:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd4fa4>
    800017b6:	df49                	beqz	a4,80001750 <copyinstr+0x26>
        *dst = *p;
    800017b8:	00e78023          	sb	a4,0(a5)
      --max;
    800017bc:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800017c0:	0785                	addi	a5,a5,1
    while(n > 0){
    800017c2:	ff0796e3          	bne	a5,a6,800017ae <copyinstr+0x84>
      dst++;
    800017c6:	8b42                	mv	s6,a6
    800017c8:	b775                	j	80001774 <copyinstr+0x4a>
    800017ca:	4781                	li	a5,0
    800017cc:	b769                	j	80001756 <copyinstr+0x2c>
      return -1;
    800017ce:	557d                	li	a0,-1
    800017d0:	b779                	j	8000175e <copyinstr+0x34>
  int got_null = 0;
    800017d2:	4781                	li	a5,0
  if(got_null){
    800017d4:	0017b793          	seqz	a5,a5
    800017d8:	40f00533          	neg	a0,a5
}
    800017dc:	8082                	ret

00000000800017de <_vmprint>:

void 
_vmprint(pagetable_t pagetable, int idx) {
    800017de:	7139                	addi	sp,sp,-64
    800017e0:	fc06                	sd	ra,56(sp)
    800017e2:	f822                	sd	s0,48(sp)
    800017e4:	f426                	sd	s1,40(sp)
    800017e6:	f04a                	sd	s2,32(sp)
    800017e8:	ec4e                	sd	s3,24(sp)
    800017ea:	e852                	sd	s4,16(sp)
    800017ec:	e456                	sd	s5,8(sp)
    800017ee:	e05a                	sd	s6,0(sp)
    800017f0:	0080                	addi	s0,sp,64
  char *fmt;
  if(idx == 1){
    800017f2:	4785                	li	a5,1
    800017f4:	02f58663          	beq	a1,a5,80001820 <_vmprint+0x42>
    fmt = " ..%d: pte %p pa %p\n";
  }else if(idx == 2) {
    800017f8:	4789                	li	a5,2
    800017fa:	02f58e63          	beq	a1,a5,80001836 <_vmprint+0x58>
    fmt = " .. ..%d: pte %p pa %p\n";
  }else if(idx == 3){
    800017fe:	478d                	li	a5,3
    fmt = " .. .. ..%d: pte %p pa %p\n";
    80001800:	00007b17          	auipc	s6,0x7
    80001804:	a80b0b13          	addi	s6,s6,-1408 # 80008280 <userret+0x1f0>
  }else if(idx == 3){
    80001808:	02f58063          	beq	a1,a5,80001828 <_vmprint+0x4a>
      printf(fmt, i, pte, child);
      _vmprint((pagetable_t)child, idx + 1);
    }
  }

}
    8000180c:	70e2                	ld	ra,56(sp)
    8000180e:	7442                	ld	s0,48(sp)
    80001810:	74a2                	ld	s1,40(sp)
    80001812:	7902                	ld	s2,32(sp)
    80001814:	69e2                	ld	s3,24(sp)
    80001816:	6a42                	ld	s4,16(sp)
    80001818:	6aa2                	ld	s5,8(sp)
    8000181a:	6b02                	ld	s6,0(sp)
    8000181c:	6121                	addi	sp,sp,64
    8000181e:	8082                	ret
    fmt = " ..%d: pte %p pa %p\n";
    80001820:	00007b17          	auipc	s6,0x7
    80001824:	a30b0b13          	addi	s6,s6,-1488 # 80008250 <userret+0x1c0>
  for(int i = 0; i < 512; i++){
    80001828:	892a                	mv	s2,a0
    8000182a:	4481                	li	s1,0
      _vmprint((pagetable_t)child, idx + 1);
    8000182c:	00158a9b          	addiw	s5,a1,1
  for(int i = 0; i < 512; i++){
    80001830:	20000a13          	li	s4,512
    80001834:	a811                	j	80001848 <_vmprint+0x6a>
    fmt = " .. ..%d: pte %p pa %p\n";
    80001836:	00007b17          	auipc	s6,0x7
    8000183a:	a32b0b13          	addi	s6,s6,-1486 # 80008268 <userret+0x1d8>
    8000183e:	b7ed                	j	80001828 <_vmprint+0x4a>
  for(int i = 0; i < 512; i++){
    80001840:	2485                	addiw	s1,s1,1
    80001842:	0921                	addi	s2,s2,8
    80001844:	fd4484e3          	beq	s1,s4,8000180c <_vmprint+0x2e>
    pte_t pte = pagetable[i];
    80001848:	00093603          	ld	a2,0(s2) # 1000 <_entry-0x7ffff000>
    if((pte & PTE_V) != 0){
    8000184c:	00167793          	andi	a5,a2,1
    80001850:	dbe5                	beqz	a5,80001840 <_vmprint+0x62>
      uint64 child = PTE2PA(pte);
    80001852:	00a65993          	srli	s3,a2,0xa
    80001856:	09b2                	slli	s3,s3,0xc
      printf(fmt, i, pte, child);
    80001858:	86ce                	mv	a3,s3
    8000185a:	85a6                	mv	a1,s1
    8000185c:	855a                	mv	a0,s6
    8000185e:	fffff097          	auipc	ra,0xfffff
    80001862:	d34080e7          	jalr	-716(ra) # 80000592 <printf>
      _vmprint((pagetable_t)child, idx + 1);
    80001866:	85d6                	mv	a1,s5
    80001868:	854e                	mv	a0,s3
    8000186a:	00000097          	auipc	ra,0x0
    8000186e:	f74080e7          	jalr	-140(ra) # 800017de <_vmprint>
    80001872:	b7f9                	j	80001840 <_vmprint+0x62>

0000000080001874 <vmprint>:

void 
vmprint(pagetable_t pagetable) {
    80001874:	1101                	addi	sp,sp,-32
    80001876:	ec06                	sd	ra,24(sp)
    80001878:	e822                	sd	s0,16(sp)
    8000187a:	e426                	sd	s1,8(sp)
    8000187c:	1000                	addi	s0,sp,32
    8000187e:	84aa                	mv	s1,a0
  printf("page table %p\n", pagetable);
    80001880:	85aa                	mv	a1,a0
    80001882:	00007517          	auipc	a0,0x7
    80001886:	a1e50513          	addi	a0,a0,-1506 # 800082a0 <userret+0x210>
    8000188a:	fffff097          	auipc	ra,0xfffff
    8000188e:	d08080e7          	jalr	-760(ra) # 80000592 <printf>
  _vmprint(pagetable, 1);
    80001892:	4585                	li	a1,1
    80001894:	8526                	mv	a0,s1
    80001896:	00000097          	auipc	ra,0x0
    8000189a:	f48080e7          	jalr	-184(ra) # 800017de <_vmprint>
    8000189e:	60e2                	ld	ra,24(sp)
    800018a0:	6442                	ld	s0,16(sp)
    800018a2:	64a2                	ld	s1,8(sp)
    800018a4:	6105                	addi	sp,sp,32
    800018a6:	8082                	ret

00000000800018a8 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    800018a8:	1101                	addi	sp,sp,-32
    800018aa:	ec06                	sd	ra,24(sp)
    800018ac:	e822                	sd	s0,16(sp)
    800018ae:	e426                	sd	s1,8(sp)
    800018b0:	1000                	addi	s0,sp,32
    800018b2:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800018b4:	fffff097          	auipc	ra,0xfffff
    800018b8:	1ca080e7          	jalr	458(ra) # 80000a7e <holding>
    800018bc:	c909                	beqz	a0,800018ce <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    800018be:	749c                	ld	a5,40(s1)
    800018c0:	00978f63          	beq	a5,s1,800018de <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    800018c4:	60e2                	ld	ra,24(sp)
    800018c6:	6442                	ld	s0,16(sp)
    800018c8:	64a2                	ld	s1,8(sp)
    800018ca:	6105                	addi	sp,sp,32
    800018cc:	8082                	ret
    panic("wakeup1");
    800018ce:	00007517          	auipc	a0,0x7
    800018d2:	9e250513          	addi	a0,a0,-1566 # 800082b0 <userret+0x220>
    800018d6:	fffff097          	auipc	ra,0xfffff
    800018da:	c72080e7          	jalr	-910(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    800018de:	4c98                	lw	a4,24(s1)
    800018e0:	4785                	li	a5,1
    800018e2:	fef711e3          	bne	a4,a5,800018c4 <wakeup1+0x1c>
    p->state = RUNNABLE;
    800018e6:	4789                	li	a5,2
    800018e8:	cc9c                	sw	a5,24(s1)
}
    800018ea:	bfe9                	j	800018c4 <wakeup1+0x1c>

00000000800018ec <procinit>:
{
    800018ec:	715d                	addi	sp,sp,-80
    800018ee:	e486                	sd	ra,72(sp)
    800018f0:	e0a2                	sd	s0,64(sp)
    800018f2:	fc26                	sd	s1,56(sp)
    800018f4:	f84a                	sd	s2,48(sp)
    800018f6:	f44e                	sd	s3,40(sp)
    800018f8:	f052                	sd	s4,32(sp)
    800018fa:	ec56                	sd	s5,24(sp)
    800018fc:	e85a                	sd	s6,16(sp)
    800018fe:	e45e                	sd	s7,8(sp)
    80001900:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001902:	00007597          	auipc	a1,0x7
    80001906:	9b658593          	addi	a1,a1,-1610 # 800082b8 <userret+0x228>
    8000190a:	00011517          	auipc	a0,0x11
    8000190e:	fde50513          	addi	a0,a0,-34 # 800128e8 <pid_lock>
    80001912:	fffff097          	auipc	ra,0xfffff
    80001916:	09e080e7          	jalr	158(ra) # 800009b0 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000191a:	00011917          	auipc	s2,0x11
    8000191e:	3e690913          	addi	s2,s2,998 # 80012d00 <proc>
      initlock(&p->lock, "proc");
    80001922:	00007b97          	auipc	s7,0x7
    80001926:	99eb8b93          	addi	s7,s7,-1634 # 800082c0 <userret+0x230>
      uint64 va = KSTACK((int) (p - proc));
    8000192a:	8b4a                	mv	s6,s2
    8000192c:	00007a97          	auipc	s5,0x7
    80001930:	1d4a8a93          	addi	s5,s5,468 # 80008b00 <syscalls+0xc0>
    80001934:	040009b7          	lui	s3,0x4000
    80001938:	19fd                	addi	s3,s3,-1
    8000193a:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000193c:	00017a17          	auipc	s4,0x17
    80001940:	dc4a0a13          	addi	s4,s4,-572 # 80018700 <tickslock>
      initlock(&p->lock, "proc");
    80001944:	85de                	mv	a1,s7
    80001946:	854a                	mv	a0,s2
    80001948:	fffff097          	auipc	ra,0xfffff
    8000194c:	068080e7          	jalr	104(ra) # 800009b0 <initlock>
      char *pa = kalloc();
    80001950:	fffff097          	auipc	ra,0xfffff
    80001954:	000080e7          	jalr	ra # 80000950 <kalloc>
    80001958:	85aa                	mv	a1,a0
      if(pa == 0)
    8000195a:	c929                	beqz	a0,800019ac <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    8000195c:	416904b3          	sub	s1,s2,s6
    80001960:	848d                	srai	s1,s1,0x3
    80001962:	000ab783          	ld	a5,0(s5)
    80001966:	02f484b3          	mul	s1,s1,a5
    8000196a:	2485                	addiw	s1,s1,1
    8000196c:	00d4949b          	slliw	s1,s1,0xd
    80001970:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001974:	4699                	li	a3,6
    80001976:	6605                	lui	a2,0x1
    80001978:	8526                	mv	a0,s1
    8000197a:	fffff097          	auipc	ra,0xfffff
    8000197e:	730080e7          	jalr	1840(ra) # 800010aa <kvmmap>
      p->kstack = va;
    80001982:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001986:	16890913          	addi	s2,s2,360
    8000198a:	fb491de3          	bne	s2,s4,80001944 <procinit+0x58>
  kvminithart();
    8000198e:	fffff097          	auipc	ra,0xfffff
    80001992:	5ca080e7          	jalr	1482(ra) # 80000f58 <kvminithart>
}
    80001996:	60a6                	ld	ra,72(sp)
    80001998:	6406                	ld	s0,64(sp)
    8000199a:	74e2                	ld	s1,56(sp)
    8000199c:	7942                	ld	s2,48(sp)
    8000199e:	79a2                	ld	s3,40(sp)
    800019a0:	7a02                	ld	s4,32(sp)
    800019a2:	6ae2                	ld	s5,24(sp)
    800019a4:	6b42                	ld	s6,16(sp)
    800019a6:	6ba2                	ld	s7,8(sp)
    800019a8:	6161                	addi	sp,sp,80
    800019aa:	8082                	ret
        panic("kalloc");
    800019ac:	00007517          	auipc	a0,0x7
    800019b0:	91c50513          	addi	a0,a0,-1764 # 800082c8 <userret+0x238>
    800019b4:	fffff097          	auipc	ra,0xfffff
    800019b8:	b94080e7          	jalr	-1132(ra) # 80000548 <panic>

00000000800019bc <cpuid>:
{
    800019bc:	1141                	addi	sp,sp,-16
    800019be:	e422                	sd	s0,8(sp)
    800019c0:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019c2:	8512                	mv	a0,tp
}
    800019c4:	2501                	sext.w	a0,a0
    800019c6:	6422                	ld	s0,8(sp)
    800019c8:	0141                	addi	sp,sp,16
    800019ca:	8082                	ret

00000000800019cc <mycpu>:
mycpu(void) {
    800019cc:	1141                	addi	sp,sp,-16
    800019ce:	e422                	sd	s0,8(sp)
    800019d0:	0800                	addi	s0,sp,16
    800019d2:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    800019d4:	2781                	sext.w	a5,a5
    800019d6:	079e                	slli	a5,a5,0x7
}
    800019d8:	00011517          	auipc	a0,0x11
    800019dc:	f2850513          	addi	a0,a0,-216 # 80012900 <cpus>
    800019e0:	953e                	add	a0,a0,a5
    800019e2:	6422                	ld	s0,8(sp)
    800019e4:	0141                	addi	sp,sp,16
    800019e6:	8082                	ret

00000000800019e8 <myproc>:
myproc(void) {
    800019e8:	1101                	addi	sp,sp,-32
    800019ea:	ec06                	sd	ra,24(sp)
    800019ec:	e822                	sd	s0,16(sp)
    800019ee:	e426                	sd	s1,8(sp)
    800019f0:	1000                	addi	s0,sp,32
  push_off();
    800019f2:	fffff097          	auipc	ra,0xfffff
    800019f6:	fd4080e7          	jalr	-44(ra) # 800009c6 <push_off>
    800019fa:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    800019fc:	2781                	sext.w	a5,a5
    800019fe:	079e                	slli	a5,a5,0x7
    80001a00:	00011717          	auipc	a4,0x11
    80001a04:	ee870713          	addi	a4,a4,-280 # 800128e8 <pid_lock>
    80001a08:	97ba                	add	a5,a5,a4
    80001a0a:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a0c:	fffff097          	auipc	ra,0xfffff
    80001a10:	006080e7          	jalr	6(ra) # 80000a12 <pop_off>
}
    80001a14:	8526                	mv	a0,s1
    80001a16:	60e2                	ld	ra,24(sp)
    80001a18:	6442                	ld	s0,16(sp)
    80001a1a:	64a2                	ld	s1,8(sp)
    80001a1c:	6105                	addi	sp,sp,32
    80001a1e:	8082                	ret

0000000080001a20 <forkret>:
{
    80001a20:	1141                	addi	sp,sp,-16
    80001a22:	e406                	sd	ra,8(sp)
    80001a24:	e022                	sd	s0,0(sp)
    80001a26:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a28:	00000097          	auipc	ra,0x0
    80001a2c:	fc0080e7          	jalr	-64(ra) # 800019e8 <myproc>
    80001a30:	fffff097          	auipc	ra,0xfffff
    80001a34:	0f6080e7          	jalr	246(ra) # 80000b26 <release>
  if (first) {
    80001a38:	00007797          	auipc	a5,0x7
    80001a3c:	5fc7a783          	lw	a5,1532(a5) # 80009034 <first.1>
    80001a40:	eb89                	bnez	a5,80001a52 <forkret+0x32>
  usertrapret();
    80001a42:	00001097          	auipc	ra,0x1
    80001a46:	bdc080e7          	jalr	-1060(ra) # 8000261e <usertrapret>
}
    80001a4a:	60a2                	ld	ra,8(sp)
    80001a4c:	6402                	ld	s0,0(sp)
    80001a4e:	0141                	addi	sp,sp,16
    80001a50:	8082                	ret
    first = 0;
    80001a52:	00007797          	auipc	a5,0x7
    80001a56:	5e07a123          	sw	zero,1506(a5) # 80009034 <first.1>
    fsinit(minor(ROOTDEV));
    80001a5a:	4501                	li	a0,0
    80001a5c:	00002097          	auipc	ra,0x2
    80001a60:	9d6080e7          	jalr	-1578(ra) # 80003432 <fsinit>
    80001a64:	bff9                	j	80001a42 <forkret+0x22>

0000000080001a66 <allocpid>:
allocpid() {
    80001a66:	1101                	addi	sp,sp,-32
    80001a68:	ec06                	sd	ra,24(sp)
    80001a6a:	e822                	sd	s0,16(sp)
    80001a6c:	e426                	sd	s1,8(sp)
    80001a6e:	e04a                	sd	s2,0(sp)
    80001a70:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a72:	00011917          	auipc	s2,0x11
    80001a76:	e7690913          	addi	s2,s2,-394 # 800128e8 <pid_lock>
    80001a7a:	854a                	mv	a0,s2
    80001a7c:	fffff097          	auipc	ra,0xfffff
    80001a80:	042080e7          	jalr	66(ra) # 80000abe <acquire>
  pid = nextpid;
    80001a84:	00007797          	auipc	a5,0x7
    80001a88:	5b478793          	addi	a5,a5,1460 # 80009038 <nextpid>
    80001a8c:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a8e:	0014871b          	addiw	a4,s1,1
    80001a92:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a94:	854a                	mv	a0,s2
    80001a96:	fffff097          	auipc	ra,0xfffff
    80001a9a:	090080e7          	jalr	144(ra) # 80000b26 <release>
}
    80001a9e:	8526                	mv	a0,s1
    80001aa0:	60e2                	ld	ra,24(sp)
    80001aa2:	6442                	ld	s0,16(sp)
    80001aa4:	64a2                	ld	s1,8(sp)
    80001aa6:	6902                	ld	s2,0(sp)
    80001aa8:	6105                	addi	sp,sp,32
    80001aaa:	8082                	ret

0000000080001aac <proc_pagetable>:
{
    80001aac:	1101                	addi	sp,sp,-32
    80001aae:	ec06                	sd	ra,24(sp)
    80001ab0:	e822                	sd	s0,16(sp)
    80001ab2:	e426                	sd	s1,8(sp)
    80001ab4:	e04a                	sd	s2,0(sp)
    80001ab6:	1000                	addi	s0,sp,32
    80001ab8:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001aba:	fffff097          	auipc	ra,0xfffff
    80001abe:	7a4080e7          	jalr	1956(ra) # 8000125e <uvmcreate>
    80001ac2:	84aa                	mv	s1,a0
  mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ac4:	4729                	li	a4,10
    80001ac6:	00006697          	auipc	a3,0x6
    80001aca:	53a68693          	addi	a3,a3,1338 # 80008000 <trampoline>
    80001ace:	6605                	lui	a2,0x1
    80001ad0:	040005b7          	lui	a1,0x4000
    80001ad4:	15fd                	addi	a1,a1,-1
    80001ad6:	05b2                	slli	a1,a1,0xc
    80001ad8:	fffff097          	auipc	ra,0xfffff
    80001adc:	544080e7          	jalr	1348(ra) # 8000101c <mappages>
  mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ae0:	4719                	li	a4,6
    80001ae2:	05893683          	ld	a3,88(s2)
    80001ae6:	6605                	lui	a2,0x1
    80001ae8:	020005b7          	lui	a1,0x2000
    80001aec:	15fd                	addi	a1,a1,-1
    80001aee:	05b6                	slli	a1,a1,0xd
    80001af0:	8526                	mv	a0,s1
    80001af2:	fffff097          	auipc	ra,0xfffff
    80001af6:	52a080e7          	jalr	1322(ra) # 8000101c <mappages>
}
    80001afa:	8526                	mv	a0,s1
    80001afc:	60e2                	ld	ra,24(sp)
    80001afe:	6442                	ld	s0,16(sp)
    80001b00:	64a2                	ld	s1,8(sp)
    80001b02:	6902                	ld	s2,0(sp)
    80001b04:	6105                	addi	sp,sp,32
    80001b06:	8082                	ret

0000000080001b08 <allocproc>:
{
    80001b08:	1101                	addi	sp,sp,-32
    80001b0a:	ec06                	sd	ra,24(sp)
    80001b0c:	e822                	sd	s0,16(sp)
    80001b0e:	e426                	sd	s1,8(sp)
    80001b10:	e04a                	sd	s2,0(sp)
    80001b12:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b14:	00011497          	auipc	s1,0x11
    80001b18:	1ec48493          	addi	s1,s1,492 # 80012d00 <proc>
    80001b1c:	00017917          	auipc	s2,0x17
    80001b20:	be490913          	addi	s2,s2,-1052 # 80018700 <tickslock>
    acquire(&p->lock);
    80001b24:	8526                	mv	a0,s1
    80001b26:	fffff097          	auipc	ra,0xfffff
    80001b2a:	f98080e7          	jalr	-104(ra) # 80000abe <acquire>
    if(p->state == UNUSED) {
    80001b2e:	4c9c                	lw	a5,24(s1)
    80001b30:	cf81                	beqz	a5,80001b48 <allocproc+0x40>
      release(&p->lock);
    80001b32:	8526                	mv	a0,s1
    80001b34:	fffff097          	auipc	ra,0xfffff
    80001b38:	ff2080e7          	jalr	-14(ra) # 80000b26 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b3c:	16848493          	addi	s1,s1,360
    80001b40:	ff2492e3          	bne	s1,s2,80001b24 <allocproc+0x1c>
  return 0;
    80001b44:	4481                	li	s1,0
    80001b46:	a0a9                	j	80001b90 <allocproc+0x88>
  p->pid = allocpid();
    80001b48:	00000097          	auipc	ra,0x0
    80001b4c:	f1e080e7          	jalr	-226(ra) # 80001a66 <allocpid>
    80001b50:	dc88                	sw	a0,56(s1)
  if((p->tf = (struct trapframe *)kalloc()) == 0){
    80001b52:	fffff097          	auipc	ra,0xfffff
    80001b56:	dfe080e7          	jalr	-514(ra) # 80000950 <kalloc>
    80001b5a:	892a                	mv	s2,a0
    80001b5c:	eca8                	sd	a0,88(s1)
    80001b5e:	c121                	beqz	a0,80001b9e <allocproc+0x96>
  p->pagetable = proc_pagetable(p);
    80001b60:	8526                	mv	a0,s1
    80001b62:	00000097          	auipc	ra,0x0
    80001b66:	f4a080e7          	jalr	-182(ra) # 80001aac <proc_pagetable>
    80001b6a:	e8a8                	sd	a0,80(s1)
  memset(&p->context, 0, sizeof p->context);
    80001b6c:	07000613          	li	a2,112
    80001b70:	4581                	li	a1,0
    80001b72:	06048513          	addi	a0,s1,96
    80001b76:	fffff097          	auipc	ra,0xfffff
    80001b7a:	00c080e7          	jalr	12(ra) # 80000b82 <memset>
  p->context.ra = (uint64)forkret;
    80001b7e:	00000797          	auipc	a5,0x0
    80001b82:	ea278793          	addi	a5,a5,-350 # 80001a20 <forkret>
    80001b86:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001b88:	60bc                	ld	a5,64(s1)
    80001b8a:	6705                	lui	a4,0x1
    80001b8c:	97ba                	add	a5,a5,a4
    80001b8e:	f4bc                	sd	a5,104(s1)
}
    80001b90:	8526                	mv	a0,s1
    80001b92:	60e2                	ld	ra,24(sp)
    80001b94:	6442                	ld	s0,16(sp)
    80001b96:	64a2                	ld	s1,8(sp)
    80001b98:	6902                	ld	s2,0(sp)
    80001b9a:	6105                	addi	sp,sp,32
    80001b9c:	8082                	ret
    release(&p->lock);
    80001b9e:	8526                	mv	a0,s1
    80001ba0:	fffff097          	auipc	ra,0xfffff
    80001ba4:	f86080e7          	jalr	-122(ra) # 80000b26 <release>
    return 0;
    80001ba8:	84ca                	mv	s1,s2
    80001baa:	b7dd                	j	80001b90 <allocproc+0x88>

0000000080001bac <proc_freepagetable>:
{
    80001bac:	1101                	addi	sp,sp,-32
    80001bae:	ec06                	sd	ra,24(sp)
    80001bb0:	e822                	sd	s0,16(sp)
    80001bb2:	e426                	sd	s1,8(sp)
    80001bb4:	e04a                	sd	s2,0(sp)
    80001bb6:	1000                	addi	s0,sp,32
    80001bb8:	84aa                	mv	s1,a0
    80001bba:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, PGSIZE, 0);
    80001bbc:	4681                	li	a3,0
    80001bbe:	6605                	lui	a2,0x1
    80001bc0:	040005b7          	lui	a1,0x4000
    80001bc4:	15fd                	addi	a1,a1,-1
    80001bc6:	05b2                	slli	a1,a1,0xc
    80001bc8:	fffff097          	auipc	ra,0xfffff
    80001bcc:	600080e7          	jalr	1536(ra) # 800011c8 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, PGSIZE, 0);
    80001bd0:	4681                	li	a3,0
    80001bd2:	6605                	lui	a2,0x1
    80001bd4:	020005b7          	lui	a1,0x2000
    80001bd8:	15fd                	addi	a1,a1,-1
    80001bda:	05b6                	slli	a1,a1,0xd
    80001bdc:	8526                	mv	a0,s1
    80001bde:	fffff097          	auipc	ra,0xfffff
    80001be2:	5ea080e7          	jalr	1514(ra) # 800011c8 <uvmunmap>
  if(sz > 0)
    80001be6:	00091863          	bnez	s2,80001bf6 <proc_freepagetable+0x4a>
}
    80001bea:	60e2                	ld	ra,24(sp)
    80001bec:	6442                	ld	s0,16(sp)
    80001bee:	64a2                	ld	s1,8(sp)
    80001bf0:	6902                	ld	s2,0(sp)
    80001bf2:	6105                	addi	sp,sp,32
    80001bf4:	8082                	ret
    uvmfree(pagetable, sz);
    80001bf6:	85ca                	mv	a1,s2
    80001bf8:	8526                	mv	a0,s1
    80001bfa:	00000097          	auipc	ra,0x0
    80001bfe:	802080e7          	jalr	-2046(ra) # 800013fc <uvmfree>
}
    80001c02:	b7e5                	j	80001bea <proc_freepagetable+0x3e>

0000000080001c04 <freeproc>:
{
    80001c04:	1101                	addi	sp,sp,-32
    80001c06:	ec06                	sd	ra,24(sp)
    80001c08:	e822                	sd	s0,16(sp)
    80001c0a:	e426                	sd	s1,8(sp)
    80001c0c:	1000                	addi	s0,sp,32
    80001c0e:	84aa                	mv	s1,a0
  if(p->tf)
    80001c10:	6d28                	ld	a0,88(a0)
    80001c12:	c509                	beqz	a0,80001c1c <freeproc+0x18>
    kfree((void*)p->tf);
    80001c14:	fffff097          	auipc	ra,0xfffff
    80001c18:	c40080e7          	jalr	-960(ra) # 80000854 <kfree>
  p->tf = 0;
    80001c1c:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c20:	68a8                	ld	a0,80(s1)
    80001c22:	c511                	beqz	a0,80001c2e <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c24:	64ac                	ld	a1,72(s1)
    80001c26:	00000097          	auipc	ra,0x0
    80001c2a:	f86080e7          	jalr	-122(ra) # 80001bac <proc_freepagetable>
  p->pagetable = 0;
    80001c2e:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c32:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c36:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001c3a:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001c3e:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c42:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001c46:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001c4a:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001c4e:	0004ac23          	sw	zero,24(s1)
}
    80001c52:	60e2                	ld	ra,24(sp)
    80001c54:	6442                	ld	s0,16(sp)
    80001c56:	64a2                	ld	s1,8(sp)
    80001c58:	6105                	addi	sp,sp,32
    80001c5a:	8082                	ret

0000000080001c5c <userinit>:
{
    80001c5c:	1101                	addi	sp,sp,-32
    80001c5e:	ec06                	sd	ra,24(sp)
    80001c60:	e822                	sd	s0,16(sp)
    80001c62:	e426                	sd	s1,8(sp)
    80001c64:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c66:	00000097          	auipc	ra,0x0
    80001c6a:	ea2080e7          	jalr	-350(ra) # 80001b08 <allocproc>
    80001c6e:	84aa                	mv	s1,a0
  initproc = p;
    80001c70:	00028797          	auipc	a5,0x28
    80001c74:	3ca7b423          	sd	a0,968(a5) # 8002a038 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001c78:	03300613          	li	a2,51
    80001c7c:	00007597          	auipc	a1,0x7
    80001c80:	38458593          	addi	a1,a1,900 # 80009000 <initcode>
    80001c84:	6928                	ld	a0,80(a0)
    80001c86:	fffff097          	auipc	ra,0xfffff
    80001c8a:	616080e7          	jalr	1558(ra) # 8000129c <uvminit>
  p->sz = PGSIZE;
    80001c8e:	6785                	lui	a5,0x1
    80001c90:	e4bc                	sd	a5,72(s1)
  p->tf->epc = 0;      // user program counter
    80001c92:	6cb8                	ld	a4,88(s1)
    80001c94:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->tf->sp = PGSIZE;  // user stack pointer
    80001c98:	6cb8                	ld	a4,88(s1)
    80001c9a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001c9c:	4641                	li	a2,16
    80001c9e:	00006597          	auipc	a1,0x6
    80001ca2:	63258593          	addi	a1,a1,1586 # 800082d0 <userret+0x240>
    80001ca6:	15848513          	addi	a0,s1,344
    80001caa:	fffff097          	auipc	ra,0xfffff
    80001cae:	02a080e7          	jalr	42(ra) # 80000cd4 <safestrcpy>
  p->cwd = namei("/");
    80001cb2:	00006517          	auipc	a0,0x6
    80001cb6:	62e50513          	addi	a0,a0,1582 # 800082e0 <userret+0x250>
    80001cba:	00002097          	auipc	ra,0x2
    80001cbe:	17a080e7          	jalr	378(ra) # 80003e34 <namei>
    80001cc2:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cc6:	4789                	li	a5,2
    80001cc8:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cca:	8526                	mv	a0,s1
    80001ccc:	fffff097          	auipc	ra,0xfffff
    80001cd0:	e5a080e7          	jalr	-422(ra) # 80000b26 <release>
}
    80001cd4:	60e2                	ld	ra,24(sp)
    80001cd6:	6442                	ld	s0,16(sp)
    80001cd8:	64a2                	ld	s1,8(sp)
    80001cda:	6105                	addi	sp,sp,32
    80001cdc:	8082                	ret

0000000080001cde <growproc>:
{
    80001cde:	1101                	addi	sp,sp,-32
    80001ce0:	ec06                	sd	ra,24(sp)
    80001ce2:	e822                	sd	s0,16(sp)
    80001ce4:	e426                	sd	s1,8(sp)
    80001ce6:	e04a                	sd	s2,0(sp)
    80001ce8:	1000                	addi	s0,sp,32
    80001cea:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001cec:	00000097          	auipc	ra,0x0
    80001cf0:	cfc080e7          	jalr	-772(ra) # 800019e8 <myproc>
    80001cf4:	892a                	mv	s2,a0
  sz = p->sz;
    80001cf6:	652c                	ld	a1,72(a0)
    80001cf8:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001cfc:	00904f63          	bgtz	s1,80001d1a <growproc+0x3c>
  } else if(n < 0){
    80001d00:	0204cc63          	bltz	s1,80001d38 <growproc+0x5a>
  p->sz = sz;
    80001d04:	1602                	slli	a2,a2,0x20
    80001d06:	9201                	srli	a2,a2,0x20
    80001d08:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d0c:	4501                	li	a0,0
}
    80001d0e:	60e2                	ld	ra,24(sp)
    80001d10:	6442                	ld	s0,16(sp)
    80001d12:	64a2                	ld	s1,8(sp)
    80001d14:	6902                	ld	s2,0(sp)
    80001d16:	6105                	addi	sp,sp,32
    80001d18:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d1a:	9e25                	addw	a2,a2,s1
    80001d1c:	1602                	slli	a2,a2,0x20
    80001d1e:	9201                	srli	a2,a2,0x20
    80001d20:	1582                	slli	a1,a1,0x20
    80001d22:	9181                	srli	a1,a1,0x20
    80001d24:	6928                	ld	a0,80(a0)
    80001d26:	fffff097          	auipc	ra,0xfffff
    80001d2a:	62c080e7          	jalr	1580(ra) # 80001352 <uvmalloc>
    80001d2e:	0005061b          	sext.w	a2,a0
    80001d32:	fa69                	bnez	a2,80001d04 <growproc+0x26>
      return -1;
    80001d34:	557d                	li	a0,-1
    80001d36:	bfe1                	j	80001d0e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d38:	9e25                	addw	a2,a2,s1
    80001d3a:	1602                	slli	a2,a2,0x20
    80001d3c:	9201                	srli	a2,a2,0x20
    80001d3e:	1582                	slli	a1,a1,0x20
    80001d40:	9181                	srli	a1,a1,0x20
    80001d42:	6928                	ld	a0,80(a0)
    80001d44:	fffff097          	auipc	ra,0xfffff
    80001d48:	5ca080e7          	jalr	1482(ra) # 8000130e <uvmdealloc>
    80001d4c:	0005061b          	sext.w	a2,a0
    80001d50:	bf55                	j	80001d04 <growproc+0x26>

0000000080001d52 <fork>:
{
    80001d52:	7139                	addi	sp,sp,-64
    80001d54:	fc06                	sd	ra,56(sp)
    80001d56:	f822                	sd	s0,48(sp)
    80001d58:	f426                	sd	s1,40(sp)
    80001d5a:	f04a                	sd	s2,32(sp)
    80001d5c:	ec4e                	sd	s3,24(sp)
    80001d5e:	e852                	sd	s4,16(sp)
    80001d60:	e456                	sd	s5,8(sp)
    80001d62:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d64:	00000097          	auipc	ra,0x0
    80001d68:	c84080e7          	jalr	-892(ra) # 800019e8 <myproc>
    80001d6c:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d6e:	00000097          	auipc	ra,0x0
    80001d72:	d9a080e7          	jalr	-614(ra) # 80001b08 <allocproc>
    80001d76:	c17d                	beqz	a0,80001e5c <fork+0x10a>
    80001d78:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d7a:	048ab603          	ld	a2,72(s5)
    80001d7e:	692c                	ld	a1,80(a0)
    80001d80:	050ab503          	ld	a0,80(s5)
    80001d84:	fffff097          	auipc	ra,0xfffff
    80001d88:	6a6080e7          	jalr	1702(ra) # 8000142a <uvmcopy>
    80001d8c:	04054a63          	bltz	a0,80001de0 <fork+0x8e>
  np->sz = p->sz;
    80001d90:	048ab783          	ld	a5,72(s5)
    80001d94:	04fa3423          	sd	a5,72(s4)
  np->parent = p;
    80001d98:	035a3023          	sd	s5,32(s4)
  *(np->tf) = *(p->tf);
    80001d9c:	058ab683          	ld	a3,88(s5)
    80001da0:	87b6                	mv	a5,a3
    80001da2:	058a3703          	ld	a4,88(s4)
    80001da6:	12068693          	addi	a3,a3,288
    80001daa:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dae:	6788                	ld	a0,8(a5)
    80001db0:	6b8c                	ld	a1,16(a5)
    80001db2:	6f90                	ld	a2,24(a5)
    80001db4:	01073023          	sd	a6,0(a4)
    80001db8:	e708                	sd	a0,8(a4)
    80001dba:	eb0c                	sd	a1,16(a4)
    80001dbc:	ef10                	sd	a2,24(a4)
    80001dbe:	02078793          	addi	a5,a5,32
    80001dc2:	02070713          	addi	a4,a4,32
    80001dc6:	fed792e3          	bne	a5,a3,80001daa <fork+0x58>
  np->tf->a0 = 0;
    80001dca:	058a3783          	ld	a5,88(s4)
    80001dce:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001dd2:	0d0a8493          	addi	s1,s5,208
    80001dd6:	0d0a0913          	addi	s2,s4,208
    80001dda:	150a8993          	addi	s3,s5,336
    80001dde:	a00d                	j	80001e00 <fork+0xae>
    freeproc(np);
    80001de0:	8552                	mv	a0,s4
    80001de2:	00000097          	auipc	ra,0x0
    80001de6:	e22080e7          	jalr	-478(ra) # 80001c04 <freeproc>
    release(&np->lock);
    80001dea:	8552                	mv	a0,s4
    80001dec:	fffff097          	auipc	ra,0xfffff
    80001df0:	d3a080e7          	jalr	-710(ra) # 80000b26 <release>
    return -1;
    80001df4:	54fd                	li	s1,-1
    80001df6:	a889                	j	80001e48 <fork+0xf6>
  for(i = 0; i < NOFILE; i++)
    80001df8:	04a1                	addi	s1,s1,8
    80001dfa:	0921                	addi	s2,s2,8
    80001dfc:	01348b63          	beq	s1,s3,80001e12 <fork+0xc0>
    if(p->ofile[i])
    80001e00:	6088                	ld	a0,0(s1)
    80001e02:	d97d                	beqz	a0,80001df8 <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e04:	00003097          	auipc	ra,0x3
    80001e08:	924080e7          	jalr	-1756(ra) # 80004728 <filedup>
    80001e0c:	00a93023          	sd	a0,0(s2)
    80001e10:	b7e5                	j	80001df8 <fork+0xa6>
  np->cwd = idup(p->cwd);
    80001e12:	150ab503          	ld	a0,336(s5)
    80001e16:	00002097          	auipc	ra,0x2
    80001e1a:	856080e7          	jalr	-1962(ra) # 8000366c <idup>
    80001e1e:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e22:	4641                	li	a2,16
    80001e24:	158a8593          	addi	a1,s5,344
    80001e28:	158a0513          	addi	a0,s4,344
    80001e2c:	fffff097          	auipc	ra,0xfffff
    80001e30:	ea8080e7          	jalr	-344(ra) # 80000cd4 <safestrcpy>
  pid = np->pid;
    80001e34:	038a2483          	lw	s1,56(s4)
  np->state = RUNNABLE;
    80001e38:	4789                	li	a5,2
    80001e3a:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e3e:	8552                	mv	a0,s4
    80001e40:	fffff097          	auipc	ra,0xfffff
    80001e44:	ce6080e7          	jalr	-794(ra) # 80000b26 <release>
}
    80001e48:	8526                	mv	a0,s1
    80001e4a:	70e2                	ld	ra,56(sp)
    80001e4c:	7442                	ld	s0,48(sp)
    80001e4e:	74a2                	ld	s1,40(sp)
    80001e50:	7902                	ld	s2,32(sp)
    80001e52:	69e2                	ld	s3,24(sp)
    80001e54:	6a42                	ld	s4,16(sp)
    80001e56:	6aa2                	ld	s5,8(sp)
    80001e58:	6121                	addi	sp,sp,64
    80001e5a:	8082                	ret
    return -1;
    80001e5c:	54fd                	li	s1,-1
    80001e5e:	b7ed                	j	80001e48 <fork+0xf6>

0000000080001e60 <reparent>:
{
    80001e60:	7179                	addi	sp,sp,-48
    80001e62:	f406                	sd	ra,40(sp)
    80001e64:	f022                	sd	s0,32(sp)
    80001e66:	ec26                	sd	s1,24(sp)
    80001e68:	e84a                	sd	s2,16(sp)
    80001e6a:	e44e                	sd	s3,8(sp)
    80001e6c:	e052                	sd	s4,0(sp)
    80001e6e:	1800                	addi	s0,sp,48
    80001e70:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001e72:	00011497          	auipc	s1,0x11
    80001e76:	e8e48493          	addi	s1,s1,-370 # 80012d00 <proc>
      pp->parent = initproc;
    80001e7a:	00028a17          	auipc	s4,0x28
    80001e7e:	1bea0a13          	addi	s4,s4,446 # 8002a038 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001e82:	00017997          	auipc	s3,0x17
    80001e86:	87e98993          	addi	s3,s3,-1922 # 80018700 <tickslock>
    80001e8a:	a029                	j	80001e94 <reparent+0x34>
    80001e8c:	16848493          	addi	s1,s1,360
    80001e90:	03348363          	beq	s1,s3,80001eb6 <reparent+0x56>
    if(pp->parent == p){
    80001e94:	709c                	ld	a5,32(s1)
    80001e96:	ff279be3          	bne	a5,s2,80001e8c <reparent+0x2c>
      acquire(&pp->lock);
    80001e9a:	8526                	mv	a0,s1
    80001e9c:	fffff097          	auipc	ra,0xfffff
    80001ea0:	c22080e7          	jalr	-990(ra) # 80000abe <acquire>
      pp->parent = initproc;
    80001ea4:	000a3783          	ld	a5,0(s4)
    80001ea8:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001eaa:	8526                	mv	a0,s1
    80001eac:	fffff097          	auipc	ra,0xfffff
    80001eb0:	c7a080e7          	jalr	-902(ra) # 80000b26 <release>
    80001eb4:	bfe1                	j	80001e8c <reparent+0x2c>
}
    80001eb6:	70a2                	ld	ra,40(sp)
    80001eb8:	7402                	ld	s0,32(sp)
    80001eba:	64e2                	ld	s1,24(sp)
    80001ebc:	6942                	ld	s2,16(sp)
    80001ebe:	69a2                	ld	s3,8(sp)
    80001ec0:	6a02                	ld	s4,0(sp)
    80001ec2:	6145                	addi	sp,sp,48
    80001ec4:	8082                	ret

0000000080001ec6 <scheduler>:
{
    80001ec6:	715d                	addi	sp,sp,-80
    80001ec8:	e486                	sd	ra,72(sp)
    80001eca:	e0a2                	sd	s0,64(sp)
    80001ecc:	fc26                	sd	s1,56(sp)
    80001ece:	f84a                	sd	s2,48(sp)
    80001ed0:	f44e                	sd	s3,40(sp)
    80001ed2:	f052                	sd	s4,32(sp)
    80001ed4:	ec56                	sd	s5,24(sp)
    80001ed6:	e85a                	sd	s6,16(sp)
    80001ed8:	e45e                	sd	s7,8(sp)
    80001eda:	e062                	sd	s8,0(sp)
    80001edc:	0880                	addi	s0,sp,80
    80001ede:	8792                	mv	a5,tp
  int id = r_tp();
    80001ee0:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ee2:	00779b13          	slli	s6,a5,0x7
    80001ee6:	00011717          	auipc	a4,0x11
    80001eea:	a0270713          	addi	a4,a4,-1534 # 800128e8 <pid_lock>
    80001eee:	975a                	add	a4,a4,s6
    80001ef0:	00073c23          	sd	zero,24(a4)
        swtch(&c->scheduler, &p->context);
    80001ef4:	00011717          	auipc	a4,0x11
    80001ef8:	a1470713          	addi	a4,a4,-1516 # 80012908 <cpus+0x8>
    80001efc:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001efe:	4c0d                	li	s8,3
        c->proc = p;
    80001f00:	079e                	slli	a5,a5,0x7
    80001f02:	00011a17          	auipc	s4,0x11
    80001f06:	9e6a0a13          	addi	s4,s4,-1562 # 800128e8 <pid_lock>
    80001f0a:	9a3e                	add	s4,s4,a5
        found = 1;
    80001f0c:	4b85                	li	s7,1
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f0e:	00016997          	auipc	s3,0x16
    80001f12:	7f298993          	addi	s3,s3,2034 # 80018700 <tickslock>
    80001f16:	a08d                	j	80001f78 <scheduler+0xb2>
      release(&p->lock);
    80001f18:	8526                	mv	a0,s1
    80001f1a:	fffff097          	auipc	ra,0xfffff
    80001f1e:	c0c080e7          	jalr	-1012(ra) # 80000b26 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f22:	16848493          	addi	s1,s1,360
    80001f26:	03348963          	beq	s1,s3,80001f58 <scheduler+0x92>
      acquire(&p->lock);
    80001f2a:	8526                	mv	a0,s1
    80001f2c:	fffff097          	auipc	ra,0xfffff
    80001f30:	b92080e7          	jalr	-1134(ra) # 80000abe <acquire>
      if(p->state == RUNNABLE) {
    80001f34:	4c9c                	lw	a5,24(s1)
    80001f36:	ff2791e3          	bne	a5,s2,80001f18 <scheduler+0x52>
        p->state = RUNNING;
    80001f3a:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001f3e:	009a3c23          	sd	s1,24(s4)
        swtch(&c->scheduler, &p->context);
    80001f42:	06048593          	addi	a1,s1,96
    80001f46:	855a                	mv	a0,s6
    80001f48:	00000097          	auipc	ra,0x0
    80001f4c:	62c080e7          	jalr	1580(ra) # 80002574 <swtch>
        c->proc = 0;
    80001f50:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80001f54:	8ade                	mv	s5,s7
    80001f56:	b7c9                	j	80001f18 <scheduler+0x52>
    if(found == 0){
    80001f58:	020a9063          	bnez	s5,80001f78 <scheduler+0xb2>
  asm volatile("csrr %0, sie" : "=r" (x) );
    80001f5c:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    80001f60:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    80001f64:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f68:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f6c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f70:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80001f74:	10500073          	wfi
  asm volatile("csrr %0, sie" : "=r" (x) );
    80001f78:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    80001f7c:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    80001f80:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f84:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f88:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f8c:	10079073          	csrw	sstatus,a5
    int found = 0;
    80001f90:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f92:	00011497          	auipc	s1,0x11
    80001f96:	d6e48493          	addi	s1,s1,-658 # 80012d00 <proc>
      if(p->state == RUNNABLE) {
    80001f9a:	4909                	li	s2,2
    80001f9c:	b779                	j	80001f2a <scheduler+0x64>

0000000080001f9e <sched>:
{
    80001f9e:	7179                	addi	sp,sp,-48
    80001fa0:	f406                	sd	ra,40(sp)
    80001fa2:	f022                	sd	s0,32(sp)
    80001fa4:	ec26                	sd	s1,24(sp)
    80001fa6:	e84a                	sd	s2,16(sp)
    80001fa8:	e44e                	sd	s3,8(sp)
    80001faa:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fac:	00000097          	auipc	ra,0x0
    80001fb0:	a3c080e7          	jalr	-1476(ra) # 800019e8 <myproc>
    80001fb4:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fb6:	fffff097          	auipc	ra,0xfffff
    80001fba:	ac8080e7          	jalr	-1336(ra) # 80000a7e <holding>
    80001fbe:	c93d                	beqz	a0,80002034 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fc0:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fc2:	2781                	sext.w	a5,a5
    80001fc4:	079e                	slli	a5,a5,0x7
    80001fc6:	00011717          	auipc	a4,0x11
    80001fca:	92270713          	addi	a4,a4,-1758 # 800128e8 <pid_lock>
    80001fce:	97ba                	add	a5,a5,a4
    80001fd0:	0907a703          	lw	a4,144(a5)
    80001fd4:	4785                	li	a5,1
    80001fd6:	06f71763          	bne	a4,a5,80002044 <sched+0xa6>
  if(p->state == RUNNING)
    80001fda:	4c98                	lw	a4,24(s1)
    80001fdc:	478d                	li	a5,3
    80001fde:	06f70b63          	beq	a4,a5,80002054 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fe2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fe6:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fe8:	efb5                	bnez	a5,80002064 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fea:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fec:	00011917          	auipc	s2,0x11
    80001ff0:	8fc90913          	addi	s2,s2,-1796 # 800128e8 <pid_lock>
    80001ff4:	2781                	sext.w	a5,a5
    80001ff6:	079e                	slli	a5,a5,0x7
    80001ff8:	97ca                	add	a5,a5,s2
    80001ffa:	0947a983          	lw	s3,148(a5)
    80001ffe:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->scheduler);
    80002000:	2781                	sext.w	a5,a5
    80002002:	079e                	slli	a5,a5,0x7
    80002004:	00011597          	auipc	a1,0x11
    80002008:	90458593          	addi	a1,a1,-1788 # 80012908 <cpus+0x8>
    8000200c:	95be                	add	a1,a1,a5
    8000200e:	06048513          	addi	a0,s1,96
    80002012:	00000097          	auipc	ra,0x0
    80002016:	562080e7          	jalr	1378(ra) # 80002574 <swtch>
    8000201a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000201c:	2781                	sext.w	a5,a5
    8000201e:	079e                	slli	a5,a5,0x7
    80002020:	97ca                	add	a5,a5,s2
    80002022:	0937aa23          	sw	s3,148(a5)
}
    80002026:	70a2                	ld	ra,40(sp)
    80002028:	7402                	ld	s0,32(sp)
    8000202a:	64e2                	ld	s1,24(sp)
    8000202c:	6942                	ld	s2,16(sp)
    8000202e:	69a2                	ld	s3,8(sp)
    80002030:	6145                	addi	sp,sp,48
    80002032:	8082                	ret
    panic("sched p->lock");
    80002034:	00006517          	auipc	a0,0x6
    80002038:	2b450513          	addi	a0,a0,692 # 800082e8 <userret+0x258>
    8000203c:	ffffe097          	auipc	ra,0xffffe
    80002040:	50c080e7          	jalr	1292(ra) # 80000548 <panic>
    panic("sched locks");
    80002044:	00006517          	auipc	a0,0x6
    80002048:	2b450513          	addi	a0,a0,692 # 800082f8 <userret+0x268>
    8000204c:	ffffe097          	auipc	ra,0xffffe
    80002050:	4fc080e7          	jalr	1276(ra) # 80000548 <panic>
    panic("sched running");
    80002054:	00006517          	auipc	a0,0x6
    80002058:	2b450513          	addi	a0,a0,692 # 80008308 <userret+0x278>
    8000205c:	ffffe097          	auipc	ra,0xffffe
    80002060:	4ec080e7          	jalr	1260(ra) # 80000548 <panic>
    panic("sched interruptible");
    80002064:	00006517          	auipc	a0,0x6
    80002068:	2b450513          	addi	a0,a0,692 # 80008318 <userret+0x288>
    8000206c:	ffffe097          	auipc	ra,0xffffe
    80002070:	4dc080e7          	jalr	1244(ra) # 80000548 <panic>

0000000080002074 <exit>:
{
    80002074:	7179                	addi	sp,sp,-48
    80002076:	f406                	sd	ra,40(sp)
    80002078:	f022                	sd	s0,32(sp)
    8000207a:	ec26                	sd	s1,24(sp)
    8000207c:	e84a                	sd	s2,16(sp)
    8000207e:	e44e                	sd	s3,8(sp)
    80002080:	e052                	sd	s4,0(sp)
    80002082:	1800                	addi	s0,sp,48
    80002084:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002086:	00000097          	auipc	ra,0x0
    8000208a:	962080e7          	jalr	-1694(ra) # 800019e8 <myproc>
    8000208e:	89aa                	mv	s3,a0
  if(p == initproc)
    80002090:	00028797          	auipc	a5,0x28
    80002094:	fa87b783          	ld	a5,-88(a5) # 8002a038 <initproc>
    80002098:	0d050493          	addi	s1,a0,208
    8000209c:	15050913          	addi	s2,a0,336
    800020a0:	02a79363          	bne	a5,a0,800020c6 <exit+0x52>
    panic("init exiting");
    800020a4:	00006517          	auipc	a0,0x6
    800020a8:	28c50513          	addi	a0,a0,652 # 80008330 <userret+0x2a0>
    800020ac:	ffffe097          	auipc	ra,0xffffe
    800020b0:	49c080e7          	jalr	1180(ra) # 80000548 <panic>
      fileclose(f);
    800020b4:	00002097          	auipc	ra,0x2
    800020b8:	6c6080e7          	jalr	1734(ra) # 8000477a <fileclose>
      p->ofile[fd] = 0;
    800020bc:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800020c0:	04a1                	addi	s1,s1,8
    800020c2:	01248563          	beq	s1,s2,800020cc <exit+0x58>
    if(p->ofile[fd]){
    800020c6:	6088                	ld	a0,0(s1)
    800020c8:	f575                	bnez	a0,800020b4 <exit+0x40>
    800020ca:	bfdd                	j	800020c0 <exit+0x4c>
  begin_op(ROOTDEV);
    800020cc:	4501                	li	a0,0
    800020ce:	00002097          	auipc	ra,0x2
    800020d2:	084080e7          	jalr	132(ra) # 80004152 <begin_op>
  iput(p->cwd);
    800020d6:	1509b503          	ld	a0,336(s3)
    800020da:	00001097          	auipc	ra,0x1
    800020de:	6de080e7          	jalr	1758(ra) # 800037b8 <iput>
  end_op(ROOTDEV);
    800020e2:	4501                	li	a0,0
    800020e4:	00002097          	auipc	ra,0x2
    800020e8:	118080e7          	jalr	280(ra) # 800041fc <end_op>
  p->cwd = 0;
    800020ec:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    800020f0:	00028497          	auipc	s1,0x28
    800020f4:	f4848493          	addi	s1,s1,-184 # 8002a038 <initproc>
    800020f8:	6088                	ld	a0,0(s1)
    800020fa:	fffff097          	auipc	ra,0xfffff
    800020fe:	9c4080e7          	jalr	-1596(ra) # 80000abe <acquire>
  wakeup1(initproc);
    80002102:	6088                	ld	a0,0(s1)
    80002104:	fffff097          	auipc	ra,0xfffff
    80002108:	7a4080e7          	jalr	1956(ra) # 800018a8 <wakeup1>
  release(&initproc->lock);
    8000210c:	6088                	ld	a0,0(s1)
    8000210e:	fffff097          	auipc	ra,0xfffff
    80002112:	a18080e7          	jalr	-1512(ra) # 80000b26 <release>
  acquire(&p->lock);
    80002116:	854e                	mv	a0,s3
    80002118:	fffff097          	auipc	ra,0xfffff
    8000211c:	9a6080e7          	jalr	-1626(ra) # 80000abe <acquire>
  struct proc *original_parent = p->parent;
    80002120:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80002124:	854e                	mv	a0,s3
    80002126:	fffff097          	auipc	ra,0xfffff
    8000212a:	a00080e7          	jalr	-1536(ra) # 80000b26 <release>
  acquire(&original_parent->lock);
    8000212e:	8526                	mv	a0,s1
    80002130:	fffff097          	auipc	ra,0xfffff
    80002134:	98e080e7          	jalr	-1650(ra) # 80000abe <acquire>
  acquire(&p->lock);
    80002138:	854e                	mv	a0,s3
    8000213a:	fffff097          	auipc	ra,0xfffff
    8000213e:	984080e7          	jalr	-1660(ra) # 80000abe <acquire>
  reparent(p);
    80002142:	854e                	mv	a0,s3
    80002144:	00000097          	auipc	ra,0x0
    80002148:	d1c080e7          	jalr	-740(ra) # 80001e60 <reparent>
  wakeup1(original_parent);
    8000214c:	8526                	mv	a0,s1
    8000214e:	fffff097          	auipc	ra,0xfffff
    80002152:	75a080e7          	jalr	1882(ra) # 800018a8 <wakeup1>
  p->xstate = status;
    80002156:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    8000215a:	4791                	li	a5,4
    8000215c:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002160:	8526                	mv	a0,s1
    80002162:	fffff097          	auipc	ra,0xfffff
    80002166:	9c4080e7          	jalr	-1596(ra) # 80000b26 <release>
  sched();
    8000216a:	00000097          	auipc	ra,0x0
    8000216e:	e34080e7          	jalr	-460(ra) # 80001f9e <sched>
  panic("zombie exit");
    80002172:	00006517          	auipc	a0,0x6
    80002176:	1ce50513          	addi	a0,a0,462 # 80008340 <userret+0x2b0>
    8000217a:	ffffe097          	auipc	ra,0xffffe
    8000217e:	3ce080e7          	jalr	974(ra) # 80000548 <panic>

0000000080002182 <yield>:
{
    80002182:	1101                	addi	sp,sp,-32
    80002184:	ec06                	sd	ra,24(sp)
    80002186:	e822                	sd	s0,16(sp)
    80002188:	e426                	sd	s1,8(sp)
    8000218a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000218c:	00000097          	auipc	ra,0x0
    80002190:	85c080e7          	jalr	-1956(ra) # 800019e8 <myproc>
    80002194:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002196:	fffff097          	auipc	ra,0xfffff
    8000219a:	928080e7          	jalr	-1752(ra) # 80000abe <acquire>
  p->state = RUNNABLE;
    8000219e:	4789                	li	a5,2
    800021a0:	cc9c                	sw	a5,24(s1)
  sched();
    800021a2:	00000097          	auipc	ra,0x0
    800021a6:	dfc080e7          	jalr	-516(ra) # 80001f9e <sched>
  release(&p->lock);
    800021aa:	8526                	mv	a0,s1
    800021ac:	fffff097          	auipc	ra,0xfffff
    800021b0:	97a080e7          	jalr	-1670(ra) # 80000b26 <release>
}
    800021b4:	60e2                	ld	ra,24(sp)
    800021b6:	6442                	ld	s0,16(sp)
    800021b8:	64a2                	ld	s1,8(sp)
    800021ba:	6105                	addi	sp,sp,32
    800021bc:	8082                	ret

00000000800021be <sleep>:
{
    800021be:	7179                	addi	sp,sp,-48
    800021c0:	f406                	sd	ra,40(sp)
    800021c2:	f022                	sd	s0,32(sp)
    800021c4:	ec26                	sd	s1,24(sp)
    800021c6:	e84a                	sd	s2,16(sp)
    800021c8:	e44e                	sd	s3,8(sp)
    800021ca:	1800                	addi	s0,sp,48
    800021cc:	89aa                	mv	s3,a0
    800021ce:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800021d0:	00000097          	auipc	ra,0x0
    800021d4:	818080e7          	jalr	-2024(ra) # 800019e8 <myproc>
    800021d8:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    800021da:	05250663          	beq	a0,s2,80002226 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    800021de:	fffff097          	auipc	ra,0xfffff
    800021e2:	8e0080e7          	jalr	-1824(ra) # 80000abe <acquire>
    release(lk);
    800021e6:	854a                	mv	a0,s2
    800021e8:	fffff097          	auipc	ra,0xfffff
    800021ec:	93e080e7          	jalr	-1730(ra) # 80000b26 <release>
  p->chan = chan;
    800021f0:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    800021f4:	4785                	li	a5,1
    800021f6:	cc9c                	sw	a5,24(s1)
  sched();
    800021f8:	00000097          	auipc	ra,0x0
    800021fc:	da6080e7          	jalr	-602(ra) # 80001f9e <sched>
  p->chan = 0;
    80002200:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002204:	8526                	mv	a0,s1
    80002206:	fffff097          	auipc	ra,0xfffff
    8000220a:	920080e7          	jalr	-1760(ra) # 80000b26 <release>
    acquire(lk);
    8000220e:	854a                	mv	a0,s2
    80002210:	fffff097          	auipc	ra,0xfffff
    80002214:	8ae080e7          	jalr	-1874(ra) # 80000abe <acquire>
}
    80002218:	70a2                	ld	ra,40(sp)
    8000221a:	7402                	ld	s0,32(sp)
    8000221c:	64e2                	ld	s1,24(sp)
    8000221e:	6942                	ld	s2,16(sp)
    80002220:	69a2                	ld	s3,8(sp)
    80002222:	6145                	addi	sp,sp,48
    80002224:	8082                	ret
  p->chan = chan;
    80002226:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    8000222a:	4785                	li	a5,1
    8000222c:	cd1c                	sw	a5,24(a0)
  sched();
    8000222e:	00000097          	auipc	ra,0x0
    80002232:	d70080e7          	jalr	-656(ra) # 80001f9e <sched>
  p->chan = 0;
    80002236:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    8000223a:	bff9                	j	80002218 <sleep+0x5a>

000000008000223c <wait>:
{
    8000223c:	715d                	addi	sp,sp,-80
    8000223e:	e486                	sd	ra,72(sp)
    80002240:	e0a2                	sd	s0,64(sp)
    80002242:	fc26                	sd	s1,56(sp)
    80002244:	f84a                	sd	s2,48(sp)
    80002246:	f44e                	sd	s3,40(sp)
    80002248:	f052                	sd	s4,32(sp)
    8000224a:	ec56                	sd	s5,24(sp)
    8000224c:	e85a                	sd	s6,16(sp)
    8000224e:	e45e                	sd	s7,8(sp)
    80002250:	0880                	addi	s0,sp,80
    80002252:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002254:	fffff097          	auipc	ra,0xfffff
    80002258:	794080e7          	jalr	1940(ra) # 800019e8 <myproc>
    8000225c:	892a                	mv	s2,a0
  acquire(&p->lock);
    8000225e:	fffff097          	auipc	ra,0xfffff
    80002262:	860080e7          	jalr	-1952(ra) # 80000abe <acquire>
    havekids = 0;
    80002266:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002268:	4a11                	li	s4,4
        havekids = 1;
    8000226a:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    8000226c:	00016997          	auipc	s3,0x16
    80002270:	49498993          	addi	s3,s3,1172 # 80018700 <tickslock>
    havekids = 0;
    80002274:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002276:	00011497          	auipc	s1,0x11
    8000227a:	a8a48493          	addi	s1,s1,-1398 # 80012d00 <proc>
    8000227e:	a08d                	j	800022e0 <wait+0xa4>
          pid = np->pid;
    80002280:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002284:	000b0e63          	beqz	s6,800022a0 <wait+0x64>
    80002288:	4691                	li	a3,4
    8000228a:	03448613          	addi	a2,s1,52
    8000228e:	85da                	mv	a1,s6
    80002290:	05093503          	ld	a0,80(s2)
    80002294:	fffff097          	auipc	ra,0xfffff
    80002298:	350080e7          	jalr	848(ra) # 800015e4 <copyout>
    8000229c:	02054263          	bltz	a0,800022c0 <wait+0x84>
          freeproc(np);
    800022a0:	8526                	mv	a0,s1
    800022a2:	00000097          	auipc	ra,0x0
    800022a6:	962080e7          	jalr	-1694(ra) # 80001c04 <freeproc>
          release(&np->lock);
    800022aa:	8526                	mv	a0,s1
    800022ac:	fffff097          	auipc	ra,0xfffff
    800022b0:	87a080e7          	jalr	-1926(ra) # 80000b26 <release>
          release(&p->lock);
    800022b4:	854a                	mv	a0,s2
    800022b6:	fffff097          	auipc	ra,0xfffff
    800022ba:	870080e7          	jalr	-1936(ra) # 80000b26 <release>
          return pid;
    800022be:	a8a9                	j	80002318 <wait+0xdc>
            release(&np->lock);
    800022c0:	8526                	mv	a0,s1
    800022c2:	fffff097          	auipc	ra,0xfffff
    800022c6:	864080e7          	jalr	-1948(ra) # 80000b26 <release>
            release(&p->lock);
    800022ca:	854a                	mv	a0,s2
    800022cc:	fffff097          	auipc	ra,0xfffff
    800022d0:	85a080e7          	jalr	-1958(ra) # 80000b26 <release>
            return -1;
    800022d4:	59fd                	li	s3,-1
    800022d6:	a089                	j	80002318 <wait+0xdc>
    for(np = proc; np < &proc[NPROC]; np++){
    800022d8:	16848493          	addi	s1,s1,360
    800022dc:	03348463          	beq	s1,s3,80002304 <wait+0xc8>
      if(np->parent == p){
    800022e0:	709c                	ld	a5,32(s1)
    800022e2:	ff279be3          	bne	a5,s2,800022d8 <wait+0x9c>
        acquire(&np->lock);
    800022e6:	8526                	mv	a0,s1
    800022e8:	ffffe097          	auipc	ra,0xffffe
    800022ec:	7d6080e7          	jalr	2006(ra) # 80000abe <acquire>
        if(np->state == ZOMBIE){
    800022f0:	4c9c                	lw	a5,24(s1)
    800022f2:	f94787e3          	beq	a5,s4,80002280 <wait+0x44>
        release(&np->lock);
    800022f6:	8526                	mv	a0,s1
    800022f8:	fffff097          	auipc	ra,0xfffff
    800022fc:	82e080e7          	jalr	-2002(ra) # 80000b26 <release>
        havekids = 1;
    80002300:	8756                	mv	a4,s5
    80002302:	bfd9                	j	800022d8 <wait+0x9c>
    if(!havekids || p->killed){
    80002304:	c701                	beqz	a4,8000230c <wait+0xd0>
    80002306:	03092783          	lw	a5,48(s2)
    8000230a:	c39d                	beqz	a5,80002330 <wait+0xf4>
      release(&p->lock);
    8000230c:	854a                	mv	a0,s2
    8000230e:	fffff097          	auipc	ra,0xfffff
    80002312:	818080e7          	jalr	-2024(ra) # 80000b26 <release>
      return -1;
    80002316:	59fd                	li	s3,-1
}
    80002318:	854e                	mv	a0,s3
    8000231a:	60a6                	ld	ra,72(sp)
    8000231c:	6406                	ld	s0,64(sp)
    8000231e:	74e2                	ld	s1,56(sp)
    80002320:	7942                	ld	s2,48(sp)
    80002322:	79a2                	ld	s3,40(sp)
    80002324:	7a02                	ld	s4,32(sp)
    80002326:	6ae2                	ld	s5,24(sp)
    80002328:	6b42                	ld	s6,16(sp)
    8000232a:	6ba2                	ld	s7,8(sp)
    8000232c:	6161                	addi	sp,sp,80
    8000232e:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002330:	85ca                	mv	a1,s2
    80002332:	854a                	mv	a0,s2
    80002334:	00000097          	auipc	ra,0x0
    80002338:	e8a080e7          	jalr	-374(ra) # 800021be <sleep>
    havekids = 0;
    8000233c:	bf25                	j	80002274 <wait+0x38>

000000008000233e <wakeup>:
{
    8000233e:	7139                	addi	sp,sp,-64
    80002340:	fc06                	sd	ra,56(sp)
    80002342:	f822                	sd	s0,48(sp)
    80002344:	f426                	sd	s1,40(sp)
    80002346:	f04a                	sd	s2,32(sp)
    80002348:	ec4e                	sd	s3,24(sp)
    8000234a:	e852                	sd	s4,16(sp)
    8000234c:	e456                	sd	s5,8(sp)
    8000234e:	0080                	addi	s0,sp,64
    80002350:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002352:	00011497          	auipc	s1,0x11
    80002356:	9ae48493          	addi	s1,s1,-1618 # 80012d00 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    8000235a:	4985                	li	s3,1
      p->state = RUNNABLE;
    8000235c:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    8000235e:	00016917          	auipc	s2,0x16
    80002362:	3a290913          	addi	s2,s2,930 # 80018700 <tickslock>
    80002366:	a811                	j	8000237a <wakeup+0x3c>
    release(&p->lock);
    80002368:	8526                	mv	a0,s1
    8000236a:	ffffe097          	auipc	ra,0xffffe
    8000236e:	7bc080e7          	jalr	1980(ra) # 80000b26 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002372:	16848493          	addi	s1,s1,360
    80002376:	03248063          	beq	s1,s2,80002396 <wakeup+0x58>
    acquire(&p->lock);
    8000237a:	8526                	mv	a0,s1
    8000237c:	ffffe097          	auipc	ra,0xffffe
    80002380:	742080e7          	jalr	1858(ra) # 80000abe <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002384:	4c9c                	lw	a5,24(s1)
    80002386:	ff3791e3          	bne	a5,s3,80002368 <wakeup+0x2a>
    8000238a:	749c                	ld	a5,40(s1)
    8000238c:	fd479ee3          	bne	a5,s4,80002368 <wakeup+0x2a>
      p->state = RUNNABLE;
    80002390:	0154ac23          	sw	s5,24(s1)
    80002394:	bfd1                	j	80002368 <wakeup+0x2a>
}
    80002396:	70e2                	ld	ra,56(sp)
    80002398:	7442                	ld	s0,48(sp)
    8000239a:	74a2                	ld	s1,40(sp)
    8000239c:	7902                	ld	s2,32(sp)
    8000239e:	69e2                	ld	s3,24(sp)
    800023a0:	6a42                	ld	s4,16(sp)
    800023a2:	6aa2                	ld	s5,8(sp)
    800023a4:	6121                	addi	sp,sp,64
    800023a6:	8082                	ret

00000000800023a8 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023a8:	7179                	addi	sp,sp,-48
    800023aa:	f406                	sd	ra,40(sp)
    800023ac:	f022                	sd	s0,32(sp)
    800023ae:	ec26                	sd	s1,24(sp)
    800023b0:	e84a                	sd	s2,16(sp)
    800023b2:	e44e                	sd	s3,8(sp)
    800023b4:	1800                	addi	s0,sp,48
    800023b6:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023b8:	00011497          	auipc	s1,0x11
    800023bc:	94848493          	addi	s1,s1,-1720 # 80012d00 <proc>
    800023c0:	00016997          	auipc	s3,0x16
    800023c4:	34098993          	addi	s3,s3,832 # 80018700 <tickslock>
    acquire(&p->lock);
    800023c8:	8526                	mv	a0,s1
    800023ca:	ffffe097          	auipc	ra,0xffffe
    800023ce:	6f4080e7          	jalr	1780(ra) # 80000abe <acquire>
    if(p->pid == pid){
    800023d2:	5c9c                	lw	a5,56(s1)
    800023d4:	01278d63          	beq	a5,s2,800023ee <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023d8:	8526                	mv	a0,s1
    800023da:	ffffe097          	auipc	ra,0xffffe
    800023de:	74c080e7          	jalr	1868(ra) # 80000b26 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023e2:	16848493          	addi	s1,s1,360
    800023e6:	ff3491e3          	bne	s1,s3,800023c8 <kill+0x20>
  }
  return -1;
    800023ea:	557d                	li	a0,-1
    800023ec:	a821                	j	80002404 <kill+0x5c>
      p->killed = 1;
    800023ee:	4785                	li	a5,1
    800023f0:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    800023f2:	4c98                	lw	a4,24(s1)
    800023f4:	00f70f63          	beq	a4,a5,80002412 <kill+0x6a>
      release(&p->lock);
    800023f8:	8526                	mv	a0,s1
    800023fa:	ffffe097          	auipc	ra,0xffffe
    800023fe:	72c080e7          	jalr	1836(ra) # 80000b26 <release>
      return 0;
    80002402:	4501                	li	a0,0
}
    80002404:	70a2                	ld	ra,40(sp)
    80002406:	7402                	ld	s0,32(sp)
    80002408:	64e2                	ld	s1,24(sp)
    8000240a:	6942                	ld	s2,16(sp)
    8000240c:	69a2                	ld	s3,8(sp)
    8000240e:	6145                	addi	sp,sp,48
    80002410:	8082                	ret
        p->state = RUNNABLE;
    80002412:	4789                	li	a5,2
    80002414:	cc9c                	sw	a5,24(s1)
    80002416:	b7cd                	j	800023f8 <kill+0x50>

0000000080002418 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002418:	7179                	addi	sp,sp,-48
    8000241a:	f406                	sd	ra,40(sp)
    8000241c:	f022                	sd	s0,32(sp)
    8000241e:	ec26                	sd	s1,24(sp)
    80002420:	e84a                	sd	s2,16(sp)
    80002422:	e44e                	sd	s3,8(sp)
    80002424:	e052                	sd	s4,0(sp)
    80002426:	1800                	addi	s0,sp,48
    80002428:	84aa                	mv	s1,a0
    8000242a:	892e                	mv	s2,a1
    8000242c:	89b2                	mv	s3,a2
    8000242e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002430:	fffff097          	auipc	ra,0xfffff
    80002434:	5b8080e7          	jalr	1464(ra) # 800019e8 <myproc>
  if(user_dst){
    80002438:	c08d                	beqz	s1,8000245a <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000243a:	86d2                	mv	a3,s4
    8000243c:	864e                	mv	a2,s3
    8000243e:	85ca                	mv	a1,s2
    80002440:	6928                	ld	a0,80(a0)
    80002442:	fffff097          	auipc	ra,0xfffff
    80002446:	1a2080e7          	jalr	418(ra) # 800015e4 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000244a:	70a2                	ld	ra,40(sp)
    8000244c:	7402                	ld	s0,32(sp)
    8000244e:	64e2                	ld	s1,24(sp)
    80002450:	6942                	ld	s2,16(sp)
    80002452:	69a2                	ld	s3,8(sp)
    80002454:	6a02                	ld	s4,0(sp)
    80002456:	6145                	addi	sp,sp,48
    80002458:	8082                	ret
    memmove((char *)dst, src, len);
    8000245a:	000a061b          	sext.w	a2,s4
    8000245e:	85ce                	mv	a1,s3
    80002460:	854a                	mv	a0,s2
    80002462:	ffffe097          	auipc	ra,0xffffe
    80002466:	77c080e7          	jalr	1916(ra) # 80000bde <memmove>
    return 0;
    8000246a:	8526                	mv	a0,s1
    8000246c:	bff9                	j	8000244a <either_copyout+0x32>

000000008000246e <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000246e:	7179                	addi	sp,sp,-48
    80002470:	f406                	sd	ra,40(sp)
    80002472:	f022                	sd	s0,32(sp)
    80002474:	ec26                	sd	s1,24(sp)
    80002476:	e84a                	sd	s2,16(sp)
    80002478:	e44e                	sd	s3,8(sp)
    8000247a:	e052                	sd	s4,0(sp)
    8000247c:	1800                	addi	s0,sp,48
    8000247e:	892a                	mv	s2,a0
    80002480:	84ae                	mv	s1,a1
    80002482:	89b2                	mv	s3,a2
    80002484:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002486:	fffff097          	auipc	ra,0xfffff
    8000248a:	562080e7          	jalr	1378(ra) # 800019e8 <myproc>
  if(user_src){
    8000248e:	c08d                	beqz	s1,800024b0 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002490:	86d2                	mv	a3,s4
    80002492:	864e                	mv	a2,s3
    80002494:	85ca                	mv	a1,s2
    80002496:	6928                	ld	a0,80(a0)
    80002498:	fffff097          	auipc	ra,0xfffff
    8000249c:	1ee080e7          	jalr	494(ra) # 80001686 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024a0:	70a2                	ld	ra,40(sp)
    800024a2:	7402                	ld	s0,32(sp)
    800024a4:	64e2                	ld	s1,24(sp)
    800024a6:	6942                	ld	s2,16(sp)
    800024a8:	69a2                	ld	s3,8(sp)
    800024aa:	6a02                	ld	s4,0(sp)
    800024ac:	6145                	addi	sp,sp,48
    800024ae:	8082                	ret
    memmove(dst, (char*)src, len);
    800024b0:	000a061b          	sext.w	a2,s4
    800024b4:	85ce                	mv	a1,s3
    800024b6:	854a                	mv	a0,s2
    800024b8:	ffffe097          	auipc	ra,0xffffe
    800024bc:	726080e7          	jalr	1830(ra) # 80000bde <memmove>
    return 0;
    800024c0:	8526                	mv	a0,s1
    800024c2:	bff9                	j	800024a0 <either_copyin+0x32>

00000000800024c4 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024c4:	715d                	addi	sp,sp,-80
    800024c6:	e486                	sd	ra,72(sp)
    800024c8:	e0a2                	sd	s0,64(sp)
    800024ca:	fc26                	sd	s1,56(sp)
    800024cc:	f84a                	sd	s2,48(sp)
    800024ce:	f44e                	sd	s3,40(sp)
    800024d0:	f052                	sd	s4,32(sp)
    800024d2:	ec56                	sd	s5,24(sp)
    800024d4:	e85a                	sd	s6,16(sp)
    800024d6:	e45e                	sd	s7,8(sp)
    800024d8:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800024da:	00006517          	auipc	a0,0x6
    800024de:	cd650513          	addi	a0,a0,-810 # 800081b0 <userret+0x120>
    800024e2:	ffffe097          	auipc	ra,0xffffe
    800024e6:	0b0080e7          	jalr	176(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800024ea:	00011497          	auipc	s1,0x11
    800024ee:	96e48493          	addi	s1,s1,-1682 # 80012e58 <proc+0x158>
    800024f2:	00016917          	auipc	s2,0x16
    800024f6:	36690913          	addi	s2,s2,870 # 80018858 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024fa:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    800024fc:	00006997          	auipc	s3,0x6
    80002500:	e5498993          	addi	s3,s3,-428 # 80008350 <userret+0x2c0>
    printf("%d %s %s", p->pid, state, p->name);
    80002504:	00006a97          	auipc	s5,0x6
    80002508:	e54a8a93          	addi	s5,s5,-428 # 80008358 <userret+0x2c8>
    printf("\n");
    8000250c:	00006a17          	auipc	s4,0x6
    80002510:	ca4a0a13          	addi	s4,s4,-860 # 800081b0 <userret+0x120>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002514:	00006b97          	auipc	s7,0x6
    80002518:	4ecb8b93          	addi	s7,s7,1260 # 80008a00 <states.0>
    8000251c:	a00d                	j	8000253e <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000251e:	ee06a583          	lw	a1,-288(a3)
    80002522:	8556                	mv	a0,s5
    80002524:	ffffe097          	auipc	ra,0xffffe
    80002528:	06e080e7          	jalr	110(ra) # 80000592 <printf>
    printf("\n");
    8000252c:	8552                	mv	a0,s4
    8000252e:	ffffe097          	auipc	ra,0xffffe
    80002532:	064080e7          	jalr	100(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002536:	16848493          	addi	s1,s1,360
    8000253a:	03248263          	beq	s1,s2,8000255e <procdump+0x9a>
    if(p->state == UNUSED)
    8000253e:	86a6                	mv	a3,s1
    80002540:	ec04a783          	lw	a5,-320(s1)
    80002544:	dbed                	beqz	a5,80002536 <procdump+0x72>
      state = "???";
    80002546:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002548:	fcfb6be3          	bltu	s6,a5,8000251e <procdump+0x5a>
    8000254c:	02079713          	slli	a4,a5,0x20
    80002550:	01d75793          	srli	a5,a4,0x1d
    80002554:	97de                	add	a5,a5,s7
    80002556:	6390                	ld	a2,0(a5)
    80002558:	f279                	bnez	a2,8000251e <procdump+0x5a>
      state = "???";
    8000255a:	864e                	mv	a2,s3
    8000255c:	b7c9                	j	8000251e <procdump+0x5a>
  }
}
    8000255e:	60a6                	ld	ra,72(sp)
    80002560:	6406                	ld	s0,64(sp)
    80002562:	74e2                	ld	s1,56(sp)
    80002564:	7942                	ld	s2,48(sp)
    80002566:	79a2                	ld	s3,40(sp)
    80002568:	7a02                	ld	s4,32(sp)
    8000256a:	6ae2                	ld	s5,24(sp)
    8000256c:	6b42                	ld	s6,16(sp)
    8000256e:	6ba2                	ld	s7,8(sp)
    80002570:	6161                	addi	sp,sp,80
    80002572:	8082                	ret

0000000080002574 <swtch>:
    80002574:	00153023          	sd	ra,0(a0)
    80002578:	00253423          	sd	sp,8(a0)
    8000257c:	e900                	sd	s0,16(a0)
    8000257e:	ed04                	sd	s1,24(a0)
    80002580:	03253023          	sd	s2,32(a0)
    80002584:	03353423          	sd	s3,40(a0)
    80002588:	03453823          	sd	s4,48(a0)
    8000258c:	03553c23          	sd	s5,56(a0)
    80002590:	05653023          	sd	s6,64(a0)
    80002594:	05753423          	sd	s7,72(a0)
    80002598:	05853823          	sd	s8,80(a0)
    8000259c:	05953c23          	sd	s9,88(a0)
    800025a0:	07a53023          	sd	s10,96(a0)
    800025a4:	07b53423          	sd	s11,104(a0)
    800025a8:	0005b083          	ld	ra,0(a1)
    800025ac:	0085b103          	ld	sp,8(a1)
    800025b0:	6980                	ld	s0,16(a1)
    800025b2:	6d84                	ld	s1,24(a1)
    800025b4:	0205b903          	ld	s2,32(a1)
    800025b8:	0285b983          	ld	s3,40(a1)
    800025bc:	0305ba03          	ld	s4,48(a1)
    800025c0:	0385ba83          	ld	s5,56(a1)
    800025c4:	0405bb03          	ld	s6,64(a1)
    800025c8:	0485bb83          	ld	s7,72(a1)
    800025cc:	0505bc03          	ld	s8,80(a1)
    800025d0:	0585bc83          	ld	s9,88(a1)
    800025d4:	0605bd03          	ld	s10,96(a1)
    800025d8:	0685bd83          	ld	s11,104(a1)
    800025dc:	8082                	ret

00000000800025de <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800025de:	1141                	addi	sp,sp,-16
    800025e0:	e406                	sd	ra,8(sp)
    800025e2:	e022                	sd	s0,0(sp)
    800025e4:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800025e6:	00006597          	auipc	a1,0x6
    800025ea:	daa58593          	addi	a1,a1,-598 # 80008390 <userret+0x300>
    800025ee:	00016517          	auipc	a0,0x16
    800025f2:	11250513          	addi	a0,a0,274 # 80018700 <tickslock>
    800025f6:	ffffe097          	auipc	ra,0xffffe
    800025fa:	3ba080e7          	jalr	954(ra) # 800009b0 <initlock>
}
    800025fe:	60a2                	ld	ra,8(sp)
    80002600:	6402                	ld	s0,0(sp)
    80002602:	0141                	addi	sp,sp,16
    80002604:	8082                	ret

0000000080002606 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002606:	1141                	addi	sp,sp,-16
    80002608:	e422                	sd	s0,8(sp)
    8000260a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000260c:	00004797          	auipc	a5,0x4
    80002610:	87478793          	addi	a5,a5,-1932 # 80005e80 <kernelvec>
    80002614:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002618:	6422                	ld	s0,8(sp)
    8000261a:	0141                	addi	sp,sp,16
    8000261c:	8082                	ret

000000008000261e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000261e:	1141                	addi	sp,sp,-16
    80002620:	e406                	sd	ra,8(sp)
    80002622:	e022                	sd	s0,0(sp)
    80002624:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002626:	fffff097          	auipc	ra,0xfffff
    8000262a:	3c2080e7          	jalr	962(ra) # 800019e8 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000262e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002632:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002634:	10079073          	csrw	sstatus,a5
  // turn off interrupts, since we're switching
  // now from kerneltrap() to usertrap().
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002638:	00006617          	auipc	a2,0x6
    8000263c:	9c860613          	addi	a2,a2,-1592 # 80008000 <trampoline>
    80002640:	00006697          	auipc	a3,0x6
    80002644:	9c068693          	addi	a3,a3,-1600 # 80008000 <trampoline>
    80002648:	8e91                	sub	a3,a3,a2
    8000264a:	040007b7          	lui	a5,0x4000
    8000264e:	17fd                	addi	a5,a5,-1
    80002650:	07b2                	slli	a5,a5,0xc
    80002652:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002654:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->tf->kernel_satp = r_satp();         // kernel page table
    80002658:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000265a:	180026f3          	csrr	a3,satp
    8000265e:	e314                	sd	a3,0(a4)
  p->tf->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002660:	6d38                	ld	a4,88(a0)
    80002662:	6134                	ld	a3,64(a0)
    80002664:	6585                	lui	a1,0x1
    80002666:	96ae                	add	a3,a3,a1
    80002668:	e714                	sd	a3,8(a4)
  p->tf->kernel_trap = (uint64)usertrap;
    8000266a:	6d38                	ld	a4,88(a0)
    8000266c:	00000697          	auipc	a3,0x0
    80002670:	12868693          	addi	a3,a3,296 # 80002794 <usertrap>
    80002674:	eb14                	sd	a3,16(a4)
  p->tf->kernel_hartid = r_tp();         // hartid for cpuid()
    80002676:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002678:	8692                	mv	a3,tp
    8000267a:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000267c:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002680:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002684:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002688:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->tf->epc);
    8000268c:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000268e:	6f18                	ld	a4,24(a4)
    80002690:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002694:	692c                	ld	a1,80(a0)
    80002696:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002698:	00006717          	auipc	a4,0x6
    8000269c:	9f870713          	addi	a4,a4,-1544 # 80008090 <userret>
    800026a0:	8f11                	sub	a4,a4,a2
    800026a2:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800026a4:	577d                	li	a4,-1
    800026a6:	177e                	slli	a4,a4,0x3f
    800026a8:	8dd9                	or	a1,a1,a4
    800026aa:	02000537          	lui	a0,0x2000
    800026ae:	157d                	addi	a0,a0,-1
    800026b0:	0536                	slli	a0,a0,0xd
    800026b2:	9782                	jalr	a5
}
    800026b4:	60a2                	ld	ra,8(sp)
    800026b6:	6402                	ld	s0,0(sp)
    800026b8:	0141                	addi	sp,sp,16
    800026ba:	8082                	ret

00000000800026bc <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800026bc:	1101                	addi	sp,sp,-32
    800026be:	ec06                	sd	ra,24(sp)
    800026c0:	e822                	sd	s0,16(sp)
    800026c2:	e426                	sd	s1,8(sp)
    800026c4:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800026c6:	00016497          	auipc	s1,0x16
    800026ca:	03a48493          	addi	s1,s1,58 # 80018700 <tickslock>
    800026ce:	8526                	mv	a0,s1
    800026d0:	ffffe097          	auipc	ra,0xffffe
    800026d4:	3ee080e7          	jalr	1006(ra) # 80000abe <acquire>
  ticks++;
    800026d8:	00028517          	auipc	a0,0x28
    800026dc:	96850513          	addi	a0,a0,-1688 # 8002a040 <ticks>
    800026e0:	411c                	lw	a5,0(a0)
    800026e2:	2785                	addiw	a5,a5,1
    800026e4:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800026e6:	00000097          	auipc	ra,0x0
    800026ea:	c58080e7          	jalr	-936(ra) # 8000233e <wakeup>
  release(&tickslock);
    800026ee:	8526                	mv	a0,s1
    800026f0:	ffffe097          	auipc	ra,0xffffe
    800026f4:	436080e7          	jalr	1078(ra) # 80000b26 <release>
}
    800026f8:	60e2                	ld	ra,24(sp)
    800026fa:	6442                	ld	s0,16(sp)
    800026fc:	64a2                	ld	s1,8(sp)
    800026fe:	6105                	addi	sp,sp,32
    80002700:	8082                	ret

0000000080002702 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002702:	1101                	addi	sp,sp,-32
    80002704:	ec06                	sd	ra,24(sp)
    80002706:	e822                	sd	s0,16(sp)
    80002708:	e426                	sd	s1,8(sp)
    8000270a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000270c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002710:	00074d63          	bltz	a4,8000272a <devintr+0x28>
      virtio_disk_intr(irq - VIRTIO0_IRQ);
    }

    plic_complete(irq);
    return 1;
  } else if(scause == 0x8000000000000001L){
    80002714:	57fd                	li	a5,-1
    80002716:	17fe                	slli	a5,a5,0x3f
    80002718:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000271a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000271c:	04f70b63          	beq	a4,a5,80002772 <devintr+0x70>
  }
}
    80002720:	60e2                	ld	ra,24(sp)
    80002722:	6442                	ld	s0,16(sp)
    80002724:	64a2                	ld	s1,8(sp)
    80002726:	6105                	addi	sp,sp,32
    80002728:	8082                	ret
     (scause & 0xff) == 9){
    8000272a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000272e:	46a5                	li	a3,9
    80002730:	fed792e3          	bne	a5,a3,80002714 <devintr+0x12>
    int irq = plic_claim();
    80002734:	00004097          	auipc	ra,0x4
    80002738:	866080e7          	jalr	-1946(ra) # 80005f9a <plic_claim>
    8000273c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000273e:	47a9                	li	a5,10
    80002740:	00f50e63          	beq	a0,a5,8000275c <devintr+0x5a>
    } else if(irq == VIRTIO0_IRQ || irq == VIRTIO1_IRQ ){
    80002744:	fff5079b          	addiw	a5,a0,-1
    80002748:	4705                	li	a4,1
    8000274a:	00f77e63          	bgeu	a4,a5,80002766 <devintr+0x64>
    plic_complete(irq);
    8000274e:	8526                	mv	a0,s1
    80002750:	00004097          	auipc	ra,0x4
    80002754:	86e080e7          	jalr	-1938(ra) # 80005fbe <plic_complete>
    return 1;
    80002758:	4505                	li	a0,1
    8000275a:	b7d9                	j	80002720 <devintr+0x1e>
      uartintr();
    8000275c:	ffffe097          	auipc	ra,0xffffe
    80002760:	0cc080e7          	jalr	204(ra) # 80000828 <uartintr>
    80002764:	b7ed                	j	8000274e <devintr+0x4c>
      virtio_disk_intr(irq - VIRTIO0_IRQ);
    80002766:	853e                	mv	a0,a5
    80002768:	00004097          	auipc	ra,0x4
    8000276c:	e00080e7          	jalr	-512(ra) # 80006568 <virtio_disk_intr>
    80002770:	bff9                	j	8000274e <devintr+0x4c>
    if(cpuid() == 0){
    80002772:	fffff097          	auipc	ra,0xfffff
    80002776:	24a080e7          	jalr	586(ra) # 800019bc <cpuid>
    8000277a:	c901                	beqz	a0,8000278a <devintr+0x88>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000277c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002780:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002782:	14479073          	csrw	sip,a5
    return 2;
    80002786:	4509                	li	a0,2
    80002788:	bf61                	j	80002720 <devintr+0x1e>
      clockintr();
    8000278a:	00000097          	auipc	ra,0x0
    8000278e:	f32080e7          	jalr	-206(ra) # 800026bc <clockintr>
    80002792:	b7ed                	j	8000277c <devintr+0x7a>

0000000080002794 <usertrap>:
{
    80002794:	7179                	addi	sp,sp,-48
    80002796:	f406                	sd	ra,40(sp)
    80002798:	f022                	sd	s0,32(sp)
    8000279a:	ec26                	sd	s1,24(sp)
    8000279c:	e84a                	sd	s2,16(sp)
    8000279e:	e44e                	sd	s3,8(sp)
    800027a0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027a2:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800027a6:	1007f793          	andi	a5,a5,256
    800027aa:	ebad                	bnez	a5,8000281c <usertrap+0x88>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027ac:	00003797          	auipc	a5,0x3
    800027b0:	6d478793          	addi	a5,a5,1748 # 80005e80 <kernelvec>
    800027b4:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800027b8:	fffff097          	auipc	ra,0xfffff
    800027bc:	230080e7          	jalr	560(ra) # 800019e8 <myproc>
    800027c0:	84aa                	mv	s1,a0
  p->tf->epc = r_sepc();
    800027c2:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800027c4:	14102773          	csrr	a4,sepc
    800027c8:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027ca:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800027ce:	47a1                	li	a5,8
    800027d0:	06f71463          	bne	a4,a5,80002838 <usertrap+0xa4>
    if(p->killed)
    800027d4:	591c                	lw	a5,48(a0)
    800027d6:	ebb9                	bnez	a5,8000282c <usertrap+0x98>
    p->tf->epc += 4;
    800027d8:	6cb8                	ld	a4,88(s1)
    800027da:	6f1c                	ld	a5,24(a4)
    800027dc:	0791                	addi	a5,a5,4
    800027de:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sie" : "=r" (x) );
    800027e0:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800027e4:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800027e8:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027ec:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800027f0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027f4:	10079073          	csrw	sstatus,a5
    syscall();
    800027f8:	00000097          	auipc	ra,0x0
    800027fc:	360080e7          	jalr	864(ra) # 80002b58 <syscall>
  if(p->killed)
    80002800:	589c                	lw	a5,48(s1)
    80002802:	10079863          	bnez	a5,80002912 <usertrap+0x17e>
  usertrapret();
    80002806:	00000097          	auipc	ra,0x0
    8000280a:	e18080e7          	jalr	-488(ra) # 8000261e <usertrapret>
}
    8000280e:	70a2                	ld	ra,40(sp)
    80002810:	7402                	ld	s0,32(sp)
    80002812:	64e2                	ld	s1,24(sp)
    80002814:	6942                	ld	s2,16(sp)
    80002816:	69a2                	ld	s3,8(sp)
    80002818:	6145                	addi	sp,sp,48
    8000281a:	8082                	ret
    panic("usertrap: not from user mode");
    8000281c:	00006517          	auipc	a0,0x6
    80002820:	b7c50513          	addi	a0,a0,-1156 # 80008398 <userret+0x308>
    80002824:	ffffe097          	auipc	ra,0xffffe
    80002828:	d24080e7          	jalr	-732(ra) # 80000548 <panic>
      exit(-1);
    8000282c:	557d                	li	a0,-1
    8000282e:	00000097          	auipc	ra,0x0
    80002832:	846080e7          	jalr	-1978(ra) # 80002074 <exit>
    80002836:	b74d                	j	800027d8 <usertrap+0x44>
  } else if((which_dev = devintr()) != 0){
    80002838:	00000097          	auipc	ra,0x0
    8000283c:	eca080e7          	jalr	-310(ra) # 80002702 <devintr>
    80002840:	892a                	mv	s2,a0
    80002842:	e569                	bnez	a0,8000290c <usertrap+0x178>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002844:	14202773          	csrr	a4,scause
  } else if(r_scause() == 13 || r_scause() == 15){
    80002848:	47b5                	li	a5,13
    8000284a:	00f70763          	beq	a4,a5,80002858 <usertrap+0xc4>
    8000284e:	14202773          	csrr	a4,scause
    80002852:	47bd                	li	a5,15
    80002854:	08f71263          	bne	a4,a5,800028d8 <usertrap+0x144>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002858:	143027f3          	csrr	a5,stval
    if(r_stval() >= p->sz || r_stval() <= PGROUNDDOWN(p->tf->sp)) {
    8000285c:	64b8                	ld	a4,72(s1)
    8000285e:	00e7fa63          	bgeu	a5,a4,80002872 <usertrap+0xde>
    80002862:	14302773          	csrr	a4,stval
    80002866:	6cbc                	ld	a5,88(s1)
    80002868:	7b94                	ld	a3,48(a5)
    8000286a:	77fd                	lui	a5,0xfffff
    8000286c:	8ff5                	and	a5,a5,a3
    8000286e:	02e7e163          	bltu	a5,a4,80002890 <usertrap+0xfc>
      p->killed = 1;
    80002872:	4785                	li	a5,1
    80002874:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002876:	557d                	li	a0,-1
    80002878:	fffff097          	auipc	ra,0xfffff
    8000287c:	7fc080e7          	jalr	2044(ra) # 80002074 <exit>
  if(which_dev == 2)
    80002880:	4789                	li	a5,2
    80002882:	f8f912e3          	bne	s2,a5,80002806 <usertrap+0x72>
    yield();
    80002886:	00000097          	auipc	ra,0x0
    8000288a:	8fc080e7          	jalr	-1796(ra) # 80002182 <yield>
    8000288e:	bfa5                	j	80002806 <usertrap+0x72>
      char *mem = kalloc();
    80002890:	ffffe097          	auipc	ra,0xffffe
    80002894:	0c0080e7          	jalr	192(ra) # 80000950 <kalloc>
    80002898:	89aa                	mv	s3,a0
      if(mem == 0){
    8000289a:	cd05                	beqz	a0,800028d2 <usertrap+0x13e>
        memset(mem, 0, PGSIZE);
    8000289c:	6605                	lui	a2,0x1
    8000289e:	4581                	li	a1,0
    800028a0:	ffffe097          	auipc	ra,0xffffe
    800028a4:	2e2080e7          	jalr	738(ra) # 80000b82 <memset>
    800028a8:	143025f3          	csrr	a1,stval
        if(mappages(p->pagetable, PGROUNDDOWN(r_stval()), PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800028ac:	4779                	li	a4,30
    800028ae:	86ce                	mv	a3,s3
    800028b0:	6605                	lui	a2,0x1
    800028b2:	77fd                	lui	a5,0xfffff
    800028b4:	8dfd                	and	a1,a1,a5
    800028b6:	68a8                	ld	a0,80(s1)
    800028b8:	ffffe097          	auipc	ra,0xffffe
    800028bc:	764080e7          	jalr	1892(ra) # 8000101c <mappages>
    800028c0:	d121                	beqz	a0,80002800 <usertrap+0x6c>
          kfree(mem);
    800028c2:	854e                	mv	a0,s3
    800028c4:	ffffe097          	auipc	ra,0xffffe
    800028c8:	f90080e7          	jalr	-112(ra) # 80000854 <kfree>
          p->killed = 1;
    800028cc:	4785                	li	a5,1
    800028ce:	d89c                	sw	a5,48(s1)
    800028d0:	b75d                	j	80002876 <usertrap+0xe2>
        p->killed = 1;
    800028d2:	4785                	li	a5,1
    800028d4:	d89c                	sw	a5,48(s1)
    800028d6:	b745                	j	80002876 <usertrap+0xe2>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028d8:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028dc:	5c90                	lw	a2,56(s1)
    800028de:	00006517          	auipc	a0,0x6
    800028e2:	ada50513          	addi	a0,a0,-1318 # 800083b8 <userret+0x328>
    800028e6:	ffffe097          	auipc	ra,0xffffe
    800028ea:	cac080e7          	jalr	-852(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028ee:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028f2:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028f6:	00006517          	auipc	a0,0x6
    800028fa:	af250513          	addi	a0,a0,-1294 # 800083e8 <userret+0x358>
    800028fe:	ffffe097          	auipc	ra,0xffffe
    80002902:	c94080e7          	jalr	-876(ra) # 80000592 <printf>
    p->killed = 1;
    80002906:	4785                	li	a5,1
    80002908:	d89c                	sw	a5,48(s1)
    8000290a:	b7b5                	j	80002876 <usertrap+0xe2>
  if(p->killed)
    8000290c:	589c                	lw	a5,48(s1)
    8000290e:	dbad                	beqz	a5,80002880 <usertrap+0xec>
    80002910:	b79d                	j	80002876 <usertrap+0xe2>
    80002912:	4901                	li	s2,0
    80002914:	b78d                	j	80002876 <usertrap+0xe2>

0000000080002916 <kerneltrap>:
{
    80002916:	7179                	addi	sp,sp,-48
    80002918:	f406                	sd	ra,40(sp)
    8000291a:	f022                	sd	s0,32(sp)
    8000291c:	ec26                	sd	s1,24(sp)
    8000291e:	e84a                	sd	s2,16(sp)
    80002920:	e44e                	sd	s3,8(sp)
    80002922:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002924:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002928:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000292c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002930:	1004f793          	andi	a5,s1,256
    80002934:	cb85                	beqz	a5,80002964 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002936:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000293a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000293c:	ef85                	bnez	a5,80002974 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000293e:	00000097          	auipc	ra,0x0
    80002942:	dc4080e7          	jalr	-572(ra) # 80002702 <devintr>
    80002946:	cd1d                	beqz	a0,80002984 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002948:	4789                	li	a5,2
    8000294a:	06f50a63          	beq	a0,a5,800029be <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000294e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002952:	10049073          	csrw	sstatus,s1
}
    80002956:	70a2                	ld	ra,40(sp)
    80002958:	7402                	ld	s0,32(sp)
    8000295a:	64e2                	ld	s1,24(sp)
    8000295c:	6942                	ld	s2,16(sp)
    8000295e:	69a2                	ld	s3,8(sp)
    80002960:	6145                	addi	sp,sp,48
    80002962:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002964:	00006517          	auipc	a0,0x6
    80002968:	aa450513          	addi	a0,a0,-1372 # 80008408 <userret+0x378>
    8000296c:	ffffe097          	auipc	ra,0xffffe
    80002970:	bdc080e7          	jalr	-1060(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002974:	00006517          	auipc	a0,0x6
    80002978:	abc50513          	addi	a0,a0,-1348 # 80008430 <userret+0x3a0>
    8000297c:	ffffe097          	auipc	ra,0xffffe
    80002980:	bcc080e7          	jalr	-1076(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002984:	85ce                	mv	a1,s3
    80002986:	00006517          	auipc	a0,0x6
    8000298a:	aca50513          	addi	a0,a0,-1334 # 80008450 <userret+0x3c0>
    8000298e:	ffffe097          	auipc	ra,0xffffe
    80002992:	c04080e7          	jalr	-1020(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002996:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000299a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000299e:	00006517          	auipc	a0,0x6
    800029a2:	ac250513          	addi	a0,a0,-1342 # 80008460 <userret+0x3d0>
    800029a6:	ffffe097          	auipc	ra,0xffffe
    800029aa:	bec080e7          	jalr	-1044(ra) # 80000592 <printf>
    panic("kerneltrap");
    800029ae:	00006517          	auipc	a0,0x6
    800029b2:	aca50513          	addi	a0,a0,-1334 # 80008478 <userret+0x3e8>
    800029b6:	ffffe097          	auipc	ra,0xffffe
    800029ba:	b92080e7          	jalr	-1134(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029be:	fffff097          	auipc	ra,0xfffff
    800029c2:	02a080e7          	jalr	42(ra) # 800019e8 <myproc>
    800029c6:	d541                	beqz	a0,8000294e <kerneltrap+0x38>
    800029c8:	fffff097          	auipc	ra,0xfffff
    800029cc:	020080e7          	jalr	32(ra) # 800019e8 <myproc>
    800029d0:	4d18                	lw	a4,24(a0)
    800029d2:	478d                	li	a5,3
    800029d4:	f6f71de3          	bne	a4,a5,8000294e <kerneltrap+0x38>
    yield();
    800029d8:	fffff097          	auipc	ra,0xfffff
    800029dc:	7aa080e7          	jalr	1962(ra) # 80002182 <yield>
    800029e0:	b7bd                	j	8000294e <kerneltrap+0x38>

00000000800029e2 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800029e2:	1101                	addi	sp,sp,-32
    800029e4:	ec06                	sd	ra,24(sp)
    800029e6:	e822                	sd	s0,16(sp)
    800029e8:	e426                	sd	s1,8(sp)
    800029ea:	1000                	addi	s0,sp,32
    800029ec:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029ee:	fffff097          	auipc	ra,0xfffff
    800029f2:	ffa080e7          	jalr	-6(ra) # 800019e8 <myproc>
  switch (n) {
    800029f6:	4795                	li	a5,5
    800029f8:	0497e163          	bltu	a5,s1,80002a3a <argraw+0x58>
    800029fc:	048a                	slli	s1,s1,0x2
    800029fe:	00006717          	auipc	a4,0x6
    80002a02:	02a70713          	addi	a4,a4,42 # 80008a28 <states.0+0x28>
    80002a06:	94ba                	add	s1,s1,a4
    80002a08:	409c                	lw	a5,0(s1)
    80002a0a:	97ba                	add	a5,a5,a4
    80002a0c:	8782                	jr	a5
  case 0:
    return p->tf->a0;
    80002a0e:	6d3c                	ld	a5,88(a0)
    80002a10:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->tf->a5;
  }
  panic("argraw");
  return -1;
}
    80002a12:	60e2                	ld	ra,24(sp)
    80002a14:	6442                	ld	s0,16(sp)
    80002a16:	64a2                	ld	s1,8(sp)
    80002a18:	6105                	addi	sp,sp,32
    80002a1a:	8082                	ret
    return p->tf->a1;
    80002a1c:	6d3c                	ld	a5,88(a0)
    80002a1e:	7fa8                	ld	a0,120(a5)
    80002a20:	bfcd                	j	80002a12 <argraw+0x30>
    return p->tf->a2;
    80002a22:	6d3c                	ld	a5,88(a0)
    80002a24:	63c8                	ld	a0,128(a5)
    80002a26:	b7f5                	j	80002a12 <argraw+0x30>
    return p->tf->a3;
    80002a28:	6d3c                	ld	a5,88(a0)
    80002a2a:	67c8                	ld	a0,136(a5)
    80002a2c:	b7dd                	j	80002a12 <argraw+0x30>
    return p->tf->a4;
    80002a2e:	6d3c                	ld	a5,88(a0)
    80002a30:	6bc8                	ld	a0,144(a5)
    80002a32:	b7c5                	j	80002a12 <argraw+0x30>
    return p->tf->a5;
    80002a34:	6d3c                	ld	a5,88(a0)
    80002a36:	6fc8                	ld	a0,152(a5)
    80002a38:	bfe9                	j	80002a12 <argraw+0x30>
  panic("argraw");
    80002a3a:	00006517          	auipc	a0,0x6
    80002a3e:	a4e50513          	addi	a0,a0,-1458 # 80008488 <userret+0x3f8>
    80002a42:	ffffe097          	auipc	ra,0xffffe
    80002a46:	b06080e7          	jalr	-1274(ra) # 80000548 <panic>

0000000080002a4a <fetchaddr>:
{
    80002a4a:	1101                	addi	sp,sp,-32
    80002a4c:	ec06                	sd	ra,24(sp)
    80002a4e:	e822                	sd	s0,16(sp)
    80002a50:	e426                	sd	s1,8(sp)
    80002a52:	e04a                	sd	s2,0(sp)
    80002a54:	1000                	addi	s0,sp,32
    80002a56:	84aa                	mv	s1,a0
    80002a58:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a5a:	fffff097          	auipc	ra,0xfffff
    80002a5e:	f8e080e7          	jalr	-114(ra) # 800019e8 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002a62:	653c                	ld	a5,72(a0)
    80002a64:	02f4f863          	bgeu	s1,a5,80002a94 <fetchaddr+0x4a>
    80002a68:	00848713          	addi	a4,s1,8
    80002a6c:	02e7e663          	bltu	a5,a4,80002a98 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a70:	46a1                	li	a3,8
    80002a72:	8626                	mv	a2,s1
    80002a74:	85ca                	mv	a1,s2
    80002a76:	6928                	ld	a0,80(a0)
    80002a78:	fffff097          	auipc	ra,0xfffff
    80002a7c:	c0e080e7          	jalr	-1010(ra) # 80001686 <copyin>
    80002a80:	00a03533          	snez	a0,a0
    80002a84:	40a00533          	neg	a0,a0
}
    80002a88:	60e2                	ld	ra,24(sp)
    80002a8a:	6442                	ld	s0,16(sp)
    80002a8c:	64a2                	ld	s1,8(sp)
    80002a8e:	6902                	ld	s2,0(sp)
    80002a90:	6105                	addi	sp,sp,32
    80002a92:	8082                	ret
    return -1;
    80002a94:	557d                	li	a0,-1
    80002a96:	bfcd                	j	80002a88 <fetchaddr+0x3e>
    80002a98:	557d                	li	a0,-1
    80002a9a:	b7fd                	j	80002a88 <fetchaddr+0x3e>

0000000080002a9c <fetchstr>:
{
    80002a9c:	7179                	addi	sp,sp,-48
    80002a9e:	f406                	sd	ra,40(sp)
    80002aa0:	f022                	sd	s0,32(sp)
    80002aa2:	ec26                	sd	s1,24(sp)
    80002aa4:	e84a                	sd	s2,16(sp)
    80002aa6:	e44e                	sd	s3,8(sp)
    80002aa8:	1800                	addi	s0,sp,48
    80002aaa:	892a                	mv	s2,a0
    80002aac:	84ae                	mv	s1,a1
    80002aae:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ab0:	fffff097          	auipc	ra,0xfffff
    80002ab4:	f38080e7          	jalr	-200(ra) # 800019e8 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002ab8:	86ce                	mv	a3,s3
    80002aba:	864a                	mv	a2,s2
    80002abc:	85a6                	mv	a1,s1
    80002abe:	6928                	ld	a0,80(a0)
    80002ac0:	fffff097          	auipc	ra,0xfffff
    80002ac4:	c6a080e7          	jalr	-918(ra) # 8000172a <copyinstr>
  if(err < 0)
    80002ac8:	00054763          	bltz	a0,80002ad6 <fetchstr+0x3a>
  return strlen(buf);
    80002acc:	8526                	mv	a0,s1
    80002ace:	ffffe097          	auipc	ra,0xffffe
    80002ad2:	238080e7          	jalr	568(ra) # 80000d06 <strlen>
}
    80002ad6:	70a2                	ld	ra,40(sp)
    80002ad8:	7402                	ld	s0,32(sp)
    80002ada:	64e2                	ld	s1,24(sp)
    80002adc:	6942                	ld	s2,16(sp)
    80002ade:	69a2                	ld	s3,8(sp)
    80002ae0:	6145                	addi	sp,sp,48
    80002ae2:	8082                	ret

0000000080002ae4 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002ae4:	1101                	addi	sp,sp,-32
    80002ae6:	ec06                	sd	ra,24(sp)
    80002ae8:	e822                	sd	s0,16(sp)
    80002aea:	e426                	sd	s1,8(sp)
    80002aec:	1000                	addi	s0,sp,32
    80002aee:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002af0:	00000097          	auipc	ra,0x0
    80002af4:	ef2080e7          	jalr	-270(ra) # 800029e2 <argraw>
    80002af8:	c088                	sw	a0,0(s1)
  return 0;
}
    80002afa:	4501                	li	a0,0
    80002afc:	60e2                	ld	ra,24(sp)
    80002afe:	6442                	ld	s0,16(sp)
    80002b00:	64a2                	ld	s1,8(sp)
    80002b02:	6105                	addi	sp,sp,32
    80002b04:	8082                	ret

0000000080002b06 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b06:	1101                	addi	sp,sp,-32
    80002b08:	ec06                	sd	ra,24(sp)
    80002b0a:	e822                	sd	s0,16(sp)
    80002b0c:	e426                	sd	s1,8(sp)
    80002b0e:	1000                	addi	s0,sp,32
    80002b10:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b12:	00000097          	auipc	ra,0x0
    80002b16:	ed0080e7          	jalr	-304(ra) # 800029e2 <argraw>
    80002b1a:	e088                	sd	a0,0(s1)
  return 0;
}
    80002b1c:	4501                	li	a0,0
    80002b1e:	60e2                	ld	ra,24(sp)
    80002b20:	6442                	ld	s0,16(sp)
    80002b22:	64a2                	ld	s1,8(sp)
    80002b24:	6105                	addi	sp,sp,32
    80002b26:	8082                	ret

0000000080002b28 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b28:	1101                	addi	sp,sp,-32
    80002b2a:	ec06                	sd	ra,24(sp)
    80002b2c:	e822                	sd	s0,16(sp)
    80002b2e:	e426                	sd	s1,8(sp)
    80002b30:	e04a                	sd	s2,0(sp)
    80002b32:	1000                	addi	s0,sp,32
    80002b34:	84ae                	mv	s1,a1
    80002b36:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002b38:	00000097          	auipc	ra,0x0
    80002b3c:	eaa080e7          	jalr	-342(ra) # 800029e2 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002b40:	864a                	mv	a2,s2
    80002b42:	85a6                	mv	a1,s1
    80002b44:	00000097          	auipc	ra,0x0
    80002b48:	f58080e7          	jalr	-168(ra) # 80002a9c <fetchstr>
}
    80002b4c:	60e2                	ld	ra,24(sp)
    80002b4e:	6442                	ld	s0,16(sp)
    80002b50:	64a2                	ld	s1,8(sp)
    80002b52:	6902                	ld	s2,0(sp)
    80002b54:	6105                	addi	sp,sp,32
    80002b56:	8082                	ret

0000000080002b58 <syscall>:
[SYS_crash]   sys_crash,
};

void
syscall(void)
{
    80002b58:	1101                	addi	sp,sp,-32
    80002b5a:	ec06                	sd	ra,24(sp)
    80002b5c:	e822                	sd	s0,16(sp)
    80002b5e:	e426                	sd	s1,8(sp)
    80002b60:	e04a                	sd	s2,0(sp)
    80002b62:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002b64:	fffff097          	auipc	ra,0xfffff
    80002b68:	e84080e7          	jalr	-380(ra) # 800019e8 <myproc>
    80002b6c:	84aa                	mv	s1,a0

  num = p->tf->a7;
    80002b6e:	05853903          	ld	s2,88(a0)
    80002b72:	0a893783          	ld	a5,168(s2)
    80002b76:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b7a:	37fd                	addiw	a5,a5,-1
    80002b7c:	4759                	li	a4,22
    80002b7e:	00f76f63          	bltu	a4,a5,80002b9c <syscall+0x44>
    80002b82:	00369713          	slli	a4,a3,0x3
    80002b86:	00006797          	auipc	a5,0x6
    80002b8a:	eba78793          	addi	a5,a5,-326 # 80008a40 <syscalls>
    80002b8e:	97ba                	add	a5,a5,a4
    80002b90:	639c                	ld	a5,0(a5)
    80002b92:	c789                	beqz	a5,80002b9c <syscall+0x44>
    p->tf->a0 = syscalls[num]();
    80002b94:	9782                	jalr	a5
    80002b96:	06a93823          	sd	a0,112(s2)
    80002b9a:	a839                	j	80002bb8 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b9c:	15848613          	addi	a2,s1,344
    80002ba0:	5c8c                	lw	a1,56(s1)
    80002ba2:	00006517          	auipc	a0,0x6
    80002ba6:	8ee50513          	addi	a0,a0,-1810 # 80008490 <userret+0x400>
    80002baa:	ffffe097          	auipc	ra,0xffffe
    80002bae:	9e8080e7          	jalr	-1560(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->tf->a0 = -1;
    80002bb2:	6cbc                	ld	a5,88(s1)
    80002bb4:	577d                	li	a4,-1
    80002bb6:	fbb8                	sd	a4,112(a5)
  }
}
    80002bb8:	60e2                	ld	ra,24(sp)
    80002bba:	6442                	ld	s0,16(sp)
    80002bbc:	64a2                	ld	s1,8(sp)
    80002bbe:	6902                	ld	s2,0(sp)
    80002bc0:	6105                	addi	sp,sp,32
    80002bc2:	8082                	ret

0000000080002bc4 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002bc4:	1101                	addi	sp,sp,-32
    80002bc6:	ec06                	sd	ra,24(sp)
    80002bc8:	e822                	sd	s0,16(sp)
    80002bca:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002bcc:	fec40593          	addi	a1,s0,-20
    80002bd0:	4501                	li	a0,0
    80002bd2:	00000097          	auipc	ra,0x0
    80002bd6:	f12080e7          	jalr	-238(ra) # 80002ae4 <argint>
    return -1;
    80002bda:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002bdc:	00054963          	bltz	a0,80002bee <sys_exit+0x2a>
  exit(n);
    80002be0:	fec42503          	lw	a0,-20(s0)
    80002be4:	fffff097          	auipc	ra,0xfffff
    80002be8:	490080e7          	jalr	1168(ra) # 80002074 <exit>
  return 0;  // not reached
    80002bec:	4781                	li	a5,0
}
    80002bee:	853e                	mv	a0,a5
    80002bf0:	60e2                	ld	ra,24(sp)
    80002bf2:	6442                	ld	s0,16(sp)
    80002bf4:	6105                	addi	sp,sp,32
    80002bf6:	8082                	ret

0000000080002bf8 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002bf8:	1141                	addi	sp,sp,-16
    80002bfa:	e406                	sd	ra,8(sp)
    80002bfc:	e022                	sd	s0,0(sp)
    80002bfe:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c00:	fffff097          	auipc	ra,0xfffff
    80002c04:	de8080e7          	jalr	-536(ra) # 800019e8 <myproc>
}
    80002c08:	5d08                	lw	a0,56(a0)
    80002c0a:	60a2                	ld	ra,8(sp)
    80002c0c:	6402                	ld	s0,0(sp)
    80002c0e:	0141                	addi	sp,sp,16
    80002c10:	8082                	ret

0000000080002c12 <sys_fork>:

uint64
sys_fork(void)
{
    80002c12:	1141                	addi	sp,sp,-16
    80002c14:	e406                	sd	ra,8(sp)
    80002c16:	e022                	sd	s0,0(sp)
    80002c18:	0800                	addi	s0,sp,16
  return fork();
    80002c1a:	fffff097          	auipc	ra,0xfffff
    80002c1e:	138080e7          	jalr	312(ra) # 80001d52 <fork>
}
    80002c22:	60a2                	ld	ra,8(sp)
    80002c24:	6402                	ld	s0,0(sp)
    80002c26:	0141                	addi	sp,sp,16
    80002c28:	8082                	ret

0000000080002c2a <sys_wait>:

uint64
sys_wait(void)
{
    80002c2a:	1101                	addi	sp,sp,-32
    80002c2c:	ec06                	sd	ra,24(sp)
    80002c2e:	e822                	sd	s0,16(sp)
    80002c30:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002c32:	fe840593          	addi	a1,s0,-24
    80002c36:	4501                	li	a0,0
    80002c38:	00000097          	auipc	ra,0x0
    80002c3c:	ece080e7          	jalr	-306(ra) # 80002b06 <argaddr>
    80002c40:	87aa                	mv	a5,a0
    return -1;
    80002c42:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002c44:	0007c863          	bltz	a5,80002c54 <sys_wait+0x2a>
  return wait(p);
    80002c48:	fe843503          	ld	a0,-24(s0)
    80002c4c:	fffff097          	auipc	ra,0xfffff
    80002c50:	5f0080e7          	jalr	1520(ra) # 8000223c <wait>
}
    80002c54:	60e2                	ld	ra,24(sp)
    80002c56:	6442                	ld	s0,16(sp)
    80002c58:	6105                	addi	sp,sp,32
    80002c5a:	8082                	ret

0000000080002c5c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c5c:	7179                	addi	sp,sp,-48
    80002c5e:	f406                	sd	ra,40(sp)
    80002c60:	f022                	sd	s0,32(sp)
    80002c62:	ec26                	sd	s1,24(sp)
    80002c64:	e84a                	sd	s2,16(sp)
    80002c66:	1800                	addi	s0,sp,48
  int addr;
  int newaddr;
  int n;

  if(argint(0, &n) < 0){
    80002c68:	fdc40593          	addi	a1,s0,-36
    80002c6c:	4501                	li	a0,0
    80002c6e:	00000097          	auipc	ra,0x0
    80002c72:	e76080e7          	jalr	-394(ra) # 80002ae4 <argint>
    80002c76:	04054363          	bltz	a0,80002cbc <sys_sbrk+0x60>
    printf("vf tm ii ui le");
    return -1;
  }
  addr = myproc()->sz;
    80002c7a:	fffff097          	auipc	ra,0xfffff
    80002c7e:	d6e080e7          	jalr	-658(ra) # 800019e8 <myproc>
    80002c82:	04852903          	lw	s2,72(a0)
  // if(growproc(n) < 0)
  //   return -1;

  newaddr = PGROUNDUP(addr + n);
    80002c86:	fdc42483          	lw	s1,-36(s0)
    80002c8a:	012484bb          	addw	s1,s1,s2
    80002c8e:	6785                	lui	a5,0x1
    80002c90:	37fd                	addiw	a5,a5,-1
    80002c92:	9cbd                	addw	s1,s1,a5
    80002c94:	77fd                	lui	a5,0xfffff
    80002c96:	8cfd                	and	s1,s1,a5
    80002c98:	2481                	sext.w	s1,s1
  // kill the shit in kernel
  if(newaddr < PGSIZE || newaddr >= MAXVA)
    80002c9a:	6785                	lui	a5,0x1
    80002c9c:	02f4ca63          	blt	s1,a5,80002cd0 <sys_sbrk+0x74>
    exit(-1);
  // instantly free mem
  if(newaddr < addr){
    80002ca0:	0324ce63          	blt	s1,s2,80002cdc <sys_sbrk+0x80>
    uvmdealloc(myproc()->pagetable, addr, newaddr);
  }
  myproc()->sz = newaddr;
    80002ca4:	fffff097          	auipc	ra,0xfffff
    80002ca8:	d44080e7          	jalr	-700(ra) # 800019e8 <myproc>
    80002cac:	e524                	sd	s1,72(a0)
  return addr;
    80002cae:	854a                	mv	a0,s2
}
    80002cb0:	70a2                	ld	ra,40(sp)
    80002cb2:	7402                	ld	s0,32(sp)
    80002cb4:	64e2                	ld	s1,24(sp)
    80002cb6:	6942                	ld	s2,16(sp)
    80002cb8:	6145                	addi	sp,sp,48
    80002cba:	8082                	ret
    printf("vf tm ii ui le");
    80002cbc:	00005517          	auipc	a0,0x5
    80002cc0:	7f450513          	addi	a0,a0,2036 # 800084b0 <userret+0x420>
    80002cc4:	ffffe097          	auipc	ra,0xffffe
    80002cc8:	8ce080e7          	jalr	-1842(ra) # 80000592 <printf>
    return -1;
    80002ccc:	557d                	li	a0,-1
    80002cce:	b7cd                	j	80002cb0 <sys_sbrk+0x54>
    exit(-1);
    80002cd0:	557d                	li	a0,-1
    80002cd2:	fffff097          	auipc	ra,0xfffff
    80002cd6:	3a2080e7          	jalr	930(ra) # 80002074 <exit>
    80002cda:	b7d9                	j	80002ca0 <sys_sbrk+0x44>
    uvmdealloc(myproc()->pagetable, addr, newaddr);
    80002cdc:	fffff097          	auipc	ra,0xfffff
    80002ce0:	d0c080e7          	jalr	-756(ra) # 800019e8 <myproc>
    80002ce4:	8626                	mv	a2,s1
    80002ce6:	85ca                	mv	a1,s2
    80002ce8:	6928                	ld	a0,80(a0)
    80002cea:	ffffe097          	auipc	ra,0xffffe
    80002cee:	624080e7          	jalr	1572(ra) # 8000130e <uvmdealloc>
    80002cf2:	bf4d                	j	80002ca4 <sys_sbrk+0x48>

0000000080002cf4 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002cf4:	7139                	addi	sp,sp,-64
    80002cf6:	fc06                	sd	ra,56(sp)
    80002cf8:	f822                	sd	s0,48(sp)
    80002cfa:	f426                	sd	s1,40(sp)
    80002cfc:	f04a                	sd	s2,32(sp)
    80002cfe:	ec4e                	sd	s3,24(sp)
    80002d00:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d02:	fcc40593          	addi	a1,s0,-52
    80002d06:	4501                	li	a0,0
    80002d08:	00000097          	auipc	ra,0x0
    80002d0c:	ddc080e7          	jalr	-548(ra) # 80002ae4 <argint>
    return -1;
    80002d10:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d12:	06054563          	bltz	a0,80002d7c <sys_sleep+0x88>
  acquire(&tickslock);
    80002d16:	00016517          	auipc	a0,0x16
    80002d1a:	9ea50513          	addi	a0,a0,-1558 # 80018700 <tickslock>
    80002d1e:	ffffe097          	auipc	ra,0xffffe
    80002d22:	da0080e7          	jalr	-608(ra) # 80000abe <acquire>
  ticks0 = ticks;
    80002d26:	00027917          	auipc	s2,0x27
    80002d2a:	31a92903          	lw	s2,794(s2) # 8002a040 <ticks>
  while(ticks - ticks0 < n){
    80002d2e:	fcc42783          	lw	a5,-52(s0)
    80002d32:	cf85                	beqz	a5,80002d6a <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d34:	00016997          	auipc	s3,0x16
    80002d38:	9cc98993          	addi	s3,s3,-1588 # 80018700 <tickslock>
    80002d3c:	00027497          	auipc	s1,0x27
    80002d40:	30448493          	addi	s1,s1,772 # 8002a040 <ticks>
    if(myproc()->killed){
    80002d44:	fffff097          	auipc	ra,0xfffff
    80002d48:	ca4080e7          	jalr	-860(ra) # 800019e8 <myproc>
    80002d4c:	591c                	lw	a5,48(a0)
    80002d4e:	ef9d                	bnez	a5,80002d8c <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002d50:	85ce                	mv	a1,s3
    80002d52:	8526                	mv	a0,s1
    80002d54:	fffff097          	auipc	ra,0xfffff
    80002d58:	46a080e7          	jalr	1130(ra) # 800021be <sleep>
  while(ticks - ticks0 < n){
    80002d5c:	409c                	lw	a5,0(s1)
    80002d5e:	412787bb          	subw	a5,a5,s2
    80002d62:	fcc42703          	lw	a4,-52(s0)
    80002d66:	fce7efe3          	bltu	a5,a4,80002d44 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002d6a:	00016517          	auipc	a0,0x16
    80002d6e:	99650513          	addi	a0,a0,-1642 # 80018700 <tickslock>
    80002d72:	ffffe097          	auipc	ra,0xffffe
    80002d76:	db4080e7          	jalr	-588(ra) # 80000b26 <release>
  return 0;
    80002d7a:	4781                	li	a5,0
}
    80002d7c:	853e                	mv	a0,a5
    80002d7e:	70e2                	ld	ra,56(sp)
    80002d80:	7442                	ld	s0,48(sp)
    80002d82:	74a2                	ld	s1,40(sp)
    80002d84:	7902                	ld	s2,32(sp)
    80002d86:	69e2                	ld	s3,24(sp)
    80002d88:	6121                	addi	sp,sp,64
    80002d8a:	8082                	ret
      release(&tickslock);
    80002d8c:	00016517          	auipc	a0,0x16
    80002d90:	97450513          	addi	a0,a0,-1676 # 80018700 <tickslock>
    80002d94:	ffffe097          	auipc	ra,0xffffe
    80002d98:	d92080e7          	jalr	-622(ra) # 80000b26 <release>
      return -1;
    80002d9c:	57fd                	li	a5,-1
    80002d9e:	bff9                	j	80002d7c <sys_sleep+0x88>

0000000080002da0 <sys_kill>:

uint64
sys_kill(void)
{
    80002da0:	1101                	addi	sp,sp,-32
    80002da2:	ec06                	sd	ra,24(sp)
    80002da4:	e822                	sd	s0,16(sp)
    80002da6:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002da8:	fec40593          	addi	a1,s0,-20
    80002dac:	4501                	li	a0,0
    80002dae:	00000097          	auipc	ra,0x0
    80002db2:	d36080e7          	jalr	-714(ra) # 80002ae4 <argint>
    80002db6:	87aa                	mv	a5,a0
    return -1;
    80002db8:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002dba:	0007c863          	bltz	a5,80002dca <sys_kill+0x2a>
  return kill(pid);
    80002dbe:	fec42503          	lw	a0,-20(s0)
    80002dc2:	fffff097          	auipc	ra,0xfffff
    80002dc6:	5e6080e7          	jalr	1510(ra) # 800023a8 <kill>
}
    80002dca:	60e2                	ld	ra,24(sp)
    80002dcc:	6442                	ld	s0,16(sp)
    80002dce:	6105                	addi	sp,sp,32
    80002dd0:	8082                	ret

0000000080002dd2 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002dd2:	1101                	addi	sp,sp,-32
    80002dd4:	ec06                	sd	ra,24(sp)
    80002dd6:	e822                	sd	s0,16(sp)
    80002dd8:	e426                	sd	s1,8(sp)
    80002dda:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002ddc:	00016517          	auipc	a0,0x16
    80002de0:	92450513          	addi	a0,a0,-1756 # 80018700 <tickslock>
    80002de4:	ffffe097          	auipc	ra,0xffffe
    80002de8:	cda080e7          	jalr	-806(ra) # 80000abe <acquire>
  xticks = ticks;
    80002dec:	00027497          	auipc	s1,0x27
    80002df0:	2544a483          	lw	s1,596(s1) # 8002a040 <ticks>
  release(&tickslock);
    80002df4:	00016517          	auipc	a0,0x16
    80002df8:	90c50513          	addi	a0,a0,-1780 # 80018700 <tickslock>
    80002dfc:	ffffe097          	auipc	ra,0xffffe
    80002e00:	d2a080e7          	jalr	-726(ra) # 80000b26 <release>
  return xticks;
}
    80002e04:	02049513          	slli	a0,s1,0x20
    80002e08:	9101                	srli	a0,a0,0x20
    80002e0a:	60e2                	ld	ra,24(sp)
    80002e0c:	6442                	ld	s0,16(sp)
    80002e0e:	64a2                	ld	s1,8(sp)
    80002e10:	6105                	addi	sp,sp,32
    80002e12:	8082                	ret

0000000080002e14 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e14:	7179                	addi	sp,sp,-48
    80002e16:	f406                	sd	ra,40(sp)
    80002e18:	f022                	sd	s0,32(sp)
    80002e1a:	ec26                	sd	s1,24(sp)
    80002e1c:	e84a                	sd	s2,16(sp)
    80002e1e:	e44e                	sd	s3,8(sp)
    80002e20:	e052                	sd	s4,0(sp)
    80002e22:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e24:	00005597          	auipc	a1,0x5
    80002e28:	69c58593          	addi	a1,a1,1692 # 800084c0 <userret+0x430>
    80002e2c:	00016517          	auipc	a0,0x16
    80002e30:	8ec50513          	addi	a0,a0,-1812 # 80018718 <bcache>
    80002e34:	ffffe097          	auipc	ra,0xffffe
    80002e38:	b7c080e7          	jalr	-1156(ra) # 800009b0 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e3c:	0001e797          	auipc	a5,0x1e
    80002e40:	8dc78793          	addi	a5,a5,-1828 # 80020718 <bcache+0x8000>
    80002e44:	0001e717          	auipc	a4,0x1e
    80002e48:	c2c70713          	addi	a4,a4,-980 # 80020a70 <bcache+0x8358>
    80002e4c:	3ae7b023          	sd	a4,928(a5)
  bcache.head.next = &bcache.head;
    80002e50:	3ae7b423          	sd	a4,936(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e54:	00016497          	auipc	s1,0x16
    80002e58:	8dc48493          	addi	s1,s1,-1828 # 80018730 <bcache+0x18>
    b->next = bcache.head.next;
    80002e5c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002e5e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002e60:	00005a17          	auipc	s4,0x5
    80002e64:	668a0a13          	addi	s4,s4,1640 # 800084c8 <userret+0x438>
    b->next = bcache.head.next;
    80002e68:	3a893783          	ld	a5,936(s2)
    80002e6c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002e6e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002e72:	85d2                	mv	a1,s4
    80002e74:	01048513          	addi	a0,s1,16
    80002e78:	00001097          	auipc	ra,0x1
    80002e7c:	6f4080e7          	jalr	1780(ra) # 8000456c <initsleeplock>
    bcache.head.next->prev = b;
    80002e80:	3a893783          	ld	a5,936(s2)
    80002e84:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002e86:	3a993423          	sd	s1,936(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e8a:	46048493          	addi	s1,s1,1120
    80002e8e:	fd349de3          	bne	s1,s3,80002e68 <binit+0x54>
  }
}
    80002e92:	70a2                	ld	ra,40(sp)
    80002e94:	7402                	ld	s0,32(sp)
    80002e96:	64e2                	ld	s1,24(sp)
    80002e98:	6942                	ld	s2,16(sp)
    80002e9a:	69a2                	ld	s3,8(sp)
    80002e9c:	6a02                	ld	s4,0(sp)
    80002e9e:	6145                	addi	sp,sp,48
    80002ea0:	8082                	ret

0000000080002ea2 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002ea2:	7179                	addi	sp,sp,-48
    80002ea4:	f406                	sd	ra,40(sp)
    80002ea6:	f022                	sd	s0,32(sp)
    80002ea8:	ec26                	sd	s1,24(sp)
    80002eaa:	e84a                	sd	s2,16(sp)
    80002eac:	e44e                	sd	s3,8(sp)
    80002eae:	1800                	addi	s0,sp,48
    80002eb0:	892a                	mv	s2,a0
    80002eb2:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002eb4:	00016517          	auipc	a0,0x16
    80002eb8:	86450513          	addi	a0,a0,-1948 # 80018718 <bcache>
    80002ebc:	ffffe097          	auipc	ra,0xffffe
    80002ec0:	c02080e7          	jalr	-1022(ra) # 80000abe <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002ec4:	0001e497          	auipc	s1,0x1e
    80002ec8:	bfc4b483          	ld	s1,-1028(s1) # 80020ac0 <bcache+0x83a8>
    80002ecc:	0001e797          	auipc	a5,0x1e
    80002ed0:	ba478793          	addi	a5,a5,-1116 # 80020a70 <bcache+0x8358>
    80002ed4:	02f48f63          	beq	s1,a5,80002f12 <bread+0x70>
    80002ed8:	873e                	mv	a4,a5
    80002eda:	a021                	j	80002ee2 <bread+0x40>
    80002edc:	68a4                	ld	s1,80(s1)
    80002ede:	02e48a63          	beq	s1,a4,80002f12 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002ee2:	449c                	lw	a5,8(s1)
    80002ee4:	ff279ce3          	bne	a5,s2,80002edc <bread+0x3a>
    80002ee8:	44dc                	lw	a5,12(s1)
    80002eea:	ff3799e3          	bne	a5,s3,80002edc <bread+0x3a>
      b->refcnt++;
    80002eee:	40bc                	lw	a5,64(s1)
    80002ef0:	2785                	addiw	a5,a5,1
    80002ef2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ef4:	00016517          	auipc	a0,0x16
    80002ef8:	82450513          	addi	a0,a0,-2012 # 80018718 <bcache>
    80002efc:	ffffe097          	auipc	ra,0xffffe
    80002f00:	c2a080e7          	jalr	-982(ra) # 80000b26 <release>
      acquiresleep(&b->lock);
    80002f04:	01048513          	addi	a0,s1,16
    80002f08:	00001097          	auipc	ra,0x1
    80002f0c:	69e080e7          	jalr	1694(ra) # 800045a6 <acquiresleep>
      return b;
    80002f10:	a8b9                	j	80002f6e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f12:	0001e497          	auipc	s1,0x1e
    80002f16:	ba64b483          	ld	s1,-1114(s1) # 80020ab8 <bcache+0x83a0>
    80002f1a:	0001e797          	auipc	a5,0x1e
    80002f1e:	b5678793          	addi	a5,a5,-1194 # 80020a70 <bcache+0x8358>
    80002f22:	00f48863          	beq	s1,a5,80002f32 <bread+0x90>
    80002f26:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f28:	40bc                	lw	a5,64(s1)
    80002f2a:	cf81                	beqz	a5,80002f42 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f2c:	64a4                	ld	s1,72(s1)
    80002f2e:	fee49de3          	bne	s1,a4,80002f28 <bread+0x86>
  panic("bget: no buffers");
    80002f32:	00005517          	auipc	a0,0x5
    80002f36:	59e50513          	addi	a0,a0,1438 # 800084d0 <userret+0x440>
    80002f3a:	ffffd097          	auipc	ra,0xffffd
    80002f3e:	60e080e7          	jalr	1550(ra) # 80000548 <panic>
      b->dev = dev;
    80002f42:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002f46:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002f4a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002f4e:	4785                	li	a5,1
    80002f50:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f52:	00015517          	auipc	a0,0x15
    80002f56:	7c650513          	addi	a0,a0,1990 # 80018718 <bcache>
    80002f5a:	ffffe097          	auipc	ra,0xffffe
    80002f5e:	bcc080e7          	jalr	-1076(ra) # 80000b26 <release>
      acquiresleep(&b->lock);
    80002f62:	01048513          	addi	a0,s1,16
    80002f66:	00001097          	auipc	ra,0x1
    80002f6a:	640080e7          	jalr	1600(ra) # 800045a6 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f6e:	409c                	lw	a5,0(s1)
    80002f70:	cb89                	beqz	a5,80002f82 <bread+0xe0>
    virtio_disk_rw(b->dev, b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f72:	8526                	mv	a0,s1
    80002f74:	70a2                	ld	ra,40(sp)
    80002f76:	7402                	ld	s0,32(sp)
    80002f78:	64e2                	ld	s1,24(sp)
    80002f7a:	6942                	ld	s2,16(sp)
    80002f7c:	69a2                	ld	s3,8(sp)
    80002f7e:	6145                	addi	sp,sp,48
    80002f80:	8082                	ret
    virtio_disk_rw(b->dev, b, 0);
    80002f82:	4601                	li	a2,0
    80002f84:	85a6                	mv	a1,s1
    80002f86:	4488                	lw	a0,8(s1)
    80002f88:	00003097          	auipc	ra,0x3
    80002f8c:	2e4080e7          	jalr	740(ra) # 8000626c <virtio_disk_rw>
    b->valid = 1;
    80002f90:	4785                	li	a5,1
    80002f92:	c09c                	sw	a5,0(s1)
  return b;
    80002f94:	bff9                	j	80002f72 <bread+0xd0>

0000000080002f96 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f96:	1101                	addi	sp,sp,-32
    80002f98:	ec06                	sd	ra,24(sp)
    80002f9a:	e822                	sd	s0,16(sp)
    80002f9c:	e426                	sd	s1,8(sp)
    80002f9e:	1000                	addi	s0,sp,32
    80002fa0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002fa2:	0541                	addi	a0,a0,16
    80002fa4:	00001097          	auipc	ra,0x1
    80002fa8:	69c080e7          	jalr	1692(ra) # 80004640 <holdingsleep>
    80002fac:	cd09                	beqz	a0,80002fc6 <bwrite+0x30>
    panic("bwrite");
  virtio_disk_rw(b->dev, b, 1);
    80002fae:	4605                	li	a2,1
    80002fb0:	85a6                	mv	a1,s1
    80002fb2:	4488                	lw	a0,8(s1)
    80002fb4:	00003097          	auipc	ra,0x3
    80002fb8:	2b8080e7          	jalr	696(ra) # 8000626c <virtio_disk_rw>
}
    80002fbc:	60e2                	ld	ra,24(sp)
    80002fbe:	6442                	ld	s0,16(sp)
    80002fc0:	64a2                	ld	s1,8(sp)
    80002fc2:	6105                	addi	sp,sp,32
    80002fc4:	8082                	ret
    panic("bwrite");
    80002fc6:	00005517          	auipc	a0,0x5
    80002fca:	52250513          	addi	a0,a0,1314 # 800084e8 <userret+0x458>
    80002fce:	ffffd097          	auipc	ra,0xffffd
    80002fd2:	57a080e7          	jalr	1402(ra) # 80000548 <panic>

0000000080002fd6 <brelse>:

// Release a locked buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
    80002fd6:	1101                	addi	sp,sp,-32
    80002fd8:	ec06                	sd	ra,24(sp)
    80002fda:	e822                	sd	s0,16(sp)
    80002fdc:	e426                	sd	s1,8(sp)
    80002fde:	e04a                	sd	s2,0(sp)
    80002fe0:	1000                	addi	s0,sp,32
    80002fe2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002fe4:	01050913          	addi	s2,a0,16
    80002fe8:	854a                	mv	a0,s2
    80002fea:	00001097          	auipc	ra,0x1
    80002fee:	656080e7          	jalr	1622(ra) # 80004640 <holdingsleep>
    80002ff2:	c92d                	beqz	a0,80003064 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002ff4:	854a                	mv	a0,s2
    80002ff6:	00001097          	auipc	ra,0x1
    80002ffa:	606080e7          	jalr	1542(ra) # 800045fc <releasesleep>

  acquire(&bcache.lock);
    80002ffe:	00015517          	auipc	a0,0x15
    80003002:	71a50513          	addi	a0,a0,1818 # 80018718 <bcache>
    80003006:	ffffe097          	auipc	ra,0xffffe
    8000300a:	ab8080e7          	jalr	-1352(ra) # 80000abe <acquire>
  b->refcnt--;
    8000300e:	40bc                	lw	a5,64(s1)
    80003010:	37fd                	addiw	a5,a5,-1
    80003012:	0007871b          	sext.w	a4,a5
    80003016:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003018:	eb05                	bnez	a4,80003048 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000301a:	68bc                	ld	a5,80(s1)
    8000301c:	64b8                	ld	a4,72(s1)
    8000301e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003020:	64bc                	ld	a5,72(s1)
    80003022:	68b8                	ld	a4,80(s1)
    80003024:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003026:	0001d797          	auipc	a5,0x1d
    8000302a:	6f278793          	addi	a5,a5,1778 # 80020718 <bcache+0x8000>
    8000302e:	3a87b703          	ld	a4,936(a5)
    80003032:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003034:	0001e717          	auipc	a4,0x1e
    80003038:	a3c70713          	addi	a4,a4,-1476 # 80020a70 <bcache+0x8358>
    8000303c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000303e:	3a87b703          	ld	a4,936(a5)
    80003042:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003044:	3a97b423          	sd	s1,936(a5)
  }
  
  release(&bcache.lock);
    80003048:	00015517          	auipc	a0,0x15
    8000304c:	6d050513          	addi	a0,a0,1744 # 80018718 <bcache>
    80003050:	ffffe097          	auipc	ra,0xffffe
    80003054:	ad6080e7          	jalr	-1322(ra) # 80000b26 <release>
}
    80003058:	60e2                	ld	ra,24(sp)
    8000305a:	6442                	ld	s0,16(sp)
    8000305c:	64a2                	ld	s1,8(sp)
    8000305e:	6902                	ld	s2,0(sp)
    80003060:	6105                	addi	sp,sp,32
    80003062:	8082                	ret
    panic("brelse");
    80003064:	00005517          	auipc	a0,0x5
    80003068:	48c50513          	addi	a0,a0,1164 # 800084f0 <userret+0x460>
    8000306c:	ffffd097          	auipc	ra,0xffffd
    80003070:	4dc080e7          	jalr	1244(ra) # 80000548 <panic>

0000000080003074 <bpin>:

void
bpin(struct buf *b) {
    80003074:	1101                	addi	sp,sp,-32
    80003076:	ec06                	sd	ra,24(sp)
    80003078:	e822                	sd	s0,16(sp)
    8000307a:	e426                	sd	s1,8(sp)
    8000307c:	1000                	addi	s0,sp,32
    8000307e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003080:	00015517          	auipc	a0,0x15
    80003084:	69850513          	addi	a0,a0,1688 # 80018718 <bcache>
    80003088:	ffffe097          	auipc	ra,0xffffe
    8000308c:	a36080e7          	jalr	-1482(ra) # 80000abe <acquire>
  b->refcnt++;
    80003090:	40bc                	lw	a5,64(s1)
    80003092:	2785                	addiw	a5,a5,1
    80003094:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003096:	00015517          	auipc	a0,0x15
    8000309a:	68250513          	addi	a0,a0,1666 # 80018718 <bcache>
    8000309e:	ffffe097          	auipc	ra,0xffffe
    800030a2:	a88080e7          	jalr	-1400(ra) # 80000b26 <release>
}
    800030a6:	60e2                	ld	ra,24(sp)
    800030a8:	6442                	ld	s0,16(sp)
    800030aa:	64a2                	ld	s1,8(sp)
    800030ac:	6105                	addi	sp,sp,32
    800030ae:	8082                	ret

00000000800030b0 <bunpin>:

void
bunpin(struct buf *b) {
    800030b0:	1101                	addi	sp,sp,-32
    800030b2:	ec06                	sd	ra,24(sp)
    800030b4:	e822                	sd	s0,16(sp)
    800030b6:	e426                	sd	s1,8(sp)
    800030b8:	1000                	addi	s0,sp,32
    800030ba:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030bc:	00015517          	auipc	a0,0x15
    800030c0:	65c50513          	addi	a0,a0,1628 # 80018718 <bcache>
    800030c4:	ffffe097          	auipc	ra,0xffffe
    800030c8:	9fa080e7          	jalr	-1542(ra) # 80000abe <acquire>
  b->refcnt--;
    800030cc:	40bc                	lw	a5,64(s1)
    800030ce:	37fd                	addiw	a5,a5,-1
    800030d0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030d2:	00015517          	auipc	a0,0x15
    800030d6:	64650513          	addi	a0,a0,1606 # 80018718 <bcache>
    800030da:	ffffe097          	auipc	ra,0xffffe
    800030de:	a4c080e7          	jalr	-1460(ra) # 80000b26 <release>
}
    800030e2:	60e2                	ld	ra,24(sp)
    800030e4:	6442                	ld	s0,16(sp)
    800030e6:	64a2                	ld	s1,8(sp)
    800030e8:	6105                	addi	sp,sp,32
    800030ea:	8082                	ret

00000000800030ec <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800030ec:	1101                	addi	sp,sp,-32
    800030ee:	ec06                	sd	ra,24(sp)
    800030f0:	e822                	sd	s0,16(sp)
    800030f2:	e426                	sd	s1,8(sp)
    800030f4:	e04a                	sd	s2,0(sp)
    800030f6:	1000                	addi	s0,sp,32
    800030f8:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800030fa:	00d5d59b          	srliw	a1,a1,0xd
    800030fe:	0001e797          	auipc	a5,0x1e
    80003102:	dee7a783          	lw	a5,-530(a5) # 80020eec <sb+0x1c>
    80003106:	9dbd                	addw	a1,a1,a5
    80003108:	00000097          	auipc	ra,0x0
    8000310c:	d9a080e7          	jalr	-614(ra) # 80002ea2 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003110:	0074f713          	andi	a4,s1,7
    80003114:	4785                	li	a5,1
    80003116:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000311a:	14ce                	slli	s1,s1,0x33
    8000311c:	90d9                	srli	s1,s1,0x36
    8000311e:	00950733          	add	a4,a0,s1
    80003122:	06074703          	lbu	a4,96(a4)
    80003126:	00e7f6b3          	and	a3,a5,a4
    8000312a:	c69d                	beqz	a3,80003158 <bfree+0x6c>
    8000312c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000312e:	94aa                	add	s1,s1,a0
    80003130:	fff7c793          	not	a5,a5
    80003134:	8ff9                	and	a5,a5,a4
    80003136:	06f48023          	sb	a5,96(s1)
  log_write(bp);
    8000313a:	00001097          	auipc	ra,0x1
    8000313e:	1d4080e7          	jalr	468(ra) # 8000430e <log_write>
  brelse(bp);
    80003142:	854a                	mv	a0,s2
    80003144:	00000097          	auipc	ra,0x0
    80003148:	e92080e7          	jalr	-366(ra) # 80002fd6 <brelse>
}
    8000314c:	60e2                	ld	ra,24(sp)
    8000314e:	6442                	ld	s0,16(sp)
    80003150:	64a2                	ld	s1,8(sp)
    80003152:	6902                	ld	s2,0(sp)
    80003154:	6105                	addi	sp,sp,32
    80003156:	8082                	ret
    panic("freeing free block");
    80003158:	00005517          	auipc	a0,0x5
    8000315c:	3a050513          	addi	a0,a0,928 # 800084f8 <userret+0x468>
    80003160:	ffffd097          	auipc	ra,0xffffd
    80003164:	3e8080e7          	jalr	1000(ra) # 80000548 <panic>

0000000080003168 <balloc>:
{
    80003168:	711d                	addi	sp,sp,-96
    8000316a:	ec86                	sd	ra,88(sp)
    8000316c:	e8a2                	sd	s0,80(sp)
    8000316e:	e4a6                	sd	s1,72(sp)
    80003170:	e0ca                	sd	s2,64(sp)
    80003172:	fc4e                	sd	s3,56(sp)
    80003174:	f852                	sd	s4,48(sp)
    80003176:	f456                	sd	s5,40(sp)
    80003178:	f05a                	sd	s6,32(sp)
    8000317a:	ec5e                	sd	s7,24(sp)
    8000317c:	e862                	sd	s8,16(sp)
    8000317e:	e466                	sd	s9,8(sp)
    80003180:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003182:	0001e797          	auipc	a5,0x1e
    80003186:	d527a783          	lw	a5,-686(a5) # 80020ed4 <sb+0x4>
    8000318a:	cbd1                	beqz	a5,8000321e <balloc+0xb6>
    8000318c:	8baa                	mv	s7,a0
    8000318e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003190:	0001eb17          	auipc	s6,0x1e
    80003194:	d40b0b13          	addi	s6,s6,-704 # 80020ed0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003198:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000319a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000319c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000319e:	6c89                	lui	s9,0x2
    800031a0:	a831                	j	800031bc <balloc+0x54>
    brelse(bp);
    800031a2:	854a                	mv	a0,s2
    800031a4:	00000097          	auipc	ra,0x0
    800031a8:	e32080e7          	jalr	-462(ra) # 80002fd6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800031ac:	015c87bb          	addw	a5,s9,s5
    800031b0:	00078a9b          	sext.w	s5,a5
    800031b4:	004b2703          	lw	a4,4(s6)
    800031b8:	06eaf363          	bgeu	s5,a4,8000321e <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800031bc:	41fad79b          	sraiw	a5,s5,0x1f
    800031c0:	0137d79b          	srliw	a5,a5,0x13
    800031c4:	015787bb          	addw	a5,a5,s5
    800031c8:	40d7d79b          	sraiw	a5,a5,0xd
    800031cc:	01cb2583          	lw	a1,28(s6)
    800031d0:	9dbd                	addw	a1,a1,a5
    800031d2:	855e                	mv	a0,s7
    800031d4:	00000097          	auipc	ra,0x0
    800031d8:	cce080e7          	jalr	-818(ra) # 80002ea2 <bread>
    800031dc:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031de:	004b2503          	lw	a0,4(s6)
    800031e2:	000a849b          	sext.w	s1,s5
    800031e6:	8662                	mv	a2,s8
    800031e8:	faa4fde3          	bgeu	s1,a0,800031a2 <balloc+0x3a>
      m = 1 << (bi % 8);
    800031ec:	41f6579b          	sraiw	a5,a2,0x1f
    800031f0:	01d7d69b          	srliw	a3,a5,0x1d
    800031f4:	00c6873b          	addw	a4,a3,a2
    800031f8:	00777793          	andi	a5,a4,7
    800031fc:	9f95                	subw	a5,a5,a3
    800031fe:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003202:	4037571b          	sraiw	a4,a4,0x3
    80003206:	00e906b3          	add	a3,s2,a4
    8000320a:	0606c683          	lbu	a3,96(a3)
    8000320e:	00d7f5b3          	and	a1,a5,a3
    80003212:	cd91                	beqz	a1,8000322e <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003214:	2605                	addiw	a2,a2,1
    80003216:	2485                	addiw	s1,s1,1
    80003218:	fd4618e3          	bne	a2,s4,800031e8 <balloc+0x80>
    8000321c:	b759                	j	800031a2 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000321e:	00005517          	auipc	a0,0x5
    80003222:	2f250513          	addi	a0,a0,754 # 80008510 <userret+0x480>
    80003226:	ffffd097          	auipc	ra,0xffffd
    8000322a:	322080e7          	jalr	802(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000322e:	974a                	add	a4,a4,s2
    80003230:	8fd5                	or	a5,a5,a3
    80003232:	06f70023          	sb	a5,96(a4)
        log_write(bp);
    80003236:	854a                	mv	a0,s2
    80003238:	00001097          	auipc	ra,0x1
    8000323c:	0d6080e7          	jalr	214(ra) # 8000430e <log_write>
        brelse(bp);
    80003240:	854a                	mv	a0,s2
    80003242:	00000097          	auipc	ra,0x0
    80003246:	d94080e7          	jalr	-620(ra) # 80002fd6 <brelse>
  bp = bread(dev, bno);
    8000324a:	85a6                	mv	a1,s1
    8000324c:	855e                	mv	a0,s7
    8000324e:	00000097          	auipc	ra,0x0
    80003252:	c54080e7          	jalr	-940(ra) # 80002ea2 <bread>
    80003256:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003258:	40000613          	li	a2,1024
    8000325c:	4581                	li	a1,0
    8000325e:	06050513          	addi	a0,a0,96
    80003262:	ffffe097          	auipc	ra,0xffffe
    80003266:	920080e7          	jalr	-1760(ra) # 80000b82 <memset>
  log_write(bp);
    8000326a:	854a                	mv	a0,s2
    8000326c:	00001097          	auipc	ra,0x1
    80003270:	0a2080e7          	jalr	162(ra) # 8000430e <log_write>
  brelse(bp);
    80003274:	854a                	mv	a0,s2
    80003276:	00000097          	auipc	ra,0x0
    8000327a:	d60080e7          	jalr	-672(ra) # 80002fd6 <brelse>
}
    8000327e:	8526                	mv	a0,s1
    80003280:	60e6                	ld	ra,88(sp)
    80003282:	6446                	ld	s0,80(sp)
    80003284:	64a6                	ld	s1,72(sp)
    80003286:	6906                	ld	s2,64(sp)
    80003288:	79e2                	ld	s3,56(sp)
    8000328a:	7a42                	ld	s4,48(sp)
    8000328c:	7aa2                	ld	s5,40(sp)
    8000328e:	7b02                	ld	s6,32(sp)
    80003290:	6be2                	ld	s7,24(sp)
    80003292:	6c42                	ld	s8,16(sp)
    80003294:	6ca2                	ld	s9,8(sp)
    80003296:	6125                	addi	sp,sp,96
    80003298:	8082                	ret

000000008000329a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000329a:	7179                	addi	sp,sp,-48
    8000329c:	f406                	sd	ra,40(sp)
    8000329e:	f022                	sd	s0,32(sp)
    800032a0:	ec26                	sd	s1,24(sp)
    800032a2:	e84a                	sd	s2,16(sp)
    800032a4:	e44e                	sd	s3,8(sp)
    800032a6:	e052                	sd	s4,0(sp)
    800032a8:	1800                	addi	s0,sp,48
    800032aa:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800032ac:	47ad                	li	a5,11
    800032ae:	04b7fe63          	bgeu	a5,a1,8000330a <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800032b2:	ff45849b          	addiw	s1,a1,-12
    800032b6:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800032ba:	0ff00793          	li	a5,255
    800032be:	0ae7e463          	bltu	a5,a4,80003366 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800032c2:	08052583          	lw	a1,128(a0)
    800032c6:	c5b5                	beqz	a1,80003332 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800032c8:	00092503          	lw	a0,0(s2)
    800032cc:	00000097          	auipc	ra,0x0
    800032d0:	bd6080e7          	jalr	-1066(ra) # 80002ea2 <bread>
    800032d4:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800032d6:	06050793          	addi	a5,a0,96
    if((addr = a[bn]) == 0){
    800032da:	02049713          	slli	a4,s1,0x20
    800032de:	01e75593          	srli	a1,a4,0x1e
    800032e2:	00b784b3          	add	s1,a5,a1
    800032e6:	0004a983          	lw	s3,0(s1)
    800032ea:	04098e63          	beqz	s3,80003346 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800032ee:	8552                	mv	a0,s4
    800032f0:	00000097          	auipc	ra,0x0
    800032f4:	ce6080e7          	jalr	-794(ra) # 80002fd6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800032f8:	854e                	mv	a0,s3
    800032fa:	70a2                	ld	ra,40(sp)
    800032fc:	7402                	ld	s0,32(sp)
    800032fe:	64e2                	ld	s1,24(sp)
    80003300:	6942                	ld	s2,16(sp)
    80003302:	69a2                	ld	s3,8(sp)
    80003304:	6a02                	ld	s4,0(sp)
    80003306:	6145                	addi	sp,sp,48
    80003308:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000330a:	02059793          	slli	a5,a1,0x20
    8000330e:	01e7d593          	srli	a1,a5,0x1e
    80003312:	00b504b3          	add	s1,a0,a1
    80003316:	0504a983          	lw	s3,80(s1)
    8000331a:	fc099fe3          	bnez	s3,800032f8 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000331e:	4108                	lw	a0,0(a0)
    80003320:	00000097          	auipc	ra,0x0
    80003324:	e48080e7          	jalr	-440(ra) # 80003168 <balloc>
    80003328:	0005099b          	sext.w	s3,a0
    8000332c:	0534a823          	sw	s3,80(s1)
    80003330:	b7e1                	j	800032f8 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003332:	4108                	lw	a0,0(a0)
    80003334:	00000097          	auipc	ra,0x0
    80003338:	e34080e7          	jalr	-460(ra) # 80003168 <balloc>
    8000333c:	0005059b          	sext.w	a1,a0
    80003340:	08b92023          	sw	a1,128(s2)
    80003344:	b751                	j	800032c8 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003346:	00092503          	lw	a0,0(s2)
    8000334a:	00000097          	auipc	ra,0x0
    8000334e:	e1e080e7          	jalr	-482(ra) # 80003168 <balloc>
    80003352:	0005099b          	sext.w	s3,a0
    80003356:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000335a:	8552                	mv	a0,s4
    8000335c:	00001097          	auipc	ra,0x1
    80003360:	fb2080e7          	jalr	-78(ra) # 8000430e <log_write>
    80003364:	b769                	j	800032ee <bmap+0x54>
  panic("bmap: out of range");
    80003366:	00005517          	auipc	a0,0x5
    8000336a:	1c250513          	addi	a0,a0,450 # 80008528 <userret+0x498>
    8000336e:	ffffd097          	auipc	ra,0xffffd
    80003372:	1da080e7          	jalr	474(ra) # 80000548 <panic>

0000000080003376 <iget>:
{
    80003376:	7179                	addi	sp,sp,-48
    80003378:	f406                	sd	ra,40(sp)
    8000337a:	f022                	sd	s0,32(sp)
    8000337c:	ec26                	sd	s1,24(sp)
    8000337e:	e84a                	sd	s2,16(sp)
    80003380:	e44e                	sd	s3,8(sp)
    80003382:	e052                	sd	s4,0(sp)
    80003384:	1800                	addi	s0,sp,48
    80003386:	89aa                	mv	s3,a0
    80003388:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000338a:	0001e517          	auipc	a0,0x1e
    8000338e:	b6650513          	addi	a0,a0,-1178 # 80020ef0 <icache>
    80003392:	ffffd097          	auipc	ra,0xffffd
    80003396:	72c080e7          	jalr	1836(ra) # 80000abe <acquire>
  empty = 0;
    8000339a:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000339c:	0001e497          	auipc	s1,0x1e
    800033a0:	b6c48493          	addi	s1,s1,-1172 # 80020f08 <icache+0x18>
    800033a4:	0001f697          	auipc	a3,0x1f
    800033a8:	5f468693          	addi	a3,a3,1524 # 80022998 <log>
    800033ac:	a039                	j	800033ba <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033ae:	02090b63          	beqz	s2,800033e4 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800033b2:	08848493          	addi	s1,s1,136
    800033b6:	02d48a63          	beq	s1,a3,800033ea <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800033ba:	449c                	lw	a5,8(s1)
    800033bc:	fef059e3          	blez	a5,800033ae <iget+0x38>
    800033c0:	4098                	lw	a4,0(s1)
    800033c2:	ff3716e3          	bne	a4,s3,800033ae <iget+0x38>
    800033c6:	40d8                	lw	a4,4(s1)
    800033c8:	ff4713e3          	bne	a4,s4,800033ae <iget+0x38>
      ip->ref++;
    800033cc:	2785                	addiw	a5,a5,1
    800033ce:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800033d0:	0001e517          	auipc	a0,0x1e
    800033d4:	b2050513          	addi	a0,a0,-1248 # 80020ef0 <icache>
    800033d8:	ffffd097          	auipc	ra,0xffffd
    800033dc:	74e080e7          	jalr	1870(ra) # 80000b26 <release>
      return ip;
    800033e0:	8926                	mv	s2,s1
    800033e2:	a03d                	j	80003410 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033e4:	f7f9                	bnez	a5,800033b2 <iget+0x3c>
    800033e6:	8926                	mv	s2,s1
    800033e8:	b7e9                	j	800033b2 <iget+0x3c>
  if(empty == 0)
    800033ea:	02090c63          	beqz	s2,80003422 <iget+0xac>
  ip->dev = dev;
    800033ee:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800033f2:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800033f6:	4785                	li	a5,1
    800033f8:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800033fc:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003400:	0001e517          	auipc	a0,0x1e
    80003404:	af050513          	addi	a0,a0,-1296 # 80020ef0 <icache>
    80003408:	ffffd097          	auipc	ra,0xffffd
    8000340c:	71e080e7          	jalr	1822(ra) # 80000b26 <release>
}
    80003410:	854a                	mv	a0,s2
    80003412:	70a2                	ld	ra,40(sp)
    80003414:	7402                	ld	s0,32(sp)
    80003416:	64e2                	ld	s1,24(sp)
    80003418:	6942                	ld	s2,16(sp)
    8000341a:	69a2                	ld	s3,8(sp)
    8000341c:	6a02                	ld	s4,0(sp)
    8000341e:	6145                	addi	sp,sp,48
    80003420:	8082                	ret
    panic("iget: no inodes");
    80003422:	00005517          	auipc	a0,0x5
    80003426:	11e50513          	addi	a0,a0,286 # 80008540 <userret+0x4b0>
    8000342a:	ffffd097          	auipc	ra,0xffffd
    8000342e:	11e080e7          	jalr	286(ra) # 80000548 <panic>

0000000080003432 <fsinit>:
fsinit(int dev) {
    80003432:	7179                	addi	sp,sp,-48
    80003434:	f406                	sd	ra,40(sp)
    80003436:	f022                	sd	s0,32(sp)
    80003438:	ec26                	sd	s1,24(sp)
    8000343a:	e84a                	sd	s2,16(sp)
    8000343c:	e44e                	sd	s3,8(sp)
    8000343e:	1800                	addi	s0,sp,48
    80003440:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003442:	4585                	li	a1,1
    80003444:	00000097          	auipc	ra,0x0
    80003448:	a5e080e7          	jalr	-1442(ra) # 80002ea2 <bread>
    8000344c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000344e:	0001e997          	auipc	s3,0x1e
    80003452:	a8298993          	addi	s3,s3,-1406 # 80020ed0 <sb>
    80003456:	02000613          	li	a2,32
    8000345a:	06050593          	addi	a1,a0,96
    8000345e:	854e                	mv	a0,s3
    80003460:	ffffd097          	auipc	ra,0xffffd
    80003464:	77e080e7          	jalr	1918(ra) # 80000bde <memmove>
  brelse(bp);
    80003468:	8526                	mv	a0,s1
    8000346a:	00000097          	auipc	ra,0x0
    8000346e:	b6c080e7          	jalr	-1172(ra) # 80002fd6 <brelse>
  if(sb.magic != FSMAGIC)
    80003472:	0009a703          	lw	a4,0(s3)
    80003476:	102037b7          	lui	a5,0x10203
    8000347a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000347e:	02f71263          	bne	a4,a5,800034a2 <fsinit+0x70>
  initlog(dev, &sb);
    80003482:	0001e597          	auipc	a1,0x1e
    80003486:	a4e58593          	addi	a1,a1,-1458 # 80020ed0 <sb>
    8000348a:	854a                	mv	a0,s2
    8000348c:	00001097          	auipc	ra,0x1
    80003490:	bfa080e7          	jalr	-1030(ra) # 80004086 <initlog>
}
    80003494:	70a2                	ld	ra,40(sp)
    80003496:	7402                	ld	s0,32(sp)
    80003498:	64e2                	ld	s1,24(sp)
    8000349a:	6942                	ld	s2,16(sp)
    8000349c:	69a2                	ld	s3,8(sp)
    8000349e:	6145                	addi	sp,sp,48
    800034a0:	8082                	ret
    panic("invalid file system");
    800034a2:	00005517          	auipc	a0,0x5
    800034a6:	0ae50513          	addi	a0,a0,174 # 80008550 <userret+0x4c0>
    800034aa:	ffffd097          	auipc	ra,0xffffd
    800034ae:	09e080e7          	jalr	158(ra) # 80000548 <panic>

00000000800034b2 <iinit>:
{
    800034b2:	7179                	addi	sp,sp,-48
    800034b4:	f406                	sd	ra,40(sp)
    800034b6:	f022                	sd	s0,32(sp)
    800034b8:	ec26                	sd	s1,24(sp)
    800034ba:	e84a                	sd	s2,16(sp)
    800034bc:	e44e                	sd	s3,8(sp)
    800034be:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800034c0:	00005597          	auipc	a1,0x5
    800034c4:	0a858593          	addi	a1,a1,168 # 80008568 <userret+0x4d8>
    800034c8:	0001e517          	auipc	a0,0x1e
    800034cc:	a2850513          	addi	a0,a0,-1496 # 80020ef0 <icache>
    800034d0:	ffffd097          	auipc	ra,0xffffd
    800034d4:	4e0080e7          	jalr	1248(ra) # 800009b0 <initlock>
  for(i = 0; i < NINODE; i++) {
    800034d8:	0001e497          	auipc	s1,0x1e
    800034dc:	a4048493          	addi	s1,s1,-1472 # 80020f18 <icache+0x28>
    800034e0:	0001f997          	auipc	s3,0x1f
    800034e4:	4c898993          	addi	s3,s3,1224 # 800229a8 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800034e8:	00005917          	auipc	s2,0x5
    800034ec:	08890913          	addi	s2,s2,136 # 80008570 <userret+0x4e0>
    800034f0:	85ca                	mv	a1,s2
    800034f2:	8526                	mv	a0,s1
    800034f4:	00001097          	auipc	ra,0x1
    800034f8:	078080e7          	jalr	120(ra) # 8000456c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800034fc:	08848493          	addi	s1,s1,136
    80003500:	ff3498e3          	bne	s1,s3,800034f0 <iinit+0x3e>
}
    80003504:	70a2                	ld	ra,40(sp)
    80003506:	7402                	ld	s0,32(sp)
    80003508:	64e2                	ld	s1,24(sp)
    8000350a:	6942                	ld	s2,16(sp)
    8000350c:	69a2                	ld	s3,8(sp)
    8000350e:	6145                	addi	sp,sp,48
    80003510:	8082                	ret

0000000080003512 <ialloc>:
{
    80003512:	715d                	addi	sp,sp,-80
    80003514:	e486                	sd	ra,72(sp)
    80003516:	e0a2                	sd	s0,64(sp)
    80003518:	fc26                	sd	s1,56(sp)
    8000351a:	f84a                	sd	s2,48(sp)
    8000351c:	f44e                	sd	s3,40(sp)
    8000351e:	f052                	sd	s4,32(sp)
    80003520:	ec56                	sd	s5,24(sp)
    80003522:	e85a                	sd	s6,16(sp)
    80003524:	e45e                	sd	s7,8(sp)
    80003526:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003528:	0001e717          	auipc	a4,0x1e
    8000352c:	9b472703          	lw	a4,-1612(a4) # 80020edc <sb+0xc>
    80003530:	4785                	li	a5,1
    80003532:	04e7fa63          	bgeu	a5,a4,80003586 <ialloc+0x74>
    80003536:	8aaa                	mv	s5,a0
    80003538:	8bae                	mv	s7,a1
    8000353a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000353c:	0001ea17          	auipc	s4,0x1e
    80003540:	994a0a13          	addi	s4,s4,-1644 # 80020ed0 <sb>
    80003544:	00048b1b          	sext.w	s6,s1
    80003548:	0044d793          	srli	a5,s1,0x4
    8000354c:	018a2583          	lw	a1,24(s4)
    80003550:	9dbd                	addw	a1,a1,a5
    80003552:	8556                	mv	a0,s5
    80003554:	00000097          	auipc	ra,0x0
    80003558:	94e080e7          	jalr	-1714(ra) # 80002ea2 <bread>
    8000355c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000355e:	06050993          	addi	s3,a0,96
    80003562:	00f4f793          	andi	a5,s1,15
    80003566:	079a                	slli	a5,a5,0x6
    80003568:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000356a:	00099783          	lh	a5,0(s3)
    8000356e:	c785                	beqz	a5,80003596 <ialloc+0x84>
    brelse(bp);
    80003570:	00000097          	auipc	ra,0x0
    80003574:	a66080e7          	jalr	-1434(ra) # 80002fd6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003578:	0485                	addi	s1,s1,1
    8000357a:	00ca2703          	lw	a4,12(s4)
    8000357e:	0004879b          	sext.w	a5,s1
    80003582:	fce7e1e3          	bltu	a5,a4,80003544 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003586:	00005517          	auipc	a0,0x5
    8000358a:	ff250513          	addi	a0,a0,-14 # 80008578 <userret+0x4e8>
    8000358e:	ffffd097          	auipc	ra,0xffffd
    80003592:	fba080e7          	jalr	-70(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    80003596:	04000613          	li	a2,64
    8000359a:	4581                	li	a1,0
    8000359c:	854e                	mv	a0,s3
    8000359e:	ffffd097          	auipc	ra,0xffffd
    800035a2:	5e4080e7          	jalr	1508(ra) # 80000b82 <memset>
      dip->type = type;
    800035a6:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800035aa:	854a                	mv	a0,s2
    800035ac:	00001097          	auipc	ra,0x1
    800035b0:	d62080e7          	jalr	-670(ra) # 8000430e <log_write>
      brelse(bp);
    800035b4:	854a                	mv	a0,s2
    800035b6:	00000097          	auipc	ra,0x0
    800035ba:	a20080e7          	jalr	-1504(ra) # 80002fd6 <brelse>
      return iget(dev, inum);
    800035be:	85da                	mv	a1,s6
    800035c0:	8556                	mv	a0,s5
    800035c2:	00000097          	auipc	ra,0x0
    800035c6:	db4080e7          	jalr	-588(ra) # 80003376 <iget>
}
    800035ca:	60a6                	ld	ra,72(sp)
    800035cc:	6406                	ld	s0,64(sp)
    800035ce:	74e2                	ld	s1,56(sp)
    800035d0:	7942                	ld	s2,48(sp)
    800035d2:	79a2                	ld	s3,40(sp)
    800035d4:	7a02                	ld	s4,32(sp)
    800035d6:	6ae2                	ld	s5,24(sp)
    800035d8:	6b42                	ld	s6,16(sp)
    800035da:	6ba2                	ld	s7,8(sp)
    800035dc:	6161                	addi	sp,sp,80
    800035de:	8082                	ret

00000000800035e0 <iupdate>:
{
    800035e0:	1101                	addi	sp,sp,-32
    800035e2:	ec06                	sd	ra,24(sp)
    800035e4:	e822                	sd	s0,16(sp)
    800035e6:	e426                	sd	s1,8(sp)
    800035e8:	e04a                	sd	s2,0(sp)
    800035ea:	1000                	addi	s0,sp,32
    800035ec:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800035ee:	415c                	lw	a5,4(a0)
    800035f0:	0047d79b          	srliw	a5,a5,0x4
    800035f4:	0001e597          	auipc	a1,0x1e
    800035f8:	8f45a583          	lw	a1,-1804(a1) # 80020ee8 <sb+0x18>
    800035fc:	9dbd                	addw	a1,a1,a5
    800035fe:	4108                	lw	a0,0(a0)
    80003600:	00000097          	auipc	ra,0x0
    80003604:	8a2080e7          	jalr	-1886(ra) # 80002ea2 <bread>
    80003608:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000360a:	06050793          	addi	a5,a0,96
    8000360e:	40c8                	lw	a0,4(s1)
    80003610:	893d                	andi	a0,a0,15
    80003612:	051a                	slli	a0,a0,0x6
    80003614:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003616:	04449703          	lh	a4,68(s1)
    8000361a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000361e:	04649703          	lh	a4,70(s1)
    80003622:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003626:	04849703          	lh	a4,72(s1)
    8000362a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000362e:	04a49703          	lh	a4,74(s1)
    80003632:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003636:	44f8                	lw	a4,76(s1)
    80003638:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000363a:	03400613          	li	a2,52
    8000363e:	05048593          	addi	a1,s1,80
    80003642:	0531                	addi	a0,a0,12
    80003644:	ffffd097          	auipc	ra,0xffffd
    80003648:	59a080e7          	jalr	1434(ra) # 80000bde <memmove>
  log_write(bp);
    8000364c:	854a                	mv	a0,s2
    8000364e:	00001097          	auipc	ra,0x1
    80003652:	cc0080e7          	jalr	-832(ra) # 8000430e <log_write>
  brelse(bp);
    80003656:	854a                	mv	a0,s2
    80003658:	00000097          	auipc	ra,0x0
    8000365c:	97e080e7          	jalr	-1666(ra) # 80002fd6 <brelse>
}
    80003660:	60e2                	ld	ra,24(sp)
    80003662:	6442                	ld	s0,16(sp)
    80003664:	64a2                	ld	s1,8(sp)
    80003666:	6902                	ld	s2,0(sp)
    80003668:	6105                	addi	sp,sp,32
    8000366a:	8082                	ret

000000008000366c <idup>:
{
    8000366c:	1101                	addi	sp,sp,-32
    8000366e:	ec06                	sd	ra,24(sp)
    80003670:	e822                	sd	s0,16(sp)
    80003672:	e426                	sd	s1,8(sp)
    80003674:	1000                	addi	s0,sp,32
    80003676:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003678:	0001e517          	auipc	a0,0x1e
    8000367c:	87850513          	addi	a0,a0,-1928 # 80020ef0 <icache>
    80003680:	ffffd097          	auipc	ra,0xffffd
    80003684:	43e080e7          	jalr	1086(ra) # 80000abe <acquire>
  ip->ref++;
    80003688:	449c                	lw	a5,8(s1)
    8000368a:	2785                	addiw	a5,a5,1
    8000368c:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000368e:	0001e517          	auipc	a0,0x1e
    80003692:	86250513          	addi	a0,a0,-1950 # 80020ef0 <icache>
    80003696:	ffffd097          	auipc	ra,0xffffd
    8000369a:	490080e7          	jalr	1168(ra) # 80000b26 <release>
}
    8000369e:	8526                	mv	a0,s1
    800036a0:	60e2                	ld	ra,24(sp)
    800036a2:	6442                	ld	s0,16(sp)
    800036a4:	64a2                	ld	s1,8(sp)
    800036a6:	6105                	addi	sp,sp,32
    800036a8:	8082                	ret

00000000800036aa <ilock>:
{
    800036aa:	1101                	addi	sp,sp,-32
    800036ac:	ec06                	sd	ra,24(sp)
    800036ae:	e822                	sd	s0,16(sp)
    800036b0:	e426                	sd	s1,8(sp)
    800036b2:	e04a                	sd	s2,0(sp)
    800036b4:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800036b6:	c115                	beqz	a0,800036da <ilock+0x30>
    800036b8:	84aa                	mv	s1,a0
    800036ba:	451c                	lw	a5,8(a0)
    800036bc:	00f05f63          	blez	a5,800036da <ilock+0x30>
  acquiresleep(&ip->lock);
    800036c0:	0541                	addi	a0,a0,16
    800036c2:	00001097          	auipc	ra,0x1
    800036c6:	ee4080e7          	jalr	-284(ra) # 800045a6 <acquiresleep>
  if(ip->valid == 0){
    800036ca:	40bc                	lw	a5,64(s1)
    800036cc:	cf99                	beqz	a5,800036ea <ilock+0x40>
}
    800036ce:	60e2                	ld	ra,24(sp)
    800036d0:	6442                	ld	s0,16(sp)
    800036d2:	64a2                	ld	s1,8(sp)
    800036d4:	6902                	ld	s2,0(sp)
    800036d6:	6105                	addi	sp,sp,32
    800036d8:	8082                	ret
    panic("ilock");
    800036da:	00005517          	auipc	a0,0x5
    800036de:	eb650513          	addi	a0,a0,-330 # 80008590 <userret+0x500>
    800036e2:	ffffd097          	auipc	ra,0xffffd
    800036e6:	e66080e7          	jalr	-410(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036ea:	40dc                	lw	a5,4(s1)
    800036ec:	0047d79b          	srliw	a5,a5,0x4
    800036f0:	0001d597          	auipc	a1,0x1d
    800036f4:	7f85a583          	lw	a1,2040(a1) # 80020ee8 <sb+0x18>
    800036f8:	9dbd                	addw	a1,a1,a5
    800036fa:	4088                	lw	a0,0(s1)
    800036fc:	fffff097          	auipc	ra,0xfffff
    80003700:	7a6080e7          	jalr	1958(ra) # 80002ea2 <bread>
    80003704:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003706:	06050593          	addi	a1,a0,96
    8000370a:	40dc                	lw	a5,4(s1)
    8000370c:	8bbd                	andi	a5,a5,15
    8000370e:	079a                	slli	a5,a5,0x6
    80003710:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003712:	00059783          	lh	a5,0(a1)
    80003716:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000371a:	00259783          	lh	a5,2(a1)
    8000371e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003722:	00459783          	lh	a5,4(a1)
    80003726:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000372a:	00659783          	lh	a5,6(a1)
    8000372e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003732:	459c                	lw	a5,8(a1)
    80003734:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003736:	03400613          	li	a2,52
    8000373a:	05b1                	addi	a1,a1,12
    8000373c:	05048513          	addi	a0,s1,80
    80003740:	ffffd097          	auipc	ra,0xffffd
    80003744:	49e080e7          	jalr	1182(ra) # 80000bde <memmove>
    brelse(bp);
    80003748:	854a                	mv	a0,s2
    8000374a:	00000097          	auipc	ra,0x0
    8000374e:	88c080e7          	jalr	-1908(ra) # 80002fd6 <brelse>
    ip->valid = 1;
    80003752:	4785                	li	a5,1
    80003754:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003756:	04449783          	lh	a5,68(s1)
    8000375a:	fbb5                	bnez	a5,800036ce <ilock+0x24>
      panic("ilock: no type");
    8000375c:	00005517          	auipc	a0,0x5
    80003760:	e3c50513          	addi	a0,a0,-452 # 80008598 <userret+0x508>
    80003764:	ffffd097          	auipc	ra,0xffffd
    80003768:	de4080e7          	jalr	-540(ra) # 80000548 <panic>

000000008000376c <iunlock>:
{
    8000376c:	1101                	addi	sp,sp,-32
    8000376e:	ec06                	sd	ra,24(sp)
    80003770:	e822                	sd	s0,16(sp)
    80003772:	e426                	sd	s1,8(sp)
    80003774:	e04a                	sd	s2,0(sp)
    80003776:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003778:	c905                	beqz	a0,800037a8 <iunlock+0x3c>
    8000377a:	84aa                	mv	s1,a0
    8000377c:	01050913          	addi	s2,a0,16
    80003780:	854a                	mv	a0,s2
    80003782:	00001097          	auipc	ra,0x1
    80003786:	ebe080e7          	jalr	-322(ra) # 80004640 <holdingsleep>
    8000378a:	cd19                	beqz	a0,800037a8 <iunlock+0x3c>
    8000378c:	449c                	lw	a5,8(s1)
    8000378e:	00f05d63          	blez	a5,800037a8 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003792:	854a                	mv	a0,s2
    80003794:	00001097          	auipc	ra,0x1
    80003798:	e68080e7          	jalr	-408(ra) # 800045fc <releasesleep>
}
    8000379c:	60e2                	ld	ra,24(sp)
    8000379e:	6442                	ld	s0,16(sp)
    800037a0:	64a2                	ld	s1,8(sp)
    800037a2:	6902                	ld	s2,0(sp)
    800037a4:	6105                	addi	sp,sp,32
    800037a6:	8082                	ret
    panic("iunlock");
    800037a8:	00005517          	auipc	a0,0x5
    800037ac:	e0050513          	addi	a0,a0,-512 # 800085a8 <userret+0x518>
    800037b0:	ffffd097          	auipc	ra,0xffffd
    800037b4:	d98080e7          	jalr	-616(ra) # 80000548 <panic>

00000000800037b8 <iput>:
{
    800037b8:	7139                	addi	sp,sp,-64
    800037ba:	fc06                	sd	ra,56(sp)
    800037bc:	f822                	sd	s0,48(sp)
    800037be:	f426                	sd	s1,40(sp)
    800037c0:	f04a                	sd	s2,32(sp)
    800037c2:	ec4e                	sd	s3,24(sp)
    800037c4:	e852                	sd	s4,16(sp)
    800037c6:	e456                	sd	s5,8(sp)
    800037c8:	0080                	addi	s0,sp,64
    800037ca:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800037cc:	0001d517          	auipc	a0,0x1d
    800037d0:	72450513          	addi	a0,a0,1828 # 80020ef0 <icache>
    800037d4:	ffffd097          	auipc	ra,0xffffd
    800037d8:	2ea080e7          	jalr	746(ra) # 80000abe <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800037dc:	4498                	lw	a4,8(s1)
    800037de:	4785                	li	a5,1
    800037e0:	02f70663          	beq	a4,a5,8000380c <iput+0x54>
  ip->ref--;
    800037e4:	449c                	lw	a5,8(s1)
    800037e6:	37fd                	addiw	a5,a5,-1
    800037e8:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800037ea:	0001d517          	auipc	a0,0x1d
    800037ee:	70650513          	addi	a0,a0,1798 # 80020ef0 <icache>
    800037f2:	ffffd097          	auipc	ra,0xffffd
    800037f6:	334080e7          	jalr	820(ra) # 80000b26 <release>
}
    800037fa:	70e2                	ld	ra,56(sp)
    800037fc:	7442                	ld	s0,48(sp)
    800037fe:	74a2                	ld	s1,40(sp)
    80003800:	7902                	ld	s2,32(sp)
    80003802:	69e2                	ld	s3,24(sp)
    80003804:	6a42                	ld	s4,16(sp)
    80003806:	6aa2                	ld	s5,8(sp)
    80003808:	6121                	addi	sp,sp,64
    8000380a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000380c:	40bc                	lw	a5,64(s1)
    8000380e:	dbf9                	beqz	a5,800037e4 <iput+0x2c>
    80003810:	04a49783          	lh	a5,74(s1)
    80003814:	fbe1                	bnez	a5,800037e4 <iput+0x2c>
    acquiresleep(&ip->lock);
    80003816:	01048a13          	addi	s4,s1,16
    8000381a:	8552                	mv	a0,s4
    8000381c:	00001097          	auipc	ra,0x1
    80003820:	d8a080e7          	jalr	-630(ra) # 800045a6 <acquiresleep>
    release(&icache.lock);
    80003824:	0001d517          	auipc	a0,0x1d
    80003828:	6cc50513          	addi	a0,a0,1740 # 80020ef0 <icache>
    8000382c:	ffffd097          	auipc	ra,0xffffd
    80003830:	2fa080e7          	jalr	762(ra) # 80000b26 <release>
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003834:	05048913          	addi	s2,s1,80
    80003838:	08048993          	addi	s3,s1,128
    8000383c:	a021                	j	80003844 <iput+0x8c>
    8000383e:	0911                	addi	s2,s2,4
    80003840:	01390d63          	beq	s2,s3,8000385a <iput+0xa2>
    if(ip->addrs[i]){
    80003844:	00092583          	lw	a1,0(s2)
    80003848:	d9fd                	beqz	a1,8000383e <iput+0x86>
      bfree(ip->dev, ip->addrs[i]);
    8000384a:	4088                	lw	a0,0(s1)
    8000384c:	00000097          	auipc	ra,0x0
    80003850:	8a0080e7          	jalr	-1888(ra) # 800030ec <bfree>
      ip->addrs[i] = 0;
    80003854:	00092023          	sw	zero,0(s2)
    80003858:	b7dd                	j	8000383e <iput+0x86>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000385a:	0804a583          	lw	a1,128(s1)
    8000385e:	ed9d                	bnez	a1,8000389c <iput+0xe4>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003860:	0404a623          	sw	zero,76(s1)
  iupdate(ip);
    80003864:	8526                	mv	a0,s1
    80003866:	00000097          	auipc	ra,0x0
    8000386a:	d7a080e7          	jalr	-646(ra) # 800035e0 <iupdate>
    ip->type = 0;
    8000386e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003872:	8526                	mv	a0,s1
    80003874:	00000097          	auipc	ra,0x0
    80003878:	d6c080e7          	jalr	-660(ra) # 800035e0 <iupdate>
    ip->valid = 0;
    8000387c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003880:	8552                	mv	a0,s4
    80003882:	00001097          	auipc	ra,0x1
    80003886:	d7a080e7          	jalr	-646(ra) # 800045fc <releasesleep>
    acquire(&icache.lock);
    8000388a:	0001d517          	auipc	a0,0x1d
    8000388e:	66650513          	addi	a0,a0,1638 # 80020ef0 <icache>
    80003892:	ffffd097          	auipc	ra,0xffffd
    80003896:	22c080e7          	jalr	556(ra) # 80000abe <acquire>
    8000389a:	b7a9                	j	800037e4 <iput+0x2c>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000389c:	4088                	lw	a0,0(s1)
    8000389e:	fffff097          	auipc	ra,0xfffff
    800038a2:	604080e7          	jalr	1540(ra) # 80002ea2 <bread>
    800038a6:	8aaa                	mv	s5,a0
    for(j = 0; j < NINDIRECT; j++){
    800038a8:	06050913          	addi	s2,a0,96
    800038ac:	46050993          	addi	s3,a0,1120
    800038b0:	a021                	j	800038b8 <iput+0x100>
    800038b2:	0911                	addi	s2,s2,4
    800038b4:	01390b63          	beq	s2,s3,800038ca <iput+0x112>
      if(a[j])
    800038b8:	00092583          	lw	a1,0(s2)
    800038bc:	d9fd                	beqz	a1,800038b2 <iput+0xfa>
        bfree(ip->dev, a[j]);
    800038be:	4088                	lw	a0,0(s1)
    800038c0:	00000097          	auipc	ra,0x0
    800038c4:	82c080e7          	jalr	-2004(ra) # 800030ec <bfree>
    800038c8:	b7ed                	j	800038b2 <iput+0xfa>
    brelse(bp);
    800038ca:	8556                	mv	a0,s5
    800038cc:	fffff097          	auipc	ra,0xfffff
    800038d0:	70a080e7          	jalr	1802(ra) # 80002fd6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038d4:	0804a583          	lw	a1,128(s1)
    800038d8:	4088                	lw	a0,0(s1)
    800038da:	00000097          	auipc	ra,0x0
    800038de:	812080e7          	jalr	-2030(ra) # 800030ec <bfree>
    ip->addrs[NDIRECT] = 0;
    800038e2:	0804a023          	sw	zero,128(s1)
    800038e6:	bfad                	j	80003860 <iput+0xa8>

00000000800038e8 <iunlockput>:
{
    800038e8:	1101                	addi	sp,sp,-32
    800038ea:	ec06                	sd	ra,24(sp)
    800038ec:	e822                	sd	s0,16(sp)
    800038ee:	e426                	sd	s1,8(sp)
    800038f0:	1000                	addi	s0,sp,32
    800038f2:	84aa                	mv	s1,a0
  iunlock(ip);
    800038f4:	00000097          	auipc	ra,0x0
    800038f8:	e78080e7          	jalr	-392(ra) # 8000376c <iunlock>
  iput(ip);
    800038fc:	8526                	mv	a0,s1
    800038fe:	00000097          	auipc	ra,0x0
    80003902:	eba080e7          	jalr	-326(ra) # 800037b8 <iput>
}
    80003906:	60e2                	ld	ra,24(sp)
    80003908:	6442                	ld	s0,16(sp)
    8000390a:	64a2                	ld	s1,8(sp)
    8000390c:	6105                	addi	sp,sp,32
    8000390e:	8082                	ret

0000000080003910 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003910:	1141                	addi	sp,sp,-16
    80003912:	e422                	sd	s0,8(sp)
    80003914:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003916:	411c                	lw	a5,0(a0)
    80003918:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000391a:	415c                	lw	a5,4(a0)
    8000391c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000391e:	04451783          	lh	a5,68(a0)
    80003922:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003926:	04a51783          	lh	a5,74(a0)
    8000392a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000392e:	04c56783          	lwu	a5,76(a0)
    80003932:	e99c                	sd	a5,16(a1)
}
    80003934:	6422                	ld	s0,8(sp)
    80003936:	0141                	addi	sp,sp,16
    80003938:	8082                	ret

000000008000393a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000393a:	457c                	lw	a5,76(a0)
    8000393c:	0ed7e563          	bltu	a5,a3,80003a26 <readi+0xec>
{
    80003940:	7159                	addi	sp,sp,-112
    80003942:	f486                	sd	ra,104(sp)
    80003944:	f0a2                	sd	s0,96(sp)
    80003946:	eca6                	sd	s1,88(sp)
    80003948:	e8ca                	sd	s2,80(sp)
    8000394a:	e4ce                	sd	s3,72(sp)
    8000394c:	e0d2                	sd	s4,64(sp)
    8000394e:	fc56                	sd	s5,56(sp)
    80003950:	f85a                	sd	s6,48(sp)
    80003952:	f45e                	sd	s7,40(sp)
    80003954:	f062                	sd	s8,32(sp)
    80003956:	ec66                	sd	s9,24(sp)
    80003958:	e86a                	sd	s10,16(sp)
    8000395a:	e46e                	sd	s11,8(sp)
    8000395c:	1880                	addi	s0,sp,112
    8000395e:	8baa                	mv	s7,a0
    80003960:	8c2e                	mv	s8,a1
    80003962:	8ab2                	mv	s5,a2
    80003964:	8936                	mv	s2,a3
    80003966:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003968:	9f35                	addw	a4,a4,a3
    8000396a:	0cd76063          	bltu	a4,a3,80003a2a <readi+0xf0>
    return -1;
  if(off + n > ip->size)
    8000396e:	00e7f463          	bgeu	a5,a4,80003976 <readi+0x3c>
    n = ip->size - off;
    80003972:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003976:	080b0763          	beqz	s6,80003a04 <readi+0xca>
    8000397a:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000397c:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003980:	5cfd                	li	s9,-1
    80003982:	a82d                	j	800039bc <readi+0x82>
    80003984:	02099d93          	slli	s11,s3,0x20
    80003988:	020ddd93          	srli	s11,s11,0x20
    8000398c:	06048793          	addi	a5,s1,96
    80003990:	86ee                	mv	a3,s11
    80003992:	963e                	add	a2,a2,a5
    80003994:	85d6                	mv	a1,s5
    80003996:	8562                	mv	a0,s8
    80003998:	fffff097          	auipc	ra,0xfffff
    8000399c:	a80080e7          	jalr	-1408(ra) # 80002418 <either_copyout>
    800039a0:	05950d63          	beq	a0,s9,800039fa <readi+0xc0>
      brelse(bp);
      break;
    }
    brelse(bp);
    800039a4:	8526                	mv	a0,s1
    800039a6:	fffff097          	auipc	ra,0xfffff
    800039aa:	630080e7          	jalr	1584(ra) # 80002fd6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039ae:	01498a3b          	addw	s4,s3,s4
    800039b2:	0129893b          	addw	s2,s3,s2
    800039b6:	9aee                	add	s5,s5,s11
    800039b8:	056a7663          	bgeu	s4,s6,80003a04 <readi+0xca>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800039bc:	000ba483          	lw	s1,0(s7)
    800039c0:	00a9559b          	srliw	a1,s2,0xa
    800039c4:	855e                	mv	a0,s7
    800039c6:	00000097          	auipc	ra,0x0
    800039ca:	8d4080e7          	jalr	-1836(ra) # 8000329a <bmap>
    800039ce:	0005059b          	sext.w	a1,a0
    800039d2:	8526                	mv	a0,s1
    800039d4:	fffff097          	auipc	ra,0xfffff
    800039d8:	4ce080e7          	jalr	1230(ra) # 80002ea2 <bread>
    800039dc:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800039de:	3ff97613          	andi	a2,s2,1023
    800039e2:	40cd07bb          	subw	a5,s10,a2
    800039e6:	414b073b          	subw	a4,s6,s4
    800039ea:	89be                	mv	s3,a5
    800039ec:	2781                	sext.w	a5,a5
    800039ee:	0007069b          	sext.w	a3,a4
    800039f2:	f8f6f9e3          	bgeu	a3,a5,80003984 <readi+0x4a>
    800039f6:	89ba                	mv	s3,a4
    800039f8:	b771                	j	80003984 <readi+0x4a>
      brelse(bp);
    800039fa:	8526                	mv	a0,s1
    800039fc:	fffff097          	auipc	ra,0xfffff
    80003a00:	5da080e7          	jalr	1498(ra) # 80002fd6 <brelse>
  }
  return n;
    80003a04:	000b051b          	sext.w	a0,s6
}
    80003a08:	70a6                	ld	ra,104(sp)
    80003a0a:	7406                	ld	s0,96(sp)
    80003a0c:	64e6                	ld	s1,88(sp)
    80003a0e:	6946                	ld	s2,80(sp)
    80003a10:	69a6                	ld	s3,72(sp)
    80003a12:	6a06                	ld	s4,64(sp)
    80003a14:	7ae2                	ld	s5,56(sp)
    80003a16:	7b42                	ld	s6,48(sp)
    80003a18:	7ba2                	ld	s7,40(sp)
    80003a1a:	7c02                	ld	s8,32(sp)
    80003a1c:	6ce2                	ld	s9,24(sp)
    80003a1e:	6d42                	ld	s10,16(sp)
    80003a20:	6da2                	ld	s11,8(sp)
    80003a22:	6165                	addi	sp,sp,112
    80003a24:	8082                	ret
    return -1;
    80003a26:	557d                	li	a0,-1
}
    80003a28:	8082                	ret
    return -1;
    80003a2a:	557d                	li	a0,-1
    80003a2c:	bff1                	j	80003a08 <readi+0xce>

0000000080003a2e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a2e:	457c                	lw	a5,76(a0)
    80003a30:	10d7e663          	bltu	a5,a3,80003b3c <writei+0x10e>
{
    80003a34:	7159                	addi	sp,sp,-112
    80003a36:	f486                	sd	ra,104(sp)
    80003a38:	f0a2                	sd	s0,96(sp)
    80003a3a:	eca6                	sd	s1,88(sp)
    80003a3c:	e8ca                	sd	s2,80(sp)
    80003a3e:	e4ce                	sd	s3,72(sp)
    80003a40:	e0d2                	sd	s4,64(sp)
    80003a42:	fc56                	sd	s5,56(sp)
    80003a44:	f85a                	sd	s6,48(sp)
    80003a46:	f45e                	sd	s7,40(sp)
    80003a48:	f062                	sd	s8,32(sp)
    80003a4a:	ec66                	sd	s9,24(sp)
    80003a4c:	e86a                	sd	s10,16(sp)
    80003a4e:	e46e                	sd	s11,8(sp)
    80003a50:	1880                	addi	s0,sp,112
    80003a52:	8baa                	mv	s7,a0
    80003a54:	8c2e                	mv	s8,a1
    80003a56:	8ab2                	mv	s5,a2
    80003a58:	8936                	mv	s2,a3
    80003a5a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a5c:	00e687bb          	addw	a5,a3,a4
    80003a60:	0ed7e063          	bltu	a5,a3,80003b40 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a64:	00043737          	lui	a4,0x43
    80003a68:	0cf76e63          	bltu	a4,a5,80003b44 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a6c:	0a0b0763          	beqz	s6,80003b1a <writei+0xec>
    80003a70:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a72:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a76:	5cfd                	li	s9,-1
    80003a78:	a091                	j	80003abc <writei+0x8e>
    80003a7a:	02099d93          	slli	s11,s3,0x20
    80003a7e:	020ddd93          	srli	s11,s11,0x20
    80003a82:	06048793          	addi	a5,s1,96
    80003a86:	86ee                	mv	a3,s11
    80003a88:	8656                	mv	a2,s5
    80003a8a:	85e2                	mv	a1,s8
    80003a8c:	953e                	add	a0,a0,a5
    80003a8e:	fffff097          	auipc	ra,0xfffff
    80003a92:	9e0080e7          	jalr	-1568(ra) # 8000246e <either_copyin>
    80003a96:	07950263          	beq	a0,s9,80003afa <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003a9a:	8526                	mv	a0,s1
    80003a9c:	00001097          	auipc	ra,0x1
    80003aa0:	872080e7          	jalr	-1934(ra) # 8000430e <log_write>
    brelse(bp);
    80003aa4:	8526                	mv	a0,s1
    80003aa6:	fffff097          	auipc	ra,0xfffff
    80003aaa:	530080e7          	jalr	1328(ra) # 80002fd6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003aae:	01498a3b          	addw	s4,s3,s4
    80003ab2:	0129893b          	addw	s2,s3,s2
    80003ab6:	9aee                	add	s5,s5,s11
    80003ab8:	056a7663          	bgeu	s4,s6,80003b04 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003abc:	000ba483          	lw	s1,0(s7)
    80003ac0:	00a9559b          	srliw	a1,s2,0xa
    80003ac4:	855e                	mv	a0,s7
    80003ac6:	fffff097          	auipc	ra,0xfffff
    80003aca:	7d4080e7          	jalr	2004(ra) # 8000329a <bmap>
    80003ace:	0005059b          	sext.w	a1,a0
    80003ad2:	8526                	mv	a0,s1
    80003ad4:	fffff097          	auipc	ra,0xfffff
    80003ad8:	3ce080e7          	jalr	974(ra) # 80002ea2 <bread>
    80003adc:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ade:	3ff97513          	andi	a0,s2,1023
    80003ae2:	40ad07bb          	subw	a5,s10,a0
    80003ae6:	414b073b          	subw	a4,s6,s4
    80003aea:	89be                	mv	s3,a5
    80003aec:	2781                	sext.w	a5,a5
    80003aee:	0007069b          	sext.w	a3,a4
    80003af2:	f8f6f4e3          	bgeu	a3,a5,80003a7a <writei+0x4c>
    80003af6:	89ba                	mv	s3,a4
    80003af8:	b749                	j	80003a7a <writei+0x4c>
      brelse(bp);
    80003afa:	8526                	mv	a0,s1
    80003afc:	fffff097          	auipc	ra,0xfffff
    80003b00:	4da080e7          	jalr	1242(ra) # 80002fd6 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003b04:	04cba783          	lw	a5,76(s7)
    80003b08:	0127f463          	bgeu	a5,s2,80003b10 <writei+0xe2>
      ip->size = off;
    80003b0c:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003b10:	855e                	mv	a0,s7
    80003b12:	00000097          	auipc	ra,0x0
    80003b16:	ace080e7          	jalr	-1330(ra) # 800035e0 <iupdate>
  }

  return n;
    80003b1a:	000b051b          	sext.w	a0,s6
}
    80003b1e:	70a6                	ld	ra,104(sp)
    80003b20:	7406                	ld	s0,96(sp)
    80003b22:	64e6                	ld	s1,88(sp)
    80003b24:	6946                	ld	s2,80(sp)
    80003b26:	69a6                	ld	s3,72(sp)
    80003b28:	6a06                	ld	s4,64(sp)
    80003b2a:	7ae2                	ld	s5,56(sp)
    80003b2c:	7b42                	ld	s6,48(sp)
    80003b2e:	7ba2                	ld	s7,40(sp)
    80003b30:	7c02                	ld	s8,32(sp)
    80003b32:	6ce2                	ld	s9,24(sp)
    80003b34:	6d42                	ld	s10,16(sp)
    80003b36:	6da2                	ld	s11,8(sp)
    80003b38:	6165                	addi	sp,sp,112
    80003b3a:	8082                	ret
    return -1;
    80003b3c:	557d                	li	a0,-1
}
    80003b3e:	8082                	ret
    return -1;
    80003b40:	557d                	li	a0,-1
    80003b42:	bff1                	j	80003b1e <writei+0xf0>
    return -1;
    80003b44:	557d                	li	a0,-1
    80003b46:	bfe1                	j	80003b1e <writei+0xf0>

0000000080003b48 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b48:	1141                	addi	sp,sp,-16
    80003b4a:	e406                	sd	ra,8(sp)
    80003b4c:	e022                	sd	s0,0(sp)
    80003b4e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b50:	4639                	li	a2,14
    80003b52:	ffffd097          	auipc	ra,0xffffd
    80003b56:	108080e7          	jalr	264(ra) # 80000c5a <strncmp>
}
    80003b5a:	60a2                	ld	ra,8(sp)
    80003b5c:	6402                	ld	s0,0(sp)
    80003b5e:	0141                	addi	sp,sp,16
    80003b60:	8082                	ret

0000000080003b62 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b62:	7139                	addi	sp,sp,-64
    80003b64:	fc06                	sd	ra,56(sp)
    80003b66:	f822                	sd	s0,48(sp)
    80003b68:	f426                	sd	s1,40(sp)
    80003b6a:	f04a                	sd	s2,32(sp)
    80003b6c:	ec4e                	sd	s3,24(sp)
    80003b6e:	e852                	sd	s4,16(sp)
    80003b70:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b72:	04451703          	lh	a4,68(a0)
    80003b76:	4785                	li	a5,1
    80003b78:	00f71a63          	bne	a4,a5,80003b8c <dirlookup+0x2a>
    80003b7c:	892a                	mv	s2,a0
    80003b7e:	89ae                	mv	s3,a1
    80003b80:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b82:	457c                	lw	a5,76(a0)
    80003b84:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003b86:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b88:	e79d                	bnez	a5,80003bb6 <dirlookup+0x54>
    80003b8a:	a8a5                	j	80003c02 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003b8c:	00005517          	auipc	a0,0x5
    80003b90:	a2450513          	addi	a0,a0,-1500 # 800085b0 <userret+0x520>
    80003b94:	ffffd097          	auipc	ra,0xffffd
    80003b98:	9b4080e7          	jalr	-1612(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003b9c:	00005517          	auipc	a0,0x5
    80003ba0:	a2c50513          	addi	a0,a0,-1492 # 800085c8 <userret+0x538>
    80003ba4:	ffffd097          	auipc	ra,0xffffd
    80003ba8:	9a4080e7          	jalr	-1628(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bac:	24c1                	addiw	s1,s1,16
    80003bae:	04c92783          	lw	a5,76(s2)
    80003bb2:	04f4f763          	bgeu	s1,a5,80003c00 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003bb6:	4741                	li	a4,16
    80003bb8:	86a6                	mv	a3,s1
    80003bba:	fc040613          	addi	a2,s0,-64
    80003bbe:	4581                	li	a1,0
    80003bc0:	854a                	mv	a0,s2
    80003bc2:	00000097          	auipc	ra,0x0
    80003bc6:	d78080e7          	jalr	-648(ra) # 8000393a <readi>
    80003bca:	47c1                	li	a5,16
    80003bcc:	fcf518e3          	bne	a0,a5,80003b9c <dirlookup+0x3a>
    if(de.inum == 0)
    80003bd0:	fc045783          	lhu	a5,-64(s0)
    80003bd4:	dfe1                	beqz	a5,80003bac <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003bd6:	fc240593          	addi	a1,s0,-62
    80003bda:	854e                	mv	a0,s3
    80003bdc:	00000097          	auipc	ra,0x0
    80003be0:	f6c080e7          	jalr	-148(ra) # 80003b48 <namecmp>
    80003be4:	f561                	bnez	a0,80003bac <dirlookup+0x4a>
      if(poff)
    80003be6:	000a0463          	beqz	s4,80003bee <dirlookup+0x8c>
        *poff = off;
    80003bea:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003bee:	fc045583          	lhu	a1,-64(s0)
    80003bf2:	00092503          	lw	a0,0(s2)
    80003bf6:	fffff097          	auipc	ra,0xfffff
    80003bfa:	780080e7          	jalr	1920(ra) # 80003376 <iget>
    80003bfe:	a011                	j	80003c02 <dirlookup+0xa0>
  return 0;
    80003c00:	4501                	li	a0,0
}
    80003c02:	70e2                	ld	ra,56(sp)
    80003c04:	7442                	ld	s0,48(sp)
    80003c06:	74a2                	ld	s1,40(sp)
    80003c08:	7902                	ld	s2,32(sp)
    80003c0a:	69e2                	ld	s3,24(sp)
    80003c0c:	6a42                	ld	s4,16(sp)
    80003c0e:	6121                	addi	sp,sp,64
    80003c10:	8082                	ret

0000000080003c12 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c12:	711d                	addi	sp,sp,-96
    80003c14:	ec86                	sd	ra,88(sp)
    80003c16:	e8a2                	sd	s0,80(sp)
    80003c18:	e4a6                	sd	s1,72(sp)
    80003c1a:	e0ca                	sd	s2,64(sp)
    80003c1c:	fc4e                	sd	s3,56(sp)
    80003c1e:	f852                	sd	s4,48(sp)
    80003c20:	f456                	sd	s5,40(sp)
    80003c22:	f05a                	sd	s6,32(sp)
    80003c24:	ec5e                	sd	s7,24(sp)
    80003c26:	e862                	sd	s8,16(sp)
    80003c28:	e466                	sd	s9,8(sp)
    80003c2a:	1080                	addi	s0,sp,96
    80003c2c:	84aa                	mv	s1,a0
    80003c2e:	8aae                	mv	s5,a1
    80003c30:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c32:	00054703          	lbu	a4,0(a0)
    80003c36:	02f00793          	li	a5,47
    80003c3a:	02f70363          	beq	a4,a5,80003c60 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c3e:	ffffe097          	auipc	ra,0xffffe
    80003c42:	daa080e7          	jalr	-598(ra) # 800019e8 <myproc>
    80003c46:	15053503          	ld	a0,336(a0)
    80003c4a:	00000097          	auipc	ra,0x0
    80003c4e:	a22080e7          	jalr	-1502(ra) # 8000366c <idup>
    80003c52:	89aa                	mv	s3,a0
  while(*path == '/')
    80003c54:	02f00913          	li	s2,47
  len = path - s;
    80003c58:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003c5a:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c5c:	4b85                	li	s7,1
    80003c5e:	a865                	j	80003d16 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003c60:	4585                	li	a1,1
    80003c62:	4501                	li	a0,0
    80003c64:	fffff097          	auipc	ra,0xfffff
    80003c68:	712080e7          	jalr	1810(ra) # 80003376 <iget>
    80003c6c:	89aa                	mv	s3,a0
    80003c6e:	b7dd                	j	80003c54 <namex+0x42>
      iunlockput(ip);
    80003c70:	854e                	mv	a0,s3
    80003c72:	00000097          	auipc	ra,0x0
    80003c76:	c76080e7          	jalr	-906(ra) # 800038e8 <iunlockput>
      return 0;
    80003c7a:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003c7c:	854e                	mv	a0,s3
    80003c7e:	60e6                	ld	ra,88(sp)
    80003c80:	6446                	ld	s0,80(sp)
    80003c82:	64a6                	ld	s1,72(sp)
    80003c84:	6906                	ld	s2,64(sp)
    80003c86:	79e2                	ld	s3,56(sp)
    80003c88:	7a42                	ld	s4,48(sp)
    80003c8a:	7aa2                	ld	s5,40(sp)
    80003c8c:	7b02                	ld	s6,32(sp)
    80003c8e:	6be2                	ld	s7,24(sp)
    80003c90:	6c42                	ld	s8,16(sp)
    80003c92:	6ca2                	ld	s9,8(sp)
    80003c94:	6125                	addi	sp,sp,96
    80003c96:	8082                	ret
      iunlock(ip);
    80003c98:	854e                	mv	a0,s3
    80003c9a:	00000097          	auipc	ra,0x0
    80003c9e:	ad2080e7          	jalr	-1326(ra) # 8000376c <iunlock>
      return ip;
    80003ca2:	bfe9                	j	80003c7c <namex+0x6a>
      iunlockput(ip);
    80003ca4:	854e                	mv	a0,s3
    80003ca6:	00000097          	auipc	ra,0x0
    80003caa:	c42080e7          	jalr	-958(ra) # 800038e8 <iunlockput>
      return 0;
    80003cae:	89e6                	mv	s3,s9
    80003cb0:	b7f1                	j	80003c7c <namex+0x6a>
  len = path - s;
    80003cb2:	40b48633          	sub	a2,s1,a1
    80003cb6:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003cba:	099c5463          	bge	s8,s9,80003d42 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003cbe:	4639                	li	a2,14
    80003cc0:	8552                	mv	a0,s4
    80003cc2:	ffffd097          	auipc	ra,0xffffd
    80003cc6:	f1c080e7          	jalr	-228(ra) # 80000bde <memmove>
  while(*path == '/')
    80003cca:	0004c783          	lbu	a5,0(s1)
    80003cce:	01279763          	bne	a5,s2,80003cdc <namex+0xca>
    path++;
    80003cd2:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003cd4:	0004c783          	lbu	a5,0(s1)
    80003cd8:	ff278de3          	beq	a5,s2,80003cd2 <namex+0xc0>
    ilock(ip);
    80003cdc:	854e                	mv	a0,s3
    80003cde:	00000097          	auipc	ra,0x0
    80003ce2:	9cc080e7          	jalr	-1588(ra) # 800036aa <ilock>
    if(ip->type != T_DIR){
    80003ce6:	04499783          	lh	a5,68(s3)
    80003cea:	f97793e3          	bne	a5,s7,80003c70 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003cee:	000a8563          	beqz	s5,80003cf8 <namex+0xe6>
    80003cf2:	0004c783          	lbu	a5,0(s1)
    80003cf6:	d3cd                	beqz	a5,80003c98 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003cf8:	865a                	mv	a2,s6
    80003cfa:	85d2                	mv	a1,s4
    80003cfc:	854e                	mv	a0,s3
    80003cfe:	00000097          	auipc	ra,0x0
    80003d02:	e64080e7          	jalr	-412(ra) # 80003b62 <dirlookup>
    80003d06:	8caa                	mv	s9,a0
    80003d08:	dd51                	beqz	a0,80003ca4 <namex+0x92>
    iunlockput(ip);
    80003d0a:	854e                	mv	a0,s3
    80003d0c:	00000097          	auipc	ra,0x0
    80003d10:	bdc080e7          	jalr	-1060(ra) # 800038e8 <iunlockput>
    ip = next;
    80003d14:	89e6                	mv	s3,s9
  while(*path == '/')
    80003d16:	0004c783          	lbu	a5,0(s1)
    80003d1a:	05279763          	bne	a5,s2,80003d68 <namex+0x156>
    path++;
    80003d1e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d20:	0004c783          	lbu	a5,0(s1)
    80003d24:	ff278de3          	beq	a5,s2,80003d1e <namex+0x10c>
  if(*path == 0)
    80003d28:	c79d                	beqz	a5,80003d56 <namex+0x144>
    path++;
    80003d2a:	85a6                	mv	a1,s1
  len = path - s;
    80003d2c:	8cda                	mv	s9,s6
    80003d2e:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003d30:	01278963          	beq	a5,s2,80003d42 <namex+0x130>
    80003d34:	dfbd                	beqz	a5,80003cb2 <namex+0xa0>
    path++;
    80003d36:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003d38:	0004c783          	lbu	a5,0(s1)
    80003d3c:	ff279ce3          	bne	a5,s2,80003d34 <namex+0x122>
    80003d40:	bf8d                	j	80003cb2 <namex+0xa0>
    memmove(name, s, len);
    80003d42:	2601                	sext.w	a2,a2
    80003d44:	8552                	mv	a0,s4
    80003d46:	ffffd097          	auipc	ra,0xffffd
    80003d4a:	e98080e7          	jalr	-360(ra) # 80000bde <memmove>
    name[len] = 0;
    80003d4e:	9cd2                	add	s9,s9,s4
    80003d50:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003d54:	bf9d                	j	80003cca <namex+0xb8>
  if(nameiparent){
    80003d56:	f20a83e3          	beqz	s5,80003c7c <namex+0x6a>
    iput(ip);
    80003d5a:	854e                	mv	a0,s3
    80003d5c:	00000097          	auipc	ra,0x0
    80003d60:	a5c080e7          	jalr	-1444(ra) # 800037b8 <iput>
    return 0;
    80003d64:	4981                	li	s3,0
    80003d66:	bf19                	j	80003c7c <namex+0x6a>
  if(*path == 0)
    80003d68:	d7fd                	beqz	a5,80003d56 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003d6a:	0004c783          	lbu	a5,0(s1)
    80003d6e:	85a6                	mv	a1,s1
    80003d70:	b7d1                	j	80003d34 <namex+0x122>

0000000080003d72 <dirlink>:
{
    80003d72:	7139                	addi	sp,sp,-64
    80003d74:	fc06                	sd	ra,56(sp)
    80003d76:	f822                	sd	s0,48(sp)
    80003d78:	f426                	sd	s1,40(sp)
    80003d7a:	f04a                	sd	s2,32(sp)
    80003d7c:	ec4e                	sd	s3,24(sp)
    80003d7e:	e852                	sd	s4,16(sp)
    80003d80:	0080                	addi	s0,sp,64
    80003d82:	892a                	mv	s2,a0
    80003d84:	8a2e                	mv	s4,a1
    80003d86:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003d88:	4601                	li	a2,0
    80003d8a:	00000097          	auipc	ra,0x0
    80003d8e:	dd8080e7          	jalr	-552(ra) # 80003b62 <dirlookup>
    80003d92:	e93d                	bnez	a0,80003e08 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d94:	04c92483          	lw	s1,76(s2)
    80003d98:	c49d                	beqz	s1,80003dc6 <dirlink+0x54>
    80003d9a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d9c:	4741                	li	a4,16
    80003d9e:	86a6                	mv	a3,s1
    80003da0:	fc040613          	addi	a2,s0,-64
    80003da4:	4581                	li	a1,0
    80003da6:	854a                	mv	a0,s2
    80003da8:	00000097          	auipc	ra,0x0
    80003dac:	b92080e7          	jalr	-1134(ra) # 8000393a <readi>
    80003db0:	47c1                	li	a5,16
    80003db2:	06f51163          	bne	a0,a5,80003e14 <dirlink+0xa2>
    if(de.inum == 0)
    80003db6:	fc045783          	lhu	a5,-64(s0)
    80003dba:	c791                	beqz	a5,80003dc6 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dbc:	24c1                	addiw	s1,s1,16
    80003dbe:	04c92783          	lw	a5,76(s2)
    80003dc2:	fcf4ede3          	bltu	s1,a5,80003d9c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003dc6:	4639                	li	a2,14
    80003dc8:	85d2                	mv	a1,s4
    80003dca:	fc240513          	addi	a0,s0,-62
    80003dce:	ffffd097          	auipc	ra,0xffffd
    80003dd2:	ec8080e7          	jalr	-312(ra) # 80000c96 <strncpy>
  de.inum = inum;
    80003dd6:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dda:	4741                	li	a4,16
    80003ddc:	86a6                	mv	a3,s1
    80003dde:	fc040613          	addi	a2,s0,-64
    80003de2:	4581                	li	a1,0
    80003de4:	854a                	mv	a0,s2
    80003de6:	00000097          	auipc	ra,0x0
    80003dea:	c48080e7          	jalr	-952(ra) # 80003a2e <writei>
    80003dee:	872a                	mv	a4,a0
    80003df0:	47c1                	li	a5,16
  return 0;
    80003df2:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003df4:	02f71863          	bne	a4,a5,80003e24 <dirlink+0xb2>
}
    80003df8:	70e2                	ld	ra,56(sp)
    80003dfa:	7442                	ld	s0,48(sp)
    80003dfc:	74a2                	ld	s1,40(sp)
    80003dfe:	7902                	ld	s2,32(sp)
    80003e00:	69e2                	ld	s3,24(sp)
    80003e02:	6a42                	ld	s4,16(sp)
    80003e04:	6121                	addi	sp,sp,64
    80003e06:	8082                	ret
    iput(ip);
    80003e08:	00000097          	auipc	ra,0x0
    80003e0c:	9b0080e7          	jalr	-1616(ra) # 800037b8 <iput>
    return -1;
    80003e10:	557d                	li	a0,-1
    80003e12:	b7dd                	j	80003df8 <dirlink+0x86>
      panic("dirlink read");
    80003e14:	00004517          	auipc	a0,0x4
    80003e18:	7c450513          	addi	a0,a0,1988 # 800085d8 <userret+0x548>
    80003e1c:	ffffc097          	auipc	ra,0xffffc
    80003e20:	72c080e7          	jalr	1836(ra) # 80000548 <panic>
    panic("dirlink");
    80003e24:	00005517          	auipc	a0,0x5
    80003e28:	96450513          	addi	a0,a0,-1692 # 80008788 <userret+0x6f8>
    80003e2c:	ffffc097          	auipc	ra,0xffffc
    80003e30:	71c080e7          	jalr	1820(ra) # 80000548 <panic>

0000000080003e34 <namei>:

struct inode*
namei(char *path)
{
    80003e34:	1101                	addi	sp,sp,-32
    80003e36:	ec06                	sd	ra,24(sp)
    80003e38:	e822                	sd	s0,16(sp)
    80003e3a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e3c:	fe040613          	addi	a2,s0,-32
    80003e40:	4581                	li	a1,0
    80003e42:	00000097          	auipc	ra,0x0
    80003e46:	dd0080e7          	jalr	-560(ra) # 80003c12 <namex>
}
    80003e4a:	60e2                	ld	ra,24(sp)
    80003e4c:	6442                	ld	s0,16(sp)
    80003e4e:	6105                	addi	sp,sp,32
    80003e50:	8082                	ret

0000000080003e52 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003e52:	1141                	addi	sp,sp,-16
    80003e54:	e406                	sd	ra,8(sp)
    80003e56:	e022                	sd	s0,0(sp)
    80003e58:	0800                	addi	s0,sp,16
    80003e5a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003e5c:	4585                	li	a1,1
    80003e5e:	00000097          	auipc	ra,0x0
    80003e62:	db4080e7          	jalr	-588(ra) # 80003c12 <namex>
}
    80003e66:	60a2                	ld	ra,8(sp)
    80003e68:	6402                	ld	s0,0(sp)
    80003e6a:	0141                	addi	sp,sp,16
    80003e6c:	8082                	ret

0000000080003e6e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(int dev)
{
    80003e6e:	7179                	addi	sp,sp,-48
    80003e70:	f406                	sd	ra,40(sp)
    80003e72:	f022                	sd	s0,32(sp)
    80003e74:	ec26                	sd	s1,24(sp)
    80003e76:	e84a                	sd	s2,16(sp)
    80003e78:	e44e                	sd	s3,8(sp)
    80003e7a:	1800                	addi	s0,sp,48
    80003e7c:	84aa                	mv	s1,a0
  struct buf *buf = bread(dev, log[dev].start);
    80003e7e:	0a800993          	li	s3,168
    80003e82:	033507b3          	mul	a5,a0,s3
    80003e86:	0001f997          	auipc	s3,0x1f
    80003e8a:	b1298993          	addi	s3,s3,-1262 # 80022998 <log>
    80003e8e:	99be                	add	s3,s3,a5
    80003e90:	0189a583          	lw	a1,24(s3)
    80003e94:	fffff097          	auipc	ra,0xfffff
    80003e98:	00e080e7          	jalr	14(ra) # 80002ea2 <bread>
    80003e9c:	892a                	mv	s2,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log[dev].lh.n;
    80003e9e:	02c9a783          	lw	a5,44(s3)
    80003ea2:	d13c                	sw	a5,96(a0)
  for (i = 0; i < log[dev].lh.n; i++) {
    80003ea4:	02c9a783          	lw	a5,44(s3)
    80003ea8:	02f05763          	blez	a5,80003ed6 <write_head+0x68>
    80003eac:	0a800793          	li	a5,168
    80003eb0:	02f487b3          	mul	a5,s1,a5
    80003eb4:	0001f717          	auipc	a4,0x1f
    80003eb8:	b1470713          	addi	a4,a4,-1260 # 800229c8 <log+0x30>
    80003ebc:	97ba                	add	a5,a5,a4
    80003ebe:	06450693          	addi	a3,a0,100
    80003ec2:	4701                	li	a4,0
    80003ec4:	85ce                	mv	a1,s3
    hb->block[i] = log[dev].lh.block[i];
    80003ec6:	4390                	lw	a2,0(a5)
    80003ec8:	c290                	sw	a2,0(a3)
  for (i = 0; i < log[dev].lh.n; i++) {
    80003eca:	2705                	addiw	a4,a4,1
    80003ecc:	0791                	addi	a5,a5,4
    80003ece:	0691                	addi	a3,a3,4
    80003ed0:	55d0                	lw	a2,44(a1)
    80003ed2:	fec74ae3          	blt	a4,a2,80003ec6 <write_head+0x58>
  }
  bwrite(buf);
    80003ed6:	854a                	mv	a0,s2
    80003ed8:	fffff097          	auipc	ra,0xfffff
    80003edc:	0be080e7          	jalr	190(ra) # 80002f96 <bwrite>
  brelse(buf);
    80003ee0:	854a                	mv	a0,s2
    80003ee2:	fffff097          	auipc	ra,0xfffff
    80003ee6:	0f4080e7          	jalr	244(ra) # 80002fd6 <brelse>
}
    80003eea:	70a2                	ld	ra,40(sp)
    80003eec:	7402                	ld	s0,32(sp)
    80003eee:	64e2                	ld	s1,24(sp)
    80003ef0:	6942                	ld	s2,16(sp)
    80003ef2:	69a2                	ld	s3,8(sp)
    80003ef4:	6145                	addi	sp,sp,48
    80003ef6:	8082                	ret

0000000080003ef8 <write_log>:
static void
write_log(int dev)
{
  int tail;

  for (tail = 0; tail < log[dev].lh.n; tail++) {
    80003ef8:	0a800793          	li	a5,168
    80003efc:	02f50733          	mul	a4,a0,a5
    80003f00:	0001f797          	auipc	a5,0x1f
    80003f04:	a9878793          	addi	a5,a5,-1384 # 80022998 <log>
    80003f08:	97ba                	add	a5,a5,a4
    80003f0a:	57dc                	lw	a5,44(a5)
    80003f0c:	0af05663          	blez	a5,80003fb8 <write_log+0xc0>
{
    80003f10:	7139                	addi	sp,sp,-64
    80003f12:	fc06                	sd	ra,56(sp)
    80003f14:	f822                	sd	s0,48(sp)
    80003f16:	f426                	sd	s1,40(sp)
    80003f18:	f04a                	sd	s2,32(sp)
    80003f1a:	ec4e                	sd	s3,24(sp)
    80003f1c:	e852                	sd	s4,16(sp)
    80003f1e:	e456                	sd	s5,8(sp)
    80003f20:	e05a                	sd	s6,0(sp)
    80003f22:	0080                	addi	s0,sp,64
    80003f24:	0001f797          	auipc	a5,0x1f
    80003f28:	aa478793          	addi	a5,a5,-1372 # 800229c8 <log+0x30>
    80003f2c:	00f70a33          	add	s4,a4,a5
  for (tail = 0; tail < log[dev].lh.n; tail++) {
    80003f30:	4981                	li	s3,0
    struct buf *to = bread(dev, log[dev].start+tail+1); // log block
    80003f32:	00050b1b          	sext.w	s6,a0
    80003f36:	0001fa97          	auipc	s5,0x1f
    80003f3a:	a62a8a93          	addi	s5,s5,-1438 # 80022998 <log>
    80003f3e:	9aba                	add	s5,s5,a4
    80003f40:	018aa583          	lw	a1,24(s5)
    80003f44:	013585bb          	addw	a1,a1,s3
    80003f48:	2585                	addiw	a1,a1,1
    80003f4a:	855a                	mv	a0,s6
    80003f4c:	fffff097          	auipc	ra,0xfffff
    80003f50:	f56080e7          	jalr	-170(ra) # 80002ea2 <bread>
    80003f54:	84aa                	mv	s1,a0
    struct buf *from = bread(dev, log[dev].lh.block[tail]); // cache block
    80003f56:	000a2583          	lw	a1,0(s4)
    80003f5a:	855a                	mv	a0,s6
    80003f5c:	fffff097          	auipc	ra,0xfffff
    80003f60:	f46080e7          	jalr	-186(ra) # 80002ea2 <bread>
    80003f64:	892a                	mv	s2,a0
    memmove(to->data, from->data, BSIZE);
    80003f66:	40000613          	li	a2,1024
    80003f6a:	06050593          	addi	a1,a0,96
    80003f6e:	06048513          	addi	a0,s1,96
    80003f72:	ffffd097          	auipc	ra,0xffffd
    80003f76:	c6c080e7          	jalr	-916(ra) # 80000bde <memmove>
    bwrite(to);  // write the log
    80003f7a:	8526                	mv	a0,s1
    80003f7c:	fffff097          	auipc	ra,0xfffff
    80003f80:	01a080e7          	jalr	26(ra) # 80002f96 <bwrite>
    brelse(from);
    80003f84:	854a                	mv	a0,s2
    80003f86:	fffff097          	auipc	ra,0xfffff
    80003f8a:	050080e7          	jalr	80(ra) # 80002fd6 <brelse>
    brelse(to);
    80003f8e:	8526                	mv	a0,s1
    80003f90:	fffff097          	auipc	ra,0xfffff
    80003f94:	046080e7          	jalr	70(ra) # 80002fd6 <brelse>
  for (tail = 0; tail < log[dev].lh.n; tail++) {
    80003f98:	2985                	addiw	s3,s3,1
    80003f9a:	0a11                	addi	s4,s4,4
    80003f9c:	02caa783          	lw	a5,44(s5)
    80003fa0:	faf9c0e3          	blt	s3,a5,80003f40 <write_log+0x48>
  }
}
    80003fa4:	70e2                	ld	ra,56(sp)
    80003fa6:	7442                	ld	s0,48(sp)
    80003fa8:	74a2                	ld	s1,40(sp)
    80003faa:	7902                	ld	s2,32(sp)
    80003fac:	69e2                	ld	s3,24(sp)
    80003fae:	6a42                	ld	s4,16(sp)
    80003fb0:	6aa2                	ld	s5,8(sp)
    80003fb2:	6b02                	ld	s6,0(sp)
    80003fb4:	6121                	addi	sp,sp,64
    80003fb6:	8082                	ret
    80003fb8:	8082                	ret

0000000080003fba <install_trans>:
  for (tail = 0; tail < log[dev].lh.n; tail++) {
    80003fba:	0a800793          	li	a5,168
    80003fbe:	02f50733          	mul	a4,a0,a5
    80003fc2:	0001f797          	auipc	a5,0x1f
    80003fc6:	9d678793          	addi	a5,a5,-1578 # 80022998 <log>
    80003fca:	97ba                	add	a5,a5,a4
    80003fcc:	57dc                	lw	a5,44(a5)
    80003fce:	0af05b63          	blez	a5,80004084 <install_trans+0xca>
{
    80003fd2:	7139                	addi	sp,sp,-64
    80003fd4:	fc06                	sd	ra,56(sp)
    80003fd6:	f822                	sd	s0,48(sp)
    80003fd8:	f426                	sd	s1,40(sp)
    80003fda:	f04a                	sd	s2,32(sp)
    80003fdc:	ec4e                	sd	s3,24(sp)
    80003fde:	e852                	sd	s4,16(sp)
    80003fe0:	e456                	sd	s5,8(sp)
    80003fe2:	e05a                	sd	s6,0(sp)
    80003fe4:	0080                	addi	s0,sp,64
    80003fe6:	0001f797          	auipc	a5,0x1f
    80003fea:	9e278793          	addi	a5,a5,-1566 # 800229c8 <log+0x30>
    80003fee:	00f70a33          	add	s4,a4,a5
  for (tail = 0; tail < log[dev].lh.n; tail++) {
    80003ff2:	4981                	li	s3,0
    struct buf *lbuf = bread(dev, log[dev].start+tail+1); // read log block
    80003ff4:	00050b1b          	sext.w	s6,a0
    80003ff8:	0001fa97          	auipc	s5,0x1f
    80003ffc:	9a0a8a93          	addi	s5,s5,-1632 # 80022998 <log>
    80004000:	9aba                	add	s5,s5,a4
    80004002:	018aa583          	lw	a1,24(s5)
    80004006:	013585bb          	addw	a1,a1,s3
    8000400a:	2585                	addiw	a1,a1,1
    8000400c:	855a                	mv	a0,s6
    8000400e:	fffff097          	auipc	ra,0xfffff
    80004012:	e94080e7          	jalr	-364(ra) # 80002ea2 <bread>
    80004016:	892a                	mv	s2,a0
    struct buf *dbuf = bread(dev, log[dev].lh.block[tail]); // read dst
    80004018:	000a2583          	lw	a1,0(s4)
    8000401c:	855a                	mv	a0,s6
    8000401e:	fffff097          	auipc	ra,0xfffff
    80004022:	e84080e7          	jalr	-380(ra) # 80002ea2 <bread>
    80004026:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004028:	40000613          	li	a2,1024
    8000402c:	06090593          	addi	a1,s2,96
    80004030:	06050513          	addi	a0,a0,96
    80004034:	ffffd097          	auipc	ra,0xffffd
    80004038:	baa080e7          	jalr	-1110(ra) # 80000bde <memmove>
    bwrite(dbuf);  // write dst to disk
    8000403c:	8526                	mv	a0,s1
    8000403e:	fffff097          	auipc	ra,0xfffff
    80004042:	f58080e7          	jalr	-168(ra) # 80002f96 <bwrite>
    bunpin(dbuf);
    80004046:	8526                	mv	a0,s1
    80004048:	fffff097          	auipc	ra,0xfffff
    8000404c:	068080e7          	jalr	104(ra) # 800030b0 <bunpin>
    brelse(lbuf);
    80004050:	854a                	mv	a0,s2
    80004052:	fffff097          	auipc	ra,0xfffff
    80004056:	f84080e7          	jalr	-124(ra) # 80002fd6 <brelse>
    brelse(dbuf);
    8000405a:	8526                	mv	a0,s1
    8000405c:	fffff097          	auipc	ra,0xfffff
    80004060:	f7a080e7          	jalr	-134(ra) # 80002fd6 <brelse>
  for (tail = 0; tail < log[dev].lh.n; tail++) {
    80004064:	2985                	addiw	s3,s3,1
    80004066:	0a11                	addi	s4,s4,4
    80004068:	02caa783          	lw	a5,44(s5)
    8000406c:	f8f9cbe3          	blt	s3,a5,80004002 <install_trans+0x48>
}
    80004070:	70e2                	ld	ra,56(sp)
    80004072:	7442                	ld	s0,48(sp)
    80004074:	74a2                	ld	s1,40(sp)
    80004076:	7902                	ld	s2,32(sp)
    80004078:	69e2                	ld	s3,24(sp)
    8000407a:	6a42                	ld	s4,16(sp)
    8000407c:	6aa2                	ld	s5,8(sp)
    8000407e:	6b02                	ld	s6,0(sp)
    80004080:	6121                	addi	sp,sp,64
    80004082:	8082                	ret
    80004084:	8082                	ret

0000000080004086 <initlog>:
{
    80004086:	7179                	addi	sp,sp,-48
    80004088:	f406                	sd	ra,40(sp)
    8000408a:	f022                	sd	s0,32(sp)
    8000408c:	ec26                	sd	s1,24(sp)
    8000408e:	e84a                	sd	s2,16(sp)
    80004090:	e44e                	sd	s3,8(sp)
    80004092:	e052                	sd	s4,0(sp)
    80004094:	1800                	addi	s0,sp,48
    80004096:	892a                	mv	s2,a0
    80004098:	8a2e                	mv	s4,a1
  initlock(&log[dev].lock, "log");
    8000409a:	0a800713          	li	a4,168
    8000409e:	02e504b3          	mul	s1,a0,a4
    800040a2:	0001f997          	auipc	s3,0x1f
    800040a6:	8f698993          	addi	s3,s3,-1802 # 80022998 <log>
    800040aa:	99a6                	add	s3,s3,s1
    800040ac:	00004597          	auipc	a1,0x4
    800040b0:	53c58593          	addi	a1,a1,1340 # 800085e8 <userret+0x558>
    800040b4:	854e                	mv	a0,s3
    800040b6:	ffffd097          	auipc	ra,0xffffd
    800040ba:	8fa080e7          	jalr	-1798(ra) # 800009b0 <initlock>
  log[dev].start = sb->logstart;
    800040be:	014a2583          	lw	a1,20(s4)
    800040c2:	00b9ac23          	sw	a1,24(s3)
  log[dev].size = sb->nlog;
    800040c6:	010a2783          	lw	a5,16(s4)
    800040ca:	00f9ae23          	sw	a5,28(s3)
  log[dev].dev = dev;
    800040ce:	0329a423          	sw	s2,40(s3)
  struct buf *buf = bread(dev, log[dev].start);
    800040d2:	854a                	mv	a0,s2
    800040d4:	fffff097          	auipc	ra,0xfffff
    800040d8:	dce080e7          	jalr	-562(ra) # 80002ea2 <bread>
  log[dev].lh.n = lh->n;
    800040dc:	5134                	lw	a3,96(a0)
    800040de:	02d9a623          	sw	a3,44(s3)
  for (i = 0; i < log[dev].lh.n; i++) {
    800040e2:	02d05763          	blez	a3,80004110 <initlog+0x8a>
    800040e6:	06450793          	addi	a5,a0,100
    800040ea:	0001f717          	auipc	a4,0x1f
    800040ee:	8de70713          	addi	a4,a4,-1826 # 800229c8 <log+0x30>
    800040f2:	9726                	add	a4,a4,s1
    800040f4:	36fd                	addiw	a3,a3,-1
    800040f6:	02069613          	slli	a2,a3,0x20
    800040fa:	01e65693          	srli	a3,a2,0x1e
    800040fe:	06850613          	addi	a2,a0,104
    80004102:	96b2                	add	a3,a3,a2
    log[dev].lh.block[i] = lh->block[i];
    80004104:	4390                	lw	a2,0(a5)
    80004106:	c310                	sw	a2,0(a4)
  for (i = 0; i < log[dev].lh.n; i++) {
    80004108:	0791                	addi	a5,a5,4
    8000410a:	0711                	addi	a4,a4,4
    8000410c:	fed79ce3          	bne	a5,a3,80004104 <initlog+0x7e>
  brelse(buf);
    80004110:	fffff097          	auipc	ra,0xfffff
    80004114:	ec6080e7          	jalr	-314(ra) # 80002fd6 <brelse>
  install_trans(dev); // if committed, copy from log to disk
    80004118:	854a                	mv	a0,s2
    8000411a:	00000097          	auipc	ra,0x0
    8000411e:	ea0080e7          	jalr	-352(ra) # 80003fba <install_trans>
  log[dev].lh.n = 0;
    80004122:	0a800793          	li	a5,168
    80004126:	02f90733          	mul	a4,s2,a5
    8000412a:	0001f797          	auipc	a5,0x1f
    8000412e:	86e78793          	addi	a5,a5,-1938 # 80022998 <log>
    80004132:	97ba                	add	a5,a5,a4
    80004134:	0207a623          	sw	zero,44(a5)
  write_head(dev); // clear the log
    80004138:	854a                	mv	a0,s2
    8000413a:	00000097          	auipc	ra,0x0
    8000413e:	d34080e7          	jalr	-716(ra) # 80003e6e <write_head>
}
    80004142:	70a2                	ld	ra,40(sp)
    80004144:	7402                	ld	s0,32(sp)
    80004146:	64e2                	ld	s1,24(sp)
    80004148:	6942                	ld	s2,16(sp)
    8000414a:	69a2                	ld	s3,8(sp)
    8000414c:	6a02                	ld	s4,0(sp)
    8000414e:	6145                	addi	sp,sp,48
    80004150:	8082                	ret

0000000080004152 <begin_op>:
{
    80004152:	7139                	addi	sp,sp,-64
    80004154:	fc06                	sd	ra,56(sp)
    80004156:	f822                	sd	s0,48(sp)
    80004158:	f426                	sd	s1,40(sp)
    8000415a:	f04a                	sd	s2,32(sp)
    8000415c:	ec4e                	sd	s3,24(sp)
    8000415e:	e852                	sd	s4,16(sp)
    80004160:	e456                	sd	s5,8(sp)
    80004162:	0080                	addi	s0,sp,64
    80004164:	8aaa                	mv	s5,a0
  acquire(&log[dev].lock);
    80004166:	0a800913          	li	s2,168
    8000416a:	032507b3          	mul	a5,a0,s2
    8000416e:	0001f917          	auipc	s2,0x1f
    80004172:	82a90913          	addi	s2,s2,-2006 # 80022998 <log>
    80004176:	993e                	add	s2,s2,a5
    80004178:	854a                	mv	a0,s2
    8000417a:	ffffd097          	auipc	ra,0xffffd
    8000417e:	944080e7          	jalr	-1724(ra) # 80000abe <acquire>
    if(log[dev].committing){
    80004182:	0001f997          	auipc	s3,0x1f
    80004186:	81698993          	addi	s3,s3,-2026 # 80022998 <log>
    8000418a:	84ca                	mv	s1,s2
    } else if(log[dev].lh.n + (log[dev].outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000418c:	4a79                	li	s4,30
    8000418e:	a039                	j	8000419c <begin_op+0x4a>
      sleep(&log, &log[dev].lock);
    80004190:	85ca                	mv	a1,s2
    80004192:	854e                	mv	a0,s3
    80004194:	ffffe097          	auipc	ra,0xffffe
    80004198:	02a080e7          	jalr	42(ra) # 800021be <sleep>
    if(log[dev].committing){
    8000419c:	50dc                	lw	a5,36(s1)
    8000419e:	fbed                	bnez	a5,80004190 <begin_op+0x3e>
    } else if(log[dev].lh.n + (log[dev].outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041a0:	509c                	lw	a5,32(s1)
    800041a2:	0017871b          	addiw	a4,a5,1
    800041a6:	0007069b          	sext.w	a3,a4
    800041aa:	0027179b          	slliw	a5,a4,0x2
    800041ae:	9fb9                	addw	a5,a5,a4
    800041b0:	0017979b          	slliw	a5,a5,0x1
    800041b4:	54d8                	lw	a4,44(s1)
    800041b6:	9fb9                	addw	a5,a5,a4
    800041b8:	00fa5963          	bge	s4,a5,800041ca <begin_op+0x78>
      sleep(&log, &log[dev].lock);
    800041bc:	85ca                	mv	a1,s2
    800041be:	854e                	mv	a0,s3
    800041c0:	ffffe097          	auipc	ra,0xffffe
    800041c4:	ffe080e7          	jalr	-2(ra) # 800021be <sleep>
    800041c8:	bfd1                	j	8000419c <begin_op+0x4a>
      log[dev].outstanding += 1;
    800041ca:	0a800513          	li	a0,168
    800041ce:	02aa8ab3          	mul	s5,s5,a0
    800041d2:	0001e797          	auipc	a5,0x1e
    800041d6:	7c678793          	addi	a5,a5,1990 # 80022998 <log>
    800041da:	9abe                	add	s5,s5,a5
    800041dc:	02daa023          	sw	a3,32(s5)
      release(&log[dev].lock);
    800041e0:	854a                	mv	a0,s2
    800041e2:	ffffd097          	auipc	ra,0xffffd
    800041e6:	944080e7          	jalr	-1724(ra) # 80000b26 <release>
}
    800041ea:	70e2                	ld	ra,56(sp)
    800041ec:	7442                	ld	s0,48(sp)
    800041ee:	74a2                	ld	s1,40(sp)
    800041f0:	7902                	ld	s2,32(sp)
    800041f2:	69e2                	ld	s3,24(sp)
    800041f4:	6a42                	ld	s4,16(sp)
    800041f6:	6aa2                	ld	s5,8(sp)
    800041f8:	6121                	addi	sp,sp,64
    800041fa:	8082                	ret

00000000800041fc <end_op>:
{
    800041fc:	7179                	addi	sp,sp,-48
    800041fe:	f406                	sd	ra,40(sp)
    80004200:	f022                	sd	s0,32(sp)
    80004202:	ec26                	sd	s1,24(sp)
    80004204:	e84a                	sd	s2,16(sp)
    80004206:	e44e                	sd	s3,8(sp)
    80004208:	1800                	addi	s0,sp,48
    8000420a:	892a                	mv	s2,a0
  acquire(&log[dev].lock);
    8000420c:	0a800493          	li	s1,168
    80004210:	029507b3          	mul	a5,a0,s1
    80004214:	0001e497          	auipc	s1,0x1e
    80004218:	78448493          	addi	s1,s1,1924 # 80022998 <log>
    8000421c:	94be                	add	s1,s1,a5
    8000421e:	8526                	mv	a0,s1
    80004220:	ffffd097          	auipc	ra,0xffffd
    80004224:	89e080e7          	jalr	-1890(ra) # 80000abe <acquire>
  log[dev].outstanding -= 1;
    80004228:	509c                	lw	a5,32(s1)
    8000422a:	37fd                	addiw	a5,a5,-1
    8000422c:	0007871b          	sext.w	a4,a5
    80004230:	d09c                	sw	a5,32(s1)
  if(log[dev].committing)
    80004232:	50dc                	lw	a5,36(s1)
    80004234:	e3ad                	bnez	a5,80004296 <end_op+0x9a>
  if(log[dev].outstanding == 0){
    80004236:	eb25                	bnez	a4,800042a6 <end_op+0xaa>
    log[dev].committing = 1;
    80004238:	0a800993          	li	s3,168
    8000423c:	033907b3          	mul	a5,s2,s3
    80004240:	0001e997          	auipc	s3,0x1e
    80004244:	75898993          	addi	s3,s3,1880 # 80022998 <log>
    80004248:	99be                	add	s3,s3,a5
    8000424a:	4785                	li	a5,1
    8000424c:	02f9a223          	sw	a5,36(s3)
  release(&log[dev].lock);
    80004250:	8526                	mv	a0,s1
    80004252:	ffffd097          	auipc	ra,0xffffd
    80004256:	8d4080e7          	jalr	-1836(ra) # 80000b26 <release>

static void
commit(int dev)
{
  if (log[dev].lh.n > 0) {
    8000425a:	02c9a783          	lw	a5,44(s3)
    8000425e:	06f04863          	bgtz	a5,800042ce <end_op+0xd2>
    acquire(&log[dev].lock);
    80004262:	8526                	mv	a0,s1
    80004264:	ffffd097          	auipc	ra,0xffffd
    80004268:	85a080e7          	jalr	-1958(ra) # 80000abe <acquire>
    log[dev].committing = 0;
    8000426c:	0001e517          	auipc	a0,0x1e
    80004270:	72c50513          	addi	a0,a0,1836 # 80022998 <log>
    80004274:	0a800793          	li	a5,168
    80004278:	02f90933          	mul	s2,s2,a5
    8000427c:	992a                	add	s2,s2,a0
    8000427e:	02092223          	sw	zero,36(s2)
    wakeup(&log);
    80004282:	ffffe097          	auipc	ra,0xffffe
    80004286:	0bc080e7          	jalr	188(ra) # 8000233e <wakeup>
    release(&log[dev].lock);
    8000428a:	8526                	mv	a0,s1
    8000428c:	ffffd097          	auipc	ra,0xffffd
    80004290:	89a080e7          	jalr	-1894(ra) # 80000b26 <release>
}
    80004294:	a035                	j	800042c0 <end_op+0xc4>
    panic("log[dev].committing");
    80004296:	00004517          	auipc	a0,0x4
    8000429a:	35a50513          	addi	a0,a0,858 # 800085f0 <userret+0x560>
    8000429e:	ffffc097          	auipc	ra,0xffffc
    800042a2:	2aa080e7          	jalr	682(ra) # 80000548 <panic>
    wakeup(&log);
    800042a6:	0001e517          	auipc	a0,0x1e
    800042aa:	6f250513          	addi	a0,a0,1778 # 80022998 <log>
    800042ae:	ffffe097          	auipc	ra,0xffffe
    800042b2:	090080e7          	jalr	144(ra) # 8000233e <wakeup>
  release(&log[dev].lock);
    800042b6:	8526                	mv	a0,s1
    800042b8:	ffffd097          	auipc	ra,0xffffd
    800042bc:	86e080e7          	jalr	-1938(ra) # 80000b26 <release>
}
    800042c0:	70a2                	ld	ra,40(sp)
    800042c2:	7402                	ld	s0,32(sp)
    800042c4:	64e2                	ld	s1,24(sp)
    800042c6:	6942                	ld	s2,16(sp)
    800042c8:	69a2                	ld	s3,8(sp)
    800042ca:	6145                	addi	sp,sp,48
    800042cc:	8082                	ret
    write_log(dev);     // Write modified blocks from cache to log
    800042ce:	854a                	mv	a0,s2
    800042d0:	00000097          	auipc	ra,0x0
    800042d4:	c28080e7          	jalr	-984(ra) # 80003ef8 <write_log>
    write_head(dev);    // Write header to disk -- the real commit
    800042d8:	854a                	mv	a0,s2
    800042da:	00000097          	auipc	ra,0x0
    800042de:	b94080e7          	jalr	-1132(ra) # 80003e6e <write_head>
    install_trans(dev); // Now install writes to home locations
    800042e2:	854a                	mv	a0,s2
    800042e4:	00000097          	auipc	ra,0x0
    800042e8:	cd6080e7          	jalr	-810(ra) # 80003fba <install_trans>
    log[dev].lh.n = 0;
    800042ec:	0a800793          	li	a5,168
    800042f0:	02f90733          	mul	a4,s2,a5
    800042f4:	0001e797          	auipc	a5,0x1e
    800042f8:	6a478793          	addi	a5,a5,1700 # 80022998 <log>
    800042fc:	97ba                	add	a5,a5,a4
    800042fe:	0207a623          	sw	zero,44(a5)
    write_head(dev);    // Erase the transaction from the log
    80004302:	854a                	mv	a0,s2
    80004304:	00000097          	auipc	ra,0x0
    80004308:	b6a080e7          	jalr	-1174(ra) # 80003e6e <write_head>
    8000430c:	bf99                	j	80004262 <end_op+0x66>

000000008000430e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000430e:	7179                	addi	sp,sp,-48
    80004310:	f406                	sd	ra,40(sp)
    80004312:	f022                	sd	s0,32(sp)
    80004314:	ec26                	sd	s1,24(sp)
    80004316:	e84a                	sd	s2,16(sp)
    80004318:	e44e                	sd	s3,8(sp)
    8000431a:	e052                	sd	s4,0(sp)
    8000431c:	1800                	addi	s0,sp,48
  int i;

  int dev = b->dev;
    8000431e:	00852903          	lw	s2,8(a0)
  if (log[dev].lh.n >= LOGSIZE || log[dev].lh.n >= log[dev].size - 1)
    80004322:	0a800793          	li	a5,168
    80004326:	02f90733          	mul	a4,s2,a5
    8000432a:	0001e797          	auipc	a5,0x1e
    8000432e:	66e78793          	addi	a5,a5,1646 # 80022998 <log>
    80004332:	97ba                	add	a5,a5,a4
    80004334:	57d4                	lw	a3,44(a5)
    80004336:	47f5                	li	a5,29
    80004338:	0ad7cc63          	blt	a5,a3,800043f0 <log_write+0xe2>
    8000433c:	89aa                	mv	s3,a0
    8000433e:	0001e797          	auipc	a5,0x1e
    80004342:	65a78793          	addi	a5,a5,1626 # 80022998 <log>
    80004346:	97ba                	add	a5,a5,a4
    80004348:	4fdc                	lw	a5,28(a5)
    8000434a:	37fd                	addiw	a5,a5,-1
    8000434c:	0af6d263          	bge	a3,a5,800043f0 <log_write+0xe2>
    panic("too big a transaction");
  if (log[dev].outstanding < 1)
    80004350:	0a800793          	li	a5,168
    80004354:	02f90733          	mul	a4,s2,a5
    80004358:	0001e797          	auipc	a5,0x1e
    8000435c:	64078793          	addi	a5,a5,1600 # 80022998 <log>
    80004360:	97ba                	add	a5,a5,a4
    80004362:	539c                	lw	a5,32(a5)
    80004364:	08f05e63          	blez	a5,80004400 <log_write+0xf2>
    panic("log_write outside of trans");

  acquire(&log[dev].lock);
    80004368:	0a800793          	li	a5,168
    8000436c:	02f904b3          	mul	s1,s2,a5
    80004370:	0001ea17          	auipc	s4,0x1e
    80004374:	628a0a13          	addi	s4,s4,1576 # 80022998 <log>
    80004378:	9a26                	add	s4,s4,s1
    8000437a:	8552                	mv	a0,s4
    8000437c:	ffffc097          	auipc	ra,0xffffc
    80004380:	742080e7          	jalr	1858(ra) # 80000abe <acquire>
  for (i = 0; i < log[dev].lh.n; i++) {
    80004384:	02ca2603          	lw	a2,44(s4)
    80004388:	08c05463          	blez	a2,80004410 <log_write+0x102>
    if (log[dev].lh.block[i] == b->blockno)   // log absorbtion
    8000438c:	00c9a583          	lw	a1,12(s3)
    80004390:	0001e797          	auipc	a5,0x1e
    80004394:	63878793          	addi	a5,a5,1592 # 800229c8 <log+0x30>
    80004398:	97a6                	add	a5,a5,s1
  for (i = 0; i < log[dev].lh.n; i++) {
    8000439a:	4701                	li	a4,0
    if (log[dev].lh.block[i] == b->blockno)   // log absorbtion
    8000439c:	4394                	lw	a3,0(a5)
    8000439e:	06b68a63          	beq	a3,a1,80004412 <log_write+0x104>
  for (i = 0; i < log[dev].lh.n; i++) {
    800043a2:	2705                	addiw	a4,a4,1
    800043a4:	0791                	addi	a5,a5,4
    800043a6:	fec71be3          	bne	a4,a2,8000439c <log_write+0x8e>
      break;
  }
  log[dev].lh.block[i] = b->blockno;
    800043aa:	02a00793          	li	a5,42
    800043ae:	02f907b3          	mul	a5,s2,a5
    800043b2:	97b2                	add	a5,a5,a2
    800043b4:	07a1                	addi	a5,a5,8
    800043b6:	078a                	slli	a5,a5,0x2
    800043b8:	0001e717          	auipc	a4,0x1e
    800043bc:	5e070713          	addi	a4,a4,1504 # 80022998 <log>
    800043c0:	97ba                	add	a5,a5,a4
    800043c2:	00c9a703          	lw	a4,12(s3)
    800043c6:	cb98                	sw	a4,16(a5)
  if (i == log[dev].lh.n) {  // Add new block to log?
    bpin(b);
    800043c8:	854e                	mv	a0,s3
    800043ca:	fffff097          	auipc	ra,0xfffff
    800043ce:	caa080e7          	jalr	-854(ra) # 80003074 <bpin>
    log[dev].lh.n++;
    800043d2:	0a800793          	li	a5,168
    800043d6:	02f90933          	mul	s2,s2,a5
    800043da:	0001e797          	auipc	a5,0x1e
    800043de:	5be78793          	addi	a5,a5,1470 # 80022998 <log>
    800043e2:	993e                	add	s2,s2,a5
    800043e4:	02c92783          	lw	a5,44(s2)
    800043e8:	2785                	addiw	a5,a5,1
    800043ea:	02f92623          	sw	a5,44(s2)
    800043ee:	a099                	j	80004434 <log_write+0x126>
    panic("too big a transaction");
    800043f0:	00004517          	auipc	a0,0x4
    800043f4:	21850513          	addi	a0,a0,536 # 80008608 <userret+0x578>
    800043f8:	ffffc097          	auipc	ra,0xffffc
    800043fc:	150080e7          	jalr	336(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    80004400:	00004517          	auipc	a0,0x4
    80004404:	22050513          	addi	a0,a0,544 # 80008620 <userret+0x590>
    80004408:	ffffc097          	auipc	ra,0xffffc
    8000440c:	140080e7          	jalr	320(ra) # 80000548 <panic>
  for (i = 0; i < log[dev].lh.n; i++) {
    80004410:	4701                	li	a4,0
  log[dev].lh.block[i] = b->blockno;
    80004412:	02a00793          	li	a5,42
    80004416:	02f907b3          	mul	a5,s2,a5
    8000441a:	97ba                	add	a5,a5,a4
    8000441c:	07a1                	addi	a5,a5,8
    8000441e:	078a                	slli	a5,a5,0x2
    80004420:	0001e697          	auipc	a3,0x1e
    80004424:	57868693          	addi	a3,a3,1400 # 80022998 <log>
    80004428:	97b6                	add	a5,a5,a3
    8000442a:	00c9a683          	lw	a3,12(s3)
    8000442e:	cb94                	sw	a3,16(a5)
  if (i == log[dev].lh.n) {  // Add new block to log?
    80004430:	f8e60ce3          	beq	a2,a4,800043c8 <log_write+0xba>
  }
  release(&log[dev].lock);
    80004434:	8552                	mv	a0,s4
    80004436:	ffffc097          	auipc	ra,0xffffc
    8000443a:	6f0080e7          	jalr	1776(ra) # 80000b26 <release>
}
    8000443e:	70a2                	ld	ra,40(sp)
    80004440:	7402                	ld	s0,32(sp)
    80004442:	64e2                	ld	s1,24(sp)
    80004444:	6942                	ld	s2,16(sp)
    80004446:	69a2                	ld	s3,8(sp)
    80004448:	6a02                	ld	s4,0(sp)
    8000444a:	6145                	addi	sp,sp,48
    8000444c:	8082                	ret

000000008000444e <crash_op>:

// crash before commit or after commit
void
crash_op(int dev, int docommit)
{
    8000444e:	7179                	addi	sp,sp,-48
    80004450:	f406                	sd	ra,40(sp)
    80004452:	f022                	sd	s0,32(sp)
    80004454:	ec26                	sd	s1,24(sp)
    80004456:	e84a                	sd	s2,16(sp)
    80004458:	e44e                	sd	s3,8(sp)
    8000445a:	1800                	addi	s0,sp,48
    8000445c:	84aa                	mv	s1,a0
    8000445e:	89ae                	mv	s3,a1
  int do_commit = 0;
    
  acquire(&log[dev].lock);
    80004460:	0a800913          	li	s2,168
    80004464:	032507b3          	mul	a5,a0,s2
    80004468:	0001e917          	auipc	s2,0x1e
    8000446c:	53090913          	addi	s2,s2,1328 # 80022998 <log>
    80004470:	993e                	add	s2,s2,a5
    80004472:	854a                	mv	a0,s2
    80004474:	ffffc097          	auipc	ra,0xffffc
    80004478:	64a080e7          	jalr	1610(ra) # 80000abe <acquire>

  if (dev < 0 || dev >= NDISK)
    8000447c:	0004871b          	sext.w	a4,s1
    80004480:	4785                	li	a5,1
    80004482:	0ae7e063          	bltu	a5,a4,80004522 <crash_op+0xd4>
    panic("end_op: invalid disk");
  if(log[dev].outstanding == 0)
    80004486:	0a800793          	li	a5,168
    8000448a:	02f48733          	mul	a4,s1,a5
    8000448e:	0001e797          	auipc	a5,0x1e
    80004492:	50a78793          	addi	a5,a5,1290 # 80022998 <log>
    80004496:	97ba                	add	a5,a5,a4
    80004498:	539c                	lw	a5,32(a5)
    8000449a:	cfc1                	beqz	a5,80004532 <crash_op+0xe4>
    panic("end_op: already closed");
  log[dev].outstanding -= 1;
    8000449c:	37fd                	addiw	a5,a5,-1
    8000449e:	0007861b          	sext.w	a2,a5
    800044a2:	0a800713          	li	a4,168
    800044a6:	02e486b3          	mul	a3,s1,a4
    800044aa:	0001e717          	auipc	a4,0x1e
    800044ae:	4ee70713          	addi	a4,a4,1262 # 80022998 <log>
    800044b2:	9736                	add	a4,a4,a3
    800044b4:	d31c                	sw	a5,32(a4)
  if(log[dev].committing)
    800044b6:	535c                	lw	a5,36(a4)
    800044b8:	e7c9                	bnez	a5,80004542 <crash_op+0xf4>
    panic("log[dev].committing");
  if(log[dev].outstanding == 0){
    800044ba:	ee41                	bnez	a2,80004552 <crash_op+0x104>
    do_commit = 1;
    log[dev].committing = 1;
    800044bc:	0a800793          	li	a5,168
    800044c0:	02f48733          	mul	a4,s1,a5
    800044c4:	0001e797          	auipc	a5,0x1e
    800044c8:	4d478793          	addi	a5,a5,1236 # 80022998 <log>
    800044cc:	97ba                	add	a5,a5,a4
    800044ce:	4705                	li	a4,1
    800044d0:	d3d8                	sw	a4,36(a5)
  }
  
  release(&log[dev].lock);
    800044d2:	854a                	mv	a0,s2
    800044d4:	ffffc097          	auipc	ra,0xffffc
    800044d8:	652080e7          	jalr	1618(ra) # 80000b26 <release>

  if(docommit & do_commit){
    800044dc:	0019f993          	andi	s3,s3,1
    800044e0:	06098e63          	beqz	s3,8000455c <crash_op+0x10e>
    printf("crash_op: commit\n");
    800044e4:	00004517          	auipc	a0,0x4
    800044e8:	18c50513          	addi	a0,a0,396 # 80008670 <userret+0x5e0>
    800044ec:	ffffc097          	auipc	ra,0xffffc
    800044f0:	0a6080e7          	jalr	166(ra) # 80000592 <printf>
    // call commit w/o holding locks, since not allowed
    // to sleep with locks.

    if (log[dev].lh.n > 0) {
    800044f4:	0a800793          	li	a5,168
    800044f8:	02f48733          	mul	a4,s1,a5
    800044fc:	0001e797          	auipc	a5,0x1e
    80004500:	49c78793          	addi	a5,a5,1180 # 80022998 <log>
    80004504:	97ba                	add	a5,a5,a4
    80004506:	57dc                	lw	a5,44(a5)
    80004508:	04f05a63          	blez	a5,8000455c <crash_op+0x10e>
      write_log(dev);     // Write modified blocks from cache to log
    8000450c:	8526                	mv	a0,s1
    8000450e:	00000097          	auipc	ra,0x0
    80004512:	9ea080e7          	jalr	-1558(ra) # 80003ef8 <write_log>
      write_head(dev);    // Write header to disk -- the real commit
    80004516:	8526                	mv	a0,s1
    80004518:	00000097          	auipc	ra,0x0
    8000451c:	956080e7          	jalr	-1706(ra) # 80003e6e <write_head>
    80004520:	a835                	j	8000455c <crash_op+0x10e>
    panic("end_op: invalid disk");
    80004522:	00004517          	auipc	a0,0x4
    80004526:	11e50513          	addi	a0,a0,286 # 80008640 <userret+0x5b0>
    8000452a:	ffffc097          	auipc	ra,0xffffc
    8000452e:	01e080e7          	jalr	30(ra) # 80000548 <panic>
    panic("end_op: already closed");
    80004532:	00004517          	auipc	a0,0x4
    80004536:	12650513          	addi	a0,a0,294 # 80008658 <userret+0x5c8>
    8000453a:	ffffc097          	auipc	ra,0xffffc
    8000453e:	00e080e7          	jalr	14(ra) # 80000548 <panic>
    panic("log[dev].committing");
    80004542:	00004517          	auipc	a0,0x4
    80004546:	0ae50513          	addi	a0,a0,174 # 800085f0 <userret+0x560>
    8000454a:	ffffc097          	auipc	ra,0xffffc
    8000454e:	ffe080e7          	jalr	-2(ra) # 80000548 <panic>
  release(&log[dev].lock);
    80004552:	854a                	mv	a0,s2
    80004554:	ffffc097          	auipc	ra,0xffffc
    80004558:	5d2080e7          	jalr	1490(ra) # 80000b26 <release>
    }
  }
  panic("crashed file system; please restart xv6 and run crashtest\n");
    8000455c:	00004517          	auipc	a0,0x4
    80004560:	12c50513          	addi	a0,a0,300 # 80008688 <userret+0x5f8>
    80004564:	ffffc097          	auipc	ra,0xffffc
    80004568:	fe4080e7          	jalr	-28(ra) # 80000548 <panic>

000000008000456c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000456c:	1101                	addi	sp,sp,-32
    8000456e:	ec06                	sd	ra,24(sp)
    80004570:	e822                	sd	s0,16(sp)
    80004572:	e426                	sd	s1,8(sp)
    80004574:	e04a                	sd	s2,0(sp)
    80004576:	1000                	addi	s0,sp,32
    80004578:	84aa                	mv	s1,a0
    8000457a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000457c:	00004597          	auipc	a1,0x4
    80004580:	14c58593          	addi	a1,a1,332 # 800086c8 <userret+0x638>
    80004584:	0521                	addi	a0,a0,8
    80004586:	ffffc097          	auipc	ra,0xffffc
    8000458a:	42a080e7          	jalr	1066(ra) # 800009b0 <initlock>
  lk->name = name;
    8000458e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004592:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004596:	0204a423          	sw	zero,40(s1)
}
    8000459a:	60e2                	ld	ra,24(sp)
    8000459c:	6442                	ld	s0,16(sp)
    8000459e:	64a2                	ld	s1,8(sp)
    800045a0:	6902                	ld	s2,0(sp)
    800045a2:	6105                	addi	sp,sp,32
    800045a4:	8082                	ret

00000000800045a6 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800045a6:	1101                	addi	sp,sp,-32
    800045a8:	ec06                	sd	ra,24(sp)
    800045aa:	e822                	sd	s0,16(sp)
    800045ac:	e426                	sd	s1,8(sp)
    800045ae:	e04a                	sd	s2,0(sp)
    800045b0:	1000                	addi	s0,sp,32
    800045b2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045b4:	00850913          	addi	s2,a0,8
    800045b8:	854a                	mv	a0,s2
    800045ba:	ffffc097          	auipc	ra,0xffffc
    800045be:	504080e7          	jalr	1284(ra) # 80000abe <acquire>
  while (lk->locked) {
    800045c2:	409c                	lw	a5,0(s1)
    800045c4:	cb89                	beqz	a5,800045d6 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800045c6:	85ca                	mv	a1,s2
    800045c8:	8526                	mv	a0,s1
    800045ca:	ffffe097          	auipc	ra,0xffffe
    800045ce:	bf4080e7          	jalr	-1036(ra) # 800021be <sleep>
  while (lk->locked) {
    800045d2:	409c                	lw	a5,0(s1)
    800045d4:	fbed                	bnez	a5,800045c6 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800045d6:	4785                	li	a5,1
    800045d8:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800045da:	ffffd097          	auipc	ra,0xffffd
    800045de:	40e080e7          	jalr	1038(ra) # 800019e8 <myproc>
    800045e2:	5d1c                	lw	a5,56(a0)
    800045e4:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800045e6:	854a                	mv	a0,s2
    800045e8:	ffffc097          	auipc	ra,0xffffc
    800045ec:	53e080e7          	jalr	1342(ra) # 80000b26 <release>
}
    800045f0:	60e2                	ld	ra,24(sp)
    800045f2:	6442                	ld	s0,16(sp)
    800045f4:	64a2                	ld	s1,8(sp)
    800045f6:	6902                	ld	s2,0(sp)
    800045f8:	6105                	addi	sp,sp,32
    800045fa:	8082                	ret

00000000800045fc <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045fc:	1101                	addi	sp,sp,-32
    800045fe:	ec06                	sd	ra,24(sp)
    80004600:	e822                	sd	s0,16(sp)
    80004602:	e426                	sd	s1,8(sp)
    80004604:	e04a                	sd	s2,0(sp)
    80004606:	1000                	addi	s0,sp,32
    80004608:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000460a:	00850913          	addi	s2,a0,8
    8000460e:	854a                	mv	a0,s2
    80004610:	ffffc097          	auipc	ra,0xffffc
    80004614:	4ae080e7          	jalr	1198(ra) # 80000abe <acquire>
  lk->locked = 0;
    80004618:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000461c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004620:	8526                	mv	a0,s1
    80004622:	ffffe097          	auipc	ra,0xffffe
    80004626:	d1c080e7          	jalr	-740(ra) # 8000233e <wakeup>
  release(&lk->lk);
    8000462a:	854a                	mv	a0,s2
    8000462c:	ffffc097          	auipc	ra,0xffffc
    80004630:	4fa080e7          	jalr	1274(ra) # 80000b26 <release>
}
    80004634:	60e2                	ld	ra,24(sp)
    80004636:	6442                	ld	s0,16(sp)
    80004638:	64a2                	ld	s1,8(sp)
    8000463a:	6902                	ld	s2,0(sp)
    8000463c:	6105                	addi	sp,sp,32
    8000463e:	8082                	ret

0000000080004640 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004640:	7179                	addi	sp,sp,-48
    80004642:	f406                	sd	ra,40(sp)
    80004644:	f022                	sd	s0,32(sp)
    80004646:	ec26                	sd	s1,24(sp)
    80004648:	e84a                	sd	s2,16(sp)
    8000464a:	e44e                	sd	s3,8(sp)
    8000464c:	1800                	addi	s0,sp,48
    8000464e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004650:	00850913          	addi	s2,a0,8
    80004654:	854a                	mv	a0,s2
    80004656:	ffffc097          	auipc	ra,0xffffc
    8000465a:	468080e7          	jalr	1128(ra) # 80000abe <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000465e:	409c                	lw	a5,0(s1)
    80004660:	ef99                	bnez	a5,8000467e <holdingsleep+0x3e>
    80004662:	4481                	li	s1,0
  release(&lk->lk);
    80004664:	854a                	mv	a0,s2
    80004666:	ffffc097          	auipc	ra,0xffffc
    8000466a:	4c0080e7          	jalr	1216(ra) # 80000b26 <release>
  return r;
}
    8000466e:	8526                	mv	a0,s1
    80004670:	70a2                	ld	ra,40(sp)
    80004672:	7402                	ld	s0,32(sp)
    80004674:	64e2                	ld	s1,24(sp)
    80004676:	6942                	ld	s2,16(sp)
    80004678:	69a2                	ld	s3,8(sp)
    8000467a:	6145                	addi	sp,sp,48
    8000467c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000467e:	0284a983          	lw	s3,40(s1)
    80004682:	ffffd097          	auipc	ra,0xffffd
    80004686:	366080e7          	jalr	870(ra) # 800019e8 <myproc>
    8000468a:	5d04                	lw	s1,56(a0)
    8000468c:	413484b3          	sub	s1,s1,s3
    80004690:	0014b493          	seqz	s1,s1
    80004694:	bfc1                	j	80004664 <holdingsleep+0x24>

0000000080004696 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004696:	1141                	addi	sp,sp,-16
    80004698:	e406                	sd	ra,8(sp)
    8000469a:	e022                	sd	s0,0(sp)
    8000469c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000469e:	00004597          	auipc	a1,0x4
    800046a2:	03a58593          	addi	a1,a1,58 # 800086d8 <userret+0x648>
    800046a6:	0001e517          	auipc	a0,0x1e
    800046aa:	4e250513          	addi	a0,a0,1250 # 80022b88 <ftable>
    800046ae:	ffffc097          	auipc	ra,0xffffc
    800046b2:	302080e7          	jalr	770(ra) # 800009b0 <initlock>
}
    800046b6:	60a2                	ld	ra,8(sp)
    800046b8:	6402                	ld	s0,0(sp)
    800046ba:	0141                	addi	sp,sp,16
    800046bc:	8082                	ret

00000000800046be <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800046be:	1101                	addi	sp,sp,-32
    800046c0:	ec06                	sd	ra,24(sp)
    800046c2:	e822                	sd	s0,16(sp)
    800046c4:	e426                	sd	s1,8(sp)
    800046c6:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800046c8:	0001e517          	auipc	a0,0x1e
    800046cc:	4c050513          	addi	a0,a0,1216 # 80022b88 <ftable>
    800046d0:	ffffc097          	auipc	ra,0xffffc
    800046d4:	3ee080e7          	jalr	1006(ra) # 80000abe <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046d8:	0001e497          	auipc	s1,0x1e
    800046dc:	4c848493          	addi	s1,s1,1224 # 80022ba0 <ftable+0x18>
    800046e0:	0001f717          	auipc	a4,0x1f
    800046e4:	46070713          	addi	a4,a4,1120 # 80023b40 <ftable+0xfb8>
    if(f->ref == 0){
    800046e8:	40dc                	lw	a5,4(s1)
    800046ea:	cf99                	beqz	a5,80004708 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046ec:	02848493          	addi	s1,s1,40
    800046f0:	fee49ce3          	bne	s1,a4,800046e8 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800046f4:	0001e517          	auipc	a0,0x1e
    800046f8:	49450513          	addi	a0,a0,1172 # 80022b88 <ftable>
    800046fc:	ffffc097          	auipc	ra,0xffffc
    80004700:	42a080e7          	jalr	1066(ra) # 80000b26 <release>
  return 0;
    80004704:	4481                	li	s1,0
    80004706:	a819                	j	8000471c <filealloc+0x5e>
      f->ref = 1;
    80004708:	4785                	li	a5,1
    8000470a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000470c:	0001e517          	auipc	a0,0x1e
    80004710:	47c50513          	addi	a0,a0,1148 # 80022b88 <ftable>
    80004714:	ffffc097          	auipc	ra,0xffffc
    80004718:	412080e7          	jalr	1042(ra) # 80000b26 <release>
}
    8000471c:	8526                	mv	a0,s1
    8000471e:	60e2                	ld	ra,24(sp)
    80004720:	6442                	ld	s0,16(sp)
    80004722:	64a2                	ld	s1,8(sp)
    80004724:	6105                	addi	sp,sp,32
    80004726:	8082                	ret

0000000080004728 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004728:	1101                	addi	sp,sp,-32
    8000472a:	ec06                	sd	ra,24(sp)
    8000472c:	e822                	sd	s0,16(sp)
    8000472e:	e426                	sd	s1,8(sp)
    80004730:	1000                	addi	s0,sp,32
    80004732:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004734:	0001e517          	auipc	a0,0x1e
    80004738:	45450513          	addi	a0,a0,1108 # 80022b88 <ftable>
    8000473c:	ffffc097          	auipc	ra,0xffffc
    80004740:	382080e7          	jalr	898(ra) # 80000abe <acquire>
  if(f->ref < 1)
    80004744:	40dc                	lw	a5,4(s1)
    80004746:	02f05263          	blez	a5,8000476a <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000474a:	2785                	addiw	a5,a5,1
    8000474c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000474e:	0001e517          	auipc	a0,0x1e
    80004752:	43a50513          	addi	a0,a0,1082 # 80022b88 <ftable>
    80004756:	ffffc097          	auipc	ra,0xffffc
    8000475a:	3d0080e7          	jalr	976(ra) # 80000b26 <release>
  return f;
}
    8000475e:	8526                	mv	a0,s1
    80004760:	60e2                	ld	ra,24(sp)
    80004762:	6442                	ld	s0,16(sp)
    80004764:	64a2                	ld	s1,8(sp)
    80004766:	6105                	addi	sp,sp,32
    80004768:	8082                	ret
    panic("filedup");
    8000476a:	00004517          	auipc	a0,0x4
    8000476e:	f7650513          	addi	a0,a0,-138 # 800086e0 <userret+0x650>
    80004772:	ffffc097          	auipc	ra,0xffffc
    80004776:	dd6080e7          	jalr	-554(ra) # 80000548 <panic>

000000008000477a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000477a:	7139                	addi	sp,sp,-64
    8000477c:	fc06                	sd	ra,56(sp)
    8000477e:	f822                	sd	s0,48(sp)
    80004780:	f426                	sd	s1,40(sp)
    80004782:	f04a                	sd	s2,32(sp)
    80004784:	ec4e                	sd	s3,24(sp)
    80004786:	e852                	sd	s4,16(sp)
    80004788:	e456                	sd	s5,8(sp)
    8000478a:	0080                	addi	s0,sp,64
    8000478c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000478e:	0001e517          	auipc	a0,0x1e
    80004792:	3fa50513          	addi	a0,a0,1018 # 80022b88 <ftable>
    80004796:	ffffc097          	auipc	ra,0xffffc
    8000479a:	328080e7          	jalr	808(ra) # 80000abe <acquire>
  if(f->ref < 1)
    8000479e:	40dc                	lw	a5,4(s1)
    800047a0:	06f05563          	blez	a5,8000480a <fileclose+0x90>
    panic("fileclose");
  if(--f->ref > 0){
    800047a4:	37fd                	addiw	a5,a5,-1
    800047a6:	0007871b          	sext.w	a4,a5
    800047aa:	c0dc                	sw	a5,4(s1)
    800047ac:	06e04763          	bgtz	a4,8000481a <fileclose+0xa0>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800047b0:	0004a903          	lw	s2,0(s1)
    800047b4:	0094ca83          	lbu	s5,9(s1)
    800047b8:	0104ba03          	ld	s4,16(s1)
    800047bc:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800047c0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800047c4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800047c8:	0001e517          	auipc	a0,0x1e
    800047cc:	3c050513          	addi	a0,a0,960 # 80022b88 <ftable>
    800047d0:	ffffc097          	auipc	ra,0xffffc
    800047d4:	356080e7          	jalr	854(ra) # 80000b26 <release>

  if(ff.type == FD_PIPE){
    800047d8:	4785                	li	a5,1
    800047da:	06f90163          	beq	s2,a5,8000483c <fileclose+0xc2>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800047de:	3979                	addiw	s2,s2,-2
    800047e0:	4785                	li	a5,1
    800047e2:	0527e463          	bltu	a5,s2,8000482a <fileclose+0xb0>
    begin_op(ff.ip->dev);
    800047e6:	0009a503          	lw	a0,0(s3)
    800047ea:	00000097          	auipc	ra,0x0
    800047ee:	968080e7          	jalr	-1688(ra) # 80004152 <begin_op>
    iput(ff.ip);
    800047f2:	854e                	mv	a0,s3
    800047f4:	fffff097          	auipc	ra,0xfffff
    800047f8:	fc4080e7          	jalr	-60(ra) # 800037b8 <iput>
    end_op(ff.ip->dev);
    800047fc:	0009a503          	lw	a0,0(s3)
    80004800:	00000097          	auipc	ra,0x0
    80004804:	9fc080e7          	jalr	-1540(ra) # 800041fc <end_op>
    80004808:	a00d                	j	8000482a <fileclose+0xb0>
    panic("fileclose");
    8000480a:	00004517          	auipc	a0,0x4
    8000480e:	ede50513          	addi	a0,a0,-290 # 800086e8 <userret+0x658>
    80004812:	ffffc097          	auipc	ra,0xffffc
    80004816:	d36080e7          	jalr	-714(ra) # 80000548 <panic>
    release(&ftable.lock);
    8000481a:	0001e517          	auipc	a0,0x1e
    8000481e:	36e50513          	addi	a0,a0,878 # 80022b88 <ftable>
    80004822:	ffffc097          	auipc	ra,0xffffc
    80004826:	304080e7          	jalr	772(ra) # 80000b26 <release>
  }
}
    8000482a:	70e2                	ld	ra,56(sp)
    8000482c:	7442                	ld	s0,48(sp)
    8000482e:	74a2                	ld	s1,40(sp)
    80004830:	7902                	ld	s2,32(sp)
    80004832:	69e2                	ld	s3,24(sp)
    80004834:	6a42                	ld	s4,16(sp)
    80004836:	6aa2                	ld	s5,8(sp)
    80004838:	6121                	addi	sp,sp,64
    8000483a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000483c:	85d6                	mv	a1,s5
    8000483e:	8552                	mv	a0,s4
    80004840:	00000097          	auipc	ra,0x0
    80004844:	378080e7          	jalr	888(ra) # 80004bb8 <pipeclose>
    80004848:	b7cd                	j	8000482a <fileclose+0xb0>

000000008000484a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000484a:	715d                	addi	sp,sp,-80
    8000484c:	e486                	sd	ra,72(sp)
    8000484e:	e0a2                	sd	s0,64(sp)
    80004850:	fc26                	sd	s1,56(sp)
    80004852:	f84a                	sd	s2,48(sp)
    80004854:	f44e                	sd	s3,40(sp)
    80004856:	0880                	addi	s0,sp,80
    80004858:	84aa                	mv	s1,a0
    8000485a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000485c:	ffffd097          	auipc	ra,0xffffd
    80004860:	18c080e7          	jalr	396(ra) # 800019e8 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004864:	409c                	lw	a5,0(s1)
    80004866:	37f9                	addiw	a5,a5,-2
    80004868:	4705                	li	a4,1
    8000486a:	04f76763          	bltu	a4,a5,800048b8 <filestat+0x6e>
    8000486e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004870:	6c88                	ld	a0,24(s1)
    80004872:	fffff097          	auipc	ra,0xfffff
    80004876:	e38080e7          	jalr	-456(ra) # 800036aa <ilock>
    stati(f->ip, &st);
    8000487a:	fb840593          	addi	a1,s0,-72
    8000487e:	6c88                	ld	a0,24(s1)
    80004880:	fffff097          	auipc	ra,0xfffff
    80004884:	090080e7          	jalr	144(ra) # 80003910 <stati>
    iunlock(f->ip);
    80004888:	6c88                	ld	a0,24(s1)
    8000488a:	fffff097          	auipc	ra,0xfffff
    8000488e:	ee2080e7          	jalr	-286(ra) # 8000376c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004892:	46e1                	li	a3,24
    80004894:	fb840613          	addi	a2,s0,-72
    80004898:	85ce                	mv	a1,s3
    8000489a:	05093503          	ld	a0,80(s2)
    8000489e:	ffffd097          	auipc	ra,0xffffd
    800048a2:	d46080e7          	jalr	-698(ra) # 800015e4 <copyout>
    800048a6:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800048aa:	60a6                	ld	ra,72(sp)
    800048ac:	6406                	ld	s0,64(sp)
    800048ae:	74e2                	ld	s1,56(sp)
    800048b0:	7942                	ld	s2,48(sp)
    800048b2:	79a2                	ld	s3,40(sp)
    800048b4:	6161                	addi	sp,sp,80
    800048b6:	8082                	ret
  return -1;
    800048b8:	557d                	li	a0,-1
    800048ba:	bfc5                	j	800048aa <filestat+0x60>

00000000800048bc <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800048bc:	7179                	addi	sp,sp,-48
    800048be:	f406                	sd	ra,40(sp)
    800048c0:	f022                	sd	s0,32(sp)
    800048c2:	ec26                	sd	s1,24(sp)
    800048c4:	e84a                	sd	s2,16(sp)
    800048c6:	e44e                	sd	s3,8(sp)
    800048c8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800048ca:	00854783          	lbu	a5,8(a0)
    800048ce:	c7c5                	beqz	a5,80004976 <fileread+0xba>
    800048d0:	84aa                	mv	s1,a0
    800048d2:	89ae                	mv	s3,a1
    800048d4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800048d6:	411c                	lw	a5,0(a0)
    800048d8:	4705                	li	a4,1
    800048da:	04e78963          	beq	a5,a4,8000492c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048de:	470d                	li	a4,3
    800048e0:	04e78d63          	beq	a5,a4,8000493a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(f, 1, addr, n);
  } else if(f->type == FD_INODE){
    800048e4:	4709                	li	a4,2
    800048e6:	08e79063          	bne	a5,a4,80004966 <fileread+0xaa>
    ilock(f->ip);
    800048ea:	6d08                	ld	a0,24(a0)
    800048ec:	fffff097          	auipc	ra,0xfffff
    800048f0:	dbe080e7          	jalr	-578(ra) # 800036aa <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800048f4:	874a                	mv	a4,s2
    800048f6:	5094                	lw	a3,32(s1)
    800048f8:	864e                	mv	a2,s3
    800048fa:	4585                	li	a1,1
    800048fc:	6c88                	ld	a0,24(s1)
    800048fe:	fffff097          	auipc	ra,0xfffff
    80004902:	03c080e7          	jalr	60(ra) # 8000393a <readi>
    80004906:	892a                	mv	s2,a0
    80004908:	00a05563          	blez	a0,80004912 <fileread+0x56>
      f->off += r;
    8000490c:	509c                	lw	a5,32(s1)
    8000490e:	9fa9                	addw	a5,a5,a0
    80004910:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004912:	6c88                	ld	a0,24(s1)
    80004914:	fffff097          	auipc	ra,0xfffff
    80004918:	e58080e7          	jalr	-424(ra) # 8000376c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000491c:	854a                	mv	a0,s2
    8000491e:	70a2                	ld	ra,40(sp)
    80004920:	7402                	ld	s0,32(sp)
    80004922:	64e2                	ld	s1,24(sp)
    80004924:	6942                	ld	s2,16(sp)
    80004926:	69a2                	ld	s3,8(sp)
    80004928:	6145                	addi	sp,sp,48
    8000492a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000492c:	6908                	ld	a0,16(a0)
    8000492e:	00000097          	auipc	ra,0x0
    80004932:	408080e7          	jalr	1032(ra) # 80004d36 <piperead>
    80004936:	892a                	mv	s2,a0
    80004938:	b7d5                	j	8000491c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000493a:	02451783          	lh	a5,36(a0)
    8000493e:	03079693          	slli	a3,a5,0x30
    80004942:	92c1                	srli	a3,a3,0x30
    80004944:	4725                	li	a4,9
    80004946:	02d76a63          	bltu	a4,a3,8000497a <fileread+0xbe>
    8000494a:	0792                	slli	a5,a5,0x4
    8000494c:	0001e717          	auipc	a4,0x1e
    80004950:	19c70713          	addi	a4,a4,412 # 80022ae8 <devsw>
    80004954:	97ba                	add	a5,a5,a4
    80004956:	639c                	ld	a5,0(a5)
    80004958:	c39d                	beqz	a5,8000497e <fileread+0xc2>
    r = devsw[f->major].read(f, 1, addr, n);
    8000495a:	86b2                	mv	a3,a2
    8000495c:	862e                	mv	a2,a1
    8000495e:	4585                	li	a1,1
    80004960:	9782                	jalr	a5
    80004962:	892a                	mv	s2,a0
    80004964:	bf65                	j	8000491c <fileread+0x60>
    panic("fileread");
    80004966:	00004517          	auipc	a0,0x4
    8000496a:	d9250513          	addi	a0,a0,-622 # 800086f8 <userret+0x668>
    8000496e:	ffffc097          	auipc	ra,0xffffc
    80004972:	bda080e7          	jalr	-1062(ra) # 80000548 <panic>
    return -1;
    80004976:	597d                	li	s2,-1
    80004978:	b755                	j	8000491c <fileread+0x60>
      return -1;
    8000497a:	597d                	li	s2,-1
    8000497c:	b745                	j	8000491c <fileread+0x60>
    8000497e:	597d                	li	s2,-1
    80004980:	bf71                	j	8000491c <fileread+0x60>

0000000080004982 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004982:	00954783          	lbu	a5,9(a0)
    80004986:	14078663          	beqz	a5,80004ad2 <filewrite+0x150>
{
    8000498a:	715d                	addi	sp,sp,-80
    8000498c:	e486                	sd	ra,72(sp)
    8000498e:	e0a2                	sd	s0,64(sp)
    80004990:	fc26                	sd	s1,56(sp)
    80004992:	f84a                	sd	s2,48(sp)
    80004994:	f44e                	sd	s3,40(sp)
    80004996:	f052                	sd	s4,32(sp)
    80004998:	ec56                	sd	s5,24(sp)
    8000499a:	e85a                	sd	s6,16(sp)
    8000499c:	e45e                	sd	s7,8(sp)
    8000499e:	e062                	sd	s8,0(sp)
    800049a0:	0880                	addi	s0,sp,80
    800049a2:	84aa                	mv	s1,a0
    800049a4:	8aae                	mv	s5,a1
    800049a6:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800049a8:	411c                	lw	a5,0(a0)
    800049aa:	4705                	li	a4,1
    800049ac:	02e78263          	beq	a5,a4,800049d0 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049b0:	470d                	li	a4,3
    800049b2:	02e78563          	beq	a5,a4,800049dc <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(f, 1, addr, n);
  } else if(f->type == FD_INODE){
    800049b6:	4709                	li	a4,2
    800049b8:	10e79563          	bne	a5,a4,80004ac2 <filewrite+0x140>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800049bc:	0ec05f63          	blez	a2,80004aba <filewrite+0x138>
    int i = 0;
    800049c0:	4981                	li	s3,0
    800049c2:	6b05                	lui	s6,0x1
    800049c4:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800049c8:	6b85                	lui	s7,0x1
    800049ca:	c00b8b9b          	addiw	s7,s7,-1024
    800049ce:	a851                	j	80004a62 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800049d0:	6908                	ld	a0,16(a0)
    800049d2:	00000097          	auipc	ra,0x0
    800049d6:	256080e7          	jalr	598(ra) # 80004c28 <pipewrite>
    800049da:	a865                	j	80004a92 <filewrite+0x110>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800049dc:	02451783          	lh	a5,36(a0)
    800049e0:	03079693          	slli	a3,a5,0x30
    800049e4:	92c1                	srli	a3,a3,0x30
    800049e6:	4725                	li	a4,9
    800049e8:	0ed76763          	bltu	a4,a3,80004ad6 <filewrite+0x154>
    800049ec:	0792                	slli	a5,a5,0x4
    800049ee:	0001e717          	auipc	a4,0x1e
    800049f2:	0fa70713          	addi	a4,a4,250 # 80022ae8 <devsw>
    800049f6:	97ba                	add	a5,a5,a4
    800049f8:	679c                	ld	a5,8(a5)
    800049fa:	c3e5                	beqz	a5,80004ada <filewrite+0x158>
    ret = devsw[f->major].write(f, 1, addr, n);
    800049fc:	86b2                	mv	a3,a2
    800049fe:	862e                	mv	a2,a1
    80004a00:	4585                	li	a1,1
    80004a02:	9782                	jalr	a5
    80004a04:	a079                	j	80004a92 <filewrite+0x110>
    80004a06:	00090c1b          	sext.w	s8,s2
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op(f->ip->dev);
    80004a0a:	6c9c                	ld	a5,24(s1)
    80004a0c:	4388                	lw	a0,0(a5)
    80004a0e:	fffff097          	auipc	ra,0xfffff
    80004a12:	744080e7          	jalr	1860(ra) # 80004152 <begin_op>
      ilock(f->ip);
    80004a16:	6c88                	ld	a0,24(s1)
    80004a18:	fffff097          	auipc	ra,0xfffff
    80004a1c:	c92080e7          	jalr	-878(ra) # 800036aa <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a20:	8762                	mv	a4,s8
    80004a22:	5094                	lw	a3,32(s1)
    80004a24:	01598633          	add	a2,s3,s5
    80004a28:	4585                	li	a1,1
    80004a2a:	6c88                	ld	a0,24(s1)
    80004a2c:	fffff097          	auipc	ra,0xfffff
    80004a30:	002080e7          	jalr	2(ra) # 80003a2e <writei>
    80004a34:	892a                	mv	s2,a0
    80004a36:	02a05e63          	blez	a0,80004a72 <filewrite+0xf0>
        f->off += r;
    80004a3a:	509c                	lw	a5,32(s1)
    80004a3c:	9fa9                	addw	a5,a5,a0
    80004a3e:	d09c                	sw	a5,32(s1)
      iunlock(f->ip);
    80004a40:	6c88                	ld	a0,24(s1)
    80004a42:	fffff097          	auipc	ra,0xfffff
    80004a46:	d2a080e7          	jalr	-726(ra) # 8000376c <iunlock>
      end_op(f->ip->dev);
    80004a4a:	6c9c                	ld	a5,24(s1)
    80004a4c:	4388                	lw	a0,0(a5)
    80004a4e:	fffff097          	auipc	ra,0xfffff
    80004a52:	7ae080e7          	jalr	1966(ra) # 800041fc <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004a56:	052c1a63          	bne	s8,s2,80004aaa <filewrite+0x128>
        panic("short filewrite");
      i += r;
    80004a5a:	013909bb          	addw	s3,s2,s3
    while(i < n){
    80004a5e:	0349d763          	bge	s3,s4,80004a8c <filewrite+0x10a>
      int n1 = n - i;
    80004a62:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a66:	893e                	mv	s2,a5
    80004a68:	2781                	sext.w	a5,a5
    80004a6a:	f8fb5ee3          	bge	s6,a5,80004a06 <filewrite+0x84>
    80004a6e:	895e                	mv	s2,s7
    80004a70:	bf59                	j	80004a06 <filewrite+0x84>
      iunlock(f->ip);
    80004a72:	6c88                	ld	a0,24(s1)
    80004a74:	fffff097          	auipc	ra,0xfffff
    80004a78:	cf8080e7          	jalr	-776(ra) # 8000376c <iunlock>
      end_op(f->ip->dev);
    80004a7c:	6c9c                	ld	a5,24(s1)
    80004a7e:	4388                	lw	a0,0(a5)
    80004a80:	fffff097          	auipc	ra,0xfffff
    80004a84:	77c080e7          	jalr	1916(ra) # 800041fc <end_op>
      if(r < 0)
    80004a88:	fc0957e3          	bgez	s2,80004a56 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004a8c:	8552                	mv	a0,s4
    80004a8e:	033a1863          	bne	s4,s3,80004abe <filewrite+0x13c>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a92:	60a6                	ld	ra,72(sp)
    80004a94:	6406                	ld	s0,64(sp)
    80004a96:	74e2                	ld	s1,56(sp)
    80004a98:	7942                	ld	s2,48(sp)
    80004a9a:	79a2                	ld	s3,40(sp)
    80004a9c:	7a02                	ld	s4,32(sp)
    80004a9e:	6ae2                	ld	s5,24(sp)
    80004aa0:	6b42                	ld	s6,16(sp)
    80004aa2:	6ba2                	ld	s7,8(sp)
    80004aa4:	6c02                	ld	s8,0(sp)
    80004aa6:	6161                	addi	sp,sp,80
    80004aa8:	8082                	ret
        panic("short filewrite");
    80004aaa:	00004517          	auipc	a0,0x4
    80004aae:	c5e50513          	addi	a0,a0,-930 # 80008708 <userret+0x678>
    80004ab2:	ffffc097          	auipc	ra,0xffffc
    80004ab6:	a96080e7          	jalr	-1386(ra) # 80000548 <panic>
    int i = 0;
    80004aba:	4981                	li	s3,0
    80004abc:	bfc1                	j	80004a8c <filewrite+0x10a>
    ret = (i == n ? n : -1);
    80004abe:	557d                	li	a0,-1
    80004ac0:	bfc9                	j	80004a92 <filewrite+0x110>
    panic("filewrite");
    80004ac2:	00004517          	auipc	a0,0x4
    80004ac6:	c5650513          	addi	a0,a0,-938 # 80008718 <userret+0x688>
    80004aca:	ffffc097          	auipc	ra,0xffffc
    80004ace:	a7e080e7          	jalr	-1410(ra) # 80000548 <panic>
    return -1;
    80004ad2:	557d                	li	a0,-1
}
    80004ad4:	8082                	ret
      return -1;
    80004ad6:	557d                	li	a0,-1
    80004ad8:	bf6d                	j	80004a92 <filewrite+0x110>
    80004ada:	557d                	li	a0,-1
    80004adc:	bf5d                	j	80004a92 <filewrite+0x110>

0000000080004ade <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004ade:	7179                	addi	sp,sp,-48
    80004ae0:	f406                	sd	ra,40(sp)
    80004ae2:	f022                	sd	s0,32(sp)
    80004ae4:	ec26                	sd	s1,24(sp)
    80004ae6:	e84a                	sd	s2,16(sp)
    80004ae8:	e44e                	sd	s3,8(sp)
    80004aea:	e052                	sd	s4,0(sp)
    80004aec:	1800                	addi	s0,sp,48
    80004aee:	84aa                	mv	s1,a0
    80004af0:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004af2:	0005b023          	sd	zero,0(a1)
    80004af6:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004afa:	00000097          	auipc	ra,0x0
    80004afe:	bc4080e7          	jalr	-1084(ra) # 800046be <filealloc>
    80004b02:	e088                	sd	a0,0(s1)
    80004b04:	c551                	beqz	a0,80004b90 <pipealloc+0xb2>
    80004b06:	00000097          	auipc	ra,0x0
    80004b0a:	bb8080e7          	jalr	-1096(ra) # 800046be <filealloc>
    80004b0e:	00aa3023          	sd	a0,0(s4)
    80004b12:	c92d                	beqz	a0,80004b84 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b14:	ffffc097          	auipc	ra,0xffffc
    80004b18:	e3c080e7          	jalr	-452(ra) # 80000950 <kalloc>
    80004b1c:	892a                	mv	s2,a0
    80004b1e:	c125                	beqz	a0,80004b7e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b20:	4985                	li	s3,1
    80004b22:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b26:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b2a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b2e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b32:	00004597          	auipc	a1,0x4
    80004b36:	bf658593          	addi	a1,a1,-1034 # 80008728 <userret+0x698>
    80004b3a:	ffffc097          	auipc	ra,0xffffc
    80004b3e:	e76080e7          	jalr	-394(ra) # 800009b0 <initlock>
  (*f0)->type = FD_PIPE;
    80004b42:	609c                	ld	a5,0(s1)
    80004b44:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b48:	609c                	ld	a5,0(s1)
    80004b4a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b4e:	609c                	ld	a5,0(s1)
    80004b50:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b54:	609c                	ld	a5,0(s1)
    80004b56:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b5a:	000a3783          	ld	a5,0(s4)
    80004b5e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b62:	000a3783          	ld	a5,0(s4)
    80004b66:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b6a:	000a3783          	ld	a5,0(s4)
    80004b6e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b72:	000a3783          	ld	a5,0(s4)
    80004b76:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b7a:	4501                	li	a0,0
    80004b7c:	a025                	j	80004ba4 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b7e:	6088                	ld	a0,0(s1)
    80004b80:	e501                	bnez	a0,80004b88 <pipealloc+0xaa>
    80004b82:	a039                	j	80004b90 <pipealloc+0xb2>
    80004b84:	6088                	ld	a0,0(s1)
    80004b86:	c51d                	beqz	a0,80004bb4 <pipealloc+0xd6>
    fileclose(*f0);
    80004b88:	00000097          	auipc	ra,0x0
    80004b8c:	bf2080e7          	jalr	-1038(ra) # 8000477a <fileclose>
  if(*f1)
    80004b90:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b94:	557d                	li	a0,-1
  if(*f1)
    80004b96:	c799                	beqz	a5,80004ba4 <pipealloc+0xc6>
    fileclose(*f1);
    80004b98:	853e                	mv	a0,a5
    80004b9a:	00000097          	auipc	ra,0x0
    80004b9e:	be0080e7          	jalr	-1056(ra) # 8000477a <fileclose>
  return -1;
    80004ba2:	557d                	li	a0,-1
}
    80004ba4:	70a2                	ld	ra,40(sp)
    80004ba6:	7402                	ld	s0,32(sp)
    80004ba8:	64e2                	ld	s1,24(sp)
    80004baa:	6942                	ld	s2,16(sp)
    80004bac:	69a2                	ld	s3,8(sp)
    80004bae:	6a02                	ld	s4,0(sp)
    80004bb0:	6145                	addi	sp,sp,48
    80004bb2:	8082                	ret
  return -1;
    80004bb4:	557d                	li	a0,-1
    80004bb6:	b7fd                	j	80004ba4 <pipealloc+0xc6>

0000000080004bb8 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004bb8:	1101                	addi	sp,sp,-32
    80004bba:	ec06                	sd	ra,24(sp)
    80004bbc:	e822                	sd	s0,16(sp)
    80004bbe:	e426                	sd	s1,8(sp)
    80004bc0:	e04a                	sd	s2,0(sp)
    80004bc2:	1000                	addi	s0,sp,32
    80004bc4:	84aa                	mv	s1,a0
    80004bc6:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004bc8:	ffffc097          	auipc	ra,0xffffc
    80004bcc:	ef6080e7          	jalr	-266(ra) # 80000abe <acquire>
  if(writable){
    80004bd0:	02090d63          	beqz	s2,80004c0a <pipeclose+0x52>
    pi->writeopen = 0;
    80004bd4:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004bd8:	21848513          	addi	a0,s1,536
    80004bdc:	ffffd097          	auipc	ra,0xffffd
    80004be0:	762080e7          	jalr	1890(ra) # 8000233e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004be4:	2204b783          	ld	a5,544(s1)
    80004be8:	eb95                	bnez	a5,80004c1c <pipeclose+0x64>
    release(&pi->lock);
    80004bea:	8526                	mv	a0,s1
    80004bec:	ffffc097          	auipc	ra,0xffffc
    80004bf0:	f3a080e7          	jalr	-198(ra) # 80000b26 <release>
    kfree((char*)pi);
    80004bf4:	8526                	mv	a0,s1
    80004bf6:	ffffc097          	auipc	ra,0xffffc
    80004bfa:	c5e080e7          	jalr	-930(ra) # 80000854 <kfree>
  } else
    release(&pi->lock);
}
    80004bfe:	60e2                	ld	ra,24(sp)
    80004c00:	6442                	ld	s0,16(sp)
    80004c02:	64a2                	ld	s1,8(sp)
    80004c04:	6902                	ld	s2,0(sp)
    80004c06:	6105                	addi	sp,sp,32
    80004c08:	8082                	ret
    pi->readopen = 0;
    80004c0a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c0e:	21c48513          	addi	a0,s1,540
    80004c12:	ffffd097          	auipc	ra,0xffffd
    80004c16:	72c080e7          	jalr	1836(ra) # 8000233e <wakeup>
    80004c1a:	b7e9                	j	80004be4 <pipeclose+0x2c>
    release(&pi->lock);
    80004c1c:	8526                	mv	a0,s1
    80004c1e:	ffffc097          	auipc	ra,0xffffc
    80004c22:	f08080e7          	jalr	-248(ra) # 80000b26 <release>
}
    80004c26:	bfe1                	j	80004bfe <pipeclose+0x46>

0000000080004c28 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c28:	711d                	addi	sp,sp,-96
    80004c2a:	ec86                	sd	ra,88(sp)
    80004c2c:	e8a2                	sd	s0,80(sp)
    80004c2e:	e4a6                	sd	s1,72(sp)
    80004c30:	e0ca                	sd	s2,64(sp)
    80004c32:	fc4e                	sd	s3,56(sp)
    80004c34:	f852                	sd	s4,48(sp)
    80004c36:	f456                	sd	s5,40(sp)
    80004c38:	f05a                	sd	s6,32(sp)
    80004c3a:	ec5e                	sd	s7,24(sp)
    80004c3c:	e862                	sd	s8,16(sp)
    80004c3e:	1080                	addi	s0,sp,96
    80004c40:	84aa                	mv	s1,a0
    80004c42:	8aae                	mv	s5,a1
    80004c44:	8a32                	mv	s4,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004c46:	ffffd097          	auipc	ra,0xffffd
    80004c4a:	da2080e7          	jalr	-606(ra) # 800019e8 <myproc>
    80004c4e:	8baa                	mv	s7,a0

  acquire(&pi->lock);
    80004c50:	8526                	mv	a0,s1
    80004c52:	ffffc097          	auipc	ra,0xffffc
    80004c56:	e6c080e7          	jalr	-404(ra) # 80000abe <acquire>
  for(i = 0; i < n; i++){
    80004c5a:	09405f63          	blez	s4,80004cf8 <pipewrite+0xd0>
    80004c5e:	fffa0b1b          	addiw	s6,s4,-1
    80004c62:	1b02                	slli	s6,s6,0x20
    80004c64:	020b5b13          	srli	s6,s6,0x20
    80004c68:	001a8793          	addi	a5,s5,1
    80004c6c:	9b3e                	add	s6,s6,a5
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || myproc()->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004c6e:	21848993          	addi	s3,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c72:	21c48913          	addi	s2,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c76:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004c78:	2184a783          	lw	a5,536(s1)
    80004c7c:	21c4a703          	lw	a4,540(s1)
    80004c80:	2007879b          	addiw	a5,a5,512
    80004c84:	02f71e63          	bne	a4,a5,80004cc0 <pipewrite+0x98>
      if(pi->readopen == 0 || myproc()->killed){
    80004c88:	2204a783          	lw	a5,544(s1)
    80004c8c:	c3d9                	beqz	a5,80004d12 <pipewrite+0xea>
    80004c8e:	ffffd097          	auipc	ra,0xffffd
    80004c92:	d5a080e7          	jalr	-678(ra) # 800019e8 <myproc>
    80004c96:	591c                	lw	a5,48(a0)
    80004c98:	efad                	bnez	a5,80004d12 <pipewrite+0xea>
      wakeup(&pi->nread);
    80004c9a:	854e                	mv	a0,s3
    80004c9c:	ffffd097          	auipc	ra,0xffffd
    80004ca0:	6a2080e7          	jalr	1698(ra) # 8000233e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ca4:	85a6                	mv	a1,s1
    80004ca6:	854a                	mv	a0,s2
    80004ca8:	ffffd097          	auipc	ra,0xffffd
    80004cac:	516080e7          	jalr	1302(ra) # 800021be <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004cb0:	2184a783          	lw	a5,536(s1)
    80004cb4:	21c4a703          	lw	a4,540(s1)
    80004cb8:	2007879b          	addiw	a5,a5,512
    80004cbc:	fcf706e3          	beq	a4,a5,80004c88 <pipewrite+0x60>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cc0:	4685                	li	a3,1
    80004cc2:	8656                	mv	a2,s5
    80004cc4:	faf40593          	addi	a1,s0,-81
    80004cc8:	050bb503          	ld	a0,80(s7) # 1050 <_entry-0x7fffefb0>
    80004ccc:	ffffd097          	auipc	ra,0xffffd
    80004cd0:	9ba080e7          	jalr	-1606(ra) # 80001686 <copyin>
    80004cd4:	03850263          	beq	a0,s8,80004cf8 <pipewrite+0xd0>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004cd8:	21c4a783          	lw	a5,540(s1)
    80004cdc:	0017871b          	addiw	a4,a5,1
    80004ce0:	20e4ae23          	sw	a4,540(s1)
    80004ce4:	1ff7f793          	andi	a5,a5,511
    80004ce8:	97a6                	add	a5,a5,s1
    80004cea:	faf44703          	lbu	a4,-81(s0)
    80004cee:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004cf2:	0a85                	addi	s5,s5,1
    80004cf4:	f96a92e3          	bne	s5,s6,80004c78 <pipewrite+0x50>
  }
  wakeup(&pi->nread);
    80004cf8:	21848513          	addi	a0,s1,536
    80004cfc:	ffffd097          	auipc	ra,0xffffd
    80004d00:	642080e7          	jalr	1602(ra) # 8000233e <wakeup>
  release(&pi->lock);
    80004d04:	8526                	mv	a0,s1
    80004d06:	ffffc097          	auipc	ra,0xffffc
    80004d0a:	e20080e7          	jalr	-480(ra) # 80000b26 <release>
  return n;
    80004d0e:	8552                	mv	a0,s4
    80004d10:	a039                	j	80004d1e <pipewrite+0xf6>
        release(&pi->lock);
    80004d12:	8526                	mv	a0,s1
    80004d14:	ffffc097          	auipc	ra,0xffffc
    80004d18:	e12080e7          	jalr	-494(ra) # 80000b26 <release>
        return -1;
    80004d1c:	557d                	li	a0,-1
}
    80004d1e:	60e6                	ld	ra,88(sp)
    80004d20:	6446                	ld	s0,80(sp)
    80004d22:	64a6                	ld	s1,72(sp)
    80004d24:	6906                	ld	s2,64(sp)
    80004d26:	79e2                	ld	s3,56(sp)
    80004d28:	7a42                	ld	s4,48(sp)
    80004d2a:	7aa2                	ld	s5,40(sp)
    80004d2c:	7b02                	ld	s6,32(sp)
    80004d2e:	6be2                	ld	s7,24(sp)
    80004d30:	6c42                	ld	s8,16(sp)
    80004d32:	6125                	addi	sp,sp,96
    80004d34:	8082                	ret

0000000080004d36 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d36:	715d                	addi	sp,sp,-80
    80004d38:	e486                	sd	ra,72(sp)
    80004d3a:	e0a2                	sd	s0,64(sp)
    80004d3c:	fc26                	sd	s1,56(sp)
    80004d3e:	f84a                	sd	s2,48(sp)
    80004d40:	f44e                	sd	s3,40(sp)
    80004d42:	f052                	sd	s4,32(sp)
    80004d44:	ec56                	sd	s5,24(sp)
    80004d46:	e85a                	sd	s6,16(sp)
    80004d48:	0880                	addi	s0,sp,80
    80004d4a:	84aa                	mv	s1,a0
    80004d4c:	892e                	mv	s2,a1
    80004d4e:	8a32                	mv	s4,a2
  int i;
  struct proc *pr = myproc();
    80004d50:	ffffd097          	auipc	ra,0xffffd
    80004d54:	c98080e7          	jalr	-872(ra) # 800019e8 <myproc>
    80004d58:	8aaa                	mv	s5,a0
  char ch;

  acquire(&pi->lock);
    80004d5a:	8526                	mv	a0,s1
    80004d5c:	ffffc097          	auipc	ra,0xffffc
    80004d60:	d62080e7          	jalr	-670(ra) # 80000abe <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d64:	2184a703          	lw	a4,536(s1)
    80004d68:	21c4a783          	lw	a5,540(s1)
    if(myproc()->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d6c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d70:	02f71763          	bne	a4,a5,80004d9e <piperead+0x68>
    80004d74:	2244a783          	lw	a5,548(s1)
    80004d78:	c39d                	beqz	a5,80004d9e <piperead+0x68>
    if(myproc()->killed){
    80004d7a:	ffffd097          	auipc	ra,0xffffd
    80004d7e:	c6e080e7          	jalr	-914(ra) # 800019e8 <myproc>
    80004d82:	591c                	lw	a5,48(a0)
    80004d84:	ebc1                	bnez	a5,80004e14 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d86:	85a6                	mv	a1,s1
    80004d88:	854e                	mv	a0,s3
    80004d8a:	ffffd097          	auipc	ra,0xffffd
    80004d8e:	434080e7          	jalr	1076(ra) # 800021be <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d92:	2184a703          	lw	a4,536(s1)
    80004d96:	21c4a783          	lw	a5,540(s1)
    80004d9a:	fcf70de3          	beq	a4,a5,80004d74 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d9e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004da0:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004da2:	05405363          	blez	s4,80004de8 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004da6:	2184a783          	lw	a5,536(s1)
    80004daa:	21c4a703          	lw	a4,540(s1)
    80004dae:	02f70d63          	beq	a4,a5,80004de8 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004db2:	0017871b          	addiw	a4,a5,1
    80004db6:	20e4ac23          	sw	a4,536(s1)
    80004dba:	1ff7f793          	andi	a5,a5,511
    80004dbe:	97a6                	add	a5,a5,s1
    80004dc0:	0187c783          	lbu	a5,24(a5)
    80004dc4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004dc8:	4685                	li	a3,1
    80004dca:	fbf40613          	addi	a2,s0,-65
    80004dce:	85ca                	mv	a1,s2
    80004dd0:	050ab503          	ld	a0,80(s5)
    80004dd4:	ffffd097          	auipc	ra,0xffffd
    80004dd8:	810080e7          	jalr	-2032(ra) # 800015e4 <copyout>
    80004ddc:	01650663          	beq	a0,s6,80004de8 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004de0:	2985                	addiw	s3,s3,1
    80004de2:	0905                	addi	s2,s2,1
    80004de4:	fd3a11e3          	bne	s4,s3,80004da6 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004de8:	21c48513          	addi	a0,s1,540
    80004dec:	ffffd097          	auipc	ra,0xffffd
    80004df0:	552080e7          	jalr	1362(ra) # 8000233e <wakeup>
  release(&pi->lock);
    80004df4:	8526                	mv	a0,s1
    80004df6:	ffffc097          	auipc	ra,0xffffc
    80004dfa:	d30080e7          	jalr	-720(ra) # 80000b26 <release>
  return i;
}
    80004dfe:	854e                	mv	a0,s3
    80004e00:	60a6                	ld	ra,72(sp)
    80004e02:	6406                	ld	s0,64(sp)
    80004e04:	74e2                	ld	s1,56(sp)
    80004e06:	7942                	ld	s2,48(sp)
    80004e08:	79a2                	ld	s3,40(sp)
    80004e0a:	7a02                	ld	s4,32(sp)
    80004e0c:	6ae2                	ld	s5,24(sp)
    80004e0e:	6b42                	ld	s6,16(sp)
    80004e10:	6161                	addi	sp,sp,80
    80004e12:	8082                	ret
      release(&pi->lock);
    80004e14:	8526                	mv	a0,s1
    80004e16:	ffffc097          	auipc	ra,0xffffc
    80004e1a:	d10080e7          	jalr	-752(ra) # 80000b26 <release>
      return -1;
    80004e1e:	59fd                	li	s3,-1
    80004e20:	bff9                	j	80004dfe <piperead+0xc8>

0000000080004e22 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004e22:	de010113          	addi	sp,sp,-544
    80004e26:	20113c23          	sd	ra,536(sp)
    80004e2a:	20813823          	sd	s0,528(sp)
    80004e2e:	20913423          	sd	s1,520(sp)
    80004e32:	21213023          	sd	s2,512(sp)
    80004e36:	ffce                	sd	s3,504(sp)
    80004e38:	fbd2                	sd	s4,496(sp)
    80004e3a:	f7d6                	sd	s5,488(sp)
    80004e3c:	f3da                	sd	s6,480(sp)
    80004e3e:	efde                	sd	s7,472(sp)
    80004e40:	ebe2                	sd	s8,464(sp)
    80004e42:	e7e6                	sd	s9,456(sp)
    80004e44:	e3ea                	sd	s10,448(sp)
    80004e46:	ff6e                	sd	s11,440(sp)
    80004e48:	1400                	addi	s0,sp,544
    80004e4a:	892a                	mv	s2,a0
    80004e4c:	dea43423          	sd	a0,-536(s0)
    80004e50:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e54:	ffffd097          	auipc	ra,0xffffd
    80004e58:	b94080e7          	jalr	-1132(ra) # 800019e8 <myproc>
    80004e5c:	84aa                	mv	s1,a0

  begin_op(ROOTDEV);
    80004e5e:	4501                	li	a0,0
    80004e60:	fffff097          	auipc	ra,0xfffff
    80004e64:	2f2080e7          	jalr	754(ra) # 80004152 <begin_op>

  if((ip = namei(path)) == 0){
    80004e68:	854a                	mv	a0,s2
    80004e6a:	fffff097          	auipc	ra,0xfffff
    80004e6e:	fca080e7          	jalr	-54(ra) # 80003e34 <namei>
    80004e72:	cd25                	beqz	a0,80004eea <exec+0xc8>
    80004e74:	8aaa                	mv	s5,a0
    end_op(ROOTDEV);
    return -1;
  }
  ilock(ip);
    80004e76:	fffff097          	auipc	ra,0xfffff
    80004e7a:	834080e7          	jalr	-1996(ra) # 800036aa <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e7e:	04000713          	li	a4,64
    80004e82:	4681                	li	a3,0
    80004e84:	e4840613          	addi	a2,s0,-440
    80004e88:	4581                	li	a1,0
    80004e8a:	8556                	mv	a0,s5
    80004e8c:	fffff097          	auipc	ra,0xfffff
    80004e90:	aae080e7          	jalr	-1362(ra) # 8000393a <readi>
    80004e94:	04000793          	li	a5,64
    80004e98:	00f51a63          	bne	a0,a5,80004eac <exec+0x8a>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e9c:	e4842703          	lw	a4,-440(s0)
    80004ea0:	464c47b7          	lui	a5,0x464c4
    80004ea4:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004ea8:	04f70863          	beq	a4,a5,80004ef8 <exec+0xd6>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004eac:	8556                	mv	a0,s5
    80004eae:	fffff097          	auipc	ra,0xfffff
    80004eb2:	a3a080e7          	jalr	-1478(ra) # 800038e8 <iunlockput>
    end_op(ROOTDEV);
    80004eb6:	4501                	li	a0,0
    80004eb8:	fffff097          	auipc	ra,0xfffff
    80004ebc:	344080e7          	jalr	836(ra) # 800041fc <end_op>
  }
  return -1;
    80004ec0:	557d                	li	a0,-1
}
    80004ec2:	21813083          	ld	ra,536(sp)
    80004ec6:	21013403          	ld	s0,528(sp)
    80004eca:	20813483          	ld	s1,520(sp)
    80004ece:	20013903          	ld	s2,512(sp)
    80004ed2:	79fe                	ld	s3,504(sp)
    80004ed4:	7a5e                	ld	s4,496(sp)
    80004ed6:	7abe                	ld	s5,488(sp)
    80004ed8:	7b1e                	ld	s6,480(sp)
    80004eda:	6bfe                	ld	s7,472(sp)
    80004edc:	6c5e                	ld	s8,464(sp)
    80004ede:	6cbe                	ld	s9,456(sp)
    80004ee0:	6d1e                	ld	s10,448(sp)
    80004ee2:	7dfa                	ld	s11,440(sp)
    80004ee4:	22010113          	addi	sp,sp,544
    80004ee8:	8082                	ret
    end_op(ROOTDEV);
    80004eea:	4501                	li	a0,0
    80004eec:	fffff097          	auipc	ra,0xfffff
    80004ef0:	310080e7          	jalr	784(ra) # 800041fc <end_op>
    return -1;
    80004ef4:	557d                	li	a0,-1
    80004ef6:	b7f1                	j	80004ec2 <exec+0xa0>
  if((pagetable = proc_pagetable(p)) == 0)
    80004ef8:	8526                	mv	a0,s1
    80004efa:	ffffd097          	auipc	ra,0xffffd
    80004efe:	bb2080e7          	jalr	-1102(ra) # 80001aac <proc_pagetable>
    80004f02:	8b2a                	mv	s6,a0
    80004f04:	d545                	beqz	a0,80004eac <exec+0x8a>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f06:	e6842783          	lw	a5,-408(s0)
    80004f0a:	e8045703          	lhu	a4,-384(s0)
    80004f0e:	10070263          	beqz	a4,80005012 <exec+0x1f0>
  sz = 0;
    80004f12:	de043c23          	sd	zero,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f16:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004f1a:	6a05                	lui	s4,0x1
    80004f1c:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004f20:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004f24:	6d85                	lui	s11,0x1
    80004f26:	7d7d                	lui	s10,0xfffff
    80004f28:	a88d                	j	80004f9a <exec+0x178>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f2a:	00004517          	auipc	a0,0x4
    80004f2e:	80650513          	addi	a0,a0,-2042 # 80008730 <userret+0x6a0>
    80004f32:	ffffb097          	auipc	ra,0xffffb
    80004f36:	616080e7          	jalr	1558(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f3a:	874a                	mv	a4,s2
    80004f3c:	009c86bb          	addw	a3,s9,s1
    80004f40:	4581                	li	a1,0
    80004f42:	8556                	mv	a0,s5
    80004f44:	fffff097          	auipc	ra,0xfffff
    80004f48:	9f6080e7          	jalr	-1546(ra) # 8000393a <readi>
    80004f4c:	2501                	sext.w	a0,a0
    80004f4e:	10a91863          	bne	s2,a0,8000505e <exec+0x23c>
  for(i = 0; i < sz; i += PGSIZE){
    80004f52:	009d84bb          	addw	s1,s11,s1
    80004f56:	013d09bb          	addw	s3,s10,s3
    80004f5a:	0374f263          	bgeu	s1,s7,80004f7e <exec+0x15c>
    pa = walkaddr(pagetable, va + i);
    80004f5e:	02049593          	slli	a1,s1,0x20
    80004f62:	9181                	srli	a1,a1,0x20
    80004f64:	95e2                	add	a1,a1,s8
    80004f66:	855a                	mv	a0,s6
    80004f68:	ffffc097          	auipc	ra,0xffffc
    80004f6c:	014080e7          	jalr	20(ra) # 80000f7c <walkaddr>
    80004f70:	862a                	mv	a2,a0
    if(pa == 0)
    80004f72:	dd45                	beqz	a0,80004f2a <exec+0x108>
      n = PGSIZE;
    80004f74:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004f76:	fd49f2e3          	bgeu	s3,s4,80004f3a <exec+0x118>
      n = sz - i;
    80004f7a:	894e                	mv	s2,s3
    80004f7c:	bf7d                	j	80004f3a <exec+0x118>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f7e:	e0843783          	ld	a5,-504(s0)
    80004f82:	0017869b          	addiw	a3,a5,1
    80004f86:	e0d43423          	sd	a3,-504(s0)
    80004f8a:	e0043783          	ld	a5,-512(s0)
    80004f8e:	0387879b          	addiw	a5,a5,56
    80004f92:	e8045703          	lhu	a4,-384(s0)
    80004f96:	08e6d063          	bge	a3,a4,80005016 <exec+0x1f4>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f9a:	2781                	sext.w	a5,a5
    80004f9c:	e0f43023          	sd	a5,-512(s0)
    80004fa0:	03800713          	li	a4,56
    80004fa4:	86be                	mv	a3,a5
    80004fa6:	e1040613          	addi	a2,s0,-496
    80004faa:	4581                	li	a1,0
    80004fac:	8556                	mv	a0,s5
    80004fae:	fffff097          	auipc	ra,0xfffff
    80004fb2:	98c080e7          	jalr	-1652(ra) # 8000393a <readi>
    80004fb6:	03800793          	li	a5,56
    80004fba:	0af51263          	bne	a0,a5,8000505e <exec+0x23c>
    if(ph.type != ELF_PROG_LOAD)
    80004fbe:	e1042783          	lw	a5,-496(s0)
    80004fc2:	4705                	li	a4,1
    80004fc4:	fae79de3          	bne	a5,a4,80004f7e <exec+0x15c>
    if(ph.memsz < ph.filesz)
    80004fc8:	e3843603          	ld	a2,-456(s0)
    80004fcc:	e3043783          	ld	a5,-464(s0)
    80004fd0:	08f66763          	bltu	a2,a5,8000505e <exec+0x23c>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004fd4:	e2043783          	ld	a5,-480(s0)
    80004fd8:	963e                	add	a2,a2,a5
    80004fda:	08f66263          	bltu	a2,a5,8000505e <exec+0x23c>
    if((sz = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fde:	df843583          	ld	a1,-520(s0)
    80004fe2:	855a                	mv	a0,s6
    80004fe4:	ffffc097          	auipc	ra,0xffffc
    80004fe8:	36e080e7          	jalr	878(ra) # 80001352 <uvmalloc>
    80004fec:	dea43c23          	sd	a0,-520(s0)
    80004ff0:	c53d                	beqz	a0,8000505e <exec+0x23c>
    if(ph.vaddr % PGSIZE != 0)
    80004ff2:	e2043c03          	ld	s8,-480(s0)
    80004ff6:	de043783          	ld	a5,-544(s0)
    80004ffa:	00fc77b3          	and	a5,s8,a5
    80004ffe:	e3a5                	bnez	a5,8000505e <exec+0x23c>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005000:	e1842c83          	lw	s9,-488(s0)
    80005004:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005008:	f60b8be3          	beqz	s7,80004f7e <exec+0x15c>
    8000500c:	89de                	mv	s3,s7
    8000500e:	4481                	li	s1,0
    80005010:	b7b9                	j	80004f5e <exec+0x13c>
  sz = 0;
    80005012:	de043c23          	sd	zero,-520(s0)
  iunlockput(ip);
    80005016:	8556                	mv	a0,s5
    80005018:	fffff097          	auipc	ra,0xfffff
    8000501c:	8d0080e7          	jalr	-1840(ra) # 800038e8 <iunlockput>
  end_op(ROOTDEV);
    80005020:	4501                	li	a0,0
    80005022:	fffff097          	auipc	ra,0xfffff
    80005026:	1da080e7          	jalr	474(ra) # 800041fc <end_op>
  p = myproc();
    8000502a:	ffffd097          	auipc	ra,0xffffd
    8000502e:	9be080e7          	jalr	-1602(ra) # 800019e8 <myproc>
    80005032:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005034:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005038:	6585                	lui	a1,0x1
    8000503a:	15fd                	addi	a1,a1,-1
    8000503c:	df843783          	ld	a5,-520(s0)
    80005040:	95be                	add	a1,a1,a5
    80005042:	77fd                	lui	a5,0xfffff
    80005044:	8dfd                	and	a1,a1,a5
  if((sz = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005046:	6609                	lui	a2,0x2
    80005048:	962e                	add	a2,a2,a1
    8000504a:	855a                	mv	a0,s6
    8000504c:	ffffc097          	auipc	ra,0xffffc
    80005050:	306080e7          	jalr	774(ra) # 80001352 <uvmalloc>
    80005054:	892a                	mv	s2,a0
    80005056:	dea43c23          	sd	a0,-520(s0)
  ip = 0;
    8000505a:	4a81                	li	s5,0
  if((sz = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000505c:	ed01                	bnez	a0,80005074 <exec+0x252>
    proc_freepagetable(pagetable, sz);
    8000505e:	df843583          	ld	a1,-520(s0)
    80005062:	855a                	mv	a0,s6
    80005064:	ffffd097          	auipc	ra,0xffffd
    80005068:	b48080e7          	jalr	-1208(ra) # 80001bac <proc_freepagetable>
  if(ip){
    8000506c:	e40a90e3          	bnez	s5,80004eac <exec+0x8a>
  return -1;
    80005070:	557d                	li	a0,-1
    80005072:	bd81                	j	80004ec2 <exec+0xa0>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005074:	75f9                	lui	a1,0xffffe
    80005076:	95aa                	add	a1,a1,a0
    80005078:	855a                	mv	a0,s6
    8000507a:	ffffc097          	auipc	ra,0xffffc
    8000507e:	464080e7          	jalr	1124(ra) # 800014de <uvmclear>
  stackbase = sp - PGSIZE;
    80005082:	7c7d                	lui	s8,0xfffff
    80005084:	9c4a                	add	s8,s8,s2
  for(argc = 0; argv[argc]; argc++) {
    80005086:	df043783          	ld	a5,-528(s0)
    8000508a:	6388                	ld	a0,0(a5)
    8000508c:	c52d                	beqz	a0,800050f6 <exec+0x2d4>
    8000508e:	e8840993          	addi	s3,s0,-376
    80005092:	f8840a93          	addi	s5,s0,-120
    80005096:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005098:	ffffc097          	auipc	ra,0xffffc
    8000509c:	c6e080e7          	jalr	-914(ra) # 80000d06 <strlen>
    800050a0:	0015079b          	addiw	a5,a0,1
    800050a4:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800050a8:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800050ac:	0f896b63          	bltu	s2,s8,800051a2 <exec+0x380>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800050b0:	df043d03          	ld	s10,-528(s0)
    800050b4:	000d3a03          	ld	s4,0(s10) # fffffffffffff000 <end+0xffffffff7ffd4fa4>
    800050b8:	8552                	mv	a0,s4
    800050ba:	ffffc097          	auipc	ra,0xffffc
    800050be:	c4c080e7          	jalr	-948(ra) # 80000d06 <strlen>
    800050c2:	0015069b          	addiw	a3,a0,1
    800050c6:	8652                	mv	a2,s4
    800050c8:	85ca                	mv	a1,s2
    800050ca:	855a                	mv	a0,s6
    800050cc:	ffffc097          	auipc	ra,0xffffc
    800050d0:	518080e7          	jalr	1304(ra) # 800015e4 <copyout>
    800050d4:	0c054963          	bltz	a0,800051a6 <exec+0x384>
    ustack[argc] = sp;
    800050d8:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800050dc:	0485                	addi	s1,s1,1
    800050de:	008d0793          	addi	a5,s10,8
    800050e2:	def43823          	sd	a5,-528(s0)
    800050e6:	008d3503          	ld	a0,8(s10)
    800050ea:	c909                	beqz	a0,800050fc <exec+0x2da>
    if(argc >= MAXARG)
    800050ec:	09a1                	addi	s3,s3,8
    800050ee:	fb3a95e3          	bne	s5,s3,80005098 <exec+0x276>
  ip = 0;
    800050f2:	4a81                	li	s5,0
    800050f4:	b7ad                	j	8000505e <exec+0x23c>
  sp = sz;
    800050f6:	df843903          	ld	s2,-520(s0)
  for(argc = 0; argv[argc]; argc++) {
    800050fa:	4481                	li	s1,0
  ustack[argc] = 0;
    800050fc:	00349793          	slli	a5,s1,0x3
    80005100:	f9040713          	addi	a4,s0,-112
    80005104:	97ba                	add	a5,a5,a4
    80005106:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd4e9c>
  sp -= (argc+1) * sizeof(uint64);
    8000510a:	00148693          	addi	a3,s1,1
    8000510e:	068e                	slli	a3,a3,0x3
    80005110:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005114:	ff097913          	andi	s2,s2,-16
  ip = 0;
    80005118:	4a81                	li	s5,0
  if(sp < stackbase)
    8000511a:	f58962e3          	bltu	s2,s8,8000505e <exec+0x23c>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000511e:	e8840613          	addi	a2,s0,-376
    80005122:	85ca                	mv	a1,s2
    80005124:	855a                	mv	a0,s6
    80005126:	ffffc097          	auipc	ra,0xffffc
    8000512a:	4be080e7          	jalr	1214(ra) # 800015e4 <copyout>
    8000512e:	06054e63          	bltz	a0,800051aa <exec+0x388>
  p->tf->a1 = sp;
    80005132:	058bb783          	ld	a5,88(s7)
    80005136:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000513a:	de843783          	ld	a5,-536(s0)
    8000513e:	0007c703          	lbu	a4,0(a5)
    80005142:	cf11                	beqz	a4,8000515e <exec+0x33c>
    80005144:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005146:	02f00693          	li	a3,47
    8000514a:	a039                	j	80005158 <exec+0x336>
      last = s+1;
    8000514c:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005150:	0785                	addi	a5,a5,1
    80005152:	fff7c703          	lbu	a4,-1(a5)
    80005156:	c701                	beqz	a4,8000515e <exec+0x33c>
    if(*s == '/')
    80005158:	fed71ce3          	bne	a4,a3,80005150 <exec+0x32e>
    8000515c:	bfc5                	j	8000514c <exec+0x32a>
  safestrcpy(p->name, last, sizeof(p->name));
    8000515e:	4641                	li	a2,16
    80005160:	de843583          	ld	a1,-536(s0)
    80005164:	158b8513          	addi	a0,s7,344
    80005168:	ffffc097          	auipc	ra,0xffffc
    8000516c:	b6c080e7          	jalr	-1172(ra) # 80000cd4 <safestrcpy>
  oldpagetable = p->pagetable;
    80005170:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005174:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005178:	df843783          	ld	a5,-520(s0)
    8000517c:	04fbb423          	sd	a5,72(s7)
  p->tf->epc = elf.entry;  // initial program counter = main
    80005180:	058bb783          	ld	a5,88(s7)
    80005184:	e6043703          	ld	a4,-416(s0)
    80005188:	ef98                	sd	a4,24(a5)
  p->tf->sp = sp; // initial stack pointer
    8000518a:	058bb783          	ld	a5,88(s7)
    8000518e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005192:	85e6                	mv	a1,s9
    80005194:	ffffd097          	auipc	ra,0xffffd
    80005198:	a18080e7          	jalr	-1512(ra) # 80001bac <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000519c:	0004851b          	sext.w	a0,s1
    800051a0:	b30d                	j	80004ec2 <exec+0xa0>
  ip = 0;
    800051a2:	4a81                	li	s5,0
    800051a4:	bd6d                	j	8000505e <exec+0x23c>
    800051a6:	4a81                	li	s5,0
    800051a8:	bd5d                	j	8000505e <exec+0x23c>
    800051aa:	4a81                	li	s5,0
    800051ac:	bd4d                	j	8000505e <exec+0x23c>

00000000800051ae <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800051ae:	7179                	addi	sp,sp,-48
    800051b0:	f406                	sd	ra,40(sp)
    800051b2:	f022                	sd	s0,32(sp)
    800051b4:	ec26                	sd	s1,24(sp)
    800051b6:	e84a                	sd	s2,16(sp)
    800051b8:	1800                	addi	s0,sp,48
    800051ba:	892e                	mv	s2,a1
    800051bc:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800051be:	fdc40593          	addi	a1,s0,-36
    800051c2:	ffffe097          	auipc	ra,0xffffe
    800051c6:	922080e7          	jalr	-1758(ra) # 80002ae4 <argint>
    800051ca:	04054063          	bltz	a0,8000520a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800051ce:	fdc42703          	lw	a4,-36(s0)
    800051d2:	47bd                	li	a5,15
    800051d4:	02e7ed63          	bltu	a5,a4,8000520e <argfd+0x60>
    800051d8:	ffffd097          	auipc	ra,0xffffd
    800051dc:	810080e7          	jalr	-2032(ra) # 800019e8 <myproc>
    800051e0:	fdc42703          	lw	a4,-36(s0)
    800051e4:	01a70793          	addi	a5,a4,26
    800051e8:	078e                	slli	a5,a5,0x3
    800051ea:	953e                	add	a0,a0,a5
    800051ec:	611c                	ld	a5,0(a0)
    800051ee:	c395                	beqz	a5,80005212 <argfd+0x64>
    return -1;
  if(pfd)
    800051f0:	00090463          	beqz	s2,800051f8 <argfd+0x4a>
    *pfd = fd;
    800051f4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051f8:	4501                	li	a0,0
  if(pf)
    800051fa:	c091                	beqz	s1,800051fe <argfd+0x50>
    *pf = f;
    800051fc:	e09c                	sd	a5,0(s1)
}
    800051fe:	70a2                	ld	ra,40(sp)
    80005200:	7402                	ld	s0,32(sp)
    80005202:	64e2                	ld	s1,24(sp)
    80005204:	6942                	ld	s2,16(sp)
    80005206:	6145                	addi	sp,sp,48
    80005208:	8082                	ret
    return -1;
    8000520a:	557d                	li	a0,-1
    8000520c:	bfcd                	j	800051fe <argfd+0x50>
    return -1;
    8000520e:	557d                	li	a0,-1
    80005210:	b7fd                	j	800051fe <argfd+0x50>
    80005212:	557d                	li	a0,-1
    80005214:	b7ed                	j	800051fe <argfd+0x50>

0000000080005216 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005216:	1101                	addi	sp,sp,-32
    80005218:	ec06                	sd	ra,24(sp)
    8000521a:	e822                	sd	s0,16(sp)
    8000521c:	e426                	sd	s1,8(sp)
    8000521e:	1000                	addi	s0,sp,32
    80005220:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005222:	ffffc097          	auipc	ra,0xffffc
    80005226:	7c6080e7          	jalr	1990(ra) # 800019e8 <myproc>
    8000522a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000522c:	0d050793          	addi	a5,a0,208
    80005230:	4501                	li	a0,0
    80005232:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005234:	6398                	ld	a4,0(a5)
    80005236:	cb19                	beqz	a4,8000524c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005238:	2505                	addiw	a0,a0,1
    8000523a:	07a1                	addi	a5,a5,8
    8000523c:	fed51ce3          	bne	a0,a3,80005234 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005240:	557d                	li	a0,-1
}
    80005242:	60e2                	ld	ra,24(sp)
    80005244:	6442                	ld	s0,16(sp)
    80005246:	64a2                	ld	s1,8(sp)
    80005248:	6105                	addi	sp,sp,32
    8000524a:	8082                	ret
      p->ofile[fd] = f;
    8000524c:	01a50793          	addi	a5,a0,26
    80005250:	078e                	slli	a5,a5,0x3
    80005252:	963e                	add	a2,a2,a5
    80005254:	e204                	sd	s1,0(a2)
      return fd;
    80005256:	b7f5                	j	80005242 <fdalloc+0x2c>

0000000080005258 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005258:	715d                	addi	sp,sp,-80
    8000525a:	e486                	sd	ra,72(sp)
    8000525c:	e0a2                	sd	s0,64(sp)
    8000525e:	fc26                	sd	s1,56(sp)
    80005260:	f84a                	sd	s2,48(sp)
    80005262:	f44e                	sd	s3,40(sp)
    80005264:	f052                	sd	s4,32(sp)
    80005266:	ec56                	sd	s5,24(sp)
    80005268:	0880                	addi	s0,sp,80
    8000526a:	89ae                	mv	s3,a1
    8000526c:	8ab2                	mv	s5,a2
    8000526e:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005270:	fb040593          	addi	a1,s0,-80
    80005274:	fffff097          	auipc	ra,0xfffff
    80005278:	bde080e7          	jalr	-1058(ra) # 80003e52 <nameiparent>
    8000527c:	892a                	mv	s2,a0
    8000527e:	12050e63          	beqz	a0,800053ba <create+0x162>
    return 0;

  ilock(dp);
    80005282:	ffffe097          	auipc	ra,0xffffe
    80005286:	428080e7          	jalr	1064(ra) # 800036aa <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000528a:	4601                	li	a2,0
    8000528c:	fb040593          	addi	a1,s0,-80
    80005290:	854a                	mv	a0,s2
    80005292:	fffff097          	auipc	ra,0xfffff
    80005296:	8d0080e7          	jalr	-1840(ra) # 80003b62 <dirlookup>
    8000529a:	84aa                	mv	s1,a0
    8000529c:	c921                	beqz	a0,800052ec <create+0x94>
    iunlockput(dp);
    8000529e:	854a                	mv	a0,s2
    800052a0:	ffffe097          	auipc	ra,0xffffe
    800052a4:	648080e7          	jalr	1608(ra) # 800038e8 <iunlockput>
    ilock(ip);
    800052a8:	8526                	mv	a0,s1
    800052aa:	ffffe097          	auipc	ra,0xffffe
    800052ae:	400080e7          	jalr	1024(ra) # 800036aa <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800052b2:	2981                	sext.w	s3,s3
    800052b4:	4789                	li	a5,2
    800052b6:	02f99463          	bne	s3,a5,800052de <create+0x86>
    800052ba:	0444d783          	lhu	a5,68(s1)
    800052be:	37f9                	addiw	a5,a5,-2
    800052c0:	17c2                	slli	a5,a5,0x30
    800052c2:	93c1                	srli	a5,a5,0x30
    800052c4:	4705                	li	a4,1
    800052c6:	00f76c63          	bltu	a4,a5,800052de <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800052ca:	8526                	mv	a0,s1
    800052cc:	60a6                	ld	ra,72(sp)
    800052ce:	6406                	ld	s0,64(sp)
    800052d0:	74e2                	ld	s1,56(sp)
    800052d2:	7942                	ld	s2,48(sp)
    800052d4:	79a2                	ld	s3,40(sp)
    800052d6:	7a02                	ld	s4,32(sp)
    800052d8:	6ae2                	ld	s5,24(sp)
    800052da:	6161                	addi	sp,sp,80
    800052dc:	8082                	ret
    iunlockput(ip);
    800052de:	8526                	mv	a0,s1
    800052e0:	ffffe097          	auipc	ra,0xffffe
    800052e4:	608080e7          	jalr	1544(ra) # 800038e8 <iunlockput>
    return 0;
    800052e8:	4481                	li	s1,0
    800052ea:	b7c5                	j	800052ca <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800052ec:	85ce                	mv	a1,s3
    800052ee:	00092503          	lw	a0,0(s2)
    800052f2:	ffffe097          	auipc	ra,0xffffe
    800052f6:	220080e7          	jalr	544(ra) # 80003512 <ialloc>
    800052fa:	84aa                	mv	s1,a0
    800052fc:	c521                	beqz	a0,80005344 <create+0xec>
  ilock(ip);
    800052fe:	ffffe097          	auipc	ra,0xffffe
    80005302:	3ac080e7          	jalr	940(ra) # 800036aa <ilock>
  ip->major = major;
    80005306:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000530a:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000530e:	4a05                	li	s4,1
    80005310:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005314:	8526                	mv	a0,s1
    80005316:	ffffe097          	auipc	ra,0xffffe
    8000531a:	2ca080e7          	jalr	714(ra) # 800035e0 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000531e:	2981                	sext.w	s3,s3
    80005320:	03498a63          	beq	s3,s4,80005354 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005324:	40d0                	lw	a2,4(s1)
    80005326:	fb040593          	addi	a1,s0,-80
    8000532a:	854a                	mv	a0,s2
    8000532c:	fffff097          	auipc	ra,0xfffff
    80005330:	a46080e7          	jalr	-1466(ra) # 80003d72 <dirlink>
    80005334:	06054b63          	bltz	a0,800053aa <create+0x152>
  iunlockput(dp);
    80005338:	854a                	mv	a0,s2
    8000533a:	ffffe097          	auipc	ra,0xffffe
    8000533e:	5ae080e7          	jalr	1454(ra) # 800038e8 <iunlockput>
  return ip;
    80005342:	b761                	j	800052ca <create+0x72>
    panic("create: ialloc");
    80005344:	00003517          	auipc	a0,0x3
    80005348:	40c50513          	addi	a0,a0,1036 # 80008750 <userret+0x6c0>
    8000534c:	ffffb097          	auipc	ra,0xffffb
    80005350:	1fc080e7          	jalr	508(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    80005354:	04a95783          	lhu	a5,74(s2)
    80005358:	2785                	addiw	a5,a5,1
    8000535a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000535e:	854a                	mv	a0,s2
    80005360:	ffffe097          	auipc	ra,0xffffe
    80005364:	280080e7          	jalr	640(ra) # 800035e0 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005368:	40d0                	lw	a2,4(s1)
    8000536a:	00003597          	auipc	a1,0x3
    8000536e:	3f658593          	addi	a1,a1,1014 # 80008760 <userret+0x6d0>
    80005372:	8526                	mv	a0,s1
    80005374:	fffff097          	auipc	ra,0xfffff
    80005378:	9fe080e7          	jalr	-1538(ra) # 80003d72 <dirlink>
    8000537c:	00054f63          	bltz	a0,8000539a <create+0x142>
    80005380:	00492603          	lw	a2,4(s2)
    80005384:	00003597          	auipc	a1,0x3
    80005388:	3e458593          	addi	a1,a1,996 # 80008768 <userret+0x6d8>
    8000538c:	8526                	mv	a0,s1
    8000538e:	fffff097          	auipc	ra,0xfffff
    80005392:	9e4080e7          	jalr	-1564(ra) # 80003d72 <dirlink>
    80005396:	f80557e3          	bgez	a0,80005324 <create+0xcc>
      panic("create dots");
    8000539a:	00003517          	auipc	a0,0x3
    8000539e:	3d650513          	addi	a0,a0,982 # 80008770 <userret+0x6e0>
    800053a2:	ffffb097          	auipc	ra,0xffffb
    800053a6:	1a6080e7          	jalr	422(ra) # 80000548 <panic>
    panic("create: dirlink");
    800053aa:	00003517          	auipc	a0,0x3
    800053ae:	3d650513          	addi	a0,a0,982 # 80008780 <userret+0x6f0>
    800053b2:	ffffb097          	auipc	ra,0xffffb
    800053b6:	196080e7          	jalr	406(ra) # 80000548 <panic>
    return 0;
    800053ba:	84aa                	mv	s1,a0
    800053bc:	b739                	j	800052ca <create+0x72>

00000000800053be <sys_dup>:
{
    800053be:	7179                	addi	sp,sp,-48
    800053c0:	f406                	sd	ra,40(sp)
    800053c2:	f022                	sd	s0,32(sp)
    800053c4:	ec26                	sd	s1,24(sp)
    800053c6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800053c8:	fd840613          	addi	a2,s0,-40
    800053cc:	4581                	li	a1,0
    800053ce:	4501                	li	a0,0
    800053d0:	00000097          	auipc	ra,0x0
    800053d4:	dde080e7          	jalr	-546(ra) # 800051ae <argfd>
    return -1;
    800053d8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800053da:	02054363          	bltz	a0,80005400 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800053de:	fd843503          	ld	a0,-40(s0)
    800053e2:	00000097          	auipc	ra,0x0
    800053e6:	e34080e7          	jalr	-460(ra) # 80005216 <fdalloc>
    800053ea:	84aa                	mv	s1,a0
    return -1;
    800053ec:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800053ee:	00054963          	bltz	a0,80005400 <sys_dup+0x42>
  filedup(f);
    800053f2:	fd843503          	ld	a0,-40(s0)
    800053f6:	fffff097          	auipc	ra,0xfffff
    800053fa:	332080e7          	jalr	818(ra) # 80004728 <filedup>
  return fd;
    800053fe:	87a6                	mv	a5,s1
}
    80005400:	853e                	mv	a0,a5
    80005402:	70a2                	ld	ra,40(sp)
    80005404:	7402                	ld	s0,32(sp)
    80005406:	64e2                	ld	s1,24(sp)
    80005408:	6145                	addi	sp,sp,48
    8000540a:	8082                	ret

000000008000540c <sys_read>:
{
    8000540c:	7179                	addi	sp,sp,-48
    8000540e:	f406                	sd	ra,40(sp)
    80005410:	f022                	sd	s0,32(sp)
    80005412:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005414:	fe840613          	addi	a2,s0,-24
    80005418:	4581                	li	a1,0
    8000541a:	4501                	li	a0,0
    8000541c:	00000097          	auipc	ra,0x0
    80005420:	d92080e7          	jalr	-622(ra) # 800051ae <argfd>
    return -1;
    80005424:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005426:	04054163          	bltz	a0,80005468 <sys_read+0x5c>
    8000542a:	fe440593          	addi	a1,s0,-28
    8000542e:	4509                	li	a0,2
    80005430:	ffffd097          	auipc	ra,0xffffd
    80005434:	6b4080e7          	jalr	1716(ra) # 80002ae4 <argint>
    return -1;
    80005438:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000543a:	02054763          	bltz	a0,80005468 <sys_read+0x5c>
    8000543e:	fd840593          	addi	a1,s0,-40
    80005442:	4505                	li	a0,1
    80005444:	ffffd097          	auipc	ra,0xffffd
    80005448:	6c2080e7          	jalr	1730(ra) # 80002b06 <argaddr>
    return -1;
    8000544c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000544e:	00054d63          	bltz	a0,80005468 <sys_read+0x5c>
  return fileread(f, p, n);
    80005452:	fe442603          	lw	a2,-28(s0)
    80005456:	fd843583          	ld	a1,-40(s0)
    8000545a:	fe843503          	ld	a0,-24(s0)
    8000545e:	fffff097          	auipc	ra,0xfffff
    80005462:	45e080e7          	jalr	1118(ra) # 800048bc <fileread>
    80005466:	87aa                	mv	a5,a0
}
    80005468:	853e                	mv	a0,a5
    8000546a:	70a2                	ld	ra,40(sp)
    8000546c:	7402                	ld	s0,32(sp)
    8000546e:	6145                	addi	sp,sp,48
    80005470:	8082                	ret

0000000080005472 <sys_write>:
{
    80005472:	7179                	addi	sp,sp,-48
    80005474:	f406                	sd	ra,40(sp)
    80005476:	f022                	sd	s0,32(sp)
    80005478:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000547a:	fe840613          	addi	a2,s0,-24
    8000547e:	4581                	li	a1,0
    80005480:	4501                	li	a0,0
    80005482:	00000097          	auipc	ra,0x0
    80005486:	d2c080e7          	jalr	-724(ra) # 800051ae <argfd>
    return -1;
    8000548a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000548c:	04054163          	bltz	a0,800054ce <sys_write+0x5c>
    80005490:	fe440593          	addi	a1,s0,-28
    80005494:	4509                	li	a0,2
    80005496:	ffffd097          	auipc	ra,0xffffd
    8000549a:	64e080e7          	jalr	1614(ra) # 80002ae4 <argint>
    return -1;
    8000549e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054a0:	02054763          	bltz	a0,800054ce <sys_write+0x5c>
    800054a4:	fd840593          	addi	a1,s0,-40
    800054a8:	4505                	li	a0,1
    800054aa:	ffffd097          	auipc	ra,0xffffd
    800054ae:	65c080e7          	jalr	1628(ra) # 80002b06 <argaddr>
    return -1;
    800054b2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054b4:	00054d63          	bltz	a0,800054ce <sys_write+0x5c>
  return filewrite(f, p, n);
    800054b8:	fe442603          	lw	a2,-28(s0)
    800054bc:	fd843583          	ld	a1,-40(s0)
    800054c0:	fe843503          	ld	a0,-24(s0)
    800054c4:	fffff097          	auipc	ra,0xfffff
    800054c8:	4be080e7          	jalr	1214(ra) # 80004982 <filewrite>
    800054cc:	87aa                	mv	a5,a0
}
    800054ce:	853e                	mv	a0,a5
    800054d0:	70a2                	ld	ra,40(sp)
    800054d2:	7402                	ld	s0,32(sp)
    800054d4:	6145                	addi	sp,sp,48
    800054d6:	8082                	ret

00000000800054d8 <sys_close>:
{
    800054d8:	1101                	addi	sp,sp,-32
    800054da:	ec06                	sd	ra,24(sp)
    800054dc:	e822                	sd	s0,16(sp)
    800054de:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800054e0:	fe040613          	addi	a2,s0,-32
    800054e4:	fec40593          	addi	a1,s0,-20
    800054e8:	4501                	li	a0,0
    800054ea:	00000097          	auipc	ra,0x0
    800054ee:	cc4080e7          	jalr	-828(ra) # 800051ae <argfd>
    return -1;
    800054f2:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800054f4:	02054463          	bltz	a0,8000551c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800054f8:	ffffc097          	auipc	ra,0xffffc
    800054fc:	4f0080e7          	jalr	1264(ra) # 800019e8 <myproc>
    80005500:	fec42783          	lw	a5,-20(s0)
    80005504:	07e9                	addi	a5,a5,26
    80005506:	078e                	slli	a5,a5,0x3
    80005508:	97aa                	add	a5,a5,a0
    8000550a:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000550e:	fe043503          	ld	a0,-32(s0)
    80005512:	fffff097          	auipc	ra,0xfffff
    80005516:	268080e7          	jalr	616(ra) # 8000477a <fileclose>
  return 0;
    8000551a:	4781                	li	a5,0
}
    8000551c:	853e                	mv	a0,a5
    8000551e:	60e2                	ld	ra,24(sp)
    80005520:	6442                	ld	s0,16(sp)
    80005522:	6105                	addi	sp,sp,32
    80005524:	8082                	ret

0000000080005526 <sys_fstat>:
{
    80005526:	1101                	addi	sp,sp,-32
    80005528:	ec06                	sd	ra,24(sp)
    8000552a:	e822                	sd	s0,16(sp)
    8000552c:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000552e:	fe840613          	addi	a2,s0,-24
    80005532:	4581                	li	a1,0
    80005534:	4501                	li	a0,0
    80005536:	00000097          	auipc	ra,0x0
    8000553a:	c78080e7          	jalr	-904(ra) # 800051ae <argfd>
    return -1;
    8000553e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005540:	02054563          	bltz	a0,8000556a <sys_fstat+0x44>
    80005544:	fe040593          	addi	a1,s0,-32
    80005548:	4505                	li	a0,1
    8000554a:	ffffd097          	auipc	ra,0xffffd
    8000554e:	5bc080e7          	jalr	1468(ra) # 80002b06 <argaddr>
    return -1;
    80005552:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005554:	00054b63          	bltz	a0,8000556a <sys_fstat+0x44>
  return filestat(f, st);
    80005558:	fe043583          	ld	a1,-32(s0)
    8000555c:	fe843503          	ld	a0,-24(s0)
    80005560:	fffff097          	auipc	ra,0xfffff
    80005564:	2ea080e7          	jalr	746(ra) # 8000484a <filestat>
    80005568:	87aa                	mv	a5,a0
}
    8000556a:	853e                	mv	a0,a5
    8000556c:	60e2                	ld	ra,24(sp)
    8000556e:	6442                	ld	s0,16(sp)
    80005570:	6105                	addi	sp,sp,32
    80005572:	8082                	ret

0000000080005574 <sys_link>:
{
    80005574:	7169                	addi	sp,sp,-304
    80005576:	f606                	sd	ra,296(sp)
    80005578:	f222                	sd	s0,288(sp)
    8000557a:	ee26                	sd	s1,280(sp)
    8000557c:	ea4a                	sd	s2,272(sp)
    8000557e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005580:	08000613          	li	a2,128
    80005584:	ed040593          	addi	a1,s0,-304
    80005588:	4501                	li	a0,0
    8000558a:	ffffd097          	auipc	ra,0xffffd
    8000558e:	59e080e7          	jalr	1438(ra) # 80002b28 <argstr>
    return -1;
    80005592:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005594:	12054363          	bltz	a0,800056ba <sys_link+0x146>
    80005598:	08000613          	li	a2,128
    8000559c:	f5040593          	addi	a1,s0,-176
    800055a0:	4505                	li	a0,1
    800055a2:	ffffd097          	auipc	ra,0xffffd
    800055a6:	586080e7          	jalr	1414(ra) # 80002b28 <argstr>
    return -1;
    800055aa:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055ac:	10054763          	bltz	a0,800056ba <sys_link+0x146>
  begin_op(ROOTDEV);
    800055b0:	4501                	li	a0,0
    800055b2:	fffff097          	auipc	ra,0xfffff
    800055b6:	ba0080e7          	jalr	-1120(ra) # 80004152 <begin_op>
  if((ip = namei(old)) == 0){
    800055ba:	ed040513          	addi	a0,s0,-304
    800055be:	fffff097          	auipc	ra,0xfffff
    800055c2:	876080e7          	jalr	-1930(ra) # 80003e34 <namei>
    800055c6:	84aa                	mv	s1,a0
    800055c8:	c559                	beqz	a0,80005656 <sys_link+0xe2>
  ilock(ip);
    800055ca:	ffffe097          	auipc	ra,0xffffe
    800055ce:	0e0080e7          	jalr	224(ra) # 800036aa <ilock>
  if(ip->type == T_DIR){
    800055d2:	04449703          	lh	a4,68(s1)
    800055d6:	4785                	li	a5,1
    800055d8:	08f70663          	beq	a4,a5,80005664 <sys_link+0xf0>
  ip->nlink++;
    800055dc:	04a4d783          	lhu	a5,74(s1)
    800055e0:	2785                	addiw	a5,a5,1
    800055e2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055e6:	8526                	mv	a0,s1
    800055e8:	ffffe097          	auipc	ra,0xffffe
    800055ec:	ff8080e7          	jalr	-8(ra) # 800035e0 <iupdate>
  iunlock(ip);
    800055f0:	8526                	mv	a0,s1
    800055f2:	ffffe097          	auipc	ra,0xffffe
    800055f6:	17a080e7          	jalr	378(ra) # 8000376c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055fa:	fd040593          	addi	a1,s0,-48
    800055fe:	f5040513          	addi	a0,s0,-176
    80005602:	fffff097          	auipc	ra,0xfffff
    80005606:	850080e7          	jalr	-1968(ra) # 80003e52 <nameiparent>
    8000560a:	892a                	mv	s2,a0
    8000560c:	cd2d                	beqz	a0,80005686 <sys_link+0x112>
  ilock(dp);
    8000560e:	ffffe097          	auipc	ra,0xffffe
    80005612:	09c080e7          	jalr	156(ra) # 800036aa <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005616:	00092703          	lw	a4,0(s2)
    8000561a:	409c                	lw	a5,0(s1)
    8000561c:	06f71063          	bne	a4,a5,8000567c <sys_link+0x108>
    80005620:	40d0                	lw	a2,4(s1)
    80005622:	fd040593          	addi	a1,s0,-48
    80005626:	854a                	mv	a0,s2
    80005628:	ffffe097          	auipc	ra,0xffffe
    8000562c:	74a080e7          	jalr	1866(ra) # 80003d72 <dirlink>
    80005630:	04054663          	bltz	a0,8000567c <sys_link+0x108>
  iunlockput(dp);
    80005634:	854a                	mv	a0,s2
    80005636:	ffffe097          	auipc	ra,0xffffe
    8000563a:	2b2080e7          	jalr	690(ra) # 800038e8 <iunlockput>
  iput(ip);
    8000563e:	8526                	mv	a0,s1
    80005640:	ffffe097          	auipc	ra,0xffffe
    80005644:	178080e7          	jalr	376(ra) # 800037b8 <iput>
  end_op(ROOTDEV);
    80005648:	4501                	li	a0,0
    8000564a:	fffff097          	auipc	ra,0xfffff
    8000564e:	bb2080e7          	jalr	-1102(ra) # 800041fc <end_op>
  return 0;
    80005652:	4781                	li	a5,0
    80005654:	a09d                	j	800056ba <sys_link+0x146>
    end_op(ROOTDEV);
    80005656:	4501                	li	a0,0
    80005658:	fffff097          	auipc	ra,0xfffff
    8000565c:	ba4080e7          	jalr	-1116(ra) # 800041fc <end_op>
    return -1;
    80005660:	57fd                	li	a5,-1
    80005662:	a8a1                	j	800056ba <sys_link+0x146>
    iunlockput(ip);
    80005664:	8526                	mv	a0,s1
    80005666:	ffffe097          	auipc	ra,0xffffe
    8000566a:	282080e7          	jalr	642(ra) # 800038e8 <iunlockput>
    end_op(ROOTDEV);
    8000566e:	4501                	li	a0,0
    80005670:	fffff097          	auipc	ra,0xfffff
    80005674:	b8c080e7          	jalr	-1140(ra) # 800041fc <end_op>
    return -1;
    80005678:	57fd                	li	a5,-1
    8000567a:	a081                	j	800056ba <sys_link+0x146>
    iunlockput(dp);
    8000567c:	854a                	mv	a0,s2
    8000567e:	ffffe097          	auipc	ra,0xffffe
    80005682:	26a080e7          	jalr	618(ra) # 800038e8 <iunlockput>
  ilock(ip);
    80005686:	8526                	mv	a0,s1
    80005688:	ffffe097          	auipc	ra,0xffffe
    8000568c:	022080e7          	jalr	34(ra) # 800036aa <ilock>
  ip->nlink--;
    80005690:	04a4d783          	lhu	a5,74(s1)
    80005694:	37fd                	addiw	a5,a5,-1
    80005696:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000569a:	8526                	mv	a0,s1
    8000569c:	ffffe097          	auipc	ra,0xffffe
    800056a0:	f44080e7          	jalr	-188(ra) # 800035e0 <iupdate>
  iunlockput(ip);
    800056a4:	8526                	mv	a0,s1
    800056a6:	ffffe097          	auipc	ra,0xffffe
    800056aa:	242080e7          	jalr	578(ra) # 800038e8 <iunlockput>
  end_op(ROOTDEV);
    800056ae:	4501                	li	a0,0
    800056b0:	fffff097          	auipc	ra,0xfffff
    800056b4:	b4c080e7          	jalr	-1204(ra) # 800041fc <end_op>
  return -1;
    800056b8:	57fd                	li	a5,-1
}
    800056ba:	853e                	mv	a0,a5
    800056bc:	70b2                	ld	ra,296(sp)
    800056be:	7412                	ld	s0,288(sp)
    800056c0:	64f2                	ld	s1,280(sp)
    800056c2:	6952                	ld	s2,272(sp)
    800056c4:	6155                	addi	sp,sp,304
    800056c6:	8082                	ret

00000000800056c8 <sys_unlink>:
{
    800056c8:	7151                	addi	sp,sp,-240
    800056ca:	f586                	sd	ra,232(sp)
    800056cc:	f1a2                	sd	s0,224(sp)
    800056ce:	eda6                	sd	s1,216(sp)
    800056d0:	e9ca                	sd	s2,208(sp)
    800056d2:	e5ce                	sd	s3,200(sp)
    800056d4:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800056d6:	08000613          	li	a2,128
    800056da:	f3040593          	addi	a1,s0,-208
    800056de:	4501                	li	a0,0
    800056e0:	ffffd097          	auipc	ra,0xffffd
    800056e4:	448080e7          	jalr	1096(ra) # 80002b28 <argstr>
    800056e8:	18054463          	bltz	a0,80005870 <sys_unlink+0x1a8>
  begin_op(ROOTDEV);
    800056ec:	4501                	li	a0,0
    800056ee:	fffff097          	auipc	ra,0xfffff
    800056f2:	a64080e7          	jalr	-1436(ra) # 80004152 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800056f6:	fb040593          	addi	a1,s0,-80
    800056fa:	f3040513          	addi	a0,s0,-208
    800056fe:	ffffe097          	auipc	ra,0xffffe
    80005702:	754080e7          	jalr	1876(ra) # 80003e52 <nameiparent>
    80005706:	84aa                	mv	s1,a0
    80005708:	cd61                	beqz	a0,800057e0 <sys_unlink+0x118>
  ilock(dp);
    8000570a:	ffffe097          	auipc	ra,0xffffe
    8000570e:	fa0080e7          	jalr	-96(ra) # 800036aa <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005712:	00003597          	auipc	a1,0x3
    80005716:	04e58593          	addi	a1,a1,78 # 80008760 <userret+0x6d0>
    8000571a:	fb040513          	addi	a0,s0,-80
    8000571e:	ffffe097          	auipc	ra,0xffffe
    80005722:	42a080e7          	jalr	1066(ra) # 80003b48 <namecmp>
    80005726:	14050c63          	beqz	a0,8000587e <sys_unlink+0x1b6>
    8000572a:	00003597          	auipc	a1,0x3
    8000572e:	03e58593          	addi	a1,a1,62 # 80008768 <userret+0x6d8>
    80005732:	fb040513          	addi	a0,s0,-80
    80005736:	ffffe097          	auipc	ra,0xffffe
    8000573a:	412080e7          	jalr	1042(ra) # 80003b48 <namecmp>
    8000573e:	14050063          	beqz	a0,8000587e <sys_unlink+0x1b6>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005742:	f2c40613          	addi	a2,s0,-212
    80005746:	fb040593          	addi	a1,s0,-80
    8000574a:	8526                	mv	a0,s1
    8000574c:	ffffe097          	auipc	ra,0xffffe
    80005750:	416080e7          	jalr	1046(ra) # 80003b62 <dirlookup>
    80005754:	892a                	mv	s2,a0
    80005756:	12050463          	beqz	a0,8000587e <sys_unlink+0x1b6>
  ilock(ip);
    8000575a:	ffffe097          	auipc	ra,0xffffe
    8000575e:	f50080e7          	jalr	-176(ra) # 800036aa <ilock>
  if(ip->nlink < 1)
    80005762:	04a91783          	lh	a5,74(s2)
    80005766:	08f05463          	blez	a5,800057ee <sys_unlink+0x126>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000576a:	04491703          	lh	a4,68(s2)
    8000576e:	4785                	li	a5,1
    80005770:	08f70763          	beq	a4,a5,800057fe <sys_unlink+0x136>
  memset(&de, 0, sizeof(de));
    80005774:	4641                	li	a2,16
    80005776:	4581                	li	a1,0
    80005778:	fc040513          	addi	a0,s0,-64
    8000577c:	ffffb097          	auipc	ra,0xffffb
    80005780:	406080e7          	jalr	1030(ra) # 80000b82 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005784:	4741                	li	a4,16
    80005786:	f2c42683          	lw	a3,-212(s0)
    8000578a:	fc040613          	addi	a2,s0,-64
    8000578e:	4581                	li	a1,0
    80005790:	8526                	mv	a0,s1
    80005792:	ffffe097          	auipc	ra,0xffffe
    80005796:	29c080e7          	jalr	668(ra) # 80003a2e <writei>
    8000579a:	47c1                	li	a5,16
    8000579c:	0af51763          	bne	a0,a5,8000584a <sys_unlink+0x182>
  if(ip->type == T_DIR){
    800057a0:	04491703          	lh	a4,68(s2)
    800057a4:	4785                	li	a5,1
    800057a6:	0af70a63          	beq	a4,a5,8000585a <sys_unlink+0x192>
  iunlockput(dp);
    800057aa:	8526                	mv	a0,s1
    800057ac:	ffffe097          	auipc	ra,0xffffe
    800057b0:	13c080e7          	jalr	316(ra) # 800038e8 <iunlockput>
  ip->nlink--;
    800057b4:	04a95783          	lhu	a5,74(s2)
    800057b8:	37fd                	addiw	a5,a5,-1
    800057ba:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800057be:	854a                	mv	a0,s2
    800057c0:	ffffe097          	auipc	ra,0xffffe
    800057c4:	e20080e7          	jalr	-480(ra) # 800035e0 <iupdate>
  iunlockput(ip);
    800057c8:	854a                	mv	a0,s2
    800057ca:	ffffe097          	auipc	ra,0xffffe
    800057ce:	11e080e7          	jalr	286(ra) # 800038e8 <iunlockput>
  end_op(ROOTDEV);
    800057d2:	4501                	li	a0,0
    800057d4:	fffff097          	auipc	ra,0xfffff
    800057d8:	a28080e7          	jalr	-1496(ra) # 800041fc <end_op>
  return 0;
    800057dc:	4501                	li	a0,0
    800057de:	a85d                	j	80005894 <sys_unlink+0x1cc>
    end_op(ROOTDEV);
    800057e0:	4501                	li	a0,0
    800057e2:	fffff097          	auipc	ra,0xfffff
    800057e6:	a1a080e7          	jalr	-1510(ra) # 800041fc <end_op>
    return -1;
    800057ea:	557d                	li	a0,-1
    800057ec:	a065                	j	80005894 <sys_unlink+0x1cc>
    panic("unlink: nlink < 1");
    800057ee:	00003517          	auipc	a0,0x3
    800057f2:	fa250513          	addi	a0,a0,-94 # 80008790 <userret+0x700>
    800057f6:	ffffb097          	auipc	ra,0xffffb
    800057fa:	d52080e7          	jalr	-686(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057fe:	04c92703          	lw	a4,76(s2)
    80005802:	02000793          	li	a5,32
    80005806:	f6e7f7e3          	bgeu	a5,a4,80005774 <sys_unlink+0xac>
    8000580a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000580e:	4741                	li	a4,16
    80005810:	86ce                	mv	a3,s3
    80005812:	f1840613          	addi	a2,s0,-232
    80005816:	4581                	li	a1,0
    80005818:	854a                	mv	a0,s2
    8000581a:	ffffe097          	auipc	ra,0xffffe
    8000581e:	120080e7          	jalr	288(ra) # 8000393a <readi>
    80005822:	47c1                	li	a5,16
    80005824:	00f51b63          	bne	a0,a5,8000583a <sys_unlink+0x172>
    if(de.inum != 0)
    80005828:	f1845783          	lhu	a5,-232(s0)
    8000582c:	e7a1                	bnez	a5,80005874 <sys_unlink+0x1ac>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000582e:	29c1                	addiw	s3,s3,16
    80005830:	04c92783          	lw	a5,76(s2)
    80005834:	fcf9ede3          	bltu	s3,a5,8000580e <sys_unlink+0x146>
    80005838:	bf35                	j	80005774 <sys_unlink+0xac>
      panic("isdirempty: readi");
    8000583a:	00003517          	auipc	a0,0x3
    8000583e:	f6e50513          	addi	a0,a0,-146 # 800087a8 <userret+0x718>
    80005842:	ffffb097          	auipc	ra,0xffffb
    80005846:	d06080e7          	jalr	-762(ra) # 80000548 <panic>
    panic("unlink: writei");
    8000584a:	00003517          	auipc	a0,0x3
    8000584e:	f7650513          	addi	a0,a0,-138 # 800087c0 <userret+0x730>
    80005852:	ffffb097          	auipc	ra,0xffffb
    80005856:	cf6080e7          	jalr	-778(ra) # 80000548 <panic>
    dp->nlink--;
    8000585a:	04a4d783          	lhu	a5,74(s1)
    8000585e:	37fd                	addiw	a5,a5,-1
    80005860:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005864:	8526                	mv	a0,s1
    80005866:	ffffe097          	auipc	ra,0xffffe
    8000586a:	d7a080e7          	jalr	-646(ra) # 800035e0 <iupdate>
    8000586e:	bf35                	j	800057aa <sys_unlink+0xe2>
    return -1;
    80005870:	557d                	li	a0,-1
    80005872:	a00d                	j	80005894 <sys_unlink+0x1cc>
    iunlockput(ip);
    80005874:	854a                	mv	a0,s2
    80005876:	ffffe097          	auipc	ra,0xffffe
    8000587a:	072080e7          	jalr	114(ra) # 800038e8 <iunlockput>
  iunlockput(dp);
    8000587e:	8526                	mv	a0,s1
    80005880:	ffffe097          	auipc	ra,0xffffe
    80005884:	068080e7          	jalr	104(ra) # 800038e8 <iunlockput>
  end_op(ROOTDEV);
    80005888:	4501                	li	a0,0
    8000588a:	fffff097          	auipc	ra,0xfffff
    8000588e:	972080e7          	jalr	-1678(ra) # 800041fc <end_op>
  return -1;
    80005892:	557d                	li	a0,-1
}
    80005894:	70ae                	ld	ra,232(sp)
    80005896:	740e                	ld	s0,224(sp)
    80005898:	64ee                	ld	s1,216(sp)
    8000589a:	694e                	ld	s2,208(sp)
    8000589c:	69ae                	ld	s3,200(sp)
    8000589e:	616d                	addi	sp,sp,240
    800058a0:	8082                	ret

00000000800058a2 <sys_open>:

uint64
sys_open(void)
{
    800058a2:	7131                	addi	sp,sp,-192
    800058a4:	fd06                	sd	ra,184(sp)
    800058a6:	f922                	sd	s0,176(sp)
    800058a8:	f526                	sd	s1,168(sp)
    800058aa:	f14a                	sd	s2,160(sp)
    800058ac:	ed4e                	sd	s3,152(sp)
    800058ae:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058b0:	08000613          	li	a2,128
    800058b4:	f5040593          	addi	a1,s0,-176
    800058b8:	4501                	li	a0,0
    800058ba:	ffffd097          	auipc	ra,0xffffd
    800058be:	26e080e7          	jalr	622(ra) # 80002b28 <argstr>
    return -1;
    800058c2:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058c4:	0a054963          	bltz	a0,80005976 <sys_open+0xd4>
    800058c8:	f4c40593          	addi	a1,s0,-180
    800058cc:	4505                	li	a0,1
    800058ce:	ffffd097          	auipc	ra,0xffffd
    800058d2:	216080e7          	jalr	534(ra) # 80002ae4 <argint>
    800058d6:	0a054063          	bltz	a0,80005976 <sys_open+0xd4>

  begin_op(ROOTDEV);
    800058da:	4501                	li	a0,0
    800058dc:	fffff097          	auipc	ra,0xfffff
    800058e0:	876080e7          	jalr	-1930(ra) # 80004152 <begin_op>

  if(omode & O_CREATE){
    800058e4:	f4c42783          	lw	a5,-180(s0)
    800058e8:	2007f793          	andi	a5,a5,512
    800058ec:	c3dd                	beqz	a5,80005992 <sys_open+0xf0>
    ip = create(path, T_FILE, 0, 0);
    800058ee:	4681                	li	a3,0
    800058f0:	4601                	li	a2,0
    800058f2:	4589                	li	a1,2
    800058f4:	f5040513          	addi	a0,s0,-176
    800058f8:	00000097          	auipc	ra,0x0
    800058fc:	960080e7          	jalr	-1696(ra) # 80005258 <create>
    80005900:	892a                	mv	s2,a0
    if(ip == 0){
    80005902:	c151                	beqz	a0,80005986 <sys_open+0xe4>
      end_op(ROOTDEV);
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005904:	04491703          	lh	a4,68(s2)
    80005908:	478d                	li	a5,3
    8000590a:	00f71763          	bne	a4,a5,80005918 <sys_open+0x76>
    8000590e:	04695703          	lhu	a4,70(s2)
    80005912:	47a5                	li	a5,9
    80005914:	0ce7e663          	bltu	a5,a4,800059e0 <sys_open+0x13e>
    iunlockput(ip);
    end_op(ROOTDEV);
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005918:	fffff097          	auipc	ra,0xfffff
    8000591c:	da6080e7          	jalr	-602(ra) # 800046be <filealloc>
    80005920:	89aa                	mv	s3,a0
    80005922:	c97d                	beqz	a0,80005a18 <sys_open+0x176>
    80005924:	00000097          	auipc	ra,0x0
    80005928:	8f2080e7          	jalr	-1806(ra) # 80005216 <fdalloc>
    8000592c:	84aa                	mv	s1,a0
    8000592e:	0e054063          	bltz	a0,80005a0e <sys_open+0x16c>
    iunlockput(ip);
    end_op(ROOTDEV);
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005932:	04491703          	lh	a4,68(s2)
    80005936:	478d                	li	a5,3
    80005938:	0cf70063          	beq	a4,a5,800059f8 <sys_open+0x156>
    f->type = FD_DEVICE;
    f->major = ip->major;
    f->minor = ip->minor;
  } else {
    f->type = FD_INODE;
    8000593c:	4789                	li	a5,2
    8000593e:	00f9a023          	sw	a5,0(s3)
  }
  f->ip = ip;
    80005942:	0129bc23          	sd	s2,24(s3)
  f->off = 0;
    80005946:	0209a023          	sw	zero,32(s3)
  f->readable = !(omode & O_WRONLY);
    8000594a:	f4c42783          	lw	a5,-180(s0)
    8000594e:	0017c713          	xori	a4,a5,1
    80005952:	8b05                	andi	a4,a4,1
    80005954:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005958:	8b8d                	andi	a5,a5,3
    8000595a:	00f037b3          	snez	a5,a5
    8000595e:	00f984a3          	sb	a5,9(s3)

  iunlock(ip);
    80005962:	854a                	mv	a0,s2
    80005964:	ffffe097          	auipc	ra,0xffffe
    80005968:	e08080e7          	jalr	-504(ra) # 8000376c <iunlock>
  end_op(ROOTDEV);
    8000596c:	4501                	li	a0,0
    8000596e:	fffff097          	auipc	ra,0xfffff
    80005972:	88e080e7          	jalr	-1906(ra) # 800041fc <end_op>

  return fd;
}
    80005976:	8526                	mv	a0,s1
    80005978:	70ea                	ld	ra,184(sp)
    8000597a:	744a                	ld	s0,176(sp)
    8000597c:	74aa                	ld	s1,168(sp)
    8000597e:	790a                	ld	s2,160(sp)
    80005980:	69ea                	ld	s3,152(sp)
    80005982:	6129                	addi	sp,sp,192
    80005984:	8082                	ret
      end_op(ROOTDEV);
    80005986:	4501                	li	a0,0
    80005988:	fffff097          	auipc	ra,0xfffff
    8000598c:	874080e7          	jalr	-1932(ra) # 800041fc <end_op>
      return -1;
    80005990:	b7dd                	j	80005976 <sys_open+0xd4>
    if((ip = namei(path)) == 0){
    80005992:	f5040513          	addi	a0,s0,-176
    80005996:	ffffe097          	auipc	ra,0xffffe
    8000599a:	49e080e7          	jalr	1182(ra) # 80003e34 <namei>
    8000599e:	892a                	mv	s2,a0
    800059a0:	c90d                	beqz	a0,800059d2 <sys_open+0x130>
    ilock(ip);
    800059a2:	ffffe097          	auipc	ra,0xffffe
    800059a6:	d08080e7          	jalr	-760(ra) # 800036aa <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800059aa:	04491703          	lh	a4,68(s2)
    800059ae:	4785                	li	a5,1
    800059b0:	f4f71ae3          	bne	a4,a5,80005904 <sys_open+0x62>
    800059b4:	f4c42783          	lw	a5,-180(s0)
    800059b8:	d3a5                	beqz	a5,80005918 <sys_open+0x76>
      iunlockput(ip);
    800059ba:	854a                	mv	a0,s2
    800059bc:	ffffe097          	auipc	ra,0xffffe
    800059c0:	f2c080e7          	jalr	-212(ra) # 800038e8 <iunlockput>
      end_op(ROOTDEV);
    800059c4:	4501                	li	a0,0
    800059c6:	fffff097          	auipc	ra,0xfffff
    800059ca:	836080e7          	jalr	-1994(ra) # 800041fc <end_op>
      return -1;
    800059ce:	54fd                	li	s1,-1
    800059d0:	b75d                	j	80005976 <sys_open+0xd4>
      end_op(ROOTDEV);
    800059d2:	4501                	li	a0,0
    800059d4:	fffff097          	auipc	ra,0xfffff
    800059d8:	828080e7          	jalr	-2008(ra) # 800041fc <end_op>
      return -1;
    800059dc:	54fd                	li	s1,-1
    800059de:	bf61                	j	80005976 <sys_open+0xd4>
    iunlockput(ip);
    800059e0:	854a                	mv	a0,s2
    800059e2:	ffffe097          	auipc	ra,0xffffe
    800059e6:	f06080e7          	jalr	-250(ra) # 800038e8 <iunlockput>
    end_op(ROOTDEV);
    800059ea:	4501                	li	a0,0
    800059ec:	fffff097          	auipc	ra,0xfffff
    800059f0:	810080e7          	jalr	-2032(ra) # 800041fc <end_op>
    return -1;
    800059f4:	54fd                	li	s1,-1
    800059f6:	b741                	j	80005976 <sys_open+0xd4>
    f->type = FD_DEVICE;
    800059f8:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800059fc:	04691783          	lh	a5,70(s2)
    80005a00:	02f99223          	sh	a5,36(s3)
    f->minor = ip->minor;
    80005a04:	04891783          	lh	a5,72(s2)
    80005a08:	02f99323          	sh	a5,38(s3)
    80005a0c:	bf1d                	j	80005942 <sys_open+0xa0>
      fileclose(f);
    80005a0e:	854e                	mv	a0,s3
    80005a10:	fffff097          	auipc	ra,0xfffff
    80005a14:	d6a080e7          	jalr	-662(ra) # 8000477a <fileclose>
    iunlockput(ip);
    80005a18:	854a                	mv	a0,s2
    80005a1a:	ffffe097          	auipc	ra,0xffffe
    80005a1e:	ece080e7          	jalr	-306(ra) # 800038e8 <iunlockput>
    end_op(ROOTDEV);
    80005a22:	4501                	li	a0,0
    80005a24:	ffffe097          	auipc	ra,0xffffe
    80005a28:	7d8080e7          	jalr	2008(ra) # 800041fc <end_op>
    return -1;
    80005a2c:	54fd                	li	s1,-1
    80005a2e:	b7a1                	j	80005976 <sys_open+0xd4>

0000000080005a30 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a30:	7175                	addi	sp,sp,-144
    80005a32:	e506                	sd	ra,136(sp)
    80005a34:	e122                	sd	s0,128(sp)
    80005a36:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op(ROOTDEV);
    80005a38:	4501                	li	a0,0
    80005a3a:	ffffe097          	auipc	ra,0xffffe
    80005a3e:	718080e7          	jalr	1816(ra) # 80004152 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a42:	08000613          	li	a2,128
    80005a46:	f7040593          	addi	a1,s0,-144
    80005a4a:	4501                	li	a0,0
    80005a4c:	ffffd097          	auipc	ra,0xffffd
    80005a50:	0dc080e7          	jalr	220(ra) # 80002b28 <argstr>
    80005a54:	02054a63          	bltz	a0,80005a88 <sys_mkdir+0x58>
    80005a58:	4681                	li	a3,0
    80005a5a:	4601                	li	a2,0
    80005a5c:	4585                	li	a1,1
    80005a5e:	f7040513          	addi	a0,s0,-144
    80005a62:	fffff097          	auipc	ra,0xfffff
    80005a66:	7f6080e7          	jalr	2038(ra) # 80005258 <create>
    80005a6a:	cd19                	beqz	a0,80005a88 <sys_mkdir+0x58>
    end_op(ROOTDEV);
    return -1;
  }
  iunlockput(ip);
    80005a6c:	ffffe097          	auipc	ra,0xffffe
    80005a70:	e7c080e7          	jalr	-388(ra) # 800038e8 <iunlockput>
  end_op(ROOTDEV);
    80005a74:	4501                	li	a0,0
    80005a76:	ffffe097          	auipc	ra,0xffffe
    80005a7a:	786080e7          	jalr	1926(ra) # 800041fc <end_op>
  return 0;
    80005a7e:	4501                	li	a0,0
}
    80005a80:	60aa                	ld	ra,136(sp)
    80005a82:	640a                	ld	s0,128(sp)
    80005a84:	6149                	addi	sp,sp,144
    80005a86:	8082                	ret
    end_op(ROOTDEV);
    80005a88:	4501                	li	a0,0
    80005a8a:	ffffe097          	auipc	ra,0xffffe
    80005a8e:	772080e7          	jalr	1906(ra) # 800041fc <end_op>
    return -1;
    80005a92:	557d                	li	a0,-1
    80005a94:	b7f5                	j	80005a80 <sys_mkdir+0x50>

0000000080005a96 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a96:	7135                	addi	sp,sp,-160
    80005a98:	ed06                	sd	ra,152(sp)
    80005a9a:	e922                	sd	s0,144(sp)
    80005a9c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op(ROOTDEV);
    80005a9e:	4501                	li	a0,0
    80005aa0:	ffffe097          	auipc	ra,0xffffe
    80005aa4:	6b2080e7          	jalr	1714(ra) # 80004152 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005aa8:	08000613          	li	a2,128
    80005aac:	f7040593          	addi	a1,s0,-144
    80005ab0:	4501                	li	a0,0
    80005ab2:	ffffd097          	auipc	ra,0xffffd
    80005ab6:	076080e7          	jalr	118(ra) # 80002b28 <argstr>
    80005aba:	04054b63          	bltz	a0,80005b10 <sys_mknod+0x7a>
     argint(1, &major) < 0 ||
    80005abe:	f6c40593          	addi	a1,s0,-148
    80005ac2:	4505                	li	a0,1
    80005ac4:	ffffd097          	auipc	ra,0xffffd
    80005ac8:	020080e7          	jalr	32(ra) # 80002ae4 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005acc:	04054263          	bltz	a0,80005b10 <sys_mknod+0x7a>
     argint(2, &minor) < 0 ||
    80005ad0:	f6840593          	addi	a1,s0,-152
    80005ad4:	4509                	li	a0,2
    80005ad6:	ffffd097          	auipc	ra,0xffffd
    80005ada:	00e080e7          	jalr	14(ra) # 80002ae4 <argint>
     argint(1, &major) < 0 ||
    80005ade:	02054963          	bltz	a0,80005b10 <sys_mknod+0x7a>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ae2:	f6841683          	lh	a3,-152(s0)
    80005ae6:	f6c41603          	lh	a2,-148(s0)
    80005aea:	458d                	li	a1,3
    80005aec:	f7040513          	addi	a0,s0,-144
    80005af0:	fffff097          	auipc	ra,0xfffff
    80005af4:	768080e7          	jalr	1896(ra) # 80005258 <create>
     argint(2, &minor) < 0 ||
    80005af8:	cd01                	beqz	a0,80005b10 <sys_mknod+0x7a>
    end_op(ROOTDEV);
    return -1;
  }
  iunlockput(ip);
    80005afa:	ffffe097          	auipc	ra,0xffffe
    80005afe:	dee080e7          	jalr	-530(ra) # 800038e8 <iunlockput>
  end_op(ROOTDEV);
    80005b02:	4501                	li	a0,0
    80005b04:	ffffe097          	auipc	ra,0xffffe
    80005b08:	6f8080e7          	jalr	1784(ra) # 800041fc <end_op>
  return 0;
    80005b0c:	4501                	li	a0,0
    80005b0e:	a039                	j	80005b1c <sys_mknod+0x86>
    end_op(ROOTDEV);
    80005b10:	4501                	li	a0,0
    80005b12:	ffffe097          	auipc	ra,0xffffe
    80005b16:	6ea080e7          	jalr	1770(ra) # 800041fc <end_op>
    return -1;
    80005b1a:	557d                	li	a0,-1
}
    80005b1c:	60ea                	ld	ra,152(sp)
    80005b1e:	644a                	ld	s0,144(sp)
    80005b20:	610d                	addi	sp,sp,160
    80005b22:	8082                	ret

0000000080005b24 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b24:	7135                	addi	sp,sp,-160
    80005b26:	ed06                	sd	ra,152(sp)
    80005b28:	e922                	sd	s0,144(sp)
    80005b2a:	e526                	sd	s1,136(sp)
    80005b2c:	e14a                	sd	s2,128(sp)
    80005b2e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b30:	ffffc097          	auipc	ra,0xffffc
    80005b34:	eb8080e7          	jalr	-328(ra) # 800019e8 <myproc>
    80005b38:	892a                	mv	s2,a0
  
  begin_op(ROOTDEV);
    80005b3a:	4501                	li	a0,0
    80005b3c:	ffffe097          	auipc	ra,0xffffe
    80005b40:	616080e7          	jalr	1558(ra) # 80004152 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b44:	08000613          	li	a2,128
    80005b48:	f6040593          	addi	a1,s0,-160
    80005b4c:	4501                	li	a0,0
    80005b4e:	ffffd097          	auipc	ra,0xffffd
    80005b52:	fda080e7          	jalr	-38(ra) # 80002b28 <argstr>
    80005b56:	04054c63          	bltz	a0,80005bae <sys_chdir+0x8a>
    80005b5a:	f6040513          	addi	a0,s0,-160
    80005b5e:	ffffe097          	auipc	ra,0xffffe
    80005b62:	2d6080e7          	jalr	726(ra) # 80003e34 <namei>
    80005b66:	84aa                	mv	s1,a0
    80005b68:	c139                	beqz	a0,80005bae <sys_chdir+0x8a>
    end_op(ROOTDEV);
    return -1;
  }
  ilock(ip);
    80005b6a:	ffffe097          	auipc	ra,0xffffe
    80005b6e:	b40080e7          	jalr	-1216(ra) # 800036aa <ilock>
  if(ip->type != T_DIR){
    80005b72:	04449703          	lh	a4,68(s1)
    80005b76:	4785                	li	a5,1
    80005b78:	04f71263          	bne	a4,a5,80005bbc <sys_chdir+0x98>
    iunlockput(ip);
    end_op(ROOTDEV);
    return -1;
  }
  iunlock(ip);
    80005b7c:	8526                	mv	a0,s1
    80005b7e:	ffffe097          	auipc	ra,0xffffe
    80005b82:	bee080e7          	jalr	-1042(ra) # 8000376c <iunlock>
  iput(p->cwd);
    80005b86:	15093503          	ld	a0,336(s2)
    80005b8a:	ffffe097          	auipc	ra,0xffffe
    80005b8e:	c2e080e7          	jalr	-978(ra) # 800037b8 <iput>
  end_op(ROOTDEV);
    80005b92:	4501                	li	a0,0
    80005b94:	ffffe097          	auipc	ra,0xffffe
    80005b98:	668080e7          	jalr	1640(ra) # 800041fc <end_op>
  p->cwd = ip;
    80005b9c:	14993823          	sd	s1,336(s2)
  return 0;
    80005ba0:	4501                	li	a0,0
}
    80005ba2:	60ea                	ld	ra,152(sp)
    80005ba4:	644a                	ld	s0,144(sp)
    80005ba6:	64aa                	ld	s1,136(sp)
    80005ba8:	690a                	ld	s2,128(sp)
    80005baa:	610d                	addi	sp,sp,160
    80005bac:	8082                	ret
    end_op(ROOTDEV);
    80005bae:	4501                	li	a0,0
    80005bb0:	ffffe097          	auipc	ra,0xffffe
    80005bb4:	64c080e7          	jalr	1612(ra) # 800041fc <end_op>
    return -1;
    80005bb8:	557d                	li	a0,-1
    80005bba:	b7e5                	j	80005ba2 <sys_chdir+0x7e>
    iunlockput(ip);
    80005bbc:	8526                	mv	a0,s1
    80005bbe:	ffffe097          	auipc	ra,0xffffe
    80005bc2:	d2a080e7          	jalr	-726(ra) # 800038e8 <iunlockput>
    end_op(ROOTDEV);
    80005bc6:	4501                	li	a0,0
    80005bc8:	ffffe097          	auipc	ra,0xffffe
    80005bcc:	634080e7          	jalr	1588(ra) # 800041fc <end_op>
    return -1;
    80005bd0:	557d                	li	a0,-1
    80005bd2:	bfc1                	j	80005ba2 <sys_chdir+0x7e>

0000000080005bd4 <sys_exec>:

uint64
sys_exec(void)
{
    80005bd4:	7145                	addi	sp,sp,-464
    80005bd6:	e786                	sd	ra,456(sp)
    80005bd8:	e3a2                	sd	s0,448(sp)
    80005bda:	ff26                	sd	s1,440(sp)
    80005bdc:	fb4a                	sd	s2,432(sp)
    80005bde:	f74e                	sd	s3,424(sp)
    80005be0:	f352                	sd	s4,416(sp)
    80005be2:	ef56                	sd	s5,408(sp)
    80005be4:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005be6:	08000613          	li	a2,128
    80005bea:	f4040593          	addi	a1,s0,-192
    80005bee:	4501                	li	a0,0
    80005bf0:	ffffd097          	auipc	ra,0xffffd
    80005bf4:	f38080e7          	jalr	-200(ra) # 80002b28 <argstr>
    80005bf8:	0e054663          	bltz	a0,80005ce4 <sys_exec+0x110>
    80005bfc:	e3840593          	addi	a1,s0,-456
    80005c00:	4505                	li	a0,1
    80005c02:	ffffd097          	auipc	ra,0xffffd
    80005c06:	f04080e7          	jalr	-252(ra) # 80002b06 <argaddr>
    80005c0a:	0e054763          	bltz	a0,80005cf8 <sys_exec+0x124>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
    80005c0e:	10000613          	li	a2,256
    80005c12:	4581                	li	a1,0
    80005c14:	e4040513          	addi	a0,s0,-448
    80005c18:	ffffb097          	auipc	ra,0xffffb
    80005c1c:	f6a080e7          	jalr	-150(ra) # 80000b82 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c20:	e4040913          	addi	s2,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c24:	89ca                	mv	s3,s2
    80005c26:	4481                	li	s1,0
    if(i >= NELEM(argv)){
    80005c28:	02000a13          	li	s4,32
    80005c2c:	00048a9b          	sext.w	s5,s1
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c30:	00349793          	slli	a5,s1,0x3
    80005c34:	e3040593          	addi	a1,s0,-464
    80005c38:	e3843503          	ld	a0,-456(s0)
    80005c3c:	953e                	add	a0,a0,a5
    80005c3e:	ffffd097          	auipc	ra,0xffffd
    80005c42:	e0c080e7          	jalr	-500(ra) # 80002a4a <fetchaddr>
    80005c46:	02054a63          	bltz	a0,80005c7a <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005c4a:	e3043783          	ld	a5,-464(s0)
    80005c4e:	c7a1                	beqz	a5,80005c96 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c50:	ffffb097          	auipc	ra,0xffffb
    80005c54:	d00080e7          	jalr	-768(ra) # 80000950 <kalloc>
    80005c58:	85aa                	mv	a1,a0
    80005c5a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c5e:	c92d                	beqz	a0,80005cd0 <sys_exec+0xfc>
      panic("sys_exec kalloc");
    if(fetchstr(uarg, argv[i], PGSIZE) < 0){
    80005c60:	6605                	lui	a2,0x1
    80005c62:	e3043503          	ld	a0,-464(s0)
    80005c66:	ffffd097          	auipc	ra,0xffffd
    80005c6a:	e36080e7          	jalr	-458(ra) # 80002a9c <fetchstr>
    80005c6e:	00054663          	bltz	a0,80005c7a <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005c72:	0485                	addi	s1,s1,1
    80005c74:	09a1                	addi	s3,s3,8
    80005c76:	fb449be3          	bne	s1,s4,80005c2c <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c7a:	10090493          	addi	s1,s2,256
    80005c7e:	00093503          	ld	a0,0(s2)
    80005c82:	cd39                	beqz	a0,80005ce0 <sys_exec+0x10c>
    kfree(argv[i]);
    80005c84:	ffffb097          	auipc	ra,0xffffb
    80005c88:	bd0080e7          	jalr	-1072(ra) # 80000854 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c8c:	0921                	addi	s2,s2,8
    80005c8e:	fe9918e3          	bne	s2,s1,80005c7e <sys_exec+0xaa>
  return -1;
    80005c92:	557d                	li	a0,-1
    80005c94:	a889                	j	80005ce6 <sys_exec+0x112>
      argv[i] = 0;
    80005c96:	0a8e                	slli	s5,s5,0x3
    80005c98:	fc040793          	addi	a5,s0,-64
    80005c9c:	9abe                	add	s5,s5,a5
    80005c9e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005ca2:	e4040593          	addi	a1,s0,-448
    80005ca6:	f4040513          	addi	a0,s0,-192
    80005caa:	fffff097          	auipc	ra,0xfffff
    80005cae:	178080e7          	jalr	376(ra) # 80004e22 <exec>
    80005cb2:	84aa                	mv	s1,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cb4:	10090993          	addi	s3,s2,256
    80005cb8:	00093503          	ld	a0,0(s2)
    80005cbc:	c901                	beqz	a0,80005ccc <sys_exec+0xf8>
    kfree(argv[i]);
    80005cbe:	ffffb097          	auipc	ra,0xffffb
    80005cc2:	b96080e7          	jalr	-1130(ra) # 80000854 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cc6:	0921                	addi	s2,s2,8
    80005cc8:	ff3918e3          	bne	s2,s3,80005cb8 <sys_exec+0xe4>
  return ret;
    80005ccc:	8526                	mv	a0,s1
    80005cce:	a821                	j	80005ce6 <sys_exec+0x112>
      panic("sys_exec kalloc");
    80005cd0:	00003517          	auipc	a0,0x3
    80005cd4:	b0050513          	addi	a0,a0,-1280 # 800087d0 <userret+0x740>
    80005cd8:	ffffb097          	auipc	ra,0xffffb
    80005cdc:	870080e7          	jalr	-1936(ra) # 80000548 <panic>
  return -1;
    80005ce0:	557d                	li	a0,-1
    80005ce2:	a011                	j	80005ce6 <sys_exec+0x112>
    return -1;
    80005ce4:	557d                	li	a0,-1
}
    80005ce6:	60be                	ld	ra,456(sp)
    80005ce8:	641e                	ld	s0,448(sp)
    80005cea:	74fa                	ld	s1,440(sp)
    80005cec:	795a                	ld	s2,432(sp)
    80005cee:	79ba                	ld	s3,424(sp)
    80005cf0:	7a1a                	ld	s4,416(sp)
    80005cf2:	6afa                	ld	s5,408(sp)
    80005cf4:	6179                	addi	sp,sp,464
    80005cf6:	8082                	ret
    return -1;
    80005cf8:	557d                	li	a0,-1
    80005cfa:	b7f5                	j	80005ce6 <sys_exec+0x112>

0000000080005cfc <sys_pipe>:

uint64
sys_pipe(void)
{
    80005cfc:	7139                	addi	sp,sp,-64
    80005cfe:	fc06                	sd	ra,56(sp)
    80005d00:	f822                	sd	s0,48(sp)
    80005d02:	f426                	sd	s1,40(sp)
    80005d04:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d06:	ffffc097          	auipc	ra,0xffffc
    80005d0a:	ce2080e7          	jalr	-798(ra) # 800019e8 <myproc>
    80005d0e:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d10:	fd840593          	addi	a1,s0,-40
    80005d14:	4501                	li	a0,0
    80005d16:	ffffd097          	auipc	ra,0xffffd
    80005d1a:	df0080e7          	jalr	-528(ra) # 80002b06 <argaddr>
    return -1;
    80005d1e:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005d20:	0e054063          	bltz	a0,80005e00 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005d24:	fc840593          	addi	a1,s0,-56
    80005d28:	fd040513          	addi	a0,s0,-48
    80005d2c:	fffff097          	auipc	ra,0xfffff
    80005d30:	db2080e7          	jalr	-590(ra) # 80004ade <pipealloc>
    return -1;
    80005d34:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d36:	0c054563          	bltz	a0,80005e00 <sys_pipe+0x104>
  fd0 = -1;
    80005d3a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d3e:	fd043503          	ld	a0,-48(s0)
    80005d42:	fffff097          	auipc	ra,0xfffff
    80005d46:	4d4080e7          	jalr	1236(ra) # 80005216 <fdalloc>
    80005d4a:	fca42223          	sw	a0,-60(s0)
    80005d4e:	08054c63          	bltz	a0,80005de6 <sys_pipe+0xea>
    80005d52:	fc843503          	ld	a0,-56(s0)
    80005d56:	fffff097          	auipc	ra,0xfffff
    80005d5a:	4c0080e7          	jalr	1216(ra) # 80005216 <fdalloc>
    80005d5e:	fca42023          	sw	a0,-64(s0)
    80005d62:	06054863          	bltz	a0,80005dd2 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d66:	4691                	li	a3,4
    80005d68:	fc440613          	addi	a2,s0,-60
    80005d6c:	fd843583          	ld	a1,-40(s0)
    80005d70:	68a8                	ld	a0,80(s1)
    80005d72:	ffffc097          	auipc	ra,0xffffc
    80005d76:	872080e7          	jalr	-1934(ra) # 800015e4 <copyout>
    80005d7a:	02054063          	bltz	a0,80005d9a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d7e:	4691                	li	a3,4
    80005d80:	fc040613          	addi	a2,s0,-64
    80005d84:	fd843583          	ld	a1,-40(s0)
    80005d88:	0591                	addi	a1,a1,4
    80005d8a:	68a8                	ld	a0,80(s1)
    80005d8c:	ffffc097          	auipc	ra,0xffffc
    80005d90:	858080e7          	jalr	-1960(ra) # 800015e4 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d94:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d96:	06055563          	bgez	a0,80005e00 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005d9a:	fc442783          	lw	a5,-60(s0)
    80005d9e:	07e9                	addi	a5,a5,26
    80005da0:	078e                	slli	a5,a5,0x3
    80005da2:	97a6                	add	a5,a5,s1
    80005da4:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005da8:	fc042503          	lw	a0,-64(s0)
    80005dac:	0569                	addi	a0,a0,26
    80005dae:	050e                	slli	a0,a0,0x3
    80005db0:	9526                	add	a0,a0,s1
    80005db2:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005db6:	fd043503          	ld	a0,-48(s0)
    80005dba:	fffff097          	auipc	ra,0xfffff
    80005dbe:	9c0080e7          	jalr	-1600(ra) # 8000477a <fileclose>
    fileclose(wf);
    80005dc2:	fc843503          	ld	a0,-56(s0)
    80005dc6:	fffff097          	auipc	ra,0xfffff
    80005dca:	9b4080e7          	jalr	-1612(ra) # 8000477a <fileclose>
    return -1;
    80005dce:	57fd                	li	a5,-1
    80005dd0:	a805                	j	80005e00 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005dd2:	fc442783          	lw	a5,-60(s0)
    80005dd6:	0007c863          	bltz	a5,80005de6 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005dda:	01a78513          	addi	a0,a5,26
    80005dde:	050e                	slli	a0,a0,0x3
    80005de0:	9526                	add	a0,a0,s1
    80005de2:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005de6:	fd043503          	ld	a0,-48(s0)
    80005dea:	fffff097          	auipc	ra,0xfffff
    80005dee:	990080e7          	jalr	-1648(ra) # 8000477a <fileclose>
    fileclose(wf);
    80005df2:	fc843503          	ld	a0,-56(s0)
    80005df6:	fffff097          	auipc	ra,0xfffff
    80005dfa:	984080e7          	jalr	-1660(ra) # 8000477a <fileclose>
    return -1;
    80005dfe:	57fd                	li	a5,-1
}
    80005e00:	853e                	mv	a0,a5
    80005e02:	70e2                	ld	ra,56(sp)
    80005e04:	7442                	ld	s0,48(sp)
    80005e06:	74a2                	ld	s1,40(sp)
    80005e08:	6121                	addi	sp,sp,64
    80005e0a:	8082                	ret

0000000080005e0c <sys_crash>:

// system call to test crashes
uint64
sys_crash(void)
{
    80005e0c:	7171                	addi	sp,sp,-176
    80005e0e:	f506                	sd	ra,168(sp)
    80005e10:	f122                	sd	s0,160(sp)
    80005e12:	ed26                	sd	s1,152(sp)
    80005e14:	1900                	addi	s0,sp,176
  char path[MAXPATH];
  struct inode *ip;
  int crash;
  
  if(argstr(0, path, MAXPATH) < 0 || argint(1, &crash) < 0)
    80005e16:	08000613          	li	a2,128
    80005e1a:	f6040593          	addi	a1,s0,-160
    80005e1e:	4501                	li	a0,0
    80005e20:	ffffd097          	auipc	ra,0xffffd
    80005e24:	d08080e7          	jalr	-760(ra) # 80002b28 <argstr>
    return -1;
    80005e28:	57fd                	li	a5,-1
  if(argstr(0, path, MAXPATH) < 0 || argint(1, &crash) < 0)
    80005e2a:	04054363          	bltz	a0,80005e70 <sys_crash+0x64>
    80005e2e:	f5c40593          	addi	a1,s0,-164
    80005e32:	4505                	li	a0,1
    80005e34:	ffffd097          	auipc	ra,0xffffd
    80005e38:	cb0080e7          	jalr	-848(ra) # 80002ae4 <argint>
    return -1;
    80005e3c:	57fd                	li	a5,-1
  if(argstr(0, path, MAXPATH) < 0 || argint(1, &crash) < 0)
    80005e3e:	02054963          	bltz	a0,80005e70 <sys_crash+0x64>
  ip = create(path, T_FILE, 0, 0);
    80005e42:	4681                	li	a3,0
    80005e44:	4601                	li	a2,0
    80005e46:	4589                	li	a1,2
    80005e48:	f6040513          	addi	a0,s0,-160
    80005e4c:	fffff097          	auipc	ra,0xfffff
    80005e50:	40c080e7          	jalr	1036(ra) # 80005258 <create>
    80005e54:	84aa                	mv	s1,a0
  if(ip == 0){
    80005e56:	c11d                	beqz	a0,80005e7c <sys_crash+0x70>
    return -1;
  }
  iunlockput(ip);
    80005e58:	ffffe097          	auipc	ra,0xffffe
    80005e5c:	a90080e7          	jalr	-1392(ra) # 800038e8 <iunlockput>
  crash_op(ip->dev, crash);
    80005e60:	f5c42583          	lw	a1,-164(s0)
    80005e64:	4088                	lw	a0,0(s1)
    80005e66:	ffffe097          	auipc	ra,0xffffe
    80005e6a:	5e8080e7          	jalr	1512(ra) # 8000444e <crash_op>
  return 0;
    80005e6e:	4781                	li	a5,0
}
    80005e70:	853e                	mv	a0,a5
    80005e72:	70aa                	ld	ra,168(sp)
    80005e74:	740a                	ld	s0,160(sp)
    80005e76:	64ea                	ld	s1,152(sp)
    80005e78:	614d                	addi	sp,sp,176
    80005e7a:	8082                	ret
    return -1;
    80005e7c:	57fd                	li	a5,-1
    80005e7e:	bfcd                	j	80005e70 <sys_crash+0x64>

0000000080005e80 <kernelvec>:
    80005e80:	7111                	addi	sp,sp,-256
    80005e82:	e006                	sd	ra,0(sp)
    80005e84:	e40a                	sd	sp,8(sp)
    80005e86:	e80e                	sd	gp,16(sp)
    80005e88:	ec12                	sd	tp,24(sp)
    80005e8a:	f016                	sd	t0,32(sp)
    80005e8c:	f41a                	sd	t1,40(sp)
    80005e8e:	f81e                	sd	t2,48(sp)
    80005e90:	fc22                	sd	s0,56(sp)
    80005e92:	e0a6                	sd	s1,64(sp)
    80005e94:	e4aa                	sd	a0,72(sp)
    80005e96:	e8ae                	sd	a1,80(sp)
    80005e98:	ecb2                	sd	a2,88(sp)
    80005e9a:	f0b6                	sd	a3,96(sp)
    80005e9c:	f4ba                	sd	a4,104(sp)
    80005e9e:	f8be                	sd	a5,112(sp)
    80005ea0:	fcc2                	sd	a6,120(sp)
    80005ea2:	e146                	sd	a7,128(sp)
    80005ea4:	e54a                	sd	s2,136(sp)
    80005ea6:	e94e                	sd	s3,144(sp)
    80005ea8:	ed52                	sd	s4,152(sp)
    80005eaa:	f156                	sd	s5,160(sp)
    80005eac:	f55a                	sd	s6,168(sp)
    80005eae:	f95e                	sd	s7,176(sp)
    80005eb0:	fd62                	sd	s8,184(sp)
    80005eb2:	e1e6                	sd	s9,192(sp)
    80005eb4:	e5ea                	sd	s10,200(sp)
    80005eb6:	e9ee                	sd	s11,208(sp)
    80005eb8:	edf2                	sd	t3,216(sp)
    80005eba:	f1f6                	sd	t4,224(sp)
    80005ebc:	f5fa                	sd	t5,232(sp)
    80005ebe:	f9fe                	sd	t6,240(sp)
    80005ec0:	a57fc0ef          	jal	ra,80002916 <kerneltrap>
    80005ec4:	6082                	ld	ra,0(sp)
    80005ec6:	6122                	ld	sp,8(sp)
    80005ec8:	61c2                	ld	gp,16(sp)
    80005eca:	7282                	ld	t0,32(sp)
    80005ecc:	7322                	ld	t1,40(sp)
    80005ece:	73c2                	ld	t2,48(sp)
    80005ed0:	7462                	ld	s0,56(sp)
    80005ed2:	6486                	ld	s1,64(sp)
    80005ed4:	6526                	ld	a0,72(sp)
    80005ed6:	65c6                	ld	a1,80(sp)
    80005ed8:	6666                	ld	a2,88(sp)
    80005eda:	7686                	ld	a3,96(sp)
    80005edc:	7726                	ld	a4,104(sp)
    80005ede:	77c6                	ld	a5,112(sp)
    80005ee0:	7866                	ld	a6,120(sp)
    80005ee2:	688a                	ld	a7,128(sp)
    80005ee4:	692a                	ld	s2,136(sp)
    80005ee6:	69ca                	ld	s3,144(sp)
    80005ee8:	6a6a                	ld	s4,152(sp)
    80005eea:	7a8a                	ld	s5,160(sp)
    80005eec:	7b2a                	ld	s6,168(sp)
    80005eee:	7bca                	ld	s7,176(sp)
    80005ef0:	7c6a                	ld	s8,184(sp)
    80005ef2:	6c8e                	ld	s9,192(sp)
    80005ef4:	6d2e                	ld	s10,200(sp)
    80005ef6:	6dce                	ld	s11,208(sp)
    80005ef8:	6e6e                	ld	t3,216(sp)
    80005efa:	7e8e                	ld	t4,224(sp)
    80005efc:	7f2e                	ld	t5,232(sp)
    80005efe:	7fce                	ld	t6,240(sp)
    80005f00:	6111                	addi	sp,sp,256
    80005f02:	10200073          	sret
    80005f06:	00000013          	nop
    80005f0a:	00000013          	nop
    80005f0e:	0001                	nop

0000000080005f10 <timervec>:
    80005f10:	34051573          	csrrw	a0,mscratch,a0
    80005f14:	e10c                	sd	a1,0(a0)
    80005f16:	e510                	sd	a2,8(a0)
    80005f18:	e914                	sd	a3,16(a0)
    80005f1a:	710c                	ld	a1,32(a0)
    80005f1c:	7510                	ld	a2,40(a0)
    80005f1e:	6194                	ld	a3,0(a1)
    80005f20:	96b2                	add	a3,a3,a2
    80005f22:	e194                	sd	a3,0(a1)
    80005f24:	4589                	li	a1,2
    80005f26:	14459073          	csrw	sip,a1
    80005f2a:	6914                	ld	a3,16(a0)
    80005f2c:	6510                	ld	a2,8(a0)
    80005f2e:	610c                	ld	a1,0(a0)
    80005f30:	34051573          	csrrw	a0,mscratch,a0
    80005f34:	30200073          	mret
	...

0000000080005f3a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f3a:	1141                	addi	sp,sp,-16
    80005f3c:	e422                	sd	s0,8(sp)
    80005f3e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f40:	0c0007b7          	lui	a5,0xc000
    80005f44:	4705                	li	a4,1
    80005f46:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f48:	c3d8                	sw	a4,4(a5)
}
    80005f4a:	6422                	ld	s0,8(sp)
    80005f4c:	0141                	addi	sp,sp,16
    80005f4e:	8082                	ret

0000000080005f50 <plicinithart>:

void
plicinithart(void)
{
    80005f50:	1141                	addi	sp,sp,-16
    80005f52:	e406                	sd	ra,8(sp)
    80005f54:	e022                	sd	s0,0(sp)
    80005f56:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f58:	ffffc097          	auipc	ra,0xffffc
    80005f5c:	a64080e7          	jalr	-1436(ra) # 800019bc <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f60:	0085171b          	slliw	a4,a0,0x8
    80005f64:	0c0027b7          	lui	a5,0xc002
    80005f68:	97ba                	add	a5,a5,a4
    80005f6a:	40200713          	li	a4,1026
    80005f6e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f72:	00d5151b          	slliw	a0,a0,0xd
    80005f76:	0c2017b7          	lui	a5,0xc201
    80005f7a:	953e                	add	a0,a0,a5
    80005f7c:	00052023          	sw	zero,0(a0)
}
    80005f80:	60a2                	ld	ra,8(sp)
    80005f82:	6402                	ld	s0,0(sp)
    80005f84:	0141                	addi	sp,sp,16
    80005f86:	8082                	ret

0000000080005f88 <plic_pending>:

// return a bitmap of which IRQs are waiting
// to be served.
uint64
plic_pending(void)
{
    80005f88:	1141                	addi	sp,sp,-16
    80005f8a:	e422                	sd	s0,8(sp)
    80005f8c:	0800                	addi	s0,sp,16
  //mask = *(uint32*)(PLIC + 0x1000);
  //mask |= (uint64)*(uint32*)(PLIC + 0x1004) << 32;
  mask = *(uint64*)PLIC_PENDING;

  return mask;
}
    80005f8e:	0c0017b7          	lui	a5,0xc001
    80005f92:	6388                	ld	a0,0(a5)
    80005f94:	6422                	ld	s0,8(sp)
    80005f96:	0141                	addi	sp,sp,16
    80005f98:	8082                	ret

0000000080005f9a <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f9a:	1141                	addi	sp,sp,-16
    80005f9c:	e406                	sd	ra,8(sp)
    80005f9e:	e022                	sd	s0,0(sp)
    80005fa0:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fa2:	ffffc097          	auipc	ra,0xffffc
    80005fa6:	a1a080e7          	jalr	-1510(ra) # 800019bc <cpuid>
  //int irq = *(uint32*)(PLIC + 0x201004);
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005faa:	00d5179b          	slliw	a5,a0,0xd
    80005fae:	0c201537          	lui	a0,0xc201
    80005fb2:	953e                	add	a0,a0,a5
  return irq;
}
    80005fb4:	4148                	lw	a0,4(a0)
    80005fb6:	60a2                	ld	ra,8(sp)
    80005fb8:	6402                	ld	s0,0(sp)
    80005fba:	0141                	addi	sp,sp,16
    80005fbc:	8082                	ret

0000000080005fbe <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005fbe:	1101                	addi	sp,sp,-32
    80005fc0:	ec06                	sd	ra,24(sp)
    80005fc2:	e822                	sd	s0,16(sp)
    80005fc4:	e426                	sd	s1,8(sp)
    80005fc6:	1000                	addi	s0,sp,32
    80005fc8:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005fca:	ffffc097          	auipc	ra,0xffffc
    80005fce:	9f2080e7          	jalr	-1550(ra) # 800019bc <cpuid>
  //*(uint32*)(PLIC + 0x201004) = irq;
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005fd2:	00d5151b          	slliw	a0,a0,0xd
    80005fd6:	0c2017b7          	lui	a5,0xc201
    80005fda:	97aa                	add	a5,a5,a0
    80005fdc:	c3c4                	sw	s1,4(a5)
}
    80005fde:	60e2                	ld	ra,24(sp)
    80005fe0:	6442                	ld	s0,16(sp)
    80005fe2:	64a2                	ld	s1,8(sp)
    80005fe4:	6105                	addi	sp,sp,32
    80005fe6:	8082                	ret

0000000080005fe8 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int n, int i)
{
    80005fe8:	1141                	addi	sp,sp,-16
    80005fea:	e406                	sd	ra,8(sp)
    80005fec:	e022                	sd	s0,0(sp)
    80005fee:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005ff0:	479d                	li	a5,7
    80005ff2:	06b7c963          	blt	a5,a1,80006064 <free_desc+0x7c>
    panic("virtio_disk_intr 1");
  if(disk[n].free[i])
    80005ff6:	00151793          	slli	a5,a0,0x1
    80005ffa:	97aa                	add	a5,a5,a0
    80005ffc:	00c79713          	slli	a4,a5,0xc
    80006000:	0001e797          	auipc	a5,0x1e
    80006004:	00078793          	mv	a5,a5
    80006008:	97ba                	add	a5,a5,a4
    8000600a:	97ae                	add	a5,a5,a1
    8000600c:	6709                	lui	a4,0x2
    8000600e:	97ba                	add	a5,a5,a4
    80006010:	0187c783          	lbu	a5,24(a5) # 80024018 <disk+0x18>
    80006014:	e3a5                	bnez	a5,80006074 <free_desc+0x8c>
    panic("virtio_disk_intr 2");
  disk[n].desc[i].addr = 0;
    80006016:	0001e817          	auipc	a6,0x1e
    8000601a:	fea80813          	addi	a6,a6,-22 # 80024000 <disk>
    8000601e:	00151693          	slli	a3,a0,0x1
    80006022:	00a68733          	add	a4,a3,a0
    80006026:	0732                	slli	a4,a4,0xc
    80006028:	00e807b3          	add	a5,a6,a4
    8000602c:	6709                	lui	a4,0x2
    8000602e:	00f70633          	add	a2,a4,a5
    80006032:	6210                	ld	a2,0(a2)
    80006034:	00459893          	slli	a7,a1,0x4
    80006038:	9646                	add	a2,a2,a7
    8000603a:	00063023          	sd	zero,0(a2) # 1000 <_entry-0x7ffff000>
  disk[n].free[i] = 1;
    8000603e:	97ae                	add	a5,a5,a1
    80006040:	97ba                	add	a5,a5,a4
    80006042:	4605                	li	a2,1
    80006044:	00c78c23          	sb	a2,24(a5)
  wakeup(&disk[n].free[0]);
    80006048:	96aa                	add	a3,a3,a0
    8000604a:	06b2                	slli	a3,a3,0xc
    8000604c:	0761                	addi	a4,a4,24
    8000604e:	96ba                	add	a3,a3,a4
    80006050:	00d80533          	add	a0,a6,a3
    80006054:	ffffc097          	auipc	ra,0xffffc
    80006058:	2ea080e7          	jalr	746(ra) # 8000233e <wakeup>
}
    8000605c:	60a2                	ld	ra,8(sp)
    8000605e:	6402                	ld	s0,0(sp)
    80006060:	0141                	addi	sp,sp,16
    80006062:	8082                	ret
    panic("virtio_disk_intr 1");
    80006064:	00002517          	auipc	a0,0x2
    80006068:	77c50513          	addi	a0,a0,1916 # 800087e0 <userret+0x750>
    8000606c:	ffffa097          	auipc	ra,0xffffa
    80006070:	4dc080e7          	jalr	1244(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80006074:	00002517          	auipc	a0,0x2
    80006078:	78450513          	addi	a0,a0,1924 # 800087f8 <userret+0x768>
    8000607c:	ffffa097          	auipc	ra,0xffffa
    80006080:	4cc080e7          	jalr	1228(ra) # 80000548 <panic>

0000000080006084 <virtio_disk_init>:
  __sync_synchronize();
    80006084:	0ff0000f          	fence
  if(disk[n].init)
    80006088:	00151793          	slli	a5,a0,0x1
    8000608c:	97aa                	add	a5,a5,a0
    8000608e:	07b2                	slli	a5,a5,0xc
    80006090:	0001e717          	auipc	a4,0x1e
    80006094:	f7070713          	addi	a4,a4,-144 # 80024000 <disk>
    80006098:	973e                	add	a4,a4,a5
    8000609a:	6789                	lui	a5,0x2
    8000609c:	97ba                	add	a5,a5,a4
    8000609e:	0a87a783          	lw	a5,168(a5) # 20a8 <_entry-0x7fffdf58>
    800060a2:	c391                	beqz	a5,800060a6 <virtio_disk_init+0x22>
    800060a4:	8082                	ret
{
    800060a6:	7139                	addi	sp,sp,-64
    800060a8:	fc06                	sd	ra,56(sp)
    800060aa:	f822                	sd	s0,48(sp)
    800060ac:	f426                	sd	s1,40(sp)
    800060ae:	f04a                	sd	s2,32(sp)
    800060b0:	ec4e                	sd	s3,24(sp)
    800060b2:	e852                	sd	s4,16(sp)
    800060b4:	e456                	sd	s5,8(sp)
    800060b6:	0080                	addi	s0,sp,64
    800060b8:	84aa                	mv	s1,a0
  printf("virtio disk init %d\n", n);
    800060ba:	85aa                	mv	a1,a0
    800060bc:	00002517          	auipc	a0,0x2
    800060c0:	75450513          	addi	a0,a0,1876 # 80008810 <userret+0x780>
    800060c4:	ffffa097          	auipc	ra,0xffffa
    800060c8:	4ce080e7          	jalr	1230(ra) # 80000592 <printf>
  initlock(&disk[n].vdisk_lock, "virtio_disk");
    800060cc:	00149993          	slli	s3,s1,0x1
    800060d0:	99a6                	add	s3,s3,s1
    800060d2:	09b2                	slli	s3,s3,0xc
    800060d4:	6789                	lui	a5,0x2
    800060d6:	0b078793          	addi	a5,a5,176 # 20b0 <_entry-0x7fffdf50>
    800060da:	97ce                	add	a5,a5,s3
    800060dc:	00002597          	auipc	a1,0x2
    800060e0:	74c58593          	addi	a1,a1,1868 # 80008828 <userret+0x798>
    800060e4:	0001e517          	auipc	a0,0x1e
    800060e8:	f1c50513          	addi	a0,a0,-228 # 80024000 <disk>
    800060ec:	953e                	add	a0,a0,a5
    800060ee:	ffffb097          	auipc	ra,0xffffb
    800060f2:	8c2080e7          	jalr	-1854(ra) # 800009b0 <initlock>
  if(*R(n, VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060f6:	0014891b          	addiw	s2,s1,1
    800060fa:	00c9191b          	slliw	s2,s2,0xc
    800060fe:	100007b7          	lui	a5,0x10000
    80006102:	97ca                	add	a5,a5,s2
    80006104:	4398                	lw	a4,0(a5)
    80006106:	2701                	sext.w	a4,a4
    80006108:	747277b7          	lui	a5,0x74727
    8000610c:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006110:	12f71663          	bne	a4,a5,8000623c <virtio_disk_init+0x1b8>
     *R(n, VIRTIO_MMIO_VERSION) != 1 ||
    80006114:	100007b7          	lui	a5,0x10000
    80006118:	0791                	addi	a5,a5,4
    8000611a:	97ca                	add	a5,a5,s2
    8000611c:	439c                	lw	a5,0(a5)
    8000611e:	2781                	sext.w	a5,a5
  if(*R(n, VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006120:	4705                	li	a4,1
    80006122:	10e79d63          	bne	a5,a4,8000623c <virtio_disk_init+0x1b8>
     *R(n, VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006126:	100007b7          	lui	a5,0x10000
    8000612a:	07a1                	addi	a5,a5,8
    8000612c:	97ca                	add	a5,a5,s2
    8000612e:	439c                	lw	a5,0(a5)
    80006130:	2781                	sext.w	a5,a5
     *R(n, VIRTIO_MMIO_VERSION) != 1 ||
    80006132:	4709                	li	a4,2
    80006134:	10e79463          	bne	a5,a4,8000623c <virtio_disk_init+0x1b8>
     *R(n, VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006138:	100007b7          	lui	a5,0x10000
    8000613c:	07b1                	addi	a5,a5,12
    8000613e:	97ca                	add	a5,a5,s2
    80006140:	4398                	lw	a4,0(a5)
    80006142:	2701                	sext.w	a4,a4
     *R(n, VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006144:	554d47b7          	lui	a5,0x554d4
    80006148:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000614c:	0ef71863          	bne	a4,a5,8000623c <virtio_disk_init+0x1b8>
  *R(n, VIRTIO_MMIO_STATUS) = status;
    80006150:	100007b7          	lui	a5,0x10000
    80006154:	07078693          	addi	a3,a5,112 # 10000070 <_entry-0x6fffff90>
    80006158:	96ca                	add	a3,a3,s2
    8000615a:	4705                	li	a4,1
    8000615c:	c298                	sw	a4,0(a3)
  *R(n, VIRTIO_MMIO_STATUS) = status;
    8000615e:	470d                	li	a4,3
    80006160:	c298                	sw	a4,0(a3)
  uint64 features = *R(n, VIRTIO_MMIO_DEVICE_FEATURES);
    80006162:	01078713          	addi	a4,a5,16
    80006166:	974a                	add	a4,a4,s2
    80006168:	430c                	lw	a1,0(a4)
  *R(n, VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000616a:	02078613          	addi	a2,a5,32
    8000616e:	964a                	add	a2,a2,s2
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006170:	c7ffe737          	lui	a4,0xc7ffe
    80006174:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd4703>
    80006178:	8f6d                	and	a4,a4,a1
  *R(n, VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000617a:	2701                	sext.w	a4,a4
    8000617c:	c218                	sw	a4,0(a2)
  *R(n, VIRTIO_MMIO_STATUS) = status;
    8000617e:	472d                	li	a4,11
    80006180:	c298                	sw	a4,0(a3)
  *R(n, VIRTIO_MMIO_STATUS) = status;
    80006182:	473d                	li	a4,15
    80006184:	c298                	sw	a4,0(a3)
  *R(n, VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006186:	02878713          	addi	a4,a5,40
    8000618a:	974a                	add	a4,a4,s2
    8000618c:	6685                	lui	a3,0x1
    8000618e:	c314                	sw	a3,0(a4)
  *R(n, VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006190:	03078713          	addi	a4,a5,48
    80006194:	974a                	add	a4,a4,s2
    80006196:	00072023          	sw	zero,0(a4)
  uint32 max = *R(n, VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000619a:	03478793          	addi	a5,a5,52
    8000619e:	97ca                	add	a5,a5,s2
    800061a0:	439c                	lw	a5,0(a5)
    800061a2:	2781                	sext.w	a5,a5
  if(max == 0)
    800061a4:	c7c5                	beqz	a5,8000624c <virtio_disk_init+0x1c8>
  if(max < NUM)
    800061a6:	471d                	li	a4,7
    800061a8:	0af77a63          	bgeu	a4,a5,8000625c <virtio_disk_init+0x1d8>
  *R(n, VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800061ac:	10000ab7          	lui	s5,0x10000
    800061b0:	038a8793          	addi	a5,s5,56 # 10000038 <_entry-0x6fffffc8>
    800061b4:	97ca                	add	a5,a5,s2
    800061b6:	4721                	li	a4,8
    800061b8:	c398                	sw	a4,0(a5)
  memset(disk[n].pages, 0, sizeof(disk[n].pages));
    800061ba:	0001ea17          	auipc	s4,0x1e
    800061be:	e46a0a13          	addi	s4,s4,-442 # 80024000 <disk>
    800061c2:	99d2                	add	s3,s3,s4
    800061c4:	6609                	lui	a2,0x2
    800061c6:	4581                	li	a1,0
    800061c8:	854e                	mv	a0,s3
    800061ca:	ffffb097          	auipc	ra,0xffffb
    800061ce:	9b8080e7          	jalr	-1608(ra) # 80000b82 <memset>
  *R(n, VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk[n].pages) >> PGSHIFT;
    800061d2:	040a8a93          	addi	s5,s5,64
    800061d6:	9956                	add	s2,s2,s5
    800061d8:	00c9d793          	srli	a5,s3,0xc
    800061dc:	2781                	sext.w	a5,a5
    800061de:	00f92023          	sw	a5,0(s2)
  disk[n].desc = (struct VRingDesc *) disk[n].pages;
    800061e2:	00149693          	slli	a3,s1,0x1
    800061e6:	009687b3          	add	a5,a3,s1
    800061ea:	07b2                	slli	a5,a5,0xc
    800061ec:	97d2                	add	a5,a5,s4
    800061ee:	6609                	lui	a2,0x2
    800061f0:	97b2                	add	a5,a5,a2
    800061f2:	0137b023          	sd	s3,0(a5)
  disk[n].avail = (uint16*)(((char*)disk[n].desc) + NUM*sizeof(struct VRingDesc));
    800061f6:	08098713          	addi	a4,s3,128
    800061fa:	e798                	sd	a4,8(a5)
  disk[n].used = (struct UsedArea *) (disk[n].pages + PGSIZE);
    800061fc:	6705                	lui	a4,0x1
    800061fe:	99ba                	add	s3,s3,a4
    80006200:	0137b823          	sd	s3,16(a5)
    disk[n].free[i] = 1;
    80006204:	4705                	li	a4,1
    80006206:	00e78c23          	sb	a4,24(a5)
    8000620a:	00e78ca3          	sb	a4,25(a5)
    8000620e:	00e78d23          	sb	a4,26(a5)
    80006212:	00e78da3          	sb	a4,27(a5)
    80006216:	00e78e23          	sb	a4,28(a5)
    8000621a:	00e78ea3          	sb	a4,29(a5)
    8000621e:	00e78f23          	sb	a4,30(a5)
    80006222:	00e78fa3          	sb	a4,31(a5)
  disk[n].init = 1;
    80006226:	0ae7a423          	sw	a4,168(a5)
}
    8000622a:	70e2                	ld	ra,56(sp)
    8000622c:	7442                	ld	s0,48(sp)
    8000622e:	74a2                	ld	s1,40(sp)
    80006230:	7902                	ld	s2,32(sp)
    80006232:	69e2                	ld	s3,24(sp)
    80006234:	6a42                	ld	s4,16(sp)
    80006236:	6aa2                	ld	s5,8(sp)
    80006238:	6121                	addi	sp,sp,64
    8000623a:	8082                	ret
    panic("could not find virtio disk");
    8000623c:	00002517          	auipc	a0,0x2
    80006240:	5fc50513          	addi	a0,a0,1532 # 80008838 <userret+0x7a8>
    80006244:	ffffa097          	auipc	ra,0xffffa
    80006248:	304080e7          	jalr	772(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    8000624c:	00002517          	auipc	a0,0x2
    80006250:	60c50513          	addi	a0,a0,1548 # 80008858 <userret+0x7c8>
    80006254:	ffffa097          	auipc	ra,0xffffa
    80006258:	2f4080e7          	jalr	756(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    8000625c:	00002517          	auipc	a0,0x2
    80006260:	61c50513          	addi	a0,a0,1564 # 80008878 <userret+0x7e8>
    80006264:	ffffa097          	auipc	ra,0xffffa
    80006268:	2e4080e7          	jalr	740(ra) # 80000548 <panic>

000000008000626c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(int n, struct buf *b, int write)
{
    8000626c:	7135                	addi	sp,sp,-160
    8000626e:	ed06                	sd	ra,152(sp)
    80006270:	e922                	sd	s0,144(sp)
    80006272:	e526                	sd	s1,136(sp)
    80006274:	e14a                	sd	s2,128(sp)
    80006276:	fcce                	sd	s3,120(sp)
    80006278:	f8d2                	sd	s4,112(sp)
    8000627a:	f4d6                	sd	s5,104(sp)
    8000627c:	f0da                	sd	s6,96(sp)
    8000627e:	ecde                	sd	s7,88(sp)
    80006280:	e8e2                	sd	s8,80(sp)
    80006282:	e4e6                	sd	s9,72(sp)
    80006284:	e0ea                	sd	s10,64(sp)
    80006286:	fc6e                	sd	s11,56(sp)
    80006288:	1100                	addi	s0,sp,160
    8000628a:	8aaa                	mv	s5,a0
    8000628c:	8c2e                	mv	s8,a1
    8000628e:	8db2                	mv	s11,a2
  uint64 sector = b->blockno * (BSIZE / 512);
    80006290:	45dc                	lw	a5,12(a1)
    80006292:	0017979b          	slliw	a5,a5,0x1
    80006296:	1782                	slli	a5,a5,0x20
    80006298:	9381                	srli	a5,a5,0x20
    8000629a:	f6f43423          	sd	a5,-152(s0)

  acquire(&disk[n].vdisk_lock);
    8000629e:	00151493          	slli	s1,a0,0x1
    800062a2:	94aa                	add	s1,s1,a0
    800062a4:	04b2                	slli	s1,s1,0xc
    800062a6:	6909                	lui	s2,0x2
    800062a8:	0b090c93          	addi	s9,s2,176 # 20b0 <_entry-0x7fffdf50>
    800062ac:	9ca6                	add	s9,s9,s1
    800062ae:	0001e997          	auipc	s3,0x1e
    800062b2:	d5298993          	addi	s3,s3,-686 # 80024000 <disk>
    800062b6:	9cce                	add	s9,s9,s3
    800062b8:	8566                	mv	a0,s9
    800062ba:	ffffb097          	auipc	ra,0xffffb
    800062be:	804080e7          	jalr	-2044(ra) # 80000abe <acquire>
  int idx[3];
  while(1){
    if(alloc3_desc(n, idx) == 0) {
      break;
    }
    sleep(&disk[n].free[0], &disk[n].vdisk_lock);
    800062c2:	0961                	addi	s2,s2,24
    800062c4:	94ca                	add	s1,s1,s2
    800062c6:	99a6                	add	s3,s3,s1
  for(int i = 0; i < 3; i++){
    800062c8:	4a01                	li	s4,0
  for(int i = 0; i < NUM; i++){
    800062ca:	44a1                	li	s1,8
      disk[n].free[i] = 0;
    800062cc:	001a9793          	slli	a5,s5,0x1
    800062d0:	97d6                	add	a5,a5,s5
    800062d2:	07b2                	slli	a5,a5,0xc
    800062d4:	0001eb97          	auipc	s7,0x1e
    800062d8:	d2cb8b93          	addi	s7,s7,-724 # 80024000 <disk>
    800062dc:	9bbe                	add	s7,s7,a5
    800062de:	a8a9                	j	80006338 <virtio_disk_rw+0xcc>
    800062e0:	00fb8733          	add	a4,s7,a5
    800062e4:	9742                	add	a4,a4,a6
    800062e6:	00070c23          	sb	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    idx[i] = alloc_desc(n);
    800062ea:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800062ec:	0207c263          	bltz	a5,80006310 <virtio_disk_rw+0xa4>
  for(int i = 0; i < 3; i++){
    800062f0:	2905                	addiw	s2,s2,1
    800062f2:	0611                	addi	a2,a2,4
    800062f4:	1ca90463          	beq	s2,a0,800064bc <virtio_disk_rw+0x250>
    idx[i] = alloc_desc(n);
    800062f8:	85b2                	mv	a1,a2
    800062fa:	874e                	mv	a4,s3
  for(int i = 0; i < NUM; i++){
    800062fc:	87d2                	mv	a5,s4
    if(disk[n].free[i]){
    800062fe:	00074683          	lbu	a3,0(a4)
    80006302:	fef9                	bnez	a3,800062e0 <virtio_disk_rw+0x74>
  for(int i = 0; i < NUM; i++){
    80006304:	2785                	addiw	a5,a5,1
    80006306:	0705                	addi	a4,a4,1
    80006308:	fe979be3          	bne	a5,s1,800062fe <virtio_disk_rw+0x92>
    idx[i] = alloc_desc(n);
    8000630c:	57fd                	li	a5,-1
    8000630e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006310:	01205e63          	blez	s2,8000632c <virtio_disk_rw+0xc0>
    80006314:	8d52                	mv	s10,s4
        free_desc(n, idx[j]);
    80006316:	000b2583          	lw	a1,0(s6)
    8000631a:	8556                	mv	a0,s5
    8000631c:	00000097          	auipc	ra,0x0
    80006320:	ccc080e7          	jalr	-820(ra) # 80005fe8 <free_desc>
      for(int j = 0; j < i; j++)
    80006324:	2d05                	addiw	s10,s10,1
    80006326:	0b11                	addi	s6,s6,4
    80006328:	ffa917e3          	bne	s2,s10,80006316 <virtio_disk_rw+0xaa>
    sleep(&disk[n].free[0], &disk[n].vdisk_lock);
    8000632c:	85e6                	mv	a1,s9
    8000632e:	854e                	mv	a0,s3
    80006330:	ffffc097          	auipc	ra,0xffffc
    80006334:	e8e080e7          	jalr	-370(ra) # 800021be <sleep>
  for(int i = 0; i < 3; i++){
    80006338:	f8040b13          	addi	s6,s0,-128
{
    8000633c:	865a                	mv	a2,s6
  for(int i = 0; i < 3; i++){
    8000633e:	8952                	mv	s2,s4
      disk[n].free[i] = 0;
    80006340:	6809                	lui	a6,0x2
  for(int i = 0; i < 3; i++){
    80006342:	450d                	li	a0,3
    80006344:	bf55                	j	800062f8 <virtio_disk_rw+0x8c>
  disk[n].desc[idx[0]].next = idx[1];

  disk[n].desc[idx[1]].addr = (uint64) b->data;
  disk[n].desc[idx[1]].len = BSIZE;
  if(write)
    disk[n].desc[idx[1]].flags = 0; // device reads b->data
    80006346:	001a9793          	slli	a5,s5,0x1
    8000634a:	97d6                	add	a5,a5,s5
    8000634c:	07b2                	slli	a5,a5,0xc
    8000634e:	0001e717          	auipc	a4,0x1e
    80006352:	cb270713          	addi	a4,a4,-846 # 80024000 <disk>
    80006356:	973e                	add	a4,a4,a5
    80006358:	6789                	lui	a5,0x2
    8000635a:	97ba                	add	a5,a5,a4
    8000635c:	639c                	ld	a5,0(a5)
    8000635e:	97b6                	add	a5,a5,a3
    80006360:	00079623          	sh	zero,12(a5) # 200c <_entry-0x7fffdff4>
  else
    disk[n].desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk[n].desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006364:	0001e517          	auipc	a0,0x1e
    80006368:	c9c50513          	addi	a0,a0,-868 # 80024000 <disk>
    8000636c:	001a9793          	slli	a5,s5,0x1
    80006370:	01578733          	add	a4,a5,s5
    80006374:	0732                	slli	a4,a4,0xc
    80006376:	972a                	add	a4,a4,a0
    80006378:	6609                	lui	a2,0x2
    8000637a:	9732                	add	a4,a4,a2
    8000637c:	6310                	ld	a2,0(a4)
    8000637e:	9636                	add	a2,a2,a3
    80006380:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006384:	0015e593          	ori	a1,a1,1
    80006388:	00b61623          	sh	a1,12(a2)
  disk[n].desc[idx[1]].next = idx[2];
    8000638c:	f8842603          	lw	a2,-120(s0)
    80006390:	630c                	ld	a1,0(a4)
    80006392:	96ae                	add	a3,a3,a1
    80006394:	00c69723          	sh	a2,14(a3) # 100e <_entry-0x7fffeff2>

  disk[n].info[idx[0]].status = 0;
    80006398:	97d6                	add	a5,a5,s5
    8000639a:	07a2                	slli	a5,a5,0x8
    8000639c:	97a6                	add	a5,a5,s1
    8000639e:	20078793          	addi	a5,a5,512
    800063a2:	0792                	slli	a5,a5,0x4
    800063a4:	97aa                	add	a5,a5,a0
    800063a6:	02078823          	sb	zero,48(a5)
  disk[n].desc[idx[2]].addr = (uint64) &disk[n].info[idx[0]].status;
    800063aa:	00461693          	slli	a3,a2,0x4
    800063ae:	00073803          	ld	a6,0(a4)
    800063b2:	9836                	add	a6,a6,a3
    800063b4:	20348613          	addi	a2,s1,515
    800063b8:	001a9593          	slli	a1,s5,0x1
    800063bc:	95d6                	add	a1,a1,s5
    800063be:	05a2                	slli	a1,a1,0x8
    800063c0:	962e                	add	a2,a2,a1
    800063c2:	0612                	slli	a2,a2,0x4
    800063c4:	962a                	add	a2,a2,a0
    800063c6:	00c83023          	sd	a2,0(a6) # 2000 <_entry-0x7fffe000>
  disk[n].desc[idx[2]].len = 1;
    800063ca:	630c                	ld	a1,0(a4)
    800063cc:	95b6                	add	a1,a1,a3
    800063ce:	4605                	li	a2,1
    800063d0:	c590                	sw	a2,8(a1)
  disk[n].desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800063d2:	630c                	ld	a1,0(a4)
    800063d4:	95b6                	add	a1,a1,a3
    800063d6:	4509                	li	a0,2
    800063d8:	00a59623          	sh	a0,12(a1)
  disk[n].desc[idx[2]].next = 0;
    800063dc:	630c                	ld	a1,0(a4)
    800063de:	96ae                	add	a3,a3,a1
    800063e0:	00069723          	sh	zero,14(a3)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800063e4:	00cc2223          	sw	a2,4(s8) # fffffffffffff004 <end+0xffffffff7ffd4fa8>
  disk[n].info[idx[0]].b = b;
    800063e8:	0387b423          	sd	s8,40(a5)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk[n].avail[2 + (disk[n].avail[1] % NUM)] = idx[0];
    800063ec:	6714                	ld	a3,8(a4)
    800063ee:	0026d783          	lhu	a5,2(a3)
    800063f2:	8b9d                	andi	a5,a5,7
    800063f4:	0789                	addi	a5,a5,2
    800063f6:	0786                	slli	a5,a5,0x1
    800063f8:	97b6                	add	a5,a5,a3
    800063fa:	00979023          	sh	s1,0(a5)
  __sync_synchronize();
    800063fe:	0ff0000f          	fence
  disk[n].avail[1] = disk[n].avail[1] + 1;
    80006402:	6718                	ld	a4,8(a4)
    80006404:	00275783          	lhu	a5,2(a4)
    80006408:	2785                	addiw	a5,a5,1
    8000640a:	00f71123          	sh	a5,2(a4)

  *R(n, VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000640e:	001a879b          	addiw	a5,s5,1
    80006412:	00c7979b          	slliw	a5,a5,0xc
    80006416:	10000737          	lui	a4,0x10000
    8000641a:	05070713          	addi	a4,a4,80 # 10000050 <_entry-0x6fffffb0>
    8000641e:	97ba                	add	a5,a5,a4
    80006420:	0007a023          	sw	zero,0(a5)

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006424:	004c2783          	lw	a5,4(s8)
    80006428:	00c79d63          	bne	a5,a2,80006442 <virtio_disk_rw+0x1d6>
    8000642c:	4485                	li	s1,1
    sleep(b, &disk[n].vdisk_lock);
    8000642e:	85e6                	mv	a1,s9
    80006430:	8562                	mv	a0,s8
    80006432:	ffffc097          	auipc	ra,0xffffc
    80006436:	d8c080e7          	jalr	-628(ra) # 800021be <sleep>
  while(b->disk == 1) {
    8000643a:	004c2783          	lw	a5,4(s8)
    8000643e:	fe9788e3          	beq	a5,s1,8000642e <virtio_disk_rw+0x1c2>
  }

  disk[n].info[idx[0]].b = 0;
    80006442:	f8042483          	lw	s1,-128(s0)
    80006446:	001a9793          	slli	a5,s5,0x1
    8000644a:	97d6                	add	a5,a5,s5
    8000644c:	07a2                	slli	a5,a5,0x8
    8000644e:	97a6                	add	a5,a5,s1
    80006450:	20078793          	addi	a5,a5,512
    80006454:	0792                	slli	a5,a5,0x4
    80006456:	0001e717          	auipc	a4,0x1e
    8000645a:	baa70713          	addi	a4,a4,-1110 # 80024000 <disk>
    8000645e:	97ba                	add	a5,a5,a4
    80006460:	0207b423          	sd	zero,40(a5)
    if(disk[n].desc[i].flags & VRING_DESC_F_NEXT)
    80006464:	001a9793          	slli	a5,s5,0x1
    80006468:	97d6                	add	a5,a5,s5
    8000646a:	07b2                	slli	a5,a5,0xc
    8000646c:	97ba                	add	a5,a5,a4
    8000646e:	6909                	lui	s2,0x2
    80006470:	993e                	add	s2,s2,a5
    80006472:	a019                	j	80006478 <virtio_disk_rw+0x20c>
      i = disk[n].desc[i].next;
    80006474:	00e4d483          	lhu	s1,14(s1)
    free_desc(n, i);
    80006478:	85a6                	mv	a1,s1
    8000647a:	8556                	mv	a0,s5
    8000647c:	00000097          	auipc	ra,0x0
    80006480:	b6c080e7          	jalr	-1172(ra) # 80005fe8 <free_desc>
    if(disk[n].desc[i].flags & VRING_DESC_F_NEXT)
    80006484:	0492                	slli	s1,s1,0x4
    80006486:	00093783          	ld	a5,0(s2) # 2000 <_entry-0x7fffe000>
    8000648a:	94be                	add	s1,s1,a5
    8000648c:	00c4d783          	lhu	a5,12(s1)
    80006490:	8b85                	andi	a5,a5,1
    80006492:	f3ed                	bnez	a5,80006474 <virtio_disk_rw+0x208>
  free_chain(n, idx[0]);

  release(&disk[n].vdisk_lock);
    80006494:	8566                	mv	a0,s9
    80006496:	ffffa097          	auipc	ra,0xffffa
    8000649a:	690080e7          	jalr	1680(ra) # 80000b26 <release>
}
    8000649e:	60ea                	ld	ra,152(sp)
    800064a0:	644a                	ld	s0,144(sp)
    800064a2:	64aa                	ld	s1,136(sp)
    800064a4:	690a                	ld	s2,128(sp)
    800064a6:	79e6                	ld	s3,120(sp)
    800064a8:	7a46                	ld	s4,112(sp)
    800064aa:	7aa6                	ld	s5,104(sp)
    800064ac:	7b06                	ld	s6,96(sp)
    800064ae:	6be6                	ld	s7,88(sp)
    800064b0:	6c46                	ld	s8,80(sp)
    800064b2:	6ca6                	ld	s9,72(sp)
    800064b4:	6d06                	ld	s10,64(sp)
    800064b6:	7de2                	ld	s11,56(sp)
    800064b8:	610d                	addi	sp,sp,160
    800064ba:	8082                	ret
  if(write)
    800064bc:	01b037b3          	snez	a5,s11
    800064c0:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    800064c4:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    800064c8:	f6843783          	ld	a5,-152(s0)
    800064cc:	f6f43c23          	sd	a5,-136(s0)
  disk[n].desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    800064d0:	f8042483          	lw	s1,-128(s0)
    800064d4:	00449993          	slli	s3,s1,0x4
    800064d8:	001a9793          	slli	a5,s5,0x1
    800064dc:	97d6                	add	a5,a5,s5
    800064de:	07b2                	slli	a5,a5,0xc
    800064e0:	0001e917          	auipc	s2,0x1e
    800064e4:	b2090913          	addi	s2,s2,-1248 # 80024000 <disk>
    800064e8:	97ca                	add	a5,a5,s2
    800064ea:	6909                	lui	s2,0x2
    800064ec:	993e                	add	s2,s2,a5
    800064ee:	00093a03          	ld	s4,0(s2) # 2000 <_entry-0x7fffe000>
    800064f2:	9a4e                	add	s4,s4,s3
    800064f4:	f7040513          	addi	a0,s0,-144
    800064f8:	ffffb097          	auipc	ra,0xffffb
    800064fc:	ac6080e7          	jalr	-1338(ra) # 80000fbe <kvmpa>
    80006500:	00aa3023          	sd	a0,0(s4)
  disk[n].desc[idx[0]].len = sizeof(buf0);
    80006504:	00093783          	ld	a5,0(s2)
    80006508:	97ce                	add	a5,a5,s3
    8000650a:	4741                	li	a4,16
    8000650c:	c798                	sw	a4,8(a5)
  disk[n].desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000650e:	00093783          	ld	a5,0(s2)
    80006512:	97ce                	add	a5,a5,s3
    80006514:	4705                	li	a4,1
    80006516:	00e79623          	sh	a4,12(a5)
  disk[n].desc[idx[0]].next = idx[1];
    8000651a:	f8442683          	lw	a3,-124(s0)
    8000651e:	00093783          	ld	a5,0(s2)
    80006522:	99be                	add	s3,s3,a5
    80006524:	00d99723          	sh	a3,14(s3)
  disk[n].desc[idx[1]].addr = (uint64) b->data;
    80006528:	0692                	slli	a3,a3,0x4
    8000652a:	00093783          	ld	a5,0(s2)
    8000652e:	97b6                	add	a5,a5,a3
    80006530:	060c0713          	addi	a4,s8,96
    80006534:	e398                	sd	a4,0(a5)
  disk[n].desc[idx[1]].len = BSIZE;
    80006536:	00093783          	ld	a5,0(s2)
    8000653a:	97b6                	add	a5,a5,a3
    8000653c:	40000713          	li	a4,1024
    80006540:	c798                	sw	a4,8(a5)
  if(write)
    80006542:	e00d92e3          	bnez	s11,80006346 <virtio_disk_rw+0xda>
    disk[n].desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006546:	001a9793          	slli	a5,s5,0x1
    8000654a:	97d6                	add	a5,a5,s5
    8000654c:	07b2                	slli	a5,a5,0xc
    8000654e:	0001e717          	auipc	a4,0x1e
    80006552:	ab270713          	addi	a4,a4,-1358 # 80024000 <disk>
    80006556:	973e                	add	a4,a4,a5
    80006558:	6789                	lui	a5,0x2
    8000655a:	97ba                	add	a5,a5,a4
    8000655c:	639c                	ld	a5,0(a5)
    8000655e:	97b6                	add	a5,a5,a3
    80006560:	4709                	li	a4,2
    80006562:	00e79623          	sh	a4,12(a5) # 200c <_entry-0x7fffdff4>
    80006566:	bbfd                	j	80006364 <virtio_disk_rw+0xf8>

0000000080006568 <virtio_disk_intr>:

void
virtio_disk_intr(int n)
{
    80006568:	7139                	addi	sp,sp,-64
    8000656a:	fc06                	sd	ra,56(sp)
    8000656c:	f822                	sd	s0,48(sp)
    8000656e:	f426                	sd	s1,40(sp)
    80006570:	f04a                	sd	s2,32(sp)
    80006572:	ec4e                	sd	s3,24(sp)
    80006574:	e852                	sd	s4,16(sp)
    80006576:	e456                	sd	s5,8(sp)
    80006578:	0080                	addi	s0,sp,64
    8000657a:	84aa                	mv	s1,a0
  acquire(&disk[n].vdisk_lock);
    8000657c:	00151913          	slli	s2,a0,0x1
    80006580:	00a90a33          	add	s4,s2,a0
    80006584:	0a32                	slli	s4,s4,0xc
    80006586:	6989                	lui	s3,0x2
    80006588:	0b098793          	addi	a5,s3,176 # 20b0 <_entry-0x7fffdf50>
    8000658c:	9a3e                	add	s4,s4,a5
    8000658e:	0001ea97          	auipc	s5,0x1e
    80006592:	a72a8a93          	addi	s5,s5,-1422 # 80024000 <disk>
    80006596:	9a56                	add	s4,s4,s5
    80006598:	8552                	mv	a0,s4
    8000659a:	ffffa097          	auipc	ra,0xffffa
    8000659e:	524080e7          	jalr	1316(ra) # 80000abe <acquire>

  while((disk[n].used_idx % NUM) != (disk[n].used->id % NUM)){
    800065a2:	9926                	add	s2,s2,s1
    800065a4:	0932                	slli	s2,s2,0xc
    800065a6:	9956                	add	s2,s2,s5
    800065a8:	99ca                	add	s3,s3,s2
    800065aa:	0209d783          	lhu	a5,32(s3)
    800065ae:	0109b703          	ld	a4,16(s3)
    800065b2:	00275683          	lhu	a3,2(a4)
    800065b6:	8ebd                	xor	a3,a3,a5
    800065b8:	8a9d                	andi	a3,a3,7
    800065ba:	c2a5                	beqz	a3,8000661a <virtio_disk_intr+0xb2>
    int id = disk[n].used->elems[disk[n].used_idx].id;

    if(disk[n].info[id].status != 0)
    800065bc:	8956                	mv	s2,s5
    800065be:	00149693          	slli	a3,s1,0x1
    800065c2:	96a6                	add	a3,a3,s1
    800065c4:	00869993          	slli	s3,a3,0x8
      panic("virtio_disk_intr status");
    
    disk[n].info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk[n].info[id].b);

    disk[n].used_idx = (disk[n].used_idx + 1) % NUM;
    800065c8:	06b2                	slli	a3,a3,0xc
    800065ca:	96d6                	add	a3,a3,s5
    800065cc:	6489                	lui	s1,0x2
    800065ce:	94b6                	add	s1,s1,a3
    int id = disk[n].used->elems[disk[n].used_idx].id;
    800065d0:	078e                	slli	a5,a5,0x3
    800065d2:	97ba                	add	a5,a5,a4
    800065d4:	43dc                	lw	a5,4(a5)
    if(disk[n].info[id].status != 0)
    800065d6:	00f98733          	add	a4,s3,a5
    800065da:	20070713          	addi	a4,a4,512
    800065de:	0712                	slli	a4,a4,0x4
    800065e0:	974a                	add	a4,a4,s2
    800065e2:	03074703          	lbu	a4,48(a4)
    800065e6:	eb21                	bnez	a4,80006636 <virtio_disk_intr+0xce>
    disk[n].info[id].b->disk = 0;   // disk is done with buf
    800065e8:	97ce                	add	a5,a5,s3
    800065ea:	20078793          	addi	a5,a5,512
    800065ee:	0792                	slli	a5,a5,0x4
    800065f0:	97ca                	add	a5,a5,s2
    800065f2:	7798                	ld	a4,40(a5)
    800065f4:	00072223          	sw	zero,4(a4)
    wakeup(disk[n].info[id].b);
    800065f8:	7788                	ld	a0,40(a5)
    800065fa:	ffffc097          	auipc	ra,0xffffc
    800065fe:	d44080e7          	jalr	-700(ra) # 8000233e <wakeup>
    disk[n].used_idx = (disk[n].used_idx + 1) % NUM;
    80006602:	0204d783          	lhu	a5,32(s1) # 2020 <_entry-0x7fffdfe0>
    80006606:	2785                	addiw	a5,a5,1
    80006608:	8b9d                	andi	a5,a5,7
    8000660a:	02f49023          	sh	a5,32(s1)
  while((disk[n].used_idx % NUM) != (disk[n].used->id % NUM)){
    8000660e:	6898                	ld	a4,16(s1)
    80006610:	00275683          	lhu	a3,2(a4)
    80006614:	8a9d                	andi	a3,a3,7
    80006616:	faf69de3          	bne	a3,a5,800065d0 <virtio_disk_intr+0x68>
  }

  release(&disk[n].vdisk_lock);
    8000661a:	8552                	mv	a0,s4
    8000661c:	ffffa097          	auipc	ra,0xffffa
    80006620:	50a080e7          	jalr	1290(ra) # 80000b26 <release>
}
    80006624:	70e2                	ld	ra,56(sp)
    80006626:	7442                	ld	s0,48(sp)
    80006628:	74a2                	ld	s1,40(sp)
    8000662a:	7902                	ld	s2,32(sp)
    8000662c:	69e2                	ld	s3,24(sp)
    8000662e:	6a42                	ld	s4,16(sp)
    80006630:	6aa2                	ld	s5,8(sp)
    80006632:	6121                	addi	sp,sp,64
    80006634:	8082                	ret
      panic("virtio_disk_intr status");
    80006636:	00002517          	auipc	a0,0x2
    8000663a:	26250513          	addi	a0,a0,610 # 80008898 <userret+0x808>
    8000663e:	ffffa097          	auipc	ra,0xffffa
    80006642:	f0a080e7          	jalr	-246(ra) # 80000548 <panic>

0000000080006646 <bit_isset>:
static Sz_info *bd_sizes; 
static void *bd_base;   // start address of memory managed by the buddy allocator
static struct spinlock lock;

// Return 1 if bit at position index in array is set to 1
int bit_isset(char *array, int index) {
    80006646:	1141                	addi	sp,sp,-16
    80006648:	e422                	sd	s0,8(sp)
    8000664a:	0800                	addi	s0,sp,16
  char b = array[index/8];
  char m = (1 << (index % 8));
    8000664c:	41f5d79b          	sraiw	a5,a1,0x1f
    80006650:	01d7d79b          	srliw	a5,a5,0x1d
    80006654:	9dbd                	addw	a1,a1,a5
    80006656:	0075f713          	andi	a4,a1,7
    8000665a:	9f1d                	subw	a4,a4,a5
    8000665c:	4785                	li	a5,1
    8000665e:	00e797bb          	sllw	a5,a5,a4
    80006662:	0ff7f793          	andi	a5,a5,255
  char b = array[index/8];
    80006666:	4035d59b          	sraiw	a1,a1,0x3
    8000666a:	95aa                	add	a1,a1,a0
  return (b & m) == m;
    8000666c:	0005c503          	lbu	a0,0(a1)
    80006670:	8d7d                	and	a0,a0,a5
    80006672:	8d1d                	sub	a0,a0,a5
}
    80006674:	00153513          	seqz	a0,a0
    80006678:	6422                	ld	s0,8(sp)
    8000667a:	0141                	addi	sp,sp,16
    8000667c:	8082                	ret

000000008000667e <bit_set>:

// Set bit at position index in array to 1
void bit_set(char *array, int index) {
    8000667e:	1141                	addi	sp,sp,-16
    80006680:	e422                	sd	s0,8(sp)
    80006682:	0800                	addi	s0,sp,16
  char b = array[index/8];
    80006684:	41f5d79b          	sraiw	a5,a1,0x1f
    80006688:	01d7d79b          	srliw	a5,a5,0x1d
    8000668c:	9dbd                	addw	a1,a1,a5
    8000668e:	4035d71b          	sraiw	a4,a1,0x3
    80006692:	953a                	add	a0,a0,a4
  char m = (1 << (index % 8));
    80006694:	899d                	andi	a1,a1,7
    80006696:	9d9d                	subw	a1,a1,a5
    80006698:	4785                	li	a5,1
    8000669a:	00b795bb          	sllw	a1,a5,a1
  array[index/8] = (b | m);
    8000669e:	00054783          	lbu	a5,0(a0)
    800066a2:	8ddd                	or	a1,a1,a5
    800066a4:	00b50023          	sb	a1,0(a0)
}
    800066a8:	6422                	ld	s0,8(sp)
    800066aa:	0141                	addi	sp,sp,16
    800066ac:	8082                	ret

00000000800066ae <bit_clear>:

// Clear bit at position index in array
void bit_clear(char *array, int index) {
    800066ae:	1141                	addi	sp,sp,-16
    800066b0:	e422                	sd	s0,8(sp)
    800066b2:	0800                	addi	s0,sp,16
  char b = array[index/8];
    800066b4:	41f5d79b          	sraiw	a5,a1,0x1f
    800066b8:	01d7d79b          	srliw	a5,a5,0x1d
    800066bc:	9dbd                	addw	a1,a1,a5
    800066be:	4035d71b          	sraiw	a4,a1,0x3
    800066c2:	953a                	add	a0,a0,a4
  char m = (1 << (index % 8));
    800066c4:	899d                	andi	a1,a1,7
    800066c6:	9d9d                	subw	a1,a1,a5
    800066c8:	4785                	li	a5,1
    800066ca:	00b795bb          	sllw	a1,a5,a1
  array[index/8] = (b & ~m);
    800066ce:	fff5c593          	not	a1,a1
    800066d2:	00054783          	lbu	a5,0(a0)
    800066d6:	8dfd                	and	a1,a1,a5
    800066d8:	00b50023          	sb	a1,0(a0)
}
    800066dc:	6422                	ld	s0,8(sp)
    800066de:	0141                	addi	sp,sp,16
    800066e0:	8082                	ret

00000000800066e2 <bd_print_vector>:

// Print a bit vector as a list of ranges of 1 bits
void
bd_print_vector(char *vector, int len) {
    800066e2:	715d                	addi	sp,sp,-80
    800066e4:	e486                	sd	ra,72(sp)
    800066e6:	e0a2                	sd	s0,64(sp)
    800066e8:	fc26                	sd	s1,56(sp)
    800066ea:	f84a                	sd	s2,48(sp)
    800066ec:	f44e                	sd	s3,40(sp)
    800066ee:	f052                	sd	s4,32(sp)
    800066f0:	ec56                	sd	s5,24(sp)
    800066f2:	e85a                	sd	s6,16(sp)
    800066f4:	e45e                	sd	s7,8(sp)
    800066f6:	0880                	addi	s0,sp,80
    800066f8:	8a2e                	mv	s4,a1
  int last, lb;
  
  last = 1;
  lb = 0;
  for (int b = 0; b < len; b++) {
    800066fa:	08b05b63          	blez	a1,80006790 <bd_print_vector+0xae>
    800066fe:	89aa                	mv	s3,a0
    80006700:	4481                	li	s1,0
  lb = 0;
    80006702:	4a81                	li	s5,0
  last = 1;
    80006704:	4905                	li	s2,1
    if (last == bit_isset(vector, b))
      continue;
    if(last == 1)
    80006706:	4b05                	li	s6,1
      printf(" [%d, %d)", lb, b);
    80006708:	00002b97          	auipc	s7,0x2
    8000670c:	1a8b8b93          	addi	s7,s7,424 # 800088b0 <userret+0x820>
    80006710:	a821                	j	80006728 <bd_print_vector+0x46>
    lb = b;
    last = bit_isset(vector, b);
    80006712:	85a6                	mv	a1,s1
    80006714:	854e                	mv	a0,s3
    80006716:	00000097          	auipc	ra,0x0
    8000671a:	f30080e7          	jalr	-208(ra) # 80006646 <bit_isset>
    8000671e:	892a                	mv	s2,a0
    80006720:	8aa6                	mv	s5,s1
  for (int b = 0; b < len; b++) {
    80006722:	2485                	addiw	s1,s1,1
    80006724:	029a0463          	beq	s4,s1,8000674c <bd_print_vector+0x6a>
    if (last == bit_isset(vector, b))
    80006728:	85a6                	mv	a1,s1
    8000672a:	854e                	mv	a0,s3
    8000672c:	00000097          	auipc	ra,0x0
    80006730:	f1a080e7          	jalr	-230(ra) # 80006646 <bit_isset>
    80006734:	ff2507e3          	beq	a0,s2,80006722 <bd_print_vector+0x40>
    if(last == 1)
    80006738:	fd691de3          	bne	s2,s6,80006712 <bd_print_vector+0x30>
      printf(" [%d, %d)", lb, b);
    8000673c:	8626                	mv	a2,s1
    8000673e:	85d6                	mv	a1,s5
    80006740:	855e                	mv	a0,s7
    80006742:	ffffa097          	auipc	ra,0xffffa
    80006746:	e50080e7          	jalr	-432(ra) # 80000592 <printf>
    8000674a:	b7e1                	j	80006712 <bd_print_vector+0x30>
  }
  if(lb == 0 || last == 1) {
    8000674c:	000a8563          	beqz	s5,80006756 <bd_print_vector+0x74>
    80006750:	4785                	li	a5,1
    80006752:	00f91c63          	bne	s2,a5,8000676a <bd_print_vector+0x88>
    printf(" [%d, %d)", lb, len);
    80006756:	8652                	mv	a2,s4
    80006758:	85d6                	mv	a1,s5
    8000675a:	00002517          	auipc	a0,0x2
    8000675e:	15650513          	addi	a0,a0,342 # 800088b0 <userret+0x820>
    80006762:	ffffa097          	auipc	ra,0xffffa
    80006766:	e30080e7          	jalr	-464(ra) # 80000592 <printf>
  }
  printf("\n");
    8000676a:	00002517          	auipc	a0,0x2
    8000676e:	a4650513          	addi	a0,a0,-1466 # 800081b0 <userret+0x120>
    80006772:	ffffa097          	auipc	ra,0xffffa
    80006776:	e20080e7          	jalr	-480(ra) # 80000592 <printf>
}
    8000677a:	60a6                	ld	ra,72(sp)
    8000677c:	6406                	ld	s0,64(sp)
    8000677e:	74e2                	ld	s1,56(sp)
    80006780:	7942                	ld	s2,48(sp)
    80006782:	79a2                	ld	s3,40(sp)
    80006784:	7a02                	ld	s4,32(sp)
    80006786:	6ae2                	ld	s5,24(sp)
    80006788:	6b42                	ld	s6,16(sp)
    8000678a:	6ba2                	ld	s7,8(sp)
    8000678c:	6161                	addi	sp,sp,80
    8000678e:	8082                	ret
  lb = 0;
    80006790:	4a81                	li	s5,0
    80006792:	b7d1                	j	80006756 <bd_print_vector+0x74>

0000000080006794 <bd_print>:

// Print buddy's data structures
void
bd_print() {
  for (int k = 0; k < nsizes; k++) {
    80006794:	00024697          	auipc	a3,0x24
    80006798:	8c46a683          	lw	a3,-1852(a3) # 8002a058 <nsizes>
    8000679c:	10d05063          	blez	a3,8000689c <bd_print+0x108>
bd_print() {
    800067a0:	711d                	addi	sp,sp,-96
    800067a2:	ec86                	sd	ra,88(sp)
    800067a4:	e8a2                	sd	s0,80(sp)
    800067a6:	e4a6                	sd	s1,72(sp)
    800067a8:	e0ca                	sd	s2,64(sp)
    800067aa:	fc4e                	sd	s3,56(sp)
    800067ac:	f852                	sd	s4,48(sp)
    800067ae:	f456                	sd	s5,40(sp)
    800067b0:	f05a                	sd	s6,32(sp)
    800067b2:	ec5e                	sd	s7,24(sp)
    800067b4:	e862                	sd	s8,16(sp)
    800067b6:	e466                	sd	s9,8(sp)
    800067b8:	e06a                	sd	s10,0(sp)
    800067ba:	1080                	addi	s0,sp,96
  for (int k = 0; k < nsizes; k++) {
    800067bc:	4481                	li	s1,0
    printf("size %d (blksz %d nblk %d): free list: ", k, BLK_SIZE(k), NBLK(k));
    800067be:	4a85                	li	s5,1
    800067c0:	4c41                	li	s8,16
    800067c2:	00002b97          	auipc	s7,0x2
    800067c6:	0feb8b93          	addi	s7,s7,254 # 800088c0 <userret+0x830>
    lst_print(&bd_sizes[k].free);
    800067ca:	00024a17          	auipc	s4,0x24
    800067ce:	886a0a13          	addi	s4,s4,-1914 # 8002a050 <bd_sizes>
    printf("  alloc:");
    800067d2:	00002b17          	auipc	s6,0x2
    800067d6:	116b0b13          	addi	s6,s6,278 # 800088e8 <userret+0x858>
    bd_print_vector(bd_sizes[k].alloc, NBLK(k));
    800067da:	00024997          	auipc	s3,0x24
    800067de:	87e98993          	addi	s3,s3,-1922 # 8002a058 <nsizes>
    if(k > 0) {
      printf("  split:");
    800067e2:	00002c97          	auipc	s9,0x2
    800067e6:	116c8c93          	addi	s9,s9,278 # 800088f8 <userret+0x868>
    800067ea:	a801                	j	800067fa <bd_print+0x66>
  for (int k = 0; k < nsizes; k++) {
    800067ec:	0009a683          	lw	a3,0(s3)
    800067f0:	0485                	addi	s1,s1,1
    800067f2:	0004879b          	sext.w	a5,s1
    800067f6:	08d7d563          	bge	a5,a3,80006880 <bd_print+0xec>
    800067fa:	0004891b          	sext.w	s2,s1
    printf("size %d (blksz %d nblk %d): free list: ", k, BLK_SIZE(k), NBLK(k));
    800067fe:	36fd                	addiw	a3,a3,-1
    80006800:	9e85                	subw	a3,a3,s1
    80006802:	00da96bb          	sllw	a3,s5,a3
    80006806:	009c1633          	sll	a2,s8,s1
    8000680a:	85ca                	mv	a1,s2
    8000680c:	855e                	mv	a0,s7
    8000680e:	ffffa097          	auipc	ra,0xffffa
    80006812:	d84080e7          	jalr	-636(ra) # 80000592 <printf>
    lst_print(&bd_sizes[k].free);
    80006816:	00549d13          	slli	s10,s1,0x5
    8000681a:	000a3503          	ld	a0,0(s4)
    8000681e:	956a                	add	a0,a0,s10
    80006820:	00001097          	auipc	ra,0x1
    80006824:	a56080e7          	jalr	-1450(ra) # 80007276 <lst_print>
    printf("  alloc:");
    80006828:	855a                	mv	a0,s6
    8000682a:	ffffa097          	auipc	ra,0xffffa
    8000682e:	d68080e7          	jalr	-664(ra) # 80000592 <printf>
    bd_print_vector(bd_sizes[k].alloc, NBLK(k));
    80006832:	0009a583          	lw	a1,0(s3)
    80006836:	35fd                	addiw	a1,a1,-1
    80006838:	412585bb          	subw	a1,a1,s2
    8000683c:	000a3783          	ld	a5,0(s4)
    80006840:	97ea                	add	a5,a5,s10
    80006842:	00ba95bb          	sllw	a1,s5,a1
    80006846:	6b88                	ld	a0,16(a5)
    80006848:	00000097          	auipc	ra,0x0
    8000684c:	e9a080e7          	jalr	-358(ra) # 800066e2 <bd_print_vector>
    if(k > 0) {
    80006850:	f9205ee3          	blez	s2,800067ec <bd_print+0x58>
      printf("  split:");
    80006854:	8566                	mv	a0,s9
    80006856:	ffffa097          	auipc	ra,0xffffa
    8000685a:	d3c080e7          	jalr	-708(ra) # 80000592 <printf>
      bd_print_vector(bd_sizes[k].split, NBLK(k));
    8000685e:	0009a583          	lw	a1,0(s3)
    80006862:	35fd                	addiw	a1,a1,-1
    80006864:	412585bb          	subw	a1,a1,s2
    80006868:	000a3783          	ld	a5,0(s4)
    8000686c:	9d3e                	add	s10,s10,a5
    8000686e:	00ba95bb          	sllw	a1,s5,a1
    80006872:	018d3503          	ld	a0,24(s10)
    80006876:	00000097          	auipc	ra,0x0
    8000687a:	e6c080e7          	jalr	-404(ra) # 800066e2 <bd_print_vector>
    8000687e:	b7bd                	j	800067ec <bd_print+0x58>
    }
  }
}
    80006880:	60e6                	ld	ra,88(sp)
    80006882:	6446                	ld	s0,80(sp)
    80006884:	64a6                	ld	s1,72(sp)
    80006886:	6906                	ld	s2,64(sp)
    80006888:	79e2                	ld	s3,56(sp)
    8000688a:	7a42                	ld	s4,48(sp)
    8000688c:	7aa2                	ld	s5,40(sp)
    8000688e:	7b02                	ld	s6,32(sp)
    80006890:	6be2                	ld	s7,24(sp)
    80006892:	6c42                	ld	s8,16(sp)
    80006894:	6ca2                	ld	s9,8(sp)
    80006896:	6d02                	ld	s10,0(sp)
    80006898:	6125                	addi	sp,sp,96
    8000689a:	8082                	ret
    8000689c:	8082                	ret

000000008000689e <firstk>:

// What is the first k such that 2^k >= n?
int
firstk(uint64 n) {
    8000689e:	1141                	addi	sp,sp,-16
    800068a0:	e422                	sd	s0,8(sp)
    800068a2:	0800                	addi	s0,sp,16
  int k = 0;
  uint64 size = LEAF_SIZE;

  while (size < n) {
    800068a4:	47c1                	li	a5,16
    800068a6:	00a7fb63          	bgeu	a5,a0,800068bc <firstk+0x1e>
    800068aa:	872a                	mv	a4,a0
  int k = 0;
    800068ac:	4501                	li	a0,0
    k++;
    800068ae:	2505                	addiw	a0,a0,1
    size *= 2;
    800068b0:	0786                	slli	a5,a5,0x1
  while (size < n) {
    800068b2:	fee7eee3          	bltu	a5,a4,800068ae <firstk+0x10>
  }
  return k;
}
    800068b6:	6422                	ld	s0,8(sp)
    800068b8:	0141                	addi	sp,sp,16
    800068ba:	8082                	ret
  int k = 0;
    800068bc:	4501                	li	a0,0
    800068be:	bfe5                	j	800068b6 <firstk+0x18>

00000000800068c0 <blk_index>:

// Compute the block index for address p at size k
int
blk_index(int k, char *p) {
    800068c0:	1141                	addi	sp,sp,-16
    800068c2:	e422                	sd	s0,8(sp)
    800068c4:	0800                	addi	s0,sp,16
  int n = p - (char *) bd_base;
  return n / BLK_SIZE(k);
    800068c6:	00023797          	auipc	a5,0x23
    800068ca:	7827b783          	ld	a5,1922(a5) # 8002a048 <bd_base>
    800068ce:	9d9d                	subw	a1,a1,a5
    800068d0:	47c1                	li	a5,16
    800068d2:	00a797b3          	sll	a5,a5,a0
    800068d6:	02f5c5b3          	div	a1,a1,a5
}
    800068da:	0005851b          	sext.w	a0,a1
    800068de:	6422                	ld	s0,8(sp)
    800068e0:	0141                	addi	sp,sp,16
    800068e2:	8082                	ret

00000000800068e4 <addr>:

// Convert a block index at size k back into an address
void *addr(int k, int bi) {
    800068e4:	1141                	addi	sp,sp,-16
    800068e6:	e422                	sd	s0,8(sp)
    800068e8:	0800                	addi	s0,sp,16
  int n = bi * BLK_SIZE(k);
    800068ea:	47c1                	li	a5,16
    800068ec:	00a797b3          	sll	a5,a5,a0
  return (char *) bd_base + n;
    800068f0:	02b787bb          	mulw	a5,a5,a1
}
    800068f4:	00023517          	auipc	a0,0x23
    800068f8:	75453503          	ld	a0,1876(a0) # 8002a048 <bd_base>
    800068fc:	953e                	add	a0,a0,a5
    800068fe:	6422                	ld	s0,8(sp)
    80006900:	0141                	addi	sp,sp,16
    80006902:	8082                	ret

0000000080006904 <bd_malloc>:

// allocate nbytes, but malloc won't return anything smaller than LEAF_SIZE
void *
bd_malloc(uint64 nbytes)
{
    80006904:	7159                	addi	sp,sp,-112
    80006906:	f486                	sd	ra,104(sp)
    80006908:	f0a2                	sd	s0,96(sp)
    8000690a:	eca6                	sd	s1,88(sp)
    8000690c:	e8ca                	sd	s2,80(sp)
    8000690e:	e4ce                	sd	s3,72(sp)
    80006910:	e0d2                	sd	s4,64(sp)
    80006912:	fc56                	sd	s5,56(sp)
    80006914:	f85a                	sd	s6,48(sp)
    80006916:	f45e                	sd	s7,40(sp)
    80006918:	f062                	sd	s8,32(sp)
    8000691a:	ec66                	sd	s9,24(sp)
    8000691c:	e86a                	sd	s10,16(sp)
    8000691e:	e46e                	sd	s11,8(sp)
    80006920:	1880                	addi	s0,sp,112
    80006922:	84aa                	mv	s1,a0
  int fk, k;

  acquire(&lock);
    80006924:	00023517          	auipc	a0,0x23
    80006928:	6dc50513          	addi	a0,a0,1756 # 8002a000 <lock>
    8000692c:	ffffa097          	auipc	ra,0xffffa
    80006930:	192080e7          	jalr	402(ra) # 80000abe <acquire>

  // Find a free block >= nbytes, starting with smallest k possible
  fk = firstk(nbytes);
    80006934:	8526                	mv	a0,s1
    80006936:	00000097          	auipc	ra,0x0
    8000693a:	f68080e7          	jalr	-152(ra) # 8000689e <firstk>
  for (k = fk; k < nsizes; k++) {
    8000693e:	00023797          	auipc	a5,0x23
    80006942:	71a7a783          	lw	a5,1818(a5) # 8002a058 <nsizes>
    80006946:	02f55d63          	bge	a0,a5,80006980 <bd_malloc+0x7c>
    8000694a:	8c2a                	mv	s8,a0
    8000694c:	00551913          	slli	s2,a0,0x5
    80006950:	84aa                	mv	s1,a0
    if(!lst_empty(&bd_sizes[k].free))
    80006952:	00023997          	auipc	s3,0x23
    80006956:	6fe98993          	addi	s3,s3,1790 # 8002a050 <bd_sizes>
  for (k = fk; k < nsizes; k++) {
    8000695a:	00023a17          	auipc	s4,0x23
    8000695e:	6fea0a13          	addi	s4,s4,1790 # 8002a058 <nsizes>
    if(!lst_empty(&bd_sizes[k].free))
    80006962:	0009b503          	ld	a0,0(s3)
    80006966:	954a                	add	a0,a0,s2
    80006968:	00001097          	auipc	ra,0x1
    8000696c:	894080e7          	jalr	-1900(ra) # 800071fc <lst_empty>
    80006970:	c115                	beqz	a0,80006994 <bd_malloc+0x90>
  for (k = fk; k < nsizes; k++) {
    80006972:	2485                	addiw	s1,s1,1
    80006974:	02090913          	addi	s2,s2,32
    80006978:	000a2783          	lw	a5,0(s4)
    8000697c:	fef4c3e3          	blt	s1,a5,80006962 <bd_malloc+0x5e>
      break;
  }
  if(k >= nsizes) { // No free blocks?
    release(&lock);
    80006980:	00023517          	auipc	a0,0x23
    80006984:	68050513          	addi	a0,a0,1664 # 8002a000 <lock>
    80006988:	ffffa097          	auipc	ra,0xffffa
    8000698c:	19e080e7          	jalr	414(ra) # 80000b26 <release>
    return 0;
    80006990:	4b01                	li	s6,0
    80006992:	a0e1                	j	80006a5a <bd_malloc+0x156>
  if(k >= nsizes) { // No free blocks?
    80006994:	00023797          	auipc	a5,0x23
    80006998:	6c47a783          	lw	a5,1732(a5) # 8002a058 <nsizes>
    8000699c:	fef4d2e3          	bge	s1,a5,80006980 <bd_malloc+0x7c>
  }

  // Found a block; pop it and potentially split it.
  char *p = lst_pop(&bd_sizes[k].free);
    800069a0:	00549993          	slli	s3,s1,0x5
    800069a4:	00023917          	auipc	s2,0x23
    800069a8:	6ac90913          	addi	s2,s2,1708 # 8002a050 <bd_sizes>
    800069ac:	00093503          	ld	a0,0(s2)
    800069b0:	954e                	add	a0,a0,s3
    800069b2:	00001097          	auipc	ra,0x1
    800069b6:	876080e7          	jalr	-1930(ra) # 80007228 <lst_pop>
    800069ba:	8b2a                	mv	s6,a0
  return n / BLK_SIZE(k);
    800069bc:	00023597          	auipc	a1,0x23
    800069c0:	68c5b583          	ld	a1,1676(a1) # 8002a048 <bd_base>
    800069c4:	40b505bb          	subw	a1,a0,a1
    800069c8:	47c1                	li	a5,16
    800069ca:	009797b3          	sll	a5,a5,s1
    800069ce:	02f5c5b3          	div	a1,a1,a5
  bit_set(bd_sizes[k].alloc, blk_index(k, p));
    800069d2:	00093783          	ld	a5,0(s2)
    800069d6:	97ce                	add	a5,a5,s3
    800069d8:	2581                	sext.w	a1,a1
    800069da:	6b88                	ld	a0,16(a5)
    800069dc:	00000097          	auipc	ra,0x0
    800069e0:	ca2080e7          	jalr	-862(ra) # 8000667e <bit_set>
  for(; k > fk; k--) {
    800069e4:	069c5363          	bge	s8,s1,80006a4a <bd_malloc+0x146>
    // split a block at size k and mark one half allocated at size k-1
    // and put the buddy on the free list at size k-1
    char *q = p + BLK_SIZE(k-1);   // p's buddy
    800069e8:	4bc1                	li	s7,16
    bit_set(bd_sizes[k].split, blk_index(k, p));
    800069ea:	8dca                	mv	s11,s2
  int n = p - (char *) bd_base;
    800069ec:	00023d17          	auipc	s10,0x23
    800069f0:	65cd0d13          	addi	s10,s10,1628 # 8002a048 <bd_base>
    char *q = p + BLK_SIZE(k-1);   // p's buddy
    800069f4:	85a6                	mv	a1,s1
    800069f6:	34fd                	addiw	s1,s1,-1
    800069f8:	009b9ab3          	sll	s5,s7,s1
    800069fc:	015b0cb3          	add	s9,s6,s5
    bit_set(bd_sizes[k].split, blk_index(k, p));
    80006a00:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
  int n = p - (char *) bd_base;
    80006a04:	000d3903          	ld	s2,0(s10)
  return n / BLK_SIZE(k);
    80006a08:	412b093b          	subw	s2,s6,s2
    80006a0c:	00bb95b3          	sll	a1,s7,a1
    80006a10:	02b945b3          	div	a1,s2,a1
    bit_set(bd_sizes[k].split, blk_index(k, p));
    80006a14:	013a07b3          	add	a5,s4,s3
    80006a18:	2581                	sext.w	a1,a1
    80006a1a:	6f88                	ld	a0,24(a5)
    80006a1c:	00000097          	auipc	ra,0x0
    80006a20:	c62080e7          	jalr	-926(ra) # 8000667e <bit_set>
    bit_set(bd_sizes[k-1].alloc, blk_index(k-1, p));
    80006a24:	1981                	addi	s3,s3,-32
    80006a26:	9a4e                	add	s4,s4,s3
  return n / BLK_SIZE(k);
    80006a28:	035945b3          	div	a1,s2,s5
    bit_set(bd_sizes[k-1].alloc, blk_index(k-1, p));
    80006a2c:	2581                	sext.w	a1,a1
    80006a2e:	010a3503          	ld	a0,16(s4)
    80006a32:	00000097          	auipc	ra,0x0
    80006a36:	c4c080e7          	jalr	-948(ra) # 8000667e <bit_set>
    lst_push(&bd_sizes[k-1].free, q);
    80006a3a:	85e6                	mv	a1,s9
    80006a3c:	8552                	mv	a0,s4
    80006a3e:	00001097          	auipc	ra,0x1
    80006a42:	820080e7          	jalr	-2016(ra) # 8000725e <lst_push>
  for(; k > fk; k--) {
    80006a46:	fb8497e3          	bne	s1,s8,800069f4 <bd_malloc+0xf0>
  }
  release(&lock);
    80006a4a:	00023517          	auipc	a0,0x23
    80006a4e:	5b650513          	addi	a0,a0,1462 # 8002a000 <lock>
    80006a52:	ffffa097          	auipc	ra,0xffffa
    80006a56:	0d4080e7          	jalr	212(ra) # 80000b26 <release>

  return p;
}
    80006a5a:	855a                	mv	a0,s6
    80006a5c:	70a6                	ld	ra,104(sp)
    80006a5e:	7406                	ld	s0,96(sp)
    80006a60:	64e6                	ld	s1,88(sp)
    80006a62:	6946                	ld	s2,80(sp)
    80006a64:	69a6                	ld	s3,72(sp)
    80006a66:	6a06                	ld	s4,64(sp)
    80006a68:	7ae2                	ld	s5,56(sp)
    80006a6a:	7b42                	ld	s6,48(sp)
    80006a6c:	7ba2                	ld	s7,40(sp)
    80006a6e:	7c02                	ld	s8,32(sp)
    80006a70:	6ce2                	ld	s9,24(sp)
    80006a72:	6d42                	ld	s10,16(sp)
    80006a74:	6da2                	ld	s11,8(sp)
    80006a76:	6165                	addi	sp,sp,112
    80006a78:	8082                	ret

0000000080006a7a <size>:

// Find the size of the block that p points to.
int
size(char *p) {
    80006a7a:	7139                	addi	sp,sp,-64
    80006a7c:	fc06                	sd	ra,56(sp)
    80006a7e:	f822                	sd	s0,48(sp)
    80006a80:	f426                	sd	s1,40(sp)
    80006a82:	f04a                	sd	s2,32(sp)
    80006a84:	ec4e                	sd	s3,24(sp)
    80006a86:	e852                	sd	s4,16(sp)
    80006a88:	e456                	sd	s5,8(sp)
    80006a8a:	e05a                	sd	s6,0(sp)
    80006a8c:	0080                	addi	s0,sp,64
  for (int k = 0; k < nsizes; k++) {
    80006a8e:	00023a97          	auipc	s5,0x23
    80006a92:	5caaaa83          	lw	s5,1482(s5) # 8002a058 <nsizes>
  return n / BLK_SIZE(k);
    80006a96:	00023a17          	auipc	s4,0x23
    80006a9a:	5b2a3a03          	ld	s4,1458(s4) # 8002a048 <bd_base>
    80006a9e:	41450a3b          	subw	s4,a0,s4
    80006aa2:	00023497          	auipc	s1,0x23
    80006aa6:	5ae4b483          	ld	s1,1454(s1) # 8002a050 <bd_sizes>
    80006aaa:	03848493          	addi	s1,s1,56
  for (int k = 0; k < nsizes; k++) {
    80006aae:	4901                	li	s2,0
  return n / BLK_SIZE(k);
    80006ab0:	4b41                	li	s6,16
  for (int k = 0; k < nsizes; k++) {
    80006ab2:	03595363          	bge	s2,s5,80006ad8 <size+0x5e>
    if(bit_isset(bd_sizes[k+1].split, blk_index(k+1, p))) {
    80006ab6:	0019099b          	addiw	s3,s2,1
  return n / BLK_SIZE(k);
    80006aba:	013b15b3          	sll	a1,s6,s3
    80006abe:	02ba45b3          	div	a1,s4,a1
    if(bit_isset(bd_sizes[k+1].split, blk_index(k+1, p))) {
    80006ac2:	2581                	sext.w	a1,a1
    80006ac4:	6088                	ld	a0,0(s1)
    80006ac6:	00000097          	auipc	ra,0x0
    80006aca:	b80080e7          	jalr	-1152(ra) # 80006646 <bit_isset>
    80006ace:	02048493          	addi	s1,s1,32
    80006ad2:	e501                	bnez	a0,80006ada <size+0x60>
  for (int k = 0; k < nsizes; k++) {
    80006ad4:	894e                	mv	s2,s3
    80006ad6:	bff1                	j	80006ab2 <size+0x38>
      return k;
    }
  }
  return 0;
    80006ad8:	4901                	li	s2,0
}
    80006ada:	854a                	mv	a0,s2
    80006adc:	70e2                	ld	ra,56(sp)
    80006ade:	7442                	ld	s0,48(sp)
    80006ae0:	74a2                	ld	s1,40(sp)
    80006ae2:	7902                	ld	s2,32(sp)
    80006ae4:	69e2                	ld	s3,24(sp)
    80006ae6:	6a42                	ld	s4,16(sp)
    80006ae8:	6aa2                	ld	s5,8(sp)
    80006aea:	6b02                	ld	s6,0(sp)
    80006aec:	6121                	addi	sp,sp,64
    80006aee:	8082                	ret

0000000080006af0 <bd_free>:

// Free memory pointed to by p, which was earlier allocated using
// bd_malloc.
void
bd_free(void *p) {
    80006af0:	7159                	addi	sp,sp,-112
    80006af2:	f486                	sd	ra,104(sp)
    80006af4:	f0a2                	sd	s0,96(sp)
    80006af6:	eca6                	sd	s1,88(sp)
    80006af8:	e8ca                	sd	s2,80(sp)
    80006afa:	e4ce                	sd	s3,72(sp)
    80006afc:	e0d2                	sd	s4,64(sp)
    80006afe:	fc56                	sd	s5,56(sp)
    80006b00:	f85a                	sd	s6,48(sp)
    80006b02:	f45e                	sd	s7,40(sp)
    80006b04:	f062                	sd	s8,32(sp)
    80006b06:	ec66                	sd	s9,24(sp)
    80006b08:	e86a                	sd	s10,16(sp)
    80006b0a:	e46e                	sd	s11,8(sp)
    80006b0c:	1880                	addi	s0,sp,112
    80006b0e:	8aaa                	mv	s5,a0
  void *q;
  int k;

  acquire(&lock);
    80006b10:	00023517          	auipc	a0,0x23
    80006b14:	4f050513          	addi	a0,a0,1264 # 8002a000 <lock>
    80006b18:	ffffa097          	auipc	ra,0xffffa
    80006b1c:	fa6080e7          	jalr	-90(ra) # 80000abe <acquire>
  for (k = size(p); k < MAXSIZE; k++) {
    80006b20:	8556                	mv	a0,s5
    80006b22:	00000097          	auipc	ra,0x0
    80006b26:	f58080e7          	jalr	-168(ra) # 80006a7a <size>
    80006b2a:	84aa                	mv	s1,a0
    80006b2c:	00023797          	auipc	a5,0x23
    80006b30:	52c7a783          	lw	a5,1324(a5) # 8002a058 <nsizes>
    80006b34:	37fd                	addiw	a5,a5,-1
    80006b36:	0cf55063          	bge	a0,a5,80006bf6 <bd_free+0x106>
    80006b3a:	00150a13          	addi	s4,a0,1
    80006b3e:	0a16                	slli	s4,s4,0x5
  int n = p - (char *) bd_base;
    80006b40:	00023c17          	auipc	s8,0x23
    80006b44:	508c0c13          	addi	s8,s8,1288 # 8002a048 <bd_base>
  return n / BLK_SIZE(k);
    80006b48:	4bc1                	li	s7,16
    int bi = blk_index(k, p);
    int buddy = (bi % 2 == 0) ? bi+1 : bi-1;
    bit_clear(bd_sizes[k].alloc, bi);  // free p at size k
    80006b4a:	00023b17          	auipc	s6,0x23
    80006b4e:	506b0b13          	addi	s6,s6,1286 # 8002a050 <bd_sizes>
  for (k = size(p); k < MAXSIZE; k++) {
    80006b52:	00023c97          	auipc	s9,0x23
    80006b56:	506c8c93          	addi	s9,s9,1286 # 8002a058 <nsizes>
    80006b5a:	a82d                	j	80006b94 <bd_free+0xa4>
    int buddy = (bi % 2 == 0) ? bi+1 : bi-1;
    80006b5c:	fff58d9b          	addiw	s11,a1,-1
    80006b60:	a881                	j	80006bb0 <bd_free+0xc0>
    if(buddy % 2 == 0) {
      p = q;
    }
    // at size k+1, mark that the merged buddy pair isn't split
    // anymore
    bit_clear(bd_sizes[k+1].split, blk_index(k+1, p));
    80006b62:	2485                	addiw	s1,s1,1
  int n = p - (char *) bd_base;
    80006b64:	000c3583          	ld	a1,0(s8)
  return n / BLK_SIZE(k);
    80006b68:	40ba85bb          	subw	a1,s5,a1
    80006b6c:	009b97b3          	sll	a5,s7,s1
    80006b70:	02f5c5b3          	div	a1,a1,a5
    bit_clear(bd_sizes[k+1].split, blk_index(k+1, p));
    80006b74:	000b3783          	ld	a5,0(s6)
    80006b78:	97d2                	add	a5,a5,s4
    80006b7a:	2581                	sext.w	a1,a1
    80006b7c:	6f88                	ld	a0,24(a5)
    80006b7e:	00000097          	auipc	ra,0x0
    80006b82:	b30080e7          	jalr	-1232(ra) # 800066ae <bit_clear>
  for (k = size(p); k < MAXSIZE; k++) {
    80006b86:	020a0a13          	addi	s4,s4,32
    80006b8a:	000ca783          	lw	a5,0(s9)
    80006b8e:	37fd                	addiw	a5,a5,-1
    80006b90:	06f4d363          	bge	s1,a5,80006bf6 <bd_free+0x106>
  int n = p - (char *) bd_base;
    80006b94:	000c3903          	ld	s2,0(s8)
  return n / BLK_SIZE(k);
    80006b98:	009b99b3          	sll	s3,s7,s1
    80006b9c:	412a87bb          	subw	a5,s5,s2
    80006ba0:	0337c7b3          	div	a5,a5,s3
    80006ba4:	0007859b          	sext.w	a1,a5
    int buddy = (bi % 2 == 0) ? bi+1 : bi-1;
    80006ba8:	8b85                	andi	a5,a5,1
    80006baa:	fbcd                	bnez	a5,80006b5c <bd_free+0x6c>
    80006bac:	00158d9b          	addiw	s11,a1,1
    bit_clear(bd_sizes[k].alloc, bi);  // free p at size k
    80006bb0:	fe0a0d13          	addi	s10,s4,-32
    80006bb4:	000b3783          	ld	a5,0(s6)
    80006bb8:	9d3e                	add	s10,s10,a5
    80006bba:	010d3503          	ld	a0,16(s10)
    80006bbe:	00000097          	auipc	ra,0x0
    80006bc2:	af0080e7          	jalr	-1296(ra) # 800066ae <bit_clear>
    if (bit_isset(bd_sizes[k].alloc, buddy)) {  // is buddy allocated?
    80006bc6:	85ee                	mv	a1,s11
    80006bc8:	010d3503          	ld	a0,16(s10)
    80006bcc:	00000097          	auipc	ra,0x0
    80006bd0:	a7a080e7          	jalr	-1414(ra) # 80006646 <bit_isset>
    80006bd4:	e10d                	bnez	a0,80006bf6 <bd_free+0x106>
  int n = bi * BLK_SIZE(k);
    80006bd6:	000d8d1b          	sext.w	s10,s11
  return (char *) bd_base + n;
    80006bda:	03b989bb          	mulw	s3,s3,s11
    80006bde:	994e                	add	s2,s2,s3
    lst_remove(q);    // remove buddy from free list
    80006be0:	854a                	mv	a0,s2
    80006be2:	00000097          	auipc	ra,0x0
    80006be6:	630080e7          	jalr	1584(ra) # 80007212 <lst_remove>
    if(buddy % 2 == 0) {
    80006bea:	001d7d13          	andi	s10,s10,1
    80006bee:	f60d1ae3          	bnez	s10,80006b62 <bd_free+0x72>
      p = q;
    80006bf2:	8aca                	mv	s5,s2
    80006bf4:	b7bd                	j	80006b62 <bd_free+0x72>
  }
  lst_push(&bd_sizes[k].free, p);
    80006bf6:	0496                	slli	s1,s1,0x5
    80006bf8:	85d6                	mv	a1,s5
    80006bfa:	00023517          	auipc	a0,0x23
    80006bfe:	45653503          	ld	a0,1110(a0) # 8002a050 <bd_sizes>
    80006c02:	9526                	add	a0,a0,s1
    80006c04:	00000097          	auipc	ra,0x0
    80006c08:	65a080e7          	jalr	1626(ra) # 8000725e <lst_push>
  release(&lock);
    80006c0c:	00023517          	auipc	a0,0x23
    80006c10:	3f450513          	addi	a0,a0,1012 # 8002a000 <lock>
    80006c14:	ffffa097          	auipc	ra,0xffffa
    80006c18:	f12080e7          	jalr	-238(ra) # 80000b26 <release>
}
    80006c1c:	70a6                	ld	ra,104(sp)
    80006c1e:	7406                	ld	s0,96(sp)
    80006c20:	64e6                	ld	s1,88(sp)
    80006c22:	6946                	ld	s2,80(sp)
    80006c24:	69a6                	ld	s3,72(sp)
    80006c26:	6a06                	ld	s4,64(sp)
    80006c28:	7ae2                	ld	s5,56(sp)
    80006c2a:	7b42                	ld	s6,48(sp)
    80006c2c:	7ba2                	ld	s7,40(sp)
    80006c2e:	7c02                	ld	s8,32(sp)
    80006c30:	6ce2                	ld	s9,24(sp)
    80006c32:	6d42                	ld	s10,16(sp)
    80006c34:	6da2                	ld	s11,8(sp)
    80006c36:	6165                	addi	sp,sp,112
    80006c38:	8082                	ret

0000000080006c3a <blk_index_next>:

// Compute the first block at size k that doesn't contain p
int
blk_index_next(int k, char *p) {
    80006c3a:	1141                	addi	sp,sp,-16
    80006c3c:	e422                	sd	s0,8(sp)
    80006c3e:	0800                	addi	s0,sp,16
  int n = (p - (char *) bd_base) / BLK_SIZE(k);
    80006c40:	00023797          	auipc	a5,0x23
    80006c44:	4087b783          	ld	a5,1032(a5) # 8002a048 <bd_base>
    80006c48:	8d9d                	sub	a1,a1,a5
    80006c4a:	47c1                	li	a5,16
    80006c4c:	00a797b3          	sll	a5,a5,a0
    80006c50:	02f5c533          	div	a0,a1,a5
    80006c54:	2501                	sext.w	a0,a0
  if((p - (char*) bd_base) % BLK_SIZE(k) != 0)
    80006c56:	02f5e5b3          	rem	a1,a1,a5
    80006c5a:	c191                	beqz	a1,80006c5e <blk_index_next+0x24>
      n++;
    80006c5c:	2505                	addiw	a0,a0,1
  return n ;
}
    80006c5e:	6422                	ld	s0,8(sp)
    80006c60:	0141                	addi	sp,sp,16
    80006c62:	8082                	ret

0000000080006c64 <log2>:

int
log2(uint64 n) {
    80006c64:	1141                	addi	sp,sp,-16
    80006c66:	e422                	sd	s0,8(sp)
    80006c68:	0800                	addi	s0,sp,16
  int k = 0;
  while (n > 1) {
    80006c6a:	4705                	li	a4,1
    80006c6c:	00a77b63          	bgeu	a4,a0,80006c82 <log2+0x1e>
    80006c70:	87aa                	mv	a5,a0
  int k = 0;
    80006c72:	4501                	li	a0,0
    k++;
    80006c74:	2505                	addiw	a0,a0,1
    n = n >> 1;
    80006c76:	8385                	srli	a5,a5,0x1
  while (n > 1) {
    80006c78:	fef76ee3          	bltu	a4,a5,80006c74 <log2+0x10>
  }
  return k;
}
    80006c7c:	6422                	ld	s0,8(sp)
    80006c7e:	0141                	addi	sp,sp,16
    80006c80:	8082                	ret
  int k = 0;
    80006c82:	4501                	li	a0,0
    80006c84:	bfe5                	j	80006c7c <log2+0x18>

0000000080006c86 <bd_mark>:

// Mark memory from [start, stop), starting at size 0, as allocated. 
void
bd_mark(void *start, void *stop)
{
    80006c86:	711d                	addi	sp,sp,-96
    80006c88:	ec86                	sd	ra,88(sp)
    80006c8a:	e8a2                	sd	s0,80(sp)
    80006c8c:	e4a6                	sd	s1,72(sp)
    80006c8e:	e0ca                	sd	s2,64(sp)
    80006c90:	fc4e                	sd	s3,56(sp)
    80006c92:	f852                	sd	s4,48(sp)
    80006c94:	f456                	sd	s5,40(sp)
    80006c96:	f05a                	sd	s6,32(sp)
    80006c98:	ec5e                	sd	s7,24(sp)
    80006c9a:	e862                	sd	s8,16(sp)
    80006c9c:	e466                	sd	s9,8(sp)
    80006c9e:	e06a                	sd	s10,0(sp)
    80006ca0:	1080                	addi	s0,sp,96
  int bi, bj;

  if (((uint64) start % LEAF_SIZE != 0) || ((uint64) stop % LEAF_SIZE != 0))
    80006ca2:	00b56933          	or	s2,a0,a1
    80006ca6:	00f97913          	andi	s2,s2,15
    80006caa:	04091263          	bnez	s2,80006cee <bd_mark+0x68>
    80006cae:	8b2a                	mv	s6,a0
    80006cb0:	8bae                	mv	s7,a1
    panic("bd_mark");

  for (int k = 0; k < nsizes; k++) {
    80006cb2:	00023c17          	auipc	s8,0x23
    80006cb6:	3a6c2c03          	lw	s8,934(s8) # 8002a058 <nsizes>
    80006cba:	4981                	li	s3,0
  int n = p - (char *) bd_base;
    80006cbc:	00023d17          	auipc	s10,0x23
    80006cc0:	38cd0d13          	addi	s10,s10,908 # 8002a048 <bd_base>
  return n / BLK_SIZE(k);
    80006cc4:	4cc1                	li	s9,16
    bi = blk_index(k, start);
    bj = blk_index_next(k, stop);
    for(; bi < bj; bi++) {
      if(k > 0) {
        // if a block is allocated at size k, mark it as split too.
        bit_set(bd_sizes[k].split, bi);
    80006cc6:	00023a97          	auipc	s5,0x23
    80006cca:	38aa8a93          	addi	s5,s5,906 # 8002a050 <bd_sizes>
  for (int k = 0; k < nsizes; k++) {
    80006cce:	07804563          	bgtz	s8,80006d38 <bd_mark+0xb2>
      }
      bit_set(bd_sizes[k].alloc, bi);
    }
  }
}
    80006cd2:	60e6                	ld	ra,88(sp)
    80006cd4:	6446                	ld	s0,80(sp)
    80006cd6:	64a6                	ld	s1,72(sp)
    80006cd8:	6906                	ld	s2,64(sp)
    80006cda:	79e2                	ld	s3,56(sp)
    80006cdc:	7a42                	ld	s4,48(sp)
    80006cde:	7aa2                	ld	s5,40(sp)
    80006ce0:	7b02                	ld	s6,32(sp)
    80006ce2:	6be2                	ld	s7,24(sp)
    80006ce4:	6c42                	ld	s8,16(sp)
    80006ce6:	6ca2                	ld	s9,8(sp)
    80006ce8:	6d02                	ld	s10,0(sp)
    80006cea:	6125                	addi	sp,sp,96
    80006cec:	8082                	ret
    panic("bd_mark");
    80006cee:	00002517          	auipc	a0,0x2
    80006cf2:	c1a50513          	addi	a0,a0,-998 # 80008908 <userret+0x878>
    80006cf6:	ffffa097          	auipc	ra,0xffffa
    80006cfa:	852080e7          	jalr	-1966(ra) # 80000548 <panic>
      bit_set(bd_sizes[k].alloc, bi);
    80006cfe:	000ab783          	ld	a5,0(s5)
    80006d02:	97ca                	add	a5,a5,s2
    80006d04:	85a6                	mv	a1,s1
    80006d06:	6b88                	ld	a0,16(a5)
    80006d08:	00000097          	auipc	ra,0x0
    80006d0c:	976080e7          	jalr	-1674(ra) # 8000667e <bit_set>
    for(; bi < bj; bi++) {
    80006d10:	2485                	addiw	s1,s1,1
    80006d12:	009a0e63          	beq	s4,s1,80006d2e <bd_mark+0xa8>
      if(k > 0) {
    80006d16:	ff3054e3          	blez	s3,80006cfe <bd_mark+0x78>
        bit_set(bd_sizes[k].split, bi);
    80006d1a:	000ab783          	ld	a5,0(s5)
    80006d1e:	97ca                	add	a5,a5,s2
    80006d20:	85a6                	mv	a1,s1
    80006d22:	6f88                	ld	a0,24(a5)
    80006d24:	00000097          	auipc	ra,0x0
    80006d28:	95a080e7          	jalr	-1702(ra) # 8000667e <bit_set>
    80006d2c:	bfc9                	j	80006cfe <bd_mark+0x78>
  for (int k = 0; k < nsizes; k++) {
    80006d2e:	2985                	addiw	s3,s3,1
    80006d30:	02090913          	addi	s2,s2,32
    80006d34:	f9898fe3          	beq	s3,s8,80006cd2 <bd_mark+0x4c>
  int n = p - (char *) bd_base;
    80006d38:	000d3483          	ld	s1,0(s10)
  return n / BLK_SIZE(k);
    80006d3c:	409b04bb          	subw	s1,s6,s1
    80006d40:	013c97b3          	sll	a5,s9,s3
    80006d44:	02f4c4b3          	div	s1,s1,a5
    80006d48:	2481                	sext.w	s1,s1
    bj = blk_index_next(k, stop);
    80006d4a:	85de                	mv	a1,s7
    80006d4c:	854e                	mv	a0,s3
    80006d4e:	00000097          	auipc	ra,0x0
    80006d52:	eec080e7          	jalr	-276(ra) # 80006c3a <blk_index_next>
    80006d56:	8a2a                	mv	s4,a0
    for(; bi < bj; bi++) {
    80006d58:	faa4cfe3          	blt	s1,a0,80006d16 <bd_mark+0x90>
    80006d5c:	bfc9                	j	80006d2e <bd_mark+0xa8>

0000000080006d5e <bd_initfree_pair>:

// If a block is marked as allocated and the buddy is free, put the
// buddy on the free list at size k.
int
bd_initfree_pair(int k, int bi) {
    80006d5e:	7139                	addi	sp,sp,-64
    80006d60:	fc06                	sd	ra,56(sp)
    80006d62:	f822                	sd	s0,48(sp)
    80006d64:	f426                	sd	s1,40(sp)
    80006d66:	f04a                	sd	s2,32(sp)
    80006d68:	ec4e                	sd	s3,24(sp)
    80006d6a:	e852                	sd	s4,16(sp)
    80006d6c:	e456                	sd	s5,8(sp)
    80006d6e:	e05a                	sd	s6,0(sp)
    80006d70:	0080                	addi	s0,sp,64
    80006d72:	89aa                	mv	s3,a0
  int buddy = (bi % 2 == 0) ? bi+1 : bi-1;
    80006d74:	00058a9b          	sext.w	s5,a1
    80006d78:	0015f793          	andi	a5,a1,1
    80006d7c:	ebad                	bnez	a5,80006dee <bd_initfree_pair+0x90>
    80006d7e:	00158a1b          	addiw	s4,a1,1
  int free = 0;
  if(bit_isset(bd_sizes[k].alloc, bi) !=  bit_isset(bd_sizes[k].alloc, buddy)) {
    80006d82:	00599493          	slli	s1,s3,0x5
    80006d86:	00023797          	auipc	a5,0x23
    80006d8a:	2ca7b783          	ld	a5,714(a5) # 8002a050 <bd_sizes>
    80006d8e:	94be                	add	s1,s1,a5
    80006d90:	0104bb03          	ld	s6,16(s1)
    80006d94:	855a                	mv	a0,s6
    80006d96:	00000097          	auipc	ra,0x0
    80006d9a:	8b0080e7          	jalr	-1872(ra) # 80006646 <bit_isset>
    80006d9e:	892a                	mv	s2,a0
    80006da0:	85d2                	mv	a1,s4
    80006da2:	855a                	mv	a0,s6
    80006da4:	00000097          	auipc	ra,0x0
    80006da8:	8a2080e7          	jalr	-1886(ra) # 80006646 <bit_isset>
  int free = 0;
    80006dac:	4b01                	li	s6,0
  if(bit_isset(bd_sizes[k].alloc, bi) !=  bit_isset(bd_sizes[k].alloc, buddy)) {
    80006dae:	02a90563          	beq	s2,a0,80006dd8 <bd_initfree_pair+0x7a>
    // one of the pair is free
    free = BLK_SIZE(k);
    80006db2:	45c1                	li	a1,16
    80006db4:	013599b3          	sll	s3,a1,s3
    80006db8:	00098b1b          	sext.w	s6,s3
    if(bit_isset(bd_sizes[k].alloc, bi))
    80006dbc:	02090c63          	beqz	s2,80006df4 <bd_initfree_pair+0x96>
  return (char *) bd_base + n;
    80006dc0:	034989bb          	mulw	s3,s3,s4
      lst_push(&bd_sizes[k].free, addr(k, buddy));   // put buddy on free list
    80006dc4:	00023597          	auipc	a1,0x23
    80006dc8:	2845b583          	ld	a1,644(a1) # 8002a048 <bd_base>
    80006dcc:	95ce                	add	a1,a1,s3
    80006dce:	8526                	mv	a0,s1
    80006dd0:	00000097          	auipc	ra,0x0
    80006dd4:	48e080e7          	jalr	1166(ra) # 8000725e <lst_push>
    else
      lst_push(&bd_sizes[k].free, addr(k, bi));      // put bi on free list
  }
  return free;
}
    80006dd8:	855a                	mv	a0,s6
    80006dda:	70e2                	ld	ra,56(sp)
    80006ddc:	7442                	ld	s0,48(sp)
    80006dde:	74a2                	ld	s1,40(sp)
    80006de0:	7902                	ld	s2,32(sp)
    80006de2:	69e2                	ld	s3,24(sp)
    80006de4:	6a42                	ld	s4,16(sp)
    80006de6:	6aa2                	ld	s5,8(sp)
    80006de8:	6b02                	ld	s6,0(sp)
    80006dea:	6121                	addi	sp,sp,64
    80006dec:	8082                	ret
  int buddy = (bi % 2 == 0) ? bi+1 : bi-1;
    80006dee:	fff58a1b          	addiw	s4,a1,-1
    80006df2:	bf41                	j	80006d82 <bd_initfree_pair+0x24>
  return (char *) bd_base + n;
    80006df4:	035989bb          	mulw	s3,s3,s5
      lst_push(&bd_sizes[k].free, addr(k, bi));      // put bi on free list
    80006df8:	00023597          	auipc	a1,0x23
    80006dfc:	2505b583          	ld	a1,592(a1) # 8002a048 <bd_base>
    80006e00:	95ce                	add	a1,a1,s3
    80006e02:	8526                	mv	a0,s1
    80006e04:	00000097          	auipc	ra,0x0
    80006e08:	45a080e7          	jalr	1114(ra) # 8000725e <lst_push>
    80006e0c:	b7f1                	j	80006dd8 <bd_initfree_pair+0x7a>

0000000080006e0e <bd_initfree>:
  
// Initialize the free lists for each size k.  For each size k, there
// are only two pairs that may have a buddy that should be on free list:
// bd_left and bd_right.
int
bd_initfree(void *bd_left, void *bd_right) {
    80006e0e:	711d                	addi	sp,sp,-96
    80006e10:	ec86                	sd	ra,88(sp)
    80006e12:	e8a2                	sd	s0,80(sp)
    80006e14:	e4a6                	sd	s1,72(sp)
    80006e16:	e0ca                	sd	s2,64(sp)
    80006e18:	fc4e                	sd	s3,56(sp)
    80006e1a:	f852                	sd	s4,48(sp)
    80006e1c:	f456                	sd	s5,40(sp)
    80006e1e:	f05a                	sd	s6,32(sp)
    80006e20:	ec5e                	sd	s7,24(sp)
    80006e22:	e862                	sd	s8,16(sp)
    80006e24:	e466                	sd	s9,8(sp)
    80006e26:	e06a                	sd	s10,0(sp)
    80006e28:	1080                	addi	s0,sp,96
  int free = 0;

  for (int k = 0; k < MAXSIZE; k++) {   // skip max size
    80006e2a:	00023717          	auipc	a4,0x23
    80006e2e:	22e72703          	lw	a4,558(a4) # 8002a058 <nsizes>
    80006e32:	4785                	li	a5,1
    80006e34:	06e7db63          	bge	a5,a4,80006eaa <bd_initfree+0x9c>
    80006e38:	8aaa                	mv	s5,a0
    80006e3a:	8b2e                	mv	s6,a1
    80006e3c:	4901                	li	s2,0
  int free = 0;
    80006e3e:	4a01                	li	s4,0
  int n = p - (char *) bd_base;
    80006e40:	00023c97          	auipc	s9,0x23
    80006e44:	208c8c93          	addi	s9,s9,520 # 8002a048 <bd_base>
  return n / BLK_SIZE(k);
    80006e48:	4c41                	li	s8,16
  for (int k = 0; k < MAXSIZE; k++) {   // skip max size
    80006e4a:	00023b97          	auipc	s7,0x23
    80006e4e:	20eb8b93          	addi	s7,s7,526 # 8002a058 <nsizes>
    80006e52:	a039                	j	80006e60 <bd_initfree+0x52>
    80006e54:	2905                	addiw	s2,s2,1
    80006e56:	000ba783          	lw	a5,0(s7)
    80006e5a:	37fd                	addiw	a5,a5,-1
    80006e5c:	04f95863          	bge	s2,a5,80006eac <bd_initfree+0x9e>
    int left = blk_index_next(k, bd_left);
    80006e60:	85d6                	mv	a1,s5
    80006e62:	854a                	mv	a0,s2
    80006e64:	00000097          	auipc	ra,0x0
    80006e68:	dd6080e7          	jalr	-554(ra) # 80006c3a <blk_index_next>
    80006e6c:	89aa                	mv	s3,a0
  int n = p - (char *) bd_base;
    80006e6e:	000cb483          	ld	s1,0(s9)
  return n / BLK_SIZE(k);
    80006e72:	409b04bb          	subw	s1,s6,s1
    80006e76:	012c17b3          	sll	a5,s8,s2
    80006e7a:	02f4c4b3          	div	s1,s1,a5
    80006e7e:	2481                	sext.w	s1,s1
    int right = blk_index(k, bd_right);
    free += bd_initfree_pair(k, left);
    80006e80:	85aa                	mv	a1,a0
    80006e82:	854a                	mv	a0,s2
    80006e84:	00000097          	auipc	ra,0x0
    80006e88:	eda080e7          	jalr	-294(ra) # 80006d5e <bd_initfree_pair>
    80006e8c:	01450d3b          	addw	s10,a0,s4
    80006e90:	000d0a1b          	sext.w	s4,s10
    if(right <= left)
    80006e94:	fc99d0e3          	bge	s3,s1,80006e54 <bd_initfree+0x46>
      continue;
    free += bd_initfree_pair(k, right);
    80006e98:	85a6                	mv	a1,s1
    80006e9a:	854a                	mv	a0,s2
    80006e9c:	00000097          	auipc	ra,0x0
    80006ea0:	ec2080e7          	jalr	-318(ra) # 80006d5e <bd_initfree_pair>
    80006ea4:	00ad0a3b          	addw	s4,s10,a0
    80006ea8:	b775                	j	80006e54 <bd_initfree+0x46>
  int free = 0;
    80006eaa:	4a01                	li	s4,0
  }
  return free;
}
    80006eac:	8552                	mv	a0,s4
    80006eae:	60e6                	ld	ra,88(sp)
    80006eb0:	6446                	ld	s0,80(sp)
    80006eb2:	64a6                	ld	s1,72(sp)
    80006eb4:	6906                	ld	s2,64(sp)
    80006eb6:	79e2                	ld	s3,56(sp)
    80006eb8:	7a42                	ld	s4,48(sp)
    80006eba:	7aa2                	ld	s5,40(sp)
    80006ebc:	7b02                	ld	s6,32(sp)
    80006ebe:	6be2                	ld	s7,24(sp)
    80006ec0:	6c42                	ld	s8,16(sp)
    80006ec2:	6ca2                	ld	s9,8(sp)
    80006ec4:	6d02                	ld	s10,0(sp)
    80006ec6:	6125                	addi	sp,sp,96
    80006ec8:	8082                	ret

0000000080006eca <bd_mark_data_structures>:

// Mark the range [bd_base,p) as allocated
int
bd_mark_data_structures(char *p) {
    80006eca:	7179                	addi	sp,sp,-48
    80006ecc:	f406                	sd	ra,40(sp)
    80006ece:	f022                	sd	s0,32(sp)
    80006ed0:	ec26                	sd	s1,24(sp)
    80006ed2:	e84a                	sd	s2,16(sp)
    80006ed4:	e44e                	sd	s3,8(sp)
    80006ed6:	1800                	addi	s0,sp,48
    80006ed8:	892a                	mv	s2,a0
  int meta = p - (char*)bd_base;
    80006eda:	00023997          	auipc	s3,0x23
    80006ede:	16e98993          	addi	s3,s3,366 # 8002a048 <bd_base>
    80006ee2:	0009b483          	ld	s1,0(s3)
    80006ee6:	409504bb          	subw	s1,a0,s1
  printf("bd: %d meta bytes for managing %d bytes of memory\n", meta, BLK_SIZE(MAXSIZE));
    80006eea:	00023797          	auipc	a5,0x23
    80006eee:	16e7a783          	lw	a5,366(a5) # 8002a058 <nsizes>
    80006ef2:	37fd                	addiw	a5,a5,-1
    80006ef4:	4641                	li	a2,16
    80006ef6:	00f61633          	sll	a2,a2,a5
    80006efa:	85a6                	mv	a1,s1
    80006efc:	00002517          	auipc	a0,0x2
    80006f00:	a1450513          	addi	a0,a0,-1516 # 80008910 <userret+0x880>
    80006f04:	ffff9097          	auipc	ra,0xffff9
    80006f08:	68e080e7          	jalr	1678(ra) # 80000592 <printf>
  bd_mark(bd_base, p);
    80006f0c:	85ca                	mv	a1,s2
    80006f0e:	0009b503          	ld	a0,0(s3)
    80006f12:	00000097          	auipc	ra,0x0
    80006f16:	d74080e7          	jalr	-652(ra) # 80006c86 <bd_mark>
  return meta;
}
    80006f1a:	8526                	mv	a0,s1
    80006f1c:	70a2                	ld	ra,40(sp)
    80006f1e:	7402                	ld	s0,32(sp)
    80006f20:	64e2                	ld	s1,24(sp)
    80006f22:	6942                	ld	s2,16(sp)
    80006f24:	69a2                	ld	s3,8(sp)
    80006f26:	6145                	addi	sp,sp,48
    80006f28:	8082                	ret

0000000080006f2a <bd_mark_unavailable>:

// Mark the range [end, HEAPSIZE) as allocated
int
bd_mark_unavailable(void *end, void *left) {
    80006f2a:	1101                	addi	sp,sp,-32
    80006f2c:	ec06                	sd	ra,24(sp)
    80006f2e:	e822                	sd	s0,16(sp)
    80006f30:	e426                	sd	s1,8(sp)
    80006f32:	1000                	addi	s0,sp,32
  int unavailable = BLK_SIZE(MAXSIZE)-(end-bd_base);
    80006f34:	00023497          	auipc	s1,0x23
    80006f38:	1244a483          	lw	s1,292(s1) # 8002a058 <nsizes>
    80006f3c:	fff4879b          	addiw	a5,s1,-1
    80006f40:	44c1                	li	s1,16
    80006f42:	00f494b3          	sll	s1,s1,a5
    80006f46:	00023797          	auipc	a5,0x23
    80006f4a:	1027b783          	ld	a5,258(a5) # 8002a048 <bd_base>
    80006f4e:	8d1d                	sub	a0,a0,a5
    80006f50:	40a4853b          	subw	a0,s1,a0
    80006f54:	0005049b          	sext.w	s1,a0
  if(unavailable > 0)
    80006f58:	00905a63          	blez	s1,80006f6c <bd_mark_unavailable+0x42>
    unavailable = ROUNDUP(unavailable, LEAF_SIZE);
    80006f5c:	357d                	addiw	a0,a0,-1
    80006f5e:	41f5549b          	sraiw	s1,a0,0x1f
    80006f62:	01c4d49b          	srliw	s1,s1,0x1c
    80006f66:	9ca9                	addw	s1,s1,a0
    80006f68:	98c1                	andi	s1,s1,-16
    80006f6a:	24c1                	addiw	s1,s1,16
  printf("bd: 0x%x bytes unavailable\n", unavailable);
    80006f6c:	85a6                	mv	a1,s1
    80006f6e:	00002517          	auipc	a0,0x2
    80006f72:	9da50513          	addi	a0,a0,-1574 # 80008948 <userret+0x8b8>
    80006f76:	ffff9097          	auipc	ra,0xffff9
    80006f7a:	61c080e7          	jalr	1564(ra) # 80000592 <printf>

  void *bd_end = bd_base+BLK_SIZE(MAXSIZE)-unavailable;
    80006f7e:	00023717          	auipc	a4,0x23
    80006f82:	0ca73703          	ld	a4,202(a4) # 8002a048 <bd_base>
    80006f86:	00023597          	auipc	a1,0x23
    80006f8a:	0d25a583          	lw	a1,210(a1) # 8002a058 <nsizes>
    80006f8e:	fff5879b          	addiw	a5,a1,-1
    80006f92:	45c1                	li	a1,16
    80006f94:	00f595b3          	sll	a1,a1,a5
    80006f98:	40958533          	sub	a0,a1,s1
  bd_mark(bd_end, bd_base+BLK_SIZE(MAXSIZE));
    80006f9c:	95ba                	add	a1,a1,a4
    80006f9e:	953a                	add	a0,a0,a4
    80006fa0:	00000097          	auipc	ra,0x0
    80006fa4:	ce6080e7          	jalr	-794(ra) # 80006c86 <bd_mark>
  return unavailable;
}
    80006fa8:	8526                	mv	a0,s1
    80006faa:	60e2                	ld	ra,24(sp)
    80006fac:	6442                	ld	s0,16(sp)
    80006fae:	64a2                	ld	s1,8(sp)
    80006fb0:	6105                	addi	sp,sp,32
    80006fb2:	8082                	ret

0000000080006fb4 <bd_init>:

// Initialize the buddy allocator: it manages memory from [base, end).
void
bd_init(void *base, void *end) {
    80006fb4:	715d                	addi	sp,sp,-80
    80006fb6:	e486                	sd	ra,72(sp)
    80006fb8:	e0a2                	sd	s0,64(sp)
    80006fba:	fc26                	sd	s1,56(sp)
    80006fbc:	f84a                	sd	s2,48(sp)
    80006fbe:	f44e                	sd	s3,40(sp)
    80006fc0:	f052                	sd	s4,32(sp)
    80006fc2:	ec56                	sd	s5,24(sp)
    80006fc4:	e85a                	sd	s6,16(sp)
    80006fc6:	e45e                	sd	s7,8(sp)
    80006fc8:	e062                	sd	s8,0(sp)
    80006fca:	0880                	addi	s0,sp,80
    80006fcc:	8c2e                	mv	s8,a1
  char *p = (char *) ROUNDUP((uint64)base, LEAF_SIZE);
    80006fce:	fff50493          	addi	s1,a0,-1
    80006fd2:	98c1                	andi	s1,s1,-16
    80006fd4:	04c1                	addi	s1,s1,16
  int sz;

  initlock(&lock, "buddy");
    80006fd6:	00002597          	auipc	a1,0x2
    80006fda:	99258593          	addi	a1,a1,-1646 # 80008968 <userret+0x8d8>
    80006fde:	00023517          	auipc	a0,0x23
    80006fe2:	02250513          	addi	a0,a0,34 # 8002a000 <lock>
    80006fe6:	ffffa097          	auipc	ra,0xffffa
    80006fea:	9ca080e7          	jalr	-1590(ra) # 800009b0 <initlock>
  bd_base = (void *) p;
    80006fee:	00023797          	auipc	a5,0x23
    80006ff2:	0497bd23          	sd	s1,90(a5) # 8002a048 <bd_base>

  // compute the number of sizes we need to manage [base, end)
  nsizes = log2(((char *)end-p)/LEAF_SIZE) + 1;
    80006ff6:	409c0933          	sub	s2,s8,s1
    80006ffa:	43f95513          	srai	a0,s2,0x3f
    80006ffe:	893d                	andi	a0,a0,15
    80007000:	954a                	add	a0,a0,s2
    80007002:	8511                	srai	a0,a0,0x4
    80007004:	00000097          	auipc	ra,0x0
    80007008:	c60080e7          	jalr	-928(ra) # 80006c64 <log2>
  if((char*)end-p > BLK_SIZE(MAXSIZE)) {
    8000700c:	47c1                	li	a5,16
    8000700e:	00a797b3          	sll	a5,a5,a0
    80007012:	1b27c663          	blt	a5,s2,800071be <bd_init+0x20a>
  nsizes = log2(((char *)end-p)/LEAF_SIZE) + 1;
    80007016:	2505                	addiw	a0,a0,1
    80007018:	00023797          	auipc	a5,0x23
    8000701c:	04a7a023          	sw	a0,64(a5) # 8002a058 <nsizes>
    nsizes++;  // round up to the next power of 2
  }

  printf("bd: memory sz is %d bytes; allocate an size array of length %d\n",
    80007020:	00023997          	auipc	s3,0x23
    80007024:	03898993          	addi	s3,s3,56 # 8002a058 <nsizes>
    80007028:	0009a603          	lw	a2,0(s3)
    8000702c:	85ca                	mv	a1,s2
    8000702e:	00002517          	auipc	a0,0x2
    80007032:	94250513          	addi	a0,a0,-1726 # 80008970 <userret+0x8e0>
    80007036:	ffff9097          	auipc	ra,0xffff9
    8000703a:	55c080e7          	jalr	1372(ra) # 80000592 <printf>
         (char*) end - p, nsizes);

  // allocate bd_sizes array
  bd_sizes = (Sz_info *) p;
    8000703e:	00023797          	auipc	a5,0x23
    80007042:	0097b923          	sd	s1,18(a5) # 8002a050 <bd_sizes>
  p += sizeof(Sz_info) * nsizes;
    80007046:	0009a603          	lw	a2,0(s3)
    8000704a:	00561913          	slli	s2,a2,0x5
    8000704e:	9926                	add	s2,s2,s1
  memset(bd_sizes, 0, sizeof(Sz_info) * nsizes);
    80007050:	0056161b          	slliw	a2,a2,0x5
    80007054:	4581                	li	a1,0
    80007056:	8526                	mv	a0,s1
    80007058:	ffffa097          	auipc	ra,0xffffa
    8000705c:	b2a080e7          	jalr	-1238(ra) # 80000b82 <memset>

  // initialize free list and allocate the alloc array for each size k
  for (int k = 0; k < nsizes; k++) {
    80007060:	0009a783          	lw	a5,0(s3)
    80007064:	06f05a63          	blez	a5,800070d8 <bd_init+0x124>
    80007068:	4981                	li	s3,0
    lst_init(&bd_sizes[k].free);
    8000706a:	00023a97          	auipc	s5,0x23
    8000706e:	fe6a8a93          	addi	s5,s5,-26 # 8002a050 <bd_sizes>
    sz = sizeof(char)* ROUNDUP(NBLK(k), 8)/8;
    80007072:	00023a17          	auipc	s4,0x23
    80007076:	fe6a0a13          	addi	s4,s4,-26 # 8002a058 <nsizes>
    8000707a:	4b05                	li	s6,1
    lst_init(&bd_sizes[k].free);
    8000707c:	00599b93          	slli	s7,s3,0x5
    80007080:	000ab503          	ld	a0,0(s5)
    80007084:	955e                	add	a0,a0,s7
    80007086:	00000097          	auipc	ra,0x0
    8000708a:	166080e7          	jalr	358(ra) # 800071ec <lst_init>
    sz = sizeof(char)* ROUNDUP(NBLK(k), 8)/8;
    8000708e:	000a2483          	lw	s1,0(s4)
    80007092:	34fd                	addiw	s1,s1,-1
    80007094:	413484bb          	subw	s1,s1,s3
    80007098:	009b14bb          	sllw	s1,s6,s1
    8000709c:	fff4879b          	addiw	a5,s1,-1
    800070a0:	41f7d49b          	sraiw	s1,a5,0x1f
    800070a4:	01d4d49b          	srliw	s1,s1,0x1d
    800070a8:	9cbd                	addw	s1,s1,a5
    800070aa:	98e1                	andi	s1,s1,-8
    800070ac:	24a1                	addiw	s1,s1,8
    bd_sizes[k].alloc = p;
    800070ae:	000ab783          	ld	a5,0(s5)
    800070b2:	9bbe                	add	s7,s7,a5
    800070b4:	012bb823          	sd	s2,16(s7)
    memset(bd_sizes[k].alloc, 0, sz);
    800070b8:	848d                	srai	s1,s1,0x3
    800070ba:	8626                	mv	a2,s1
    800070bc:	4581                	li	a1,0
    800070be:	854a                	mv	a0,s2
    800070c0:	ffffa097          	auipc	ra,0xffffa
    800070c4:	ac2080e7          	jalr	-1342(ra) # 80000b82 <memset>
    p += sz;
    800070c8:	9926                	add	s2,s2,s1
  for (int k = 0; k < nsizes; k++) {
    800070ca:	0985                	addi	s3,s3,1
    800070cc:	000a2703          	lw	a4,0(s4)
    800070d0:	0009879b          	sext.w	a5,s3
    800070d4:	fae7c4e3          	blt	a5,a4,8000707c <bd_init+0xc8>
  }

  // allocate the split array for each size k, except for k = 0, since
  // we will not split blocks of size k = 0, the smallest size.
  for (int k = 1; k < nsizes; k++) {
    800070d8:	00023797          	auipc	a5,0x23
    800070dc:	f807a783          	lw	a5,-128(a5) # 8002a058 <nsizes>
    800070e0:	4705                	li	a4,1
    800070e2:	06f75163          	bge	a4,a5,80007144 <bd_init+0x190>
    800070e6:	02000a13          	li	s4,32
    800070ea:	4985                	li	s3,1
    sz = sizeof(char)* (ROUNDUP(NBLK(k), 8))/8;
    800070ec:	4b85                	li	s7,1
    bd_sizes[k].split = p;
    800070ee:	00023b17          	auipc	s6,0x23
    800070f2:	f62b0b13          	addi	s6,s6,-158 # 8002a050 <bd_sizes>
  for (int k = 1; k < nsizes; k++) {
    800070f6:	00023a97          	auipc	s5,0x23
    800070fa:	f62a8a93          	addi	s5,s5,-158 # 8002a058 <nsizes>
    sz = sizeof(char)* (ROUNDUP(NBLK(k), 8))/8;
    800070fe:	37fd                	addiw	a5,a5,-1
    80007100:	413787bb          	subw	a5,a5,s3
    80007104:	00fb94bb          	sllw	s1,s7,a5
    80007108:	fff4879b          	addiw	a5,s1,-1
    8000710c:	41f7d49b          	sraiw	s1,a5,0x1f
    80007110:	01d4d49b          	srliw	s1,s1,0x1d
    80007114:	9cbd                	addw	s1,s1,a5
    80007116:	98e1                	andi	s1,s1,-8
    80007118:	24a1                	addiw	s1,s1,8
    bd_sizes[k].split = p;
    8000711a:	000b3783          	ld	a5,0(s6)
    8000711e:	97d2                	add	a5,a5,s4
    80007120:	0127bc23          	sd	s2,24(a5)
    memset(bd_sizes[k].split, 0, sz);
    80007124:	848d                	srai	s1,s1,0x3
    80007126:	8626                	mv	a2,s1
    80007128:	4581                	li	a1,0
    8000712a:	854a                	mv	a0,s2
    8000712c:	ffffa097          	auipc	ra,0xffffa
    80007130:	a56080e7          	jalr	-1450(ra) # 80000b82 <memset>
    p += sz;
    80007134:	9926                	add	s2,s2,s1
  for (int k = 1; k < nsizes; k++) {
    80007136:	2985                	addiw	s3,s3,1
    80007138:	000aa783          	lw	a5,0(s5)
    8000713c:	020a0a13          	addi	s4,s4,32
    80007140:	faf9cfe3          	blt	s3,a5,800070fe <bd_init+0x14a>
  }
  p = (char *) ROUNDUP((uint64) p, LEAF_SIZE);
    80007144:	197d                	addi	s2,s2,-1
    80007146:	ff097913          	andi	s2,s2,-16
    8000714a:	0941                	addi	s2,s2,16

  // done allocating; mark the memory range [base, p) as allocated, so
  // that buddy will not hand out that memory.
  int meta = bd_mark_data_structures(p);
    8000714c:	854a                	mv	a0,s2
    8000714e:	00000097          	auipc	ra,0x0
    80007152:	d7c080e7          	jalr	-644(ra) # 80006eca <bd_mark_data_structures>
    80007156:	8a2a                	mv	s4,a0
  
  // mark the unavailable memory range [end, HEAP_SIZE) as allocated,
  // so that buddy will not hand out that memory.
  int unavailable = bd_mark_unavailable(end, p);
    80007158:	85ca                	mv	a1,s2
    8000715a:	8562                	mv	a0,s8
    8000715c:	00000097          	auipc	ra,0x0
    80007160:	dce080e7          	jalr	-562(ra) # 80006f2a <bd_mark_unavailable>
    80007164:	89aa                	mv	s3,a0
  void *bd_end = bd_base+BLK_SIZE(MAXSIZE)-unavailable;
    80007166:	00023a97          	auipc	s5,0x23
    8000716a:	ef2a8a93          	addi	s5,s5,-270 # 8002a058 <nsizes>
    8000716e:	000aa783          	lw	a5,0(s5)
    80007172:	37fd                	addiw	a5,a5,-1
    80007174:	44c1                	li	s1,16
    80007176:	00f497b3          	sll	a5,s1,a5
    8000717a:	8f89                	sub	a5,a5,a0
  
  // initialize free lists for each size k
  int free = bd_initfree(p, bd_end);
    8000717c:	00023597          	auipc	a1,0x23
    80007180:	ecc5b583          	ld	a1,-308(a1) # 8002a048 <bd_base>
    80007184:	95be                	add	a1,a1,a5
    80007186:	854a                	mv	a0,s2
    80007188:	00000097          	auipc	ra,0x0
    8000718c:	c86080e7          	jalr	-890(ra) # 80006e0e <bd_initfree>

  // check if the amount that is free is what we expect
  if(free != BLK_SIZE(MAXSIZE)-meta-unavailable) {
    80007190:	000aa603          	lw	a2,0(s5)
    80007194:	367d                	addiw	a2,a2,-1
    80007196:	00c49633          	sll	a2,s1,a2
    8000719a:	41460633          	sub	a2,a2,s4
    8000719e:	41360633          	sub	a2,a2,s3
    800071a2:	02c51463          	bne	a0,a2,800071ca <bd_init+0x216>
    printf("free %d %d\n", free, BLK_SIZE(MAXSIZE)-meta-unavailable);
    panic("bd_init: free mem");
  }
}
    800071a6:	60a6                	ld	ra,72(sp)
    800071a8:	6406                	ld	s0,64(sp)
    800071aa:	74e2                	ld	s1,56(sp)
    800071ac:	7942                	ld	s2,48(sp)
    800071ae:	79a2                	ld	s3,40(sp)
    800071b0:	7a02                	ld	s4,32(sp)
    800071b2:	6ae2                	ld	s5,24(sp)
    800071b4:	6b42                	ld	s6,16(sp)
    800071b6:	6ba2                	ld	s7,8(sp)
    800071b8:	6c02                	ld	s8,0(sp)
    800071ba:	6161                	addi	sp,sp,80
    800071bc:	8082                	ret
    nsizes++;  // round up to the next power of 2
    800071be:	2509                	addiw	a0,a0,2
    800071c0:	00023797          	auipc	a5,0x23
    800071c4:	e8a7ac23          	sw	a0,-360(a5) # 8002a058 <nsizes>
    800071c8:	bda1                	j	80007020 <bd_init+0x6c>
    printf("free %d %d\n", free, BLK_SIZE(MAXSIZE)-meta-unavailable);
    800071ca:	85aa                	mv	a1,a0
    800071cc:	00001517          	auipc	a0,0x1
    800071d0:	7e450513          	addi	a0,a0,2020 # 800089b0 <userret+0x920>
    800071d4:	ffff9097          	auipc	ra,0xffff9
    800071d8:	3be080e7          	jalr	958(ra) # 80000592 <printf>
    panic("bd_init: free mem");
    800071dc:	00001517          	auipc	a0,0x1
    800071e0:	7e450513          	addi	a0,a0,2020 # 800089c0 <userret+0x930>
    800071e4:	ffff9097          	auipc	ra,0xffff9
    800071e8:	364080e7          	jalr	868(ra) # 80000548 <panic>

00000000800071ec <lst_init>:
// fast. circular simplifies code, because don't have to check for
// empty list in insert and remove.

void
lst_init(struct list *lst)
{
    800071ec:	1141                	addi	sp,sp,-16
    800071ee:	e422                	sd	s0,8(sp)
    800071f0:	0800                	addi	s0,sp,16
  lst->next = lst;
    800071f2:	e108                	sd	a0,0(a0)
  lst->prev = lst;
    800071f4:	e508                	sd	a0,8(a0)
}
    800071f6:	6422                	ld	s0,8(sp)
    800071f8:	0141                	addi	sp,sp,16
    800071fa:	8082                	ret

00000000800071fc <lst_empty>:

int
lst_empty(struct list *lst) {
    800071fc:	1141                	addi	sp,sp,-16
    800071fe:	e422                	sd	s0,8(sp)
    80007200:	0800                	addi	s0,sp,16
  return lst->next == lst;
    80007202:	611c                	ld	a5,0(a0)
    80007204:	40a78533          	sub	a0,a5,a0
}
    80007208:	00153513          	seqz	a0,a0
    8000720c:	6422                	ld	s0,8(sp)
    8000720e:	0141                	addi	sp,sp,16
    80007210:	8082                	ret

0000000080007212 <lst_remove>:

void
lst_remove(struct list *e) {
    80007212:	1141                	addi	sp,sp,-16
    80007214:	e422                	sd	s0,8(sp)
    80007216:	0800                	addi	s0,sp,16
  e->prev->next = e->next;
    80007218:	6518                	ld	a4,8(a0)
    8000721a:	611c                	ld	a5,0(a0)
    8000721c:	e31c                	sd	a5,0(a4)
  e->next->prev = e->prev;
    8000721e:	6518                	ld	a4,8(a0)
    80007220:	e798                	sd	a4,8(a5)
}
    80007222:	6422                	ld	s0,8(sp)
    80007224:	0141                	addi	sp,sp,16
    80007226:	8082                	ret

0000000080007228 <lst_pop>:

void*
lst_pop(struct list *lst) {
    80007228:	1101                	addi	sp,sp,-32
    8000722a:	ec06                	sd	ra,24(sp)
    8000722c:	e822                	sd	s0,16(sp)
    8000722e:	e426                	sd	s1,8(sp)
    80007230:	1000                	addi	s0,sp,32
  if(lst->next == lst)
    80007232:	6104                	ld	s1,0(a0)
    80007234:	00a48d63          	beq	s1,a0,8000724e <lst_pop+0x26>
    panic("lst_pop");
  struct list *p = lst->next;
  lst_remove(p);
    80007238:	8526                	mv	a0,s1
    8000723a:	00000097          	auipc	ra,0x0
    8000723e:	fd8080e7          	jalr	-40(ra) # 80007212 <lst_remove>
  return (void *)p;
}
    80007242:	8526                	mv	a0,s1
    80007244:	60e2                	ld	ra,24(sp)
    80007246:	6442                	ld	s0,16(sp)
    80007248:	64a2                	ld	s1,8(sp)
    8000724a:	6105                	addi	sp,sp,32
    8000724c:	8082                	ret
    panic("lst_pop");
    8000724e:	00001517          	auipc	a0,0x1
    80007252:	78a50513          	addi	a0,a0,1930 # 800089d8 <userret+0x948>
    80007256:	ffff9097          	auipc	ra,0xffff9
    8000725a:	2f2080e7          	jalr	754(ra) # 80000548 <panic>

000000008000725e <lst_push>:

void
lst_push(struct list *lst, void *p)
{
    8000725e:	1141                	addi	sp,sp,-16
    80007260:	e422                	sd	s0,8(sp)
    80007262:	0800                	addi	s0,sp,16
  struct list *e = (struct list *) p;
  e->next = lst->next;
    80007264:	611c                	ld	a5,0(a0)
    80007266:	e19c                	sd	a5,0(a1)
  e->prev = lst;
    80007268:	e588                	sd	a0,8(a1)
  lst->next->prev = p;
    8000726a:	611c                	ld	a5,0(a0)
    8000726c:	e78c                	sd	a1,8(a5)
  lst->next = e;
    8000726e:	e10c                	sd	a1,0(a0)
}
    80007270:	6422                	ld	s0,8(sp)
    80007272:	0141                	addi	sp,sp,16
    80007274:	8082                	ret

0000000080007276 <lst_print>:

void
lst_print(struct list *lst)
{
    80007276:	7179                	addi	sp,sp,-48
    80007278:	f406                	sd	ra,40(sp)
    8000727a:	f022                	sd	s0,32(sp)
    8000727c:	ec26                	sd	s1,24(sp)
    8000727e:	e84a                	sd	s2,16(sp)
    80007280:	e44e                	sd	s3,8(sp)
    80007282:	1800                	addi	s0,sp,48
  for (struct list *p = lst->next; p != lst; p = p->next) {
    80007284:	6104                	ld	s1,0(a0)
    80007286:	02950063          	beq	a0,s1,800072a6 <lst_print+0x30>
    8000728a:	892a                	mv	s2,a0
    printf(" %p", p);
    8000728c:	00001997          	auipc	s3,0x1
    80007290:	75498993          	addi	s3,s3,1876 # 800089e0 <userret+0x950>
    80007294:	85a6                	mv	a1,s1
    80007296:	854e                	mv	a0,s3
    80007298:	ffff9097          	auipc	ra,0xffff9
    8000729c:	2fa080e7          	jalr	762(ra) # 80000592 <printf>
  for (struct list *p = lst->next; p != lst; p = p->next) {
    800072a0:	6084                	ld	s1,0(s1)
    800072a2:	fe9919e3          	bne	s2,s1,80007294 <lst_print+0x1e>
  }
  printf("\n");
    800072a6:	00001517          	auipc	a0,0x1
    800072aa:	f0a50513          	addi	a0,a0,-246 # 800081b0 <userret+0x120>
    800072ae:	ffff9097          	auipc	ra,0xffff9
    800072b2:	2e4080e7          	jalr	740(ra) # 80000592 <printf>
}
    800072b6:	70a2                	ld	ra,40(sp)
    800072b8:	7402                	ld	s0,32(sp)
    800072ba:	64e2                	ld	s1,24(sp)
    800072bc:	6942                	ld	s2,16(sp)
    800072be:	69a2                	ld	s3,8(sp)
    800072c0:	6145                	addi	sp,sp,48
    800072c2:	8082                	ret
	...

0000000080008000 <trampoline>:
    80008000:	14051573          	csrrw	a0,sscratch,a0
    80008004:	02153423          	sd	ra,40(a0)
    80008008:	02253823          	sd	sp,48(a0)
    8000800c:	02353c23          	sd	gp,56(a0)
    80008010:	04453023          	sd	tp,64(a0)
    80008014:	04553423          	sd	t0,72(a0)
    80008018:	04653823          	sd	t1,80(a0)
    8000801c:	04753c23          	sd	t2,88(a0)
    80008020:	f120                	sd	s0,96(a0)
    80008022:	f524                	sd	s1,104(a0)
    80008024:	fd2c                	sd	a1,120(a0)
    80008026:	e150                	sd	a2,128(a0)
    80008028:	e554                	sd	a3,136(a0)
    8000802a:	e958                	sd	a4,144(a0)
    8000802c:	ed5c                	sd	a5,152(a0)
    8000802e:	0b053023          	sd	a6,160(a0)
    80008032:	0b153423          	sd	a7,168(a0)
    80008036:	0b253823          	sd	s2,176(a0)
    8000803a:	0b353c23          	sd	s3,184(a0)
    8000803e:	0d453023          	sd	s4,192(a0)
    80008042:	0d553423          	sd	s5,200(a0)
    80008046:	0d653823          	sd	s6,208(a0)
    8000804a:	0d753c23          	sd	s7,216(a0)
    8000804e:	0f853023          	sd	s8,224(a0)
    80008052:	0f953423          	sd	s9,232(a0)
    80008056:	0fa53823          	sd	s10,240(a0)
    8000805a:	0fb53c23          	sd	s11,248(a0)
    8000805e:	11c53023          	sd	t3,256(a0)
    80008062:	11d53423          	sd	t4,264(a0)
    80008066:	11e53823          	sd	t5,272(a0)
    8000806a:	11f53c23          	sd	t6,280(a0)
    8000806e:	140022f3          	csrr	t0,sscratch
    80008072:	06553823          	sd	t0,112(a0)
    80008076:	00853103          	ld	sp,8(a0)
    8000807a:	02053203          	ld	tp,32(a0)
    8000807e:	01053283          	ld	t0,16(a0)
    80008082:	00053303          	ld	t1,0(a0)
    80008086:	18031073          	csrw	satp,t1
    8000808a:	12000073          	sfence.vma
    8000808e:	8282                	jr	t0

0000000080008090 <userret>:
    80008090:	18059073          	csrw	satp,a1
    80008094:	12000073          	sfence.vma
    80008098:	07053283          	ld	t0,112(a0)
    8000809c:	14029073          	csrw	sscratch,t0
    800080a0:	02853083          	ld	ra,40(a0)
    800080a4:	03053103          	ld	sp,48(a0)
    800080a8:	03853183          	ld	gp,56(a0)
    800080ac:	04053203          	ld	tp,64(a0)
    800080b0:	04853283          	ld	t0,72(a0)
    800080b4:	05053303          	ld	t1,80(a0)
    800080b8:	05853383          	ld	t2,88(a0)
    800080bc:	7120                	ld	s0,96(a0)
    800080be:	7524                	ld	s1,104(a0)
    800080c0:	7d2c                	ld	a1,120(a0)
    800080c2:	6150                	ld	a2,128(a0)
    800080c4:	6554                	ld	a3,136(a0)
    800080c6:	6958                	ld	a4,144(a0)
    800080c8:	6d5c                	ld	a5,152(a0)
    800080ca:	0a053803          	ld	a6,160(a0)
    800080ce:	0a853883          	ld	a7,168(a0)
    800080d2:	0b053903          	ld	s2,176(a0)
    800080d6:	0b853983          	ld	s3,184(a0)
    800080da:	0c053a03          	ld	s4,192(a0)
    800080de:	0c853a83          	ld	s5,200(a0)
    800080e2:	0d053b03          	ld	s6,208(a0)
    800080e6:	0d853b83          	ld	s7,216(a0)
    800080ea:	0e053c03          	ld	s8,224(a0)
    800080ee:	0e853c83          	ld	s9,232(a0)
    800080f2:	0f053d03          	ld	s10,240(a0)
    800080f6:	0f853d83          	ld	s11,248(a0)
    800080fa:	10053e03          	ld	t3,256(a0)
    800080fe:	10853e83          	ld	t4,264(a0)
    80008102:	11053f03          	ld	t5,272(a0)
    80008106:	11853f83          	ld	t6,280(a0)
    8000810a:	14051573          	csrrw	a0,sscratch,a0
    8000810e:	10200073          	sret

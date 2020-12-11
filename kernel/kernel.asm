
kernel/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	80010113          	addi	sp,sp,-2048 # 80009800 <stack0>
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
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fb660613          	addi	a2,a2,-74 # 80009000 <mscratch0>
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
    80000060:	b4478793          	addi	a5,a5,-1212 # 80005ba0 <timervec>
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
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd67a3>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	b8878793          	addi	a5,a5,-1144 # 80000c2e <main>
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
consoleread(int user_dst, uint64 dst, int n)
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
    800000fc:	8aaa                	mv	s5,a0
    800000fe:	8a2e                	mv	s4,a1
    80000100:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000102:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000106:	00011517          	auipc	a0,0x11
    8000010a:	6fa50513          	addi	a0,a0,1786 # 80011800 <cons>
    8000010e:	00001097          	auipc	ra,0x1
    80000112:	8ae080e7          	jalr	-1874(ra) # 800009bc <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000116:	00011497          	auipc	s1,0x11
    8000011a:	6ea48493          	addi	s1,s1,1770 # 80011800 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    8000011e:	00011917          	auipc	s2,0x11
    80000122:	77a90913          	addi	s2,s2,1914 # 80011898 <cons+0x98>
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
    8000013c:	00001097          	auipc	ra,0x1
    80000140:	5e0080e7          	jalr	1504(ra) # 8000171c <myproc>
    80000144:	591c                	lw	a5,48(a0)
    80000146:	e7b5                	bnez	a5,800001b2 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    80000148:	85a6                	mv	a1,s1
    8000014a:	854a                	mv	a0,s2
    8000014c:	00002097          	auipc	ra,0x2
    80000150:	de6080e7          	jalr	-538(ra) # 80001f32 <sleep>
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
    8000018c:	004080e7          	jalr	4(ra) # 8000218c <either_copyout>
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
    8000019c:	00011517          	auipc	a0,0x11
    800001a0:	66450513          	addi	a0,a0,1636 # 80011800 <cons>
    800001a4:	00001097          	auipc	ra,0x1
    800001a8:	880080e7          	jalr	-1920(ra) # 80000a24 <release>

  return target - n;
    800001ac:	413b053b          	subw	a0,s6,s3
    800001b0:	a811                	j	800001c4 <consoleread+0xe4>
        release(&cons.lock);
    800001b2:	00011517          	auipc	a0,0x11
    800001b6:	64e50513          	addi	a0,a0,1614 # 80011800 <cons>
    800001ba:	00001097          	auipc	ra,0x1
    800001be:	86a080e7          	jalr	-1942(ra) # 80000a24 <release>
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
    800001e8:	00011717          	auipc	a4,0x11
    800001ec:	6af72823          	sw	a5,1712(a4) # 80011898 <cons+0x98>
    800001f0:	b775                	j	8000019c <consoleread+0xbc>

00000000800001f2 <consputc>:
  if(panicked){
    800001f2:	00028797          	auipc	a5,0x28
    800001f6:	e267a783          	lw	a5,-474(a5) # 80028018 <panicked>
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
    80000252:	89aa                	mv	s3,a0
    80000254:	84ae                	mv	s1,a1
    80000256:	8ab2                	mv	s5,a2
  acquire(&cons.lock);
    80000258:	00011517          	auipc	a0,0x11
    8000025c:	5a850513          	addi	a0,a0,1448 # 80011800 <cons>
    80000260:	00000097          	auipc	ra,0x0
    80000264:	75c080e7          	jalr	1884(ra) # 800009bc <acquire>
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
    8000028a:	f5c080e7          	jalr	-164(ra) # 800021e2 <either_copyin>
    8000028e:	01450b63          	beq	a0,s4,800002a4 <consolewrite+0x64>
    consputc(c);
    80000292:	fbf44503          	lbu	a0,-65(s0)
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	f5c080e7          	jalr	-164(ra) # 800001f2 <consputc>
  for(i = 0; i < n; i++){
    8000029e:	0485                	addi	s1,s1,1
    800002a0:	fd249ee3          	bne	s1,s2,8000027c <consolewrite+0x3c>
  release(&cons.lock);
    800002a4:	00011517          	auipc	a0,0x11
    800002a8:	55c50513          	addi	a0,a0,1372 # 80011800 <cons>
    800002ac:	00000097          	auipc	ra,0x0
    800002b0:	778080e7          	jalr	1912(ra) # 80000a24 <release>
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
    800002d6:	00011517          	auipc	a0,0x11
    800002da:	52a50513          	addi	a0,a0,1322 # 80011800 <cons>
    800002de:	00000097          	auipc	ra,0x0
    800002e2:	6de080e7          	jalr	1758(ra) # 800009bc <acquire>

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
    80000300:	f3c080e7          	jalr	-196(ra) # 80002238 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	4fc50513          	addi	a0,a0,1276 # 80011800 <cons>
    8000030c:	00000097          	auipc	ra,0x0
    80000310:	718080e7          	jalr	1816(ra) # 80000a24 <release>
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
    80000328:	00011717          	auipc	a4,0x11
    8000032c:	4d870713          	addi	a4,a4,1240 # 80011800 <cons>
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
    80000352:	00011797          	auipc	a5,0x11
    80000356:	4ae78793          	addi	a5,a5,1198 # 80011800 <cons>
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
    80000380:	00011797          	auipc	a5,0x11
    80000384:	5187a783          	lw	a5,1304(a5) # 80011898 <cons+0x98>
    80000388:	0807879b          	addiw	a5,a5,128
    8000038c:	f6f61ce3          	bne	a2,a5,80000304 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000390:	863e                	mv	a2,a5
    80000392:	a07d                	j	80000440 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000394:	00011717          	auipc	a4,0x11
    80000398:	46c70713          	addi	a4,a4,1132 # 80011800 <cons>
    8000039c:	0a072783          	lw	a5,160(a4)
    800003a0:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a4:	00011497          	auipc	s1,0x11
    800003a8:	45c48493          	addi	s1,s1,1116 # 80011800 <cons>
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
    800003e0:	00011717          	auipc	a4,0x11
    800003e4:	42070713          	addi	a4,a4,1056 # 80011800 <cons>
    800003e8:	0a072783          	lw	a5,160(a4)
    800003ec:	09c72703          	lw	a4,156(a4)
    800003f0:	f0f70ae3          	beq	a4,a5,80000304 <consoleintr+0x3c>
      cons.e--;
    800003f4:	37fd                	addiw	a5,a5,-1
    800003f6:	00011717          	auipc	a4,0x11
    800003fa:	4af72523          	sw	a5,1194(a4) # 800118a0 <cons+0xa0>
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
    8000041c:	00011797          	auipc	a5,0x11
    80000420:	3e478793          	addi	a5,a5,996 # 80011800 <cons>
    80000424:	0a07a703          	lw	a4,160(a5)
    80000428:	0017069b          	addiw	a3,a4,1
    8000042c:	0006861b          	sext.w	a2,a3
    80000430:	0ad7a023          	sw	a3,160(a5)
    80000434:	07f77713          	andi	a4,a4,127
    80000438:	97ba                	add	a5,a5,a4
    8000043a:	4729                	li	a4,10
    8000043c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000440:	00011797          	auipc	a5,0x11
    80000444:	44c7ae23          	sw	a2,1116(a5) # 8001189c <cons+0x9c>
        wakeup(&cons.r);
    80000448:	00011517          	auipc	a0,0x11
    8000044c:	45050513          	addi	a0,a0,1104 # 80011898 <cons+0x98>
    80000450:	00002097          	auipc	ra,0x2
    80000454:	c62080e7          	jalr	-926(ra) # 800020b2 <wakeup>
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
    80000462:	00007597          	auipc	a1,0x7
    80000466:	cb658593          	addi	a1,a1,-842 # 80007118 <userret+0x88>
    8000046a:	00011517          	auipc	a0,0x11
    8000046e:	39650513          	addi	a0,a0,918 # 80011800 <cons>
    80000472:	00000097          	auipc	ra,0x0
    80000476:	43c080e7          	jalr	1084(ra) # 800008ae <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	32a080e7          	jalr	810(ra) # 800007a4 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00021797          	auipc	a5,0x21
    80000486:	65e78793          	addi	a5,a5,1630 # 80021ae0 <devsw>
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
    800004c4:	00007617          	auipc	a2,0x7
    800004c8:	51460613          	addi	a2,a2,1300 # 800079d8 <digits>
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
    80000554:	00011797          	auipc	a5,0x11
    80000558:	3607a623          	sw	zero,876(a5) # 800118c0 <pr+0x18>
  printf("panic: ");
    8000055c:	00007517          	auipc	a0,0x7
    80000560:	bc450513          	addi	a0,a0,-1084 # 80007120 <userret+0x90>
    80000564:	00000097          	auipc	ra,0x0
    80000568:	02e080e7          	jalr	46(ra) # 80000592 <printf>
  printf(s);
    8000056c:	8526                	mv	a0,s1
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	024080e7          	jalr	36(ra) # 80000592 <printf>
  printf("\n");
    80000576:	00007517          	auipc	a0,0x7
    8000057a:	c2a50513          	addi	a0,a0,-982 # 800071a0 <userret+0x110>
    8000057e:	00000097          	auipc	ra,0x0
    80000582:	014080e7          	jalr	20(ra) # 80000592 <printf>
  panicked = 1; // freeze other CPUs
    80000586:	4785                	li	a5,1
    80000588:	00028717          	auipc	a4,0x28
    8000058c:	a8f72823          	sw	a5,-1392(a4) # 80028018 <panicked>
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
    800005c4:	00011d97          	auipc	s11,0x11
    800005c8:	2fcdad83          	lw	s11,764(s11) # 800118c0 <pr+0x18>
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
    800005f0:	00007b17          	auipc	s6,0x7
    800005f4:	3e8b0b13          	addi	s6,s6,1000 # 800079d8 <digits>
    switch(c){
    800005f8:	07300c93          	li	s9,115
    800005fc:	06400c13          	li	s8,100
    80000600:	a82d                	j	8000063a <printf+0xa8>
    acquire(&pr.lock);
    80000602:	00011517          	auipc	a0,0x11
    80000606:	2a650513          	addi	a0,a0,678 # 800118a8 <pr>
    8000060a:	00000097          	auipc	ra,0x0
    8000060e:	3b2080e7          	jalr	946(ra) # 800009bc <acquire>
    80000612:	bf7d                	j	800005d0 <printf+0x3e>
    panic("null fmt");
    80000614:	00007517          	auipc	a0,0x7
    80000618:	b1c50513          	addi	a0,a0,-1252 # 80007130 <userret+0xa0>
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
    8000070e:	00007497          	auipc	s1,0x7
    80000712:	a1a48493          	addi	s1,s1,-1510 # 80007128 <userret+0x98>
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
    80000760:	00011517          	auipc	a0,0x11
    80000764:	14850513          	addi	a0,a0,328 # 800118a8 <pr>
    80000768:	00000097          	auipc	ra,0x0
    8000076c:	2bc080e7          	jalr	700(ra) # 80000a24 <release>
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
    8000077c:	00011497          	auipc	s1,0x11
    80000780:	12c48493          	addi	s1,s1,300 # 800118a8 <pr>
    80000784:	00007597          	auipc	a1,0x7
    80000788:	9bc58593          	addi	a1,a1,-1604 # 80007140 <userret+0xb0>
    8000078c:	8526                	mv	a0,s1
    8000078e:	00000097          	auipc	ra,0x0
    80000792:	120080e7          	jalr	288(ra) # 800008ae <initlock>
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

0000000080000854 <kinit>:

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.
void
kinit()
{
    80000854:	1141                	addi	sp,sp,-16
    80000856:	e406                	sd	ra,8(sp)
    80000858:	e022                	sd	s0,0(sp)
    8000085a:	0800                	addi	s0,sp,16
  char *p = (char *) PGROUNDUP((uint64) end);
  bd_init(p, (void*)PHYSTOP);
    8000085c:	45c5                	li	a1,17
    8000085e:	05ee                	slli	a1,a1,0x1b
    80000860:	00028517          	auipc	a0,0x28
    80000864:	7fb50513          	addi	a0,a0,2043 # 8002905b <end+0xfff>
    80000868:	77fd                	lui	a5,0xfffff
    8000086a:	8d7d                	and	a0,a0,a5
    8000086c:	00006097          	auipc	ra,0x6
    80000870:	470080e7          	jalr	1136(ra) # 80006cdc <bd_init>
}
    80000874:	60a2                	ld	ra,8(sp)
    80000876:	6402                	ld	s0,0(sp)
    80000878:	0141                	addi	sp,sp,16
    8000087a:	8082                	ret

000000008000087c <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    8000087c:	1141                	addi	sp,sp,-16
    8000087e:	e406                	sd	ra,8(sp)
    80000880:	e022                	sd	s0,0(sp)
    80000882:	0800                	addi	s0,sp,16
  bd_free(pa);
    80000884:	00006097          	auipc	ra,0x6
    80000888:	f7a080e7          	jalr	-134(ra) # 800067fe <bd_free>
}
    8000088c:	60a2                	ld	ra,8(sp)
    8000088e:	6402                	ld	s0,0(sp)
    80000890:	0141                	addi	sp,sp,16
    80000892:	8082                	ret

0000000080000894 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000894:	1141                	addi	sp,sp,-16
    80000896:	e406                	sd	ra,8(sp)
    80000898:	e022                	sd	s0,0(sp)
    8000089a:	0800                	addi	s0,sp,16
  return bd_malloc(PGSIZE);
    8000089c:	6505                	lui	a0,0x1
    8000089e:	00006097          	auipc	ra,0x6
    800008a2:	d74080e7          	jalr	-652(ra) # 80006612 <bd_malloc>
}
    800008a6:	60a2                	ld	ra,8(sp)
    800008a8:	6402                	ld	s0,0(sp)
    800008aa:	0141                	addi	sp,sp,16
    800008ac:	8082                	ret

00000000800008ae <initlock>:

uint64 ntest_and_set;

void
initlock(struct spinlock *lk, char *name)
{
    800008ae:	1141                	addi	sp,sp,-16
    800008b0:	e422                	sd	s0,8(sp)
    800008b2:	0800                	addi	s0,sp,16
  lk->name = name;
    800008b4:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    800008b6:	00052023          	sw	zero,0(a0) # 1000 <_entry-0x7ffff000>
  lk->cpu = 0;
    800008ba:	00053823          	sd	zero,16(a0)
}
    800008be:	6422                	ld	s0,8(sp)
    800008c0:	0141                	addi	sp,sp,16
    800008c2:	8082                	ret

00000000800008c4 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    800008c4:	1101                	addi	sp,sp,-32
    800008c6:	ec06                	sd	ra,24(sp)
    800008c8:	e822                	sd	s0,16(sp)
    800008ca:	e426                	sd	s1,8(sp)
    800008cc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800008ce:	100024f3          	csrr	s1,sstatus
    800008d2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800008d6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800008d8:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    800008dc:	00001097          	auipc	ra,0x1
    800008e0:	e24080e7          	jalr	-476(ra) # 80001700 <mycpu>
    800008e4:	5d3c                	lw	a5,120(a0)
    800008e6:	cf89                	beqz	a5,80000900 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    800008e8:	00001097          	auipc	ra,0x1
    800008ec:	e18080e7          	jalr	-488(ra) # 80001700 <mycpu>
    800008f0:	5d3c                	lw	a5,120(a0)
    800008f2:	2785                	addiw	a5,a5,1
    800008f4:	dd3c                	sw	a5,120(a0)
}
    800008f6:	60e2                	ld	ra,24(sp)
    800008f8:	6442                	ld	s0,16(sp)
    800008fa:	64a2                	ld	s1,8(sp)
    800008fc:	6105                	addi	sp,sp,32
    800008fe:	8082                	ret
    mycpu()->intena = old;
    80000900:	00001097          	auipc	ra,0x1
    80000904:	e00080e7          	jalr	-512(ra) # 80001700 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000908:	8085                	srli	s1,s1,0x1
    8000090a:	8885                	andi	s1,s1,1
    8000090c:	dd64                	sw	s1,124(a0)
    8000090e:	bfe9                	j	800008e8 <push_off+0x24>

0000000080000910 <pop_off>:

void
pop_off(void)
{
    80000910:	1141                	addi	sp,sp,-16
    80000912:	e406                	sd	ra,8(sp)
    80000914:	e022                	sd	s0,0(sp)
    80000916:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000918:	00001097          	auipc	ra,0x1
    8000091c:	de8080e7          	jalr	-536(ra) # 80001700 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000920:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000924:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000926:	eb9d                	bnez	a5,8000095c <pop_off+0x4c>
    panic("pop_off - interruptible");
  c->noff -= 1;
    80000928:	5d3c                	lw	a5,120(a0)
    8000092a:	37fd                	addiw	a5,a5,-1
    8000092c:	0007871b          	sext.w	a4,a5
    80000930:	dd3c                	sw	a5,120(a0)
  if(c->noff < 0)
    80000932:	02074d63          	bltz	a4,8000096c <pop_off+0x5c>
    panic("pop_off");
  if(c->noff == 0 && c->intena)
    80000936:	ef19                	bnez	a4,80000954 <pop_off+0x44>
    80000938:	5d7c                	lw	a5,124(a0)
    8000093a:	cf89                	beqz	a5,80000954 <pop_off+0x44>
  asm volatile("csrr %0, sie" : "=r" (x) );
    8000093c:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    80000940:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    80000944:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000948:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000094c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000950:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000954:	60a2                	ld	ra,8(sp)
    80000956:	6402                	ld	s0,0(sp)
    80000958:	0141                	addi	sp,sp,16
    8000095a:	8082                	ret
    panic("pop_off - interruptible");
    8000095c:	00006517          	auipc	a0,0x6
    80000960:	7ec50513          	addi	a0,a0,2028 # 80007148 <userret+0xb8>
    80000964:	00000097          	auipc	ra,0x0
    80000968:	be4080e7          	jalr	-1052(ra) # 80000548 <panic>
    panic("pop_off");
    8000096c:	00006517          	auipc	a0,0x6
    80000970:	7f450513          	addi	a0,a0,2036 # 80007160 <userret+0xd0>
    80000974:	00000097          	auipc	ra,0x0
    80000978:	bd4080e7          	jalr	-1068(ra) # 80000548 <panic>

000000008000097c <holding>:
{
    8000097c:	1101                	addi	sp,sp,-32
    8000097e:	ec06                	sd	ra,24(sp)
    80000980:	e822                	sd	s0,16(sp)
    80000982:	e426                	sd	s1,8(sp)
    80000984:	1000                	addi	s0,sp,32
    80000986:	84aa                	mv	s1,a0
  push_off();
    80000988:	00000097          	auipc	ra,0x0
    8000098c:	f3c080e7          	jalr	-196(ra) # 800008c4 <push_off>
  r = (lk->locked && lk->cpu == mycpu());
    80000990:	409c                	lw	a5,0(s1)
    80000992:	ef81                	bnez	a5,800009aa <holding+0x2e>
    80000994:	4481                	li	s1,0
  pop_off();
    80000996:	00000097          	auipc	ra,0x0
    8000099a:	f7a080e7          	jalr	-134(ra) # 80000910 <pop_off>
}
    8000099e:	8526                	mv	a0,s1
    800009a0:	60e2                	ld	ra,24(sp)
    800009a2:	6442                	ld	s0,16(sp)
    800009a4:	64a2                	ld	s1,8(sp)
    800009a6:	6105                	addi	sp,sp,32
    800009a8:	8082                	ret
  r = (lk->locked && lk->cpu == mycpu());
    800009aa:	6884                	ld	s1,16(s1)
    800009ac:	00001097          	auipc	ra,0x1
    800009b0:	d54080e7          	jalr	-684(ra) # 80001700 <mycpu>
    800009b4:	8c89                	sub	s1,s1,a0
    800009b6:	0014b493          	seqz	s1,s1
    800009ba:	bff1                	j	80000996 <holding+0x1a>

00000000800009bc <acquire>:
{
    800009bc:	1101                	addi	sp,sp,-32
    800009be:	ec06                	sd	ra,24(sp)
    800009c0:	e822                	sd	s0,16(sp)
    800009c2:	e426                	sd	s1,8(sp)
    800009c4:	1000                	addi	s0,sp,32
    800009c6:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    800009c8:	00000097          	auipc	ra,0x0
    800009cc:	efc080e7          	jalr	-260(ra) # 800008c4 <push_off>
  if(holding(lk))
    800009d0:	8526                	mv	a0,s1
    800009d2:	00000097          	auipc	ra,0x0
    800009d6:	faa080e7          	jalr	-86(ra) # 8000097c <holding>
    800009da:	e901                	bnez	a0,800009ea <acquire+0x2e>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    800009dc:	4685                	li	a3,1
     __sync_fetch_and_add(&ntest_and_set, 1);
    800009de:	00027717          	auipc	a4,0x27
    800009e2:	64270713          	addi	a4,a4,1602 # 80028020 <ntest_and_set>
    800009e6:	4605                	li	a2,1
    800009e8:	a829                	j	80000a02 <acquire+0x46>
    panic("acquire");
    800009ea:	00006517          	auipc	a0,0x6
    800009ee:	77e50513          	addi	a0,a0,1918 # 80007168 <userret+0xd8>
    800009f2:	00000097          	auipc	ra,0x0
    800009f6:	b56080e7          	jalr	-1194(ra) # 80000548 <panic>
     __sync_fetch_and_add(&ntest_and_set, 1);
    800009fa:	0f50000f          	fence	iorw,ow
    800009fe:	04c7302f          	amoadd.d.aq	zero,a2,(a4)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000a02:	87b6                	mv	a5,a3
    80000a04:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000a08:	2781                	sext.w	a5,a5
    80000a0a:	fbe5                	bnez	a5,800009fa <acquire+0x3e>
  __sync_synchronize();
    80000a0c:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000a10:	00001097          	auipc	ra,0x1
    80000a14:	cf0080e7          	jalr	-784(ra) # 80001700 <mycpu>
    80000a18:	e888                	sd	a0,16(s1)
}
    80000a1a:	60e2                	ld	ra,24(sp)
    80000a1c:	6442                	ld	s0,16(sp)
    80000a1e:	64a2                	ld	s1,8(sp)
    80000a20:	6105                	addi	sp,sp,32
    80000a22:	8082                	ret

0000000080000a24 <release>:
{
    80000a24:	1101                	addi	sp,sp,-32
    80000a26:	ec06                	sd	ra,24(sp)
    80000a28:	e822                	sd	s0,16(sp)
    80000a2a:	e426                	sd	s1,8(sp)
    80000a2c:	1000                	addi	s0,sp,32
    80000a2e:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000a30:	00000097          	auipc	ra,0x0
    80000a34:	f4c080e7          	jalr	-180(ra) # 8000097c <holding>
    80000a38:	c115                	beqz	a0,80000a5c <release+0x38>
  lk->cpu = 0;
    80000a3a:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000a3e:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000a42:	0f50000f          	fence	iorw,ow
    80000a46:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	ec6080e7          	jalr	-314(ra) # 80000910 <pop_off>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6105                	addi	sp,sp,32
    80000a5a:	8082                	ret
    panic("release");
    80000a5c:	00006517          	auipc	a0,0x6
    80000a60:	71450513          	addi	a0,a0,1812 # 80007170 <userret+0xe0>
    80000a64:	00000097          	auipc	ra,0x0
    80000a68:	ae4080e7          	jalr	-1308(ra) # 80000548 <panic>

0000000080000a6c <sys_ntas>:

uint64
sys_ntas(void)
{
    80000a6c:	1141                	addi	sp,sp,-16
    80000a6e:	e422                	sd	s0,8(sp)
    80000a70:	0800                	addi	s0,sp,16
  return ntest_and_set;
}
    80000a72:	00027517          	auipc	a0,0x27
    80000a76:	5ae53503          	ld	a0,1454(a0) # 80028020 <ntest_and_set>
    80000a7a:	6422                	ld	s0,8(sp)
    80000a7c:	0141                	addi	sp,sp,16
    80000a7e:	8082                	ret

0000000080000a80 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000a80:	1141                	addi	sp,sp,-16
    80000a82:	e422                	sd	s0,8(sp)
    80000a84:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000a86:	ca19                	beqz	a2,80000a9c <memset+0x1c>
    80000a88:	87aa                	mv	a5,a0
    80000a8a:	1602                	slli	a2,a2,0x20
    80000a8c:	9201                	srli	a2,a2,0x20
    80000a8e:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000a92:	00b78023          	sb	a1,0(a5) # fffffffffffff000 <end+0xffffffff7ffd6fa4>
  for(i = 0; i < n; i++){
    80000a96:	0785                	addi	a5,a5,1
    80000a98:	fee79de3          	bne	a5,a4,80000a92 <memset+0x12>
  }
  return dst;
}
    80000a9c:	6422                	ld	s0,8(sp)
    80000a9e:	0141                	addi	sp,sp,16
    80000aa0:	8082                	ret

0000000080000aa2 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000aa2:	1141                	addi	sp,sp,-16
    80000aa4:	e422                	sd	s0,8(sp)
    80000aa6:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000aa8:	ca05                	beqz	a2,80000ad8 <memcmp+0x36>
    80000aaa:	fff6069b          	addiw	a3,a2,-1
    80000aae:	1682                	slli	a3,a3,0x20
    80000ab0:	9281                	srli	a3,a3,0x20
    80000ab2:	0685                	addi	a3,a3,1
    80000ab4:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000ab6:	00054783          	lbu	a5,0(a0)
    80000aba:	0005c703          	lbu	a4,0(a1)
    80000abe:	00e79863          	bne	a5,a4,80000ace <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000ac2:	0505                	addi	a0,a0,1
    80000ac4:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000ac6:	fed518e3          	bne	a0,a3,80000ab6 <memcmp+0x14>
  }

  return 0;
    80000aca:	4501                	li	a0,0
    80000acc:	a019                	j	80000ad2 <memcmp+0x30>
      return *s1 - *s2;
    80000ace:	40e7853b          	subw	a0,a5,a4
}
    80000ad2:	6422                	ld	s0,8(sp)
    80000ad4:	0141                	addi	sp,sp,16
    80000ad6:	8082                	ret
  return 0;
    80000ad8:	4501                	li	a0,0
    80000ada:	bfe5                	j	80000ad2 <memcmp+0x30>

0000000080000adc <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000adc:	1141                	addi	sp,sp,-16
    80000ade:	e422                	sd	s0,8(sp)
    80000ae0:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000ae2:	02a5e563          	bltu	a1,a0,80000b0c <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000ae6:	fff6069b          	addiw	a3,a2,-1
    80000aea:	ce11                	beqz	a2,80000b06 <memmove+0x2a>
    80000aec:	1682                	slli	a3,a3,0x20
    80000aee:	9281                	srli	a3,a3,0x20
    80000af0:	0685                	addi	a3,a3,1
    80000af2:	96ae                	add	a3,a3,a1
    80000af4:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000af6:	0585                	addi	a1,a1,1
    80000af8:	0785                	addi	a5,a5,1
    80000afa:	fff5c703          	lbu	a4,-1(a1)
    80000afe:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000b02:	fed59ae3          	bne	a1,a3,80000af6 <memmove+0x1a>

  return dst;
}
    80000b06:	6422                	ld	s0,8(sp)
    80000b08:	0141                	addi	sp,sp,16
    80000b0a:	8082                	ret
  if(s < d && s + n > d){
    80000b0c:	02061713          	slli	a4,a2,0x20
    80000b10:	9301                	srli	a4,a4,0x20
    80000b12:	00e587b3          	add	a5,a1,a4
    80000b16:	fcf578e3          	bgeu	a0,a5,80000ae6 <memmove+0xa>
    d += n;
    80000b1a:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000b1c:	fff6069b          	addiw	a3,a2,-1
    80000b20:	d27d                	beqz	a2,80000b06 <memmove+0x2a>
    80000b22:	02069613          	slli	a2,a3,0x20
    80000b26:	9201                	srli	a2,a2,0x20
    80000b28:	fff64613          	not	a2,a2
    80000b2c:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000b2e:	17fd                	addi	a5,a5,-1
    80000b30:	177d                	addi	a4,a4,-1
    80000b32:	0007c683          	lbu	a3,0(a5)
    80000b36:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000b3a:	fef61ae3          	bne	a2,a5,80000b2e <memmove+0x52>
    80000b3e:	b7e1                	j	80000b06 <memmove+0x2a>

0000000080000b40 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000b40:	1141                	addi	sp,sp,-16
    80000b42:	e406                	sd	ra,8(sp)
    80000b44:	e022                	sd	s0,0(sp)
    80000b46:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000b48:	00000097          	auipc	ra,0x0
    80000b4c:	f94080e7          	jalr	-108(ra) # 80000adc <memmove>
}
    80000b50:	60a2                	ld	ra,8(sp)
    80000b52:	6402                	ld	s0,0(sp)
    80000b54:	0141                	addi	sp,sp,16
    80000b56:	8082                	ret

0000000080000b58 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000b58:	1141                	addi	sp,sp,-16
    80000b5a:	e422                	sd	s0,8(sp)
    80000b5c:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000b5e:	ce11                	beqz	a2,80000b7a <strncmp+0x22>
    80000b60:	00054783          	lbu	a5,0(a0)
    80000b64:	cf89                	beqz	a5,80000b7e <strncmp+0x26>
    80000b66:	0005c703          	lbu	a4,0(a1)
    80000b6a:	00f71a63          	bne	a4,a5,80000b7e <strncmp+0x26>
    n--, p++, q++;
    80000b6e:	367d                	addiw	a2,a2,-1
    80000b70:	0505                	addi	a0,a0,1
    80000b72:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000b74:	f675                	bnez	a2,80000b60 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000b76:	4501                	li	a0,0
    80000b78:	a809                	j	80000b8a <strncmp+0x32>
    80000b7a:	4501                	li	a0,0
    80000b7c:	a039                	j	80000b8a <strncmp+0x32>
  if(n == 0)
    80000b7e:	ca09                	beqz	a2,80000b90 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000b80:	00054503          	lbu	a0,0(a0)
    80000b84:	0005c783          	lbu	a5,0(a1)
    80000b88:	9d1d                	subw	a0,a0,a5
}
    80000b8a:	6422                	ld	s0,8(sp)
    80000b8c:	0141                	addi	sp,sp,16
    80000b8e:	8082                	ret
    return 0;
    80000b90:	4501                	li	a0,0
    80000b92:	bfe5                	j	80000b8a <strncmp+0x32>

0000000080000b94 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000b94:	1141                	addi	sp,sp,-16
    80000b96:	e422                	sd	s0,8(sp)
    80000b98:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000b9a:	872a                	mv	a4,a0
    80000b9c:	8832                	mv	a6,a2
    80000b9e:	367d                	addiw	a2,a2,-1
    80000ba0:	01005963          	blez	a6,80000bb2 <strncpy+0x1e>
    80000ba4:	0705                	addi	a4,a4,1
    80000ba6:	0005c783          	lbu	a5,0(a1)
    80000baa:	fef70fa3          	sb	a5,-1(a4)
    80000bae:	0585                	addi	a1,a1,1
    80000bb0:	f7f5                	bnez	a5,80000b9c <strncpy+0x8>
    ;
  while(n-- > 0)
    80000bb2:	86ba                	mv	a3,a4
    80000bb4:	00c05c63          	blez	a2,80000bcc <strncpy+0x38>
    *s++ = 0;
    80000bb8:	0685                	addi	a3,a3,1
    80000bba:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000bbe:	fff6c793          	not	a5,a3
    80000bc2:	9fb9                	addw	a5,a5,a4
    80000bc4:	010787bb          	addw	a5,a5,a6
    80000bc8:	fef048e3          	bgtz	a5,80000bb8 <strncpy+0x24>
  return os;
}
    80000bcc:	6422                	ld	s0,8(sp)
    80000bce:	0141                	addi	sp,sp,16
    80000bd0:	8082                	ret

0000000080000bd2 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000bd2:	1141                	addi	sp,sp,-16
    80000bd4:	e422                	sd	s0,8(sp)
    80000bd6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000bd8:	02c05363          	blez	a2,80000bfe <safestrcpy+0x2c>
    80000bdc:	fff6069b          	addiw	a3,a2,-1
    80000be0:	1682                	slli	a3,a3,0x20
    80000be2:	9281                	srli	a3,a3,0x20
    80000be4:	96ae                	add	a3,a3,a1
    80000be6:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000be8:	00d58963          	beq	a1,a3,80000bfa <safestrcpy+0x28>
    80000bec:	0585                	addi	a1,a1,1
    80000bee:	0785                	addi	a5,a5,1
    80000bf0:	fff5c703          	lbu	a4,-1(a1)
    80000bf4:	fee78fa3          	sb	a4,-1(a5)
    80000bf8:	fb65                	bnez	a4,80000be8 <safestrcpy+0x16>
    ;
  *s = 0;
    80000bfa:	00078023          	sb	zero,0(a5)
  return os;
}
    80000bfe:	6422                	ld	s0,8(sp)
    80000c00:	0141                	addi	sp,sp,16
    80000c02:	8082                	ret

0000000080000c04 <strlen>:

int
strlen(const char *s)
{
    80000c04:	1141                	addi	sp,sp,-16
    80000c06:	e422                	sd	s0,8(sp)
    80000c08:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000c0a:	00054783          	lbu	a5,0(a0)
    80000c0e:	cf91                	beqz	a5,80000c2a <strlen+0x26>
    80000c10:	0505                	addi	a0,a0,1
    80000c12:	87aa                	mv	a5,a0
    80000c14:	4685                	li	a3,1
    80000c16:	9e89                	subw	a3,a3,a0
    80000c18:	00f6853b          	addw	a0,a3,a5
    80000c1c:	0785                	addi	a5,a5,1
    80000c1e:	fff7c703          	lbu	a4,-1(a5)
    80000c22:	fb7d                	bnez	a4,80000c18 <strlen+0x14>
    ;
  return n;
}
    80000c24:	6422                	ld	s0,8(sp)
    80000c26:	0141                	addi	sp,sp,16
    80000c28:	8082                	ret
  for(n = 0; s[n]; n++)
    80000c2a:	4501                	li	a0,0
    80000c2c:	bfe5                	j	80000c24 <strlen+0x20>

0000000080000c2e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000c2e:	1141                	addi	sp,sp,-16
    80000c30:	e406                	sd	ra,8(sp)
    80000c32:	e022                	sd	s0,0(sp)
    80000c34:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000c36:	00001097          	auipc	ra,0x1
    80000c3a:	aba080e7          	jalr	-1350(ra) # 800016f0 <cpuid>
    virtio_disk_init(minor(ROOTDEV)); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000c3e:	00027717          	auipc	a4,0x27
    80000c42:	3ea70713          	addi	a4,a4,1002 # 80028028 <started>
  if(cpuid() == 0){
    80000c46:	c139                	beqz	a0,80000c8c <main+0x5e>
    while(started == 0)
    80000c48:	431c                	lw	a5,0(a4)
    80000c4a:	2781                	sext.w	a5,a5
    80000c4c:	dff5                	beqz	a5,80000c48 <main+0x1a>
      ;
    __sync_synchronize();
    80000c4e:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000c52:	00001097          	auipc	ra,0x1
    80000c56:	a9e080e7          	jalr	-1378(ra) # 800016f0 <cpuid>
    80000c5a:	85aa                	mv	a1,a0
    80000c5c:	00006517          	auipc	a0,0x6
    80000c60:	53450513          	addi	a0,a0,1332 # 80007190 <userret+0x100>
    80000c64:	00000097          	auipc	ra,0x0
    80000c68:	92e080e7          	jalr	-1746(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000c6c:	00000097          	auipc	ra,0x0
    80000c70:	1ea080e7          	jalr	490(ra) # 80000e56 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000c74:	00001097          	auipc	ra,0x1
    80000c78:	706080e7          	jalr	1798(ra) # 8000237a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000c7c:	00005097          	auipc	ra,0x5
    80000c80:	f64080e7          	jalr	-156(ra) # 80005be0 <plicinithart>
  }

  scheduler();        
    80000c84:	00001097          	auipc	ra,0x1
    80000c88:	fde080e7          	jalr	-34(ra) # 80001c62 <scheduler>
    consoleinit();
    80000c8c:	fffff097          	auipc	ra,0xfffff
    80000c90:	7ce080e7          	jalr	1998(ra) # 8000045a <consoleinit>
    printfinit();
    80000c94:	00000097          	auipc	ra,0x0
    80000c98:	ade080e7          	jalr	-1314(ra) # 80000772 <printfinit>
    printf("\n");
    80000c9c:	00006517          	auipc	a0,0x6
    80000ca0:	50450513          	addi	a0,a0,1284 # 800071a0 <userret+0x110>
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	8ee080e7          	jalr	-1810(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000cac:	00006517          	auipc	a0,0x6
    80000cb0:	4cc50513          	addi	a0,a0,1228 # 80007178 <userret+0xe8>
    80000cb4:	00000097          	auipc	ra,0x0
    80000cb8:	8de080e7          	jalr	-1826(ra) # 80000592 <printf>
    printf("\n");
    80000cbc:	00006517          	auipc	a0,0x6
    80000cc0:	4e450513          	addi	a0,a0,1252 # 800071a0 <userret+0x110>
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	8ce080e7          	jalr	-1842(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000ccc:	00000097          	auipc	ra,0x0
    80000cd0:	b88080e7          	jalr	-1144(ra) # 80000854 <kinit>
    kvminit();       // create kernel page table
    80000cd4:	00000097          	auipc	ra,0x0
    80000cd8:	300080e7          	jalr	768(ra) # 80000fd4 <kvminit>
    kvminithart();   // turn on paging
    80000cdc:	00000097          	auipc	ra,0x0
    80000ce0:	17a080e7          	jalr	378(ra) # 80000e56 <kvminithart>
    procinit();      // process table
    80000ce4:	00001097          	auipc	ra,0x1
    80000ce8:	93c080e7          	jalr	-1732(ra) # 80001620 <procinit>
    trapinit();      // trap vectors
    80000cec:	00001097          	auipc	ra,0x1
    80000cf0:	666080e7          	jalr	1638(ra) # 80002352 <trapinit>
    trapinithart();  // install kernel trap vector
    80000cf4:	00001097          	auipc	ra,0x1
    80000cf8:	686080e7          	jalr	1670(ra) # 8000237a <trapinithart>
    plicinit();      // set up interrupt controller
    80000cfc:	00005097          	auipc	ra,0x5
    80000d00:	ece080e7          	jalr	-306(ra) # 80005bca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000d04:	00005097          	auipc	ra,0x5
    80000d08:	edc080e7          	jalr	-292(ra) # 80005be0 <plicinithart>
    binit();         // buffer cache
    80000d0c:	00002097          	auipc	ra,0x2
    80000d10:	daa080e7          	jalr	-598(ra) # 80002ab6 <binit>
    iinit();         // inode cache
    80000d14:	00002097          	auipc	ra,0x2
    80000d18:	440080e7          	jalr	1088(ra) # 80003154 <iinit>
    fileinit();      // file table
    80000d1c:	00003097          	auipc	ra,0x3
    80000d20:	61e080e7          	jalr	1566(ra) # 8000433a <fileinit>
    virtio_disk_init(minor(ROOTDEV)); // emulated hard disk
    80000d24:	4501                	li	a0,0
    80000d26:	00005097          	auipc	ra,0x5
    80000d2a:	fee080e7          	jalr	-18(ra) # 80005d14 <virtio_disk_init>
    userinit();      // first user process
    80000d2e:	00001097          	auipc	ra,0x1
    80000d32:	c62080e7          	jalr	-926(ra) # 80001990 <userinit>
    __sync_synchronize();
    80000d36:	0ff0000f          	fence
    started = 1;
    80000d3a:	4785                	li	a5,1
    80000d3c:	00027717          	auipc	a4,0x27
    80000d40:	2ef72623          	sw	a5,748(a4) # 80028028 <started>
    80000d44:	b781                	j	80000c84 <main+0x56>

0000000080000d46 <walk>:
//   21..39 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..12 -- 12 bits of byte offset within the page.
static pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000d46:	7139                	addi	sp,sp,-64
    80000d48:	fc06                	sd	ra,56(sp)
    80000d4a:	f822                	sd	s0,48(sp)
    80000d4c:	f426                	sd	s1,40(sp)
    80000d4e:	f04a                	sd	s2,32(sp)
    80000d50:	ec4e                	sd	s3,24(sp)
    80000d52:	e852                	sd	s4,16(sp)
    80000d54:	e456                	sd	s5,8(sp)
    80000d56:	e05a                	sd	s6,0(sp)
    80000d58:	0080                	addi	s0,sp,64
    80000d5a:	84aa                	mv	s1,a0
    80000d5c:	89ae                	mv	s3,a1
    80000d5e:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000d60:	57fd                	li	a5,-1
    80000d62:	83e9                	srli	a5,a5,0x1a
    80000d64:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000d66:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000d68:	04b7f263          	bgeu	a5,a1,80000dac <walk+0x66>
    panic("walk");
    80000d6c:	00006517          	auipc	a0,0x6
    80000d70:	43c50513          	addi	a0,a0,1084 # 800071a8 <userret+0x118>
    80000d74:	fffff097          	auipc	ra,0xfffff
    80000d78:	7d4080e7          	jalr	2004(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000d7c:	060a8663          	beqz	s5,80000de8 <walk+0xa2>
    80000d80:	00000097          	auipc	ra,0x0
    80000d84:	b14080e7          	jalr	-1260(ra) # 80000894 <kalloc>
    80000d88:	84aa                	mv	s1,a0
    80000d8a:	c529                	beqz	a0,80000dd4 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000d8c:	6605                	lui	a2,0x1
    80000d8e:	4581                	li	a1,0
    80000d90:	00000097          	auipc	ra,0x0
    80000d94:	cf0080e7          	jalr	-784(ra) # 80000a80 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000d98:	00c4d793          	srli	a5,s1,0xc
    80000d9c:	07aa                	slli	a5,a5,0xa
    80000d9e:	0017e793          	ori	a5,a5,1
    80000da2:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80000da6:	3a5d                	addiw	s4,s4,-9
    80000da8:	036a0063          	beq	s4,s6,80000dc8 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80000dac:	0149d933          	srl	s2,s3,s4
    80000db0:	1ff97913          	andi	s2,s2,511
    80000db4:	090e                	slli	s2,s2,0x3
    80000db6:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80000db8:	00093483          	ld	s1,0(s2)
    80000dbc:	0014f793          	andi	a5,s1,1
    80000dc0:	dfd5                	beqz	a5,80000d7c <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80000dc2:	80a9                	srli	s1,s1,0xa
    80000dc4:	04b2                	slli	s1,s1,0xc
    80000dc6:	b7c5                	j	80000da6 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80000dc8:	00c9d513          	srli	a0,s3,0xc
    80000dcc:	1ff57513          	andi	a0,a0,511
    80000dd0:	050e                	slli	a0,a0,0x3
    80000dd2:	9526                	add	a0,a0,s1
}
    80000dd4:	70e2                	ld	ra,56(sp)
    80000dd6:	7442                	ld	s0,48(sp)
    80000dd8:	74a2                	ld	s1,40(sp)
    80000dda:	7902                	ld	s2,32(sp)
    80000ddc:	69e2                	ld	s3,24(sp)
    80000dde:	6a42                	ld	s4,16(sp)
    80000de0:	6aa2                	ld	s5,8(sp)
    80000de2:	6b02                	ld	s6,0(sp)
    80000de4:	6121                	addi	sp,sp,64
    80000de6:	8082                	ret
        return 0;
    80000de8:	4501                	li	a0,0
    80000dea:	b7ed                	j	80000dd4 <walk+0x8e>

0000000080000dec <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
static void
freewalk(pagetable_t pagetable)
{
    80000dec:	7179                	addi	sp,sp,-48
    80000dee:	f406                	sd	ra,40(sp)
    80000df0:	f022                	sd	s0,32(sp)
    80000df2:	ec26                	sd	s1,24(sp)
    80000df4:	e84a                	sd	s2,16(sp)
    80000df6:	e44e                	sd	s3,8(sp)
    80000df8:	e052                	sd	s4,0(sp)
    80000dfa:	1800                	addi	s0,sp,48
    80000dfc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80000dfe:	84aa                	mv	s1,a0
    80000e00:	6905                	lui	s2,0x1
    80000e02:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80000e04:	4985                	li	s3,1
    80000e06:	a821                	j	80000e1e <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80000e08:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80000e0a:	0532                	slli	a0,a0,0xc
    80000e0c:	00000097          	auipc	ra,0x0
    80000e10:	fe0080e7          	jalr	-32(ra) # 80000dec <freewalk>
      pagetable[i] = 0;
    80000e14:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80000e18:	04a1                	addi	s1,s1,8
    80000e1a:	03248163          	beq	s1,s2,80000e3c <freewalk+0x50>
    pte_t pte = pagetable[i];
    80000e1e:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80000e20:	00f57793          	andi	a5,a0,15
    80000e24:	ff3782e3          	beq	a5,s3,80000e08 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80000e28:	8905                	andi	a0,a0,1
    80000e2a:	d57d                	beqz	a0,80000e18 <freewalk+0x2c>
      panic("freewalk: leaf");
    80000e2c:	00006517          	auipc	a0,0x6
    80000e30:	38450513          	addi	a0,a0,900 # 800071b0 <userret+0x120>
    80000e34:	fffff097          	auipc	ra,0xfffff
    80000e38:	714080e7          	jalr	1812(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    80000e3c:	8552                	mv	a0,s4
    80000e3e:	00000097          	auipc	ra,0x0
    80000e42:	a3e080e7          	jalr	-1474(ra) # 8000087c <kfree>
}
    80000e46:	70a2                	ld	ra,40(sp)
    80000e48:	7402                	ld	s0,32(sp)
    80000e4a:	64e2                	ld	s1,24(sp)
    80000e4c:	6942                	ld	s2,16(sp)
    80000e4e:	69a2                	ld	s3,8(sp)
    80000e50:	6a02                	ld	s4,0(sp)
    80000e52:	6145                	addi	sp,sp,48
    80000e54:	8082                	ret

0000000080000e56 <kvminithart>:
{
    80000e56:	1141                	addi	sp,sp,-16
    80000e58:	e422                	sd	s0,8(sp)
    80000e5a:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000e5c:	00027797          	auipc	a5,0x27
    80000e60:	1d47b783          	ld	a5,468(a5) # 80028030 <kernel_pagetable>
    80000e64:	83b1                	srli	a5,a5,0xc
    80000e66:	577d                	li	a4,-1
    80000e68:	177e                	slli	a4,a4,0x3f
    80000e6a:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000e6c:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000e70:	12000073          	sfence.vma
}
    80000e74:	6422                	ld	s0,8(sp)
    80000e76:	0141                	addi	sp,sp,16
    80000e78:	8082                	ret

0000000080000e7a <walkaddr>:
{
    80000e7a:	1141                	addi	sp,sp,-16
    80000e7c:	e406                	sd	ra,8(sp)
    80000e7e:	e022                	sd	s0,0(sp)
    80000e80:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80000e82:	4601                	li	a2,0
    80000e84:	00000097          	auipc	ra,0x0
    80000e88:	ec2080e7          	jalr	-318(ra) # 80000d46 <walk>
  if(pte == 0)
    80000e8c:	c105                	beqz	a0,80000eac <walkaddr+0x32>
  if((*pte & PTE_V) == 0)
    80000e8e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80000e90:	0117f693          	andi	a3,a5,17
    80000e94:	4745                	li	a4,17
    return 0;
    80000e96:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80000e98:	00e68663          	beq	a3,a4,80000ea4 <walkaddr+0x2a>
}
    80000e9c:	60a2                	ld	ra,8(sp)
    80000e9e:	6402                	ld	s0,0(sp)
    80000ea0:	0141                	addi	sp,sp,16
    80000ea2:	8082                	ret
  pa = PTE2PA(*pte);
    80000ea4:	83a9                	srli	a5,a5,0xa
    80000ea6:	00c79513          	slli	a0,a5,0xc
  return pa;
    80000eaa:	bfcd                	j	80000e9c <walkaddr+0x22>
    return 0;
    80000eac:	4501                	li	a0,0
    80000eae:	b7fd                	j	80000e9c <walkaddr+0x22>

0000000080000eb0 <kvmpa>:
{
    80000eb0:	1101                	addi	sp,sp,-32
    80000eb2:	ec06                	sd	ra,24(sp)
    80000eb4:	e822                	sd	s0,16(sp)
    80000eb6:	e426                	sd	s1,8(sp)
    80000eb8:	1000                	addi	s0,sp,32
    80000eba:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    80000ebc:	1552                	slli	a0,a0,0x34
    80000ebe:	03455493          	srli	s1,a0,0x34
  pte = walk(kernel_pagetable, va, 0);
    80000ec2:	4601                	li	a2,0
    80000ec4:	00027517          	auipc	a0,0x27
    80000ec8:	16c53503          	ld	a0,364(a0) # 80028030 <kernel_pagetable>
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	e7a080e7          	jalr	-390(ra) # 80000d46 <walk>
  if(pte == 0)
    80000ed4:	cd09                	beqz	a0,80000eee <kvmpa+0x3e>
  if((*pte & PTE_V) == 0)
    80000ed6:	6108                	ld	a0,0(a0)
    80000ed8:	00157793          	andi	a5,a0,1
    80000edc:	c38d                	beqz	a5,80000efe <kvmpa+0x4e>
  pa = PTE2PA(*pte);
    80000ede:	8129                	srli	a0,a0,0xa
    80000ee0:	0532                	slli	a0,a0,0xc
}
    80000ee2:	9526                	add	a0,a0,s1
    80000ee4:	60e2                	ld	ra,24(sp)
    80000ee6:	6442                	ld	s0,16(sp)
    80000ee8:	64a2                	ld	s1,8(sp)
    80000eea:	6105                	addi	sp,sp,32
    80000eec:	8082                	ret
    panic("kvmpa");
    80000eee:	00006517          	auipc	a0,0x6
    80000ef2:	2d250513          	addi	a0,a0,722 # 800071c0 <userret+0x130>
    80000ef6:	fffff097          	auipc	ra,0xfffff
    80000efa:	652080e7          	jalr	1618(ra) # 80000548 <panic>
    panic("kvmpa");
    80000efe:	00006517          	auipc	a0,0x6
    80000f02:	2c250513          	addi	a0,a0,706 # 800071c0 <userret+0x130>
    80000f06:	fffff097          	auipc	ra,0xfffff
    80000f0a:	642080e7          	jalr	1602(ra) # 80000548 <panic>

0000000080000f0e <mappages>:
{
    80000f0e:	715d                	addi	sp,sp,-80
    80000f10:	e486                	sd	ra,72(sp)
    80000f12:	e0a2                	sd	s0,64(sp)
    80000f14:	fc26                	sd	s1,56(sp)
    80000f16:	f84a                	sd	s2,48(sp)
    80000f18:	f44e                	sd	s3,40(sp)
    80000f1a:	f052                	sd	s4,32(sp)
    80000f1c:	ec56                	sd	s5,24(sp)
    80000f1e:	e85a                	sd	s6,16(sp)
    80000f20:	e45e                	sd	s7,8(sp)
    80000f22:	0880                	addi	s0,sp,80
    80000f24:	8aaa                	mv	s5,a0
    80000f26:	8b3a                	mv	s6,a4
  a = PGROUNDDOWN(va);
    80000f28:	777d                	lui	a4,0xfffff
    80000f2a:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80000f2e:	167d                	addi	a2,a2,-1
    80000f30:	00b609b3          	add	s3,a2,a1
    80000f34:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80000f38:	893e                	mv	s2,a5
    80000f3a:	40f68a33          	sub	s4,a3,a5
    a += PGSIZE;
    80000f3e:	6b85                	lui	s7,0x1
    80000f40:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80000f44:	4605                	li	a2,1
    80000f46:	85ca                	mv	a1,s2
    80000f48:	8556                	mv	a0,s5
    80000f4a:	00000097          	auipc	ra,0x0
    80000f4e:	dfc080e7          	jalr	-516(ra) # 80000d46 <walk>
    80000f52:	c51d                	beqz	a0,80000f80 <mappages+0x72>
    if(*pte & PTE_V)
    80000f54:	611c                	ld	a5,0(a0)
    80000f56:	8b85                	andi	a5,a5,1
    80000f58:	ef81                	bnez	a5,80000f70 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80000f5a:	80b1                	srli	s1,s1,0xc
    80000f5c:	04aa                	slli	s1,s1,0xa
    80000f5e:	0164e4b3          	or	s1,s1,s6
    80000f62:	0014e493          	ori	s1,s1,1
    80000f66:	e104                	sd	s1,0(a0)
    if(a == last)
    80000f68:	03390863          	beq	s2,s3,80000f98 <mappages+0x8a>
    a += PGSIZE;
    80000f6c:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80000f6e:	bfc9                	j	80000f40 <mappages+0x32>
      panic("remap");
    80000f70:	00006517          	auipc	a0,0x6
    80000f74:	25850513          	addi	a0,a0,600 # 800071c8 <userret+0x138>
    80000f78:	fffff097          	auipc	ra,0xfffff
    80000f7c:	5d0080e7          	jalr	1488(ra) # 80000548 <panic>
      return -1;
    80000f80:	557d                	li	a0,-1
}
    80000f82:	60a6                	ld	ra,72(sp)
    80000f84:	6406                	ld	s0,64(sp)
    80000f86:	74e2                	ld	s1,56(sp)
    80000f88:	7942                	ld	s2,48(sp)
    80000f8a:	79a2                	ld	s3,40(sp)
    80000f8c:	7a02                	ld	s4,32(sp)
    80000f8e:	6ae2                	ld	s5,24(sp)
    80000f90:	6b42                	ld	s6,16(sp)
    80000f92:	6ba2                	ld	s7,8(sp)
    80000f94:	6161                	addi	sp,sp,80
    80000f96:	8082                	ret
  return 0;
    80000f98:	4501                	li	a0,0
    80000f9a:	b7e5                	j	80000f82 <mappages+0x74>

0000000080000f9c <kvmmap>:
{
    80000f9c:	1141                	addi	sp,sp,-16
    80000f9e:	e406                	sd	ra,8(sp)
    80000fa0:	e022                	sd	s0,0(sp)
    80000fa2:	0800                	addi	s0,sp,16
    80000fa4:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80000fa6:	86ae                	mv	a3,a1
    80000fa8:	85aa                	mv	a1,a0
    80000faa:	00027517          	auipc	a0,0x27
    80000fae:	08653503          	ld	a0,134(a0) # 80028030 <kernel_pagetable>
    80000fb2:	00000097          	auipc	ra,0x0
    80000fb6:	f5c080e7          	jalr	-164(ra) # 80000f0e <mappages>
    80000fba:	e509                	bnez	a0,80000fc4 <kvmmap+0x28>
}
    80000fbc:	60a2                	ld	ra,8(sp)
    80000fbe:	6402                	ld	s0,0(sp)
    80000fc0:	0141                	addi	sp,sp,16
    80000fc2:	8082                	ret
    panic("kvmmap");
    80000fc4:	00006517          	auipc	a0,0x6
    80000fc8:	20c50513          	addi	a0,a0,524 # 800071d0 <userret+0x140>
    80000fcc:	fffff097          	auipc	ra,0xfffff
    80000fd0:	57c080e7          	jalr	1404(ra) # 80000548 <panic>

0000000080000fd4 <kvminit>:
{
    80000fd4:	1101                	addi	sp,sp,-32
    80000fd6:	ec06                	sd	ra,24(sp)
    80000fd8:	e822                	sd	s0,16(sp)
    80000fda:	e426                	sd	s1,8(sp)
    80000fdc:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80000fde:	00000097          	auipc	ra,0x0
    80000fe2:	8b6080e7          	jalr	-1866(ra) # 80000894 <kalloc>
    80000fe6:	00027797          	auipc	a5,0x27
    80000fea:	04a7b523          	sd	a0,74(a5) # 80028030 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80000fee:	6605                	lui	a2,0x1
    80000ff0:	4581                	li	a1,0
    80000ff2:	00000097          	auipc	ra,0x0
    80000ff6:	a8e080e7          	jalr	-1394(ra) # 80000a80 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80000ffa:	4699                	li	a3,6
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	100005b7          	lui	a1,0x10000
    80001002:	10000537          	lui	a0,0x10000
    80001006:	00000097          	auipc	ra,0x0
    8000100a:	f96080e7          	jalr	-106(ra) # 80000f9c <kvmmap>
  kvmmap(VIRTION(0), VIRTION(0), PGSIZE, PTE_R | PTE_W);
    8000100e:	4699                	li	a3,6
    80001010:	6605                	lui	a2,0x1
    80001012:	100015b7          	lui	a1,0x10001
    80001016:	10001537          	lui	a0,0x10001
    8000101a:	00000097          	auipc	ra,0x0
    8000101e:	f82080e7          	jalr	-126(ra) # 80000f9c <kvmmap>
  kvmmap(VIRTION(1), VIRTION(1), PGSIZE, PTE_R | PTE_W);
    80001022:	4699                	li	a3,6
    80001024:	6605                	lui	a2,0x1
    80001026:	100025b7          	lui	a1,0x10002
    8000102a:	10002537          	lui	a0,0x10002
    8000102e:	00000097          	auipc	ra,0x0
    80001032:	f6e080e7          	jalr	-146(ra) # 80000f9c <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    80001036:	4699                	li	a3,6
    80001038:	6641                	lui	a2,0x10
    8000103a:	020005b7          	lui	a1,0x2000
    8000103e:	02000537          	lui	a0,0x2000
    80001042:	00000097          	auipc	ra,0x0
    80001046:	f5a080e7          	jalr	-166(ra) # 80000f9c <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000104a:	4699                	li	a3,6
    8000104c:	00400637          	lui	a2,0x400
    80001050:	0c0005b7          	lui	a1,0xc000
    80001054:	0c000537          	lui	a0,0xc000
    80001058:	00000097          	auipc	ra,0x0
    8000105c:	f44080e7          	jalr	-188(ra) # 80000f9c <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001060:	00007497          	auipc	s1,0x7
    80001064:	fa048493          	addi	s1,s1,-96 # 80008000 <initcode>
    80001068:	46a9                	li	a3,10
    8000106a:	80007617          	auipc	a2,0x80007
    8000106e:	f9660613          	addi	a2,a2,-106 # 8000 <_entry-0x7fff8000>
    80001072:	4585                	li	a1,1
    80001074:	05fe                	slli	a1,a1,0x1f
    80001076:	852e                	mv	a0,a1
    80001078:	00000097          	auipc	ra,0x0
    8000107c:	f24080e7          	jalr	-220(ra) # 80000f9c <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001080:	4699                	li	a3,6
    80001082:	4645                	li	a2,17
    80001084:	066e                	slli	a2,a2,0x1b
    80001086:	8e05                	sub	a2,a2,s1
    80001088:	85a6                	mv	a1,s1
    8000108a:	8526                	mv	a0,s1
    8000108c:	00000097          	auipc	ra,0x0
    80001090:	f10080e7          	jalr	-240(ra) # 80000f9c <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001094:	46a9                	li	a3,10
    80001096:	6605                	lui	a2,0x1
    80001098:	00006597          	auipc	a1,0x6
    8000109c:	f6858593          	addi	a1,a1,-152 # 80007000 <trampoline>
    800010a0:	04000537          	lui	a0,0x4000
    800010a4:	157d                	addi	a0,a0,-1
    800010a6:	0532                	slli	a0,a0,0xc
    800010a8:	00000097          	auipc	ra,0x0
    800010ac:	ef4080e7          	jalr	-268(ra) # 80000f9c <kvmmap>
}
    800010b0:	60e2                	ld	ra,24(sp)
    800010b2:	6442                	ld	s0,16(sp)
    800010b4:	64a2                	ld	s1,8(sp)
    800010b6:	6105                	addi	sp,sp,32
    800010b8:	8082                	ret

00000000800010ba <uvmunmap>:
{
    800010ba:	715d                	addi	sp,sp,-80
    800010bc:	e486                	sd	ra,72(sp)
    800010be:	e0a2                	sd	s0,64(sp)
    800010c0:	fc26                	sd	s1,56(sp)
    800010c2:	f84a                	sd	s2,48(sp)
    800010c4:	f44e                	sd	s3,40(sp)
    800010c6:	f052                	sd	s4,32(sp)
    800010c8:	ec56                	sd	s5,24(sp)
    800010ca:	e85a                	sd	s6,16(sp)
    800010cc:	e45e                	sd	s7,8(sp)
    800010ce:	0880                	addi	s0,sp,80
    800010d0:	8a2a                	mv	s4,a0
    800010d2:	8ab6                	mv	s5,a3
  a = PGROUNDDOWN(va);
    800010d4:	77fd                	lui	a5,0xfffff
    800010d6:	00f5f933          	and	s2,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010da:	167d                	addi	a2,a2,-1
    800010dc:	00b609b3          	add	s3,a2,a1
    800010e0:	00f9f9b3          	and	s3,s3,a5
    if(PTE_FLAGS(*pte) == PTE_V)
    800010e4:	4b05                	li	s6,1
    a += PGSIZE;
    800010e6:	6b85                	lui	s7,0x1
    800010e8:	a0b9                	j	80001136 <uvmunmap+0x7c>
      panic("uvmunmap: walk");
    800010ea:	00006517          	auipc	a0,0x6
    800010ee:	0ee50513          	addi	a0,a0,238 # 800071d8 <userret+0x148>
    800010f2:	fffff097          	auipc	ra,0xfffff
    800010f6:	456080e7          	jalr	1110(ra) # 80000548 <panic>
      printf("va=%p pte=%p\n", a, *pte);
    800010fa:	85ca                	mv	a1,s2
    800010fc:	00006517          	auipc	a0,0x6
    80001100:	0ec50513          	addi	a0,a0,236 # 800071e8 <userret+0x158>
    80001104:	fffff097          	auipc	ra,0xfffff
    80001108:	48e080e7          	jalr	1166(ra) # 80000592 <printf>
      panic("uvmunmap: not mapped");
    8000110c:	00006517          	auipc	a0,0x6
    80001110:	0ec50513          	addi	a0,a0,236 # 800071f8 <userret+0x168>
    80001114:	fffff097          	auipc	ra,0xfffff
    80001118:	434080e7          	jalr	1076(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    8000111c:	00006517          	auipc	a0,0x6
    80001120:	0f450513          	addi	a0,a0,244 # 80007210 <userret+0x180>
    80001124:	fffff097          	auipc	ra,0xfffff
    80001128:	424080e7          	jalr	1060(ra) # 80000548 <panic>
    *pte = 0;
    8000112c:	0004b023          	sd	zero,0(s1)
    if(a == last)
    80001130:	03390e63          	beq	s2,s3,8000116c <uvmunmap+0xb2>
    a += PGSIZE;
    80001134:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 0)) == 0)
    80001136:	4601                	li	a2,0
    80001138:	85ca                	mv	a1,s2
    8000113a:	8552                	mv	a0,s4
    8000113c:	00000097          	auipc	ra,0x0
    80001140:	c0a080e7          	jalr	-1014(ra) # 80000d46 <walk>
    80001144:	84aa                	mv	s1,a0
    80001146:	d155                	beqz	a0,800010ea <uvmunmap+0x30>
    if((*pte & PTE_V) == 0){
    80001148:	6110                	ld	a2,0(a0)
    8000114a:	00167793          	andi	a5,a2,1
    8000114e:	d7d5                	beqz	a5,800010fa <uvmunmap+0x40>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001150:	3ff67793          	andi	a5,a2,1023
    80001154:	fd6784e3          	beq	a5,s6,8000111c <uvmunmap+0x62>
    if(do_free){
    80001158:	fc0a8ae3          	beqz	s5,8000112c <uvmunmap+0x72>
      pa = PTE2PA(*pte);
    8000115c:	8229                	srli	a2,a2,0xa
      kfree((void*)pa);
    8000115e:	00c61513          	slli	a0,a2,0xc
    80001162:	fffff097          	auipc	ra,0xfffff
    80001166:	71a080e7          	jalr	1818(ra) # 8000087c <kfree>
    8000116a:	b7c9                	j	8000112c <uvmunmap+0x72>
}
    8000116c:	60a6                	ld	ra,72(sp)
    8000116e:	6406                	ld	s0,64(sp)
    80001170:	74e2                	ld	s1,56(sp)
    80001172:	7942                	ld	s2,48(sp)
    80001174:	79a2                	ld	s3,40(sp)
    80001176:	7a02                	ld	s4,32(sp)
    80001178:	6ae2                	ld	s5,24(sp)
    8000117a:	6b42                	ld	s6,16(sp)
    8000117c:	6ba2                	ld	s7,8(sp)
    8000117e:	6161                	addi	sp,sp,80
    80001180:	8082                	ret

0000000080001182 <uvmcreate>:
{
    80001182:	1101                	addi	sp,sp,-32
    80001184:	ec06                	sd	ra,24(sp)
    80001186:	e822                	sd	s0,16(sp)
    80001188:	e426                	sd	s1,8(sp)
    8000118a:	1000                	addi	s0,sp,32
  pagetable = (pagetable_t) kalloc();
    8000118c:	fffff097          	auipc	ra,0xfffff
    80001190:	708080e7          	jalr	1800(ra) # 80000894 <kalloc>
  if(pagetable == 0)
    80001194:	cd11                	beqz	a0,800011b0 <uvmcreate+0x2e>
    80001196:	84aa                	mv	s1,a0
  memset(pagetable, 0, PGSIZE);
    80001198:	6605                	lui	a2,0x1
    8000119a:	4581                	li	a1,0
    8000119c:	00000097          	auipc	ra,0x0
    800011a0:	8e4080e7          	jalr	-1820(ra) # 80000a80 <memset>
}
    800011a4:	8526                	mv	a0,s1
    800011a6:	60e2                	ld	ra,24(sp)
    800011a8:	6442                	ld	s0,16(sp)
    800011aa:	64a2                	ld	s1,8(sp)
    800011ac:	6105                	addi	sp,sp,32
    800011ae:	8082                	ret
    panic("uvmcreate: out of memory");
    800011b0:	00006517          	auipc	a0,0x6
    800011b4:	07850513          	addi	a0,a0,120 # 80007228 <userret+0x198>
    800011b8:	fffff097          	auipc	ra,0xfffff
    800011bc:	390080e7          	jalr	912(ra) # 80000548 <panic>

00000000800011c0 <uvminit>:
{
    800011c0:	7179                	addi	sp,sp,-48
    800011c2:	f406                	sd	ra,40(sp)
    800011c4:	f022                	sd	s0,32(sp)
    800011c6:	ec26                	sd	s1,24(sp)
    800011c8:	e84a                	sd	s2,16(sp)
    800011ca:	e44e                	sd	s3,8(sp)
    800011cc:	e052                	sd	s4,0(sp)
    800011ce:	1800                	addi	s0,sp,48
  if(sz >= PGSIZE)
    800011d0:	6785                	lui	a5,0x1
    800011d2:	04f67863          	bgeu	a2,a5,80001222 <uvminit+0x62>
    800011d6:	8a2a                	mv	s4,a0
    800011d8:	89ae                	mv	s3,a1
    800011da:	84b2                	mv	s1,a2
  mem = kalloc();
    800011dc:	fffff097          	auipc	ra,0xfffff
    800011e0:	6b8080e7          	jalr	1720(ra) # 80000894 <kalloc>
    800011e4:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800011e6:	6605                	lui	a2,0x1
    800011e8:	4581                	li	a1,0
    800011ea:	00000097          	auipc	ra,0x0
    800011ee:	896080e7          	jalr	-1898(ra) # 80000a80 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800011f2:	4779                	li	a4,30
    800011f4:	86ca                	mv	a3,s2
    800011f6:	6605                	lui	a2,0x1
    800011f8:	4581                	li	a1,0
    800011fa:	8552                	mv	a0,s4
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	d12080e7          	jalr	-750(ra) # 80000f0e <mappages>
  memmove(mem, src, sz);
    80001204:	8626                	mv	a2,s1
    80001206:	85ce                	mv	a1,s3
    80001208:	854a                	mv	a0,s2
    8000120a:	00000097          	auipc	ra,0x0
    8000120e:	8d2080e7          	jalr	-1838(ra) # 80000adc <memmove>
}
    80001212:	70a2                	ld	ra,40(sp)
    80001214:	7402                	ld	s0,32(sp)
    80001216:	64e2                	ld	s1,24(sp)
    80001218:	6942                	ld	s2,16(sp)
    8000121a:	69a2                	ld	s3,8(sp)
    8000121c:	6a02                	ld	s4,0(sp)
    8000121e:	6145                	addi	sp,sp,48
    80001220:	8082                	ret
    panic("inituvm: more than a page");
    80001222:	00006517          	auipc	a0,0x6
    80001226:	02650513          	addi	a0,a0,38 # 80007248 <userret+0x1b8>
    8000122a:	fffff097          	auipc	ra,0xfffff
    8000122e:	31e080e7          	jalr	798(ra) # 80000548 <panic>

0000000080001232 <uvmdealloc>:
{
    80001232:	87aa                	mv	a5,a0
    80001234:	852e                	mv	a0,a1
  if(newsz >= oldsz)
    80001236:	00b66363          	bltu	a2,a1,8000123c <uvmdealloc+0xa>
}
    8000123a:	8082                	ret
{
    8000123c:	1101                	addi	sp,sp,-32
    8000123e:	ec06                	sd	ra,24(sp)
    80001240:	e822                	sd	s0,16(sp)
    80001242:	e426                	sd	s1,8(sp)
    80001244:	1000                	addi	s0,sp,32
    80001246:	84b2                	mv	s1,a2
  uvmunmap(pagetable, newsz, oldsz - newsz, 1);
    80001248:	4685                	li	a3,1
    8000124a:	40c58633          	sub	a2,a1,a2
    8000124e:	85a6                	mv	a1,s1
    80001250:	853e                	mv	a0,a5
    80001252:	00000097          	auipc	ra,0x0
    80001256:	e68080e7          	jalr	-408(ra) # 800010ba <uvmunmap>
  return newsz;
    8000125a:	8526                	mv	a0,s1
}
    8000125c:	60e2                	ld	ra,24(sp)
    8000125e:	6442                	ld	s0,16(sp)
    80001260:	64a2                	ld	s1,8(sp)
    80001262:	6105                	addi	sp,sp,32
    80001264:	8082                	ret

0000000080001266 <uvmalloc>:
  if(newsz < oldsz)
    80001266:	0ab66163          	bltu	a2,a1,80001308 <uvmalloc+0xa2>
{
    8000126a:	7139                	addi	sp,sp,-64
    8000126c:	fc06                	sd	ra,56(sp)
    8000126e:	f822                	sd	s0,48(sp)
    80001270:	f426                	sd	s1,40(sp)
    80001272:	f04a                	sd	s2,32(sp)
    80001274:	ec4e                	sd	s3,24(sp)
    80001276:	e852                	sd	s4,16(sp)
    80001278:	e456                	sd	s5,8(sp)
    8000127a:	0080                	addi	s0,sp,64
    8000127c:	8aaa                	mv	s5,a0
    8000127e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001280:	6985                	lui	s3,0x1
    80001282:	19fd                	addi	s3,s3,-1
    80001284:	95ce                	add	a1,a1,s3
    80001286:	79fd                	lui	s3,0xfffff
    80001288:	0135f9b3          	and	s3,a1,s3
  for(; a < newsz; a += PGSIZE){
    8000128c:	08c9f063          	bgeu	s3,a2,8000130c <uvmalloc+0xa6>
  a = oldsz;
    80001290:	894e                	mv	s2,s3
    mem = kalloc();
    80001292:	fffff097          	auipc	ra,0xfffff
    80001296:	602080e7          	jalr	1538(ra) # 80000894 <kalloc>
    8000129a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000129c:	c51d                	beqz	a0,800012ca <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000129e:	6605                	lui	a2,0x1
    800012a0:	4581                	li	a1,0
    800012a2:	fffff097          	auipc	ra,0xfffff
    800012a6:	7de080e7          	jalr	2014(ra) # 80000a80 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800012aa:	4779                	li	a4,30
    800012ac:	86a6                	mv	a3,s1
    800012ae:	6605                	lui	a2,0x1
    800012b0:	85ca                	mv	a1,s2
    800012b2:	8556                	mv	a0,s5
    800012b4:	00000097          	auipc	ra,0x0
    800012b8:	c5a080e7          	jalr	-934(ra) # 80000f0e <mappages>
    800012bc:	e905                	bnez	a0,800012ec <uvmalloc+0x86>
  for(; a < newsz; a += PGSIZE){
    800012be:	6785                	lui	a5,0x1
    800012c0:	993e                	add	s2,s2,a5
    800012c2:	fd4968e3          	bltu	s2,s4,80001292 <uvmalloc+0x2c>
  return newsz;
    800012c6:	8552                	mv	a0,s4
    800012c8:	a809                	j	800012da <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800012ca:	864e                	mv	a2,s3
    800012cc:	85ca                	mv	a1,s2
    800012ce:	8556                	mv	a0,s5
    800012d0:	00000097          	auipc	ra,0x0
    800012d4:	f62080e7          	jalr	-158(ra) # 80001232 <uvmdealloc>
      return 0;
    800012d8:	4501                	li	a0,0
}
    800012da:	70e2                	ld	ra,56(sp)
    800012dc:	7442                	ld	s0,48(sp)
    800012de:	74a2                	ld	s1,40(sp)
    800012e0:	7902                	ld	s2,32(sp)
    800012e2:	69e2                	ld	s3,24(sp)
    800012e4:	6a42                	ld	s4,16(sp)
    800012e6:	6aa2                	ld	s5,8(sp)
    800012e8:	6121                	addi	sp,sp,64
    800012ea:	8082                	ret
      kfree(mem);
    800012ec:	8526                	mv	a0,s1
    800012ee:	fffff097          	auipc	ra,0xfffff
    800012f2:	58e080e7          	jalr	1422(ra) # 8000087c <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800012f6:	864e                	mv	a2,s3
    800012f8:	85ca                	mv	a1,s2
    800012fa:	8556                	mv	a0,s5
    800012fc:	00000097          	auipc	ra,0x0
    80001300:	f36080e7          	jalr	-202(ra) # 80001232 <uvmdealloc>
      return 0;
    80001304:	4501                	li	a0,0
    80001306:	bfd1                	j	800012da <uvmalloc+0x74>
    return oldsz;
    80001308:	852e                	mv	a0,a1
}
    8000130a:	8082                	ret
  return newsz;
    8000130c:	8532                	mv	a0,a2
    8000130e:	b7f1                	j	800012da <uvmalloc+0x74>

0000000080001310 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001310:	1101                	addi	sp,sp,-32
    80001312:	ec06                	sd	ra,24(sp)
    80001314:	e822                	sd	s0,16(sp)
    80001316:	e426                	sd	s1,8(sp)
    80001318:	1000                	addi	s0,sp,32
    8000131a:	84aa                	mv	s1,a0
    8000131c:	862e                	mv	a2,a1
  uvmunmap(pagetable, 0, sz, 1);
    8000131e:	4685                	li	a3,1
    80001320:	4581                	li	a1,0
    80001322:	00000097          	auipc	ra,0x0
    80001326:	d98080e7          	jalr	-616(ra) # 800010ba <uvmunmap>
  freewalk(pagetable);
    8000132a:	8526                	mv	a0,s1
    8000132c:	00000097          	auipc	ra,0x0
    80001330:	ac0080e7          	jalr	-1344(ra) # 80000dec <freewalk>
}
    80001334:	60e2                	ld	ra,24(sp)
    80001336:	6442                	ld	s0,16(sp)
    80001338:	64a2                	ld	s1,8(sp)
    8000133a:	6105                	addi	sp,sp,32
    8000133c:	8082                	ret

000000008000133e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000133e:	c671                	beqz	a2,8000140a <uvmcopy+0xcc>
{
    80001340:	715d                	addi	sp,sp,-80
    80001342:	e486                	sd	ra,72(sp)
    80001344:	e0a2                	sd	s0,64(sp)
    80001346:	fc26                	sd	s1,56(sp)
    80001348:	f84a                	sd	s2,48(sp)
    8000134a:	f44e                	sd	s3,40(sp)
    8000134c:	f052                	sd	s4,32(sp)
    8000134e:	ec56                	sd	s5,24(sp)
    80001350:	e85a                	sd	s6,16(sp)
    80001352:	e45e                	sd	s7,8(sp)
    80001354:	0880                	addi	s0,sp,80
    80001356:	8b2a                	mv	s6,a0
    80001358:	8aae                	mv	s5,a1
    8000135a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000135c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000135e:	4601                	li	a2,0
    80001360:	85ce                	mv	a1,s3
    80001362:	855a                	mv	a0,s6
    80001364:	00000097          	auipc	ra,0x0
    80001368:	9e2080e7          	jalr	-1566(ra) # 80000d46 <walk>
    8000136c:	c531                	beqz	a0,800013b8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000136e:	6118                	ld	a4,0(a0)
    80001370:	00177793          	andi	a5,a4,1
    80001374:	cbb1                	beqz	a5,800013c8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001376:	00a75593          	srli	a1,a4,0xa
    8000137a:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000137e:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001382:	fffff097          	auipc	ra,0xfffff
    80001386:	512080e7          	jalr	1298(ra) # 80000894 <kalloc>
    8000138a:	892a                	mv	s2,a0
    8000138c:	c939                	beqz	a0,800013e2 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	85de                	mv	a1,s7
    80001392:	fffff097          	auipc	ra,0xfffff
    80001396:	74a080e7          	jalr	1866(ra) # 80000adc <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000139a:	8726                	mv	a4,s1
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	85ce                	mv	a1,s3
    800013a2:	8556                	mv	a0,s5
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	b6a080e7          	jalr	-1174(ra) # 80000f0e <mappages>
    800013ac:	e515                	bnez	a0,800013d8 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800013ae:	6785                	lui	a5,0x1
    800013b0:	99be                	add	s3,s3,a5
    800013b2:	fb49e6e3          	bltu	s3,s4,8000135e <uvmcopy+0x20>
    800013b6:	a83d                	j	800013f4 <uvmcopy+0xb6>
      panic("uvmcopy: pte should exist");
    800013b8:	00006517          	auipc	a0,0x6
    800013bc:	eb050513          	addi	a0,a0,-336 # 80007268 <userret+0x1d8>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	188080e7          	jalr	392(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    800013c8:	00006517          	auipc	a0,0x6
    800013cc:	ec050513          	addi	a0,a0,-320 # 80007288 <userret+0x1f8>
    800013d0:	fffff097          	auipc	ra,0xfffff
    800013d4:	178080e7          	jalr	376(ra) # 80000548 <panic>
      kfree(mem);
    800013d8:	854a                	mv	a0,s2
    800013da:	fffff097          	auipc	ra,0xfffff
    800013de:	4a2080e7          	jalr	1186(ra) # 8000087c <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i, 1);
    800013e2:	4685                	li	a3,1
    800013e4:	864e                	mv	a2,s3
    800013e6:	4581                	li	a1,0
    800013e8:	8556                	mv	a0,s5
    800013ea:	00000097          	auipc	ra,0x0
    800013ee:	cd0080e7          	jalr	-816(ra) # 800010ba <uvmunmap>
  return -1;
    800013f2:	557d                	li	a0,-1
}
    800013f4:	60a6                	ld	ra,72(sp)
    800013f6:	6406                	ld	s0,64(sp)
    800013f8:	74e2                	ld	s1,56(sp)
    800013fa:	7942                	ld	s2,48(sp)
    800013fc:	79a2                	ld	s3,40(sp)
    800013fe:	7a02                	ld	s4,32(sp)
    80001400:	6ae2                	ld	s5,24(sp)
    80001402:	6b42                	ld	s6,16(sp)
    80001404:	6ba2                	ld	s7,8(sp)
    80001406:	6161                	addi	sp,sp,80
    80001408:	8082                	ret
  return 0;
    8000140a:	4501                	li	a0,0
}
    8000140c:	8082                	ret

000000008000140e <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000140e:	1141                	addi	sp,sp,-16
    80001410:	e406                	sd	ra,8(sp)
    80001412:	e022                	sd	s0,0(sp)
    80001414:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001416:	4601                	li	a2,0
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	92e080e7          	jalr	-1746(ra) # 80000d46 <walk>
  if(pte == 0)
    80001420:	c901                	beqz	a0,80001430 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001422:	611c                	ld	a5,0(a0)
    80001424:	9bbd                	andi	a5,a5,-17
    80001426:	e11c                	sd	a5,0(a0)
}
    80001428:	60a2                	ld	ra,8(sp)
    8000142a:	6402                	ld	s0,0(sp)
    8000142c:	0141                	addi	sp,sp,16
    8000142e:	8082                	ret
    panic("uvmclear");
    80001430:	00006517          	auipc	a0,0x6
    80001434:	e7850513          	addi	a0,a0,-392 # 800072a8 <userret+0x218>
    80001438:	fffff097          	auipc	ra,0xfffff
    8000143c:	110080e7          	jalr	272(ra) # 80000548 <panic>

0000000080001440 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001440:	cab5                	beqz	a3,800014b4 <copyout+0x74>
{
    80001442:	715d                	addi	sp,sp,-80
    80001444:	e486                	sd	ra,72(sp)
    80001446:	e0a2                	sd	s0,64(sp)
    80001448:	fc26                	sd	s1,56(sp)
    8000144a:	f84a                	sd	s2,48(sp)
    8000144c:	f44e                	sd	s3,40(sp)
    8000144e:	f052                	sd	s4,32(sp)
    80001450:	ec56                	sd	s5,24(sp)
    80001452:	e85a                	sd	s6,16(sp)
    80001454:	e45e                	sd	s7,8(sp)
    80001456:	e062                	sd	s8,0(sp)
    80001458:	0880                	addi	s0,sp,80
    8000145a:	8baa                	mv	s7,a0
    8000145c:	8c2e                	mv	s8,a1
    8000145e:	8a32                	mv	s4,a2
    80001460:	89b6                	mv	s3,a3
    va0 = (uint)PGROUNDDOWN(dstva);
    80001462:	00100b37          	lui	s6,0x100
    80001466:	1b7d                	addi	s6,s6,-1
    80001468:	0b32                	slli	s6,s6,0xc
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000146a:	6a85                	lui	s5,0x1
    8000146c:	a015                	j	80001490 <copyout+0x50>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000146e:	9562                	add	a0,a0,s8
    80001470:	0004861b          	sext.w	a2,s1
    80001474:	85d2                	mv	a1,s4
    80001476:	41250533          	sub	a0,a0,s2
    8000147a:	fffff097          	auipc	ra,0xfffff
    8000147e:	662080e7          	jalr	1634(ra) # 80000adc <memmove>

    len -= n;
    80001482:	409989b3          	sub	s3,s3,s1
    src += n;
    80001486:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001488:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000148c:	02098263          	beqz	s3,800014b0 <copyout+0x70>
    va0 = (uint)PGROUNDDOWN(dstva);
    80001490:	016c7933          	and	s2,s8,s6
    pa0 = walkaddr(pagetable, va0);
    80001494:	85ca                	mv	a1,s2
    80001496:	855e                	mv	a0,s7
    80001498:	00000097          	auipc	ra,0x0
    8000149c:	9e2080e7          	jalr	-1566(ra) # 80000e7a <walkaddr>
    if(pa0 == 0)
    800014a0:	cd01                	beqz	a0,800014b8 <copyout+0x78>
    n = PGSIZE - (dstva - va0);
    800014a2:	418904b3          	sub	s1,s2,s8
    800014a6:	94d6                	add	s1,s1,s5
    if(n > len)
    800014a8:	fc99f3e3          	bgeu	s3,s1,8000146e <copyout+0x2e>
    800014ac:	84ce                	mv	s1,s3
    800014ae:	b7c1                	j	8000146e <copyout+0x2e>
  }
  return 0;
    800014b0:	4501                	li	a0,0
    800014b2:	a021                	j	800014ba <copyout+0x7a>
    800014b4:	4501                	li	a0,0
}
    800014b6:	8082                	ret
      return -1;
    800014b8:	557d                	li	a0,-1
}
    800014ba:	60a6                	ld	ra,72(sp)
    800014bc:	6406                	ld	s0,64(sp)
    800014be:	74e2                	ld	s1,56(sp)
    800014c0:	7942                	ld	s2,48(sp)
    800014c2:	79a2                	ld	s3,40(sp)
    800014c4:	7a02                	ld	s4,32(sp)
    800014c6:	6ae2                	ld	s5,24(sp)
    800014c8:	6b42                	ld	s6,16(sp)
    800014ca:	6ba2                	ld	s7,8(sp)
    800014cc:	6c02                	ld	s8,0(sp)
    800014ce:	6161                	addi	sp,sp,80
    800014d0:	8082                	ret

00000000800014d2 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800014d2:	cabd                	beqz	a3,80001548 <copyin+0x76>
{
    800014d4:	715d                	addi	sp,sp,-80
    800014d6:	e486                	sd	ra,72(sp)
    800014d8:	e0a2                	sd	s0,64(sp)
    800014da:	fc26                	sd	s1,56(sp)
    800014dc:	f84a                	sd	s2,48(sp)
    800014de:	f44e                	sd	s3,40(sp)
    800014e0:	f052                	sd	s4,32(sp)
    800014e2:	ec56                	sd	s5,24(sp)
    800014e4:	e85a                	sd	s6,16(sp)
    800014e6:	e45e                	sd	s7,8(sp)
    800014e8:	e062                	sd	s8,0(sp)
    800014ea:	0880                	addi	s0,sp,80
    800014ec:	8baa                	mv	s7,a0
    800014ee:	8a2e                	mv	s4,a1
    800014f0:	8c32                	mv	s8,a2
    800014f2:	89b6                	mv	s3,a3
    va0 = (uint)PGROUNDDOWN(srcva);
    800014f4:	00100b37          	lui	s6,0x100
    800014f8:	1b7d                	addi	s6,s6,-1
    800014fa:	0b32                	slli	s6,s6,0xc
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800014fc:	6a85                	lui	s5,0x1
    800014fe:	a01d                	j	80001524 <copyin+0x52>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001500:	018505b3          	add	a1,a0,s8
    80001504:	0004861b          	sext.w	a2,s1
    80001508:	412585b3          	sub	a1,a1,s2
    8000150c:	8552                	mv	a0,s4
    8000150e:	fffff097          	auipc	ra,0xfffff
    80001512:	5ce080e7          	jalr	1486(ra) # 80000adc <memmove>

    len -= n;
    80001516:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000151a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000151c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001520:	02098263          	beqz	s3,80001544 <copyin+0x72>
    va0 = (uint)PGROUNDDOWN(srcva);
    80001524:	016c7933          	and	s2,s8,s6
    pa0 = walkaddr(pagetable, va0);
    80001528:	85ca                	mv	a1,s2
    8000152a:	855e                	mv	a0,s7
    8000152c:	00000097          	auipc	ra,0x0
    80001530:	94e080e7          	jalr	-1714(ra) # 80000e7a <walkaddr>
    if(pa0 == 0)
    80001534:	cd01                	beqz	a0,8000154c <copyin+0x7a>
    n = PGSIZE - (srcva - va0);
    80001536:	418904b3          	sub	s1,s2,s8
    8000153a:	94d6                	add	s1,s1,s5
    if(n > len)
    8000153c:	fc99f2e3          	bgeu	s3,s1,80001500 <copyin+0x2e>
    80001540:	84ce                	mv	s1,s3
    80001542:	bf7d                	j	80001500 <copyin+0x2e>
  }
  return 0;
    80001544:	4501                	li	a0,0
    80001546:	a021                	j	8000154e <copyin+0x7c>
    80001548:	4501                	li	a0,0
}
    8000154a:	8082                	ret
      return -1;
    8000154c:	557d                	li	a0,-1
}
    8000154e:	60a6                	ld	ra,72(sp)
    80001550:	6406                	ld	s0,64(sp)
    80001552:	74e2                	ld	s1,56(sp)
    80001554:	7942                	ld	s2,48(sp)
    80001556:	79a2                	ld	s3,40(sp)
    80001558:	7a02                	ld	s4,32(sp)
    8000155a:	6ae2                	ld	s5,24(sp)
    8000155c:	6b42                	ld	s6,16(sp)
    8000155e:	6ba2                	ld	s7,8(sp)
    80001560:	6c02                	ld	s8,0(sp)
    80001562:	6161                	addi	sp,sp,80
    80001564:	8082                	ret

0000000080001566 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001566:	c6dd                	beqz	a3,80001614 <copyinstr+0xae>
{
    80001568:	715d                	addi	sp,sp,-80
    8000156a:	e486                	sd	ra,72(sp)
    8000156c:	e0a2                	sd	s0,64(sp)
    8000156e:	fc26                	sd	s1,56(sp)
    80001570:	f84a                	sd	s2,48(sp)
    80001572:	f44e                	sd	s3,40(sp)
    80001574:	f052                	sd	s4,32(sp)
    80001576:	ec56                	sd	s5,24(sp)
    80001578:	e85a                	sd	s6,16(sp)
    8000157a:	e45e                	sd	s7,8(sp)
    8000157c:	0880                	addi	s0,sp,80
    8000157e:	8aaa                	mv	s5,a0
    80001580:	8b2e                	mv	s6,a1
    80001582:	8bb2                	mv	s7,a2
    80001584:	84b6                	mv	s1,a3
    va0 = (uint)PGROUNDDOWN(srcva);
    80001586:	00100a37          	lui	s4,0x100
    8000158a:	1a7d                	addi	s4,s4,-1
    8000158c:	0a32                	slli	s4,s4,0xc
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000158e:	6985                	lui	s3,0x1
    80001590:	a035                	j	800015bc <copyinstr+0x56>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001592:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001596:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001598:	0017b793          	seqz	a5,a5
    8000159c:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800015a0:	60a6                	ld	ra,72(sp)
    800015a2:	6406                	ld	s0,64(sp)
    800015a4:	74e2                	ld	s1,56(sp)
    800015a6:	7942                	ld	s2,48(sp)
    800015a8:	79a2                	ld	s3,40(sp)
    800015aa:	7a02                	ld	s4,32(sp)
    800015ac:	6ae2                	ld	s5,24(sp)
    800015ae:	6b42                	ld	s6,16(sp)
    800015b0:	6ba2                	ld	s7,8(sp)
    800015b2:	6161                	addi	sp,sp,80
    800015b4:	8082                	ret
    srcva = va0 + PGSIZE;
    800015b6:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800015ba:	c8a9                	beqz	s1,8000160c <copyinstr+0xa6>
    va0 = (uint)PGROUNDDOWN(srcva);
    800015bc:	014bf933          	and	s2,s7,s4
    pa0 = walkaddr(pagetable, va0);
    800015c0:	85ca                	mv	a1,s2
    800015c2:	8556                	mv	a0,s5
    800015c4:	00000097          	auipc	ra,0x0
    800015c8:	8b6080e7          	jalr	-1866(ra) # 80000e7a <walkaddr>
    if(pa0 == 0)
    800015cc:	c131                	beqz	a0,80001610 <copyinstr+0xaa>
    n = PGSIZE - (srcva - va0);
    800015ce:	41790833          	sub	a6,s2,s7
    800015d2:	984e                	add	a6,a6,s3
    if(n > max)
    800015d4:	0104f363          	bgeu	s1,a6,800015da <copyinstr+0x74>
    800015d8:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800015da:	955e                	add	a0,a0,s7
    800015dc:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800015e0:	fc080be3          	beqz	a6,800015b6 <copyinstr+0x50>
    800015e4:	985a                	add	a6,a6,s6
    800015e6:	87da                	mv	a5,s6
      if(*p == '\0'){
    800015e8:	41650633          	sub	a2,a0,s6
    800015ec:	14fd                	addi	s1,s1,-1
    800015ee:	9b26                	add	s6,s6,s1
    800015f0:	00f60733          	add	a4,a2,a5
    800015f4:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd6fa4>
    800015f8:	df49                	beqz	a4,80001592 <copyinstr+0x2c>
        *dst = *p;
    800015fa:	00e78023          	sb	a4,0(a5)
      --max;
    800015fe:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001602:	0785                	addi	a5,a5,1
    while(n > 0){
    80001604:	ff0796e3          	bne	a5,a6,800015f0 <copyinstr+0x8a>
      dst++;
    80001608:	8b42                	mv	s6,a6
    8000160a:	b775                	j	800015b6 <copyinstr+0x50>
    8000160c:	4781                	li	a5,0
    8000160e:	b769                	j	80001598 <copyinstr+0x32>
      return -1;
    80001610:	557d                	li	a0,-1
    80001612:	b779                	j	800015a0 <copyinstr+0x3a>
  int got_null = 0;
    80001614:	4781                	li	a5,0
  if(got_null){
    80001616:	0017b793          	seqz	a5,a5
    8000161a:	40f00533          	neg	a0,a5
}
    8000161e:	8082                	ret

0000000080001620 <procinit>:

extern char trampoline[]; // trampoline.S

void
procinit(void)
{
    80001620:	715d                	addi	sp,sp,-80
    80001622:	e486                	sd	ra,72(sp)
    80001624:	e0a2                	sd	s0,64(sp)
    80001626:	fc26                	sd	s1,56(sp)
    80001628:	f84a                	sd	s2,48(sp)
    8000162a:	f44e                	sd	s3,40(sp)
    8000162c:	f052                	sd	s4,32(sp)
    8000162e:	ec56                	sd	s5,24(sp)
    80001630:	e85a                	sd	s6,16(sp)
    80001632:	e45e                	sd	s7,8(sp)
    80001634:	0880                	addi	s0,sp,80
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001636:	00006597          	auipc	a1,0x6
    8000163a:	c8258593          	addi	a1,a1,-894 # 800072b8 <userret+0x228>
    8000163e:	00010517          	auipc	a0,0x10
    80001642:	28a50513          	addi	a0,a0,650 # 800118c8 <pid_lock>
    80001646:	fffff097          	auipc	ra,0xfffff
    8000164a:	268080e7          	jalr	616(ra) # 800008ae <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000164e:	00010917          	auipc	s2,0x10
    80001652:	69290913          	addi	s2,s2,1682 # 80011ce0 <proc>
      initlock(&p->lock, "proc");
    80001656:	00006b97          	auipc	s7,0x6
    8000165a:	c6ab8b93          	addi	s7,s7,-918 # 800072c0 <userret+0x230>
      // Map it high in memory, followed by an invalid
      // guard page.
      char *pa = kalloc();
      if(pa == 0)
        panic("kalloc");
      uint64 va = KSTACK((int) (p - proc));
    8000165e:	8b4a                	mv	s6,s2
    80001660:	00006a97          	auipc	s5,0x6
    80001664:	490a8a93          	addi	s5,s5,1168 # 80007af0 <syscalls+0xc0>
    80001668:	040009b7          	lui	s3,0x4000
    8000166c:	19fd                	addi	s3,s3,-1
    8000166e:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001670:	00016a17          	auipc	s4,0x16
    80001674:	070a0a13          	addi	s4,s4,112 # 800176e0 <tickslock>
      initlock(&p->lock, "proc");
    80001678:	85de                	mv	a1,s7
    8000167a:	854a                	mv	a0,s2
    8000167c:	fffff097          	auipc	ra,0xfffff
    80001680:	232080e7          	jalr	562(ra) # 800008ae <initlock>
      char *pa = kalloc();
    80001684:	fffff097          	auipc	ra,0xfffff
    80001688:	210080e7          	jalr	528(ra) # 80000894 <kalloc>
    8000168c:	85aa                	mv	a1,a0
      if(pa == 0)
    8000168e:	c929                	beqz	a0,800016e0 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001690:	416904b3          	sub	s1,s2,s6
    80001694:	848d                	srai	s1,s1,0x3
    80001696:	000ab783          	ld	a5,0(s5)
    8000169a:	02f484b3          	mul	s1,s1,a5
    8000169e:	2485                	addiw	s1,s1,1
    800016a0:	00d4949b          	slliw	s1,s1,0xd
    800016a4:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800016a8:	4699                	li	a3,6
    800016aa:	6605                	lui	a2,0x1
    800016ac:	8526                	mv	a0,s1
    800016ae:	00000097          	auipc	ra,0x0
    800016b2:	8ee080e7          	jalr	-1810(ra) # 80000f9c <kvmmap>
      p->kstack = va;
    800016b6:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    800016ba:	16890913          	addi	s2,s2,360
    800016be:	fb491de3          	bne	s2,s4,80001678 <procinit+0x58>
  }
  kvminithart();
    800016c2:	fffff097          	auipc	ra,0xfffff
    800016c6:	794080e7          	jalr	1940(ra) # 80000e56 <kvminithart>
}
    800016ca:	60a6                	ld	ra,72(sp)
    800016cc:	6406                	ld	s0,64(sp)
    800016ce:	74e2                	ld	s1,56(sp)
    800016d0:	7942                	ld	s2,48(sp)
    800016d2:	79a2                	ld	s3,40(sp)
    800016d4:	7a02                	ld	s4,32(sp)
    800016d6:	6ae2                	ld	s5,24(sp)
    800016d8:	6b42                	ld	s6,16(sp)
    800016da:	6ba2                	ld	s7,8(sp)
    800016dc:	6161                	addi	sp,sp,80
    800016de:	8082                	ret
        panic("kalloc");
    800016e0:	00006517          	auipc	a0,0x6
    800016e4:	be850513          	addi	a0,a0,-1048 # 800072c8 <userret+0x238>
    800016e8:	fffff097          	auipc	ra,0xfffff
    800016ec:	e60080e7          	jalr	-416(ra) # 80000548 <panic>

00000000800016f0 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800016f0:	1141                	addi	sp,sp,-16
    800016f2:	e422                	sd	s0,8(sp)
    800016f4:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800016f6:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800016f8:	2501                	sext.w	a0,a0
    800016fa:	6422                	ld	s0,8(sp)
    800016fc:	0141                	addi	sp,sp,16
    800016fe:	8082                	ret

0000000080001700 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001700:	1141                	addi	sp,sp,-16
    80001702:	e422                	sd	s0,8(sp)
    80001704:	0800                	addi	s0,sp,16
    80001706:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001708:	2781                	sext.w	a5,a5
    8000170a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000170c:	00010517          	auipc	a0,0x10
    80001710:	1d450513          	addi	a0,a0,468 # 800118e0 <cpus>
    80001714:	953e                	add	a0,a0,a5
    80001716:	6422                	ld	s0,8(sp)
    80001718:	0141                	addi	sp,sp,16
    8000171a:	8082                	ret

000000008000171c <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    8000171c:	1101                	addi	sp,sp,-32
    8000171e:	ec06                	sd	ra,24(sp)
    80001720:	e822                	sd	s0,16(sp)
    80001722:	e426                	sd	s1,8(sp)
    80001724:	1000                	addi	s0,sp,32
  push_off();
    80001726:	fffff097          	auipc	ra,0xfffff
    8000172a:	19e080e7          	jalr	414(ra) # 800008c4 <push_off>
    8000172e:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001730:	2781                	sext.w	a5,a5
    80001732:	079e                	slli	a5,a5,0x7
    80001734:	00010717          	auipc	a4,0x10
    80001738:	19470713          	addi	a4,a4,404 # 800118c8 <pid_lock>
    8000173c:	97ba                	add	a5,a5,a4
    8000173e:	6f84                	ld	s1,24(a5)
  pop_off();
    80001740:	fffff097          	auipc	ra,0xfffff
    80001744:	1d0080e7          	jalr	464(ra) # 80000910 <pop_off>
  return p;
}
    80001748:	8526                	mv	a0,s1
    8000174a:	60e2                	ld	ra,24(sp)
    8000174c:	6442                	ld	s0,16(sp)
    8000174e:	64a2                	ld	s1,8(sp)
    80001750:	6105                	addi	sp,sp,32
    80001752:	8082                	ret

0000000080001754 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001754:	1141                	addi	sp,sp,-16
    80001756:	e406                	sd	ra,8(sp)
    80001758:	e022                	sd	s0,0(sp)
    8000175a:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    8000175c:	00000097          	auipc	ra,0x0
    80001760:	fc0080e7          	jalr	-64(ra) # 8000171c <myproc>
    80001764:	fffff097          	auipc	ra,0xfffff
    80001768:	2c0080e7          	jalr	704(ra) # 80000a24 <release>

  if (first) {
    8000176c:	00007797          	auipc	a5,0x7
    80001770:	8c87a783          	lw	a5,-1848(a5) # 80008034 <first.1>
    80001774:	eb89                	bnez	a5,80001786 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(minor(ROOTDEV));
  }

  usertrapret();
    80001776:	00001097          	auipc	ra,0x1
    8000177a:	c1c080e7          	jalr	-996(ra) # 80002392 <usertrapret>
}
    8000177e:	60a2                	ld	ra,8(sp)
    80001780:	6402                	ld	s0,0(sp)
    80001782:	0141                	addi	sp,sp,16
    80001784:	8082                	ret
    first = 0;
    80001786:	00007797          	auipc	a5,0x7
    8000178a:	8a07a723          	sw	zero,-1874(a5) # 80008034 <first.1>
    fsinit(minor(ROOTDEV));
    8000178e:	4501                	li	a0,0
    80001790:	00002097          	auipc	ra,0x2
    80001794:	944080e7          	jalr	-1724(ra) # 800030d4 <fsinit>
    80001798:	bff9                	j	80001776 <forkret+0x22>

000000008000179a <allocpid>:
allocpid() {
    8000179a:	1101                	addi	sp,sp,-32
    8000179c:	ec06                	sd	ra,24(sp)
    8000179e:	e822                	sd	s0,16(sp)
    800017a0:	e426                	sd	s1,8(sp)
    800017a2:	e04a                	sd	s2,0(sp)
    800017a4:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    800017a6:	00010917          	auipc	s2,0x10
    800017aa:	12290913          	addi	s2,s2,290 # 800118c8 <pid_lock>
    800017ae:	854a                	mv	a0,s2
    800017b0:	fffff097          	auipc	ra,0xfffff
    800017b4:	20c080e7          	jalr	524(ra) # 800009bc <acquire>
  pid = nextpid;
    800017b8:	00007797          	auipc	a5,0x7
    800017bc:	88078793          	addi	a5,a5,-1920 # 80008038 <nextpid>
    800017c0:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    800017c2:	0014871b          	addiw	a4,s1,1
    800017c6:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    800017c8:	854a                	mv	a0,s2
    800017ca:	fffff097          	auipc	ra,0xfffff
    800017ce:	25a080e7          	jalr	602(ra) # 80000a24 <release>
}
    800017d2:	8526                	mv	a0,s1
    800017d4:	60e2                	ld	ra,24(sp)
    800017d6:	6442                	ld	s0,16(sp)
    800017d8:	64a2                	ld	s1,8(sp)
    800017da:	6902                	ld	s2,0(sp)
    800017dc:	6105                	addi	sp,sp,32
    800017de:	8082                	ret

00000000800017e0 <proc_pagetable>:
{
    800017e0:	1101                	addi	sp,sp,-32
    800017e2:	ec06                	sd	ra,24(sp)
    800017e4:	e822                	sd	s0,16(sp)
    800017e6:	e426                	sd	s1,8(sp)
    800017e8:	e04a                	sd	s2,0(sp)
    800017ea:	1000                	addi	s0,sp,32
    800017ec:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    800017ee:	00000097          	auipc	ra,0x0
    800017f2:	994080e7          	jalr	-1644(ra) # 80001182 <uvmcreate>
    800017f6:	84aa                	mv	s1,a0
  mappages(pagetable, TRAMPOLINE, PGSIZE,
    800017f8:	4729                	li	a4,10
    800017fa:	00006697          	auipc	a3,0x6
    800017fe:	80668693          	addi	a3,a3,-2042 # 80007000 <trampoline>
    80001802:	6605                	lui	a2,0x1
    80001804:	040005b7          	lui	a1,0x4000
    80001808:	15fd                	addi	a1,a1,-1
    8000180a:	05b2                	slli	a1,a1,0xc
    8000180c:	fffff097          	auipc	ra,0xfffff
    80001810:	702080e7          	jalr	1794(ra) # 80000f0e <mappages>
  mappages(pagetable, TRAPFRAME, PGSIZE,
    80001814:	4719                	li	a4,6
    80001816:	05893683          	ld	a3,88(s2)
    8000181a:	6605                	lui	a2,0x1
    8000181c:	020005b7          	lui	a1,0x2000
    80001820:	15fd                	addi	a1,a1,-1
    80001822:	05b6                	slli	a1,a1,0xd
    80001824:	8526                	mv	a0,s1
    80001826:	fffff097          	auipc	ra,0xfffff
    8000182a:	6e8080e7          	jalr	1768(ra) # 80000f0e <mappages>
}
    8000182e:	8526                	mv	a0,s1
    80001830:	60e2                	ld	ra,24(sp)
    80001832:	6442                	ld	s0,16(sp)
    80001834:	64a2                	ld	s1,8(sp)
    80001836:	6902                	ld	s2,0(sp)
    80001838:	6105                	addi	sp,sp,32
    8000183a:	8082                	ret

000000008000183c <allocproc>:
{
    8000183c:	1101                	addi	sp,sp,-32
    8000183e:	ec06                	sd	ra,24(sp)
    80001840:	e822                	sd	s0,16(sp)
    80001842:	e426                	sd	s1,8(sp)
    80001844:	e04a                	sd	s2,0(sp)
    80001846:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001848:	00010497          	auipc	s1,0x10
    8000184c:	49848493          	addi	s1,s1,1176 # 80011ce0 <proc>
    80001850:	00016917          	auipc	s2,0x16
    80001854:	e9090913          	addi	s2,s2,-368 # 800176e0 <tickslock>
    acquire(&p->lock);
    80001858:	8526                	mv	a0,s1
    8000185a:	fffff097          	auipc	ra,0xfffff
    8000185e:	162080e7          	jalr	354(ra) # 800009bc <acquire>
    if(p->state == UNUSED) {
    80001862:	4c9c                	lw	a5,24(s1)
    80001864:	cf81                	beqz	a5,8000187c <allocproc+0x40>
      release(&p->lock);
    80001866:	8526                	mv	a0,s1
    80001868:	fffff097          	auipc	ra,0xfffff
    8000186c:	1bc080e7          	jalr	444(ra) # 80000a24 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001870:	16848493          	addi	s1,s1,360
    80001874:	ff2492e3          	bne	s1,s2,80001858 <allocproc+0x1c>
  return 0;
    80001878:	4481                	li	s1,0
    8000187a:	a0a9                	j	800018c4 <allocproc+0x88>
  p->pid = allocpid();
    8000187c:	00000097          	auipc	ra,0x0
    80001880:	f1e080e7          	jalr	-226(ra) # 8000179a <allocpid>
    80001884:	dc88                	sw	a0,56(s1)
  if((p->tf = (struct trapframe *)kalloc()) == 0){
    80001886:	fffff097          	auipc	ra,0xfffff
    8000188a:	00e080e7          	jalr	14(ra) # 80000894 <kalloc>
    8000188e:	892a                	mv	s2,a0
    80001890:	eca8                	sd	a0,88(s1)
    80001892:	c121                	beqz	a0,800018d2 <allocproc+0x96>
  p->pagetable = proc_pagetable(p);
    80001894:	8526                	mv	a0,s1
    80001896:	00000097          	auipc	ra,0x0
    8000189a:	f4a080e7          	jalr	-182(ra) # 800017e0 <proc_pagetable>
    8000189e:	e8a8                	sd	a0,80(s1)
  memset(&p->context, 0, sizeof p->context);
    800018a0:	07000613          	li	a2,112
    800018a4:	4581                	li	a1,0
    800018a6:	06048513          	addi	a0,s1,96
    800018aa:	fffff097          	auipc	ra,0xfffff
    800018ae:	1d6080e7          	jalr	470(ra) # 80000a80 <memset>
  p->context.ra = (uint64)forkret;
    800018b2:	00000797          	auipc	a5,0x0
    800018b6:	ea278793          	addi	a5,a5,-350 # 80001754 <forkret>
    800018ba:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    800018bc:	60bc                	ld	a5,64(s1)
    800018be:	6705                	lui	a4,0x1
    800018c0:	97ba                	add	a5,a5,a4
    800018c2:	f4bc                	sd	a5,104(s1)
}
    800018c4:	8526                	mv	a0,s1
    800018c6:	60e2                	ld	ra,24(sp)
    800018c8:	6442                	ld	s0,16(sp)
    800018ca:	64a2                	ld	s1,8(sp)
    800018cc:	6902                	ld	s2,0(sp)
    800018ce:	6105                	addi	sp,sp,32
    800018d0:	8082                	ret
    release(&p->lock);
    800018d2:	8526                	mv	a0,s1
    800018d4:	fffff097          	auipc	ra,0xfffff
    800018d8:	150080e7          	jalr	336(ra) # 80000a24 <release>
    return 0;
    800018dc:	84ca                	mv	s1,s2
    800018de:	b7dd                	j	800018c4 <allocproc+0x88>

00000000800018e0 <proc_freepagetable>:
{
    800018e0:	1101                	addi	sp,sp,-32
    800018e2:	ec06                	sd	ra,24(sp)
    800018e4:	e822                	sd	s0,16(sp)
    800018e6:	e426                	sd	s1,8(sp)
    800018e8:	e04a                	sd	s2,0(sp)
    800018ea:	1000                	addi	s0,sp,32
    800018ec:	84aa                	mv	s1,a0
    800018ee:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, PGSIZE, 0);
    800018f0:	4681                	li	a3,0
    800018f2:	6605                	lui	a2,0x1
    800018f4:	040005b7          	lui	a1,0x4000
    800018f8:	15fd                	addi	a1,a1,-1
    800018fa:	05b2                	slli	a1,a1,0xc
    800018fc:	fffff097          	auipc	ra,0xfffff
    80001900:	7be080e7          	jalr	1982(ra) # 800010ba <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, PGSIZE, 0);
    80001904:	4681                	li	a3,0
    80001906:	6605                	lui	a2,0x1
    80001908:	020005b7          	lui	a1,0x2000
    8000190c:	15fd                	addi	a1,a1,-1
    8000190e:	05b6                	slli	a1,a1,0xd
    80001910:	8526                	mv	a0,s1
    80001912:	fffff097          	auipc	ra,0xfffff
    80001916:	7a8080e7          	jalr	1960(ra) # 800010ba <uvmunmap>
  if(sz > 0)
    8000191a:	00091863          	bnez	s2,8000192a <proc_freepagetable+0x4a>
}
    8000191e:	60e2                	ld	ra,24(sp)
    80001920:	6442                	ld	s0,16(sp)
    80001922:	64a2                	ld	s1,8(sp)
    80001924:	6902                	ld	s2,0(sp)
    80001926:	6105                	addi	sp,sp,32
    80001928:	8082                	ret
    uvmfree(pagetable, sz);
    8000192a:	85ca                	mv	a1,s2
    8000192c:	8526                	mv	a0,s1
    8000192e:	00000097          	auipc	ra,0x0
    80001932:	9e2080e7          	jalr	-1566(ra) # 80001310 <uvmfree>
}
    80001936:	b7e5                	j	8000191e <proc_freepagetable+0x3e>

0000000080001938 <freeproc>:
{
    80001938:	1101                	addi	sp,sp,-32
    8000193a:	ec06                	sd	ra,24(sp)
    8000193c:	e822                	sd	s0,16(sp)
    8000193e:	e426                	sd	s1,8(sp)
    80001940:	1000                	addi	s0,sp,32
    80001942:	84aa                	mv	s1,a0
  if(p->tf)
    80001944:	6d28                	ld	a0,88(a0)
    80001946:	c509                	beqz	a0,80001950 <freeproc+0x18>
    kfree((void*)p->tf);
    80001948:	fffff097          	auipc	ra,0xfffff
    8000194c:	f34080e7          	jalr	-204(ra) # 8000087c <kfree>
  p->tf = 0;
    80001950:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001954:	68a8                	ld	a0,80(s1)
    80001956:	c511                	beqz	a0,80001962 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001958:	64ac                	ld	a1,72(s1)
    8000195a:	00000097          	auipc	ra,0x0
    8000195e:	f86080e7          	jalr	-122(ra) # 800018e0 <proc_freepagetable>
  p->pagetable = 0;
    80001962:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001966:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    8000196a:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    8000196e:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001972:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001976:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    8000197a:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    8000197e:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001982:	0004ac23          	sw	zero,24(s1)
}
    80001986:	60e2                	ld	ra,24(sp)
    80001988:	6442                	ld	s0,16(sp)
    8000198a:	64a2                	ld	s1,8(sp)
    8000198c:	6105                	addi	sp,sp,32
    8000198e:	8082                	ret

0000000080001990 <userinit>:
{
    80001990:	1101                	addi	sp,sp,-32
    80001992:	ec06                	sd	ra,24(sp)
    80001994:	e822                	sd	s0,16(sp)
    80001996:	e426                	sd	s1,8(sp)
    80001998:	1000                	addi	s0,sp,32
  p = allocproc();
    8000199a:	00000097          	auipc	ra,0x0
    8000199e:	ea2080e7          	jalr	-350(ra) # 8000183c <allocproc>
    800019a2:	84aa                	mv	s1,a0
  initproc = p;
    800019a4:	00026797          	auipc	a5,0x26
    800019a8:	68a7ba23          	sd	a0,1684(a5) # 80028038 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    800019ac:	03300613          	li	a2,51
    800019b0:	00006597          	auipc	a1,0x6
    800019b4:	65058593          	addi	a1,a1,1616 # 80008000 <initcode>
    800019b8:	6928                	ld	a0,80(a0)
    800019ba:	00000097          	auipc	ra,0x0
    800019be:	806080e7          	jalr	-2042(ra) # 800011c0 <uvminit>
  p->sz = PGSIZE;
    800019c2:	6785                	lui	a5,0x1
    800019c4:	e4bc                	sd	a5,72(s1)
  p->tf->epc = 0;      // user program counter
    800019c6:	6cb8                	ld	a4,88(s1)
    800019c8:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->tf->sp = PGSIZE;  // user stack pointer
    800019cc:	6cb8                	ld	a4,88(s1)
    800019ce:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800019d0:	4641                	li	a2,16
    800019d2:	00006597          	auipc	a1,0x6
    800019d6:	8fe58593          	addi	a1,a1,-1794 # 800072d0 <userret+0x240>
    800019da:	15848513          	addi	a0,s1,344
    800019de:	fffff097          	auipc	ra,0xfffff
    800019e2:	1f4080e7          	jalr	500(ra) # 80000bd2 <safestrcpy>
  p->cwd = namei("/");
    800019e6:	00006517          	auipc	a0,0x6
    800019ea:	8fa50513          	addi	a0,a0,-1798 # 800072e0 <userret+0x250>
    800019ee:	00002097          	auipc	ra,0x2
    800019f2:	0ea080e7          	jalr	234(ra) # 80003ad8 <namei>
    800019f6:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    800019fa:	4789                	li	a5,2
    800019fc:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    800019fe:	8526                	mv	a0,s1
    80001a00:	fffff097          	auipc	ra,0xfffff
    80001a04:	024080e7          	jalr	36(ra) # 80000a24 <release>
}
    80001a08:	60e2                	ld	ra,24(sp)
    80001a0a:	6442                	ld	s0,16(sp)
    80001a0c:	64a2                	ld	s1,8(sp)
    80001a0e:	6105                	addi	sp,sp,32
    80001a10:	8082                	ret

0000000080001a12 <growproc>:
{
    80001a12:	1101                	addi	sp,sp,-32
    80001a14:	ec06                	sd	ra,24(sp)
    80001a16:	e822                	sd	s0,16(sp)
    80001a18:	e426                	sd	s1,8(sp)
    80001a1a:	e04a                	sd	s2,0(sp)
    80001a1c:	1000                	addi	s0,sp,32
    80001a1e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001a20:	00000097          	auipc	ra,0x0
    80001a24:	cfc080e7          	jalr	-772(ra) # 8000171c <myproc>
    80001a28:	892a                	mv	s2,a0
  sz = p->sz;
    80001a2a:	652c                	ld	a1,72(a0)
    80001a2c:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001a30:	00904f63          	bgtz	s1,80001a4e <growproc+0x3c>
  } else if(n < 0){
    80001a34:	0204cc63          	bltz	s1,80001a6c <growproc+0x5a>
  p->sz = sz;
    80001a38:	1602                	slli	a2,a2,0x20
    80001a3a:	9201                	srli	a2,a2,0x20
    80001a3c:	04c93423          	sd	a2,72(s2)
  return 0;
    80001a40:	4501                	li	a0,0
}
    80001a42:	60e2                	ld	ra,24(sp)
    80001a44:	6442                	ld	s0,16(sp)
    80001a46:	64a2                	ld	s1,8(sp)
    80001a48:	6902                	ld	s2,0(sp)
    80001a4a:	6105                	addi	sp,sp,32
    80001a4c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001a4e:	9e25                	addw	a2,a2,s1
    80001a50:	1602                	slli	a2,a2,0x20
    80001a52:	9201                	srli	a2,a2,0x20
    80001a54:	1582                	slli	a1,a1,0x20
    80001a56:	9181                	srli	a1,a1,0x20
    80001a58:	6928                	ld	a0,80(a0)
    80001a5a:	00000097          	auipc	ra,0x0
    80001a5e:	80c080e7          	jalr	-2036(ra) # 80001266 <uvmalloc>
    80001a62:	0005061b          	sext.w	a2,a0
    80001a66:	fa69                	bnez	a2,80001a38 <growproc+0x26>
      return -1;
    80001a68:	557d                	li	a0,-1
    80001a6a:	bfe1                	j	80001a42 <growproc+0x30>
    if((sz = uvmdealloc(p->pagetable, sz, sz + n)) == 0) {
    80001a6c:	9e25                	addw	a2,a2,s1
    80001a6e:	1602                	slli	a2,a2,0x20
    80001a70:	9201                	srli	a2,a2,0x20
    80001a72:	1582                	slli	a1,a1,0x20
    80001a74:	9181                	srli	a1,a1,0x20
    80001a76:	6928                	ld	a0,80(a0)
    80001a78:	fffff097          	auipc	ra,0xfffff
    80001a7c:	7ba080e7          	jalr	1978(ra) # 80001232 <uvmdealloc>
    80001a80:	0005061b          	sext.w	a2,a0
    80001a84:	fa55                	bnez	a2,80001a38 <growproc+0x26>
      return -1;
    80001a86:	557d                	li	a0,-1
    80001a88:	bf6d                	j	80001a42 <growproc+0x30>

0000000080001a8a <fork>:
{
    80001a8a:	7139                	addi	sp,sp,-64
    80001a8c:	fc06                	sd	ra,56(sp)
    80001a8e:	f822                	sd	s0,48(sp)
    80001a90:	f426                	sd	s1,40(sp)
    80001a92:	f04a                	sd	s2,32(sp)
    80001a94:	ec4e                	sd	s3,24(sp)
    80001a96:	e852                	sd	s4,16(sp)
    80001a98:	e456                	sd	s5,8(sp)
    80001a9a:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001a9c:	00000097          	auipc	ra,0x0
    80001aa0:	c80080e7          	jalr	-896(ra) # 8000171c <myproc>
    80001aa4:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001aa6:	00000097          	auipc	ra,0x0
    80001aaa:	d96080e7          	jalr	-618(ra) # 8000183c <allocproc>
    80001aae:	c17d                	beqz	a0,80001b94 <fork+0x10a>
    80001ab0:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001ab2:	048ab603          	ld	a2,72(s5)
    80001ab6:	692c                	ld	a1,80(a0)
    80001ab8:	050ab503          	ld	a0,80(s5)
    80001abc:	00000097          	auipc	ra,0x0
    80001ac0:	882080e7          	jalr	-1918(ra) # 8000133e <uvmcopy>
    80001ac4:	04054a63          	bltz	a0,80001b18 <fork+0x8e>
  np->sz = p->sz;
    80001ac8:	048ab783          	ld	a5,72(s5)
    80001acc:	04fa3423          	sd	a5,72(s4)
  np->parent = p;
    80001ad0:	035a3023          	sd	s5,32(s4)
  *(np->tf) = *(p->tf);
    80001ad4:	058ab683          	ld	a3,88(s5)
    80001ad8:	87b6                	mv	a5,a3
    80001ada:	058a3703          	ld	a4,88(s4)
    80001ade:	12068693          	addi	a3,a3,288
    80001ae2:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001ae6:	6788                	ld	a0,8(a5)
    80001ae8:	6b8c                	ld	a1,16(a5)
    80001aea:	6f90                	ld	a2,24(a5)
    80001aec:	01073023          	sd	a6,0(a4)
    80001af0:	e708                	sd	a0,8(a4)
    80001af2:	eb0c                	sd	a1,16(a4)
    80001af4:	ef10                	sd	a2,24(a4)
    80001af6:	02078793          	addi	a5,a5,32
    80001afa:	02070713          	addi	a4,a4,32
    80001afe:	fed792e3          	bne	a5,a3,80001ae2 <fork+0x58>
  np->tf->a0 = 0;
    80001b02:	058a3783          	ld	a5,88(s4)
    80001b06:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001b0a:	0d0a8493          	addi	s1,s5,208
    80001b0e:	0d0a0913          	addi	s2,s4,208
    80001b12:	150a8993          	addi	s3,s5,336
    80001b16:	a00d                	j	80001b38 <fork+0xae>
    freeproc(np);
    80001b18:	8552                	mv	a0,s4
    80001b1a:	00000097          	auipc	ra,0x0
    80001b1e:	e1e080e7          	jalr	-482(ra) # 80001938 <freeproc>
    release(&np->lock);
    80001b22:	8552                	mv	a0,s4
    80001b24:	fffff097          	auipc	ra,0xfffff
    80001b28:	f00080e7          	jalr	-256(ra) # 80000a24 <release>
    return -1;
    80001b2c:	54fd                	li	s1,-1
    80001b2e:	a889                	j	80001b80 <fork+0xf6>
  for(i = 0; i < NOFILE; i++)
    80001b30:	04a1                	addi	s1,s1,8
    80001b32:	0921                	addi	s2,s2,8
    80001b34:	01348b63          	beq	s1,s3,80001b4a <fork+0xc0>
    if(p->ofile[i])
    80001b38:	6088                	ld	a0,0(s1)
    80001b3a:	d97d                	beqz	a0,80001b30 <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    80001b3c:	00003097          	auipc	ra,0x3
    80001b40:	890080e7          	jalr	-1904(ra) # 800043cc <filedup>
    80001b44:	00a93023          	sd	a0,0(s2)
    80001b48:	b7e5                	j	80001b30 <fork+0xa6>
  np->cwd = idup(p->cwd);
    80001b4a:	150ab503          	ld	a0,336(s5)
    80001b4e:	00001097          	auipc	ra,0x1
    80001b52:	7c0080e7          	jalr	1984(ra) # 8000330e <idup>
    80001b56:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001b5a:	4641                	li	a2,16
    80001b5c:	158a8593          	addi	a1,s5,344
    80001b60:	158a0513          	addi	a0,s4,344
    80001b64:	fffff097          	auipc	ra,0xfffff
    80001b68:	06e080e7          	jalr	110(ra) # 80000bd2 <safestrcpy>
  pid = np->pid;
    80001b6c:	038a2483          	lw	s1,56(s4)
  np->state = RUNNABLE;
    80001b70:	4789                	li	a5,2
    80001b72:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001b76:	8552                	mv	a0,s4
    80001b78:	fffff097          	auipc	ra,0xfffff
    80001b7c:	eac080e7          	jalr	-340(ra) # 80000a24 <release>
}
    80001b80:	8526                	mv	a0,s1
    80001b82:	70e2                	ld	ra,56(sp)
    80001b84:	7442                	ld	s0,48(sp)
    80001b86:	74a2                	ld	s1,40(sp)
    80001b88:	7902                	ld	s2,32(sp)
    80001b8a:	69e2                	ld	s3,24(sp)
    80001b8c:	6a42                	ld	s4,16(sp)
    80001b8e:	6aa2                	ld	s5,8(sp)
    80001b90:	6121                	addi	sp,sp,64
    80001b92:	8082                	ret
    return -1;
    80001b94:	54fd                	li	s1,-1
    80001b96:	b7ed                	j	80001b80 <fork+0xf6>

0000000080001b98 <reparent>:
reparent(struct proc *p, struct proc *parent) {
    80001b98:	711d                	addi	sp,sp,-96
    80001b9a:	ec86                	sd	ra,88(sp)
    80001b9c:	e8a2                	sd	s0,80(sp)
    80001b9e:	e4a6                	sd	s1,72(sp)
    80001ba0:	e0ca                	sd	s2,64(sp)
    80001ba2:	fc4e                	sd	s3,56(sp)
    80001ba4:	f852                	sd	s4,48(sp)
    80001ba6:	f456                	sd	s5,40(sp)
    80001ba8:	f05a                	sd	s6,32(sp)
    80001baa:	ec5e                	sd	s7,24(sp)
    80001bac:	e862                	sd	s8,16(sp)
    80001bae:	e466                	sd	s9,8(sp)
    80001bb0:	1080                	addi	s0,sp,96
    80001bb2:	892a                	mv	s2,a0
  int child_of_init = (p->parent == initproc);
    80001bb4:	02053b83          	ld	s7,32(a0)
    80001bb8:	00026b17          	auipc	s6,0x26
    80001bbc:	480b3b03          	ld	s6,1152(s6) # 80028038 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001bc0:	00010497          	auipc	s1,0x10
    80001bc4:	12048493          	addi	s1,s1,288 # 80011ce0 <proc>
      pp->parent = initproc;
    80001bc8:	00026a17          	auipc	s4,0x26
    80001bcc:	470a0a13          	addi	s4,s4,1136 # 80028038 <initproc>
      if(pp->state == ZOMBIE) {
    80001bd0:	4a91                	li	s5,4
// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
  if(p->chan == p && p->state == SLEEPING) {
    80001bd2:	4c05                	li	s8,1
    p->state = RUNNABLE;
    80001bd4:	4c89                	li	s9,2
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001bd6:	00016997          	auipc	s3,0x16
    80001bda:	b0a98993          	addi	s3,s3,-1270 # 800176e0 <tickslock>
    80001bde:	a805                	j	80001c0e <reparent+0x76>
  if(p->chan == p && p->state == SLEEPING) {
    80001be0:	751c                	ld	a5,40(a0)
    80001be2:	00f51d63          	bne	a0,a5,80001bfc <reparent+0x64>
    80001be6:	4d1c                	lw	a5,24(a0)
    80001be8:	01879a63          	bne	a5,s8,80001bfc <reparent+0x64>
    p->state = RUNNABLE;
    80001bec:	01952c23          	sw	s9,24(a0)
        if(!child_of_init)
    80001bf0:	016b8663          	beq	s7,s6,80001bfc <reparent+0x64>
          release(&initproc->lock);
    80001bf4:	fffff097          	auipc	ra,0xfffff
    80001bf8:	e30080e7          	jalr	-464(ra) # 80000a24 <release>
      release(&pp->lock);
    80001bfc:	8526                	mv	a0,s1
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	e26080e7          	jalr	-474(ra) # 80000a24 <release>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001c06:	16848493          	addi	s1,s1,360
    80001c0a:	03348f63          	beq	s1,s3,80001c48 <reparent+0xb0>
    if(pp->parent == p){
    80001c0e:	709c                	ld	a5,32(s1)
    80001c10:	ff279be3          	bne	a5,s2,80001c06 <reparent+0x6e>
      acquire(&pp->lock);
    80001c14:	8526                	mv	a0,s1
    80001c16:	fffff097          	auipc	ra,0xfffff
    80001c1a:	da6080e7          	jalr	-602(ra) # 800009bc <acquire>
      pp->parent = initproc;
    80001c1e:	000a3503          	ld	a0,0(s4)
    80001c22:	f088                	sd	a0,32(s1)
      if(pp->state == ZOMBIE) {
    80001c24:	4c9c                	lw	a5,24(s1)
    80001c26:	fd579be3          	bne	a5,s5,80001bfc <reparent+0x64>
        if(!child_of_init)
    80001c2a:	fb6b8be3          	beq	s7,s6,80001be0 <reparent+0x48>
          acquire(&initproc->lock);
    80001c2e:	fffff097          	auipc	ra,0xfffff
    80001c32:	d8e080e7          	jalr	-626(ra) # 800009bc <acquire>
        wakeup1(initproc);
    80001c36:	000a3503          	ld	a0,0(s4)
  if(p->chan == p && p->state == SLEEPING) {
    80001c3a:	751c                	ld	a5,40(a0)
    80001c3c:	faa79ce3          	bne	a5,a0,80001bf4 <reparent+0x5c>
    80001c40:	4d1c                	lw	a5,24(a0)
    80001c42:	fb8799e3          	bne	a5,s8,80001bf4 <reparent+0x5c>
    80001c46:	b75d                	j	80001bec <reparent+0x54>
}
    80001c48:	60e6                	ld	ra,88(sp)
    80001c4a:	6446                	ld	s0,80(sp)
    80001c4c:	64a6                	ld	s1,72(sp)
    80001c4e:	6906                	ld	s2,64(sp)
    80001c50:	79e2                	ld	s3,56(sp)
    80001c52:	7a42                	ld	s4,48(sp)
    80001c54:	7aa2                	ld	s5,40(sp)
    80001c56:	7b02                	ld	s6,32(sp)
    80001c58:	6be2                	ld	s7,24(sp)
    80001c5a:	6c42                	ld	s8,16(sp)
    80001c5c:	6ca2                	ld	s9,8(sp)
    80001c5e:	6125                	addi	sp,sp,96
    80001c60:	8082                	ret

0000000080001c62 <scheduler>:
{
    80001c62:	715d                	addi	sp,sp,-80
    80001c64:	e486                	sd	ra,72(sp)
    80001c66:	e0a2                	sd	s0,64(sp)
    80001c68:	fc26                	sd	s1,56(sp)
    80001c6a:	f84a                	sd	s2,48(sp)
    80001c6c:	f44e                	sd	s3,40(sp)
    80001c6e:	f052                	sd	s4,32(sp)
    80001c70:	ec56                	sd	s5,24(sp)
    80001c72:	e85a                	sd	s6,16(sp)
    80001c74:	e45e                	sd	s7,8(sp)
    80001c76:	e062                	sd	s8,0(sp)
    80001c78:	0880                	addi	s0,sp,80
    80001c7a:	8792                	mv	a5,tp
  int id = r_tp();
    80001c7c:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001c7e:	00779b13          	slli	s6,a5,0x7
    80001c82:	00010717          	auipc	a4,0x10
    80001c86:	c4670713          	addi	a4,a4,-954 # 800118c8 <pid_lock>
    80001c8a:	975a                	add	a4,a4,s6
    80001c8c:	00073c23          	sd	zero,24(a4)
        swtch(&c->scheduler, &p->context);
    80001c90:	00010717          	auipc	a4,0x10
    80001c94:	c5870713          	addi	a4,a4,-936 # 800118e8 <cpus+0x8>
    80001c98:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001c9a:	4c0d                	li	s8,3
        c->proc = p;
    80001c9c:	079e                	slli	a5,a5,0x7
    80001c9e:	00010a17          	auipc	s4,0x10
    80001ca2:	c2aa0a13          	addi	s4,s4,-982 # 800118c8 <pid_lock>
    80001ca6:	9a3e                	add	s4,s4,a5
        found = 1;
    80001ca8:	4b85                	li	s7,1
    for(p = proc; p < &proc[NPROC]; p++) {
    80001caa:	00016997          	auipc	s3,0x16
    80001cae:	a3698993          	addi	s3,s3,-1482 # 800176e0 <tickslock>
    80001cb2:	a08d                	j	80001d14 <scheduler+0xb2>
      release(&p->lock);
    80001cb4:	8526                	mv	a0,s1
    80001cb6:	fffff097          	auipc	ra,0xfffff
    80001cba:	d6e080e7          	jalr	-658(ra) # 80000a24 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001cbe:	16848493          	addi	s1,s1,360
    80001cc2:	03348963          	beq	s1,s3,80001cf4 <scheduler+0x92>
      acquire(&p->lock);
    80001cc6:	8526                	mv	a0,s1
    80001cc8:	fffff097          	auipc	ra,0xfffff
    80001ccc:	cf4080e7          	jalr	-780(ra) # 800009bc <acquire>
      if(p->state == RUNNABLE) {
    80001cd0:	4c9c                	lw	a5,24(s1)
    80001cd2:	ff2791e3          	bne	a5,s2,80001cb4 <scheduler+0x52>
        p->state = RUNNING;
    80001cd6:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001cda:	009a3c23          	sd	s1,24(s4)
        swtch(&c->scheduler, &p->context);
    80001cde:	06048593          	addi	a1,s1,96
    80001ce2:	855a                	mv	a0,s6
    80001ce4:	00000097          	auipc	ra,0x0
    80001ce8:	604080e7          	jalr	1540(ra) # 800022e8 <swtch>
        c->proc = 0;
    80001cec:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80001cf0:	8ade                	mv	s5,s7
    80001cf2:	b7c9                	j	80001cb4 <scheduler+0x52>
    if(found == 0){
    80001cf4:	020a9063          	bnez	s5,80001d14 <scheduler+0xb2>
  asm volatile("csrr %0, sie" : "=r" (x) );
    80001cf8:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    80001cfc:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    80001d00:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001d04:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001d08:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001d0c:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80001d10:	10500073          	wfi
  asm volatile("csrr %0, sie" : "=r" (x) );
    80001d14:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    80001d18:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    80001d1c:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001d20:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001d24:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001d28:	10079073          	csrw	sstatus,a5
    int found = 0;
    80001d2c:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80001d2e:	00010497          	auipc	s1,0x10
    80001d32:	fb248493          	addi	s1,s1,-78 # 80011ce0 <proc>
      if(p->state == RUNNABLE) {
    80001d36:	4909                	li	s2,2
    80001d38:	b779                	j	80001cc6 <scheduler+0x64>

0000000080001d3a <sched>:
{
    80001d3a:	7179                	addi	sp,sp,-48
    80001d3c:	f406                	sd	ra,40(sp)
    80001d3e:	f022                	sd	s0,32(sp)
    80001d40:	ec26                	sd	s1,24(sp)
    80001d42:	e84a                	sd	s2,16(sp)
    80001d44:	e44e                	sd	s3,8(sp)
    80001d46:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001d48:	00000097          	auipc	ra,0x0
    80001d4c:	9d4080e7          	jalr	-1580(ra) # 8000171c <myproc>
    80001d50:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001d52:	fffff097          	auipc	ra,0xfffff
    80001d56:	c2a080e7          	jalr	-982(ra) # 8000097c <holding>
    80001d5a:	c93d                	beqz	a0,80001dd0 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001d5c:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001d5e:	2781                	sext.w	a5,a5
    80001d60:	079e                	slli	a5,a5,0x7
    80001d62:	00010717          	auipc	a4,0x10
    80001d66:	b6670713          	addi	a4,a4,-1178 # 800118c8 <pid_lock>
    80001d6a:	97ba                	add	a5,a5,a4
    80001d6c:	0907a703          	lw	a4,144(a5)
    80001d70:	4785                	li	a5,1
    80001d72:	06f71763          	bne	a4,a5,80001de0 <sched+0xa6>
  if(p->state == RUNNING)
    80001d76:	4c98                	lw	a4,24(s1)
    80001d78:	478d                	li	a5,3
    80001d7a:	06f70b63          	beq	a4,a5,80001df0 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001d7e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001d82:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001d84:	efb5                	bnez	a5,80001e00 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001d86:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001d88:	00010917          	auipc	s2,0x10
    80001d8c:	b4090913          	addi	s2,s2,-1216 # 800118c8 <pid_lock>
    80001d90:	2781                	sext.w	a5,a5
    80001d92:	079e                	slli	a5,a5,0x7
    80001d94:	97ca                	add	a5,a5,s2
    80001d96:	0947a983          	lw	s3,148(a5)
    80001d9a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->scheduler);
    80001d9c:	2781                	sext.w	a5,a5
    80001d9e:	079e                	slli	a5,a5,0x7
    80001da0:	00010597          	auipc	a1,0x10
    80001da4:	b4858593          	addi	a1,a1,-1208 # 800118e8 <cpus+0x8>
    80001da8:	95be                	add	a1,a1,a5
    80001daa:	06048513          	addi	a0,s1,96
    80001dae:	00000097          	auipc	ra,0x0
    80001db2:	53a080e7          	jalr	1338(ra) # 800022e8 <swtch>
    80001db6:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001db8:	2781                	sext.w	a5,a5
    80001dba:	079e                	slli	a5,a5,0x7
    80001dbc:	97ca                	add	a5,a5,s2
    80001dbe:	0937aa23          	sw	s3,148(a5)
}
    80001dc2:	70a2                	ld	ra,40(sp)
    80001dc4:	7402                	ld	s0,32(sp)
    80001dc6:	64e2                	ld	s1,24(sp)
    80001dc8:	6942                	ld	s2,16(sp)
    80001dca:	69a2                	ld	s3,8(sp)
    80001dcc:	6145                	addi	sp,sp,48
    80001dce:	8082                	ret
    panic("sched p->lock");
    80001dd0:	00005517          	auipc	a0,0x5
    80001dd4:	51850513          	addi	a0,a0,1304 # 800072e8 <userret+0x258>
    80001dd8:	ffffe097          	auipc	ra,0xffffe
    80001ddc:	770080e7          	jalr	1904(ra) # 80000548 <panic>
    panic("sched locks");
    80001de0:	00005517          	auipc	a0,0x5
    80001de4:	51850513          	addi	a0,a0,1304 # 800072f8 <userret+0x268>
    80001de8:	ffffe097          	auipc	ra,0xffffe
    80001dec:	760080e7          	jalr	1888(ra) # 80000548 <panic>
    panic("sched running");
    80001df0:	00005517          	auipc	a0,0x5
    80001df4:	51850513          	addi	a0,a0,1304 # 80007308 <userret+0x278>
    80001df8:	ffffe097          	auipc	ra,0xffffe
    80001dfc:	750080e7          	jalr	1872(ra) # 80000548 <panic>
    panic("sched interruptible");
    80001e00:	00005517          	auipc	a0,0x5
    80001e04:	51850513          	addi	a0,a0,1304 # 80007318 <userret+0x288>
    80001e08:	ffffe097          	auipc	ra,0xffffe
    80001e0c:	740080e7          	jalr	1856(ra) # 80000548 <panic>

0000000080001e10 <exit>:
{
    80001e10:	7179                	addi	sp,sp,-48
    80001e12:	f406                	sd	ra,40(sp)
    80001e14:	f022                	sd	s0,32(sp)
    80001e16:	ec26                	sd	s1,24(sp)
    80001e18:	e84a                	sd	s2,16(sp)
    80001e1a:	e44e                	sd	s3,8(sp)
    80001e1c:	e052                	sd	s4,0(sp)
    80001e1e:	1800                	addi	s0,sp,48
    80001e20:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80001e22:	00000097          	auipc	ra,0x0
    80001e26:	8fa080e7          	jalr	-1798(ra) # 8000171c <myproc>
    80001e2a:	89aa                	mv	s3,a0
  if(p == initproc)
    80001e2c:	00026797          	auipc	a5,0x26
    80001e30:	20c7b783          	ld	a5,524(a5) # 80028038 <initproc>
    80001e34:	0d050493          	addi	s1,a0,208
    80001e38:	15050913          	addi	s2,a0,336
    80001e3c:	02a79363          	bne	a5,a0,80001e62 <exit+0x52>
    panic("init exiting");
    80001e40:	00005517          	auipc	a0,0x5
    80001e44:	4f050513          	addi	a0,a0,1264 # 80007330 <userret+0x2a0>
    80001e48:	ffffe097          	auipc	ra,0xffffe
    80001e4c:	700080e7          	jalr	1792(ra) # 80000548 <panic>
      fileclose(f);
    80001e50:	00002097          	auipc	ra,0x2
    80001e54:	5ce080e7          	jalr	1486(ra) # 8000441e <fileclose>
      p->ofile[fd] = 0;
    80001e58:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80001e5c:	04a1                	addi	s1,s1,8
    80001e5e:	01248563          	beq	s1,s2,80001e68 <exit+0x58>
    if(p->ofile[fd]){
    80001e62:	6088                	ld	a0,0(s1)
    80001e64:	f575                	bnez	a0,80001e50 <exit+0x40>
    80001e66:	bfdd                	j	80001e5c <exit+0x4c>
  begin_op(ROOTDEV);
    80001e68:	4501                	li	a0,0
    80001e6a:	00002097          	auipc	ra,0x2
    80001e6e:	f8c080e7          	jalr	-116(ra) # 80003df6 <begin_op>
  iput(p->cwd);
    80001e72:	1509b503          	ld	a0,336(s3)
    80001e76:	00001097          	auipc	ra,0x1
    80001e7a:	5e4080e7          	jalr	1508(ra) # 8000345a <iput>
  end_op(ROOTDEV);
    80001e7e:	4501                	li	a0,0
    80001e80:	00002097          	auipc	ra,0x2
    80001e84:	020080e7          	jalr	32(ra) # 80003ea0 <end_op>
  p->cwd = 0;
    80001e88:	1409b823          	sd	zero,336(s3)
  acquire(&p->parent->lock);
    80001e8c:	0209b503          	ld	a0,32(s3)
    80001e90:	fffff097          	auipc	ra,0xfffff
    80001e94:	b2c080e7          	jalr	-1236(ra) # 800009bc <acquire>
  acquire(&p->lock);
    80001e98:	854e                	mv	a0,s3
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	b22080e7          	jalr	-1246(ra) # 800009bc <acquire>
  reparent(p, p->parent);
    80001ea2:	0209b583          	ld	a1,32(s3)
    80001ea6:	854e                	mv	a0,s3
    80001ea8:	00000097          	auipc	ra,0x0
    80001eac:	cf0080e7          	jalr	-784(ra) # 80001b98 <reparent>
  wakeup1(p->parent);
    80001eb0:	0209b783          	ld	a5,32(s3)
  if(p->chan == p && p->state == SLEEPING) {
    80001eb4:	7798                	ld	a4,40(a5)
    80001eb6:	02e78963          	beq	a5,a4,80001ee8 <exit+0xd8>
  p->xstate = status;
    80001eba:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80001ebe:	4791                	li	a5,4
    80001ec0:	00f9ac23          	sw	a5,24(s3)
  release(&p->parent->lock);
    80001ec4:	0209b503          	ld	a0,32(s3)
    80001ec8:	fffff097          	auipc	ra,0xfffff
    80001ecc:	b5c080e7          	jalr	-1188(ra) # 80000a24 <release>
  sched();
    80001ed0:	00000097          	auipc	ra,0x0
    80001ed4:	e6a080e7          	jalr	-406(ra) # 80001d3a <sched>
  panic("zombie exit");
    80001ed8:	00005517          	auipc	a0,0x5
    80001edc:	46850513          	addi	a0,a0,1128 # 80007340 <userret+0x2b0>
    80001ee0:	ffffe097          	auipc	ra,0xffffe
    80001ee4:	668080e7          	jalr	1640(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001ee8:	4f94                	lw	a3,24(a5)
    80001eea:	4705                	li	a4,1
    80001eec:	fce697e3          	bne	a3,a4,80001eba <exit+0xaa>
    p->state = RUNNABLE;
    80001ef0:	4709                	li	a4,2
    80001ef2:	cf98                	sw	a4,24(a5)
    80001ef4:	b7d9                	j	80001eba <exit+0xaa>

0000000080001ef6 <yield>:
{
    80001ef6:	1101                	addi	sp,sp,-32
    80001ef8:	ec06                	sd	ra,24(sp)
    80001efa:	e822                	sd	s0,16(sp)
    80001efc:	e426                	sd	s1,8(sp)
    80001efe:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001f00:	00000097          	auipc	ra,0x0
    80001f04:	81c080e7          	jalr	-2020(ra) # 8000171c <myproc>
    80001f08:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001f0a:	fffff097          	auipc	ra,0xfffff
    80001f0e:	ab2080e7          	jalr	-1358(ra) # 800009bc <acquire>
  p->state = RUNNABLE;
    80001f12:	4789                	li	a5,2
    80001f14:	cc9c                	sw	a5,24(s1)
  sched();
    80001f16:	00000097          	auipc	ra,0x0
    80001f1a:	e24080e7          	jalr	-476(ra) # 80001d3a <sched>
  release(&p->lock);
    80001f1e:	8526                	mv	a0,s1
    80001f20:	fffff097          	auipc	ra,0xfffff
    80001f24:	b04080e7          	jalr	-1276(ra) # 80000a24 <release>
}
    80001f28:	60e2                	ld	ra,24(sp)
    80001f2a:	6442                	ld	s0,16(sp)
    80001f2c:	64a2                	ld	s1,8(sp)
    80001f2e:	6105                	addi	sp,sp,32
    80001f30:	8082                	ret

0000000080001f32 <sleep>:
{
    80001f32:	7179                	addi	sp,sp,-48
    80001f34:	f406                	sd	ra,40(sp)
    80001f36:	f022                	sd	s0,32(sp)
    80001f38:	ec26                	sd	s1,24(sp)
    80001f3a:	e84a                	sd	s2,16(sp)
    80001f3c:	e44e                	sd	s3,8(sp)
    80001f3e:	1800                	addi	s0,sp,48
    80001f40:	89aa                	mv	s3,a0
    80001f42:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80001f44:	fffff097          	auipc	ra,0xfffff
    80001f48:	7d8080e7          	jalr	2008(ra) # 8000171c <myproc>
    80001f4c:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80001f4e:	05250663          	beq	a0,s2,80001f9a <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80001f52:	fffff097          	auipc	ra,0xfffff
    80001f56:	a6a080e7          	jalr	-1430(ra) # 800009bc <acquire>
    release(lk);
    80001f5a:	854a                	mv	a0,s2
    80001f5c:	fffff097          	auipc	ra,0xfffff
    80001f60:	ac8080e7          	jalr	-1336(ra) # 80000a24 <release>
  p->chan = chan;
    80001f64:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80001f68:	4785                	li	a5,1
    80001f6a:	cc9c                	sw	a5,24(s1)
  sched();
    80001f6c:	00000097          	auipc	ra,0x0
    80001f70:	dce080e7          	jalr	-562(ra) # 80001d3a <sched>
  p->chan = 0;
    80001f74:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80001f78:	8526                	mv	a0,s1
    80001f7a:	fffff097          	auipc	ra,0xfffff
    80001f7e:	aaa080e7          	jalr	-1366(ra) # 80000a24 <release>
    acquire(lk);
    80001f82:	854a                	mv	a0,s2
    80001f84:	fffff097          	auipc	ra,0xfffff
    80001f88:	a38080e7          	jalr	-1480(ra) # 800009bc <acquire>
}
    80001f8c:	70a2                	ld	ra,40(sp)
    80001f8e:	7402                	ld	s0,32(sp)
    80001f90:	64e2                	ld	s1,24(sp)
    80001f92:	6942                	ld	s2,16(sp)
    80001f94:	69a2                	ld	s3,8(sp)
    80001f96:	6145                	addi	sp,sp,48
    80001f98:	8082                	ret
  p->chan = chan;
    80001f9a:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80001f9e:	4785                	li	a5,1
    80001fa0:	cd1c                	sw	a5,24(a0)
  sched();
    80001fa2:	00000097          	auipc	ra,0x0
    80001fa6:	d98080e7          	jalr	-616(ra) # 80001d3a <sched>
  p->chan = 0;
    80001faa:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80001fae:	bff9                	j	80001f8c <sleep+0x5a>

0000000080001fb0 <wait>:
{
    80001fb0:	715d                	addi	sp,sp,-80
    80001fb2:	e486                	sd	ra,72(sp)
    80001fb4:	e0a2                	sd	s0,64(sp)
    80001fb6:	fc26                	sd	s1,56(sp)
    80001fb8:	f84a                	sd	s2,48(sp)
    80001fba:	f44e                	sd	s3,40(sp)
    80001fbc:	f052                	sd	s4,32(sp)
    80001fbe:	ec56                	sd	s5,24(sp)
    80001fc0:	e85a                	sd	s6,16(sp)
    80001fc2:	e45e                	sd	s7,8(sp)
    80001fc4:	0880                	addi	s0,sp,80
    80001fc6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80001fc8:	fffff097          	auipc	ra,0xfffff
    80001fcc:	754080e7          	jalr	1876(ra) # 8000171c <myproc>
    80001fd0:	892a                	mv	s2,a0
  acquire(&p->lock);
    80001fd2:	fffff097          	auipc	ra,0xfffff
    80001fd6:	9ea080e7          	jalr	-1558(ra) # 800009bc <acquire>
    havekids = 0;
    80001fda:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80001fdc:	4a11                	li	s4,4
        havekids = 1;
    80001fde:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80001fe0:	00015997          	auipc	s3,0x15
    80001fe4:	70098993          	addi	s3,s3,1792 # 800176e0 <tickslock>
    havekids = 0;
    80001fe8:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80001fea:	00010497          	auipc	s1,0x10
    80001fee:	cf648493          	addi	s1,s1,-778 # 80011ce0 <proc>
    80001ff2:	a08d                	j	80002054 <wait+0xa4>
          pid = np->pid;
    80001ff4:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80001ff8:	000b0e63          	beqz	s6,80002014 <wait+0x64>
    80001ffc:	4691                	li	a3,4
    80001ffe:	03448613          	addi	a2,s1,52
    80002002:	85da                	mv	a1,s6
    80002004:	05093503          	ld	a0,80(s2)
    80002008:	fffff097          	auipc	ra,0xfffff
    8000200c:	438080e7          	jalr	1080(ra) # 80001440 <copyout>
    80002010:	02054263          	bltz	a0,80002034 <wait+0x84>
          freeproc(np);
    80002014:	8526                	mv	a0,s1
    80002016:	00000097          	auipc	ra,0x0
    8000201a:	922080e7          	jalr	-1758(ra) # 80001938 <freeproc>
          release(&np->lock);
    8000201e:	8526                	mv	a0,s1
    80002020:	fffff097          	auipc	ra,0xfffff
    80002024:	a04080e7          	jalr	-1532(ra) # 80000a24 <release>
          release(&p->lock);
    80002028:	854a                	mv	a0,s2
    8000202a:	fffff097          	auipc	ra,0xfffff
    8000202e:	9fa080e7          	jalr	-1542(ra) # 80000a24 <release>
          return pid;
    80002032:	a8a9                	j	8000208c <wait+0xdc>
            release(&np->lock);
    80002034:	8526                	mv	a0,s1
    80002036:	fffff097          	auipc	ra,0xfffff
    8000203a:	9ee080e7          	jalr	-1554(ra) # 80000a24 <release>
            release(&p->lock);
    8000203e:	854a                	mv	a0,s2
    80002040:	fffff097          	auipc	ra,0xfffff
    80002044:	9e4080e7          	jalr	-1564(ra) # 80000a24 <release>
            return -1;
    80002048:	59fd                	li	s3,-1
    8000204a:	a089                	j	8000208c <wait+0xdc>
    for(np = proc; np < &proc[NPROC]; np++){
    8000204c:	16848493          	addi	s1,s1,360
    80002050:	03348463          	beq	s1,s3,80002078 <wait+0xc8>
      if(np->parent == p){
    80002054:	709c                	ld	a5,32(s1)
    80002056:	ff279be3          	bne	a5,s2,8000204c <wait+0x9c>
        acquire(&np->lock);
    8000205a:	8526                	mv	a0,s1
    8000205c:	fffff097          	auipc	ra,0xfffff
    80002060:	960080e7          	jalr	-1696(ra) # 800009bc <acquire>
        if(np->state == ZOMBIE){
    80002064:	4c9c                	lw	a5,24(s1)
    80002066:	f94787e3          	beq	a5,s4,80001ff4 <wait+0x44>
        release(&np->lock);
    8000206a:	8526                	mv	a0,s1
    8000206c:	fffff097          	auipc	ra,0xfffff
    80002070:	9b8080e7          	jalr	-1608(ra) # 80000a24 <release>
        havekids = 1;
    80002074:	8756                	mv	a4,s5
    80002076:	bfd9                	j	8000204c <wait+0x9c>
    if(!havekids || p->killed){
    80002078:	c701                	beqz	a4,80002080 <wait+0xd0>
    8000207a:	03092783          	lw	a5,48(s2)
    8000207e:	c39d                	beqz	a5,800020a4 <wait+0xf4>
      release(&p->lock);
    80002080:	854a                	mv	a0,s2
    80002082:	fffff097          	auipc	ra,0xfffff
    80002086:	9a2080e7          	jalr	-1630(ra) # 80000a24 <release>
      return -1;
    8000208a:	59fd                	li	s3,-1
}
    8000208c:	854e                	mv	a0,s3
    8000208e:	60a6                	ld	ra,72(sp)
    80002090:	6406                	ld	s0,64(sp)
    80002092:	74e2                	ld	s1,56(sp)
    80002094:	7942                	ld	s2,48(sp)
    80002096:	79a2                	ld	s3,40(sp)
    80002098:	7a02                	ld	s4,32(sp)
    8000209a:	6ae2                	ld	s5,24(sp)
    8000209c:	6b42                	ld	s6,16(sp)
    8000209e:	6ba2                	ld	s7,8(sp)
    800020a0:	6161                	addi	sp,sp,80
    800020a2:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800020a4:	85ca                	mv	a1,s2
    800020a6:	854a                	mv	a0,s2
    800020a8:	00000097          	auipc	ra,0x0
    800020ac:	e8a080e7          	jalr	-374(ra) # 80001f32 <sleep>
    havekids = 0;
    800020b0:	bf25                	j	80001fe8 <wait+0x38>

00000000800020b2 <wakeup>:
{
    800020b2:	7139                	addi	sp,sp,-64
    800020b4:	fc06                	sd	ra,56(sp)
    800020b6:	f822                	sd	s0,48(sp)
    800020b8:	f426                	sd	s1,40(sp)
    800020ba:	f04a                	sd	s2,32(sp)
    800020bc:	ec4e                	sd	s3,24(sp)
    800020be:	e852                	sd	s4,16(sp)
    800020c0:	e456                	sd	s5,8(sp)
    800020c2:	0080                	addi	s0,sp,64
    800020c4:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800020c6:	00010497          	auipc	s1,0x10
    800020ca:	c1a48493          	addi	s1,s1,-998 # 80011ce0 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800020ce:	4985                	li	s3,1
      p->state = RUNNABLE;
    800020d0:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800020d2:	00015917          	auipc	s2,0x15
    800020d6:	60e90913          	addi	s2,s2,1550 # 800176e0 <tickslock>
    800020da:	a811                	j	800020ee <wakeup+0x3c>
    release(&p->lock);
    800020dc:	8526                	mv	a0,s1
    800020de:	fffff097          	auipc	ra,0xfffff
    800020e2:	946080e7          	jalr	-1722(ra) # 80000a24 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800020e6:	16848493          	addi	s1,s1,360
    800020ea:	03248063          	beq	s1,s2,8000210a <wakeup+0x58>
    acquire(&p->lock);
    800020ee:	8526                	mv	a0,s1
    800020f0:	fffff097          	auipc	ra,0xfffff
    800020f4:	8cc080e7          	jalr	-1844(ra) # 800009bc <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800020f8:	4c9c                	lw	a5,24(s1)
    800020fa:	ff3791e3          	bne	a5,s3,800020dc <wakeup+0x2a>
    800020fe:	749c                	ld	a5,40(s1)
    80002100:	fd479ee3          	bne	a5,s4,800020dc <wakeup+0x2a>
      p->state = RUNNABLE;
    80002104:	0154ac23          	sw	s5,24(s1)
    80002108:	bfd1                	j	800020dc <wakeup+0x2a>
}
    8000210a:	70e2                	ld	ra,56(sp)
    8000210c:	7442                	ld	s0,48(sp)
    8000210e:	74a2                	ld	s1,40(sp)
    80002110:	7902                	ld	s2,32(sp)
    80002112:	69e2                	ld	s3,24(sp)
    80002114:	6a42                	ld	s4,16(sp)
    80002116:	6aa2                	ld	s5,8(sp)
    80002118:	6121                	addi	sp,sp,64
    8000211a:	8082                	ret

000000008000211c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000211c:	7179                	addi	sp,sp,-48
    8000211e:	f406                	sd	ra,40(sp)
    80002120:	f022                	sd	s0,32(sp)
    80002122:	ec26                	sd	s1,24(sp)
    80002124:	e84a                	sd	s2,16(sp)
    80002126:	e44e                	sd	s3,8(sp)
    80002128:	1800                	addi	s0,sp,48
    8000212a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000212c:	00010497          	auipc	s1,0x10
    80002130:	bb448493          	addi	s1,s1,-1100 # 80011ce0 <proc>
    80002134:	00015997          	auipc	s3,0x15
    80002138:	5ac98993          	addi	s3,s3,1452 # 800176e0 <tickslock>
    acquire(&p->lock);
    8000213c:	8526                	mv	a0,s1
    8000213e:	fffff097          	auipc	ra,0xfffff
    80002142:	87e080e7          	jalr	-1922(ra) # 800009bc <acquire>
    if(p->pid == pid){
    80002146:	5c9c                	lw	a5,56(s1)
    80002148:	01278d63          	beq	a5,s2,80002162 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000214c:	8526                	mv	a0,s1
    8000214e:	fffff097          	auipc	ra,0xfffff
    80002152:	8d6080e7          	jalr	-1834(ra) # 80000a24 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002156:	16848493          	addi	s1,s1,360
    8000215a:	ff3491e3          	bne	s1,s3,8000213c <kill+0x20>
  }
  return -1;
    8000215e:	557d                	li	a0,-1
    80002160:	a821                	j	80002178 <kill+0x5c>
      p->killed = 1;
    80002162:	4785                	li	a5,1
    80002164:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002166:	4c98                	lw	a4,24(s1)
    80002168:	00f70f63          	beq	a4,a5,80002186 <kill+0x6a>
      release(&p->lock);
    8000216c:	8526                	mv	a0,s1
    8000216e:	fffff097          	auipc	ra,0xfffff
    80002172:	8b6080e7          	jalr	-1866(ra) # 80000a24 <release>
      return 0;
    80002176:	4501                	li	a0,0
}
    80002178:	70a2                	ld	ra,40(sp)
    8000217a:	7402                	ld	s0,32(sp)
    8000217c:	64e2                	ld	s1,24(sp)
    8000217e:	6942                	ld	s2,16(sp)
    80002180:	69a2                	ld	s3,8(sp)
    80002182:	6145                	addi	sp,sp,48
    80002184:	8082                	ret
        p->state = RUNNABLE;
    80002186:	4789                	li	a5,2
    80002188:	cc9c                	sw	a5,24(s1)
    8000218a:	b7cd                	j	8000216c <kill+0x50>

000000008000218c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000218c:	7179                	addi	sp,sp,-48
    8000218e:	f406                	sd	ra,40(sp)
    80002190:	f022                	sd	s0,32(sp)
    80002192:	ec26                	sd	s1,24(sp)
    80002194:	e84a                	sd	s2,16(sp)
    80002196:	e44e                	sd	s3,8(sp)
    80002198:	e052                	sd	s4,0(sp)
    8000219a:	1800                	addi	s0,sp,48
    8000219c:	84aa                	mv	s1,a0
    8000219e:	892e                	mv	s2,a1
    800021a0:	89b2                	mv	s3,a2
    800021a2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800021a4:	fffff097          	auipc	ra,0xfffff
    800021a8:	578080e7          	jalr	1400(ra) # 8000171c <myproc>
  if(user_dst){
    800021ac:	c08d                	beqz	s1,800021ce <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800021ae:	86d2                	mv	a3,s4
    800021b0:	864e                	mv	a2,s3
    800021b2:	85ca                	mv	a1,s2
    800021b4:	6928                	ld	a0,80(a0)
    800021b6:	fffff097          	auipc	ra,0xfffff
    800021ba:	28a080e7          	jalr	650(ra) # 80001440 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800021be:	70a2                	ld	ra,40(sp)
    800021c0:	7402                	ld	s0,32(sp)
    800021c2:	64e2                	ld	s1,24(sp)
    800021c4:	6942                	ld	s2,16(sp)
    800021c6:	69a2                	ld	s3,8(sp)
    800021c8:	6a02                	ld	s4,0(sp)
    800021ca:	6145                	addi	sp,sp,48
    800021cc:	8082                	ret
    memmove((char *)dst, src, len);
    800021ce:	000a061b          	sext.w	a2,s4
    800021d2:	85ce                	mv	a1,s3
    800021d4:	854a                	mv	a0,s2
    800021d6:	fffff097          	auipc	ra,0xfffff
    800021da:	906080e7          	jalr	-1786(ra) # 80000adc <memmove>
    return 0;
    800021de:	8526                	mv	a0,s1
    800021e0:	bff9                	j	800021be <either_copyout+0x32>

00000000800021e2 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800021e2:	7179                	addi	sp,sp,-48
    800021e4:	f406                	sd	ra,40(sp)
    800021e6:	f022                	sd	s0,32(sp)
    800021e8:	ec26                	sd	s1,24(sp)
    800021ea:	e84a                	sd	s2,16(sp)
    800021ec:	e44e                	sd	s3,8(sp)
    800021ee:	e052                	sd	s4,0(sp)
    800021f0:	1800                	addi	s0,sp,48
    800021f2:	892a                	mv	s2,a0
    800021f4:	84ae                	mv	s1,a1
    800021f6:	89b2                	mv	s3,a2
    800021f8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800021fa:	fffff097          	auipc	ra,0xfffff
    800021fe:	522080e7          	jalr	1314(ra) # 8000171c <myproc>
  if(user_src){
    80002202:	c08d                	beqz	s1,80002224 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002204:	86d2                	mv	a3,s4
    80002206:	864e                	mv	a2,s3
    80002208:	85ca                	mv	a1,s2
    8000220a:	6928                	ld	a0,80(a0)
    8000220c:	fffff097          	auipc	ra,0xfffff
    80002210:	2c6080e7          	jalr	710(ra) # 800014d2 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002214:	70a2                	ld	ra,40(sp)
    80002216:	7402                	ld	s0,32(sp)
    80002218:	64e2                	ld	s1,24(sp)
    8000221a:	6942                	ld	s2,16(sp)
    8000221c:	69a2                	ld	s3,8(sp)
    8000221e:	6a02                	ld	s4,0(sp)
    80002220:	6145                	addi	sp,sp,48
    80002222:	8082                	ret
    memmove(dst, (char*)src, len);
    80002224:	000a061b          	sext.w	a2,s4
    80002228:	85ce                	mv	a1,s3
    8000222a:	854a                	mv	a0,s2
    8000222c:	fffff097          	auipc	ra,0xfffff
    80002230:	8b0080e7          	jalr	-1872(ra) # 80000adc <memmove>
    return 0;
    80002234:	8526                	mv	a0,s1
    80002236:	bff9                	j	80002214 <either_copyin+0x32>

0000000080002238 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002238:	715d                	addi	sp,sp,-80
    8000223a:	e486                	sd	ra,72(sp)
    8000223c:	e0a2                	sd	s0,64(sp)
    8000223e:	fc26                	sd	s1,56(sp)
    80002240:	f84a                	sd	s2,48(sp)
    80002242:	f44e                	sd	s3,40(sp)
    80002244:	f052                	sd	s4,32(sp)
    80002246:	ec56                	sd	s5,24(sp)
    80002248:	e85a                	sd	s6,16(sp)
    8000224a:	e45e                	sd	s7,8(sp)
    8000224c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000224e:	00005517          	auipc	a0,0x5
    80002252:	f5250513          	addi	a0,a0,-174 # 800071a0 <userret+0x110>
    80002256:	ffffe097          	auipc	ra,0xffffe
    8000225a:	33c080e7          	jalr	828(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000225e:	00010497          	auipc	s1,0x10
    80002262:	bda48493          	addi	s1,s1,-1062 # 80011e38 <proc+0x158>
    80002266:	00015917          	auipc	s2,0x15
    8000226a:	5d290913          	addi	s2,s2,1490 # 80017838 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000226e:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002270:	00005997          	auipc	s3,0x5
    80002274:	0e098993          	addi	s3,s3,224 # 80007350 <userret+0x2c0>
    printf("%d %s %s", p->pid, state, p->name);
    80002278:	00005a97          	auipc	s5,0x5
    8000227c:	0e0a8a93          	addi	s5,s5,224 # 80007358 <userret+0x2c8>
    printf("\n");
    80002280:	00005a17          	auipc	s4,0x5
    80002284:	f20a0a13          	addi	s4,s4,-224 # 800071a0 <userret+0x110>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002288:	00005b97          	auipc	s7,0x5
    8000228c:	768b8b93          	addi	s7,s7,1896 # 800079f0 <states.0>
    80002290:	a00d                	j	800022b2 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002292:	ee06a583          	lw	a1,-288(a3)
    80002296:	8556                	mv	a0,s5
    80002298:	ffffe097          	auipc	ra,0xffffe
    8000229c:	2fa080e7          	jalr	762(ra) # 80000592 <printf>
    printf("\n");
    800022a0:	8552                	mv	a0,s4
    800022a2:	ffffe097          	auipc	ra,0xffffe
    800022a6:	2f0080e7          	jalr	752(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800022aa:	16848493          	addi	s1,s1,360
    800022ae:	03248263          	beq	s1,s2,800022d2 <procdump+0x9a>
    if(p->state == UNUSED)
    800022b2:	86a6                	mv	a3,s1
    800022b4:	ec04a783          	lw	a5,-320(s1)
    800022b8:	dbed                	beqz	a5,800022aa <procdump+0x72>
      state = "???";
    800022ba:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800022bc:	fcfb6be3          	bltu	s6,a5,80002292 <procdump+0x5a>
    800022c0:	02079713          	slli	a4,a5,0x20
    800022c4:	01d75793          	srli	a5,a4,0x1d
    800022c8:	97de                	add	a5,a5,s7
    800022ca:	6390                	ld	a2,0(a5)
    800022cc:	f279                	bnez	a2,80002292 <procdump+0x5a>
      state = "???";
    800022ce:	864e                	mv	a2,s3
    800022d0:	b7c9                	j	80002292 <procdump+0x5a>
  }
}
    800022d2:	60a6                	ld	ra,72(sp)
    800022d4:	6406                	ld	s0,64(sp)
    800022d6:	74e2                	ld	s1,56(sp)
    800022d8:	7942                	ld	s2,48(sp)
    800022da:	79a2                	ld	s3,40(sp)
    800022dc:	7a02                	ld	s4,32(sp)
    800022de:	6ae2                	ld	s5,24(sp)
    800022e0:	6b42                	ld	s6,16(sp)
    800022e2:	6ba2                	ld	s7,8(sp)
    800022e4:	6161                	addi	sp,sp,80
    800022e6:	8082                	ret

00000000800022e8 <swtch>:
    800022e8:	00153023          	sd	ra,0(a0)
    800022ec:	00253423          	sd	sp,8(a0)
    800022f0:	e900                	sd	s0,16(a0)
    800022f2:	ed04                	sd	s1,24(a0)
    800022f4:	03253023          	sd	s2,32(a0)
    800022f8:	03353423          	sd	s3,40(a0)
    800022fc:	03453823          	sd	s4,48(a0)
    80002300:	03553c23          	sd	s5,56(a0)
    80002304:	05653023          	sd	s6,64(a0)
    80002308:	05753423          	sd	s7,72(a0)
    8000230c:	05853823          	sd	s8,80(a0)
    80002310:	05953c23          	sd	s9,88(a0)
    80002314:	07a53023          	sd	s10,96(a0)
    80002318:	07b53423          	sd	s11,104(a0)
    8000231c:	0005b083          	ld	ra,0(a1)
    80002320:	0085b103          	ld	sp,8(a1)
    80002324:	6980                	ld	s0,16(a1)
    80002326:	6d84                	ld	s1,24(a1)
    80002328:	0205b903          	ld	s2,32(a1)
    8000232c:	0285b983          	ld	s3,40(a1)
    80002330:	0305ba03          	ld	s4,48(a1)
    80002334:	0385ba83          	ld	s5,56(a1)
    80002338:	0405bb03          	ld	s6,64(a1)
    8000233c:	0485bb83          	ld	s7,72(a1)
    80002340:	0505bc03          	ld	s8,80(a1)
    80002344:	0585bc83          	ld	s9,88(a1)
    80002348:	0605bd03          	ld	s10,96(a1)
    8000234c:	0685bd83          	ld	s11,104(a1)
    80002350:	8082                	ret

0000000080002352 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002352:	1141                	addi	sp,sp,-16
    80002354:	e406                	sd	ra,8(sp)
    80002356:	e022                	sd	s0,0(sp)
    80002358:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000235a:	00005597          	auipc	a1,0x5
    8000235e:	03658593          	addi	a1,a1,54 # 80007390 <userret+0x300>
    80002362:	00015517          	auipc	a0,0x15
    80002366:	37e50513          	addi	a0,a0,894 # 800176e0 <tickslock>
    8000236a:	ffffe097          	auipc	ra,0xffffe
    8000236e:	544080e7          	jalr	1348(ra) # 800008ae <initlock>
}
    80002372:	60a2                	ld	ra,8(sp)
    80002374:	6402                	ld	s0,0(sp)
    80002376:	0141                	addi	sp,sp,16
    80002378:	8082                	ret

000000008000237a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000237a:	1141                	addi	sp,sp,-16
    8000237c:	e422                	sd	s0,8(sp)
    8000237e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002380:	00003797          	auipc	a5,0x3
    80002384:	79078793          	addi	a5,a5,1936 # 80005b10 <kernelvec>
    80002388:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000238c:	6422                	ld	s0,8(sp)
    8000238e:	0141                	addi	sp,sp,16
    80002390:	8082                	ret

0000000080002392 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002392:	1141                	addi	sp,sp,-16
    80002394:	e406                	sd	ra,8(sp)
    80002396:	e022                	sd	s0,0(sp)
    80002398:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000239a:	fffff097          	auipc	ra,0xfffff
    8000239e:	382080e7          	jalr	898(ra) # 8000171c <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800023a2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800023a6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800023a8:	10079073          	csrw	sstatus,a5
  // turn off interrupts, since we're switching
  // now from kerneltrap() to usertrap().
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800023ac:	00005617          	auipc	a2,0x5
    800023b0:	c5460613          	addi	a2,a2,-940 # 80007000 <trampoline>
    800023b4:	00005697          	auipc	a3,0x5
    800023b8:	c4c68693          	addi	a3,a3,-948 # 80007000 <trampoline>
    800023bc:	8e91                	sub	a3,a3,a2
    800023be:	040007b7          	lui	a5,0x4000
    800023c2:	17fd                	addi	a5,a5,-1
    800023c4:	07b2                	slli	a5,a5,0xc
    800023c6:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800023c8:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->tf->kernel_satp = r_satp();         // kernel page table
    800023cc:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800023ce:	180026f3          	csrr	a3,satp
    800023d2:	e314                	sd	a3,0(a4)
  p->tf->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800023d4:	6d38                	ld	a4,88(a0)
    800023d6:	6134                	ld	a3,64(a0)
    800023d8:	6585                	lui	a1,0x1
    800023da:	96ae                	add	a3,a3,a1
    800023dc:	e714                	sd	a3,8(a4)
  p->tf->kernel_trap = (uint64)usertrap;
    800023de:	6d38                	ld	a4,88(a0)
    800023e0:	00000697          	auipc	a3,0x0
    800023e4:	12868693          	addi	a3,a3,296 # 80002508 <usertrap>
    800023e8:	eb14                	sd	a3,16(a4)
  p->tf->kernel_hartid = r_tp();         // hartid for cpuid()
    800023ea:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800023ec:	8692                	mv	a3,tp
    800023ee:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800023f0:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800023f4:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800023f8:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800023fc:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->tf->epc);
    80002400:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002402:	6f18                	ld	a4,24(a4)
    80002404:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002408:	692c                	ld	a1,80(a0)
    8000240a:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000240c:	00005717          	auipc	a4,0x5
    80002410:	c8470713          	addi	a4,a4,-892 # 80007090 <userret>
    80002414:	8f11                	sub	a4,a4,a2
    80002416:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002418:	577d                	li	a4,-1
    8000241a:	177e                	slli	a4,a4,0x3f
    8000241c:	8dd9                	or	a1,a1,a4
    8000241e:	02000537          	lui	a0,0x2000
    80002422:	157d                	addi	a0,a0,-1
    80002424:	0536                	slli	a0,a0,0xd
    80002426:	9782                	jalr	a5
}
    80002428:	60a2                	ld	ra,8(sp)
    8000242a:	6402                	ld	s0,0(sp)
    8000242c:	0141                	addi	sp,sp,16
    8000242e:	8082                	ret

0000000080002430 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002430:	1101                	addi	sp,sp,-32
    80002432:	ec06                	sd	ra,24(sp)
    80002434:	e822                	sd	s0,16(sp)
    80002436:	e426                	sd	s1,8(sp)
    80002438:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000243a:	00015497          	auipc	s1,0x15
    8000243e:	2a648493          	addi	s1,s1,678 # 800176e0 <tickslock>
    80002442:	8526                	mv	a0,s1
    80002444:	ffffe097          	auipc	ra,0xffffe
    80002448:	578080e7          	jalr	1400(ra) # 800009bc <acquire>
  ticks++;
    8000244c:	00026517          	auipc	a0,0x26
    80002450:	bf450513          	addi	a0,a0,-1036 # 80028040 <ticks>
    80002454:	411c                	lw	a5,0(a0)
    80002456:	2785                	addiw	a5,a5,1
    80002458:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000245a:	00000097          	auipc	ra,0x0
    8000245e:	c58080e7          	jalr	-936(ra) # 800020b2 <wakeup>
  release(&tickslock);
    80002462:	8526                	mv	a0,s1
    80002464:	ffffe097          	auipc	ra,0xffffe
    80002468:	5c0080e7          	jalr	1472(ra) # 80000a24 <release>
}
    8000246c:	60e2                	ld	ra,24(sp)
    8000246e:	6442                	ld	s0,16(sp)
    80002470:	64a2                	ld	s1,8(sp)
    80002472:	6105                	addi	sp,sp,32
    80002474:	8082                	ret

0000000080002476 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002476:	1101                	addi	sp,sp,-32
    80002478:	ec06                	sd	ra,24(sp)
    8000247a:	e822                	sd	s0,16(sp)
    8000247c:	e426                	sd	s1,8(sp)
    8000247e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002480:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002484:	00074d63          	bltz	a4,8000249e <devintr+0x28>
      virtio_disk_intr(irq - VIRTIO0_IRQ);
    }

    plic_complete(irq);
    return 1;
  } else if(scause == 0x8000000000000001L){
    80002488:	57fd                	li	a5,-1
    8000248a:	17fe                	slli	a5,a5,0x3f
    8000248c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000248e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002490:	04f70b63          	beq	a4,a5,800024e6 <devintr+0x70>
  }
}
    80002494:	60e2                	ld	ra,24(sp)
    80002496:	6442                	ld	s0,16(sp)
    80002498:	64a2                	ld	s1,8(sp)
    8000249a:	6105                	addi	sp,sp,32
    8000249c:	8082                	ret
     (scause & 0xff) == 9){
    8000249e:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800024a2:	46a5                	li	a3,9
    800024a4:	fed792e3          	bne	a5,a3,80002488 <devintr+0x12>
    int irq = plic_claim();
    800024a8:	00003097          	auipc	ra,0x3
    800024ac:	782080e7          	jalr	1922(ra) # 80005c2a <plic_claim>
    800024b0:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800024b2:	47a9                	li	a5,10
    800024b4:	00f50e63          	beq	a0,a5,800024d0 <devintr+0x5a>
    } else if(irq == VIRTIO0_IRQ || irq == VIRTIO1_IRQ ){
    800024b8:	fff5079b          	addiw	a5,a0,-1
    800024bc:	4705                	li	a4,1
    800024be:	00f77e63          	bgeu	a4,a5,800024da <devintr+0x64>
    plic_complete(irq);
    800024c2:	8526                	mv	a0,s1
    800024c4:	00003097          	auipc	ra,0x3
    800024c8:	78a080e7          	jalr	1930(ra) # 80005c4e <plic_complete>
    return 1;
    800024cc:	4505                	li	a0,1
    800024ce:	b7d9                	j	80002494 <devintr+0x1e>
      uartintr();
    800024d0:	ffffe097          	auipc	ra,0xffffe
    800024d4:	358080e7          	jalr	856(ra) # 80000828 <uartintr>
    800024d8:	b7ed                	j	800024c2 <devintr+0x4c>
      virtio_disk_intr(irq - VIRTIO0_IRQ);
    800024da:	853e                	mv	a0,a5
    800024dc:	00004097          	auipc	ra,0x4
    800024e0:	d1c080e7          	jalr	-740(ra) # 800061f8 <virtio_disk_intr>
    800024e4:	bff9                	j	800024c2 <devintr+0x4c>
    if(cpuid() == 0){
    800024e6:	fffff097          	auipc	ra,0xfffff
    800024ea:	20a080e7          	jalr	522(ra) # 800016f0 <cpuid>
    800024ee:	c901                	beqz	a0,800024fe <devintr+0x88>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800024f0:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800024f4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800024f6:	14479073          	csrw	sip,a5
    return 2;
    800024fa:	4509                	li	a0,2
    800024fc:	bf61                	j	80002494 <devintr+0x1e>
      clockintr();
    800024fe:	00000097          	auipc	ra,0x0
    80002502:	f32080e7          	jalr	-206(ra) # 80002430 <clockintr>
    80002506:	b7ed                	j	800024f0 <devintr+0x7a>

0000000080002508 <usertrap>:
{
    80002508:	1101                	addi	sp,sp,-32
    8000250a:	ec06                	sd	ra,24(sp)
    8000250c:	e822                	sd	s0,16(sp)
    8000250e:	e426                	sd	s1,8(sp)
    80002510:	e04a                	sd	s2,0(sp)
    80002512:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002514:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002518:	1007f793          	andi	a5,a5,256
    8000251c:	e7bd                	bnez	a5,8000258a <usertrap+0x82>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000251e:	00003797          	auipc	a5,0x3
    80002522:	5f278793          	addi	a5,a5,1522 # 80005b10 <kernelvec>
    80002526:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000252a:	fffff097          	auipc	ra,0xfffff
    8000252e:	1f2080e7          	jalr	498(ra) # 8000171c <myproc>
    80002532:	84aa                	mv	s1,a0
  p->tf->epc = r_sepc();
    80002534:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002536:	14102773          	csrr	a4,sepc
    8000253a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000253c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002540:	47a1                	li	a5,8
    80002542:	06f71263          	bne	a4,a5,800025a6 <usertrap+0x9e>
    if(p->killed)
    80002546:	591c                	lw	a5,48(a0)
    80002548:	eba9                	bnez	a5,8000259a <usertrap+0x92>
    p->tf->epc += 4;
    8000254a:	6cb8                	ld	a4,88(s1)
    8000254c:	6f1c                	ld	a5,24(a4)
    8000254e:	0791                	addi	a5,a5,4
    80002550:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sie" : "=r" (x) );
    80002552:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    80002556:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    8000255a:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000255e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002562:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002566:	10079073          	csrw	sstatus,a5
    syscall();
    8000256a:	00000097          	auipc	ra,0x0
    8000256e:	2e0080e7          	jalr	736(ra) # 8000284a <syscall>
  if(p->killed)
    80002572:	589c                	lw	a5,48(s1)
    80002574:	ebc1                	bnez	a5,80002604 <usertrap+0xfc>
  usertrapret();
    80002576:	00000097          	auipc	ra,0x0
    8000257a:	e1c080e7          	jalr	-484(ra) # 80002392 <usertrapret>
}
    8000257e:	60e2                	ld	ra,24(sp)
    80002580:	6442                	ld	s0,16(sp)
    80002582:	64a2                	ld	s1,8(sp)
    80002584:	6902                	ld	s2,0(sp)
    80002586:	6105                	addi	sp,sp,32
    80002588:	8082                	ret
    panic("usertrap: not from user mode");
    8000258a:	00005517          	auipc	a0,0x5
    8000258e:	e0e50513          	addi	a0,a0,-498 # 80007398 <userret+0x308>
    80002592:	ffffe097          	auipc	ra,0xffffe
    80002596:	fb6080e7          	jalr	-74(ra) # 80000548 <panic>
      exit(-1);
    8000259a:	557d                	li	a0,-1
    8000259c:	00000097          	auipc	ra,0x0
    800025a0:	874080e7          	jalr	-1932(ra) # 80001e10 <exit>
    800025a4:	b75d                	j	8000254a <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800025a6:	00000097          	auipc	ra,0x0
    800025aa:	ed0080e7          	jalr	-304(ra) # 80002476 <devintr>
    800025ae:	892a                	mv	s2,a0
    800025b0:	c501                	beqz	a0,800025b8 <usertrap+0xb0>
  if(p->killed)
    800025b2:	589c                	lw	a5,48(s1)
    800025b4:	c3a1                	beqz	a5,800025f4 <usertrap+0xec>
    800025b6:	a815                	j	800025ea <usertrap+0xe2>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800025b8:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800025bc:	5c90                	lw	a2,56(s1)
    800025be:	00005517          	auipc	a0,0x5
    800025c2:	dfa50513          	addi	a0,a0,-518 # 800073b8 <userret+0x328>
    800025c6:	ffffe097          	auipc	ra,0xffffe
    800025ca:	fcc080e7          	jalr	-52(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800025ce:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800025d2:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800025d6:	00005517          	auipc	a0,0x5
    800025da:	e1250513          	addi	a0,a0,-494 # 800073e8 <userret+0x358>
    800025de:	ffffe097          	auipc	ra,0xffffe
    800025e2:	fb4080e7          	jalr	-76(ra) # 80000592 <printf>
    p->killed = 1;
    800025e6:	4785                	li	a5,1
    800025e8:	d89c                	sw	a5,48(s1)
    exit(-1);
    800025ea:	557d                	li	a0,-1
    800025ec:	00000097          	auipc	ra,0x0
    800025f0:	824080e7          	jalr	-2012(ra) # 80001e10 <exit>
  if(which_dev == 2)
    800025f4:	4789                	li	a5,2
    800025f6:	f8f910e3          	bne	s2,a5,80002576 <usertrap+0x6e>
    yield();
    800025fa:	00000097          	auipc	ra,0x0
    800025fe:	8fc080e7          	jalr	-1796(ra) # 80001ef6 <yield>
    80002602:	bf95                	j	80002576 <usertrap+0x6e>
  int which_dev = 0;
    80002604:	4901                	li	s2,0
    80002606:	b7d5                	j	800025ea <usertrap+0xe2>

0000000080002608 <kerneltrap>:
{
    80002608:	7179                	addi	sp,sp,-48
    8000260a:	f406                	sd	ra,40(sp)
    8000260c:	f022                	sd	s0,32(sp)
    8000260e:	ec26                	sd	s1,24(sp)
    80002610:	e84a                	sd	s2,16(sp)
    80002612:	e44e                	sd	s3,8(sp)
    80002614:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002616:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000261a:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000261e:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002622:	1004f793          	andi	a5,s1,256
    80002626:	cb85                	beqz	a5,80002656 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002628:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000262c:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000262e:	ef85                	bnez	a5,80002666 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002630:	00000097          	auipc	ra,0x0
    80002634:	e46080e7          	jalr	-442(ra) # 80002476 <devintr>
    80002638:	cd1d                	beqz	a0,80002676 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000263a:	4789                	li	a5,2
    8000263c:	06f50a63          	beq	a0,a5,800026b0 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002640:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002644:	10049073          	csrw	sstatus,s1
}
    80002648:	70a2                	ld	ra,40(sp)
    8000264a:	7402                	ld	s0,32(sp)
    8000264c:	64e2                	ld	s1,24(sp)
    8000264e:	6942                	ld	s2,16(sp)
    80002650:	69a2                	ld	s3,8(sp)
    80002652:	6145                	addi	sp,sp,48
    80002654:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002656:	00005517          	auipc	a0,0x5
    8000265a:	db250513          	addi	a0,a0,-590 # 80007408 <userret+0x378>
    8000265e:	ffffe097          	auipc	ra,0xffffe
    80002662:	eea080e7          	jalr	-278(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002666:	00005517          	auipc	a0,0x5
    8000266a:	dca50513          	addi	a0,a0,-566 # 80007430 <userret+0x3a0>
    8000266e:	ffffe097          	auipc	ra,0xffffe
    80002672:	eda080e7          	jalr	-294(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002676:	85ce                	mv	a1,s3
    80002678:	00005517          	auipc	a0,0x5
    8000267c:	dd850513          	addi	a0,a0,-552 # 80007450 <userret+0x3c0>
    80002680:	ffffe097          	auipc	ra,0xffffe
    80002684:	f12080e7          	jalr	-238(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002688:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000268c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002690:	00005517          	auipc	a0,0x5
    80002694:	dd050513          	addi	a0,a0,-560 # 80007460 <userret+0x3d0>
    80002698:	ffffe097          	auipc	ra,0xffffe
    8000269c:	efa080e7          	jalr	-262(ra) # 80000592 <printf>
    panic("kerneltrap");
    800026a0:	00005517          	auipc	a0,0x5
    800026a4:	dd850513          	addi	a0,a0,-552 # 80007478 <userret+0x3e8>
    800026a8:	ffffe097          	auipc	ra,0xffffe
    800026ac:	ea0080e7          	jalr	-352(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800026b0:	fffff097          	auipc	ra,0xfffff
    800026b4:	06c080e7          	jalr	108(ra) # 8000171c <myproc>
    800026b8:	d541                	beqz	a0,80002640 <kerneltrap+0x38>
    800026ba:	fffff097          	auipc	ra,0xfffff
    800026be:	062080e7          	jalr	98(ra) # 8000171c <myproc>
    800026c2:	4d18                	lw	a4,24(a0)
    800026c4:	478d                	li	a5,3
    800026c6:	f6f71de3          	bne	a4,a5,80002640 <kerneltrap+0x38>
    yield();
    800026ca:	00000097          	auipc	ra,0x0
    800026ce:	82c080e7          	jalr	-2004(ra) # 80001ef6 <yield>
    800026d2:	b7bd                	j	80002640 <kerneltrap+0x38>

00000000800026d4 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800026d4:	1101                	addi	sp,sp,-32
    800026d6:	ec06                	sd	ra,24(sp)
    800026d8:	e822                	sd	s0,16(sp)
    800026da:	e426                	sd	s1,8(sp)
    800026dc:	1000                	addi	s0,sp,32
    800026de:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800026e0:	fffff097          	auipc	ra,0xfffff
    800026e4:	03c080e7          	jalr	60(ra) # 8000171c <myproc>
  switch (n) {
    800026e8:	4795                	li	a5,5
    800026ea:	0497e163          	bltu	a5,s1,8000272c <argraw+0x58>
    800026ee:	048a                	slli	s1,s1,0x2
    800026f0:	00005717          	auipc	a4,0x5
    800026f4:	32870713          	addi	a4,a4,808 # 80007a18 <states.0+0x28>
    800026f8:	94ba                	add	s1,s1,a4
    800026fa:	409c                	lw	a5,0(s1)
    800026fc:	97ba                	add	a5,a5,a4
    800026fe:	8782                	jr	a5
  case 0:
    return p->tf->a0;
    80002700:	6d3c                	ld	a5,88(a0)
    80002702:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->tf->a5;
  }
  panic("argraw");
  return -1;
}
    80002704:	60e2                	ld	ra,24(sp)
    80002706:	6442                	ld	s0,16(sp)
    80002708:	64a2                	ld	s1,8(sp)
    8000270a:	6105                	addi	sp,sp,32
    8000270c:	8082                	ret
    return p->tf->a1;
    8000270e:	6d3c                	ld	a5,88(a0)
    80002710:	7fa8                	ld	a0,120(a5)
    80002712:	bfcd                	j	80002704 <argraw+0x30>
    return p->tf->a2;
    80002714:	6d3c                	ld	a5,88(a0)
    80002716:	63c8                	ld	a0,128(a5)
    80002718:	b7f5                	j	80002704 <argraw+0x30>
    return p->tf->a3;
    8000271a:	6d3c                	ld	a5,88(a0)
    8000271c:	67c8                	ld	a0,136(a5)
    8000271e:	b7dd                	j	80002704 <argraw+0x30>
    return p->tf->a4;
    80002720:	6d3c                	ld	a5,88(a0)
    80002722:	6bc8                	ld	a0,144(a5)
    80002724:	b7c5                	j	80002704 <argraw+0x30>
    return p->tf->a5;
    80002726:	6d3c                	ld	a5,88(a0)
    80002728:	6fc8                	ld	a0,152(a5)
    8000272a:	bfe9                	j	80002704 <argraw+0x30>
  panic("argraw");
    8000272c:	00005517          	auipc	a0,0x5
    80002730:	d5c50513          	addi	a0,a0,-676 # 80007488 <userret+0x3f8>
    80002734:	ffffe097          	auipc	ra,0xffffe
    80002738:	e14080e7          	jalr	-492(ra) # 80000548 <panic>

000000008000273c <fetchaddr>:
{
    8000273c:	1101                	addi	sp,sp,-32
    8000273e:	ec06                	sd	ra,24(sp)
    80002740:	e822                	sd	s0,16(sp)
    80002742:	e426                	sd	s1,8(sp)
    80002744:	e04a                	sd	s2,0(sp)
    80002746:	1000                	addi	s0,sp,32
    80002748:	84aa                	mv	s1,a0
    8000274a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000274c:	fffff097          	auipc	ra,0xfffff
    80002750:	fd0080e7          	jalr	-48(ra) # 8000171c <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002754:	653c                	ld	a5,72(a0)
    80002756:	02f4f863          	bgeu	s1,a5,80002786 <fetchaddr+0x4a>
    8000275a:	00848713          	addi	a4,s1,8
    8000275e:	02e7e663          	bltu	a5,a4,8000278a <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002762:	46a1                	li	a3,8
    80002764:	8626                	mv	a2,s1
    80002766:	85ca                	mv	a1,s2
    80002768:	6928                	ld	a0,80(a0)
    8000276a:	fffff097          	auipc	ra,0xfffff
    8000276e:	d68080e7          	jalr	-664(ra) # 800014d2 <copyin>
    80002772:	00a03533          	snez	a0,a0
    80002776:	40a00533          	neg	a0,a0
}
    8000277a:	60e2                	ld	ra,24(sp)
    8000277c:	6442                	ld	s0,16(sp)
    8000277e:	64a2                	ld	s1,8(sp)
    80002780:	6902                	ld	s2,0(sp)
    80002782:	6105                	addi	sp,sp,32
    80002784:	8082                	ret
    return -1;
    80002786:	557d                	li	a0,-1
    80002788:	bfcd                	j	8000277a <fetchaddr+0x3e>
    8000278a:	557d                	li	a0,-1
    8000278c:	b7fd                	j	8000277a <fetchaddr+0x3e>

000000008000278e <fetchstr>:
{
    8000278e:	7179                	addi	sp,sp,-48
    80002790:	f406                	sd	ra,40(sp)
    80002792:	f022                	sd	s0,32(sp)
    80002794:	ec26                	sd	s1,24(sp)
    80002796:	e84a                	sd	s2,16(sp)
    80002798:	e44e                	sd	s3,8(sp)
    8000279a:	1800                	addi	s0,sp,48
    8000279c:	892a                	mv	s2,a0
    8000279e:	84ae                	mv	s1,a1
    800027a0:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800027a2:	fffff097          	auipc	ra,0xfffff
    800027a6:	f7a080e7          	jalr	-134(ra) # 8000171c <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    800027aa:	86ce                	mv	a3,s3
    800027ac:	864a                	mv	a2,s2
    800027ae:	85a6                	mv	a1,s1
    800027b0:	6928                	ld	a0,80(a0)
    800027b2:	fffff097          	auipc	ra,0xfffff
    800027b6:	db4080e7          	jalr	-588(ra) # 80001566 <copyinstr>
  if(err < 0)
    800027ba:	00054763          	bltz	a0,800027c8 <fetchstr+0x3a>
  return strlen(buf);
    800027be:	8526                	mv	a0,s1
    800027c0:	ffffe097          	auipc	ra,0xffffe
    800027c4:	444080e7          	jalr	1092(ra) # 80000c04 <strlen>
}
    800027c8:	70a2                	ld	ra,40(sp)
    800027ca:	7402                	ld	s0,32(sp)
    800027cc:	64e2                	ld	s1,24(sp)
    800027ce:	6942                	ld	s2,16(sp)
    800027d0:	69a2                	ld	s3,8(sp)
    800027d2:	6145                	addi	sp,sp,48
    800027d4:	8082                	ret

00000000800027d6 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    800027d6:	1101                	addi	sp,sp,-32
    800027d8:	ec06                	sd	ra,24(sp)
    800027da:	e822                	sd	s0,16(sp)
    800027dc:	e426                	sd	s1,8(sp)
    800027de:	1000                	addi	s0,sp,32
    800027e0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800027e2:	00000097          	auipc	ra,0x0
    800027e6:	ef2080e7          	jalr	-270(ra) # 800026d4 <argraw>
    800027ea:	c088                	sw	a0,0(s1)
  return 0;
}
    800027ec:	4501                	li	a0,0
    800027ee:	60e2                	ld	ra,24(sp)
    800027f0:	6442                	ld	s0,16(sp)
    800027f2:	64a2                	ld	s1,8(sp)
    800027f4:	6105                	addi	sp,sp,32
    800027f6:	8082                	ret

00000000800027f8 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800027f8:	1101                	addi	sp,sp,-32
    800027fa:	ec06                	sd	ra,24(sp)
    800027fc:	e822                	sd	s0,16(sp)
    800027fe:	e426                	sd	s1,8(sp)
    80002800:	1000                	addi	s0,sp,32
    80002802:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002804:	00000097          	auipc	ra,0x0
    80002808:	ed0080e7          	jalr	-304(ra) # 800026d4 <argraw>
    8000280c:	e088                	sd	a0,0(s1)
  return 0;
}
    8000280e:	4501                	li	a0,0
    80002810:	60e2                	ld	ra,24(sp)
    80002812:	6442                	ld	s0,16(sp)
    80002814:	64a2                	ld	s1,8(sp)
    80002816:	6105                	addi	sp,sp,32
    80002818:	8082                	ret

000000008000281a <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    8000281a:	1101                	addi	sp,sp,-32
    8000281c:	ec06                	sd	ra,24(sp)
    8000281e:	e822                	sd	s0,16(sp)
    80002820:	e426                	sd	s1,8(sp)
    80002822:	e04a                	sd	s2,0(sp)
    80002824:	1000                	addi	s0,sp,32
    80002826:	84ae                	mv	s1,a1
    80002828:	8932                	mv	s2,a2
  *ip = argraw(n);
    8000282a:	00000097          	auipc	ra,0x0
    8000282e:	eaa080e7          	jalr	-342(ra) # 800026d4 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002832:	864a                	mv	a2,s2
    80002834:	85a6                	mv	a1,s1
    80002836:	00000097          	auipc	ra,0x0
    8000283a:	f58080e7          	jalr	-168(ra) # 8000278e <fetchstr>
}
    8000283e:	60e2                	ld	ra,24(sp)
    80002840:	6442                	ld	s0,16(sp)
    80002842:	64a2                	ld	s1,8(sp)
    80002844:	6902                	ld	s2,0(sp)
    80002846:	6105                	addi	sp,sp,32
    80002848:	8082                	ret

000000008000284a <syscall>:
[SYS_crash]   sys_crash,
};

void
syscall(void)
{
    8000284a:	1101                	addi	sp,sp,-32
    8000284c:	ec06                	sd	ra,24(sp)
    8000284e:	e822                	sd	s0,16(sp)
    80002850:	e426                	sd	s1,8(sp)
    80002852:	e04a                	sd	s2,0(sp)
    80002854:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002856:	fffff097          	auipc	ra,0xfffff
    8000285a:	ec6080e7          	jalr	-314(ra) # 8000171c <myproc>
    8000285e:	84aa                	mv	s1,a0

  num = p->tf->a7;
    80002860:	05853903          	ld	s2,88(a0)
    80002864:	0a893783          	ld	a5,168(s2)
    80002868:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000286c:	37fd                	addiw	a5,a5,-1
    8000286e:	4759                	li	a4,22
    80002870:	00f76f63          	bltu	a4,a5,8000288e <syscall+0x44>
    80002874:	00369713          	slli	a4,a3,0x3
    80002878:	00005797          	auipc	a5,0x5
    8000287c:	1b878793          	addi	a5,a5,440 # 80007a30 <syscalls>
    80002880:	97ba                	add	a5,a5,a4
    80002882:	639c                	ld	a5,0(a5)
    80002884:	c789                	beqz	a5,8000288e <syscall+0x44>
    p->tf->a0 = syscalls[num]();
    80002886:	9782                	jalr	a5
    80002888:	06a93823          	sd	a0,112(s2)
    8000288c:	a839                	j	800028aa <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000288e:	15848613          	addi	a2,s1,344
    80002892:	5c8c                	lw	a1,56(s1)
    80002894:	00005517          	auipc	a0,0x5
    80002898:	bfc50513          	addi	a0,a0,-1028 # 80007490 <userret+0x400>
    8000289c:	ffffe097          	auipc	ra,0xffffe
    800028a0:	cf6080e7          	jalr	-778(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->tf->a0 = -1;
    800028a4:	6cbc                	ld	a5,88(s1)
    800028a6:	577d                	li	a4,-1
    800028a8:	fbb8                	sd	a4,112(a5)
  }
}
    800028aa:	60e2                	ld	ra,24(sp)
    800028ac:	6442                	ld	s0,16(sp)
    800028ae:	64a2                	ld	s1,8(sp)
    800028b0:	6902                	ld	s2,0(sp)
    800028b2:	6105                	addi	sp,sp,32
    800028b4:	8082                	ret

00000000800028b6 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800028b6:	1101                	addi	sp,sp,-32
    800028b8:	ec06                	sd	ra,24(sp)
    800028ba:	e822                	sd	s0,16(sp)
    800028bc:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800028be:	fec40593          	addi	a1,s0,-20
    800028c2:	4501                	li	a0,0
    800028c4:	00000097          	auipc	ra,0x0
    800028c8:	f12080e7          	jalr	-238(ra) # 800027d6 <argint>
    return -1;
    800028cc:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800028ce:	00054963          	bltz	a0,800028e0 <sys_exit+0x2a>
  exit(n);
    800028d2:	fec42503          	lw	a0,-20(s0)
    800028d6:	fffff097          	auipc	ra,0xfffff
    800028da:	53a080e7          	jalr	1338(ra) # 80001e10 <exit>
  return 0;  // not reached
    800028de:	4781                	li	a5,0
}
    800028e0:	853e                	mv	a0,a5
    800028e2:	60e2                	ld	ra,24(sp)
    800028e4:	6442                	ld	s0,16(sp)
    800028e6:	6105                	addi	sp,sp,32
    800028e8:	8082                	ret

00000000800028ea <sys_getpid>:

uint64
sys_getpid(void)
{
    800028ea:	1141                	addi	sp,sp,-16
    800028ec:	e406                	sd	ra,8(sp)
    800028ee:	e022                	sd	s0,0(sp)
    800028f0:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800028f2:	fffff097          	auipc	ra,0xfffff
    800028f6:	e2a080e7          	jalr	-470(ra) # 8000171c <myproc>
}
    800028fa:	5d08                	lw	a0,56(a0)
    800028fc:	60a2                	ld	ra,8(sp)
    800028fe:	6402                	ld	s0,0(sp)
    80002900:	0141                	addi	sp,sp,16
    80002902:	8082                	ret

0000000080002904 <sys_fork>:

uint64
sys_fork(void)
{
    80002904:	1141                	addi	sp,sp,-16
    80002906:	e406                	sd	ra,8(sp)
    80002908:	e022                	sd	s0,0(sp)
    8000290a:	0800                	addi	s0,sp,16
  return fork();
    8000290c:	fffff097          	auipc	ra,0xfffff
    80002910:	17e080e7          	jalr	382(ra) # 80001a8a <fork>
}
    80002914:	60a2                	ld	ra,8(sp)
    80002916:	6402                	ld	s0,0(sp)
    80002918:	0141                	addi	sp,sp,16
    8000291a:	8082                	ret

000000008000291c <sys_wait>:

uint64
sys_wait(void)
{
    8000291c:	1101                	addi	sp,sp,-32
    8000291e:	ec06                	sd	ra,24(sp)
    80002920:	e822                	sd	s0,16(sp)
    80002922:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002924:	fe840593          	addi	a1,s0,-24
    80002928:	4501                	li	a0,0
    8000292a:	00000097          	auipc	ra,0x0
    8000292e:	ece080e7          	jalr	-306(ra) # 800027f8 <argaddr>
    80002932:	87aa                	mv	a5,a0
    return -1;
    80002934:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002936:	0007c863          	bltz	a5,80002946 <sys_wait+0x2a>
  return wait(p);
    8000293a:	fe843503          	ld	a0,-24(s0)
    8000293e:	fffff097          	auipc	ra,0xfffff
    80002942:	672080e7          	jalr	1650(ra) # 80001fb0 <wait>
}
    80002946:	60e2                	ld	ra,24(sp)
    80002948:	6442                	ld	s0,16(sp)
    8000294a:	6105                	addi	sp,sp,32
    8000294c:	8082                	ret

000000008000294e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000294e:	7179                	addi	sp,sp,-48
    80002950:	f406                	sd	ra,40(sp)
    80002952:	f022                	sd	s0,32(sp)
    80002954:	ec26                	sd	s1,24(sp)
    80002956:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002958:	fdc40593          	addi	a1,s0,-36
    8000295c:	4501                	li	a0,0
    8000295e:	00000097          	auipc	ra,0x0
    80002962:	e78080e7          	jalr	-392(ra) # 800027d6 <argint>
    return -1;
    80002966:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002968:	00054f63          	bltz	a0,80002986 <sys_sbrk+0x38>
  addr = myproc()->sz;
    8000296c:	fffff097          	auipc	ra,0xfffff
    80002970:	db0080e7          	jalr	-592(ra) # 8000171c <myproc>
    80002974:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002976:	fdc42503          	lw	a0,-36(s0)
    8000297a:	fffff097          	auipc	ra,0xfffff
    8000297e:	098080e7          	jalr	152(ra) # 80001a12 <growproc>
    80002982:	00054863          	bltz	a0,80002992 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002986:	8526                	mv	a0,s1
    80002988:	70a2                	ld	ra,40(sp)
    8000298a:	7402                	ld	s0,32(sp)
    8000298c:	64e2                	ld	s1,24(sp)
    8000298e:	6145                	addi	sp,sp,48
    80002990:	8082                	ret
    return -1;
    80002992:	54fd                	li	s1,-1
    80002994:	bfcd                	j	80002986 <sys_sbrk+0x38>

0000000080002996 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002996:	7139                	addi	sp,sp,-64
    80002998:	fc06                	sd	ra,56(sp)
    8000299a:	f822                	sd	s0,48(sp)
    8000299c:	f426                	sd	s1,40(sp)
    8000299e:	f04a                	sd	s2,32(sp)
    800029a0:	ec4e                	sd	s3,24(sp)
    800029a2:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800029a4:	fcc40593          	addi	a1,s0,-52
    800029a8:	4501                	li	a0,0
    800029aa:	00000097          	auipc	ra,0x0
    800029ae:	e2c080e7          	jalr	-468(ra) # 800027d6 <argint>
    return -1;
    800029b2:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800029b4:	06054563          	bltz	a0,80002a1e <sys_sleep+0x88>
  acquire(&tickslock);
    800029b8:	00015517          	auipc	a0,0x15
    800029bc:	d2850513          	addi	a0,a0,-728 # 800176e0 <tickslock>
    800029c0:	ffffe097          	auipc	ra,0xffffe
    800029c4:	ffc080e7          	jalr	-4(ra) # 800009bc <acquire>
  ticks0 = ticks;
    800029c8:	00025917          	auipc	s2,0x25
    800029cc:	67892903          	lw	s2,1656(s2) # 80028040 <ticks>
  while(ticks - ticks0 < n){
    800029d0:	fcc42783          	lw	a5,-52(s0)
    800029d4:	cf85                	beqz	a5,80002a0c <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800029d6:	00015997          	auipc	s3,0x15
    800029da:	d0a98993          	addi	s3,s3,-758 # 800176e0 <tickslock>
    800029de:	00025497          	auipc	s1,0x25
    800029e2:	66248493          	addi	s1,s1,1634 # 80028040 <ticks>
    if(myproc()->killed){
    800029e6:	fffff097          	auipc	ra,0xfffff
    800029ea:	d36080e7          	jalr	-714(ra) # 8000171c <myproc>
    800029ee:	591c                	lw	a5,48(a0)
    800029f0:	ef9d                	bnez	a5,80002a2e <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800029f2:	85ce                	mv	a1,s3
    800029f4:	8526                	mv	a0,s1
    800029f6:	fffff097          	auipc	ra,0xfffff
    800029fa:	53c080e7          	jalr	1340(ra) # 80001f32 <sleep>
  while(ticks - ticks0 < n){
    800029fe:	409c                	lw	a5,0(s1)
    80002a00:	412787bb          	subw	a5,a5,s2
    80002a04:	fcc42703          	lw	a4,-52(s0)
    80002a08:	fce7efe3          	bltu	a5,a4,800029e6 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002a0c:	00015517          	auipc	a0,0x15
    80002a10:	cd450513          	addi	a0,a0,-812 # 800176e0 <tickslock>
    80002a14:	ffffe097          	auipc	ra,0xffffe
    80002a18:	010080e7          	jalr	16(ra) # 80000a24 <release>
  return 0;
    80002a1c:	4781                	li	a5,0
}
    80002a1e:	853e                	mv	a0,a5
    80002a20:	70e2                	ld	ra,56(sp)
    80002a22:	7442                	ld	s0,48(sp)
    80002a24:	74a2                	ld	s1,40(sp)
    80002a26:	7902                	ld	s2,32(sp)
    80002a28:	69e2                	ld	s3,24(sp)
    80002a2a:	6121                	addi	sp,sp,64
    80002a2c:	8082                	ret
      release(&tickslock);
    80002a2e:	00015517          	auipc	a0,0x15
    80002a32:	cb250513          	addi	a0,a0,-846 # 800176e0 <tickslock>
    80002a36:	ffffe097          	auipc	ra,0xffffe
    80002a3a:	fee080e7          	jalr	-18(ra) # 80000a24 <release>
      return -1;
    80002a3e:	57fd                	li	a5,-1
    80002a40:	bff9                	j	80002a1e <sys_sleep+0x88>

0000000080002a42 <sys_kill>:

uint64
sys_kill(void)
{
    80002a42:	1101                	addi	sp,sp,-32
    80002a44:	ec06                	sd	ra,24(sp)
    80002a46:	e822                	sd	s0,16(sp)
    80002a48:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002a4a:	fec40593          	addi	a1,s0,-20
    80002a4e:	4501                	li	a0,0
    80002a50:	00000097          	auipc	ra,0x0
    80002a54:	d86080e7          	jalr	-634(ra) # 800027d6 <argint>
    80002a58:	87aa                	mv	a5,a0
    return -1;
    80002a5a:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002a5c:	0007c863          	bltz	a5,80002a6c <sys_kill+0x2a>
  return kill(pid);
    80002a60:	fec42503          	lw	a0,-20(s0)
    80002a64:	fffff097          	auipc	ra,0xfffff
    80002a68:	6b8080e7          	jalr	1720(ra) # 8000211c <kill>
}
    80002a6c:	60e2                	ld	ra,24(sp)
    80002a6e:	6442                	ld	s0,16(sp)
    80002a70:	6105                	addi	sp,sp,32
    80002a72:	8082                	ret

0000000080002a74 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002a74:	1101                	addi	sp,sp,-32
    80002a76:	ec06                	sd	ra,24(sp)
    80002a78:	e822                	sd	s0,16(sp)
    80002a7a:	e426                	sd	s1,8(sp)
    80002a7c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002a7e:	00015517          	auipc	a0,0x15
    80002a82:	c6250513          	addi	a0,a0,-926 # 800176e0 <tickslock>
    80002a86:	ffffe097          	auipc	ra,0xffffe
    80002a8a:	f36080e7          	jalr	-202(ra) # 800009bc <acquire>
  xticks = ticks;
    80002a8e:	00025497          	auipc	s1,0x25
    80002a92:	5b24a483          	lw	s1,1458(s1) # 80028040 <ticks>
  release(&tickslock);
    80002a96:	00015517          	auipc	a0,0x15
    80002a9a:	c4a50513          	addi	a0,a0,-950 # 800176e0 <tickslock>
    80002a9e:	ffffe097          	auipc	ra,0xffffe
    80002aa2:	f86080e7          	jalr	-122(ra) # 80000a24 <release>
  return xticks;
}
    80002aa6:	02049513          	slli	a0,s1,0x20
    80002aaa:	9101                	srli	a0,a0,0x20
    80002aac:	60e2                	ld	ra,24(sp)
    80002aae:	6442                	ld	s0,16(sp)
    80002ab0:	64a2                	ld	s1,8(sp)
    80002ab2:	6105                	addi	sp,sp,32
    80002ab4:	8082                	ret

0000000080002ab6 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002ab6:	7179                	addi	sp,sp,-48
    80002ab8:	f406                	sd	ra,40(sp)
    80002aba:	f022                	sd	s0,32(sp)
    80002abc:	ec26                	sd	s1,24(sp)
    80002abe:	e84a                	sd	s2,16(sp)
    80002ac0:	e44e                	sd	s3,8(sp)
    80002ac2:	e052                	sd	s4,0(sp)
    80002ac4:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ac6:	00005597          	auipc	a1,0x5
    80002aca:	9ea58593          	addi	a1,a1,-1558 # 800074b0 <userret+0x420>
    80002ace:	00015517          	auipc	a0,0x15
    80002ad2:	c2a50513          	addi	a0,a0,-982 # 800176f8 <bcache>
    80002ad6:	ffffe097          	auipc	ra,0xffffe
    80002ada:	dd8080e7          	jalr	-552(ra) # 800008ae <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002ade:	0001d797          	auipc	a5,0x1d
    80002ae2:	c1a78793          	addi	a5,a5,-998 # 8001f6f8 <bcache+0x8000>
    80002ae6:	0001d717          	auipc	a4,0x1d
    80002aea:	f6a70713          	addi	a4,a4,-150 # 8001fa50 <bcache+0x8358>
    80002aee:	3ae7b023          	sd	a4,928(a5)
  bcache.head.next = &bcache.head;
    80002af2:	3ae7b423          	sd	a4,936(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002af6:	00015497          	auipc	s1,0x15
    80002afa:	c1a48493          	addi	s1,s1,-998 # 80017710 <bcache+0x18>
    b->next = bcache.head.next;
    80002afe:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002b00:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002b02:	00005a17          	auipc	s4,0x5
    80002b06:	9b6a0a13          	addi	s4,s4,-1610 # 800074b8 <userret+0x428>
    b->next = bcache.head.next;
    80002b0a:	3a893783          	ld	a5,936(s2)
    80002b0e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002b10:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002b14:	85d2                	mv	a1,s4
    80002b16:	01048513          	addi	a0,s1,16
    80002b1a:	00001097          	auipc	ra,0x1
    80002b1e:	6f6080e7          	jalr	1782(ra) # 80004210 <initsleeplock>
    bcache.head.next->prev = b;
    80002b22:	3a893783          	ld	a5,936(s2)
    80002b26:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002b28:	3a993423          	sd	s1,936(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002b2c:	46048493          	addi	s1,s1,1120
    80002b30:	fd349de3          	bne	s1,s3,80002b0a <binit+0x54>
  }
}
    80002b34:	70a2                	ld	ra,40(sp)
    80002b36:	7402                	ld	s0,32(sp)
    80002b38:	64e2                	ld	s1,24(sp)
    80002b3a:	6942                	ld	s2,16(sp)
    80002b3c:	69a2                	ld	s3,8(sp)
    80002b3e:	6a02                	ld	s4,0(sp)
    80002b40:	6145                	addi	sp,sp,48
    80002b42:	8082                	ret

0000000080002b44 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002b44:	7179                	addi	sp,sp,-48
    80002b46:	f406                	sd	ra,40(sp)
    80002b48:	f022                	sd	s0,32(sp)
    80002b4a:	ec26                	sd	s1,24(sp)
    80002b4c:	e84a                	sd	s2,16(sp)
    80002b4e:	e44e                	sd	s3,8(sp)
    80002b50:	1800                	addi	s0,sp,48
    80002b52:	892a                	mv	s2,a0
    80002b54:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002b56:	00015517          	auipc	a0,0x15
    80002b5a:	ba250513          	addi	a0,a0,-1118 # 800176f8 <bcache>
    80002b5e:	ffffe097          	auipc	ra,0xffffe
    80002b62:	e5e080e7          	jalr	-418(ra) # 800009bc <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002b66:	0001d497          	auipc	s1,0x1d
    80002b6a:	f3a4b483          	ld	s1,-198(s1) # 8001faa0 <bcache+0x83a8>
    80002b6e:	0001d797          	auipc	a5,0x1d
    80002b72:	ee278793          	addi	a5,a5,-286 # 8001fa50 <bcache+0x8358>
    80002b76:	02f48f63          	beq	s1,a5,80002bb4 <bread+0x70>
    80002b7a:	873e                	mv	a4,a5
    80002b7c:	a021                	j	80002b84 <bread+0x40>
    80002b7e:	68a4                	ld	s1,80(s1)
    80002b80:	02e48a63          	beq	s1,a4,80002bb4 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002b84:	449c                	lw	a5,8(s1)
    80002b86:	ff279ce3          	bne	a5,s2,80002b7e <bread+0x3a>
    80002b8a:	44dc                	lw	a5,12(s1)
    80002b8c:	ff3799e3          	bne	a5,s3,80002b7e <bread+0x3a>
      b->refcnt++;
    80002b90:	40bc                	lw	a5,64(s1)
    80002b92:	2785                	addiw	a5,a5,1
    80002b94:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002b96:	00015517          	auipc	a0,0x15
    80002b9a:	b6250513          	addi	a0,a0,-1182 # 800176f8 <bcache>
    80002b9e:	ffffe097          	auipc	ra,0xffffe
    80002ba2:	e86080e7          	jalr	-378(ra) # 80000a24 <release>
      acquiresleep(&b->lock);
    80002ba6:	01048513          	addi	a0,s1,16
    80002baa:	00001097          	auipc	ra,0x1
    80002bae:	6a0080e7          	jalr	1696(ra) # 8000424a <acquiresleep>
      return b;
    80002bb2:	a8b9                	j	80002c10 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002bb4:	0001d497          	auipc	s1,0x1d
    80002bb8:	ee44b483          	ld	s1,-284(s1) # 8001fa98 <bcache+0x83a0>
    80002bbc:	0001d797          	auipc	a5,0x1d
    80002bc0:	e9478793          	addi	a5,a5,-364 # 8001fa50 <bcache+0x8358>
    80002bc4:	00f48863          	beq	s1,a5,80002bd4 <bread+0x90>
    80002bc8:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002bca:	40bc                	lw	a5,64(s1)
    80002bcc:	cf81                	beqz	a5,80002be4 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002bce:	64a4                	ld	s1,72(s1)
    80002bd0:	fee49de3          	bne	s1,a4,80002bca <bread+0x86>
  panic("bget: no buffers");
    80002bd4:	00005517          	auipc	a0,0x5
    80002bd8:	8ec50513          	addi	a0,a0,-1812 # 800074c0 <userret+0x430>
    80002bdc:	ffffe097          	auipc	ra,0xffffe
    80002be0:	96c080e7          	jalr	-1684(ra) # 80000548 <panic>
      b->dev = dev;
    80002be4:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002be8:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002bec:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002bf0:	4785                	li	a5,1
    80002bf2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002bf4:	00015517          	auipc	a0,0x15
    80002bf8:	b0450513          	addi	a0,a0,-1276 # 800176f8 <bcache>
    80002bfc:	ffffe097          	auipc	ra,0xffffe
    80002c00:	e28080e7          	jalr	-472(ra) # 80000a24 <release>
      acquiresleep(&b->lock);
    80002c04:	01048513          	addi	a0,s1,16
    80002c08:	00001097          	auipc	ra,0x1
    80002c0c:	642080e7          	jalr	1602(ra) # 8000424a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002c10:	409c                	lw	a5,0(s1)
    80002c12:	cb89                	beqz	a5,80002c24 <bread+0xe0>
    virtio_disk_rw(b->dev, b, 0);
    b->valid = 1;
  }
  return b;
}
    80002c14:	8526                	mv	a0,s1
    80002c16:	70a2                	ld	ra,40(sp)
    80002c18:	7402                	ld	s0,32(sp)
    80002c1a:	64e2                	ld	s1,24(sp)
    80002c1c:	6942                	ld	s2,16(sp)
    80002c1e:	69a2                	ld	s3,8(sp)
    80002c20:	6145                	addi	sp,sp,48
    80002c22:	8082                	ret
    virtio_disk_rw(b->dev, b, 0);
    80002c24:	4601                	li	a2,0
    80002c26:	85a6                	mv	a1,s1
    80002c28:	4488                	lw	a0,8(s1)
    80002c2a:	00003097          	auipc	ra,0x3
    80002c2e:	2d2080e7          	jalr	722(ra) # 80005efc <virtio_disk_rw>
    b->valid = 1;
    80002c32:	4785                	li	a5,1
    80002c34:	c09c                	sw	a5,0(s1)
  return b;
    80002c36:	bff9                	j	80002c14 <bread+0xd0>

0000000080002c38 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002c38:	1101                	addi	sp,sp,-32
    80002c3a:	ec06                	sd	ra,24(sp)
    80002c3c:	e822                	sd	s0,16(sp)
    80002c3e:	e426                	sd	s1,8(sp)
    80002c40:	1000                	addi	s0,sp,32
    80002c42:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002c44:	0541                	addi	a0,a0,16
    80002c46:	00001097          	auipc	ra,0x1
    80002c4a:	69e080e7          	jalr	1694(ra) # 800042e4 <holdingsleep>
    80002c4e:	cd09                	beqz	a0,80002c68 <bwrite+0x30>
    panic("bwrite");
  virtio_disk_rw(b->dev, b, 1);
    80002c50:	4605                	li	a2,1
    80002c52:	85a6                	mv	a1,s1
    80002c54:	4488                	lw	a0,8(s1)
    80002c56:	00003097          	auipc	ra,0x3
    80002c5a:	2a6080e7          	jalr	678(ra) # 80005efc <virtio_disk_rw>
}
    80002c5e:	60e2                	ld	ra,24(sp)
    80002c60:	6442                	ld	s0,16(sp)
    80002c62:	64a2                	ld	s1,8(sp)
    80002c64:	6105                	addi	sp,sp,32
    80002c66:	8082                	ret
    panic("bwrite");
    80002c68:	00005517          	auipc	a0,0x5
    80002c6c:	87050513          	addi	a0,a0,-1936 # 800074d8 <userret+0x448>
    80002c70:	ffffe097          	auipc	ra,0xffffe
    80002c74:	8d8080e7          	jalr	-1832(ra) # 80000548 <panic>

0000000080002c78 <brelse>:

// Release a locked buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
    80002c78:	1101                	addi	sp,sp,-32
    80002c7a:	ec06                	sd	ra,24(sp)
    80002c7c:	e822                	sd	s0,16(sp)
    80002c7e:	e426                	sd	s1,8(sp)
    80002c80:	e04a                	sd	s2,0(sp)
    80002c82:	1000                	addi	s0,sp,32
    80002c84:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002c86:	01050913          	addi	s2,a0,16
    80002c8a:	854a                	mv	a0,s2
    80002c8c:	00001097          	auipc	ra,0x1
    80002c90:	658080e7          	jalr	1624(ra) # 800042e4 <holdingsleep>
    80002c94:	c92d                	beqz	a0,80002d06 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002c96:	854a                	mv	a0,s2
    80002c98:	00001097          	auipc	ra,0x1
    80002c9c:	608080e7          	jalr	1544(ra) # 800042a0 <releasesleep>

  acquire(&bcache.lock);
    80002ca0:	00015517          	auipc	a0,0x15
    80002ca4:	a5850513          	addi	a0,a0,-1448 # 800176f8 <bcache>
    80002ca8:	ffffe097          	auipc	ra,0xffffe
    80002cac:	d14080e7          	jalr	-748(ra) # 800009bc <acquire>
  b->refcnt--;
    80002cb0:	40bc                	lw	a5,64(s1)
    80002cb2:	37fd                	addiw	a5,a5,-1
    80002cb4:	0007871b          	sext.w	a4,a5
    80002cb8:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002cba:	eb05                	bnez	a4,80002cea <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002cbc:	68bc                	ld	a5,80(s1)
    80002cbe:	64b8                	ld	a4,72(s1)
    80002cc0:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002cc2:	64bc                	ld	a5,72(s1)
    80002cc4:	68b8                	ld	a4,80(s1)
    80002cc6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002cc8:	0001d797          	auipc	a5,0x1d
    80002ccc:	a3078793          	addi	a5,a5,-1488 # 8001f6f8 <bcache+0x8000>
    80002cd0:	3a87b703          	ld	a4,936(a5)
    80002cd4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002cd6:	0001d717          	auipc	a4,0x1d
    80002cda:	d7a70713          	addi	a4,a4,-646 # 8001fa50 <bcache+0x8358>
    80002cde:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002ce0:	3a87b703          	ld	a4,936(a5)
    80002ce4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002ce6:	3a97b423          	sd	s1,936(a5)
  }
  
  release(&bcache.lock);
    80002cea:	00015517          	auipc	a0,0x15
    80002cee:	a0e50513          	addi	a0,a0,-1522 # 800176f8 <bcache>
    80002cf2:	ffffe097          	auipc	ra,0xffffe
    80002cf6:	d32080e7          	jalr	-718(ra) # 80000a24 <release>
}
    80002cfa:	60e2                	ld	ra,24(sp)
    80002cfc:	6442                	ld	s0,16(sp)
    80002cfe:	64a2                	ld	s1,8(sp)
    80002d00:	6902                	ld	s2,0(sp)
    80002d02:	6105                	addi	sp,sp,32
    80002d04:	8082                	ret
    panic("brelse");
    80002d06:	00004517          	auipc	a0,0x4
    80002d0a:	7da50513          	addi	a0,a0,2010 # 800074e0 <userret+0x450>
    80002d0e:	ffffe097          	auipc	ra,0xffffe
    80002d12:	83a080e7          	jalr	-1990(ra) # 80000548 <panic>

0000000080002d16 <bpin>:

void
bpin(struct buf *b) {
    80002d16:	1101                	addi	sp,sp,-32
    80002d18:	ec06                	sd	ra,24(sp)
    80002d1a:	e822                	sd	s0,16(sp)
    80002d1c:	e426                	sd	s1,8(sp)
    80002d1e:	1000                	addi	s0,sp,32
    80002d20:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002d22:	00015517          	auipc	a0,0x15
    80002d26:	9d650513          	addi	a0,a0,-1578 # 800176f8 <bcache>
    80002d2a:	ffffe097          	auipc	ra,0xffffe
    80002d2e:	c92080e7          	jalr	-878(ra) # 800009bc <acquire>
  b->refcnt++;
    80002d32:	40bc                	lw	a5,64(s1)
    80002d34:	2785                	addiw	a5,a5,1
    80002d36:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002d38:	00015517          	auipc	a0,0x15
    80002d3c:	9c050513          	addi	a0,a0,-1600 # 800176f8 <bcache>
    80002d40:	ffffe097          	auipc	ra,0xffffe
    80002d44:	ce4080e7          	jalr	-796(ra) # 80000a24 <release>
}
    80002d48:	60e2                	ld	ra,24(sp)
    80002d4a:	6442                	ld	s0,16(sp)
    80002d4c:	64a2                	ld	s1,8(sp)
    80002d4e:	6105                	addi	sp,sp,32
    80002d50:	8082                	ret

0000000080002d52 <bunpin>:

void
bunpin(struct buf *b) {
    80002d52:	1101                	addi	sp,sp,-32
    80002d54:	ec06                	sd	ra,24(sp)
    80002d56:	e822                	sd	s0,16(sp)
    80002d58:	e426                	sd	s1,8(sp)
    80002d5a:	1000                	addi	s0,sp,32
    80002d5c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002d5e:	00015517          	auipc	a0,0x15
    80002d62:	99a50513          	addi	a0,a0,-1638 # 800176f8 <bcache>
    80002d66:	ffffe097          	auipc	ra,0xffffe
    80002d6a:	c56080e7          	jalr	-938(ra) # 800009bc <acquire>
  b->refcnt--;
    80002d6e:	40bc                	lw	a5,64(s1)
    80002d70:	37fd                	addiw	a5,a5,-1
    80002d72:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002d74:	00015517          	auipc	a0,0x15
    80002d78:	98450513          	addi	a0,a0,-1660 # 800176f8 <bcache>
    80002d7c:	ffffe097          	auipc	ra,0xffffe
    80002d80:	ca8080e7          	jalr	-856(ra) # 80000a24 <release>
}
    80002d84:	60e2                	ld	ra,24(sp)
    80002d86:	6442                	ld	s0,16(sp)
    80002d88:	64a2                	ld	s1,8(sp)
    80002d8a:	6105                	addi	sp,sp,32
    80002d8c:	8082                	ret

0000000080002d8e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80002d8e:	1101                	addi	sp,sp,-32
    80002d90:	ec06                	sd	ra,24(sp)
    80002d92:	e822                	sd	s0,16(sp)
    80002d94:	e426                	sd	s1,8(sp)
    80002d96:	e04a                	sd	s2,0(sp)
    80002d98:	1000                	addi	s0,sp,32
    80002d9a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80002d9c:	00d5d59b          	srliw	a1,a1,0xd
    80002da0:	0001d797          	auipc	a5,0x1d
    80002da4:	12c7a783          	lw	a5,300(a5) # 8001fecc <sb+0x1c>
    80002da8:	9dbd                	addw	a1,a1,a5
    80002daa:	00000097          	auipc	ra,0x0
    80002dae:	d9a080e7          	jalr	-614(ra) # 80002b44 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80002db2:	0074f713          	andi	a4,s1,7
    80002db6:	4785                	li	a5,1
    80002db8:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80002dbc:	14ce                	slli	s1,s1,0x33
    80002dbe:	90d9                	srli	s1,s1,0x36
    80002dc0:	00950733          	add	a4,a0,s1
    80002dc4:	06074703          	lbu	a4,96(a4)
    80002dc8:	00e7f6b3          	and	a3,a5,a4
    80002dcc:	c69d                	beqz	a3,80002dfa <bfree+0x6c>
    80002dce:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80002dd0:	94aa                	add	s1,s1,a0
    80002dd2:	fff7c793          	not	a5,a5
    80002dd6:	8ff9                	and	a5,a5,a4
    80002dd8:	06f48023          	sb	a5,96(s1)
  log_write(bp);
    80002ddc:	00001097          	auipc	ra,0x1
    80002de0:	1d6080e7          	jalr	470(ra) # 80003fb2 <log_write>
  brelse(bp);
    80002de4:	854a                	mv	a0,s2
    80002de6:	00000097          	auipc	ra,0x0
    80002dea:	e92080e7          	jalr	-366(ra) # 80002c78 <brelse>
}
    80002dee:	60e2                	ld	ra,24(sp)
    80002df0:	6442                	ld	s0,16(sp)
    80002df2:	64a2                	ld	s1,8(sp)
    80002df4:	6902                	ld	s2,0(sp)
    80002df6:	6105                	addi	sp,sp,32
    80002df8:	8082                	ret
    panic("freeing free block");
    80002dfa:	00004517          	auipc	a0,0x4
    80002dfe:	6ee50513          	addi	a0,a0,1774 # 800074e8 <userret+0x458>
    80002e02:	ffffd097          	auipc	ra,0xffffd
    80002e06:	746080e7          	jalr	1862(ra) # 80000548 <panic>

0000000080002e0a <balloc>:
{
    80002e0a:	711d                	addi	sp,sp,-96
    80002e0c:	ec86                	sd	ra,88(sp)
    80002e0e:	e8a2                	sd	s0,80(sp)
    80002e10:	e4a6                	sd	s1,72(sp)
    80002e12:	e0ca                	sd	s2,64(sp)
    80002e14:	fc4e                	sd	s3,56(sp)
    80002e16:	f852                	sd	s4,48(sp)
    80002e18:	f456                	sd	s5,40(sp)
    80002e1a:	f05a                	sd	s6,32(sp)
    80002e1c:	ec5e                	sd	s7,24(sp)
    80002e1e:	e862                	sd	s8,16(sp)
    80002e20:	e466                	sd	s9,8(sp)
    80002e22:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80002e24:	0001d797          	auipc	a5,0x1d
    80002e28:	0907a783          	lw	a5,144(a5) # 8001feb4 <sb+0x4>
    80002e2c:	cbd1                	beqz	a5,80002ec0 <balloc+0xb6>
    80002e2e:	8baa                	mv	s7,a0
    80002e30:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80002e32:	0001db17          	auipc	s6,0x1d
    80002e36:	07eb0b13          	addi	s6,s6,126 # 8001feb0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002e3a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80002e3c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002e3e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80002e40:	6c89                	lui	s9,0x2
    80002e42:	a831                	j	80002e5e <balloc+0x54>
    brelse(bp);
    80002e44:	854a                	mv	a0,s2
    80002e46:	00000097          	auipc	ra,0x0
    80002e4a:	e32080e7          	jalr	-462(ra) # 80002c78 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80002e4e:	015c87bb          	addw	a5,s9,s5
    80002e52:	00078a9b          	sext.w	s5,a5
    80002e56:	004b2703          	lw	a4,4(s6)
    80002e5a:	06eaf363          	bgeu	s5,a4,80002ec0 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80002e5e:	41fad79b          	sraiw	a5,s5,0x1f
    80002e62:	0137d79b          	srliw	a5,a5,0x13
    80002e66:	015787bb          	addw	a5,a5,s5
    80002e6a:	40d7d79b          	sraiw	a5,a5,0xd
    80002e6e:	01cb2583          	lw	a1,28(s6)
    80002e72:	9dbd                	addw	a1,a1,a5
    80002e74:	855e                	mv	a0,s7
    80002e76:	00000097          	auipc	ra,0x0
    80002e7a:	cce080e7          	jalr	-818(ra) # 80002b44 <bread>
    80002e7e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002e80:	004b2503          	lw	a0,4(s6)
    80002e84:	000a849b          	sext.w	s1,s5
    80002e88:	8662                	mv	a2,s8
    80002e8a:	faa4fde3          	bgeu	s1,a0,80002e44 <balloc+0x3a>
      m = 1 << (bi % 8);
    80002e8e:	41f6579b          	sraiw	a5,a2,0x1f
    80002e92:	01d7d69b          	srliw	a3,a5,0x1d
    80002e96:	00c6873b          	addw	a4,a3,a2
    80002e9a:	00777793          	andi	a5,a4,7
    80002e9e:	9f95                	subw	a5,a5,a3
    80002ea0:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80002ea4:	4037571b          	sraiw	a4,a4,0x3
    80002ea8:	00e906b3          	add	a3,s2,a4
    80002eac:	0606c683          	lbu	a3,96(a3)
    80002eb0:	00d7f5b3          	and	a1,a5,a3
    80002eb4:	cd91                	beqz	a1,80002ed0 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002eb6:	2605                	addiw	a2,a2,1
    80002eb8:	2485                	addiw	s1,s1,1
    80002eba:	fd4618e3          	bne	a2,s4,80002e8a <balloc+0x80>
    80002ebe:	b759                	j	80002e44 <balloc+0x3a>
  panic("balloc: out of blocks");
    80002ec0:	00004517          	auipc	a0,0x4
    80002ec4:	64050513          	addi	a0,a0,1600 # 80007500 <userret+0x470>
    80002ec8:	ffffd097          	auipc	ra,0xffffd
    80002ecc:	680080e7          	jalr	1664(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80002ed0:	974a                	add	a4,a4,s2
    80002ed2:	8fd5                	or	a5,a5,a3
    80002ed4:	06f70023          	sb	a5,96(a4)
        log_write(bp);
    80002ed8:	854a                	mv	a0,s2
    80002eda:	00001097          	auipc	ra,0x1
    80002ede:	0d8080e7          	jalr	216(ra) # 80003fb2 <log_write>
        brelse(bp);
    80002ee2:	854a                	mv	a0,s2
    80002ee4:	00000097          	auipc	ra,0x0
    80002ee8:	d94080e7          	jalr	-620(ra) # 80002c78 <brelse>
  bp = bread(dev, bno);
    80002eec:	85a6                	mv	a1,s1
    80002eee:	855e                	mv	a0,s7
    80002ef0:	00000097          	auipc	ra,0x0
    80002ef4:	c54080e7          	jalr	-940(ra) # 80002b44 <bread>
    80002ef8:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80002efa:	40000613          	li	a2,1024
    80002efe:	4581                	li	a1,0
    80002f00:	06050513          	addi	a0,a0,96
    80002f04:	ffffe097          	auipc	ra,0xffffe
    80002f08:	b7c080e7          	jalr	-1156(ra) # 80000a80 <memset>
  log_write(bp);
    80002f0c:	854a                	mv	a0,s2
    80002f0e:	00001097          	auipc	ra,0x1
    80002f12:	0a4080e7          	jalr	164(ra) # 80003fb2 <log_write>
  brelse(bp);
    80002f16:	854a                	mv	a0,s2
    80002f18:	00000097          	auipc	ra,0x0
    80002f1c:	d60080e7          	jalr	-672(ra) # 80002c78 <brelse>
}
    80002f20:	8526                	mv	a0,s1
    80002f22:	60e6                	ld	ra,88(sp)
    80002f24:	6446                	ld	s0,80(sp)
    80002f26:	64a6                	ld	s1,72(sp)
    80002f28:	6906                	ld	s2,64(sp)
    80002f2a:	79e2                	ld	s3,56(sp)
    80002f2c:	7a42                	ld	s4,48(sp)
    80002f2e:	7aa2                	ld	s5,40(sp)
    80002f30:	7b02                	ld	s6,32(sp)
    80002f32:	6be2                	ld	s7,24(sp)
    80002f34:	6c42                	ld	s8,16(sp)
    80002f36:	6ca2                	ld	s9,8(sp)
    80002f38:	6125                	addi	sp,sp,96
    80002f3a:	8082                	ret

0000000080002f3c <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80002f3c:	7179                	addi	sp,sp,-48
    80002f3e:	f406                	sd	ra,40(sp)
    80002f40:	f022                	sd	s0,32(sp)
    80002f42:	ec26                	sd	s1,24(sp)
    80002f44:	e84a                	sd	s2,16(sp)
    80002f46:	e44e                	sd	s3,8(sp)
    80002f48:	e052                	sd	s4,0(sp)
    80002f4a:	1800                	addi	s0,sp,48
    80002f4c:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80002f4e:	47ad                	li	a5,11
    80002f50:	04b7fe63          	bgeu	a5,a1,80002fac <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80002f54:	ff45849b          	addiw	s1,a1,-12
    80002f58:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80002f5c:	0ff00793          	li	a5,255
    80002f60:	0ae7e463          	bltu	a5,a4,80003008 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80002f64:	08052583          	lw	a1,128(a0)
    80002f68:	c5b5                	beqz	a1,80002fd4 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80002f6a:	00092503          	lw	a0,0(s2)
    80002f6e:	00000097          	auipc	ra,0x0
    80002f72:	bd6080e7          	jalr	-1066(ra) # 80002b44 <bread>
    80002f76:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80002f78:	06050793          	addi	a5,a0,96
    if((addr = a[bn]) == 0){
    80002f7c:	02049713          	slli	a4,s1,0x20
    80002f80:	01e75593          	srli	a1,a4,0x1e
    80002f84:	00b784b3          	add	s1,a5,a1
    80002f88:	0004a983          	lw	s3,0(s1)
    80002f8c:	04098e63          	beqz	s3,80002fe8 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80002f90:	8552                	mv	a0,s4
    80002f92:	00000097          	auipc	ra,0x0
    80002f96:	ce6080e7          	jalr	-794(ra) # 80002c78 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80002f9a:	854e                	mv	a0,s3
    80002f9c:	70a2                	ld	ra,40(sp)
    80002f9e:	7402                	ld	s0,32(sp)
    80002fa0:	64e2                	ld	s1,24(sp)
    80002fa2:	6942                	ld	s2,16(sp)
    80002fa4:	69a2                	ld	s3,8(sp)
    80002fa6:	6a02                	ld	s4,0(sp)
    80002fa8:	6145                	addi	sp,sp,48
    80002faa:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80002fac:	02059793          	slli	a5,a1,0x20
    80002fb0:	01e7d593          	srli	a1,a5,0x1e
    80002fb4:	00b504b3          	add	s1,a0,a1
    80002fb8:	0504a983          	lw	s3,80(s1)
    80002fbc:	fc099fe3          	bnez	s3,80002f9a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80002fc0:	4108                	lw	a0,0(a0)
    80002fc2:	00000097          	auipc	ra,0x0
    80002fc6:	e48080e7          	jalr	-440(ra) # 80002e0a <balloc>
    80002fca:	0005099b          	sext.w	s3,a0
    80002fce:	0534a823          	sw	s3,80(s1)
    80002fd2:	b7e1                	j	80002f9a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80002fd4:	4108                	lw	a0,0(a0)
    80002fd6:	00000097          	auipc	ra,0x0
    80002fda:	e34080e7          	jalr	-460(ra) # 80002e0a <balloc>
    80002fde:	0005059b          	sext.w	a1,a0
    80002fe2:	08b92023          	sw	a1,128(s2)
    80002fe6:	b751                	j	80002f6a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80002fe8:	00092503          	lw	a0,0(s2)
    80002fec:	00000097          	auipc	ra,0x0
    80002ff0:	e1e080e7          	jalr	-482(ra) # 80002e0a <balloc>
    80002ff4:	0005099b          	sext.w	s3,a0
    80002ff8:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80002ffc:	8552                	mv	a0,s4
    80002ffe:	00001097          	auipc	ra,0x1
    80003002:	fb4080e7          	jalr	-76(ra) # 80003fb2 <log_write>
    80003006:	b769                	j	80002f90 <bmap+0x54>
  panic("bmap: out of range");
    80003008:	00004517          	auipc	a0,0x4
    8000300c:	51050513          	addi	a0,a0,1296 # 80007518 <userret+0x488>
    80003010:	ffffd097          	auipc	ra,0xffffd
    80003014:	538080e7          	jalr	1336(ra) # 80000548 <panic>

0000000080003018 <iget>:
{
    80003018:	7179                	addi	sp,sp,-48
    8000301a:	f406                	sd	ra,40(sp)
    8000301c:	f022                	sd	s0,32(sp)
    8000301e:	ec26                	sd	s1,24(sp)
    80003020:	e84a                	sd	s2,16(sp)
    80003022:	e44e                	sd	s3,8(sp)
    80003024:	e052                	sd	s4,0(sp)
    80003026:	1800                	addi	s0,sp,48
    80003028:	89aa                	mv	s3,a0
    8000302a:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000302c:	0001d517          	auipc	a0,0x1d
    80003030:	ea450513          	addi	a0,a0,-348 # 8001fed0 <icache>
    80003034:	ffffe097          	auipc	ra,0xffffe
    80003038:	988080e7          	jalr	-1656(ra) # 800009bc <acquire>
  empty = 0;
    8000303c:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000303e:	0001d497          	auipc	s1,0x1d
    80003042:	eaa48493          	addi	s1,s1,-342 # 8001fee8 <icache+0x18>
    80003046:	0001f697          	auipc	a3,0x1f
    8000304a:	93268693          	addi	a3,a3,-1742 # 80021978 <log>
    8000304e:	a039                	j	8000305c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003050:	02090b63          	beqz	s2,80003086 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003054:	08848493          	addi	s1,s1,136
    80003058:	02d48a63          	beq	s1,a3,8000308c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000305c:	449c                	lw	a5,8(s1)
    8000305e:	fef059e3          	blez	a5,80003050 <iget+0x38>
    80003062:	4098                	lw	a4,0(s1)
    80003064:	ff3716e3          	bne	a4,s3,80003050 <iget+0x38>
    80003068:	40d8                	lw	a4,4(s1)
    8000306a:	ff4713e3          	bne	a4,s4,80003050 <iget+0x38>
      ip->ref++;
    8000306e:	2785                	addiw	a5,a5,1
    80003070:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003072:	0001d517          	auipc	a0,0x1d
    80003076:	e5e50513          	addi	a0,a0,-418 # 8001fed0 <icache>
    8000307a:	ffffe097          	auipc	ra,0xffffe
    8000307e:	9aa080e7          	jalr	-1622(ra) # 80000a24 <release>
      return ip;
    80003082:	8926                	mv	s2,s1
    80003084:	a03d                	j	800030b2 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003086:	f7f9                	bnez	a5,80003054 <iget+0x3c>
    80003088:	8926                	mv	s2,s1
    8000308a:	b7e9                	j	80003054 <iget+0x3c>
  if(empty == 0)
    8000308c:	02090c63          	beqz	s2,800030c4 <iget+0xac>
  ip->dev = dev;
    80003090:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003094:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003098:	4785                	li	a5,1
    8000309a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000309e:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800030a2:	0001d517          	auipc	a0,0x1d
    800030a6:	e2e50513          	addi	a0,a0,-466 # 8001fed0 <icache>
    800030aa:	ffffe097          	auipc	ra,0xffffe
    800030ae:	97a080e7          	jalr	-1670(ra) # 80000a24 <release>
}
    800030b2:	854a                	mv	a0,s2
    800030b4:	70a2                	ld	ra,40(sp)
    800030b6:	7402                	ld	s0,32(sp)
    800030b8:	64e2                	ld	s1,24(sp)
    800030ba:	6942                	ld	s2,16(sp)
    800030bc:	69a2                	ld	s3,8(sp)
    800030be:	6a02                	ld	s4,0(sp)
    800030c0:	6145                	addi	sp,sp,48
    800030c2:	8082                	ret
    panic("iget: no inodes");
    800030c4:	00004517          	auipc	a0,0x4
    800030c8:	46c50513          	addi	a0,a0,1132 # 80007530 <userret+0x4a0>
    800030cc:	ffffd097          	auipc	ra,0xffffd
    800030d0:	47c080e7          	jalr	1148(ra) # 80000548 <panic>

00000000800030d4 <fsinit>:
fsinit(int dev) {
    800030d4:	7179                	addi	sp,sp,-48
    800030d6:	f406                	sd	ra,40(sp)
    800030d8:	f022                	sd	s0,32(sp)
    800030da:	ec26                	sd	s1,24(sp)
    800030dc:	e84a                	sd	s2,16(sp)
    800030de:	e44e                	sd	s3,8(sp)
    800030e0:	1800                	addi	s0,sp,48
    800030e2:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800030e4:	4585                	li	a1,1
    800030e6:	00000097          	auipc	ra,0x0
    800030ea:	a5e080e7          	jalr	-1442(ra) # 80002b44 <bread>
    800030ee:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800030f0:	0001d997          	auipc	s3,0x1d
    800030f4:	dc098993          	addi	s3,s3,-576 # 8001feb0 <sb>
    800030f8:	02000613          	li	a2,32
    800030fc:	06050593          	addi	a1,a0,96
    80003100:	854e                	mv	a0,s3
    80003102:	ffffe097          	auipc	ra,0xffffe
    80003106:	9da080e7          	jalr	-1574(ra) # 80000adc <memmove>
  brelse(bp);
    8000310a:	8526                	mv	a0,s1
    8000310c:	00000097          	auipc	ra,0x0
    80003110:	b6c080e7          	jalr	-1172(ra) # 80002c78 <brelse>
  if(sb.magic != FSMAGIC)
    80003114:	0009a703          	lw	a4,0(s3)
    80003118:	102037b7          	lui	a5,0x10203
    8000311c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003120:	02f71263          	bne	a4,a5,80003144 <fsinit+0x70>
  initlog(dev, &sb);
    80003124:	0001d597          	auipc	a1,0x1d
    80003128:	d8c58593          	addi	a1,a1,-628 # 8001feb0 <sb>
    8000312c:	854a                	mv	a0,s2
    8000312e:	00001097          	auipc	ra,0x1
    80003132:	bfc080e7          	jalr	-1028(ra) # 80003d2a <initlog>
}
    80003136:	70a2                	ld	ra,40(sp)
    80003138:	7402                	ld	s0,32(sp)
    8000313a:	64e2                	ld	s1,24(sp)
    8000313c:	6942                	ld	s2,16(sp)
    8000313e:	69a2                	ld	s3,8(sp)
    80003140:	6145                	addi	sp,sp,48
    80003142:	8082                	ret
    panic("invalid file system");
    80003144:	00004517          	auipc	a0,0x4
    80003148:	3fc50513          	addi	a0,a0,1020 # 80007540 <userret+0x4b0>
    8000314c:	ffffd097          	auipc	ra,0xffffd
    80003150:	3fc080e7          	jalr	1020(ra) # 80000548 <panic>

0000000080003154 <iinit>:
{
    80003154:	7179                	addi	sp,sp,-48
    80003156:	f406                	sd	ra,40(sp)
    80003158:	f022                	sd	s0,32(sp)
    8000315a:	ec26                	sd	s1,24(sp)
    8000315c:	e84a                	sd	s2,16(sp)
    8000315e:	e44e                	sd	s3,8(sp)
    80003160:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003162:	00004597          	auipc	a1,0x4
    80003166:	3f658593          	addi	a1,a1,1014 # 80007558 <userret+0x4c8>
    8000316a:	0001d517          	auipc	a0,0x1d
    8000316e:	d6650513          	addi	a0,a0,-666 # 8001fed0 <icache>
    80003172:	ffffd097          	auipc	ra,0xffffd
    80003176:	73c080e7          	jalr	1852(ra) # 800008ae <initlock>
  for(i = 0; i < NINODE; i++) {
    8000317a:	0001d497          	auipc	s1,0x1d
    8000317e:	d7e48493          	addi	s1,s1,-642 # 8001fef8 <icache+0x28>
    80003182:	0001f997          	auipc	s3,0x1f
    80003186:	80698993          	addi	s3,s3,-2042 # 80021988 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000318a:	00004917          	auipc	s2,0x4
    8000318e:	3d690913          	addi	s2,s2,982 # 80007560 <userret+0x4d0>
    80003192:	85ca                	mv	a1,s2
    80003194:	8526                	mv	a0,s1
    80003196:	00001097          	auipc	ra,0x1
    8000319a:	07a080e7          	jalr	122(ra) # 80004210 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000319e:	08848493          	addi	s1,s1,136
    800031a2:	ff3498e3          	bne	s1,s3,80003192 <iinit+0x3e>
}
    800031a6:	70a2                	ld	ra,40(sp)
    800031a8:	7402                	ld	s0,32(sp)
    800031aa:	64e2                	ld	s1,24(sp)
    800031ac:	6942                	ld	s2,16(sp)
    800031ae:	69a2                	ld	s3,8(sp)
    800031b0:	6145                	addi	sp,sp,48
    800031b2:	8082                	ret

00000000800031b4 <ialloc>:
{
    800031b4:	715d                	addi	sp,sp,-80
    800031b6:	e486                	sd	ra,72(sp)
    800031b8:	e0a2                	sd	s0,64(sp)
    800031ba:	fc26                	sd	s1,56(sp)
    800031bc:	f84a                	sd	s2,48(sp)
    800031be:	f44e                	sd	s3,40(sp)
    800031c0:	f052                	sd	s4,32(sp)
    800031c2:	ec56                	sd	s5,24(sp)
    800031c4:	e85a                	sd	s6,16(sp)
    800031c6:	e45e                	sd	s7,8(sp)
    800031c8:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800031ca:	0001d717          	auipc	a4,0x1d
    800031ce:	cf272703          	lw	a4,-782(a4) # 8001febc <sb+0xc>
    800031d2:	4785                	li	a5,1
    800031d4:	04e7fa63          	bgeu	a5,a4,80003228 <ialloc+0x74>
    800031d8:	8aaa                	mv	s5,a0
    800031da:	8bae                	mv	s7,a1
    800031dc:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800031de:	0001da17          	auipc	s4,0x1d
    800031e2:	cd2a0a13          	addi	s4,s4,-814 # 8001feb0 <sb>
    800031e6:	00048b1b          	sext.w	s6,s1
    800031ea:	0044d793          	srli	a5,s1,0x4
    800031ee:	018a2583          	lw	a1,24(s4)
    800031f2:	9dbd                	addw	a1,a1,a5
    800031f4:	8556                	mv	a0,s5
    800031f6:	00000097          	auipc	ra,0x0
    800031fa:	94e080e7          	jalr	-1714(ra) # 80002b44 <bread>
    800031fe:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003200:	06050993          	addi	s3,a0,96
    80003204:	00f4f793          	andi	a5,s1,15
    80003208:	079a                	slli	a5,a5,0x6
    8000320a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000320c:	00099783          	lh	a5,0(s3)
    80003210:	c785                	beqz	a5,80003238 <ialloc+0x84>
    brelse(bp);
    80003212:	00000097          	auipc	ra,0x0
    80003216:	a66080e7          	jalr	-1434(ra) # 80002c78 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000321a:	0485                	addi	s1,s1,1
    8000321c:	00ca2703          	lw	a4,12(s4)
    80003220:	0004879b          	sext.w	a5,s1
    80003224:	fce7e1e3          	bltu	a5,a4,800031e6 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003228:	00004517          	auipc	a0,0x4
    8000322c:	34050513          	addi	a0,a0,832 # 80007568 <userret+0x4d8>
    80003230:	ffffd097          	auipc	ra,0xffffd
    80003234:	318080e7          	jalr	792(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    80003238:	04000613          	li	a2,64
    8000323c:	4581                	li	a1,0
    8000323e:	854e                	mv	a0,s3
    80003240:	ffffe097          	auipc	ra,0xffffe
    80003244:	840080e7          	jalr	-1984(ra) # 80000a80 <memset>
      dip->type = type;
    80003248:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000324c:	854a                	mv	a0,s2
    8000324e:	00001097          	auipc	ra,0x1
    80003252:	d64080e7          	jalr	-668(ra) # 80003fb2 <log_write>
      brelse(bp);
    80003256:	854a                	mv	a0,s2
    80003258:	00000097          	auipc	ra,0x0
    8000325c:	a20080e7          	jalr	-1504(ra) # 80002c78 <brelse>
      return iget(dev, inum);
    80003260:	85da                	mv	a1,s6
    80003262:	8556                	mv	a0,s5
    80003264:	00000097          	auipc	ra,0x0
    80003268:	db4080e7          	jalr	-588(ra) # 80003018 <iget>
}
    8000326c:	60a6                	ld	ra,72(sp)
    8000326e:	6406                	ld	s0,64(sp)
    80003270:	74e2                	ld	s1,56(sp)
    80003272:	7942                	ld	s2,48(sp)
    80003274:	79a2                	ld	s3,40(sp)
    80003276:	7a02                	ld	s4,32(sp)
    80003278:	6ae2                	ld	s5,24(sp)
    8000327a:	6b42                	ld	s6,16(sp)
    8000327c:	6ba2                	ld	s7,8(sp)
    8000327e:	6161                	addi	sp,sp,80
    80003280:	8082                	ret

0000000080003282 <iupdate>:
{
    80003282:	1101                	addi	sp,sp,-32
    80003284:	ec06                	sd	ra,24(sp)
    80003286:	e822                	sd	s0,16(sp)
    80003288:	e426                	sd	s1,8(sp)
    8000328a:	e04a                	sd	s2,0(sp)
    8000328c:	1000                	addi	s0,sp,32
    8000328e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003290:	415c                	lw	a5,4(a0)
    80003292:	0047d79b          	srliw	a5,a5,0x4
    80003296:	0001d597          	auipc	a1,0x1d
    8000329a:	c325a583          	lw	a1,-974(a1) # 8001fec8 <sb+0x18>
    8000329e:	9dbd                	addw	a1,a1,a5
    800032a0:	4108                	lw	a0,0(a0)
    800032a2:	00000097          	auipc	ra,0x0
    800032a6:	8a2080e7          	jalr	-1886(ra) # 80002b44 <bread>
    800032aa:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800032ac:	06050793          	addi	a5,a0,96
    800032b0:	40c8                	lw	a0,4(s1)
    800032b2:	893d                	andi	a0,a0,15
    800032b4:	051a                	slli	a0,a0,0x6
    800032b6:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800032b8:	04449703          	lh	a4,68(s1)
    800032bc:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800032c0:	04649703          	lh	a4,70(s1)
    800032c4:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800032c8:	04849703          	lh	a4,72(s1)
    800032cc:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800032d0:	04a49703          	lh	a4,74(s1)
    800032d4:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800032d8:	44f8                	lw	a4,76(s1)
    800032da:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800032dc:	03400613          	li	a2,52
    800032e0:	05048593          	addi	a1,s1,80
    800032e4:	0531                	addi	a0,a0,12
    800032e6:	ffffd097          	auipc	ra,0xffffd
    800032ea:	7f6080e7          	jalr	2038(ra) # 80000adc <memmove>
  log_write(bp);
    800032ee:	854a                	mv	a0,s2
    800032f0:	00001097          	auipc	ra,0x1
    800032f4:	cc2080e7          	jalr	-830(ra) # 80003fb2 <log_write>
  brelse(bp);
    800032f8:	854a                	mv	a0,s2
    800032fa:	00000097          	auipc	ra,0x0
    800032fe:	97e080e7          	jalr	-1666(ra) # 80002c78 <brelse>
}
    80003302:	60e2                	ld	ra,24(sp)
    80003304:	6442                	ld	s0,16(sp)
    80003306:	64a2                	ld	s1,8(sp)
    80003308:	6902                	ld	s2,0(sp)
    8000330a:	6105                	addi	sp,sp,32
    8000330c:	8082                	ret

000000008000330e <idup>:
{
    8000330e:	1101                	addi	sp,sp,-32
    80003310:	ec06                	sd	ra,24(sp)
    80003312:	e822                	sd	s0,16(sp)
    80003314:	e426                	sd	s1,8(sp)
    80003316:	1000                	addi	s0,sp,32
    80003318:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000331a:	0001d517          	auipc	a0,0x1d
    8000331e:	bb650513          	addi	a0,a0,-1098 # 8001fed0 <icache>
    80003322:	ffffd097          	auipc	ra,0xffffd
    80003326:	69a080e7          	jalr	1690(ra) # 800009bc <acquire>
  ip->ref++;
    8000332a:	449c                	lw	a5,8(s1)
    8000332c:	2785                	addiw	a5,a5,1
    8000332e:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003330:	0001d517          	auipc	a0,0x1d
    80003334:	ba050513          	addi	a0,a0,-1120 # 8001fed0 <icache>
    80003338:	ffffd097          	auipc	ra,0xffffd
    8000333c:	6ec080e7          	jalr	1772(ra) # 80000a24 <release>
}
    80003340:	8526                	mv	a0,s1
    80003342:	60e2                	ld	ra,24(sp)
    80003344:	6442                	ld	s0,16(sp)
    80003346:	64a2                	ld	s1,8(sp)
    80003348:	6105                	addi	sp,sp,32
    8000334a:	8082                	ret

000000008000334c <ilock>:
{
    8000334c:	1101                	addi	sp,sp,-32
    8000334e:	ec06                	sd	ra,24(sp)
    80003350:	e822                	sd	s0,16(sp)
    80003352:	e426                	sd	s1,8(sp)
    80003354:	e04a                	sd	s2,0(sp)
    80003356:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003358:	c115                	beqz	a0,8000337c <ilock+0x30>
    8000335a:	84aa                	mv	s1,a0
    8000335c:	451c                	lw	a5,8(a0)
    8000335e:	00f05f63          	blez	a5,8000337c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003362:	0541                	addi	a0,a0,16
    80003364:	00001097          	auipc	ra,0x1
    80003368:	ee6080e7          	jalr	-282(ra) # 8000424a <acquiresleep>
  if(ip->valid == 0){
    8000336c:	40bc                	lw	a5,64(s1)
    8000336e:	cf99                	beqz	a5,8000338c <ilock+0x40>
}
    80003370:	60e2                	ld	ra,24(sp)
    80003372:	6442                	ld	s0,16(sp)
    80003374:	64a2                	ld	s1,8(sp)
    80003376:	6902                	ld	s2,0(sp)
    80003378:	6105                	addi	sp,sp,32
    8000337a:	8082                	ret
    panic("ilock");
    8000337c:	00004517          	auipc	a0,0x4
    80003380:	20450513          	addi	a0,a0,516 # 80007580 <userret+0x4f0>
    80003384:	ffffd097          	auipc	ra,0xffffd
    80003388:	1c4080e7          	jalr	452(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000338c:	40dc                	lw	a5,4(s1)
    8000338e:	0047d79b          	srliw	a5,a5,0x4
    80003392:	0001d597          	auipc	a1,0x1d
    80003396:	b365a583          	lw	a1,-1226(a1) # 8001fec8 <sb+0x18>
    8000339a:	9dbd                	addw	a1,a1,a5
    8000339c:	4088                	lw	a0,0(s1)
    8000339e:	fffff097          	auipc	ra,0xfffff
    800033a2:	7a6080e7          	jalr	1958(ra) # 80002b44 <bread>
    800033a6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800033a8:	06050593          	addi	a1,a0,96
    800033ac:	40dc                	lw	a5,4(s1)
    800033ae:	8bbd                	andi	a5,a5,15
    800033b0:	079a                	slli	a5,a5,0x6
    800033b2:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800033b4:	00059783          	lh	a5,0(a1)
    800033b8:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800033bc:	00259783          	lh	a5,2(a1)
    800033c0:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800033c4:	00459783          	lh	a5,4(a1)
    800033c8:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800033cc:	00659783          	lh	a5,6(a1)
    800033d0:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800033d4:	459c                	lw	a5,8(a1)
    800033d6:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800033d8:	03400613          	li	a2,52
    800033dc:	05b1                	addi	a1,a1,12
    800033de:	05048513          	addi	a0,s1,80
    800033e2:	ffffd097          	auipc	ra,0xffffd
    800033e6:	6fa080e7          	jalr	1786(ra) # 80000adc <memmove>
    brelse(bp);
    800033ea:	854a                	mv	a0,s2
    800033ec:	00000097          	auipc	ra,0x0
    800033f0:	88c080e7          	jalr	-1908(ra) # 80002c78 <brelse>
    ip->valid = 1;
    800033f4:	4785                	li	a5,1
    800033f6:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800033f8:	04449783          	lh	a5,68(s1)
    800033fc:	fbb5                	bnez	a5,80003370 <ilock+0x24>
      panic("ilock: no type");
    800033fe:	00004517          	auipc	a0,0x4
    80003402:	18a50513          	addi	a0,a0,394 # 80007588 <userret+0x4f8>
    80003406:	ffffd097          	auipc	ra,0xffffd
    8000340a:	142080e7          	jalr	322(ra) # 80000548 <panic>

000000008000340e <iunlock>:
{
    8000340e:	1101                	addi	sp,sp,-32
    80003410:	ec06                	sd	ra,24(sp)
    80003412:	e822                	sd	s0,16(sp)
    80003414:	e426                	sd	s1,8(sp)
    80003416:	e04a                	sd	s2,0(sp)
    80003418:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000341a:	c905                	beqz	a0,8000344a <iunlock+0x3c>
    8000341c:	84aa                	mv	s1,a0
    8000341e:	01050913          	addi	s2,a0,16
    80003422:	854a                	mv	a0,s2
    80003424:	00001097          	auipc	ra,0x1
    80003428:	ec0080e7          	jalr	-320(ra) # 800042e4 <holdingsleep>
    8000342c:	cd19                	beqz	a0,8000344a <iunlock+0x3c>
    8000342e:	449c                	lw	a5,8(s1)
    80003430:	00f05d63          	blez	a5,8000344a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003434:	854a                	mv	a0,s2
    80003436:	00001097          	auipc	ra,0x1
    8000343a:	e6a080e7          	jalr	-406(ra) # 800042a0 <releasesleep>
}
    8000343e:	60e2                	ld	ra,24(sp)
    80003440:	6442                	ld	s0,16(sp)
    80003442:	64a2                	ld	s1,8(sp)
    80003444:	6902                	ld	s2,0(sp)
    80003446:	6105                	addi	sp,sp,32
    80003448:	8082                	ret
    panic("iunlock");
    8000344a:	00004517          	auipc	a0,0x4
    8000344e:	14e50513          	addi	a0,a0,334 # 80007598 <userret+0x508>
    80003452:	ffffd097          	auipc	ra,0xffffd
    80003456:	0f6080e7          	jalr	246(ra) # 80000548 <panic>

000000008000345a <iput>:
{
    8000345a:	7139                	addi	sp,sp,-64
    8000345c:	fc06                	sd	ra,56(sp)
    8000345e:	f822                	sd	s0,48(sp)
    80003460:	f426                	sd	s1,40(sp)
    80003462:	f04a                	sd	s2,32(sp)
    80003464:	ec4e                	sd	s3,24(sp)
    80003466:	e852                	sd	s4,16(sp)
    80003468:	e456                	sd	s5,8(sp)
    8000346a:	0080                	addi	s0,sp,64
    8000346c:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000346e:	0001d517          	auipc	a0,0x1d
    80003472:	a6250513          	addi	a0,a0,-1438 # 8001fed0 <icache>
    80003476:	ffffd097          	auipc	ra,0xffffd
    8000347a:	546080e7          	jalr	1350(ra) # 800009bc <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000347e:	4498                	lw	a4,8(s1)
    80003480:	4785                	li	a5,1
    80003482:	02f70663          	beq	a4,a5,800034ae <iput+0x54>
  ip->ref--;
    80003486:	449c                	lw	a5,8(s1)
    80003488:	37fd                	addiw	a5,a5,-1
    8000348a:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000348c:	0001d517          	auipc	a0,0x1d
    80003490:	a4450513          	addi	a0,a0,-1468 # 8001fed0 <icache>
    80003494:	ffffd097          	auipc	ra,0xffffd
    80003498:	590080e7          	jalr	1424(ra) # 80000a24 <release>
}
    8000349c:	70e2                	ld	ra,56(sp)
    8000349e:	7442                	ld	s0,48(sp)
    800034a0:	74a2                	ld	s1,40(sp)
    800034a2:	7902                	ld	s2,32(sp)
    800034a4:	69e2                	ld	s3,24(sp)
    800034a6:	6a42                	ld	s4,16(sp)
    800034a8:	6aa2                	ld	s5,8(sp)
    800034aa:	6121                	addi	sp,sp,64
    800034ac:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800034ae:	40bc                	lw	a5,64(s1)
    800034b0:	dbf9                	beqz	a5,80003486 <iput+0x2c>
    800034b2:	04a49783          	lh	a5,74(s1)
    800034b6:	fbe1                	bnez	a5,80003486 <iput+0x2c>
    acquiresleep(&ip->lock);
    800034b8:	01048a13          	addi	s4,s1,16
    800034bc:	8552                	mv	a0,s4
    800034be:	00001097          	auipc	ra,0x1
    800034c2:	d8c080e7          	jalr	-628(ra) # 8000424a <acquiresleep>
    release(&icache.lock);
    800034c6:	0001d517          	auipc	a0,0x1d
    800034ca:	a0a50513          	addi	a0,a0,-1526 # 8001fed0 <icache>
    800034ce:	ffffd097          	auipc	ra,0xffffd
    800034d2:	556080e7          	jalr	1366(ra) # 80000a24 <release>
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800034d6:	05048913          	addi	s2,s1,80
    800034da:	08048993          	addi	s3,s1,128
    800034de:	a021                	j	800034e6 <iput+0x8c>
    800034e0:	0911                	addi	s2,s2,4
    800034e2:	01390d63          	beq	s2,s3,800034fc <iput+0xa2>
    if(ip->addrs[i]){
    800034e6:	00092583          	lw	a1,0(s2)
    800034ea:	d9fd                	beqz	a1,800034e0 <iput+0x86>
      bfree(ip->dev, ip->addrs[i]);
    800034ec:	4088                	lw	a0,0(s1)
    800034ee:	00000097          	auipc	ra,0x0
    800034f2:	8a0080e7          	jalr	-1888(ra) # 80002d8e <bfree>
      ip->addrs[i] = 0;
    800034f6:	00092023          	sw	zero,0(s2)
    800034fa:	b7dd                	j	800034e0 <iput+0x86>
    }
  }

  if(ip->addrs[NDIRECT]){
    800034fc:	0804a583          	lw	a1,128(s1)
    80003500:	ed9d                	bnez	a1,8000353e <iput+0xe4>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003502:	0404a623          	sw	zero,76(s1)
  iupdate(ip);
    80003506:	8526                	mv	a0,s1
    80003508:	00000097          	auipc	ra,0x0
    8000350c:	d7a080e7          	jalr	-646(ra) # 80003282 <iupdate>
    ip->type = 0;
    80003510:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003514:	8526                	mv	a0,s1
    80003516:	00000097          	auipc	ra,0x0
    8000351a:	d6c080e7          	jalr	-660(ra) # 80003282 <iupdate>
    ip->valid = 0;
    8000351e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003522:	8552                	mv	a0,s4
    80003524:	00001097          	auipc	ra,0x1
    80003528:	d7c080e7          	jalr	-644(ra) # 800042a0 <releasesleep>
    acquire(&icache.lock);
    8000352c:	0001d517          	auipc	a0,0x1d
    80003530:	9a450513          	addi	a0,a0,-1628 # 8001fed0 <icache>
    80003534:	ffffd097          	auipc	ra,0xffffd
    80003538:	488080e7          	jalr	1160(ra) # 800009bc <acquire>
    8000353c:	b7a9                	j	80003486 <iput+0x2c>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000353e:	4088                	lw	a0,0(s1)
    80003540:	fffff097          	auipc	ra,0xfffff
    80003544:	604080e7          	jalr	1540(ra) # 80002b44 <bread>
    80003548:	8aaa                	mv	s5,a0
    for(j = 0; j < NINDIRECT; j++){
    8000354a:	06050913          	addi	s2,a0,96
    8000354e:	46050993          	addi	s3,a0,1120
    80003552:	a021                	j	8000355a <iput+0x100>
    80003554:	0911                	addi	s2,s2,4
    80003556:	01390b63          	beq	s2,s3,8000356c <iput+0x112>
      if(a[j])
    8000355a:	00092583          	lw	a1,0(s2)
    8000355e:	d9fd                	beqz	a1,80003554 <iput+0xfa>
        bfree(ip->dev, a[j]);
    80003560:	4088                	lw	a0,0(s1)
    80003562:	00000097          	auipc	ra,0x0
    80003566:	82c080e7          	jalr	-2004(ra) # 80002d8e <bfree>
    8000356a:	b7ed                	j	80003554 <iput+0xfa>
    brelse(bp);
    8000356c:	8556                	mv	a0,s5
    8000356e:	fffff097          	auipc	ra,0xfffff
    80003572:	70a080e7          	jalr	1802(ra) # 80002c78 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003576:	0804a583          	lw	a1,128(s1)
    8000357a:	4088                	lw	a0,0(s1)
    8000357c:	00000097          	auipc	ra,0x0
    80003580:	812080e7          	jalr	-2030(ra) # 80002d8e <bfree>
    ip->addrs[NDIRECT] = 0;
    80003584:	0804a023          	sw	zero,128(s1)
    80003588:	bfad                	j	80003502 <iput+0xa8>

000000008000358a <iunlockput>:
{
    8000358a:	1101                	addi	sp,sp,-32
    8000358c:	ec06                	sd	ra,24(sp)
    8000358e:	e822                	sd	s0,16(sp)
    80003590:	e426                	sd	s1,8(sp)
    80003592:	1000                	addi	s0,sp,32
    80003594:	84aa                	mv	s1,a0
  iunlock(ip);
    80003596:	00000097          	auipc	ra,0x0
    8000359a:	e78080e7          	jalr	-392(ra) # 8000340e <iunlock>
  iput(ip);
    8000359e:	8526                	mv	a0,s1
    800035a0:	00000097          	auipc	ra,0x0
    800035a4:	eba080e7          	jalr	-326(ra) # 8000345a <iput>
}
    800035a8:	60e2                	ld	ra,24(sp)
    800035aa:	6442                	ld	s0,16(sp)
    800035ac:	64a2                	ld	s1,8(sp)
    800035ae:	6105                	addi	sp,sp,32
    800035b0:	8082                	ret

00000000800035b2 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800035b2:	1141                	addi	sp,sp,-16
    800035b4:	e422                	sd	s0,8(sp)
    800035b6:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800035b8:	411c                	lw	a5,0(a0)
    800035ba:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800035bc:	415c                	lw	a5,4(a0)
    800035be:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800035c0:	04451783          	lh	a5,68(a0)
    800035c4:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800035c8:	04a51783          	lh	a5,74(a0)
    800035cc:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800035d0:	04c56783          	lwu	a5,76(a0)
    800035d4:	e99c                	sd	a5,16(a1)
}
    800035d6:	6422                	ld	s0,8(sp)
    800035d8:	0141                	addi	sp,sp,16
    800035da:	8082                	ret

00000000800035dc <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800035dc:	457c                	lw	a5,76(a0)
    800035de:	0ed7e563          	bltu	a5,a3,800036c8 <readi+0xec>
{
    800035e2:	7159                	addi	sp,sp,-112
    800035e4:	f486                	sd	ra,104(sp)
    800035e6:	f0a2                	sd	s0,96(sp)
    800035e8:	eca6                	sd	s1,88(sp)
    800035ea:	e8ca                	sd	s2,80(sp)
    800035ec:	e4ce                	sd	s3,72(sp)
    800035ee:	e0d2                	sd	s4,64(sp)
    800035f0:	fc56                	sd	s5,56(sp)
    800035f2:	f85a                	sd	s6,48(sp)
    800035f4:	f45e                	sd	s7,40(sp)
    800035f6:	f062                	sd	s8,32(sp)
    800035f8:	ec66                	sd	s9,24(sp)
    800035fa:	e86a                	sd	s10,16(sp)
    800035fc:	e46e                	sd	s11,8(sp)
    800035fe:	1880                	addi	s0,sp,112
    80003600:	8baa                	mv	s7,a0
    80003602:	8c2e                	mv	s8,a1
    80003604:	8ab2                	mv	s5,a2
    80003606:	8936                	mv	s2,a3
    80003608:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000360a:	9f35                	addw	a4,a4,a3
    8000360c:	0cd76063          	bltu	a4,a3,800036cc <readi+0xf0>
    return -1;
  if(off + n > ip->size)
    80003610:	00e7f463          	bgeu	a5,a4,80003618 <readi+0x3c>
    n = ip->size - off;
    80003614:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003618:	080b0763          	beqz	s6,800036a6 <readi+0xca>
    8000361c:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000361e:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003622:	5cfd                	li	s9,-1
    80003624:	a82d                	j	8000365e <readi+0x82>
    80003626:	02099d93          	slli	s11,s3,0x20
    8000362a:	020ddd93          	srli	s11,s11,0x20
    8000362e:	06048793          	addi	a5,s1,96
    80003632:	86ee                	mv	a3,s11
    80003634:	963e                	add	a2,a2,a5
    80003636:	85d6                	mv	a1,s5
    80003638:	8562                	mv	a0,s8
    8000363a:	fffff097          	auipc	ra,0xfffff
    8000363e:	b52080e7          	jalr	-1198(ra) # 8000218c <either_copyout>
    80003642:	05950d63          	beq	a0,s9,8000369c <readi+0xc0>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003646:	8526                	mv	a0,s1
    80003648:	fffff097          	auipc	ra,0xfffff
    8000364c:	630080e7          	jalr	1584(ra) # 80002c78 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003650:	01498a3b          	addw	s4,s3,s4
    80003654:	0129893b          	addw	s2,s3,s2
    80003658:	9aee                	add	s5,s5,s11
    8000365a:	056a7663          	bgeu	s4,s6,800036a6 <readi+0xca>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000365e:	000ba483          	lw	s1,0(s7)
    80003662:	00a9559b          	srliw	a1,s2,0xa
    80003666:	855e                	mv	a0,s7
    80003668:	00000097          	auipc	ra,0x0
    8000366c:	8d4080e7          	jalr	-1836(ra) # 80002f3c <bmap>
    80003670:	0005059b          	sext.w	a1,a0
    80003674:	8526                	mv	a0,s1
    80003676:	fffff097          	auipc	ra,0xfffff
    8000367a:	4ce080e7          	jalr	1230(ra) # 80002b44 <bread>
    8000367e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003680:	3ff97613          	andi	a2,s2,1023
    80003684:	40cd07bb          	subw	a5,s10,a2
    80003688:	414b073b          	subw	a4,s6,s4
    8000368c:	89be                	mv	s3,a5
    8000368e:	2781                	sext.w	a5,a5
    80003690:	0007069b          	sext.w	a3,a4
    80003694:	f8f6f9e3          	bgeu	a3,a5,80003626 <readi+0x4a>
    80003698:	89ba                	mv	s3,a4
    8000369a:	b771                	j	80003626 <readi+0x4a>
      brelse(bp);
    8000369c:	8526                	mv	a0,s1
    8000369e:	fffff097          	auipc	ra,0xfffff
    800036a2:	5da080e7          	jalr	1498(ra) # 80002c78 <brelse>
  }
  return n;
    800036a6:	000b051b          	sext.w	a0,s6
}
    800036aa:	70a6                	ld	ra,104(sp)
    800036ac:	7406                	ld	s0,96(sp)
    800036ae:	64e6                	ld	s1,88(sp)
    800036b0:	6946                	ld	s2,80(sp)
    800036b2:	69a6                	ld	s3,72(sp)
    800036b4:	6a06                	ld	s4,64(sp)
    800036b6:	7ae2                	ld	s5,56(sp)
    800036b8:	7b42                	ld	s6,48(sp)
    800036ba:	7ba2                	ld	s7,40(sp)
    800036bc:	7c02                	ld	s8,32(sp)
    800036be:	6ce2                	ld	s9,24(sp)
    800036c0:	6d42                	ld	s10,16(sp)
    800036c2:	6da2                	ld	s11,8(sp)
    800036c4:	6165                	addi	sp,sp,112
    800036c6:	8082                	ret
    return -1;
    800036c8:	557d                	li	a0,-1
}
    800036ca:	8082                	ret
    return -1;
    800036cc:	557d                	li	a0,-1
    800036ce:	bff1                	j	800036aa <readi+0xce>

00000000800036d0 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800036d0:	457c                	lw	a5,76(a0)
    800036d2:	10d7e763          	bltu	a5,a3,800037e0 <writei+0x110>
{
    800036d6:	7159                	addi	sp,sp,-112
    800036d8:	f486                	sd	ra,104(sp)
    800036da:	f0a2                	sd	s0,96(sp)
    800036dc:	eca6                	sd	s1,88(sp)
    800036de:	e8ca                	sd	s2,80(sp)
    800036e0:	e4ce                	sd	s3,72(sp)
    800036e2:	e0d2                	sd	s4,64(sp)
    800036e4:	fc56                	sd	s5,56(sp)
    800036e6:	f85a                	sd	s6,48(sp)
    800036e8:	f45e                	sd	s7,40(sp)
    800036ea:	f062                	sd	s8,32(sp)
    800036ec:	ec66                	sd	s9,24(sp)
    800036ee:	e86a                	sd	s10,16(sp)
    800036f0:	e46e                	sd	s11,8(sp)
    800036f2:	1880                	addi	s0,sp,112
    800036f4:	8baa                	mv	s7,a0
    800036f6:	8c2e                	mv	s8,a1
    800036f8:	8ab2                	mv	s5,a2
    800036fa:	8936                	mv	s2,a3
    800036fc:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800036fe:	00e687bb          	addw	a5,a3,a4
    80003702:	0ed7e163          	bltu	a5,a3,800037e4 <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003706:	00043737          	lui	a4,0x43
    8000370a:	0cf76f63          	bltu	a4,a5,800037e8 <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000370e:	0a0b0063          	beqz	s6,800037ae <writei+0xde>
    80003712:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003714:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003718:	5cfd                	li	s9,-1
    8000371a:	a091                	j	8000375e <writei+0x8e>
    8000371c:	02099d93          	slli	s11,s3,0x20
    80003720:	020ddd93          	srli	s11,s11,0x20
    80003724:	06048793          	addi	a5,s1,96
    80003728:	86ee                	mv	a3,s11
    8000372a:	8656                	mv	a2,s5
    8000372c:	85e2                	mv	a1,s8
    8000372e:	953e                	add	a0,a0,a5
    80003730:	fffff097          	auipc	ra,0xfffff
    80003734:	ab2080e7          	jalr	-1358(ra) # 800021e2 <either_copyin>
    80003738:	07950263          	beq	a0,s9,8000379c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000373c:	8526                	mv	a0,s1
    8000373e:	00001097          	auipc	ra,0x1
    80003742:	874080e7          	jalr	-1932(ra) # 80003fb2 <log_write>
    brelse(bp);
    80003746:	8526                	mv	a0,s1
    80003748:	fffff097          	auipc	ra,0xfffff
    8000374c:	530080e7          	jalr	1328(ra) # 80002c78 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003750:	01498a3b          	addw	s4,s3,s4
    80003754:	0129893b          	addw	s2,s3,s2
    80003758:	9aee                	add	s5,s5,s11
    8000375a:	056a7663          	bgeu	s4,s6,800037a6 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000375e:	000ba483          	lw	s1,0(s7)
    80003762:	00a9559b          	srliw	a1,s2,0xa
    80003766:	855e                	mv	a0,s7
    80003768:	fffff097          	auipc	ra,0xfffff
    8000376c:	7d4080e7          	jalr	2004(ra) # 80002f3c <bmap>
    80003770:	0005059b          	sext.w	a1,a0
    80003774:	8526                	mv	a0,s1
    80003776:	fffff097          	auipc	ra,0xfffff
    8000377a:	3ce080e7          	jalr	974(ra) # 80002b44 <bread>
    8000377e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003780:	3ff97513          	andi	a0,s2,1023
    80003784:	40ad07bb          	subw	a5,s10,a0
    80003788:	414b073b          	subw	a4,s6,s4
    8000378c:	89be                	mv	s3,a5
    8000378e:	2781                	sext.w	a5,a5
    80003790:	0007069b          	sext.w	a3,a4
    80003794:	f8f6f4e3          	bgeu	a3,a5,8000371c <writei+0x4c>
    80003798:	89ba                	mv	s3,a4
    8000379a:	b749                	j	8000371c <writei+0x4c>
      brelse(bp);
    8000379c:	8526                	mv	a0,s1
    8000379e:	fffff097          	auipc	ra,0xfffff
    800037a2:	4da080e7          	jalr	1242(ra) # 80002c78 <brelse>
  }

  if(n > 0 && off > ip->size){
    800037a6:	04cba783          	lw	a5,76(s7)
    800037aa:	0327e363          	bltu	a5,s2,800037d0 <writei+0x100>
    ip->size = off;
    iupdate(ip);
  }
  return n;
    800037ae:	000b051b          	sext.w	a0,s6
}
    800037b2:	70a6                	ld	ra,104(sp)
    800037b4:	7406                	ld	s0,96(sp)
    800037b6:	64e6                	ld	s1,88(sp)
    800037b8:	6946                	ld	s2,80(sp)
    800037ba:	69a6                	ld	s3,72(sp)
    800037bc:	6a06                	ld	s4,64(sp)
    800037be:	7ae2                	ld	s5,56(sp)
    800037c0:	7b42                	ld	s6,48(sp)
    800037c2:	7ba2                	ld	s7,40(sp)
    800037c4:	7c02                	ld	s8,32(sp)
    800037c6:	6ce2                	ld	s9,24(sp)
    800037c8:	6d42                	ld	s10,16(sp)
    800037ca:	6da2                	ld	s11,8(sp)
    800037cc:	6165                	addi	sp,sp,112
    800037ce:	8082                	ret
    ip->size = off;
    800037d0:	052ba623          	sw	s2,76(s7)
    iupdate(ip);
    800037d4:	855e                	mv	a0,s7
    800037d6:	00000097          	auipc	ra,0x0
    800037da:	aac080e7          	jalr	-1364(ra) # 80003282 <iupdate>
    800037de:	bfc1                	j	800037ae <writei+0xde>
    return -1;
    800037e0:	557d                	li	a0,-1
}
    800037e2:	8082                	ret
    return -1;
    800037e4:	557d                	li	a0,-1
    800037e6:	b7f1                	j	800037b2 <writei+0xe2>
    return -1;
    800037e8:	557d                	li	a0,-1
    800037ea:	b7e1                	j	800037b2 <writei+0xe2>

00000000800037ec <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800037ec:	1141                	addi	sp,sp,-16
    800037ee:	e406                	sd	ra,8(sp)
    800037f0:	e022                	sd	s0,0(sp)
    800037f2:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800037f4:	4639                	li	a2,14
    800037f6:	ffffd097          	auipc	ra,0xffffd
    800037fa:	362080e7          	jalr	866(ra) # 80000b58 <strncmp>
}
    800037fe:	60a2                	ld	ra,8(sp)
    80003800:	6402                	ld	s0,0(sp)
    80003802:	0141                	addi	sp,sp,16
    80003804:	8082                	ret

0000000080003806 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003806:	7139                	addi	sp,sp,-64
    80003808:	fc06                	sd	ra,56(sp)
    8000380a:	f822                	sd	s0,48(sp)
    8000380c:	f426                	sd	s1,40(sp)
    8000380e:	f04a                	sd	s2,32(sp)
    80003810:	ec4e                	sd	s3,24(sp)
    80003812:	e852                	sd	s4,16(sp)
    80003814:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003816:	04451703          	lh	a4,68(a0)
    8000381a:	4785                	li	a5,1
    8000381c:	00f71a63          	bne	a4,a5,80003830 <dirlookup+0x2a>
    80003820:	892a                	mv	s2,a0
    80003822:	89ae                	mv	s3,a1
    80003824:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003826:	457c                	lw	a5,76(a0)
    80003828:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000382a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000382c:	e79d                	bnez	a5,8000385a <dirlookup+0x54>
    8000382e:	a8a5                	j	800038a6 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003830:	00004517          	auipc	a0,0x4
    80003834:	d7050513          	addi	a0,a0,-656 # 800075a0 <userret+0x510>
    80003838:	ffffd097          	auipc	ra,0xffffd
    8000383c:	d10080e7          	jalr	-752(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003840:	00004517          	auipc	a0,0x4
    80003844:	d7850513          	addi	a0,a0,-648 # 800075b8 <userret+0x528>
    80003848:	ffffd097          	auipc	ra,0xffffd
    8000384c:	d00080e7          	jalr	-768(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003850:	24c1                	addiw	s1,s1,16
    80003852:	04c92783          	lw	a5,76(s2)
    80003856:	04f4f763          	bgeu	s1,a5,800038a4 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000385a:	4741                	li	a4,16
    8000385c:	86a6                	mv	a3,s1
    8000385e:	fc040613          	addi	a2,s0,-64
    80003862:	4581                	li	a1,0
    80003864:	854a                	mv	a0,s2
    80003866:	00000097          	auipc	ra,0x0
    8000386a:	d76080e7          	jalr	-650(ra) # 800035dc <readi>
    8000386e:	47c1                	li	a5,16
    80003870:	fcf518e3          	bne	a0,a5,80003840 <dirlookup+0x3a>
    if(de.inum == 0)
    80003874:	fc045783          	lhu	a5,-64(s0)
    80003878:	dfe1                	beqz	a5,80003850 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000387a:	fc240593          	addi	a1,s0,-62
    8000387e:	854e                	mv	a0,s3
    80003880:	00000097          	auipc	ra,0x0
    80003884:	f6c080e7          	jalr	-148(ra) # 800037ec <namecmp>
    80003888:	f561                	bnez	a0,80003850 <dirlookup+0x4a>
      if(poff)
    8000388a:	000a0463          	beqz	s4,80003892 <dirlookup+0x8c>
        *poff = off;
    8000388e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003892:	fc045583          	lhu	a1,-64(s0)
    80003896:	00092503          	lw	a0,0(s2)
    8000389a:	fffff097          	auipc	ra,0xfffff
    8000389e:	77e080e7          	jalr	1918(ra) # 80003018 <iget>
    800038a2:	a011                	j	800038a6 <dirlookup+0xa0>
  return 0;
    800038a4:	4501                	li	a0,0
}
    800038a6:	70e2                	ld	ra,56(sp)
    800038a8:	7442                	ld	s0,48(sp)
    800038aa:	74a2                	ld	s1,40(sp)
    800038ac:	7902                	ld	s2,32(sp)
    800038ae:	69e2                	ld	s3,24(sp)
    800038b0:	6a42                	ld	s4,16(sp)
    800038b2:	6121                	addi	sp,sp,64
    800038b4:	8082                	ret

00000000800038b6 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800038b6:	711d                	addi	sp,sp,-96
    800038b8:	ec86                	sd	ra,88(sp)
    800038ba:	e8a2                	sd	s0,80(sp)
    800038bc:	e4a6                	sd	s1,72(sp)
    800038be:	e0ca                	sd	s2,64(sp)
    800038c0:	fc4e                	sd	s3,56(sp)
    800038c2:	f852                	sd	s4,48(sp)
    800038c4:	f456                	sd	s5,40(sp)
    800038c6:	f05a                	sd	s6,32(sp)
    800038c8:	ec5e                	sd	s7,24(sp)
    800038ca:	e862                	sd	s8,16(sp)
    800038cc:	e466                	sd	s9,8(sp)
    800038ce:	1080                	addi	s0,sp,96
    800038d0:	84aa                	mv	s1,a0
    800038d2:	8aae                	mv	s5,a1
    800038d4:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    800038d6:	00054703          	lbu	a4,0(a0)
    800038da:	02f00793          	li	a5,47
    800038de:	02f70363          	beq	a4,a5,80003904 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800038e2:	ffffe097          	auipc	ra,0xffffe
    800038e6:	e3a080e7          	jalr	-454(ra) # 8000171c <myproc>
    800038ea:	15053503          	ld	a0,336(a0)
    800038ee:	00000097          	auipc	ra,0x0
    800038f2:	a20080e7          	jalr	-1504(ra) # 8000330e <idup>
    800038f6:	89aa                	mv	s3,a0
  while(*path == '/')
    800038f8:	02f00913          	li	s2,47
  len = path - s;
    800038fc:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    800038fe:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003900:	4b85                	li	s7,1
    80003902:	a865                	j	800039ba <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003904:	4585                	li	a1,1
    80003906:	4501                	li	a0,0
    80003908:	fffff097          	auipc	ra,0xfffff
    8000390c:	710080e7          	jalr	1808(ra) # 80003018 <iget>
    80003910:	89aa                	mv	s3,a0
    80003912:	b7dd                	j	800038f8 <namex+0x42>
      iunlockput(ip);
    80003914:	854e                	mv	a0,s3
    80003916:	00000097          	auipc	ra,0x0
    8000391a:	c74080e7          	jalr	-908(ra) # 8000358a <iunlockput>
      return 0;
    8000391e:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003920:	854e                	mv	a0,s3
    80003922:	60e6                	ld	ra,88(sp)
    80003924:	6446                	ld	s0,80(sp)
    80003926:	64a6                	ld	s1,72(sp)
    80003928:	6906                	ld	s2,64(sp)
    8000392a:	79e2                	ld	s3,56(sp)
    8000392c:	7a42                	ld	s4,48(sp)
    8000392e:	7aa2                	ld	s5,40(sp)
    80003930:	7b02                	ld	s6,32(sp)
    80003932:	6be2                	ld	s7,24(sp)
    80003934:	6c42                	ld	s8,16(sp)
    80003936:	6ca2                	ld	s9,8(sp)
    80003938:	6125                	addi	sp,sp,96
    8000393a:	8082                	ret
      iunlock(ip);
    8000393c:	854e                	mv	a0,s3
    8000393e:	00000097          	auipc	ra,0x0
    80003942:	ad0080e7          	jalr	-1328(ra) # 8000340e <iunlock>
      return ip;
    80003946:	bfe9                	j	80003920 <namex+0x6a>
      iunlockput(ip);
    80003948:	854e                	mv	a0,s3
    8000394a:	00000097          	auipc	ra,0x0
    8000394e:	c40080e7          	jalr	-960(ra) # 8000358a <iunlockput>
      return 0;
    80003952:	89e6                	mv	s3,s9
    80003954:	b7f1                	j	80003920 <namex+0x6a>
  len = path - s;
    80003956:	40b48633          	sub	a2,s1,a1
    8000395a:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    8000395e:	099c5463          	bge	s8,s9,800039e6 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003962:	4639                	li	a2,14
    80003964:	8552                	mv	a0,s4
    80003966:	ffffd097          	auipc	ra,0xffffd
    8000396a:	176080e7          	jalr	374(ra) # 80000adc <memmove>
  while(*path == '/')
    8000396e:	0004c783          	lbu	a5,0(s1)
    80003972:	01279763          	bne	a5,s2,80003980 <namex+0xca>
    path++;
    80003976:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003978:	0004c783          	lbu	a5,0(s1)
    8000397c:	ff278de3          	beq	a5,s2,80003976 <namex+0xc0>
    ilock(ip);
    80003980:	854e                	mv	a0,s3
    80003982:	00000097          	auipc	ra,0x0
    80003986:	9ca080e7          	jalr	-1590(ra) # 8000334c <ilock>
    if(ip->type != T_DIR){
    8000398a:	04499783          	lh	a5,68(s3)
    8000398e:	f97793e3          	bne	a5,s7,80003914 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003992:	000a8563          	beqz	s5,8000399c <namex+0xe6>
    80003996:	0004c783          	lbu	a5,0(s1)
    8000399a:	d3cd                	beqz	a5,8000393c <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000399c:	865a                	mv	a2,s6
    8000399e:	85d2                	mv	a1,s4
    800039a0:	854e                	mv	a0,s3
    800039a2:	00000097          	auipc	ra,0x0
    800039a6:	e64080e7          	jalr	-412(ra) # 80003806 <dirlookup>
    800039aa:	8caa                	mv	s9,a0
    800039ac:	dd51                	beqz	a0,80003948 <namex+0x92>
    iunlockput(ip);
    800039ae:	854e                	mv	a0,s3
    800039b0:	00000097          	auipc	ra,0x0
    800039b4:	bda080e7          	jalr	-1062(ra) # 8000358a <iunlockput>
    ip = next;
    800039b8:	89e6                	mv	s3,s9
  while(*path == '/')
    800039ba:	0004c783          	lbu	a5,0(s1)
    800039be:	05279763          	bne	a5,s2,80003a0c <namex+0x156>
    path++;
    800039c2:	0485                	addi	s1,s1,1
  while(*path == '/')
    800039c4:	0004c783          	lbu	a5,0(s1)
    800039c8:	ff278de3          	beq	a5,s2,800039c2 <namex+0x10c>
  if(*path == 0)
    800039cc:	c79d                	beqz	a5,800039fa <namex+0x144>
    path++;
    800039ce:	85a6                	mv	a1,s1
  len = path - s;
    800039d0:	8cda                	mv	s9,s6
    800039d2:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    800039d4:	01278963          	beq	a5,s2,800039e6 <namex+0x130>
    800039d8:	dfbd                	beqz	a5,80003956 <namex+0xa0>
    path++;
    800039da:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800039dc:	0004c783          	lbu	a5,0(s1)
    800039e0:	ff279ce3          	bne	a5,s2,800039d8 <namex+0x122>
    800039e4:	bf8d                	j	80003956 <namex+0xa0>
    memmove(name, s, len);
    800039e6:	2601                	sext.w	a2,a2
    800039e8:	8552                	mv	a0,s4
    800039ea:	ffffd097          	auipc	ra,0xffffd
    800039ee:	0f2080e7          	jalr	242(ra) # 80000adc <memmove>
    name[len] = 0;
    800039f2:	9cd2                	add	s9,s9,s4
    800039f4:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800039f8:	bf9d                	j	8000396e <namex+0xb8>
  if(nameiparent){
    800039fa:	f20a83e3          	beqz	s5,80003920 <namex+0x6a>
    iput(ip);
    800039fe:	854e                	mv	a0,s3
    80003a00:	00000097          	auipc	ra,0x0
    80003a04:	a5a080e7          	jalr	-1446(ra) # 8000345a <iput>
    return 0;
    80003a08:	4981                	li	s3,0
    80003a0a:	bf19                	j	80003920 <namex+0x6a>
  if(*path == 0)
    80003a0c:	d7fd                	beqz	a5,800039fa <namex+0x144>
  while(*path != '/' && *path != 0)
    80003a0e:	0004c783          	lbu	a5,0(s1)
    80003a12:	85a6                	mv	a1,s1
    80003a14:	b7d1                	j	800039d8 <namex+0x122>

0000000080003a16 <dirlink>:
{
    80003a16:	7139                	addi	sp,sp,-64
    80003a18:	fc06                	sd	ra,56(sp)
    80003a1a:	f822                	sd	s0,48(sp)
    80003a1c:	f426                	sd	s1,40(sp)
    80003a1e:	f04a                	sd	s2,32(sp)
    80003a20:	ec4e                	sd	s3,24(sp)
    80003a22:	e852                	sd	s4,16(sp)
    80003a24:	0080                	addi	s0,sp,64
    80003a26:	892a                	mv	s2,a0
    80003a28:	8a2e                	mv	s4,a1
    80003a2a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003a2c:	4601                	li	a2,0
    80003a2e:	00000097          	auipc	ra,0x0
    80003a32:	dd8080e7          	jalr	-552(ra) # 80003806 <dirlookup>
    80003a36:	e93d                	bnez	a0,80003aac <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003a38:	04c92483          	lw	s1,76(s2)
    80003a3c:	c49d                	beqz	s1,80003a6a <dirlink+0x54>
    80003a3e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003a40:	4741                	li	a4,16
    80003a42:	86a6                	mv	a3,s1
    80003a44:	fc040613          	addi	a2,s0,-64
    80003a48:	4581                	li	a1,0
    80003a4a:	854a                	mv	a0,s2
    80003a4c:	00000097          	auipc	ra,0x0
    80003a50:	b90080e7          	jalr	-1136(ra) # 800035dc <readi>
    80003a54:	47c1                	li	a5,16
    80003a56:	06f51163          	bne	a0,a5,80003ab8 <dirlink+0xa2>
    if(de.inum == 0)
    80003a5a:	fc045783          	lhu	a5,-64(s0)
    80003a5e:	c791                	beqz	a5,80003a6a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003a60:	24c1                	addiw	s1,s1,16
    80003a62:	04c92783          	lw	a5,76(s2)
    80003a66:	fcf4ede3          	bltu	s1,a5,80003a40 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003a6a:	4639                	li	a2,14
    80003a6c:	85d2                	mv	a1,s4
    80003a6e:	fc240513          	addi	a0,s0,-62
    80003a72:	ffffd097          	auipc	ra,0xffffd
    80003a76:	122080e7          	jalr	290(ra) # 80000b94 <strncpy>
  de.inum = inum;
    80003a7a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003a7e:	4741                	li	a4,16
    80003a80:	86a6                	mv	a3,s1
    80003a82:	fc040613          	addi	a2,s0,-64
    80003a86:	4581                	li	a1,0
    80003a88:	854a                	mv	a0,s2
    80003a8a:	00000097          	auipc	ra,0x0
    80003a8e:	c46080e7          	jalr	-954(ra) # 800036d0 <writei>
    80003a92:	872a                	mv	a4,a0
    80003a94:	47c1                	li	a5,16
  return 0;
    80003a96:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003a98:	02f71863          	bne	a4,a5,80003ac8 <dirlink+0xb2>
}
    80003a9c:	70e2                	ld	ra,56(sp)
    80003a9e:	7442                	ld	s0,48(sp)
    80003aa0:	74a2                	ld	s1,40(sp)
    80003aa2:	7902                	ld	s2,32(sp)
    80003aa4:	69e2                	ld	s3,24(sp)
    80003aa6:	6a42                	ld	s4,16(sp)
    80003aa8:	6121                	addi	sp,sp,64
    80003aaa:	8082                	ret
    iput(ip);
    80003aac:	00000097          	auipc	ra,0x0
    80003ab0:	9ae080e7          	jalr	-1618(ra) # 8000345a <iput>
    return -1;
    80003ab4:	557d                	li	a0,-1
    80003ab6:	b7dd                	j	80003a9c <dirlink+0x86>
      panic("dirlink read");
    80003ab8:	00004517          	auipc	a0,0x4
    80003abc:	b1050513          	addi	a0,a0,-1264 # 800075c8 <userret+0x538>
    80003ac0:	ffffd097          	auipc	ra,0xffffd
    80003ac4:	a88080e7          	jalr	-1400(ra) # 80000548 <panic>
    panic("dirlink");
    80003ac8:	00004517          	auipc	a0,0x4
    80003acc:	cb050513          	addi	a0,a0,-848 # 80007778 <userret+0x6e8>
    80003ad0:	ffffd097          	auipc	ra,0xffffd
    80003ad4:	a78080e7          	jalr	-1416(ra) # 80000548 <panic>

0000000080003ad8 <namei>:

struct inode*
namei(char *path)
{
    80003ad8:	1101                	addi	sp,sp,-32
    80003ada:	ec06                	sd	ra,24(sp)
    80003adc:	e822                	sd	s0,16(sp)
    80003ade:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003ae0:	fe040613          	addi	a2,s0,-32
    80003ae4:	4581                	li	a1,0
    80003ae6:	00000097          	auipc	ra,0x0
    80003aea:	dd0080e7          	jalr	-560(ra) # 800038b6 <namex>
}
    80003aee:	60e2                	ld	ra,24(sp)
    80003af0:	6442                	ld	s0,16(sp)
    80003af2:	6105                	addi	sp,sp,32
    80003af4:	8082                	ret

0000000080003af6 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003af6:	1141                	addi	sp,sp,-16
    80003af8:	e406                	sd	ra,8(sp)
    80003afa:	e022                	sd	s0,0(sp)
    80003afc:	0800                	addi	s0,sp,16
    80003afe:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003b00:	4585                	li	a1,1
    80003b02:	00000097          	auipc	ra,0x0
    80003b06:	db4080e7          	jalr	-588(ra) # 800038b6 <namex>
}
    80003b0a:	60a2                	ld	ra,8(sp)
    80003b0c:	6402                	ld	s0,0(sp)
    80003b0e:	0141                	addi	sp,sp,16
    80003b10:	8082                	ret

0000000080003b12 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(int dev)
{
    80003b12:	7179                	addi	sp,sp,-48
    80003b14:	f406                	sd	ra,40(sp)
    80003b16:	f022                	sd	s0,32(sp)
    80003b18:	ec26                	sd	s1,24(sp)
    80003b1a:	e84a                	sd	s2,16(sp)
    80003b1c:	e44e                	sd	s3,8(sp)
    80003b1e:	1800                	addi	s0,sp,48
    80003b20:	84aa                	mv	s1,a0
  struct buf *buf = bread(dev, log[dev].start);
    80003b22:	0a800993          	li	s3,168
    80003b26:	033507b3          	mul	a5,a0,s3
    80003b2a:	0001e997          	auipc	s3,0x1e
    80003b2e:	e4e98993          	addi	s3,s3,-434 # 80021978 <log>
    80003b32:	99be                	add	s3,s3,a5
    80003b34:	0189a583          	lw	a1,24(s3)
    80003b38:	fffff097          	auipc	ra,0xfffff
    80003b3c:	00c080e7          	jalr	12(ra) # 80002b44 <bread>
    80003b40:	892a                	mv	s2,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log[dev].lh.n;
    80003b42:	02c9a783          	lw	a5,44(s3)
    80003b46:	d13c                	sw	a5,96(a0)
  for (i = 0; i < log[dev].lh.n; i++) {
    80003b48:	02c9a783          	lw	a5,44(s3)
    80003b4c:	02f05763          	blez	a5,80003b7a <write_head+0x68>
    80003b50:	0a800793          	li	a5,168
    80003b54:	02f487b3          	mul	a5,s1,a5
    80003b58:	0001e717          	auipc	a4,0x1e
    80003b5c:	e5070713          	addi	a4,a4,-432 # 800219a8 <log+0x30>
    80003b60:	97ba                	add	a5,a5,a4
    80003b62:	06450693          	addi	a3,a0,100
    80003b66:	4701                	li	a4,0
    80003b68:	85ce                	mv	a1,s3
    hb->block[i] = log[dev].lh.block[i];
    80003b6a:	4390                	lw	a2,0(a5)
    80003b6c:	c290                	sw	a2,0(a3)
  for (i = 0; i < log[dev].lh.n; i++) {
    80003b6e:	2705                	addiw	a4,a4,1
    80003b70:	0791                	addi	a5,a5,4
    80003b72:	0691                	addi	a3,a3,4
    80003b74:	55d0                	lw	a2,44(a1)
    80003b76:	fec74ae3          	blt	a4,a2,80003b6a <write_head+0x58>
  }
  bwrite(buf);
    80003b7a:	854a                	mv	a0,s2
    80003b7c:	fffff097          	auipc	ra,0xfffff
    80003b80:	0bc080e7          	jalr	188(ra) # 80002c38 <bwrite>
  brelse(buf);
    80003b84:	854a                	mv	a0,s2
    80003b86:	fffff097          	auipc	ra,0xfffff
    80003b8a:	0f2080e7          	jalr	242(ra) # 80002c78 <brelse>
}
    80003b8e:	70a2                	ld	ra,40(sp)
    80003b90:	7402                	ld	s0,32(sp)
    80003b92:	64e2                	ld	s1,24(sp)
    80003b94:	6942                	ld	s2,16(sp)
    80003b96:	69a2                	ld	s3,8(sp)
    80003b98:	6145                	addi	sp,sp,48
    80003b9a:	8082                	ret

0000000080003b9c <write_log>:
static void
write_log(int dev)
{
  int tail;

  for (tail = 0; tail < log[dev].lh.n; tail++) {
    80003b9c:	0a800793          	li	a5,168
    80003ba0:	02f50733          	mul	a4,a0,a5
    80003ba4:	0001e797          	auipc	a5,0x1e
    80003ba8:	dd478793          	addi	a5,a5,-556 # 80021978 <log>
    80003bac:	97ba                	add	a5,a5,a4
    80003bae:	57dc                	lw	a5,44(a5)
    80003bb0:	0af05663          	blez	a5,80003c5c <write_log+0xc0>
{
    80003bb4:	7139                	addi	sp,sp,-64
    80003bb6:	fc06                	sd	ra,56(sp)
    80003bb8:	f822                	sd	s0,48(sp)
    80003bba:	f426                	sd	s1,40(sp)
    80003bbc:	f04a                	sd	s2,32(sp)
    80003bbe:	ec4e                	sd	s3,24(sp)
    80003bc0:	e852                	sd	s4,16(sp)
    80003bc2:	e456                	sd	s5,8(sp)
    80003bc4:	e05a                	sd	s6,0(sp)
    80003bc6:	0080                	addi	s0,sp,64
    80003bc8:	0001e797          	auipc	a5,0x1e
    80003bcc:	de078793          	addi	a5,a5,-544 # 800219a8 <log+0x30>
    80003bd0:	00f70a33          	add	s4,a4,a5
  for (tail = 0; tail < log[dev].lh.n; tail++) {
    80003bd4:	4981                	li	s3,0
    struct buf *to = bread(dev, log[dev].start+tail+1); // log block
    80003bd6:	00050b1b          	sext.w	s6,a0
    80003bda:	0001ea97          	auipc	s5,0x1e
    80003bde:	d9ea8a93          	addi	s5,s5,-610 # 80021978 <log>
    80003be2:	9aba                	add	s5,s5,a4
    80003be4:	018aa583          	lw	a1,24(s5)
    80003be8:	013585bb          	addw	a1,a1,s3
    80003bec:	2585                	addiw	a1,a1,1
    80003bee:	855a                	mv	a0,s6
    80003bf0:	fffff097          	auipc	ra,0xfffff
    80003bf4:	f54080e7          	jalr	-172(ra) # 80002b44 <bread>
    80003bf8:	84aa                	mv	s1,a0
    struct buf *from = bread(dev, log[dev].lh.block[tail]); // cache block
    80003bfa:	000a2583          	lw	a1,0(s4)
    80003bfe:	855a                	mv	a0,s6
    80003c00:	fffff097          	auipc	ra,0xfffff
    80003c04:	f44080e7          	jalr	-188(ra) # 80002b44 <bread>
    80003c08:	892a                	mv	s2,a0
    memmove(to->data, from->data, BSIZE);
    80003c0a:	40000613          	li	a2,1024
    80003c0e:	06050593          	addi	a1,a0,96
    80003c12:	06048513          	addi	a0,s1,96
    80003c16:	ffffd097          	auipc	ra,0xffffd
    80003c1a:	ec6080e7          	jalr	-314(ra) # 80000adc <memmove>
    bwrite(to);  // write the log
    80003c1e:	8526                	mv	a0,s1
    80003c20:	fffff097          	auipc	ra,0xfffff
    80003c24:	018080e7          	jalr	24(ra) # 80002c38 <bwrite>
    brelse(from);
    80003c28:	854a                	mv	a0,s2
    80003c2a:	fffff097          	auipc	ra,0xfffff
    80003c2e:	04e080e7          	jalr	78(ra) # 80002c78 <brelse>
    brelse(to);
    80003c32:	8526                	mv	a0,s1
    80003c34:	fffff097          	auipc	ra,0xfffff
    80003c38:	044080e7          	jalr	68(ra) # 80002c78 <brelse>
  for (tail = 0; tail < log[dev].lh.n; tail++) {
    80003c3c:	2985                	addiw	s3,s3,1
    80003c3e:	0a11                	addi	s4,s4,4
    80003c40:	02caa783          	lw	a5,44(s5)
    80003c44:	faf9c0e3          	blt	s3,a5,80003be4 <write_log+0x48>
  }
}
    80003c48:	70e2                	ld	ra,56(sp)
    80003c4a:	7442                	ld	s0,48(sp)
    80003c4c:	74a2                	ld	s1,40(sp)
    80003c4e:	7902                	ld	s2,32(sp)
    80003c50:	69e2                	ld	s3,24(sp)
    80003c52:	6a42                	ld	s4,16(sp)
    80003c54:	6aa2                	ld	s5,8(sp)
    80003c56:	6b02                	ld	s6,0(sp)
    80003c58:	6121                	addi	sp,sp,64
    80003c5a:	8082                	ret
    80003c5c:	8082                	ret

0000000080003c5e <install_trans>:
  for (tail = 0; tail < log[dev].lh.n; tail++) {
    80003c5e:	0a800793          	li	a5,168
    80003c62:	02f50733          	mul	a4,a0,a5
    80003c66:	0001e797          	auipc	a5,0x1e
    80003c6a:	d1278793          	addi	a5,a5,-750 # 80021978 <log>
    80003c6e:	97ba                	add	a5,a5,a4
    80003c70:	57dc                	lw	a5,44(a5)
    80003c72:	0af05b63          	blez	a5,80003d28 <install_trans+0xca>
{
    80003c76:	7139                	addi	sp,sp,-64
    80003c78:	fc06                	sd	ra,56(sp)
    80003c7a:	f822                	sd	s0,48(sp)
    80003c7c:	f426                	sd	s1,40(sp)
    80003c7e:	f04a                	sd	s2,32(sp)
    80003c80:	ec4e                	sd	s3,24(sp)
    80003c82:	e852                	sd	s4,16(sp)
    80003c84:	e456                	sd	s5,8(sp)
    80003c86:	e05a                	sd	s6,0(sp)
    80003c88:	0080                	addi	s0,sp,64
    80003c8a:	0001e797          	auipc	a5,0x1e
    80003c8e:	d1e78793          	addi	a5,a5,-738 # 800219a8 <log+0x30>
    80003c92:	00f70a33          	add	s4,a4,a5
  for (tail = 0; tail < log[dev].lh.n; tail++) {
    80003c96:	4981                	li	s3,0
    struct buf *lbuf = bread(dev, log[dev].start+tail+1); // read log block
    80003c98:	00050b1b          	sext.w	s6,a0
    80003c9c:	0001ea97          	auipc	s5,0x1e
    80003ca0:	cdca8a93          	addi	s5,s5,-804 # 80021978 <log>
    80003ca4:	9aba                	add	s5,s5,a4
    80003ca6:	018aa583          	lw	a1,24(s5)
    80003caa:	013585bb          	addw	a1,a1,s3
    80003cae:	2585                	addiw	a1,a1,1
    80003cb0:	855a                	mv	a0,s6
    80003cb2:	fffff097          	auipc	ra,0xfffff
    80003cb6:	e92080e7          	jalr	-366(ra) # 80002b44 <bread>
    80003cba:	892a                	mv	s2,a0
    struct buf *dbuf = bread(dev, log[dev].lh.block[tail]); // read dst
    80003cbc:	000a2583          	lw	a1,0(s4)
    80003cc0:	855a                	mv	a0,s6
    80003cc2:	fffff097          	auipc	ra,0xfffff
    80003cc6:	e82080e7          	jalr	-382(ra) # 80002b44 <bread>
    80003cca:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003ccc:	40000613          	li	a2,1024
    80003cd0:	06090593          	addi	a1,s2,96
    80003cd4:	06050513          	addi	a0,a0,96
    80003cd8:	ffffd097          	auipc	ra,0xffffd
    80003cdc:	e04080e7          	jalr	-508(ra) # 80000adc <memmove>
    bwrite(dbuf);  // write dst to disk
    80003ce0:	8526                	mv	a0,s1
    80003ce2:	fffff097          	auipc	ra,0xfffff
    80003ce6:	f56080e7          	jalr	-170(ra) # 80002c38 <bwrite>
    bunpin(dbuf);
    80003cea:	8526                	mv	a0,s1
    80003cec:	fffff097          	auipc	ra,0xfffff
    80003cf0:	066080e7          	jalr	102(ra) # 80002d52 <bunpin>
    brelse(lbuf);
    80003cf4:	854a                	mv	a0,s2
    80003cf6:	fffff097          	auipc	ra,0xfffff
    80003cfa:	f82080e7          	jalr	-126(ra) # 80002c78 <brelse>
    brelse(dbuf);
    80003cfe:	8526                	mv	a0,s1
    80003d00:	fffff097          	auipc	ra,0xfffff
    80003d04:	f78080e7          	jalr	-136(ra) # 80002c78 <brelse>
  for (tail = 0; tail < log[dev].lh.n; tail++) {
    80003d08:	2985                	addiw	s3,s3,1
    80003d0a:	0a11                	addi	s4,s4,4
    80003d0c:	02caa783          	lw	a5,44(s5)
    80003d10:	f8f9cbe3          	blt	s3,a5,80003ca6 <install_trans+0x48>
}
    80003d14:	70e2                	ld	ra,56(sp)
    80003d16:	7442                	ld	s0,48(sp)
    80003d18:	74a2                	ld	s1,40(sp)
    80003d1a:	7902                	ld	s2,32(sp)
    80003d1c:	69e2                	ld	s3,24(sp)
    80003d1e:	6a42                	ld	s4,16(sp)
    80003d20:	6aa2                	ld	s5,8(sp)
    80003d22:	6b02                	ld	s6,0(sp)
    80003d24:	6121                	addi	sp,sp,64
    80003d26:	8082                	ret
    80003d28:	8082                	ret

0000000080003d2a <initlog>:
{
    80003d2a:	7179                	addi	sp,sp,-48
    80003d2c:	f406                	sd	ra,40(sp)
    80003d2e:	f022                	sd	s0,32(sp)
    80003d30:	ec26                	sd	s1,24(sp)
    80003d32:	e84a                	sd	s2,16(sp)
    80003d34:	e44e                	sd	s3,8(sp)
    80003d36:	e052                	sd	s4,0(sp)
    80003d38:	1800                	addi	s0,sp,48
    80003d3a:	892a                	mv	s2,a0
    80003d3c:	8a2e                	mv	s4,a1
  initlock(&log[dev].lock, "log");
    80003d3e:	0a800713          	li	a4,168
    80003d42:	02e504b3          	mul	s1,a0,a4
    80003d46:	0001e997          	auipc	s3,0x1e
    80003d4a:	c3298993          	addi	s3,s3,-974 # 80021978 <log>
    80003d4e:	99a6                	add	s3,s3,s1
    80003d50:	00004597          	auipc	a1,0x4
    80003d54:	88858593          	addi	a1,a1,-1912 # 800075d8 <userret+0x548>
    80003d58:	854e                	mv	a0,s3
    80003d5a:	ffffd097          	auipc	ra,0xffffd
    80003d5e:	b54080e7          	jalr	-1196(ra) # 800008ae <initlock>
  log[dev].start = sb->logstart;
    80003d62:	014a2583          	lw	a1,20(s4)
    80003d66:	00b9ac23          	sw	a1,24(s3)
  log[dev].size = sb->nlog;
    80003d6a:	010a2783          	lw	a5,16(s4)
    80003d6e:	00f9ae23          	sw	a5,28(s3)
  log[dev].dev = dev;
    80003d72:	0329a423          	sw	s2,40(s3)
  struct buf *buf = bread(dev, log[dev].start);
    80003d76:	854a                	mv	a0,s2
    80003d78:	fffff097          	auipc	ra,0xfffff
    80003d7c:	dcc080e7          	jalr	-564(ra) # 80002b44 <bread>
  log[dev].lh.n = lh->n;
    80003d80:	5134                	lw	a3,96(a0)
    80003d82:	02d9a623          	sw	a3,44(s3)
  for (i = 0; i < log[dev].lh.n; i++) {
    80003d86:	02d05763          	blez	a3,80003db4 <initlog+0x8a>
    80003d8a:	06450793          	addi	a5,a0,100
    80003d8e:	0001e717          	auipc	a4,0x1e
    80003d92:	c1a70713          	addi	a4,a4,-998 # 800219a8 <log+0x30>
    80003d96:	9726                	add	a4,a4,s1
    80003d98:	36fd                	addiw	a3,a3,-1
    80003d9a:	02069613          	slli	a2,a3,0x20
    80003d9e:	01e65693          	srli	a3,a2,0x1e
    80003da2:	06850613          	addi	a2,a0,104
    80003da6:	96b2                	add	a3,a3,a2
    log[dev].lh.block[i] = lh->block[i];
    80003da8:	4390                	lw	a2,0(a5)
    80003daa:	c310                	sw	a2,0(a4)
  for (i = 0; i < log[dev].lh.n; i++) {
    80003dac:	0791                	addi	a5,a5,4
    80003dae:	0711                	addi	a4,a4,4
    80003db0:	fed79ce3          	bne	a5,a3,80003da8 <initlog+0x7e>
  brelse(buf);
    80003db4:	fffff097          	auipc	ra,0xfffff
    80003db8:	ec4080e7          	jalr	-316(ra) # 80002c78 <brelse>
  install_trans(dev); // if committed, copy from log to disk
    80003dbc:	854a                	mv	a0,s2
    80003dbe:	00000097          	auipc	ra,0x0
    80003dc2:	ea0080e7          	jalr	-352(ra) # 80003c5e <install_trans>
  log[dev].lh.n = 0;
    80003dc6:	0a800793          	li	a5,168
    80003dca:	02f90733          	mul	a4,s2,a5
    80003dce:	0001e797          	auipc	a5,0x1e
    80003dd2:	baa78793          	addi	a5,a5,-1110 # 80021978 <log>
    80003dd6:	97ba                	add	a5,a5,a4
    80003dd8:	0207a623          	sw	zero,44(a5)
  write_head(dev); // clear the log
    80003ddc:	854a                	mv	a0,s2
    80003dde:	00000097          	auipc	ra,0x0
    80003de2:	d34080e7          	jalr	-716(ra) # 80003b12 <write_head>
}
    80003de6:	70a2                	ld	ra,40(sp)
    80003de8:	7402                	ld	s0,32(sp)
    80003dea:	64e2                	ld	s1,24(sp)
    80003dec:	6942                	ld	s2,16(sp)
    80003dee:	69a2                	ld	s3,8(sp)
    80003df0:	6a02                	ld	s4,0(sp)
    80003df2:	6145                	addi	sp,sp,48
    80003df4:	8082                	ret

0000000080003df6 <begin_op>:
{
    80003df6:	7139                	addi	sp,sp,-64
    80003df8:	fc06                	sd	ra,56(sp)
    80003dfa:	f822                	sd	s0,48(sp)
    80003dfc:	f426                	sd	s1,40(sp)
    80003dfe:	f04a                	sd	s2,32(sp)
    80003e00:	ec4e                	sd	s3,24(sp)
    80003e02:	e852                	sd	s4,16(sp)
    80003e04:	e456                	sd	s5,8(sp)
    80003e06:	0080                	addi	s0,sp,64
    80003e08:	8aaa                	mv	s5,a0
  acquire(&log[dev].lock);
    80003e0a:	0a800913          	li	s2,168
    80003e0e:	032507b3          	mul	a5,a0,s2
    80003e12:	0001e917          	auipc	s2,0x1e
    80003e16:	b6690913          	addi	s2,s2,-1178 # 80021978 <log>
    80003e1a:	993e                	add	s2,s2,a5
    80003e1c:	854a                	mv	a0,s2
    80003e1e:	ffffd097          	auipc	ra,0xffffd
    80003e22:	b9e080e7          	jalr	-1122(ra) # 800009bc <acquire>
    if(log[dev].committing){
    80003e26:	0001e997          	auipc	s3,0x1e
    80003e2a:	b5298993          	addi	s3,s3,-1198 # 80021978 <log>
    80003e2e:	84ca                	mv	s1,s2
    } else if(log[dev].lh.n + (log[dev].outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80003e30:	4a79                	li	s4,30
    80003e32:	a039                	j	80003e40 <begin_op+0x4a>
      sleep(&log, &log[dev].lock);
    80003e34:	85ca                	mv	a1,s2
    80003e36:	854e                	mv	a0,s3
    80003e38:	ffffe097          	auipc	ra,0xffffe
    80003e3c:	0fa080e7          	jalr	250(ra) # 80001f32 <sleep>
    if(log[dev].committing){
    80003e40:	50dc                	lw	a5,36(s1)
    80003e42:	fbed                	bnez	a5,80003e34 <begin_op+0x3e>
    } else if(log[dev].lh.n + (log[dev].outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80003e44:	509c                	lw	a5,32(s1)
    80003e46:	0017871b          	addiw	a4,a5,1
    80003e4a:	0007069b          	sext.w	a3,a4
    80003e4e:	0027179b          	slliw	a5,a4,0x2
    80003e52:	9fb9                	addw	a5,a5,a4
    80003e54:	0017979b          	slliw	a5,a5,0x1
    80003e58:	54d8                	lw	a4,44(s1)
    80003e5a:	9fb9                	addw	a5,a5,a4
    80003e5c:	00fa5963          	bge	s4,a5,80003e6e <begin_op+0x78>
      sleep(&log, &log[dev].lock);
    80003e60:	85ca                	mv	a1,s2
    80003e62:	854e                	mv	a0,s3
    80003e64:	ffffe097          	auipc	ra,0xffffe
    80003e68:	0ce080e7          	jalr	206(ra) # 80001f32 <sleep>
    80003e6c:	bfd1                	j	80003e40 <begin_op+0x4a>
      log[dev].outstanding += 1;
    80003e6e:	0a800513          	li	a0,168
    80003e72:	02aa8ab3          	mul	s5,s5,a0
    80003e76:	0001e797          	auipc	a5,0x1e
    80003e7a:	b0278793          	addi	a5,a5,-1278 # 80021978 <log>
    80003e7e:	9abe                	add	s5,s5,a5
    80003e80:	02daa023          	sw	a3,32(s5)
      release(&log[dev].lock);
    80003e84:	854a                	mv	a0,s2
    80003e86:	ffffd097          	auipc	ra,0xffffd
    80003e8a:	b9e080e7          	jalr	-1122(ra) # 80000a24 <release>
}
    80003e8e:	70e2                	ld	ra,56(sp)
    80003e90:	7442                	ld	s0,48(sp)
    80003e92:	74a2                	ld	s1,40(sp)
    80003e94:	7902                	ld	s2,32(sp)
    80003e96:	69e2                	ld	s3,24(sp)
    80003e98:	6a42                	ld	s4,16(sp)
    80003e9a:	6aa2                	ld	s5,8(sp)
    80003e9c:	6121                	addi	sp,sp,64
    80003e9e:	8082                	ret

0000000080003ea0 <end_op>:
{
    80003ea0:	7179                	addi	sp,sp,-48
    80003ea2:	f406                	sd	ra,40(sp)
    80003ea4:	f022                	sd	s0,32(sp)
    80003ea6:	ec26                	sd	s1,24(sp)
    80003ea8:	e84a                	sd	s2,16(sp)
    80003eaa:	e44e                	sd	s3,8(sp)
    80003eac:	1800                	addi	s0,sp,48
    80003eae:	892a                	mv	s2,a0
  acquire(&log[dev].lock);
    80003eb0:	0a800493          	li	s1,168
    80003eb4:	029507b3          	mul	a5,a0,s1
    80003eb8:	0001e497          	auipc	s1,0x1e
    80003ebc:	ac048493          	addi	s1,s1,-1344 # 80021978 <log>
    80003ec0:	94be                	add	s1,s1,a5
    80003ec2:	8526                	mv	a0,s1
    80003ec4:	ffffd097          	auipc	ra,0xffffd
    80003ec8:	af8080e7          	jalr	-1288(ra) # 800009bc <acquire>
  log[dev].outstanding -= 1;
    80003ecc:	509c                	lw	a5,32(s1)
    80003ece:	37fd                	addiw	a5,a5,-1
    80003ed0:	0007871b          	sext.w	a4,a5
    80003ed4:	d09c                	sw	a5,32(s1)
  if(log[dev].committing)
    80003ed6:	50dc                	lw	a5,36(s1)
    80003ed8:	e3ad                	bnez	a5,80003f3a <end_op+0x9a>
  if(log[dev].outstanding == 0){
    80003eda:	eb25                	bnez	a4,80003f4a <end_op+0xaa>
    log[dev].committing = 1;
    80003edc:	0a800993          	li	s3,168
    80003ee0:	033907b3          	mul	a5,s2,s3
    80003ee4:	0001e997          	auipc	s3,0x1e
    80003ee8:	a9498993          	addi	s3,s3,-1388 # 80021978 <log>
    80003eec:	99be                	add	s3,s3,a5
    80003eee:	4785                	li	a5,1
    80003ef0:	02f9a223          	sw	a5,36(s3)
  release(&log[dev].lock);
    80003ef4:	8526                	mv	a0,s1
    80003ef6:	ffffd097          	auipc	ra,0xffffd
    80003efa:	b2e080e7          	jalr	-1234(ra) # 80000a24 <release>

static void
commit(int dev)
{
  if (log[dev].lh.n > 0) {
    80003efe:	02c9a783          	lw	a5,44(s3)
    80003f02:	06f04863          	bgtz	a5,80003f72 <end_op+0xd2>
    acquire(&log[dev].lock);
    80003f06:	8526                	mv	a0,s1
    80003f08:	ffffd097          	auipc	ra,0xffffd
    80003f0c:	ab4080e7          	jalr	-1356(ra) # 800009bc <acquire>
    log[dev].committing = 0;
    80003f10:	0001e517          	auipc	a0,0x1e
    80003f14:	a6850513          	addi	a0,a0,-1432 # 80021978 <log>
    80003f18:	0a800793          	li	a5,168
    80003f1c:	02f90933          	mul	s2,s2,a5
    80003f20:	992a                	add	s2,s2,a0
    80003f22:	02092223          	sw	zero,36(s2)
    wakeup(&log);
    80003f26:	ffffe097          	auipc	ra,0xffffe
    80003f2a:	18c080e7          	jalr	396(ra) # 800020b2 <wakeup>
    release(&log[dev].lock);
    80003f2e:	8526                	mv	a0,s1
    80003f30:	ffffd097          	auipc	ra,0xffffd
    80003f34:	af4080e7          	jalr	-1292(ra) # 80000a24 <release>
}
    80003f38:	a035                	j	80003f64 <end_op+0xc4>
    panic("log[dev].committing");
    80003f3a:	00003517          	auipc	a0,0x3
    80003f3e:	6a650513          	addi	a0,a0,1702 # 800075e0 <userret+0x550>
    80003f42:	ffffc097          	auipc	ra,0xffffc
    80003f46:	606080e7          	jalr	1542(ra) # 80000548 <panic>
    wakeup(&log);
    80003f4a:	0001e517          	auipc	a0,0x1e
    80003f4e:	a2e50513          	addi	a0,a0,-1490 # 80021978 <log>
    80003f52:	ffffe097          	auipc	ra,0xffffe
    80003f56:	160080e7          	jalr	352(ra) # 800020b2 <wakeup>
  release(&log[dev].lock);
    80003f5a:	8526                	mv	a0,s1
    80003f5c:	ffffd097          	auipc	ra,0xffffd
    80003f60:	ac8080e7          	jalr	-1336(ra) # 80000a24 <release>
}
    80003f64:	70a2                	ld	ra,40(sp)
    80003f66:	7402                	ld	s0,32(sp)
    80003f68:	64e2                	ld	s1,24(sp)
    80003f6a:	6942                	ld	s2,16(sp)
    80003f6c:	69a2                	ld	s3,8(sp)
    80003f6e:	6145                	addi	sp,sp,48
    80003f70:	8082                	ret
    write_log(dev);     // Write modified blocks from cache to log
    80003f72:	854a                	mv	a0,s2
    80003f74:	00000097          	auipc	ra,0x0
    80003f78:	c28080e7          	jalr	-984(ra) # 80003b9c <write_log>
    write_head(dev);    // Write header to disk -- the real commit
    80003f7c:	854a                	mv	a0,s2
    80003f7e:	00000097          	auipc	ra,0x0
    80003f82:	b94080e7          	jalr	-1132(ra) # 80003b12 <write_head>
    install_trans(dev); // Now install writes to home locations
    80003f86:	854a                	mv	a0,s2
    80003f88:	00000097          	auipc	ra,0x0
    80003f8c:	cd6080e7          	jalr	-810(ra) # 80003c5e <install_trans>
    log[dev].lh.n = 0;
    80003f90:	0a800793          	li	a5,168
    80003f94:	02f90733          	mul	a4,s2,a5
    80003f98:	0001e797          	auipc	a5,0x1e
    80003f9c:	9e078793          	addi	a5,a5,-1568 # 80021978 <log>
    80003fa0:	97ba                	add	a5,a5,a4
    80003fa2:	0207a623          	sw	zero,44(a5)
    write_head(dev);    // Erase the transaction from the log
    80003fa6:	854a                	mv	a0,s2
    80003fa8:	00000097          	auipc	ra,0x0
    80003fac:	b6a080e7          	jalr	-1174(ra) # 80003b12 <write_head>
    80003fb0:	bf99                	j	80003f06 <end_op+0x66>

0000000080003fb2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80003fb2:	7179                	addi	sp,sp,-48
    80003fb4:	f406                	sd	ra,40(sp)
    80003fb6:	f022                	sd	s0,32(sp)
    80003fb8:	ec26                	sd	s1,24(sp)
    80003fba:	e84a                	sd	s2,16(sp)
    80003fbc:	e44e                	sd	s3,8(sp)
    80003fbe:	e052                	sd	s4,0(sp)
    80003fc0:	1800                	addi	s0,sp,48
  int i;

  int dev = b->dev;
    80003fc2:	00852903          	lw	s2,8(a0)
  if (log[dev].lh.n >= LOGSIZE || log[dev].lh.n >= log[dev].size - 1)
    80003fc6:	0a800793          	li	a5,168
    80003fca:	02f90733          	mul	a4,s2,a5
    80003fce:	0001e797          	auipc	a5,0x1e
    80003fd2:	9aa78793          	addi	a5,a5,-1622 # 80021978 <log>
    80003fd6:	97ba                	add	a5,a5,a4
    80003fd8:	57d4                	lw	a3,44(a5)
    80003fda:	47f5                	li	a5,29
    80003fdc:	0ad7cc63          	blt	a5,a3,80004094 <log_write+0xe2>
    80003fe0:	89aa                	mv	s3,a0
    80003fe2:	0001e797          	auipc	a5,0x1e
    80003fe6:	99678793          	addi	a5,a5,-1642 # 80021978 <log>
    80003fea:	97ba                	add	a5,a5,a4
    80003fec:	4fdc                	lw	a5,28(a5)
    80003fee:	37fd                	addiw	a5,a5,-1
    80003ff0:	0af6d263          	bge	a3,a5,80004094 <log_write+0xe2>
    panic("too big a transaction");
  if (log[dev].outstanding < 1)
    80003ff4:	0a800793          	li	a5,168
    80003ff8:	02f90733          	mul	a4,s2,a5
    80003ffc:	0001e797          	auipc	a5,0x1e
    80004000:	97c78793          	addi	a5,a5,-1668 # 80021978 <log>
    80004004:	97ba                	add	a5,a5,a4
    80004006:	539c                	lw	a5,32(a5)
    80004008:	08f05e63          	blez	a5,800040a4 <log_write+0xf2>
    panic("log_write outside of trans");

  acquire(&log[dev].lock);
    8000400c:	0a800793          	li	a5,168
    80004010:	02f904b3          	mul	s1,s2,a5
    80004014:	0001ea17          	auipc	s4,0x1e
    80004018:	964a0a13          	addi	s4,s4,-1692 # 80021978 <log>
    8000401c:	9a26                	add	s4,s4,s1
    8000401e:	8552                	mv	a0,s4
    80004020:	ffffd097          	auipc	ra,0xffffd
    80004024:	99c080e7          	jalr	-1636(ra) # 800009bc <acquire>
  for (i = 0; i < log[dev].lh.n; i++) {
    80004028:	02ca2603          	lw	a2,44(s4)
    8000402c:	08c05463          	blez	a2,800040b4 <log_write+0x102>
    if (log[dev].lh.block[i] == b->blockno)   // log absorbtion
    80004030:	00c9a583          	lw	a1,12(s3)
    80004034:	0001e797          	auipc	a5,0x1e
    80004038:	97478793          	addi	a5,a5,-1676 # 800219a8 <log+0x30>
    8000403c:	97a6                	add	a5,a5,s1
  for (i = 0; i < log[dev].lh.n; i++) {
    8000403e:	4701                	li	a4,0
    if (log[dev].lh.block[i] == b->blockno)   // log absorbtion
    80004040:	4394                	lw	a3,0(a5)
    80004042:	06b68a63          	beq	a3,a1,800040b6 <log_write+0x104>
  for (i = 0; i < log[dev].lh.n; i++) {
    80004046:	2705                	addiw	a4,a4,1
    80004048:	0791                	addi	a5,a5,4
    8000404a:	fec71be3          	bne	a4,a2,80004040 <log_write+0x8e>
      break;
  }
  log[dev].lh.block[i] = b->blockno;
    8000404e:	02a00793          	li	a5,42
    80004052:	02f907b3          	mul	a5,s2,a5
    80004056:	97b2                	add	a5,a5,a2
    80004058:	07a1                	addi	a5,a5,8
    8000405a:	078a                	slli	a5,a5,0x2
    8000405c:	0001e717          	auipc	a4,0x1e
    80004060:	91c70713          	addi	a4,a4,-1764 # 80021978 <log>
    80004064:	97ba                	add	a5,a5,a4
    80004066:	00c9a703          	lw	a4,12(s3)
    8000406a:	cb98                	sw	a4,16(a5)
  if (i == log[dev].lh.n) {  // Add new block to log?
    bpin(b);
    8000406c:	854e                	mv	a0,s3
    8000406e:	fffff097          	auipc	ra,0xfffff
    80004072:	ca8080e7          	jalr	-856(ra) # 80002d16 <bpin>
    log[dev].lh.n++;
    80004076:	0a800793          	li	a5,168
    8000407a:	02f90933          	mul	s2,s2,a5
    8000407e:	0001e797          	auipc	a5,0x1e
    80004082:	8fa78793          	addi	a5,a5,-1798 # 80021978 <log>
    80004086:	993e                	add	s2,s2,a5
    80004088:	02c92783          	lw	a5,44(s2)
    8000408c:	2785                	addiw	a5,a5,1
    8000408e:	02f92623          	sw	a5,44(s2)
    80004092:	a099                	j	800040d8 <log_write+0x126>
    panic("too big a transaction");
    80004094:	00003517          	auipc	a0,0x3
    80004098:	56450513          	addi	a0,a0,1380 # 800075f8 <userret+0x568>
    8000409c:	ffffc097          	auipc	ra,0xffffc
    800040a0:	4ac080e7          	jalr	1196(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    800040a4:	00003517          	auipc	a0,0x3
    800040a8:	56c50513          	addi	a0,a0,1388 # 80007610 <userret+0x580>
    800040ac:	ffffc097          	auipc	ra,0xffffc
    800040b0:	49c080e7          	jalr	1180(ra) # 80000548 <panic>
  for (i = 0; i < log[dev].lh.n; i++) {
    800040b4:	4701                	li	a4,0
  log[dev].lh.block[i] = b->blockno;
    800040b6:	02a00793          	li	a5,42
    800040ba:	02f907b3          	mul	a5,s2,a5
    800040be:	97ba                	add	a5,a5,a4
    800040c0:	07a1                	addi	a5,a5,8
    800040c2:	078a                	slli	a5,a5,0x2
    800040c4:	0001e697          	auipc	a3,0x1e
    800040c8:	8b468693          	addi	a3,a3,-1868 # 80021978 <log>
    800040cc:	97b6                	add	a5,a5,a3
    800040ce:	00c9a683          	lw	a3,12(s3)
    800040d2:	cb94                	sw	a3,16(a5)
  if (i == log[dev].lh.n) {  // Add new block to log?
    800040d4:	f8e60ce3          	beq	a2,a4,8000406c <log_write+0xba>
  }
  release(&log[dev].lock);
    800040d8:	8552                	mv	a0,s4
    800040da:	ffffd097          	auipc	ra,0xffffd
    800040de:	94a080e7          	jalr	-1718(ra) # 80000a24 <release>
}
    800040e2:	70a2                	ld	ra,40(sp)
    800040e4:	7402                	ld	s0,32(sp)
    800040e6:	64e2                	ld	s1,24(sp)
    800040e8:	6942                	ld	s2,16(sp)
    800040ea:	69a2                	ld	s3,8(sp)
    800040ec:	6a02                	ld	s4,0(sp)
    800040ee:	6145                	addi	sp,sp,48
    800040f0:	8082                	ret

00000000800040f2 <crash_op>:

// crash before commit or after commit
void
crash_op(int dev, int docommit)
{
    800040f2:	7179                	addi	sp,sp,-48
    800040f4:	f406                	sd	ra,40(sp)
    800040f6:	f022                	sd	s0,32(sp)
    800040f8:	ec26                	sd	s1,24(sp)
    800040fa:	e84a                	sd	s2,16(sp)
    800040fc:	e44e                	sd	s3,8(sp)
    800040fe:	1800                	addi	s0,sp,48
    80004100:	84aa                	mv	s1,a0
    80004102:	89ae                	mv	s3,a1
  int do_commit = 0;
    
  acquire(&log[dev].lock);
    80004104:	0a800913          	li	s2,168
    80004108:	032507b3          	mul	a5,a0,s2
    8000410c:	0001e917          	auipc	s2,0x1e
    80004110:	86c90913          	addi	s2,s2,-1940 # 80021978 <log>
    80004114:	993e                	add	s2,s2,a5
    80004116:	854a                	mv	a0,s2
    80004118:	ffffd097          	auipc	ra,0xffffd
    8000411c:	8a4080e7          	jalr	-1884(ra) # 800009bc <acquire>

  if (dev < 0 || dev >= NDISK)
    80004120:	0004871b          	sext.w	a4,s1
    80004124:	4785                	li	a5,1
    80004126:	0ae7e063          	bltu	a5,a4,800041c6 <crash_op+0xd4>
    panic("end_op: invalid disk");
  if(log[dev].outstanding == 0)
    8000412a:	0a800793          	li	a5,168
    8000412e:	02f48733          	mul	a4,s1,a5
    80004132:	0001e797          	auipc	a5,0x1e
    80004136:	84678793          	addi	a5,a5,-1978 # 80021978 <log>
    8000413a:	97ba                	add	a5,a5,a4
    8000413c:	539c                	lw	a5,32(a5)
    8000413e:	cfc1                	beqz	a5,800041d6 <crash_op+0xe4>
    panic("end_op: already closed");
  log[dev].outstanding -= 1;
    80004140:	37fd                	addiw	a5,a5,-1
    80004142:	0007861b          	sext.w	a2,a5
    80004146:	0a800713          	li	a4,168
    8000414a:	02e486b3          	mul	a3,s1,a4
    8000414e:	0001e717          	auipc	a4,0x1e
    80004152:	82a70713          	addi	a4,a4,-2006 # 80021978 <log>
    80004156:	9736                	add	a4,a4,a3
    80004158:	d31c                	sw	a5,32(a4)
  if(log[dev].committing)
    8000415a:	535c                	lw	a5,36(a4)
    8000415c:	e7c9                	bnez	a5,800041e6 <crash_op+0xf4>
    panic("log[dev].committing");
  if(log[dev].outstanding == 0){
    8000415e:	ee41                	bnez	a2,800041f6 <crash_op+0x104>
    do_commit = 1;
    log[dev].committing = 1;
    80004160:	0a800793          	li	a5,168
    80004164:	02f48733          	mul	a4,s1,a5
    80004168:	0001e797          	auipc	a5,0x1e
    8000416c:	81078793          	addi	a5,a5,-2032 # 80021978 <log>
    80004170:	97ba                	add	a5,a5,a4
    80004172:	4705                	li	a4,1
    80004174:	d3d8                	sw	a4,36(a5)
  }
  
  release(&log[dev].lock);
    80004176:	854a                	mv	a0,s2
    80004178:	ffffd097          	auipc	ra,0xffffd
    8000417c:	8ac080e7          	jalr	-1876(ra) # 80000a24 <release>

  if(docommit & do_commit){
    80004180:	0019f993          	andi	s3,s3,1
    80004184:	06098e63          	beqz	s3,80004200 <crash_op+0x10e>
    printf("crash_op: commit\n");
    80004188:	00003517          	auipc	a0,0x3
    8000418c:	4d850513          	addi	a0,a0,1240 # 80007660 <userret+0x5d0>
    80004190:	ffffc097          	auipc	ra,0xffffc
    80004194:	402080e7          	jalr	1026(ra) # 80000592 <printf>
    // call commit w/o holding locks, since not allowed
    // to sleep with locks.

    if (log[dev].lh.n > 0) {
    80004198:	0a800793          	li	a5,168
    8000419c:	02f48733          	mul	a4,s1,a5
    800041a0:	0001d797          	auipc	a5,0x1d
    800041a4:	7d878793          	addi	a5,a5,2008 # 80021978 <log>
    800041a8:	97ba                	add	a5,a5,a4
    800041aa:	57dc                	lw	a5,44(a5)
    800041ac:	04f05a63          	blez	a5,80004200 <crash_op+0x10e>
      write_log(dev);     // Write modified blocks from cache to log
    800041b0:	8526                	mv	a0,s1
    800041b2:	00000097          	auipc	ra,0x0
    800041b6:	9ea080e7          	jalr	-1558(ra) # 80003b9c <write_log>
      write_head(dev);    // Write header to disk -- the real commit
    800041ba:	8526                	mv	a0,s1
    800041bc:	00000097          	auipc	ra,0x0
    800041c0:	956080e7          	jalr	-1706(ra) # 80003b12 <write_head>
    800041c4:	a835                	j	80004200 <crash_op+0x10e>
    panic("end_op: invalid disk");
    800041c6:	00003517          	auipc	a0,0x3
    800041ca:	46a50513          	addi	a0,a0,1130 # 80007630 <userret+0x5a0>
    800041ce:	ffffc097          	auipc	ra,0xffffc
    800041d2:	37a080e7          	jalr	890(ra) # 80000548 <panic>
    panic("end_op: already closed");
    800041d6:	00003517          	auipc	a0,0x3
    800041da:	47250513          	addi	a0,a0,1138 # 80007648 <userret+0x5b8>
    800041de:	ffffc097          	auipc	ra,0xffffc
    800041e2:	36a080e7          	jalr	874(ra) # 80000548 <panic>
    panic("log[dev].committing");
    800041e6:	00003517          	auipc	a0,0x3
    800041ea:	3fa50513          	addi	a0,a0,1018 # 800075e0 <userret+0x550>
    800041ee:	ffffc097          	auipc	ra,0xffffc
    800041f2:	35a080e7          	jalr	858(ra) # 80000548 <panic>
  release(&log[dev].lock);
    800041f6:	854a                	mv	a0,s2
    800041f8:	ffffd097          	auipc	ra,0xffffd
    800041fc:	82c080e7          	jalr	-2004(ra) # 80000a24 <release>
    }
  }
  panic("crashed file system; please restart xv6 and run crashtest\n");
    80004200:	00003517          	auipc	a0,0x3
    80004204:	47850513          	addi	a0,a0,1144 # 80007678 <userret+0x5e8>
    80004208:	ffffc097          	auipc	ra,0xffffc
    8000420c:	340080e7          	jalr	832(ra) # 80000548 <panic>

0000000080004210 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004210:	1101                	addi	sp,sp,-32
    80004212:	ec06                	sd	ra,24(sp)
    80004214:	e822                	sd	s0,16(sp)
    80004216:	e426                	sd	s1,8(sp)
    80004218:	e04a                	sd	s2,0(sp)
    8000421a:	1000                	addi	s0,sp,32
    8000421c:	84aa                	mv	s1,a0
    8000421e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004220:	00003597          	auipc	a1,0x3
    80004224:	49858593          	addi	a1,a1,1176 # 800076b8 <userret+0x628>
    80004228:	0521                	addi	a0,a0,8
    8000422a:	ffffc097          	auipc	ra,0xffffc
    8000422e:	684080e7          	jalr	1668(ra) # 800008ae <initlock>
  lk->name = name;
    80004232:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004236:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000423a:	0204a423          	sw	zero,40(s1)
}
    8000423e:	60e2                	ld	ra,24(sp)
    80004240:	6442                	ld	s0,16(sp)
    80004242:	64a2                	ld	s1,8(sp)
    80004244:	6902                	ld	s2,0(sp)
    80004246:	6105                	addi	sp,sp,32
    80004248:	8082                	ret

000000008000424a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000424a:	1101                	addi	sp,sp,-32
    8000424c:	ec06                	sd	ra,24(sp)
    8000424e:	e822                	sd	s0,16(sp)
    80004250:	e426                	sd	s1,8(sp)
    80004252:	e04a                	sd	s2,0(sp)
    80004254:	1000                	addi	s0,sp,32
    80004256:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004258:	00850913          	addi	s2,a0,8
    8000425c:	854a                	mv	a0,s2
    8000425e:	ffffc097          	auipc	ra,0xffffc
    80004262:	75e080e7          	jalr	1886(ra) # 800009bc <acquire>
  while (lk->locked) {
    80004266:	409c                	lw	a5,0(s1)
    80004268:	cb89                	beqz	a5,8000427a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000426a:	85ca                	mv	a1,s2
    8000426c:	8526                	mv	a0,s1
    8000426e:	ffffe097          	auipc	ra,0xffffe
    80004272:	cc4080e7          	jalr	-828(ra) # 80001f32 <sleep>
  while (lk->locked) {
    80004276:	409c                	lw	a5,0(s1)
    80004278:	fbed                	bnez	a5,8000426a <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000427a:	4785                	li	a5,1
    8000427c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000427e:	ffffd097          	auipc	ra,0xffffd
    80004282:	49e080e7          	jalr	1182(ra) # 8000171c <myproc>
    80004286:	5d1c                	lw	a5,56(a0)
    80004288:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000428a:	854a                	mv	a0,s2
    8000428c:	ffffc097          	auipc	ra,0xffffc
    80004290:	798080e7          	jalr	1944(ra) # 80000a24 <release>
}
    80004294:	60e2                	ld	ra,24(sp)
    80004296:	6442                	ld	s0,16(sp)
    80004298:	64a2                	ld	s1,8(sp)
    8000429a:	6902                	ld	s2,0(sp)
    8000429c:	6105                	addi	sp,sp,32
    8000429e:	8082                	ret

00000000800042a0 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800042a0:	1101                	addi	sp,sp,-32
    800042a2:	ec06                	sd	ra,24(sp)
    800042a4:	e822                	sd	s0,16(sp)
    800042a6:	e426                	sd	s1,8(sp)
    800042a8:	e04a                	sd	s2,0(sp)
    800042aa:	1000                	addi	s0,sp,32
    800042ac:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800042ae:	00850913          	addi	s2,a0,8
    800042b2:	854a                	mv	a0,s2
    800042b4:	ffffc097          	auipc	ra,0xffffc
    800042b8:	708080e7          	jalr	1800(ra) # 800009bc <acquire>
  lk->locked = 0;
    800042bc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800042c0:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800042c4:	8526                	mv	a0,s1
    800042c6:	ffffe097          	auipc	ra,0xffffe
    800042ca:	dec080e7          	jalr	-532(ra) # 800020b2 <wakeup>
  release(&lk->lk);
    800042ce:	854a                	mv	a0,s2
    800042d0:	ffffc097          	auipc	ra,0xffffc
    800042d4:	754080e7          	jalr	1876(ra) # 80000a24 <release>
}
    800042d8:	60e2                	ld	ra,24(sp)
    800042da:	6442                	ld	s0,16(sp)
    800042dc:	64a2                	ld	s1,8(sp)
    800042de:	6902                	ld	s2,0(sp)
    800042e0:	6105                	addi	sp,sp,32
    800042e2:	8082                	ret

00000000800042e4 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800042e4:	7179                	addi	sp,sp,-48
    800042e6:	f406                	sd	ra,40(sp)
    800042e8:	f022                	sd	s0,32(sp)
    800042ea:	ec26                	sd	s1,24(sp)
    800042ec:	e84a                	sd	s2,16(sp)
    800042ee:	e44e                	sd	s3,8(sp)
    800042f0:	1800                	addi	s0,sp,48
    800042f2:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800042f4:	00850913          	addi	s2,a0,8
    800042f8:	854a                	mv	a0,s2
    800042fa:	ffffc097          	auipc	ra,0xffffc
    800042fe:	6c2080e7          	jalr	1730(ra) # 800009bc <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004302:	409c                	lw	a5,0(s1)
    80004304:	ef99                	bnez	a5,80004322 <holdingsleep+0x3e>
    80004306:	4481                	li	s1,0
  release(&lk->lk);
    80004308:	854a                	mv	a0,s2
    8000430a:	ffffc097          	auipc	ra,0xffffc
    8000430e:	71a080e7          	jalr	1818(ra) # 80000a24 <release>
  return r;
}
    80004312:	8526                	mv	a0,s1
    80004314:	70a2                	ld	ra,40(sp)
    80004316:	7402                	ld	s0,32(sp)
    80004318:	64e2                	ld	s1,24(sp)
    8000431a:	6942                	ld	s2,16(sp)
    8000431c:	69a2                	ld	s3,8(sp)
    8000431e:	6145                	addi	sp,sp,48
    80004320:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004322:	0284a983          	lw	s3,40(s1)
    80004326:	ffffd097          	auipc	ra,0xffffd
    8000432a:	3f6080e7          	jalr	1014(ra) # 8000171c <myproc>
    8000432e:	5d04                	lw	s1,56(a0)
    80004330:	413484b3          	sub	s1,s1,s3
    80004334:	0014b493          	seqz	s1,s1
    80004338:	bfc1                	j	80004308 <holdingsleep+0x24>

000000008000433a <fileinit>:
  //struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000433a:	1141                	addi	sp,sp,-16
    8000433c:	e406                	sd	ra,8(sp)
    8000433e:	e022                	sd	s0,0(sp)
    80004340:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004342:	00003597          	auipc	a1,0x3
    80004346:	38658593          	addi	a1,a1,902 # 800076c8 <userret+0x638>
    8000434a:	0001d517          	auipc	a0,0x1d
    8000434e:	77e50513          	addi	a0,a0,1918 # 80021ac8 <ftable>
    80004352:	ffffc097          	auipc	ra,0xffffc
    80004356:	55c080e7          	jalr	1372(ra) # 800008ae <initlock>
}
    8000435a:	60a2                	ld	ra,8(sp)
    8000435c:	6402                	ld	s0,0(sp)
    8000435e:	0141                	addi	sp,sp,16
    80004360:	8082                	ret

0000000080004362 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004362:	1101                	addi	sp,sp,-32
    80004364:	ec06                	sd	ra,24(sp)
    80004366:	e822                	sd	s0,16(sp)
    80004368:	e426                	sd	s1,8(sp)
    8000436a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000436c:	0001d517          	auipc	a0,0x1d
    80004370:	75c50513          	addi	a0,a0,1884 # 80021ac8 <ftable>
    80004374:	ffffc097          	auipc	ra,0xffffc
    80004378:	648080e7          	jalr	1608(ra) # 800009bc <acquire>
  f=bd_malloc(sizeof(struct file));//修改为bd_malloc
    8000437c:	02800513          	li	a0,40
    80004380:	00002097          	auipc	ra,0x2
    80004384:	292080e7          	jalr	658(ra) # 80006612 <bd_malloc>
    80004388:	84aa                	mv	s1,a0
  if(f){
    8000438a:	c905                	beqz	a0,800043ba <filealloc+0x58>
    memset(f,0,sizeof(struct file));
    8000438c:	02800613          	li	a2,40
    80004390:	4581                	li	a1,0
    80004392:	ffffc097          	auipc	ra,0xffffc
    80004396:	6ee080e7          	jalr	1774(ra) # 80000a80 <memset>
    f->ref=1;
    8000439a:	4785                	li	a5,1
    8000439c:	c0dc                	sw	a5,4(s1)
    release(&ftable.lock);
    8000439e:	0001d517          	auipc	a0,0x1d
    800043a2:	72a50513          	addi	a0,a0,1834 # 80021ac8 <ftable>
    800043a6:	ffffc097          	auipc	ra,0xffffc
    800043aa:	67e080e7          	jalr	1662(ra) # 80000a24 <release>
    return f;
  }  
  release(&ftable.lock);
  return 0;
}
    800043ae:	8526                	mv	a0,s1
    800043b0:	60e2                	ld	ra,24(sp)
    800043b2:	6442                	ld	s0,16(sp)
    800043b4:	64a2                	ld	s1,8(sp)
    800043b6:	6105                	addi	sp,sp,32
    800043b8:	8082                	ret
  release(&ftable.lock);
    800043ba:	0001d517          	auipc	a0,0x1d
    800043be:	70e50513          	addi	a0,a0,1806 # 80021ac8 <ftable>
    800043c2:	ffffc097          	auipc	ra,0xffffc
    800043c6:	662080e7          	jalr	1634(ra) # 80000a24 <release>
  return 0;
    800043ca:	b7d5                	j	800043ae <filealloc+0x4c>

00000000800043cc <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800043cc:	1101                	addi	sp,sp,-32
    800043ce:	ec06                	sd	ra,24(sp)
    800043d0:	e822                	sd	s0,16(sp)
    800043d2:	e426                	sd	s1,8(sp)
    800043d4:	1000                	addi	s0,sp,32
    800043d6:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800043d8:	0001d517          	auipc	a0,0x1d
    800043dc:	6f050513          	addi	a0,a0,1776 # 80021ac8 <ftable>
    800043e0:	ffffc097          	auipc	ra,0xffffc
    800043e4:	5dc080e7          	jalr	1500(ra) # 800009bc <acquire>
  if(f->ref < 1)
    800043e8:	40dc                	lw	a5,4(s1)
    800043ea:	02f05263          	blez	a5,8000440e <filedup+0x42>
    panic("filedup");
  f->ref++;
    800043ee:	2785                	addiw	a5,a5,1
    800043f0:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800043f2:	0001d517          	auipc	a0,0x1d
    800043f6:	6d650513          	addi	a0,a0,1750 # 80021ac8 <ftable>
    800043fa:	ffffc097          	auipc	ra,0xffffc
    800043fe:	62a080e7          	jalr	1578(ra) # 80000a24 <release>
  return f;
}
    80004402:	8526                	mv	a0,s1
    80004404:	60e2                	ld	ra,24(sp)
    80004406:	6442                	ld	s0,16(sp)
    80004408:	64a2                	ld	s1,8(sp)
    8000440a:	6105                	addi	sp,sp,32
    8000440c:	8082                	ret
    panic("filedup");
    8000440e:	00003517          	auipc	a0,0x3
    80004412:	2c250513          	addi	a0,a0,706 # 800076d0 <userret+0x640>
    80004416:	ffffc097          	auipc	ra,0xffffc
    8000441a:	132080e7          	jalr	306(ra) # 80000548 <panic>

000000008000441e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000441e:	7139                	addi	sp,sp,-64
    80004420:	fc06                	sd	ra,56(sp)
    80004422:	f822                	sd	s0,48(sp)
    80004424:	f426                	sd	s1,40(sp)
    80004426:	f04a                	sd	s2,32(sp)
    80004428:	ec4e                	sd	s3,24(sp)
    8000442a:	e852                	sd	s4,16(sp)
    8000442c:	e456                	sd	s5,8(sp)
    8000442e:	0080                	addi	s0,sp,64
    80004430:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004432:	0001d517          	auipc	a0,0x1d
    80004436:	69650513          	addi	a0,a0,1686 # 80021ac8 <ftable>
    8000443a:	ffffc097          	auipc	ra,0xffffc
    8000443e:	582080e7          	jalr	1410(ra) # 800009bc <acquire>
  if(f->ref < 1)
    80004442:	40dc                	lw	a5,4(s1)
    80004444:	06f05163          	blez	a5,800044a6 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004448:	37fd                	addiw	a5,a5,-1
    8000444a:	0007871b          	sext.w	a4,a5
    8000444e:	c0dc                	sw	a5,4(s1)
    80004450:	06e04363          	bgtz	a4,800044b6 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004454:	0004a903          	lw	s2,0(s1)
    80004458:	0094ca83          	lbu	s5,9(s1)
    8000445c:	0104ba03          	ld	s4,16(s1)
    80004460:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004464:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004468:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000446c:	0001d517          	auipc	a0,0x1d
    80004470:	65c50513          	addi	a0,a0,1628 # 80021ac8 <ftable>
    80004474:	ffffc097          	auipc	ra,0xffffc
    80004478:	5b0080e7          	jalr	1456(ra) # 80000a24 <release>

  if(ff.type == FD_PIPE){
    8000447c:	4785                	li	a5,1
    8000447e:	04f90563          	beq	s2,a5,800044c8 <fileclose+0xaa>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004482:	3979                	addiw	s2,s2,-2
    80004484:	4785                	li	a5,1
    80004486:	0527f863          	bgeu	a5,s2,800044d6 <fileclose+0xb8>
    begin_op(ff.ip->dev);
    iput(ff.ip);
    end_op(ff.ip->dev);
  }
  bd_free(f);//修改项，增加bd_free(f)
    8000448a:	8526                	mv	a0,s1
    8000448c:	00002097          	auipc	ra,0x2
    80004490:	372080e7          	jalr	882(ra) # 800067fe <bd_free>
}
    80004494:	70e2                	ld	ra,56(sp)
    80004496:	7442                	ld	s0,48(sp)
    80004498:	74a2                	ld	s1,40(sp)
    8000449a:	7902                	ld	s2,32(sp)
    8000449c:	69e2                	ld	s3,24(sp)
    8000449e:	6a42                	ld	s4,16(sp)
    800044a0:	6aa2                	ld	s5,8(sp)
    800044a2:	6121                	addi	sp,sp,64
    800044a4:	8082                	ret
    panic("fileclose");
    800044a6:	00003517          	auipc	a0,0x3
    800044aa:	23250513          	addi	a0,a0,562 # 800076d8 <userret+0x648>
    800044ae:	ffffc097          	auipc	ra,0xffffc
    800044b2:	09a080e7          	jalr	154(ra) # 80000548 <panic>
    release(&ftable.lock);
    800044b6:	0001d517          	auipc	a0,0x1d
    800044ba:	61250513          	addi	a0,a0,1554 # 80021ac8 <ftable>
    800044be:	ffffc097          	auipc	ra,0xffffc
    800044c2:	566080e7          	jalr	1382(ra) # 80000a24 <release>
    return;
    800044c6:	b7f9                	j	80004494 <fileclose+0x76>
    pipeclose(ff.pipe, ff.writable);
    800044c8:	85d6                	mv	a1,s5
    800044ca:	8552                	mv	a0,s4
    800044cc:	00000097          	auipc	ra,0x0
    800044d0:	394080e7          	jalr	916(ra) # 80004860 <pipeclose>
    800044d4:	bf5d                	j	8000448a <fileclose+0x6c>
    begin_op(ff.ip->dev);
    800044d6:	0009a503          	lw	a0,0(s3)
    800044da:	00000097          	auipc	ra,0x0
    800044de:	91c080e7          	jalr	-1764(ra) # 80003df6 <begin_op>
    iput(ff.ip);
    800044e2:	854e                	mv	a0,s3
    800044e4:	fffff097          	auipc	ra,0xfffff
    800044e8:	f76080e7          	jalr	-138(ra) # 8000345a <iput>
    end_op(ff.ip->dev);
    800044ec:	0009a503          	lw	a0,0(s3)
    800044f0:	00000097          	auipc	ra,0x0
    800044f4:	9b0080e7          	jalr	-1616(ra) # 80003ea0 <end_op>
    800044f8:	bf49                	j	8000448a <fileclose+0x6c>

00000000800044fa <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800044fa:	715d                	addi	sp,sp,-80
    800044fc:	e486                	sd	ra,72(sp)
    800044fe:	e0a2                	sd	s0,64(sp)
    80004500:	fc26                	sd	s1,56(sp)
    80004502:	f84a                	sd	s2,48(sp)
    80004504:	f44e                	sd	s3,40(sp)
    80004506:	0880                	addi	s0,sp,80
    80004508:	84aa                	mv	s1,a0
    8000450a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000450c:	ffffd097          	auipc	ra,0xffffd
    80004510:	210080e7          	jalr	528(ra) # 8000171c <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004514:	409c                	lw	a5,0(s1)
    80004516:	37f9                	addiw	a5,a5,-2
    80004518:	4705                	li	a4,1
    8000451a:	04f76763          	bltu	a4,a5,80004568 <filestat+0x6e>
    8000451e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004520:	6c88                	ld	a0,24(s1)
    80004522:	fffff097          	auipc	ra,0xfffff
    80004526:	e2a080e7          	jalr	-470(ra) # 8000334c <ilock>
    stati(f->ip, &st);
    8000452a:	fb840593          	addi	a1,s0,-72
    8000452e:	6c88                	ld	a0,24(s1)
    80004530:	fffff097          	auipc	ra,0xfffff
    80004534:	082080e7          	jalr	130(ra) # 800035b2 <stati>
    iunlock(f->ip);
    80004538:	6c88                	ld	a0,24(s1)
    8000453a:	fffff097          	auipc	ra,0xfffff
    8000453e:	ed4080e7          	jalr	-300(ra) # 8000340e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004542:	46e1                	li	a3,24
    80004544:	fb840613          	addi	a2,s0,-72
    80004548:	85ce                	mv	a1,s3
    8000454a:	05093503          	ld	a0,80(s2)
    8000454e:	ffffd097          	auipc	ra,0xffffd
    80004552:	ef2080e7          	jalr	-270(ra) # 80001440 <copyout>
    80004556:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000455a:	60a6                	ld	ra,72(sp)
    8000455c:	6406                	ld	s0,64(sp)
    8000455e:	74e2                	ld	s1,56(sp)
    80004560:	7942                	ld	s2,48(sp)
    80004562:	79a2                	ld	s3,40(sp)
    80004564:	6161                	addi	sp,sp,80
    80004566:	8082                	ret
  return -1;
    80004568:	557d                	li	a0,-1
    8000456a:	bfc5                	j	8000455a <filestat+0x60>

000000008000456c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000456c:	7179                	addi	sp,sp,-48
    8000456e:	f406                	sd	ra,40(sp)
    80004570:	f022                	sd	s0,32(sp)
    80004572:	ec26                	sd	s1,24(sp)
    80004574:	e84a                	sd	s2,16(sp)
    80004576:	e44e                	sd	s3,8(sp)
    80004578:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000457a:	00854783          	lbu	a5,8(a0)
    8000457e:	c3d5                	beqz	a5,80004622 <fileread+0xb6>
    80004580:	84aa                	mv	s1,a0
    80004582:	89ae                	mv	s3,a1
    80004584:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004586:	411c                	lw	a5,0(a0)
    80004588:	4705                	li	a4,1
    8000458a:	04e78963          	beq	a5,a4,800045dc <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000458e:	470d                	li	a4,3
    80004590:	04e78d63          	beq	a5,a4,800045ea <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004594:	4709                	li	a4,2
    80004596:	06e79e63          	bne	a5,a4,80004612 <fileread+0xa6>
    ilock(f->ip);
    8000459a:	6d08                	ld	a0,24(a0)
    8000459c:	fffff097          	auipc	ra,0xfffff
    800045a0:	db0080e7          	jalr	-592(ra) # 8000334c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800045a4:	874a                	mv	a4,s2
    800045a6:	5094                	lw	a3,32(s1)
    800045a8:	864e                	mv	a2,s3
    800045aa:	4585                	li	a1,1
    800045ac:	6c88                	ld	a0,24(s1)
    800045ae:	fffff097          	auipc	ra,0xfffff
    800045b2:	02e080e7          	jalr	46(ra) # 800035dc <readi>
    800045b6:	892a                	mv	s2,a0
    800045b8:	00a05563          	blez	a0,800045c2 <fileread+0x56>
      f->off += r;
    800045bc:	509c                	lw	a5,32(s1)
    800045be:	9fa9                	addw	a5,a5,a0
    800045c0:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800045c2:	6c88                	ld	a0,24(s1)
    800045c4:	fffff097          	auipc	ra,0xfffff
    800045c8:	e4a080e7          	jalr	-438(ra) # 8000340e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800045cc:	854a                	mv	a0,s2
    800045ce:	70a2                	ld	ra,40(sp)
    800045d0:	7402                	ld	s0,32(sp)
    800045d2:	64e2                	ld	s1,24(sp)
    800045d4:	6942                	ld	s2,16(sp)
    800045d6:	69a2                	ld	s3,8(sp)
    800045d8:	6145                	addi	sp,sp,48
    800045da:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800045dc:	6908                	ld	a0,16(a0)
    800045de:	00000097          	auipc	ra,0x0
    800045e2:	400080e7          	jalr	1024(ra) # 800049de <piperead>
    800045e6:	892a                	mv	s2,a0
    800045e8:	b7d5                	j	800045cc <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800045ea:	02451783          	lh	a5,36(a0)
    800045ee:	03079693          	slli	a3,a5,0x30
    800045f2:	92c1                	srli	a3,a3,0x30
    800045f4:	4725                	li	a4,9
    800045f6:	02d76863          	bltu	a4,a3,80004626 <fileread+0xba>
    800045fa:	0792                	slli	a5,a5,0x4
    800045fc:	0001d717          	auipc	a4,0x1d
    80004600:	4cc70713          	addi	a4,a4,1228 # 80021ac8 <ftable>
    80004604:	97ba                	add	a5,a5,a4
    80004606:	6f9c                	ld	a5,24(a5)
    80004608:	c38d                	beqz	a5,8000462a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000460a:	4505                	li	a0,1
    8000460c:	9782                	jalr	a5
    8000460e:	892a                	mv	s2,a0
    80004610:	bf75                	j	800045cc <fileread+0x60>
    panic("fileread");
    80004612:	00003517          	auipc	a0,0x3
    80004616:	0d650513          	addi	a0,a0,214 # 800076e8 <userret+0x658>
    8000461a:	ffffc097          	auipc	ra,0xffffc
    8000461e:	f2e080e7          	jalr	-210(ra) # 80000548 <panic>
    return -1;
    80004622:	597d                	li	s2,-1
    80004624:	b765                	j	800045cc <fileread+0x60>
      return -1;
    80004626:	597d                	li	s2,-1
    80004628:	b755                	j	800045cc <fileread+0x60>
    8000462a:	597d                	li	s2,-1
    8000462c:	b745                	j	800045cc <fileread+0x60>

000000008000462e <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    8000462e:	00954783          	lbu	a5,9(a0)
    80004632:	14078463          	beqz	a5,8000477a <filewrite+0x14c>
{
    80004636:	715d                	addi	sp,sp,-80
    80004638:	e486                	sd	ra,72(sp)
    8000463a:	e0a2                	sd	s0,64(sp)
    8000463c:	fc26                	sd	s1,56(sp)
    8000463e:	f84a                	sd	s2,48(sp)
    80004640:	f44e                	sd	s3,40(sp)
    80004642:	f052                	sd	s4,32(sp)
    80004644:	ec56                	sd	s5,24(sp)
    80004646:	e85a                	sd	s6,16(sp)
    80004648:	e45e                	sd	s7,8(sp)
    8000464a:	e062                	sd	s8,0(sp)
    8000464c:	0880                	addi	s0,sp,80
    8000464e:	84aa                	mv	s1,a0
    80004650:	8aae                	mv	s5,a1
    80004652:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004654:	411c                	lw	a5,0(a0)
    80004656:	4705                	li	a4,1
    80004658:	02e78263          	beq	a5,a4,8000467c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000465c:	470d                	li	a4,3
    8000465e:	02e78563          	beq	a5,a4,80004688 <filewrite+0x5a>
      if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004662:	4709                	li	a4,2
    80004664:	10e79363          	bne	a5,a4,8000476a <filewrite+0x13c>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004668:	0ec05d63          	blez	a2,80004762 <filewrite+0x134>
    int i = 0;
    8000466c:	4981                	li	s3,0
    8000466e:	6b05                	lui	s6,0x1
    80004670:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004674:	6b85                	lui	s7,0x1
    80004676:	c00b8b9b          	addiw	s7,s7,-1024
    8000467a:	a841                	j	8000470a <filewrite+0xdc>
    ret = pipewrite(f->pipe, addr, n);
    8000467c:	6908                	ld	a0,16(a0)
    8000467e:	00000097          	auipc	ra,0x0
    80004682:	252080e7          	jalr	594(ra) # 800048d0 <pipewrite>
    80004686:	a855                	j	8000473a <filewrite+0x10c>
      if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004688:	02451783          	lh	a5,36(a0)
    8000468c:	03079693          	slli	a3,a5,0x30
    80004690:	92c1                	srli	a3,a3,0x30
    80004692:	4725                	li	a4,9
    80004694:	0ed76563          	bltu	a4,a3,8000477e <filewrite+0x150>
    80004698:	0792                	slli	a5,a5,0x4
    8000469a:	0001d717          	auipc	a4,0x1d
    8000469e:	42e70713          	addi	a4,a4,1070 # 80021ac8 <ftable>
    800046a2:	97ba                	add	a5,a5,a4
    800046a4:	739c                	ld	a5,32(a5)
    800046a6:	cff1                	beqz	a5,80004782 <filewrite+0x154>
    ret = devsw[f->major].write(1, addr, n);
    800046a8:	4505                	li	a0,1
    800046aa:	9782                	jalr	a5
    800046ac:	a079                	j	8000473a <filewrite+0x10c>
    800046ae:	00090c1b          	sext.w	s8,s2
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op(f->ip->dev);
    800046b2:	6c9c                	ld	a5,24(s1)
    800046b4:	4388                	lw	a0,0(a5)
    800046b6:	fffff097          	auipc	ra,0xfffff
    800046ba:	740080e7          	jalr	1856(ra) # 80003df6 <begin_op>
      ilock(f->ip);
    800046be:	6c88                	ld	a0,24(s1)
    800046c0:	fffff097          	auipc	ra,0xfffff
    800046c4:	c8c080e7          	jalr	-884(ra) # 8000334c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800046c8:	8762                	mv	a4,s8
    800046ca:	5094                	lw	a3,32(s1)
    800046cc:	01598633          	add	a2,s3,s5
    800046d0:	4585                	li	a1,1
    800046d2:	6c88                	ld	a0,24(s1)
    800046d4:	fffff097          	auipc	ra,0xfffff
    800046d8:	ffc080e7          	jalr	-4(ra) # 800036d0 <writei>
    800046dc:	892a                	mv	s2,a0
    800046de:	02a05e63          	blez	a0,8000471a <filewrite+0xec>
        f->off += r;
    800046e2:	509c                	lw	a5,32(s1)
    800046e4:	9fa9                	addw	a5,a5,a0
    800046e6:	d09c                	sw	a5,32(s1)
      iunlock(f->ip);
    800046e8:	6c88                	ld	a0,24(s1)
    800046ea:	fffff097          	auipc	ra,0xfffff
    800046ee:	d24080e7          	jalr	-732(ra) # 8000340e <iunlock>
      end_op(f->ip->dev);
    800046f2:	6c9c                	ld	a5,24(s1)
    800046f4:	4388                	lw	a0,0(a5)
    800046f6:	fffff097          	auipc	ra,0xfffff
    800046fa:	7aa080e7          	jalr	1962(ra) # 80003ea0 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    800046fe:	052c1a63          	bne	s8,s2,80004752 <filewrite+0x124>
        panic("short filewrite");
      i += r;
    80004702:	013909bb          	addw	s3,s2,s3
    while(i < n){
    80004706:	0349d763          	bge	s3,s4,80004734 <filewrite+0x106>
      int n1 = n - i;
    8000470a:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000470e:	893e                	mv	s2,a5
    80004710:	2781                	sext.w	a5,a5
    80004712:	f8fb5ee3          	bge	s6,a5,800046ae <filewrite+0x80>
    80004716:	895e                	mv	s2,s7
    80004718:	bf59                	j	800046ae <filewrite+0x80>
      iunlock(f->ip);
    8000471a:	6c88                	ld	a0,24(s1)
    8000471c:	fffff097          	auipc	ra,0xfffff
    80004720:	cf2080e7          	jalr	-782(ra) # 8000340e <iunlock>
      end_op(f->ip->dev);
    80004724:	6c9c                	ld	a5,24(s1)
    80004726:	4388                	lw	a0,0(a5)
    80004728:	fffff097          	auipc	ra,0xfffff
    8000472c:	778080e7          	jalr	1912(ra) # 80003ea0 <end_op>
      if(r < 0)
    80004730:	fc0957e3          	bgez	s2,800046fe <filewrite+0xd0>
    }
    ret = (i == n ? n : -1);
    80004734:	8552                	mv	a0,s4
    80004736:	033a1863          	bne	s4,s3,80004766 <filewrite+0x138>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000473a:	60a6                	ld	ra,72(sp)
    8000473c:	6406                	ld	s0,64(sp)
    8000473e:	74e2                	ld	s1,56(sp)
    80004740:	7942                	ld	s2,48(sp)
    80004742:	79a2                	ld	s3,40(sp)
    80004744:	7a02                	ld	s4,32(sp)
    80004746:	6ae2                	ld	s5,24(sp)
    80004748:	6b42                	ld	s6,16(sp)
    8000474a:	6ba2                	ld	s7,8(sp)
    8000474c:	6c02                	ld	s8,0(sp)
    8000474e:	6161                	addi	sp,sp,80
    80004750:	8082                	ret
        panic("short filewrite");
    80004752:	00003517          	auipc	a0,0x3
    80004756:	fa650513          	addi	a0,a0,-90 # 800076f8 <userret+0x668>
    8000475a:	ffffc097          	auipc	ra,0xffffc
    8000475e:	dee080e7          	jalr	-530(ra) # 80000548 <panic>
    int i = 0;
    80004762:	4981                	li	s3,0
    80004764:	bfc1                	j	80004734 <filewrite+0x106>
    ret = (i == n ? n : -1);
    80004766:	557d                	li	a0,-1
    80004768:	bfc9                	j	8000473a <filewrite+0x10c>
    panic("filewrite");
    8000476a:	00003517          	auipc	a0,0x3
    8000476e:	f9e50513          	addi	a0,a0,-98 # 80007708 <userret+0x678>
    80004772:	ffffc097          	auipc	ra,0xffffc
    80004776:	dd6080e7          	jalr	-554(ra) # 80000548 <panic>
    return -1;
    8000477a:	557d                	li	a0,-1
}
    8000477c:	8082                	ret
      return -1;
    8000477e:	557d                	li	a0,-1
    80004780:	bf6d                	j	8000473a <filewrite+0x10c>
    80004782:	557d                	li	a0,-1
    80004784:	bf5d                	j	8000473a <filewrite+0x10c>

0000000080004786 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004786:	7179                	addi	sp,sp,-48
    80004788:	f406                	sd	ra,40(sp)
    8000478a:	f022                	sd	s0,32(sp)
    8000478c:	ec26                	sd	s1,24(sp)
    8000478e:	e84a                	sd	s2,16(sp)
    80004790:	e44e                	sd	s3,8(sp)
    80004792:	e052                	sd	s4,0(sp)
    80004794:	1800                	addi	s0,sp,48
    80004796:	84aa                	mv	s1,a0
    80004798:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000479a:	0005b023          	sd	zero,0(a1)
    8000479e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800047a2:	00000097          	auipc	ra,0x0
    800047a6:	bc0080e7          	jalr	-1088(ra) # 80004362 <filealloc>
    800047aa:	e088                	sd	a0,0(s1)
    800047ac:	c551                	beqz	a0,80004838 <pipealloc+0xb2>
    800047ae:	00000097          	auipc	ra,0x0
    800047b2:	bb4080e7          	jalr	-1100(ra) # 80004362 <filealloc>
    800047b6:	00aa3023          	sd	a0,0(s4)
    800047ba:	c92d                	beqz	a0,8000482c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800047bc:	ffffc097          	auipc	ra,0xffffc
    800047c0:	0d8080e7          	jalr	216(ra) # 80000894 <kalloc>
    800047c4:	892a                	mv	s2,a0
    800047c6:	c125                	beqz	a0,80004826 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800047c8:	4985                	li	s3,1
    800047ca:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800047ce:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800047d2:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800047d6:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800047da:	00003597          	auipc	a1,0x3
    800047de:	f3e58593          	addi	a1,a1,-194 # 80007718 <userret+0x688>
    800047e2:	ffffc097          	auipc	ra,0xffffc
    800047e6:	0cc080e7          	jalr	204(ra) # 800008ae <initlock>
  (*f0)->type = FD_PIPE;
    800047ea:	609c                	ld	a5,0(s1)
    800047ec:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800047f0:	609c                	ld	a5,0(s1)
    800047f2:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800047f6:	609c                	ld	a5,0(s1)
    800047f8:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800047fc:	609c                	ld	a5,0(s1)
    800047fe:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004802:	000a3783          	ld	a5,0(s4)
    80004806:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000480a:	000a3783          	ld	a5,0(s4)
    8000480e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004812:	000a3783          	ld	a5,0(s4)
    80004816:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000481a:	000a3783          	ld	a5,0(s4)
    8000481e:	0127b823          	sd	s2,16(a5)
  return 0;
    80004822:	4501                	li	a0,0
    80004824:	a025                	j	8000484c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004826:	6088                	ld	a0,0(s1)
    80004828:	e501                	bnez	a0,80004830 <pipealloc+0xaa>
    8000482a:	a039                	j	80004838 <pipealloc+0xb2>
    8000482c:	6088                	ld	a0,0(s1)
    8000482e:	c51d                	beqz	a0,8000485c <pipealloc+0xd6>
    fileclose(*f0);
    80004830:	00000097          	auipc	ra,0x0
    80004834:	bee080e7          	jalr	-1042(ra) # 8000441e <fileclose>
  if(*f1)
    80004838:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000483c:	557d                	li	a0,-1
  if(*f1)
    8000483e:	c799                	beqz	a5,8000484c <pipealloc+0xc6>
    fileclose(*f1);
    80004840:	853e                	mv	a0,a5
    80004842:	00000097          	auipc	ra,0x0
    80004846:	bdc080e7          	jalr	-1060(ra) # 8000441e <fileclose>
  return -1;
    8000484a:	557d                	li	a0,-1
}
    8000484c:	70a2                	ld	ra,40(sp)
    8000484e:	7402                	ld	s0,32(sp)
    80004850:	64e2                	ld	s1,24(sp)
    80004852:	6942                	ld	s2,16(sp)
    80004854:	69a2                	ld	s3,8(sp)
    80004856:	6a02                	ld	s4,0(sp)
    80004858:	6145                	addi	sp,sp,48
    8000485a:	8082                	ret
  return -1;
    8000485c:	557d                	li	a0,-1
    8000485e:	b7fd                	j	8000484c <pipealloc+0xc6>

0000000080004860 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004860:	1101                	addi	sp,sp,-32
    80004862:	ec06                	sd	ra,24(sp)
    80004864:	e822                	sd	s0,16(sp)
    80004866:	e426                	sd	s1,8(sp)
    80004868:	e04a                	sd	s2,0(sp)
    8000486a:	1000                	addi	s0,sp,32
    8000486c:	84aa                	mv	s1,a0
    8000486e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004870:	ffffc097          	auipc	ra,0xffffc
    80004874:	14c080e7          	jalr	332(ra) # 800009bc <acquire>
  if(writable){
    80004878:	02090d63          	beqz	s2,800048b2 <pipeclose+0x52>
    pi->writeopen = 0;
    8000487c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004880:	21848513          	addi	a0,s1,536
    80004884:	ffffe097          	auipc	ra,0xffffe
    80004888:	82e080e7          	jalr	-2002(ra) # 800020b2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000488c:	2204b783          	ld	a5,544(s1)
    80004890:	eb95                	bnez	a5,800048c4 <pipeclose+0x64>
    release(&pi->lock);
    80004892:	8526                	mv	a0,s1
    80004894:	ffffc097          	auipc	ra,0xffffc
    80004898:	190080e7          	jalr	400(ra) # 80000a24 <release>
    kfree((char*)pi);
    8000489c:	8526                	mv	a0,s1
    8000489e:	ffffc097          	auipc	ra,0xffffc
    800048a2:	fde080e7          	jalr	-34(ra) # 8000087c <kfree>
  } else
    release(&pi->lock);
}
    800048a6:	60e2                	ld	ra,24(sp)
    800048a8:	6442                	ld	s0,16(sp)
    800048aa:	64a2                	ld	s1,8(sp)
    800048ac:	6902                	ld	s2,0(sp)
    800048ae:	6105                	addi	sp,sp,32
    800048b0:	8082                	ret
    pi->readopen = 0;
    800048b2:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800048b6:	21c48513          	addi	a0,s1,540
    800048ba:	ffffd097          	auipc	ra,0xffffd
    800048be:	7f8080e7          	jalr	2040(ra) # 800020b2 <wakeup>
    800048c2:	b7e9                	j	8000488c <pipeclose+0x2c>
    release(&pi->lock);
    800048c4:	8526                	mv	a0,s1
    800048c6:	ffffc097          	auipc	ra,0xffffc
    800048ca:	15e080e7          	jalr	350(ra) # 80000a24 <release>
}
    800048ce:	bfe1                	j	800048a6 <pipeclose+0x46>

00000000800048d0 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800048d0:	711d                	addi	sp,sp,-96
    800048d2:	ec86                	sd	ra,88(sp)
    800048d4:	e8a2                	sd	s0,80(sp)
    800048d6:	e4a6                	sd	s1,72(sp)
    800048d8:	e0ca                	sd	s2,64(sp)
    800048da:	fc4e                	sd	s3,56(sp)
    800048dc:	f852                	sd	s4,48(sp)
    800048de:	f456                	sd	s5,40(sp)
    800048e0:	f05a                	sd	s6,32(sp)
    800048e2:	ec5e                	sd	s7,24(sp)
    800048e4:	e862                	sd	s8,16(sp)
    800048e6:	1080                	addi	s0,sp,96
    800048e8:	84aa                	mv	s1,a0
    800048ea:	8aae                	mv	s5,a1
    800048ec:	8a32                	mv	s4,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    800048ee:	ffffd097          	auipc	ra,0xffffd
    800048f2:	e2e080e7          	jalr	-466(ra) # 8000171c <myproc>
    800048f6:	8baa                	mv	s7,a0

  acquire(&pi->lock);
    800048f8:	8526                	mv	a0,s1
    800048fa:	ffffc097          	auipc	ra,0xffffc
    800048fe:	0c2080e7          	jalr	194(ra) # 800009bc <acquire>
  for(i = 0; i < n; i++){
    80004902:	09405f63          	blez	s4,800049a0 <pipewrite+0xd0>
    80004906:	fffa0b1b          	addiw	s6,s4,-1
    8000490a:	1b02                	slli	s6,s6,0x20
    8000490c:	020b5b13          	srli	s6,s6,0x20
    80004910:	001a8793          	addi	a5,s5,1
    80004914:	9b3e                	add	s6,s6,a5
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || myproc()->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004916:	21848993          	addi	s3,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000491a:	21c48913          	addi	s2,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000491e:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004920:	2184a783          	lw	a5,536(s1)
    80004924:	21c4a703          	lw	a4,540(s1)
    80004928:	2007879b          	addiw	a5,a5,512
    8000492c:	02f71e63          	bne	a4,a5,80004968 <pipewrite+0x98>
      if(pi->readopen == 0 || myproc()->killed){
    80004930:	2204a783          	lw	a5,544(s1)
    80004934:	c3d9                	beqz	a5,800049ba <pipewrite+0xea>
    80004936:	ffffd097          	auipc	ra,0xffffd
    8000493a:	de6080e7          	jalr	-538(ra) # 8000171c <myproc>
    8000493e:	591c                	lw	a5,48(a0)
    80004940:	efad                	bnez	a5,800049ba <pipewrite+0xea>
      wakeup(&pi->nread);
    80004942:	854e                	mv	a0,s3
    80004944:	ffffd097          	auipc	ra,0xffffd
    80004948:	76e080e7          	jalr	1902(ra) # 800020b2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000494c:	85a6                	mv	a1,s1
    8000494e:	854a                	mv	a0,s2
    80004950:	ffffd097          	auipc	ra,0xffffd
    80004954:	5e2080e7          	jalr	1506(ra) # 80001f32 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004958:	2184a783          	lw	a5,536(s1)
    8000495c:	21c4a703          	lw	a4,540(s1)
    80004960:	2007879b          	addiw	a5,a5,512
    80004964:	fcf706e3          	beq	a4,a5,80004930 <pipewrite+0x60>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004968:	4685                	li	a3,1
    8000496a:	8656                	mv	a2,s5
    8000496c:	faf40593          	addi	a1,s0,-81
    80004970:	050bb503          	ld	a0,80(s7) # 1050 <_entry-0x7fffefb0>
    80004974:	ffffd097          	auipc	ra,0xffffd
    80004978:	b5e080e7          	jalr	-1186(ra) # 800014d2 <copyin>
    8000497c:	03850263          	beq	a0,s8,800049a0 <pipewrite+0xd0>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004980:	21c4a783          	lw	a5,540(s1)
    80004984:	0017871b          	addiw	a4,a5,1
    80004988:	20e4ae23          	sw	a4,540(s1)
    8000498c:	1ff7f793          	andi	a5,a5,511
    80004990:	97a6                	add	a5,a5,s1
    80004992:	faf44703          	lbu	a4,-81(s0)
    80004996:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    8000499a:	0a85                	addi	s5,s5,1
    8000499c:	f96a92e3          	bne	s5,s6,80004920 <pipewrite+0x50>
  }
  wakeup(&pi->nread);
    800049a0:	21848513          	addi	a0,s1,536
    800049a4:	ffffd097          	auipc	ra,0xffffd
    800049a8:	70e080e7          	jalr	1806(ra) # 800020b2 <wakeup>
  release(&pi->lock);
    800049ac:	8526                	mv	a0,s1
    800049ae:	ffffc097          	auipc	ra,0xffffc
    800049b2:	076080e7          	jalr	118(ra) # 80000a24 <release>
  return n;
    800049b6:	8552                	mv	a0,s4
    800049b8:	a039                	j	800049c6 <pipewrite+0xf6>
        release(&pi->lock);
    800049ba:	8526                	mv	a0,s1
    800049bc:	ffffc097          	auipc	ra,0xffffc
    800049c0:	068080e7          	jalr	104(ra) # 80000a24 <release>
        return -1;
    800049c4:	557d                	li	a0,-1
}
    800049c6:	60e6                	ld	ra,88(sp)
    800049c8:	6446                	ld	s0,80(sp)
    800049ca:	64a6                	ld	s1,72(sp)
    800049cc:	6906                	ld	s2,64(sp)
    800049ce:	79e2                	ld	s3,56(sp)
    800049d0:	7a42                	ld	s4,48(sp)
    800049d2:	7aa2                	ld	s5,40(sp)
    800049d4:	7b02                	ld	s6,32(sp)
    800049d6:	6be2                	ld	s7,24(sp)
    800049d8:	6c42                	ld	s8,16(sp)
    800049da:	6125                	addi	sp,sp,96
    800049dc:	8082                	ret

00000000800049de <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800049de:	715d                	addi	sp,sp,-80
    800049e0:	e486                	sd	ra,72(sp)
    800049e2:	e0a2                	sd	s0,64(sp)
    800049e4:	fc26                	sd	s1,56(sp)
    800049e6:	f84a                	sd	s2,48(sp)
    800049e8:	f44e                	sd	s3,40(sp)
    800049ea:	f052                	sd	s4,32(sp)
    800049ec:	ec56                	sd	s5,24(sp)
    800049ee:	e85a                	sd	s6,16(sp)
    800049f0:	0880                	addi	s0,sp,80
    800049f2:	84aa                	mv	s1,a0
    800049f4:	892e                	mv	s2,a1
    800049f6:	8a32                	mv	s4,a2
  int i;
  struct proc *pr = myproc();
    800049f8:	ffffd097          	auipc	ra,0xffffd
    800049fc:	d24080e7          	jalr	-732(ra) # 8000171c <myproc>
    80004a00:	8aaa                	mv	s5,a0
  char ch;

  acquire(&pi->lock);
    80004a02:	8526                	mv	a0,s1
    80004a04:	ffffc097          	auipc	ra,0xffffc
    80004a08:	fb8080e7          	jalr	-72(ra) # 800009bc <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a0c:	2184a703          	lw	a4,536(s1)
    80004a10:	21c4a783          	lw	a5,540(s1)
    if(myproc()->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a14:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a18:	02f71763          	bne	a4,a5,80004a46 <piperead+0x68>
    80004a1c:	2244a783          	lw	a5,548(s1)
    80004a20:	c39d                	beqz	a5,80004a46 <piperead+0x68>
    if(myproc()->killed){
    80004a22:	ffffd097          	auipc	ra,0xffffd
    80004a26:	cfa080e7          	jalr	-774(ra) # 8000171c <myproc>
    80004a2a:	591c                	lw	a5,48(a0)
    80004a2c:	ebc1                	bnez	a5,80004abc <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a2e:	85a6                	mv	a1,s1
    80004a30:	854e                	mv	a0,s3
    80004a32:	ffffd097          	auipc	ra,0xffffd
    80004a36:	500080e7          	jalr	1280(ra) # 80001f32 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a3a:	2184a703          	lw	a4,536(s1)
    80004a3e:	21c4a783          	lw	a5,540(s1)
    80004a42:	fcf70de3          	beq	a4,a5,80004a1c <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004a46:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004a48:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004a4a:	05405363          	blez	s4,80004a90 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004a4e:	2184a783          	lw	a5,536(s1)
    80004a52:	21c4a703          	lw	a4,540(s1)
    80004a56:	02f70d63          	beq	a4,a5,80004a90 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004a5a:	0017871b          	addiw	a4,a5,1
    80004a5e:	20e4ac23          	sw	a4,536(s1)
    80004a62:	1ff7f793          	andi	a5,a5,511
    80004a66:	97a6                	add	a5,a5,s1
    80004a68:	0187c783          	lbu	a5,24(a5)
    80004a6c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004a70:	4685                	li	a3,1
    80004a72:	fbf40613          	addi	a2,s0,-65
    80004a76:	85ca                	mv	a1,s2
    80004a78:	050ab503          	ld	a0,80(s5)
    80004a7c:	ffffd097          	auipc	ra,0xffffd
    80004a80:	9c4080e7          	jalr	-1596(ra) # 80001440 <copyout>
    80004a84:	01650663          	beq	a0,s6,80004a90 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004a88:	2985                	addiw	s3,s3,1
    80004a8a:	0905                	addi	s2,s2,1
    80004a8c:	fd3a11e3          	bne	s4,s3,80004a4e <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004a90:	21c48513          	addi	a0,s1,540
    80004a94:	ffffd097          	auipc	ra,0xffffd
    80004a98:	61e080e7          	jalr	1566(ra) # 800020b2 <wakeup>
  release(&pi->lock);
    80004a9c:	8526                	mv	a0,s1
    80004a9e:	ffffc097          	auipc	ra,0xffffc
    80004aa2:	f86080e7          	jalr	-122(ra) # 80000a24 <release>
  return i;
}
    80004aa6:	854e                	mv	a0,s3
    80004aa8:	60a6                	ld	ra,72(sp)
    80004aaa:	6406                	ld	s0,64(sp)
    80004aac:	74e2                	ld	s1,56(sp)
    80004aae:	7942                	ld	s2,48(sp)
    80004ab0:	79a2                	ld	s3,40(sp)
    80004ab2:	7a02                	ld	s4,32(sp)
    80004ab4:	6ae2                	ld	s5,24(sp)
    80004ab6:	6b42                	ld	s6,16(sp)
    80004ab8:	6161                	addi	sp,sp,80
    80004aba:	8082                	ret
      release(&pi->lock);
    80004abc:	8526                	mv	a0,s1
    80004abe:	ffffc097          	auipc	ra,0xffffc
    80004ac2:	f66080e7          	jalr	-154(ra) # 80000a24 <release>
      return -1;
    80004ac6:	59fd                	li	s3,-1
    80004ac8:	bff9                	j	80004aa6 <piperead+0xc8>

0000000080004aca <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004aca:	de010113          	addi	sp,sp,-544
    80004ace:	20113c23          	sd	ra,536(sp)
    80004ad2:	20813823          	sd	s0,528(sp)
    80004ad6:	20913423          	sd	s1,520(sp)
    80004ada:	21213023          	sd	s2,512(sp)
    80004ade:	ffce                	sd	s3,504(sp)
    80004ae0:	fbd2                	sd	s4,496(sp)
    80004ae2:	f7d6                	sd	s5,488(sp)
    80004ae4:	f3da                	sd	s6,480(sp)
    80004ae6:	efde                	sd	s7,472(sp)
    80004ae8:	ebe2                	sd	s8,464(sp)
    80004aea:	e7e6                	sd	s9,456(sp)
    80004aec:	e3ea                	sd	s10,448(sp)
    80004aee:	ff6e                	sd	s11,440(sp)
    80004af0:	1400                	addi	s0,sp,544
    80004af2:	892a                	mv	s2,a0
    80004af4:	dea43423          	sd	a0,-536(s0)
    80004af8:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004afc:	ffffd097          	auipc	ra,0xffffd
    80004b00:	c20080e7          	jalr	-992(ra) # 8000171c <myproc>
    80004b04:	84aa                	mv	s1,a0

  begin_op(ROOTDEV);
    80004b06:	4501                	li	a0,0
    80004b08:	fffff097          	auipc	ra,0xfffff
    80004b0c:	2ee080e7          	jalr	750(ra) # 80003df6 <begin_op>

  if((ip = namei(path)) == 0){
    80004b10:	854a                	mv	a0,s2
    80004b12:	fffff097          	auipc	ra,0xfffff
    80004b16:	fc6080e7          	jalr	-58(ra) # 80003ad8 <namei>
    80004b1a:	cd25                	beqz	a0,80004b92 <exec+0xc8>
    80004b1c:	8aaa                	mv	s5,a0
    end_op(ROOTDEV);
    return -1;
  }
  ilock(ip);
    80004b1e:	fffff097          	auipc	ra,0xfffff
    80004b22:	82e080e7          	jalr	-2002(ra) # 8000334c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004b26:	04000713          	li	a4,64
    80004b2a:	4681                	li	a3,0
    80004b2c:	e4840613          	addi	a2,s0,-440
    80004b30:	4581                	li	a1,0
    80004b32:	8556                	mv	a0,s5
    80004b34:	fffff097          	auipc	ra,0xfffff
    80004b38:	aa8080e7          	jalr	-1368(ra) # 800035dc <readi>
    80004b3c:	04000793          	li	a5,64
    80004b40:	00f51a63          	bne	a0,a5,80004b54 <exec+0x8a>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004b44:	e4842703          	lw	a4,-440(s0)
    80004b48:	464c47b7          	lui	a5,0x464c4
    80004b4c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004b50:	04f70863          	beq	a4,a5,80004ba0 <exec+0xd6>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004b54:	8556                	mv	a0,s5
    80004b56:	fffff097          	auipc	ra,0xfffff
    80004b5a:	a34080e7          	jalr	-1484(ra) # 8000358a <iunlockput>
    end_op(ROOTDEV);
    80004b5e:	4501                	li	a0,0
    80004b60:	fffff097          	auipc	ra,0xfffff
    80004b64:	340080e7          	jalr	832(ra) # 80003ea0 <end_op>
  }
  return -1;
    80004b68:	557d                	li	a0,-1
}
    80004b6a:	21813083          	ld	ra,536(sp)
    80004b6e:	21013403          	ld	s0,528(sp)
    80004b72:	20813483          	ld	s1,520(sp)
    80004b76:	20013903          	ld	s2,512(sp)
    80004b7a:	79fe                	ld	s3,504(sp)
    80004b7c:	7a5e                	ld	s4,496(sp)
    80004b7e:	7abe                	ld	s5,488(sp)
    80004b80:	7b1e                	ld	s6,480(sp)
    80004b82:	6bfe                	ld	s7,472(sp)
    80004b84:	6c5e                	ld	s8,464(sp)
    80004b86:	6cbe                	ld	s9,456(sp)
    80004b88:	6d1e                	ld	s10,448(sp)
    80004b8a:	7dfa                	ld	s11,440(sp)
    80004b8c:	22010113          	addi	sp,sp,544
    80004b90:	8082                	ret
    end_op(ROOTDEV);
    80004b92:	4501                	li	a0,0
    80004b94:	fffff097          	auipc	ra,0xfffff
    80004b98:	30c080e7          	jalr	780(ra) # 80003ea0 <end_op>
    return -1;
    80004b9c:	557d                	li	a0,-1
    80004b9e:	b7f1                	j	80004b6a <exec+0xa0>
  if((pagetable = proc_pagetable(p)) == 0)
    80004ba0:	8526                	mv	a0,s1
    80004ba2:	ffffd097          	auipc	ra,0xffffd
    80004ba6:	c3e080e7          	jalr	-962(ra) # 800017e0 <proc_pagetable>
    80004baa:	8b2a                	mv	s6,a0
    80004bac:	d545                	beqz	a0,80004b54 <exec+0x8a>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004bae:	e6842783          	lw	a5,-408(s0)
    80004bb2:	e8045703          	lhu	a4,-384(s0)
    80004bb6:	10070263          	beqz	a4,80004cba <exec+0x1f0>
  sz = 0;
    80004bba:	de043c23          	sd	zero,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004bbe:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004bc2:	6a05                	lui	s4,0x1
    80004bc4:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004bc8:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004bcc:	6d85                	lui	s11,0x1
    80004bce:	7d7d                	lui	s10,0xfffff
    80004bd0:	a88d                	j	80004c42 <exec+0x178>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004bd2:	00003517          	auipc	a0,0x3
    80004bd6:	b4e50513          	addi	a0,a0,-1202 # 80007720 <userret+0x690>
    80004bda:	ffffc097          	auipc	ra,0xffffc
    80004bde:	96e080e7          	jalr	-1682(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004be2:	874a                	mv	a4,s2
    80004be4:	009c86bb          	addw	a3,s9,s1
    80004be8:	4581                	li	a1,0
    80004bea:	8556                	mv	a0,s5
    80004bec:	fffff097          	auipc	ra,0xfffff
    80004bf0:	9f0080e7          	jalr	-1552(ra) # 800035dc <readi>
    80004bf4:	2501                	sext.w	a0,a0
    80004bf6:	10a91863          	bne	s2,a0,80004d06 <exec+0x23c>
  for(i = 0; i < sz; i += PGSIZE){
    80004bfa:	009d84bb          	addw	s1,s11,s1
    80004bfe:	013d09bb          	addw	s3,s10,s3
    80004c02:	0374f263          	bgeu	s1,s7,80004c26 <exec+0x15c>
    pa = walkaddr(pagetable, va + i);
    80004c06:	02049593          	slli	a1,s1,0x20
    80004c0a:	9181                	srli	a1,a1,0x20
    80004c0c:	95e2                	add	a1,a1,s8
    80004c0e:	855a                	mv	a0,s6
    80004c10:	ffffc097          	auipc	ra,0xffffc
    80004c14:	26a080e7          	jalr	618(ra) # 80000e7a <walkaddr>
    80004c18:	862a                	mv	a2,a0
    if(pa == 0)
    80004c1a:	dd45                	beqz	a0,80004bd2 <exec+0x108>
      n = PGSIZE;
    80004c1c:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004c1e:	fd49f2e3          	bgeu	s3,s4,80004be2 <exec+0x118>
      n = sz - i;
    80004c22:	894e                	mv	s2,s3
    80004c24:	bf7d                	j	80004be2 <exec+0x118>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c26:	e0843783          	ld	a5,-504(s0)
    80004c2a:	0017869b          	addiw	a3,a5,1
    80004c2e:	e0d43423          	sd	a3,-504(s0)
    80004c32:	e0043783          	ld	a5,-512(s0)
    80004c36:	0387879b          	addiw	a5,a5,56
    80004c3a:	e8045703          	lhu	a4,-384(s0)
    80004c3e:	08e6d063          	bge	a3,a4,80004cbe <exec+0x1f4>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004c42:	2781                	sext.w	a5,a5
    80004c44:	e0f43023          	sd	a5,-512(s0)
    80004c48:	03800713          	li	a4,56
    80004c4c:	86be                	mv	a3,a5
    80004c4e:	e1040613          	addi	a2,s0,-496
    80004c52:	4581                	li	a1,0
    80004c54:	8556                	mv	a0,s5
    80004c56:	fffff097          	auipc	ra,0xfffff
    80004c5a:	986080e7          	jalr	-1658(ra) # 800035dc <readi>
    80004c5e:	03800793          	li	a5,56
    80004c62:	0af51263          	bne	a0,a5,80004d06 <exec+0x23c>
    if(ph.type != ELF_PROG_LOAD)
    80004c66:	e1042783          	lw	a5,-496(s0)
    80004c6a:	4705                	li	a4,1
    80004c6c:	fae79de3          	bne	a5,a4,80004c26 <exec+0x15c>
    if(ph.memsz < ph.filesz)
    80004c70:	e3843603          	ld	a2,-456(s0)
    80004c74:	e3043783          	ld	a5,-464(s0)
    80004c78:	08f66763          	bltu	a2,a5,80004d06 <exec+0x23c>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004c7c:	e2043783          	ld	a5,-480(s0)
    80004c80:	963e                	add	a2,a2,a5
    80004c82:	08f66263          	bltu	a2,a5,80004d06 <exec+0x23c>
    if((sz = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004c86:	df843583          	ld	a1,-520(s0)
    80004c8a:	855a                	mv	a0,s6
    80004c8c:	ffffc097          	auipc	ra,0xffffc
    80004c90:	5da080e7          	jalr	1498(ra) # 80001266 <uvmalloc>
    80004c94:	dea43c23          	sd	a0,-520(s0)
    80004c98:	c53d                	beqz	a0,80004d06 <exec+0x23c>
    if(ph.vaddr % PGSIZE != 0)
    80004c9a:	e2043c03          	ld	s8,-480(s0)
    80004c9e:	de043783          	ld	a5,-544(s0)
    80004ca2:	00fc77b3          	and	a5,s8,a5
    80004ca6:	e3a5                	bnez	a5,80004d06 <exec+0x23c>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004ca8:	e1842c83          	lw	s9,-488(s0)
    80004cac:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004cb0:	f60b8be3          	beqz	s7,80004c26 <exec+0x15c>
    80004cb4:	89de                	mv	s3,s7
    80004cb6:	4481                	li	s1,0
    80004cb8:	b7b9                	j	80004c06 <exec+0x13c>
  sz = 0;
    80004cba:	de043c23          	sd	zero,-520(s0)
  iunlockput(ip);
    80004cbe:	8556                	mv	a0,s5
    80004cc0:	fffff097          	auipc	ra,0xfffff
    80004cc4:	8ca080e7          	jalr	-1846(ra) # 8000358a <iunlockput>
  end_op(ROOTDEV);
    80004cc8:	4501                	li	a0,0
    80004cca:	fffff097          	auipc	ra,0xfffff
    80004cce:	1d6080e7          	jalr	470(ra) # 80003ea0 <end_op>
  p = myproc();
    80004cd2:	ffffd097          	auipc	ra,0xffffd
    80004cd6:	a4a080e7          	jalr	-1462(ra) # 8000171c <myproc>
    80004cda:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004cdc:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80004ce0:	6585                	lui	a1,0x1
    80004ce2:	15fd                	addi	a1,a1,-1
    80004ce4:	df843783          	ld	a5,-520(s0)
    80004ce8:	95be                	add	a1,a1,a5
    80004cea:	77fd                	lui	a5,0xfffff
    80004cec:	8dfd                	and	a1,a1,a5
  if((sz = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004cee:	6609                	lui	a2,0x2
    80004cf0:	962e                	add	a2,a2,a1
    80004cf2:	855a                	mv	a0,s6
    80004cf4:	ffffc097          	auipc	ra,0xffffc
    80004cf8:	572080e7          	jalr	1394(ra) # 80001266 <uvmalloc>
    80004cfc:	892a                	mv	s2,a0
    80004cfe:	dea43c23          	sd	a0,-520(s0)
  ip = 0;
    80004d02:	4a81                	li	s5,0
  if((sz = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d04:	ed01                	bnez	a0,80004d1c <exec+0x252>
    proc_freepagetable(pagetable, sz);
    80004d06:	df843583          	ld	a1,-520(s0)
    80004d0a:	855a                	mv	a0,s6
    80004d0c:	ffffd097          	auipc	ra,0xffffd
    80004d10:	bd4080e7          	jalr	-1068(ra) # 800018e0 <proc_freepagetable>
  if(ip){
    80004d14:	e40a90e3          	bnez	s5,80004b54 <exec+0x8a>
  return -1;
    80004d18:	557d                	li	a0,-1
    80004d1a:	bd81                	j	80004b6a <exec+0xa0>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004d1c:	75f9                	lui	a1,0xffffe
    80004d1e:	95aa                	add	a1,a1,a0
    80004d20:	855a                	mv	a0,s6
    80004d22:	ffffc097          	auipc	ra,0xffffc
    80004d26:	6ec080e7          	jalr	1772(ra) # 8000140e <uvmclear>
  stackbase = sp - PGSIZE;
    80004d2a:	7c7d                	lui	s8,0xfffff
    80004d2c:	9c4a                	add	s8,s8,s2
  for(argc = 0; argv[argc]; argc++) {
    80004d2e:	df043783          	ld	a5,-528(s0)
    80004d32:	6388                	ld	a0,0(a5)
    80004d34:	c52d                	beqz	a0,80004d9e <exec+0x2d4>
    80004d36:	e8840993          	addi	s3,s0,-376
    80004d3a:	f8840a93          	addi	s5,s0,-120
    80004d3e:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004d40:	ffffc097          	auipc	ra,0xffffc
    80004d44:	ec4080e7          	jalr	-316(ra) # 80000c04 <strlen>
    80004d48:	0015079b          	addiw	a5,a0,1
    80004d4c:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004d50:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004d54:	0f896b63          	bltu	s2,s8,80004e4a <exec+0x380>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004d58:	df043d03          	ld	s10,-528(s0)
    80004d5c:	000d3a03          	ld	s4,0(s10) # fffffffffffff000 <end+0xffffffff7ffd6fa4>
    80004d60:	8552                	mv	a0,s4
    80004d62:	ffffc097          	auipc	ra,0xffffc
    80004d66:	ea2080e7          	jalr	-350(ra) # 80000c04 <strlen>
    80004d6a:	0015069b          	addiw	a3,a0,1
    80004d6e:	8652                	mv	a2,s4
    80004d70:	85ca                	mv	a1,s2
    80004d72:	855a                	mv	a0,s6
    80004d74:	ffffc097          	auipc	ra,0xffffc
    80004d78:	6cc080e7          	jalr	1740(ra) # 80001440 <copyout>
    80004d7c:	0c054963          	bltz	a0,80004e4e <exec+0x384>
    ustack[argc] = sp;
    80004d80:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004d84:	0485                	addi	s1,s1,1
    80004d86:	008d0793          	addi	a5,s10,8
    80004d8a:	def43823          	sd	a5,-528(s0)
    80004d8e:	008d3503          	ld	a0,8(s10)
    80004d92:	c909                	beqz	a0,80004da4 <exec+0x2da>
    if(argc >= MAXARG)
    80004d94:	09a1                	addi	s3,s3,8
    80004d96:	fb3a95e3          	bne	s5,s3,80004d40 <exec+0x276>
  ip = 0;
    80004d9a:	4a81                	li	s5,0
    80004d9c:	b7ad                	j	80004d06 <exec+0x23c>
  sp = sz;
    80004d9e:	df843903          	ld	s2,-520(s0)
  for(argc = 0; argv[argc]; argc++) {
    80004da2:	4481                	li	s1,0
  ustack[argc] = 0;
    80004da4:	00349793          	slli	a5,s1,0x3
    80004da8:	f9040713          	addi	a4,s0,-112
    80004dac:	97ba                	add	a5,a5,a4
    80004dae:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd6e9c>
  sp -= (argc+1) * sizeof(uint64);
    80004db2:	00148693          	addi	a3,s1,1
    80004db6:	068e                	slli	a3,a3,0x3
    80004db8:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004dbc:	ff097913          	andi	s2,s2,-16
  ip = 0;
    80004dc0:	4a81                	li	s5,0
  if(sp < stackbase)
    80004dc2:	f58962e3          	bltu	s2,s8,80004d06 <exec+0x23c>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004dc6:	e8840613          	addi	a2,s0,-376
    80004dca:	85ca                	mv	a1,s2
    80004dcc:	855a                	mv	a0,s6
    80004dce:	ffffc097          	auipc	ra,0xffffc
    80004dd2:	672080e7          	jalr	1650(ra) # 80001440 <copyout>
    80004dd6:	06054e63          	bltz	a0,80004e52 <exec+0x388>
  p->tf->a1 = sp;
    80004dda:	058bb783          	ld	a5,88(s7)
    80004dde:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004de2:	de843783          	ld	a5,-536(s0)
    80004de6:	0007c703          	lbu	a4,0(a5)
    80004dea:	cf11                	beqz	a4,80004e06 <exec+0x33c>
    80004dec:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004dee:	02f00693          	li	a3,47
    80004df2:	a039                	j	80004e00 <exec+0x336>
      last = s+1;
    80004df4:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004df8:	0785                	addi	a5,a5,1
    80004dfa:	fff7c703          	lbu	a4,-1(a5)
    80004dfe:	c701                	beqz	a4,80004e06 <exec+0x33c>
    if(*s == '/')
    80004e00:	fed71ce3          	bne	a4,a3,80004df8 <exec+0x32e>
    80004e04:	bfc5                	j	80004df4 <exec+0x32a>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e06:	4641                	li	a2,16
    80004e08:	de843583          	ld	a1,-536(s0)
    80004e0c:	158b8513          	addi	a0,s7,344
    80004e10:	ffffc097          	auipc	ra,0xffffc
    80004e14:	dc2080e7          	jalr	-574(ra) # 80000bd2 <safestrcpy>
  oldpagetable = p->pagetable;
    80004e18:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004e1c:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004e20:	df843783          	ld	a5,-520(s0)
    80004e24:	04fbb423          	sd	a5,72(s7)
  p->tf->epc = elf.entry;  // initial program counter = main
    80004e28:	058bb783          	ld	a5,88(s7)
    80004e2c:	e6043703          	ld	a4,-416(s0)
    80004e30:	ef98                	sd	a4,24(a5)
  p->tf->sp = sp; // initial stack pointer
    80004e32:	058bb783          	ld	a5,88(s7)
    80004e36:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004e3a:	85e6                	mv	a1,s9
    80004e3c:	ffffd097          	auipc	ra,0xffffd
    80004e40:	aa4080e7          	jalr	-1372(ra) # 800018e0 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e44:	0004851b          	sext.w	a0,s1
    80004e48:	b30d                	j	80004b6a <exec+0xa0>
  ip = 0;
    80004e4a:	4a81                	li	s5,0
    80004e4c:	bd6d                	j	80004d06 <exec+0x23c>
    80004e4e:	4a81                	li	s5,0
    80004e50:	bd5d                	j	80004d06 <exec+0x23c>
    80004e52:	4a81                	li	s5,0
    80004e54:	bd4d                	j	80004d06 <exec+0x23c>

0000000080004e56 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004e56:	7179                	addi	sp,sp,-48
    80004e58:	f406                	sd	ra,40(sp)
    80004e5a:	f022                	sd	s0,32(sp)
    80004e5c:	ec26                	sd	s1,24(sp)
    80004e5e:	e84a                	sd	s2,16(sp)
    80004e60:	1800                	addi	s0,sp,48
    80004e62:	892e                	mv	s2,a1
    80004e64:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004e66:	fdc40593          	addi	a1,s0,-36
    80004e6a:	ffffe097          	auipc	ra,0xffffe
    80004e6e:	96c080e7          	jalr	-1684(ra) # 800027d6 <argint>
    80004e72:	04054063          	bltz	a0,80004eb2 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004e76:	fdc42703          	lw	a4,-36(s0)
    80004e7a:	47bd                	li	a5,15
    80004e7c:	02e7ed63          	bltu	a5,a4,80004eb6 <argfd+0x60>
    80004e80:	ffffd097          	auipc	ra,0xffffd
    80004e84:	89c080e7          	jalr	-1892(ra) # 8000171c <myproc>
    80004e88:	fdc42703          	lw	a4,-36(s0)
    80004e8c:	01a70793          	addi	a5,a4,26
    80004e90:	078e                	slli	a5,a5,0x3
    80004e92:	953e                	add	a0,a0,a5
    80004e94:	611c                	ld	a5,0(a0)
    80004e96:	c395                	beqz	a5,80004eba <argfd+0x64>
    return -1;
  if(pfd)
    80004e98:	00090463          	beqz	s2,80004ea0 <argfd+0x4a>
    *pfd = fd;
    80004e9c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004ea0:	4501                	li	a0,0
  if(pf)
    80004ea2:	c091                	beqz	s1,80004ea6 <argfd+0x50>
    *pf = f;
    80004ea4:	e09c                	sd	a5,0(s1)
}
    80004ea6:	70a2                	ld	ra,40(sp)
    80004ea8:	7402                	ld	s0,32(sp)
    80004eaa:	64e2                	ld	s1,24(sp)
    80004eac:	6942                	ld	s2,16(sp)
    80004eae:	6145                	addi	sp,sp,48
    80004eb0:	8082                	ret
    return -1;
    80004eb2:	557d                	li	a0,-1
    80004eb4:	bfcd                	j	80004ea6 <argfd+0x50>
    return -1;
    80004eb6:	557d                	li	a0,-1
    80004eb8:	b7fd                	j	80004ea6 <argfd+0x50>
    80004eba:	557d                	li	a0,-1
    80004ebc:	b7ed                	j	80004ea6 <argfd+0x50>

0000000080004ebe <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004ebe:	1101                	addi	sp,sp,-32
    80004ec0:	ec06                	sd	ra,24(sp)
    80004ec2:	e822                	sd	s0,16(sp)
    80004ec4:	e426                	sd	s1,8(sp)
    80004ec6:	1000                	addi	s0,sp,32
    80004ec8:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004eca:	ffffd097          	auipc	ra,0xffffd
    80004ece:	852080e7          	jalr	-1966(ra) # 8000171c <myproc>
    80004ed2:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004ed4:	0d050793          	addi	a5,a0,208
    80004ed8:	4501                	li	a0,0
    80004eda:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004edc:	6398                	ld	a4,0(a5)
    80004ede:	cb19                	beqz	a4,80004ef4 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004ee0:	2505                	addiw	a0,a0,1
    80004ee2:	07a1                	addi	a5,a5,8
    80004ee4:	fed51ce3          	bne	a0,a3,80004edc <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004ee8:	557d                	li	a0,-1
}
    80004eea:	60e2                	ld	ra,24(sp)
    80004eec:	6442                	ld	s0,16(sp)
    80004eee:	64a2                	ld	s1,8(sp)
    80004ef0:	6105                	addi	sp,sp,32
    80004ef2:	8082                	ret
      p->ofile[fd] = f;
    80004ef4:	01a50793          	addi	a5,a0,26
    80004ef8:	078e                	slli	a5,a5,0x3
    80004efa:	963e                	add	a2,a2,a5
    80004efc:	e204                	sd	s1,0(a2)
      return fd;
    80004efe:	b7f5                	j	80004eea <fdalloc+0x2c>

0000000080004f00 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004f00:	715d                	addi	sp,sp,-80
    80004f02:	e486                	sd	ra,72(sp)
    80004f04:	e0a2                	sd	s0,64(sp)
    80004f06:	fc26                	sd	s1,56(sp)
    80004f08:	f84a                	sd	s2,48(sp)
    80004f0a:	f44e                	sd	s3,40(sp)
    80004f0c:	f052                	sd	s4,32(sp)
    80004f0e:	ec56                	sd	s5,24(sp)
    80004f10:	0880                	addi	s0,sp,80
    80004f12:	89ae                	mv	s3,a1
    80004f14:	8ab2                	mv	s5,a2
    80004f16:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004f18:	fb040593          	addi	a1,s0,-80
    80004f1c:	fffff097          	auipc	ra,0xfffff
    80004f20:	bda080e7          	jalr	-1062(ra) # 80003af6 <nameiparent>
    80004f24:	892a                	mv	s2,a0
    80004f26:	12050e63          	beqz	a0,80005062 <create+0x162>
    return 0;

  ilock(dp);
    80004f2a:	ffffe097          	auipc	ra,0xffffe
    80004f2e:	422080e7          	jalr	1058(ra) # 8000334c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004f32:	4601                	li	a2,0
    80004f34:	fb040593          	addi	a1,s0,-80
    80004f38:	854a                	mv	a0,s2
    80004f3a:	fffff097          	auipc	ra,0xfffff
    80004f3e:	8cc080e7          	jalr	-1844(ra) # 80003806 <dirlookup>
    80004f42:	84aa                	mv	s1,a0
    80004f44:	c921                	beqz	a0,80004f94 <create+0x94>
    iunlockput(dp);
    80004f46:	854a                	mv	a0,s2
    80004f48:	ffffe097          	auipc	ra,0xffffe
    80004f4c:	642080e7          	jalr	1602(ra) # 8000358a <iunlockput>
    ilock(ip);
    80004f50:	8526                	mv	a0,s1
    80004f52:	ffffe097          	auipc	ra,0xffffe
    80004f56:	3fa080e7          	jalr	1018(ra) # 8000334c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004f5a:	2981                	sext.w	s3,s3
    80004f5c:	4789                	li	a5,2
    80004f5e:	02f99463          	bne	s3,a5,80004f86 <create+0x86>
    80004f62:	0444d783          	lhu	a5,68(s1)
    80004f66:	37f9                	addiw	a5,a5,-2
    80004f68:	17c2                	slli	a5,a5,0x30
    80004f6a:	93c1                	srli	a5,a5,0x30
    80004f6c:	4705                	li	a4,1
    80004f6e:	00f76c63          	bltu	a4,a5,80004f86 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80004f72:	8526                	mv	a0,s1
    80004f74:	60a6                	ld	ra,72(sp)
    80004f76:	6406                	ld	s0,64(sp)
    80004f78:	74e2                	ld	s1,56(sp)
    80004f7a:	7942                	ld	s2,48(sp)
    80004f7c:	79a2                	ld	s3,40(sp)
    80004f7e:	7a02                	ld	s4,32(sp)
    80004f80:	6ae2                	ld	s5,24(sp)
    80004f82:	6161                	addi	sp,sp,80
    80004f84:	8082                	ret
    iunlockput(ip);
    80004f86:	8526                	mv	a0,s1
    80004f88:	ffffe097          	auipc	ra,0xffffe
    80004f8c:	602080e7          	jalr	1538(ra) # 8000358a <iunlockput>
    return 0;
    80004f90:	4481                	li	s1,0
    80004f92:	b7c5                	j	80004f72 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80004f94:	85ce                	mv	a1,s3
    80004f96:	00092503          	lw	a0,0(s2)
    80004f9a:	ffffe097          	auipc	ra,0xffffe
    80004f9e:	21a080e7          	jalr	538(ra) # 800031b4 <ialloc>
    80004fa2:	84aa                	mv	s1,a0
    80004fa4:	c521                	beqz	a0,80004fec <create+0xec>
  ilock(ip);
    80004fa6:	ffffe097          	auipc	ra,0xffffe
    80004faa:	3a6080e7          	jalr	934(ra) # 8000334c <ilock>
  ip->major = major;
    80004fae:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80004fb2:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80004fb6:	4a05                	li	s4,1
    80004fb8:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80004fbc:	8526                	mv	a0,s1
    80004fbe:	ffffe097          	auipc	ra,0xffffe
    80004fc2:	2c4080e7          	jalr	708(ra) # 80003282 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80004fc6:	2981                	sext.w	s3,s3
    80004fc8:	03498a63          	beq	s3,s4,80004ffc <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80004fcc:	40d0                	lw	a2,4(s1)
    80004fce:	fb040593          	addi	a1,s0,-80
    80004fd2:	854a                	mv	a0,s2
    80004fd4:	fffff097          	auipc	ra,0xfffff
    80004fd8:	a42080e7          	jalr	-1470(ra) # 80003a16 <dirlink>
    80004fdc:	06054b63          	bltz	a0,80005052 <create+0x152>
  iunlockput(dp);
    80004fe0:	854a                	mv	a0,s2
    80004fe2:	ffffe097          	auipc	ra,0xffffe
    80004fe6:	5a8080e7          	jalr	1448(ra) # 8000358a <iunlockput>
  return ip;
    80004fea:	b761                	j	80004f72 <create+0x72>
    panic("create: ialloc");
    80004fec:	00002517          	auipc	a0,0x2
    80004ff0:	75450513          	addi	a0,a0,1876 # 80007740 <userret+0x6b0>
    80004ff4:	ffffb097          	auipc	ra,0xffffb
    80004ff8:	554080e7          	jalr	1364(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    80004ffc:	04a95783          	lhu	a5,74(s2)
    80005000:	2785                	addiw	a5,a5,1
    80005002:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005006:	854a                	mv	a0,s2
    80005008:	ffffe097          	auipc	ra,0xffffe
    8000500c:	27a080e7          	jalr	634(ra) # 80003282 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005010:	40d0                	lw	a2,4(s1)
    80005012:	00002597          	auipc	a1,0x2
    80005016:	73e58593          	addi	a1,a1,1854 # 80007750 <userret+0x6c0>
    8000501a:	8526                	mv	a0,s1
    8000501c:	fffff097          	auipc	ra,0xfffff
    80005020:	9fa080e7          	jalr	-1542(ra) # 80003a16 <dirlink>
    80005024:	00054f63          	bltz	a0,80005042 <create+0x142>
    80005028:	00492603          	lw	a2,4(s2)
    8000502c:	00002597          	auipc	a1,0x2
    80005030:	72c58593          	addi	a1,a1,1836 # 80007758 <userret+0x6c8>
    80005034:	8526                	mv	a0,s1
    80005036:	fffff097          	auipc	ra,0xfffff
    8000503a:	9e0080e7          	jalr	-1568(ra) # 80003a16 <dirlink>
    8000503e:	f80557e3          	bgez	a0,80004fcc <create+0xcc>
      panic("create dots");
    80005042:	00002517          	auipc	a0,0x2
    80005046:	71e50513          	addi	a0,a0,1822 # 80007760 <userret+0x6d0>
    8000504a:	ffffb097          	auipc	ra,0xffffb
    8000504e:	4fe080e7          	jalr	1278(ra) # 80000548 <panic>
    panic("create: dirlink");
    80005052:	00002517          	auipc	a0,0x2
    80005056:	71e50513          	addi	a0,a0,1822 # 80007770 <userret+0x6e0>
    8000505a:	ffffb097          	auipc	ra,0xffffb
    8000505e:	4ee080e7          	jalr	1262(ra) # 80000548 <panic>
    return 0;
    80005062:	84aa                	mv	s1,a0
    80005064:	b739                	j	80004f72 <create+0x72>

0000000080005066 <sys_dup>:
{
    80005066:	7179                	addi	sp,sp,-48
    80005068:	f406                	sd	ra,40(sp)
    8000506a:	f022                	sd	s0,32(sp)
    8000506c:	ec26                	sd	s1,24(sp)
    8000506e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005070:	fd840613          	addi	a2,s0,-40
    80005074:	4581                	li	a1,0
    80005076:	4501                	li	a0,0
    80005078:	00000097          	auipc	ra,0x0
    8000507c:	dde080e7          	jalr	-546(ra) # 80004e56 <argfd>
    return -1;
    80005080:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005082:	02054363          	bltz	a0,800050a8 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005086:	fd843503          	ld	a0,-40(s0)
    8000508a:	00000097          	auipc	ra,0x0
    8000508e:	e34080e7          	jalr	-460(ra) # 80004ebe <fdalloc>
    80005092:	84aa                	mv	s1,a0
    return -1;
    80005094:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005096:	00054963          	bltz	a0,800050a8 <sys_dup+0x42>
  filedup(f);
    8000509a:	fd843503          	ld	a0,-40(s0)
    8000509e:	fffff097          	auipc	ra,0xfffff
    800050a2:	32e080e7          	jalr	814(ra) # 800043cc <filedup>
  return fd;
    800050a6:	87a6                	mv	a5,s1
}
    800050a8:	853e                	mv	a0,a5
    800050aa:	70a2                	ld	ra,40(sp)
    800050ac:	7402                	ld	s0,32(sp)
    800050ae:	64e2                	ld	s1,24(sp)
    800050b0:	6145                	addi	sp,sp,48
    800050b2:	8082                	ret

00000000800050b4 <sys_read>:
{
    800050b4:	7179                	addi	sp,sp,-48
    800050b6:	f406                	sd	ra,40(sp)
    800050b8:	f022                	sd	s0,32(sp)
    800050ba:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800050bc:	fe840613          	addi	a2,s0,-24
    800050c0:	4581                	li	a1,0
    800050c2:	4501                	li	a0,0
    800050c4:	00000097          	auipc	ra,0x0
    800050c8:	d92080e7          	jalr	-622(ra) # 80004e56 <argfd>
    return -1;
    800050cc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800050ce:	04054163          	bltz	a0,80005110 <sys_read+0x5c>
    800050d2:	fe440593          	addi	a1,s0,-28
    800050d6:	4509                	li	a0,2
    800050d8:	ffffd097          	auipc	ra,0xffffd
    800050dc:	6fe080e7          	jalr	1790(ra) # 800027d6 <argint>
    return -1;
    800050e0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800050e2:	02054763          	bltz	a0,80005110 <sys_read+0x5c>
    800050e6:	fd840593          	addi	a1,s0,-40
    800050ea:	4505                	li	a0,1
    800050ec:	ffffd097          	auipc	ra,0xffffd
    800050f0:	70c080e7          	jalr	1804(ra) # 800027f8 <argaddr>
    return -1;
    800050f4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800050f6:	00054d63          	bltz	a0,80005110 <sys_read+0x5c>
  return fileread(f, p, n);
    800050fa:	fe442603          	lw	a2,-28(s0)
    800050fe:	fd843583          	ld	a1,-40(s0)
    80005102:	fe843503          	ld	a0,-24(s0)
    80005106:	fffff097          	auipc	ra,0xfffff
    8000510a:	466080e7          	jalr	1126(ra) # 8000456c <fileread>
    8000510e:	87aa                	mv	a5,a0
}
    80005110:	853e                	mv	a0,a5
    80005112:	70a2                	ld	ra,40(sp)
    80005114:	7402                	ld	s0,32(sp)
    80005116:	6145                	addi	sp,sp,48
    80005118:	8082                	ret

000000008000511a <sys_write>:
{
    8000511a:	7179                	addi	sp,sp,-48
    8000511c:	f406                	sd	ra,40(sp)
    8000511e:	f022                	sd	s0,32(sp)
    80005120:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005122:	fe840613          	addi	a2,s0,-24
    80005126:	4581                	li	a1,0
    80005128:	4501                	li	a0,0
    8000512a:	00000097          	auipc	ra,0x0
    8000512e:	d2c080e7          	jalr	-724(ra) # 80004e56 <argfd>
    return -1;
    80005132:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005134:	04054163          	bltz	a0,80005176 <sys_write+0x5c>
    80005138:	fe440593          	addi	a1,s0,-28
    8000513c:	4509                	li	a0,2
    8000513e:	ffffd097          	auipc	ra,0xffffd
    80005142:	698080e7          	jalr	1688(ra) # 800027d6 <argint>
    return -1;
    80005146:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005148:	02054763          	bltz	a0,80005176 <sys_write+0x5c>
    8000514c:	fd840593          	addi	a1,s0,-40
    80005150:	4505                	li	a0,1
    80005152:	ffffd097          	auipc	ra,0xffffd
    80005156:	6a6080e7          	jalr	1702(ra) # 800027f8 <argaddr>
    return -1;
    8000515a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000515c:	00054d63          	bltz	a0,80005176 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005160:	fe442603          	lw	a2,-28(s0)
    80005164:	fd843583          	ld	a1,-40(s0)
    80005168:	fe843503          	ld	a0,-24(s0)
    8000516c:	fffff097          	auipc	ra,0xfffff
    80005170:	4c2080e7          	jalr	1218(ra) # 8000462e <filewrite>
    80005174:	87aa                	mv	a5,a0
}
    80005176:	853e                	mv	a0,a5
    80005178:	70a2                	ld	ra,40(sp)
    8000517a:	7402                	ld	s0,32(sp)
    8000517c:	6145                	addi	sp,sp,48
    8000517e:	8082                	ret

0000000080005180 <sys_close>:
{
    80005180:	1101                	addi	sp,sp,-32
    80005182:	ec06                	sd	ra,24(sp)
    80005184:	e822                	sd	s0,16(sp)
    80005186:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005188:	fe040613          	addi	a2,s0,-32
    8000518c:	fec40593          	addi	a1,s0,-20
    80005190:	4501                	li	a0,0
    80005192:	00000097          	auipc	ra,0x0
    80005196:	cc4080e7          	jalr	-828(ra) # 80004e56 <argfd>
    return -1;
    8000519a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000519c:	02054463          	bltz	a0,800051c4 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800051a0:	ffffc097          	auipc	ra,0xffffc
    800051a4:	57c080e7          	jalr	1404(ra) # 8000171c <myproc>
    800051a8:	fec42783          	lw	a5,-20(s0)
    800051ac:	07e9                	addi	a5,a5,26
    800051ae:	078e                	slli	a5,a5,0x3
    800051b0:	97aa                	add	a5,a5,a0
    800051b2:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800051b6:	fe043503          	ld	a0,-32(s0)
    800051ba:	fffff097          	auipc	ra,0xfffff
    800051be:	264080e7          	jalr	612(ra) # 8000441e <fileclose>
  return 0;
    800051c2:	4781                	li	a5,0
}
    800051c4:	853e                	mv	a0,a5
    800051c6:	60e2                	ld	ra,24(sp)
    800051c8:	6442                	ld	s0,16(sp)
    800051ca:	6105                	addi	sp,sp,32
    800051cc:	8082                	ret

00000000800051ce <sys_fstat>:
{
    800051ce:	1101                	addi	sp,sp,-32
    800051d0:	ec06                	sd	ra,24(sp)
    800051d2:	e822                	sd	s0,16(sp)
    800051d4:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800051d6:	fe840613          	addi	a2,s0,-24
    800051da:	4581                	li	a1,0
    800051dc:	4501                	li	a0,0
    800051de:	00000097          	auipc	ra,0x0
    800051e2:	c78080e7          	jalr	-904(ra) # 80004e56 <argfd>
    return -1;
    800051e6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800051e8:	02054563          	bltz	a0,80005212 <sys_fstat+0x44>
    800051ec:	fe040593          	addi	a1,s0,-32
    800051f0:	4505                	li	a0,1
    800051f2:	ffffd097          	auipc	ra,0xffffd
    800051f6:	606080e7          	jalr	1542(ra) # 800027f8 <argaddr>
    return -1;
    800051fa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800051fc:	00054b63          	bltz	a0,80005212 <sys_fstat+0x44>
  return filestat(f, st);
    80005200:	fe043583          	ld	a1,-32(s0)
    80005204:	fe843503          	ld	a0,-24(s0)
    80005208:	fffff097          	auipc	ra,0xfffff
    8000520c:	2f2080e7          	jalr	754(ra) # 800044fa <filestat>
    80005210:	87aa                	mv	a5,a0
}
    80005212:	853e                	mv	a0,a5
    80005214:	60e2                	ld	ra,24(sp)
    80005216:	6442                	ld	s0,16(sp)
    80005218:	6105                	addi	sp,sp,32
    8000521a:	8082                	ret

000000008000521c <sys_link>:
{
    8000521c:	7169                	addi	sp,sp,-304
    8000521e:	f606                	sd	ra,296(sp)
    80005220:	f222                	sd	s0,288(sp)
    80005222:	ee26                	sd	s1,280(sp)
    80005224:	ea4a                	sd	s2,272(sp)
    80005226:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005228:	08000613          	li	a2,128
    8000522c:	ed040593          	addi	a1,s0,-304
    80005230:	4501                	li	a0,0
    80005232:	ffffd097          	auipc	ra,0xffffd
    80005236:	5e8080e7          	jalr	1512(ra) # 8000281a <argstr>
    return -1;
    8000523a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000523c:	12054363          	bltz	a0,80005362 <sys_link+0x146>
    80005240:	08000613          	li	a2,128
    80005244:	f5040593          	addi	a1,s0,-176
    80005248:	4505                	li	a0,1
    8000524a:	ffffd097          	auipc	ra,0xffffd
    8000524e:	5d0080e7          	jalr	1488(ra) # 8000281a <argstr>
    return -1;
    80005252:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005254:	10054763          	bltz	a0,80005362 <sys_link+0x146>
  begin_op(ROOTDEV);
    80005258:	4501                	li	a0,0
    8000525a:	fffff097          	auipc	ra,0xfffff
    8000525e:	b9c080e7          	jalr	-1124(ra) # 80003df6 <begin_op>
  if((ip = namei(old)) == 0){
    80005262:	ed040513          	addi	a0,s0,-304
    80005266:	fffff097          	auipc	ra,0xfffff
    8000526a:	872080e7          	jalr	-1934(ra) # 80003ad8 <namei>
    8000526e:	84aa                	mv	s1,a0
    80005270:	c559                	beqz	a0,800052fe <sys_link+0xe2>
  ilock(ip);
    80005272:	ffffe097          	auipc	ra,0xffffe
    80005276:	0da080e7          	jalr	218(ra) # 8000334c <ilock>
  if(ip->type == T_DIR){
    8000527a:	04449703          	lh	a4,68(s1)
    8000527e:	4785                	li	a5,1
    80005280:	08f70663          	beq	a4,a5,8000530c <sys_link+0xf0>
  ip->nlink++;
    80005284:	04a4d783          	lhu	a5,74(s1)
    80005288:	2785                	addiw	a5,a5,1
    8000528a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000528e:	8526                	mv	a0,s1
    80005290:	ffffe097          	auipc	ra,0xffffe
    80005294:	ff2080e7          	jalr	-14(ra) # 80003282 <iupdate>
  iunlock(ip);
    80005298:	8526                	mv	a0,s1
    8000529a:	ffffe097          	auipc	ra,0xffffe
    8000529e:	174080e7          	jalr	372(ra) # 8000340e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800052a2:	fd040593          	addi	a1,s0,-48
    800052a6:	f5040513          	addi	a0,s0,-176
    800052aa:	fffff097          	auipc	ra,0xfffff
    800052ae:	84c080e7          	jalr	-1972(ra) # 80003af6 <nameiparent>
    800052b2:	892a                	mv	s2,a0
    800052b4:	cd2d                	beqz	a0,8000532e <sys_link+0x112>
  ilock(dp);
    800052b6:	ffffe097          	auipc	ra,0xffffe
    800052ba:	096080e7          	jalr	150(ra) # 8000334c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800052be:	00092703          	lw	a4,0(s2)
    800052c2:	409c                	lw	a5,0(s1)
    800052c4:	06f71063          	bne	a4,a5,80005324 <sys_link+0x108>
    800052c8:	40d0                	lw	a2,4(s1)
    800052ca:	fd040593          	addi	a1,s0,-48
    800052ce:	854a                	mv	a0,s2
    800052d0:	ffffe097          	auipc	ra,0xffffe
    800052d4:	746080e7          	jalr	1862(ra) # 80003a16 <dirlink>
    800052d8:	04054663          	bltz	a0,80005324 <sys_link+0x108>
  iunlockput(dp);
    800052dc:	854a                	mv	a0,s2
    800052de:	ffffe097          	auipc	ra,0xffffe
    800052e2:	2ac080e7          	jalr	684(ra) # 8000358a <iunlockput>
  iput(ip);
    800052e6:	8526                	mv	a0,s1
    800052e8:	ffffe097          	auipc	ra,0xffffe
    800052ec:	172080e7          	jalr	370(ra) # 8000345a <iput>
  end_op(ROOTDEV);
    800052f0:	4501                	li	a0,0
    800052f2:	fffff097          	auipc	ra,0xfffff
    800052f6:	bae080e7          	jalr	-1106(ra) # 80003ea0 <end_op>
  return 0;
    800052fa:	4781                	li	a5,0
    800052fc:	a09d                	j	80005362 <sys_link+0x146>
    end_op(ROOTDEV);
    800052fe:	4501                	li	a0,0
    80005300:	fffff097          	auipc	ra,0xfffff
    80005304:	ba0080e7          	jalr	-1120(ra) # 80003ea0 <end_op>
    return -1;
    80005308:	57fd                	li	a5,-1
    8000530a:	a8a1                	j	80005362 <sys_link+0x146>
    iunlockput(ip);
    8000530c:	8526                	mv	a0,s1
    8000530e:	ffffe097          	auipc	ra,0xffffe
    80005312:	27c080e7          	jalr	636(ra) # 8000358a <iunlockput>
    end_op(ROOTDEV);
    80005316:	4501                	li	a0,0
    80005318:	fffff097          	auipc	ra,0xfffff
    8000531c:	b88080e7          	jalr	-1144(ra) # 80003ea0 <end_op>
    return -1;
    80005320:	57fd                	li	a5,-1
    80005322:	a081                	j	80005362 <sys_link+0x146>
    iunlockput(dp);
    80005324:	854a                	mv	a0,s2
    80005326:	ffffe097          	auipc	ra,0xffffe
    8000532a:	264080e7          	jalr	612(ra) # 8000358a <iunlockput>
  ilock(ip);
    8000532e:	8526                	mv	a0,s1
    80005330:	ffffe097          	auipc	ra,0xffffe
    80005334:	01c080e7          	jalr	28(ra) # 8000334c <ilock>
  ip->nlink--;
    80005338:	04a4d783          	lhu	a5,74(s1)
    8000533c:	37fd                	addiw	a5,a5,-1
    8000533e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005342:	8526                	mv	a0,s1
    80005344:	ffffe097          	auipc	ra,0xffffe
    80005348:	f3e080e7          	jalr	-194(ra) # 80003282 <iupdate>
  iunlockput(ip);
    8000534c:	8526                	mv	a0,s1
    8000534e:	ffffe097          	auipc	ra,0xffffe
    80005352:	23c080e7          	jalr	572(ra) # 8000358a <iunlockput>
  end_op(ROOTDEV);
    80005356:	4501                	li	a0,0
    80005358:	fffff097          	auipc	ra,0xfffff
    8000535c:	b48080e7          	jalr	-1208(ra) # 80003ea0 <end_op>
  return -1;
    80005360:	57fd                	li	a5,-1
}
    80005362:	853e                	mv	a0,a5
    80005364:	70b2                	ld	ra,296(sp)
    80005366:	7412                	ld	s0,288(sp)
    80005368:	64f2                	ld	s1,280(sp)
    8000536a:	6952                	ld	s2,272(sp)
    8000536c:	6155                	addi	sp,sp,304
    8000536e:	8082                	ret

0000000080005370 <sys_unlink>:
{
    80005370:	7151                	addi	sp,sp,-240
    80005372:	f586                	sd	ra,232(sp)
    80005374:	f1a2                	sd	s0,224(sp)
    80005376:	eda6                	sd	s1,216(sp)
    80005378:	e9ca                	sd	s2,208(sp)
    8000537a:	e5ce                	sd	s3,200(sp)
    8000537c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000537e:	08000613          	li	a2,128
    80005382:	f3040593          	addi	a1,s0,-208
    80005386:	4501                	li	a0,0
    80005388:	ffffd097          	auipc	ra,0xffffd
    8000538c:	492080e7          	jalr	1170(ra) # 8000281a <argstr>
    80005390:	18054463          	bltz	a0,80005518 <sys_unlink+0x1a8>
  begin_op(ROOTDEV);
    80005394:	4501                	li	a0,0
    80005396:	fffff097          	auipc	ra,0xfffff
    8000539a:	a60080e7          	jalr	-1440(ra) # 80003df6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000539e:	fb040593          	addi	a1,s0,-80
    800053a2:	f3040513          	addi	a0,s0,-208
    800053a6:	ffffe097          	auipc	ra,0xffffe
    800053aa:	750080e7          	jalr	1872(ra) # 80003af6 <nameiparent>
    800053ae:	84aa                	mv	s1,a0
    800053b0:	cd61                	beqz	a0,80005488 <sys_unlink+0x118>
  ilock(dp);
    800053b2:	ffffe097          	auipc	ra,0xffffe
    800053b6:	f9a080e7          	jalr	-102(ra) # 8000334c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800053ba:	00002597          	auipc	a1,0x2
    800053be:	39658593          	addi	a1,a1,918 # 80007750 <userret+0x6c0>
    800053c2:	fb040513          	addi	a0,s0,-80
    800053c6:	ffffe097          	auipc	ra,0xffffe
    800053ca:	426080e7          	jalr	1062(ra) # 800037ec <namecmp>
    800053ce:	14050c63          	beqz	a0,80005526 <sys_unlink+0x1b6>
    800053d2:	00002597          	auipc	a1,0x2
    800053d6:	38658593          	addi	a1,a1,902 # 80007758 <userret+0x6c8>
    800053da:	fb040513          	addi	a0,s0,-80
    800053de:	ffffe097          	auipc	ra,0xffffe
    800053e2:	40e080e7          	jalr	1038(ra) # 800037ec <namecmp>
    800053e6:	14050063          	beqz	a0,80005526 <sys_unlink+0x1b6>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800053ea:	f2c40613          	addi	a2,s0,-212
    800053ee:	fb040593          	addi	a1,s0,-80
    800053f2:	8526                	mv	a0,s1
    800053f4:	ffffe097          	auipc	ra,0xffffe
    800053f8:	412080e7          	jalr	1042(ra) # 80003806 <dirlookup>
    800053fc:	892a                	mv	s2,a0
    800053fe:	12050463          	beqz	a0,80005526 <sys_unlink+0x1b6>
  ilock(ip);
    80005402:	ffffe097          	auipc	ra,0xffffe
    80005406:	f4a080e7          	jalr	-182(ra) # 8000334c <ilock>
  if(ip->nlink < 1)
    8000540a:	04a91783          	lh	a5,74(s2)
    8000540e:	08f05463          	blez	a5,80005496 <sys_unlink+0x126>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005412:	04491703          	lh	a4,68(s2)
    80005416:	4785                	li	a5,1
    80005418:	08f70763          	beq	a4,a5,800054a6 <sys_unlink+0x136>
  memset(&de, 0, sizeof(de));
    8000541c:	4641                	li	a2,16
    8000541e:	4581                	li	a1,0
    80005420:	fc040513          	addi	a0,s0,-64
    80005424:	ffffb097          	auipc	ra,0xffffb
    80005428:	65c080e7          	jalr	1628(ra) # 80000a80 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000542c:	4741                	li	a4,16
    8000542e:	f2c42683          	lw	a3,-212(s0)
    80005432:	fc040613          	addi	a2,s0,-64
    80005436:	4581                	li	a1,0
    80005438:	8526                	mv	a0,s1
    8000543a:	ffffe097          	auipc	ra,0xffffe
    8000543e:	296080e7          	jalr	662(ra) # 800036d0 <writei>
    80005442:	47c1                	li	a5,16
    80005444:	0af51763          	bne	a0,a5,800054f2 <sys_unlink+0x182>
  if(ip->type == T_DIR){
    80005448:	04491703          	lh	a4,68(s2)
    8000544c:	4785                	li	a5,1
    8000544e:	0af70a63          	beq	a4,a5,80005502 <sys_unlink+0x192>
  iunlockput(dp);
    80005452:	8526                	mv	a0,s1
    80005454:	ffffe097          	auipc	ra,0xffffe
    80005458:	136080e7          	jalr	310(ra) # 8000358a <iunlockput>
  ip->nlink--;
    8000545c:	04a95783          	lhu	a5,74(s2)
    80005460:	37fd                	addiw	a5,a5,-1
    80005462:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005466:	854a                	mv	a0,s2
    80005468:	ffffe097          	auipc	ra,0xffffe
    8000546c:	e1a080e7          	jalr	-486(ra) # 80003282 <iupdate>
  iunlockput(ip);
    80005470:	854a                	mv	a0,s2
    80005472:	ffffe097          	auipc	ra,0xffffe
    80005476:	118080e7          	jalr	280(ra) # 8000358a <iunlockput>
  end_op(ROOTDEV);
    8000547a:	4501                	li	a0,0
    8000547c:	fffff097          	auipc	ra,0xfffff
    80005480:	a24080e7          	jalr	-1500(ra) # 80003ea0 <end_op>
  return 0;
    80005484:	4501                	li	a0,0
    80005486:	a85d                	j	8000553c <sys_unlink+0x1cc>
    end_op(ROOTDEV);
    80005488:	4501                	li	a0,0
    8000548a:	fffff097          	auipc	ra,0xfffff
    8000548e:	a16080e7          	jalr	-1514(ra) # 80003ea0 <end_op>
    return -1;
    80005492:	557d                	li	a0,-1
    80005494:	a065                	j	8000553c <sys_unlink+0x1cc>
    panic("unlink: nlink < 1");
    80005496:	00002517          	auipc	a0,0x2
    8000549a:	2ea50513          	addi	a0,a0,746 # 80007780 <userret+0x6f0>
    8000549e:	ffffb097          	auipc	ra,0xffffb
    800054a2:	0aa080e7          	jalr	170(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800054a6:	04c92703          	lw	a4,76(s2)
    800054aa:	02000793          	li	a5,32
    800054ae:	f6e7f7e3          	bgeu	a5,a4,8000541c <sys_unlink+0xac>
    800054b2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800054b6:	4741                	li	a4,16
    800054b8:	86ce                	mv	a3,s3
    800054ba:	f1840613          	addi	a2,s0,-232
    800054be:	4581                	li	a1,0
    800054c0:	854a                	mv	a0,s2
    800054c2:	ffffe097          	auipc	ra,0xffffe
    800054c6:	11a080e7          	jalr	282(ra) # 800035dc <readi>
    800054ca:	47c1                	li	a5,16
    800054cc:	00f51b63          	bne	a0,a5,800054e2 <sys_unlink+0x172>
    if(de.inum != 0)
    800054d0:	f1845783          	lhu	a5,-232(s0)
    800054d4:	e7a1                	bnez	a5,8000551c <sys_unlink+0x1ac>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800054d6:	29c1                	addiw	s3,s3,16
    800054d8:	04c92783          	lw	a5,76(s2)
    800054dc:	fcf9ede3          	bltu	s3,a5,800054b6 <sys_unlink+0x146>
    800054e0:	bf35                	j	8000541c <sys_unlink+0xac>
      panic("isdirempty: readi");
    800054e2:	00002517          	auipc	a0,0x2
    800054e6:	2b650513          	addi	a0,a0,694 # 80007798 <userret+0x708>
    800054ea:	ffffb097          	auipc	ra,0xffffb
    800054ee:	05e080e7          	jalr	94(ra) # 80000548 <panic>
    panic("unlink: writei");
    800054f2:	00002517          	auipc	a0,0x2
    800054f6:	2be50513          	addi	a0,a0,702 # 800077b0 <userret+0x720>
    800054fa:	ffffb097          	auipc	ra,0xffffb
    800054fe:	04e080e7          	jalr	78(ra) # 80000548 <panic>
    dp->nlink--;
    80005502:	04a4d783          	lhu	a5,74(s1)
    80005506:	37fd                	addiw	a5,a5,-1
    80005508:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000550c:	8526                	mv	a0,s1
    8000550e:	ffffe097          	auipc	ra,0xffffe
    80005512:	d74080e7          	jalr	-652(ra) # 80003282 <iupdate>
    80005516:	bf35                	j	80005452 <sys_unlink+0xe2>
    return -1;
    80005518:	557d                	li	a0,-1
    8000551a:	a00d                	j	8000553c <sys_unlink+0x1cc>
    iunlockput(ip);
    8000551c:	854a                	mv	a0,s2
    8000551e:	ffffe097          	auipc	ra,0xffffe
    80005522:	06c080e7          	jalr	108(ra) # 8000358a <iunlockput>
  iunlockput(dp);
    80005526:	8526                	mv	a0,s1
    80005528:	ffffe097          	auipc	ra,0xffffe
    8000552c:	062080e7          	jalr	98(ra) # 8000358a <iunlockput>
  end_op(ROOTDEV);
    80005530:	4501                	li	a0,0
    80005532:	fffff097          	auipc	ra,0xfffff
    80005536:	96e080e7          	jalr	-1682(ra) # 80003ea0 <end_op>
  return -1;
    8000553a:	557d                	li	a0,-1
}
    8000553c:	70ae                	ld	ra,232(sp)
    8000553e:	740e                	ld	s0,224(sp)
    80005540:	64ee                	ld	s1,216(sp)
    80005542:	694e                	ld	s2,208(sp)
    80005544:	69ae                	ld	s3,200(sp)
    80005546:	616d                	addi	sp,sp,240
    80005548:	8082                	ret

000000008000554a <sys_open>:

uint64
sys_open(void)
{
    8000554a:	7131                	addi	sp,sp,-192
    8000554c:	fd06                	sd	ra,184(sp)
    8000554e:	f922                	sd	s0,176(sp)
    80005550:	f526                	sd	s1,168(sp)
    80005552:	f14a                	sd	s2,160(sp)
    80005554:	ed4e                	sd	s3,152(sp)
    80005556:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005558:	08000613          	li	a2,128
    8000555c:	f5040593          	addi	a1,s0,-176
    80005560:	4501                	li	a0,0
    80005562:	ffffd097          	auipc	ra,0xffffd
    80005566:	2b8080e7          	jalr	696(ra) # 8000281a <argstr>
    return -1;
    8000556a:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000556c:	0a054963          	bltz	a0,8000561e <sys_open+0xd4>
    80005570:	f4c40593          	addi	a1,s0,-180
    80005574:	4505                	li	a0,1
    80005576:	ffffd097          	auipc	ra,0xffffd
    8000557a:	260080e7          	jalr	608(ra) # 800027d6 <argint>
    8000557e:	0a054063          	bltz	a0,8000561e <sys_open+0xd4>

  begin_op(ROOTDEV);
    80005582:	4501                	li	a0,0
    80005584:	fffff097          	auipc	ra,0xfffff
    80005588:	872080e7          	jalr	-1934(ra) # 80003df6 <begin_op>

  if(omode & O_CREATE){
    8000558c:	f4c42783          	lw	a5,-180(s0)
    80005590:	2007f793          	andi	a5,a5,512
    80005594:	c3dd                	beqz	a5,8000563a <sys_open+0xf0>
    ip = create(path, T_FILE, 0, 0);
    80005596:	4681                	li	a3,0
    80005598:	4601                	li	a2,0
    8000559a:	4589                	li	a1,2
    8000559c:	f5040513          	addi	a0,s0,-176
    800055a0:	00000097          	auipc	ra,0x0
    800055a4:	960080e7          	jalr	-1696(ra) # 80004f00 <create>
    800055a8:	892a                	mv	s2,a0
    if(ip == 0){
    800055aa:	c151                	beqz	a0,8000562e <sys_open+0xe4>
      end_op(ROOTDEV);
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800055ac:	04491703          	lh	a4,68(s2)
    800055b0:	478d                	li	a5,3
    800055b2:	00f71763          	bne	a4,a5,800055c0 <sys_open+0x76>
    800055b6:	04695703          	lhu	a4,70(s2)
    800055ba:	47a5                	li	a5,9
    800055bc:	0ce7e663          	bltu	a5,a4,80005688 <sys_open+0x13e>
    iunlockput(ip);
    end_op(ROOTDEV);
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800055c0:	fffff097          	auipc	ra,0xfffff
    800055c4:	da2080e7          	jalr	-606(ra) # 80004362 <filealloc>
    800055c8:	89aa                	mv	s3,a0
    800055ca:	c57d                	beqz	a0,800056b8 <sys_open+0x16e>
    800055cc:	00000097          	auipc	ra,0x0
    800055d0:	8f2080e7          	jalr	-1806(ra) # 80004ebe <fdalloc>
    800055d4:	84aa                	mv	s1,a0
    800055d6:	0c054c63          	bltz	a0,800056ae <sys_open+0x164>
    iunlockput(ip);
    end_op(ROOTDEV);
    return -1;
  }

  if(ip->type == T_DEVICE){
    800055da:	04491703          	lh	a4,68(s2)
    800055de:	478d                	li	a5,3
    800055e0:	0cf70063          	beq	a4,a5,800056a0 <sys_open+0x156>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800055e4:	4789                	li	a5,2
    800055e6:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800055ea:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800055ee:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800055f2:	f4c42783          	lw	a5,-180(s0)
    800055f6:	0017c713          	xori	a4,a5,1
    800055fa:	8b05                	andi	a4,a4,1
    800055fc:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005600:	8b8d                	andi	a5,a5,3
    80005602:	00f037b3          	snez	a5,a5
    80005606:	00f984a3          	sb	a5,9(s3)

  iunlock(ip);
    8000560a:	854a                	mv	a0,s2
    8000560c:	ffffe097          	auipc	ra,0xffffe
    80005610:	e02080e7          	jalr	-510(ra) # 8000340e <iunlock>
  end_op(ROOTDEV);
    80005614:	4501                	li	a0,0
    80005616:	fffff097          	auipc	ra,0xfffff
    8000561a:	88a080e7          	jalr	-1910(ra) # 80003ea0 <end_op>

  return fd;
}
    8000561e:	8526                	mv	a0,s1
    80005620:	70ea                	ld	ra,184(sp)
    80005622:	744a                	ld	s0,176(sp)
    80005624:	74aa                	ld	s1,168(sp)
    80005626:	790a                	ld	s2,160(sp)
    80005628:	69ea                	ld	s3,152(sp)
    8000562a:	6129                	addi	sp,sp,192
    8000562c:	8082                	ret
      end_op(ROOTDEV);
    8000562e:	4501                	li	a0,0
    80005630:	fffff097          	auipc	ra,0xfffff
    80005634:	870080e7          	jalr	-1936(ra) # 80003ea0 <end_op>
      return -1;
    80005638:	b7dd                	j	8000561e <sys_open+0xd4>
    if((ip = namei(path)) == 0){
    8000563a:	f5040513          	addi	a0,s0,-176
    8000563e:	ffffe097          	auipc	ra,0xffffe
    80005642:	49a080e7          	jalr	1178(ra) # 80003ad8 <namei>
    80005646:	892a                	mv	s2,a0
    80005648:	c90d                	beqz	a0,8000567a <sys_open+0x130>
    ilock(ip);
    8000564a:	ffffe097          	auipc	ra,0xffffe
    8000564e:	d02080e7          	jalr	-766(ra) # 8000334c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005652:	04491703          	lh	a4,68(s2)
    80005656:	4785                	li	a5,1
    80005658:	f4f71ae3          	bne	a4,a5,800055ac <sys_open+0x62>
    8000565c:	f4c42783          	lw	a5,-180(s0)
    80005660:	d3a5                	beqz	a5,800055c0 <sys_open+0x76>
      iunlockput(ip);
    80005662:	854a                	mv	a0,s2
    80005664:	ffffe097          	auipc	ra,0xffffe
    80005668:	f26080e7          	jalr	-218(ra) # 8000358a <iunlockput>
      end_op(ROOTDEV);
    8000566c:	4501                	li	a0,0
    8000566e:	fffff097          	auipc	ra,0xfffff
    80005672:	832080e7          	jalr	-1998(ra) # 80003ea0 <end_op>
      return -1;
    80005676:	54fd                	li	s1,-1
    80005678:	b75d                	j	8000561e <sys_open+0xd4>
      end_op(ROOTDEV);
    8000567a:	4501                	li	a0,0
    8000567c:	fffff097          	auipc	ra,0xfffff
    80005680:	824080e7          	jalr	-2012(ra) # 80003ea0 <end_op>
      return -1;
    80005684:	54fd                	li	s1,-1
    80005686:	bf61                	j	8000561e <sys_open+0xd4>
    iunlockput(ip);
    80005688:	854a                	mv	a0,s2
    8000568a:	ffffe097          	auipc	ra,0xffffe
    8000568e:	f00080e7          	jalr	-256(ra) # 8000358a <iunlockput>
    end_op(ROOTDEV);
    80005692:	4501                	li	a0,0
    80005694:	fffff097          	auipc	ra,0xfffff
    80005698:	80c080e7          	jalr	-2036(ra) # 80003ea0 <end_op>
    return -1;
    8000569c:	54fd                	li	s1,-1
    8000569e:	b741                	j	8000561e <sys_open+0xd4>
    f->type = FD_DEVICE;
    800056a0:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800056a4:	04691783          	lh	a5,70(s2)
    800056a8:	02f99223          	sh	a5,36(s3)
    800056ac:	b789                	j	800055ee <sys_open+0xa4>
      fileclose(f);
    800056ae:	854e                	mv	a0,s3
    800056b0:	fffff097          	auipc	ra,0xfffff
    800056b4:	d6e080e7          	jalr	-658(ra) # 8000441e <fileclose>
    iunlockput(ip);
    800056b8:	854a                	mv	a0,s2
    800056ba:	ffffe097          	auipc	ra,0xffffe
    800056be:	ed0080e7          	jalr	-304(ra) # 8000358a <iunlockput>
    end_op(ROOTDEV);
    800056c2:	4501                	li	a0,0
    800056c4:	ffffe097          	auipc	ra,0xffffe
    800056c8:	7dc080e7          	jalr	2012(ra) # 80003ea0 <end_op>
    return -1;
    800056cc:	54fd                	li	s1,-1
    800056ce:	bf81                	j	8000561e <sys_open+0xd4>

00000000800056d0 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800056d0:	7175                	addi	sp,sp,-144
    800056d2:	e506                	sd	ra,136(sp)
    800056d4:	e122                	sd	s0,128(sp)
    800056d6:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op(ROOTDEV);
    800056d8:	4501                	li	a0,0
    800056da:	ffffe097          	auipc	ra,0xffffe
    800056de:	71c080e7          	jalr	1820(ra) # 80003df6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800056e2:	08000613          	li	a2,128
    800056e6:	f7040593          	addi	a1,s0,-144
    800056ea:	4501                	li	a0,0
    800056ec:	ffffd097          	auipc	ra,0xffffd
    800056f0:	12e080e7          	jalr	302(ra) # 8000281a <argstr>
    800056f4:	02054a63          	bltz	a0,80005728 <sys_mkdir+0x58>
    800056f8:	4681                	li	a3,0
    800056fa:	4601                	li	a2,0
    800056fc:	4585                	li	a1,1
    800056fe:	f7040513          	addi	a0,s0,-144
    80005702:	fffff097          	auipc	ra,0xfffff
    80005706:	7fe080e7          	jalr	2046(ra) # 80004f00 <create>
    8000570a:	cd19                	beqz	a0,80005728 <sys_mkdir+0x58>
    end_op(ROOTDEV);
    return -1;
  }
  iunlockput(ip);
    8000570c:	ffffe097          	auipc	ra,0xffffe
    80005710:	e7e080e7          	jalr	-386(ra) # 8000358a <iunlockput>
  end_op(ROOTDEV);
    80005714:	4501                	li	a0,0
    80005716:	ffffe097          	auipc	ra,0xffffe
    8000571a:	78a080e7          	jalr	1930(ra) # 80003ea0 <end_op>
  return 0;
    8000571e:	4501                	li	a0,0
}
    80005720:	60aa                	ld	ra,136(sp)
    80005722:	640a                	ld	s0,128(sp)
    80005724:	6149                	addi	sp,sp,144
    80005726:	8082                	ret
    end_op(ROOTDEV);
    80005728:	4501                	li	a0,0
    8000572a:	ffffe097          	auipc	ra,0xffffe
    8000572e:	776080e7          	jalr	1910(ra) # 80003ea0 <end_op>
    return -1;
    80005732:	557d                	li	a0,-1
    80005734:	b7f5                	j	80005720 <sys_mkdir+0x50>

0000000080005736 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005736:	7135                	addi	sp,sp,-160
    80005738:	ed06                	sd	ra,152(sp)
    8000573a:	e922                	sd	s0,144(sp)
    8000573c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op(ROOTDEV);
    8000573e:	4501                	li	a0,0
    80005740:	ffffe097          	auipc	ra,0xffffe
    80005744:	6b6080e7          	jalr	1718(ra) # 80003df6 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005748:	08000613          	li	a2,128
    8000574c:	f7040593          	addi	a1,s0,-144
    80005750:	4501                	li	a0,0
    80005752:	ffffd097          	auipc	ra,0xffffd
    80005756:	0c8080e7          	jalr	200(ra) # 8000281a <argstr>
    8000575a:	04054b63          	bltz	a0,800057b0 <sys_mknod+0x7a>
     argint(1, &major) < 0 ||
    8000575e:	f6c40593          	addi	a1,s0,-148
    80005762:	4505                	li	a0,1
    80005764:	ffffd097          	auipc	ra,0xffffd
    80005768:	072080e7          	jalr	114(ra) # 800027d6 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000576c:	04054263          	bltz	a0,800057b0 <sys_mknod+0x7a>
     argint(2, &minor) < 0 ||
    80005770:	f6840593          	addi	a1,s0,-152
    80005774:	4509                	li	a0,2
    80005776:	ffffd097          	auipc	ra,0xffffd
    8000577a:	060080e7          	jalr	96(ra) # 800027d6 <argint>
     argint(1, &major) < 0 ||
    8000577e:	02054963          	bltz	a0,800057b0 <sys_mknod+0x7a>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005782:	f6841683          	lh	a3,-152(s0)
    80005786:	f6c41603          	lh	a2,-148(s0)
    8000578a:	458d                	li	a1,3
    8000578c:	f7040513          	addi	a0,s0,-144
    80005790:	fffff097          	auipc	ra,0xfffff
    80005794:	770080e7          	jalr	1904(ra) # 80004f00 <create>
     argint(2, &minor) < 0 ||
    80005798:	cd01                	beqz	a0,800057b0 <sys_mknod+0x7a>
    end_op(ROOTDEV);
    return -1;
  }
  iunlockput(ip);
    8000579a:	ffffe097          	auipc	ra,0xffffe
    8000579e:	df0080e7          	jalr	-528(ra) # 8000358a <iunlockput>
  end_op(ROOTDEV);
    800057a2:	4501                	li	a0,0
    800057a4:	ffffe097          	auipc	ra,0xffffe
    800057a8:	6fc080e7          	jalr	1788(ra) # 80003ea0 <end_op>
  return 0;
    800057ac:	4501                	li	a0,0
    800057ae:	a039                	j	800057bc <sys_mknod+0x86>
    end_op(ROOTDEV);
    800057b0:	4501                	li	a0,0
    800057b2:	ffffe097          	auipc	ra,0xffffe
    800057b6:	6ee080e7          	jalr	1774(ra) # 80003ea0 <end_op>
    return -1;
    800057ba:	557d                	li	a0,-1
}
    800057bc:	60ea                	ld	ra,152(sp)
    800057be:	644a                	ld	s0,144(sp)
    800057c0:	610d                	addi	sp,sp,160
    800057c2:	8082                	ret

00000000800057c4 <sys_chdir>:

uint64
sys_chdir(void)
{
    800057c4:	7135                	addi	sp,sp,-160
    800057c6:	ed06                	sd	ra,152(sp)
    800057c8:	e922                	sd	s0,144(sp)
    800057ca:	e526                	sd	s1,136(sp)
    800057cc:	e14a                	sd	s2,128(sp)
    800057ce:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800057d0:	ffffc097          	auipc	ra,0xffffc
    800057d4:	f4c080e7          	jalr	-180(ra) # 8000171c <myproc>
    800057d8:	892a                	mv	s2,a0
  
  begin_op(ROOTDEV);
    800057da:	4501                	li	a0,0
    800057dc:	ffffe097          	auipc	ra,0xffffe
    800057e0:	61a080e7          	jalr	1562(ra) # 80003df6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800057e4:	08000613          	li	a2,128
    800057e8:	f6040593          	addi	a1,s0,-160
    800057ec:	4501                	li	a0,0
    800057ee:	ffffd097          	auipc	ra,0xffffd
    800057f2:	02c080e7          	jalr	44(ra) # 8000281a <argstr>
    800057f6:	04054c63          	bltz	a0,8000584e <sys_chdir+0x8a>
    800057fa:	f6040513          	addi	a0,s0,-160
    800057fe:	ffffe097          	auipc	ra,0xffffe
    80005802:	2da080e7          	jalr	730(ra) # 80003ad8 <namei>
    80005806:	84aa                	mv	s1,a0
    80005808:	c139                	beqz	a0,8000584e <sys_chdir+0x8a>
    end_op(ROOTDEV);
    return -1;
  }
  ilock(ip);
    8000580a:	ffffe097          	auipc	ra,0xffffe
    8000580e:	b42080e7          	jalr	-1214(ra) # 8000334c <ilock>
  if(ip->type != T_DIR){
    80005812:	04449703          	lh	a4,68(s1)
    80005816:	4785                	li	a5,1
    80005818:	04f71263          	bne	a4,a5,8000585c <sys_chdir+0x98>
    iunlockput(ip);
    end_op(ROOTDEV);
    return -1;
  }
  iunlock(ip);
    8000581c:	8526                	mv	a0,s1
    8000581e:	ffffe097          	auipc	ra,0xffffe
    80005822:	bf0080e7          	jalr	-1040(ra) # 8000340e <iunlock>
  iput(p->cwd);
    80005826:	15093503          	ld	a0,336(s2)
    8000582a:	ffffe097          	auipc	ra,0xffffe
    8000582e:	c30080e7          	jalr	-976(ra) # 8000345a <iput>
  end_op(ROOTDEV);
    80005832:	4501                	li	a0,0
    80005834:	ffffe097          	auipc	ra,0xffffe
    80005838:	66c080e7          	jalr	1644(ra) # 80003ea0 <end_op>
  p->cwd = ip;
    8000583c:	14993823          	sd	s1,336(s2)
  return 0;
    80005840:	4501                	li	a0,0
}
    80005842:	60ea                	ld	ra,152(sp)
    80005844:	644a                	ld	s0,144(sp)
    80005846:	64aa                	ld	s1,136(sp)
    80005848:	690a                	ld	s2,128(sp)
    8000584a:	610d                	addi	sp,sp,160
    8000584c:	8082                	ret
    end_op(ROOTDEV);
    8000584e:	4501                	li	a0,0
    80005850:	ffffe097          	auipc	ra,0xffffe
    80005854:	650080e7          	jalr	1616(ra) # 80003ea0 <end_op>
    return -1;
    80005858:	557d                	li	a0,-1
    8000585a:	b7e5                	j	80005842 <sys_chdir+0x7e>
    iunlockput(ip);
    8000585c:	8526                	mv	a0,s1
    8000585e:	ffffe097          	auipc	ra,0xffffe
    80005862:	d2c080e7          	jalr	-724(ra) # 8000358a <iunlockput>
    end_op(ROOTDEV);
    80005866:	4501                	li	a0,0
    80005868:	ffffe097          	auipc	ra,0xffffe
    8000586c:	638080e7          	jalr	1592(ra) # 80003ea0 <end_op>
    return -1;
    80005870:	557d                	li	a0,-1
    80005872:	bfc1                	j	80005842 <sys_chdir+0x7e>

0000000080005874 <sys_exec>:

uint64
sys_exec(void)
{
    80005874:	7145                	addi	sp,sp,-464
    80005876:	e786                	sd	ra,456(sp)
    80005878:	e3a2                	sd	s0,448(sp)
    8000587a:	ff26                	sd	s1,440(sp)
    8000587c:	fb4a                	sd	s2,432(sp)
    8000587e:	f74e                	sd	s3,424(sp)
    80005880:	f352                	sd	s4,416(sp)
    80005882:	ef56                	sd	s5,408(sp)
    80005884:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005886:	08000613          	li	a2,128
    8000588a:	f4040593          	addi	a1,s0,-192
    8000588e:	4501                	li	a0,0
    80005890:	ffffd097          	auipc	ra,0xffffd
    80005894:	f8a080e7          	jalr	-118(ra) # 8000281a <argstr>
    80005898:	0c054863          	bltz	a0,80005968 <sys_exec+0xf4>
    8000589c:	e3840593          	addi	a1,s0,-456
    800058a0:	4505                	li	a0,1
    800058a2:	ffffd097          	auipc	ra,0xffffd
    800058a6:	f56080e7          	jalr	-170(ra) # 800027f8 <argaddr>
    800058aa:	0c054963          	bltz	a0,8000597c <sys_exec+0x108>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
    800058ae:	10000613          	li	a2,256
    800058b2:	4581                	li	a1,0
    800058b4:	e4040513          	addi	a0,s0,-448
    800058b8:	ffffb097          	auipc	ra,0xffffb
    800058bc:	1c8080e7          	jalr	456(ra) # 80000a80 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800058c0:	e4040993          	addi	s3,s0,-448
  memset(argv, 0, sizeof(argv));
    800058c4:	894e                	mv	s2,s3
    800058c6:	4481                	li	s1,0
    if(i >= NELEM(argv)){
    800058c8:	02000a13          	li	s4,32
    800058cc:	00048a9b          	sext.w	s5,s1
      return -1;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800058d0:	00349793          	slli	a5,s1,0x3
    800058d4:	e3040593          	addi	a1,s0,-464
    800058d8:	e3843503          	ld	a0,-456(s0)
    800058dc:	953e                	add	a0,a0,a5
    800058de:	ffffd097          	auipc	ra,0xffffd
    800058e2:	e5e080e7          	jalr	-418(ra) # 8000273c <fetchaddr>
    800058e6:	08054d63          	bltz	a0,80005980 <sys_exec+0x10c>
      return -1;
    }
    if(uarg == 0){
    800058ea:	e3043783          	ld	a5,-464(s0)
    800058ee:	cb85                	beqz	a5,8000591e <sys_exec+0xaa>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800058f0:	ffffb097          	auipc	ra,0xffffb
    800058f4:	fa4080e7          	jalr	-92(ra) # 80000894 <kalloc>
    800058f8:	85aa                	mv	a1,a0
    800058fa:	00a93023          	sd	a0,0(s2)
    if(argv[i] == 0)
    800058fe:	cd29                	beqz	a0,80005958 <sys_exec+0xe4>
      panic("sys_exec kalloc");
    if(fetchstr(uarg, argv[i], PGSIZE) < 0){
    80005900:	6605                	lui	a2,0x1
    80005902:	e3043503          	ld	a0,-464(s0)
    80005906:	ffffd097          	auipc	ra,0xffffd
    8000590a:	e88080e7          	jalr	-376(ra) # 8000278e <fetchstr>
    8000590e:	06054b63          	bltz	a0,80005984 <sys_exec+0x110>
    if(i >= NELEM(argv)){
    80005912:	0485                	addi	s1,s1,1
    80005914:	0921                	addi	s2,s2,8
    80005916:	fb449be3          	bne	s1,s4,800058cc <sys_exec+0x58>
      return -1;
    8000591a:	557d                	li	a0,-1
    8000591c:	a0b9                	j	8000596a <sys_exec+0xf6>
      argv[i] = 0;
    8000591e:	0a8e                	slli	s5,s5,0x3
    80005920:	fc040793          	addi	a5,s0,-64
    80005924:	9abe                	add	s5,s5,a5
    80005926:	e80ab023          	sd	zero,-384(s5)
      return -1;
    }
  }

  int ret = exec(path, argv);
    8000592a:	e4040593          	addi	a1,s0,-448
    8000592e:	f4040513          	addi	a0,s0,-192
    80005932:	fffff097          	auipc	ra,0xfffff
    80005936:	198080e7          	jalr	408(ra) # 80004aca <exec>
    8000593a:	84aa                	mv	s1,a0

  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000593c:	10098913          	addi	s2,s3,256
    80005940:	0009b503          	ld	a0,0(s3)
    80005944:	c901                	beqz	a0,80005954 <sys_exec+0xe0>
    kfree(argv[i]);
    80005946:	ffffb097          	auipc	ra,0xffffb
    8000594a:	f36080e7          	jalr	-202(ra) # 8000087c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000594e:	09a1                	addi	s3,s3,8
    80005950:	ff2998e3          	bne	s3,s2,80005940 <sys_exec+0xcc>

  return ret;
    80005954:	8526                	mv	a0,s1
    80005956:	a811                	j	8000596a <sys_exec+0xf6>
      panic("sys_exec kalloc");
    80005958:	00002517          	auipc	a0,0x2
    8000595c:	e6850513          	addi	a0,a0,-408 # 800077c0 <userret+0x730>
    80005960:	ffffb097          	auipc	ra,0xffffb
    80005964:	be8080e7          	jalr	-1048(ra) # 80000548 <panic>
    return -1;
    80005968:	557d                	li	a0,-1
}
    8000596a:	60be                	ld	ra,456(sp)
    8000596c:	641e                	ld	s0,448(sp)
    8000596e:	74fa                	ld	s1,440(sp)
    80005970:	795a                	ld	s2,432(sp)
    80005972:	79ba                	ld	s3,424(sp)
    80005974:	7a1a                	ld	s4,416(sp)
    80005976:	6afa                	ld	s5,408(sp)
    80005978:	6179                	addi	sp,sp,464
    8000597a:	8082                	ret
    return -1;
    8000597c:	557d                	li	a0,-1
    8000597e:	b7f5                	j	8000596a <sys_exec+0xf6>
      return -1;
    80005980:	557d                	li	a0,-1
    80005982:	b7e5                	j	8000596a <sys_exec+0xf6>
      return -1;
    80005984:	557d                	li	a0,-1
    80005986:	b7d5                	j	8000596a <sys_exec+0xf6>

0000000080005988 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005988:	7139                	addi	sp,sp,-64
    8000598a:	fc06                	sd	ra,56(sp)
    8000598c:	f822                	sd	s0,48(sp)
    8000598e:	f426                	sd	s1,40(sp)
    80005990:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005992:	ffffc097          	auipc	ra,0xffffc
    80005996:	d8a080e7          	jalr	-630(ra) # 8000171c <myproc>
    8000599a:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    8000599c:	fd840593          	addi	a1,s0,-40
    800059a0:	4501                	li	a0,0
    800059a2:	ffffd097          	auipc	ra,0xffffd
    800059a6:	e56080e7          	jalr	-426(ra) # 800027f8 <argaddr>
    return -1;
    800059aa:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800059ac:	0e054063          	bltz	a0,80005a8c <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800059b0:	fc840593          	addi	a1,s0,-56
    800059b4:	fd040513          	addi	a0,s0,-48
    800059b8:	fffff097          	auipc	ra,0xfffff
    800059bc:	dce080e7          	jalr	-562(ra) # 80004786 <pipealloc>
    return -1;
    800059c0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800059c2:	0c054563          	bltz	a0,80005a8c <sys_pipe+0x104>
  fd0 = -1;
    800059c6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800059ca:	fd043503          	ld	a0,-48(s0)
    800059ce:	fffff097          	auipc	ra,0xfffff
    800059d2:	4f0080e7          	jalr	1264(ra) # 80004ebe <fdalloc>
    800059d6:	fca42223          	sw	a0,-60(s0)
    800059da:	08054c63          	bltz	a0,80005a72 <sys_pipe+0xea>
    800059de:	fc843503          	ld	a0,-56(s0)
    800059e2:	fffff097          	auipc	ra,0xfffff
    800059e6:	4dc080e7          	jalr	1244(ra) # 80004ebe <fdalloc>
    800059ea:	fca42023          	sw	a0,-64(s0)
    800059ee:	06054863          	bltz	a0,80005a5e <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800059f2:	4691                	li	a3,4
    800059f4:	fc440613          	addi	a2,s0,-60
    800059f8:	fd843583          	ld	a1,-40(s0)
    800059fc:	68a8                	ld	a0,80(s1)
    800059fe:	ffffc097          	auipc	ra,0xffffc
    80005a02:	a42080e7          	jalr	-1470(ra) # 80001440 <copyout>
    80005a06:	02054063          	bltz	a0,80005a26 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005a0a:	4691                	li	a3,4
    80005a0c:	fc040613          	addi	a2,s0,-64
    80005a10:	fd843583          	ld	a1,-40(s0)
    80005a14:	0591                	addi	a1,a1,4
    80005a16:	68a8                	ld	a0,80(s1)
    80005a18:	ffffc097          	auipc	ra,0xffffc
    80005a1c:	a28080e7          	jalr	-1496(ra) # 80001440 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005a20:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a22:	06055563          	bgez	a0,80005a8c <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005a26:	fc442783          	lw	a5,-60(s0)
    80005a2a:	07e9                	addi	a5,a5,26
    80005a2c:	078e                	slli	a5,a5,0x3
    80005a2e:	97a6                	add	a5,a5,s1
    80005a30:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005a34:	fc042503          	lw	a0,-64(s0)
    80005a38:	0569                	addi	a0,a0,26
    80005a3a:	050e                	slli	a0,a0,0x3
    80005a3c:	9526                	add	a0,a0,s1
    80005a3e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005a42:	fd043503          	ld	a0,-48(s0)
    80005a46:	fffff097          	auipc	ra,0xfffff
    80005a4a:	9d8080e7          	jalr	-1576(ra) # 8000441e <fileclose>
    fileclose(wf);
    80005a4e:	fc843503          	ld	a0,-56(s0)
    80005a52:	fffff097          	auipc	ra,0xfffff
    80005a56:	9cc080e7          	jalr	-1588(ra) # 8000441e <fileclose>
    return -1;
    80005a5a:	57fd                	li	a5,-1
    80005a5c:	a805                	j	80005a8c <sys_pipe+0x104>
    if(fd0 >= 0)
    80005a5e:	fc442783          	lw	a5,-60(s0)
    80005a62:	0007c863          	bltz	a5,80005a72 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005a66:	01a78513          	addi	a0,a5,26
    80005a6a:	050e                	slli	a0,a0,0x3
    80005a6c:	9526                	add	a0,a0,s1
    80005a6e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005a72:	fd043503          	ld	a0,-48(s0)
    80005a76:	fffff097          	auipc	ra,0xfffff
    80005a7a:	9a8080e7          	jalr	-1624(ra) # 8000441e <fileclose>
    fileclose(wf);
    80005a7e:	fc843503          	ld	a0,-56(s0)
    80005a82:	fffff097          	auipc	ra,0xfffff
    80005a86:	99c080e7          	jalr	-1636(ra) # 8000441e <fileclose>
    return -1;
    80005a8a:	57fd                	li	a5,-1
}
    80005a8c:	853e                	mv	a0,a5
    80005a8e:	70e2                	ld	ra,56(sp)
    80005a90:	7442                	ld	s0,48(sp)
    80005a92:	74a2                	ld	s1,40(sp)
    80005a94:	6121                	addi	sp,sp,64
    80005a96:	8082                	ret

0000000080005a98 <sys_crash>:

// system call to test crashes
uint64
sys_crash(void)
{
    80005a98:	7171                	addi	sp,sp,-176
    80005a9a:	f506                	sd	ra,168(sp)
    80005a9c:	f122                	sd	s0,160(sp)
    80005a9e:	ed26                	sd	s1,152(sp)
    80005aa0:	1900                	addi	s0,sp,176
  char path[MAXPATH];
  struct inode *ip;
  int crash;
  
  if(argstr(0, path, MAXPATH) < 0 || argint(1, &crash) < 0)
    80005aa2:	08000613          	li	a2,128
    80005aa6:	f6040593          	addi	a1,s0,-160
    80005aaa:	4501                	li	a0,0
    80005aac:	ffffd097          	auipc	ra,0xffffd
    80005ab0:	d6e080e7          	jalr	-658(ra) # 8000281a <argstr>
    return -1;
    80005ab4:	57fd                	li	a5,-1
  if(argstr(0, path, MAXPATH) < 0 || argint(1, &crash) < 0)
    80005ab6:	04054363          	bltz	a0,80005afc <sys_crash+0x64>
    80005aba:	f5c40593          	addi	a1,s0,-164
    80005abe:	4505                	li	a0,1
    80005ac0:	ffffd097          	auipc	ra,0xffffd
    80005ac4:	d16080e7          	jalr	-746(ra) # 800027d6 <argint>
    return -1;
    80005ac8:	57fd                	li	a5,-1
  if(argstr(0, path, MAXPATH) < 0 || argint(1, &crash) < 0)
    80005aca:	02054963          	bltz	a0,80005afc <sys_crash+0x64>
  ip = create(path, T_FILE, 0, 0);
    80005ace:	4681                	li	a3,0
    80005ad0:	4601                	li	a2,0
    80005ad2:	4589                	li	a1,2
    80005ad4:	f6040513          	addi	a0,s0,-160
    80005ad8:	fffff097          	auipc	ra,0xfffff
    80005adc:	428080e7          	jalr	1064(ra) # 80004f00 <create>
    80005ae0:	84aa                	mv	s1,a0
  if(ip == 0){
    80005ae2:	c11d                	beqz	a0,80005b08 <sys_crash+0x70>
    return -1;
  }
  iunlockput(ip);
    80005ae4:	ffffe097          	auipc	ra,0xffffe
    80005ae8:	aa6080e7          	jalr	-1370(ra) # 8000358a <iunlockput>
  crash_op(ip->dev, crash);
    80005aec:	f5c42583          	lw	a1,-164(s0)
    80005af0:	4088                	lw	a0,0(s1)
    80005af2:	ffffe097          	auipc	ra,0xffffe
    80005af6:	600080e7          	jalr	1536(ra) # 800040f2 <crash_op>
  return 0;
    80005afa:	4781                	li	a5,0
}
    80005afc:	853e                	mv	a0,a5
    80005afe:	70aa                	ld	ra,168(sp)
    80005b00:	740a                	ld	s0,160(sp)
    80005b02:	64ea                	ld	s1,152(sp)
    80005b04:	614d                	addi	sp,sp,176
    80005b06:	8082                	ret
    return -1;
    80005b08:	57fd                	li	a5,-1
    80005b0a:	bfcd                	j	80005afc <sys_crash+0x64>
    80005b0c:	0000                	unimp
	...

0000000080005b10 <kernelvec>:
    80005b10:	7111                	addi	sp,sp,-256
    80005b12:	e006                	sd	ra,0(sp)
    80005b14:	e40a                	sd	sp,8(sp)
    80005b16:	e80e                	sd	gp,16(sp)
    80005b18:	ec12                	sd	tp,24(sp)
    80005b1a:	f016                	sd	t0,32(sp)
    80005b1c:	f41a                	sd	t1,40(sp)
    80005b1e:	f81e                	sd	t2,48(sp)
    80005b20:	fc22                	sd	s0,56(sp)
    80005b22:	e0a6                	sd	s1,64(sp)
    80005b24:	e4aa                	sd	a0,72(sp)
    80005b26:	e8ae                	sd	a1,80(sp)
    80005b28:	ecb2                	sd	a2,88(sp)
    80005b2a:	f0b6                	sd	a3,96(sp)
    80005b2c:	f4ba                	sd	a4,104(sp)
    80005b2e:	f8be                	sd	a5,112(sp)
    80005b30:	fcc2                	sd	a6,120(sp)
    80005b32:	e146                	sd	a7,128(sp)
    80005b34:	e54a                	sd	s2,136(sp)
    80005b36:	e94e                	sd	s3,144(sp)
    80005b38:	ed52                	sd	s4,152(sp)
    80005b3a:	f156                	sd	s5,160(sp)
    80005b3c:	f55a                	sd	s6,168(sp)
    80005b3e:	f95e                	sd	s7,176(sp)
    80005b40:	fd62                	sd	s8,184(sp)
    80005b42:	e1e6                	sd	s9,192(sp)
    80005b44:	e5ea                	sd	s10,200(sp)
    80005b46:	e9ee                	sd	s11,208(sp)
    80005b48:	edf2                	sd	t3,216(sp)
    80005b4a:	f1f6                	sd	t4,224(sp)
    80005b4c:	f5fa                	sd	t5,232(sp)
    80005b4e:	f9fe                	sd	t6,240(sp)
    80005b50:	ab9fc0ef          	jal	ra,80002608 <kerneltrap>
    80005b54:	6082                	ld	ra,0(sp)
    80005b56:	6122                	ld	sp,8(sp)
    80005b58:	61c2                	ld	gp,16(sp)
    80005b5a:	7282                	ld	t0,32(sp)
    80005b5c:	7322                	ld	t1,40(sp)
    80005b5e:	73c2                	ld	t2,48(sp)
    80005b60:	7462                	ld	s0,56(sp)
    80005b62:	6486                	ld	s1,64(sp)
    80005b64:	6526                	ld	a0,72(sp)
    80005b66:	65c6                	ld	a1,80(sp)
    80005b68:	6666                	ld	a2,88(sp)
    80005b6a:	7686                	ld	a3,96(sp)
    80005b6c:	7726                	ld	a4,104(sp)
    80005b6e:	77c6                	ld	a5,112(sp)
    80005b70:	7866                	ld	a6,120(sp)
    80005b72:	688a                	ld	a7,128(sp)
    80005b74:	692a                	ld	s2,136(sp)
    80005b76:	69ca                	ld	s3,144(sp)
    80005b78:	6a6a                	ld	s4,152(sp)
    80005b7a:	7a8a                	ld	s5,160(sp)
    80005b7c:	7b2a                	ld	s6,168(sp)
    80005b7e:	7bca                	ld	s7,176(sp)
    80005b80:	7c6a                	ld	s8,184(sp)
    80005b82:	6c8e                	ld	s9,192(sp)
    80005b84:	6d2e                	ld	s10,200(sp)
    80005b86:	6dce                	ld	s11,208(sp)
    80005b88:	6e6e                	ld	t3,216(sp)
    80005b8a:	7e8e                	ld	t4,224(sp)
    80005b8c:	7f2e                	ld	t5,232(sp)
    80005b8e:	7fce                	ld	t6,240(sp)
    80005b90:	6111                	addi	sp,sp,256
    80005b92:	10200073          	sret
    80005b96:	00000013          	nop
    80005b9a:	00000013          	nop
    80005b9e:	0001                	nop

0000000080005ba0 <timervec>:
    80005ba0:	34051573          	csrrw	a0,mscratch,a0
    80005ba4:	e10c                	sd	a1,0(a0)
    80005ba6:	e510                	sd	a2,8(a0)
    80005ba8:	e914                	sd	a3,16(a0)
    80005baa:	710c                	ld	a1,32(a0)
    80005bac:	7510                	ld	a2,40(a0)
    80005bae:	6194                	ld	a3,0(a1)
    80005bb0:	96b2                	add	a3,a3,a2
    80005bb2:	e194                	sd	a3,0(a1)
    80005bb4:	4589                	li	a1,2
    80005bb6:	14459073          	csrw	sip,a1
    80005bba:	6914                	ld	a3,16(a0)
    80005bbc:	6510                	ld	a2,8(a0)
    80005bbe:	610c                	ld	a1,0(a0)
    80005bc0:	34051573          	csrrw	a0,mscratch,a0
    80005bc4:	30200073          	mret
	...

0000000080005bca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005bca:	1141                	addi	sp,sp,-16
    80005bcc:	e422                	sd	s0,8(sp)
    80005bce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005bd0:	0c0007b7          	lui	a5,0xc000
    80005bd4:	4705                	li	a4,1
    80005bd6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005bd8:	c3d8                	sw	a4,4(a5)
}
    80005bda:	6422                	ld	s0,8(sp)
    80005bdc:	0141                	addi	sp,sp,16
    80005bde:	8082                	ret

0000000080005be0 <plicinithart>:

void
plicinithart(void)
{
    80005be0:	1141                	addi	sp,sp,-16
    80005be2:	e406                	sd	ra,8(sp)
    80005be4:	e022                	sd	s0,0(sp)
    80005be6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005be8:	ffffc097          	auipc	ra,0xffffc
    80005bec:	b08080e7          	jalr	-1272(ra) # 800016f0 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005bf0:	0085171b          	slliw	a4,a0,0x8
    80005bf4:	0c0027b7          	lui	a5,0xc002
    80005bf8:	97ba                	add	a5,a5,a4
    80005bfa:	40200713          	li	a4,1026
    80005bfe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005c02:	00d5151b          	slliw	a0,a0,0xd
    80005c06:	0c2017b7          	lui	a5,0xc201
    80005c0a:	953e                	add	a0,a0,a5
    80005c0c:	00052023          	sw	zero,0(a0)
}
    80005c10:	60a2                	ld	ra,8(sp)
    80005c12:	6402                	ld	s0,0(sp)
    80005c14:	0141                	addi	sp,sp,16
    80005c16:	8082                	ret

0000000080005c18 <plic_pending>:

// return a bitmap of which IRQs are waiting
// to be served.
uint64
plic_pending(void)
{
    80005c18:	1141                	addi	sp,sp,-16
    80005c1a:	e422                	sd	s0,8(sp)
    80005c1c:	0800                	addi	s0,sp,16
  //mask = *(uint32*)(PLIC + 0x1000);
  //mask |= (uint64)*(uint32*)(PLIC + 0x1004) << 32;
  mask = *(uint64*)PLIC_PENDING;

  return mask;
}
    80005c1e:	0c0017b7          	lui	a5,0xc001
    80005c22:	6388                	ld	a0,0(a5)
    80005c24:	6422                	ld	s0,8(sp)
    80005c26:	0141                	addi	sp,sp,16
    80005c28:	8082                	ret

0000000080005c2a <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005c2a:	1141                	addi	sp,sp,-16
    80005c2c:	e406                	sd	ra,8(sp)
    80005c2e:	e022                	sd	s0,0(sp)
    80005c30:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c32:	ffffc097          	auipc	ra,0xffffc
    80005c36:	abe080e7          	jalr	-1346(ra) # 800016f0 <cpuid>
  //int irq = *(uint32*)(PLIC + 0x201004);
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005c3a:	00d5179b          	slliw	a5,a0,0xd
    80005c3e:	0c201537          	lui	a0,0xc201
    80005c42:	953e                	add	a0,a0,a5
  return irq;
}
    80005c44:	4148                	lw	a0,4(a0)
    80005c46:	60a2                	ld	ra,8(sp)
    80005c48:	6402                	ld	s0,0(sp)
    80005c4a:	0141                	addi	sp,sp,16
    80005c4c:	8082                	ret

0000000080005c4e <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005c4e:	1101                	addi	sp,sp,-32
    80005c50:	ec06                	sd	ra,24(sp)
    80005c52:	e822                	sd	s0,16(sp)
    80005c54:	e426                	sd	s1,8(sp)
    80005c56:	1000                	addi	s0,sp,32
    80005c58:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005c5a:	ffffc097          	auipc	ra,0xffffc
    80005c5e:	a96080e7          	jalr	-1386(ra) # 800016f0 <cpuid>
  //*(uint32*)(PLIC + 0x201004) = irq;
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005c62:	00d5151b          	slliw	a0,a0,0xd
    80005c66:	0c2017b7          	lui	a5,0xc201
    80005c6a:	97aa                	add	a5,a5,a0
    80005c6c:	c3c4                	sw	s1,4(a5)
}
    80005c6e:	60e2                	ld	ra,24(sp)
    80005c70:	6442                	ld	s0,16(sp)
    80005c72:	64a2                	ld	s1,8(sp)
    80005c74:	6105                	addi	sp,sp,32
    80005c76:	8082                	ret

0000000080005c78 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int n, int i)
{
    80005c78:	1141                	addi	sp,sp,-16
    80005c7a:	e406                	sd	ra,8(sp)
    80005c7c:	e022                	sd	s0,0(sp)
    80005c7e:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005c80:	479d                	li	a5,7
    80005c82:	06b7c963          	blt	a5,a1,80005cf4 <free_desc+0x7c>
    panic("virtio_disk_intr 1");
  if(disk[n].free[i])
    80005c86:	00151793          	slli	a5,a0,0x1
    80005c8a:	97aa                	add	a5,a5,a0
    80005c8c:	00c79713          	slli	a4,a5,0xc
    80005c90:	0001c797          	auipc	a5,0x1c
    80005c94:	37078793          	addi	a5,a5,880 # 80022000 <disk>
    80005c98:	97ba                	add	a5,a5,a4
    80005c9a:	97ae                	add	a5,a5,a1
    80005c9c:	6709                	lui	a4,0x2
    80005c9e:	97ba                	add	a5,a5,a4
    80005ca0:	0187c783          	lbu	a5,24(a5)
    80005ca4:	e3a5                	bnez	a5,80005d04 <free_desc+0x8c>
    panic("virtio_disk_intr 2");
  disk[n].desc[i].addr = 0;
    80005ca6:	0001c817          	auipc	a6,0x1c
    80005caa:	35a80813          	addi	a6,a6,858 # 80022000 <disk>
    80005cae:	00151693          	slli	a3,a0,0x1
    80005cb2:	00a68733          	add	a4,a3,a0
    80005cb6:	0732                	slli	a4,a4,0xc
    80005cb8:	00e807b3          	add	a5,a6,a4
    80005cbc:	6709                	lui	a4,0x2
    80005cbe:	00f70633          	add	a2,a4,a5
    80005cc2:	6210                	ld	a2,0(a2)
    80005cc4:	00459893          	slli	a7,a1,0x4
    80005cc8:	9646                	add	a2,a2,a7
    80005cca:	00063023          	sd	zero,0(a2) # 1000 <_entry-0x7ffff000>
  disk[n].free[i] = 1;
    80005cce:	97ae                	add	a5,a5,a1
    80005cd0:	97ba                	add	a5,a5,a4
    80005cd2:	4605                	li	a2,1
    80005cd4:	00c78c23          	sb	a2,24(a5)
  wakeup(&disk[n].free[0]);
    80005cd8:	96aa                	add	a3,a3,a0
    80005cda:	06b2                	slli	a3,a3,0xc
    80005cdc:	0761                	addi	a4,a4,24
    80005cde:	96ba                	add	a3,a3,a4
    80005ce0:	00d80533          	add	a0,a6,a3
    80005ce4:	ffffc097          	auipc	ra,0xffffc
    80005ce8:	3ce080e7          	jalr	974(ra) # 800020b2 <wakeup>
}
    80005cec:	60a2                	ld	ra,8(sp)
    80005cee:	6402                	ld	s0,0(sp)
    80005cf0:	0141                	addi	sp,sp,16
    80005cf2:	8082                	ret
    panic("virtio_disk_intr 1");
    80005cf4:	00002517          	auipc	a0,0x2
    80005cf8:	adc50513          	addi	a0,a0,-1316 # 800077d0 <userret+0x740>
    80005cfc:	ffffb097          	auipc	ra,0xffffb
    80005d00:	84c080e7          	jalr	-1972(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80005d04:	00002517          	auipc	a0,0x2
    80005d08:	ae450513          	addi	a0,a0,-1308 # 800077e8 <userret+0x758>
    80005d0c:	ffffb097          	auipc	ra,0xffffb
    80005d10:	83c080e7          	jalr	-1988(ra) # 80000548 <panic>

0000000080005d14 <virtio_disk_init>:
  __sync_synchronize();
    80005d14:	0ff0000f          	fence
  if(disk[n].init)
    80005d18:	00151793          	slli	a5,a0,0x1
    80005d1c:	97aa                	add	a5,a5,a0
    80005d1e:	07b2                	slli	a5,a5,0xc
    80005d20:	0001c717          	auipc	a4,0x1c
    80005d24:	2e070713          	addi	a4,a4,736 # 80022000 <disk>
    80005d28:	973e                	add	a4,a4,a5
    80005d2a:	6789                	lui	a5,0x2
    80005d2c:	97ba                	add	a5,a5,a4
    80005d2e:	0a87a783          	lw	a5,168(a5) # 20a8 <_entry-0x7fffdf58>
    80005d32:	c391                	beqz	a5,80005d36 <virtio_disk_init+0x22>
    80005d34:	8082                	ret
{
    80005d36:	7139                	addi	sp,sp,-64
    80005d38:	fc06                	sd	ra,56(sp)
    80005d3a:	f822                	sd	s0,48(sp)
    80005d3c:	f426                	sd	s1,40(sp)
    80005d3e:	f04a                	sd	s2,32(sp)
    80005d40:	ec4e                	sd	s3,24(sp)
    80005d42:	e852                	sd	s4,16(sp)
    80005d44:	e456                	sd	s5,8(sp)
    80005d46:	0080                	addi	s0,sp,64
    80005d48:	84aa                	mv	s1,a0
  printf("virtio disk init %d\n", n);
    80005d4a:	85aa                	mv	a1,a0
    80005d4c:	00002517          	auipc	a0,0x2
    80005d50:	ab450513          	addi	a0,a0,-1356 # 80007800 <userret+0x770>
    80005d54:	ffffb097          	auipc	ra,0xffffb
    80005d58:	83e080e7          	jalr	-1986(ra) # 80000592 <printf>
  initlock(&disk[n].vdisk_lock, "virtio_disk");
    80005d5c:	00149993          	slli	s3,s1,0x1
    80005d60:	99a6                	add	s3,s3,s1
    80005d62:	09b2                	slli	s3,s3,0xc
    80005d64:	6789                	lui	a5,0x2
    80005d66:	0b078793          	addi	a5,a5,176 # 20b0 <_entry-0x7fffdf50>
    80005d6a:	97ce                	add	a5,a5,s3
    80005d6c:	00002597          	auipc	a1,0x2
    80005d70:	aac58593          	addi	a1,a1,-1364 # 80007818 <userret+0x788>
    80005d74:	0001c517          	auipc	a0,0x1c
    80005d78:	28c50513          	addi	a0,a0,652 # 80022000 <disk>
    80005d7c:	953e                	add	a0,a0,a5
    80005d7e:	ffffb097          	auipc	ra,0xffffb
    80005d82:	b30080e7          	jalr	-1232(ra) # 800008ae <initlock>
  if(*R(n, VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d86:	0014891b          	addiw	s2,s1,1
    80005d8a:	00c9191b          	slliw	s2,s2,0xc
    80005d8e:	100007b7          	lui	a5,0x10000
    80005d92:	97ca                	add	a5,a5,s2
    80005d94:	4398                	lw	a4,0(a5)
    80005d96:	2701                	sext.w	a4,a4
    80005d98:	747277b7          	lui	a5,0x74727
    80005d9c:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005da0:	12f71663          	bne	a4,a5,80005ecc <virtio_disk_init+0x1b8>
     *R(n, VIRTIO_MMIO_VERSION) != 1 ||
    80005da4:	100007b7          	lui	a5,0x10000
    80005da8:	0791                	addi	a5,a5,4
    80005daa:	97ca                	add	a5,a5,s2
    80005dac:	439c                	lw	a5,0(a5)
    80005dae:	2781                	sext.w	a5,a5
  if(*R(n, VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005db0:	4705                	li	a4,1
    80005db2:	10e79d63          	bne	a5,a4,80005ecc <virtio_disk_init+0x1b8>
     *R(n, VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005db6:	100007b7          	lui	a5,0x10000
    80005dba:	07a1                	addi	a5,a5,8
    80005dbc:	97ca                	add	a5,a5,s2
    80005dbe:	439c                	lw	a5,0(a5)
    80005dc0:	2781                	sext.w	a5,a5
     *R(n, VIRTIO_MMIO_VERSION) != 1 ||
    80005dc2:	4709                	li	a4,2
    80005dc4:	10e79463          	bne	a5,a4,80005ecc <virtio_disk_init+0x1b8>
     *R(n, VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005dc8:	100007b7          	lui	a5,0x10000
    80005dcc:	07b1                	addi	a5,a5,12
    80005dce:	97ca                	add	a5,a5,s2
    80005dd0:	4398                	lw	a4,0(a5)
    80005dd2:	2701                	sext.w	a4,a4
     *R(n, VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005dd4:	554d47b7          	lui	a5,0x554d4
    80005dd8:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005ddc:	0ef71863          	bne	a4,a5,80005ecc <virtio_disk_init+0x1b8>
  *R(n, VIRTIO_MMIO_STATUS) = status;
    80005de0:	100007b7          	lui	a5,0x10000
    80005de4:	07078693          	addi	a3,a5,112 # 10000070 <_entry-0x6fffff90>
    80005de8:	96ca                	add	a3,a3,s2
    80005dea:	4705                	li	a4,1
    80005dec:	c298                	sw	a4,0(a3)
  *R(n, VIRTIO_MMIO_STATUS) = status;
    80005dee:	470d                	li	a4,3
    80005df0:	c298                	sw	a4,0(a3)
  uint64 features = *R(n, VIRTIO_MMIO_DEVICE_FEATURES);
    80005df2:	01078713          	addi	a4,a5,16
    80005df6:	974a                	add	a4,a4,s2
    80005df8:	430c                	lw	a1,0(a4)
  *R(n, VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005dfa:	02078613          	addi	a2,a5,32
    80005dfe:	964a                	add	a2,a2,s2
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e00:	c7ffe737          	lui	a4,0xc7ffe
    80005e04:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd6703>
    80005e08:	8f6d                	and	a4,a4,a1
  *R(n, VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e0a:	2701                	sext.w	a4,a4
    80005e0c:	c218                	sw	a4,0(a2)
  *R(n, VIRTIO_MMIO_STATUS) = status;
    80005e0e:	472d                	li	a4,11
    80005e10:	c298                	sw	a4,0(a3)
  *R(n, VIRTIO_MMIO_STATUS) = status;
    80005e12:	473d                	li	a4,15
    80005e14:	c298                	sw	a4,0(a3)
  *R(n, VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005e16:	02878713          	addi	a4,a5,40
    80005e1a:	974a                	add	a4,a4,s2
    80005e1c:	6685                	lui	a3,0x1
    80005e1e:	c314                	sw	a3,0(a4)
  *R(n, VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e20:	03078713          	addi	a4,a5,48
    80005e24:	974a                	add	a4,a4,s2
    80005e26:	00072023          	sw	zero,0(a4)
  uint32 max = *R(n, VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e2a:	03478793          	addi	a5,a5,52
    80005e2e:	97ca                	add	a5,a5,s2
    80005e30:	439c                	lw	a5,0(a5)
    80005e32:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e34:	c7c5                	beqz	a5,80005edc <virtio_disk_init+0x1c8>
  if(max < NUM)
    80005e36:	471d                	li	a4,7
    80005e38:	0af77a63          	bgeu	a4,a5,80005eec <virtio_disk_init+0x1d8>
  *R(n, VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e3c:	10000ab7          	lui	s5,0x10000
    80005e40:	038a8793          	addi	a5,s5,56 # 10000038 <_entry-0x6fffffc8>
    80005e44:	97ca                	add	a5,a5,s2
    80005e46:	4721                	li	a4,8
    80005e48:	c398                	sw	a4,0(a5)
  memset(disk[n].pages, 0, sizeof(disk[n].pages));
    80005e4a:	0001ca17          	auipc	s4,0x1c
    80005e4e:	1b6a0a13          	addi	s4,s4,438 # 80022000 <disk>
    80005e52:	99d2                	add	s3,s3,s4
    80005e54:	6609                	lui	a2,0x2
    80005e56:	4581                	li	a1,0
    80005e58:	854e                	mv	a0,s3
    80005e5a:	ffffb097          	auipc	ra,0xffffb
    80005e5e:	c26080e7          	jalr	-986(ra) # 80000a80 <memset>
  *R(n, VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk[n].pages) >> PGSHIFT;
    80005e62:	040a8a93          	addi	s5,s5,64
    80005e66:	9956                	add	s2,s2,s5
    80005e68:	00c9d793          	srli	a5,s3,0xc
    80005e6c:	2781                	sext.w	a5,a5
    80005e6e:	00f92023          	sw	a5,0(s2)
  disk[n].desc = (struct VRingDesc *) disk[n].pages;
    80005e72:	00149693          	slli	a3,s1,0x1
    80005e76:	009687b3          	add	a5,a3,s1
    80005e7a:	07b2                	slli	a5,a5,0xc
    80005e7c:	97d2                	add	a5,a5,s4
    80005e7e:	6609                	lui	a2,0x2
    80005e80:	97b2                	add	a5,a5,a2
    80005e82:	0137b023          	sd	s3,0(a5)
  disk[n].avail = (uint16*)(((char*)disk[n].desc) + NUM*sizeof(struct VRingDesc));
    80005e86:	08098713          	addi	a4,s3,128
    80005e8a:	e798                	sd	a4,8(a5)
  disk[n].used = (struct UsedArea *) (disk[n].pages + PGSIZE);
    80005e8c:	6705                	lui	a4,0x1
    80005e8e:	99ba                	add	s3,s3,a4
    80005e90:	0137b823          	sd	s3,16(a5)
    disk[n].free[i] = 1;
    80005e94:	4705                	li	a4,1
    80005e96:	00e78c23          	sb	a4,24(a5)
    80005e9a:	00e78ca3          	sb	a4,25(a5)
    80005e9e:	00e78d23          	sb	a4,26(a5)
    80005ea2:	00e78da3          	sb	a4,27(a5)
    80005ea6:	00e78e23          	sb	a4,28(a5)
    80005eaa:	00e78ea3          	sb	a4,29(a5)
    80005eae:	00e78f23          	sb	a4,30(a5)
    80005eb2:	00e78fa3          	sb	a4,31(a5)
  disk[n].init = 1;
    80005eb6:	0ae7a423          	sw	a4,168(a5)
}
    80005eba:	70e2                	ld	ra,56(sp)
    80005ebc:	7442                	ld	s0,48(sp)
    80005ebe:	74a2                	ld	s1,40(sp)
    80005ec0:	7902                	ld	s2,32(sp)
    80005ec2:	69e2                	ld	s3,24(sp)
    80005ec4:	6a42                	ld	s4,16(sp)
    80005ec6:	6aa2                	ld	s5,8(sp)
    80005ec8:	6121                	addi	sp,sp,64
    80005eca:	8082                	ret
    panic("could not find virtio disk");
    80005ecc:	00002517          	auipc	a0,0x2
    80005ed0:	95c50513          	addi	a0,a0,-1700 # 80007828 <userret+0x798>
    80005ed4:	ffffa097          	auipc	ra,0xffffa
    80005ed8:	674080e7          	jalr	1652(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    80005edc:	00002517          	auipc	a0,0x2
    80005ee0:	96c50513          	addi	a0,a0,-1684 # 80007848 <userret+0x7b8>
    80005ee4:	ffffa097          	auipc	ra,0xffffa
    80005ee8:	664080e7          	jalr	1636(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    80005eec:	00002517          	auipc	a0,0x2
    80005ef0:	97c50513          	addi	a0,a0,-1668 # 80007868 <userret+0x7d8>
    80005ef4:	ffffa097          	auipc	ra,0xffffa
    80005ef8:	654080e7          	jalr	1620(ra) # 80000548 <panic>

0000000080005efc <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(int n, struct buf *b, int write)
{
    80005efc:	7135                	addi	sp,sp,-160
    80005efe:	ed06                	sd	ra,152(sp)
    80005f00:	e922                	sd	s0,144(sp)
    80005f02:	e526                	sd	s1,136(sp)
    80005f04:	e14a                	sd	s2,128(sp)
    80005f06:	fcce                	sd	s3,120(sp)
    80005f08:	f8d2                	sd	s4,112(sp)
    80005f0a:	f4d6                	sd	s5,104(sp)
    80005f0c:	f0da                	sd	s6,96(sp)
    80005f0e:	ecde                	sd	s7,88(sp)
    80005f10:	e8e2                	sd	s8,80(sp)
    80005f12:	e4e6                	sd	s9,72(sp)
    80005f14:	e0ea                	sd	s10,64(sp)
    80005f16:	fc6e                	sd	s11,56(sp)
    80005f18:	1100                	addi	s0,sp,160
    80005f1a:	8aaa                	mv	s5,a0
    80005f1c:	8c2e                	mv	s8,a1
    80005f1e:	8db2                	mv	s11,a2
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f20:	45dc                	lw	a5,12(a1)
    80005f22:	0017979b          	slliw	a5,a5,0x1
    80005f26:	1782                	slli	a5,a5,0x20
    80005f28:	9381                	srli	a5,a5,0x20
    80005f2a:	f6f43423          	sd	a5,-152(s0)

  acquire(&disk[n].vdisk_lock);
    80005f2e:	00151493          	slli	s1,a0,0x1
    80005f32:	94aa                	add	s1,s1,a0
    80005f34:	04b2                	slli	s1,s1,0xc
    80005f36:	6909                	lui	s2,0x2
    80005f38:	0b090c93          	addi	s9,s2,176 # 20b0 <_entry-0x7fffdf50>
    80005f3c:	9ca6                	add	s9,s9,s1
    80005f3e:	0001c997          	auipc	s3,0x1c
    80005f42:	0c298993          	addi	s3,s3,194 # 80022000 <disk>
    80005f46:	9cce                	add	s9,s9,s3
    80005f48:	8566                	mv	a0,s9
    80005f4a:	ffffb097          	auipc	ra,0xffffb
    80005f4e:	a72080e7          	jalr	-1422(ra) # 800009bc <acquire>
  int idx[3];
  while(1){
    if(alloc3_desc(n, idx) == 0) {
      break;
    }
    sleep(&disk[n].free[0], &disk[n].vdisk_lock);
    80005f52:	0961                	addi	s2,s2,24
    80005f54:	94ca                	add	s1,s1,s2
    80005f56:	99a6                	add	s3,s3,s1
  for(int i = 0; i < 3; i++){
    80005f58:	4a01                	li	s4,0
  for(int i = 0; i < NUM; i++){
    80005f5a:	44a1                	li	s1,8
      disk[n].free[i] = 0;
    80005f5c:	001a9793          	slli	a5,s5,0x1
    80005f60:	97d6                	add	a5,a5,s5
    80005f62:	07b2                	slli	a5,a5,0xc
    80005f64:	0001cb97          	auipc	s7,0x1c
    80005f68:	09cb8b93          	addi	s7,s7,156 # 80022000 <disk>
    80005f6c:	9bbe                	add	s7,s7,a5
    80005f6e:	a8a9                	j	80005fc8 <virtio_disk_rw+0xcc>
    80005f70:	00fb8733          	add	a4,s7,a5
    80005f74:	9742                	add	a4,a4,a6
    80005f76:	00070c23          	sb	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    idx[i] = alloc_desc(n);
    80005f7a:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005f7c:	0207c263          	bltz	a5,80005fa0 <virtio_disk_rw+0xa4>
  for(int i = 0; i < 3; i++){
    80005f80:	2905                	addiw	s2,s2,1
    80005f82:	0611                	addi	a2,a2,4
    80005f84:	1ca90463          	beq	s2,a0,8000614c <virtio_disk_rw+0x250>
    idx[i] = alloc_desc(n);
    80005f88:	85b2                	mv	a1,a2
    80005f8a:	874e                	mv	a4,s3
  for(int i = 0; i < NUM; i++){
    80005f8c:	87d2                	mv	a5,s4
    if(disk[n].free[i]){
    80005f8e:	00074683          	lbu	a3,0(a4)
    80005f92:	fef9                	bnez	a3,80005f70 <virtio_disk_rw+0x74>
  for(int i = 0; i < NUM; i++){
    80005f94:	2785                	addiw	a5,a5,1
    80005f96:	0705                	addi	a4,a4,1
    80005f98:	fe979be3          	bne	a5,s1,80005f8e <virtio_disk_rw+0x92>
    idx[i] = alloc_desc(n);
    80005f9c:	57fd                	li	a5,-1
    80005f9e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005fa0:	01205e63          	blez	s2,80005fbc <virtio_disk_rw+0xc0>
    80005fa4:	8d52                	mv	s10,s4
        free_desc(n, idx[j]);
    80005fa6:	000b2583          	lw	a1,0(s6)
    80005faa:	8556                	mv	a0,s5
    80005fac:	00000097          	auipc	ra,0x0
    80005fb0:	ccc080e7          	jalr	-820(ra) # 80005c78 <free_desc>
      for(int j = 0; j < i; j++)
    80005fb4:	2d05                	addiw	s10,s10,1
    80005fb6:	0b11                	addi	s6,s6,4
    80005fb8:	ffa917e3          	bne	s2,s10,80005fa6 <virtio_disk_rw+0xaa>
    sleep(&disk[n].free[0], &disk[n].vdisk_lock);
    80005fbc:	85e6                	mv	a1,s9
    80005fbe:	854e                	mv	a0,s3
    80005fc0:	ffffc097          	auipc	ra,0xffffc
    80005fc4:	f72080e7          	jalr	-142(ra) # 80001f32 <sleep>
  for(int i = 0; i < 3; i++){
    80005fc8:	f8040b13          	addi	s6,s0,-128
{
    80005fcc:	865a                	mv	a2,s6
  for(int i = 0; i < 3; i++){
    80005fce:	8952                	mv	s2,s4
      disk[n].free[i] = 0;
    80005fd0:	6809                	lui	a6,0x2
  for(int i = 0; i < 3; i++){
    80005fd2:	450d                	li	a0,3
    80005fd4:	bf55                	j	80005f88 <virtio_disk_rw+0x8c>
  disk[n].desc[idx[0]].next = idx[1];

  disk[n].desc[idx[1]].addr = (uint64) b->data;
  disk[n].desc[idx[1]].len = BSIZE;
  if(write)
    disk[n].desc[idx[1]].flags = 0; // device reads b->data
    80005fd6:	001a9793          	slli	a5,s5,0x1
    80005fda:	97d6                	add	a5,a5,s5
    80005fdc:	07b2                	slli	a5,a5,0xc
    80005fde:	0001c717          	auipc	a4,0x1c
    80005fe2:	02270713          	addi	a4,a4,34 # 80022000 <disk>
    80005fe6:	973e                	add	a4,a4,a5
    80005fe8:	6789                	lui	a5,0x2
    80005fea:	97ba                	add	a5,a5,a4
    80005fec:	639c                	ld	a5,0(a5)
    80005fee:	97b6                	add	a5,a5,a3
    80005ff0:	00079623          	sh	zero,12(a5) # 200c <_entry-0x7fffdff4>
  else
    disk[n].desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk[n].desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005ff4:	0001c517          	auipc	a0,0x1c
    80005ff8:	00c50513          	addi	a0,a0,12 # 80022000 <disk>
    80005ffc:	001a9793          	slli	a5,s5,0x1
    80006000:	01578733          	add	a4,a5,s5
    80006004:	0732                	slli	a4,a4,0xc
    80006006:	972a                	add	a4,a4,a0
    80006008:	6609                	lui	a2,0x2
    8000600a:	9732                	add	a4,a4,a2
    8000600c:	6310                	ld	a2,0(a4)
    8000600e:	9636                	add	a2,a2,a3
    80006010:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006014:	0015e593          	ori	a1,a1,1
    80006018:	00b61623          	sh	a1,12(a2)
  disk[n].desc[idx[1]].next = idx[2];
    8000601c:	f8842603          	lw	a2,-120(s0)
    80006020:	630c                	ld	a1,0(a4)
    80006022:	96ae                	add	a3,a3,a1
    80006024:	00c69723          	sh	a2,14(a3) # 100e <_entry-0x7fffeff2>

  disk[n].info[idx[0]].status = 0;
    80006028:	97d6                	add	a5,a5,s5
    8000602a:	07a2                	slli	a5,a5,0x8
    8000602c:	97a6                	add	a5,a5,s1
    8000602e:	20078793          	addi	a5,a5,512
    80006032:	0792                	slli	a5,a5,0x4
    80006034:	97aa                	add	a5,a5,a0
    80006036:	02078823          	sb	zero,48(a5)
  disk[n].desc[idx[2]].addr = (uint64) &disk[n].info[idx[0]].status;
    8000603a:	00461693          	slli	a3,a2,0x4
    8000603e:	00073803          	ld	a6,0(a4)
    80006042:	9836                	add	a6,a6,a3
    80006044:	20348613          	addi	a2,s1,515
    80006048:	001a9593          	slli	a1,s5,0x1
    8000604c:	95d6                	add	a1,a1,s5
    8000604e:	05a2                	slli	a1,a1,0x8
    80006050:	962e                	add	a2,a2,a1
    80006052:	0612                	slli	a2,a2,0x4
    80006054:	962a                	add	a2,a2,a0
    80006056:	00c83023          	sd	a2,0(a6) # 2000 <_entry-0x7fffe000>
  disk[n].desc[idx[2]].len = 1;
    8000605a:	630c                	ld	a1,0(a4)
    8000605c:	95b6                	add	a1,a1,a3
    8000605e:	4605                	li	a2,1
    80006060:	c590                	sw	a2,8(a1)
  disk[n].desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006062:	630c                	ld	a1,0(a4)
    80006064:	95b6                	add	a1,a1,a3
    80006066:	4509                	li	a0,2
    80006068:	00a59623          	sh	a0,12(a1)
  disk[n].desc[idx[2]].next = 0;
    8000606c:	630c                	ld	a1,0(a4)
    8000606e:	96ae                	add	a3,a3,a1
    80006070:	00069723          	sh	zero,14(a3)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006074:	00cc2223          	sw	a2,4(s8) # fffffffffffff004 <end+0xffffffff7ffd6fa8>
  disk[n].info[idx[0]].b = b;
    80006078:	0387b423          	sd	s8,40(a5)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk[n].avail[2 + (disk[n].avail[1] % NUM)] = idx[0];
    8000607c:	6714                	ld	a3,8(a4)
    8000607e:	0026d783          	lhu	a5,2(a3)
    80006082:	8b9d                	andi	a5,a5,7
    80006084:	0789                	addi	a5,a5,2
    80006086:	0786                	slli	a5,a5,0x1
    80006088:	97b6                	add	a5,a5,a3
    8000608a:	00979023          	sh	s1,0(a5)
  __sync_synchronize();
    8000608e:	0ff0000f          	fence
  disk[n].avail[1] = disk[n].avail[1] + 1;
    80006092:	6718                	ld	a4,8(a4)
    80006094:	00275783          	lhu	a5,2(a4)
    80006098:	2785                	addiw	a5,a5,1
    8000609a:	00f71123          	sh	a5,2(a4)

  *R(n, VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000609e:	001a879b          	addiw	a5,s5,1
    800060a2:	00c7979b          	slliw	a5,a5,0xc
    800060a6:	10000737          	lui	a4,0x10000
    800060aa:	05070713          	addi	a4,a4,80 # 10000050 <_entry-0x6fffffb0>
    800060ae:	97ba                	add	a5,a5,a4
    800060b0:	0007a023          	sw	zero,0(a5)

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800060b4:	004c2783          	lw	a5,4(s8)
    800060b8:	00c79d63          	bne	a5,a2,800060d2 <virtio_disk_rw+0x1d6>
    800060bc:	4485                	li	s1,1
    sleep(b, &disk[n].vdisk_lock);
    800060be:	85e6                	mv	a1,s9
    800060c0:	8562                	mv	a0,s8
    800060c2:	ffffc097          	auipc	ra,0xffffc
    800060c6:	e70080e7          	jalr	-400(ra) # 80001f32 <sleep>
  while(b->disk == 1) {
    800060ca:	004c2783          	lw	a5,4(s8)
    800060ce:	fe9788e3          	beq	a5,s1,800060be <virtio_disk_rw+0x1c2>
  }

  disk[n].info[idx[0]].b = 0;
    800060d2:	f8042483          	lw	s1,-128(s0)
    800060d6:	001a9793          	slli	a5,s5,0x1
    800060da:	97d6                	add	a5,a5,s5
    800060dc:	07a2                	slli	a5,a5,0x8
    800060de:	97a6                	add	a5,a5,s1
    800060e0:	20078793          	addi	a5,a5,512
    800060e4:	0792                	slli	a5,a5,0x4
    800060e6:	0001c717          	auipc	a4,0x1c
    800060ea:	f1a70713          	addi	a4,a4,-230 # 80022000 <disk>
    800060ee:	97ba                	add	a5,a5,a4
    800060f0:	0207b423          	sd	zero,40(a5)
    if(disk[n].desc[i].flags & VRING_DESC_F_NEXT)
    800060f4:	001a9793          	slli	a5,s5,0x1
    800060f8:	97d6                	add	a5,a5,s5
    800060fa:	07b2                	slli	a5,a5,0xc
    800060fc:	97ba                	add	a5,a5,a4
    800060fe:	6909                	lui	s2,0x2
    80006100:	993e                	add	s2,s2,a5
    80006102:	a019                	j	80006108 <virtio_disk_rw+0x20c>
      i = disk[n].desc[i].next;
    80006104:	00e4d483          	lhu	s1,14(s1)
    free_desc(n, i);
    80006108:	85a6                	mv	a1,s1
    8000610a:	8556                	mv	a0,s5
    8000610c:	00000097          	auipc	ra,0x0
    80006110:	b6c080e7          	jalr	-1172(ra) # 80005c78 <free_desc>
    if(disk[n].desc[i].flags & VRING_DESC_F_NEXT)
    80006114:	0492                	slli	s1,s1,0x4
    80006116:	00093783          	ld	a5,0(s2) # 2000 <_entry-0x7fffe000>
    8000611a:	94be                	add	s1,s1,a5
    8000611c:	00c4d783          	lhu	a5,12(s1)
    80006120:	8b85                	andi	a5,a5,1
    80006122:	f3ed                	bnez	a5,80006104 <virtio_disk_rw+0x208>
  free_chain(n, idx[0]);

  release(&disk[n].vdisk_lock);
    80006124:	8566                	mv	a0,s9
    80006126:	ffffb097          	auipc	ra,0xffffb
    8000612a:	8fe080e7          	jalr	-1794(ra) # 80000a24 <release>
}
    8000612e:	60ea                	ld	ra,152(sp)
    80006130:	644a                	ld	s0,144(sp)
    80006132:	64aa                	ld	s1,136(sp)
    80006134:	690a                	ld	s2,128(sp)
    80006136:	79e6                	ld	s3,120(sp)
    80006138:	7a46                	ld	s4,112(sp)
    8000613a:	7aa6                	ld	s5,104(sp)
    8000613c:	7b06                	ld	s6,96(sp)
    8000613e:	6be6                	ld	s7,88(sp)
    80006140:	6c46                	ld	s8,80(sp)
    80006142:	6ca6                	ld	s9,72(sp)
    80006144:	6d06                	ld	s10,64(sp)
    80006146:	7de2                	ld	s11,56(sp)
    80006148:	610d                	addi	sp,sp,160
    8000614a:	8082                	ret
  if(write)
    8000614c:	01b037b3          	snez	a5,s11
    80006150:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    80006154:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    80006158:	f6843783          	ld	a5,-152(s0)
    8000615c:	f6f43c23          	sd	a5,-136(s0)
  disk[n].desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006160:	f8042483          	lw	s1,-128(s0)
    80006164:	00449993          	slli	s3,s1,0x4
    80006168:	001a9793          	slli	a5,s5,0x1
    8000616c:	97d6                	add	a5,a5,s5
    8000616e:	07b2                	slli	a5,a5,0xc
    80006170:	0001c917          	auipc	s2,0x1c
    80006174:	e9090913          	addi	s2,s2,-368 # 80022000 <disk>
    80006178:	97ca                	add	a5,a5,s2
    8000617a:	6909                	lui	s2,0x2
    8000617c:	993e                	add	s2,s2,a5
    8000617e:	00093a03          	ld	s4,0(s2) # 2000 <_entry-0x7fffe000>
    80006182:	9a4e                	add	s4,s4,s3
    80006184:	f7040513          	addi	a0,s0,-144
    80006188:	ffffb097          	auipc	ra,0xffffb
    8000618c:	d28080e7          	jalr	-728(ra) # 80000eb0 <kvmpa>
    80006190:	00aa3023          	sd	a0,0(s4)
  disk[n].desc[idx[0]].len = sizeof(buf0);
    80006194:	00093783          	ld	a5,0(s2)
    80006198:	97ce                	add	a5,a5,s3
    8000619a:	4741                	li	a4,16
    8000619c:	c798                	sw	a4,8(a5)
  disk[n].desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000619e:	00093783          	ld	a5,0(s2)
    800061a2:	97ce                	add	a5,a5,s3
    800061a4:	4705                	li	a4,1
    800061a6:	00e79623          	sh	a4,12(a5)
  disk[n].desc[idx[0]].next = idx[1];
    800061aa:	f8442683          	lw	a3,-124(s0)
    800061ae:	00093783          	ld	a5,0(s2)
    800061b2:	99be                	add	s3,s3,a5
    800061b4:	00d99723          	sh	a3,14(s3)
  disk[n].desc[idx[1]].addr = (uint64) b->data;
    800061b8:	0692                	slli	a3,a3,0x4
    800061ba:	00093783          	ld	a5,0(s2)
    800061be:	97b6                	add	a5,a5,a3
    800061c0:	060c0713          	addi	a4,s8,96
    800061c4:	e398                	sd	a4,0(a5)
  disk[n].desc[idx[1]].len = BSIZE;
    800061c6:	00093783          	ld	a5,0(s2)
    800061ca:	97b6                	add	a5,a5,a3
    800061cc:	40000713          	li	a4,1024
    800061d0:	c798                	sw	a4,8(a5)
  if(write)
    800061d2:	e00d92e3          	bnez	s11,80005fd6 <virtio_disk_rw+0xda>
    disk[n].desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800061d6:	001a9793          	slli	a5,s5,0x1
    800061da:	97d6                	add	a5,a5,s5
    800061dc:	07b2                	slli	a5,a5,0xc
    800061de:	0001c717          	auipc	a4,0x1c
    800061e2:	e2270713          	addi	a4,a4,-478 # 80022000 <disk>
    800061e6:	973e                	add	a4,a4,a5
    800061e8:	6789                	lui	a5,0x2
    800061ea:	97ba                	add	a5,a5,a4
    800061ec:	639c                	ld	a5,0(a5)
    800061ee:	97b6                	add	a5,a5,a3
    800061f0:	4709                	li	a4,2
    800061f2:	00e79623          	sh	a4,12(a5) # 200c <_entry-0x7fffdff4>
    800061f6:	bbfd                	j	80005ff4 <virtio_disk_rw+0xf8>

00000000800061f8 <virtio_disk_intr>:

void
virtio_disk_intr(int n)
{
    800061f8:	7139                	addi	sp,sp,-64
    800061fa:	fc06                	sd	ra,56(sp)
    800061fc:	f822                	sd	s0,48(sp)
    800061fe:	f426                	sd	s1,40(sp)
    80006200:	f04a                	sd	s2,32(sp)
    80006202:	ec4e                	sd	s3,24(sp)
    80006204:	e852                	sd	s4,16(sp)
    80006206:	e456                	sd	s5,8(sp)
    80006208:	0080                	addi	s0,sp,64
    8000620a:	84aa                	mv	s1,a0
  acquire(&disk[n].vdisk_lock);
    8000620c:	00151913          	slli	s2,a0,0x1
    80006210:	00a90a33          	add	s4,s2,a0
    80006214:	0a32                	slli	s4,s4,0xc
    80006216:	6989                	lui	s3,0x2
    80006218:	0b098793          	addi	a5,s3,176 # 20b0 <_entry-0x7fffdf50>
    8000621c:	9a3e                	add	s4,s4,a5
    8000621e:	0001ca97          	auipc	s5,0x1c
    80006222:	de2a8a93          	addi	s5,s5,-542 # 80022000 <disk>
    80006226:	9a56                	add	s4,s4,s5
    80006228:	8552                	mv	a0,s4
    8000622a:	ffffa097          	auipc	ra,0xffffa
    8000622e:	792080e7          	jalr	1938(ra) # 800009bc <acquire>

  while((disk[n].used_idx % NUM) != (disk[n].used->id % NUM)){
    80006232:	9926                	add	s2,s2,s1
    80006234:	0932                	slli	s2,s2,0xc
    80006236:	9956                	add	s2,s2,s5
    80006238:	99ca                	add	s3,s3,s2
    8000623a:	0209d783          	lhu	a5,32(s3)
    8000623e:	0109b703          	ld	a4,16(s3)
    80006242:	00275683          	lhu	a3,2(a4)
    80006246:	8ebd                	xor	a3,a3,a5
    80006248:	8a9d                	andi	a3,a3,7
    8000624a:	c2a5                	beqz	a3,800062aa <virtio_disk_intr+0xb2>
    int id = disk[n].used->elems[disk[n].used_idx].id;

    if(disk[n].info[id].status != 0)
    8000624c:	8956                	mv	s2,s5
    8000624e:	00149693          	slli	a3,s1,0x1
    80006252:	96a6                	add	a3,a3,s1
    80006254:	00869993          	slli	s3,a3,0x8
      panic("virtio_disk_intr status");
    
    disk[n].info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk[n].info[id].b);

    disk[n].used_idx = (disk[n].used_idx + 1) % NUM;
    80006258:	06b2                	slli	a3,a3,0xc
    8000625a:	96d6                	add	a3,a3,s5
    8000625c:	6489                	lui	s1,0x2
    8000625e:	94b6                	add	s1,s1,a3
    int id = disk[n].used->elems[disk[n].used_idx].id;
    80006260:	078e                	slli	a5,a5,0x3
    80006262:	97ba                	add	a5,a5,a4
    80006264:	43dc                	lw	a5,4(a5)
    if(disk[n].info[id].status != 0)
    80006266:	00f98733          	add	a4,s3,a5
    8000626a:	20070713          	addi	a4,a4,512
    8000626e:	0712                	slli	a4,a4,0x4
    80006270:	974a                	add	a4,a4,s2
    80006272:	03074703          	lbu	a4,48(a4)
    80006276:	eb21                	bnez	a4,800062c6 <virtio_disk_intr+0xce>
    disk[n].info[id].b->disk = 0;   // disk is done with buf
    80006278:	97ce                	add	a5,a5,s3
    8000627a:	20078793          	addi	a5,a5,512
    8000627e:	0792                	slli	a5,a5,0x4
    80006280:	97ca                	add	a5,a5,s2
    80006282:	7798                	ld	a4,40(a5)
    80006284:	00072223          	sw	zero,4(a4)
    wakeup(disk[n].info[id].b);
    80006288:	7788                	ld	a0,40(a5)
    8000628a:	ffffc097          	auipc	ra,0xffffc
    8000628e:	e28080e7          	jalr	-472(ra) # 800020b2 <wakeup>
    disk[n].used_idx = (disk[n].used_idx + 1) % NUM;
    80006292:	0204d783          	lhu	a5,32(s1) # 2020 <_entry-0x7fffdfe0>
    80006296:	2785                	addiw	a5,a5,1
    80006298:	8b9d                	andi	a5,a5,7
    8000629a:	02f49023          	sh	a5,32(s1)
  while((disk[n].used_idx % NUM) != (disk[n].used->id % NUM)){
    8000629e:	6898                	ld	a4,16(s1)
    800062a0:	00275683          	lhu	a3,2(a4)
    800062a4:	8a9d                	andi	a3,a3,7
    800062a6:	faf69de3          	bne	a3,a5,80006260 <virtio_disk_intr+0x68>
  }

  release(&disk[n].vdisk_lock);
    800062aa:	8552                	mv	a0,s4
    800062ac:	ffffa097          	auipc	ra,0xffffa
    800062b0:	778080e7          	jalr	1912(ra) # 80000a24 <release>
}
    800062b4:	70e2                	ld	ra,56(sp)
    800062b6:	7442                	ld	s0,48(sp)
    800062b8:	74a2                	ld	s1,40(sp)
    800062ba:	7902                	ld	s2,32(sp)
    800062bc:	69e2                	ld	s3,24(sp)
    800062be:	6a42                	ld	s4,16(sp)
    800062c0:	6aa2                	ld	s5,8(sp)
    800062c2:	6121                	addi	sp,sp,64
    800062c4:	8082                	ret
      panic("virtio_disk_intr status");
    800062c6:	00001517          	auipc	a0,0x1
    800062ca:	5c250513          	addi	a0,a0,1474 # 80007888 <userret+0x7f8>
    800062ce:	ffffa097          	auipc	ra,0xffffa
    800062d2:	27a080e7          	jalr	634(ra) # 80000548 <panic>

00000000800062d6 <bit_isset>:
static Sz_info *bd_sizes; 
static void *bd_base;   // start address of memory managed by the buddy allocator
static struct spinlock lock;

// Return 1 if bit at position index in array is set to 1
int bit_isset(char *array, int index) {
    800062d6:	1141                	addi	sp,sp,-16
    800062d8:	e422                	sd	s0,8(sp)
    800062da:	0800                	addi	s0,sp,16
  char b = array[index/8];
  char m = (1 << (index % 8));
    800062dc:	41f5d79b          	sraiw	a5,a1,0x1f
    800062e0:	01d7d79b          	srliw	a5,a5,0x1d
    800062e4:	9dbd                	addw	a1,a1,a5
    800062e6:	0075f713          	andi	a4,a1,7
    800062ea:	9f1d                	subw	a4,a4,a5
    800062ec:	4785                	li	a5,1
    800062ee:	00e797bb          	sllw	a5,a5,a4
    800062f2:	0ff7f793          	andi	a5,a5,255
  char b = array[index/8];
    800062f6:	4035d59b          	sraiw	a1,a1,0x3
    800062fa:	95aa                	add	a1,a1,a0
  return (b & m) == m;
    800062fc:	0005c503          	lbu	a0,0(a1)
    80006300:	8d7d                	and	a0,a0,a5
    80006302:	8d1d                	sub	a0,a0,a5
}
    80006304:	00153513          	seqz	a0,a0
    80006308:	6422                	ld	s0,8(sp)
    8000630a:	0141                	addi	sp,sp,16
    8000630c:	8082                	ret

000000008000630e <bit_set>:

// Set bit at position index in array to 1
void bit_set(char *array, int index) {
    8000630e:	1141                	addi	sp,sp,-16
    80006310:	e422                	sd	s0,8(sp)
    80006312:	0800                	addi	s0,sp,16
  char b = array[index/8];
    80006314:	41f5d79b          	sraiw	a5,a1,0x1f
    80006318:	01d7d79b          	srliw	a5,a5,0x1d
    8000631c:	9dbd                	addw	a1,a1,a5
    8000631e:	4035d71b          	sraiw	a4,a1,0x3
    80006322:	953a                	add	a0,a0,a4
  char m = (1 << (index % 8));
    80006324:	899d                	andi	a1,a1,7
    80006326:	9d9d                	subw	a1,a1,a5
    80006328:	4785                	li	a5,1
    8000632a:	00b795bb          	sllw	a1,a5,a1
  array[index/8] = (b | m);
    8000632e:	00054783          	lbu	a5,0(a0)
    80006332:	8ddd                	or	a1,a1,a5
    80006334:	00b50023          	sb	a1,0(a0)
}
    80006338:	6422                	ld	s0,8(sp)
    8000633a:	0141                	addi	sp,sp,16
    8000633c:	8082                	ret

000000008000633e <bit_clear>:

// Clear bit at position index in array
void bit_clear(char *array, int index) {
    8000633e:	1141                	addi	sp,sp,-16
    80006340:	e422                	sd	s0,8(sp)
    80006342:	0800                	addi	s0,sp,16
  char b = array[index/8];
    80006344:	41f5d79b          	sraiw	a5,a1,0x1f
    80006348:	01d7d79b          	srliw	a5,a5,0x1d
    8000634c:	9dbd                	addw	a1,a1,a5
    8000634e:	4035d71b          	sraiw	a4,a1,0x3
    80006352:	953a                	add	a0,a0,a4
  char m = (1 << (index % 8));
    80006354:	899d                	andi	a1,a1,7
    80006356:	9d9d                	subw	a1,a1,a5
    80006358:	4785                	li	a5,1
    8000635a:	00b795bb          	sllw	a1,a5,a1
  array[index/8] = (b & ~m);
    8000635e:	fff5c593          	not	a1,a1
    80006362:	00054783          	lbu	a5,0(a0)
    80006366:	8dfd                	and	a1,a1,a5
    80006368:	00b50023          	sb	a1,0(a0)
}
    8000636c:	6422                	ld	s0,8(sp)
    8000636e:	0141                	addi	sp,sp,16
    80006370:	8082                	ret

0000000080006372 <bit_toggle>:

// toggle bit at position index in array
void bit_toggle(char *array,int index){
    80006372:	1141                	addi	sp,sp,-16
    80006374:	e422                	sd	s0,8(sp)
    80006376:	0800                	addi	s0,sp,16
  index/=2;
    80006378:	01f5d79b          	srliw	a5,a1,0x1f
    8000637c:	9dbd                	addw	a1,a1,a5
    8000637e:	4015d79b          	sraiw	a5,a1,0x1
  char b = array[index/8];
    80006382:	41f5d59b          	sraiw	a1,a1,0x1f
    80006386:	01d5d59b          	srliw	a1,a1,0x1d
    8000638a:	9fad                	addw	a5,a5,a1
    8000638c:	4037d71b          	sraiw	a4,a5,0x3
    80006390:	953a                	add	a0,a0,a4
  char m = (1 << (index % 8));
    80006392:	8b9d                	andi	a5,a5,7
    80006394:	40b785bb          	subw	a1,a5,a1
    80006398:	4785                	li	a5,1
    8000639a:	00b795bb          	sllw	a1,a5,a1
  array[index/8] = (b ^ m);
    8000639e:	00054783          	lbu	a5,0(a0)
    800063a2:	8dbd                	xor	a1,a1,a5
    800063a4:	00b50023          	sb	a1,0(a0)
}
    800063a8:	6422                	ld	s0,8(sp)
    800063aa:	0141                	addi	sp,sp,16
    800063ac:	8082                	ret

00000000800063ae <bit_get>:

// return 1 if the bit at position index in array is 1
// which indicates one is free , the other is allocated
int bit_get(char *array,int index){
    800063ae:	1141                	addi	sp,sp,-16
    800063b0:	e422                	sd	s0,8(sp)
    800063b2:	0800                	addi	s0,sp,16
  index/=2;
    800063b4:	01f5d79b          	srliw	a5,a1,0x1f
    800063b8:	9dbd                	addw	a1,a1,a5
    800063ba:	4015d79b          	sraiw	a5,a1,0x1
  char b = array[index/8];
  char m = (1 << (index % 8));
    800063be:	41f5d59b          	sraiw	a1,a1,0x1f
    800063c2:	01d5d59b          	srliw	a1,a1,0x1d
    800063c6:	9fad                	addw	a5,a5,a1
    800063c8:	0077f713          	andi	a4,a5,7
    800063cc:	9f0d                	subw	a4,a4,a1
    800063ce:	4585                	li	a1,1
    800063d0:	00e595bb          	sllw	a1,a1,a4
    800063d4:	0ff5f593          	andi	a1,a1,255
  char b = array[index/8];
    800063d8:	4037d79b          	sraiw	a5,a5,0x3
    800063dc:	97aa                	add	a5,a5,a0
  return (b & m) == m;
    800063de:	0007c503          	lbu	a0,0(a5)
    800063e2:	8d6d                	and	a0,a0,a1
    800063e4:	8d0d                	sub	a0,a0,a1
}
    800063e6:	00153513          	seqz	a0,a0
    800063ea:	6422                	ld	s0,8(sp)
    800063ec:	0141                	addi	sp,sp,16
    800063ee:	8082                	ret

00000000800063f0 <bd_print_vector>:

// Print a bit vector as a list of ranges of 1 bits
void
bd_print_vector(char *vector, int len) {
    800063f0:	715d                	addi	sp,sp,-80
    800063f2:	e486                	sd	ra,72(sp)
    800063f4:	e0a2                	sd	s0,64(sp)
    800063f6:	fc26                	sd	s1,56(sp)
    800063f8:	f84a                	sd	s2,48(sp)
    800063fa:	f44e                	sd	s3,40(sp)
    800063fc:	f052                	sd	s4,32(sp)
    800063fe:	ec56                	sd	s5,24(sp)
    80006400:	e85a                	sd	s6,16(sp)
    80006402:	e45e                	sd	s7,8(sp)
    80006404:	0880                	addi	s0,sp,80
    80006406:	8a2e                	mv	s4,a1
  int last, lb;
  
  last = 1;
  lb = 0;
  for (int b = 0; b < len; b++) {
    80006408:	08b05b63          	blez	a1,8000649e <bd_print_vector+0xae>
    8000640c:	89aa                	mv	s3,a0
    8000640e:	4481                	li	s1,0
  lb = 0;
    80006410:	4a81                	li	s5,0
  last = 1;
    80006412:	4905                	li	s2,1
    if (last == bit_isset(vector, b))
      continue;
    if(last == 1)
    80006414:	4b05                	li	s6,1
      printf(" [%d, %d)", lb, b);
    80006416:	00001b97          	auipc	s7,0x1
    8000641a:	48ab8b93          	addi	s7,s7,1162 # 800078a0 <userret+0x810>
    8000641e:	a821                	j	80006436 <bd_print_vector+0x46>
    lb = b;
    last = bit_isset(vector, b);
    80006420:	85a6                	mv	a1,s1
    80006422:	854e                	mv	a0,s3
    80006424:	00000097          	auipc	ra,0x0
    80006428:	eb2080e7          	jalr	-334(ra) # 800062d6 <bit_isset>
    8000642c:	892a                	mv	s2,a0
    8000642e:	8aa6                	mv	s5,s1
  for (int b = 0; b < len; b++) {
    80006430:	2485                	addiw	s1,s1,1
    80006432:	029a0463          	beq	s4,s1,8000645a <bd_print_vector+0x6a>
    if (last == bit_isset(vector, b))
    80006436:	85a6                	mv	a1,s1
    80006438:	854e                	mv	a0,s3
    8000643a:	00000097          	auipc	ra,0x0
    8000643e:	e9c080e7          	jalr	-356(ra) # 800062d6 <bit_isset>
    80006442:	ff2507e3          	beq	a0,s2,80006430 <bd_print_vector+0x40>
    if(last == 1)
    80006446:	fd691de3          	bne	s2,s6,80006420 <bd_print_vector+0x30>
      printf(" [%d, %d)", lb, b);
    8000644a:	8626                	mv	a2,s1
    8000644c:	85d6                	mv	a1,s5
    8000644e:	855e                	mv	a0,s7
    80006450:	ffffa097          	auipc	ra,0xffffa
    80006454:	142080e7          	jalr	322(ra) # 80000592 <printf>
    80006458:	b7e1                	j	80006420 <bd_print_vector+0x30>
  }
  if(lb == 0 || last == 1) {
    8000645a:	000a8563          	beqz	s5,80006464 <bd_print_vector+0x74>
    8000645e:	4785                	li	a5,1
    80006460:	00f91c63          	bne	s2,a5,80006478 <bd_print_vector+0x88>
    printf(" [%d, %d)", lb, len);
    80006464:	8652                	mv	a2,s4
    80006466:	85d6                	mv	a1,s5
    80006468:	00001517          	auipc	a0,0x1
    8000646c:	43850513          	addi	a0,a0,1080 # 800078a0 <userret+0x810>
    80006470:	ffffa097          	auipc	ra,0xffffa
    80006474:	122080e7          	jalr	290(ra) # 80000592 <printf>
  }
  printf("\n");
    80006478:	00001517          	auipc	a0,0x1
    8000647c:	d2850513          	addi	a0,a0,-728 # 800071a0 <userret+0x110>
    80006480:	ffffa097          	auipc	ra,0xffffa
    80006484:	112080e7          	jalr	274(ra) # 80000592 <printf>
}
    80006488:	60a6                	ld	ra,72(sp)
    8000648a:	6406                	ld	s0,64(sp)
    8000648c:	74e2                	ld	s1,56(sp)
    8000648e:	7942                	ld	s2,48(sp)
    80006490:	79a2                	ld	s3,40(sp)
    80006492:	7a02                	ld	s4,32(sp)
    80006494:	6ae2                	ld	s5,24(sp)
    80006496:	6b42                	ld	s6,16(sp)
    80006498:	6ba2                	ld	s7,8(sp)
    8000649a:	6161                	addi	sp,sp,80
    8000649c:	8082                	ret
  lb = 0;
    8000649e:	4a81                	li	s5,0
    800064a0:	b7d1                	j	80006464 <bd_print_vector+0x74>

00000000800064a2 <bd_print>:

// Print buddy's data structures
void
bd_print() {
  for (int k = 0; k < nsizes; k++) {
    800064a2:	00022697          	auipc	a3,0x22
    800064a6:	bb66a683          	lw	a3,-1098(a3) # 80028058 <nsizes>
    800064aa:	10d05063          	blez	a3,800065aa <bd_print+0x108>
bd_print() {
    800064ae:	711d                	addi	sp,sp,-96
    800064b0:	ec86                	sd	ra,88(sp)
    800064b2:	e8a2                	sd	s0,80(sp)
    800064b4:	e4a6                	sd	s1,72(sp)
    800064b6:	e0ca                	sd	s2,64(sp)
    800064b8:	fc4e                	sd	s3,56(sp)
    800064ba:	f852                	sd	s4,48(sp)
    800064bc:	f456                	sd	s5,40(sp)
    800064be:	f05a                	sd	s6,32(sp)
    800064c0:	ec5e                	sd	s7,24(sp)
    800064c2:	e862                	sd	s8,16(sp)
    800064c4:	e466                	sd	s9,8(sp)
    800064c6:	e06a                	sd	s10,0(sp)
    800064c8:	1080                	addi	s0,sp,96
  for (int k = 0; k < nsizes; k++) {
    800064ca:	4481                	li	s1,0
    printf("size %d (blksz %d nblk %d): free list: ", k, BLK_SIZE(k), NBLK(k));
    800064cc:	4a85                	li	s5,1
    800064ce:	4c41                	li	s8,16
    800064d0:	00001b97          	auipc	s7,0x1
    800064d4:	3e0b8b93          	addi	s7,s7,992 # 800078b0 <userret+0x820>
    lst_print(&bd_sizes[k].free);
    800064d8:	00022a17          	auipc	s4,0x22
    800064dc:	b78a0a13          	addi	s4,s4,-1160 # 80028050 <bd_sizes>
    printf("  alloc:");
    800064e0:	00001b17          	auipc	s6,0x1
    800064e4:	3f8b0b13          	addi	s6,s6,1016 # 800078d8 <userret+0x848>
    bd_print_vector(bd_sizes[k].alloc, NBLK(k));
    800064e8:	00022997          	auipc	s3,0x22
    800064ec:	b7098993          	addi	s3,s3,-1168 # 80028058 <nsizes>
    if(k > 0) {
      printf("  split:");
    800064f0:	00001c97          	auipc	s9,0x1
    800064f4:	3f8c8c93          	addi	s9,s9,1016 # 800078e8 <userret+0x858>
    800064f8:	a801                	j	80006508 <bd_print+0x66>
  for (int k = 0; k < nsizes; k++) {
    800064fa:	0009a683          	lw	a3,0(s3)
    800064fe:	0485                	addi	s1,s1,1
    80006500:	0004879b          	sext.w	a5,s1
    80006504:	08d7d563          	bge	a5,a3,8000658e <bd_print+0xec>
    80006508:	0004891b          	sext.w	s2,s1
    printf("size %d (blksz %d nblk %d): free list: ", k, BLK_SIZE(k), NBLK(k));
    8000650c:	36fd                	addiw	a3,a3,-1
    8000650e:	9e85                	subw	a3,a3,s1
    80006510:	00da96bb          	sllw	a3,s5,a3
    80006514:	009c1633          	sll	a2,s8,s1
    80006518:	85ca                	mv	a1,s2
    8000651a:	855e                	mv	a0,s7
    8000651c:	ffffa097          	auipc	ra,0xffffa
    80006520:	076080e7          	jalr	118(ra) # 80000592 <printf>
    lst_print(&bd_sizes[k].free);
    80006524:	00549d13          	slli	s10,s1,0x5
    80006528:	000a3503          	ld	a0,0(s4)
    8000652c:	956a                	add	a0,a0,s10
    8000652e:	00001097          	auipc	ra,0x1
    80006532:	a70080e7          	jalr	-1424(ra) # 80006f9e <lst_print>
    printf("  alloc:");
    80006536:	855a                	mv	a0,s6
    80006538:	ffffa097          	auipc	ra,0xffffa
    8000653c:	05a080e7          	jalr	90(ra) # 80000592 <printf>
    bd_print_vector(bd_sizes[k].alloc, NBLK(k));
    80006540:	0009a583          	lw	a1,0(s3)
    80006544:	35fd                	addiw	a1,a1,-1
    80006546:	412585bb          	subw	a1,a1,s2
    8000654a:	000a3783          	ld	a5,0(s4)
    8000654e:	97ea                	add	a5,a5,s10
    80006550:	00ba95bb          	sllw	a1,s5,a1
    80006554:	6b88                	ld	a0,16(a5)
    80006556:	00000097          	auipc	ra,0x0
    8000655a:	e9a080e7          	jalr	-358(ra) # 800063f0 <bd_print_vector>
    if(k > 0) {
    8000655e:	f9205ee3          	blez	s2,800064fa <bd_print+0x58>
      printf("  split:");
    80006562:	8566                	mv	a0,s9
    80006564:	ffffa097          	auipc	ra,0xffffa
    80006568:	02e080e7          	jalr	46(ra) # 80000592 <printf>
      bd_print_vector(bd_sizes[k].split, NBLK(k));
    8000656c:	0009a583          	lw	a1,0(s3)
    80006570:	35fd                	addiw	a1,a1,-1
    80006572:	412585bb          	subw	a1,a1,s2
    80006576:	000a3783          	ld	a5,0(s4)
    8000657a:	9d3e                	add	s10,s10,a5
    8000657c:	00ba95bb          	sllw	a1,s5,a1
    80006580:	018d3503          	ld	a0,24(s10)
    80006584:	00000097          	auipc	ra,0x0
    80006588:	e6c080e7          	jalr	-404(ra) # 800063f0 <bd_print_vector>
    8000658c:	b7bd                	j	800064fa <bd_print+0x58>
    }
  }
}
    8000658e:	60e6                	ld	ra,88(sp)
    80006590:	6446                	ld	s0,80(sp)
    80006592:	64a6                	ld	s1,72(sp)
    80006594:	6906                	ld	s2,64(sp)
    80006596:	79e2                	ld	s3,56(sp)
    80006598:	7a42                	ld	s4,48(sp)
    8000659a:	7aa2                	ld	s5,40(sp)
    8000659c:	7b02                	ld	s6,32(sp)
    8000659e:	6be2                	ld	s7,24(sp)
    800065a0:	6c42                	ld	s8,16(sp)
    800065a2:	6ca2                	ld	s9,8(sp)
    800065a4:	6d02                	ld	s10,0(sp)
    800065a6:	6125                	addi	sp,sp,96
    800065a8:	8082                	ret
    800065aa:	8082                	ret

00000000800065ac <firstk>:

// What is the first k such that 2^k >= n?
int
firstk(uint64 n) {
    800065ac:	1141                	addi	sp,sp,-16
    800065ae:	e422                	sd	s0,8(sp)
    800065b0:	0800                	addi	s0,sp,16
  int k = 0;
  uint64 size = LEAF_SIZE;

  while (size < n) {
    800065b2:	47c1                	li	a5,16
    800065b4:	00a7fb63          	bgeu	a5,a0,800065ca <firstk+0x1e>
    800065b8:	872a                	mv	a4,a0
  int k = 0;
    800065ba:	4501                	li	a0,0
    k++;
    800065bc:	2505                	addiw	a0,a0,1
    size *= 2;
    800065be:	0786                	slli	a5,a5,0x1
  while (size < n) {
    800065c0:	fee7eee3          	bltu	a5,a4,800065bc <firstk+0x10>
  }
  return k;
}
    800065c4:	6422                	ld	s0,8(sp)
    800065c6:	0141                	addi	sp,sp,16
    800065c8:	8082                	ret
  int k = 0;
    800065ca:	4501                	li	a0,0
    800065cc:	bfe5                	j	800065c4 <firstk+0x18>

00000000800065ce <blk_index>:

// Compute the block index for address p at size k
int
blk_index(int k, char *p) {
    800065ce:	1141                	addi	sp,sp,-16
    800065d0:	e422                	sd	s0,8(sp)
    800065d2:	0800                	addi	s0,sp,16
  int n = p - (char *) bd_base;
  return n / BLK_SIZE(k);
    800065d4:	00022797          	auipc	a5,0x22
    800065d8:	a747b783          	ld	a5,-1420(a5) # 80028048 <bd_base>
    800065dc:	9d9d                	subw	a1,a1,a5
    800065de:	47c1                	li	a5,16
    800065e0:	00a797b3          	sll	a5,a5,a0
    800065e4:	02f5c5b3          	div	a1,a1,a5
}
    800065e8:	0005851b          	sext.w	a0,a1
    800065ec:	6422                	ld	s0,8(sp)
    800065ee:	0141                	addi	sp,sp,16
    800065f0:	8082                	ret

00000000800065f2 <addr>:

// Convert a block index at size k back into an address
void *addr(int k, int bi) {
    800065f2:	1141                	addi	sp,sp,-16
    800065f4:	e422                	sd	s0,8(sp)
    800065f6:	0800                	addi	s0,sp,16
  int n = bi * BLK_SIZE(k);
    800065f8:	47c1                	li	a5,16
    800065fa:	00a797b3          	sll	a5,a5,a0
  return (char *) bd_base + n;
    800065fe:	02b787bb          	mulw	a5,a5,a1
}
    80006602:	00022517          	auipc	a0,0x22
    80006606:	a4653503          	ld	a0,-1466(a0) # 80028048 <bd_base>
    8000660a:	953e                	add	a0,a0,a5
    8000660c:	6422                	ld	s0,8(sp)
    8000660e:	0141                	addi	sp,sp,16
    80006610:	8082                	ret

0000000080006612 <bd_malloc>:

// allocate nbytes, but malloc won't return anything smaller than LEAF_SIZE
void *
bd_malloc(uint64 nbytes)
{
    80006612:	7159                	addi	sp,sp,-112
    80006614:	f486                	sd	ra,104(sp)
    80006616:	f0a2                	sd	s0,96(sp)
    80006618:	eca6                	sd	s1,88(sp)
    8000661a:	e8ca                	sd	s2,80(sp)
    8000661c:	e4ce                	sd	s3,72(sp)
    8000661e:	e0d2                	sd	s4,64(sp)
    80006620:	fc56                	sd	s5,56(sp)
    80006622:	f85a                	sd	s6,48(sp)
    80006624:	f45e                	sd	s7,40(sp)
    80006626:	f062                	sd	s8,32(sp)
    80006628:	ec66                	sd	s9,24(sp)
    8000662a:	e86a                	sd	s10,16(sp)
    8000662c:	e46e                	sd	s11,8(sp)
    8000662e:	1880                	addi	s0,sp,112
    80006630:	84aa                	mv	s1,a0
  int fk, k;

  acquire(&lock);
    80006632:	00022517          	auipc	a0,0x22
    80006636:	9ce50513          	addi	a0,a0,-1586 # 80028000 <lock>
    8000663a:	ffffa097          	auipc	ra,0xffffa
    8000663e:	382080e7          	jalr	898(ra) # 800009bc <acquire>

  // Find a free block >= nbytes, starting with smallest k possible
  fk = firstk(nbytes);
    80006642:	8526                	mv	a0,s1
    80006644:	00000097          	auipc	ra,0x0
    80006648:	f68080e7          	jalr	-152(ra) # 800065ac <firstk>
  for (k = fk; k < nsizes; k++) {
    8000664c:	00022797          	auipc	a5,0x22
    80006650:	a0c7a783          	lw	a5,-1524(a5) # 80028058 <nsizes>
    80006654:	02f55d63          	bge	a0,a5,8000668e <bd_malloc+0x7c>
    80006658:	8c2a                	mv	s8,a0
    8000665a:	00551913          	slli	s2,a0,0x5
    8000665e:	84aa                	mv	s1,a0
    if(!lst_empty(&bd_sizes[k].free))
    80006660:	00022997          	auipc	s3,0x22
    80006664:	9f098993          	addi	s3,s3,-1552 # 80028050 <bd_sizes>
  for (k = fk; k < nsizes; k++) {
    80006668:	00022a17          	auipc	s4,0x22
    8000666c:	9f0a0a13          	addi	s4,s4,-1552 # 80028058 <nsizes>
    if(!lst_empty(&bd_sizes[k].free))
    80006670:	0009b503          	ld	a0,0(s3)
    80006674:	954a                	add	a0,a0,s2
    80006676:	00001097          	auipc	ra,0x1
    8000667a:	8ae080e7          	jalr	-1874(ra) # 80006f24 <lst_empty>
    8000667e:	c115                	beqz	a0,800066a2 <bd_malloc+0x90>
  for (k = fk; k < nsizes; k++) {
    80006680:	2485                	addiw	s1,s1,1
    80006682:	02090913          	addi	s2,s2,32
    80006686:	000a2783          	lw	a5,0(s4)
    8000668a:	fef4c3e3          	blt	s1,a5,80006670 <bd_malloc+0x5e>
      break;
  }
  if(k >= nsizes) { // No free blocks?
    release(&lock);
    8000668e:	00022517          	auipc	a0,0x22
    80006692:	97250513          	addi	a0,a0,-1678 # 80028000 <lock>
    80006696:	ffffa097          	auipc	ra,0xffffa
    8000669a:	38e080e7          	jalr	910(ra) # 80000a24 <release>
    return 0;
    8000669e:	4b01                	li	s6,0
    800066a0:	a0e1                	j	80006768 <bd_malloc+0x156>
  if(k >= nsizes) { // No free blocks?
    800066a2:	00022797          	auipc	a5,0x22
    800066a6:	9b67a783          	lw	a5,-1610(a5) # 80028058 <nsizes>
    800066aa:	fef4d2e3          	bge	s1,a5,8000668e <bd_malloc+0x7c>
  }

  // Found a block; pop it and potentially split it.
  char *p = lst_pop(&bd_sizes[k].free);
    800066ae:	00549993          	slli	s3,s1,0x5
    800066b2:	00022917          	auipc	s2,0x22
    800066b6:	99e90913          	addi	s2,s2,-1634 # 80028050 <bd_sizes>
    800066ba:	00093503          	ld	a0,0(s2)
    800066be:	954e                	add	a0,a0,s3
    800066c0:	00001097          	auipc	ra,0x1
    800066c4:	890080e7          	jalr	-1904(ra) # 80006f50 <lst_pop>
    800066c8:	8b2a                	mv	s6,a0
  return n / BLK_SIZE(k);
    800066ca:	00022597          	auipc	a1,0x22
    800066ce:	97e5b583          	ld	a1,-1666(a1) # 80028048 <bd_base>
    800066d2:	40b505bb          	subw	a1,a0,a1
    800066d6:	47c1                	li	a5,16
    800066d8:	009797b3          	sll	a5,a5,s1
    800066dc:	02f5c5b3          	div	a1,a1,a5
  // bit_set(bd_sizes[k].alloc, blk_index(k, p));
  bit_toggle(bd_sizes[k].alloc, blk_index(k, p));
    800066e0:	00093783          	ld	a5,0(s2)
    800066e4:	97ce                	add	a5,a5,s3
    800066e6:	2581                	sext.w	a1,a1
    800066e8:	6b88                	ld	a0,16(a5)
    800066ea:	00000097          	auipc	ra,0x0
    800066ee:	c88080e7          	jalr	-888(ra) # 80006372 <bit_toggle>
  for(; k > fk; k--) {
    800066f2:	069c5363          	bge	s8,s1,80006758 <bd_malloc+0x146>
    // split a block at size k and mark one half allocated at size k-1
    // and put the buddy on the free list at size k-1
    char *q = p + BLK_SIZE(k-1);   // p's buddy
    800066f6:	4bc1                	li	s7,16
    bit_set(bd_sizes[k].split, blk_index(k, p));
    800066f8:	8dca                	mv	s11,s2
  int n = p - (char *) bd_base;
    800066fa:	00022d17          	auipc	s10,0x22
    800066fe:	94ed0d13          	addi	s10,s10,-1714 # 80028048 <bd_base>
    char *q = p + BLK_SIZE(k-1);   // p's buddy
    80006702:	85a6                	mv	a1,s1
    80006704:	34fd                	addiw	s1,s1,-1
    80006706:	009b9ab3          	sll	s5,s7,s1
    8000670a:	015b0cb3          	add	s9,s6,s5
    bit_set(bd_sizes[k].split, blk_index(k, p));
    8000670e:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
  int n = p - (char *) bd_base;
    80006712:	000d3903          	ld	s2,0(s10)
  return n / BLK_SIZE(k);
    80006716:	412b093b          	subw	s2,s6,s2
    8000671a:	00bb95b3          	sll	a1,s7,a1
    8000671e:	02b945b3          	div	a1,s2,a1
    bit_set(bd_sizes[k].split, blk_index(k, p));
    80006722:	013a07b3          	add	a5,s4,s3
    80006726:	2581                	sext.w	a1,a1
    80006728:	6f88                	ld	a0,24(a5)
    8000672a:	00000097          	auipc	ra,0x0
    8000672e:	be4080e7          	jalr	-1052(ra) # 8000630e <bit_set>
    // bit_set(bd_sizes[k-1].alloc, blk_index(k-1, p));
    bit_toggle(bd_sizes[k-1].alloc, blk_index(k-1, p));
    80006732:	1981                	addi	s3,s3,-32
    80006734:	9a4e                	add	s4,s4,s3
  return n / BLK_SIZE(k);
    80006736:	035945b3          	div	a1,s2,s5
    bit_toggle(bd_sizes[k-1].alloc, blk_index(k-1, p));
    8000673a:	2581                	sext.w	a1,a1
    8000673c:	010a3503          	ld	a0,16(s4)
    80006740:	00000097          	auipc	ra,0x0
    80006744:	c32080e7          	jalr	-974(ra) # 80006372 <bit_toggle>
    lst_push(&bd_sizes[k-1].free, q);
    80006748:	85e6                	mv	a1,s9
    8000674a:	8552                	mv	a0,s4
    8000674c:	00001097          	auipc	ra,0x1
    80006750:	83a080e7          	jalr	-1990(ra) # 80006f86 <lst_push>
  for(; k > fk; k--) {
    80006754:	fb8497e3          	bne	s1,s8,80006702 <bd_malloc+0xf0>
  }
  release(&lock);
    80006758:	00022517          	auipc	a0,0x22
    8000675c:	8a850513          	addi	a0,a0,-1880 # 80028000 <lock>
    80006760:	ffffa097          	auipc	ra,0xffffa
    80006764:	2c4080e7          	jalr	708(ra) # 80000a24 <release>

  return p;
}
    80006768:	855a                	mv	a0,s6
    8000676a:	70a6                	ld	ra,104(sp)
    8000676c:	7406                	ld	s0,96(sp)
    8000676e:	64e6                	ld	s1,88(sp)
    80006770:	6946                	ld	s2,80(sp)
    80006772:	69a6                	ld	s3,72(sp)
    80006774:	6a06                	ld	s4,64(sp)
    80006776:	7ae2                	ld	s5,56(sp)
    80006778:	7b42                	ld	s6,48(sp)
    8000677a:	7ba2                	ld	s7,40(sp)
    8000677c:	7c02                	ld	s8,32(sp)
    8000677e:	6ce2                	ld	s9,24(sp)
    80006780:	6d42                	ld	s10,16(sp)
    80006782:	6da2                	ld	s11,8(sp)
    80006784:	6165                	addi	sp,sp,112
    80006786:	8082                	ret

0000000080006788 <size>:

// Find the size of the block that p points to.
int
size(char *p) {
    80006788:	7139                	addi	sp,sp,-64
    8000678a:	fc06                	sd	ra,56(sp)
    8000678c:	f822                	sd	s0,48(sp)
    8000678e:	f426                	sd	s1,40(sp)
    80006790:	f04a                	sd	s2,32(sp)
    80006792:	ec4e                	sd	s3,24(sp)
    80006794:	e852                	sd	s4,16(sp)
    80006796:	e456                	sd	s5,8(sp)
    80006798:	e05a                	sd	s6,0(sp)
    8000679a:	0080                	addi	s0,sp,64
  for (int k = 0; k < nsizes; k++) {
    8000679c:	00022a97          	auipc	s5,0x22
    800067a0:	8bcaaa83          	lw	s5,-1860(s5) # 80028058 <nsizes>
  return n / BLK_SIZE(k);
    800067a4:	00022a17          	auipc	s4,0x22
    800067a8:	8a4a3a03          	ld	s4,-1884(s4) # 80028048 <bd_base>
    800067ac:	41450a3b          	subw	s4,a0,s4
    800067b0:	00022497          	auipc	s1,0x22
    800067b4:	8a04b483          	ld	s1,-1888(s1) # 80028050 <bd_sizes>
    800067b8:	03848493          	addi	s1,s1,56
  for (int k = 0; k < nsizes; k++) {
    800067bc:	4901                	li	s2,0
  return n / BLK_SIZE(k);
    800067be:	4b41                	li	s6,16
  for (int k = 0; k < nsizes; k++) {
    800067c0:	03595363          	bge	s2,s5,800067e6 <size+0x5e>
    if(bit_isset(bd_sizes[k+1].split, blk_index(k+1, p))) {
    800067c4:	0019099b          	addiw	s3,s2,1
  return n / BLK_SIZE(k);
    800067c8:	013b15b3          	sll	a1,s6,s3
    800067cc:	02ba45b3          	div	a1,s4,a1
    if(bit_isset(bd_sizes[k+1].split, blk_index(k+1, p))) {
    800067d0:	2581                	sext.w	a1,a1
    800067d2:	6088                	ld	a0,0(s1)
    800067d4:	00000097          	auipc	ra,0x0
    800067d8:	b02080e7          	jalr	-1278(ra) # 800062d6 <bit_isset>
    800067dc:	02048493          	addi	s1,s1,32
    800067e0:	e501                	bnez	a0,800067e8 <size+0x60>
  for (int k = 0; k < nsizes; k++) {
    800067e2:	894e                	mv	s2,s3
    800067e4:	bff1                	j	800067c0 <size+0x38>
      return k;
    }
  }
  return 0;
    800067e6:	4901                	li	s2,0
}
    800067e8:	854a                	mv	a0,s2
    800067ea:	70e2                	ld	ra,56(sp)
    800067ec:	7442                	ld	s0,48(sp)
    800067ee:	74a2                	ld	s1,40(sp)
    800067f0:	7902                	ld	s2,32(sp)
    800067f2:	69e2                	ld	s3,24(sp)
    800067f4:	6a42                	ld	s4,16(sp)
    800067f6:	6aa2                	ld	s5,8(sp)
    800067f8:	6b02                	ld	s6,0(sp)
    800067fa:	6121                	addi	sp,sp,64
    800067fc:	8082                	ret

00000000800067fe <bd_free>:

// Free memory pointed to by p, which was earlier allocated using
// bd_malloc.
void
bd_free(void *p) {
    800067fe:	7159                	addi	sp,sp,-112
    80006800:	f486                	sd	ra,104(sp)
    80006802:	f0a2                	sd	s0,96(sp)
    80006804:	eca6                	sd	s1,88(sp)
    80006806:	e8ca                	sd	s2,80(sp)
    80006808:	e4ce                	sd	s3,72(sp)
    8000680a:	e0d2                	sd	s4,64(sp)
    8000680c:	fc56                	sd	s5,56(sp)
    8000680e:	f85a                	sd	s6,48(sp)
    80006810:	f45e                	sd	s7,40(sp)
    80006812:	f062                	sd	s8,32(sp)
    80006814:	ec66                	sd	s9,24(sp)
    80006816:	e86a                	sd	s10,16(sp)
    80006818:	e46e                	sd	s11,8(sp)
    8000681a:	1880                	addi	s0,sp,112
    8000681c:	8baa                	mv	s7,a0
  void *q;
  int k;

  acquire(&lock);
    8000681e:	00021517          	auipc	a0,0x21
    80006822:	7e250513          	addi	a0,a0,2018 # 80028000 <lock>
    80006826:	ffffa097          	auipc	ra,0xffffa
    8000682a:	196080e7          	jalr	406(ra) # 800009bc <acquire>
  for (k = size(p); k < MAXSIZE; k++) {
    8000682e:	855e                	mv	a0,s7
    80006830:	00000097          	auipc	ra,0x0
    80006834:	f58080e7          	jalr	-168(ra) # 80006788 <size>
    80006838:	84aa                	mv	s1,a0
    8000683a:	00022797          	auipc	a5,0x22
    8000683e:	81e7a783          	lw	a5,-2018(a5) # 80028058 <nsizes>
    80006842:	37fd                	addiw	a5,a5,-1
    80006844:	0cf55063          	bge	a0,a5,80006904 <bd_free+0x106>
    80006848:	00150a93          	addi	s5,a0,1
    8000684c:	0a96                	slli	s5,s5,0x5
  int n = p - (char *) bd_base;
    8000684e:	00021d97          	auipc	s11,0x21
    80006852:	7fad8d93          	addi	s11,s11,2042 # 80028048 <bd_base>
  return n / BLK_SIZE(k);
    80006856:	4d41                	li	s10,16
    int bi = blk_index(k, p);
    int buddy = (bi % 2 == 0) ? bi+1 : bi-1;
    // bit_clear(bd_sizes[k].alloc, bi);  // free p at size k
    bit_toggle(bd_sizes[k].alloc, bi);  // free p at size k
    80006858:	00021c97          	auipc	s9,0x21
    8000685c:	7f8c8c93          	addi	s9,s9,2040 # 80028050 <bd_sizes>
    80006860:	a081                	j	800068a0 <bd_free+0xa2>
    int buddy = (bi % 2 == 0) ? bi+1 : bi-1;
    80006862:	fffb0c1b          	addiw	s8,s6,-1
    80006866:	a899                	j	800068bc <bd_free+0xbe>
    if(buddy % 2 == 0) {
      p = q;
    }
    // at size k+1, mark that the merged buddy pair isn't split
    // anymore
    bit_clear(bd_sizes[k+1].split, blk_index(k+1, p));
    80006868:	2485                	addiw	s1,s1,1
  int n = p - (char *) bd_base;
    8000686a:	000db583          	ld	a1,0(s11)
  return n / BLK_SIZE(k);
    8000686e:	40bb85bb          	subw	a1,s7,a1
    80006872:	009d17b3          	sll	a5,s10,s1
    80006876:	02f5c5b3          	div	a1,a1,a5
    bit_clear(bd_sizes[k+1].split, blk_index(k+1, p));
    8000687a:	000cb783          	ld	a5,0(s9)
    8000687e:	97d6                	add	a5,a5,s5
    80006880:	2581                	sext.w	a1,a1
    80006882:	6f88                	ld	a0,24(a5)
    80006884:	00000097          	auipc	ra,0x0
    80006888:	aba080e7          	jalr	-1350(ra) # 8000633e <bit_clear>
  for (k = size(p); k < MAXSIZE; k++) {
    8000688c:	020a8a93          	addi	s5,s5,32
    80006890:	00021797          	auipc	a5,0x21
    80006894:	7c878793          	addi	a5,a5,1992 # 80028058 <nsizes>
    80006898:	439c                	lw	a5,0(a5)
    8000689a:	37fd                	addiw	a5,a5,-1
    8000689c:	06f4d463          	bge	s1,a5,80006904 <bd_free+0x106>
  int n = p - (char *) bd_base;
    800068a0:	000db903          	ld	s2,0(s11)
  return n / BLK_SIZE(k);
    800068a4:	009d1a33          	sll	s4,s10,s1
    800068a8:	412b87bb          	subw	a5,s7,s2
    800068ac:	0347c7b3          	div	a5,a5,s4
    800068b0:	00078b1b          	sext.w	s6,a5
    int buddy = (bi % 2 == 0) ? bi+1 : bi-1;
    800068b4:	8b85                	andi	a5,a5,1
    800068b6:	f7d5                	bnez	a5,80006862 <bd_free+0x64>
    800068b8:	001b0c1b          	addiw	s8,s6,1
    bit_toggle(bd_sizes[k].alloc, bi);  // free p at size k
    800068bc:	fe0a8993          	addi	s3,s5,-32
    800068c0:	000cb783          	ld	a5,0(s9)
    800068c4:	99be                	add	s3,s3,a5
    800068c6:	85da                	mv	a1,s6
    800068c8:	0109b503          	ld	a0,16(s3)
    800068cc:	00000097          	auipc	ra,0x0
    800068d0:	aa6080e7          	jalr	-1370(ra) # 80006372 <bit_toggle>
    if (bit_get(bd_sizes[k].alloc, bi)) {  // is buddy allocated?
    800068d4:	85da                	mv	a1,s6
    800068d6:	0109b503          	ld	a0,16(s3)
    800068da:	00000097          	auipc	ra,0x0
    800068de:	ad4080e7          	jalr	-1324(ra) # 800063ae <bit_get>
    800068e2:	e10d                	bnez	a0,80006904 <bd_free+0x106>
  int n = bi * BLK_SIZE(k);
    800068e4:	000c099b          	sext.w	s3,s8
  return (char *) bd_base + n;
    800068e8:	038a0a3b          	mulw	s4,s4,s8
    800068ec:	9952                	add	s2,s2,s4
    lst_remove(q);    // remove buddy from free list
    800068ee:	854a                	mv	a0,s2
    800068f0:	00000097          	auipc	ra,0x0
    800068f4:	64a080e7          	jalr	1610(ra) # 80006f3a <lst_remove>
    if(buddy % 2 == 0) {
    800068f8:	0019f993          	andi	s3,s3,1
    800068fc:	f60996e3          	bnez	s3,80006868 <bd_free+0x6a>
      p = q;
    80006900:	8bca                	mv	s7,s2
    80006902:	b79d                	j	80006868 <bd_free+0x6a>
  }
  lst_push(&bd_sizes[k].free, p);
    80006904:	0496                	slli	s1,s1,0x5
    80006906:	85de                	mv	a1,s7
    80006908:	00021517          	auipc	a0,0x21
    8000690c:	74853503          	ld	a0,1864(a0) # 80028050 <bd_sizes>
    80006910:	9526                	add	a0,a0,s1
    80006912:	00000097          	auipc	ra,0x0
    80006916:	674080e7          	jalr	1652(ra) # 80006f86 <lst_push>
  release(&lock);
    8000691a:	00021517          	auipc	a0,0x21
    8000691e:	6e650513          	addi	a0,a0,1766 # 80028000 <lock>
    80006922:	ffffa097          	auipc	ra,0xffffa
    80006926:	102080e7          	jalr	258(ra) # 80000a24 <release>
}
    8000692a:	70a6                	ld	ra,104(sp)
    8000692c:	7406                	ld	s0,96(sp)
    8000692e:	64e6                	ld	s1,88(sp)
    80006930:	6946                	ld	s2,80(sp)
    80006932:	69a6                	ld	s3,72(sp)
    80006934:	6a06                	ld	s4,64(sp)
    80006936:	7ae2                	ld	s5,56(sp)
    80006938:	7b42                	ld	s6,48(sp)
    8000693a:	7ba2                	ld	s7,40(sp)
    8000693c:	7c02                	ld	s8,32(sp)
    8000693e:	6ce2                	ld	s9,24(sp)
    80006940:	6d42                	ld	s10,16(sp)
    80006942:	6da2                	ld	s11,8(sp)
    80006944:	6165                	addi	sp,sp,112
    80006946:	8082                	ret

0000000080006948 <blk_index_next>:

// Compute the first block at size k that doesn't contain p
int
blk_index_next(int k, char *p) {
    80006948:	1141                	addi	sp,sp,-16
    8000694a:	e422                	sd	s0,8(sp)
    8000694c:	0800                	addi	s0,sp,16
  int n = (p - (char *) bd_base) / BLK_SIZE(k);
    8000694e:	00021797          	auipc	a5,0x21
    80006952:	6fa7b783          	ld	a5,1786(a5) # 80028048 <bd_base>
    80006956:	8d9d                	sub	a1,a1,a5
    80006958:	47c1                	li	a5,16
    8000695a:	00a797b3          	sll	a5,a5,a0
    8000695e:	02f5c533          	div	a0,a1,a5
    80006962:	2501                	sext.w	a0,a0
  if((p - (char*) bd_base) % BLK_SIZE(k) != 0)
    80006964:	02f5e5b3          	rem	a1,a1,a5
    80006968:	c191                	beqz	a1,8000696c <blk_index_next+0x24>
      n++;
    8000696a:	2505                	addiw	a0,a0,1
  return n ;
}
    8000696c:	6422                	ld	s0,8(sp)
    8000696e:	0141                	addi	sp,sp,16
    80006970:	8082                	ret

0000000080006972 <log2>:

int
log2(uint64 n) {
    80006972:	1141                	addi	sp,sp,-16
    80006974:	e422                	sd	s0,8(sp)
    80006976:	0800                	addi	s0,sp,16
  int k = 0;
  while (n > 1) {
    80006978:	4705                	li	a4,1
    8000697a:	00a77b63          	bgeu	a4,a0,80006990 <log2+0x1e>
    8000697e:	87aa                	mv	a5,a0
  int k = 0;
    80006980:	4501                	li	a0,0
    k++;
    80006982:	2505                	addiw	a0,a0,1
    n = n >> 1;
    80006984:	8385                	srli	a5,a5,0x1
  while (n > 1) {
    80006986:	fef76ee3          	bltu	a4,a5,80006982 <log2+0x10>
  }
  return k;
}
    8000698a:	6422                	ld	s0,8(sp)
    8000698c:	0141                	addi	sp,sp,16
    8000698e:	8082                	ret
  int k = 0;
    80006990:	4501                	li	a0,0
    80006992:	bfe5                	j	8000698a <log2+0x18>

0000000080006994 <bd_mark>:

// Mark memory from [start, stop), starting at size 0, as allocated. 
void
bd_mark(void *start, void *stop)
{
    80006994:	711d                	addi	sp,sp,-96
    80006996:	ec86                	sd	ra,88(sp)
    80006998:	e8a2                	sd	s0,80(sp)
    8000699a:	e4a6                	sd	s1,72(sp)
    8000699c:	e0ca                	sd	s2,64(sp)
    8000699e:	fc4e                	sd	s3,56(sp)
    800069a0:	f852                	sd	s4,48(sp)
    800069a2:	f456                	sd	s5,40(sp)
    800069a4:	f05a                	sd	s6,32(sp)
    800069a6:	ec5e                	sd	s7,24(sp)
    800069a8:	e862                	sd	s8,16(sp)
    800069aa:	e466                	sd	s9,8(sp)
    800069ac:	e06a                	sd	s10,0(sp)
    800069ae:	1080                	addi	s0,sp,96
  int bi, bj;

  if (((uint64) start % LEAF_SIZE != 0) || ((uint64) stop % LEAF_SIZE != 0))
    800069b0:	00b56933          	or	s2,a0,a1
    800069b4:	00f97913          	andi	s2,s2,15
    800069b8:	04091263          	bnez	s2,800069fc <bd_mark+0x68>
    800069bc:	8b2a                	mv	s6,a0
    800069be:	8bae                	mv	s7,a1
    panic("bd_mark");

  for (int k = 0; k < nsizes; k++) {
    800069c0:	00021c17          	auipc	s8,0x21
    800069c4:	698c2c03          	lw	s8,1688(s8) # 80028058 <nsizes>
    800069c8:	4981                	li	s3,0
  int n = p - (char *) bd_base;
    800069ca:	00021d17          	auipc	s10,0x21
    800069ce:	67ed0d13          	addi	s10,s10,1662 # 80028048 <bd_base>
  return n / BLK_SIZE(k);
    800069d2:	4cc1                	li	s9,16
    bi = blk_index(k, start);
    bj = blk_index_next(k, stop);
    for(; bi < bj; bi++) {
      if(k > 0) {
        
        bit_set(bd_sizes[k].split, bi);
    800069d4:	00021a97          	auipc	s5,0x21
    800069d8:	67ca8a93          	addi	s5,s5,1660 # 80028050 <bd_sizes>
  for (int k = 0; k < nsizes; k++) {
    800069dc:	07804563          	bgtz	s8,80006a46 <bd_mark+0xb2>
      }
      // bit_set(bd_sizes[k].alloc, bi);
      bit_toggle(bd_sizes[k].alloc,bi);
    }
  }
} 
    800069e0:	60e6                	ld	ra,88(sp)
    800069e2:	6446                	ld	s0,80(sp)
    800069e4:	64a6                	ld	s1,72(sp)
    800069e6:	6906                	ld	s2,64(sp)
    800069e8:	79e2                	ld	s3,56(sp)
    800069ea:	7a42                	ld	s4,48(sp)
    800069ec:	7aa2                	ld	s5,40(sp)
    800069ee:	7b02                	ld	s6,32(sp)
    800069f0:	6be2                	ld	s7,24(sp)
    800069f2:	6c42                	ld	s8,16(sp)
    800069f4:	6ca2                	ld	s9,8(sp)
    800069f6:	6d02                	ld	s10,0(sp)
    800069f8:	6125                	addi	sp,sp,96
    800069fa:	8082                	ret
    panic("bd_mark");
    800069fc:	00001517          	auipc	a0,0x1
    80006a00:	efc50513          	addi	a0,a0,-260 # 800078f8 <userret+0x868>
    80006a04:	ffffa097          	auipc	ra,0xffffa
    80006a08:	b44080e7          	jalr	-1212(ra) # 80000548 <panic>
      bit_toggle(bd_sizes[k].alloc,bi);
    80006a0c:	000ab783          	ld	a5,0(s5)
    80006a10:	97ca                	add	a5,a5,s2
    80006a12:	85a6                	mv	a1,s1
    80006a14:	6b88                	ld	a0,16(a5)
    80006a16:	00000097          	auipc	ra,0x0
    80006a1a:	95c080e7          	jalr	-1700(ra) # 80006372 <bit_toggle>
    for(; bi < bj; bi++) {
    80006a1e:	2485                	addiw	s1,s1,1
    80006a20:	009a0e63          	beq	s4,s1,80006a3c <bd_mark+0xa8>
      if(k > 0) {
    80006a24:	ff3054e3          	blez	s3,80006a0c <bd_mark+0x78>
        bit_set(bd_sizes[k].split, bi);
    80006a28:	000ab783          	ld	a5,0(s5)
    80006a2c:	97ca                	add	a5,a5,s2
    80006a2e:	85a6                	mv	a1,s1
    80006a30:	6f88                	ld	a0,24(a5)
    80006a32:	00000097          	auipc	ra,0x0
    80006a36:	8dc080e7          	jalr	-1828(ra) # 8000630e <bit_set>
    80006a3a:	bfc9                	j	80006a0c <bd_mark+0x78>
  for (int k = 0; k < nsizes; k++) {
    80006a3c:	2985                	addiw	s3,s3,1
    80006a3e:	02090913          	addi	s2,s2,32
    80006a42:	f9898fe3          	beq	s3,s8,800069e0 <bd_mark+0x4c>
  int n = p - (char *) bd_base;
    80006a46:	000d3483          	ld	s1,0(s10)
  return n / BLK_SIZE(k);
    80006a4a:	409b04bb          	subw	s1,s6,s1
    80006a4e:	013c97b3          	sll	a5,s9,s3
    80006a52:	02f4c4b3          	div	s1,s1,a5
    80006a56:	2481                	sext.w	s1,s1
    bj = blk_index_next(k, stop);
    80006a58:	85de                	mv	a1,s7
    80006a5a:	854e                	mv	a0,s3
    80006a5c:	00000097          	auipc	ra,0x0
    80006a60:	eec080e7          	jalr	-276(ra) # 80006948 <blk_index_next>
    80006a64:	8a2a                	mv	s4,a0
    for(; bi < bj; bi++) {
    80006a66:	faa4cfe3          	blt	s1,a0,80006a24 <bd_mark+0x90>
    80006a6a:	bfc9                	j	80006a3c <bd_mark+0xa8>

0000000080006a6c <addr_in_range>:

// return 1 if addr is in range (left,right)
int addr_in_range(void *addr,void *left,void *right,int size){
    80006a6c:	1141                	addi	sp,sp,-16
    80006a6e:	e422                	sd	s0,8(sp)
    80006a70:	0800                	addi	s0,sp,16
  return (addr>=left)&&((addr+size)<right);
    80006a72:	00b56863          	bltu	a0,a1,80006a82 <addr_in_range+0x16>
    80006a76:	9536                	add	a0,a0,a3
    80006a78:	00c53533          	sltu	a0,a0,a2
}
    80006a7c:	6422                	ld	s0,8(sp)
    80006a7e:	0141                	addi	sp,sp,16
    80006a80:	8082                	ret
  return (addr>=left)&&((addr+size)<right);
    80006a82:	4501                	li	a0,0
    80006a84:	bfe5                	j	80006a7c <addr_in_range+0x10>

0000000080006a86 <bd_initfree_pair>:

// If a block is marked as allocated and the buddy is free, put the
// buddy on the free list at size k.
int
bd_initfree_pair(int k, int bi,void *left,void *right) {
    80006a86:	715d                	addi	sp,sp,-80
    80006a88:	e486                	sd	ra,72(sp)
    80006a8a:	e0a2                	sd	s0,64(sp)
    80006a8c:	fc26                	sd	s1,56(sp)
    80006a8e:	f84a                	sd	s2,48(sp)
    80006a90:	f44e                	sd	s3,40(sp)
    80006a92:	f052                	sd	s4,32(sp)
    80006a94:	ec56                	sd	s5,24(sp)
    80006a96:	e85a                	sd	s6,16(sp)
    80006a98:	e45e                	sd	s7,8(sp)
    80006a9a:	0880                	addi	s0,sp,80
    80006a9c:	8b2a                	mv	s6,a0
    80006a9e:	89b2                	mv	s3,a2
    80006aa0:	8a36                	mv	s4,a3
  int buddy = (bi % 2 == 0) ? bi+1 : bi-1;
    80006aa2:	00058b9b          	sext.w	s7,a1
    80006aa6:	0015f793          	andi	a5,a1,1
    80006aaa:	ebb1                	bnez	a5,80006afe <bd_initfree_pair+0x78>
    80006aac:	00158a9b          	addiw	s5,a1,1
  int free = 0;
  // if(bit_isset(bd_sizes[k].alloc, bi) !=  bit_isset(bd_sizes[k].alloc, buddy)) {
  if(bit_get(bd_sizes[k].alloc,bi)){
    80006ab0:	005b1793          	slli	a5,s6,0x5
    80006ab4:	00021917          	auipc	s2,0x21
    80006ab8:	59c93903          	ld	s2,1436(s2) # 80028050 <bd_sizes>
    80006abc:	993e                	add	s2,s2,a5
    80006abe:	01093503          	ld	a0,16(s2)
    80006ac2:	00000097          	auipc	ra,0x0
    80006ac6:	8ec080e7          	jalr	-1812(ra) # 800063ae <bit_get>
    80006aca:	84aa                	mv	s1,a0
    80006acc:	c529                	beqz	a0,80006b16 <bd_initfree_pair+0x90>
    // one of the pair is free
    free = BLK_SIZE(k);
    80006ace:	44c1                	li	s1,16
    80006ad0:	016494b3          	sll	s1,s1,s6
    80006ad4:	2481                	sext.w	s1,s1
  int n = bi * BLK_SIZE(k);
    80006ad6:	8726                	mv	a4,s1
  return (char *) bd_base + n;
    80006ad8:	00021797          	auipc	a5,0x21
    80006adc:	5707b783          	ld	a5,1392(a5) # 80028048 <bd_base>
    80006ae0:	029b85bb          	mulw	a1,s7,s1
    80006ae4:	95be                	add	a1,a1,a5
  return (addr>=left)&&((addr+size)<right);
    80006ae6:	0135ef63          	bltu	a1,s3,80006b04 <bd_initfree_pair+0x7e>
    80006aea:	009586b3          	add	a3,a1,s1
    80006aee:	0146fb63          	bgeu	a3,s4,80006b04 <bd_initfree_pair+0x7e>
    if(addr_in_range(addr(k,bi),left,right,free)){
      lst_push(&bd_sizes[k].free, addr(k, bi)); 
    80006af2:	854a                	mv	a0,s2
    80006af4:	00000097          	auipc	ra,0x0
    80006af8:	492080e7          	jalr	1170(ra) # 80006f86 <lst_push>
    80006afc:	a829                	j	80006b16 <bd_initfree_pair+0x90>
  int buddy = (bi % 2 == 0) ? bi+1 : bi-1;
    80006afe:	fff58a9b          	addiw	s5,a1,-1
    80006b02:	b77d                	j	80006ab0 <bd_initfree_pair+0x2a>
  return (char *) bd_base + n;
    80006b04:	02ea8abb          	mulw	s5,s5,a4
    }else{
      lst_push(&bd_sizes[k].free, addr(k, buddy)); 
    80006b08:	015785b3          	add	a1,a5,s5
    80006b0c:	854a                	mv	a0,s2
    80006b0e:	00000097          	auipc	ra,0x0
    80006b12:	478080e7          	jalr	1144(ra) # 80006f86 <lst_push>
    }
    
  }
  return free;
}
    80006b16:	8526                	mv	a0,s1
    80006b18:	60a6                	ld	ra,72(sp)
    80006b1a:	6406                	ld	s0,64(sp)
    80006b1c:	74e2                	ld	s1,56(sp)
    80006b1e:	7942                	ld	s2,48(sp)
    80006b20:	79a2                	ld	s3,40(sp)
    80006b22:	7a02                	ld	s4,32(sp)
    80006b24:	6ae2                	ld	s5,24(sp)
    80006b26:	6b42                	ld	s6,16(sp)
    80006b28:	6ba2                	ld	s7,8(sp)
    80006b2a:	6161                	addi	sp,sp,80
    80006b2c:	8082                	ret

0000000080006b2e <bd_initfree>:
  
// Initialize the free lists for each size k.  For each size k, there
// are only two pairs that may have a buddy that should be on free list:
// bd_left and bd_right.
int
bd_initfree(void *bd_left, void *bd_right) {
    80006b2e:	711d                	addi	sp,sp,-96
    80006b30:	ec86                	sd	ra,88(sp)
    80006b32:	e8a2                	sd	s0,80(sp)
    80006b34:	e4a6                	sd	s1,72(sp)
    80006b36:	e0ca                	sd	s2,64(sp)
    80006b38:	fc4e                	sd	s3,56(sp)
    80006b3a:	f852                	sd	s4,48(sp)
    80006b3c:	f456                	sd	s5,40(sp)
    80006b3e:	f05a                	sd	s6,32(sp)
    80006b40:	ec5e                	sd	s7,24(sp)
    80006b42:	e862                	sd	s8,16(sp)
    80006b44:	e466                	sd	s9,8(sp)
    80006b46:	e06a                	sd	s10,0(sp)
    80006b48:	1080                	addi	s0,sp,96
  int free = 0;

  for (int k = 0; k < MAXSIZE; k++) {   // skip max size
    80006b4a:	00021717          	auipc	a4,0x21
    80006b4e:	50e72703          	lw	a4,1294(a4) # 80028058 <nsizes>
    80006b52:	4785                	li	a5,1
    80006b54:	06e7df63          	bge	a5,a4,80006bd2 <bd_initfree+0xa4>
    80006b58:	8aaa                	mv	s5,a0
    80006b5a:	8b2e                	mv	s6,a1
    80006b5c:	4901                	li	s2,0
  int free = 0;
    80006b5e:	4a01                	li	s4,0
  int n = p - (char *) bd_base;
    80006b60:	00021c97          	auipc	s9,0x21
    80006b64:	4e8c8c93          	addi	s9,s9,1256 # 80028048 <bd_base>
  return n / BLK_SIZE(k);
    80006b68:	4c41                	li	s8,16
  for (int k = 0; k < MAXSIZE; k++) {   // skip max size
    80006b6a:	00021b97          	auipc	s7,0x21
    80006b6e:	4eeb8b93          	addi	s7,s7,1262 # 80028058 <nsizes>
    80006b72:	a039                	j	80006b80 <bd_initfree+0x52>
    80006b74:	2905                	addiw	s2,s2,1
    80006b76:	000ba783          	lw	a5,0(s7)
    80006b7a:	37fd                	addiw	a5,a5,-1
    80006b7c:	04f95c63          	bge	s2,a5,80006bd4 <bd_initfree+0xa6>
    int left = blk_index_next(k, bd_left);
    80006b80:	85d6                	mv	a1,s5
    80006b82:	854a                	mv	a0,s2
    80006b84:	00000097          	auipc	ra,0x0
    80006b88:	dc4080e7          	jalr	-572(ra) # 80006948 <blk_index_next>
    80006b8c:	89aa                	mv	s3,a0
  int n = p - (char *) bd_base;
    80006b8e:	000cb483          	ld	s1,0(s9)
  return n / BLK_SIZE(k);
    80006b92:	409b04bb          	subw	s1,s6,s1
    80006b96:	012c17b3          	sll	a5,s8,s2
    80006b9a:	02f4c4b3          	div	s1,s1,a5
    80006b9e:	2481                	sext.w	s1,s1
    int right = blk_index(k, bd_right);
    free += bd_initfree_pair(k, left,bd_left,bd_right);
    80006ba0:	86da                	mv	a3,s6
    80006ba2:	8656                	mv	a2,s5
    80006ba4:	85aa                	mv	a1,a0
    80006ba6:	854a                	mv	a0,s2
    80006ba8:	00000097          	auipc	ra,0x0
    80006bac:	ede080e7          	jalr	-290(ra) # 80006a86 <bd_initfree_pair>
    80006bb0:	01450d3b          	addw	s10,a0,s4
    80006bb4:	000d0a1b          	sext.w	s4,s10
    if(right <= left)
    80006bb8:	fa99dee3          	bge	s3,s1,80006b74 <bd_initfree+0x46>
      continue;
    free += bd_initfree_pair(k, right,bd_left,bd_right);
    80006bbc:	86da                	mv	a3,s6
    80006bbe:	8656                	mv	a2,s5
    80006bc0:	85a6                	mv	a1,s1
    80006bc2:	854a                	mv	a0,s2
    80006bc4:	00000097          	auipc	ra,0x0
    80006bc8:	ec2080e7          	jalr	-318(ra) # 80006a86 <bd_initfree_pair>
    80006bcc:	00ad0a3b          	addw	s4,s10,a0
    80006bd0:	b755                	j	80006b74 <bd_initfree+0x46>
  int free = 0;
    80006bd2:	4a01                	li	s4,0
  }
  return free;
}
    80006bd4:	8552                	mv	a0,s4
    80006bd6:	60e6                	ld	ra,88(sp)
    80006bd8:	6446                	ld	s0,80(sp)
    80006bda:	64a6                	ld	s1,72(sp)
    80006bdc:	6906                	ld	s2,64(sp)
    80006bde:	79e2                	ld	s3,56(sp)
    80006be0:	7a42                	ld	s4,48(sp)
    80006be2:	7aa2                	ld	s5,40(sp)
    80006be4:	7b02                	ld	s6,32(sp)
    80006be6:	6be2                	ld	s7,24(sp)
    80006be8:	6c42                	ld	s8,16(sp)
    80006bea:	6ca2                	ld	s9,8(sp)
    80006bec:	6d02                	ld	s10,0(sp)
    80006bee:	6125                	addi	sp,sp,96
    80006bf0:	8082                	ret

0000000080006bf2 <bd_mark_data_structures>:

// Mark the range [bd_base,p) as allocated
int
bd_mark_data_structures(char *p) {
    80006bf2:	7179                	addi	sp,sp,-48
    80006bf4:	f406                	sd	ra,40(sp)
    80006bf6:	f022                	sd	s0,32(sp)
    80006bf8:	ec26                	sd	s1,24(sp)
    80006bfa:	e84a                	sd	s2,16(sp)
    80006bfc:	e44e                	sd	s3,8(sp)
    80006bfe:	1800                	addi	s0,sp,48
    80006c00:	892a                	mv	s2,a0
  int meta = p - (char*)bd_base;
    80006c02:	00021997          	auipc	s3,0x21
    80006c06:	44698993          	addi	s3,s3,1094 # 80028048 <bd_base>
    80006c0a:	0009b483          	ld	s1,0(s3)
    80006c0e:	409504bb          	subw	s1,a0,s1
  printf("bd: %d meta bytes for managing %d bytes of memory\n", meta, BLK_SIZE(MAXSIZE));
    80006c12:	00021797          	auipc	a5,0x21
    80006c16:	4467a783          	lw	a5,1094(a5) # 80028058 <nsizes>
    80006c1a:	37fd                	addiw	a5,a5,-1
    80006c1c:	4641                	li	a2,16
    80006c1e:	00f61633          	sll	a2,a2,a5
    80006c22:	85a6                	mv	a1,s1
    80006c24:	00001517          	auipc	a0,0x1
    80006c28:	cdc50513          	addi	a0,a0,-804 # 80007900 <userret+0x870>
    80006c2c:	ffffa097          	auipc	ra,0xffffa
    80006c30:	966080e7          	jalr	-1690(ra) # 80000592 <printf>
  bd_mark(bd_base, p);
    80006c34:	85ca                	mv	a1,s2
    80006c36:	0009b503          	ld	a0,0(s3)
    80006c3a:	00000097          	auipc	ra,0x0
    80006c3e:	d5a080e7          	jalr	-678(ra) # 80006994 <bd_mark>
  return meta;
}
    80006c42:	8526                	mv	a0,s1
    80006c44:	70a2                	ld	ra,40(sp)
    80006c46:	7402                	ld	s0,32(sp)
    80006c48:	64e2                	ld	s1,24(sp)
    80006c4a:	6942                	ld	s2,16(sp)
    80006c4c:	69a2                	ld	s3,8(sp)
    80006c4e:	6145                	addi	sp,sp,48
    80006c50:	8082                	ret

0000000080006c52 <bd_mark_unavailable>:

// Mark the range [end, HEAPSIZE) as allocated
int
bd_mark_unavailable(void *end, void *left) {
    80006c52:	1101                	addi	sp,sp,-32
    80006c54:	ec06                	sd	ra,24(sp)
    80006c56:	e822                	sd	s0,16(sp)
    80006c58:	e426                	sd	s1,8(sp)
    80006c5a:	1000                	addi	s0,sp,32
  int unavailable = BLK_SIZE(MAXSIZE)-(end-bd_base);
    80006c5c:	00021497          	auipc	s1,0x21
    80006c60:	3fc4a483          	lw	s1,1020(s1) # 80028058 <nsizes>
    80006c64:	fff4879b          	addiw	a5,s1,-1
    80006c68:	44c1                	li	s1,16
    80006c6a:	00f494b3          	sll	s1,s1,a5
    80006c6e:	00021797          	auipc	a5,0x21
    80006c72:	3da7b783          	ld	a5,986(a5) # 80028048 <bd_base>
    80006c76:	8d1d                	sub	a0,a0,a5
    80006c78:	40a4853b          	subw	a0,s1,a0
    80006c7c:	0005049b          	sext.w	s1,a0
  if(unavailable > 0)
    80006c80:	00905a63          	blez	s1,80006c94 <bd_mark_unavailable+0x42>
    unavailable = ROUNDUP(unavailable, LEAF_SIZE);
    80006c84:	357d                	addiw	a0,a0,-1
    80006c86:	41f5549b          	sraiw	s1,a0,0x1f
    80006c8a:	01c4d49b          	srliw	s1,s1,0x1c
    80006c8e:	9ca9                	addw	s1,s1,a0
    80006c90:	98c1                	andi	s1,s1,-16
    80006c92:	24c1                	addiw	s1,s1,16
  printf("bd: 0x%x bytes unavailable\n", unavailable);
    80006c94:	85a6                	mv	a1,s1
    80006c96:	00001517          	auipc	a0,0x1
    80006c9a:	ca250513          	addi	a0,a0,-862 # 80007938 <userret+0x8a8>
    80006c9e:	ffffa097          	auipc	ra,0xffffa
    80006ca2:	8f4080e7          	jalr	-1804(ra) # 80000592 <printf>

  void *bd_end = bd_base+BLK_SIZE(MAXSIZE)-unavailable;
    80006ca6:	00021717          	auipc	a4,0x21
    80006caa:	3a273703          	ld	a4,930(a4) # 80028048 <bd_base>
    80006cae:	00021597          	auipc	a1,0x21
    80006cb2:	3aa5a583          	lw	a1,938(a1) # 80028058 <nsizes>
    80006cb6:	fff5879b          	addiw	a5,a1,-1
    80006cba:	45c1                	li	a1,16
    80006cbc:	00f595b3          	sll	a1,a1,a5
    80006cc0:	40958533          	sub	a0,a1,s1
  bd_mark(bd_end, bd_base+BLK_SIZE(MAXSIZE));
    80006cc4:	95ba                	add	a1,a1,a4
    80006cc6:	953a                	add	a0,a0,a4
    80006cc8:	00000097          	auipc	ra,0x0
    80006ccc:	ccc080e7          	jalr	-820(ra) # 80006994 <bd_mark>
  return unavailable;
}
    80006cd0:	8526                	mv	a0,s1
    80006cd2:	60e2                	ld	ra,24(sp)
    80006cd4:	6442                	ld	s0,16(sp)
    80006cd6:	64a2                	ld	s1,8(sp)
    80006cd8:	6105                	addi	sp,sp,32
    80006cda:	8082                	ret

0000000080006cdc <bd_init>:

// Initialize the buddy allocator: it manages memory from [base, end).
void
bd_init(void *base, void *end) {
    80006cdc:	715d                	addi	sp,sp,-80
    80006cde:	e486                	sd	ra,72(sp)
    80006ce0:	e0a2                	sd	s0,64(sp)
    80006ce2:	fc26                	sd	s1,56(sp)
    80006ce4:	f84a                	sd	s2,48(sp)
    80006ce6:	f44e                	sd	s3,40(sp)
    80006ce8:	f052                	sd	s4,32(sp)
    80006cea:	ec56                	sd	s5,24(sp)
    80006cec:	e85a                	sd	s6,16(sp)
    80006cee:	e45e                	sd	s7,8(sp)
    80006cf0:	e062                	sd	s8,0(sp)
    80006cf2:	0880                	addi	s0,sp,80
    80006cf4:	8c2e                	mv	s8,a1
  char *p = (char *) ROUNDUP((uint64)base, LEAF_SIZE);
    80006cf6:	fff50493          	addi	s1,a0,-1
    80006cfa:	98c1                	andi	s1,s1,-16
    80006cfc:	04c1                	addi	s1,s1,16
  int sz;

  initlock(&lock, "buddy");
    80006cfe:	00001597          	auipc	a1,0x1
    80006d02:	c5a58593          	addi	a1,a1,-934 # 80007958 <userret+0x8c8>
    80006d06:	00021517          	auipc	a0,0x21
    80006d0a:	2fa50513          	addi	a0,a0,762 # 80028000 <lock>
    80006d0e:	ffffa097          	auipc	ra,0xffffa
    80006d12:	ba0080e7          	jalr	-1120(ra) # 800008ae <initlock>
  bd_base = (void *) p;
    80006d16:	00021797          	auipc	a5,0x21
    80006d1a:	3297b923          	sd	s1,818(a5) # 80028048 <bd_base>

  // compute the number of sizes we need to manage [base, end)
  nsizes = log2(((char *)end-p)/LEAF_SIZE) + 1;
    80006d1e:	409c0933          	sub	s2,s8,s1
    80006d22:	43f95513          	srai	a0,s2,0x3f
    80006d26:	893d                	andi	a0,a0,15
    80006d28:	954a                	add	a0,a0,s2
    80006d2a:	8511                	srai	a0,a0,0x4
    80006d2c:	00000097          	auipc	ra,0x0
    80006d30:	c46080e7          	jalr	-954(ra) # 80006972 <log2>
  if((char*)end-p > BLK_SIZE(MAXSIZE)) {
    80006d34:	47c1                	li	a5,16
    80006d36:	00a797b3          	sll	a5,a5,a0
    80006d3a:	1b27c663          	blt	a5,s2,80006ee6 <bd_init+0x20a>
  nsizes = log2(((char *)end-p)/LEAF_SIZE) + 1;
    80006d3e:	2505                	addiw	a0,a0,1
    80006d40:	00021797          	auipc	a5,0x21
    80006d44:	30a7ac23          	sw	a0,792(a5) # 80028058 <nsizes>
    nsizes++;  // round up to the next power of 2
  }

  printf("bd: memory sz is %d bytes; allocate an size array of length %d\n",
    80006d48:	00021997          	auipc	s3,0x21
    80006d4c:	31098993          	addi	s3,s3,784 # 80028058 <nsizes>
    80006d50:	0009a603          	lw	a2,0(s3)
    80006d54:	85ca                	mv	a1,s2
    80006d56:	00001517          	auipc	a0,0x1
    80006d5a:	c0a50513          	addi	a0,a0,-1014 # 80007960 <userret+0x8d0>
    80006d5e:	ffffa097          	auipc	ra,0xffffa
    80006d62:	834080e7          	jalr	-1996(ra) # 80000592 <printf>
         (char*) end - p, nsizes);

  // allocate bd_sizes array
  bd_sizes = (Sz_info *) p;
    80006d66:	00021797          	auipc	a5,0x21
    80006d6a:	2e97b523          	sd	s1,746(a5) # 80028050 <bd_sizes>
  p += sizeof(Sz_info) * nsizes;
    80006d6e:	0009a603          	lw	a2,0(s3)
    80006d72:	00561913          	slli	s2,a2,0x5
    80006d76:	9926                	add	s2,s2,s1
  memset(bd_sizes, 0, sizeof(Sz_info) * nsizes);
    80006d78:	0056161b          	slliw	a2,a2,0x5
    80006d7c:	4581                	li	a1,0
    80006d7e:	8526                	mv	a0,s1
    80006d80:	ffffa097          	auipc	ra,0xffffa
    80006d84:	d00080e7          	jalr	-768(ra) # 80000a80 <memset>

  // initialize free list and allocate the alloc array for each size k
  for (int k = 0; k < nsizes; k++) {
    80006d88:	0009a783          	lw	a5,0(s3)
    80006d8c:	06f05a63          	blez	a5,80006e00 <bd_init+0x124>
    80006d90:	4981                	li	s3,0
    lst_init(&bd_sizes[k].free);
    80006d92:	00021a97          	auipc	s5,0x21
    80006d96:	2bea8a93          	addi	s5,s5,702 # 80028050 <bd_sizes>
    sz = sizeof(char)* ROUNDUP(NBLK(k), 16)/16;
    80006d9a:	00021a17          	auipc	s4,0x21
    80006d9e:	2bea0a13          	addi	s4,s4,702 # 80028058 <nsizes>
    80006da2:	4b05                	li	s6,1
    lst_init(&bd_sizes[k].free);
    80006da4:	00599b93          	slli	s7,s3,0x5
    80006da8:	000ab503          	ld	a0,0(s5)
    80006dac:	955e                	add	a0,a0,s7
    80006dae:	00000097          	auipc	ra,0x0
    80006db2:	166080e7          	jalr	358(ra) # 80006f14 <lst_init>
    sz = sizeof(char)* ROUNDUP(NBLK(k), 16)/16;
    80006db6:	000a2483          	lw	s1,0(s4)
    80006dba:	34fd                	addiw	s1,s1,-1
    80006dbc:	413484bb          	subw	s1,s1,s3
    80006dc0:	009b14bb          	sllw	s1,s6,s1
    80006dc4:	fff4879b          	addiw	a5,s1,-1
    80006dc8:	41f7d49b          	sraiw	s1,a5,0x1f
    80006dcc:	01c4d49b          	srliw	s1,s1,0x1c
    80006dd0:	9cbd                	addw	s1,s1,a5
    80006dd2:	98c1                	andi	s1,s1,-16
    80006dd4:	24c1                	addiw	s1,s1,16
    bd_sizes[k].alloc = p;
    80006dd6:	000ab783          	ld	a5,0(s5)
    80006dda:	9bbe                	add	s7,s7,a5
    80006ddc:	012bb823          	sd	s2,16(s7)
    memset(bd_sizes[k].alloc, 0, sz);
    80006de0:	8491                	srai	s1,s1,0x4
    80006de2:	8626                	mv	a2,s1
    80006de4:	4581                	li	a1,0
    80006de6:	854a                	mv	a0,s2
    80006de8:	ffffa097          	auipc	ra,0xffffa
    80006dec:	c98080e7          	jalr	-872(ra) # 80000a80 <memset>
    p += sz;
    80006df0:	9926                	add	s2,s2,s1
  for (int k = 0; k < nsizes; k++) {
    80006df2:	0985                	addi	s3,s3,1
    80006df4:	000a2703          	lw	a4,0(s4)
    80006df8:	0009879b          	sext.w	a5,s3
    80006dfc:	fae7c4e3          	blt	a5,a4,80006da4 <bd_init+0xc8>
  }

  // allocate the split array for each size k, except for k = 0, since
  // we will not split blocks of size k = 0, the smallest size.
  for (int k = 1; k < nsizes; k++) {
    80006e00:	00021797          	auipc	a5,0x21
    80006e04:	2587a783          	lw	a5,600(a5) # 80028058 <nsizes>
    80006e08:	4705                	li	a4,1
    80006e0a:	06f75163          	bge	a4,a5,80006e6c <bd_init+0x190>
    80006e0e:	02000a13          	li	s4,32
    80006e12:	4985                	li	s3,1
    sz = sizeof(char)* (ROUNDUP(NBLK(k), 8))/8;
    80006e14:	4b85                	li	s7,1
    bd_sizes[k].split = p;
    80006e16:	00021b17          	auipc	s6,0x21
    80006e1a:	23ab0b13          	addi	s6,s6,570 # 80028050 <bd_sizes>
  for (int k = 1; k < nsizes; k++) {
    80006e1e:	00021a97          	auipc	s5,0x21
    80006e22:	23aa8a93          	addi	s5,s5,570 # 80028058 <nsizes>
    sz = sizeof(char)* (ROUNDUP(NBLK(k), 8))/8;
    80006e26:	37fd                	addiw	a5,a5,-1
    80006e28:	413787bb          	subw	a5,a5,s3
    80006e2c:	00fb94bb          	sllw	s1,s7,a5
    80006e30:	fff4879b          	addiw	a5,s1,-1
    80006e34:	41f7d49b          	sraiw	s1,a5,0x1f
    80006e38:	01d4d49b          	srliw	s1,s1,0x1d
    80006e3c:	9cbd                	addw	s1,s1,a5
    80006e3e:	98e1                	andi	s1,s1,-8
    80006e40:	24a1                	addiw	s1,s1,8
    bd_sizes[k].split = p;
    80006e42:	000b3783          	ld	a5,0(s6)
    80006e46:	97d2                	add	a5,a5,s4
    80006e48:	0127bc23          	sd	s2,24(a5)
    memset(bd_sizes[k].split, 0, sz);
    80006e4c:	848d                	srai	s1,s1,0x3
    80006e4e:	8626                	mv	a2,s1
    80006e50:	4581                	li	a1,0
    80006e52:	854a                	mv	a0,s2
    80006e54:	ffffa097          	auipc	ra,0xffffa
    80006e58:	c2c080e7          	jalr	-980(ra) # 80000a80 <memset>
    p += sz;
    80006e5c:	9926                	add	s2,s2,s1
  for (int k = 1; k < nsizes; k++) {
    80006e5e:	2985                	addiw	s3,s3,1
    80006e60:	000aa783          	lw	a5,0(s5)
    80006e64:	020a0a13          	addi	s4,s4,32
    80006e68:	faf9cfe3          	blt	s3,a5,80006e26 <bd_init+0x14a>
  }
  p = (char *) ROUNDUP((uint64) p, LEAF_SIZE);
    80006e6c:	197d                	addi	s2,s2,-1
    80006e6e:	ff097913          	andi	s2,s2,-16
    80006e72:	0941                	addi	s2,s2,16

  // done allocating; mark the memory range [base, p) as allocated, so
  // that buddy will not hand out that memory.
  int meta = bd_mark_data_structures(p);
    80006e74:	854a                	mv	a0,s2
    80006e76:	00000097          	auipc	ra,0x0
    80006e7a:	d7c080e7          	jalr	-644(ra) # 80006bf2 <bd_mark_data_structures>
    80006e7e:	8a2a                	mv	s4,a0
  
  // mark the unavailable memory range [end, HEAP_SIZE) as allocated,
  // so that buddy will not hand out that memory.
  int unavailable = bd_mark_unavailable(end, p);
    80006e80:	85ca                	mv	a1,s2
    80006e82:	8562                	mv	a0,s8
    80006e84:	00000097          	auipc	ra,0x0
    80006e88:	dce080e7          	jalr	-562(ra) # 80006c52 <bd_mark_unavailable>
    80006e8c:	89aa                	mv	s3,a0
  void *bd_end = bd_base+BLK_SIZE(MAXSIZE)-unavailable;
    80006e8e:	00021a97          	auipc	s5,0x21
    80006e92:	1caa8a93          	addi	s5,s5,458 # 80028058 <nsizes>
    80006e96:	000aa783          	lw	a5,0(s5)
    80006e9a:	37fd                	addiw	a5,a5,-1
    80006e9c:	44c1                	li	s1,16
    80006e9e:	00f497b3          	sll	a5,s1,a5
    80006ea2:	8f89                	sub	a5,a5,a0
  
  // initialize free lists for each size k
  int free = bd_initfree(p, bd_end);
    80006ea4:	00021597          	auipc	a1,0x21
    80006ea8:	1a45b583          	ld	a1,420(a1) # 80028048 <bd_base>
    80006eac:	95be                	add	a1,a1,a5
    80006eae:	854a                	mv	a0,s2
    80006eb0:	00000097          	auipc	ra,0x0
    80006eb4:	c7e080e7          	jalr	-898(ra) # 80006b2e <bd_initfree>

  // check if the amount that is free is what we expect
  if(free != BLK_SIZE(MAXSIZE)-meta-unavailable) {
    80006eb8:	000aa603          	lw	a2,0(s5)
    80006ebc:	367d                	addiw	a2,a2,-1
    80006ebe:	00c49633          	sll	a2,s1,a2
    80006ec2:	41460633          	sub	a2,a2,s4
    80006ec6:	41360633          	sub	a2,a2,s3
    80006eca:	02c51463          	bne	a0,a2,80006ef2 <bd_init+0x216>
    printf("free %d %d\n", free, BLK_SIZE(MAXSIZE)-meta-unavailable);
    panic("bd_init: free mem");
  }
}
    80006ece:	60a6                	ld	ra,72(sp)
    80006ed0:	6406                	ld	s0,64(sp)
    80006ed2:	74e2                	ld	s1,56(sp)
    80006ed4:	7942                	ld	s2,48(sp)
    80006ed6:	79a2                	ld	s3,40(sp)
    80006ed8:	7a02                	ld	s4,32(sp)
    80006eda:	6ae2                	ld	s5,24(sp)
    80006edc:	6b42                	ld	s6,16(sp)
    80006ede:	6ba2                	ld	s7,8(sp)
    80006ee0:	6c02                	ld	s8,0(sp)
    80006ee2:	6161                	addi	sp,sp,80
    80006ee4:	8082                	ret
    nsizes++;  // round up to the next power of 2
    80006ee6:	2509                	addiw	a0,a0,2
    80006ee8:	00021797          	auipc	a5,0x21
    80006eec:	16a7a823          	sw	a0,368(a5) # 80028058 <nsizes>
    80006ef0:	bda1                	j	80006d48 <bd_init+0x6c>
    printf("free %d %d\n", free, BLK_SIZE(MAXSIZE)-meta-unavailable);
    80006ef2:	85aa                	mv	a1,a0
    80006ef4:	00001517          	auipc	a0,0x1
    80006ef8:	aac50513          	addi	a0,a0,-1364 # 800079a0 <userret+0x910>
    80006efc:	ffff9097          	auipc	ra,0xffff9
    80006f00:	696080e7          	jalr	1686(ra) # 80000592 <printf>
    panic("bd_init: free mem");
    80006f04:	00001517          	auipc	a0,0x1
    80006f08:	aac50513          	addi	a0,a0,-1364 # 800079b0 <userret+0x920>
    80006f0c:	ffff9097          	auipc	ra,0xffff9
    80006f10:	63c080e7          	jalr	1596(ra) # 80000548 <panic>

0000000080006f14 <lst_init>:
// fast. circular simplifies code, because don't have to check for
// empty list in insert and remove.

void
lst_init(struct list *lst)
{
    80006f14:	1141                	addi	sp,sp,-16
    80006f16:	e422                	sd	s0,8(sp)
    80006f18:	0800                	addi	s0,sp,16
  lst->next = lst;
    80006f1a:	e108                	sd	a0,0(a0)
  lst->prev = lst;
    80006f1c:	e508                	sd	a0,8(a0)
}
    80006f1e:	6422                	ld	s0,8(sp)
    80006f20:	0141                	addi	sp,sp,16
    80006f22:	8082                	ret

0000000080006f24 <lst_empty>:

int
lst_empty(struct list *lst) {
    80006f24:	1141                	addi	sp,sp,-16
    80006f26:	e422                	sd	s0,8(sp)
    80006f28:	0800                	addi	s0,sp,16
  return lst->next == lst;
    80006f2a:	611c                	ld	a5,0(a0)
    80006f2c:	40a78533          	sub	a0,a5,a0
}
    80006f30:	00153513          	seqz	a0,a0
    80006f34:	6422                	ld	s0,8(sp)
    80006f36:	0141                	addi	sp,sp,16
    80006f38:	8082                	ret

0000000080006f3a <lst_remove>:

void
lst_remove(struct list *e) {
    80006f3a:	1141                	addi	sp,sp,-16
    80006f3c:	e422                	sd	s0,8(sp)
    80006f3e:	0800                	addi	s0,sp,16
  e->prev->next = e->next;
    80006f40:	6518                	ld	a4,8(a0)
    80006f42:	611c                	ld	a5,0(a0)
    80006f44:	e31c                	sd	a5,0(a4)
  e->next->prev = e->prev;
    80006f46:	6518                	ld	a4,8(a0)
    80006f48:	e798                	sd	a4,8(a5)
}
    80006f4a:	6422                	ld	s0,8(sp)
    80006f4c:	0141                	addi	sp,sp,16
    80006f4e:	8082                	ret

0000000080006f50 <lst_pop>:

void*
lst_pop(struct list *lst) {
    80006f50:	1101                	addi	sp,sp,-32
    80006f52:	ec06                	sd	ra,24(sp)
    80006f54:	e822                	sd	s0,16(sp)
    80006f56:	e426                	sd	s1,8(sp)
    80006f58:	1000                	addi	s0,sp,32
  if(lst->next == lst)
    80006f5a:	6104                	ld	s1,0(a0)
    80006f5c:	00a48d63          	beq	s1,a0,80006f76 <lst_pop+0x26>
    panic("lst_pop");
  struct list *p = lst->next;
  lst_remove(p);
    80006f60:	8526                	mv	a0,s1
    80006f62:	00000097          	auipc	ra,0x0
    80006f66:	fd8080e7          	jalr	-40(ra) # 80006f3a <lst_remove>
  return (void *)p;
}
    80006f6a:	8526                	mv	a0,s1
    80006f6c:	60e2                	ld	ra,24(sp)
    80006f6e:	6442                	ld	s0,16(sp)
    80006f70:	64a2                	ld	s1,8(sp)
    80006f72:	6105                	addi	sp,sp,32
    80006f74:	8082                	ret
    panic("lst_pop");
    80006f76:	00001517          	auipc	a0,0x1
    80006f7a:	a5250513          	addi	a0,a0,-1454 # 800079c8 <userret+0x938>
    80006f7e:	ffff9097          	auipc	ra,0xffff9
    80006f82:	5ca080e7          	jalr	1482(ra) # 80000548 <panic>

0000000080006f86 <lst_push>:

void
lst_push(struct list *lst, void *p)
{
    80006f86:	1141                	addi	sp,sp,-16
    80006f88:	e422                	sd	s0,8(sp)
    80006f8a:	0800                	addi	s0,sp,16
  struct list *e = (struct list *) p;
  e->next = lst->next;
    80006f8c:	611c                	ld	a5,0(a0)
    80006f8e:	e19c                	sd	a5,0(a1)
  e->prev = lst;
    80006f90:	e588                	sd	a0,8(a1)
  lst->next->prev = p;
    80006f92:	611c                	ld	a5,0(a0)
    80006f94:	e78c                	sd	a1,8(a5)
  lst->next = e;
    80006f96:	e10c                	sd	a1,0(a0)
}
    80006f98:	6422                	ld	s0,8(sp)
    80006f9a:	0141                	addi	sp,sp,16
    80006f9c:	8082                	ret

0000000080006f9e <lst_print>:

void
lst_print(struct list *lst)
{
    80006f9e:	7179                	addi	sp,sp,-48
    80006fa0:	f406                	sd	ra,40(sp)
    80006fa2:	f022                	sd	s0,32(sp)
    80006fa4:	ec26                	sd	s1,24(sp)
    80006fa6:	e84a                	sd	s2,16(sp)
    80006fa8:	e44e                	sd	s3,8(sp)
    80006faa:	1800                	addi	s0,sp,48
  for (struct list *p = lst->next; p != lst; p = p->next) {
    80006fac:	6104                	ld	s1,0(a0)
    80006fae:	02950063          	beq	a0,s1,80006fce <lst_print+0x30>
    80006fb2:	892a                	mv	s2,a0
    printf(" %p", p);
    80006fb4:	00001997          	auipc	s3,0x1
    80006fb8:	a1c98993          	addi	s3,s3,-1508 # 800079d0 <userret+0x940>
    80006fbc:	85a6                	mv	a1,s1
    80006fbe:	854e                	mv	a0,s3
    80006fc0:	ffff9097          	auipc	ra,0xffff9
    80006fc4:	5d2080e7          	jalr	1490(ra) # 80000592 <printf>
  for (struct list *p = lst->next; p != lst; p = p->next) {
    80006fc8:	6084                	ld	s1,0(s1)
    80006fca:	fe9919e3          	bne	s2,s1,80006fbc <lst_print+0x1e>
  }
  printf("\n");
    80006fce:	00000517          	auipc	a0,0x0
    80006fd2:	1d250513          	addi	a0,a0,466 # 800071a0 <userret+0x110>
    80006fd6:	ffff9097          	auipc	ra,0xffff9
    80006fda:	5bc080e7          	jalr	1468(ra) # 80000592 <printf>
}
    80006fde:	70a2                	ld	ra,40(sp)
    80006fe0:	7402                	ld	s0,32(sp)
    80006fe2:	64e2                	ld	s1,24(sp)
    80006fe4:	6942                	ld	s2,16(sp)
    80006fe6:	69a2                	ld	s3,8(sp)
    80006fe8:	6145                	addi	sp,sp,48
    80006fea:	8082                	ret
	...

0000000080007000 <trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret

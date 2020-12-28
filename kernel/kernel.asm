
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
    80000060:	03478793          	addi	a5,a5,52 # 80006090 <timervec>
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
    8000013c:	00001097          	auipc	ra,0x1
    80000140:	7ce080e7          	jalr	1998(ra) # 8000190a <myproc>
    80000144:	591c                	lw	a5,48(a0)
    80000146:	e7b5                	bnez	a5,800001b2 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    80000148:	85a6                	mv	a1,s1
    8000014a:	854a                	mv	a0,s2
    8000014c:	00002097          	auipc	ra,0x2
    80000150:	f9c080e7          	jalr	-100(ra) # 800020e8 <sleep>
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
    8000018c:	1ba080e7          	jalr	442(ra) # 80002342 <either_copyout>
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
    8000028a:	112080e7          	jalr	274(ra) # 80002398 <either_copyin>
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
    80000300:	0f2080e7          	jalr	242(ra) # 800023ee <procdump>
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
    80000454:	e18080e7          	jalr	-488(ra) # 80002268 <wakeup>
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
    80000482:	00023797          	auipc	a5,0x23
    80000486:	86678793          	addi	a5,a5,-1946 # 80022ce8 <devsw>
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
    800004c8:	5bc60613          	addi	a2,a2,1468 # 80008a80 <digits>
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
    800005f4:	490b0b13          	addi	s6,s6,1168 # 80008a80 <digits>
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
    800009e2:	f10080e7          	jalr	-240(ra) # 800018ee <mycpu>
    800009e6:	5d3c                	lw	a5,120(a0)
    800009e8:	cf89                	beqz	a5,80000a02 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    800009ea:	00001097          	auipc	ra,0x1
    800009ee:	f04080e7          	jalr	-252(ra) # 800018ee <mycpu>
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
    80000a06:	eec080e7          	jalr	-276(ra) # 800018ee <mycpu>
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
    80000a1e:	ed4080e7          	jalr	-300(ra) # 800018ee <mycpu>
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
    80000ab2:	e40080e7          	jalr	-448(ra) # 800018ee <mycpu>
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
    80000b16:	ddc080e7          	jalr	-548(ra) # 800018ee <mycpu>
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
    80000d3c:	ba6080e7          	jalr	-1114(ra) # 800018de <cpuid>
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
    80000d58:	b8a080e7          	jalr	-1142(ra) # 800018de <cpuid>
    80000d5c:	85aa                	mv	a1,a0
    80000d5e:	00007517          	auipc	a0,0x7
    80000d62:	44250513          	addi	a0,a0,1090 # 800081a0 <userret+0x110>
    80000d66:	00000097          	auipc	ra,0x0
    80000d6a:	82c080e7          	jalr	-2004(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000d6e:	00000097          	auipc	ra,0x0
    80000d72:	1ea080e7          	jalr	490(ra) # 80000f58 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000d76:	00001097          	auipc	ra,0x1
    80000d7a:	7ba080e7          	jalr	1978(ra) # 80002530 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000d7e:	00005097          	auipc	ra,0x5
    80000d82:	352080e7          	jalr	850(ra) # 800060d0 <plicinithart>
  }

  scheduler();        
    80000d86:	00001097          	auipc	ra,0x1
    80000d8a:	06a080e7          	jalr	106(ra) # 80001df0 <scheduler>
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
    80000dea:	a28080e7          	jalr	-1496(ra) # 8000180e <procinit>
    trapinit();      // trap vectors
    80000dee:	00001097          	auipc	ra,0x1
    80000df2:	71a080e7          	jalr	1818(ra) # 80002508 <trapinit>
    trapinithart();  // install kernel trap vector
    80000df6:	00001097          	auipc	ra,0x1
    80000dfa:	73a080e7          	jalr	1850(ra) # 80002530 <trapinithart>
    plicinit();      // set up interrupt controller
    80000dfe:	00005097          	auipc	ra,0x5
    80000e02:	2bc080e7          	jalr	700(ra) # 800060ba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000e06:	00005097          	auipc	ra,0x5
    80000e0a:	2ca080e7          	jalr	714(ra) # 800060d0 <plicinithart>
    binit();         // buffer cache
    80000e0e:	00002097          	auipc	ra,0x2
    80000e12:	f7c080e7          	jalr	-132(ra) # 80002d8a <binit>
    iinit();         // inode cache
    80000e16:	00002097          	auipc	ra,0x2
    80000e1a:	612080e7          	jalr	1554(ra) # 80003428 <iinit>
    fileinit();      // file table
    80000e1e:	00003097          	auipc	ra,0x3
    80000e22:	7ee080e7          	jalr	2030(ra) # 8000460c <fileinit>
    virtio_disk_init(minor(ROOTDEV)); // emulated hard disk
    80000e26:	4501                	li	a0,0
    80000e28:	00005097          	auipc	ra,0x5
    80000e2c:	3dc080e7          	jalr	988(ra) # 80006204 <virtio_disk_init>
    userinit();      // first user process
    80000e30:	00001097          	auipc	ra,0x1
    80000e34:	d4e080e7          	jalr	-690(ra) # 80001b7e <userinit>
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
        if (PTE_FLAGS(*pte) == PTE_V)
    800011f2:	4b85                	li	s7,1
        a += PGSIZE;
    800011f4:	6a85                	lui	s5,0x1
    800011f6:	a831                	j	80001212 <uvmunmap+0x4a>
            panic("uvmunmap: not a leaf"); //不是叶子页表项
    800011f8:	00007517          	auipc	a0,0x7
    800011fc:	ff050513          	addi	a0,a0,-16 # 800081e8 <userret+0x158>
    80001200:	fffff097          	auipc	ra,0xfffff
    80001204:	348080e7          	jalr	840(ra) # 80000548 <panic>
        *pte = 0;
    80001208:	0004b023          	sd	zero,0(s1)
        if (a == last)
    8000120c:	03390e63          	beq	s2,s3,80001248 <uvmunmap+0x80>
        a += PGSIZE;
    80001210:	9956                	add	s2,s2,s5
        if ((pte = walk(pagetable, a, 0)) == 0)  //walk定义在上方
    80001212:	4601                	li	a2,0
    80001214:	85ca                	mv	a1,s2
    80001216:	8552                	mv	a0,s4
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	c30080e7          	jalr	-976(ra) # 80000e48 <walk>
    80001220:	84aa                	mv	s1,a0
    80001222:	d56d                	beqz	a0,8000120c <uvmunmap+0x44>
        if ((*pte & PTE_V) == 0)
    80001224:	611c                	ld	a5,0(a0)
    80001226:	0017f713          	andi	a4,a5,1
    8000122a:	d36d                	beqz	a4,8000120c <uvmunmap+0x44>
        if (PTE_FLAGS(*pte) == PTE_V)
    8000122c:	3ff7f713          	andi	a4,a5,1023
    80001230:	fd7704e3          	beq	a4,s7,800011f8 <uvmunmap+0x30>
        if (do_free)
    80001234:	fc0b0ae3          	beqz	s6,80001208 <uvmunmap+0x40>
            pa = PTE2PA(*pte);
    80001238:	83a9                	srli	a5,a5,0xa
            kfree((void *)pa);
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

    for (i = 0; i < sz; i += PGSIZE)
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
    for (i = 0; i < sz; i += PGSIZE)
    80001448:	4481                	li	s1,0
    8000144a:	a029                	j	80001454 <uvmcopy+0x2a>
    8000144c:	6785                	lui	a5,0x1
    8000144e:	94be                	add	s1,s1,a5
    80001450:	0744f963          	bgeu	s1,s4,800014c2 <uvmcopy+0x98>
    {
        if ((pte = walk(old, i, 0)) == 0)  //walk定义在上面，在页表old中返回与虚拟地址i对应的PTE地址。如果alloc=0，不创建任何必需的页表页。
    80001454:	4601                	li	a2,0
    80001456:	85a6                	mv	a1,s1
    80001458:	8556                	mv	a0,s5
    8000145a:	00000097          	auipc	ra,0x0
    8000145e:	9ee080e7          	jalr	-1554(ra) # 80000e48 <walk>
    80001462:	d56d                	beqz	a0,8000144c <uvmcopy+0x22>
            //panic("uvmcopy: pte should exist");
            continue;  //如果当前没有返回对应的物理地址，则判断下一项
            //break;  //otherwise the kill and wait failed?
        if ((*pte & PTE_V) == 0)
    80001464:	6118                	ld	a4,0(a0)
    80001466:	00177793          	andi	a5,a4,1
    8000146a:	d3ed                	beqz	a5,8000144c <uvmcopy+0x22>
            //panic("uvmcopy: page not present");
            continue;  //如果当前页表项无效(不在内存中)，PTE_V=0，则判断下一项
            //break;
        pa = PTE2PA(*pte); //找到旧页表项的物理地址
    8000146c:	00a75593          	srli	a1,a4,0xa
    80001470:	00c59b93          	slli	s7,a1,0xc
        flags = PTE_FLAGS(*pte);
    80001474:	3ff77913          	andi	s2,a4,1023
        if ((mem = kalloc()) == 0)  //分配页面失败
    80001478:	fffff097          	auipc	ra,0xfffff
    8000147c:	4d8080e7          	jalr	1240(ra) # 80000950 <kalloc>
    80001480:	89aa                	mv	s3,a0
    80001482:	c515                	beqz	a0,800014ae <uvmcopy+0x84>
            goto err;
        memmove(mem, (char *)pa, PGSIZE);  //将就页表项复制到mem中
    80001484:	6605                	lui	a2,0x1
    80001486:	85de                	mv	a1,s7
    80001488:	fffff097          	auipc	ra,0xfffff
    8000148c:	756080e7          	jalr	1878(ra) # 80000bde <memmove>
        if (mappages(new, i, PGSIZE, (uint64)mem, flags) != 0)  //如果建立页表逻辑地址与物理地址映射失败
    80001490:	874a                	mv	a4,s2
    80001492:	86ce                	mv	a3,s3
    80001494:	6605                	lui	a2,0x1
    80001496:	85a6                	mv	a1,s1
    80001498:	855a                	mv	a0,s6
    8000149a:	00000097          	auipc	ra,0x0
    8000149e:	b82080e7          	jalr	-1150(ra) # 8000101c <mappages>
    800014a2:	d54d                	beqz	a0,8000144c <uvmcopy+0x22>
        {
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

0000000080001510 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001510:	c6bd                	beqz	a3,8000157e <copyout+0x6e>
{
    80001512:	715d                	addi	sp,sp,-80
    80001514:	e486                	sd	ra,72(sp)
    80001516:	e0a2                	sd	s0,64(sp)
    80001518:	fc26                	sd	s1,56(sp)
    8000151a:	f84a                	sd	s2,48(sp)
    8000151c:	f44e                	sd	s3,40(sp)
    8000151e:	f052                	sd	s4,32(sp)
    80001520:	ec56                	sd	s5,24(sp)
    80001522:	e85a                	sd	s6,16(sp)
    80001524:	e45e                	sd	s7,8(sp)
    80001526:	e062                	sd	s8,0(sp)
    80001528:	0880                	addi	s0,sp,80
    8000152a:	8b2a                	mv	s6,a0
    8000152c:	8c2e                	mv	s8,a1
    8000152e:	8a32                	mv	s4,a2
    80001530:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001532:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001534:	6a85                	lui	s5,0x1
    80001536:	a015                	j	8000155a <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001538:	9562                	add	a0,a0,s8
    8000153a:	0004861b          	sext.w	a2,s1
    8000153e:	85d2                	mv	a1,s4
    80001540:	41250533          	sub	a0,a0,s2
    80001544:	fffff097          	auipc	ra,0xfffff
    80001548:	69a080e7          	jalr	1690(ra) # 80000bde <memmove>

    len -= n;
    8000154c:	409989b3          	sub	s3,s3,s1
    src += n;
    80001550:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001552:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001556:	02098263          	beqz	s3,8000157a <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000155a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000155e:	85ca                	mv	a1,s2
    80001560:	855a                	mv	a0,s6
    80001562:	00000097          	auipc	ra,0x0
    80001566:	a1a080e7          	jalr	-1510(ra) # 80000f7c <walkaddr>
    if(pa0 == 0)
    8000156a:	cd01                	beqz	a0,80001582 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000156c:	418904b3          	sub	s1,s2,s8
    80001570:	94d6                	add	s1,s1,s5
    if(n > len)
    80001572:	fc99f3e3          	bgeu	s3,s1,80001538 <copyout+0x28>
    80001576:	84ce                	mv	s1,s3
    80001578:	b7c1                	j	80001538 <copyout+0x28>
  }
  return 0;
    8000157a:	4501                	li	a0,0
    8000157c:	a021                	j	80001584 <copyout+0x74>
    8000157e:	4501                	li	a0,0
}
    80001580:	8082                	ret
      return -1;
    80001582:	557d                	li	a0,-1
}
    80001584:	60a6                	ld	ra,72(sp)
    80001586:	6406                	ld	s0,64(sp)
    80001588:	74e2                	ld	s1,56(sp)
    8000158a:	7942                	ld	s2,48(sp)
    8000158c:	79a2                	ld	s3,40(sp)
    8000158e:	7a02                	ld	s4,32(sp)
    80001590:	6ae2                	ld	s5,24(sp)
    80001592:	6b42                	ld	s6,16(sp)
    80001594:	6ba2                	ld	s7,8(sp)
    80001596:	6c02                	ld	s8,0(sp)
    80001598:	6161                	addi	sp,sp,80
    8000159a:	8082                	ret

000000008000159c <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000159c:	caa5                	beqz	a3,8000160c <copyin+0x70>
{
    8000159e:	715d                	addi	sp,sp,-80
    800015a0:	e486                	sd	ra,72(sp)
    800015a2:	e0a2                	sd	s0,64(sp)
    800015a4:	fc26                	sd	s1,56(sp)
    800015a6:	f84a                	sd	s2,48(sp)
    800015a8:	f44e                	sd	s3,40(sp)
    800015aa:	f052                	sd	s4,32(sp)
    800015ac:	ec56                	sd	s5,24(sp)
    800015ae:	e85a                	sd	s6,16(sp)
    800015b0:	e45e                	sd	s7,8(sp)
    800015b2:	e062                	sd	s8,0(sp)
    800015b4:	0880                	addi	s0,sp,80
    800015b6:	8b2a                	mv	s6,a0
    800015b8:	8a2e                	mv	s4,a1
    800015ba:	8c32                	mv	s8,a2
    800015bc:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800015be:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800015c0:	6a85                	lui	s5,0x1
    800015c2:	a01d                	j	800015e8 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800015c4:	018505b3          	add	a1,a0,s8
    800015c8:	0004861b          	sext.w	a2,s1
    800015cc:	412585b3          	sub	a1,a1,s2
    800015d0:	8552                	mv	a0,s4
    800015d2:	fffff097          	auipc	ra,0xfffff
    800015d6:	60c080e7          	jalr	1548(ra) # 80000bde <memmove>

    len -= n;
    800015da:	409989b3          	sub	s3,s3,s1
    dst += n;
    800015de:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800015e0:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800015e4:	02098263          	beqz	s3,80001608 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800015e8:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800015ec:	85ca                	mv	a1,s2
    800015ee:	855a                	mv	a0,s6
    800015f0:	00000097          	auipc	ra,0x0
    800015f4:	98c080e7          	jalr	-1652(ra) # 80000f7c <walkaddr>
    if(pa0 == 0)
    800015f8:	cd01                	beqz	a0,80001610 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800015fa:	418904b3          	sub	s1,s2,s8
    800015fe:	94d6                	add	s1,s1,s5
    if(n > len)
    80001600:	fc99f2e3          	bgeu	s3,s1,800015c4 <copyin+0x28>
    80001604:	84ce                	mv	s1,s3
    80001606:	bf7d                	j	800015c4 <copyin+0x28>
  }
  return 0;
    80001608:	4501                	li	a0,0
    8000160a:	a021                	j	80001612 <copyin+0x76>
    8000160c:	4501                	li	a0,0
}
    8000160e:	8082                	ret
      return -1;
    80001610:	557d                	li	a0,-1
}
    80001612:	60a6                	ld	ra,72(sp)
    80001614:	6406                	ld	s0,64(sp)
    80001616:	74e2                	ld	s1,56(sp)
    80001618:	7942                	ld	s2,48(sp)
    8000161a:	79a2                	ld	s3,40(sp)
    8000161c:	7a02                	ld	s4,32(sp)
    8000161e:	6ae2                	ld	s5,24(sp)
    80001620:	6b42                	ld	s6,16(sp)
    80001622:	6ba2                	ld	s7,8(sp)
    80001624:	6c02                	ld	s8,0(sp)
    80001626:	6161                	addi	sp,sp,80
    80001628:	8082                	ret

000000008000162a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000162a:	c6c5                	beqz	a3,800016d2 <copyinstr+0xa8>
{
    8000162c:	715d                	addi	sp,sp,-80
    8000162e:	e486                	sd	ra,72(sp)
    80001630:	e0a2                	sd	s0,64(sp)
    80001632:	fc26                	sd	s1,56(sp)
    80001634:	f84a                	sd	s2,48(sp)
    80001636:	f44e                	sd	s3,40(sp)
    80001638:	f052                	sd	s4,32(sp)
    8000163a:	ec56                	sd	s5,24(sp)
    8000163c:	e85a                	sd	s6,16(sp)
    8000163e:	e45e                	sd	s7,8(sp)
    80001640:	0880                	addi	s0,sp,80
    80001642:	8a2a                	mv	s4,a0
    80001644:	8b2e                	mv	s6,a1
    80001646:	8bb2                	mv	s7,a2
    80001648:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000164a:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000164c:	6985                	lui	s3,0x1
    8000164e:	a035                	j	8000167a <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001650:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001654:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001656:	0017b793          	seqz	a5,a5
    8000165a:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000165e:	60a6                	ld	ra,72(sp)
    80001660:	6406                	ld	s0,64(sp)
    80001662:	74e2                	ld	s1,56(sp)
    80001664:	7942                	ld	s2,48(sp)
    80001666:	79a2                	ld	s3,40(sp)
    80001668:	7a02                	ld	s4,32(sp)
    8000166a:	6ae2                	ld	s5,24(sp)
    8000166c:	6b42                	ld	s6,16(sp)
    8000166e:	6ba2                	ld	s7,8(sp)
    80001670:	6161                	addi	sp,sp,80
    80001672:	8082                	ret
    srcva = va0 + PGSIZE;
    80001674:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001678:	c8a9                	beqz	s1,800016ca <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000167a:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000167e:	85ca                	mv	a1,s2
    80001680:	8552                	mv	a0,s4
    80001682:	00000097          	auipc	ra,0x0
    80001686:	8fa080e7          	jalr	-1798(ra) # 80000f7c <walkaddr>
    if(pa0 == 0)
    8000168a:	c131                	beqz	a0,800016ce <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    8000168c:	41790833          	sub	a6,s2,s7
    80001690:	984e                	add	a6,a6,s3
    if(n > max)
    80001692:	0104f363          	bgeu	s1,a6,80001698 <copyinstr+0x6e>
    80001696:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001698:	955e                	add	a0,a0,s7
    8000169a:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000169e:	fc080be3          	beqz	a6,80001674 <copyinstr+0x4a>
    800016a2:	985a                	add	a6,a6,s6
    800016a4:	87da                	mv	a5,s6
      if(*p == '\0'){
    800016a6:	41650633          	sub	a2,a0,s6
    800016aa:	14fd                	addi	s1,s1,-1
    800016ac:	9b26                	add	s6,s6,s1
    800016ae:	00f60733          	add	a4,a2,a5
    800016b2:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd4fa4>
    800016b6:	df49                	beqz	a4,80001650 <copyinstr+0x26>
        *dst = *p;
    800016b8:	00e78023          	sb	a4,0(a5)
      --max;
    800016bc:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800016c0:	0785                	addi	a5,a5,1
    while(n > 0){
    800016c2:	ff0796e3          	bne	a5,a6,800016ae <copyinstr+0x84>
      dst++;
    800016c6:	8b42                	mv	s6,a6
    800016c8:	b775                	j	80001674 <copyinstr+0x4a>
    800016ca:	4781                	li	a5,0
    800016cc:	b769                	j	80001656 <copyinstr+0x2c>
      return -1;
    800016ce:	557d                	li	a0,-1
    800016d0:	b779                	j	8000165e <copyinstr+0x34>
  int got_null = 0;
    800016d2:	4781                	li	a5,0
  if(got_null){
    800016d4:	0017b793          	seqz	a5,a5
    800016d8:	40f00533          	neg	a0,a5
}
    800016dc:	8082                	ret

00000000800016de <print_page_table>:




void print_page_table(pagetable_t pagetable, int depth)
{
    800016de:	7159                	addi	sp,sp,-112
    800016e0:	f486                	sd	ra,104(sp)
    800016e2:	f0a2                	sd	s0,96(sp)
    800016e4:	eca6                	sd	s1,88(sp)
    800016e6:	e8ca                	sd	s2,80(sp)
    800016e8:	e4ce                	sd	s3,72(sp)
    800016ea:	e0d2                	sd	s4,64(sp)
    800016ec:	fc56                	sd	s5,56(sp)
    800016ee:	f85a                	sd	s6,48(sp)
    800016f0:	f45e                	sd	s7,40(sp)
    800016f2:	f062                	sd	s8,32(sp)
    800016f4:	ec66                	sd	s9,24(sp)
    800016f6:	e86a                	sd	s10,16(sp)
    800016f8:	e46e                	sd	s11,8(sp)
    800016fa:	1880                	addi	s0,sp,112
    800016fc:	8aae                	mv	s5,a1
  // there are 2^9 = 512 PTEs in a page table. //参考freewalk
  for (int i = 0; i < 512; i++)
    800016fe:	8a2a                	mv	s4,a0
    80001700:	4981                	li	s3,0

    if (pte & PTE_V) //如果该页表项有效，否则跳过
    {
      for (int j = 0; j < depth; j++) //递归打印页表，每个深度打印..
        printf(" ..");
      printf("%d: pte %p pa %p\n", i, pte, PTE2PA(pte)); //PTE2PA定义在riscv.h中，将页号对应的页表项转化为对应的物理地址
    80001702:	00007c97          	auipc	s9,0x7
    80001706:	b56c8c93          	addi	s9,s9,-1194 # 80008258 <userret+0x1c8>
      for (int j = 0; j < depth; j++) //递归打印页表，每个深度打印..
    8000170a:	4d01                	li	s10,0
        printf(" ..");
    8000170c:	00007b17          	auipc	s6,0x7
    80001710:	b44b0b13          	addi	s6,s6,-1212 # 80008250 <userret+0x1c0>
    }

    //如果该页有效，并且PTE_R、PTE_W和PTE_X均为0，说明该页表项指向一个页表(下一级页表)
    if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
    80001714:	4c05                	li	s8,1
    {
      // this PTE points to a lower-level page table.
      uint64 child_table = PTE2PA(pte);                      //取得该页表的物理首地址
      print_page_table((pagetable_t)child_table, depth + 1); //递归调用函数，传入子页表的地址，深度+1
    80001716:	00158d9b          	addiw	s11,a1,1
  for (int i = 0; i < 512; i++)
    8000171a:	20000b93          	li	s7,512
    8000171e:	a01d                	j	80001744 <print_page_table+0x66>
      printf("%d: pte %p pa %p\n", i, pte, PTE2PA(pte)); //PTE2PA定义在riscv.h中，将页号对应的页表项转化为对应的物理地址
    80001720:	00a95693          	srli	a3,s2,0xa
    80001724:	06b2                	slli	a3,a3,0xc
    80001726:	864a                	mv	a2,s2
    80001728:	85ce                	mv	a1,s3
    8000172a:	8566                	mv	a0,s9
    8000172c:	fffff097          	auipc	ra,0xfffff
    80001730:	e66080e7          	jalr	-410(ra) # 80000592 <printf>
    if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
    80001734:	00f97793          	andi	a5,s2,15
    80001738:	03878763          	beq	a5,s8,80001766 <print_page_table+0x88>
  for (int i = 0; i < 512; i++)
    8000173c:	2985                	addiw	s3,s3,1
    8000173e:	0a21                	addi	s4,s4,8
    80001740:	03798c63          	beq	s3,s7,80001778 <print_page_table+0x9a>
    pte_t pte = pagetable[i]; //获取当前level页表的第i项，pte为虚拟地址
    80001744:	000a3903          	ld	s2,0(s4) # fffffffffffff000 <end+0xffffffff7ffd4fa4>
    if (pte & PTE_V) //如果该页表项有效，否则跳过
    80001748:	00197793          	andi	a5,s2,1
    8000174c:	d7e5                	beqz	a5,80001734 <print_page_table+0x56>
      for (int j = 0; j < depth; j++) //递归打印页表，每个深度打印..
    8000174e:	fd5059e3          	blez	s5,80001720 <print_page_table+0x42>
    80001752:	84ea                	mv	s1,s10
        printf(" ..");
    80001754:	855a                	mv	a0,s6
    80001756:	fffff097          	auipc	ra,0xfffff
    8000175a:	e3c080e7          	jalr	-452(ra) # 80000592 <printf>
      for (int j = 0; j < depth; j++) //递归打印页表，每个深度打印..
    8000175e:	2485                	addiw	s1,s1,1
    80001760:	fe9a9ae3          	bne	s5,s1,80001754 <print_page_table+0x76>
    80001764:	bf75                	j	80001720 <print_page_table+0x42>
      uint64 child_table = PTE2PA(pte);                      //取得该页表的物理首地址
    80001766:	00a95513          	srli	a0,s2,0xa
      print_page_table((pagetable_t)child_table, depth + 1); //递归调用函数，传入子页表的地址，深度+1
    8000176a:	85ee                	mv	a1,s11
    8000176c:	0532                	slli	a0,a0,0xc
    8000176e:	00000097          	auipc	ra,0x0
    80001772:	f70080e7          	jalr	-144(ra) # 800016de <print_page_table>
    80001776:	b7d9                	j	8000173c <print_page_table+0x5e>
    }
  }
}
    80001778:	70a6                	ld	ra,104(sp)
    8000177a:	7406                	ld	s0,96(sp)
    8000177c:	64e6                	ld	s1,88(sp)
    8000177e:	6946                	ld	s2,80(sp)
    80001780:	69a6                	ld	s3,72(sp)
    80001782:	6a06                	ld	s4,64(sp)
    80001784:	7ae2                	ld	s5,56(sp)
    80001786:	7b42                	ld	s6,48(sp)
    80001788:	7ba2                	ld	s7,40(sp)
    8000178a:	7c02                	ld	s8,32(sp)
    8000178c:	6ce2                	ld	s9,24(sp)
    8000178e:	6d42                	ld	s10,16(sp)
    80001790:	6da2                	ld	s11,8(sp)
    80001792:	6165                	addi	sp,sp,112
    80001794:	8082                	ret

0000000080001796 <vmprint>:

void vmprint(pagetable_t top_level) //pagetable_t 指向页表的指针类型
{
    80001796:	1101                	addi	sp,sp,-32
    80001798:	ec06                	sd	ra,24(sp)
    8000179a:	e822                	sd	s0,16(sp)
    8000179c:	e426                	sd	s1,8(sp)
    8000179e:	1000                	addi	s0,sp,32
    800017a0:	84aa                	mv	s1,a0
  printf("page table %p\n", top_level);
    800017a2:	85aa                	mv	a1,a0
    800017a4:	00007517          	auipc	a0,0x7
    800017a8:	acc50513          	addi	a0,a0,-1332 # 80008270 <userret+0x1e0>
    800017ac:	fffff097          	auipc	ra,0xfffff
    800017b0:	de6080e7          	jalr	-538(ra) # 80000592 <printf>
  print_page_table(top_level, 1);  //打印最顶层table，初始深度为1
    800017b4:	4585                	li	a1,1
    800017b6:	8526                	mv	a0,s1
    800017b8:	00000097          	auipc	ra,0x0
    800017bc:	f26080e7          	jalr	-218(ra) # 800016de <print_page_table>
}
    800017c0:	60e2                	ld	ra,24(sp)
    800017c2:	6442                	ld	s0,16(sp)
    800017c4:	64a2                	ld	s1,8(sp)
    800017c6:	6105                	addi	sp,sp,32
    800017c8:	8082                	ret

00000000800017ca <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    800017ca:	1101                	addi	sp,sp,-32
    800017cc:	ec06                	sd	ra,24(sp)
    800017ce:	e822                	sd	s0,16(sp)
    800017d0:	e426                	sd	s1,8(sp)
    800017d2:	1000                	addi	s0,sp,32
    800017d4:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800017d6:	fffff097          	auipc	ra,0xfffff
    800017da:	2a8080e7          	jalr	680(ra) # 80000a7e <holding>
    800017de:	c909                	beqz	a0,800017f0 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    800017e0:	749c                	ld	a5,40(s1)
    800017e2:	00978f63          	beq	a5,s1,80001800 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    800017e6:	60e2                	ld	ra,24(sp)
    800017e8:	6442                	ld	s0,16(sp)
    800017ea:	64a2                	ld	s1,8(sp)
    800017ec:	6105                	addi	sp,sp,32
    800017ee:	8082                	ret
    panic("wakeup1");
    800017f0:	00007517          	auipc	a0,0x7
    800017f4:	a9050513          	addi	a0,a0,-1392 # 80008280 <userret+0x1f0>
    800017f8:	fffff097          	auipc	ra,0xfffff
    800017fc:	d50080e7          	jalr	-688(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001800:	4c98                	lw	a4,24(s1)
    80001802:	4785                	li	a5,1
    80001804:	fef711e3          	bne	a4,a5,800017e6 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001808:	4789                	li	a5,2
    8000180a:	cc9c                	sw	a5,24(s1)
}
    8000180c:	bfe9                	j	800017e6 <wakeup1+0x1c>

000000008000180e <procinit>:
{
    8000180e:	715d                	addi	sp,sp,-80
    80001810:	e486                	sd	ra,72(sp)
    80001812:	e0a2                	sd	s0,64(sp)
    80001814:	fc26                	sd	s1,56(sp)
    80001816:	f84a                	sd	s2,48(sp)
    80001818:	f44e                	sd	s3,40(sp)
    8000181a:	f052                	sd	s4,32(sp)
    8000181c:	ec56                	sd	s5,24(sp)
    8000181e:	e85a                	sd	s6,16(sp)
    80001820:	e45e                	sd	s7,8(sp)
    80001822:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001824:	00007597          	auipc	a1,0x7
    80001828:	a6458593          	addi	a1,a1,-1436 # 80008288 <userret+0x1f8>
    8000182c:	00011517          	auipc	a0,0x11
    80001830:	0bc50513          	addi	a0,a0,188 # 800128e8 <pid_lock>
    80001834:	fffff097          	auipc	ra,0xfffff
    80001838:	17c080e7          	jalr	380(ra) # 800009b0 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000183c:	00011917          	auipc	s2,0x11
    80001840:	4c490913          	addi	s2,s2,1220 # 80012d00 <proc>
      initlock(&p->lock, "proc");
    80001844:	00007b97          	auipc	s7,0x7
    80001848:	a4cb8b93          	addi	s7,s7,-1460 # 80008290 <userret+0x200>
      uint64 va = KSTACK((int) (p - proc));
    8000184c:	8b4a                	mv	s6,s2
    8000184e:	00007a97          	auipc	s5,0x7
    80001852:	34aa8a93          	addi	s5,s5,842 # 80008b98 <syscalls+0xc0>
    80001856:	040009b7          	lui	s3,0x4000
    8000185a:	19fd                	addi	s3,s3,-1
    8000185c:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000185e:	00017a17          	auipc	s4,0x17
    80001862:	0a2a0a13          	addi	s4,s4,162 # 80018900 <tickslock>
      initlock(&p->lock, "proc");
    80001866:	85de                	mv	a1,s7
    80001868:	854a                	mv	a0,s2
    8000186a:	fffff097          	auipc	ra,0xfffff
    8000186e:	146080e7          	jalr	326(ra) # 800009b0 <initlock>
      char *pa = kalloc();
    80001872:	fffff097          	auipc	ra,0xfffff
    80001876:	0de080e7          	jalr	222(ra) # 80000950 <kalloc>
    8000187a:	85aa                	mv	a1,a0
      if(pa == 0)
    8000187c:	c929                	beqz	a0,800018ce <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    8000187e:	416904b3          	sub	s1,s2,s6
    80001882:	8491                	srai	s1,s1,0x4
    80001884:	000ab783          	ld	a5,0(s5)
    80001888:	02f484b3          	mul	s1,s1,a5
    8000188c:	2485                	addiw	s1,s1,1
    8000188e:	00d4949b          	slliw	s1,s1,0xd
    80001892:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001896:	4699                	li	a3,6
    80001898:	6605                	lui	a2,0x1
    8000189a:	8526                	mv	a0,s1
    8000189c:	00000097          	auipc	ra,0x0
    800018a0:	80e080e7          	jalr	-2034(ra) # 800010aa <kvmmap>
      p->kstack = va;
    800018a4:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a8:	17090913          	addi	s2,s2,368
    800018ac:	fb491de3          	bne	s2,s4,80001866 <procinit+0x58>
  kvminithart();
    800018b0:	fffff097          	auipc	ra,0xfffff
    800018b4:	6a8080e7          	jalr	1704(ra) # 80000f58 <kvminithart>
}
    800018b8:	60a6                	ld	ra,72(sp)
    800018ba:	6406                	ld	s0,64(sp)
    800018bc:	74e2                	ld	s1,56(sp)
    800018be:	7942                	ld	s2,48(sp)
    800018c0:	79a2                	ld	s3,40(sp)
    800018c2:	7a02                	ld	s4,32(sp)
    800018c4:	6ae2                	ld	s5,24(sp)
    800018c6:	6b42                	ld	s6,16(sp)
    800018c8:	6ba2                	ld	s7,8(sp)
    800018ca:	6161                	addi	sp,sp,80
    800018cc:	8082                	ret
        panic("kalloc");
    800018ce:	00007517          	auipc	a0,0x7
    800018d2:	9ca50513          	addi	a0,a0,-1590 # 80008298 <userret+0x208>
    800018d6:	fffff097          	auipc	ra,0xfffff
    800018da:	c72080e7          	jalr	-910(ra) # 80000548 <panic>

00000000800018de <cpuid>:
{
    800018de:	1141                	addi	sp,sp,-16
    800018e0:	e422                	sd	s0,8(sp)
    800018e2:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800018e4:	8512                	mv	a0,tp
}
    800018e6:	2501                	sext.w	a0,a0
    800018e8:	6422                	ld	s0,8(sp)
    800018ea:	0141                	addi	sp,sp,16
    800018ec:	8082                	ret

00000000800018ee <mycpu>:
mycpu(void) {
    800018ee:	1141                	addi	sp,sp,-16
    800018f0:	e422                	sd	s0,8(sp)
    800018f2:	0800                	addi	s0,sp,16
    800018f4:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    800018f6:	2781                	sext.w	a5,a5
    800018f8:	079e                	slli	a5,a5,0x7
}
    800018fa:	00011517          	auipc	a0,0x11
    800018fe:	00650513          	addi	a0,a0,6 # 80012900 <cpus>
    80001902:	953e                	add	a0,a0,a5
    80001904:	6422                	ld	s0,8(sp)
    80001906:	0141                	addi	sp,sp,16
    80001908:	8082                	ret

000000008000190a <myproc>:
myproc(void) {
    8000190a:	1101                	addi	sp,sp,-32
    8000190c:	ec06                	sd	ra,24(sp)
    8000190e:	e822                	sd	s0,16(sp)
    80001910:	e426                	sd	s1,8(sp)
    80001912:	1000                	addi	s0,sp,32
  push_off();
    80001914:	fffff097          	auipc	ra,0xfffff
    80001918:	0b2080e7          	jalr	178(ra) # 800009c6 <push_off>
    8000191c:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    8000191e:	2781                	sext.w	a5,a5
    80001920:	079e                	slli	a5,a5,0x7
    80001922:	00011717          	auipc	a4,0x11
    80001926:	fc670713          	addi	a4,a4,-58 # 800128e8 <pid_lock>
    8000192a:	97ba                	add	a5,a5,a4
    8000192c:	6f84                	ld	s1,24(a5)
  pop_off();
    8000192e:	fffff097          	auipc	ra,0xfffff
    80001932:	0e4080e7          	jalr	228(ra) # 80000a12 <pop_off>
}
    80001936:	8526                	mv	a0,s1
    80001938:	60e2                	ld	ra,24(sp)
    8000193a:	6442                	ld	s0,16(sp)
    8000193c:	64a2                	ld	s1,8(sp)
    8000193e:	6105                	addi	sp,sp,32
    80001940:	8082                	ret

0000000080001942 <forkret>:
{
    80001942:	1141                	addi	sp,sp,-16
    80001944:	e406                	sd	ra,8(sp)
    80001946:	e022                	sd	s0,0(sp)
    80001948:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    8000194a:	00000097          	auipc	ra,0x0
    8000194e:	fc0080e7          	jalr	-64(ra) # 8000190a <myproc>
    80001952:	fffff097          	auipc	ra,0xfffff
    80001956:	1d4080e7          	jalr	468(ra) # 80000b26 <release>
  if (first) {
    8000195a:	00007797          	auipc	a5,0x7
    8000195e:	6da7a783          	lw	a5,1754(a5) # 80009034 <first.1>
    80001962:	eb89                	bnez	a5,80001974 <forkret+0x32>
  usertrapret();
    80001964:	00001097          	auipc	ra,0x1
    80001968:	be4080e7          	jalr	-1052(ra) # 80002548 <usertrapret>
}
    8000196c:	60a2                	ld	ra,8(sp)
    8000196e:	6402                	ld	s0,0(sp)
    80001970:	0141                	addi	sp,sp,16
    80001972:	8082                	ret
    first = 0;
    80001974:	00007797          	auipc	a5,0x7
    80001978:	6c07a023          	sw	zero,1728(a5) # 80009034 <first.1>
    fsinit(minor(ROOTDEV));
    8000197c:	4501                	li	a0,0
    8000197e:	00002097          	auipc	ra,0x2
    80001982:	a2a080e7          	jalr	-1494(ra) # 800033a8 <fsinit>
    80001986:	bff9                	j	80001964 <forkret+0x22>

0000000080001988 <allocpid>:
allocpid() {
    80001988:	1101                	addi	sp,sp,-32
    8000198a:	ec06                	sd	ra,24(sp)
    8000198c:	e822                	sd	s0,16(sp)
    8000198e:	e426                	sd	s1,8(sp)
    80001990:	e04a                	sd	s2,0(sp)
    80001992:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001994:	00011917          	auipc	s2,0x11
    80001998:	f5490913          	addi	s2,s2,-172 # 800128e8 <pid_lock>
    8000199c:	854a                	mv	a0,s2
    8000199e:	fffff097          	auipc	ra,0xfffff
    800019a2:	120080e7          	jalr	288(ra) # 80000abe <acquire>
  pid = nextpid;
    800019a6:	00007797          	auipc	a5,0x7
    800019aa:	69278793          	addi	a5,a5,1682 # 80009038 <nextpid>
    800019ae:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    800019b0:	0014871b          	addiw	a4,s1,1
    800019b4:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    800019b6:	854a                	mv	a0,s2
    800019b8:	fffff097          	auipc	ra,0xfffff
    800019bc:	16e080e7          	jalr	366(ra) # 80000b26 <release>
}
    800019c0:	8526                	mv	a0,s1
    800019c2:	60e2                	ld	ra,24(sp)
    800019c4:	6442                	ld	s0,16(sp)
    800019c6:	64a2                	ld	s1,8(sp)
    800019c8:	6902                	ld	s2,0(sp)
    800019ca:	6105                	addi	sp,sp,32
    800019cc:	8082                	ret

00000000800019ce <proc_pagetable>:
{
    800019ce:	1101                	addi	sp,sp,-32
    800019d0:	ec06                	sd	ra,24(sp)
    800019d2:	e822                	sd	s0,16(sp)
    800019d4:	e426                	sd	s1,8(sp)
    800019d6:	e04a                	sd	s2,0(sp)
    800019d8:	1000                	addi	s0,sp,32
    800019da:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    800019dc:	00000097          	auipc	ra,0x0
    800019e0:	882080e7          	jalr	-1918(ra) # 8000125e <uvmcreate>
    800019e4:	84aa                	mv	s1,a0
  mappages(pagetable, TRAMPOLINE, PGSIZE,
    800019e6:	4729                	li	a4,10
    800019e8:	00006697          	auipc	a3,0x6
    800019ec:	61868693          	addi	a3,a3,1560 # 80008000 <trampoline>
    800019f0:	6605                	lui	a2,0x1
    800019f2:	040005b7          	lui	a1,0x4000
    800019f6:	15fd                	addi	a1,a1,-1
    800019f8:	05b2                	slli	a1,a1,0xc
    800019fa:	fffff097          	auipc	ra,0xfffff
    800019fe:	622080e7          	jalr	1570(ra) # 8000101c <mappages>
  mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a02:	4719                	li	a4,6
    80001a04:	06093683          	ld	a3,96(s2)
    80001a08:	6605                	lui	a2,0x1
    80001a0a:	020005b7          	lui	a1,0x2000
    80001a0e:	15fd                	addi	a1,a1,-1
    80001a10:	05b6                	slli	a1,a1,0xd
    80001a12:	8526                	mv	a0,s1
    80001a14:	fffff097          	auipc	ra,0xfffff
    80001a18:	608080e7          	jalr	1544(ra) # 8000101c <mappages>
}
    80001a1c:	8526                	mv	a0,s1
    80001a1e:	60e2                	ld	ra,24(sp)
    80001a20:	6442                	ld	s0,16(sp)
    80001a22:	64a2                	ld	s1,8(sp)
    80001a24:	6902                	ld	s2,0(sp)
    80001a26:	6105                	addi	sp,sp,32
    80001a28:	8082                	ret

0000000080001a2a <allocproc>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a36:	00011497          	auipc	s1,0x11
    80001a3a:	2ca48493          	addi	s1,s1,714 # 80012d00 <proc>
    80001a3e:	00017917          	auipc	s2,0x17
    80001a42:	ec290913          	addi	s2,s2,-318 # 80018900 <tickslock>
    acquire(&p->lock);
    80001a46:	8526                	mv	a0,s1
    80001a48:	fffff097          	auipc	ra,0xfffff
    80001a4c:	076080e7          	jalr	118(ra) # 80000abe <acquire>
    if(p->state == UNUSED) {
    80001a50:	4c9c                	lw	a5,24(s1)
    80001a52:	cf81                	beqz	a5,80001a6a <allocproc+0x40>
      release(&p->lock);
    80001a54:	8526                	mv	a0,s1
    80001a56:	fffff097          	auipc	ra,0xfffff
    80001a5a:	0d0080e7          	jalr	208(ra) # 80000b26 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a5e:	17048493          	addi	s1,s1,368
    80001a62:	ff2492e3          	bne	s1,s2,80001a46 <allocproc+0x1c>
  return 0;
    80001a66:	4481                	li	s1,0
    80001a68:	a0a9                	j	80001ab2 <allocproc+0x88>
  p->pid = allocpid();
    80001a6a:	00000097          	auipc	ra,0x0
    80001a6e:	f1e080e7          	jalr	-226(ra) # 80001988 <allocpid>
    80001a72:	dc88                	sw	a0,56(s1)
  if((p->tf = (struct trapframe *)kalloc()) == 0){
    80001a74:	fffff097          	auipc	ra,0xfffff
    80001a78:	edc080e7          	jalr	-292(ra) # 80000950 <kalloc>
    80001a7c:	892a                	mv	s2,a0
    80001a7e:	f0a8                	sd	a0,96(s1)
    80001a80:	c121                	beqz	a0,80001ac0 <allocproc+0x96>
  p->pagetable = proc_pagetable(p);
    80001a82:	8526                	mv	a0,s1
    80001a84:	00000097          	auipc	ra,0x0
    80001a88:	f4a080e7          	jalr	-182(ra) # 800019ce <proc_pagetable>
    80001a8c:	eca8                	sd	a0,88(s1)
  memset(&p->context, 0, sizeof p->context);
    80001a8e:	07000613          	li	a2,112
    80001a92:	4581                	li	a1,0
    80001a94:	06848513          	addi	a0,s1,104
    80001a98:	fffff097          	auipc	ra,0xfffff
    80001a9c:	0ea080e7          	jalr	234(ra) # 80000b82 <memset>
  p->context.ra = (uint64)forkret;
    80001aa0:	00000797          	auipc	a5,0x0
    80001aa4:	ea278793          	addi	a5,a5,-350 # 80001942 <forkret>
    80001aa8:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001aaa:	60bc                	ld	a5,64(s1)
    80001aac:	6705                	lui	a4,0x1
    80001aae:	97ba                	add	a5,a5,a4
    80001ab0:	f8bc                	sd	a5,112(s1)
}
    80001ab2:	8526                	mv	a0,s1
    80001ab4:	60e2                	ld	ra,24(sp)
    80001ab6:	6442                	ld	s0,16(sp)
    80001ab8:	64a2                	ld	s1,8(sp)
    80001aba:	6902                	ld	s2,0(sp)
    80001abc:	6105                	addi	sp,sp,32
    80001abe:	8082                	ret
    release(&p->lock);
    80001ac0:	8526                	mv	a0,s1
    80001ac2:	fffff097          	auipc	ra,0xfffff
    80001ac6:	064080e7          	jalr	100(ra) # 80000b26 <release>
    return 0;
    80001aca:	84ca                	mv	s1,s2
    80001acc:	b7dd                	j	80001ab2 <allocproc+0x88>

0000000080001ace <proc_freepagetable>:
{
    80001ace:	1101                	addi	sp,sp,-32
    80001ad0:	ec06                	sd	ra,24(sp)
    80001ad2:	e822                	sd	s0,16(sp)
    80001ad4:	e426                	sd	s1,8(sp)
    80001ad6:	e04a                	sd	s2,0(sp)
    80001ad8:	1000                	addi	s0,sp,32
    80001ada:	84aa                	mv	s1,a0
    80001adc:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, PGSIZE, 0);
    80001ade:	4681                	li	a3,0
    80001ae0:	6605                	lui	a2,0x1
    80001ae2:	040005b7          	lui	a1,0x4000
    80001ae6:	15fd                	addi	a1,a1,-1
    80001ae8:	05b2                	slli	a1,a1,0xc
    80001aea:	fffff097          	auipc	ra,0xfffff
    80001aee:	6de080e7          	jalr	1758(ra) # 800011c8 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, PGSIZE, 0);
    80001af2:	4681                	li	a3,0
    80001af4:	6605                	lui	a2,0x1
    80001af6:	020005b7          	lui	a1,0x2000
    80001afa:	15fd                	addi	a1,a1,-1
    80001afc:	05b6                	slli	a1,a1,0xd
    80001afe:	8526                	mv	a0,s1
    80001b00:	fffff097          	auipc	ra,0xfffff
    80001b04:	6c8080e7          	jalr	1736(ra) # 800011c8 <uvmunmap>
  if(sz > 0)
    80001b08:	00091863          	bnez	s2,80001b18 <proc_freepagetable+0x4a>
}
    80001b0c:	60e2                	ld	ra,24(sp)
    80001b0e:	6442                	ld	s0,16(sp)
    80001b10:	64a2                	ld	s1,8(sp)
    80001b12:	6902                	ld	s2,0(sp)
    80001b14:	6105                	addi	sp,sp,32
    80001b16:	8082                	ret
    uvmfree(pagetable, sz);
    80001b18:	85ca                	mv	a1,s2
    80001b1a:	8526                	mv	a0,s1
    80001b1c:	00000097          	auipc	ra,0x0
    80001b20:	8e0080e7          	jalr	-1824(ra) # 800013fc <uvmfree>
}
    80001b24:	b7e5                	j	80001b0c <proc_freepagetable+0x3e>

0000000080001b26 <freeproc>:
{
    80001b26:	1101                	addi	sp,sp,-32
    80001b28:	ec06                	sd	ra,24(sp)
    80001b2a:	e822                	sd	s0,16(sp)
    80001b2c:	e426                	sd	s1,8(sp)
    80001b2e:	1000                	addi	s0,sp,32
    80001b30:	84aa                	mv	s1,a0
  if(p->tf)
    80001b32:	7128                	ld	a0,96(a0)
    80001b34:	c509                	beqz	a0,80001b3e <freeproc+0x18>
    kfree((void*)p->tf);
    80001b36:	fffff097          	auipc	ra,0xfffff
    80001b3a:	d1e080e7          	jalr	-738(ra) # 80000854 <kfree>
  p->tf = 0;
    80001b3e:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001b42:	6ca8                	ld	a0,88(s1)
    80001b44:	c511                	beqz	a0,80001b50 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b46:	68ac                	ld	a1,80(s1)
    80001b48:	00000097          	auipc	ra,0x0
    80001b4c:	f86080e7          	jalr	-122(ra) # 80001ace <proc_freepagetable>
  p->pagetable = 0;
    80001b50:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001b54:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    80001b58:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001b5c:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001b60:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001b64:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001b68:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001b6c:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001b70:	0004ac23          	sw	zero,24(s1)
}
    80001b74:	60e2                	ld	ra,24(sp)
    80001b76:	6442                	ld	s0,16(sp)
    80001b78:	64a2                	ld	s1,8(sp)
    80001b7a:	6105                	addi	sp,sp,32
    80001b7c:	8082                	ret

0000000080001b7e <userinit>:
{
    80001b7e:	1101                	addi	sp,sp,-32
    80001b80:	ec06                	sd	ra,24(sp)
    80001b82:	e822                	sd	s0,16(sp)
    80001b84:	e426                	sd	s1,8(sp)
    80001b86:	1000                	addi	s0,sp,32
  p = allocproc();
    80001b88:	00000097          	auipc	ra,0x0
    80001b8c:	ea2080e7          	jalr	-350(ra) # 80001a2a <allocproc>
    80001b90:	84aa                	mv	s1,a0
  initproc = p;
    80001b92:	00028797          	auipc	a5,0x28
    80001b96:	4aa7b323          	sd	a0,1190(a5) # 8002a038 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001b9a:	03300613          	li	a2,51
    80001b9e:	00007597          	auipc	a1,0x7
    80001ba2:	46258593          	addi	a1,a1,1122 # 80009000 <initcode>
    80001ba6:	6d28                	ld	a0,88(a0)
    80001ba8:	fffff097          	auipc	ra,0xfffff
    80001bac:	6f4080e7          	jalr	1780(ra) # 8000129c <uvminit>
  p->sz = PGSIZE;
    80001bb0:	6785                	lui	a5,0x1
    80001bb2:	e8bc                	sd	a5,80(s1)
  p->tf->epc = 0;      // user program counter
    80001bb4:	70b8                	ld	a4,96(s1)
    80001bb6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->tf->sp = PGSIZE;  // user stack pointer
    80001bba:	70b8                	ld	a4,96(s1)
    80001bbc:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001bbe:	4641                	li	a2,16
    80001bc0:	00006597          	auipc	a1,0x6
    80001bc4:	6e058593          	addi	a1,a1,1760 # 800082a0 <userret+0x210>
    80001bc8:	16048513          	addi	a0,s1,352
    80001bcc:	fffff097          	auipc	ra,0xfffff
    80001bd0:	108080e7          	jalr	264(ra) # 80000cd4 <safestrcpy>
  p->cwd = namei("/");
    80001bd4:	00006517          	auipc	a0,0x6
    80001bd8:	6dc50513          	addi	a0,a0,1756 # 800082b0 <userret+0x220>
    80001bdc:	00002097          	auipc	ra,0x2
    80001be0:	1ce080e7          	jalr	462(ra) # 80003daa <namei>
    80001be4:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80001be8:	4789                	li	a5,2
    80001bea:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001bec:	8526                	mv	a0,s1
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	f38080e7          	jalr	-200(ra) # 80000b26 <release>
}
    80001bf6:	60e2                	ld	ra,24(sp)
    80001bf8:	6442                	ld	s0,16(sp)
    80001bfa:	64a2                	ld	s1,8(sp)
    80001bfc:	6105                	addi	sp,sp,32
    80001bfe:	8082                	ret

0000000080001c00 <growproc>:
{
    80001c00:	1101                	addi	sp,sp,-32
    80001c02:	ec06                	sd	ra,24(sp)
    80001c04:	e822                	sd	s0,16(sp)
    80001c06:	e426                	sd	s1,8(sp)
    80001c08:	e04a                	sd	s2,0(sp)
    80001c0a:	1000                	addi	s0,sp,32
    80001c0c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001c0e:	00000097          	auipc	ra,0x0
    80001c12:	cfc080e7          	jalr	-772(ra) # 8000190a <myproc>
    80001c16:	892a                	mv	s2,a0
  sz = p->sz;
    80001c18:	692c                	ld	a1,80(a0)
    80001c1a:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001c1e:	00904f63          	bgtz	s1,80001c3c <growproc+0x3c>
  } else if(n < 0){
    80001c22:	0204cc63          	bltz	s1,80001c5a <growproc+0x5a>
  p->sz = sz;
    80001c26:	1602                	slli	a2,a2,0x20
    80001c28:	9201                	srli	a2,a2,0x20
    80001c2a:	04c93823          	sd	a2,80(s2)
  return 0;
    80001c2e:	4501                	li	a0,0
}
    80001c30:	60e2                	ld	ra,24(sp)
    80001c32:	6442                	ld	s0,16(sp)
    80001c34:	64a2                	ld	s1,8(sp)
    80001c36:	6902                	ld	s2,0(sp)
    80001c38:	6105                	addi	sp,sp,32
    80001c3a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001c3c:	9e25                	addw	a2,a2,s1
    80001c3e:	1602                	slli	a2,a2,0x20
    80001c40:	9201                	srli	a2,a2,0x20
    80001c42:	1582                	slli	a1,a1,0x20
    80001c44:	9181                	srli	a1,a1,0x20
    80001c46:	6d28                	ld	a0,88(a0)
    80001c48:	fffff097          	auipc	ra,0xfffff
    80001c4c:	70a080e7          	jalr	1802(ra) # 80001352 <uvmalloc>
    80001c50:	0005061b          	sext.w	a2,a0
    80001c54:	fa69                	bnez	a2,80001c26 <growproc+0x26>
      return -1;
    80001c56:	557d                	li	a0,-1
    80001c58:	bfe1                	j	80001c30 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001c5a:	9e25                	addw	a2,a2,s1
    80001c5c:	1602                	slli	a2,a2,0x20
    80001c5e:	9201                	srli	a2,a2,0x20
    80001c60:	1582                	slli	a1,a1,0x20
    80001c62:	9181                	srli	a1,a1,0x20
    80001c64:	6d28                	ld	a0,88(a0)
    80001c66:	fffff097          	auipc	ra,0xfffff
    80001c6a:	6a8080e7          	jalr	1704(ra) # 8000130e <uvmdealloc>
    80001c6e:	0005061b          	sext.w	a2,a0
    80001c72:	bf55                	j	80001c26 <growproc+0x26>

0000000080001c74 <fork>:
{
    80001c74:	7139                	addi	sp,sp,-64
    80001c76:	fc06                	sd	ra,56(sp)
    80001c78:	f822                	sd	s0,48(sp)
    80001c7a:	f426                	sd	s1,40(sp)
    80001c7c:	f04a                	sd	s2,32(sp)
    80001c7e:	ec4e                	sd	s3,24(sp)
    80001c80:	e852                	sd	s4,16(sp)
    80001c82:	e456                	sd	s5,8(sp)
    80001c84:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001c86:	00000097          	auipc	ra,0x0
    80001c8a:	c84080e7          	jalr	-892(ra) # 8000190a <myproc>
    80001c8e:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001c90:	00000097          	auipc	ra,0x0
    80001c94:	d9a080e7          	jalr	-614(ra) # 80001a2a <allocproc>
    80001c98:	c57d                	beqz	a0,80001d86 <fork+0x112>
    80001c9a:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001c9c:	050ab603          	ld	a2,80(s5)
    80001ca0:	6d2c                	ld	a1,88(a0)
    80001ca2:	058ab503          	ld	a0,88(s5)
    80001ca6:	fffff097          	auipc	ra,0xfffff
    80001caa:	784080e7          	jalr	1924(ra) # 8000142a <uvmcopy>
    80001cae:	04054e63          	bltz	a0,80001d0a <fork+0x96>
  np->sz = p->sz;
    80001cb2:	050ab783          	ld	a5,80(s5)
    80001cb6:	04fa3823          	sd	a5,80(s4)
  np->stack_top = p->stack_top;  //新建的进程复制父进程的用户栈栈顶指针
    80001cba:	048ab783          	ld	a5,72(s5)
    80001cbe:	04fa3423          	sd	a5,72(s4)
  np->parent = p;
    80001cc2:	035a3023          	sd	s5,32(s4)
  *(np->tf) = *(p->tf);
    80001cc6:	060ab683          	ld	a3,96(s5)
    80001cca:	87b6                	mv	a5,a3
    80001ccc:	060a3703          	ld	a4,96(s4)
    80001cd0:	12068693          	addi	a3,a3,288
    80001cd4:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001cd8:	6788                	ld	a0,8(a5)
    80001cda:	6b8c                	ld	a1,16(a5)
    80001cdc:	6f90                	ld	a2,24(a5)
    80001cde:	01073023          	sd	a6,0(a4)
    80001ce2:	e708                	sd	a0,8(a4)
    80001ce4:	eb0c                	sd	a1,16(a4)
    80001ce6:	ef10                	sd	a2,24(a4)
    80001ce8:	02078793          	addi	a5,a5,32
    80001cec:	02070713          	addi	a4,a4,32
    80001cf0:	fed792e3          	bne	a5,a3,80001cd4 <fork+0x60>
  np->tf->a0 = 0;
    80001cf4:	060a3783          	ld	a5,96(s4)
    80001cf8:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001cfc:	0d8a8493          	addi	s1,s5,216
    80001d00:	0d8a0913          	addi	s2,s4,216
    80001d04:	158a8993          	addi	s3,s5,344
    80001d08:	a00d                	j	80001d2a <fork+0xb6>
    freeproc(np);
    80001d0a:	8552                	mv	a0,s4
    80001d0c:	00000097          	auipc	ra,0x0
    80001d10:	e1a080e7          	jalr	-486(ra) # 80001b26 <freeproc>
    release(&np->lock);
    80001d14:	8552                	mv	a0,s4
    80001d16:	fffff097          	auipc	ra,0xfffff
    80001d1a:	e10080e7          	jalr	-496(ra) # 80000b26 <release>
    return -1;
    80001d1e:	54fd                	li	s1,-1
    80001d20:	a889                	j	80001d72 <fork+0xfe>
  for(i = 0; i < NOFILE; i++)
    80001d22:	04a1                	addi	s1,s1,8
    80001d24:	0921                	addi	s2,s2,8
    80001d26:	01348b63          	beq	s1,s3,80001d3c <fork+0xc8>
    if(p->ofile[i])
    80001d2a:	6088                	ld	a0,0(s1)
    80001d2c:	d97d                	beqz	a0,80001d22 <fork+0xae>
      np->ofile[i] = filedup(p->ofile[i]);
    80001d2e:	00003097          	auipc	ra,0x3
    80001d32:	970080e7          	jalr	-1680(ra) # 8000469e <filedup>
    80001d36:	00a93023          	sd	a0,0(s2)
    80001d3a:	b7e5                	j	80001d22 <fork+0xae>
  np->cwd = idup(p->cwd);
    80001d3c:	158ab503          	ld	a0,344(s5)
    80001d40:	00002097          	auipc	ra,0x2
    80001d44:	8a2080e7          	jalr	-1886(ra) # 800035e2 <idup>
    80001d48:	14aa3c23          	sd	a0,344(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001d4c:	4641                	li	a2,16
    80001d4e:	160a8593          	addi	a1,s5,352
    80001d52:	160a0513          	addi	a0,s4,352
    80001d56:	fffff097          	auipc	ra,0xfffff
    80001d5a:	f7e080e7          	jalr	-130(ra) # 80000cd4 <safestrcpy>
  pid = np->pid;
    80001d5e:	038a2483          	lw	s1,56(s4)
  np->state = RUNNABLE;
    80001d62:	4789                	li	a5,2
    80001d64:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001d68:	8552                	mv	a0,s4
    80001d6a:	fffff097          	auipc	ra,0xfffff
    80001d6e:	dbc080e7          	jalr	-580(ra) # 80000b26 <release>
}
    80001d72:	8526                	mv	a0,s1
    80001d74:	70e2                	ld	ra,56(sp)
    80001d76:	7442                	ld	s0,48(sp)
    80001d78:	74a2                	ld	s1,40(sp)
    80001d7a:	7902                	ld	s2,32(sp)
    80001d7c:	69e2                	ld	s3,24(sp)
    80001d7e:	6a42                	ld	s4,16(sp)
    80001d80:	6aa2                	ld	s5,8(sp)
    80001d82:	6121                	addi	sp,sp,64
    80001d84:	8082                	ret
    return -1;
    80001d86:	54fd                	li	s1,-1
    80001d88:	b7ed                	j	80001d72 <fork+0xfe>

0000000080001d8a <reparent>:
{
    80001d8a:	7179                	addi	sp,sp,-48
    80001d8c:	f406                	sd	ra,40(sp)
    80001d8e:	f022                	sd	s0,32(sp)
    80001d90:	ec26                	sd	s1,24(sp)
    80001d92:	e84a                	sd	s2,16(sp)
    80001d94:	e44e                	sd	s3,8(sp)
    80001d96:	e052                	sd	s4,0(sp)
    80001d98:	1800                	addi	s0,sp,48
    80001d9a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001d9c:	00011497          	auipc	s1,0x11
    80001da0:	f6448493          	addi	s1,s1,-156 # 80012d00 <proc>
      pp->parent = initproc;
    80001da4:	00028a17          	auipc	s4,0x28
    80001da8:	294a0a13          	addi	s4,s4,660 # 8002a038 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001dac:	00017997          	auipc	s3,0x17
    80001db0:	b5498993          	addi	s3,s3,-1196 # 80018900 <tickslock>
    80001db4:	a029                	j	80001dbe <reparent+0x34>
    80001db6:	17048493          	addi	s1,s1,368
    80001dba:	03348363          	beq	s1,s3,80001de0 <reparent+0x56>
    if(pp->parent == p){
    80001dbe:	709c                	ld	a5,32(s1)
    80001dc0:	ff279be3          	bne	a5,s2,80001db6 <reparent+0x2c>
      acquire(&pp->lock);
    80001dc4:	8526                	mv	a0,s1
    80001dc6:	fffff097          	auipc	ra,0xfffff
    80001dca:	cf8080e7          	jalr	-776(ra) # 80000abe <acquire>
      pp->parent = initproc;
    80001dce:	000a3783          	ld	a5,0(s4)
    80001dd2:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001dd4:	8526                	mv	a0,s1
    80001dd6:	fffff097          	auipc	ra,0xfffff
    80001dda:	d50080e7          	jalr	-688(ra) # 80000b26 <release>
    80001dde:	bfe1                	j	80001db6 <reparent+0x2c>
}
    80001de0:	70a2                	ld	ra,40(sp)
    80001de2:	7402                	ld	s0,32(sp)
    80001de4:	64e2                	ld	s1,24(sp)
    80001de6:	6942                	ld	s2,16(sp)
    80001de8:	69a2                	ld	s3,8(sp)
    80001dea:	6a02                	ld	s4,0(sp)
    80001dec:	6145                	addi	sp,sp,48
    80001dee:	8082                	ret

0000000080001df0 <scheduler>:
{
    80001df0:	715d                	addi	sp,sp,-80
    80001df2:	e486                	sd	ra,72(sp)
    80001df4:	e0a2                	sd	s0,64(sp)
    80001df6:	fc26                	sd	s1,56(sp)
    80001df8:	f84a                	sd	s2,48(sp)
    80001dfa:	f44e                	sd	s3,40(sp)
    80001dfc:	f052                	sd	s4,32(sp)
    80001dfe:	ec56                	sd	s5,24(sp)
    80001e00:	e85a                	sd	s6,16(sp)
    80001e02:	e45e                	sd	s7,8(sp)
    80001e04:	e062                	sd	s8,0(sp)
    80001e06:	0880                	addi	s0,sp,80
    80001e08:	8792                	mv	a5,tp
  int id = r_tp();
    80001e0a:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001e0c:	00779b13          	slli	s6,a5,0x7
    80001e10:	00011717          	auipc	a4,0x11
    80001e14:	ad870713          	addi	a4,a4,-1320 # 800128e8 <pid_lock>
    80001e18:	975a                	add	a4,a4,s6
    80001e1a:	00073c23          	sd	zero,24(a4)
        swtch(&c->scheduler, &p->context);
    80001e1e:	00011717          	auipc	a4,0x11
    80001e22:	aea70713          	addi	a4,a4,-1302 # 80012908 <cpus+0x8>
    80001e26:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001e28:	4c0d                	li	s8,3
        c->proc = p;
    80001e2a:	079e                	slli	a5,a5,0x7
    80001e2c:	00011a17          	auipc	s4,0x11
    80001e30:	abca0a13          	addi	s4,s4,-1348 # 800128e8 <pid_lock>
    80001e34:	9a3e                	add	s4,s4,a5
        found = 1;
    80001e36:	4b85                	li	s7,1
    for(p = proc; p < &proc[NPROC]; p++) {
    80001e38:	00017997          	auipc	s3,0x17
    80001e3c:	ac898993          	addi	s3,s3,-1336 # 80018900 <tickslock>
    80001e40:	a08d                	j	80001ea2 <scheduler+0xb2>
      release(&p->lock);
    80001e42:	8526                	mv	a0,s1
    80001e44:	fffff097          	auipc	ra,0xfffff
    80001e48:	ce2080e7          	jalr	-798(ra) # 80000b26 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001e4c:	17048493          	addi	s1,s1,368
    80001e50:	03348963          	beq	s1,s3,80001e82 <scheduler+0x92>
      acquire(&p->lock);
    80001e54:	8526                	mv	a0,s1
    80001e56:	fffff097          	auipc	ra,0xfffff
    80001e5a:	c68080e7          	jalr	-920(ra) # 80000abe <acquire>
      if(p->state == RUNNABLE) {
    80001e5e:	4c9c                	lw	a5,24(s1)
    80001e60:	ff2791e3          	bne	a5,s2,80001e42 <scheduler+0x52>
        p->state = RUNNING;
    80001e64:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001e68:	009a3c23          	sd	s1,24(s4)
        swtch(&c->scheduler, &p->context);
    80001e6c:	06848593          	addi	a1,s1,104
    80001e70:	855a                	mv	a0,s6
    80001e72:	00000097          	auipc	ra,0x0
    80001e76:	62c080e7          	jalr	1580(ra) # 8000249e <swtch>
        c->proc = 0;
    80001e7a:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80001e7e:	8ade                	mv	s5,s7
    80001e80:	b7c9                	j	80001e42 <scheduler+0x52>
    if(found == 0){
    80001e82:	020a9063          	bnez	s5,80001ea2 <scheduler+0xb2>
  asm volatile("csrr %0, sie" : "=r" (x) );
    80001e86:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    80001e8a:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    80001e8e:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001e92:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001e96:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001e9a:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80001e9e:	10500073          	wfi
  asm volatile("csrr %0, sie" : "=r" (x) );
    80001ea2:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    80001ea6:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    80001eaa:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001eae:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001eb2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001eb6:	10079073          	csrw	sstatus,a5
    int found = 0;
    80001eba:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ebc:	00011497          	auipc	s1,0x11
    80001ec0:	e4448493          	addi	s1,s1,-444 # 80012d00 <proc>
      if(p->state == RUNNABLE) {
    80001ec4:	4909                	li	s2,2
    80001ec6:	b779                	j	80001e54 <scheduler+0x64>

0000000080001ec8 <sched>:
{
    80001ec8:	7179                	addi	sp,sp,-48
    80001eca:	f406                	sd	ra,40(sp)
    80001ecc:	f022                	sd	s0,32(sp)
    80001ece:	ec26                	sd	s1,24(sp)
    80001ed0:	e84a                	sd	s2,16(sp)
    80001ed2:	e44e                	sd	s3,8(sp)
    80001ed4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ed6:	00000097          	auipc	ra,0x0
    80001eda:	a34080e7          	jalr	-1484(ra) # 8000190a <myproc>
    80001ede:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	b9e080e7          	jalr	-1122(ra) # 80000a7e <holding>
    80001ee8:	c93d                	beqz	a0,80001f5e <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001eea:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001eec:	2781                	sext.w	a5,a5
    80001eee:	079e                	slli	a5,a5,0x7
    80001ef0:	00011717          	auipc	a4,0x11
    80001ef4:	9f870713          	addi	a4,a4,-1544 # 800128e8 <pid_lock>
    80001ef8:	97ba                	add	a5,a5,a4
    80001efa:	0907a703          	lw	a4,144(a5)
    80001efe:	4785                	li	a5,1
    80001f00:	06f71763          	bne	a4,a5,80001f6e <sched+0xa6>
  if(p->state == RUNNING)
    80001f04:	4c98                	lw	a4,24(s1)
    80001f06:	478d                	li	a5,3
    80001f08:	06f70b63          	beq	a4,a5,80001f7e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f0c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f10:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f12:	efb5                	bnez	a5,80001f8e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f14:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f16:	00011917          	auipc	s2,0x11
    80001f1a:	9d290913          	addi	s2,s2,-1582 # 800128e8 <pid_lock>
    80001f1e:	2781                	sext.w	a5,a5
    80001f20:	079e                	slli	a5,a5,0x7
    80001f22:	97ca                	add	a5,a5,s2
    80001f24:	0947a983          	lw	s3,148(a5)
    80001f28:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->scheduler);
    80001f2a:	2781                	sext.w	a5,a5
    80001f2c:	079e                	slli	a5,a5,0x7
    80001f2e:	00011597          	auipc	a1,0x11
    80001f32:	9da58593          	addi	a1,a1,-1574 # 80012908 <cpus+0x8>
    80001f36:	95be                	add	a1,a1,a5
    80001f38:	06848513          	addi	a0,s1,104
    80001f3c:	00000097          	auipc	ra,0x0
    80001f40:	562080e7          	jalr	1378(ra) # 8000249e <swtch>
    80001f44:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001f46:	2781                	sext.w	a5,a5
    80001f48:	079e                	slli	a5,a5,0x7
    80001f4a:	97ca                	add	a5,a5,s2
    80001f4c:	0937aa23          	sw	s3,148(a5)
}
    80001f50:	70a2                	ld	ra,40(sp)
    80001f52:	7402                	ld	s0,32(sp)
    80001f54:	64e2                	ld	s1,24(sp)
    80001f56:	6942                	ld	s2,16(sp)
    80001f58:	69a2                	ld	s3,8(sp)
    80001f5a:	6145                	addi	sp,sp,48
    80001f5c:	8082                	ret
    panic("sched p->lock");
    80001f5e:	00006517          	auipc	a0,0x6
    80001f62:	35a50513          	addi	a0,a0,858 # 800082b8 <userret+0x228>
    80001f66:	ffffe097          	auipc	ra,0xffffe
    80001f6a:	5e2080e7          	jalr	1506(ra) # 80000548 <panic>
    panic("sched locks");
    80001f6e:	00006517          	auipc	a0,0x6
    80001f72:	35a50513          	addi	a0,a0,858 # 800082c8 <userret+0x238>
    80001f76:	ffffe097          	auipc	ra,0xffffe
    80001f7a:	5d2080e7          	jalr	1490(ra) # 80000548 <panic>
    panic("sched running");
    80001f7e:	00006517          	auipc	a0,0x6
    80001f82:	35a50513          	addi	a0,a0,858 # 800082d8 <userret+0x248>
    80001f86:	ffffe097          	auipc	ra,0xffffe
    80001f8a:	5c2080e7          	jalr	1474(ra) # 80000548 <panic>
    panic("sched interruptible");
    80001f8e:	00006517          	auipc	a0,0x6
    80001f92:	35a50513          	addi	a0,a0,858 # 800082e8 <userret+0x258>
    80001f96:	ffffe097          	auipc	ra,0xffffe
    80001f9a:	5b2080e7          	jalr	1458(ra) # 80000548 <panic>

0000000080001f9e <exit>:
{
    80001f9e:	7179                	addi	sp,sp,-48
    80001fa0:	f406                	sd	ra,40(sp)
    80001fa2:	f022                	sd	s0,32(sp)
    80001fa4:	ec26                	sd	s1,24(sp)
    80001fa6:	e84a                	sd	s2,16(sp)
    80001fa8:	e44e                	sd	s3,8(sp)
    80001faa:	e052                	sd	s4,0(sp)
    80001fac:	1800                	addi	s0,sp,48
    80001fae:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80001fb0:	00000097          	auipc	ra,0x0
    80001fb4:	95a080e7          	jalr	-1702(ra) # 8000190a <myproc>
    80001fb8:	89aa                	mv	s3,a0
  if(p == initproc)
    80001fba:	00028797          	auipc	a5,0x28
    80001fbe:	07e7b783          	ld	a5,126(a5) # 8002a038 <initproc>
    80001fc2:	0d850493          	addi	s1,a0,216
    80001fc6:	15850913          	addi	s2,a0,344
    80001fca:	02a79363          	bne	a5,a0,80001ff0 <exit+0x52>
    panic("init exiting");
    80001fce:	00006517          	auipc	a0,0x6
    80001fd2:	33250513          	addi	a0,a0,818 # 80008300 <userret+0x270>
    80001fd6:	ffffe097          	auipc	ra,0xffffe
    80001fda:	572080e7          	jalr	1394(ra) # 80000548 <panic>
      fileclose(f);
    80001fde:	00002097          	auipc	ra,0x2
    80001fe2:	712080e7          	jalr	1810(ra) # 800046f0 <fileclose>
      p->ofile[fd] = 0;
    80001fe6:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80001fea:	04a1                	addi	s1,s1,8
    80001fec:	01248563          	beq	s1,s2,80001ff6 <exit+0x58>
    if(p->ofile[fd]){
    80001ff0:	6088                	ld	a0,0(s1)
    80001ff2:	f575                	bnez	a0,80001fde <exit+0x40>
    80001ff4:	bfdd                	j	80001fea <exit+0x4c>
  begin_op(ROOTDEV);
    80001ff6:	4501                	li	a0,0
    80001ff8:	00002097          	auipc	ra,0x2
    80001ffc:	0d0080e7          	jalr	208(ra) # 800040c8 <begin_op>
  iput(p->cwd);
    80002000:	1589b503          	ld	a0,344(s3)
    80002004:	00001097          	auipc	ra,0x1
    80002008:	72a080e7          	jalr	1834(ra) # 8000372e <iput>
  end_op(ROOTDEV);
    8000200c:	4501                	li	a0,0
    8000200e:	00002097          	auipc	ra,0x2
    80002012:	164080e7          	jalr	356(ra) # 80004172 <end_op>
  p->cwd = 0;
    80002016:	1409bc23          	sd	zero,344(s3)
  acquire(&initproc->lock);
    8000201a:	00028497          	auipc	s1,0x28
    8000201e:	01e48493          	addi	s1,s1,30 # 8002a038 <initproc>
    80002022:	6088                	ld	a0,0(s1)
    80002024:	fffff097          	auipc	ra,0xfffff
    80002028:	a9a080e7          	jalr	-1382(ra) # 80000abe <acquire>
  wakeup1(initproc);
    8000202c:	6088                	ld	a0,0(s1)
    8000202e:	fffff097          	auipc	ra,0xfffff
    80002032:	79c080e7          	jalr	1948(ra) # 800017ca <wakeup1>
  release(&initproc->lock);
    80002036:	6088                	ld	a0,0(s1)
    80002038:	fffff097          	auipc	ra,0xfffff
    8000203c:	aee080e7          	jalr	-1298(ra) # 80000b26 <release>
  acquire(&p->lock);
    80002040:	854e                	mv	a0,s3
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	a7c080e7          	jalr	-1412(ra) # 80000abe <acquire>
  struct proc *original_parent = p->parent;
    8000204a:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    8000204e:	854e                	mv	a0,s3
    80002050:	fffff097          	auipc	ra,0xfffff
    80002054:	ad6080e7          	jalr	-1322(ra) # 80000b26 <release>
  acquire(&original_parent->lock);
    80002058:	8526                	mv	a0,s1
    8000205a:	fffff097          	auipc	ra,0xfffff
    8000205e:	a64080e7          	jalr	-1436(ra) # 80000abe <acquire>
  acquire(&p->lock);
    80002062:	854e                	mv	a0,s3
    80002064:	fffff097          	auipc	ra,0xfffff
    80002068:	a5a080e7          	jalr	-1446(ra) # 80000abe <acquire>
  reparent(p);
    8000206c:	854e                	mv	a0,s3
    8000206e:	00000097          	auipc	ra,0x0
    80002072:	d1c080e7          	jalr	-740(ra) # 80001d8a <reparent>
  wakeup1(original_parent);
    80002076:	8526                	mv	a0,s1
    80002078:	fffff097          	auipc	ra,0xfffff
    8000207c:	752080e7          	jalr	1874(ra) # 800017ca <wakeup1>
  p->xstate = status;
    80002080:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80002084:	4791                	li	a5,4
    80002086:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    8000208a:	8526                	mv	a0,s1
    8000208c:	fffff097          	auipc	ra,0xfffff
    80002090:	a9a080e7          	jalr	-1382(ra) # 80000b26 <release>
  sched();
    80002094:	00000097          	auipc	ra,0x0
    80002098:	e34080e7          	jalr	-460(ra) # 80001ec8 <sched>
  panic("zombie exit");
    8000209c:	00006517          	auipc	a0,0x6
    800020a0:	27450513          	addi	a0,a0,628 # 80008310 <userret+0x280>
    800020a4:	ffffe097          	auipc	ra,0xffffe
    800020a8:	4a4080e7          	jalr	1188(ra) # 80000548 <panic>

00000000800020ac <yield>:
{
    800020ac:	1101                	addi	sp,sp,-32
    800020ae:	ec06                	sd	ra,24(sp)
    800020b0:	e822                	sd	s0,16(sp)
    800020b2:	e426                	sd	s1,8(sp)
    800020b4:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020b6:	00000097          	auipc	ra,0x0
    800020ba:	854080e7          	jalr	-1964(ra) # 8000190a <myproc>
    800020be:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020c0:	fffff097          	auipc	ra,0xfffff
    800020c4:	9fe080e7          	jalr	-1538(ra) # 80000abe <acquire>
  p->state = RUNNABLE;
    800020c8:	4789                	li	a5,2
    800020ca:	cc9c                	sw	a5,24(s1)
  sched();
    800020cc:	00000097          	auipc	ra,0x0
    800020d0:	dfc080e7          	jalr	-516(ra) # 80001ec8 <sched>
  release(&p->lock);
    800020d4:	8526                	mv	a0,s1
    800020d6:	fffff097          	auipc	ra,0xfffff
    800020da:	a50080e7          	jalr	-1456(ra) # 80000b26 <release>
}
    800020de:	60e2                	ld	ra,24(sp)
    800020e0:	6442                	ld	s0,16(sp)
    800020e2:	64a2                	ld	s1,8(sp)
    800020e4:	6105                	addi	sp,sp,32
    800020e6:	8082                	ret

00000000800020e8 <sleep>:
{
    800020e8:	7179                	addi	sp,sp,-48
    800020ea:	f406                	sd	ra,40(sp)
    800020ec:	f022                	sd	s0,32(sp)
    800020ee:	ec26                	sd	s1,24(sp)
    800020f0:	e84a                	sd	s2,16(sp)
    800020f2:	e44e                	sd	s3,8(sp)
    800020f4:	1800                	addi	s0,sp,48
    800020f6:	89aa                	mv	s3,a0
    800020f8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020fa:	00000097          	auipc	ra,0x0
    800020fe:	810080e7          	jalr	-2032(ra) # 8000190a <myproc>
    80002102:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002104:	05250663          	beq	a0,s2,80002150 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002108:	fffff097          	auipc	ra,0xfffff
    8000210c:	9b6080e7          	jalr	-1610(ra) # 80000abe <acquire>
    release(lk);
    80002110:	854a                	mv	a0,s2
    80002112:	fffff097          	auipc	ra,0xfffff
    80002116:	a14080e7          	jalr	-1516(ra) # 80000b26 <release>
  p->chan = chan;
    8000211a:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    8000211e:	4785                	li	a5,1
    80002120:	cc9c                	sw	a5,24(s1)
  sched();
    80002122:	00000097          	auipc	ra,0x0
    80002126:	da6080e7          	jalr	-602(ra) # 80001ec8 <sched>
  p->chan = 0;
    8000212a:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    8000212e:	8526                	mv	a0,s1
    80002130:	fffff097          	auipc	ra,0xfffff
    80002134:	9f6080e7          	jalr	-1546(ra) # 80000b26 <release>
    acquire(lk);
    80002138:	854a                	mv	a0,s2
    8000213a:	fffff097          	auipc	ra,0xfffff
    8000213e:	984080e7          	jalr	-1660(ra) # 80000abe <acquire>
}
    80002142:	70a2                	ld	ra,40(sp)
    80002144:	7402                	ld	s0,32(sp)
    80002146:	64e2                	ld	s1,24(sp)
    80002148:	6942                	ld	s2,16(sp)
    8000214a:	69a2                	ld	s3,8(sp)
    8000214c:	6145                	addi	sp,sp,48
    8000214e:	8082                	ret
  p->chan = chan;
    80002150:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80002154:	4785                	li	a5,1
    80002156:	cd1c                	sw	a5,24(a0)
  sched();
    80002158:	00000097          	auipc	ra,0x0
    8000215c:	d70080e7          	jalr	-656(ra) # 80001ec8 <sched>
  p->chan = 0;
    80002160:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002164:	bff9                	j	80002142 <sleep+0x5a>

0000000080002166 <wait>:
{
    80002166:	715d                	addi	sp,sp,-80
    80002168:	e486                	sd	ra,72(sp)
    8000216a:	e0a2                	sd	s0,64(sp)
    8000216c:	fc26                	sd	s1,56(sp)
    8000216e:	f84a                	sd	s2,48(sp)
    80002170:	f44e                	sd	s3,40(sp)
    80002172:	f052                	sd	s4,32(sp)
    80002174:	ec56                	sd	s5,24(sp)
    80002176:	e85a                	sd	s6,16(sp)
    80002178:	e45e                	sd	s7,8(sp)
    8000217a:	0880                	addi	s0,sp,80
    8000217c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000217e:	fffff097          	auipc	ra,0xfffff
    80002182:	78c080e7          	jalr	1932(ra) # 8000190a <myproc>
    80002186:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002188:	fffff097          	auipc	ra,0xfffff
    8000218c:	936080e7          	jalr	-1738(ra) # 80000abe <acquire>
    havekids = 0;
    80002190:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002192:	4a11                	li	s4,4
        havekids = 1;
    80002194:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002196:	00016997          	auipc	s3,0x16
    8000219a:	76a98993          	addi	s3,s3,1898 # 80018900 <tickslock>
    havekids = 0;
    8000219e:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800021a0:	00011497          	auipc	s1,0x11
    800021a4:	b6048493          	addi	s1,s1,-1184 # 80012d00 <proc>
    800021a8:	a08d                	j	8000220a <wait+0xa4>
          pid = np->pid;
    800021aa:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800021ae:	000b0e63          	beqz	s6,800021ca <wait+0x64>
    800021b2:	4691                	li	a3,4
    800021b4:	03448613          	addi	a2,s1,52
    800021b8:	85da                	mv	a1,s6
    800021ba:	05893503          	ld	a0,88(s2)
    800021be:	fffff097          	auipc	ra,0xfffff
    800021c2:	352080e7          	jalr	850(ra) # 80001510 <copyout>
    800021c6:	02054263          	bltz	a0,800021ea <wait+0x84>
          freeproc(np);
    800021ca:	8526                	mv	a0,s1
    800021cc:	00000097          	auipc	ra,0x0
    800021d0:	95a080e7          	jalr	-1702(ra) # 80001b26 <freeproc>
          release(&np->lock);
    800021d4:	8526                	mv	a0,s1
    800021d6:	fffff097          	auipc	ra,0xfffff
    800021da:	950080e7          	jalr	-1712(ra) # 80000b26 <release>
          release(&p->lock);
    800021de:	854a                	mv	a0,s2
    800021e0:	fffff097          	auipc	ra,0xfffff
    800021e4:	946080e7          	jalr	-1722(ra) # 80000b26 <release>
          return pid;
    800021e8:	a8a9                	j	80002242 <wait+0xdc>
            release(&np->lock);
    800021ea:	8526                	mv	a0,s1
    800021ec:	fffff097          	auipc	ra,0xfffff
    800021f0:	93a080e7          	jalr	-1734(ra) # 80000b26 <release>
            release(&p->lock);
    800021f4:	854a                	mv	a0,s2
    800021f6:	fffff097          	auipc	ra,0xfffff
    800021fa:	930080e7          	jalr	-1744(ra) # 80000b26 <release>
            return -1;
    800021fe:	59fd                	li	s3,-1
    80002200:	a089                	j	80002242 <wait+0xdc>
    for(np = proc; np < &proc[NPROC]; np++){
    80002202:	17048493          	addi	s1,s1,368
    80002206:	03348463          	beq	s1,s3,8000222e <wait+0xc8>
      if(np->parent == p){
    8000220a:	709c                	ld	a5,32(s1)
    8000220c:	ff279be3          	bne	a5,s2,80002202 <wait+0x9c>
        acquire(&np->lock);
    80002210:	8526                	mv	a0,s1
    80002212:	fffff097          	auipc	ra,0xfffff
    80002216:	8ac080e7          	jalr	-1876(ra) # 80000abe <acquire>
        if(np->state == ZOMBIE){
    8000221a:	4c9c                	lw	a5,24(s1)
    8000221c:	f94787e3          	beq	a5,s4,800021aa <wait+0x44>
        release(&np->lock);
    80002220:	8526                	mv	a0,s1
    80002222:	fffff097          	auipc	ra,0xfffff
    80002226:	904080e7          	jalr	-1788(ra) # 80000b26 <release>
        havekids = 1;
    8000222a:	8756                	mv	a4,s5
    8000222c:	bfd9                	j	80002202 <wait+0x9c>
    if(!havekids || p->killed){
    8000222e:	c701                	beqz	a4,80002236 <wait+0xd0>
    80002230:	03092783          	lw	a5,48(s2)
    80002234:	c39d                	beqz	a5,8000225a <wait+0xf4>
      release(&p->lock);
    80002236:	854a                	mv	a0,s2
    80002238:	fffff097          	auipc	ra,0xfffff
    8000223c:	8ee080e7          	jalr	-1810(ra) # 80000b26 <release>
      return -1;
    80002240:	59fd                	li	s3,-1
}
    80002242:	854e                	mv	a0,s3
    80002244:	60a6                	ld	ra,72(sp)
    80002246:	6406                	ld	s0,64(sp)
    80002248:	74e2                	ld	s1,56(sp)
    8000224a:	7942                	ld	s2,48(sp)
    8000224c:	79a2                	ld	s3,40(sp)
    8000224e:	7a02                	ld	s4,32(sp)
    80002250:	6ae2                	ld	s5,24(sp)
    80002252:	6b42                	ld	s6,16(sp)
    80002254:	6ba2                	ld	s7,8(sp)
    80002256:	6161                	addi	sp,sp,80
    80002258:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    8000225a:	85ca                	mv	a1,s2
    8000225c:	854a                	mv	a0,s2
    8000225e:	00000097          	auipc	ra,0x0
    80002262:	e8a080e7          	jalr	-374(ra) # 800020e8 <sleep>
    havekids = 0;
    80002266:	bf25                	j	8000219e <wait+0x38>

0000000080002268 <wakeup>:
{
    80002268:	7139                	addi	sp,sp,-64
    8000226a:	fc06                	sd	ra,56(sp)
    8000226c:	f822                	sd	s0,48(sp)
    8000226e:	f426                	sd	s1,40(sp)
    80002270:	f04a                	sd	s2,32(sp)
    80002272:	ec4e                	sd	s3,24(sp)
    80002274:	e852                	sd	s4,16(sp)
    80002276:	e456                	sd	s5,8(sp)
    80002278:	0080                	addi	s0,sp,64
    8000227a:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000227c:	00011497          	auipc	s1,0x11
    80002280:	a8448493          	addi	s1,s1,-1404 # 80012d00 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002284:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002286:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002288:	00016917          	auipc	s2,0x16
    8000228c:	67890913          	addi	s2,s2,1656 # 80018900 <tickslock>
    80002290:	a811                	j	800022a4 <wakeup+0x3c>
    release(&p->lock);
    80002292:	8526                	mv	a0,s1
    80002294:	fffff097          	auipc	ra,0xfffff
    80002298:	892080e7          	jalr	-1902(ra) # 80000b26 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000229c:	17048493          	addi	s1,s1,368
    800022a0:	03248063          	beq	s1,s2,800022c0 <wakeup+0x58>
    acquire(&p->lock);
    800022a4:	8526                	mv	a0,s1
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	818080e7          	jalr	-2024(ra) # 80000abe <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800022ae:	4c9c                	lw	a5,24(s1)
    800022b0:	ff3791e3          	bne	a5,s3,80002292 <wakeup+0x2a>
    800022b4:	749c                	ld	a5,40(s1)
    800022b6:	fd479ee3          	bne	a5,s4,80002292 <wakeup+0x2a>
      p->state = RUNNABLE;
    800022ba:	0154ac23          	sw	s5,24(s1)
    800022be:	bfd1                	j	80002292 <wakeup+0x2a>
}
    800022c0:	70e2                	ld	ra,56(sp)
    800022c2:	7442                	ld	s0,48(sp)
    800022c4:	74a2                	ld	s1,40(sp)
    800022c6:	7902                	ld	s2,32(sp)
    800022c8:	69e2                	ld	s3,24(sp)
    800022ca:	6a42                	ld	s4,16(sp)
    800022cc:	6aa2                	ld	s5,8(sp)
    800022ce:	6121                	addi	sp,sp,64
    800022d0:	8082                	ret

00000000800022d2 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800022d2:	7179                	addi	sp,sp,-48
    800022d4:	f406                	sd	ra,40(sp)
    800022d6:	f022                	sd	s0,32(sp)
    800022d8:	ec26                	sd	s1,24(sp)
    800022da:	e84a                	sd	s2,16(sp)
    800022dc:	e44e                	sd	s3,8(sp)
    800022de:	1800                	addi	s0,sp,48
    800022e0:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800022e2:	00011497          	auipc	s1,0x11
    800022e6:	a1e48493          	addi	s1,s1,-1506 # 80012d00 <proc>
    800022ea:	00016997          	auipc	s3,0x16
    800022ee:	61698993          	addi	s3,s3,1558 # 80018900 <tickslock>
    acquire(&p->lock);
    800022f2:	8526                	mv	a0,s1
    800022f4:	ffffe097          	auipc	ra,0xffffe
    800022f8:	7ca080e7          	jalr	1994(ra) # 80000abe <acquire>
    if(p->pid == pid){
    800022fc:	5c9c                	lw	a5,56(s1)
    800022fe:	01278d63          	beq	a5,s2,80002318 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002302:	8526                	mv	a0,s1
    80002304:	fffff097          	auipc	ra,0xfffff
    80002308:	822080e7          	jalr	-2014(ra) # 80000b26 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000230c:	17048493          	addi	s1,s1,368
    80002310:	ff3491e3          	bne	s1,s3,800022f2 <kill+0x20>
  }
  return -1;
    80002314:	557d                	li	a0,-1
    80002316:	a821                	j	8000232e <kill+0x5c>
      p->killed = 1;
    80002318:	4785                	li	a5,1
    8000231a:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    8000231c:	4c98                	lw	a4,24(s1)
    8000231e:	00f70f63          	beq	a4,a5,8000233c <kill+0x6a>
      release(&p->lock);
    80002322:	8526                	mv	a0,s1
    80002324:	fffff097          	auipc	ra,0xfffff
    80002328:	802080e7          	jalr	-2046(ra) # 80000b26 <release>
      return 0;
    8000232c:	4501                	li	a0,0
}
    8000232e:	70a2                	ld	ra,40(sp)
    80002330:	7402                	ld	s0,32(sp)
    80002332:	64e2                	ld	s1,24(sp)
    80002334:	6942                	ld	s2,16(sp)
    80002336:	69a2                	ld	s3,8(sp)
    80002338:	6145                	addi	sp,sp,48
    8000233a:	8082                	ret
        p->state = RUNNABLE;
    8000233c:	4789                	li	a5,2
    8000233e:	cc9c                	sw	a5,24(s1)
    80002340:	b7cd                	j	80002322 <kill+0x50>

0000000080002342 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002342:	7179                	addi	sp,sp,-48
    80002344:	f406                	sd	ra,40(sp)
    80002346:	f022                	sd	s0,32(sp)
    80002348:	ec26                	sd	s1,24(sp)
    8000234a:	e84a                	sd	s2,16(sp)
    8000234c:	e44e                	sd	s3,8(sp)
    8000234e:	e052                	sd	s4,0(sp)
    80002350:	1800                	addi	s0,sp,48
    80002352:	84aa                	mv	s1,a0
    80002354:	892e                	mv	s2,a1
    80002356:	89b2                	mv	s3,a2
    80002358:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	5b0080e7          	jalr	1456(ra) # 8000190a <myproc>
  if(user_dst){
    80002362:	c08d                	beqz	s1,80002384 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002364:	86d2                	mv	a3,s4
    80002366:	864e                	mv	a2,s3
    80002368:	85ca                	mv	a1,s2
    8000236a:	6d28                	ld	a0,88(a0)
    8000236c:	fffff097          	auipc	ra,0xfffff
    80002370:	1a4080e7          	jalr	420(ra) # 80001510 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002374:	70a2                	ld	ra,40(sp)
    80002376:	7402                	ld	s0,32(sp)
    80002378:	64e2                	ld	s1,24(sp)
    8000237a:	6942                	ld	s2,16(sp)
    8000237c:	69a2                	ld	s3,8(sp)
    8000237e:	6a02                	ld	s4,0(sp)
    80002380:	6145                	addi	sp,sp,48
    80002382:	8082                	ret
    memmove((char *)dst, src, len);
    80002384:	000a061b          	sext.w	a2,s4
    80002388:	85ce                	mv	a1,s3
    8000238a:	854a                	mv	a0,s2
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	852080e7          	jalr	-1966(ra) # 80000bde <memmove>
    return 0;
    80002394:	8526                	mv	a0,s1
    80002396:	bff9                	j	80002374 <either_copyout+0x32>

0000000080002398 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002398:	7179                	addi	sp,sp,-48
    8000239a:	f406                	sd	ra,40(sp)
    8000239c:	f022                	sd	s0,32(sp)
    8000239e:	ec26                	sd	s1,24(sp)
    800023a0:	e84a                	sd	s2,16(sp)
    800023a2:	e44e                	sd	s3,8(sp)
    800023a4:	e052                	sd	s4,0(sp)
    800023a6:	1800                	addi	s0,sp,48
    800023a8:	892a                	mv	s2,a0
    800023aa:	84ae                	mv	s1,a1
    800023ac:	89b2                	mv	s3,a2
    800023ae:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	55a080e7          	jalr	1370(ra) # 8000190a <myproc>
  if(user_src){
    800023b8:	c08d                	beqz	s1,800023da <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800023ba:	86d2                	mv	a3,s4
    800023bc:	864e                	mv	a2,s3
    800023be:	85ca                	mv	a1,s2
    800023c0:	6d28                	ld	a0,88(a0)
    800023c2:	fffff097          	auipc	ra,0xfffff
    800023c6:	1da080e7          	jalr	474(ra) # 8000159c <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800023ca:	70a2                	ld	ra,40(sp)
    800023cc:	7402                	ld	s0,32(sp)
    800023ce:	64e2                	ld	s1,24(sp)
    800023d0:	6942                	ld	s2,16(sp)
    800023d2:	69a2                	ld	s3,8(sp)
    800023d4:	6a02                	ld	s4,0(sp)
    800023d6:	6145                	addi	sp,sp,48
    800023d8:	8082                	ret
    memmove(dst, (char*)src, len);
    800023da:	000a061b          	sext.w	a2,s4
    800023de:	85ce                	mv	a1,s3
    800023e0:	854a                	mv	a0,s2
    800023e2:	ffffe097          	auipc	ra,0xffffe
    800023e6:	7fc080e7          	jalr	2044(ra) # 80000bde <memmove>
    return 0;
    800023ea:	8526                	mv	a0,s1
    800023ec:	bff9                	j	800023ca <either_copyin+0x32>

00000000800023ee <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800023ee:	715d                	addi	sp,sp,-80
    800023f0:	e486                	sd	ra,72(sp)
    800023f2:	e0a2                	sd	s0,64(sp)
    800023f4:	fc26                	sd	s1,56(sp)
    800023f6:	f84a                	sd	s2,48(sp)
    800023f8:	f44e                	sd	s3,40(sp)
    800023fa:	f052                	sd	s4,32(sp)
    800023fc:	ec56                	sd	s5,24(sp)
    800023fe:	e85a                	sd	s6,16(sp)
    80002400:	e45e                	sd	s7,8(sp)
    80002402:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002404:	00006517          	auipc	a0,0x6
    80002408:	dac50513          	addi	a0,a0,-596 # 800081b0 <userret+0x120>
    8000240c:	ffffe097          	auipc	ra,0xffffe
    80002410:	186080e7          	jalr	390(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002414:	00011497          	auipc	s1,0x11
    80002418:	a4c48493          	addi	s1,s1,-1460 # 80012e60 <proc+0x160>
    8000241c:	00016917          	auipc	s2,0x16
    80002420:	64490913          	addi	s2,s2,1604 # 80018a60 <bcache+0x148>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002424:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002426:	00006997          	auipc	s3,0x6
    8000242a:	efa98993          	addi	s3,s3,-262 # 80008320 <userret+0x290>
    printf("%d %s %s", p->pid, state, p->name);
    8000242e:	00006a97          	auipc	s5,0x6
    80002432:	efaa8a93          	addi	s5,s5,-262 # 80008328 <userret+0x298>
    printf("\n");
    80002436:	00006a17          	auipc	s4,0x6
    8000243a:	d7aa0a13          	addi	s4,s4,-646 # 800081b0 <userret+0x120>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000243e:	00006b97          	auipc	s7,0x6
    80002442:	65ab8b93          	addi	s7,s7,1626 # 80008a98 <states.0>
    80002446:	a00d                	j	80002468 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002448:	ed86a583          	lw	a1,-296(a3)
    8000244c:	8556                	mv	a0,s5
    8000244e:	ffffe097          	auipc	ra,0xffffe
    80002452:	144080e7          	jalr	324(ra) # 80000592 <printf>
    printf("\n");
    80002456:	8552                	mv	a0,s4
    80002458:	ffffe097          	auipc	ra,0xffffe
    8000245c:	13a080e7          	jalr	314(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002460:	17048493          	addi	s1,s1,368
    80002464:	03248263          	beq	s1,s2,80002488 <procdump+0x9a>
    if(p->state == UNUSED)
    80002468:	86a6                	mv	a3,s1
    8000246a:	eb84a783          	lw	a5,-328(s1)
    8000246e:	dbed                	beqz	a5,80002460 <procdump+0x72>
      state = "???";
    80002470:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002472:	fcfb6be3          	bltu	s6,a5,80002448 <procdump+0x5a>
    80002476:	02079713          	slli	a4,a5,0x20
    8000247a:	01d75793          	srli	a5,a4,0x1d
    8000247e:	97de                	add	a5,a5,s7
    80002480:	6390                	ld	a2,0(a5)
    80002482:	f279                	bnez	a2,80002448 <procdump+0x5a>
      state = "???";
    80002484:	864e                	mv	a2,s3
    80002486:	b7c9                	j	80002448 <procdump+0x5a>
  }
}
    80002488:	60a6                	ld	ra,72(sp)
    8000248a:	6406                	ld	s0,64(sp)
    8000248c:	74e2                	ld	s1,56(sp)
    8000248e:	7942                	ld	s2,48(sp)
    80002490:	79a2                	ld	s3,40(sp)
    80002492:	7a02                	ld	s4,32(sp)
    80002494:	6ae2                	ld	s5,24(sp)
    80002496:	6b42                	ld	s6,16(sp)
    80002498:	6ba2                	ld	s7,8(sp)
    8000249a:	6161                	addi	sp,sp,80
    8000249c:	8082                	ret

000000008000249e <swtch>:
    8000249e:	00153023          	sd	ra,0(a0)
    800024a2:	00253423          	sd	sp,8(a0)
    800024a6:	e900                	sd	s0,16(a0)
    800024a8:	ed04                	sd	s1,24(a0)
    800024aa:	03253023          	sd	s2,32(a0)
    800024ae:	03353423          	sd	s3,40(a0)
    800024b2:	03453823          	sd	s4,48(a0)
    800024b6:	03553c23          	sd	s5,56(a0)
    800024ba:	05653023          	sd	s6,64(a0)
    800024be:	05753423          	sd	s7,72(a0)
    800024c2:	05853823          	sd	s8,80(a0)
    800024c6:	05953c23          	sd	s9,88(a0)
    800024ca:	07a53023          	sd	s10,96(a0)
    800024ce:	07b53423          	sd	s11,104(a0)
    800024d2:	0005b083          	ld	ra,0(a1)
    800024d6:	0085b103          	ld	sp,8(a1)
    800024da:	6980                	ld	s0,16(a1)
    800024dc:	6d84                	ld	s1,24(a1)
    800024de:	0205b903          	ld	s2,32(a1)
    800024e2:	0285b983          	ld	s3,40(a1)
    800024e6:	0305ba03          	ld	s4,48(a1)
    800024ea:	0385ba83          	ld	s5,56(a1)
    800024ee:	0405bb03          	ld	s6,64(a1)
    800024f2:	0485bb83          	ld	s7,72(a1)
    800024f6:	0505bc03          	ld	s8,80(a1)
    800024fa:	0585bc83          	ld	s9,88(a1)
    800024fe:	0605bd03          	ld	s10,96(a1)
    80002502:	0685bd83          	ld	s11,104(a1)
    80002506:	8082                	ret

0000000080002508 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002508:	1141                	addi	sp,sp,-16
    8000250a:	e406                	sd	ra,8(sp)
    8000250c:	e022                	sd	s0,0(sp)
    8000250e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002510:	00006597          	auipc	a1,0x6
    80002514:	e5058593          	addi	a1,a1,-432 # 80008360 <userret+0x2d0>
    80002518:	00016517          	auipc	a0,0x16
    8000251c:	3e850513          	addi	a0,a0,1000 # 80018900 <tickslock>
    80002520:	ffffe097          	auipc	ra,0xffffe
    80002524:	490080e7          	jalr	1168(ra) # 800009b0 <initlock>
}
    80002528:	60a2                	ld	ra,8(sp)
    8000252a:	6402                	ld	s0,0(sp)
    8000252c:	0141                	addi	sp,sp,16
    8000252e:	8082                	ret

0000000080002530 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002530:	1141                	addi	sp,sp,-16
    80002532:	e422                	sd	s0,8(sp)
    80002534:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002536:	00004797          	auipc	a5,0x4
    8000253a:	aca78793          	addi	a5,a5,-1334 # 80006000 <kernelvec>
    8000253e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002542:	6422                	ld	s0,8(sp)
    80002544:	0141                	addi	sp,sp,16
    80002546:	8082                	ret

0000000080002548 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002548:	1141                	addi	sp,sp,-16
    8000254a:	e406                	sd	ra,8(sp)
    8000254c:	e022                	sd	s0,0(sp)
    8000254e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002550:	fffff097          	auipc	ra,0xfffff
    80002554:	3ba080e7          	jalr	954(ra) # 8000190a <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002558:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000255c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000255e:	10079073          	csrw	sstatus,a5
  // turn off interrupts, since we're switching
  // now from kerneltrap() to usertrap().
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002562:	00006617          	auipc	a2,0x6
    80002566:	a9e60613          	addi	a2,a2,-1378 # 80008000 <trampoline>
    8000256a:	00006697          	auipc	a3,0x6
    8000256e:	a9668693          	addi	a3,a3,-1386 # 80008000 <trampoline>
    80002572:	8e91                	sub	a3,a3,a2
    80002574:	040007b7          	lui	a5,0x4000
    80002578:	17fd                	addi	a5,a5,-1
    8000257a:	07b2                	slli	a5,a5,0xc
    8000257c:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000257e:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->tf->kernel_satp = r_satp();         // kernel page table
    80002582:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002584:	180026f3          	csrr	a3,satp
    80002588:	e314                	sd	a3,0(a4)
  p->tf->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000258a:	7138                	ld	a4,96(a0)
    8000258c:	6134                	ld	a3,64(a0)
    8000258e:	6585                	lui	a1,0x1
    80002590:	96ae                	add	a3,a3,a1
    80002592:	e714                	sd	a3,8(a4)
  p->tf->kernel_trap = (uint64)usertrap;
    80002594:	7138                	ld	a4,96(a0)
    80002596:	00000697          	auipc	a3,0x0
    8000259a:	12868693          	addi	a3,a3,296 # 800026be <usertrap>
    8000259e:	eb14                	sd	a3,16(a4)
  p->tf->kernel_hartid = r_tp();         // hartid for cpuid()
    800025a0:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800025a2:	8692                	mv	a3,tp
    800025a4:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025a6:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800025aa:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800025ae:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800025b2:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->tf->epc);
    800025b6:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800025b8:	6f18                	ld	a4,24(a4)
    800025ba:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800025be:	6d2c                	ld	a1,88(a0)
    800025c0:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800025c2:	00006717          	auipc	a4,0x6
    800025c6:	ace70713          	addi	a4,a4,-1330 # 80008090 <userret>
    800025ca:	8f11                	sub	a4,a4,a2
    800025cc:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800025ce:	577d                	li	a4,-1
    800025d0:	177e                	slli	a4,a4,0x3f
    800025d2:	8dd9                	or	a1,a1,a4
    800025d4:	02000537          	lui	a0,0x2000
    800025d8:	157d                	addi	a0,a0,-1
    800025da:	0536                	slli	a0,a0,0xd
    800025dc:	9782                	jalr	a5
}
    800025de:	60a2                	ld	ra,8(sp)
    800025e0:	6402                	ld	s0,0(sp)
    800025e2:	0141                	addi	sp,sp,16
    800025e4:	8082                	ret

00000000800025e6 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800025e6:	1101                	addi	sp,sp,-32
    800025e8:	ec06                	sd	ra,24(sp)
    800025ea:	e822                	sd	s0,16(sp)
    800025ec:	e426                	sd	s1,8(sp)
    800025ee:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800025f0:	00016497          	auipc	s1,0x16
    800025f4:	31048493          	addi	s1,s1,784 # 80018900 <tickslock>
    800025f8:	8526                	mv	a0,s1
    800025fa:	ffffe097          	auipc	ra,0xffffe
    800025fe:	4c4080e7          	jalr	1220(ra) # 80000abe <acquire>
  ticks++;
    80002602:	00028517          	auipc	a0,0x28
    80002606:	a3e50513          	addi	a0,a0,-1474 # 8002a040 <ticks>
    8000260a:	411c                	lw	a5,0(a0)
    8000260c:	2785                	addiw	a5,a5,1
    8000260e:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002610:	00000097          	auipc	ra,0x0
    80002614:	c58080e7          	jalr	-936(ra) # 80002268 <wakeup>
  release(&tickslock);
    80002618:	8526                	mv	a0,s1
    8000261a:	ffffe097          	auipc	ra,0xffffe
    8000261e:	50c080e7          	jalr	1292(ra) # 80000b26 <release>
}
    80002622:	60e2                	ld	ra,24(sp)
    80002624:	6442                	ld	s0,16(sp)
    80002626:	64a2                	ld	s1,8(sp)
    80002628:	6105                	addi	sp,sp,32
    8000262a:	8082                	ret

000000008000262c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000262c:	1101                	addi	sp,sp,-32
    8000262e:	ec06                	sd	ra,24(sp)
    80002630:	e822                	sd	s0,16(sp)
    80002632:	e426                	sd	s1,8(sp)
    80002634:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002636:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000263a:	00074d63          	bltz	a4,80002654 <devintr+0x28>
      virtio_disk_intr(irq - VIRTIO0_IRQ);
    }

    plic_complete(irq);
    return 1;
  } else if(scause == 0x8000000000000001L){
    8000263e:	57fd                	li	a5,-1
    80002640:	17fe                	slli	a5,a5,0x3f
    80002642:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002644:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002646:	04f70b63          	beq	a4,a5,8000269c <devintr+0x70>
  }
}
    8000264a:	60e2                	ld	ra,24(sp)
    8000264c:	6442                	ld	s0,16(sp)
    8000264e:	64a2                	ld	s1,8(sp)
    80002650:	6105                	addi	sp,sp,32
    80002652:	8082                	ret
     (scause & 0xff) == 9){
    80002654:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002658:	46a5                	li	a3,9
    8000265a:	fed792e3          	bne	a5,a3,8000263e <devintr+0x12>
    int irq = plic_claim();
    8000265e:	00004097          	auipc	ra,0x4
    80002662:	abc080e7          	jalr	-1348(ra) # 8000611a <plic_claim>
    80002666:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002668:	47a9                	li	a5,10
    8000266a:	00f50e63          	beq	a0,a5,80002686 <devintr+0x5a>
    } else if(irq == VIRTIO0_IRQ || irq == VIRTIO1_IRQ ){
    8000266e:	fff5079b          	addiw	a5,a0,-1
    80002672:	4705                	li	a4,1
    80002674:	00f77e63          	bgeu	a4,a5,80002690 <devintr+0x64>
    plic_complete(irq);
    80002678:	8526                	mv	a0,s1
    8000267a:	00004097          	auipc	ra,0x4
    8000267e:	ac4080e7          	jalr	-1340(ra) # 8000613e <plic_complete>
    return 1;
    80002682:	4505                	li	a0,1
    80002684:	b7d9                	j	8000264a <devintr+0x1e>
      uartintr();
    80002686:	ffffe097          	auipc	ra,0xffffe
    8000268a:	1a2080e7          	jalr	418(ra) # 80000828 <uartintr>
    8000268e:	b7ed                	j	80002678 <devintr+0x4c>
      virtio_disk_intr(irq - VIRTIO0_IRQ);
    80002690:	853e                	mv	a0,a5
    80002692:	00004097          	auipc	ra,0x4
    80002696:	056080e7          	jalr	86(ra) # 800066e8 <virtio_disk_intr>
    8000269a:	bff9                	j	80002678 <devintr+0x4c>
    if(cpuid() == 0){
    8000269c:	fffff097          	auipc	ra,0xfffff
    800026a0:	242080e7          	jalr	578(ra) # 800018de <cpuid>
    800026a4:	c901                	beqz	a0,800026b4 <devintr+0x88>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800026a6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800026aa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800026ac:	14479073          	csrw	sip,a5
    return 2;
    800026b0:	4509                	li	a0,2
    800026b2:	bf61                	j	8000264a <devintr+0x1e>
      clockintr();
    800026b4:	00000097          	auipc	ra,0x0
    800026b8:	f32080e7          	jalr	-206(ra) # 800025e6 <clockintr>
    800026bc:	b7ed                	j	800026a6 <devintr+0x7a>

00000000800026be <usertrap>:
{
    800026be:	7179                	addi	sp,sp,-48
    800026c0:	f406                	sd	ra,40(sp)
    800026c2:	f022                	sd	s0,32(sp)
    800026c4:	ec26                	sd	s1,24(sp)
    800026c6:	e84a                	sd	s2,16(sp)
    800026c8:	e44e                	sd	s3,8(sp)
    800026ca:	e052                	sd	s4,0(sp)
    800026cc:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026ce:	100027f3          	csrr	a5,sstatus
    if ((r_sstatus() & SSTATUS_SPP) != 0)
    800026d2:	1007f793          	andi	a5,a5,256
    800026d6:	efc5                	bnez	a5,8000278e <usertrap+0xd0>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026d8:	00004797          	auipc	a5,0x4
    800026dc:	92878793          	addi	a5,a5,-1752 # 80006000 <kernelvec>
    800026e0:	10579073          	csrw	stvec,a5
    struct proc *p = myproc(); //myproc()函数获取当前进程的结构体，定义在proc.c中
    800026e4:	fffff097          	auipc	ra,0xfffff
    800026e8:	226080e7          	jalr	550(ra) # 8000190a <myproc>
    800026ec:	84aa                	mv	s1,a0
    p->tf->epc = r_sepc();
    800026ee:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800026f0:	14102773          	csrr	a4,sepc
    800026f4:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800026f6:	14202773          	csrr	a4,scause
    if (r_scause() == 8)
    800026fa:	47a1                	li	a5,8
    800026fc:	0af70163          	beq	a4,a5,8000279e <usertrap+0xe0>
    80002700:	14202773          	csrr	a4,scause
    else if (r_scause() == 13 || r_scause() == 15)
    80002704:	47b5                	li	a5,13
    80002706:	00f70763          	beq	a4,a5,80002714 <usertrap+0x56>
    8000270a:	14202773          	csrr	a4,scause
    8000270e:	47bd                	li	a5,15
    80002710:	12f71f63          	bne	a4,a5,8000284e <usertrap+0x190>
        pagetable_t cur_pagetable = p->pagetable;
    80002714:	0584ba03          	ld	s4,88(s1)
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002718:	14302973          	csrr	s2,stval
        uint64 fault_page = PGROUNDDOWN(fault_vaddr);
    8000271c:	79fd                	lui	s3,0xfffff
    8000271e:	013979b3          	and	s3,s2,s3
        if (fault_vaddr < p->stack_top && fault_vaddr >= p->stack_top - PGSIZE)
    80002722:	64bc                	ld	a5,72(s1)
    80002724:	00f97663          	bgeu	s2,a5,80002730 <usertrap+0x72>
    80002728:	777d                	lui	a4,0xfffff
    8000272a:	97ba                	add	a5,a5,a4
    8000272c:	0cf97163          	bgeu	s2,a5,800027ee <usertrap+0x130>
        if (fault_vaddr >= p->sz)
    80002730:	68bc                	ld	a5,80(s1)
    80002732:	0cf97e63          	bgeu	s2,a5,8000280e <usertrap+0x150>
            mem = kalloc(); //分配一个页的内存空间
    80002736:	ffffe097          	auipc	ra,0xffffe
    8000273a:	21a080e7          	jalr	538(ra) # 80000950 <kalloc>
    8000273e:	892a                	mv	s2,a0
            if (!mem)
    80002740:	c57d                	beqz	a0,8000282e <usertrap+0x170>
            memset(mem, 0, PGSIZE);
    80002742:	6605                	lui	a2,0x1
    80002744:	4581                	li	a1,0
    80002746:	854a                	mv	a0,s2
    80002748:	ffffe097          	auipc	ra,0xffffe
    8000274c:	43a080e7          	jalr	1082(ra) # 80000b82 <memset>
            if (mappages(cur_pagetable, fault_page, PGSIZE, (uint64)mem, PTE_W | PTE_X | PTE_R | PTE_U) != 0)
    80002750:	4779                	li	a4,30
    80002752:	86ca                	mv	a3,s2
    80002754:	6605                	lui	a2,0x1
    80002756:	85ce                	mv	a1,s3
    80002758:	8552                	mv	a0,s4
    8000275a:	fffff097          	auipc	ra,0xfffff
    8000275e:	8c2080e7          	jalr	-1854(ra) # 8000101c <mappages>
    80002762:	c525                	beqz	a0,800027ca <usertrap+0x10c>
                printf("usertrap():无法将一个物理页映射到页表中\n");
    80002764:	00006517          	auipc	a0,0x6
    80002768:	cc450513          	addi	a0,a0,-828 # 80008428 <userret+0x398>
    8000276c:	ffffe097          	auipc	ra,0xffffe
    80002770:	e26080e7          	jalr	-474(ra) # 80000592 <printf>
                kfree(mem);
    80002774:	854a                	mv	a0,s2
    80002776:	ffffe097          	auipc	ra,0xffffe
    8000277a:	0de080e7          	jalr	222(ra) # 80000854 <kfree>
                p->killed = 1;
    8000277e:	4785                	li	a5,1
    80002780:	d89c                	sw	a5,48(s1)
                exit(-1);
    80002782:	557d                	li	a0,-1
    80002784:	00000097          	auipc	ra,0x0
    80002788:	81a080e7          	jalr	-2022(ra) # 80001f9e <exit>
    if (which_dev == 2)
    8000278c:	a83d                	j	800027ca <usertrap+0x10c>
        panic("usertrap: not from user mode");
    8000278e:	00006517          	auipc	a0,0x6
    80002792:	bda50513          	addi	a0,a0,-1062 # 80008368 <userret+0x2d8>
    80002796:	ffffe097          	auipc	ra,0xffffe
    8000279a:	db2080e7          	jalr	-590(ra) # 80000548 <panic>
        if (p->killed) //杀死进程
    8000279e:	591c                	lw	a5,48(a0)
    800027a0:	e3a9                	bnez	a5,800027e2 <usertrap+0x124>
        p->tf->epc += 4;
    800027a2:	70b8                	ld	a4,96(s1)
    800027a4:	6f1c                	ld	a5,24(a4)
    800027a6:	0791                	addi	a5,a5,4
    800027a8:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sie" : "=r" (x) );
    800027aa:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800027ae:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800027b2:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027b6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800027ba:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027be:	10079073          	csrw	sstatus,a5
        syscall();
    800027c2:	00000097          	auipc	ra,0x0
    800027c6:	338080e7          	jalr	824(ra) # 80002afa <syscall>
    usertrapret();
    800027ca:	00000097          	auipc	ra,0x0
    800027ce:	d7e080e7          	jalr	-642(ra) # 80002548 <usertrapret>
}
    800027d2:	70a2                	ld	ra,40(sp)
    800027d4:	7402                	ld	s0,32(sp)
    800027d6:	64e2                	ld	s1,24(sp)
    800027d8:	6942                	ld	s2,16(sp)
    800027da:	69a2                	ld	s3,8(sp)
    800027dc:	6a02                	ld	s4,0(sp)
    800027de:	6145                	addi	sp,sp,48
    800027e0:	8082                	ret
            exit(-1);
    800027e2:	557d                	li	a0,-1
    800027e4:	fffff097          	auipc	ra,0xfffff
    800027e8:	7ba080e7          	jalr	1978(ra) # 80001f9e <exit>
    800027ec:	bf5d                	j	800027a2 <usertrap+0xe4>
            p->killed = 1;
    800027ee:	4785                	li	a5,1
    800027f0:	d89c                	sw	a5,48(s1)
            printf("usertrap(): 非法访问保护区，访问地址小于栈顶\n");
    800027f2:	00006517          	auipc	a0,0x6
    800027f6:	b9650513          	addi	a0,a0,-1130 # 80008388 <userret+0x2f8>
    800027fa:	ffffe097          	auipc	ra,0xffffe
    800027fe:	d98080e7          	jalr	-616(ra) # 80000592 <printf>
            exit(-1);
    80002802:	557d                	li	a0,-1
    80002804:	fffff097          	auipc	ra,0xfffff
    80002808:	79a080e7          	jalr	1946(ra) # 80001f9e <exit>
    8000280c:	b715                	j	80002730 <usertrap+0x72>
            p->killed = 1;
    8000280e:	4785                	li	a5,1
    80002810:	d89c                	sw	a5,48(s1)
            printf("usertrap(): 访问超出了线性地址的有效范围\n");
    80002812:	00006517          	auipc	a0,0x6
    80002816:	bb650513          	addi	a0,a0,-1098 # 800083c8 <userret+0x338>
    8000281a:	ffffe097          	auipc	ra,0xffffe
    8000281e:	d78080e7          	jalr	-648(ra) # 80000592 <printf>
            exit(-1);
    80002822:	557d                	li	a0,-1
    80002824:	fffff097          	auipc	ra,0xfffff
    80002828:	77a080e7          	jalr	1914(ra) # 80001f9e <exit>
    8000282c:	b729                	j	80002736 <usertrap+0x78>
                printf("usertrap():内存空间分配失败\n");
    8000282e:	00006517          	auipc	a0,0x6
    80002832:	bd250513          	addi	a0,a0,-1070 # 80008400 <userret+0x370>
    80002836:	ffffe097          	auipc	ra,0xffffe
    8000283a:	d5c080e7          	jalr	-676(ra) # 80000592 <printf>
                p->killed = 1;
    8000283e:	4785                	li	a5,1
    80002840:	d89c                	sw	a5,48(s1)
                exit(-1);
    80002842:	557d                	li	a0,-1
    80002844:	fffff097          	auipc	ra,0xfffff
    80002848:	75a080e7          	jalr	1882(ra) # 80001f9e <exit>
    8000284c:	bddd                	j	80002742 <usertrap+0x84>
    else if ((which_dev = devintr()) != 0)
    8000284e:	00000097          	auipc	ra,0x0
    80002852:	dde080e7          	jalr	-546(ra) # 8000262c <devintr>
    80002856:	892a                	mv	s2,a0
    80002858:	c10d                	beqz	a0,8000287a <usertrap+0x1bc>
        if (p->killed)
    8000285a:	589c                	lw	a5,48(s1)
    8000285c:	eb89                	bnez	a5,8000286e <usertrap+0x1b0>
    if (which_dev == 2)
    8000285e:	4789                	li	a5,2
    80002860:	f6f915e3          	bne	s2,a5,800027ca <usertrap+0x10c>
        yield();
    80002864:	00000097          	auipc	ra,0x0
    80002868:	848080e7          	jalr	-1976(ra) # 800020ac <yield>
    8000286c:	bfb9                	j	800027ca <usertrap+0x10c>
            exit(-1);
    8000286e:	557d                	li	a0,-1
    80002870:	fffff097          	auipc	ra,0xfffff
    80002874:	72e080e7          	jalr	1838(ra) # 80001f9e <exit>
    80002878:	b7dd                	j	8000285e <usertrap+0x1a0>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000287a:	142025f3          	csrr	a1,scause
        printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000287e:	5c90                	lw	a2,56(s1)
    80002880:	00006517          	auipc	a0,0x6
    80002884:	be050513          	addi	a0,a0,-1056 # 80008460 <userret+0x3d0>
    80002888:	ffffe097          	auipc	ra,0xffffe
    8000288c:	d0a080e7          	jalr	-758(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002890:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002894:	14302673          	csrr	a2,stval
        printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002898:	00006517          	auipc	a0,0x6
    8000289c:	bf850513          	addi	a0,a0,-1032 # 80008490 <userret+0x400>
    800028a0:	ffffe097          	auipc	ra,0xffffe
    800028a4:	cf2080e7          	jalr	-782(ra) # 80000592 <printf>
        p->killed = 1;
    800028a8:	4785                	li	a5,1
    800028aa:	d89c                	sw	a5,48(s1)
        exit(-1); //这里要加上exit(-1)否则出错
    800028ac:	557d                	li	a0,-1
    800028ae:	fffff097          	auipc	ra,0xfffff
    800028b2:	6f0080e7          	jalr	1776(ra) # 80001f9e <exit>
    if (which_dev == 2)
    800028b6:	bf11                	j	800027ca <usertrap+0x10c>

00000000800028b8 <kerneltrap>:
{
    800028b8:	7179                	addi	sp,sp,-48
    800028ba:	f406                	sd	ra,40(sp)
    800028bc:	f022                	sd	s0,32(sp)
    800028be:	ec26                	sd	s1,24(sp)
    800028c0:	e84a                	sd	s2,16(sp)
    800028c2:	e44e                	sd	s3,8(sp)
    800028c4:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028c6:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ca:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028ce:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800028d2:	1004f793          	andi	a5,s1,256
    800028d6:	cb85                	beqz	a5,80002906 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028d8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800028dc:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800028de:	ef85                	bnez	a5,80002916 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800028e0:	00000097          	auipc	ra,0x0
    800028e4:	d4c080e7          	jalr	-692(ra) # 8000262c <devintr>
    800028e8:	cd1d                	beqz	a0,80002926 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800028ea:	4789                	li	a5,2
    800028ec:	06f50a63          	beq	a0,a5,80002960 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028f0:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028f4:	10049073          	csrw	sstatus,s1
}
    800028f8:	70a2                	ld	ra,40(sp)
    800028fa:	7402                	ld	s0,32(sp)
    800028fc:	64e2                	ld	s1,24(sp)
    800028fe:	6942                	ld	s2,16(sp)
    80002900:	69a2                	ld	s3,8(sp)
    80002902:	6145                	addi	sp,sp,48
    80002904:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002906:	00006517          	auipc	a0,0x6
    8000290a:	baa50513          	addi	a0,a0,-1110 # 800084b0 <userret+0x420>
    8000290e:	ffffe097          	auipc	ra,0xffffe
    80002912:	c3a080e7          	jalr	-966(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002916:	00006517          	auipc	a0,0x6
    8000291a:	bc250513          	addi	a0,a0,-1086 # 800084d8 <userret+0x448>
    8000291e:	ffffe097          	auipc	ra,0xffffe
    80002922:	c2a080e7          	jalr	-982(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002926:	85ce                	mv	a1,s3
    80002928:	00006517          	auipc	a0,0x6
    8000292c:	bd050513          	addi	a0,a0,-1072 # 800084f8 <userret+0x468>
    80002930:	ffffe097          	auipc	ra,0xffffe
    80002934:	c62080e7          	jalr	-926(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002938:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000293c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002940:	00006517          	auipc	a0,0x6
    80002944:	bc850513          	addi	a0,a0,-1080 # 80008508 <userret+0x478>
    80002948:	ffffe097          	auipc	ra,0xffffe
    8000294c:	c4a080e7          	jalr	-950(ra) # 80000592 <printf>
    panic("kerneltrap");
    80002950:	00006517          	auipc	a0,0x6
    80002954:	bd050513          	addi	a0,a0,-1072 # 80008520 <userret+0x490>
    80002958:	ffffe097          	auipc	ra,0xffffe
    8000295c:	bf0080e7          	jalr	-1040(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002960:	fffff097          	auipc	ra,0xfffff
    80002964:	faa080e7          	jalr	-86(ra) # 8000190a <myproc>
    80002968:	d541                	beqz	a0,800028f0 <kerneltrap+0x38>
    8000296a:	fffff097          	auipc	ra,0xfffff
    8000296e:	fa0080e7          	jalr	-96(ra) # 8000190a <myproc>
    80002972:	4d18                	lw	a4,24(a0)
    80002974:	478d                	li	a5,3
    80002976:	f6f71de3          	bne	a4,a5,800028f0 <kerneltrap+0x38>
    yield();
    8000297a:	fffff097          	auipc	ra,0xfffff
    8000297e:	732080e7          	jalr	1842(ra) # 800020ac <yield>
    80002982:	b7bd                	j	800028f0 <kerneltrap+0x38>

0000000080002984 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002984:	1101                	addi	sp,sp,-32
    80002986:	ec06                	sd	ra,24(sp)
    80002988:	e822                	sd	s0,16(sp)
    8000298a:	e426                	sd	s1,8(sp)
    8000298c:	1000                	addi	s0,sp,32
    8000298e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002990:	fffff097          	auipc	ra,0xfffff
    80002994:	f7a080e7          	jalr	-134(ra) # 8000190a <myproc>
  switch (n) {
    80002998:	4795                	li	a5,5
    8000299a:	0497e163          	bltu	a5,s1,800029dc <argraw+0x58>
    8000299e:	048a                	slli	s1,s1,0x2
    800029a0:	00006717          	auipc	a4,0x6
    800029a4:	12070713          	addi	a4,a4,288 # 80008ac0 <states.0+0x28>
    800029a8:	94ba                	add	s1,s1,a4
    800029aa:	409c                	lw	a5,0(s1)
    800029ac:	97ba                	add	a5,a5,a4
    800029ae:	8782                	jr	a5
  case 0:
    return p->tf->a0;
    800029b0:	713c                	ld	a5,96(a0)
    800029b2:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->tf->a5;
  }
  panic("argraw");
  return -1;
}
    800029b4:	60e2                	ld	ra,24(sp)
    800029b6:	6442                	ld	s0,16(sp)
    800029b8:	64a2                	ld	s1,8(sp)
    800029ba:	6105                	addi	sp,sp,32
    800029bc:	8082                	ret
    return p->tf->a1;
    800029be:	713c                	ld	a5,96(a0)
    800029c0:	7fa8                	ld	a0,120(a5)
    800029c2:	bfcd                	j	800029b4 <argraw+0x30>
    return p->tf->a2;
    800029c4:	713c                	ld	a5,96(a0)
    800029c6:	63c8                	ld	a0,128(a5)
    800029c8:	b7f5                	j	800029b4 <argraw+0x30>
    return p->tf->a3;
    800029ca:	713c                	ld	a5,96(a0)
    800029cc:	67c8                	ld	a0,136(a5)
    800029ce:	b7dd                	j	800029b4 <argraw+0x30>
    return p->tf->a4;
    800029d0:	713c                	ld	a5,96(a0)
    800029d2:	6bc8                	ld	a0,144(a5)
    800029d4:	b7c5                	j	800029b4 <argraw+0x30>
    return p->tf->a5;
    800029d6:	713c                	ld	a5,96(a0)
    800029d8:	6fc8                	ld	a0,152(a5)
    800029da:	bfe9                	j	800029b4 <argraw+0x30>
  panic("argraw");
    800029dc:	00006517          	auipc	a0,0x6
    800029e0:	b5450513          	addi	a0,a0,-1196 # 80008530 <userret+0x4a0>
    800029e4:	ffffe097          	auipc	ra,0xffffe
    800029e8:	b64080e7          	jalr	-1180(ra) # 80000548 <panic>

00000000800029ec <fetchaddr>:
{
    800029ec:	1101                	addi	sp,sp,-32
    800029ee:	ec06                	sd	ra,24(sp)
    800029f0:	e822                	sd	s0,16(sp)
    800029f2:	e426                	sd	s1,8(sp)
    800029f4:	e04a                	sd	s2,0(sp)
    800029f6:	1000                	addi	s0,sp,32
    800029f8:	84aa                	mv	s1,a0
    800029fa:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800029fc:	fffff097          	auipc	ra,0xfffff
    80002a00:	f0e080e7          	jalr	-242(ra) # 8000190a <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002a04:	693c                	ld	a5,80(a0)
    80002a06:	02f4f863          	bgeu	s1,a5,80002a36 <fetchaddr+0x4a>
    80002a0a:	00848713          	addi	a4,s1,8
    80002a0e:	02e7e663          	bltu	a5,a4,80002a3a <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a12:	46a1                	li	a3,8
    80002a14:	8626                	mv	a2,s1
    80002a16:	85ca                	mv	a1,s2
    80002a18:	6d28                	ld	a0,88(a0)
    80002a1a:	fffff097          	auipc	ra,0xfffff
    80002a1e:	b82080e7          	jalr	-1150(ra) # 8000159c <copyin>
    80002a22:	00a03533          	snez	a0,a0
    80002a26:	40a00533          	neg	a0,a0
}
    80002a2a:	60e2                	ld	ra,24(sp)
    80002a2c:	6442                	ld	s0,16(sp)
    80002a2e:	64a2                	ld	s1,8(sp)
    80002a30:	6902                	ld	s2,0(sp)
    80002a32:	6105                	addi	sp,sp,32
    80002a34:	8082                	ret
    return -1;
    80002a36:	557d                	li	a0,-1
    80002a38:	bfcd                	j	80002a2a <fetchaddr+0x3e>
    80002a3a:	557d                	li	a0,-1
    80002a3c:	b7fd                	j	80002a2a <fetchaddr+0x3e>

0000000080002a3e <fetchstr>:
{
    80002a3e:	7179                	addi	sp,sp,-48
    80002a40:	f406                	sd	ra,40(sp)
    80002a42:	f022                	sd	s0,32(sp)
    80002a44:	ec26                	sd	s1,24(sp)
    80002a46:	e84a                	sd	s2,16(sp)
    80002a48:	e44e                	sd	s3,8(sp)
    80002a4a:	1800                	addi	s0,sp,48
    80002a4c:	892a                	mv	s2,a0
    80002a4e:	84ae                	mv	s1,a1
    80002a50:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a52:	fffff097          	auipc	ra,0xfffff
    80002a56:	eb8080e7          	jalr	-328(ra) # 8000190a <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002a5a:	86ce                	mv	a3,s3
    80002a5c:	864a                	mv	a2,s2
    80002a5e:	85a6                	mv	a1,s1
    80002a60:	6d28                	ld	a0,88(a0)
    80002a62:	fffff097          	auipc	ra,0xfffff
    80002a66:	bc8080e7          	jalr	-1080(ra) # 8000162a <copyinstr>
  if(err < 0)
    80002a6a:	00054763          	bltz	a0,80002a78 <fetchstr+0x3a>
  return strlen(buf);
    80002a6e:	8526                	mv	a0,s1
    80002a70:	ffffe097          	auipc	ra,0xffffe
    80002a74:	296080e7          	jalr	662(ra) # 80000d06 <strlen>
}
    80002a78:	70a2                	ld	ra,40(sp)
    80002a7a:	7402                	ld	s0,32(sp)
    80002a7c:	64e2                	ld	s1,24(sp)
    80002a7e:	6942                	ld	s2,16(sp)
    80002a80:	69a2                	ld	s3,8(sp)
    80002a82:	6145                	addi	sp,sp,48
    80002a84:	8082                	ret

0000000080002a86 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002a86:	1101                	addi	sp,sp,-32
    80002a88:	ec06                	sd	ra,24(sp)
    80002a8a:	e822                	sd	s0,16(sp)
    80002a8c:	e426                	sd	s1,8(sp)
    80002a8e:	1000                	addi	s0,sp,32
    80002a90:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a92:	00000097          	auipc	ra,0x0
    80002a96:	ef2080e7          	jalr	-270(ra) # 80002984 <argraw>
    80002a9a:	c088                	sw	a0,0(s1)
  return 0;
}
    80002a9c:	4501                	li	a0,0
    80002a9e:	60e2                	ld	ra,24(sp)
    80002aa0:	6442                	ld	s0,16(sp)
    80002aa2:	64a2                	ld	s1,8(sp)
    80002aa4:	6105                	addi	sp,sp,32
    80002aa6:	8082                	ret

0000000080002aa8 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002aa8:	1101                	addi	sp,sp,-32
    80002aaa:	ec06                	sd	ra,24(sp)
    80002aac:	e822                	sd	s0,16(sp)
    80002aae:	e426                	sd	s1,8(sp)
    80002ab0:	1000                	addi	s0,sp,32
    80002ab2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ab4:	00000097          	auipc	ra,0x0
    80002ab8:	ed0080e7          	jalr	-304(ra) # 80002984 <argraw>
    80002abc:	e088                	sd	a0,0(s1)
  return 0;
}
    80002abe:	4501                	li	a0,0
    80002ac0:	60e2                	ld	ra,24(sp)
    80002ac2:	6442                	ld	s0,16(sp)
    80002ac4:	64a2                	ld	s1,8(sp)
    80002ac6:	6105                	addi	sp,sp,32
    80002ac8:	8082                	ret

0000000080002aca <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002aca:	1101                	addi	sp,sp,-32
    80002acc:	ec06                	sd	ra,24(sp)
    80002ace:	e822                	sd	s0,16(sp)
    80002ad0:	e426                	sd	s1,8(sp)
    80002ad2:	e04a                	sd	s2,0(sp)
    80002ad4:	1000                	addi	s0,sp,32
    80002ad6:	84ae                	mv	s1,a1
    80002ad8:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002ada:	00000097          	auipc	ra,0x0
    80002ade:	eaa080e7          	jalr	-342(ra) # 80002984 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002ae2:	864a                	mv	a2,s2
    80002ae4:	85a6                	mv	a1,s1
    80002ae6:	00000097          	auipc	ra,0x0
    80002aea:	f58080e7          	jalr	-168(ra) # 80002a3e <fetchstr>
}
    80002aee:	60e2                	ld	ra,24(sp)
    80002af0:	6442                	ld	s0,16(sp)
    80002af2:	64a2                	ld	s1,8(sp)
    80002af4:	6902                	ld	s2,0(sp)
    80002af6:	6105                	addi	sp,sp,32
    80002af8:	8082                	ret

0000000080002afa <syscall>:
[SYS_crash]   sys_crash,
};

void
syscall(void)
{
    80002afa:	1101                	addi	sp,sp,-32
    80002afc:	ec06                	sd	ra,24(sp)
    80002afe:	e822                	sd	s0,16(sp)
    80002b00:	e426                	sd	s1,8(sp)
    80002b02:	e04a                	sd	s2,0(sp)
    80002b04:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002b06:	fffff097          	auipc	ra,0xfffff
    80002b0a:	e04080e7          	jalr	-508(ra) # 8000190a <myproc>
    80002b0e:	84aa                	mv	s1,a0

  num = p->tf->a7;
    80002b10:	06053903          	ld	s2,96(a0)
    80002b14:	0a893783          	ld	a5,168(s2)
    80002b18:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b1c:	37fd                	addiw	a5,a5,-1
    80002b1e:	4759                	li	a4,22
    80002b20:	00f76f63          	bltu	a4,a5,80002b3e <syscall+0x44>
    80002b24:	00369713          	slli	a4,a3,0x3
    80002b28:	00006797          	auipc	a5,0x6
    80002b2c:	fb078793          	addi	a5,a5,-80 # 80008ad8 <syscalls>
    80002b30:	97ba                	add	a5,a5,a4
    80002b32:	639c                	ld	a5,0(a5)
    80002b34:	c789                	beqz	a5,80002b3e <syscall+0x44>
    p->tf->a0 = syscalls[num]();
    80002b36:	9782                	jalr	a5
    80002b38:	06a93823          	sd	a0,112(s2)
    80002b3c:	a839                	j	80002b5a <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b3e:	16048613          	addi	a2,s1,352
    80002b42:	5c8c                	lw	a1,56(s1)
    80002b44:	00006517          	auipc	a0,0x6
    80002b48:	9f450513          	addi	a0,a0,-1548 # 80008538 <userret+0x4a8>
    80002b4c:	ffffe097          	auipc	ra,0xffffe
    80002b50:	a46080e7          	jalr	-1466(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->tf->a0 = -1;
    80002b54:	70bc                	ld	a5,96(s1)
    80002b56:	577d                	li	a4,-1
    80002b58:	fbb8                	sd	a4,112(a5)
  }
}
    80002b5a:	60e2                	ld	ra,24(sp)
    80002b5c:	6442                	ld	s0,16(sp)
    80002b5e:	64a2                	ld	s1,8(sp)
    80002b60:	6902                	ld	s2,0(sp)
    80002b62:	6105                	addi	sp,sp,32
    80002b64:	8082                	ret

0000000080002b66 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002b66:	1101                	addi	sp,sp,-32
    80002b68:	ec06                	sd	ra,24(sp)
    80002b6a:	e822                	sd	s0,16(sp)
    80002b6c:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002b6e:	fec40593          	addi	a1,s0,-20
    80002b72:	4501                	li	a0,0
    80002b74:	00000097          	auipc	ra,0x0
    80002b78:	f12080e7          	jalr	-238(ra) # 80002a86 <argint>
    return -1;
    80002b7c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002b7e:	00054963          	bltz	a0,80002b90 <sys_exit+0x2a>
  exit(n);
    80002b82:	fec42503          	lw	a0,-20(s0)
    80002b86:	fffff097          	auipc	ra,0xfffff
    80002b8a:	418080e7          	jalr	1048(ra) # 80001f9e <exit>
  return 0;  // not reached
    80002b8e:	4781                	li	a5,0
}
    80002b90:	853e                	mv	a0,a5
    80002b92:	60e2                	ld	ra,24(sp)
    80002b94:	6442                	ld	s0,16(sp)
    80002b96:	6105                	addi	sp,sp,32
    80002b98:	8082                	ret

0000000080002b9a <sys_getpid>:

uint64
sys_getpid(void)
{
    80002b9a:	1141                	addi	sp,sp,-16
    80002b9c:	e406                	sd	ra,8(sp)
    80002b9e:	e022                	sd	s0,0(sp)
    80002ba0:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002ba2:	fffff097          	auipc	ra,0xfffff
    80002ba6:	d68080e7          	jalr	-664(ra) # 8000190a <myproc>
}
    80002baa:	5d08                	lw	a0,56(a0)
    80002bac:	60a2                	ld	ra,8(sp)
    80002bae:	6402                	ld	s0,0(sp)
    80002bb0:	0141                	addi	sp,sp,16
    80002bb2:	8082                	ret

0000000080002bb4 <sys_fork>:

uint64
sys_fork(void)
{
    80002bb4:	1141                	addi	sp,sp,-16
    80002bb6:	e406                	sd	ra,8(sp)
    80002bb8:	e022                	sd	s0,0(sp)
    80002bba:	0800                	addi	s0,sp,16
  return fork();
    80002bbc:	fffff097          	auipc	ra,0xfffff
    80002bc0:	0b8080e7          	jalr	184(ra) # 80001c74 <fork>
}
    80002bc4:	60a2                	ld	ra,8(sp)
    80002bc6:	6402                	ld	s0,0(sp)
    80002bc8:	0141                	addi	sp,sp,16
    80002bca:	8082                	ret

0000000080002bcc <sys_wait>:

uint64
sys_wait(void)
{
    80002bcc:	1101                	addi	sp,sp,-32
    80002bce:	ec06                	sd	ra,24(sp)
    80002bd0:	e822                	sd	s0,16(sp)
    80002bd2:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002bd4:	fe840593          	addi	a1,s0,-24
    80002bd8:	4501                	li	a0,0
    80002bda:	00000097          	auipc	ra,0x0
    80002bde:	ece080e7          	jalr	-306(ra) # 80002aa8 <argaddr>
    80002be2:	87aa                	mv	a5,a0
    return -1;
    80002be4:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002be6:	0007c863          	bltz	a5,80002bf6 <sys_wait+0x2a>
  return wait(p);
    80002bea:	fe843503          	ld	a0,-24(s0)
    80002bee:	fffff097          	auipc	ra,0xfffff
    80002bf2:	578080e7          	jalr	1400(ra) # 80002166 <wait>
}
    80002bf6:	60e2                	ld	ra,24(sp)
    80002bf8:	6442                	ld	s0,16(sp)
    80002bfa:	6105                	addi	sp,sp,32
    80002bfc:	8082                	ret

0000000080002bfe <sys_sbrk>:


uint64
sys_sbrk(void)
{
    80002bfe:	7179                	addi	sp,sp,-48
    80002c00:	f406                	sd	ra,40(sp)
    80002c02:	f022                	sd	s0,32(sp)
    80002c04:	ec26                	sd	s1,24(sp)
    80002c06:	e84a                	sd	s2,16(sp)
    80002c08:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;
  struct proc *p = myproc();
    80002c0a:	fffff097          	auipc	ra,0xfffff
    80002c0e:	d00080e7          	jalr	-768(ra) # 8000190a <myproc>
    80002c12:	84aa                	mv	s1,a0
  if(argint(0, &n) < 0)
    80002c14:	fdc40593          	addi	a1,s0,-36
    80002c18:	4501                	li	a0,0
    80002c1a:	00000097          	auipc	ra,0x0
    80002c1e:	e6c080e7          	jalr	-404(ra) # 80002a86 <argint>
    80002c22:	04054063          	bltz	a0,80002c62 <sys_sbrk+0x64>
    return -1;
  addr = p->sz;  //获得旧的大小
    80002c26:	0504b903          	ld	s2,80(s1)
  if(addr + n > MAXVA)
    80002c2a:	fdc42703          	lw	a4,-36(s0)
    80002c2e:	01270633          	add	a2,a4,s2
    80002c32:	4785                	li	a5,1
    80002c34:	179a                	slli	a5,a5,0x26
    80002c36:	02c7e863          	bltu	a5,a2,80002c66 <sys_sbrk+0x68>
    return -1;
  // if(growproc(n) < 0)
  //   return -1;
  if(n < 0){  //sbrk()输入参数为负数时，进程归还大小为n的线性地址空间。通过uvmdealloc释放。
    80002c3a:	00074d63          	bltz	a4,80002c54 <sys_sbrk+0x56>
    uvmdealloc(p->pagetable, addr, addr + n);  
  }
  p->sz = addr + n;  //进程大小增加n
    80002c3e:	fdc42783          	lw	a5,-36(s0)
    80002c42:	97ca                	add	a5,a5,s2
    80002c44:	e8bc                	sd	a5,80(s1)
  return addr;
}
    80002c46:	854a                	mv	a0,s2
    80002c48:	70a2                	ld	ra,40(sp)
    80002c4a:	7402                	ld	s0,32(sp)
    80002c4c:	64e2                	ld	s1,24(sp)
    80002c4e:	6942                	ld	s2,16(sp)
    80002c50:	6145                	addi	sp,sp,48
    80002c52:	8082                	ret
    uvmdealloc(p->pagetable, addr, addr + n);  
    80002c54:	85ca                	mv	a1,s2
    80002c56:	6ca8                	ld	a0,88(s1)
    80002c58:	ffffe097          	auipc	ra,0xffffe
    80002c5c:	6b6080e7          	jalr	1718(ra) # 8000130e <uvmdealloc>
    80002c60:	bff9                	j	80002c3e <sys_sbrk+0x40>
    return -1;
    80002c62:	597d                	li	s2,-1
    80002c64:	b7cd                	j	80002c46 <sys_sbrk+0x48>
    return -1;
    80002c66:	597d                	li	s2,-1
    80002c68:	bff9                	j	80002c46 <sys_sbrk+0x48>

0000000080002c6a <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c6a:	7139                	addi	sp,sp,-64
    80002c6c:	fc06                	sd	ra,56(sp)
    80002c6e:	f822                	sd	s0,48(sp)
    80002c70:	f426                	sd	s1,40(sp)
    80002c72:	f04a                	sd	s2,32(sp)
    80002c74:	ec4e                	sd	s3,24(sp)
    80002c76:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002c78:	fcc40593          	addi	a1,s0,-52
    80002c7c:	4501                	li	a0,0
    80002c7e:	00000097          	auipc	ra,0x0
    80002c82:	e08080e7          	jalr	-504(ra) # 80002a86 <argint>
    return -1;
    80002c86:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c88:	06054563          	bltz	a0,80002cf2 <sys_sleep+0x88>
  acquire(&tickslock);
    80002c8c:	00016517          	auipc	a0,0x16
    80002c90:	c7450513          	addi	a0,a0,-908 # 80018900 <tickslock>
    80002c94:	ffffe097          	auipc	ra,0xffffe
    80002c98:	e2a080e7          	jalr	-470(ra) # 80000abe <acquire>
  ticks0 = ticks;
    80002c9c:	00027917          	auipc	s2,0x27
    80002ca0:	3a492903          	lw	s2,932(s2) # 8002a040 <ticks>
  while(ticks - ticks0 < n){
    80002ca4:	fcc42783          	lw	a5,-52(s0)
    80002ca8:	cf85                	beqz	a5,80002ce0 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002caa:	00016997          	auipc	s3,0x16
    80002cae:	c5698993          	addi	s3,s3,-938 # 80018900 <tickslock>
    80002cb2:	00027497          	auipc	s1,0x27
    80002cb6:	38e48493          	addi	s1,s1,910 # 8002a040 <ticks>
    if(myproc()->killed){
    80002cba:	fffff097          	auipc	ra,0xfffff
    80002cbe:	c50080e7          	jalr	-944(ra) # 8000190a <myproc>
    80002cc2:	591c                	lw	a5,48(a0)
    80002cc4:	ef9d                	bnez	a5,80002d02 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002cc6:	85ce                	mv	a1,s3
    80002cc8:	8526                	mv	a0,s1
    80002cca:	fffff097          	auipc	ra,0xfffff
    80002cce:	41e080e7          	jalr	1054(ra) # 800020e8 <sleep>
  while(ticks - ticks0 < n){
    80002cd2:	409c                	lw	a5,0(s1)
    80002cd4:	412787bb          	subw	a5,a5,s2
    80002cd8:	fcc42703          	lw	a4,-52(s0)
    80002cdc:	fce7efe3          	bltu	a5,a4,80002cba <sys_sleep+0x50>
  }
  release(&tickslock);
    80002ce0:	00016517          	auipc	a0,0x16
    80002ce4:	c2050513          	addi	a0,a0,-992 # 80018900 <tickslock>
    80002ce8:	ffffe097          	auipc	ra,0xffffe
    80002cec:	e3e080e7          	jalr	-450(ra) # 80000b26 <release>
  return 0;
    80002cf0:	4781                	li	a5,0
}
    80002cf2:	853e                	mv	a0,a5
    80002cf4:	70e2                	ld	ra,56(sp)
    80002cf6:	7442                	ld	s0,48(sp)
    80002cf8:	74a2                	ld	s1,40(sp)
    80002cfa:	7902                	ld	s2,32(sp)
    80002cfc:	69e2                	ld	s3,24(sp)
    80002cfe:	6121                	addi	sp,sp,64
    80002d00:	8082                	ret
      release(&tickslock);
    80002d02:	00016517          	auipc	a0,0x16
    80002d06:	bfe50513          	addi	a0,a0,-1026 # 80018900 <tickslock>
    80002d0a:	ffffe097          	auipc	ra,0xffffe
    80002d0e:	e1c080e7          	jalr	-484(ra) # 80000b26 <release>
      return -1;
    80002d12:	57fd                	li	a5,-1
    80002d14:	bff9                	j	80002cf2 <sys_sleep+0x88>

0000000080002d16 <sys_kill>:

uint64
sys_kill(void)
{
    80002d16:	1101                	addi	sp,sp,-32
    80002d18:	ec06                	sd	ra,24(sp)
    80002d1a:	e822                	sd	s0,16(sp)
    80002d1c:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002d1e:	fec40593          	addi	a1,s0,-20
    80002d22:	4501                	li	a0,0
    80002d24:	00000097          	auipc	ra,0x0
    80002d28:	d62080e7          	jalr	-670(ra) # 80002a86 <argint>
    80002d2c:	87aa                	mv	a5,a0
    return -1;
    80002d2e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002d30:	0007c863          	bltz	a5,80002d40 <sys_kill+0x2a>
  return kill(pid);
    80002d34:	fec42503          	lw	a0,-20(s0)
    80002d38:	fffff097          	auipc	ra,0xfffff
    80002d3c:	59a080e7          	jalr	1434(ra) # 800022d2 <kill>
}
    80002d40:	60e2                	ld	ra,24(sp)
    80002d42:	6442                	ld	s0,16(sp)
    80002d44:	6105                	addi	sp,sp,32
    80002d46:	8082                	ret

0000000080002d48 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d48:	1101                	addi	sp,sp,-32
    80002d4a:	ec06                	sd	ra,24(sp)
    80002d4c:	e822                	sd	s0,16(sp)
    80002d4e:	e426                	sd	s1,8(sp)
    80002d50:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d52:	00016517          	auipc	a0,0x16
    80002d56:	bae50513          	addi	a0,a0,-1106 # 80018900 <tickslock>
    80002d5a:	ffffe097          	auipc	ra,0xffffe
    80002d5e:	d64080e7          	jalr	-668(ra) # 80000abe <acquire>
  xticks = ticks;
    80002d62:	00027497          	auipc	s1,0x27
    80002d66:	2de4a483          	lw	s1,734(s1) # 8002a040 <ticks>
  release(&tickslock);
    80002d6a:	00016517          	auipc	a0,0x16
    80002d6e:	b9650513          	addi	a0,a0,-1130 # 80018900 <tickslock>
    80002d72:	ffffe097          	auipc	ra,0xffffe
    80002d76:	db4080e7          	jalr	-588(ra) # 80000b26 <release>
  return xticks;
}
    80002d7a:	02049513          	slli	a0,s1,0x20
    80002d7e:	9101                	srli	a0,a0,0x20
    80002d80:	60e2                	ld	ra,24(sp)
    80002d82:	6442                	ld	s0,16(sp)
    80002d84:	64a2                	ld	s1,8(sp)
    80002d86:	6105                	addi	sp,sp,32
    80002d88:	8082                	ret

0000000080002d8a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002d8a:	7179                	addi	sp,sp,-48
    80002d8c:	f406                	sd	ra,40(sp)
    80002d8e:	f022                	sd	s0,32(sp)
    80002d90:	ec26                	sd	s1,24(sp)
    80002d92:	e84a                	sd	s2,16(sp)
    80002d94:	e44e                	sd	s3,8(sp)
    80002d96:	e052                	sd	s4,0(sp)
    80002d98:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002d9a:	00005597          	auipc	a1,0x5
    80002d9e:	7be58593          	addi	a1,a1,1982 # 80008558 <userret+0x4c8>
    80002da2:	00016517          	auipc	a0,0x16
    80002da6:	b7650513          	addi	a0,a0,-1162 # 80018918 <bcache>
    80002daa:	ffffe097          	auipc	ra,0xffffe
    80002dae:	c06080e7          	jalr	-1018(ra) # 800009b0 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002db2:	0001e797          	auipc	a5,0x1e
    80002db6:	b6678793          	addi	a5,a5,-1178 # 80020918 <bcache+0x8000>
    80002dba:	0001e717          	auipc	a4,0x1e
    80002dbe:	eb670713          	addi	a4,a4,-330 # 80020c70 <bcache+0x8358>
    80002dc2:	3ae7b023          	sd	a4,928(a5)
  bcache.head.next = &bcache.head;
    80002dc6:	3ae7b423          	sd	a4,936(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002dca:	00016497          	auipc	s1,0x16
    80002dce:	b6648493          	addi	s1,s1,-1178 # 80018930 <bcache+0x18>
    b->next = bcache.head.next;
    80002dd2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002dd4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002dd6:	00005a17          	auipc	s4,0x5
    80002dda:	78aa0a13          	addi	s4,s4,1930 # 80008560 <userret+0x4d0>
    b->next = bcache.head.next;
    80002dde:	3a893783          	ld	a5,936(s2)
    80002de2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002de4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002de8:	85d2                	mv	a1,s4
    80002dea:	01048513          	addi	a0,s1,16
    80002dee:	00001097          	auipc	ra,0x1
    80002df2:	6f4080e7          	jalr	1780(ra) # 800044e2 <initsleeplock>
    bcache.head.next->prev = b;
    80002df6:	3a893783          	ld	a5,936(s2)
    80002dfa:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002dfc:	3a993423          	sd	s1,936(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e00:	46048493          	addi	s1,s1,1120
    80002e04:	fd349de3          	bne	s1,s3,80002dde <binit+0x54>
  }
}
    80002e08:	70a2                	ld	ra,40(sp)
    80002e0a:	7402                	ld	s0,32(sp)
    80002e0c:	64e2                	ld	s1,24(sp)
    80002e0e:	6942                	ld	s2,16(sp)
    80002e10:	69a2                	ld	s3,8(sp)
    80002e12:	6a02                	ld	s4,0(sp)
    80002e14:	6145                	addi	sp,sp,48
    80002e16:	8082                	ret

0000000080002e18 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e18:	7179                	addi	sp,sp,-48
    80002e1a:	f406                	sd	ra,40(sp)
    80002e1c:	f022                	sd	s0,32(sp)
    80002e1e:	ec26                	sd	s1,24(sp)
    80002e20:	e84a                	sd	s2,16(sp)
    80002e22:	e44e                	sd	s3,8(sp)
    80002e24:	1800                	addi	s0,sp,48
    80002e26:	892a                	mv	s2,a0
    80002e28:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002e2a:	00016517          	auipc	a0,0x16
    80002e2e:	aee50513          	addi	a0,a0,-1298 # 80018918 <bcache>
    80002e32:	ffffe097          	auipc	ra,0xffffe
    80002e36:	c8c080e7          	jalr	-884(ra) # 80000abe <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e3a:	0001e497          	auipc	s1,0x1e
    80002e3e:	e864b483          	ld	s1,-378(s1) # 80020cc0 <bcache+0x83a8>
    80002e42:	0001e797          	auipc	a5,0x1e
    80002e46:	e2e78793          	addi	a5,a5,-466 # 80020c70 <bcache+0x8358>
    80002e4a:	02f48f63          	beq	s1,a5,80002e88 <bread+0x70>
    80002e4e:	873e                	mv	a4,a5
    80002e50:	a021                	j	80002e58 <bread+0x40>
    80002e52:	68a4                	ld	s1,80(s1)
    80002e54:	02e48a63          	beq	s1,a4,80002e88 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002e58:	449c                	lw	a5,8(s1)
    80002e5a:	ff279ce3          	bne	a5,s2,80002e52 <bread+0x3a>
    80002e5e:	44dc                	lw	a5,12(s1)
    80002e60:	ff3799e3          	bne	a5,s3,80002e52 <bread+0x3a>
      b->refcnt++;
    80002e64:	40bc                	lw	a5,64(s1)
    80002e66:	2785                	addiw	a5,a5,1
    80002e68:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e6a:	00016517          	auipc	a0,0x16
    80002e6e:	aae50513          	addi	a0,a0,-1362 # 80018918 <bcache>
    80002e72:	ffffe097          	auipc	ra,0xffffe
    80002e76:	cb4080e7          	jalr	-844(ra) # 80000b26 <release>
      acquiresleep(&b->lock);
    80002e7a:	01048513          	addi	a0,s1,16
    80002e7e:	00001097          	auipc	ra,0x1
    80002e82:	69e080e7          	jalr	1694(ra) # 8000451c <acquiresleep>
      return b;
    80002e86:	a8b9                	j	80002ee4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e88:	0001e497          	auipc	s1,0x1e
    80002e8c:	e304b483          	ld	s1,-464(s1) # 80020cb8 <bcache+0x83a0>
    80002e90:	0001e797          	auipc	a5,0x1e
    80002e94:	de078793          	addi	a5,a5,-544 # 80020c70 <bcache+0x8358>
    80002e98:	00f48863          	beq	s1,a5,80002ea8 <bread+0x90>
    80002e9c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002e9e:	40bc                	lw	a5,64(s1)
    80002ea0:	cf81                	beqz	a5,80002eb8 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ea2:	64a4                	ld	s1,72(s1)
    80002ea4:	fee49de3          	bne	s1,a4,80002e9e <bread+0x86>
  panic("bget: no buffers");
    80002ea8:	00005517          	auipc	a0,0x5
    80002eac:	6c050513          	addi	a0,a0,1728 # 80008568 <userret+0x4d8>
    80002eb0:	ffffd097          	auipc	ra,0xffffd
    80002eb4:	698080e7          	jalr	1688(ra) # 80000548 <panic>
      b->dev = dev;
    80002eb8:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002ebc:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002ec0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002ec4:	4785                	li	a5,1
    80002ec6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ec8:	00016517          	auipc	a0,0x16
    80002ecc:	a5050513          	addi	a0,a0,-1456 # 80018918 <bcache>
    80002ed0:	ffffe097          	auipc	ra,0xffffe
    80002ed4:	c56080e7          	jalr	-938(ra) # 80000b26 <release>
      acquiresleep(&b->lock);
    80002ed8:	01048513          	addi	a0,s1,16
    80002edc:	00001097          	auipc	ra,0x1
    80002ee0:	640080e7          	jalr	1600(ra) # 8000451c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002ee4:	409c                	lw	a5,0(s1)
    80002ee6:	cb89                	beqz	a5,80002ef8 <bread+0xe0>
    virtio_disk_rw(b->dev, b, 0);
    b->valid = 1;
  }
  return b;
}
    80002ee8:	8526                	mv	a0,s1
    80002eea:	70a2                	ld	ra,40(sp)
    80002eec:	7402                	ld	s0,32(sp)
    80002eee:	64e2                	ld	s1,24(sp)
    80002ef0:	6942                	ld	s2,16(sp)
    80002ef2:	69a2                	ld	s3,8(sp)
    80002ef4:	6145                	addi	sp,sp,48
    80002ef6:	8082                	ret
    virtio_disk_rw(b->dev, b, 0);
    80002ef8:	4601                	li	a2,0
    80002efa:	85a6                	mv	a1,s1
    80002efc:	4488                	lw	a0,8(s1)
    80002efe:	00003097          	auipc	ra,0x3
    80002f02:	4ee080e7          	jalr	1262(ra) # 800063ec <virtio_disk_rw>
    b->valid = 1;
    80002f06:	4785                	li	a5,1
    80002f08:	c09c                	sw	a5,0(s1)
  return b;
    80002f0a:	bff9                	j	80002ee8 <bread+0xd0>

0000000080002f0c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f0c:	1101                	addi	sp,sp,-32
    80002f0e:	ec06                	sd	ra,24(sp)
    80002f10:	e822                	sd	s0,16(sp)
    80002f12:	e426                	sd	s1,8(sp)
    80002f14:	1000                	addi	s0,sp,32
    80002f16:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f18:	0541                	addi	a0,a0,16
    80002f1a:	00001097          	auipc	ra,0x1
    80002f1e:	69c080e7          	jalr	1692(ra) # 800045b6 <holdingsleep>
    80002f22:	cd09                	beqz	a0,80002f3c <bwrite+0x30>
    panic("bwrite");
  virtio_disk_rw(b->dev, b, 1);
    80002f24:	4605                	li	a2,1
    80002f26:	85a6                	mv	a1,s1
    80002f28:	4488                	lw	a0,8(s1)
    80002f2a:	00003097          	auipc	ra,0x3
    80002f2e:	4c2080e7          	jalr	1218(ra) # 800063ec <virtio_disk_rw>
}
    80002f32:	60e2                	ld	ra,24(sp)
    80002f34:	6442                	ld	s0,16(sp)
    80002f36:	64a2                	ld	s1,8(sp)
    80002f38:	6105                	addi	sp,sp,32
    80002f3a:	8082                	ret
    panic("bwrite");
    80002f3c:	00005517          	auipc	a0,0x5
    80002f40:	64450513          	addi	a0,a0,1604 # 80008580 <userret+0x4f0>
    80002f44:	ffffd097          	auipc	ra,0xffffd
    80002f48:	604080e7          	jalr	1540(ra) # 80000548 <panic>

0000000080002f4c <brelse>:

// Release a locked buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
    80002f4c:	1101                	addi	sp,sp,-32
    80002f4e:	ec06                	sd	ra,24(sp)
    80002f50:	e822                	sd	s0,16(sp)
    80002f52:	e426                	sd	s1,8(sp)
    80002f54:	e04a                	sd	s2,0(sp)
    80002f56:	1000                	addi	s0,sp,32
    80002f58:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f5a:	01050913          	addi	s2,a0,16
    80002f5e:	854a                	mv	a0,s2
    80002f60:	00001097          	auipc	ra,0x1
    80002f64:	656080e7          	jalr	1622(ra) # 800045b6 <holdingsleep>
    80002f68:	c92d                	beqz	a0,80002fda <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002f6a:	854a                	mv	a0,s2
    80002f6c:	00001097          	auipc	ra,0x1
    80002f70:	606080e7          	jalr	1542(ra) # 80004572 <releasesleep>

  acquire(&bcache.lock);
    80002f74:	00016517          	auipc	a0,0x16
    80002f78:	9a450513          	addi	a0,a0,-1628 # 80018918 <bcache>
    80002f7c:	ffffe097          	auipc	ra,0xffffe
    80002f80:	b42080e7          	jalr	-1214(ra) # 80000abe <acquire>
  b->refcnt--;
    80002f84:	40bc                	lw	a5,64(s1)
    80002f86:	37fd                	addiw	a5,a5,-1
    80002f88:	0007871b          	sext.w	a4,a5
    80002f8c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002f8e:	eb05                	bnez	a4,80002fbe <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002f90:	68bc                	ld	a5,80(s1)
    80002f92:	64b8                	ld	a4,72(s1)
    80002f94:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002f96:	64bc                	ld	a5,72(s1)
    80002f98:	68b8                	ld	a4,80(s1)
    80002f9a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002f9c:	0001e797          	auipc	a5,0x1e
    80002fa0:	97c78793          	addi	a5,a5,-1668 # 80020918 <bcache+0x8000>
    80002fa4:	3a87b703          	ld	a4,936(a5)
    80002fa8:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002faa:	0001e717          	auipc	a4,0x1e
    80002fae:	cc670713          	addi	a4,a4,-826 # 80020c70 <bcache+0x8358>
    80002fb2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002fb4:	3a87b703          	ld	a4,936(a5)
    80002fb8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002fba:	3a97b423          	sd	s1,936(a5)
  }
  
  release(&bcache.lock);
    80002fbe:	00016517          	auipc	a0,0x16
    80002fc2:	95a50513          	addi	a0,a0,-1702 # 80018918 <bcache>
    80002fc6:	ffffe097          	auipc	ra,0xffffe
    80002fca:	b60080e7          	jalr	-1184(ra) # 80000b26 <release>
}
    80002fce:	60e2                	ld	ra,24(sp)
    80002fd0:	6442                	ld	s0,16(sp)
    80002fd2:	64a2                	ld	s1,8(sp)
    80002fd4:	6902                	ld	s2,0(sp)
    80002fd6:	6105                	addi	sp,sp,32
    80002fd8:	8082                	ret
    panic("brelse");
    80002fda:	00005517          	auipc	a0,0x5
    80002fde:	5ae50513          	addi	a0,a0,1454 # 80008588 <userret+0x4f8>
    80002fe2:	ffffd097          	auipc	ra,0xffffd
    80002fe6:	566080e7          	jalr	1382(ra) # 80000548 <panic>

0000000080002fea <bpin>:

void
bpin(struct buf *b) {
    80002fea:	1101                	addi	sp,sp,-32
    80002fec:	ec06                	sd	ra,24(sp)
    80002fee:	e822                	sd	s0,16(sp)
    80002ff0:	e426                	sd	s1,8(sp)
    80002ff2:	1000                	addi	s0,sp,32
    80002ff4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002ff6:	00016517          	auipc	a0,0x16
    80002ffa:	92250513          	addi	a0,a0,-1758 # 80018918 <bcache>
    80002ffe:	ffffe097          	auipc	ra,0xffffe
    80003002:	ac0080e7          	jalr	-1344(ra) # 80000abe <acquire>
  b->refcnt++;
    80003006:	40bc                	lw	a5,64(s1)
    80003008:	2785                	addiw	a5,a5,1
    8000300a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000300c:	00016517          	auipc	a0,0x16
    80003010:	90c50513          	addi	a0,a0,-1780 # 80018918 <bcache>
    80003014:	ffffe097          	auipc	ra,0xffffe
    80003018:	b12080e7          	jalr	-1262(ra) # 80000b26 <release>
}
    8000301c:	60e2                	ld	ra,24(sp)
    8000301e:	6442                	ld	s0,16(sp)
    80003020:	64a2                	ld	s1,8(sp)
    80003022:	6105                	addi	sp,sp,32
    80003024:	8082                	ret

0000000080003026 <bunpin>:

void
bunpin(struct buf *b) {
    80003026:	1101                	addi	sp,sp,-32
    80003028:	ec06                	sd	ra,24(sp)
    8000302a:	e822                	sd	s0,16(sp)
    8000302c:	e426                	sd	s1,8(sp)
    8000302e:	1000                	addi	s0,sp,32
    80003030:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003032:	00016517          	auipc	a0,0x16
    80003036:	8e650513          	addi	a0,a0,-1818 # 80018918 <bcache>
    8000303a:	ffffe097          	auipc	ra,0xffffe
    8000303e:	a84080e7          	jalr	-1404(ra) # 80000abe <acquire>
  b->refcnt--;
    80003042:	40bc                	lw	a5,64(s1)
    80003044:	37fd                	addiw	a5,a5,-1
    80003046:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003048:	00016517          	auipc	a0,0x16
    8000304c:	8d050513          	addi	a0,a0,-1840 # 80018918 <bcache>
    80003050:	ffffe097          	auipc	ra,0xffffe
    80003054:	ad6080e7          	jalr	-1322(ra) # 80000b26 <release>
}
    80003058:	60e2                	ld	ra,24(sp)
    8000305a:	6442                	ld	s0,16(sp)
    8000305c:	64a2                	ld	s1,8(sp)
    8000305e:	6105                	addi	sp,sp,32
    80003060:	8082                	ret

0000000080003062 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003062:	1101                	addi	sp,sp,-32
    80003064:	ec06                	sd	ra,24(sp)
    80003066:	e822                	sd	s0,16(sp)
    80003068:	e426                	sd	s1,8(sp)
    8000306a:	e04a                	sd	s2,0(sp)
    8000306c:	1000                	addi	s0,sp,32
    8000306e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003070:	00d5d59b          	srliw	a1,a1,0xd
    80003074:	0001e797          	auipc	a5,0x1e
    80003078:	0787a783          	lw	a5,120(a5) # 800210ec <sb+0x1c>
    8000307c:	9dbd                	addw	a1,a1,a5
    8000307e:	00000097          	auipc	ra,0x0
    80003082:	d9a080e7          	jalr	-614(ra) # 80002e18 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003086:	0074f713          	andi	a4,s1,7
    8000308a:	4785                	li	a5,1
    8000308c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003090:	14ce                	slli	s1,s1,0x33
    80003092:	90d9                	srli	s1,s1,0x36
    80003094:	00950733          	add	a4,a0,s1
    80003098:	06074703          	lbu	a4,96(a4)
    8000309c:	00e7f6b3          	and	a3,a5,a4
    800030a0:	c69d                	beqz	a3,800030ce <bfree+0x6c>
    800030a2:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800030a4:	94aa                	add	s1,s1,a0
    800030a6:	fff7c793          	not	a5,a5
    800030aa:	8ff9                	and	a5,a5,a4
    800030ac:	06f48023          	sb	a5,96(s1)
  log_write(bp);
    800030b0:	00001097          	auipc	ra,0x1
    800030b4:	1d4080e7          	jalr	468(ra) # 80004284 <log_write>
  brelse(bp);
    800030b8:	854a                	mv	a0,s2
    800030ba:	00000097          	auipc	ra,0x0
    800030be:	e92080e7          	jalr	-366(ra) # 80002f4c <brelse>
}
    800030c2:	60e2                	ld	ra,24(sp)
    800030c4:	6442                	ld	s0,16(sp)
    800030c6:	64a2                	ld	s1,8(sp)
    800030c8:	6902                	ld	s2,0(sp)
    800030ca:	6105                	addi	sp,sp,32
    800030cc:	8082                	ret
    panic("freeing free block");
    800030ce:	00005517          	auipc	a0,0x5
    800030d2:	4c250513          	addi	a0,a0,1218 # 80008590 <userret+0x500>
    800030d6:	ffffd097          	auipc	ra,0xffffd
    800030da:	472080e7          	jalr	1138(ra) # 80000548 <panic>

00000000800030de <balloc>:
{
    800030de:	711d                	addi	sp,sp,-96
    800030e0:	ec86                	sd	ra,88(sp)
    800030e2:	e8a2                	sd	s0,80(sp)
    800030e4:	e4a6                	sd	s1,72(sp)
    800030e6:	e0ca                	sd	s2,64(sp)
    800030e8:	fc4e                	sd	s3,56(sp)
    800030ea:	f852                	sd	s4,48(sp)
    800030ec:	f456                	sd	s5,40(sp)
    800030ee:	f05a                	sd	s6,32(sp)
    800030f0:	ec5e                	sd	s7,24(sp)
    800030f2:	e862                	sd	s8,16(sp)
    800030f4:	e466                	sd	s9,8(sp)
    800030f6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800030f8:	0001e797          	auipc	a5,0x1e
    800030fc:	fdc7a783          	lw	a5,-36(a5) # 800210d4 <sb+0x4>
    80003100:	cbd1                	beqz	a5,80003194 <balloc+0xb6>
    80003102:	8baa                	mv	s7,a0
    80003104:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003106:	0001eb17          	auipc	s6,0x1e
    8000310a:	fcab0b13          	addi	s6,s6,-54 # 800210d0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000310e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003110:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003112:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003114:	6c89                	lui	s9,0x2
    80003116:	a831                	j	80003132 <balloc+0x54>
    brelse(bp);
    80003118:	854a                	mv	a0,s2
    8000311a:	00000097          	auipc	ra,0x0
    8000311e:	e32080e7          	jalr	-462(ra) # 80002f4c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003122:	015c87bb          	addw	a5,s9,s5
    80003126:	00078a9b          	sext.w	s5,a5
    8000312a:	004b2703          	lw	a4,4(s6)
    8000312e:	06eaf363          	bgeu	s5,a4,80003194 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003132:	41fad79b          	sraiw	a5,s5,0x1f
    80003136:	0137d79b          	srliw	a5,a5,0x13
    8000313a:	015787bb          	addw	a5,a5,s5
    8000313e:	40d7d79b          	sraiw	a5,a5,0xd
    80003142:	01cb2583          	lw	a1,28(s6)
    80003146:	9dbd                	addw	a1,a1,a5
    80003148:	855e                	mv	a0,s7
    8000314a:	00000097          	auipc	ra,0x0
    8000314e:	cce080e7          	jalr	-818(ra) # 80002e18 <bread>
    80003152:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003154:	004b2503          	lw	a0,4(s6)
    80003158:	000a849b          	sext.w	s1,s5
    8000315c:	8662                	mv	a2,s8
    8000315e:	faa4fde3          	bgeu	s1,a0,80003118 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003162:	41f6579b          	sraiw	a5,a2,0x1f
    80003166:	01d7d69b          	srliw	a3,a5,0x1d
    8000316a:	00c6873b          	addw	a4,a3,a2
    8000316e:	00777793          	andi	a5,a4,7
    80003172:	9f95                	subw	a5,a5,a3
    80003174:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003178:	4037571b          	sraiw	a4,a4,0x3
    8000317c:	00e906b3          	add	a3,s2,a4
    80003180:	0606c683          	lbu	a3,96(a3)
    80003184:	00d7f5b3          	and	a1,a5,a3
    80003188:	cd91                	beqz	a1,800031a4 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000318a:	2605                	addiw	a2,a2,1
    8000318c:	2485                	addiw	s1,s1,1
    8000318e:	fd4618e3          	bne	a2,s4,8000315e <balloc+0x80>
    80003192:	b759                	j	80003118 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003194:	00005517          	auipc	a0,0x5
    80003198:	41450513          	addi	a0,a0,1044 # 800085a8 <userret+0x518>
    8000319c:	ffffd097          	auipc	ra,0xffffd
    800031a0:	3ac080e7          	jalr	940(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800031a4:	974a                	add	a4,a4,s2
    800031a6:	8fd5                	or	a5,a5,a3
    800031a8:	06f70023          	sb	a5,96(a4)
        log_write(bp);
    800031ac:	854a                	mv	a0,s2
    800031ae:	00001097          	auipc	ra,0x1
    800031b2:	0d6080e7          	jalr	214(ra) # 80004284 <log_write>
        brelse(bp);
    800031b6:	854a                	mv	a0,s2
    800031b8:	00000097          	auipc	ra,0x0
    800031bc:	d94080e7          	jalr	-620(ra) # 80002f4c <brelse>
  bp = bread(dev, bno);
    800031c0:	85a6                	mv	a1,s1
    800031c2:	855e                	mv	a0,s7
    800031c4:	00000097          	auipc	ra,0x0
    800031c8:	c54080e7          	jalr	-940(ra) # 80002e18 <bread>
    800031cc:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800031ce:	40000613          	li	a2,1024
    800031d2:	4581                	li	a1,0
    800031d4:	06050513          	addi	a0,a0,96
    800031d8:	ffffe097          	auipc	ra,0xffffe
    800031dc:	9aa080e7          	jalr	-1622(ra) # 80000b82 <memset>
  log_write(bp);
    800031e0:	854a                	mv	a0,s2
    800031e2:	00001097          	auipc	ra,0x1
    800031e6:	0a2080e7          	jalr	162(ra) # 80004284 <log_write>
  brelse(bp);
    800031ea:	854a                	mv	a0,s2
    800031ec:	00000097          	auipc	ra,0x0
    800031f0:	d60080e7          	jalr	-672(ra) # 80002f4c <brelse>
}
    800031f4:	8526                	mv	a0,s1
    800031f6:	60e6                	ld	ra,88(sp)
    800031f8:	6446                	ld	s0,80(sp)
    800031fa:	64a6                	ld	s1,72(sp)
    800031fc:	6906                	ld	s2,64(sp)
    800031fe:	79e2                	ld	s3,56(sp)
    80003200:	7a42                	ld	s4,48(sp)
    80003202:	7aa2                	ld	s5,40(sp)
    80003204:	7b02                	ld	s6,32(sp)
    80003206:	6be2                	ld	s7,24(sp)
    80003208:	6c42                	ld	s8,16(sp)
    8000320a:	6ca2                	ld	s9,8(sp)
    8000320c:	6125                	addi	sp,sp,96
    8000320e:	8082                	ret

0000000080003210 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003210:	7179                	addi	sp,sp,-48
    80003212:	f406                	sd	ra,40(sp)
    80003214:	f022                	sd	s0,32(sp)
    80003216:	ec26                	sd	s1,24(sp)
    80003218:	e84a                	sd	s2,16(sp)
    8000321a:	e44e                	sd	s3,8(sp)
    8000321c:	e052                	sd	s4,0(sp)
    8000321e:	1800                	addi	s0,sp,48
    80003220:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003222:	47ad                	li	a5,11
    80003224:	04b7fe63          	bgeu	a5,a1,80003280 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003228:	ff45849b          	addiw	s1,a1,-12
    8000322c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003230:	0ff00793          	li	a5,255
    80003234:	0ae7e463          	bltu	a5,a4,800032dc <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003238:	08052583          	lw	a1,128(a0)
    8000323c:	c5b5                	beqz	a1,800032a8 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000323e:	00092503          	lw	a0,0(s2)
    80003242:	00000097          	auipc	ra,0x0
    80003246:	bd6080e7          	jalr	-1066(ra) # 80002e18 <bread>
    8000324a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000324c:	06050793          	addi	a5,a0,96
    if((addr = a[bn]) == 0){
    80003250:	02049713          	slli	a4,s1,0x20
    80003254:	01e75593          	srli	a1,a4,0x1e
    80003258:	00b784b3          	add	s1,a5,a1
    8000325c:	0004a983          	lw	s3,0(s1)
    80003260:	04098e63          	beqz	s3,800032bc <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003264:	8552                	mv	a0,s4
    80003266:	00000097          	auipc	ra,0x0
    8000326a:	ce6080e7          	jalr	-794(ra) # 80002f4c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000326e:	854e                	mv	a0,s3
    80003270:	70a2                	ld	ra,40(sp)
    80003272:	7402                	ld	s0,32(sp)
    80003274:	64e2                	ld	s1,24(sp)
    80003276:	6942                	ld	s2,16(sp)
    80003278:	69a2                	ld	s3,8(sp)
    8000327a:	6a02                	ld	s4,0(sp)
    8000327c:	6145                	addi	sp,sp,48
    8000327e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003280:	02059793          	slli	a5,a1,0x20
    80003284:	01e7d593          	srli	a1,a5,0x1e
    80003288:	00b504b3          	add	s1,a0,a1
    8000328c:	0504a983          	lw	s3,80(s1)
    80003290:	fc099fe3          	bnez	s3,8000326e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003294:	4108                	lw	a0,0(a0)
    80003296:	00000097          	auipc	ra,0x0
    8000329a:	e48080e7          	jalr	-440(ra) # 800030de <balloc>
    8000329e:	0005099b          	sext.w	s3,a0
    800032a2:	0534a823          	sw	s3,80(s1)
    800032a6:	b7e1                	j	8000326e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800032a8:	4108                	lw	a0,0(a0)
    800032aa:	00000097          	auipc	ra,0x0
    800032ae:	e34080e7          	jalr	-460(ra) # 800030de <balloc>
    800032b2:	0005059b          	sext.w	a1,a0
    800032b6:	08b92023          	sw	a1,128(s2)
    800032ba:	b751                	j	8000323e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800032bc:	00092503          	lw	a0,0(s2)
    800032c0:	00000097          	auipc	ra,0x0
    800032c4:	e1e080e7          	jalr	-482(ra) # 800030de <balloc>
    800032c8:	0005099b          	sext.w	s3,a0
    800032cc:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800032d0:	8552                	mv	a0,s4
    800032d2:	00001097          	auipc	ra,0x1
    800032d6:	fb2080e7          	jalr	-78(ra) # 80004284 <log_write>
    800032da:	b769                	j	80003264 <bmap+0x54>
  panic("bmap: out of range");
    800032dc:	00005517          	auipc	a0,0x5
    800032e0:	2e450513          	addi	a0,a0,740 # 800085c0 <userret+0x530>
    800032e4:	ffffd097          	auipc	ra,0xffffd
    800032e8:	264080e7          	jalr	612(ra) # 80000548 <panic>

00000000800032ec <iget>:
{
    800032ec:	7179                	addi	sp,sp,-48
    800032ee:	f406                	sd	ra,40(sp)
    800032f0:	f022                	sd	s0,32(sp)
    800032f2:	ec26                	sd	s1,24(sp)
    800032f4:	e84a                	sd	s2,16(sp)
    800032f6:	e44e                	sd	s3,8(sp)
    800032f8:	e052                	sd	s4,0(sp)
    800032fa:	1800                	addi	s0,sp,48
    800032fc:	89aa                	mv	s3,a0
    800032fe:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003300:	0001e517          	auipc	a0,0x1e
    80003304:	df050513          	addi	a0,a0,-528 # 800210f0 <icache>
    80003308:	ffffd097          	auipc	ra,0xffffd
    8000330c:	7b6080e7          	jalr	1974(ra) # 80000abe <acquire>
  empty = 0;
    80003310:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003312:	0001e497          	auipc	s1,0x1e
    80003316:	df648493          	addi	s1,s1,-522 # 80021108 <icache+0x18>
    8000331a:	00020697          	auipc	a3,0x20
    8000331e:	87e68693          	addi	a3,a3,-1922 # 80022b98 <log>
    80003322:	a039                	j	80003330 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003324:	02090b63          	beqz	s2,8000335a <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003328:	08848493          	addi	s1,s1,136
    8000332c:	02d48a63          	beq	s1,a3,80003360 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003330:	449c                	lw	a5,8(s1)
    80003332:	fef059e3          	blez	a5,80003324 <iget+0x38>
    80003336:	4098                	lw	a4,0(s1)
    80003338:	ff3716e3          	bne	a4,s3,80003324 <iget+0x38>
    8000333c:	40d8                	lw	a4,4(s1)
    8000333e:	ff4713e3          	bne	a4,s4,80003324 <iget+0x38>
      ip->ref++;
    80003342:	2785                	addiw	a5,a5,1
    80003344:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003346:	0001e517          	auipc	a0,0x1e
    8000334a:	daa50513          	addi	a0,a0,-598 # 800210f0 <icache>
    8000334e:	ffffd097          	auipc	ra,0xffffd
    80003352:	7d8080e7          	jalr	2008(ra) # 80000b26 <release>
      return ip;
    80003356:	8926                	mv	s2,s1
    80003358:	a03d                	j	80003386 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000335a:	f7f9                	bnez	a5,80003328 <iget+0x3c>
    8000335c:	8926                	mv	s2,s1
    8000335e:	b7e9                	j	80003328 <iget+0x3c>
  if(empty == 0)
    80003360:	02090c63          	beqz	s2,80003398 <iget+0xac>
  ip->dev = dev;
    80003364:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003368:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000336c:	4785                	li	a5,1
    8000336e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003372:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003376:	0001e517          	auipc	a0,0x1e
    8000337a:	d7a50513          	addi	a0,a0,-646 # 800210f0 <icache>
    8000337e:	ffffd097          	auipc	ra,0xffffd
    80003382:	7a8080e7          	jalr	1960(ra) # 80000b26 <release>
}
    80003386:	854a                	mv	a0,s2
    80003388:	70a2                	ld	ra,40(sp)
    8000338a:	7402                	ld	s0,32(sp)
    8000338c:	64e2                	ld	s1,24(sp)
    8000338e:	6942                	ld	s2,16(sp)
    80003390:	69a2                	ld	s3,8(sp)
    80003392:	6a02                	ld	s4,0(sp)
    80003394:	6145                	addi	sp,sp,48
    80003396:	8082                	ret
    panic("iget: no inodes");
    80003398:	00005517          	auipc	a0,0x5
    8000339c:	24050513          	addi	a0,a0,576 # 800085d8 <userret+0x548>
    800033a0:	ffffd097          	auipc	ra,0xffffd
    800033a4:	1a8080e7          	jalr	424(ra) # 80000548 <panic>

00000000800033a8 <fsinit>:
fsinit(int dev) {
    800033a8:	7179                	addi	sp,sp,-48
    800033aa:	f406                	sd	ra,40(sp)
    800033ac:	f022                	sd	s0,32(sp)
    800033ae:	ec26                	sd	s1,24(sp)
    800033b0:	e84a                	sd	s2,16(sp)
    800033b2:	e44e                	sd	s3,8(sp)
    800033b4:	1800                	addi	s0,sp,48
    800033b6:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800033b8:	4585                	li	a1,1
    800033ba:	00000097          	auipc	ra,0x0
    800033be:	a5e080e7          	jalr	-1442(ra) # 80002e18 <bread>
    800033c2:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800033c4:	0001e997          	auipc	s3,0x1e
    800033c8:	d0c98993          	addi	s3,s3,-756 # 800210d0 <sb>
    800033cc:	02000613          	li	a2,32
    800033d0:	06050593          	addi	a1,a0,96
    800033d4:	854e                	mv	a0,s3
    800033d6:	ffffe097          	auipc	ra,0xffffe
    800033da:	808080e7          	jalr	-2040(ra) # 80000bde <memmove>
  brelse(bp);
    800033de:	8526                	mv	a0,s1
    800033e0:	00000097          	auipc	ra,0x0
    800033e4:	b6c080e7          	jalr	-1172(ra) # 80002f4c <brelse>
  if(sb.magic != FSMAGIC)
    800033e8:	0009a703          	lw	a4,0(s3)
    800033ec:	102037b7          	lui	a5,0x10203
    800033f0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800033f4:	02f71263          	bne	a4,a5,80003418 <fsinit+0x70>
  initlog(dev, &sb);
    800033f8:	0001e597          	auipc	a1,0x1e
    800033fc:	cd858593          	addi	a1,a1,-808 # 800210d0 <sb>
    80003400:	854a                	mv	a0,s2
    80003402:	00001097          	auipc	ra,0x1
    80003406:	bfa080e7          	jalr	-1030(ra) # 80003ffc <initlog>
}
    8000340a:	70a2                	ld	ra,40(sp)
    8000340c:	7402                	ld	s0,32(sp)
    8000340e:	64e2                	ld	s1,24(sp)
    80003410:	6942                	ld	s2,16(sp)
    80003412:	69a2                	ld	s3,8(sp)
    80003414:	6145                	addi	sp,sp,48
    80003416:	8082                	ret
    panic("invalid file system");
    80003418:	00005517          	auipc	a0,0x5
    8000341c:	1d050513          	addi	a0,a0,464 # 800085e8 <userret+0x558>
    80003420:	ffffd097          	auipc	ra,0xffffd
    80003424:	128080e7          	jalr	296(ra) # 80000548 <panic>

0000000080003428 <iinit>:
{
    80003428:	7179                	addi	sp,sp,-48
    8000342a:	f406                	sd	ra,40(sp)
    8000342c:	f022                	sd	s0,32(sp)
    8000342e:	ec26                	sd	s1,24(sp)
    80003430:	e84a                	sd	s2,16(sp)
    80003432:	e44e                	sd	s3,8(sp)
    80003434:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003436:	00005597          	auipc	a1,0x5
    8000343a:	1ca58593          	addi	a1,a1,458 # 80008600 <userret+0x570>
    8000343e:	0001e517          	auipc	a0,0x1e
    80003442:	cb250513          	addi	a0,a0,-846 # 800210f0 <icache>
    80003446:	ffffd097          	auipc	ra,0xffffd
    8000344a:	56a080e7          	jalr	1386(ra) # 800009b0 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000344e:	0001e497          	auipc	s1,0x1e
    80003452:	cca48493          	addi	s1,s1,-822 # 80021118 <icache+0x28>
    80003456:	0001f997          	auipc	s3,0x1f
    8000345a:	75298993          	addi	s3,s3,1874 # 80022ba8 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000345e:	00005917          	auipc	s2,0x5
    80003462:	1aa90913          	addi	s2,s2,426 # 80008608 <userret+0x578>
    80003466:	85ca                	mv	a1,s2
    80003468:	8526                	mv	a0,s1
    8000346a:	00001097          	auipc	ra,0x1
    8000346e:	078080e7          	jalr	120(ra) # 800044e2 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003472:	08848493          	addi	s1,s1,136
    80003476:	ff3498e3          	bne	s1,s3,80003466 <iinit+0x3e>
}
    8000347a:	70a2                	ld	ra,40(sp)
    8000347c:	7402                	ld	s0,32(sp)
    8000347e:	64e2                	ld	s1,24(sp)
    80003480:	6942                	ld	s2,16(sp)
    80003482:	69a2                	ld	s3,8(sp)
    80003484:	6145                	addi	sp,sp,48
    80003486:	8082                	ret

0000000080003488 <ialloc>:
{
    80003488:	715d                	addi	sp,sp,-80
    8000348a:	e486                	sd	ra,72(sp)
    8000348c:	e0a2                	sd	s0,64(sp)
    8000348e:	fc26                	sd	s1,56(sp)
    80003490:	f84a                	sd	s2,48(sp)
    80003492:	f44e                	sd	s3,40(sp)
    80003494:	f052                	sd	s4,32(sp)
    80003496:	ec56                	sd	s5,24(sp)
    80003498:	e85a                	sd	s6,16(sp)
    8000349a:	e45e                	sd	s7,8(sp)
    8000349c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000349e:	0001e717          	auipc	a4,0x1e
    800034a2:	c3e72703          	lw	a4,-962(a4) # 800210dc <sb+0xc>
    800034a6:	4785                	li	a5,1
    800034a8:	04e7fa63          	bgeu	a5,a4,800034fc <ialloc+0x74>
    800034ac:	8aaa                	mv	s5,a0
    800034ae:	8bae                	mv	s7,a1
    800034b0:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800034b2:	0001ea17          	auipc	s4,0x1e
    800034b6:	c1ea0a13          	addi	s4,s4,-994 # 800210d0 <sb>
    800034ba:	00048b1b          	sext.w	s6,s1
    800034be:	0044d793          	srli	a5,s1,0x4
    800034c2:	018a2583          	lw	a1,24(s4)
    800034c6:	9dbd                	addw	a1,a1,a5
    800034c8:	8556                	mv	a0,s5
    800034ca:	00000097          	auipc	ra,0x0
    800034ce:	94e080e7          	jalr	-1714(ra) # 80002e18 <bread>
    800034d2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800034d4:	06050993          	addi	s3,a0,96
    800034d8:	00f4f793          	andi	a5,s1,15
    800034dc:	079a                	slli	a5,a5,0x6
    800034de:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800034e0:	00099783          	lh	a5,0(s3)
    800034e4:	c785                	beqz	a5,8000350c <ialloc+0x84>
    brelse(bp);
    800034e6:	00000097          	auipc	ra,0x0
    800034ea:	a66080e7          	jalr	-1434(ra) # 80002f4c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800034ee:	0485                	addi	s1,s1,1
    800034f0:	00ca2703          	lw	a4,12(s4)
    800034f4:	0004879b          	sext.w	a5,s1
    800034f8:	fce7e1e3          	bltu	a5,a4,800034ba <ialloc+0x32>
  panic("ialloc: no inodes");
    800034fc:	00005517          	auipc	a0,0x5
    80003500:	11450513          	addi	a0,a0,276 # 80008610 <userret+0x580>
    80003504:	ffffd097          	auipc	ra,0xffffd
    80003508:	044080e7          	jalr	68(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    8000350c:	04000613          	li	a2,64
    80003510:	4581                	li	a1,0
    80003512:	854e                	mv	a0,s3
    80003514:	ffffd097          	auipc	ra,0xffffd
    80003518:	66e080e7          	jalr	1646(ra) # 80000b82 <memset>
      dip->type = type;
    8000351c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003520:	854a                	mv	a0,s2
    80003522:	00001097          	auipc	ra,0x1
    80003526:	d62080e7          	jalr	-670(ra) # 80004284 <log_write>
      brelse(bp);
    8000352a:	854a                	mv	a0,s2
    8000352c:	00000097          	auipc	ra,0x0
    80003530:	a20080e7          	jalr	-1504(ra) # 80002f4c <brelse>
      return iget(dev, inum);
    80003534:	85da                	mv	a1,s6
    80003536:	8556                	mv	a0,s5
    80003538:	00000097          	auipc	ra,0x0
    8000353c:	db4080e7          	jalr	-588(ra) # 800032ec <iget>
}
    80003540:	60a6                	ld	ra,72(sp)
    80003542:	6406                	ld	s0,64(sp)
    80003544:	74e2                	ld	s1,56(sp)
    80003546:	7942                	ld	s2,48(sp)
    80003548:	79a2                	ld	s3,40(sp)
    8000354a:	7a02                	ld	s4,32(sp)
    8000354c:	6ae2                	ld	s5,24(sp)
    8000354e:	6b42                	ld	s6,16(sp)
    80003550:	6ba2                	ld	s7,8(sp)
    80003552:	6161                	addi	sp,sp,80
    80003554:	8082                	ret

0000000080003556 <iupdate>:
{
    80003556:	1101                	addi	sp,sp,-32
    80003558:	ec06                	sd	ra,24(sp)
    8000355a:	e822                	sd	s0,16(sp)
    8000355c:	e426                	sd	s1,8(sp)
    8000355e:	e04a                	sd	s2,0(sp)
    80003560:	1000                	addi	s0,sp,32
    80003562:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003564:	415c                	lw	a5,4(a0)
    80003566:	0047d79b          	srliw	a5,a5,0x4
    8000356a:	0001e597          	auipc	a1,0x1e
    8000356e:	b7e5a583          	lw	a1,-1154(a1) # 800210e8 <sb+0x18>
    80003572:	9dbd                	addw	a1,a1,a5
    80003574:	4108                	lw	a0,0(a0)
    80003576:	00000097          	auipc	ra,0x0
    8000357a:	8a2080e7          	jalr	-1886(ra) # 80002e18 <bread>
    8000357e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003580:	06050793          	addi	a5,a0,96
    80003584:	40c8                	lw	a0,4(s1)
    80003586:	893d                	andi	a0,a0,15
    80003588:	051a                	slli	a0,a0,0x6
    8000358a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000358c:	04449703          	lh	a4,68(s1)
    80003590:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003594:	04649703          	lh	a4,70(s1)
    80003598:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000359c:	04849703          	lh	a4,72(s1)
    800035a0:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800035a4:	04a49703          	lh	a4,74(s1)
    800035a8:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800035ac:	44f8                	lw	a4,76(s1)
    800035ae:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800035b0:	03400613          	li	a2,52
    800035b4:	05048593          	addi	a1,s1,80
    800035b8:	0531                	addi	a0,a0,12
    800035ba:	ffffd097          	auipc	ra,0xffffd
    800035be:	624080e7          	jalr	1572(ra) # 80000bde <memmove>
  log_write(bp);
    800035c2:	854a                	mv	a0,s2
    800035c4:	00001097          	auipc	ra,0x1
    800035c8:	cc0080e7          	jalr	-832(ra) # 80004284 <log_write>
  brelse(bp);
    800035cc:	854a                	mv	a0,s2
    800035ce:	00000097          	auipc	ra,0x0
    800035d2:	97e080e7          	jalr	-1666(ra) # 80002f4c <brelse>
}
    800035d6:	60e2                	ld	ra,24(sp)
    800035d8:	6442                	ld	s0,16(sp)
    800035da:	64a2                	ld	s1,8(sp)
    800035dc:	6902                	ld	s2,0(sp)
    800035de:	6105                	addi	sp,sp,32
    800035e0:	8082                	ret

00000000800035e2 <idup>:
{
    800035e2:	1101                	addi	sp,sp,-32
    800035e4:	ec06                	sd	ra,24(sp)
    800035e6:	e822                	sd	s0,16(sp)
    800035e8:	e426                	sd	s1,8(sp)
    800035ea:	1000                	addi	s0,sp,32
    800035ec:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800035ee:	0001e517          	auipc	a0,0x1e
    800035f2:	b0250513          	addi	a0,a0,-1278 # 800210f0 <icache>
    800035f6:	ffffd097          	auipc	ra,0xffffd
    800035fa:	4c8080e7          	jalr	1224(ra) # 80000abe <acquire>
  ip->ref++;
    800035fe:	449c                	lw	a5,8(s1)
    80003600:	2785                	addiw	a5,a5,1
    80003602:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003604:	0001e517          	auipc	a0,0x1e
    80003608:	aec50513          	addi	a0,a0,-1300 # 800210f0 <icache>
    8000360c:	ffffd097          	auipc	ra,0xffffd
    80003610:	51a080e7          	jalr	1306(ra) # 80000b26 <release>
}
    80003614:	8526                	mv	a0,s1
    80003616:	60e2                	ld	ra,24(sp)
    80003618:	6442                	ld	s0,16(sp)
    8000361a:	64a2                	ld	s1,8(sp)
    8000361c:	6105                	addi	sp,sp,32
    8000361e:	8082                	ret

0000000080003620 <ilock>:
{
    80003620:	1101                	addi	sp,sp,-32
    80003622:	ec06                	sd	ra,24(sp)
    80003624:	e822                	sd	s0,16(sp)
    80003626:	e426                	sd	s1,8(sp)
    80003628:	e04a                	sd	s2,0(sp)
    8000362a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000362c:	c115                	beqz	a0,80003650 <ilock+0x30>
    8000362e:	84aa                	mv	s1,a0
    80003630:	451c                	lw	a5,8(a0)
    80003632:	00f05f63          	blez	a5,80003650 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003636:	0541                	addi	a0,a0,16
    80003638:	00001097          	auipc	ra,0x1
    8000363c:	ee4080e7          	jalr	-284(ra) # 8000451c <acquiresleep>
  if(ip->valid == 0){
    80003640:	40bc                	lw	a5,64(s1)
    80003642:	cf99                	beqz	a5,80003660 <ilock+0x40>
}
    80003644:	60e2                	ld	ra,24(sp)
    80003646:	6442                	ld	s0,16(sp)
    80003648:	64a2                	ld	s1,8(sp)
    8000364a:	6902                	ld	s2,0(sp)
    8000364c:	6105                	addi	sp,sp,32
    8000364e:	8082                	ret
    panic("ilock");
    80003650:	00005517          	auipc	a0,0x5
    80003654:	fd850513          	addi	a0,a0,-40 # 80008628 <userret+0x598>
    80003658:	ffffd097          	auipc	ra,0xffffd
    8000365c:	ef0080e7          	jalr	-272(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003660:	40dc                	lw	a5,4(s1)
    80003662:	0047d79b          	srliw	a5,a5,0x4
    80003666:	0001e597          	auipc	a1,0x1e
    8000366a:	a825a583          	lw	a1,-1406(a1) # 800210e8 <sb+0x18>
    8000366e:	9dbd                	addw	a1,a1,a5
    80003670:	4088                	lw	a0,0(s1)
    80003672:	fffff097          	auipc	ra,0xfffff
    80003676:	7a6080e7          	jalr	1958(ra) # 80002e18 <bread>
    8000367a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000367c:	06050593          	addi	a1,a0,96
    80003680:	40dc                	lw	a5,4(s1)
    80003682:	8bbd                	andi	a5,a5,15
    80003684:	079a                	slli	a5,a5,0x6
    80003686:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003688:	00059783          	lh	a5,0(a1)
    8000368c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003690:	00259783          	lh	a5,2(a1)
    80003694:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003698:	00459783          	lh	a5,4(a1)
    8000369c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800036a0:	00659783          	lh	a5,6(a1)
    800036a4:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800036a8:	459c                	lw	a5,8(a1)
    800036aa:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800036ac:	03400613          	li	a2,52
    800036b0:	05b1                	addi	a1,a1,12
    800036b2:	05048513          	addi	a0,s1,80
    800036b6:	ffffd097          	auipc	ra,0xffffd
    800036ba:	528080e7          	jalr	1320(ra) # 80000bde <memmove>
    brelse(bp);
    800036be:	854a                	mv	a0,s2
    800036c0:	00000097          	auipc	ra,0x0
    800036c4:	88c080e7          	jalr	-1908(ra) # 80002f4c <brelse>
    ip->valid = 1;
    800036c8:	4785                	li	a5,1
    800036ca:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800036cc:	04449783          	lh	a5,68(s1)
    800036d0:	fbb5                	bnez	a5,80003644 <ilock+0x24>
      panic("ilock: no type");
    800036d2:	00005517          	auipc	a0,0x5
    800036d6:	f5e50513          	addi	a0,a0,-162 # 80008630 <userret+0x5a0>
    800036da:	ffffd097          	auipc	ra,0xffffd
    800036de:	e6e080e7          	jalr	-402(ra) # 80000548 <panic>

00000000800036e2 <iunlock>:
{
    800036e2:	1101                	addi	sp,sp,-32
    800036e4:	ec06                	sd	ra,24(sp)
    800036e6:	e822                	sd	s0,16(sp)
    800036e8:	e426                	sd	s1,8(sp)
    800036ea:	e04a                	sd	s2,0(sp)
    800036ec:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800036ee:	c905                	beqz	a0,8000371e <iunlock+0x3c>
    800036f0:	84aa                	mv	s1,a0
    800036f2:	01050913          	addi	s2,a0,16
    800036f6:	854a                	mv	a0,s2
    800036f8:	00001097          	auipc	ra,0x1
    800036fc:	ebe080e7          	jalr	-322(ra) # 800045b6 <holdingsleep>
    80003700:	cd19                	beqz	a0,8000371e <iunlock+0x3c>
    80003702:	449c                	lw	a5,8(s1)
    80003704:	00f05d63          	blez	a5,8000371e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003708:	854a                	mv	a0,s2
    8000370a:	00001097          	auipc	ra,0x1
    8000370e:	e68080e7          	jalr	-408(ra) # 80004572 <releasesleep>
}
    80003712:	60e2                	ld	ra,24(sp)
    80003714:	6442                	ld	s0,16(sp)
    80003716:	64a2                	ld	s1,8(sp)
    80003718:	6902                	ld	s2,0(sp)
    8000371a:	6105                	addi	sp,sp,32
    8000371c:	8082                	ret
    panic("iunlock");
    8000371e:	00005517          	auipc	a0,0x5
    80003722:	f2250513          	addi	a0,a0,-222 # 80008640 <userret+0x5b0>
    80003726:	ffffd097          	auipc	ra,0xffffd
    8000372a:	e22080e7          	jalr	-478(ra) # 80000548 <panic>

000000008000372e <iput>:
{
    8000372e:	7139                	addi	sp,sp,-64
    80003730:	fc06                	sd	ra,56(sp)
    80003732:	f822                	sd	s0,48(sp)
    80003734:	f426                	sd	s1,40(sp)
    80003736:	f04a                	sd	s2,32(sp)
    80003738:	ec4e                	sd	s3,24(sp)
    8000373a:	e852                	sd	s4,16(sp)
    8000373c:	e456                	sd	s5,8(sp)
    8000373e:	0080                	addi	s0,sp,64
    80003740:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003742:	0001e517          	auipc	a0,0x1e
    80003746:	9ae50513          	addi	a0,a0,-1618 # 800210f0 <icache>
    8000374a:	ffffd097          	auipc	ra,0xffffd
    8000374e:	374080e7          	jalr	884(ra) # 80000abe <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003752:	4498                	lw	a4,8(s1)
    80003754:	4785                	li	a5,1
    80003756:	02f70663          	beq	a4,a5,80003782 <iput+0x54>
  ip->ref--;
    8000375a:	449c                	lw	a5,8(s1)
    8000375c:	37fd                	addiw	a5,a5,-1
    8000375e:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003760:	0001e517          	auipc	a0,0x1e
    80003764:	99050513          	addi	a0,a0,-1648 # 800210f0 <icache>
    80003768:	ffffd097          	auipc	ra,0xffffd
    8000376c:	3be080e7          	jalr	958(ra) # 80000b26 <release>
}
    80003770:	70e2                	ld	ra,56(sp)
    80003772:	7442                	ld	s0,48(sp)
    80003774:	74a2                	ld	s1,40(sp)
    80003776:	7902                	ld	s2,32(sp)
    80003778:	69e2                	ld	s3,24(sp)
    8000377a:	6a42                	ld	s4,16(sp)
    8000377c:	6aa2                	ld	s5,8(sp)
    8000377e:	6121                	addi	sp,sp,64
    80003780:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003782:	40bc                	lw	a5,64(s1)
    80003784:	dbf9                	beqz	a5,8000375a <iput+0x2c>
    80003786:	04a49783          	lh	a5,74(s1)
    8000378a:	fbe1                	bnez	a5,8000375a <iput+0x2c>
    acquiresleep(&ip->lock);
    8000378c:	01048a13          	addi	s4,s1,16
    80003790:	8552                	mv	a0,s4
    80003792:	00001097          	auipc	ra,0x1
    80003796:	d8a080e7          	jalr	-630(ra) # 8000451c <acquiresleep>
    release(&icache.lock);
    8000379a:	0001e517          	auipc	a0,0x1e
    8000379e:	95650513          	addi	a0,a0,-1706 # 800210f0 <icache>
    800037a2:	ffffd097          	auipc	ra,0xffffd
    800037a6:	384080e7          	jalr	900(ra) # 80000b26 <release>
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800037aa:	05048913          	addi	s2,s1,80
    800037ae:	08048993          	addi	s3,s1,128
    800037b2:	a021                	j	800037ba <iput+0x8c>
    800037b4:	0911                	addi	s2,s2,4
    800037b6:	01390d63          	beq	s2,s3,800037d0 <iput+0xa2>
    if(ip->addrs[i]){
    800037ba:	00092583          	lw	a1,0(s2)
    800037be:	d9fd                	beqz	a1,800037b4 <iput+0x86>
      bfree(ip->dev, ip->addrs[i]);
    800037c0:	4088                	lw	a0,0(s1)
    800037c2:	00000097          	auipc	ra,0x0
    800037c6:	8a0080e7          	jalr	-1888(ra) # 80003062 <bfree>
      ip->addrs[i] = 0;
    800037ca:	00092023          	sw	zero,0(s2)
    800037ce:	b7dd                	j	800037b4 <iput+0x86>
    }
  }

  if(ip->addrs[NDIRECT]){
    800037d0:	0804a583          	lw	a1,128(s1)
    800037d4:	ed9d                	bnez	a1,80003812 <iput+0xe4>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800037d6:	0404a623          	sw	zero,76(s1)
  iupdate(ip);
    800037da:	8526                	mv	a0,s1
    800037dc:	00000097          	auipc	ra,0x0
    800037e0:	d7a080e7          	jalr	-646(ra) # 80003556 <iupdate>
    ip->type = 0;
    800037e4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800037e8:	8526                	mv	a0,s1
    800037ea:	00000097          	auipc	ra,0x0
    800037ee:	d6c080e7          	jalr	-660(ra) # 80003556 <iupdate>
    ip->valid = 0;
    800037f2:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800037f6:	8552                	mv	a0,s4
    800037f8:	00001097          	auipc	ra,0x1
    800037fc:	d7a080e7          	jalr	-646(ra) # 80004572 <releasesleep>
    acquire(&icache.lock);
    80003800:	0001e517          	auipc	a0,0x1e
    80003804:	8f050513          	addi	a0,a0,-1808 # 800210f0 <icache>
    80003808:	ffffd097          	auipc	ra,0xffffd
    8000380c:	2b6080e7          	jalr	694(ra) # 80000abe <acquire>
    80003810:	b7a9                	j	8000375a <iput+0x2c>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003812:	4088                	lw	a0,0(s1)
    80003814:	fffff097          	auipc	ra,0xfffff
    80003818:	604080e7          	jalr	1540(ra) # 80002e18 <bread>
    8000381c:	8aaa                	mv	s5,a0
    for(j = 0; j < NINDIRECT; j++){
    8000381e:	06050913          	addi	s2,a0,96
    80003822:	46050993          	addi	s3,a0,1120
    80003826:	a021                	j	8000382e <iput+0x100>
    80003828:	0911                	addi	s2,s2,4
    8000382a:	01390b63          	beq	s2,s3,80003840 <iput+0x112>
      if(a[j])
    8000382e:	00092583          	lw	a1,0(s2)
    80003832:	d9fd                	beqz	a1,80003828 <iput+0xfa>
        bfree(ip->dev, a[j]);
    80003834:	4088                	lw	a0,0(s1)
    80003836:	00000097          	auipc	ra,0x0
    8000383a:	82c080e7          	jalr	-2004(ra) # 80003062 <bfree>
    8000383e:	b7ed                	j	80003828 <iput+0xfa>
    brelse(bp);
    80003840:	8556                	mv	a0,s5
    80003842:	fffff097          	auipc	ra,0xfffff
    80003846:	70a080e7          	jalr	1802(ra) # 80002f4c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000384a:	0804a583          	lw	a1,128(s1)
    8000384e:	4088                	lw	a0,0(s1)
    80003850:	00000097          	auipc	ra,0x0
    80003854:	812080e7          	jalr	-2030(ra) # 80003062 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003858:	0804a023          	sw	zero,128(s1)
    8000385c:	bfad                	j	800037d6 <iput+0xa8>

000000008000385e <iunlockput>:
{
    8000385e:	1101                	addi	sp,sp,-32
    80003860:	ec06                	sd	ra,24(sp)
    80003862:	e822                	sd	s0,16(sp)
    80003864:	e426                	sd	s1,8(sp)
    80003866:	1000                	addi	s0,sp,32
    80003868:	84aa                	mv	s1,a0
  iunlock(ip);
    8000386a:	00000097          	auipc	ra,0x0
    8000386e:	e78080e7          	jalr	-392(ra) # 800036e2 <iunlock>
  iput(ip);
    80003872:	8526                	mv	a0,s1
    80003874:	00000097          	auipc	ra,0x0
    80003878:	eba080e7          	jalr	-326(ra) # 8000372e <iput>
}
    8000387c:	60e2                	ld	ra,24(sp)
    8000387e:	6442                	ld	s0,16(sp)
    80003880:	64a2                	ld	s1,8(sp)
    80003882:	6105                	addi	sp,sp,32
    80003884:	8082                	ret

0000000080003886 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003886:	1141                	addi	sp,sp,-16
    80003888:	e422                	sd	s0,8(sp)
    8000388a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000388c:	411c                	lw	a5,0(a0)
    8000388e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003890:	415c                	lw	a5,4(a0)
    80003892:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003894:	04451783          	lh	a5,68(a0)
    80003898:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000389c:	04a51783          	lh	a5,74(a0)
    800038a0:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800038a4:	04c56783          	lwu	a5,76(a0)
    800038a8:	e99c                	sd	a5,16(a1)
}
    800038aa:	6422                	ld	s0,8(sp)
    800038ac:	0141                	addi	sp,sp,16
    800038ae:	8082                	ret

00000000800038b0 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800038b0:	457c                	lw	a5,76(a0)
    800038b2:	0ed7e563          	bltu	a5,a3,8000399c <readi+0xec>
{
    800038b6:	7159                	addi	sp,sp,-112
    800038b8:	f486                	sd	ra,104(sp)
    800038ba:	f0a2                	sd	s0,96(sp)
    800038bc:	eca6                	sd	s1,88(sp)
    800038be:	e8ca                	sd	s2,80(sp)
    800038c0:	e4ce                	sd	s3,72(sp)
    800038c2:	e0d2                	sd	s4,64(sp)
    800038c4:	fc56                	sd	s5,56(sp)
    800038c6:	f85a                	sd	s6,48(sp)
    800038c8:	f45e                	sd	s7,40(sp)
    800038ca:	f062                	sd	s8,32(sp)
    800038cc:	ec66                	sd	s9,24(sp)
    800038ce:	e86a                	sd	s10,16(sp)
    800038d0:	e46e                	sd	s11,8(sp)
    800038d2:	1880                	addi	s0,sp,112
    800038d4:	8baa                	mv	s7,a0
    800038d6:	8c2e                	mv	s8,a1
    800038d8:	8ab2                	mv	s5,a2
    800038da:	8936                	mv	s2,a3
    800038dc:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800038de:	9f35                	addw	a4,a4,a3
    800038e0:	0cd76063          	bltu	a4,a3,800039a0 <readi+0xf0>
    return -1;
  if(off + n > ip->size)
    800038e4:	00e7f463          	bgeu	a5,a4,800038ec <readi+0x3c>
    n = ip->size - off;
    800038e8:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800038ec:	080b0763          	beqz	s6,8000397a <readi+0xca>
    800038f0:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800038f2:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800038f6:	5cfd                	li	s9,-1
    800038f8:	a82d                	j	80003932 <readi+0x82>
    800038fa:	02099d93          	slli	s11,s3,0x20
    800038fe:	020ddd93          	srli	s11,s11,0x20
    80003902:	06048793          	addi	a5,s1,96
    80003906:	86ee                	mv	a3,s11
    80003908:	963e                	add	a2,a2,a5
    8000390a:	85d6                	mv	a1,s5
    8000390c:	8562                	mv	a0,s8
    8000390e:	fffff097          	auipc	ra,0xfffff
    80003912:	a34080e7          	jalr	-1484(ra) # 80002342 <either_copyout>
    80003916:	05950d63          	beq	a0,s9,80003970 <readi+0xc0>
      brelse(bp);
      break;
    }
    brelse(bp);
    8000391a:	8526                	mv	a0,s1
    8000391c:	fffff097          	auipc	ra,0xfffff
    80003920:	630080e7          	jalr	1584(ra) # 80002f4c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003924:	01498a3b          	addw	s4,s3,s4
    80003928:	0129893b          	addw	s2,s3,s2
    8000392c:	9aee                	add	s5,s5,s11
    8000392e:	056a7663          	bgeu	s4,s6,8000397a <readi+0xca>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003932:	000ba483          	lw	s1,0(s7)
    80003936:	00a9559b          	srliw	a1,s2,0xa
    8000393a:	855e                	mv	a0,s7
    8000393c:	00000097          	auipc	ra,0x0
    80003940:	8d4080e7          	jalr	-1836(ra) # 80003210 <bmap>
    80003944:	0005059b          	sext.w	a1,a0
    80003948:	8526                	mv	a0,s1
    8000394a:	fffff097          	auipc	ra,0xfffff
    8000394e:	4ce080e7          	jalr	1230(ra) # 80002e18 <bread>
    80003952:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003954:	3ff97613          	andi	a2,s2,1023
    80003958:	40cd07bb          	subw	a5,s10,a2
    8000395c:	414b073b          	subw	a4,s6,s4
    80003960:	89be                	mv	s3,a5
    80003962:	2781                	sext.w	a5,a5
    80003964:	0007069b          	sext.w	a3,a4
    80003968:	f8f6f9e3          	bgeu	a3,a5,800038fa <readi+0x4a>
    8000396c:	89ba                	mv	s3,a4
    8000396e:	b771                	j	800038fa <readi+0x4a>
      brelse(bp);
    80003970:	8526                	mv	a0,s1
    80003972:	fffff097          	auipc	ra,0xfffff
    80003976:	5da080e7          	jalr	1498(ra) # 80002f4c <brelse>
  }
  return n;
    8000397a:	000b051b          	sext.w	a0,s6
}
    8000397e:	70a6                	ld	ra,104(sp)
    80003980:	7406                	ld	s0,96(sp)
    80003982:	64e6                	ld	s1,88(sp)
    80003984:	6946                	ld	s2,80(sp)
    80003986:	69a6                	ld	s3,72(sp)
    80003988:	6a06                	ld	s4,64(sp)
    8000398a:	7ae2                	ld	s5,56(sp)
    8000398c:	7b42                	ld	s6,48(sp)
    8000398e:	7ba2                	ld	s7,40(sp)
    80003990:	7c02                	ld	s8,32(sp)
    80003992:	6ce2                	ld	s9,24(sp)
    80003994:	6d42                	ld	s10,16(sp)
    80003996:	6da2                	ld	s11,8(sp)
    80003998:	6165                	addi	sp,sp,112
    8000399a:	8082                	ret
    return -1;
    8000399c:	557d                	li	a0,-1
}
    8000399e:	8082                	ret
    return -1;
    800039a0:	557d                	li	a0,-1
    800039a2:	bff1                	j	8000397e <readi+0xce>

00000000800039a4 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039a4:	457c                	lw	a5,76(a0)
    800039a6:	10d7e663          	bltu	a5,a3,80003ab2 <writei+0x10e>
{
    800039aa:	7159                	addi	sp,sp,-112
    800039ac:	f486                	sd	ra,104(sp)
    800039ae:	f0a2                	sd	s0,96(sp)
    800039b0:	eca6                	sd	s1,88(sp)
    800039b2:	e8ca                	sd	s2,80(sp)
    800039b4:	e4ce                	sd	s3,72(sp)
    800039b6:	e0d2                	sd	s4,64(sp)
    800039b8:	fc56                	sd	s5,56(sp)
    800039ba:	f85a                	sd	s6,48(sp)
    800039bc:	f45e                	sd	s7,40(sp)
    800039be:	f062                	sd	s8,32(sp)
    800039c0:	ec66                	sd	s9,24(sp)
    800039c2:	e86a                	sd	s10,16(sp)
    800039c4:	e46e                	sd	s11,8(sp)
    800039c6:	1880                	addi	s0,sp,112
    800039c8:	8baa                	mv	s7,a0
    800039ca:	8c2e                	mv	s8,a1
    800039cc:	8ab2                	mv	s5,a2
    800039ce:	8936                	mv	s2,a3
    800039d0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800039d2:	00e687bb          	addw	a5,a3,a4
    800039d6:	0ed7e063          	bltu	a5,a3,80003ab6 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800039da:	00043737          	lui	a4,0x43
    800039de:	0cf76e63          	bltu	a4,a5,80003aba <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800039e2:	0a0b0763          	beqz	s6,80003a90 <writei+0xec>
    800039e6:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800039e8:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800039ec:	5cfd                	li	s9,-1
    800039ee:	a091                	j	80003a32 <writei+0x8e>
    800039f0:	02099d93          	slli	s11,s3,0x20
    800039f4:	020ddd93          	srli	s11,s11,0x20
    800039f8:	06048793          	addi	a5,s1,96
    800039fc:	86ee                	mv	a3,s11
    800039fe:	8656                	mv	a2,s5
    80003a00:	85e2                	mv	a1,s8
    80003a02:	953e                	add	a0,a0,a5
    80003a04:	fffff097          	auipc	ra,0xfffff
    80003a08:	994080e7          	jalr	-1644(ra) # 80002398 <either_copyin>
    80003a0c:	07950263          	beq	a0,s9,80003a70 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003a10:	8526                	mv	a0,s1
    80003a12:	00001097          	auipc	ra,0x1
    80003a16:	872080e7          	jalr	-1934(ra) # 80004284 <log_write>
    brelse(bp);
    80003a1a:	8526                	mv	a0,s1
    80003a1c:	fffff097          	auipc	ra,0xfffff
    80003a20:	530080e7          	jalr	1328(ra) # 80002f4c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a24:	01498a3b          	addw	s4,s3,s4
    80003a28:	0129893b          	addw	s2,s3,s2
    80003a2c:	9aee                	add	s5,s5,s11
    80003a2e:	056a7663          	bgeu	s4,s6,80003a7a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a32:	000ba483          	lw	s1,0(s7)
    80003a36:	00a9559b          	srliw	a1,s2,0xa
    80003a3a:	855e                	mv	a0,s7
    80003a3c:	fffff097          	auipc	ra,0xfffff
    80003a40:	7d4080e7          	jalr	2004(ra) # 80003210 <bmap>
    80003a44:	0005059b          	sext.w	a1,a0
    80003a48:	8526                	mv	a0,s1
    80003a4a:	fffff097          	auipc	ra,0xfffff
    80003a4e:	3ce080e7          	jalr	974(ra) # 80002e18 <bread>
    80003a52:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a54:	3ff97513          	andi	a0,s2,1023
    80003a58:	40ad07bb          	subw	a5,s10,a0
    80003a5c:	414b073b          	subw	a4,s6,s4
    80003a60:	89be                	mv	s3,a5
    80003a62:	2781                	sext.w	a5,a5
    80003a64:	0007069b          	sext.w	a3,a4
    80003a68:	f8f6f4e3          	bgeu	a3,a5,800039f0 <writei+0x4c>
    80003a6c:	89ba                	mv	s3,a4
    80003a6e:	b749                	j	800039f0 <writei+0x4c>
      brelse(bp);
    80003a70:	8526                	mv	a0,s1
    80003a72:	fffff097          	auipc	ra,0xfffff
    80003a76:	4da080e7          	jalr	1242(ra) # 80002f4c <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003a7a:	04cba783          	lw	a5,76(s7)
    80003a7e:	0127f463          	bgeu	a5,s2,80003a86 <writei+0xe2>
      ip->size = off;
    80003a82:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003a86:	855e                	mv	a0,s7
    80003a88:	00000097          	auipc	ra,0x0
    80003a8c:	ace080e7          	jalr	-1330(ra) # 80003556 <iupdate>
  }

  return n;
    80003a90:	000b051b          	sext.w	a0,s6
}
    80003a94:	70a6                	ld	ra,104(sp)
    80003a96:	7406                	ld	s0,96(sp)
    80003a98:	64e6                	ld	s1,88(sp)
    80003a9a:	6946                	ld	s2,80(sp)
    80003a9c:	69a6                	ld	s3,72(sp)
    80003a9e:	6a06                	ld	s4,64(sp)
    80003aa0:	7ae2                	ld	s5,56(sp)
    80003aa2:	7b42                	ld	s6,48(sp)
    80003aa4:	7ba2                	ld	s7,40(sp)
    80003aa6:	7c02                	ld	s8,32(sp)
    80003aa8:	6ce2                	ld	s9,24(sp)
    80003aaa:	6d42                	ld	s10,16(sp)
    80003aac:	6da2                	ld	s11,8(sp)
    80003aae:	6165                	addi	sp,sp,112
    80003ab0:	8082                	ret
    return -1;
    80003ab2:	557d                	li	a0,-1
}
    80003ab4:	8082                	ret
    return -1;
    80003ab6:	557d                	li	a0,-1
    80003ab8:	bff1                	j	80003a94 <writei+0xf0>
    return -1;
    80003aba:	557d                	li	a0,-1
    80003abc:	bfe1                	j	80003a94 <writei+0xf0>

0000000080003abe <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003abe:	1141                	addi	sp,sp,-16
    80003ac0:	e406                	sd	ra,8(sp)
    80003ac2:	e022                	sd	s0,0(sp)
    80003ac4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ac6:	4639                	li	a2,14
    80003ac8:	ffffd097          	auipc	ra,0xffffd
    80003acc:	192080e7          	jalr	402(ra) # 80000c5a <strncmp>
}
    80003ad0:	60a2                	ld	ra,8(sp)
    80003ad2:	6402                	ld	s0,0(sp)
    80003ad4:	0141                	addi	sp,sp,16
    80003ad6:	8082                	ret

0000000080003ad8 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003ad8:	7139                	addi	sp,sp,-64
    80003ada:	fc06                	sd	ra,56(sp)
    80003adc:	f822                	sd	s0,48(sp)
    80003ade:	f426                	sd	s1,40(sp)
    80003ae0:	f04a                	sd	s2,32(sp)
    80003ae2:	ec4e                	sd	s3,24(sp)
    80003ae4:	e852                	sd	s4,16(sp)
    80003ae6:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ae8:	04451703          	lh	a4,68(a0)
    80003aec:	4785                	li	a5,1
    80003aee:	00f71a63          	bne	a4,a5,80003b02 <dirlookup+0x2a>
    80003af2:	892a                	mv	s2,a0
    80003af4:	89ae                	mv	s3,a1
    80003af6:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003af8:	457c                	lw	a5,76(a0)
    80003afa:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003afc:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003afe:	e79d                	bnez	a5,80003b2c <dirlookup+0x54>
    80003b00:	a8a5                	j	80003b78 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003b02:	00005517          	auipc	a0,0x5
    80003b06:	b4650513          	addi	a0,a0,-1210 # 80008648 <userret+0x5b8>
    80003b0a:	ffffd097          	auipc	ra,0xffffd
    80003b0e:	a3e080e7          	jalr	-1474(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003b12:	00005517          	auipc	a0,0x5
    80003b16:	b4e50513          	addi	a0,a0,-1202 # 80008660 <userret+0x5d0>
    80003b1a:	ffffd097          	auipc	ra,0xffffd
    80003b1e:	a2e080e7          	jalr	-1490(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b22:	24c1                	addiw	s1,s1,16
    80003b24:	04c92783          	lw	a5,76(s2)
    80003b28:	04f4f763          	bgeu	s1,a5,80003b76 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b2c:	4741                	li	a4,16
    80003b2e:	86a6                	mv	a3,s1
    80003b30:	fc040613          	addi	a2,s0,-64
    80003b34:	4581                	li	a1,0
    80003b36:	854a                	mv	a0,s2
    80003b38:	00000097          	auipc	ra,0x0
    80003b3c:	d78080e7          	jalr	-648(ra) # 800038b0 <readi>
    80003b40:	47c1                	li	a5,16
    80003b42:	fcf518e3          	bne	a0,a5,80003b12 <dirlookup+0x3a>
    if(de.inum == 0)
    80003b46:	fc045783          	lhu	a5,-64(s0)
    80003b4a:	dfe1                	beqz	a5,80003b22 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003b4c:	fc240593          	addi	a1,s0,-62
    80003b50:	854e                	mv	a0,s3
    80003b52:	00000097          	auipc	ra,0x0
    80003b56:	f6c080e7          	jalr	-148(ra) # 80003abe <namecmp>
    80003b5a:	f561                	bnez	a0,80003b22 <dirlookup+0x4a>
      if(poff)
    80003b5c:	000a0463          	beqz	s4,80003b64 <dirlookup+0x8c>
        *poff = off;
    80003b60:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003b64:	fc045583          	lhu	a1,-64(s0)
    80003b68:	00092503          	lw	a0,0(s2)
    80003b6c:	fffff097          	auipc	ra,0xfffff
    80003b70:	780080e7          	jalr	1920(ra) # 800032ec <iget>
    80003b74:	a011                	j	80003b78 <dirlookup+0xa0>
  return 0;
    80003b76:	4501                	li	a0,0
}
    80003b78:	70e2                	ld	ra,56(sp)
    80003b7a:	7442                	ld	s0,48(sp)
    80003b7c:	74a2                	ld	s1,40(sp)
    80003b7e:	7902                	ld	s2,32(sp)
    80003b80:	69e2                	ld	s3,24(sp)
    80003b82:	6a42                	ld	s4,16(sp)
    80003b84:	6121                	addi	sp,sp,64
    80003b86:	8082                	ret

0000000080003b88 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003b88:	711d                	addi	sp,sp,-96
    80003b8a:	ec86                	sd	ra,88(sp)
    80003b8c:	e8a2                	sd	s0,80(sp)
    80003b8e:	e4a6                	sd	s1,72(sp)
    80003b90:	e0ca                	sd	s2,64(sp)
    80003b92:	fc4e                	sd	s3,56(sp)
    80003b94:	f852                	sd	s4,48(sp)
    80003b96:	f456                	sd	s5,40(sp)
    80003b98:	f05a                	sd	s6,32(sp)
    80003b9a:	ec5e                	sd	s7,24(sp)
    80003b9c:	e862                	sd	s8,16(sp)
    80003b9e:	e466                	sd	s9,8(sp)
    80003ba0:	1080                	addi	s0,sp,96
    80003ba2:	84aa                	mv	s1,a0
    80003ba4:	8aae                	mv	s5,a1
    80003ba6:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003ba8:	00054703          	lbu	a4,0(a0)
    80003bac:	02f00793          	li	a5,47
    80003bb0:	02f70363          	beq	a4,a5,80003bd6 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003bb4:	ffffe097          	auipc	ra,0xffffe
    80003bb8:	d56080e7          	jalr	-682(ra) # 8000190a <myproc>
    80003bbc:	15853503          	ld	a0,344(a0)
    80003bc0:	00000097          	auipc	ra,0x0
    80003bc4:	a22080e7          	jalr	-1502(ra) # 800035e2 <idup>
    80003bc8:	89aa                	mv	s3,a0
  while(*path == '/')
    80003bca:	02f00913          	li	s2,47
  len = path - s;
    80003bce:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003bd0:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003bd2:	4b85                	li	s7,1
    80003bd4:	a865                	j	80003c8c <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003bd6:	4585                	li	a1,1
    80003bd8:	4501                	li	a0,0
    80003bda:	fffff097          	auipc	ra,0xfffff
    80003bde:	712080e7          	jalr	1810(ra) # 800032ec <iget>
    80003be2:	89aa                	mv	s3,a0
    80003be4:	b7dd                	j	80003bca <namex+0x42>
      iunlockput(ip);
    80003be6:	854e                	mv	a0,s3
    80003be8:	00000097          	auipc	ra,0x0
    80003bec:	c76080e7          	jalr	-906(ra) # 8000385e <iunlockput>
      return 0;
    80003bf0:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003bf2:	854e                	mv	a0,s3
    80003bf4:	60e6                	ld	ra,88(sp)
    80003bf6:	6446                	ld	s0,80(sp)
    80003bf8:	64a6                	ld	s1,72(sp)
    80003bfa:	6906                	ld	s2,64(sp)
    80003bfc:	79e2                	ld	s3,56(sp)
    80003bfe:	7a42                	ld	s4,48(sp)
    80003c00:	7aa2                	ld	s5,40(sp)
    80003c02:	7b02                	ld	s6,32(sp)
    80003c04:	6be2                	ld	s7,24(sp)
    80003c06:	6c42                	ld	s8,16(sp)
    80003c08:	6ca2                	ld	s9,8(sp)
    80003c0a:	6125                	addi	sp,sp,96
    80003c0c:	8082                	ret
      iunlock(ip);
    80003c0e:	854e                	mv	a0,s3
    80003c10:	00000097          	auipc	ra,0x0
    80003c14:	ad2080e7          	jalr	-1326(ra) # 800036e2 <iunlock>
      return ip;
    80003c18:	bfe9                	j	80003bf2 <namex+0x6a>
      iunlockput(ip);
    80003c1a:	854e                	mv	a0,s3
    80003c1c:	00000097          	auipc	ra,0x0
    80003c20:	c42080e7          	jalr	-958(ra) # 8000385e <iunlockput>
      return 0;
    80003c24:	89e6                	mv	s3,s9
    80003c26:	b7f1                	j	80003bf2 <namex+0x6a>
  len = path - s;
    80003c28:	40b48633          	sub	a2,s1,a1
    80003c2c:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003c30:	099c5463          	bge	s8,s9,80003cb8 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003c34:	4639                	li	a2,14
    80003c36:	8552                	mv	a0,s4
    80003c38:	ffffd097          	auipc	ra,0xffffd
    80003c3c:	fa6080e7          	jalr	-90(ra) # 80000bde <memmove>
  while(*path == '/')
    80003c40:	0004c783          	lbu	a5,0(s1)
    80003c44:	01279763          	bne	a5,s2,80003c52 <namex+0xca>
    path++;
    80003c48:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003c4a:	0004c783          	lbu	a5,0(s1)
    80003c4e:	ff278de3          	beq	a5,s2,80003c48 <namex+0xc0>
    ilock(ip);
    80003c52:	854e                	mv	a0,s3
    80003c54:	00000097          	auipc	ra,0x0
    80003c58:	9cc080e7          	jalr	-1588(ra) # 80003620 <ilock>
    if(ip->type != T_DIR){
    80003c5c:	04499783          	lh	a5,68(s3)
    80003c60:	f97793e3          	bne	a5,s7,80003be6 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003c64:	000a8563          	beqz	s5,80003c6e <namex+0xe6>
    80003c68:	0004c783          	lbu	a5,0(s1)
    80003c6c:	d3cd                	beqz	a5,80003c0e <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003c6e:	865a                	mv	a2,s6
    80003c70:	85d2                	mv	a1,s4
    80003c72:	854e                	mv	a0,s3
    80003c74:	00000097          	auipc	ra,0x0
    80003c78:	e64080e7          	jalr	-412(ra) # 80003ad8 <dirlookup>
    80003c7c:	8caa                	mv	s9,a0
    80003c7e:	dd51                	beqz	a0,80003c1a <namex+0x92>
    iunlockput(ip);
    80003c80:	854e                	mv	a0,s3
    80003c82:	00000097          	auipc	ra,0x0
    80003c86:	bdc080e7          	jalr	-1060(ra) # 8000385e <iunlockput>
    ip = next;
    80003c8a:	89e6                	mv	s3,s9
  while(*path == '/')
    80003c8c:	0004c783          	lbu	a5,0(s1)
    80003c90:	05279763          	bne	a5,s2,80003cde <namex+0x156>
    path++;
    80003c94:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003c96:	0004c783          	lbu	a5,0(s1)
    80003c9a:	ff278de3          	beq	a5,s2,80003c94 <namex+0x10c>
  if(*path == 0)
    80003c9e:	c79d                	beqz	a5,80003ccc <namex+0x144>
    path++;
    80003ca0:	85a6                	mv	a1,s1
  len = path - s;
    80003ca2:	8cda                	mv	s9,s6
    80003ca4:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003ca6:	01278963          	beq	a5,s2,80003cb8 <namex+0x130>
    80003caa:	dfbd                	beqz	a5,80003c28 <namex+0xa0>
    path++;
    80003cac:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003cae:	0004c783          	lbu	a5,0(s1)
    80003cb2:	ff279ce3          	bne	a5,s2,80003caa <namex+0x122>
    80003cb6:	bf8d                	j	80003c28 <namex+0xa0>
    memmove(name, s, len);
    80003cb8:	2601                	sext.w	a2,a2
    80003cba:	8552                	mv	a0,s4
    80003cbc:	ffffd097          	auipc	ra,0xffffd
    80003cc0:	f22080e7          	jalr	-222(ra) # 80000bde <memmove>
    name[len] = 0;
    80003cc4:	9cd2                	add	s9,s9,s4
    80003cc6:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003cca:	bf9d                	j	80003c40 <namex+0xb8>
  if(nameiparent){
    80003ccc:	f20a83e3          	beqz	s5,80003bf2 <namex+0x6a>
    iput(ip);
    80003cd0:	854e                	mv	a0,s3
    80003cd2:	00000097          	auipc	ra,0x0
    80003cd6:	a5c080e7          	jalr	-1444(ra) # 8000372e <iput>
    return 0;
    80003cda:	4981                	li	s3,0
    80003cdc:	bf19                	j	80003bf2 <namex+0x6a>
  if(*path == 0)
    80003cde:	d7fd                	beqz	a5,80003ccc <namex+0x144>
  while(*path != '/' && *path != 0)
    80003ce0:	0004c783          	lbu	a5,0(s1)
    80003ce4:	85a6                	mv	a1,s1
    80003ce6:	b7d1                	j	80003caa <namex+0x122>

0000000080003ce8 <dirlink>:
{
    80003ce8:	7139                	addi	sp,sp,-64
    80003cea:	fc06                	sd	ra,56(sp)
    80003cec:	f822                	sd	s0,48(sp)
    80003cee:	f426                	sd	s1,40(sp)
    80003cf0:	f04a                	sd	s2,32(sp)
    80003cf2:	ec4e                	sd	s3,24(sp)
    80003cf4:	e852                	sd	s4,16(sp)
    80003cf6:	0080                	addi	s0,sp,64
    80003cf8:	892a                	mv	s2,a0
    80003cfa:	8a2e                	mv	s4,a1
    80003cfc:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003cfe:	4601                	li	a2,0
    80003d00:	00000097          	auipc	ra,0x0
    80003d04:	dd8080e7          	jalr	-552(ra) # 80003ad8 <dirlookup>
    80003d08:	e93d                	bnez	a0,80003d7e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d0a:	04c92483          	lw	s1,76(s2)
    80003d0e:	c49d                	beqz	s1,80003d3c <dirlink+0x54>
    80003d10:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d12:	4741                	li	a4,16
    80003d14:	86a6                	mv	a3,s1
    80003d16:	fc040613          	addi	a2,s0,-64
    80003d1a:	4581                	li	a1,0
    80003d1c:	854a                	mv	a0,s2
    80003d1e:	00000097          	auipc	ra,0x0
    80003d22:	b92080e7          	jalr	-1134(ra) # 800038b0 <readi>
    80003d26:	47c1                	li	a5,16
    80003d28:	06f51163          	bne	a0,a5,80003d8a <dirlink+0xa2>
    if(de.inum == 0)
    80003d2c:	fc045783          	lhu	a5,-64(s0)
    80003d30:	c791                	beqz	a5,80003d3c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d32:	24c1                	addiw	s1,s1,16
    80003d34:	04c92783          	lw	a5,76(s2)
    80003d38:	fcf4ede3          	bltu	s1,a5,80003d12 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003d3c:	4639                	li	a2,14
    80003d3e:	85d2                	mv	a1,s4
    80003d40:	fc240513          	addi	a0,s0,-62
    80003d44:	ffffd097          	auipc	ra,0xffffd
    80003d48:	f52080e7          	jalr	-174(ra) # 80000c96 <strncpy>
  de.inum = inum;
    80003d4c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d50:	4741                	li	a4,16
    80003d52:	86a6                	mv	a3,s1
    80003d54:	fc040613          	addi	a2,s0,-64
    80003d58:	4581                	li	a1,0
    80003d5a:	854a                	mv	a0,s2
    80003d5c:	00000097          	auipc	ra,0x0
    80003d60:	c48080e7          	jalr	-952(ra) # 800039a4 <writei>
    80003d64:	872a                	mv	a4,a0
    80003d66:	47c1                	li	a5,16
  return 0;
    80003d68:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d6a:	02f71863          	bne	a4,a5,80003d9a <dirlink+0xb2>
}
    80003d6e:	70e2                	ld	ra,56(sp)
    80003d70:	7442                	ld	s0,48(sp)
    80003d72:	74a2                	ld	s1,40(sp)
    80003d74:	7902                	ld	s2,32(sp)
    80003d76:	69e2                	ld	s3,24(sp)
    80003d78:	6a42                	ld	s4,16(sp)
    80003d7a:	6121                	addi	sp,sp,64
    80003d7c:	8082                	ret
    iput(ip);
    80003d7e:	00000097          	auipc	ra,0x0
    80003d82:	9b0080e7          	jalr	-1616(ra) # 8000372e <iput>
    return -1;
    80003d86:	557d                	li	a0,-1
    80003d88:	b7dd                	j	80003d6e <dirlink+0x86>
      panic("dirlink read");
    80003d8a:	00005517          	auipc	a0,0x5
    80003d8e:	8e650513          	addi	a0,a0,-1818 # 80008670 <userret+0x5e0>
    80003d92:	ffffc097          	auipc	ra,0xffffc
    80003d96:	7b6080e7          	jalr	1974(ra) # 80000548 <panic>
    panic("dirlink");
    80003d9a:	00005517          	auipc	a0,0x5
    80003d9e:	a8650513          	addi	a0,a0,-1402 # 80008820 <userret+0x790>
    80003da2:	ffffc097          	auipc	ra,0xffffc
    80003da6:	7a6080e7          	jalr	1958(ra) # 80000548 <panic>

0000000080003daa <namei>:

struct inode*
namei(char *path)
{
    80003daa:	1101                	addi	sp,sp,-32
    80003dac:	ec06                	sd	ra,24(sp)
    80003dae:	e822                	sd	s0,16(sp)
    80003db0:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003db2:	fe040613          	addi	a2,s0,-32
    80003db6:	4581                	li	a1,0
    80003db8:	00000097          	auipc	ra,0x0
    80003dbc:	dd0080e7          	jalr	-560(ra) # 80003b88 <namex>
}
    80003dc0:	60e2                	ld	ra,24(sp)
    80003dc2:	6442                	ld	s0,16(sp)
    80003dc4:	6105                	addi	sp,sp,32
    80003dc6:	8082                	ret

0000000080003dc8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003dc8:	1141                	addi	sp,sp,-16
    80003dca:	e406                	sd	ra,8(sp)
    80003dcc:	e022                	sd	s0,0(sp)
    80003dce:	0800                	addi	s0,sp,16
    80003dd0:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003dd2:	4585                	li	a1,1
    80003dd4:	00000097          	auipc	ra,0x0
    80003dd8:	db4080e7          	jalr	-588(ra) # 80003b88 <namex>
}
    80003ddc:	60a2                	ld	ra,8(sp)
    80003dde:	6402                	ld	s0,0(sp)
    80003de0:	0141                	addi	sp,sp,16
    80003de2:	8082                	ret

0000000080003de4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(int dev)
{
    80003de4:	7179                	addi	sp,sp,-48
    80003de6:	f406                	sd	ra,40(sp)
    80003de8:	f022                	sd	s0,32(sp)
    80003dea:	ec26                	sd	s1,24(sp)
    80003dec:	e84a                	sd	s2,16(sp)
    80003dee:	e44e                	sd	s3,8(sp)
    80003df0:	1800                	addi	s0,sp,48
    80003df2:	84aa                	mv	s1,a0
  struct buf *buf = bread(dev, log[dev].start);
    80003df4:	0a800993          	li	s3,168
    80003df8:	033507b3          	mul	a5,a0,s3
    80003dfc:	0001f997          	auipc	s3,0x1f
    80003e00:	d9c98993          	addi	s3,s3,-612 # 80022b98 <log>
    80003e04:	99be                	add	s3,s3,a5
    80003e06:	0189a583          	lw	a1,24(s3)
    80003e0a:	fffff097          	auipc	ra,0xfffff
    80003e0e:	00e080e7          	jalr	14(ra) # 80002e18 <bread>
    80003e12:	892a                	mv	s2,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log[dev].lh.n;
    80003e14:	02c9a783          	lw	a5,44(s3)
    80003e18:	d13c                	sw	a5,96(a0)
  for (i = 0; i < log[dev].lh.n; i++) {
    80003e1a:	02c9a783          	lw	a5,44(s3)
    80003e1e:	02f05763          	blez	a5,80003e4c <write_head+0x68>
    80003e22:	0a800793          	li	a5,168
    80003e26:	02f487b3          	mul	a5,s1,a5
    80003e2a:	0001f717          	auipc	a4,0x1f
    80003e2e:	d9e70713          	addi	a4,a4,-610 # 80022bc8 <log+0x30>
    80003e32:	97ba                	add	a5,a5,a4
    80003e34:	06450693          	addi	a3,a0,100
    80003e38:	4701                	li	a4,0
    80003e3a:	85ce                	mv	a1,s3
    hb->block[i] = log[dev].lh.block[i];
    80003e3c:	4390                	lw	a2,0(a5)
    80003e3e:	c290                	sw	a2,0(a3)
  for (i = 0; i < log[dev].lh.n; i++) {
    80003e40:	2705                	addiw	a4,a4,1
    80003e42:	0791                	addi	a5,a5,4
    80003e44:	0691                	addi	a3,a3,4
    80003e46:	55d0                	lw	a2,44(a1)
    80003e48:	fec74ae3          	blt	a4,a2,80003e3c <write_head+0x58>
  }
  bwrite(buf);
    80003e4c:	854a                	mv	a0,s2
    80003e4e:	fffff097          	auipc	ra,0xfffff
    80003e52:	0be080e7          	jalr	190(ra) # 80002f0c <bwrite>
  brelse(buf);
    80003e56:	854a                	mv	a0,s2
    80003e58:	fffff097          	auipc	ra,0xfffff
    80003e5c:	0f4080e7          	jalr	244(ra) # 80002f4c <brelse>
}
    80003e60:	70a2                	ld	ra,40(sp)
    80003e62:	7402                	ld	s0,32(sp)
    80003e64:	64e2                	ld	s1,24(sp)
    80003e66:	6942                	ld	s2,16(sp)
    80003e68:	69a2                	ld	s3,8(sp)
    80003e6a:	6145                	addi	sp,sp,48
    80003e6c:	8082                	ret

0000000080003e6e <write_log>:
static void
write_log(int dev)
{
  int tail;

  for (tail = 0; tail < log[dev].lh.n; tail++) {
    80003e6e:	0a800793          	li	a5,168
    80003e72:	02f50733          	mul	a4,a0,a5
    80003e76:	0001f797          	auipc	a5,0x1f
    80003e7a:	d2278793          	addi	a5,a5,-734 # 80022b98 <log>
    80003e7e:	97ba                	add	a5,a5,a4
    80003e80:	57dc                	lw	a5,44(a5)
    80003e82:	0af05663          	blez	a5,80003f2e <write_log+0xc0>
{
    80003e86:	7139                	addi	sp,sp,-64
    80003e88:	fc06                	sd	ra,56(sp)
    80003e8a:	f822                	sd	s0,48(sp)
    80003e8c:	f426                	sd	s1,40(sp)
    80003e8e:	f04a                	sd	s2,32(sp)
    80003e90:	ec4e                	sd	s3,24(sp)
    80003e92:	e852                	sd	s4,16(sp)
    80003e94:	e456                	sd	s5,8(sp)
    80003e96:	e05a                	sd	s6,0(sp)
    80003e98:	0080                	addi	s0,sp,64
    80003e9a:	0001f797          	auipc	a5,0x1f
    80003e9e:	d2e78793          	addi	a5,a5,-722 # 80022bc8 <log+0x30>
    80003ea2:	00f70a33          	add	s4,a4,a5
  for (tail = 0; tail < log[dev].lh.n; tail++) {
    80003ea6:	4981                	li	s3,0
    struct buf *to = bread(dev, log[dev].start+tail+1); // log block
    80003ea8:	00050b1b          	sext.w	s6,a0
    80003eac:	0001fa97          	auipc	s5,0x1f
    80003eb0:	ceca8a93          	addi	s5,s5,-788 # 80022b98 <log>
    80003eb4:	9aba                	add	s5,s5,a4
    80003eb6:	018aa583          	lw	a1,24(s5)
    80003eba:	013585bb          	addw	a1,a1,s3
    80003ebe:	2585                	addiw	a1,a1,1
    80003ec0:	855a                	mv	a0,s6
    80003ec2:	fffff097          	auipc	ra,0xfffff
    80003ec6:	f56080e7          	jalr	-170(ra) # 80002e18 <bread>
    80003eca:	84aa                	mv	s1,a0
    struct buf *from = bread(dev, log[dev].lh.block[tail]); // cache block
    80003ecc:	000a2583          	lw	a1,0(s4)
    80003ed0:	855a                	mv	a0,s6
    80003ed2:	fffff097          	auipc	ra,0xfffff
    80003ed6:	f46080e7          	jalr	-186(ra) # 80002e18 <bread>
    80003eda:	892a                	mv	s2,a0
    memmove(to->data, from->data, BSIZE);
    80003edc:	40000613          	li	a2,1024
    80003ee0:	06050593          	addi	a1,a0,96
    80003ee4:	06048513          	addi	a0,s1,96
    80003ee8:	ffffd097          	auipc	ra,0xffffd
    80003eec:	cf6080e7          	jalr	-778(ra) # 80000bde <memmove>
    bwrite(to);  // write the log
    80003ef0:	8526                	mv	a0,s1
    80003ef2:	fffff097          	auipc	ra,0xfffff
    80003ef6:	01a080e7          	jalr	26(ra) # 80002f0c <bwrite>
    brelse(from);
    80003efa:	854a                	mv	a0,s2
    80003efc:	fffff097          	auipc	ra,0xfffff
    80003f00:	050080e7          	jalr	80(ra) # 80002f4c <brelse>
    brelse(to);
    80003f04:	8526                	mv	a0,s1
    80003f06:	fffff097          	auipc	ra,0xfffff
    80003f0a:	046080e7          	jalr	70(ra) # 80002f4c <brelse>
  for (tail = 0; tail < log[dev].lh.n; tail++) {
    80003f0e:	2985                	addiw	s3,s3,1
    80003f10:	0a11                	addi	s4,s4,4
    80003f12:	02caa783          	lw	a5,44(s5)
    80003f16:	faf9c0e3          	blt	s3,a5,80003eb6 <write_log+0x48>
  }
}
    80003f1a:	70e2                	ld	ra,56(sp)
    80003f1c:	7442                	ld	s0,48(sp)
    80003f1e:	74a2                	ld	s1,40(sp)
    80003f20:	7902                	ld	s2,32(sp)
    80003f22:	69e2                	ld	s3,24(sp)
    80003f24:	6a42                	ld	s4,16(sp)
    80003f26:	6aa2                	ld	s5,8(sp)
    80003f28:	6b02                	ld	s6,0(sp)
    80003f2a:	6121                	addi	sp,sp,64
    80003f2c:	8082                	ret
    80003f2e:	8082                	ret

0000000080003f30 <install_trans>:
  for (tail = 0; tail < log[dev].lh.n; tail++) {
    80003f30:	0a800793          	li	a5,168
    80003f34:	02f50733          	mul	a4,a0,a5
    80003f38:	0001f797          	auipc	a5,0x1f
    80003f3c:	c6078793          	addi	a5,a5,-928 # 80022b98 <log>
    80003f40:	97ba                	add	a5,a5,a4
    80003f42:	57dc                	lw	a5,44(a5)
    80003f44:	0af05b63          	blez	a5,80003ffa <install_trans+0xca>
{
    80003f48:	7139                	addi	sp,sp,-64
    80003f4a:	fc06                	sd	ra,56(sp)
    80003f4c:	f822                	sd	s0,48(sp)
    80003f4e:	f426                	sd	s1,40(sp)
    80003f50:	f04a                	sd	s2,32(sp)
    80003f52:	ec4e                	sd	s3,24(sp)
    80003f54:	e852                	sd	s4,16(sp)
    80003f56:	e456                	sd	s5,8(sp)
    80003f58:	e05a                	sd	s6,0(sp)
    80003f5a:	0080                	addi	s0,sp,64
    80003f5c:	0001f797          	auipc	a5,0x1f
    80003f60:	c6c78793          	addi	a5,a5,-916 # 80022bc8 <log+0x30>
    80003f64:	00f70a33          	add	s4,a4,a5
  for (tail = 0; tail < log[dev].lh.n; tail++) {
    80003f68:	4981                	li	s3,0
    struct buf *lbuf = bread(dev, log[dev].start+tail+1); // read log block
    80003f6a:	00050b1b          	sext.w	s6,a0
    80003f6e:	0001fa97          	auipc	s5,0x1f
    80003f72:	c2aa8a93          	addi	s5,s5,-982 # 80022b98 <log>
    80003f76:	9aba                	add	s5,s5,a4
    80003f78:	018aa583          	lw	a1,24(s5)
    80003f7c:	013585bb          	addw	a1,a1,s3
    80003f80:	2585                	addiw	a1,a1,1
    80003f82:	855a                	mv	a0,s6
    80003f84:	fffff097          	auipc	ra,0xfffff
    80003f88:	e94080e7          	jalr	-364(ra) # 80002e18 <bread>
    80003f8c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(dev, log[dev].lh.block[tail]); // read dst
    80003f8e:	000a2583          	lw	a1,0(s4)
    80003f92:	855a                	mv	a0,s6
    80003f94:	fffff097          	auipc	ra,0xfffff
    80003f98:	e84080e7          	jalr	-380(ra) # 80002e18 <bread>
    80003f9c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f9e:	40000613          	li	a2,1024
    80003fa2:	06090593          	addi	a1,s2,96
    80003fa6:	06050513          	addi	a0,a0,96
    80003faa:	ffffd097          	auipc	ra,0xffffd
    80003fae:	c34080e7          	jalr	-972(ra) # 80000bde <memmove>
    bwrite(dbuf);  // write dst to disk
    80003fb2:	8526                	mv	a0,s1
    80003fb4:	fffff097          	auipc	ra,0xfffff
    80003fb8:	f58080e7          	jalr	-168(ra) # 80002f0c <bwrite>
    bunpin(dbuf);
    80003fbc:	8526                	mv	a0,s1
    80003fbe:	fffff097          	auipc	ra,0xfffff
    80003fc2:	068080e7          	jalr	104(ra) # 80003026 <bunpin>
    brelse(lbuf);
    80003fc6:	854a                	mv	a0,s2
    80003fc8:	fffff097          	auipc	ra,0xfffff
    80003fcc:	f84080e7          	jalr	-124(ra) # 80002f4c <brelse>
    brelse(dbuf);
    80003fd0:	8526                	mv	a0,s1
    80003fd2:	fffff097          	auipc	ra,0xfffff
    80003fd6:	f7a080e7          	jalr	-134(ra) # 80002f4c <brelse>
  for (tail = 0; tail < log[dev].lh.n; tail++) {
    80003fda:	2985                	addiw	s3,s3,1
    80003fdc:	0a11                	addi	s4,s4,4
    80003fde:	02caa783          	lw	a5,44(s5)
    80003fe2:	f8f9cbe3          	blt	s3,a5,80003f78 <install_trans+0x48>
}
    80003fe6:	70e2                	ld	ra,56(sp)
    80003fe8:	7442                	ld	s0,48(sp)
    80003fea:	74a2                	ld	s1,40(sp)
    80003fec:	7902                	ld	s2,32(sp)
    80003fee:	69e2                	ld	s3,24(sp)
    80003ff0:	6a42                	ld	s4,16(sp)
    80003ff2:	6aa2                	ld	s5,8(sp)
    80003ff4:	6b02                	ld	s6,0(sp)
    80003ff6:	6121                	addi	sp,sp,64
    80003ff8:	8082                	ret
    80003ffa:	8082                	ret

0000000080003ffc <initlog>:
{
    80003ffc:	7179                	addi	sp,sp,-48
    80003ffe:	f406                	sd	ra,40(sp)
    80004000:	f022                	sd	s0,32(sp)
    80004002:	ec26                	sd	s1,24(sp)
    80004004:	e84a                	sd	s2,16(sp)
    80004006:	e44e                	sd	s3,8(sp)
    80004008:	e052                	sd	s4,0(sp)
    8000400a:	1800                	addi	s0,sp,48
    8000400c:	892a                	mv	s2,a0
    8000400e:	8a2e                	mv	s4,a1
  initlock(&log[dev].lock, "log");
    80004010:	0a800713          	li	a4,168
    80004014:	02e504b3          	mul	s1,a0,a4
    80004018:	0001f997          	auipc	s3,0x1f
    8000401c:	b8098993          	addi	s3,s3,-1152 # 80022b98 <log>
    80004020:	99a6                	add	s3,s3,s1
    80004022:	00004597          	auipc	a1,0x4
    80004026:	65e58593          	addi	a1,a1,1630 # 80008680 <userret+0x5f0>
    8000402a:	854e                	mv	a0,s3
    8000402c:	ffffd097          	auipc	ra,0xffffd
    80004030:	984080e7          	jalr	-1660(ra) # 800009b0 <initlock>
  log[dev].start = sb->logstart;
    80004034:	014a2583          	lw	a1,20(s4)
    80004038:	00b9ac23          	sw	a1,24(s3)
  log[dev].size = sb->nlog;
    8000403c:	010a2783          	lw	a5,16(s4)
    80004040:	00f9ae23          	sw	a5,28(s3)
  log[dev].dev = dev;
    80004044:	0329a423          	sw	s2,40(s3)
  struct buf *buf = bread(dev, log[dev].start);
    80004048:	854a                	mv	a0,s2
    8000404a:	fffff097          	auipc	ra,0xfffff
    8000404e:	dce080e7          	jalr	-562(ra) # 80002e18 <bread>
  log[dev].lh.n = lh->n;
    80004052:	5134                	lw	a3,96(a0)
    80004054:	02d9a623          	sw	a3,44(s3)
  for (i = 0; i < log[dev].lh.n; i++) {
    80004058:	02d05763          	blez	a3,80004086 <initlog+0x8a>
    8000405c:	06450793          	addi	a5,a0,100
    80004060:	0001f717          	auipc	a4,0x1f
    80004064:	b6870713          	addi	a4,a4,-1176 # 80022bc8 <log+0x30>
    80004068:	9726                	add	a4,a4,s1
    8000406a:	36fd                	addiw	a3,a3,-1
    8000406c:	02069613          	slli	a2,a3,0x20
    80004070:	01e65693          	srli	a3,a2,0x1e
    80004074:	06850613          	addi	a2,a0,104
    80004078:	96b2                	add	a3,a3,a2
    log[dev].lh.block[i] = lh->block[i];
    8000407a:	4390                	lw	a2,0(a5)
    8000407c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log[dev].lh.n; i++) {
    8000407e:	0791                	addi	a5,a5,4
    80004080:	0711                	addi	a4,a4,4
    80004082:	fed79ce3          	bne	a5,a3,8000407a <initlog+0x7e>
  brelse(buf);
    80004086:	fffff097          	auipc	ra,0xfffff
    8000408a:	ec6080e7          	jalr	-314(ra) # 80002f4c <brelse>
  install_trans(dev); // if committed, copy from log to disk
    8000408e:	854a                	mv	a0,s2
    80004090:	00000097          	auipc	ra,0x0
    80004094:	ea0080e7          	jalr	-352(ra) # 80003f30 <install_trans>
  log[dev].lh.n = 0;
    80004098:	0a800793          	li	a5,168
    8000409c:	02f90733          	mul	a4,s2,a5
    800040a0:	0001f797          	auipc	a5,0x1f
    800040a4:	af878793          	addi	a5,a5,-1288 # 80022b98 <log>
    800040a8:	97ba                	add	a5,a5,a4
    800040aa:	0207a623          	sw	zero,44(a5)
  write_head(dev); // clear the log
    800040ae:	854a                	mv	a0,s2
    800040b0:	00000097          	auipc	ra,0x0
    800040b4:	d34080e7          	jalr	-716(ra) # 80003de4 <write_head>
}
    800040b8:	70a2                	ld	ra,40(sp)
    800040ba:	7402                	ld	s0,32(sp)
    800040bc:	64e2                	ld	s1,24(sp)
    800040be:	6942                	ld	s2,16(sp)
    800040c0:	69a2                	ld	s3,8(sp)
    800040c2:	6a02                	ld	s4,0(sp)
    800040c4:	6145                	addi	sp,sp,48
    800040c6:	8082                	ret

00000000800040c8 <begin_op>:
{
    800040c8:	7139                	addi	sp,sp,-64
    800040ca:	fc06                	sd	ra,56(sp)
    800040cc:	f822                	sd	s0,48(sp)
    800040ce:	f426                	sd	s1,40(sp)
    800040d0:	f04a                	sd	s2,32(sp)
    800040d2:	ec4e                	sd	s3,24(sp)
    800040d4:	e852                	sd	s4,16(sp)
    800040d6:	e456                	sd	s5,8(sp)
    800040d8:	0080                	addi	s0,sp,64
    800040da:	8aaa                	mv	s5,a0
  acquire(&log[dev].lock);
    800040dc:	0a800913          	li	s2,168
    800040e0:	032507b3          	mul	a5,a0,s2
    800040e4:	0001f917          	auipc	s2,0x1f
    800040e8:	ab490913          	addi	s2,s2,-1356 # 80022b98 <log>
    800040ec:	993e                	add	s2,s2,a5
    800040ee:	854a                	mv	a0,s2
    800040f0:	ffffd097          	auipc	ra,0xffffd
    800040f4:	9ce080e7          	jalr	-1586(ra) # 80000abe <acquire>
    if(log[dev].committing){
    800040f8:	0001f997          	auipc	s3,0x1f
    800040fc:	aa098993          	addi	s3,s3,-1376 # 80022b98 <log>
    80004100:	84ca                	mv	s1,s2
    } else if(log[dev].lh.n + (log[dev].outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004102:	4a79                	li	s4,30
    80004104:	a039                	j	80004112 <begin_op+0x4a>
      sleep(&log, &log[dev].lock);
    80004106:	85ca                	mv	a1,s2
    80004108:	854e                	mv	a0,s3
    8000410a:	ffffe097          	auipc	ra,0xffffe
    8000410e:	fde080e7          	jalr	-34(ra) # 800020e8 <sleep>
    if(log[dev].committing){
    80004112:	50dc                	lw	a5,36(s1)
    80004114:	fbed                	bnez	a5,80004106 <begin_op+0x3e>
    } else if(log[dev].lh.n + (log[dev].outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004116:	509c                	lw	a5,32(s1)
    80004118:	0017871b          	addiw	a4,a5,1
    8000411c:	0007069b          	sext.w	a3,a4
    80004120:	0027179b          	slliw	a5,a4,0x2
    80004124:	9fb9                	addw	a5,a5,a4
    80004126:	0017979b          	slliw	a5,a5,0x1
    8000412a:	54d8                	lw	a4,44(s1)
    8000412c:	9fb9                	addw	a5,a5,a4
    8000412e:	00fa5963          	bge	s4,a5,80004140 <begin_op+0x78>
      sleep(&log, &log[dev].lock);
    80004132:	85ca                	mv	a1,s2
    80004134:	854e                	mv	a0,s3
    80004136:	ffffe097          	auipc	ra,0xffffe
    8000413a:	fb2080e7          	jalr	-78(ra) # 800020e8 <sleep>
    8000413e:	bfd1                	j	80004112 <begin_op+0x4a>
      log[dev].outstanding += 1;
    80004140:	0a800513          	li	a0,168
    80004144:	02aa8ab3          	mul	s5,s5,a0
    80004148:	0001f797          	auipc	a5,0x1f
    8000414c:	a5078793          	addi	a5,a5,-1456 # 80022b98 <log>
    80004150:	9abe                	add	s5,s5,a5
    80004152:	02daa023          	sw	a3,32(s5)
      release(&log[dev].lock);
    80004156:	854a                	mv	a0,s2
    80004158:	ffffd097          	auipc	ra,0xffffd
    8000415c:	9ce080e7          	jalr	-1586(ra) # 80000b26 <release>
}
    80004160:	70e2                	ld	ra,56(sp)
    80004162:	7442                	ld	s0,48(sp)
    80004164:	74a2                	ld	s1,40(sp)
    80004166:	7902                	ld	s2,32(sp)
    80004168:	69e2                	ld	s3,24(sp)
    8000416a:	6a42                	ld	s4,16(sp)
    8000416c:	6aa2                	ld	s5,8(sp)
    8000416e:	6121                	addi	sp,sp,64
    80004170:	8082                	ret

0000000080004172 <end_op>:
{
    80004172:	7179                	addi	sp,sp,-48
    80004174:	f406                	sd	ra,40(sp)
    80004176:	f022                	sd	s0,32(sp)
    80004178:	ec26                	sd	s1,24(sp)
    8000417a:	e84a                	sd	s2,16(sp)
    8000417c:	e44e                	sd	s3,8(sp)
    8000417e:	1800                	addi	s0,sp,48
    80004180:	892a                	mv	s2,a0
  acquire(&log[dev].lock);
    80004182:	0a800493          	li	s1,168
    80004186:	029507b3          	mul	a5,a0,s1
    8000418a:	0001f497          	auipc	s1,0x1f
    8000418e:	a0e48493          	addi	s1,s1,-1522 # 80022b98 <log>
    80004192:	94be                	add	s1,s1,a5
    80004194:	8526                	mv	a0,s1
    80004196:	ffffd097          	auipc	ra,0xffffd
    8000419a:	928080e7          	jalr	-1752(ra) # 80000abe <acquire>
  log[dev].outstanding -= 1;
    8000419e:	509c                	lw	a5,32(s1)
    800041a0:	37fd                	addiw	a5,a5,-1
    800041a2:	0007871b          	sext.w	a4,a5
    800041a6:	d09c                	sw	a5,32(s1)
  if(log[dev].committing)
    800041a8:	50dc                	lw	a5,36(s1)
    800041aa:	e3ad                	bnez	a5,8000420c <end_op+0x9a>
  if(log[dev].outstanding == 0){
    800041ac:	eb25                	bnez	a4,8000421c <end_op+0xaa>
    log[dev].committing = 1;
    800041ae:	0a800993          	li	s3,168
    800041b2:	033907b3          	mul	a5,s2,s3
    800041b6:	0001f997          	auipc	s3,0x1f
    800041ba:	9e298993          	addi	s3,s3,-1566 # 80022b98 <log>
    800041be:	99be                	add	s3,s3,a5
    800041c0:	4785                	li	a5,1
    800041c2:	02f9a223          	sw	a5,36(s3)
  release(&log[dev].lock);
    800041c6:	8526                	mv	a0,s1
    800041c8:	ffffd097          	auipc	ra,0xffffd
    800041cc:	95e080e7          	jalr	-1698(ra) # 80000b26 <release>

static void
commit(int dev)
{
  if (log[dev].lh.n > 0) {
    800041d0:	02c9a783          	lw	a5,44(s3)
    800041d4:	06f04863          	bgtz	a5,80004244 <end_op+0xd2>
    acquire(&log[dev].lock);
    800041d8:	8526                	mv	a0,s1
    800041da:	ffffd097          	auipc	ra,0xffffd
    800041de:	8e4080e7          	jalr	-1820(ra) # 80000abe <acquire>
    log[dev].committing = 0;
    800041e2:	0001f517          	auipc	a0,0x1f
    800041e6:	9b650513          	addi	a0,a0,-1610 # 80022b98 <log>
    800041ea:	0a800793          	li	a5,168
    800041ee:	02f90933          	mul	s2,s2,a5
    800041f2:	992a                	add	s2,s2,a0
    800041f4:	02092223          	sw	zero,36(s2)
    wakeup(&log);
    800041f8:	ffffe097          	auipc	ra,0xffffe
    800041fc:	070080e7          	jalr	112(ra) # 80002268 <wakeup>
    release(&log[dev].lock);
    80004200:	8526                	mv	a0,s1
    80004202:	ffffd097          	auipc	ra,0xffffd
    80004206:	924080e7          	jalr	-1756(ra) # 80000b26 <release>
}
    8000420a:	a035                	j	80004236 <end_op+0xc4>
    panic("log[dev].committing");
    8000420c:	00004517          	auipc	a0,0x4
    80004210:	47c50513          	addi	a0,a0,1148 # 80008688 <userret+0x5f8>
    80004214:	ffffc097          	auipc	ra,0xffffc
    80004218:	334080e7          	jalr	820(ra) # 80000548 <panic>
    wakeup(&log);
    8000421c:	0001f517          	auipc	a0,0x1f
    80004220:	97c50513          	addi	a0,a0,-1668 # 80022b98 <log>
    80004224:	ffffe097          	auipc	ra,0xffffe
    80004228:	044080e7          	jalr	68(ra) # 80002268 <wakeup>
  release(&log[dev].lock);
    8000422c:	8526                	mv	a0,s1
    8000422e:	ffffd097          	auipc	ra,0xffffd
    80004232:	8f8080e7          	jalr	-1800(ra) # 80000b26 <release>
}
    80004236:	70a2                	ld	ra,40(sp)
    80004238:	7402                	ld	s0,32(sp)
    8000423a:	64e2                	ld	s1,24(sp)
    8000423c:	6942                	ld	s2,16(sp)
    8000423e:	69a2                	ld	s3,8(sp)
    80004240:	6145                	addi	sp,sp,48
    80004242:	8082                	ret
    write_log(dev);     // Write modified blocks from cache to log
    80004244:	854a                	mv	a0,s2
    80004246:	00000097          	auipc	ra,0x0
    8000424a:	c28080e7          	jalr	-984(ra) # 80003e6e <write_log>
    write_head(dev);    // Write header to disk -- the real commit
    8000424e:	854a                	mv	a0,s2
    80004250:	00000097          	auipc	ra,0x0
    80004254:	b94080e7          	jalr	-1132(ra) # 80003de4 <write_head>
    install_trans(dev); // Now install writes to home locations
    80004258:	854a                	mv	a0,s2
    8000425a:	00000097          	auipc	ra,0x0
    8000425e:	cd6080e7          	jalr	-810(ra) # 80003f30 <install_trans>
    log[dev].lh.n = 0;
    80004262:	0a800793          	li	a5,168
    80004266:	02f90733          	mul	a4,s2,a5
    8000426a:	0001f797          	auipc	a5,0x1f
    8000426e:	92e78793          	addi	a5,a5,-1746 # 80022b98 <log>
    80004272:	97ba                	add	a5,a5,a4
    80004274:	0207a623          	sw	zero,44(a5)
    write_head(dev);    // Erase the transaction from the log
    80004278:	854a                	mv	a0,s2
    8000427a:	00000097          	auipc	ra,0x0
    8000427e:	b6a080e7          	jalr	-1174(ra) # 80003de4 <write_head>
    80004282:	bf99                	j	800041d8 <end_op+0x66>

0000000080004284 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004284:	7179                	addi	sp,sp,-48
    80004286:	f406                	sd	ra,40(sp)
    80004288:	f022                	sd	s0,32(sp)
    8000428a:	ec26                	sd	s1,24(sp)
    8000428c:	e84a                	sd	s2,16(sp)
    8000428e:	e44e                	sd	s3,8(sp)
    80004290:	e052                	sd	s4,0(sp)
    80004292:	1800                	addi	s0,sp,48
  int i;

  int dev = b->dev;
    80004294:	00852903          	lw	s2,8(a0)
  if (log[dev].lh.n >= LOGSIZE || log[dev].lh.n >= log[dev].size - 1)
    80004298:	0a800793          	li	a5,168
    8000429c:	02f90733          	mul	a4,s2,a5
    800042a0:	0001f797          	auipc	a5,0x1f
    800042a4:	8f878793          	addi	a5,a5,-1800 # 80022b98 <log>
    800042a8:	97ba                	add	a5,a5,a4
    800042aa:	57d4                	lw	a3,44(a5)
    800042ac:	47f5                	li	a5,29
    800042ae:	0ad7cc63          	blt	a5,a3,80004366 <log_write+0xe2>
    800042b2:	89aa                	mv	s3,a0
    800042b4:	0001f797          	auipc	a5,0x1f
    800042b8:	8e478793          	addi	a5,a5,-1820 # 80022b98 <log>
    800042bc:	97ba                	add	a5,a5,a4
    800042be:	4fdc                	lw	a5,28(a5)
    800042c0:	37fd                	addiw	a5,a5,-1
    800042c2:	0af6d263          	bge	a3,a5,80004366 <log_write+0xe2>
    panic("too big a transaction");
  if (log[dev].outstanding < 1)
    800042c6:	0a800793          	li	a5,168
    800042ca:	02f90733          	mul	a4,s2,a5
    800042ce:	0001f797          	auipc	a5,0x1f
    800042d2:	8ca78793          	addi	a5,a5,-1846 # 80022b98 <log>
    800042d6:	97ba                	add	a5,a5,a4
    800042d8:	539c                	lw	a5,32(a5)
    800042da:	08f05e63          	blez	a5,80004376 <log_write+0xf2>
    panic("log_write outside of trans");

  acquire(&log[dev].lock);
    800042de:	0a800793          	li	a5,168
    800042e2:	02f904b3          	mul	s1,s2,a5
    800042e6:	0001fa17          	auipc	s4,0x1f
    800042ea:	8b2a0a13          	addi	s4,s4,-1870 # 80022b98 <log>
    800042ee:	9a26                	add	s4,s4,s1
    800042f0:	8552                	mv	a0,s4
    800042f2:	ffffc097          	auipc	ra,0xffffc
    800042f6:	7cc080e7          	jalr	1996(ra) # 80000abe <acquire>
  for (i = 0; i < log[dev].lh.n; i++) {
    800042fa:	02ca2603          	lw	a2,44(s4)
    800042fe:	08c05463          	blez	a2,80004386 <log_write+0x102>
    if (log[dev].lh.block[i] == b->blockno)   // log absorbtion
    80004302:	00c9a583          	lw	a1,12(s3)
    80004306:	0001f797          	auipc	a5,0x1f
    8000430a:	8c278793          	addi	a5,a5,-1854 # 80022bc8 <log+0x30>
    8000430e:	97a6                	add	a5,a5,s1
  for (i = 0; i < log[dev].lh.n; i++) {
    80004310:	4701                	li	a4,0
    if (log[dev].lh.block[i] == b->blockno)   // log absorbtion
    80004312:	4394                	lw	a3,0(a5)
    80004314:	06b68a63          	beq	a3,a1,80004388 <log_write+0x104>
  for (i = 0; i < log[dev].lh.n; i++) {
    80004318:	2705                	addiw	a4,a4,1
    8000431a:	0791                	addi	a5,a5,4
    8000431c:	fec71be3          	bne	a4,a2,80004312 <log_write+0x8e>
      break;
  }
  log[dev].lh.block[i] = b->blockno;
    80004320:	02a00793          	li	a5,42
    80004324:	02f907b3          	mul	a5,s2,a5
    80004328:	97b2                	add	a5,a5,a2
    8000432a:	07a1                	addi	a5,a5,8
    8000432c:	078a                	slli	a5,a5,0x2
    8000432e:	0001f717          	auipc	a4,0x1f
    80004332:	86a70713          	addi	a4,a4,-1942 # 80022b98 <log>
    80004336:	97ba                	add	a5,a5,a4
    80004338:	00c9a703          	lw	a4,12(s3)
    8000433c:	cb98                	sw	a4,16(a5)
  if (i == log[dev].lh.n) {  // Add new block to log?
    bpin(b);
    8000433e:	854e                	mv	a0,s3
    80004340:	fffff097          	auipc	ra,0xfffff
    80004344:	caa080e7          	jalr	-854(ra) # 80002fea <bpin>
    log[dev].lh.n++;
    80004348:	0a800793          	li	a5,168
    8000434c:	02f90933          	mul	s2,s2,a5
    80004350:	0001f797          	auipc	a5,0x1f
    80004354:	84878793          	addi	a5,a5,-1976 # 80022b98 <log>
    80004358:	993e                	add	s2,s2,a5
    8000435a:	02c92783          	lw	a5,44(s2)
    8000435e:	2785                	addiw	a5,a5,1
    80004360:	02f92623          	sw	a5,44(s2)
    80004364:	a099                	j	800043aa <log_write+0x126>
    panic("too big a transaction");
    80004366:	00004517          	auipc	a0,0x4
    8000436a:	33a50513          	addi	a0,a0,826 # 800086a0 <userret+0x610>
    8000436e:	ffffc097          	auipc	ra,0xffffc
    80004372:	1da080e7          	jalr	474(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    80004376:	00004517          	auipc	a0,0x4
    8000437a:	34250513          	addi	a0,a0,834 # 800086b8 <userret+0x628>
    8000437e:	ffffc097          	auipc	ra,0xffffc
    80004382:	1ca080e7          	jalr	458(ra) # 80000548 <panic>
  for (i = 0; i < log[dev].lh.n; i++) {
    80004386:	4701                	li	a4,0
  log[dev].lh.block[i] = b->blockno;
    80004388:	02a00793          	li	a5,42
    8000438c:	02f907b3          	mul	a5,s2,a5
    80004390:	97ba                	add	a5,a5,a4
    80004392:	07a1                	addi	a5,a5,8
    80004394:	078a                	slli	a5,a5,0x2
    80004396:	0001f697          	auipc	a3,0x1f
    8000439a:	80268693          	addi	a3,a3,-2046 # 80022b98 <log>
    8000439e:	97b6                	add	a5,a5,a3
    800043a0:	00c9a683          	lw	a3,12(s3)
    800043a4:	cb94                	sw	a3,16(a5)
  if (i == log[dev].lh.n) {  // Add new block to log?
    800043a6:	f8e60ce3          	beq	a2,a4,8000433e <log_write+0xba>
  }
  release(&log[dev].lock);
    800043aa:	8552                	mv	a0,s4
    800043ac:	ffffc097          	auipc	ra,0xffffc
    800043b0:	77a080e7          	jalr	1914(ra) # 80000b26 <release>
}
    800043b4:	70a2                	ld	ra,40(sp)
    800043b6:	7402                	ld	s0,32(sp)
    800043b8:	64e2                	ld	s1,24(sp)
    800043ba:	6942                	ld	s2,16(sp)
    800043bc:	69a2                	ld	s3,8(sp)
    800043be:	6a02                	ld	s4,0(sp)
    800043c0:	6145                	addi	sp,sp,48
    800043c2:	8082                	ret

00000000800043c4 <crash_op>:

// crash before commit or after commit
void
crash_op(int dev, int docommit)
{
    800043c4:	7179                	addi	sp,sp,-48
    800043c6:	f406                	sd	ra,40(sp)
    800043c8:	f022                	sd	s0,32(sp)
    800043ca:	ec26                	sd	s1,24(sp)
    800043cc:	e84a                	sd	s2,16(sp)
    800043ce:	e44e                	sd	s3,8(sp)
    800043d0:	1800                	addi	s0,sp,48
    800043d2:	84aa                	mv	s1,a0
    800043d4:	89ae                	mv	s3,a1
  int do_commit = 0;
    
  acquire(&log[dev].lock);
    800043d6:	0a800913          	li	s2,168
    800043da:	032507b3          	mul	a5,a0,s2
    800043de:	0001e917          	auipc	s2,0x1e
    800043e2:	7ba90913          	addi	s2,s2,1978 # 80022b98 <log>
    800043e6:	993e                	add	s2,s2,a5
    800043e8:	854a                	mv	a0,s2
    800043ea:	ffffc097          	auipc	ra,0xffffc
    800043ee:	6d4080e7          	jalr	1748(ra) # 80000abe <acquire>

  if (dev < 0 || dev >= NDISK)
    800043f2:	0004871b          	sext.w	a4,s1
    800043f6:	4785                	li	a5,1
    800043f8:	0ae7e063          	bltu	a5,a4,80004498 <crash_op+0xd4>
    panic("end_op: invalid disk");
  if(log[dev].outstanding == 0)
    800043fc:	0a800793          	li	a5,168
    80004400:	02f48733          	mul	a4,s1,a5
    80004404:	0001e797          	auipc	a5,0x1e
    80004408:	79478793          	addi	a5,a5,1940 # 80022b98 <log>
    8000440c:	97ba                	add	a5,a5,a4
    8000440e:	539c                	lw	a5,32(a5)
    80004410:	cfc1                	beqz	a5,800044a8 <crash_op+0xe4>
    panic("end_op: already closed");
  log[dev].outstanding -= 1;
    80004412:	37fd                	addiw	a5,a5,-1
    80004414:	0007861b          	sext.w	a2,a5
    80004418:	0a800713          	li	a4,168
    8000441c:	02e486b3          	mul	a3,s1,a4
    80004420:	0001e717          	auipc	a4,0x1e
    80004424:	77870713          	addi	a4,a4,1912 # 80022b98 <log>
    80004428:	9736                	add	a4,a4,a3
    8000442a:	d31c                	sw	a5,32(a4)
  if(log[dev].committing)
    8000442c:	535c                	lw	a5,36(a4)
    8000442e:	e7c9                	bnez	a5,800044b8 <crash_op+0xf4>
    panic("log[dev].committing");
  if(log[dev].outstanding == 0){
    80004430:	ee41                	bnez	a2,800044c8 <crash_op+0x104>
    do_commit = 1;
    log[dev].committing = 1;
    80004432:	0a800793          	li	a5,168
    80004436:	02f48733          	mul	a4,s1,a5
    8000443a:	0001e797          	auipc	a5,0x1e
    8000443e:	75e78793          	addi	a5,a5,1886 # 80022b98 <log>
    80004442:	97ba                	add	a5,a5,a4
    80004444:	4705                	li	a4,1
    80004446:	d3d8                	sw	a4,36(a5)
  }
  
  release(&log[dev].lock);
    80004448:	854a                	mv	a0,s2
    8000444a:	ffffc097          	auipc	ra,0xffffc
    8000444e:	6dc080e7          	jalr	1756(ra) # 80000b26 <release>

  if(docommit & do_commit){
    80004452:	0019f993          	andi	s3,s3,1
    80004456:	06098e63          	beqz	s3,800044d2 <crash_op+0x10e>
    printf("crash_op: commit\n");
    8000445a:	00004517          	auipc	a0,0x4
    8000445e:	2ae50513          	addi	a0,a0,686 # 80008708 <userret+0x678>
    80004462:	ffffc097          	auipc	ra,0xffffc
    80004466:	130080e7          	jalr	304(ra) # 80000592 <printf>
    // call commit w/o holding locks, since not allowed
    // to sleep with locks.

    if (log[dev].lh.n > 0) {
    8000446a:	0a800793          	li	a5,168
    8000446e:	02f48733          	mul	a4,s1,a5
    80004472:	0001e797          	auipc	a5,0x1e
    80004476:	72678793          	addi	a5,a5,1830 # 80022b98 <log>
    8000447a:	97ba                	add	a5,a5,a4
    8000447c:	57dc                	lw	a5,44(a5)
    8000447e:	04f05a63          	blez	a5,800044d2 <crash_op+0x10e>
      write_log(dev);     // Write modified blocks from cache to log
    80004482:	8526                	mv	a0,s1
    80004484:	00000097          	auipc	ra,0x0
    80004488:	9ea080e7          	jalr	-1558(ra) # 80003e6e <write_log>
      write_head(dev);    // Write header to disk -- the real commit
    8000448c:	8526                	mv	a0,s1
    8000448e:	00000097          	auipc	ra,0x0
    80004492:	956080e7          	jalr	-1706(ra) # 80003de4 <write_head>
    80004496:	a835                	j	800044d2 <crash_op+0x10e>
    panic("end_op: invalid disk");
    80004498:	00004517          	auipc	a0,0x4
    8000449c:	24050513          	addi	a0,a0,576 # 800086d8 <userret+0x648>
    800044a0:	ffffc097          	auipc	ra,0xffffc
    800044a4:	0a8080e7          	jalr	168(ra) # 80000548 <panic>
    panic("end_op: already closed");
    800044a8:	00004517          	auipc	a0,0x4
    800044ac:	24850513          	addi	a0,a0,584 # 800086f0 <userret+0x660>
    800044b0:	ffffc097          	auipc	ra,0xffffc
    800044b4:	098080e7          	jalr	152(ra) # 80000548 <panic>
    panic("log[dev].committing");
    800044b8:	00004517          	auipc	a0,0x4
    800044bc:	1d050513          	addi	a0,a0,464 # 80008688 <userret+0x5f8>
    800044c0:	ffffc097          	auipc	ra,0xffffc
    800044c4:	088080e7          	jalr	136(ra) # 80000548 <panic>
  release(&log[dev].lock);
    800044c8:	854a                	mv	a0,s2
    800044ca:	ffffc097          	auipc	ra,0xffffc
    800044ce:	65c080e7          	jalr	1628(ra) # 80000b26 <release>
    }
  }
  panic("crashed file system; please restart xv6 and run crashtest\n");
    800044d2:	00004517          	auipc	a0,0x4
    800044d6:	24e50513          	addi	a0,a0,590 # 80008720 <userret+0x690>
    800044da:	ffffc097          	auipc	ra,0xffffc
    800044de:	06e080e7          	jalr	110(ra) # 80000548 <panic>

00000000800044e2 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800044e2:	1101                	addi	sp,sp,-32
    800044e4:	ec06                	sd	ra,24(sp)
    800044e6:	e822                	sd	s0,16(sp)
    800044e8:	e426                	sd	s1,8(sp)
    800044ea:	e04a                	sd	s2,0(sp)
    800044ec:	1000                	addi	s0,sp,32
    800044ee:	84aa                	mv	s1,a0
    800044f0:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800044f2:	00004597          	auipc	a1,0x4
    800044f6:	26e58593          	addi	a1,a1,622 # 80008760 <userret+0x6d0>
    800044fa:	0521                	addi	a0,a0,8
    800044fc:	ffffc097          	auipc	ra,0xffffc
    80004500:	4b4080e7          	jalr	1204(ra) # 800009b0 <initlock>
  lk->name = name;
    80004504:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004508:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000450c:	0204a423          	sw	zero,40(s1)
}
    80004510:	60e2                	ld	ra,24(sp)
    80004512:	6442                	ld	s0,16(sp)
    80004514:	64a2                	ld	s1,8(sp)
    80004516:	6902                	ld	s2,0(sp)
    80004518:	6105                	addi	sp,sp,32
    8000451a:	8082                	ret

000000008000451c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000451c:	1101                	addi	sp,sp,-32
    8000451e:	ec06                	sd	ra,24(sp)
    80004520:	e822                	sd	s0,16(sp)
    80004522:	e426                	sd	s1,8(sp)
    80004524:	e04a                	sd	s2,0(sp)
    80004526:	1000                	addi	s0,sp,32
    80004528:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000452a:	00850913          	addi	s2,a0,8
    8000452e:	854a                	mv	a0,s2
    80004530:	ffffc097          	auipc	ra,0xffffc
    80004534:	58e080e7          	jalr	1422(ra) # 80000abe <acquire>
  while (lk->locked) {
    80004538:	409c                	lw	a5,0(s1)
    8000453a:	cb89                	beqz	a5,8000454c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000453c:	85ca                	mv	a1,s2
    8000453e:	8526                	mv	a0,s1
    80004540:	ffffe097          	auipc	ra,0xffffe
    80004544:	ba8080e7          	jalr	-1112(ra) # 800020e8 <sleep>
  while (lk->locked) {
    80004548:	409c                	lw	a5,0(s1)
    8000454a:	fbed                	bnez	a5,8000453c <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000454c:	4785                	li	a5,1
    8000454e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004550:	ffffd097          	auipc	ra,0xffffd
    80004554:	3ba080e7          	jalr	954(ra) # 8000190a <myproc>
    80004558:	5d1c                	lw	a5,56(a0)
    8000455a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000455c:	854a                	mv	a0,s2
    8000455e:	ffffc097          	auipc	ra,0xffffc
    80004562:	5c8080e7          	jalr	1480(ra) # 80000b26 <release>
}
    80004566:	60e2                	ld	ra,24(sp)
    80004568:	6442                	ld	s0,16(sp)
    8000456a:	64a2                	ld	s1,8(sp)
    8000456c:	6902                	ld	s2,0(sp)
    8000456e:	6105                	addi	sp,sp,32
    80004570:	8082                	ret

0000000080004572 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004572:	1101                	addi	sp,sp,-32
    80004574:	ec06                	sd	ra,24(sp)
    80004576:	e822                	sd	s0,16(sp)
    80004578:	e426                	sd	s1,8(sp)
    8000457a:	e04a                	sd	s2,0(sp)
    8000457c:	1000                	addi	s0,sp,32
    8000457e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004580:	00850913          	addi	s2,a0,8
    80004584:	854a                	mv	a0,s2
    80004586:	ffffc097          	auipc	ra,0xffffc
    8000458a:	538080e7          	jalr	1336(ra) # 80000abe <acquire>
  lk->locked = 0;
    8000458e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004592:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004596:	8526                	mv	a0,s1
    80004598:	ffffe097          	auipc	ra,0xffffe
    8000459c:	cd0080e7          	jalr	-816(ra) # 80002268 <wakeup>
  release(&lk->lk);
    800045a0:	854a                	mv	a0,s2
    800045a2:	ffffc097          	auipc	ra,0xffffc
    800045a6:	584080e7          	jalr	1412(ra) # 80000b26 <release>
}
    800045aa:	60e2                	ld	ra,24(sp)
    800045ac:	6442                	ld	s0,16(sp)
    800045ae:	64a2                	ld	s1,8(sp)
    800045b0:	6902                	ld	s2,0(sp)
    800045b2:	6105                	addi	sp,sp,32
    800045b4:	8082                	ret

00000000800045b6 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800045b6:	7179                	addi	sp,sp,-48
    800045b8:	f406                	sd	ra,40(sp)
    800045ba:	f022                	sd	s0,32(sp)
    800045bc:	ec26                	sd	s1,24(sp)
    800045be:	e84a                	sd	s2,16(sp)
    800045c0:	e44e                	sd	s3,8(sp)
    800045c2:	1800                	addi	s0,sp,48
    800045c4:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800045c6:	00850913          	addi	s2,a0,8
    800045ca:	854a                	mv	a0,s2
    800045cc:	ffffc097          	auipc	ra,0xffffc
    800045d0:	4f2080e7          	jalr	1266(ra) # 80000abe <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800045d4:	409c                	lw	a5,0(s1)
    800045d6:	ef99                	bnez	a5,800045f4 <holdingsleep+0x3e>
    800045d8:	4481                	li	s1,0
  release(&lk->lk);
    800045da:	854a                	mv	a0,s2
    800045dc:	ffffc097          	auipc	ra,0xffffc
    800045e0:	54a080e7          	jalr	1354(ra) # 80000b26 <release>
  return r;
}
    800045e4:	8526                	mv	a0,s1
    800045e6:	70a2                	ld	ra,40(sp)
    800045e8:	7402                	ld	s0,32(sp)
    800045ea:	64e2                	ld	s1,24(sp)
    800045ec:	6942                	ld	s2,16(sp)
    800045ee:	69a2                	ld	s3,8(sp)
    800045f0:	6145                	addi	sp,sp,48
    800045f2:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800045f4:	0284a983          	lw	s3,40(s1)
    800045f8:	ffffd097          	auipc	ra,0xffffd
    800045fc:	312080e7          	jalr	786(ra) # 8000190a <myproc>
    80004600:	5d04                	lw	s1,56(a0)
    80004602:	413484b3          	sub	s1,s1,s3
    80004606:	0014b493          	seqz	s1,s1
    8000460a:	bfc1                	j	800045da <holdingsleep+0x24>

000000008000460c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000460c:	1141                	addi	sp,sp,-16
    8000460e:	e406                	sd	ra,8(sp)
    80004610:	e022                	sd	s0,0(sp)
    80004612:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004614:	00004597          	auipc	a1,0x4
    80004618:	15c58593          	addi	a1,a1,348 # 80008770 <userret+0x6e0>
    8000461c:	0001e517          	auipc	a0,0x1e
    80004620:	76c50513          	addi	a0,a0,1900 # 80022d88 <ftable>
    80004624:	ffffc097          	auipc	ra,0xffffc
    80004628:	38c080e7          	jalr	908(ra) # 800009b0 <initlock>
}
    8000462c:	60a2                	ld	ra,8(sp)
    8000462e:	6402                	ld	s0,0(sp)
    80004630:	0141                	addi	sp,sp,16
    80004632:	8082                	ret

0000000080004634 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004634:	1101                	addi	sp,sp,-32
    80004636:	ec06                	sd	ra,24(sp)
    80004638:	e822                	sd	s0,16(sp)
    8000463a:	e426                	sd	s1,8(sp)
    8000463c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000463e:	0001e517          	auipc	a0,0x1e
    80004642:	74a50513          	addi	a0,a0,1866 # 80022d88 <ftable>
    80004646:	ffffc097          	auipc	ra,0xffffc
    8000464a:	478080e7          	jalr	1144(ra) # 80000abe <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000464e:	0001e497          	auipc	s1,0x1e
    80004652:	75248493          	addi	s1,s1,1874 # 80022da0 <ftable+0x18>
    80004656:	0001f717          	auipc	a4,0x1f
    8000465a:	6ea70713          	addi	a4,a4,1770 # 80023d40 <ftable+0xfb8>
    if(f->ref == 0){
    8000465e:	40dc                	lw	a5,4(s1)
    80004660:	cf99                	beqz	a5,8000467e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004662:	02848493          	addi	s1,s1,40
    80004666:	fee49ce3          	bne	s1,a4,8000465e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000466a:	0001e517          	auipc	a0,0x1e
    8000466e:	71e50513          	addi	a0,a0,1822 # 80022d88 <ftable>
    80004672:	ffffc097          	auipc	ra,0xffffc
    80004676:	4b4080e7          	jalr	1204(ra) # 80000b26 <release>
  return 0;
    8000467a:	4481                	li	s1,0
    8000467c:	a819                	j	80004692 <filealloc+0x5e>
      f->ref = 1;
    8000467e:	4785                	li	a5,1
    80004680:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004682:	0001e517          	auipc	a0,0x1e
    80004686:	70650513          	addi	a0,a0,1798 # 80022d88 <ftable>
    8000468a:	ffffc097          	auipc	ra,0xffffc
    8000468e:	49c080e7          	jalr	1180(ra) # 80000b26 <release>
}
    80004692:	8526                	mv	a0,s1
    80004694:	60e2                	ld	ra,24(sp)
    80004696:	6442                	ld	s0,16(sp)
    80004698:	64a2                	ld	s1,8(sp)
    8000469a:	6105                	addi	sp,sp,32
    8000469c:	8082                	ret

000000008000469e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000469e:	1101                	addi	sp,sp,-32
    800046a0:	ec06                	sd	ra,24(sp)
    800046a2:	e822                	sd	s0,16(sp)
    800046a4:	e426                	sd	s1,8(sp)
    800046a6:	1000                	addi	s0,sp,32
    800046a8:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800046aa:	0001e517          	auipc	a0,0x1e
    800046ae:	6de50513          	addi	a0,a0,1758 # 80022d88 <ftable>
    800046b2:	ffffc097          	auipc	ra,0xffffc
    800046b6:	40c080e7          	jalr	1036(ra) # 80000abe <acquire>
  if(f->ref < 1)
    800046ba:	40dc                	lw	a5,4(s1)
    800046bc:	02f05263          	blez	a5,800046e0 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800046c0:	2785                	addiw	a5,a5,1
    800046c2:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800046c4:	0001e517          	auipc	a0,0x1e
    800046c8:	6c450513          	addi	a0,a0,1732 # 80022d88 <ftable>
    800046cc:	ffffc097          	auipc	ra,0xffffc
    800046d0:	45a080e7          	jalr	1114(ra) # 80000b26 <release>
  return f;
}
    800046d4:	8526                	mv	a0,s1
    800046d6:	60e2                	ld	ra,24(sp)
    800046d8:	6442                	ld	s0,16(sp)
    800046da:	64a2                	ld	s1,8(sp)
    800046dc:	6105                	addi	sp,sp,32
    800046de:	8082                	ret
    panic("filedup");
    800046e0:	00004517          	auipc	a0,0x4
    800046e4:	09850513          	addi	a0,a0,152 # 80008778 <userret+0x6e8>
    800046e8:	ffffc097          	auipc	ra,0xffffc
    800046ec:	e60080e7          	jalr	-416(ra) # 80000548 <panic>

00000000800046f0 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046f0:	7139                	addi	sp,sp,-64
    800046f2:	fc06                	sd	ra,56(sp)
    800046f4:	f822                	sd	s0,48(sp)
    800046f6:	f426                	sd	s1,40(sp)
    800046f8:	f04a                	sd	s2,32(sp)
    800046fa:	ec4e                	sd	s3,24(sp)
    800046fc:	e852                	sd	s4,16(sp)
    800046fe:	e456                	sd	s5,8(sp)
    80004700:	0080                	addi	s0,sp,64
    80004702:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004704:	0001e517          	auipc	a0,0x1e
    80004708:	68450513          	addi	a0,a0,1668 # 80022d88 <ftable>
    8000470c:	ffffc097          	auipc	ra,0xffffc
    80004710:	3b2080e7          	jalr	946(ra) # 80000abe <acquire>
  if(f->ref < 1)
    80004714:	40dc                	lw	a5,4(s1)
    80004716:	06f05563          	blez	a5,80004780 <fileclose+0x90>
    panic("fileclose");
  if(--f->ref > 0){
    8000471a:	37fd                	addiw	a5,a5,-1
    8000471c:	0007871b          	sext.w	a4,a5
    80004720:	c0dc                	sw	a5,4(s1)
    80004722:	06e04763          	bgtz	a4,80004790 <fileclose+0xa0>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004726:	0004a903          	lw	s2,0(s1)
    8000472a:	0094ca83          	lbu	s5,9(s1)
    8000472e:	0104ba03          	ld	s4,16(s1)
    80004732:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004736:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000473a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000473e:	0001e517          	auipc	a0,0x1e
    80004742:	64a50513          	addi	a0,a0,1610 # 80022d88 <ftable>
    80004746:	ffffc097          	auipc	ra,0xffffc
    8000474a:	3e0080e7          	jalr	992(ra) # 80000b26 <release>

  if(ff.type == FD_PIPE){
    8000474e:	4785                	li	a5,1
    80004750:	06f90163          	beq	s2,a5,800047b2 <fileclose+0xc2>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004754:	3979                	addiw	s2,s2,-2
    80004756:	4785                	li	a5,1
    80004758:	0527e463          	bltu	a5,s2,800047a0 <fileclose+0xb0>
    begin_op(ff.ip->dev);
    8000475c:	0009a503          	lw	a0,0(s3)
    80004760:	00000097          	auipc	ra,0x0
    80004764:	968080e7          	jalr	-1688(ra) # 800040c8 <begin_op>
    iput(ff.ip);
    80004768:	854e                	mv	a0,s3
    8000476a:	fffff097          	auipc	ra,0xfffff
    8000476e:	fc4080e7          	jalr	-60(ra) # 8000372e <iput>
    end_op(ff.ip->dev);
    80004772:	0009a503          	lw	a0,0(s3)
    80004776:	00000097          	auipc	ra,0x0
    8000477a:	9fc080e7          	jalr	-1540(ra) # 80004172 <end_op>
    8000477e:	a00d                	j	800047a0 <fileclose+0xb0>
    panic("fileclose");
    80004780:	00004517          	auipc	a0,0x4
    80004784:	00050513          	mv	a0,a0
    80004788:	ffffc097          	auipc	ra,0xffffc
    8000478c:	dc0080e7          	jalr	-576(ra) # 80000548 <panic>
    release(&ftable.lock);
    80004790:	0001e517          	auipc	a0,0x1e
    80004794:	5f850513          	addi	a0,a0,1528 # 80022d88 <ftable>
    80004798:	ffffc097          	auipc	ra,0xffffc
    8000479c:	38e080e7          	jalr	910(ra) # 80000b26 <release>
  }
}
    800047a0:	70e2                	ld	ra,56(sp)
    800047a2:	7442                	ld	s0,48(sp)
    800047a4:	74a2                	ld	s1,40(sp)
    800047a6:	7902                	ld	s2,32(sp)
    800047a8:	69e2                	ld	s3,24(sp)
    800047aa:	6a42                	ld	s4,16(sp)
    800047ac:	6aa2                	ld	s5,8(sp)
    800047ae:	6121                	addi	sp,sp,64
    800047b0:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800047b2:	85d6                	mv	a1,s5
    800047b4:	8552                	mv	a0,s4
    800047b6:	00000097          	auipc	ra,0x0
    800047ba:	378080e7          	jalr	888(ra) # 80004b2e <pipeclose>
    800047be:	b7cd                	j	800047a0 <fileclose+0xb0>

00000000800047c0 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800047c0:	715d                	addi	sp,sp,-80
    800047c2:	e486                	sd	ra,72(sp)
    800047c4:	e0a2                	sd	s0,64(sp)
    800047c6:	fc26                	sd	s1,56(sp)
    800047c8:	f84a                	sd	s2,48(sp)
    800047ca:	f44e                	sd	s3,40(sp)
    800047cc:	0880                	addi	s0,sp,80
    800047ce:	84aa                	mv	s1,a0
    800047d0:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800047d2:	ffffd097          	auipc	ra,0xffffd
    800047d6:	138080e7          	jalr	312(ra) # 8000190a <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800047da:	409c                	lw	a5,0(s1)
    800047dc:	37f9                	addiw	a5,a5,-2
    800047de:	4705                	li	a4,1
    800047e0:	04f76763          	bltu	a4,a5,8000482e <filestat+0x6e>
    800047e4:	892a                	mv	s2,a0
    ilock(f->ip);
    800047e6:	6c88                	ld	a0,24(s1)
    800047e8:	fffff097          	auipc	ra,0xfffff
    800047ec:	e38080e7          	jalr	-456(ra) # 80003620 <ilock>
    stati(f->ip, &st);
    800047f0:	fb840593          	addi	a1,s0,-72
    800047f4:	6c88                	ld	a0,24(s1)
    800047f6:	fffff097          	auipc	ra,0xfffff
    800047fa:	090080e7          	jalr	144(ra) # 80003886 <stati>
    iunlock(f->ip);
    800047fe:	6c88                	ld	a0,24(s1)
    80004800:	fffff097          	auipc	ra,0xfffff
    80004804:	ee2080e7          	jalr	-286(ra) # 800036e2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004808:	46e1                	li	a3,24
    8000480a:	fb840613          	addi	a2,s0,-72
    8000480e:	85ce                	mv	a1,s3
    80004810:	05893503          	ld	a0,88(s2)
    80004814:	ffffd097          	auipc	ra,0xffffd
    80004818:	cfc080e7          	jalr	-772(ra) # 80001510 <copyout>
    8000481c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004820:	60a6                	ld	ra,72(sp)
    80004822:	6406                	ld	s0,64(sp)
    80004824:	74e2                	ld	s1,56(sp)
    80004826:	7942                	ld	s2,48(sp)
    80004828:	79a2                	ld	s3,40(sp)
    8000482a:	6161                	addi	sp,sp,80
    8000482c:	8082                	ret
  return -1;
    8000482e:	557d                	li	a0,-1
    80004830:	bfc5                	j	80004820 <filestat+0x60>

0000000080004832 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004832:	7179                	addi	sp,sp,-48
    80004834:	f406                	sd	ra,40(sp)
    80004836:	f022                	sd	s0,32(sp)
    80004838:	ec26                	sd	s1,24(sp)
    8000483a:	e84a                	sd	s2,16(sp)
    8000483c:	e44e                	sd	s3,8(sp)
    8000483e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004840:	00854783          	lbu	a5,8(a0)
    80004844:	c7c5                	beqz	a5,800048ec <fileread+0xba>
    80004846:	84aa                	mv	s1,a0
    80004848:	89ae                	mv	s3,a1
    8000484a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000484c:	411c                	lw	a5,0(a0)
    8000484e:	4705                	li	a4,1
    80004850:	04e78963          	beq	a5,a4,800048a2 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004854:	470d                	li	a4,3
    80004856:	04e78d63          	beq	a5,a4,800048b0 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(f, 1, addr, n);
  } else if(f->type == FD_INODE){
    8000485a:	4709                	li	a4,2
    8000485c:	08e79063          	bne	a5,a4,800048dc <fileread+0xaa>
    ilock(f->ip);
    80004860:	6d08                	ld	a0,24(a0)
    80004862:	fffff097          	auipc	ra,0xfffff
    80004866:	dbe080e7          	jalr	-578(ra) # 80003620 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000486a:	874a                	mv	a4,s2
    8000486c:	5094                	lw	a3,32(s1)
    8000486e:	864e                	mv	a2,s3
    80004870:	4585                	li	a1,1
    80004872:	6c88                	ld	a0,24(s1)
    80004874:	fffff097          	auipc	ra,0xfffff
    80004878:	03c080e7          	jalr	60(ra) # 800038b0 <readi>
    8000487c:	892a                	mv	s2,a0
    8000487e:	00a05563          	blez	a0,80004888 <fileread+0x56>
      f->off += r;
    80004882:	509c                	lw	a5,32(s1)
    80004884:	9fa9                	addw	a5,a5,a0
    80004886:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004888:	6c88                	ld	a0,24(s1)
    8000488a:	fffff097          	auipc	ra,0xfffff
    8000488e:	e58080e7          	jalr	-424(ra) # 800036e2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004892:	854a                	mv	a0,s2
    80004894:	70a2                	ld	ra,40(sp)
    80004896:	7402                	ld	s0,32(sp)
    80004898:	64e2                	ld	s1,24(sp)
    8000489a:	6942                	ld	s2,16(sp)
    8000489c:	69a2                	ld	s3,8(sp)
    8000489e:	6145                	addi	sp,sp,48
    800048a0:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800048a2:	6908                	ld	a0,16(a0)
    800048a4:	00000097          	auipc	ra,0x0
    800048a8:	408080e7          	jalr	1032(ra) # 80004cac <piperead>
    800048ac:	892a                	mv	s2,a0
    800048ae:	b7d5                	j	80004892 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800048b0:	02451783          	lh	a5,36(a0)
    800048b4:	03079693          	slli	a3,a5,0x30
    800048b8:	92c1                	srli	a3,a3,0x30
    800048ba:	4725                	li	a4,9
    800048bc:	02d76a63          	bltu	a4,a3,800048f0 <fileread+0xbe>
    800048c0:	0792                	slli	a5,a5,0x4
    800048c2:	0001e717          	auipc	a4,0x1e
    800048c6:	42670713          	addi	a4,a4,1062 # 80022ce8 <devsw>
    800048ca:	97ba                	add	a5,a5,a4
    800048cc:	639c                	ld	a5,0(a5)
    800048ce:	c39d                	beqz	a5,800048f4 <fileread+0xc2>
    r = devsw[f->major].read(f, 1, addr, n);
    800048d0:	86b2                	mv	a3,a2
    800048d2:	862e                	mv	a2,a1
    800048d4:	4585                	li	a1,1
    800048d6:	9782                	jalr	a5
    800048d8:	892a                	mv	s2,a0
    800048da:	bf65                	j	80004892 <fileread+0x60>
    panic("fileread");
    800048dc:	00004517          	auipc	a0,0x4
    800048e0:	eb450513          	addi	a0,a0,-332 # 80008790 <userret+0x700>
    800048e4:	ffffc097          	auipc	ra,0xffffc
    800048e8:	c64080e7          	jalr	-924(ra) # 80000548 <panic>
    return -1;
    800048ec:	597d                	li	s2,-1
    800048ee:	b755                	j	80004892 <fileread+0x60>
      return -1;
    800048f0:	597d                	li	s2,-1
    800048f2:	b745                	j	80004892 <fileread+0x60>
    800048f4:	597d                	li	s2,-1
    800048f6:	bf71                	j	80004892 <fileread+0x60>

00000000800048f8 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800048f8:	00954783          	lbu	a5,9(a0)
    800048fc:	14078663          	beqz	a5,80004a48 <filewrite+0x150>
{
    80004900:	715d                	addi	sp,sp,-80
    80004902:	e486                	sd	ra,72(sp)
    80004904:	e0a2                	sd	s0,64(sp)
    80004906:	fc26                	sd	s1,56(sp)
    80004908:	f84a                	sd	s2,48(sp)
    8000490a:	f44e                	sd	s3,40(sp)
    8000490c:	f052                	sd	s4,32(sp)
    8000490e:	ec56                	sd	s5,24(sp)
    80004910:	e85a                	sd	s6,16(sp)
    80004912:	e45e                	sd	s7,8(sp)
    80004914:	e062                	sd	s8,0(sp)
    80004916:	0880                	addi	s0,sp,80
    80004918:	84aa                	mv	s1,a0
    8000491a:	8aae                	mv	s5,a1
    8000491c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000491e:	411c                	lw	a5,0(a0)
    80004920:	4705                	li	a4,1
    80004922:	02e78263          	beq	a5,a4,80004946 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004926:	470d                	li	a4,3
    80004928:	02e78563          	beq	a5,a4,80004952 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(f, 1, addr, n);
  } else if(f->type == FD_INODE){
    8000492c:	4709                	li	a4,2
    8000492e:	10e79563          	bne	a5,a4,80004a38 <filewrite+0x140>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004932:	0ec05f63          	blez	a2,80004a30 <filewrite+0x138>
    int i = 0;
    80004936:	4981                	li	s3,0
    80004938:	6b05                	lui	s6,0x1
    8000493a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000493e:	6b85                	lui	s7,0x1
    80004940:	c00b8b9b          	addiw	s7,s7,-1024
    80004944:	a851                	j	800049d8 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004946:	6908                	ld	a0,16(a0)
    80004948:	00000097          	auipc	ra,0x0
    8000494c:	256080e7          	jalr	598(ra) # 80004b9e <pipewrite>
    80004950:	a865                	j	80004a08 <filewrite+0x110>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004952:	02451783          	lh	a5,36(a0)
    80004956:	03079693          	slli	a3,a5,0x30
    8000495a:	92c1                	srli	a3,a3,0x30
    8000495c:	4725                	li	a4,9
    8000495e:	0ed76763          	bltu	a4,a3,80004a4c <filewrite+0x154>
    80004962:	0792                	slli	a5,a5,0x4
    80004964:	0001e717          	auipc	a4,0x1e
    80004968:	38470713          	addi	a4,a4,900 # 80022ce8 <devsw>
    8000496c:	97ba                	add	a5,a5,a4
    8000496e:	679c                	ld	a5,8(a5)
    80004970:	c3e5                	beqz	a5,80004a50 <filewrite+0x158>
    ret = devsw[f->major].write(f, 1, addr, n);
    80004972:	86b2                	mv	a3,a2
    80004974:	862e                	mv	a2,a1
    80004976:	4585                	li	a1,1
    80004978:	9782                	jalr	a5
    8000497a:	a079                	j	80004a08 <filewrite+0x110>
    8000497c:	00090c1b          	sext.w	s8,s2
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op(f->ip->dev);
    80004980:	6c9c                	ld	a5,24(s1)
    80004982:	4388                	lw	a0,0(a5)
    80004984:	fffff097          	auipc	ra,0xfffff
    80004988:	744080e7          	jalr	1860(ra) # 800040c8 <begin_op>
      ilock(f->ip);
    8000498c:	6c88                	ld	a0,24(s1)
    8000498e:	fffff097          	auipc	ra,0xfffff
    80004992:	c92080e7          	jalr	-878(ra) # 80003620 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004996:	8762                	mv	a4,s8
    80004998:	5094                	lw	a3,32(s1)
    8000499a:	01598633          	add	a2,s3,s5
    8000499e:	4585                	li	a1,1
    800049a0:	6c88                	ld	a0,24(s1)
    800049a2:	fffff097          	auipc	ra,0xfffff
    800049a6:	002080e7          	jalr	2(ra) # 800039a4 <writei>
    800049aa:	892a                	mv	s2,a0
    800049ac:	02a05e63          	blez	a0,800049e8 <filewrite+0xf0>
        f->off += r;
    800049b0:	509c                	lw	a5,32(s1)
    800049b2:	9fa9                	addw	a5,a5,a0
    800049b4:	d09c                	sw	a5,32(s1)
      iunlock(f->ip);
    800049b6:	6c88                	ld	a0,24(s1)
    800049b8:	fffff097          	auipc	ra,0xfffff
    800049bc:	d2a080e7          	jalr	-726(ra) # 800036e2 <iunlock>
      end_op(f->ip->dev);
    800049c0:	6c9c                	ld	a5,24(s1)
    800049c2:	4388                	lw	a0,0(a5)
    800049c4:	fffff097          	auipc	ra,0xfffff
    800049c8:	7ae080e7          	jalr	1966(ra) # 80004172 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    800049cc:	052c1a63          	bne	s8,s2,80004a20 <filewrite+0x128>
        panic("short filewrite");
      i += r;
    800049d0:	013909bb          	addw	s3,s2,s3
    while(i < n){
    800049d4:	0349d763          	bge	s3,s4,80004a02 <filewrite+0x10a>
      int n1 = n - i;
    800049d8:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800049dc:	893e                	mv	s2,a5
    800049de:	2781                	sext.w	a5,a5
    800049e0:	f8fb5ee3          	bge	s6,a5,8000497c <filewrite+0x84>
    800049e4:	895e                	mv	s2,s7
    800049e6:	bf59                	j	8000497c <filewrite+0x84>
      iunlock(f->ip);
    800049e8:	6c88                	ld	a0,24(s1)
    800049ea:	fffff097          	auipc	ra,0xfffff
    800049ee:	cf8080e7          	jalr	-776(ra) # 800036e2 <iunlock>
      end_op(f->ip->dev);
    800049f2:	6c9c                	ld	a5,24(s1)
    800049f4:	4388                	lw	a0,0(a5)
    800049f6:	fffff097          	auipc	ra,0xfffff
    800049fa:	77c080e7          	jalr	1916(ra) # 80004172 <end_op>
      if(r < 0)
    800049fe:	fc0957e3          	bgez	s2,800049cc <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004a02:	8552                	mv	a0,s4
    80004a04:	033a1863          	bne	s4,s3,80004a34 <filewrite+0x13c>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a08:	60a6                	ld	ra,72(sp)
    80004a0a:	6406                	ld	s0,64(sp)
    80004a0c:	74e2                	ld	s1,56(sp)
    80004a0e:	7942                	ld	s2,48(sp)
    80004a10:	79a2                	ld	s3,40(sp)
    80004a12:	7a02                	ld	s4,32(sp)
    80004a14:	6ae2                	ld	s5,24(sp)
    80004a16:	6b42                	ld	s6,16(sp)
    80004a18:	6ba2                	ld	s7,8(sp)
    80004a1a:	6c02                	ld	s8,0(sp)
    80004a1c:	6161                	addi	sp,sp,80
    80004a1e:	8082                	ret
        panic("short filewrite");
    80004a20:	00004517          	auipc	a0,0x4
    80004a24:	d8050513          	addi	a0,a0,-640 # 800087a0 <userret+0x710>
    80004a28:	ffffc097          	auipc	ra,0xffffc
    80004a2c:	b20080e7          	jalr	-1248(ra) # 80000548 <panic>
    int i = 0;
    80004a30:	4981                	li	s3,0
    80004a32:	bfc1                	j	80004a02 <filewrite+0x10a>
    ret = (i == n ? n : -1);
    80004a34:	557d                	li	a0,-1
    80004a36:	bfc9                	j	80004a08 <filewrite+0x110>
    panic("filewrite");
    80004a38:	00004517          	auipc	a0,0x4
    80004a3c:	d7850513          	addi	a0,a0,-648 # 800087b0 <userret+0x720>
    80004a40:	ffffc097          	auipc	ra,0xffffc
    80004a44:	b08080e7          	jalr	-1272(ra) # 80000548 <panic>
    return -1;
    80004a48:	557d                	li	a0,-1
}
    80004a4a:	8082                	ret
      return -1;
    80004a4c:	557d                	li	a0,-1
    80004a4e:	bf6d                	j	80004a08 <filewrite+0x110>
    80004a50:	557d                	li	a0,-1
    80004a52:	bf5d                	j	80004a08 <filewrite+0x110>

0000000080004a54 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a54:	7179                	addi	sp,sp,-48
    80004a56:	f406                	sd	ra,40(sp)
    80004a58:	f022                	sd	s0,32(sp)
    80004a5a:	ec26                	sd	s1,24(sp)
    80004a5c:	e84a                	sd	s2,16(sp)
    80004a5e:	e44e                	sd	s3,8(sp)
    80004a60:	e052                	sd	s4,0(sp)
    80004a62:	1800                	addi	s0,sp,48
    80004a64:	84aa                	mv	s1,a0
    80004a66:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a68:	0005b023          	sd	zero,0(a1)
    80004a6c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a70:	00000097          	auipc	ra,0x0
    80004a74:	bc4080e7          	jalr	-1084(ra) # 80004634 <filealloc>
    80004a78:	e088                	sd	a0,0(s1)
    80004a7a:	c551                	beqz	a0,80004b06 <pipealloc+0xb2>
    80004a7c:	00000097          	auipc	ra,0x0
    80004a80:	bb8080e7          	jalr	-1096(ra) # 80004634 <filealloc>
    80004a84:	00aa3023          	sd	a0,0(s4)
    80004a88:	c92d                	beqz	a0,80004afa <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a8a:	ffffc097          	auipc	ra,0xffffc
    80004a8e:	ec6080e7          	jalr	-314(ra) # 80000950 <kalloc>
    80004a92:	892a                	mv	s2,a0
    80004a94:	c125                	beqz	a0,80004af4 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a96:	4985                	li	s3,1
    80004a98:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a9c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004aa0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004aa4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004aa8:	00004597          	auipc	a1,0x4
    80004aac:	d1858593          	addi	a1,a1,-744 # 800087c0 <userret+0x730>
    80004ab0:	ffffc097          	auipc	ra,0xffffc
    80004ab4:	f00080e7          	jalr	-256(ra) # 800009b0 <initlock>
  (*f0)->type = FD_PIPE;
    80004ab8:	609c                	ld	a5,0(s1)
    80004aba:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004abe:	609c                	ld	a5,0(s1)
    80004ac0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ac4:	609c                	ld	a5,0(s1)
    80004ac6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004aca:	609c                	ld	a5,0(s1)
    80004acc:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004ad0:	000a3783          	ld	a5,0(s4)
    80004ad4:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004ad8:	000a3783          	ld	a5,0(s4)
    80004adc:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004ae0:	000a3783          	ld	a5,0(s4)
    80004ae4:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004ae8:	000a3783          	ld	a5,0(s4)
    80004aec:	0127b823          	sd	s2,16(a5)
  return 0;
    80004af0:	4501                	li	a0,0
    80004af2:	a025                	j	80004b1a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004af4:	6088                	ld	a0,0(s1)
    80004af6:	e501                	bnez	a0,80004afe <pipealloc+0xaa>
    80004af8:	a039                	j	80004b06 <pipealloc+0xb2>
    80004afa:	6088                	ld	a0,0(s1)
    80004afc:	c51d                	beqz	a0,80004b2a <pipealloc+0xd6>
    fileclose(*f0);
    80004afe:	00000097          	auipc	ra,0x0
    80004b02:	bf2080e7          	jalr	-1038(ra) # 800046f0 <fileclose>
  if(*f1)
    80004b06:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b0a:	557d                	li	a0,-1
  if(*f1)
    80004b0c:	c799                	beqz	a5,80004b1a <pipealloc+0xc6>
    fileclose(*f1);
    80004b0e:	853e                	mv	a0,a5
    80004b10:	00000097          	auipc	ra,0x0
    80004b14:	be0080e7          	jalr	-1056(ra) # 800046f0 <fileclose>
  return -1;
    80004b18:	557d                	li	a0,-1
}
    80004b1a:	70a2                	ld	ra,40(sp)
    80004b1c:	7402                	ld	s0,32(sp)
    80004b1e:	64e2                	ld	s1,24(sp)
    80004b20:	6942                	ld	s2,16(sp)
    80004b22:	69a2                	ld	s3,8(sp)
    80004b24:	6a02                	ld	s4,0(sp)
    80004b26:	6145                	addi	sp,sp,48
    80004b28:	8082                	ret
  return -1;
    80004b2a:	557d                	li	a0,-1
    80004b2c:	b7fd                	j	80004b1a <pipealloc+0xc6>

0000000080004b2e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b2e:	1101                	addi	sp,sp,-32
    80004b30:	ec06                	sd	ra,24(sp)
    80004b32:	e822                	sd	s0,16(sp)
    80004b34:	e426                	sd	s1,8(sp)
    80004b36:	e04a                	sd	s2,0(sp)
    80004b38:	1000                	addi	s0,sp,32
    80004b3a:	84aa                	mv	s1,a0
    80004b3c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b3e:	ffffc097          	auipc	ra,0xffffc
    80004b42:	f80080e7          	jalr	-128(ra) # 80000abe <acquire>
  if(writable){
    80004b46:	02090d63          	beqz	s2,80004b80 <pipeclose+0x52>
    pi->writeopen = 0;
    80004b4a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b4e:	21848513          	addi	a0,s1,536
    80004b52:	ffffd097          	auipc	ra,0xffffd
    80004b56:	716080e7          	jalr	1814(ra) # 80002268 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b5a:	2204b783          	ld	a5,544(s1)
    80004b5e:	eb95                	bnez	a5,80004b92 <pipeclose+0x64>
    release(&pi->lock);
    80004b60:	8526                	mv	a0,s1
    80004b62:	ffffc097          	auipc	ra,0xffffc
    80004b66:	fc4080e7          	jalr	-60(ra) # 80000b26 <release>
    kfree((char*)pi);
    80004b6a:	8526                	mv	a0,s1
    80004b6c:	ffffc097          	auipc	ra,0xffffc
    80004b70:	ce8080e7          	jalr	-792(ra) # 80000854 <kfree>
  } else
    release(&pi->lock);
}
    80004b74:	60e2                	ld	ra,24(sp)
    80004b76:	6442                	ld	s0,16(sp)
    80004b78:	64a2                	ld	s1,8(sp)
    80004b7a:	6902                	ld	s2,0(sp)
    80004b7c:	6105                	addi	sp,sp,32
    80004b7e:	8082                	ret
    pi->readopen = 0;
    80004b80:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b84:	21c48513          	addi	a0,s1,540
    80004b88:	ffffd097          	auipc	ra,0xffffd
    80004b8c:	6e0080e7          	jalr	1760(ra) # 80002268 <wakeup>
    80004b90:	b7e9                	j	80004b5a <pipeclose+0x2c>
    release(&pi->lock);
    80004b92:	8526                	mv	a0,s1
    80004b94:	ffffc097          	auipc	ra,0xffffc
    80004b98:	f92080e7          	jalr	-110(ra) # 80000b26 <release>
}
    80004b9c:	bfe1                	j	80004b74 <pipeclose+0x46>

0000000080004b9e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b9e:	711d                	addi	sp,sp,-96
    80004ba0:	ec86                	sd	ra,88(sp)
    80004ba2:	e8a2                	sd	s0,80(sp)
    80004ba4:	e4a6                	sd	s1,72(sp)
    80004ba6:	e0ca                	sd	s2,64(sp)
    80004ba8:	fc4e                	sd	s3,56(sp)
    80004baa:	f852                	sd	s4,48(sp)
    80004bac:	f456                	sd	s5,40(sp)
    80004bae:	f05a                	sd	s6,32(sp)
    80004bb0:	ec5e                	sd	s7,24(sp)
    80004bb2:	e862                	sd	s8,16(sp)
    80004bb4:	1080                	addi	s0,sp,96
    80004bb6:	84aa                	mv	s1,a0
    80004bb8:	8aae                	mv	s5,a1
    80004bba:	8a32                	mv	s4,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004bbc:	ffffd097          	auipc	ra,0xffffd
    80004bc0:	d4e080e7          	jalr	-690(ra) # 8000190a <myproc>
    80004bc4:	8baa                	mv	s7,a0

  acquire(&pi->lock);
    80004bc6:	8526                	mv	a0,s1
    80004bc8:	ffffc097          	auipc	ra,0xffffc
    80004bcc:	ef6080e7          	jalr	-266(ra) # 80000abe <acquire>
  for(i = 0; i < n; i++){
    80004bd0:	09405f63          	blez	s4,80004c6e <pipewrite+0xd0>
    80004bd4:	fffa0b1b          	addiw	s6,s4,-1
    80004bd8:	1b02                	slli	s6,s6,0x20
    80004bda:	020b5b13          	srli	s6,s6,0x20
    80004bde:	001a8793          	addi	a5,s5,1
    80004be2:	9b3e                	add	s6,s6,a5
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || myproc()->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004be4:	21848993          	addi	s3,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004be8:	21c48913          	addi	s2,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bec:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004bee:	2184a783          	lw	a5,536(s1)
    80004bf2:	21c4a703          	lw	a4,540(s1)
    80004bf6:	2007879b          	addiw	a5,a5,512
    80004bfa:	02f71e63          	bne	a4,a5,80004c36 <pipewrite+0x98>
      if(pi->readopen == 0 || myproc()->killed){
    80004bfe:	2204a783          	lw	a5,544(s1)
    80004c02:	c3d9                	beqz	a5,80004c88 <pipewrite+0xea>
    80004c04:	ffffd097          	auipc	ra,0xffffd
    80004c08:	d06080e7          	jalr	-762(ra) # 8000190a <myproc>
    80004c0c:	591c                	lw	a5,48(a0)
    80004c0e:	efad                	bnez	a5,80004c88 <pipewrite+0xea>
      wakeup(&pi->nread);
    80004c10:	854e                	mv	a0,s3
    80004c12:	ffffd097          	auipc	ra,0xffffd
    80004c16:	656080e7          	jalr	1622(ra) # 80002268 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c1a:	85a6                	mv	a1,s1
    80004c1c:	854a                	mv	a0,s2
    80004c1e:	ffffd097          	auipc	ra,0xffffd
    80004c22:	4ca080e7          	jalr	1226(ra) # 800020e8 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004c26:	2184a783          	lw	a5,536(s1)
    80004c2a:	21c4a703          	lw	a4,540(s1)
    80004c2e:	2007879b          	addiw	a5,a5,512
    80004c32:	fcf706e3          	beq	a4,a5,80004bfe <pipewrite+0x60>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c36:	4685                	li	a3,1
    80004c38:	8656                	mv	a2,s5
    80004c3a:	faf40593          	addi	a1,s0,-81
    80004c3e:	058bb503          	ld	a0,88(s7) # 1058 <_entry-0x7fffefa8>
    80004c42:	ffffd097          	auipc	ra,0xffffd
    80004c46:	95a080e7          	jalr	-1702(ra) # 8000159c <copyin>
    80004c4a:	03850263          	beq	a0,s8,80004c6e <pipewrite+0xd0>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c4e:	21c4a783          	lw	a5,540(s1)
    80004c52:	0017871b          	addiw	a4,a5,1
    80004c56:	20e4ae23          	sw	a4,540(s1)
    80004c5a:	1ff7f793          	andi	a5,a5,511
    80004c5e:	97a6                	add	a5,a5,s1
    80004c60:	faf44703          	lbu	a4,-81(s0)
    80004c64:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004c68:	0a85                	addi	s5,s5,1
    80004c6a:	f96a92e3          	bne	s5,s6,80004bee <pipewrite+0x50>
  }
  wakeup(&pi->nread);
    80004c6e:	21848513          	addi	a0,s1,536
    80004c72:	ffffd097          	auipc	ra,0xffffd
    80004c76:	5f6080e7          	jalr	1526(ra) # 80002268 <wakeup>
  release(&pi->lock);
    80004c7a:	8526                	mv	a0,s1
    80004c7c:	ffffc097          	auipc	ra,0xffffc
    80004c80:	eaa080e7          	jalr	-342(ra) # 80000b26 <release>
  return n;
    80004c84:	8552                	mv	a0,s4
    80004c86:	a039                	j	80004c94 <pipewrite+0xf6>
        release(&pi->lock);
    80004c88:	8526                	mv	a0,s1
    80004c8a:	ffffc097          	auipc	ra,0xffffc
    80004c8e:	e9c080e7          	jalr	-356(ra) # 80000b26 <release>
        return -1;
    80004c92:	557d                	li	a0,-1
}
    80004c94:	60e6                	ld	ra,88(sp)
    80004c96:	6446                	ld	s0,80(sp)
    80004c98:	64a6                	ld	s1,72(sp)
    80004c9a:	6906                	ld	s2,64(sp)
    80004c9c:	79e2                	ld	s3,56(sp)
    80004c9e:	7a42                	ld	s4,48(sp)
    80004ca0:	7aa2                	ld	s5,40(sp)
    80004ca2:	7b02                	ld	s6,32(sp)
    80004ca4:	6be2                	ld	s7,24(sp)
    80004ca6:	6c42                	ld	s8,16(sp)
    80004ca8:	6125                	addi	sp,sp,96
    80004caa:	8082                	ret

0000000080004cac <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004cac:	715d                	addi	sp,sp,-80
    80004cae:	e486                	sd	ra,72(sp)
    80004cb0:	e0a2                	sd	s0,64(sp)
    80004cb2:	fc26                	sd	s1,56(sp)
    80004cb4:	f84a                	sd	s2,48(sp)
    80004cb6:	f44e                	sd	s3,40(sp)
    80004cb8:	f052                	sd	s4,32(sp)
    80004cba:	ec56                	sd	s5,24(sp)
    80004cbc:	e85a                	sd	s6,16(sp)
    80004cbe:	0880                	addi	s0,sp,80
    80004cc0:	84aa                	mv	s1,a0
    80004cc2:	892e                	mv	s2,a1
    80004cc4:	8a32                	mv	s4,a2
  int i;
  struct proc *pr = myproc();
    80004cc6:	ffffd097          	auipc	ra,0xffffd
    80004cca:	c44080e7          	jalr	-956(ra) # 8000190a <myproc>
    80004cce:	8aaa                	mv	s5,a0
  char ch;

  acquire(&pi->lock);
    80004cd0:	8526                	mv	a0,s1
    80004cd2:	ffffc097          	auipc	ra,0xffffc
    80004cd6:	dec080e7          	jalr	-532(ra) # 80000abe <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cda:	2184a703          	lw	a4,536(s1)
    80004cde:	21c4a783          	lw	a5,540(s1)
    if(myproc()->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ce2:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ce6:	02f71763          	bne	a4,a5,80004d14 <piperead+0x68>
    80004cea:	2244a783          	lw	a5,548(s1)
    80004cee:	c39d                	beqz	a5,80004d14 <piperead+0x68>
    if(myproc()->killed){
    80004cf0:	ffffd097          	auipc	ra,0xffffd
    80004cf4:	c1a080e7          	jalr	-998(ra) # 8000190a <myproc>
    80004cf8:	591c                	lw	a5,48(a0)
    80004cfa:	ebc1                	bnez	a5,80004d8a <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cfc:	85a6                	mv	a1,s1
    80004cfe:	854e                	mv	a0,s3
    80004d00:	ffffd097          	auipc	ra,0xffffd
    80004d04:	3e8080e7          	jalr	1000(ra) # 800020e8 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d08:	2184a703          	lw	a4,536(s1)
    80004d0c:	21c4a783          	lw	a5,540(s1)
    80004d10:	fcf70de3          	beq	a4,a5,80004cea <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d14:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d16:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d18:	05405363          	blez	s4,80004d5e <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004d1c:	2184a783          	lw	a5,536(s1)
    80004d20:	21c4a703          	lw	a4,540(s1)
    80004d24:	02f70d63          	beq	a4,a5,80004d5e <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d28:	0017871b          	addiw	a4,a5,1
    80004d2c:	20e4ac23          	sw	a4,536(s1)
    80004d30:	1ff7f793          	andi	a5,a5,511
    80004d34:	97a6                	add	a5,a5,s1
    80004d36:	0187c783          	lbu	a5,24(a5)
    80004d3a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d3e:	4685                	li	a3,1
    80004d40:	fbf40613          	addi	a2,s0,-65
    80004d44:	85ca                	mv	a1,s2
    80004d46:	058ab503          	ld	a0,88(s5)
    80004d4a:	ffffc097          	auipc	ra,0xffffc
    80004d4e:	7c6080e7          	jalr	1990(ra) # 80001510 <copyout>
    80004d52:	01650663          	beq	a0,s6,80004d5e <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d56:	2985                	addiw	s3,s3,1
    80004d58:	0905                	addi	s2,s2,1
    80004d5a:	fd3a11e3          	bne	s4,s3,80004d1c <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d5e:	21c48513          	addi	a0,s1,540
    80004d62:	ffffd097          	auipc	ra,0xffffd
    80004d66:	506080e7          	jalr	1286(ra) # 80002268 <wakeup>
  release(&pi->lock);
    80004d6a:	8526                	mv	a0,s1
    80004d6c:	ffffc097          	auipc	ra,0xffffc
    80004d70:	dba080e7          	jalr	-582(ra) # 80000b26 <release>
  return i;
}
    80004d74:	854e                	mv	a0,s3
    80004d76:	60a6                	ld	ra,72(sp)
    80004d78:	6406                	ld	s0,64(sp)
    80004d7a:	74e2                	ld	s1,56(sp)
    80004d7c:	7942                	ld	s2,48(sp)
    80004d7e:	79a2                	ld	s3,40(sp)
    80004d80:	7a02                	ld	s4,32(sp)
    80004d82:	6ae2                	ld	s5,24(sp)
    80004d84:	6b42                	ld	s6,16(sp)
    80004d86:	6161                	addi	sp,sp,80
    80004d88:	8082                	ret
      release(&pi->lock);
    80004d8a:	8526                	mv	a0,s1
    80004d8c:	ffffc097          	auipc	ra,0xffffc
    80004d90:	d9a080e7          	jalr	-614(ra) # 80000b26 <release>
      return -1;
    80004d94:	59fd                	li	s3,-1
    80004d96:	bff9                	j	80004d74 <piperead+0xc8>

0000000080004d98 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d98:	de010113          	addi	sp,sp,-544
    80004d9c:	20113c23          	sd	ra,536(sp)
    80004da0:	20813823          	sd	s0,528(sp)
    80004da4:	20913423          	sd	s1,520(sp)
    80004da8:	21213023          	sd	s2,512(sp)
    80004dac:	ffce                	sd	s3,504(sp)
    80004dae:	fbd2                	sd	s4,496(sp)
    80004db0:	f7d6                	sd	s5,488(sp)
    80004db2:	f3da                	sd	s6,480(sp)
    80004db4:	efde                	sd	s7,472(sp)
    80004db6:	ebe2                	sd	s8,464(sp)
    80004db8:	e7e6                	sd	s9,456(sp)
    80004dba:	e3ea                	sd	s10,448(sp)
    80004dbc:	ff6e                	sd	s11,440(sp)
    80004dbe:	1400                	addi	s0,sp,544
    80004dc0:	892a                	mv	s2,a0
    80004dc2:	dea43423          	sd	a0,-536(s0)
    80004dc6:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004dca:	ffffd097          	auipc	ra,0xffffd
    80004dce:	b40080e7          	jalr	-1216(ra) # 8000190a <myproc>
    80004dd2:	84aa                	mv	s1,a0

  begin_op(ROOTDEV);
    80004dd4:	4501                	li	a0,0
    80004dd6:	fffff097          	auipc	ra,0xfffff
    80004dda:	2f2080e7          	jalr	754(ra) # 800040c8 <begin_op>

  if((ip = namei(path)) == 0){
    80004dde:	854a                	mv	a0,s2
    80004de0:	fffff097          	auipc	ra,0xfffff
    80004de4:	fca080e7          	jalr	-54(ra) # 80003daa <namei>
    80004de8:	cd25                	beqz	a0,80004e60 <exec+0xc8>
    80004dea:	8aaa                	mv	s5,a0
    end_op(ROOTDEV);
    return -1;
  }
  ilock(ip);
    80004dec:	fffff097          	auipc	ra,0xfffff
    80004df0:	834080e7          	jalr	-1996(ra) # 80003620 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004df4:	04000713          	li	a4,64
    80004df8:	4681                	li	a3,0
    80004dfa:	e4840613          	addi	a2,s0,-440
    80004dfe:	4581                	li	a1,0
    80004e00:	8556                	mv	a0,s5
    80004e02:	fffff097          	auipc	ra,0xfffff
    80004e06:	aae080e7          	jalr	-1362(ra) # 800038b0 <readi>
    80004e0a:	04000793          	li	a5,64
    80004e0e:	00f51a63          	bne	a0,a5,80004e22 <exec+0x8a>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e12:	e4842703          	lw	a4,-440(s0)
    80004e16:	464c47b7          	lui	a5,0x464c4
    80004e1a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e1e:	04f70863          	beq	a4,a5,80004e6e <exec+0xd6>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e22:	8556                	mv	a0,s5
    80004e24:	fffff097          	auipc	ra,0xfffff
    80004e28:	a3a080e7          	jalr	-1478(ra) # 8000385e <iunlockput>
    end_op(ROOTDEV);
    80004e2c:	4501                	li	a0,0
    80004e2e:	fffff097          	auipc	ra,0xfffff
    80004e32:	344080e7          	jalr	836(ra) # 80004172 <end_op>
  }
  return -1;
    80004e36:	557d                	li	a0,-1
}
    80004e38:	21813083          	ld	ra,536(sp)
    80004e3c:	21013403          	ld	s0,528(sp)
    80004e40:	20813483          	ld	s1,520(sp)
    80004e44:	20013903          	ld	s2,512(sp)
    80004e48:	79fe                	ld	s3,504(sp)
    80004e4a:	7a5e                	ld	s4,496(sp)
    80004e4c:	7abe                	ld	s5,488(sp)
    80004e4e:	7b1e                	ld	s6,480(sp)
    80004e50:	6bfe                	ld	s7,472(sp)
    80004e52:	6c5e                	ld	s8,464(sp)
    80004e54:	6cbe                	ld	s9,456(sp)
    80004e56:	6d1e                	ld	s10,448(sp)
    80004e58:	7dfa                	ld	s11,440(sp)
    80004e5a:	22010113          	addi	sp,sp,544
    80004e5e:	8082                	ret
    end_op(ROOTDEV);
    80004e60:	4501                	li	a0,0
    80004e62:	fffff097          	auipc	ra,0xfffff
    80004e66:	310080e7          	jalr	784(ra) # 80004172 <end_op>
    return -1;
    80004e6a:	557d                	li	a0,-1
    80004e6c:	b7f1                	j	80004e38 <exec+0xa0>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e6e:	8526                	mv	a0,s1
    80004e70:	ffffd097          	auipc	ra,0xffffd
    80004e74:	b5e080e7          	jalr	-1186(ra) # 800019ce <proc_pagetable>
    80004e78:	8b2a                	mv	s6,a0
    80004e7a:	d545                	beqz	a0,80004e22 <exec+0x8a>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e7c:	e6842783          	lw	a5,-408(s0)
    80004e80:	e8045703          	lhu	a4,-384(s0)
    80004e84:	10070263          	beqz	a4,80004f88 <exec+0x1f0>
  sz = 0;
    80004e88:	de043c23          	sd	zero,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e8c:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004e90:	6a05                	lui	s4,0x1
    80004e92:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004e96:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004e9a:	6d85                	lui	s11,0x1
    80004e9c:	7d7d                	lui	s10,0xfffff
    80004e9e:	a88d                	j	80004f10 <exec+0x178>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004ea0:	00004517          	auipc	a0,0x4
    80004ea4:	92850513          	addi	a0,a0,-1752 # 800087c8 <userret+0x738>
    80004ea8:	ffffb097          	auipc	ra,0xffffb
    80004eac:	6a0080e7          	jalr	1696(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004eb0:	874a                	mv	a4,s2
    80004eb2:	009c86bb          	addw	a3,s9,s1
    80004eb6:	4581                	li	a1,0
    80004eb8:	8556                	mv	a0,s5
    80004eba:	fffff097          	auipc	ra,0xfffff
    80004ebe:	9f6080e7          	jalr	-1546(ra) # 800038b0 <readi>
    80004ec2:	2501                	sext.w	a0,a0
    80004ec4:	10a91863          	bne	s2,a0,80004fd4 <exec+0x23c>
  for(i = 0; i < sz; i += PGSIZE){
    80004ec8:	009d84bb          	addw	s1,s11,s1
    80004ecc:	013d09bb          	addw	s3,s10,s3
    80004ed0:	0374f263          	bgeu	s1,s7,80004ef4 <exec+0x15c>
    pa = walkaddr(pagetable, va + i);
    80004ed4:	02049593          	slli	a1,s1,0x20
    80004ed8:	9181                	srli	a1,a1,0x20
    80004eda:	95e2                	add	a1,a1,s8
    80004edc:	855a                	mv	a0,s6
    80004ede:	ffffc097          	auipc	ra,0xffffc
    80004ee2:	09e080e7          	jalr	158(ra) # 80000f7c <walkaddr>
    80004ee6:	862a                	mv	a2,a0
    if(pa == 0)
    80004ee8:	dd45                	beqz	a0,80004ea0 <exec+0x108>
      n = PGSIZE;
    80004eea:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004eec:	fd49f2e3          	bgeu	s3,s4,80004eb0 <exec+0x118>
      n = sz - i;
    80004ef0:	894e                	mv	s2,s3
    80004ef2:	bf7d                	j	80004eb0 <exec+0x118>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ef4:	e0843783          	ld	a5,-504(s0)
    80004ef8:	0017869b          	addiw	a3,a5,1
    80004efc:	e0d43423          	sd	a3,-504(s0)
    80004f00:	e0043783          	ld	a5,-512(s0)
    80004f04:	0387879b          	addiw	a5,a5,56
    80004f08:	e8045703          	lhu	a4,-384(s0)
    80004f0c:	08e6d063          	bge	a3,a4,80004f8c <exec+0x1f4>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f10:	2781                	sext.w	a5,a5
    80004f12:	e0f43023          	sd	a5,-512(s0)
    80004f16:	03800713          	li	a4,56
    80004f1a:	86be                	mv	a3,a5
    80004f1c:	e1040613          	addi	a2,s0,-496
    80004f20:	4581                	li	a1,0
    80004f22:	8556                	mv	a0,s5
    80004f24:	fffff097          	auipc	ra,0xfffff
    80004f28:	98c080e7          	jalr	-1652(ra) # 800038b0 <readi>
    80004f2c:	03800793          	li	a5,56
    80004f30:	0af51263          	bne	a0,a5,80004fd4 <exec+0x23c>
    if(ph.type != ELF_PROG_LOAD)
    80004f34:	e1042783          	lw	a5,-496(s0)
    80004f38:	4705                	li	a4,1
    80004f3a:	fae79de3          	bne	a5,a4,80004ef4 <exec+0x15c>
    if(ph.memsz < ph.filesz)
    80004f3e:	e3843603          	ld	a2,-456(s0)
    80004f42:	e3043783          	ld	a5,-464(s0)
    80004f46:	08f66763          	bltu	a2,a5,80004fd4 <exec+0x23c>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f4a:	e2043783          	ld	a5,-480(s0)
    80004f4e:	963e                	add	a2,a2,a5
    80004f50:	08f66263          	bltu	a2,a5,80004fd4 <exec+0x23c>
    if((sz = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f54:	df843583          	ld	a1,-520(s0)
    80004f58:	855a                	mv	a0,s6
    80004f5a:	ffffc097          	auipc	ra,0xffffc
    80004f5e:	3f8080e7          	jalr	1016(ra) # 80001352 <uvmalloc>
    80004f62:	dea43c23          	sd	a0,-520(s0)
    80004f66:	c53d                	beqz	a0,80004fd4 <exec+0x23c>
    if(ph.vaddr % PGSIZE != 0)
    80004f68:	e2043c03          	ld	s8,-480(s0)
    80004f6c:	de043783          	ld	a5,-544(s0)
    80004f70:	00fc77b3          	and	a5,s8,a5
    80004f74:	e3a5                	bnez	a5,80004fd4 <exec+0x23c>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f76:	e1842c83          	lw	s9,-488(s0)
    80004f7a:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004f7e:	f60b8be3          	beqz	s7,80004ef4 <exec+0x15c>
    80004f82:	89de                	mv	s3,s7
    80004f84:	4481                	li	s1,0
    80004f86:	b7b9                	j	80004ed4 <exec+0x13c>
  sz = 0;
    80004f88:	de043c23          	sd	zero,-520(s0)
  iunlockput(ip);
    80004f8c:	8556                	mv	a0,s5
    80004f8e:	fffff097          	auipc	ra,0xfffff
    80004f92:	8d0080e7          	jalr	-1840(ra) # 8000385e <iunlockput>
  end_op(ROOTDEV);
    80004f96:	4501                	li	a0,0
    80004f98:	fffff097          	auipc	ra,0xfffff
    80004f9c:	1da080e7          	jalr	474(ra) # 80004172 <end_op>
  p = myproc();
    80004fa0:	ffffd097          	auipc	ra,0xffffd
    80004fa4:	96a080e7          	jalr	-1686(ra) # 8000190a <myproc>
    80004fa8:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004faa:	05053c83          	ld	s9,80(a0)
  sz = PGROUNDUP(sz);
    80004fae:	6585                	lui	a1,0x1
    80004fb0:	15fd                	addi	a1,a1,-1
    80004fb2:	df843783          	ld	a5,-520(s0)
    80004fb6:	95be                	add	a1,a1,a5
    80004fb8:	77fd                	lui	a5,0xfffff
    80004fba:	8dfd                	and	a1,a1,a5
  if((sz = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004fbc:	6609                	lui	a2,0x2
    80004fbe:	962e                	add	a2,a2,a1
    80004fc0:	855a                	mv	a0,s6
    80004fc2:	ffffc097          	auipc	ra,0xffffc
    80004fc6:	390080e7          	jalr	912(ra) # 80001352 <uvmalloc>
    80004fca:	892a                	mv	s2,a0
    80004fcc:	dea43c23          	sd	a0,-520(s0)
  ip = 0;
    80004fd0:	4a81                	li	s5,0
  if((sz = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004fd2:	ed01                	bnez	a0,80004fea <exec+0x252>
    proc_freepagetable(pagetable, sz);
    80004fd4:	df843583          	ld	a1,-520(s0)
    80004fd8:	855a                	mv	a0,s6
    80004fda:	ffffd097          	auipc	ra,0xffffd
    80004fde:	af4080e7          	jalr	-1292(ra) # 80001ace <proc_freepagetable>
  if(ip){
    80004fe2:	e40a90e3          	bnez	s5,80004e22 <exec+0x8a>
  return -1;
    80004fe6:	557d                	li	a0,-1
    80004fe8:	bd81                	j	80004e38 <exec+0xa0>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004fea:	75f9                	lui	a1,0xffffe
    80004fec:	95aa                	add	a1,a1,a0
    80004fee:	855a                	mv	a0,s6
    80004ff0:	ffffc097          	auipc	ra,0xffffc
    80004ff4:	4ee080e7          	jalr	1262(ra) # 800014de <uvmclear>
  stackbase = sp - PGSIZE;
    80004ff8:	7c7d                	lui	s8,0xfffff
    80004ffa:	9c4a                	add	s8,s8,s2
  p->stack_top = stackbase;  //设置用户栈栈顶，一旦below stack_top，则user_trap()捕获越界访问内存
    80004ffc:	058bb423          	sd	s8,72(s7)
  for(argc = 0; argv[argc]; argc++) {
    80005000:	df043783          	ld	a5,-528(s0)
    80005004:	6388                	ld	a0,0(a5)
    80005006:	c52d                	beqz	a0,80005070 <exec+0x2d8>
    80005008:	e8840993          	addi	s3,s0,-376
    8000500c:	f8840a93          	addi	s5,s0,-120
    80005010:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005012:	ffffc097          	auipc	ra,0xffffc
    80005016:	cf4080e7          	jalr	-780(ra) # 80000d06 <strlen>
    8000501a:	0015079b          	addiw	a5,a0,1
    8000501e:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005022:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005026:	11896063          	bltu	s2,s8,80005126 <exec+0x38e>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000502a:	df043d03          	ld	s10,-528(s0)
    8000502e:	000d3a03          	ld	s4,0(s10) # fffffffffffff000 <end+0xffffffff7ffd4fa4>
    80005032:	8552                	mv	a0,s4
    80005034:	ffffc097          	auipc	ra,0xffffc
    80005038:	cd2080e7          	jalr	-814(ra) # 80000d06 <strlen>
    8000503c:	0015069b          	addiw	a3,a0,1
    80005040:	8652                	mv	a2,s4
    80005042:	85ca                	mv	a1,s2
    80005044:	855a                	mv	a0,s6
    80005046:	ffffc097          	auipc	ra,0xffffc
    8000504a:	4ca080e7          	jalr	1226(ra) # 80001510 <copyout>
    8000504e:	0c054e63          	bltz	a0,8000512a <exec+0x392>
    ustack[argc] = sp;
    80005052:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005056:	0485                	addi	s1,s1,1
    80005058:	008d0793          	addi	a5,s10,8
    8000505c:	def43823          	sd	a5,-528(s0)
    80005060:	008d3503          	ld	a0,8(s10)
    80005064:	c909                	beqz	a0,80005076 <exec+0x2de>
    if(argc >= MAXARG)
    80005066:	09a1                	addi	s3,s3,8
    80005068:	fb3a95e3          	bne	s5,s3,80005012 <exec+0x27a>
  ip = 0;
    8000506c:	4a81                	li	s5,0
    8000506e:	b79d                	j	80004fd4 <exec+0x23c>
  sp = sz;
    80005070:	df843903          	ld	s2,-520(s0)
  for(argc = 0; argv[argc]; argc++) {
    80005074:	4481                	li	s1,0
  ustack[argc] = 0;
    80005076:	00349793          	slli	a5,s1,0x3
    8000507a:	f9040713          	addi	a4,s0,-112
    8000507e:	97ba                	add	a5,a5,a4
    80005080:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd4e9c>
  sp -= (argc+1) * sizeof(uint64);
    80005084:	00148693          	addi	a3,s1,1
    80005088:	068e                	slli	a3,a3,0x3
    8000508a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000508e:	ff097913          	andi	s2,s2,-16
  ip = 0;
    80005092:	4a81                	li	s5,0
  if(sp < stackbase)
    80005094:	f58960e3          	bltu	s2,s8,80004fd4 <exec+0x23c>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005098:	e8840613          	addi	a2,s0,-376
    8000509c:	85ca                	mv	a1,s2
    8000509e:	855a                	mv	a0,s6
    800050a0:	ffffc097          	auipc	ra,0xffffc
    800050a4:	470080e7          	jalr	1136(ra) # 80001510 <copyout>
    800050a8:	08054363          	bltz	a0,8000512e <exec+0x396>
  p->tf->a1 = sp;
    800050ac:	060bb783          	ld	a5,96(s7)
    800050b0:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800050b4:	de843783          	ld	a5,-536(s0)
    800050b8:	0007c703          	lbu	a4,0(a5)
    800050bc:	cf11                	beqz	a4,800050d8 <exec+0x340>
    800050be:	0785                	addi	a5,a5,1
    if(*s == '/')
    800050c0:	02f00693          	li	a3,47
    800050c4:	a039                	j	800050d2 <exec+0x33a>
      last = s+1;
    800050c6:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800050ca:	0785                	addi	a5,a5,1
    800050cc:	fff7c703          	lbu	a4,-1(a5)
    800050d0:	c701                	beqz	a4,800050d8 <exec+0x340>
    if(*s == '/')
    800050d2:	fed71ce3          	bne	a4,a3,800050ca <exec+0x332>
    800050d6:	bfc5                	j	800050c6 <exec+0x32e>
  safestrcpy(p->name, last, sizeof(p->name));
    800050d8:	4641                	li	a2,16
    800050da:	de843583          	ld	a1,-536(s0)
    800050de:	160b8513          	addi	a0,s7,352
    800050e2:	ffffc097          	auipc	ra,0xffffc
    800050e6:	bf2080e7          	jalr	-1038(ra) # 80000cd4 <safestrcpy>
  oldpagetable = p->pagetable;
    800050ea:	058bb503          	ld	a0,88(s7)
  p->pagetable = pagetable;
    800050ee:	056bbc23          	sd	s6,88(s7)
  p->sz = sz;
    800050f2:	df843783          	ld	a5,-520(s0)
    800050f6:	04fbb823          	sd	a5,80(s7)
  p->tf->epc = elf.entry;  // initial program counter = main
    800050fa:	060bb783          	ld	a5,96(s7)
    800050fe:	e6043703          	ld	a4,-416(s0)
    80005102:	ef98                	sd	a4,24(a5)
  p->tf->sp = sp; // initial stack pointer
    80005104:	060bb783          	ld	a5,96(s7)
    80005108:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000510c:	85e6                	mv	a1,s9
    8000510e:	ffffd097          	auipc	ra,0xffffd
    80005112:	9c0080e7          	jalr	-1600(ra) # 80001ace <proc_freepagetable>
  vmprint(pagetable);  // 添加，以打印页表
    80005116:	855a                	mv	a0,s6
    80005118:	ffffc097          	auipc	ra,0xffffc
    8000511c:	67e080e7          	jalr	1662(ra) # 80001796 <vmprint>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005120:	0004851b          	sext.w	a0,s1
    80005124:	bb11                	j	80004e38 <exec+0xa0>
  ip = 0;
    80005126:	4a81                	li	s5,0
    80005128:	b575                	j	80004fd4 <exec+0x23c>
    8000512a:	4a81                	li	s5,0
    8000512c:	b565                	j	80004fd4 <exec+0x23c>
    8000512e:	4a81                	li	s5,0
    80005130:	b555                	j	80004fd4 <exec+0x23c>

0000000080005132 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005132:	1101                	addi	sp,sp,-32
    80005134:	ec06                	sd	ra,24(sp)
    80005136:	e822                	sd	s0,16(sp)
    80005138:	e426                	sd	s1,8(sp)
    8000513a:	1000                	addi	s0,sp,32
    8000513c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000513e:	ffffc097          	auipc	ra,0xffffc
    80005142:	7cc080e7          	jalr	1996(ra) # 8000190a <myproc>
    80005146:	862a                	mv	a2,a0

  for (fd = 0; fd < NOFILE; fd++)
    80005148:	0d850793          	addi	a5,a0,216
    8000514c:	4501                	li	a0,0
    8000514e:	46c1                	li	a3,16
  {
    if (p->ofile[fd] == 0)
    80005150:	6398                	ld	a4,0(a5)
    80005152:	cb19                	beqz	a4,80005168 <fdalloc+0x36>
  for (fd = 0; fd < NOFILE; fd++)
    80005154:	2505                	addiw	a0,a0,1
    80005156:	07a1                	addi	a5,a5,8
    80005158:	fed51ce3          	bne	a0,a3,80005150 <fdalloc+0x1e>
    {
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000515c:	557d                	li	a0,-1
}
    8000515e:	60e2                	ld	ra,24(sp)
    80005160:	6442                	ld	s0,16(sp)
    80005162:	64a2                	ld	s1,8(sp)
    80005164:	6105                	addi	sp,sp,32
    80005166:	8082                	ret
      p->ofile[fd] = f;
    80005168:	01a50793          	addi	a5,a0,26
    8000516c:	078e                	slli	a5,a5,0x3
    8000516e:	963e                	add	a2,a2,a5
    80005170:	e604                	sd	s1,8(a2)
      return fd;
    80005172:	b7f5                	j	8000515e <fdalloc+0x2c>

0000000080005174 <argfd>:
{
    80005174:	7179                	addi	sp,sp,-48
    80005176:	f406                	sd	ra,40(sp)
    80005178:	f022                	sd	s0,32(sp)
    8000517a:	ec26                	sd	s1,24(sp)
    8000517c:	e84a                	sd	s2,16(sp)
    8000517e:	1800                	addi	s0,sp,48
    80005180:	892e                	mv	s2,a1
    80005182:	84b2                	mv	s1,a2
  if (argint(n, &fd) < 0)
    80005184:	fdc40593          	addi	a1,s0,-36
    80005188:	ffffe097          	auipc	ra,0xffffe
    8000518c:	8fe080e7          	jalr	-1794(ra) # 80002a86 <argint>
    80005190:	04054063          	bltz	a0,800051d0 <argfd+0x5c>
  if (fd < 0 || fd >= NOFILE || (f = myproc()->ofile[fd]) == 0)
    80005194:	fdc42703          	lw	a4,-36(s0)
    80005198:	47bd                	li	a5,15
    8000519a:	02e7ed63          	bltu	a5,a4,800051d4 <argfd+0x60>
    8000519e:	ffffc097          	auipc	ra,0xffffc
    800051a2:	76c080e7          	jalr	1900(ra) # 8000190a <myproc>
    800051a6:	fdc42703          	lw	a4,-36(s0)
    800051aa:	01a70793          	addi	a5,a4,26
    800051ae:	078e                	slli	a5,a5,0x3
    800051b0:	953e                	add	a0,a0,a5
    800051b2:	651c                	ld	a5,8(a0)
    800051b4:	c395                	beqz	a5,800051d8 <argfd+0x64>
  if (pfd)
    800051b6:	00090463          	beqz	s2,800051be <argfd+0x4a>
    *pfd = fd;
    800051ba:	00e92023          	sw	a4,0(s2)
  return 0;
    800051be:	4501                	li	a0,0
  if (pf)
    800051c0:	c091                	beqz	s1,800051c4 <argfd+0x50>
    *pf = f;
    800051c2:	e09c                	sd	a5,0(s1)
}
    800051c4:	70a2                	ld	ra,40(sp)
    800051c6:	7402                	ld	s0,32(sp)
    800051c8:	64e2                	ld	s1,24(sp)
    800051ca:	6942                	ld	s2,16(sp)
    800051cc:	6145                	addi	sp,sp,48
    800051ce:	8082                	ret
    return -1;
    800051d0:	557d                	li	a0,-1
    800051d2:	bfcd                	j	800051c4 <argfd+0x50>
    return -1;
    800051d4:	557d                	li	a0,-1
    800051d6:	b7fd                	j	800051c4 <argfd+0x50>
    800051d8:	557d                	li	a0,-1
    800051da:	b7ed                	j	800051c4 <argfd+0x50>

00000000800051dc <create>:
  return -1;
}

static struct inode *
create(char *path, short type, short major, short minor)
{
    800051dc:	715d                	addi	sp,sp,-80
    800051de:	e486                	sd	ra,72(sp)
    800051e0:	e0a2                	sd	s0,64(sp)
    800051e2:	fc26                	sd	s1,56(sp)
    800051e4:	f84a                	sd	s2,48(sp)
    800051e6:	f44e                	sd	s3,40(sp)
    800051e8:	f052                	sd	s4,32(sp)
    800051ea:	ec56                	sd	s5,24(sp)
    800051ec:	0880                	addi	s0,sp,80
    800051ee:	89ae                	mv	s3,a1
    800051f0:	8ab2                	mv	s5,a2
    800051f2:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if ((dp = nameiparent(path, name)) == 0)
    800051f4:	fb040593          	addi	a1,s0,-80
    800051f8:	fffff097          	auipc	ra,0xfffff
    800051fc:	bd0080e7          	jalr	-1072(ra) # 80003dc8 <nameiparent>
    80005200:	892a                	mv	s2,a0
    80005202:	12050e63          	beqz	a0,8000533e <create+0x162>
    return 0;

  ilock(dp);
    80005206:	ffffe097          	auipc	ra,0xffffe
    8000520a:	41a080e7          	jalr	1050(ra) # 80003620 <ilock>

  if ((ip = dirlookup(dp, name, 0)) != 0)
    8000520e:	4601                	li	a2,0
    80005210:	fb040593          	addi	a1,s0,-80
    80005214:	854a                	mv	a0,s2
    80005216:	fffff097          	auipc	ra,0xfffff
    8000521a:	8c2080e7          	jalr	-1854(ra) # 80003ad8 <dirlookup>
    8000521e:	84aa                	mv	s1,a0
    80005220:	c921                	beqz	a0,80005270 <create+0x94>
  {
    iunlockput(dp);
    80005222:	854a                	mv	a0,s2
    80005224:	ffffe097          	auipc	ra,0xffffe
    80005228:	63a080e7          	jalr	1594(ra) # 8000385e <iunlockput>
    ilock(ip);
    8000522c:	8526                	mv	a0,s1
    8000522e:	ffffe097          	auipc	ra,0xffffe
    80005232:	3f2080e7          	jalr	1010(ra) # 80003620 <ilock>
    if (type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005236:	2981                	sext.w	s3,s3
    80005238:	4789                	li	a5,2
    8000523a:	02f99463          	bne	s3,a5,80005262 <create+0x86>
    8000523e:	0444d783          	lhu	a5,68(s1)
    80005242:	37f9                	addiw	a5,a5,-2
    80005244:	17c2                	slli	a5,a5,0x30
    80005246:	93c1                	srli	a5,a5,0x30
    80005248:	4705                	li	a4,1
    8000524a:	00f76c63          	bltu	a4,a5,80005262 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000524e:	8526                	mv	a0,s1
    80005250:	60a6                	ld	ra,72(sp)
    80005252:	6406                	ld	s0,64(sp)
    80005254:	74e2                	ld	s1,56(sp)
    80005256:	7942                	ld	s2,48(sp)
    80005258:	79a2                	ld	s3,40(sp)
    8000525a:	7a02                	ld	s4,32(sp)
    8000525c:	6ae2                	ld	s5,24(sp)
    8000525e:	6161                	addi	sp,sp,80
    80005260:	8082                	ret
    iunlockput(ip);
    80005262:	8526                	mv	a0,s1
    80005264:	ffffe097          	auipc	ra,0xffffe
    80005268:	5fa080e7          	jalr	1530(ra) # 8000385e <iunlockput>
    return 0;
    8000526c:	4481                	li	s1,0
    8000526e:	b7c5                	j	8000524e <create+0x72>
  if ((ip = ialloc(dp->dev, type)) == 0)
    80005270:	85ce                	mv	a1,s3
    80005272:	00092503          	lw	a0,0(s2)
    80005276:	ffffe097          	auipc	ra,0xffffe
    8000527a:	212080e7          	jalr	530(ra) # 80003488 <ialloc>
    8000527e:	84aa                	mv	s1,a0
    80005280:	c521                	beqz	a0,800052c8 <create+0xec>
  ilock(ip);
    80005282:	ffffe097          	auipc	ra,0xffffe
    80005286:	39e080e7          	jalr	926(ra) # 80003620 <ilock>
  ip->major = major;
    8000528a:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000528e:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005292:	4a05                	li	s4,1
    80005294:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005298:	8526                	mv	a0,s1
    8000529a:	ffffe097          	auipc	ra,0xffffe
    8000529e:	2bc080e7          	jalr	700(ra) # 80003556 <iupdate>
  if (type == T_DIR)
    800052a2:	2981                	sext.w	s3,s3
    800052a4:	03498a63          	beq	s3,s4,800052d8 <create+0xfc>
  if (dirlink(dp, name, ip->inum) < 0)
    800052a8:	40d0                	lw	a2,4(s1)
    800052aa:	fb040593          	addi	a1,s0,-80
    800052ae:	854a                	mv	a0,s2
    800052b0:	fffff097          	auipc	ra,0xfffff
    800052b4:	a38080e7          	jalr	-1480(ra) # 80003ce8 <dirlink>
    800052b8:	06054b63          	bltz	a0,8000532e <create+0x152>
  iunlockput(dp);
    800052bc:	854a                	mv	a0,s2
    800052be:	ffffe097          	auipc	ra,0xffffe
    800052c2:	5a0080e7          	jalr	1440(ra) # 8000385e <iunlockput>
  return ip;
    800052c6:	b761                	j	8000524e <create+0x72>
    panic("create: ialloc");
    800052c8:	00003517          	auipc	a0,0x3
    800052cc:	52050513          	addi	a0,a0,1312 # 800087e8 <userret+0x758>
    800052d0:	ffffb097          	auipc	ra,0xffffb
    800052d4:	278080e7          	jalr	632(ra) # 80000548 <panic>
    dp->nlink++; // for ".."
    800052d8:	04a95783          	lhu	a5,74(s2)
    800052dc:	2785                	addiw	a5,a5,1
    800052de:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800052e2:	854a                	mv	a0,s2
    800052e4:	ffffe097          	auipc	ra,0xffffe
    800052e8:	272080e7          	jalr	626(ra) # 80003556 <iupdate>
    if (dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800052ec:	40d0                	lw	a2,4(s1)
    800052ee:	00003597          	auipc	a1,0x3
    800052f2:	50a58593          	addi	a1,a1,1290 # 800087f8 <userret+0x768>
    800052f6:	8526                	mv	a0,s1
    800052f8:	fffff097          	auipc	ra,0xfffff
    800052fc:	9f0080e7          	jalr	-1552(ra) # 80003ce8 <dirlink>
    80005300:	00054f63          	bltz	a0,8000531e <create+0x142>
    80005304:	00492603          	lw	a2,4(s2)
    80005308:	00003597          	auipc	a1,0x3
    8000530c:	4f858593          	addi	a1,a1,1272 # 80008800 <userret+0x770>
    80005310:	8526                	mv	a0,s1
    80005312:	fffff097          	auipc	ra,0xfffff
    80005316:	9d6080e7          	jalr	-1578(ra) # 80003ce8 <dirlink>
    8000531a:	f80557e3          	bgez	a0,800052a8 <create+0xcc>
      panic("create dots");
    8000531e:	00003517          	auipc	a0,0x3
    80005322:	4ea50513          	addi	a0,a0,1258 # 80008808 <userret+0x778>
    80005326:	ffffb097          	auipc	ra,0xffffb
    8000532a:	222080e7          	jalr	546(ra) # 80000548 <panic>
    panic("create: dirlink");
    8000532e:	00003517          	auipc	a0,0x3
    80005332:	4ea50513          	addi	a0,a0,1258 # 80008818 <userret+0x788>
    80005336:	ffffb097          	auipc	ra,0xffffb
    8000533a:	212080e7          	jalr	530(ra) # 80000548 <panic>
    return 0;
    8000533e:	84aa                	mv	s1,a0
    80005340:	b739                	j	8000524e <create+0x72>

0000000080005342 <sys_lazyalloc>:
{
    80005342:	7139                	addi	sp,sp,-64
    80005344:	fc06                	sd	ra,56(sp)
    80005346:	f822                	sd	s0,48(sp)
    80005348:	f426                	sd	s1,40(sp)
    8000534a:	f04a                	sd	s2,32(sp)
    8000534c:	ec4e                	sd	s3,24(sp)
    8000534e:	e852                	sd	s4,16(sp)
    80005350:	e456                	sd	s5,8(sp)
    80005352:	e05a                	sd	s6,0(sp)
    80005354:	0080                	addi	s0,sp,64
    80005356:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80005358:	ffffc097          	auipc	ra,0xffffc
    8000535c:	5b2080e7          	jalr	1458(ra) # 8000190a <myproc>
    80005360:	8aaa                	mv	s5,a0
  if (fault_vaddr < p->stack_top && fault_vaddr >= p->stack_top - PGSIZE)
    80005362:	653c                	ld	a5,72(a0)
    80005364:	00fa7663          	bgeu	s4,a5,80005370 <sys_lazyalloc+0x2e>
    80005368:	777d                	lui	a4,0xfffff
    8000536a:	97ba                	add	a5,a5,a4
    8000536c:	0cfa7f63          	bgeu	s4,a5,8000544a <sys_lazyalloc+0x108>
  if (fault_vaddr >= p->sz)
    80005370:	050ab783          	ld	a5,80(s5)
    80005374:	0cfa7d63          	bgeu	s4,a5,8000544e <sys_lazyalloc+0x10c>
  pte_t *pte = sys_walk(p->pagetable, fault_vaddr, 1);
    80005378:	058ab483          	ld	s1,88(s5)
  if (va >= MAXVA)
    8000537c:	57fd                	li	a5,-1
    8000537e:	83e9                	srli	a5,a5,0x1a
    80005380:	49f9                	li	s3,30
  for (int level = 2; level > 0; level--)
    80005382:	4b31                	li	s6,12
  if (va >= MAXVA)
    80005384:	0547f063          	bgeu	a5,s4,800053c4 <sys_lazyalloc+0x82>
    panic("walk");
    80005388:	00003517          	auipc	a0,0x3
    8000538c:	e3050513          	addi	a0,a0,-464 # 800081b8 <userret+0x128>
    80005390:	ffffb097          	auipc	ra,0xffffb
    80005394:	1b8080e7          	jalr	440(ra) # 80000548 <panic>
      if (!alloc || (pagetable = (pde_t *)kalloc()) == 0)
    80005398:	ffffb097          	auipc	ra,0xffffb
    8000539c:	5b8080e7          	jalr	1464(ra) # 80000950 <kalloc>
    800053a0:	84aa                	mv	s1,a0
    800053a2:	c529                	beqz	a0,800053ec <sys_lazyalloc+0xaa>
      memset(pagetable, 0, PGSIZE);
    800053a4:	6605                	lui	a2,0x1
    800053a6:	4581                	li	a1,0
    800053a8:	ffffb097          	auipc	ra,0xffffb
    800053ac:	7da080e7          	jalr	2010(ra) # 80000b82 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800053b0:	00c4d793          	srli	a5,s1,0xc
    800053b4:	07aa                	slli	a5,a5,0xa
    800053b6:	0017e793          	ori	a5,a5,1
    800053ba:	00f93023          	sd	a5,0(s2)
  for (int level = 2; level > 0; level--)
    800053be:	39dd                	addiw	s3,s3,-9
    800053c0:	03698063          	beq	s3,s6,800053e0 <sys_lazyalloc+0x9e>
    pte_t *pte = &pagetable[PX(level, va)];
    800053c4:	013a5933          	srl	s2,s4,s3
    800053c8:	1ff97913          	andi	s2,s2,511
    800053cc:	090e                	slli	s2,s2,0x3
    800053ce:	9926                	add	s2,s2,s1
    if (*pte & PTE_V)
    800053d0:	00093483          	ld	s1,0(s2)
    800053d4:	0014f793          	andi	a5,s1,1
    800053d8:	d3e1                	beqz	a5,80005398 <sys_lazyalloc+0x56>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800053da:	80a9                	srli	s1,s1,0xa
    800053dc:	04b2                	slli	s1,s1,0xc
    800053de:	b7c5                	j	800053be <sys_lazyalloc+0x7c>
  return &pagetable[PX(0, va)];
    800053e0:	00ca5793          	srli	a5,s4,0xc
    800053e4:	1ff7f793          	andi	a5,a5,511
    800053e8:	078e                	slli	a5,a5,0x3
    800053ea:	94be                	add	s1,s1,a5
  if (!(*pte & PTE_V))
    800053ec:	6084                	ld	s1,0(s1)
    800053ee:	8885                	andi	s1,s1,1
    800053f0:	cc89                	beqz	s1,8000540a <sys_lazyalloc+0xc8>
  return 0;
    800053f2:	4481                	li	s1,0
}
    800053f4:	8526                	mv	a0,s1
    800053f6:	70e2                	ld	ra,56(sp)
    800053f8:	7442                	ld	s0,48(sp)
    800053fa:	74a2                	ld	s1,40(sp)
    800053fc:	7902                	ld	s2,32(sp)
    800053fe:	69e2                	ld	s3,24(sp)
    80005400:	6a42                	ld	s4,16(sp)
    80005402:	6aa2                	ld	s5,8(sp)
    80005404:	6b02                	ld	s6,0(sp)
    80005406:	6121                	addi	sp,sp,64
    80005408:	8082                	ret
    mem = kalloc();
    8000540a:	ffffb097          	auipc	ra,0xffffb
    8000540e:	546080e7          	jalr	1350(ra) # 80000950 <kalloc>
    80005412:	892a                	mv	s2,a0
    if (!mem)
    80005414:	cd1d                	beqz	a0,80005452 <sys_lazyalloc+0x110>
    memset(mem, 0, PGSIZE);
    80005416:	6605                	lui	a2,0x1
    80005418:	4581                	li	a1,0
    8000541a:	ffffb097          	auipc	ra,0xffffb
    8000541e:	768080e7          	jalr	1896(ra) # 80000b82 <memset>
    if (mappages(p->pagetable, fault_page, PGSIZE, (uint64)mem, PTE_W | PTE_X | PTE_R | PTE_U) != 0)
    80005422:	4779                	li	a4,30
    80005424:	86ca                	mv	a3,s2
    80005426:	6605                	lui	a2,0x1
    80005428:	75fd                	lui	a1,0xfffff
    8000542a:	00ba75b3          	and	a1,s4,a1
    8000542e:	058ab503          	ld	a0,88(s5)
    80005432:	ffffc097          	auipc	ra,0xffffc
    80005436:	bea080e7          	jalr	-1046(ra) # 8000101c <mappages>
    8000543a:	dd4d                	beqz	a0,800053f4 <sys_lazyalloc+0xb2>
      kfree(mem);
    8000543c:	854a                	mv	a0,s2
    8000543e:	ffffb097          	auipc	ra,0xffffb
    80005442:	416080e7          	jalr	1046(ra) # 80000854 <kfree>
      return -1;
    80005446:	54fd                	li	s1,-1
    80005448:	b775                	j	800053f4 <sys_lazyalloc+0xb2>
    return -1;
    8000544a:	54fd                	li	s1,-1
    8000544c:	b765                	j	800053f4 <sys_lazyalloc+0xb2>
    return -1;
    8000544e:	54fd                	li	s1,-1
    80005450:	b755                	j	800053f4 <sys_lazyalloc+0xb2>
      return -1;
    80005452:	54fd                	li	s1,-1
    80005454:	b745                	j	800053f4 <sys_lazyalloc+0xb2>

0000000080005456 <sys_dup>:
{
    80005456:	7179                	addi	sp,sp,-48
    80005458:	f406                	sd	ra,40(sp)
    8000545a:	f022                	sd	s0,32(sp)
    8000545c:	ec26                	sd	s1,24(sp)
    8000545e:	1800                	addi	s0,sp,48
  if (argfd(0, 0, &f) < 0)
    80005460:	fd840613          	addi	a2,s0,-40
    80005464:	4581                	li	a1,0
    80005466:	4501                	li	a0,0
    80005468:	00000097          	auipc	ra,0x0
    8000546c:	d0c080e7          	jalr	-756(ra) # 80005174 <argfd>
    return -1;
    80005470:	57fd                	li	a5,-1
  if (argfd(0, 0, &f) < 0)
    80005472:	02054363          	bltz	a0,80005498 <sys_dup+0x42>
  if ((fd = fdalloc(f)) < 0)
    80005476:	fd843503          	ld	a0,-40(s0)
    8000547a:	00000097          	auipc	ra,0x0
    8000547e:	cb8080e7          	jalr	-840(ra) # 80005132 <fdalloc>
    80005482:	84aa                	mv	s1,a0
    return -1;
    80005484:	57fd                	li	a5,-1
  if ((fd = fdalloc(f)) < 0)
    80005486:	00054963          	bltz	a0,80005498 <sys_dup+0x42>
  filedup(f);
    8000548a:	fd843503          	ld	a0,-40(s0)
    8000548e:	fffff097          	auipc	ra,0xfffff
    80005492:	210080e7          	jalr	528(ra) # 8000469e <filedup>
  return fd;
    80005496:	87a6                	mv	a5,s1
}
    80005498:	853e                	mv	a0,a5
    8000549a:	70a2                	ld	ra,40(sp)
    8000549c:	7402                	ld	s0,32(sp)
    8000549e:	64e2                	ld	s1,24(sp)
    800054a0:	6145                	addi	sp,sp,48
    800054a2:	8082                	ret

00000000800054a4 <sys_read>:
{
    800054a4:	715d                	addi	sp,sp,-80
    800054a6:	e486                	sd	ra,72(sp)
    800054a8:	e0a2                	sd	s0,64(sp)
    800054aa:	fc26                	sd	s1,56(sp)
    800054ac:	f84a                	sd	s2,48(sp)
    800054ae:	f44e                	sd	s3,40(sp)
    800054b0:	0880                	addi	s0,sp,80
  if (argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054b2:	fc840613          	addi	a2,s0,-56
    800054b6:	4581                	li	a1,0
    800054b8:	4501                	li	a0,0
    800054ba:	00000097          	auipc	ra,0x0
    800054be:	cba080e7          	jalr	-838(ra) # 80005174 <argfd>
    800054c2:	87aa                	mv	a5,a0
    return -1;
    800054c4:	557d                	li	a0,-1
  if (argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054c6:	0807c063          	bltz	a5,80005546 <sys_read+0xa2>
    800054ca:	fc440593          	addi	a1,s0,-60
    800054ce:	4509                	li	a0,2
    800054d0:	ffffd097          	auipc	ra,0xffffd
    800054d4:	5b6080e7          	jalr	1462(ra) # 80002a86 <argint>
    800054d8:	87aa                	mv	a5,a0
    return -1;
    800054da:	557d                	li	a0,-1
  if (argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054dc:	0607c563          	bltz	a5,80005546 <sys_read+0xa2>
    800054e0:	fb840593          	addi	a1,s0,-72
    800054e4:	4505                	li	a0,1
    800054e6:	ffffd097          	auipc	ra,0xffffd
    800054ea:	5c2080e7          	jalr	1474(ra) # 80002aa8 <argaddr>
    800054ee:	06054363          	bltz	a0,80005554 <sys_read+0xb0>
  uint64 i = p;
    800054f2:	fb843483          	ld	s1,-72(s0)
  while (i < p + n)
    800054f6:	fc442503          	lw	a0,-60(s0)
    800054fa:	9526                	add	a0,a0,s1
    800054fc:	02a4f363          	bgeu	s1,a0,80005522 <sys_read+0x7e>
    if (sys_lazyalloc(i) == -1)
    80005500:	597d                	li	s2,-1
    i = i + PGSIZE;
    80005502:	6985                	lui	s3,0x1
    if (sys_lazyalloc(i) == -1)
    80005504:	8526                	mv	a0,s1
    80005506:	00000097          	auipc	ra,0x0
    8000550a:	e3c080e7          	jalr	-452(ra) # 80005342 <sys_lazyalloc>
    8000550e:	03250c63          	beq	a0,s2,80005546 <sys_read+0xa2>
    i = i + PGSIZE;
    80005512:	94ce                	add	s1,s1,s3
  while (i < p + n)
    80005514:	fc442503          	lw	a0,-60(s0)
    80005518:	fb843783          	ld	a5,-72(s0)
    8000551c:	953e                	add	a0,a0,a5
    8000551e:	fea4e3e3          	bltu	s1,a0,80005504 <sys_read+0x60>
  if (sys_lazyalloc(p + n - 1) == -1)
    80005522:	157d                	addi	a0,a0,-1
    80005524:	00000097          	auipc	ra,0x0
    80005528:	e1e080e7          	jalr	-482(ra) # 80005342 <sys_lazyalloc>
    8000552c:	57fd                	li	a5,-1
    8000552e:	00f50c63          	beq	a0,a5,80005546 <sys_read+0xa2>
  return fileread(f, p, n);
    80005532:	fc442603          	lw	a2,-60(s0)
    80005536:	fb843583          	ld	a1,-72(s0)
    8000553a:	fc843503          	ld	a0,-56(s0)
    8000553e:	fffff097          	auipc	ra,0xfffff
    80005542:	2f4080e7          	jalr	756(ra) # 80004832 <fileread>
}
    80005546:	60a6                	ld	ra,72(sp)
    80005548:	6406                	ld	s0,64(sp)
    8000554a:	74e2                	ld	s1,56(sp)
    8000554c:	7942                	ld	s2,48(sp)
    8000554e:	79a2                	ld	s3,40(sp)
    80005550:	6161                	addi	sp,sp,80
    80005552:	8082                	ret
    return -1;
    80005554:	557d                	li	a0,-1
    80005556:	bfc5                	j	80005546 <sys_read+0xa2>

0000000080005558 <sys_write>:
{
    80005558:	715d                	addi	sp,sp,-80
    8000555a:	e486                	sd	ra,72(sp)
    8000555c:	e0a2                	sd	s0,64(sp)
    8000555e:	fc26                	sd	s1,56(sp)
    80005560:	f84a                	sd	s2,48(sp)
    80005562:	f44e                	sd	s3,40(sp)
    80005564:	0880                	addi	s0,sp,80
  if (argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005566:	fc840613          	addi	a2,s0,-56
    8000556a:	4581                	li	a1,0
    8000556c:	4501                	li	a0,0
    8000556e:	00000097          	auipc	ra,0x0
    80005572:	c06080e7          	jalr	-1018(ra) # 80005174 <argfd>
    80005576:	87aa                	mv	a5,a0
    return -1;
    80005578:	557d                	li	a0,-1
  if (argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000557a:	0807c063          	bltz	a5,800055fa <sys_write+0xa2>
    8000557e:	fc440593          	addi	a1,s0,-60
    80005582:	4509                	li	a0,2
    80005584:	ffffd097          	auipc	ra,0xffffd
    80005588:	502080e7          	jalr	1282(ra) # 80002a86 <argint>
    8000558c:	87aa                	mv	a5,a0
    return -1;
    8000558e:	557d                	li	a0,-1
  if (argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005590:	0607c563          	bltz	a5,800055fa <sys_write+0xa2>
    80005594:	fb840593          	addi	a1,s0,-72
    80005598:	4505                	li	a0,1
    8000559a:	ffffd097          	auipc	ra,0xffffd
    8000559e:	50e080e7          	jalr	1294(ra) # 80002aa8 <argaddr>
    800055a2:	06054363          	bltz	a0,80005608 <sys_write+0xb0>
  uint64 i = p;
    800055a6:	fb843483          	ld	s1,-72(s0)
  while (i < p + n)
    800055aa:	fc442503          	lw	a0,-60(s0)
    800055ae:	9526                	add	a0,a0,s1
    800055b0:	02a4f363          	bgeu	s1,a0,800055d6 <sys_write+0x7e>
    if (sys_lazyalloc(i) == -1)
    800055b4:	597d                	li	s2,-1
    i = i + PGSIZE;
    800055b6:	6985                	lui	s3,0x1
    if (sys_lazyalloc(i) == -1)
    800055b8:	8526                	mv	a0,s1
    800055ba:	00000097          	auipc	ra,0x0
    800055be:	d88080e7          	jalr	-632(ra) # 80005342 <sys_lazyalloc>
    800055c2:	03250c63          	beq	a0,s2,800055fa <sys_write+0xa2>
    i = i + PGSIZE;
    800055c6:	94ce                	add	s1,s1,s3
  while (i < p + n)
    800055c8:	fc442503          	lw	a0,-60(s0)
    800055cc:	fb843783          	ld	a5,-72(s0)
    800055d0:	953e                	add	a0,a0,a5
    800055d2:	fea4e3e3          	bltu	s1,a0,800055b8 <sys_write+0x60>
  if (sys_lazyalloc(p + n - 1) == -1)
    800055d6:	157d                	addi	a0,a0,-1
    800055d8:	00000097          	auipc	ra,0x0
    800055dc:	d6a080e7          	jalr	-662(ra) # 80005342 <sys_lazyalloc>
    800055e0:	57fd                	li	a5,-1
    800055e2:	00f50c63          	beq	a0,a5,800055fa <sys_write+0xa2>
  return filewrite(f, p, n);
    800055e6:	fc442603          	lw	a2,-60(s0)
    800055ea:	fb843583          	ld	a1,-72(s0)
    800055ee:	fc843503          	ld	a0,-56(s0)
    800055f2:	fffff097          	auipc	ra,0xfffff
    800055f6:	306080e7          	jalr	774(ra) # 800048f8 <filewrite>
}
    800055fa:	60a6                	ld	ra,72(sp)
    800055fc:	6406                	ld	s0,64(sp)
    800055fe:	74e2                	ld	s1,56(sp)
    80005600:	7942                	ld	s2,48(sp)
    80005602:	79a2                	ld	s3,40(sp)
    80005604:	6161                	addi	sp,sp,80
    80005606:	8082                	ret
    return -1;
    80005608:	557d                	li	a0,-1
    8000560a:	bfc5                	j	800055fa <sys_write+0xa2>

000000008000560c <sys_close>:
{
    8000560c:	1101                	addi	sp,sp,-32
    8000560e:	ec06                	sd	ra,24(sp)
    80005610:	e822                	sd	s0,16(sp)
    80005612:	1000                	addi	s0,sp,32
  if (argfd(0, &fd, &f) < 0)
    80005614:	fe040613          	addi	a2,s0,-32
    80005618:	fec40593          	addi	a1,s0,-20
    8000561c:	4501                	li	a0,0
    8000561e:	00000097          	auipc	ra,0x0
    80005622:	b56080e7          	jalr	-1194(ra) # 80005174 <argfd>
    return -1;
    80005626:	57fd                	li	a5,-1
  if (argfd(0, &fd, &f) < 0)
    80005628:	02054463          	bltz	a0,80005650 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000562c:	ffffc097          	auipc	ra,0xffffc
    80005630:	2de080e7          	jalr	734(ra) # 8000190a <myproc>
    80005634:	fec42783          	lw	a5,-20(s0)
    80005638:	07e9                	addi	a5,a5,26
    8000563a:	078e                	slli	a5,a5,0x3
    8000563c:	97aa                	add	a5,a5,a0
    8000563e:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80005642:	fe043503          	ld	a0,-32(s0)
    80005646:	fffff097          	auipc	ra,0xfffff
    8000564a:	0aa080e7          	jalr	170(ra) # 800046f0 <fileclose>
  return 0;
    8000564e:	4781                	li	a5,0
}
    80005650:	853e                	mv	a0,a5
    80005652:	60e2                	ld	ra,24(sp)
    80005654:	6442                	ld	s0,16(sp)
    80005656:	6105                	addi	sp,sp,32
    80005658:	8082                	ret

000000008000565a <sys_fstat>:
{
    8000565a:	1101                	addi	sp,sp,-32
    8000565c:	ec06                	sd	ra,24(sp)
    8000565e:	e822                	sd	s0,16(sp)
    80005660:	1000                	addi	s0,sp,32
  if (argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005662:	fe840613          	addi	a2,s0,-24
    80005666:	4581                	li	a1,0
    80005668:	4501                	li	a0,0
    8000566a:	00000097          	auipc	ra,0x0
    8000566e:	b0a080e7          	jalr	-1270(ra) # 80005174 <argfd>
    return -1;
    80005672:	57fd                	li	a5,-1
  if (argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005674:	02054563          	bltz	a0,8000569e <sys_fstat+0x44>
    80005678:	fe040593          	addi	a1,s0,-32
    8000567c:	4505                	li	a0,1
    8000567e:	ffffd097          	auipc	ra,0xffffd
    80005682:	42a080e7          	jalr	1066(ra) # 80002aa8 <argaddr>
    return -1;
    80005686:	57fd                	li	a5,-1
  if (argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005688:	00054b63          	bltz	a0,8000569e <sys_fstat+0x44>
  return filestat(f, st);
    8000568c:	fe043583          	ld	a1,-32(s0)
    80005690:	fe843503          	ld	a0,-24(s0)
    80005694:	fffff097          	auipc	ra,0xfffff
    80005698:	12c080e7          	jalr	300(ra) # 800047c0 <filestat>
    8000569c:	87aa                	mv	a5,a0
}
    8000569e:	853e                	mv	a0,a5
    800056a0:	60e2                	ld	ra,24(sp)
    800056a2:	6442                	ld	s0,16(sp)
    800056a4:	6105                	addi	sp,sp,32
    800056a6:	8082                	ret

00000000800056a8 <sys_link>:
{
    800056a8:	7169                	addi	sp,sp,-304
    800056aa:	f606                	sd	ra,296(sp)
    800056ac:	f222                	sd	s0,288(sp)
    800056ae:	ee26                	sd	s1,280(sp)
    800056b0:	ea4a                	sd	s2,272(sp)
    800056b2:	1a00                	addi	s0,sp,304
  if (argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056b4:	08000613          	li	a2,128
    800056b8:	ed040593          	addi	a1,s0,-304
    800056bc:	4501                	li	a0,0
    800056be:	ffffd097          	auipc	ra,0xffffd
    800056c2:	40c080e7          	jalr	1036(ra) # 80002aca <argstr>
    return -1;
    800056c6:	57fd                	li	a5,-1
  if (argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056c8:	12054363          	bltz	a0,800057ee <sys_link+0x146>
    800056cc:	08000613          	li	a2,128
    800056d0:	f5040593          	addi	a1,s0,-176
    800056d4:	4505                	li	a0,1
    800056d6:	ffffd097          	auipc	ra,0xffffd
    800056da:	3f4080e7          	jalr	1012(ra) # 80002aca <argstr>
    return -1;
    800056de:	57fd                	li	a5,-1
  if (argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056e0:	10054763          	bltz	a0,800057ee <sys_link+0x146>
  begin_op(ROOTDEV);
    800056e4:	4501                	li	a0,0
    800056e6:	fffff097          	auipc	ra,0xfffff
    800056ea:	9e2080e7          	jalr	-1566(ra) # 800040c8 <begin_op>
  if ((ip = namei(old)) == 0)
    800056ee:	ed040513          	addi	a0,s0,-304
    800056f2:	ffffe097          	auipc	ra,0xffffe
    800056f6:	6b8080e7          	jalr	1720(ra) # 80003daa <namei>
    800056fa:	84aa                	mv	s1,a0
    800056fc:	c559                	beqz	a0,8000578a <sys_link+0xe2>
  ilock(ip);
    800056fe:	ffffe097          	auipc	ra,0xffffe
    80005702:	f22080e7          	jalr	-222(ra) # 80003620 <ilock>
  if (ip->type == T_DIR)
    80005706:	04449703          	lh	a4,68(s1)
    8000570a:	4785                	li	a5,1
    8000570c:	08f70663          	beq	a4,a5,80005798 <sys_link+0xf0>
  ip->nlink++;
    80005710:	04a4d783          	lhu	a5,74(s1)
    80005714:	2785                	addiw	a5,a5,1
    80005716:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000571a:	8526                	mv	a0,s1
    8000571c:	ffffe097          	auipc	ra,0xffffe
    80005720:	e3a080e7          	jalr	-454(ra) # 80003556 <iupdate>
  iunlock(ip);
    80005724:	8526                	mv	a0,s1
    80005726:	ffffe097          	auipc	ra,0xffffe
    8000572a:	fbc080e7          	jalr	-68(ra) # 800036e2 <iunlock>
  if ((dp = nameiparent(new, name)) == 0)
    8000572e:	fd040593          	addi	a1,s0,-48
    80005732:	f5040513          	addi	a0,s0,-176
    80005736:	ffffe097          	auipc	ra,0xffffe
    8000573a:	692080e7          	jalr	1682(ra) # 80003dc8 <nameiparent>
    8000573e:	892a                	mv	s2,a0
    80005740:	cd2d                	beqz	a0,800057ba <sys_link+0x112>
  ilock(dp);
    80005742:	ffffe097          	auipc	ra,0xffffe
    80005746:	ede080e7          	jalr	-290(ra) # 80003620 <ilock>
  if (dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0)
    8000574a:	00092703          	lw	a4,0(s2)
    8000574e:	409c                	lw	a5,0(s1)
    80005750:	06f71063          	bne	a4,a5,800057b0 <sys_link+0x108>
    80005754:	40d0                	lw	a2,4(s1)
    80005756:	fd040593          	addi	a1,s0,-48
    8000575a:	854a                	mv	a0,s2
    8000575c:	ffffe097          	auipc	ra,0xffffe
    80005760:	58c080e7          	jalr	1420(ra) # 80003ce8 <dirlink>
    80005764:	04054663          	bltz	a0,800057b0 <sys_link+0x108>
  iunlockput(dp);
    80005768:	854a                	mv	a0,s2
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	0f4080e7          	jalr	244(ra) # 8000385e <iunlockput>
  iput(ip);
    80005772:	8526                	mv	a0,s1
    80005774:	ffffe097          	auipc	ra,0xffffe
    80005778:	fba080e7          	jalr	-70(ra) # 8000372e <iput>
  end_op(ROOTDEV);
    8000577c:	4501                	li	a0,0
    8000577e:	fffff097          	auipc	ra,0xfffff
    80005782:	9f4080e7          	jalr	-1548(ra) # 80004172 <end_op>
  return 0;
    80005786:	4781                	li	a5,0
    80005788:	a09d                	j	800057ee <sys_link+0x146>
    end_op(ROOTDEV);
    8000578a:	4501                	li	a0,0
    8000578c:	fffff097          	auipc	ra,0xfffff
    80005790:	9e6080e7          	jalr	-1562(ra) # 80004172 <end_op>
    return -1;
    80005794:	57fd                	li	a5,-1
    80005796:	a8a1                	j	800057ee <sys_link+0x146>
    iunlockput(ip);
    80005798:	8526                	mv	a0,s1
    8000579a:	ffffe097          	auipc	ra,0xffffe
    8000579e:	0c4080e7          	jalr	196(ra) # 8000385e <iunlockput>
    end_op(ROOTDEV);
    800057a2:	4501                	li	a0,0
    800057a4:	fffff097          	auipc	ra,0xfffff
    800057a8:	9ce080e7          	jalr	-1586(ra) # 80004172 <end_op>
    return -1;
    800057ac:	57fd                	li	a5,-1
    800057ae:	a081                	j	800057ee <sys_link+0x146>
    iunlockput(dp);
    800057b0:	854a                	mv	a0,s2
    800057b2:	ffffe097          	auipc	ra,0xffffe
    800057b6:	0ac080e7          	jalr	172(ra) # 8000385e <iunlockput>
  ilock(ip);
    800057ba:	8526                	mv	a0,s1
    800057bc:	ffffe097          	auipc	ra,0xffffe
    800057c0:	e64080e7          	jalr	-412(ra) # 80003620 <ilock>
  ip->nlink--;
    800057c4:	04a4d783          	lhu	a5,74(s1)
    800057c8:	37fd                	addiw	a5,a5,-1
    800057ca:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057ce:	8526                	mv	a0,s1
    800057d0:	ffffe097          	auipc	ra,0xffffe
    800057d4:	d86080e7          	jalr	-634(ra) # 80003556 <iupdate>
  iunlockput(ip);
    800057d8:	8526                	mv	a0,s1
    800057da:	ffffe097          	auipc	ra,0xffffe
    800057de:	084080e7          	jalr	132(ra) # 8000385e <iunlockput>
  end_op(ROOTDEV);
    800057e2:	4501                	li	a0,0
    800057e4:	fffff097          	auipc	ra,0xfffff
    800057e8:	98e080e7          	jalr	-1650(ra) # 80004172 <end_op>
  return -1;
    800057ec:	57fd                	li	a5,-1
}
    800057ee:	853e                	mv	a0,a5
    800057f0:	70b2                	ld	ra,296(sp)
    800057f2:	7412                	ld	s0,288(sp)
    800057f4:	64f2                	ld	s1,280(sp)
    800057f6:	6952                	ld	s2,272(sp)
    800057f8:	6155                	addi	sp,sp,304
    800057fa:	8082                	ret

00000000800057fc <sys_unlink>:
{
    800057fc:	7151                	addi	sp,sp,-240
    800057fe:	f586                	sd	ra,232(sp)
    80005800:	f1a2                	sd	s0,224(sp)
    80005802:	eda6                	sd	s1,216(sp)
    80005804:	e9ca                	sd	s2,208(sp)
    80005806:	e5ce                	sd	s3,200(sp)
    80005808:	1980                	addi	s0,sp,240
  if (argstr(0, path, MAXPATH) < 0)
    8000580a:	08000613          	li	a2,128
    8000580e:	f3040593          	addi	a1,s0,-208
    80005812:	4501                	li	a0,0
    80005814:	ffffd097          	auipc	ra,0xffffd
    80005818:	2b6080e7          	jalr	694(ra) # 80002aca <argstr>
    8000581c:	18054463          	bltz	a0,800059a4 <sys_unlink+0x1a8>
  begin_op(ROOTDEV);
    80005820:	4501                	li	a0,0
    80005822:	fffff097          	auipc	ra,0xfffff
    80005826:	8a6080e7          	jalr	-1882(ra) # 800040c8 <begin_op>
  if ((dp = nameiparent(path, name)) == 0)
    8000582a:	fb040593          	addi	a1,s0,-80
    8000582e:	f3040513          	addi	a0,s0,-208
    80005832:	ffffe097          	auipc	ra,0xffffe
    80005836:	596080e7          	jalr	1430(ra) # 80003dc8 <nameiparent>
    8000583a:	84aa                	mv	s1,a0
    8000583c:	cd61                	beqz	a0,80005914 <sys_unlink+0x118>
  ilock(dp);
    8000583e:	ffffe097          	auipc	ra,0xffffe
    80005842:	de2080e7          	jalr	-542(ra) # 80003620 <ilock>
  if (namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005846:	00003597          	auipc	a1,0x3
    8000584a:	fb258593          	addi	a1,a1,-78 # 800087f8 <userret+0x768>
    8000584e:	fb040513          	addi	a0,s0,-80
    80005852:	ffffe097          	auipc	ra,0xffffe
    80005856:	26c080e7          	jalr	620(ra) # 80003abe <namecmp>
    8000585a:	14050c63          	beqz	a0,800059b2 <sys_unlink+0x1b6>
    8000585e:	00003597          	auipc	a1,0x3
    80005862:	fa258593          	addi	a1,a1,-94 # 80008800 <userret+0x770>
    80005866:	fb040513          	addi	a0,s0,-80
    8000586a:	ffffe097          	auipc	ra,0xffffe
    8000586e:	254080e7          	jalr	596(ra) # 80003abe <namecmp>
    80005872:	14050063          	beqz	a0,800059b2 <sys_unlink+0x1b6>
  if ((ip = dirlookup(dp, name, &off)) == 0)
    80005876:	f2c40613          	addi	a2,s0,-212
    8000587a:	fb040593          	addi	a1,s0,-80
    8000587e:	8526                	mv	a0,s1
    80005880:	ffffe097          	auipc	ra,0xffffe
    80005884:	258080e7          	jalr	600(ra) # 80003ad8 <dirlookup>
    80005888:	892a                	mv	s2,a0
    8000588a:	12050463          	beqz	a0,800059b2 <sys_unlink+0x1b6>
  ilock(ip);
    8000588e:	ffffe097          	auipc	ra,0xffffe
    80005892:	d92080e7          	jalr	-622(ra) # 80003620 <ilock>
  if (ip->nlink < 1)
    80005896:	04a91783          	lh	a5,74(s2)
    8000589a:	08f05463          	blez	a5,80005922 <sys_unlink+0x126>
  if (ip->type == T_DIR && !isdirempty(ip))
    8000589e:	04491703          	lh	a4,68(s2)
    800058a2:	4785                	li	a5,1
    800058a4:	08f70763          	beq	a4,a5,80005932 <sys_unlink+0x136>
  memset(&de, 0, sizeof(de));
    800058a8:	4641                	li	a2,16
    800058aa:	4581                	li	a1,0
    800058ac:	fc040513          	addi	a0,s0,-64
    800058b0:	ffffb097          	auipc	ra,0xffffb
    800058b4:	2d2080e7          	jalr	722(ra) # 80000b82 <memset>
  if (writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058b8:	4741                	li	a4,16
    800058ba:	f2c42683          	lw	a3,-212(s0)
    800058be:	fc040613          	addi	a2,s0,-64
    800058c2:	4581                	li	a1,0
    800058c4:	8526                	mv	a0,s1
    800058c6:	ffffe097          	auipc	ra,0xffffe
    800058ca:	0de080e7          	jalr	222(ra) # 800039a4 <writei>
    800058ce:	47c1                	li	a5,16
    800058d0:	0af51763          	bne	a0,a5,8000597e <sys_unlink+0x182>
  if (ip->type == T_DIR)
    800058d4:	04491703          	lh	a4,68(s2)
    800058d8:	4785                	li	a5,1
    800058da:	0af70a63          	beq	a4,a5,8000598e <sys_unlink+0x192>
  iunlockput(dp);
    800058de:	8526                	mv	a0,s1
    800058e0:	ffffe097          	auipc	ra,0xffffe
    800058e4:	f7e080e7          	jalr	-130(ra) # 8000385e <iunlockput>
  ip->nlink--;
    800058e8:	04a95783          	lhu	a5,74(s2)
    800058ec:	37fd                	addiw	a5,a5,-1
    800058ee:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800058f2:	854a                	mv	a0,s2
    800058f4:	ffffe097          	auipc	ra,0xffffe
    800058f8:	c62080e7          	jalr	-926(ra) # 80003556 <iupdate>
  iunlockput(ip);
    800058fc:	854a                	mv	a0,s2
    800058fe:	ffffe097          	auipc	ra,0xffffe
    80005902:	f60080e7          	jalr	-160(ra) # 8000385e <iunlockput>
  end_op(ROOTDEV);
    80005906:	4501                	li	a0,0
    80005908:	fffff097          	auipc	ra,0xfffff
    8000590c:	86a080e7          	jalr	-1942(ra) # 80004172 <end_op>
  return 0;
    80005910:	4501                	li	a0,0
    80005912:	a85d                	j	800059c8 <sys_unlink+0x1cc>
    end_op(ROOTDEV);
    80005914:	4501                	li	a0,0
    80005916:	fffff097          	auipc	ra,0xfffff
    8000591a:	85c080e7          	jalr	-1956(ra) # 80004172 <end_op>
    return -1;
    8000591e:	557d                	li	a0,-1
    80005920:	a065                	j	800059c8 <sys_unlink+0x1cc>
    panic("unlink: nlink < 1");
    80005922:	00003517          	auipc	a0,0x3
    80005926:	f0650513          	addi	a0,a0,-250 # 80008828 <userret+0x798>
    8000592a:	ffffb097          	auipc	ra,0xffffb
    8000592e:	c1e080e7          	jalr	-994(ra) # 80000548 <panic>
  for (off = 2 * sizeof(de); off < dp->size; off += sizeof(de))
    80005932:	04c92703          	lw	a4,76(s2)
    80005936:	02000793          	li	a5,32
    8000593a:	f6e7f7e3          	bgeu	a5,a4,800058a8 <sys_unlink+0xac>
    8000593e:	02000993          	li	s3,32
    if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005942:	4741                	li	a4,16
    80005944:	86ce                	mv	a3,s3
    80005946:	f1840613          	addi	a2,s0,-232
    8000594a:	4581                	li	a1,0
    8000594c:	854a                	mv	a0,s2
    8000594e:	ffffe097          	auipc	ra,0xffffe
    80005952:	f62080e7          	jalr	-158(ra) # 800038b0 <readi>
    80005956:	47c1                	li	a5,16
    80005958:	00f51b63          	bne	a0,a5,8000596e <sys_unlink+0x172>
    if (de.inum != 0)
    8000595c:	f1845783          	lhu	a5,-232(s0)
    80005960:	e7a1                	bnez	a5,800059a8 <sys_unlink+0x1ac>
  for (off = 2 * sizeof(de); off < dp->size; off += sizeof(de))
    80005962:	29c1                	addiw	s3,s3,16
    80005964:	04c92783          	lw	a5,76(s2)
    80005968:	fcf9ede3          	bltu	s3,a5,80005942 <sys_unlink+0x146>
    8000596c:	bf35                	j	800058a8 <sys_unlink+0xac>
      panic("isdirempty: readi");
    8000596e:	00003517          	auipc	a0,0x3
    80005972:	ed250513          	addi	a0,a0,-302 # 80008840 <userret+0x7b0>
    80005976:	ffffb097          	auipc	ra,0xffffb
    8000597a:	bd2080e7          	jalr	-1070(ra) # 80000548 <panic>
    panic("unlink: writei");
    8000597e:	00003517          	auipc	a0,0x3
    80005982:	eda50513          	addi	a0,a0,-294 # 80008858 <userret+0x7c8>
    80005986:	ffffb097          	auipc	ra,0xffffb
    8000598a:	bc2080e7          	jalr	-1086(ra) # 80000548 <panic>
    dp->nlink--;
    8000598e:	04a4d783          	lhu	a5,74(s1)
    80005992:	37fd                	addiw	a5,a5,-1
    80005994:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005998:	8526                	mv	a0,s1
    8000599a:	ffffe097          	auipc	ra,0xffffe
    8000599e:	bbc080e7          	jalr	-1092(ra) # 80003556 <iupdate>
    800059a2:	bf35                	j	800058de <sys_unlink+0xe2>
    return -1;
    800059a4:	557d                	li	a0,-1
    800059a6:	a00d                	j	800059c8 <sys_unlink+0x1cc>
    iunlockput(ip);
    800059a8:	854a                	mv	a0,s2
    800059aa:	ffffe097          	auipc	ra,0xffffe
    800059ae:	eb4080e7          	jalr	-332(ra) # 8000385e <iunlockput>
  iunlockput(dp);
    800059b2:	8526                	mv	a0,s1
    800059b4:	ffffe097          	auipc	ra,0xffffe
    800059b8:	eaa080e7          	jalr	-342(ra) # 8000385e <iunlockput>
  end_op(ROOTDEV);
    800059bc:	4501                	li	a0,0
    800059be:	ffffe097          	auipc	ra,0xffffe
    800059c2:	7b4080e7          	jalr	1972(ra) # 80004172 <end_op>
  return -1;
    800059c6:	557d                	li	a0,-1
}
    800059c8:	70ae                	ld	ra,232(sp)
    800059ca:	740e                	ld	s0,224(sp)
    800059cc:	64ee                	ld	s1,216(sp)
    800059ce:	694e                	ld	s2,208(sp)
    800059d0:	69ae                	ld	s3,200(sp)
    800059d2:	616d                	addi	sp,sp,240
    800059d4:	8082                	ret

00000000800059d6 <sys_open>:

uint64
sys_open(void)
{
    800059d6:	7131                	addi	sp,sp,-192
    800059d8:	fd06                	sd	ra,184(sp)
    800059da:	f922                	sd	s0,176(sp)
    800059dc:	f526                	sd	s1,168(sp)
    800059de:	f14a                	sd	s2,160(sp)
    800059e0:	ed4e                	sd	s3,152(sp)
    800059e2:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if ((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800059e4:	08000613          	li	a2,128
    800059e8:	f5040593          	addi	a1,s0,-176
    800059ec:	4501                	li	a0,0
    800059ee:	ffffd097          	auipc	ra,0xffffd
    800059f2:	0dc080e7          	jalr	220(ra) # 80002aca <argstr>
    return -1;
    800059f6:	54fd                	li	s1,-1
  if ((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800059f8:	0a054963          	bltz	a0,80005aaa <sys_open+0xd4>
    800059fc:	f4c40593          	addi	a1,s0,-180
    80005a00:	4505                	li	a0,1
    80005a02:	ffffd097          	auipc	ra,0xffffd
    80005a06:	084080e7          	jalr	132(ra) # 80002a86 <argint>
    80005a0a:	0a054063          	bltz	a0,80005aaa <sys_open+0xd4>

  begin_op(ROOTDEV);
    80005a0e:	4501                	li	a0,0
    80005a10:	ffffe097          	auipc	ra,0xffffe
    80005a14:	6b8080e7          	jalr	1720(ra) # 800040c8 <begin_op>

  if (omode & O_CREATE)
    80005a18:	f4c42783          	lw	a5,-180(s0)
    80005a1c:	2007f793          	andi	a5,a5,512
    80005a20:	c3dd                	beqz	a5,80005ac6 <sys_open+0xf0>
  {
    ip = create(path, T_FILE, 0, 0);
    80005a22:	4681                	li	a3,0
    80005a24:	4601                	li	a2,0
    80005a26:	4589                	li	a1,2
    80005a28:	f5040513          	addi	a0,s0,-176
    80005a2c:	fffff097          	auipc	ra,0xfffff
    80005a30:	7b0080e7          	jalr	1968(ra) # 800051dc <create>
    80005a34:	892a                	mv	s2,a0
    if (ip == 0)
    80005a36:	c151                	beqz	a0,80005aba <sys_open+0xe4>
      end_op(ROOTDEV);
      return -1;
    }
  }

  if (ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV))
    80005a38:	04491703          	lh	a4,68(s2)
    80005a3c:	478d                	li	a5,3
    80005a3e:	00f71763          	bne	a4,a5,80005a4c <sys_open+0x76>
    80005a42:	04695703          	lhu	a4,70(s2)
    80005a46:	47a5                	li	a5,9
    80005a48:	0ce7e663          	bltu	a5,a4,80005b14 <sys_open+0x13e>
    iunlockput(ip);
    end_op(ROOTDEV);
    return -1;
  }

  if ((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0)
    80005a4c:	fffff097          	auipc	ra,0xfffff
    80005a50:	be8080e7          	jalr	-1048(ra) # 80004634 <filealloc>
    80005a54:	89aa                	mv	s3,a0
    80005a56:	c97d                	beqz	a0,80005b4c <sys_open+0x176>
    80005a58:	fffff097          	auipc	ra,0xfffff
    80005a5c:	6da080e7          	jalr	1754(ra) # 80005132 <fdalloc>
    80005a60:	84aa                	mv	s1,a0
    80005a62:	0e054063          	bltz	a0,80005b42 <sys_open+0x16c>
    iunlockput(ip);
    end_op(ROOTDEV);
    return -1;
  }

  if (ip->type == T_DEVICE)
    80005a66:	04491703          	lh	a4,68(s2)
    80005a6a:	478d                	li	a5,3
    80005a6c:	0cf70063          	beq	a4,a5,80005b2c <sys_open+0x156>
    f->major = ip->major;
    f->minor = ip->minor;
  }
  else
  {
    f->type = FD_INODE;
    80005a70:	4789                	li	a5,2
    80005a72:	00f9a023          	sw	a5,0(s3) # 1000 <_entry-0x7ffff000>
  }
  f->ip = ip;
    80005a76:	0129bc23          	sd	s2,24(s3)
  f->off = 0;
    80005a7a:	0209a023          	sw	zero,32(s3)
  f->readable = !(omode & O_WRONLY);
    80005a7e:	f4c42783          	lw	a5,-180(s0)
    80005a82:	0017c713          	xori	a4,a5,1
    80005a86:	8b05                	andi	a4,a4,1
    80005a88:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005a8c:	8b8d                	andi	a5,a5,3
    80005a8e:	00f037b3          	snez	a5,a5
    80005a92:	00f984a3          	sb	a5,9(s3)

  iunlock(ip);
    80005a96:	854a                	mv	a0,s2
    80005a98:	ffffe097          	auipc	ra,0xffffe
    80005a9c:	c4a080e7          	jalr	-950(ra) # 800036e2 <iunlock>
  end_op(ROOTDEV);
    80005aa0:	4501                	li	a0,0
    80005aa2:	ffffe097          	auipc	ra,0xffffe
    80005aa6:	6d0080e7          	jalr	1744(ra) # 80004172 <end_op>

  return fd;
}
    80005aaa:	8526                	mv	a0,s1
    80005aac:	70ea                	ld	ra,184(sp)
    80005aae:	744a                	ld	s0,176(sp)
    80005ab0:	74aa                	ld	s1,168(sp)
    80005ab2:	790a                	ld	s2,160(sp)
    80005ab4:	69ea                	ld	s3,152(sp)
    80005ab6:	6129                	addi	sp,sp,192
    80005ab8:	8082                	ret
      end_op(ROOTDEV);
    80005aba:	4501                	li	a0,0
    80005abc:	ffffe097          	auipc	ra,0xffffe
    80005ac0:	6b6080e7          	jalr	1718(ra) # 80004172 <end_op>
      return -1;
    80005ac4:	b7dd                	j	80005aaa <sys_open+0xd4>
    if ((ip = namei(path)) == 0)
    80005ac6:	f5040513          	addi	a0,s0,-176
    80005aca:	ffffe097          	auipc	ra,0xffffe
    80005ace:	2e0080e7          	jalr	736(ra) # 80003daa <namei>
    80005ad2:	892a                	mv	s2,a0
    80005ad4:	c90d                	beqz	a0,80005b06 <sys_open+0x130>
    ilock(ip);
    80005ad6:	ffffe097          	auipc	ra,0xffffe
    80005ada:	b4a080e7          	jalr	-1206(ra) # 80003620 <ilock>
    if (ip->type == T_DIR && omode != O_RDONLY)
    80005ade:	04491703          	lh	a4,68(s2)
    80005ae2:	4785                	li	a5,1
    80005ae4:	f4f71ae3          	bne	a4,a5,80005a38 <sys_open+0x62>
    80005ae8:	f4c42783          	lw	a5,-180(s0)
    80005aec:	d3a5                	beqz	a5,80005a4c <sys_open+0x76>
      iunlockput(ip);
    80005aee:	854a                	mv	a0,s2
    80005af0:	ffffe097          	auipc	ra,0xffffe
    80005af4:	d6e080e7          	jalr	-658(ra) # 8000385e <iunlockput>
      end_op(ROOTDEV);
    80005af8:	4501                	li	a0,0
    80005afa:	ffffe097          	auipc	ra,0xffffe
    80005afe:	678080e7          	jalr	1656(ra) # 80004172 <end_op>
      return -1;
    80005b02:	54fd                	li	s1,-1
    80005b04:	b75d                	j	80005aaa <sys_open+0xd4>
      end_op(ROOTDEV);
    80005b06:	4501                	li	a0,0
    80005b08:	ffffe097          	auipc	ra,0xffffe
    80005b0c:	66a080e7          	jalr	1642(ra) # 80004172 <end_op>
      return -1;
    80005b10:	54fd                	li	s1,-1
    80005b12:	bf61                	j	80005aaa <sys_open+0xd4>
    iunlockput(ip);
    80005b14:	854a                	mv	a0,s2
    80005b16:	ffffe097          	auipc	ra,0xffffe
    80005b1a:	d48080e7          	jalr	-696(ra) # 8000385e <iunlockput>
    end_op(ROOTDEV);
    80005b1e:	4501                	li	a0,0
    80005b20:	ffffe097          	auipc	ra,0xffffe
    80005b24:	652080e7          	jalr	1618(ra) # 80004172 <end_op>
    return -1;
    80005b28:	54fd                	li	s1,-1
    80005b2a:	b741                	j	80005aaa <sys_open+0xd4>
    f->type = FD_DEVICE;
    80005b2c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005b30:	04691783          	lh	a5,70(s2)
    80005b34:	02f99223          	sh	a5,36(s3)
    f->minor = ip->minor;
    80005b38:	04891783          	lh	a5,72(s2)
    80005b3c:	02f99323          	sh	a5,38(s3)
    80005b40:	bf1d                	j	80005a76 <sys_open+0xa0>
      fileclose(f);
    80005b42:	854e                	mv	a0,s3
    80005b44:	fffff097          	auipc	ra,0xfffff
    80005b48:	bac080e7          	jalr	-1108(ra) # 800046f0 <fileclose>
    iunlockput(ip);
    80005b4c:	854a                	mv	a0,s2
    80005b4e:	ffffe097          	auipc	ra,0xffffe
    80005b52:	d10080e7          	jalr	-752(ra) # 8000385e <iunlockput>
    end_op(ROOTDEV);
    80005b56:	4501                	li	a0,0
    80005b58:	ffffe097          	auipc	ra,0xffffe
    80005b5c:	61a080e7          	jalr	1562(ra) # 80004172 <end_op>
    return -1;
    80005b60:	54fd                	li	s1,-1
    80005b62:	b7a1                	j	80005aaa <sys_open+0xd4>

0000000080005b64 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005b64:	7175                	addi	sp,sp,-144
    80005b66:	e506                	sd	ra,136(sp)
    80005b68:	e122                	sd	s0,128(sp)
    80005b6a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op(ROOTDEV);
    80005b6c:	4501                	li	a0,0
    80005b6e:	ffffe097          	auipc	ra,0xffffe
    80005b72:	55a080e7          	jalr	1370(ra) # 800040c8 <begin_op>
  if (argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0)
    80005b76:	08000613          	li	a2,128
    80005b7a:	f7040593          	addi	a1,s0,-144
    80005b7e:	4501                	li	a0,0
    80005b80:	ffffd097          	auipc	ra,0xffffd
    80005b84:	f4a080e7          	jalr	-182(ra) # 80002aca <argstr>
    80005b88:	02054a63          	bltz	a0,80005bbc <sys_mkdir+0x58>
    80005b8c:	4681                	li	a3,0
    80005b8e:	4601                	li	a2,0
    80005b90:	4585                	li	a1,1
    80005b92:	f7040513          	addi	a0,s0,-144
    80005b96:	fffff097          	auipc	ra,0xfffff
    80005b9a:	646080e7          	jalr	1606(ra) # 800051dc <create>
    80005b9e:	cd19                	beqz	a0,80005bbc <sys_mkdir+0x58>
  {
    end_op(ROOTDEV);
    return -1;
  }
  iunlockput(ip);
    80005ba0:	ffffe097          	auipc	ra,0xffffe
    80005ba4:	cbe080e7          	jalr	-834(ra) # 8000385e <iunlockput>
  end_op(ROOTDEV);
    80005ba8:	4501                	li	a0,0
    80005baa:	ffffe097          	auipc	ra,0xffffe
    80005bae:	5c8080e7          	jalr	1480(ra) # 80004172 <end_op>
  return 0;
    80005bb2:	4501                	li	a0,0
}
    80005bb4:	60aa                	ld	ra,136(sp)
    80005bb6:	640a                	ld	s0,128(sp)
    80005bb8:	6149                	addi	sp,sp,144
    80005bba:	8082                	ret
    end_op(ROOTDEV);
    80005bbc:	4501                	li	a0,0
    80005bbe:	ffffe097          	auipc	ra,0xffffe
    80005bc2:	5b4080e7          	jalr	1460(ra) # 80004172 <end_op>
    return -1;
    80005bc6:	557d                	li	a0,-1
    80005bc8:	b7f5                	j	80005bb4 <sys_mkdir+0x50>

0000000080005bca <sys_mknod>:

uint64
sys_mknod(void)
{
    80005bca:	7135                	addi	sp,sp,-160
    80005bcc:	ed06                	sd	ra,152(sp)
    80005bce:	e922                	sd	s0,144(sp)
    80005bd0:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op(ROOTDEV);
    80005bd2:	4501                	li	a0,0
    80005bd4:	ffffe097          	auipc	ra,0xffffe
    80005bd8:	4f4080e7          	jalr	1268(ra) # 800040c8 <begin_op>
  if ((argstr(0, path, MAXPATH)) < 0 ||
    80005bdc:	08000613          	li	a2,128
    80005be0:	f7040593          	addi	a1,s0,-144
    80005be4:	4501                	li	a0,0
    80005be6:	ffffd097          	auipc	ra,0xffffd
    80005bea:	ee4080e7          	jalr	-284(ra) # 80002aca <argstr>
    80005bee:	04054b63          	bltz	a0,80005c44 <sys_mknod+0x7a>
      argint(1, &major) < 0 ||
    80005bf2:	f6c40593          	addi	a1,s0,-148
    80005bf6:	4505                	li	a0,1
    80005bf8:	ffffd097          	auipc	ra,0xffffd
    80005bfc:	e8e080e7          	jalr	-370(ra) # 80002a86 <argint>
  if ((argstr(0, path, MAXPATH)) < 0 ||
    80005c00:	04054263          	bltz	a0,80005c44 <sys_mknod+0x7a>
      argint(2, &minor) < 0 ||
    80005c04:	f6840593          	addi	a1,s0,-152
    80005c08:	4509                	li	a0,2
    80005c0a:	ffffd097          	auipc	ra,0xffffd
    80005c0e:	e7c080e7          	jalr	-388(ra) # 80002a86 <argint>
      argint(1, &major) < 0 ||
    80005c12:	02054963          	bltz	a0,80005c44 <sys_mknod+0x7a>
      (ip = create(path, T_DEVICE, major, minor)) == 0)
    80005c16:	f6841683          	lh	a3,-152(s0)
    80005c1a:	f6c41603          	lh	a2,-148(s0)
    80005c1e:	458d                	li	a1,3
    80005c20:	f7040513          	addi	a0,s0,-144
    80005c24:	fffff097          	auipc	ra,0xfffff
    80005c28:	5b8080e7          	jalr	1464(ra) # 800051dc <create>
      argint(2, &minor) < 0 ||
    80005c2c:	cd01                	beqz	a0,80005c44 <sys_mknod+0x7a>
  {
    end_op(ROOTDEV);
    return -1;
  }
  iunlockput(ip);
    80005c2e:	ffffe097          	auipc	ra,0xffffe
    80005c32:	c30080e7          	jalr	-976(ra) # 8000385e <iunlockput>
  end_op(ROOTDEV);
    80005c36:	4501                	li	a0,0
    80005c38:	ffffe097          	auipc	ra,0xffffe
    80005c3c:	53a080e7          	jalr	1338(ra) # 80004172 <end_op>
  return 0;
    80005c40:	4501                	li	a0,0
    80005c42:	a039                	j	80005c50 <sys_mknod+0x86>
    end_op(ROOTDEV);
    80005c44:	4501                	li	a0,0
    80005c46:	ffffe097          	auipc	ra,0xffffe
    80005c4a:	52c080e7          	jalr	1324(ra) # 80004172 <end_op>
    return -1;
    80005c4e:	557d                	li	a0,-1
}
    80005c50:	60ea                	ld	ra,152(sp)
    80005c52:	644a                	ld	s0,144(sp)
    80005c54:	610d                	addi	sp,sp,160
    80005c56:	8082                	ret

0000000080005c58 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005c58:	7135                	addi	sp,sp,-160
    80005c5a:	ed06                	sd	ra,152(sp)
    80005c5c:	e922                	sd	s0,144(sp)
    80005c5e:	e526                	sd	s1,136(sp)
    80005c60:	e14a                	sd	s2,128(sp)
    80005c62:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c64:	ffffc097          	auipc	ra,0xffffc
    80005c68:	ca6080e7          	jalr	-858(ra) # 8000190a <myproc>
    80005c6c:	892a                	mv	s2,a0

  begin_op(ROOTDEV);
    80005c6e:	4501                	li	a0,0
    80005c70:	ffffe097          	auipc	ra,0xffffe
    80005c74:	458080e7          	jalr	1112(ra) # 800040c8 <begin_op>
  if (argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0)
    80005c78:	08000613          	li	a2,128
    80005c7c:	f6040593          	addi	a1,s0,-160
    80005c80:	4501                	li	a0,0
    80005c82:	ffffd097          	auipc	ra,0xffffd
    80005c86:	e48080e7          	jalr	-440(ra) # 80002aca <argstr>
    80005c8a:	04054c63          	bltz	a0,80005ce2 <sys_chdir+0x8a>
    80005c8e:	f6040513          	addi	a0,s0,-160
    80005c92:	ffffe097          	auipc	ra,0xffffe
    80005c96:	118080e7          	jalr	280(ra) # 80003daa <namei>
    80005c9a:	84aa                	mv	s1,a0
    80005c9c:	c139                	beqz	a0,80005ce2 <sys_chdir+0x8a>
  {
    end_op(ROOTDEV);
    return -1;
  }
  ilock(ip);
    80005c9e:	ffffe097          	auipc	ra,0xffffe
    80005ca2:	982080e7          	jalr	-1662(ra) # 80003620 <ilock>
  if (ip->type != T_DIR)
    80005ca6:	04449703          	lh	a4,68(s1)
    80005caa:	4785                	li	a5,1
    80005cac:	04f71263          	bne	a4,a5,80005cf0 <sys_chdir+0x98>
  {
    iunlockput(ip);
    end_op(ROOTDEV);
    return -1;
  }
  iunlock(ip);
    80005cb0:	8526                	mv	a0,s1
    80005cb2:	ffffe097          	auipc	ra,0xffffe
    80005cb6:	a30080e7          	jalr	-1488(ra) # 800036e2 <iunlock>
  iput(p->cwd);
    80005cba:	15893503          	ld	a0,344(s2)
    80005cbe:	ffffe097          	auipc	ra,0xffffe
    80005cc2:	a70080e7          	jalr	-1424(ra) # 8000372e <iput>
  end_op(ROOTDEV);
    80005cc6:	4501                	li	a0,0
    80005cc8:	ffffe097          	auipc	ra,0xffffe
    80005ccc:	4aa080e7          	jalr	1194(ra) # 80004172 <end_op>
  p->cwd = ip;
    80005cd0:	14993c23          	sd	s1,344(s2)
  return 0;
    80005cd4:	4501                	li	a0,0
}
    80005cd6:	60ea                	ld	ra,152(sp)
    80005cd8:	644a                	ld	s0,144(sp)
    80005cda:	64aa                	ld	s1,136(sp)
    80005cdc:	690a                	ld	s2,128(sp)
    80005cde:	610d                	addi	sp,sp,160
    80005ce0:	8082                	ret
    end_op(ROOTDEV);
    80005ce2:	4501                	li	a0,0
    80005ce4:	ffffe097          	auipc	ra,0xffffe
    80005ce8:	48e080e7          	jalr	1166(ra) # 80004172 <end_op>
    return -1;
    80005cec:	557d                	li	a0,-1
    80005cee:	b7e5                	j	80005cd6 <sys_chdir+0x7e>
    iunlockput(ip);
    80005cf0:	8526                	mv	a0,s1
    80005cf2:	ffffe097          	auipc	ra,0xffffe
    80005cf6:	b6c080e7          	jalr	-1172(ra) # 8000385e <iunlockput>
    end_op(ROOTDEV);
    80005cfa:	4501                	li	a0,0
    80005cfc:	ffffe097          	auipc	ra,0xffffe
    80005d00:	476080e7          	jalr	1142(ra) # 80004172 <end_op>
    return -1;
    80005d04:	557d                	li	a0,-1
    80005d06:	bfc1                	j	80005cd6 <sys_chdir+0x7e>

0000000080005d08 <sys_exec>:

uint64
sys_exec(void)
{
    80005d08:	7145                	addi	sp,sp,-464
    80005d0a:	e786                	sd	ra,456(sp)
    80005d0c:	e3a2                	sd	s0,448(sp)
    80005d0e:	ff26                	sd	s1,440(sp)
    80005d10:	fb4a                	sd	s2,432(sp)
    80005d12:	f74e                	sd	s3,424(sp)
    80005d14:	f352                	sd	s4,416(sp)
    80005d16:	ef56                	sd	s5,408(sp)
    80005d18:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if (argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0)
    80005d1a:	08000613          	li	a2,128
    80005d1e:	f4040593          	addi	a1,s0,-192
    80005d22:	4501                	li	a0,0
    80005d24:	ffffd097          	auipc	ra,0xffffd
    80005d28:	da6080e7          	jalr	-602(ra) # 80002aca <argstr>
    80005d2c:	0e054663          	bltz	a0,80005e18 <sys_exec+0x110>
    80005d30:	e3840593          	addi	a1,s0,-456
    80005d34:	4505                	li	a0,1
    80005d36:	ffffd097          	auipc	ra,0xffffd
    80005d3a:	d72080e7          	jalr	-654(ra) # 80002aa8 <argaddr>
    80005d3e:	0e054763          	bltz	a0,80005e2c <sys_exec+0x124>
  {
    return -1;
  }
  memset(argv, 0, sizeof(argv));
    80005d42:	10000613          	li	a2,256
    80005d46:	4581                	li	a1,0
    80005d48:	e4040513          	addi	a0,s0,-448
    80005d4c:	ffffb097          	auipc	ra,0xffffb
    80005d50:	e36080e7          	jalr	-458(ra) # 80000b82 <memset>
  for (i = 0;; i++)
  {
    if (i >= NELEM(argv))
    80005d54:	e4040913          	addi	s2,s0,-448
  memset(argv, 0, sizeof(argv));
    80005d58:	89ca                	mv	s3,s2
    80005d5a:	4481                	li	s1,0
    if (i >= NELEM(argv))
    80005d5c:	02000a13          	li	s4,32
    80005d60:	00048a9b          	sext.w	s5,s1
    {
      goto bad;
    }
    if (fetchaddr(uargv + sizeof(uint64) * i, (uint64 *)&uarg) < 0)
    80005d64:	00349793          	slli	a5,s1,0x3
    80005d68:	e3040593          	addi	a1,s0,-464
    80005d6c:	e3843503          	ld	a0,-456(s0)
    80005d70:	953e                	add	a0,a0,a5
    80005d72:	ffffd097          	auipc	ra,0xffffd
    80005d76:	c7a080e7          	jalr	-902(ra) # 800029ec <fetchaddr>
    80005d7a:	02054a63          	bltz	a0,80005dae <sys_exec+0xa6>
    {
      goto bad;
    }
    if (uarg == 0)
    80005d7e:	e3043783          	ld	a5,-464(s0)
    80005d82:	c7a1                	beqz	a5,80005dca <sys_exec+0xc2>
    {
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005d84:	ffffb097          	auipc	ra,0xffffb
    80005d88:	bcc080e7          	jalr	-1076(ra) # 80000950 <kalloc>
    80005d8c:	85aa                	mv	a1,a0
    80005d8e:	00a9b023          	sd	a0,0(s3)
    if (argv[i] == 0)
    80005d92:	c92d                	beqz	a0,80005e04 <sys_exec+0xfc>
      panic("sys_exec kalloc");
    if (fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005d94:	6605                	lui	a2,0x1
    80005d96:	e3043503          	ld	a0,-464(s0)
    80005d9a:	ffffd097          	auipc	ra,0xffffd
    80005d9e:	ca4080e7          	jalr	-860(ra) # 80002a3e <fetchstr>
    80005da2:	00054663          	bltz	a0,80005dae <sys_exec+0xa6>
    if (i >= NELEM(argv))
    80005da6:	0485                	addi	s1,s1,1
    80005da8:	09a1                	addi	s3,s3,8
    80005daa:	fb449be3          	bne	s1,s4,80005d60 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

bad:
  for (i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dae:	10090493          	addi	s1,s2,256
    80005db2:	00093503          	ld	a0,0(s2)
    80005db6:	cd39                	beqz	a0,80005e14 <sys_exec+0x10c>
    kfree(argv[i]);
    80005db8:	ffffb097          	auipc	ra,0xffffb
    80005dbc:	a9c080e7          	jalr	-1380(ra) # 80000854 <kfree>
  for (i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dc0:	0921                	addi	s2,s2,8
    80005dc2:	fe9918e3          	bne	s2,s1,80005db2 <sys_exec+0xaa>
  return -1;
    80005dc6:	557d                	li	a0,-1
    80005dc8:	a889                	j	80005e1a <sys_exec+0x112>
      argv[i] = 0;
    80005dca:	0a8e                	slli	s5,s5,0x3
    80005dcc:	fc040793          	addi	a5,s0,-64
    80005dd0:	9abe                	add	s5,s5,a5
    80005dd2:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005dd6:	e4040593          	addi	a1,s0,-448
    80005dda:	f4040513          	addi	a0,s0,-192
    80005dde:	fffff097          	auipc	ra,0xfffff
    80005de2:	fba080e7          	jalr	-70(ra) # 80004d98 <exec>
    80005de6:	84aa                	mv	s1,a0
  for (i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005de8:	10090993          	addi	s3,s2,256
    80005dec:	00093503          	ld	a0,0(s2)
    80005df0:	c901                	beqz	a0,80005e00 <sys_exec+0xf8>
    kfree(argv[i]);
    80005df2:	ffffb097          	auipc	ra,0xffffb
    80005df6:	a62080e7          	jalr	-1438(ra) # 80000854 <kfree>
  for (i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dfa:	0921                	addi	s2,s2,8
    80005dfc:	ff3918e3          	bne	s2,s3,80005dec <sys_exec+0xe4>
  return ret;
    80005e00:	8526                	mv	a0,s1
    80005e02:	a821                	j	80005e1a <sys_exec+0x112>
      panic("sys_exec kalloc");
    80005e04:	00003517          	auipc	a0,0x3
    80005e08:	a6450513          	addi	a0,a0,-1436 # 80008868 <userret+0x7d8>
    80005e0c:	ffffa097          	auipc	ra,0xffffa
    80005e10:	73c080e7          	jalr	1852(ra) # 80000548 <panic>
  return -1;
    80005e14:	557d                	li	a0,-1
    80005e16:	a011                	j	80005e1a <sys_exec+0x112>
    return -1;
    80005e18:	557d                	li	a0,-1
}
    80005e1a:	60be                	ld	ra,456(sp)
    80005e1c:	641e                	ld	s0,448(sp)
    80005e1e:	74fa                	ld	s1,440(sp)
    80005e20:	795a                	ld	s2,432(sp)
    80005e22:	79ba                	ld	s3,424(sp)
    80005e24:	7a1a                	ld	s4,416(sp)
    80005e26:	6afa                	ld	s5,408(sp)
    80005e28:	6179                	addi	sp,sp,464
    80005e2a:	8082                	ret
    return -1;
    80005e2c:	557d                	li	a0,-1
    80005e2e:	b7f5                	j	80005e1a <sys_exec+0x112>

0000000080005e30 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005e30:	715d                	addi	sp,sp,-80
    80005e32:	e486                	sd	ra,72(sp)
    80005e34:	e0a2                	sd	s0,64(sp)
    80005e36:	fc26                	sd	s1,56(sp)
    80005e38:	f84a                	sd	s2,48(sp)
    80005e3a:	f44e                	sd	s3,40(sp)
    80005e3c:	f052                	sd	s4,32(sp)
    80005e3e:	0880                	addi	s0,sp,80
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005e40:	ffffc097          	auipc	ra,0xffffc
    80005e44:	aca080e7          	jalr	-1334(ra) # 8000190a <myproc>
    80005e48:	892a                	mv	s2,a0

  if (argaddr(0, &fdarray) < 0)
    80005e4a:	fc840593          	addi	a1,s0,-56
    80005e4e:	4501                	li	a0,0
    80005e50:	ffffd097          	auipc	ra,0xffffd
    80005e54:	c58080e7          	jalr	-936(ra) # 80002aa8 <argaddr>
    return -1;
    80005e58:	57fd                	li	a5,-1
  if (argaddr(0, &fdarray) < 0)
    80005e5a:	10054f63          	bltz	a0,80005f78 <sys_pipe+0x148>
  if (pipealloc(&rf, &wf) < 0)
    80005e5e:	fb840593          	addi	a1,s0,-72
    80005e62:	fc040513          	addi	a0,s0,-64
    80005e66:	fffff097          	auipc	ra,0xfffff
    80005e6a:	bee080e7          	jalr	-1042(ra) # 80004a54 <pipealloc>
    return -1;
    80005e6e:	57fd                	li	a5,-1
  if (pipealloc(&rf, &wf) < 0)
    80005e70:	10054463          	bltz	a0,80005f78 <sys_pipe+0x148>
  fd0 = -1;
    80005e74:	faf42a23          	sw	a5,-76(s0)
  if ((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0)
    80005e78:	fc043503          	ld	a0,-64(s0)
    80005e7c:	fffff097          	auipc	ra,0xfffff
    80005e80:	2b6080e7          	jalr	694(ra) # 80005132 <fdalloc>
    80005e84:	faa42a23          	sw	a0,-76(s0)
    80005e88:	0c054b63          	bltz	a0,80005f5e <sys_pipe+0x12e>
    80005e8c:	fb843503          	ld	a0,-72(s0)
    80005e90:	fffff097          	auipc	ra,0xfffff
    80005e94:	2a2080e7          	jalr	674(ra) # 80005132 <fdalloc>
    80005e98:	faa42823          	sw	a0,-80(s0)
    80005e9c:	0a054863          	bltz	a0,80005f4c <sys_pipe+0x11c>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  uint64 i = fdarray; //管道描述符数组也要lazy分配真实空间
    80005ea0:	fc843483          	ld	s1,-56(s0)
  while (i < fdarray + 2 * sizeof(int) - 1)
    80005ea4:	00748513          	addi	a0,s1,7
    80005ea8:	02a4f263          	bgeu	s1,a0,80005ecc <sys_pipe+0x9c>
  {
    if (sys_lazyalloc(i) == -1)
    80005eac:	59fd                	li	s3,-1
      return -1;
    i = i + PGSIZE;
    80005eae:	6a05                	lui	s4,0x1
    if (sys_lazyalloc(i) == -1)
    80005eb0:	8526                	mv	a0,s1
    80005eb2:	fffff097          	auipc	ra,0xfffff
    80005eb6:	490080e7          	jalr	1168(ra) # 80005342 <sys_lazyalloc>
    80005eba:	87aa                	mv	a5,a0
    80005ebc:	0b350e63          	beq	a0,s3,80005f78 <sys_pipe+0x148>
    i = i + PGSIZE;
    80005ec0:	94d2                	add	s1,s1,s4
  while (i < fdarray + 2 * sizeof(int) - 1)
    80005ec2:	fc843503          	ld	a0,-56(s0)
    80005ec6:	051d                	addi	a0,a0,7
    80005ec8:	fea4e4e3          	bltu	s1,a0,80005eb0 <sys_pipe+0x80>
  }
  //分配最后一段小空间，不是PGSIZE的整数倍
  if (sys_lazyalloc(fdarray + 2 * sizeof(int) - 1) == -1)
    80005ecc:	fffff097          	auipc	ra,0xfffff
    80005ed0:	476080e7          	jalr	1142(ra) # 80005342 <sys_lazyalloc>
    80005ed4:	87aa                	mv	a5,a0
    80005ed6:	577d                	li	a4,-1
    80005ed8:	0ae50063          	beq	a0,a4,80005f78 <sys_pipe+0x148>
    return -1;
  if (copyout(p->pagetable, fdarray, (char *)&fd0, sizeof(fd0)) < 0 ||
    80005edc:	4691                	li	a3,4
    80005ede:	fb440613          	addi	a2,s0,-76
    80005ee2:	fc843583          	ld	a1,-56(s0)
    80005ee6:	05893503          	ld	a0,88(s2)
    80005eea:	ffffb097          	auipc	ra,0xffffb
    80005eee:	626080e7          	jalr	1574(ra) # 80001510 <copyout>
    80005ef2:	02054163          	bltz	a0,80005f14 <sys_pipe+0xe4>
      copyout(p->pagetable, fdarray + sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0)
    80005ef6:	4691                	li	a3,4
    80005ef8:	fb040613          	addi	a2,s0,-80
    80005efc:	fc843583          	ld	a1,-56(s0)
    80005f00:	0591                	addi	a1,a1,4
    80005f02:	05893503          	ld	a0,88(s2)
    80005f06:	ffffb097          	auipc	ra,0xffffb
    80005f0a:	60a080e7          	jalr	1546(ra) # 80001510 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005f0e:	4781                	li	a5,0
  if (copyout(p->pagetable, fdarray, (char *)&fd0, sizeof(fd0)) < 0 ||
    80005f10:	06055463          	bgez	a0,80005f78 <sys_pipe+0x148>
    p->ofile[fd0] = 0;
    80005f14:	fb442783          	lw	a5,-76(s0)
    80005f18:	07e9                	addi	a5,a5,26
    80005f1a:	078e                	slli	a5,a5,0x3
    80005f1c:	97ca                	add	a5,a5,s2
    80005f1e:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005f22:	fb042783          	lw	a5,-80(s0)
    80005f26:	07e9                	addi	a5,a5,26
    80005f28:	078e                	slli	a5,a5,0x3
    80005f2a:	993e                	add	s2,s2,a5
    80005f2c:	00093423          	sd	zero,8(s2)
    fileclose(rf);
    80005f30:	fc043503          	ld	a0,-64(s0)
    80005f34:	ffffe097          	auipc	ra,0xffffe
    80005f38:	7bc080e7          	jalr	1980(ra) # 800046f0 <fileclose>
    fileclose(wf);
    80005f3c:	fb843503          	ld	a0,-72(s0)
    80005f40:	ffffe097          	auipc	ra,0xffffe
    80005f44:	7b0080e7          	jalr	1968(ra) # 800046f0 <fileclose>
    return -1;
    80005f48:	57fd                	li	a5,-1
    80005f4a:	a03d                	j	80005f78 <sys_pipe+0x148>
    if (fd0 >= 0)
    80005f4c:	fb442783          	lw	a5,-76(s0)
    80005f50:	0007c763          	bltz	a5,80005f5e <sys_pipe+0x12e>
      p->ofile[fd0] = 0;
    80005f54:	07e9                	addi	a5,a5,26
    80005f56:	078e                	slli	a5,a5,0x3
    80005f58:	993e                	add	s2,s2,a5
    80005f5a:	00093423          	sd	zero,8(s2)
    fileclose(rf);
    80005f5e:	fc043503          	ld	a0,-64(s0)
    80005f62:	ffffe097          	auipc	ra,0xffffe
    80005f66:	78e080e7          	jalr	1934(ra) # 800046f0 <fileclose>
    fileclose(wf);
    80005f6a:	fb843503          	ld	a0,-72(s0)
    80005f6e:	ffffe097          	auipc	ra,0xffffe
    80005f72:	782080e7          	jalr	1922(ra) # 800046f0 <fileclose>
    return -1;
    80005f76:	57fd                	li	a5,-1
}
    80005f78:	853e                	mv	a0,a5
    80005f7a:	60a6                	ld	ra,72(sp)
    80005f7c:	6406                	ld	s0,64(sp)
    80005f7e:	74e2                	ld	s1,56(sp)
    80005f80:	7942                	ld	s2,48(sp)
    80005f82:	79a2                	ld	s3,40(sp)
    80005f84:	7a02                	ld	s4,32(sp)
    80005f86:	6161                	addi	sp,sp,80
    80005f88:	8082                	ret

0000000080005f8a <sys_crash>:

// system call to test crashes
uint64
sys_crash(void)
{
    80005f8a:	7171                	addi	sp,sp,-176
    80005f8c:	f506                	sd	ra,168(sp)
    80005f8e:	f122                	sd	s0,160(sp)
    80005f90:	ed26                	sd	s1,152(sp)
    80005f92:	1900                	addi	s0,sp,176
  char path[MAXPATH];
  struct inode *ip;
  int crash;

  if (argstr(0, path, MAXPATH) < 0 || argint(1, &crash) < 0)
    80005f94:	08000613          	li	a2,128
    80005f98:	f6040593          	addi	a1,s0,-160
    80005f9c:	4501                	li	a0,0
    80005f9e:	ffffd097          	auipc	ra,0xffffd
    80005fa2:	b2c080e7          	jalr	-1236(ra) # 80002aca <argstr>
    return -1;
    80005fa6:	57fd                	li	a5,-1
  if (argstr(0, path, MAXPATH) < 0 || argint(1, &crash) < 0)
    80005fa8:	04054363          	bltz	a0,80005fee <sys_crash+0x64>
    80005fac:	f5c40593          	addi	a1,s0,-164
    80005fb0:	4505                	li	a0,1
    80005fb2:	ffffd097          	auipc	ra,0xffffd
    80005fb6:	ad4080e7          	jalr	-1324(ra) # 80002a86 <argint>
    return -1;
    80005fba:	57fd                	li	a5,-1
  if (argstr(0, path, MAXPATH) < 0 || argint(1, &crash) < 0)
    80005fbc:	02054963          	bltz	a0,80005fee <sys_crash+0x64>
  ip = create(path, T_FILE, 0, 0);
    80005fc0:	4681                	li	a3,0
    80005fc2:	4601                	li	a2,0
    80005fc4:	4589                	li	a1,2
    80005fc6:	f6040513          	addi	a0,s0,-160
    80005fca:	fffff097          	auipc	ra,0xfffff
    80005fce:	212080e7          	jalr	530(ra) # 800051dc <create>
    80005fd2:	84aa                	mv	s1,a0
  if (ip == 0)
    80005fd4:	c11d                	beqz	a0,80005ffa <sys_crash+0x70>
  {
    return -1;
  }
  iunlockput(ip);
    80005fd6:	ffffe097          	auipc	ra,0xffffe
    80005fda:	888080e7          	jalr	-1912(ra) # 8000385e <iunlockput>
  crash_op(ip->dev, crash);
    80005fde:	f5c42583          	lw	a1,-164(s0)
    80005fe2:	4088                	lw	a0,0(s1)
    80005fe4:	ffffe097          	auipc	ra,0xffffe
    80005fe8:	3e0080e7          	jalr	992(ra) # 800043c4 <crash_op>
  return 0;
    80005fec:	4781                	li	a5,0
}
    80005fee:	853e                	mv	a0,a5
    80005ff0:	70aa                	ld	ra,168(sp)
    80005ff2:	740a                	ld	s0,160(sp)
    80005ff4:	64ea                	ld	s1,152(sp)
    80005ff6:	614d                	addi	sp,sp,176
    80005ff8:	8082                	ret
    return -1;
    80005ffa:	57fd                	li	a5,-1
    80005ffc:	bfcd                	j	80005fee <sys_crash+0x64>
	...

0000000080006000 <kernelvec>:
    80006000:	7111                	addi	sp,sp,-256
    80006002:	e006                	sd	ra,0(sp)
    80006004:	e40a                	sd	sp,8(sp)
    80006006:	e80e                	sd	gp,16(sp)
    80006008:	ec12                	sd	tp,24(sp)
    8000600a:	f016                	sd	t0,32(sp)
    8000600c:	f41a                	sd	t1,40(sp)
    8000600e:	f81e                	sd	t2,48(sp)
    80006010:	fc22                	sd	s0,56(sp)
    80006012:	e0a6                	sd	s1,64(sp)
    80006014:	e4aa                	sd	a0,72(sp)
    80006016:	e8ae                	sd	a1,80(sp)
    80006018:	ecb2                	sd	a2,88(sp)
    8000601a:	f0b6                	sd	a3,96(sp)
    8000601c:	f4ba                	sd	a4,104(sp)
    8000601e:	f8be                	sd	a5,112(sp)
    80006020:	fcc2                	sd	a6,120(sp)
    80006022:	e146                	sd	a7,128(sp)
    80006024:	e54a                	sd	s2,136(sp)
    80006026:	e94e                	sd	s3,144(sp)
    80006028:	ed52                	sd	s4,152(sp)
    8000602a:	f156                	sd	s5,160(sp)
    8000602c:	f55a                	sd	s6,168(sp)
    8000602e:	f95e                	sd	s7,176(sp)
    80006030:	fd62                	sd	s8,184(sp)
    80006032:	e1e6                	sd	s9,192(sp)
    80006034:	e5ea                	sd	s10,200(sp)
    80006036:	e9ee                	sd	s11,208(sp)
    80006038:	edf2                	sd	t3,216(sp)
    8000603a:	f1f6                	sd	t4,224(sp)
    8000603c:	f5fa                	sd	t5,232(sp)
    8000603e:	f9fe                	sd	t6,240(sp)
    80006040:	879fc0ef          	jal	ra,800028b8 <kerneltrap>
    80006044:	6082                	ld	ra,0(sp)
    80006046:	6122                	ld	sp,8(sp)
    80006048:	61c2                	ld	gp,16(sp)
    8000604a:	7282                	ld	t0,32(sp)
    8000604c:	7322                	ld	t1,40(sp)
    8000604e:	73c2                	ld	t2,48(sp)
    80006050:	7462                	ld	s0,56(sp)
    80006052:	6486                	ld	s1,64(sp)
    80006054:	6526                	ld	a0,72(sp)
    80006056:	65c6                	ld	a1,80(sp)
    80006058:	6666                	ld	a2,88(sp)
    8000605a:	7686                	ld	a3,96(sp)
    8000605c:	7726                	ld	a4,104(sp)
    8000605e:	77c6                	ld	a5,112(sp)
    80006060:	7866                	ld	a6,120(sp)
    80006062:	688a                	ld	a7,128(sp)
    80006064:	692a                	ld	s2,136(sp)
    80006066:	69ca                	ld	s3,144(sp)
    80006068:	6a6a                	ld	s4,152(sp)
    8000606a:	7a8a                	ld	s5,160(sp)
    8000606c:	7b2a                	ld	s6,168(sp)
    8000606e:	7bca                	ld	s7,176(sp)
    80006070:	7c6a                	ld	s8,184(sp)
    80006072:	6c8e                	ld	s9,192(sp)
    80006074:	6d2e                	ld	s10,200(sp)
    80006076:	6dce                	ld	s11,208(sp)
    80006078:	6e6e                	ld	t3,216(sp)
    8000607a:	7e8e                	ld	t4,224(sp)
    8000607c:	7f2e                	ld	t5,232(sp)
    8000607e:	7fce                	ld	t6,240(sp)
    80006080:	6111                	addi	sp,sp,256
    80006082:	10200073          	sret
    80006086:	00000013          	nop
    8000608a:	00000013          	nop
    8000608e:	0001                	nop

0000000080006090 <timervec>:
    80006090:	34051573          	csrrw	a0,mscratch,a0
    80006094:	e10c                	sd	a1,0(a0)
    80006096:	e510                	sd	a2,8(a0)
    80006098:	e914                	sd	a3,16(a0)
    8000609a:	710c                	ld	a1,32(a0)
    8000609c:	7510                	ld	a2,40(a0)
    8000609e:	6194                	ld	a3,0(a1)
    800060a0:	96b2                	add	a3,a3,a2
    800060a2:	e194                	sd	a3,0(a1)
    800060a4:	4589                	li	a1,2
    800060a6:	14459073          	csrw	sip,a1
    800060aa:	6914                	ld	a3,16(a0)
    800060ac:	6510                	ld	a2,8(a0)
    800060ae:	610c                	ld	a1,0(a0)
    800060b0:	34051573          	csrrw	a0,mscratch,a0
    800060b4:	30200073          	mret
	...

00000000800060ba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800060ba:	1141                	addi	sp,sp,-16
    800060bc:	e422                	sd	s0,8(sp)
    800060be:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800060c0:	0c0007b7          	lui	a5,0xc000
    800060c4:	4705                	li	a4,1
    800060c6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800060c8:	c3d8                	sw	a4,4(a5)
}
    800060ca:	6422                	ld	s0,8(sp)
    800060cc:	0141                	addi	sp,sp,16
    800060ce:	8082                	ret

00000000800060d0 <plicinithart>:

void
plicinithart(void)
{
    800060d0:	1141                	addi	sp,sp,-16
    800060d2:	e406                	sd	ra,8(sp)
    800060d4:	e022                	sd	s0,0(sp)
    800060d6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060d8:	ffffc097          	auipc	ra,0xffffc
    800060dc:	806080e7          	jalr	-2042(ra) # 800018de <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800060e0:	0085171b          	slliw	a4,a0,0x8
    800060e4:	0c0027b7          	lui	a5,0xc002
    800060e8:	97ba                	add	a5,a5,a4
    800060ea:	40200713          	li	a4,1026
    800060ee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800060f2:	00d5151b          	slliw	a0,a0,0xd
    800060f6:	0c2017b7          	lui	a5,0xc201
    800060fa:	953e                	add	a0,a0,a5
    800060fc:	00052023          	sw	zero,0(a0)
}
    80006100:	60a2                	ld	ra,8(sp)
    80006102:	6402                	ld	s0,0(sp)
    80006104:	0141                	addi	sp,sp,16
    80006106:	8082                	ret

0000000080006108 <plic_pending>:

// return a bitmap of which IRQs are waiting
// to be served.
uint64
plic_pending(void)
{
    80006108:	1141                	addi	sp,sp,-16
    8000610a:	e422                	sd	s0,8(sp)
    8000610c:	0800                	addi	s0,sp,16
  //mask = *(uint32*)(PLIC + 0x1000);
  //mask |= (uint64)*(uint32*)(PLIC + 0x1004) << 32;
  mask = *(uint64*)PLIC_PENDING;

  return mask;
}
    8000610e:	0c0017b7          	lui	a5,0xc001
    80006112:	6388                	ld	a0,0(a5)
    80006114:	6422                	ld	s0,8(sp)
    80006116:	0141                	addi	sp,sp,16
    80006118:	8082                	ret

000000008000611a <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    8000611a:	1141                	addi	sp,sp,-16
    8000611c:	e406                	sd	ra,8(sp)
    8000611e:	e022                	sd	s0,0(sp)
    80006120:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006122:	ffffb097          	auipc	ra,0xffffb
    80006126:	7bc080e7          	jalr	1980(ra) # 800018de <cpuid>
  //int irq = *(uint32*)(PLIC + 0x201004);
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    8000612a:	00d5179b          	slliw	a5,a0,0xd
    8000612e:	0c201537          	lui	a0,0xc201
    80006132:	953e                	add	a0,a0,a5
  return irq;
}
    80006134:	4148                	lw	a0,4(a0)
    80006136:	60a2                	ld	ra,8(sp)
    80006138:	6402                	ld	s0,0(sp)
    8000613a:	0141                	addi	sp,sp,16
    8000613c:	8082                	ret

000000008000613e <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000613e:	1101                	addi	sp,sp,-32
    80006140:	ec06                	sd	ra,24(sp)
    80006142:	e822                	sd	s0,16(sp)
    80006144:	e426                	sd	s1,8(sp)
    80006146:	1000                	addi	s0,sp,32
    80006148:	84aa                	mv	s1,a0
  int hart = cpuid();
    8000614a:	ffffb097          	auipc	ra,0xffffb
    8000614e:	794080e7          	jalr	1940(ra) # 800018de <cpuid>
  //*(uint32*)(PLIC + 0x201004) = irq;
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006152:	00d5151b          	slliw	a0,a0,0xd
    80006156:	0c2017b7          	lui	a5,0xc201
    8000615a:	97aa                	add	a5,a5,a0
    8000615c:	c3c4                	sw	s1,4(a5)
}
    8000615e:	60e2                	ld	ra,24(sp)
    80006160:	6442                	ld	s0,16(sp)
    80006162:	64a2                	ld	s1,8(sp)
    80006164:	6105                	addi	sp,sp,32
    80006166:	8082                	ret

0000000080006168 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int n, int i)
{
    80006168:	1141                	addi	sp,sp,-16
    8000616a:	e406                	sd	ra,8(sp)
    8000616c:	e022                	sd	s0,0(sp)
    8000616e:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80006170:	479d                	li	a5,7
    80006172:	06b7c963          	blt	a5,a1,800061e4 <free_desc+0x7c>
    panic("virtio_disk_intr 1");
  if(disk[n].free[i])
    80006176:	00151793          	slli	a5,a0,0x1
    8000617a:	97aa                	add	a5,a5,a0
    8000617c:	00c79713          	slli	a4,a5,0xc
    80006180:	0001e797          	auipc	a5,0x1e
    80006184:	e8078793          	addi	a5,a5,-384 # 80024000 <disk>
    80006188:	97ba                	add	a5,a5,a4
    8000618a:	97ae                	add	a5,a5,a1
    8000618c:	6709                	lui	a4,0x2
    8000618e:	97ba                	add	a5,a5,a4
    80006190:	0187c783          	lbu	a5,24(a5)
    80006194:	e3a5                	bnez	a5,800061f4 <free_desc+0x8c>
    panic("virtio_disk_intr 2");
  disk[n].desc[i].addr = 0;
    80006196:	0001e817          	auipc	a6,0x1e
    8000619a:	e6a80813          	addi	a6,a6,-406 # 80024000 <disk>
    8000619e:	00151693          	slli	a3,a0,0x1
    800061a2:	00a68733          	add	a4,a3,a0
    800061a6:	0732                	slli	a4,a4,0xc
    800061a8:	00e807b3          	add	a5,a6,a4
    800061ac:	6709                	lui	a4,0x2
    800061ae:	00f70633          	add	a2,a4,a5
    800061b2:	6210                	ld	a2,0(a2)
    800061b4:	00459893          	slli	a7,a1,0x4
    800061b8:	9646                	add	a2,a2,a7
    800061ba:	00063023          	sd	zero,0(a2) # 1000 <_entry-0x7ffff000>
  disk[n].free[i] = 1;
    800061be:	97ae                	add	a5,a5,a1
    800061c0:	97ba                	add	a5,a5,a4
    800061c2:	4605                	li	a2,1
    800061c4:	00c78c23          	sb	a2,24(a5)
  wakeup(&disk[n].free[0]);
    800061c8:	96aa                	add	a3,a3,a0
    800061ca:	06b2                	slli	a3,a3,0xc
    800061cc:	0761                	addi	a4,a4,24
    800061ce:	96ba                	add	a3,a3,a4
    800061d0:	00d80533          	add	a0,a6,a3
    800061d4:	ffffc097          	auipc	ra,0xffffc
    800061d8:	094080e7          	jalr	148(ra) # 80002268 <wakeup>
}
    800061dc:	60a2                	ld	ra,8(sp)
    800061de:	6402                	ld	s0,0(sp)
    800061e0:	0141                	addi	sp,sp,16
    800061e2:	8082                	ret
    panic("virtio_disk_intr 1");
    800061e4:	00002517          	auipc	a0,0x2
    800061e8:	69450513          	addi	a0,a0,1684 # 80008878 <userret+0x7e8>
    800061ec:	ffffa097          	auipc	ra,0xffffa
    800061f0:	35c080e7          	jalr	860(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    800061f4:	00002517          	auipc	a0,0x2
    800061f8:	69c50513          	addi	a0,a0,1692 # 80008890 <userret+0x800>
    800061fc:	ffffa097          	auipc	ra,0xffffa
    80006200:	34c080e7          	jalr	844(ra) # 80000548 <panic>

0000000080006204 <virtio_disk_init>:
  __sync_synchronize();
    80006204:	0ff0000f          	fence
  if(disk[n].init)
    80006208:	00151793          	slli	a5,a0,0x1
    8000620c:	97aa                	add	a5,a5,a0
    8000620e:	07b2                	slli	a5,a5,0xc
    80006210:	0001e717          	auipc	a4,0x1e
    80006214:	df070713          	addi	a4,a4,-528 # 80024000 <disk>
    80006218:	973e                	add	a4,a4,a5
    8000621a:	6789                	lui	a5,0x2
    8000621c:	97ba                	add	a5,a5,a4
    8000621e:	0a87a783          	lw	a5,168(a5) # 20a8 <_entry-0x7fffdf58>
    80006222:	c391                	beqz	a5,80006226 <virtio_disk_init+0x22>
    80006224:	8082                	ret
{
    80006226:	7139                	addi	sp,sp,-64
    80006228:	fc06                	sd	ra,56(sp)
    8000622a:	f822                	sd	s0,48(sp)
    8000622c:	f426                	sd	s1,40(sp)
    8000622e:	f04a                	sd	s2,32(sp)
    80006230:	ec4e                	sd	s3,24(sp)
    80006232:	e852                	sd	s4,16(sp)
    80006234:	e456                	sd	s5,8(sp)
    80006236:	0080                	addi	s0,sp,64
    80006238:	84aa                	mv	s1,a0
  printf("virtio disk init %d\n", n);
    8000623a:	85aa                	mv	a1,a0
    8000623c:	00002517          	auipc	a0,0x2
    80006240:	66c50513          	addi	a0,a0,1644 # 800088a8 <userret+0x818>
    80006244:	ffffa097          	auipc	ra,0xffffa
    80006248:	34e080e7          	jalr	846(ra) # 80000592 <printf>
  initlock(&disk[n].vdisk_lock, "virtio_disk");
    8000624c:	00149993          	slli	s3,s1,0x1
    80006250:	99a6                	add	s3,s3,s1
    80006252:	09b2                	slli	s3,s3,0xc
    80006254:	6789                	lui	a5,0x2
    80006256:	0b078793          	addi	a5,a5,176 # 20b0 <_entry-0x7fffdf50>
    8000625a:	97ce                	add	a5,a5,s3
    8000625c:	00002597          	auipc	a1,0x2
    80006260:	66458593          	addi	a1,a1,1636 # 800088c0 <userret+0x830>
    80006264:	0001e517          	auipc	a0,0x1e
    80006268:	d9c50513          	addi	a0,a0,-612 # 80024000 <disk>
    8000626c:	953e                	add	a0,a0,a5
    8000626e:	ffffa097          	auipc	ra,0xffffa
    80006272:	742080e7          	jalr	1858(ra) # 800009b0 <initlock>
  if(*R(n, VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006276:	0014891b          	addiw	s2,s1,1
    8000627a:	00c9191b          	slliw	s2,s2,0xc
    8000627e:	100007b7          	lui	a5,0x10000
    80006282:	97ca                	add	a5,a5,s2
    80006284:	4398                	lw	a4,0(a5)
    80006286:	2701                	sext.w	a4,a4
    80006288:	747277b7          	lui	a5,0x74727
    8000628c:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006290:	12f71663          	bne	a4,a5,800063bc <virtio_disk_init+0x1b8>
     *R(n, VIRTIO_MMIO_VERSION) != 1 ||
    80006294:	100007b7          	lui	a5,0x10000
    80006298:	0791                	addi	a5,a5,4
    8000629a:	97ca                	add	a5,a5,s2
    8000629c:	439c                	lw	a5,0(a5)
    8000629e:	2781                	sext.w	a5,a5
  if(*R(n, VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062a0:	4705                	li	a4,1
    800062a2:	10e79d63          	bne	a5,a4,800063bc <virtio_disk_init+0x1b8>
     *R(n, VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062a6:	100007b7          	lui	a5,0x10000
    800062aa:	07a1                	addi	a5,a5,8
    800062ac:	97ca                	add	a5,a5,s2
    800062ae:	439c                	lw	a5,0(a5)
    800062b0:	2781                	sext.w	a5,a5
     *R(n, VIRTIO_MMIO_VERSION) != 1 ||
    800062b2:	4709                	li	a4,2
    800062b4:	10e79463          	bne	a5,a4,800063bc <virtio_disk_init+0x1b8>
     *R(n, VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800062b8:	100007b7          	lui	a5,0x10000
    800062bc:	07b1                	addi	a5,a5,12
    800062be:	97ca                	add	a5,a5,s2
    800062c0:	4398                	lw	a4,0(a5)
    800062c2:	2701                	sext.w	a4,a4
     *R(n, VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062c4:	554d47b7          	lui	a5,0x554d4
    800062c8:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800062cc:	0ef71863          	bne	a4,a5,800063bc <virtio_disk_init+0x1b8>
  *R(n, VIRTIO_MMIO_STATUS) = status;
    800062d0:	100007b7          	lui	a5,0x10000
    800062d4:	07078693          	addi	a3,a5,112 # 10000070 <_entry-0x6fffff90>
    800062d8:	96ca                	add	a3,a3,s2
    800062da:	4705                	li	a4,1
    800062dc:	c298                	sw	a4,0(a3)
  *R(n, VIRTIO_MMIO_STATUS) = status;
    800062de:	470d                	li	a4,3
    800062e0:	c298                	sw	a4,0(a3)
  uint64 features = *R(n, VIRTIO_MMIO_DEVICE_FEATURES);
    800062e2:	01078713          	addi	a4,a5,16
    800062e6:	974a                	add	a4,a4,s2
    800062e8:	430c                	lw	a1,0(a4)
  *R(n, VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800062ea:	02078613          	addi	a2,a5,32
    800062ee:	964a                	add	a2,a2,s2
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800062f0:	c7ffe737          	lui	a4,0xc7ffe
    800062f4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd4703>
    800062f8:	8f6d                	and	a4,a4,a1
  *R(n, VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800062fa:	2701                	sext.w	a4,a4
    800062fc:	c218                	sw	a4,0(a2)
  *R(n, VIRTIO_MMIO_STATUS) = status;
    800062fe:	472d                	li	a4,11
    80006300:	c298                	sw	a4,0(a3)
  *R(n, VIRTIO_MMIO_STATUS) = status;
    80006302:	473d                	li	a4,15
    80006304:	c298                	sw	a4,0(a3)
  *R(n, VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006306:	02878713          	addi	a4,a5,40
    8000630a:	974a                	add	a4,a4,s2
    8000630c:	6685                	lui	a3,0x1
    8000630e:	c314                	sw	a3,0(a4)
  *R(n, VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006310:	03078713          	addi	a4,a5,48
    80006314:	974a                	add	a4,a4,s2
    80006316:	00072023          	sw	zero,0(a4)
  uint32 max = *R(n, VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000631a:	03478793          	addi	a5,a5,52
    8000631e:	97ca                	add	a5,a5,s2
    80006320:	439c                	lw	a5,0(a5)
    80006322:	2781                	sext.w	a5,a5
  if(max == 0)
    80006324:	c7c5                	beqz	a5,800063cc <virtio_disk_init+0x1c8>
  if(max < NUM)
    80006326:	471d                	li	a4,7
    80006328:	0af77a63          	bgeu	a4,a5,800063dc <virtio_disk_init+0x1d8>
  *R(n, VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000632c:	10000ab7          	lui	s5,0x10000
    80006330:	038a8793          	addi	a5,s5,56 # 10000038 <_entry-0x6fffffc8>
    80006334:	97ca                	add	a5,a5,s2
    80006336:	4721                	li	a4,8
    80006338:	c398                	sw	a4,0(a5)
  memset(disk[n].pages, 0, sizeof(disk[n].pages));
    8000633a:	0001ea17          	auipc	s4,0x1e
    8000633e:	cc6a0a13          	addi	s4,s4,-826 # 80024000 <disk>
    80006342:	99d2                	add	s3,s3,s4
    80006344:	6609                	lui	a2,0x2
    80006346:	4581                	li	a1,0
    80006348:	854e                	mv	a0,s3
    8000634a:	ffffb097          	auipc	ra,0xffffb
    8000634e:	838080e7          	jalr	-1992(ra) # 80000b82 <memset>
  *R(n, VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk[n].pages) >> PGSHIFT;
    80006352:	040a8a93          	addi	s5,s5,64
    80006356:	9956                	add	s2,s2,s5
    80006358:	00c9d793          	srli	a5,s3,0xc
    8000635c:	2781                	sext.w	a5,a5
    8000635e:	00f92023          	sw	a5,0(s2)
  disk[n].desc = (struct VRingDesc *) disk[n].pages;
    80006362:	00149693          	slli	a3,s1,0x1
    80006366:	009687b3          	add	a5,a3,s1
    8000636a:	07b2                	slli	a5,a5,0xc
    8000636c:	97d2                	add	a5,a5,s4
    8000636e:	6609                	lui	a2,0x2
    80006370:	97b2                	add	a5,a5,a2
    80006372:	0137b023          	sd	s3,0(a5)
  disk[n].avail = (uint16*)(((char*)disk[n].desc) + NUM*sizeof(struct VRingDesc));
    80006376:	08098713          	addi	a4,s3,128
    8000637a:	e798                	sd	a4,8(a5)
  disk[n].used = (struct UsedArea *) (disk[n].pages + PGSIZE);
    8000637c:	6705                	lui	a4,0x1
    8000637e:	99ba                	add	s3,s3,a4
    80006380:	0137b823          	sd	s3,16(a5)
    disk[n].free[i] = 1;
    80006384:	4705                	li	a4,1
    80006386:	00e78c23          	sb	a4,24(a5)
    8000638a:	00e78ca3          	sb	a4,25(a5)
    8000638e:	00e78d23          	sb	a4,26(a5)
    80006392:	00e78da3          	sb	a4,27(a5)
    80006396:	00e78e23          	sb	a4,28(a5)
    8000639a:	00e78ea3          	sb	a4,29(a5)
    8000639e:	00e78f23          	sb	a4,30(a5)
    800063a2:	00e78fa3          	sb	a4,31(a5)
  disk[n].init = 1;
    800063a6:	0ae7a423          	sw	a4,168(a5)
}
    800063aa:	70e2                	ld	ra,56(sp)
    800063ac:	7442                	ld	s0,48(sp)
    800063ae:	74a2                	ld	s1,40(sp)
    800063b0:	7902                	ld	s2,32(sp)
    800063b2:	69e2                	ld	s3,24(sp)
    800063b4:	6a42                	ld	s4,16(sp)
    800063b6:	6aa2                	ld	s5,8(sp)
    800063b8:	6121                	addi	sp,sp,64
    800063ba:	8082                	ret
    panic("could not find virtio disk");
    800063bc:	00002517          	auipc	a0,0x2
    800063c0:	51450513          	addi	a0,a0,1300 # 800088d0 <userret+0x840>
    800063c4:	ffffa097          	auipc	ra,0xffffa
    800063c8:	184080e7          	jalr	388(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    800063cc:	00002517          	auipc	a0,0x2
    800063d0:	52450513          	addi	a0,a0,1316 # 800088f0 <userret+0x860>
    800063d4:	ffffa097          	auipc	ra,0xffffa
    800063d8:	174080e7          	jalr	372(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    800063dc:	00002517          	auipc	a0,0x2
    800063e0:	53450513          	addi	a0,a0,1332 # 80008910 <userret+0x880>
    800063e4:	ffffa097          	auipc	ra,0xffffa
    800063e8:	164080e7          	jalr	356(ra) # 80000548 <panic>

00000000800063ec <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(int n, struct buf *b, int write)
{
    800063ec:	7135                	addi	sp,sp,-160
    800063ee:	ed06                	sd	ra,152(sp)
    800063f0:	e922                	sd	s0,144(sp)
    800063f2:	e526                	sd	s1,136(sp)
    800063f4:	e14a                	sd	s2,128(sp)
    800063f6:	fcce                	sd	s3,120(sp)
    800063f8:	f8d2                	sd	s4,112(sp)
    800063fa:	f4d6                	sd	s5,104(sp)
    800063fc:	f0da                	sd	s6,96(sp)
    800063fe:	ecde                	sd	s7,88(sp)
    80006400:	e8e2                	sd	s8,80(sp)
    80006402:	e4e6                	sd	s9,72(sp)
    80006404:	e0ea                	sd	s10,64(sp)
    80006406:	fc6e                	sd	s11,56(sp)
    80006408:	1100                	addi	s0,sp,160
    8000640a:	8aaa                	mv	s5,a0
    8000640c:	8c2e                	mv	s8,a1
    8000640e:	8db2                	mv	s11,a2
  uint64 sector = b->blockno * (BSIZE / 512);
    80006410:	45dc                	lw	a5,12(a1)
    80006412:	0017979b          	slliw	a5,a5,0x1
    80006416:	1782                	slli	a5,a5,0x20
    80006418:	9381                	srli	a5,a5,0x20
    8000641a:	f6f43423          	sd	a5,-152(s0)

  acquire(&disk[n].vdisk_lock);
    8000641e:	00151493          	slli	s1,a0,0x1
    80006422:	94aa                	add	s1,s1,a0
    80006424:	04b2                	slli	s1,s1,0xc
    80006426:	6909                	lui	s2,0x2
    80006428:	0b090c93          	addi	s9,s2,176 # 20b0 <_entry-0x7fffdf50>
    8000642c:	9ca6                	add	s9,s9,s1
    8000642e:	0001e997          	auipc	s3,0x1e
    80006432:	bd298993          	addi	s3,s3,-1070 # 80024000 <disk>
    80006436:	9cce                	add	s9,s9,s3
    80006438:	8566                	mv	a0,s9
    8000643a:	ffffa097          	auipc	ra,0xffffa
    8000643e:	684080e7          	jalr	1668(ra) # 80000abe <acquire>
  int idx[3];
  while(1){
    if(alloc3_desc(n, idx) == 0) {
      break;
    }
    sleep(&disk[n].free[0], &disk[n].vdisk_lock);
    80006442:	0961                	addi	s2,s2,24
    80006444:	94ca                	add	s1,s1,s2
    80006446:	99a6                	add	s3,s3,s1
  for(int i = 0; i < 3; i++){
    80006448:	4a01                	li	s4,0
  for(int i = 0; i < NUM; i++){
    8000644a:	44a1                	li	s1,8
      disk[n].free[i] = 0;
    8000644c:	001a9793          	slli	a5,s5,0x1
    80006450:	97d6                	add	a5,a5,s5
    80006452:	07b2                	slli	a5,a5,0xc
    80006454:	0001eb97          	auipc	s7,0x1e
    80006458:	bacb8b93          	addi	s7,s7,-1108 # 80024000 <disk>
    8000645c:	9bbe                	add	s7,s7,a5
    8000645e:	a8a9                	j	800064b8 <virtio_disk_rw+0xcc>
    80006460:	00fb8733          	add	a4,s7,a5
    80006464:	9742                	add	a4,a4,a6
    80006466:	00070c23          	sb	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    idx[i] = alloc_desc(n);
    8000646a:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    8000646c:	0207c263          	bltz	a5,80006490 <virtio_disk_rw+0xa4>
  for(int i = 0; i < 3; i++){
    80006470:	2905                	addiw	s2,s2,1
    80006472:	0611                	addi	a2,a2,4
    80006474:	1ca90463          	beq	s2,a0,8000663c <virtio_disk_rw+0x250>
    idx[i] = alloc_desc(n);
    80006478:	85b2                	mv	a1,a2
    8000647a:	874e                	mv	a4,s3
  for(int i = 0; i < NUM; i++){
    8000647c:	87d2                	mv	a5,s4
    if(disk[n].free[i]){
    8000647e:	00074683          	lbu	a3,0(a4)
    80006482:	fef9                	bnez	a3,80006460 <virtio_disk_rw+0x74>
  for(int i = 0; i < NUM; i++){
    80006484:	2785                	addiw	a5,a5,1
    80006486:	0705                	addi	a4,a4,1
    80006488:	fe979be3          	bne	a5,s1,8000647e <virtio_disk_rw+0x92>
    idx[i] = alloc_desc(n);
    8000648c:	57fd                	li	a5,-1
    8000648e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006490:	01205e63          	blez	s2,800064ac <virtio_disk_rw+0xc0>
    80006494:	8d52                	mv	s10,s4
        free_desc(n, idx[j]);
    80006496:	000b2583          	lw	a1,0(s6)
    8000649a:	8556                	mv	a0,s5
    8000649c:	00000097          	auipc	ra,0x0
    800064a0:	ccc080e7          	jalr	-820(ra) # 80006168 <free_desc>
      for(int j = 0; j < i; j++)
    800064a4:	2d05                	addiw	s10,s10,1
    800064a6:	0b11                	addi	s6,s6,4
    800064a8:	ffa917e3          	bne	s2,s10,80006496 <virtio_disk_rw+0xaa>
    sleep(&disk[n].free[0], &disk[n].vdisk_lock);
    800064ac:	85e6                	mv	a1,s9
    800064ae:	854e                	mv	a0,s3
    800064b0:	ffffc097          	auipc	ra,0xffffc
    800064b4:	c38080e7          	jalr	-968(ra) # 800020e8 <sleep>
  for(int i = 0; i < 3; i++){
    800064b8:	f8040b13          	addi	s6,s0,-128
{
    800064bc:	865a                	mv	a2,s6
  for(int i = 0; i < 3; i++){
    800064be:	8952                	mv	s2,s4
      disk[n].free[i] = 0;
    800064c0:	6809                	lui	a6,0x2
  for(int i = 0; i < 3; i++){
    800064c2:	450d                	li	a0,3
    800064c4:	bf55                	j	80006478 <virtio_disk_rw+0x8c>
  disk[n].desc[idx[0]].next = idx[1];

  disk[n].desc[idx[1]].addr = (uint64) b->data;
  disk[n].desc[idx[1]].len = BSIZE;
  if(write)
    disk[n].desc[idx[1]].flags = 0; // device reads b->data
    800064c6:	001a9793          	slli	a5,s5,0x1
    800064ca:	97d6                	add	a5,a5,s5
    800064cc:	07b2                	slli	a5,a5,0xc
    800064ce:	0001e717          	auipc	a4,0x1e
    800064d2:	b3270713          	addi	a4,a4,-1230 # 80024000 <disk>
    800064d6:	973e                	add	a4,a4,a5
    800064d8:	6789                	lui	a5,0x2
    800064da:	97ba                	add	a5,a5,a4
    800064dc:	639c                	ld	a5,0(a5)
    800064de:	97b6                	add	a5,a5,a3
    800064e0:	00079623          	sh	zero,12(a5) # 200c <_entry-0x7fffdff4>
  else
    disk[n].desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk[n].desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800064e4:	0001e517          	auipc	a0,0x1e
    800064e8:	b1c50513          	addi	a0,a0,-1252 # 80024000 <disk>
    800064ec:	001a9793          	slli	a5,s5,0x1
    800064f0:	01578733          	add	a4,a5,s5
    800064f4:	0732                	slli	a4,a4,0xc
    800064f6:	972a                	add	a4,a4,a0
    800064f8:	6609                	lui	a2,0x2
    800064fa:	9732                	add	a4,a4,a2
    800064fc:	6310                	ld	a2,0(a4)
    800064fe:	9636                	add	a2,a2,a3
    80006500:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006504:	0015e593          	ori	a1,a1,1
    80006508:	00b61623          	sh	a1,12(a2)
  disk[n].desc[idx[1]].next = idx[2];
    8000650c:	f8842603          	lw	a2,-120(s0)
    80006510:	630c                	ld	a1,0(a4)
    80006512:	96ae                	add	a3,a3,a1
    80006514:	00c69723          	sh	a2,14(a3) # 100e <_entry-0x7fffeff2>

  disk[n].info[idx[0]].status = 0;
    80006518:	97d6                	add	a5,a5,s5
    8000651a:	07a2                	slli	a5,a5,0x8
    8000651c:	97a6                	add	a5,a5,s1
    8000651e:	20078793          	addi	a5,a5,512
    80006522:	0792                	slli	a5,a5,0x4
    80006524:	97aa                	add	a5,a5,a0
    80006526:	02078823          	sb	zero,48(a5)
  disk[n].desc[idx[2]].addr = (uint64) &disk[n].info[idx[0]].status;
    8000652a:	00461693          	slli	a3,a2,0x4
    8000652e:	00073803          	ld	a6,0(a4)
    80006532:	9836                	add	a6,a6,a3
    80006534:	20348613          	addi	a2,s1,515
    80006538:	001a9593          	slli	a1,s5,0x1
    8000653c:	95d6                	add	a1,a1,s5
    8000653e:	05a2                	slli	a1,a1,0x8
    80006540:	962e                	add	a2,a2,a1
    80006542:	0612                	slli	a2,a2,0x4
    80006544:	962a                	add	a2,a2,a0
    80006546:	00c83023          	sd	a2,0(a6) # 2000 <_entry-0x7fffe000>
  disk[n].desc[idx[2]].len = 1;
    8000654a:	630c                	ld	a1,0(a4)
    8000654c:	95b6                	add	a1,a1,a3
    8000654e:	4605                	li	a2,1
    80006550:	c590                	sw	a2,8(a1)
  disk[n].desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006552:	630c                	ld	a1,0(a4)
    80006554:	95b6                	add	a1,a1,a3
    80006556:	4509                	li	a0,2
    80006558:	00a59623          	sh	a0,12(a1)
  disk[n].desc[idx[2]].next = 0;
    8000655c:	630c                	ld	a1,0(a4)
    8000655e:	96ae                	add	a3,a3,a1
    80006560:	00069723          	sh	zero,14(a3)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006564:	00cc2223          	sw	a2,4(s8) # fffffffffffff004 <end+0xffffffff7ffd4fa8>
  disk[n].info[idx[0]].b = b;
    80006568:	0387b423          	sd	s8,40(a5)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk[n].avail[2 + (disk[n].avail[1] % NUM)] = idx[0];
    8000656c:	6714                	ld	a3,8(a4)
    8000656e:	0026d783          	lhu	a5,2(a3)
    80006572:	8b9d                	andi	a5,a5,7
    80006574:	0789                	addi	a5,a5,2
    80006576:	0786                	slli	a5,a5,0x1
    80006578:	97b6                	add	a5,a5,a3
    8000657a:	00979023          	sh	s1,0(a5)
  __sync_synchronize();
    8000657e:	0ff0000f          	fence
  disk[n].avail[1] = disk[n].avail[1] + 1;
    80006582:	6718                	ld	a4,8(a4)
    80006584:	00275783          	lhu	a5,2(a4)
    80006588:	2785                	addiw	a5,a5,1
    8000658a:	00f71123          	sh	a5,2(a4)

  *R(n, VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000658e:	001a879b          	addiw	a5,s5,1
    80006592:	00c7979b          	slliw	a5,a5,0xc
    80006596:	10000737          	lui	a4,0x10000
    8000659a:	05070713          	addi	a4,a4,80 # 10000050 <_entry-0x6fffffb0>
    8000659e:	97ba                	add	a5,a5,a4
    800065a0:	0007a023          	sw	zero,0(a5)

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800065a4:	004c2783          	lw	a5,4(s8)
    800065a8:	00c79d63          	bne	a5,a2,800065c2 <virtio_disk_rw+0x1d6>
    800065ac:	4485                	li	s1,1
    sleep(b, &disk[n].vdisk_lock);
    800065ae:	85e6                	mv	a1,s9
    800065b0:	8562                	mv	a0,s8
    800065b2:	ffffc097          	auipc	ra,0xffffc
    800065b6:	b36080e7          	jalr	-1226(ra) # 800020e8 <sleep>
  while(b->disk == 1) {
    800065ba:	004c2783          	lw	a5,4(s8)
    800065be:	fe9788e3          	beq	a5,s1,800065ae <virtio_disk_rw+0x1c2>
  }

  disk[n].info[idx[0]].b = 0;
    800065c2:	f8042483          	lw	s1,-128(s0)
    800065c6:	001a9793          	slli	a5,s5,0x1
    800065ca:	97d6                	add	a5,a5,s5
    800065cc:	07a2                	slli	a5,a5,0x8
    800065ce:	97a6                	add	a5,a5,s1
    800065d0:	20078793          	addi	a5,a5,512
    800065d4:	0792                	slli	a5,a5,0x4
    800065d6:	0001e717          	auipc	a4,0x1e
    800065da:	a2a70713          	addi	a4,a4,-1494 # 80024000 <disk>
    800065de:	97ba                	add	a5,a5,a4
    800065e0:	0207b423          	sd	zero,40(a5)
    if(disk[n].desc[i].flags & VRING_DESC_F_NEXT)
    800065e4:	001a9793          	slli	a5,s5,0x1
    800065e8:	97d6                	add	a5,a5,s5
    800065ea:	07b2                	slli	a5,a5,0xc
    800065ec:	97ba                	add	a5,a5,a4
    800065ee:	6909                	lui	s2,0x2
    800065f0:	993e                	add	s2,s2,a5
    800065f2:	a019                	j	800065f8 <virtio_disk_rw+0x20c>
      i = disk[n].desc[i].next;
    800065f4:	00e4d483          	lhu	s1,14(s1)
    free_desc(n, i);
    800065f8:	85a6                	mv	a1,s1
    800065fa:	8556                	mv	a0,s5
    800065fc:	00000097          	auipc	ra,0x0
    80006600:	b6c080e7          	jalr	-1172(ra) # 80006168 <free_desc>
    if(disk[n].desc[i].flags & VRING_DESC_F_NEXT)
    80006604:	0492                	slli	s1,s1,0x4
    80006606:	00093783          	ld	a5,0(s2) # 2000 <_entry-0x7fffe000>
    8000660a:	94be                	add	s1,s1,a5
    8000660c:	00c4d783          	lhu	a5,12(s1)
    80006610:	8b85                	andi	a5,a5,1
    80006612:	f3ed                	bnez	a5,800065f4 <virtio_disk_rw+0x208>
  free_chain(n, idx[0]);

  release(&disk[n].vdisk_lock);
    80006614:	8566                	mv	a0,s9
    80006616:	ffffa097          	auipc	ra,0xffffa
    8000661a:	510080e7          	jalr	1296(ra) # 80000b26 <release>
}
    8000661e:	60ea                	ld	ra,152(sp)
    80006620:	644a                	ld	s0,144(sp)
    80006622:	64aa                	ld	s1,136(sp)
    80006624:	690a                	ld	s2,128(sp)
    80006626:	79e6                	ld	s3,120(sp)
    80006628:	7a46                	ld	s4,112(sp)
    8000662a:	7aa6                	ld	s5,104(sp)
    8000662c:	7b06                	ld	s6,96(sp)
    8000662e:	6be6                	ld	s7,88(sp)
    80006630:	6c46                	ld	s8,80(sp)
    80006632:	6ca6                	ld	s9,72(sp)
    80006634:	6d06                	ld	s10,64(sp)
    80006636:	7de2                	ld	s11,56(sp)
    80006638:	610d                	addi	sp,sp,160
    8000663a:	8082                	ret
  if(write)
    8000663c:	01b037b3          	snez	a5,s11
    80006640:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    80006644:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    80006648:	f6843783          	ld	a5,-152(s0)
    8000664c:	f6f43c23          	sd	a5,-136(s0)
  disk[n].desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006650:	f8042483          	lw	s1,-128(s0)
    80006654:	00449993          	slli	s3,s1,0x4
    80006658:	001a9793          	slli	a5,s5,0x1
    8000665c:	97d6                	add	a5,a5,s5
    8000665e:	07b2                	slli	a5,a5,0xc
    80006660:	0001e917          	auipc	s2,0x1e
    80006664:	9a090913          	addi	s2,s2,-1632 # 80024000 <disk>
    80006668:	97ca                	add	a5,a5,s2
    8000666a:	6909                	lui	s2,0x2
    8000666c:	993e                	add	s2,s2,a5
    8000666e:	00093a03          	ld	s4,0(s2) # 2000 <_entry-0x7fffe000>
    80006672:	9a4e                	add	s4,s4,s3
    80006674:	f7040513          	addi	a0,s0,-144
    80006678:	ffffb097          	auipc	ra,0xffffb
    8000667c:	946080e7          	jalr	-1722(ra) # 80000fbe <kvmpa>
    80006680:	00aa3023          	sd	a0,0(s4)
  disk[n].desc[idx[0]].len = sizeof(buf0);
    80006684:	00093783          	ld	a5,0(s2)
    80006688:	97ce                	add	a5,a5,s3
    8000668a:	4741                	li	a4,16
    8000668c:	c798                	sw	a4,8(a5)
  disk[n].desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000668e:	00093783          	ld	a5,0(s2)
    80006692:	97ce                	add	a5,a5,s3
    80006694:	4705                	li	a4,1
    80006696:	00e79623          	sh	a4,12(a5)
  disk[n].desc[idx[0]].next = idx[1];
    8000669a:	f8442683          	lw	a3,-124(s0)
    8000669e:	00093783          	ld	a5,0(s2)
    800066a2:	99be                	add	s3,s3,a5
    800066a4:	00d99723          	sh	a3,14(s3)
  disk[n].desc[idx[1]].addr = (uint64) b->data;
    800066a8:	0692                	slli	a3,a3,0x4
    800066aa:	00093783          	ld	a5,0(s2)
    800066ae:	97b6                	add	a5,a5,a3
    800066b0:	060c0713          	addi	a4,s8,96
    800066b4:	e398                	sd	a4,0(a5)
  disk[n].desc[idx[1]].len = BSIZE;
    800066b6:	00093783          	ld	a5,0(s2)
    800066ba:	97b6                	add	a5,a5,a3
    800066bc:	40000713          	li	a4,1024
    800066c0:	c798                	sw	a4,8(a5)
  if(write)
    800066c2:	e00d92e3          	bnez	s11,800064c6 <virtio_disk_rw+0xda>
    disk[n].desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800066c6:	001a9793          	slli	a5,s5,0x1
    800066ca:	97d6                	add	a5,a5,s5
    800066cc:	07b2                	slli	a5,a5,0xc
    800066ce:	0001e717          	auipc	a4,0x1e
    800066d2:	93270713          	addi	a4,a4,-1742 # 80024000 <disk>
    800066d6:	973e                	add	a4,a4,a5
    800066d8:	6789                	lui	a5,0x2
    800066da:	97ba                	add	a5,a5,a4
    800066dc:	639c                	ld	a5,0(a5)
    800066de:	97b6                	add	a5,a5,a3
    800066e0:	4709                	li	a4,2
    800066e2:	00e79623          	sh	a4,12(a5) # 200c <_entry-0x7fffdff4>
    800066e6:	bbfd                	j	800064e4 <virtio_disk_rw+0xf8>

00000000800066e8 <virtio_disk_intr>:

void
virtio_disk_intr(int n)
{
    800066e8:	7139                	addi	sp,sp,-64
    800066ea:	fc06                	sd	ra,56(sp)
    800066ec:	f822                	sd	s0,48(sp)
    800066ee:	f426                	sd	s1,40(sp)
    800066f0:	f04a                	sd	s2,32(sp)
    800066f2:	ec4e                	sd	s3,24(sp)
    800066f4:	e852                	sd	s4,16(sp)
    800066f6:	e456                	sd	s5,8(sp)
    800066f8:	0080                	addi	s0,sp,64
    800066fa:	84aa                	mv	s1,a0
  acquire(&disk[n].vdisk_lock);
    800066fc:	00151913          	slli	s2,a0,0x1
    80006700:	00a90a33          	add	s4,s2,a0
    80006704:	0a32                	slli	s4,s4,0xc
    80006706:	6989                	lui	s3,0x2
    80006708:	0b098793          	addi	a5,s3,176 # 20b0 <_entry-0x7fffdf50>
    8000670c:	9a3e                	add	s4,s4,a5
    8000670e:	0001ea97          	auipc	s5,0x1e
    80006712:	8f2a8a93          	addi	s5,s5,-1806 # 80024000 <disk>
    80006716:	9a56                	add	s4,s4,s5
    80006718:	8552                	mv	a0,s4
    8000671a:	ffffa097          	auipc	ra,0xffffa
    8000671e:	3a4080e7          	jalr	932(ra) # 80000abe <acquire>

  while((disk[n].used_idx % NUM) != (disk[n].used->id % NUM)){
    80006722:	9926                	add	s2,s2,s1
    80006724:	0932                	slli	s2,s2,0xc
    80006726:	9956                	add	s2,s2,s5
    80006728:	99ca                	add	s3,s3,s2
    8000672a:	0209d783          	lhu	a5,32(s3)
    8000672e:	0109b703          	ld	a4,16(s3)
    80006732:	00275683          	lhu	a3,2(a4)
    80006736:	8ebd                	xor	a3,a3,a5
    80006738:	8a9d                	andi	a3,a3,7
    8000673a:	c2a5                	beqz	a3,8000679a <virtio_disk_intr+0xb2>
    int id = disk[n].used->elems[disk[n].used_idx].id;

    if(disk[n].info[id].status != 0)
    8000673c:	8956                	mv	s2,s5
    8000673e:	00149693          	slli	a3,s1,0x1
    80006742:	96a6                	add	a3,a3,s1
    80006744:	00869993          	slli	s3,a3,0x8
      panic("virtio_disk_intr status");
    
    disk[n].info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk[n].info[id].b);

    disk[n].used_idx = (disk[n].used_idx + 1) % NUM;
    80006748:	06b2                	slli	a3,a3,0xc
    8000674a:	96d6                	add	a3,a3,s5
    8000674c:	6489                	lui	s1,0x2
    8000674e:	94b6                	add	s1,s1,a3
    int id = disk[n].used->elems[disk[n].used_idx].id;
    80006750:	078e                	slli	a5,a5,0x3
    80006752:	97ba                	add	a5,a5,a4
    80006754:	43dc                	lw	a5,4(a5)
    if(disk[n].info[id].status != 0)
    80006756:	00f98733          	add	a4,s3,a5
    8000675a:	20070713          	addi	a4,a4,512
    8000675e:	0712                	slli	a4,a4,0x4
    80006760:	974a                	add	a4,a4,s2
    80006762:	03074703          	lbu	a4,48(a4)
    80006766:	eb21                	bnez	a4,800067b6 <virtio_disk_intr+0xce>
    disk[n].info[id].b->disk = 0;   // disk is done with buf
    80006768:	97ce                	add	a5,a5,s3
    8000676a:	20078793          	addi	a5,a5,512
    8000676e:	0792                	slli	a5,a5,0x4
    80006770:	97ca                	add	a5,a5,s2
    80006772:	7798                	ld	a4,40(a5)
    80006774:	00072223          	sw	zero,4(a4)
    wakeup(disk[n].info[id].b);
    80006778:	7788                	ld	a0,40(a5)
    8000677a:	ffffc097          	auipc	ra,0xffffc
    8000677e:	aee080e7          	jalr	-1298(ra) # 80002268 <wakeup>
    disk[n].used_idx = (disk[n].used_idx + 1) % NUM;
    80006782:	0204d783          	lhu	a5,32(s1) # 2020 <_entry-0x7fffdfe0>
    80006786:	2785                	addiw	a5,a5,1
    80006788:	8b9d                	andi	a5,a5,7
    8000678a:	02f49023          	sh	a5,32(s1)
  while((disk[n].used_idx % NUM) != (disk[n].used->id % NUM)){
    8000678e:	6898                	ld	a4,16(s1)
    80006790:	00275683          	lhu	a3,2(a4)
    80006794:	8a9d                	andi	a3,a3,7
    80006796:	faf69de3          	bne	a3,a5,80006750 <virtio_disk_intr+0x68>
  }

  release(&disk[n].vdisk_lock);
    8000679a:	8552                	mv	a0,s4
    8000679c:	ffffa097          	auipc	ra,0xffffa
    800067a0:	38a080e7          	jalr	906(ra) # 80000b26 <release>
}
    800067a4:	70e2                	ld	ra,56(sp)
    800067a6:	7442                	ld	s0,48(sp)
    800067a8:	74a2                	ld	s1,40(sp)
    800067aa:	7902                	ld	s2,32(sp)
    800067ac:	69e2                	ld	s3,24(sp)
    800067ae:	6a42                	ld	s4,16(sp)
    800067b0:	6aa2                	ld	s5,8(sp)
    800067b2:	6121                	addi	sp,sp,64
    800067b4:	8082                	ret
      panic("virtio_disk_intr status");
    800067b6:	00002517          	auipc	a0,0x2
    800067ba:	17a50513          	addi	a0,a0,378 # 80008930 <userret+0x8a0>
    800067be:	ffffa097          	auipc	ra,0xffffa
    800067c2:	d8a080e7          	jalr	-630(ra) # 80000548 <panic>

00000000800067c6 <bit_isset>:
static Sz_info *bd_sizes; 
static void *bd_base;   // start address of memory managed by the buddy allocator
static struct spinlock lock;

// Return 1 if bit at position index in array is set to 1
int bit_isset(char *array, int index) {
    800067c6:	1141                	addi	sp,sp,-16
    800067c8:	e422                	sd	s0,8(sp)
    800067ca:	0800                	addi	s0,sp,16
  char b = array[index/8];
  char m = (1 << (index % 8));
    800067cc:	41f5d79b          	sraiw	a5,a1,0x1f
    800067d0:	01d7d79b          	srliw	a5,a5,0x1d
    800067d4:	9dbd                	addw	a1,a1,a5
    800067d6:	0075f713          	andi	a4,a1,7
    800067da:	9f1d                	subw	a4,a4,a5
    800067dc:	4785                	li	a5,1
    800067de:	00e797bb          	sllw	a5,a5,a4
    800067e2:	0ff7f793          	andi	a5,a5,255
  char b = array[index/8];
    800067e6:	4035d59b          	sraiw	a1,a1,0x3
    800067ea:	95aa                	add	a1,a1,a0
  return (b & m) == m;
    800067ec:	0005c503          	lbu	a0,0(a1)
    800067f0:	8d7d                	and	a0,a0,a5
    800067f2:	8d1d                	sub	a0,a0,a5
}
    800067f4:	00153513          	seqz	a0,a0
    800067f8:	6422                	ld	s0,8(sp)
    800067fa:	0141                	addi	sp,sp,16
    800067fc:	8082                	ret

00000000800067fe <bit_set>:

// Set bit at position index in array to 1
void bit_set(char *array, int index) {
    800067fe:	1141                	addi	sp,sp,-16
    80006800:	e422                	sd	s0,8(sp)
    80006802:	0800                	addi	s0,sp,16
  char b = array[index/8];
    80006804:	41f5d79b          	sraiw	a5,a1,0x1f
    80006808:	01d7d79b          	srliw	a5,a5,0x1d
    8000680c:	9dbd                	addw	a1,a1,a5
    8000680e:	4035d71b          	sraiw	a4,a1,0x3
    80006812:	953a                	add	a0,a0,a4
  char m = (1 << (index % 8));
    80006814:	899d                	andi	a1,a1,7
    80006816:	9d9d                	subw	a1,a1,a5
    80006818:	4785                	li	a5,1
    8000681a:	00b795bb          	sllw	a1,a5,a1
  array[index/8] = (b | m);
    8000681e:	00054783          	lbu	a5,0(a0)
    80006822:	8ddd                	or	a1,a1,a5
    80006824:	00b50023          	sb	a1,0(a0)
}
    80006828:	6422                	ld	s0,8(sp)
    8000682a:	0141                	addi	sp,sp,16
    8000682c:	8082                	ret

000000008000682e <bit_clear>:

// Clear bit at position index in array
void bit_clear(char *array, int index) {
    8000682e:	1141                	addi	sp,sp,-16
    80006830:	e422                	sd	s0,8(sp)
    80006832:	0800                	addi	s0,sp,16
  char b = array[index/8];
    80006834:	41f5d79b          	sraiw	a5,a1,0x1f
    80006838:	01d7d79b          	srliw	a5,a5,0x1d
    8000683c:	9dbd                	addw	a1,a1,a5
    8000683e:	4035d71b          	sraiw	a4,a1,0x3
    80006842:	953a                	add	a0,a0,a4
  char m = (1 << (index % 8));
    80006844:	899d                	andi	a1,a1,7
    80006846:	9d9d                	subw	a1,a1,a5
    80006848:	4785                	li	a5,1
    8000684a:	00b795bb          	sllw	a1,a5,a1
  array[index/8] = (b & ~m);
    8000684e:	fff5c593          	not	a1,a1
    80006852:	00054783          	lbu	a5,0(a0)
    80006856:	8dfd                	and	a1,a1,a5
    80006858:	00b50023          	sb	a1,0(a0)
}
    8000685c:	6422                	ld	s0,8(sp)
    8000685e:	0141                	addi	sp,sp,16
    80006860:	8082                	ret

0000000080006862 <bd_print_vector>:

// Print a bit vector as a list of ranges of 1 bits
void
bd_print_vector(char *vector, int len) {
    80006862:	715d                	addi	sp,sp,-80
    80006864:	e486                	sd	ra,72(sp)
    80006866:	e0a2                	sd	s0,64(sp)
    80006868:	fc26                	sd	s1,56(sp)
    8000686a:	f84a                	sd	s2,48(sp)
    8000686c:	f44e                	sd	s3,40(sp)
    8000686e:	f052                	sd	s4,32(sp)
    80006870:	ec56                	sd	s5,24(sp)
    80006872:	e85a                	sd	s6,16(sp)
    80006874:	e45e                	sd	s7,8(sp)
    80006876:	0880                	addi	s0,sp,80
    80006878:	8a2e                	mv	s4,a1
  int last, lb;
  
  last = 1;
  lb = 0;
  for (int b = 0; b < len; b++) {
    8000687a:	08b05b63          	blez	a1,80006910 <bd_print_vector+0xae>
    8000687e:	89aa                	mv	s3,a0
    80006880:	4481                	li	s1,0
  lb = 0;
    80006882:	4a81                	li	s5,0
  last = 1;
    80006884:	4905                	li	s2,1
    if (last == bit_isset(vector, b))
      continue;
    if(last == 1)
    80006886:	4b05                	li	s6,1
      printf(" [%d, %d)", lb, b);
    80006888:	00002b97          	auipc	s7,0x2
    8000688c:	0c0b8b93          	addi	s7,s7,192 # 80008948 <userret+0x8b8>
    80006890:	a821                	j	800068a8 <bd_print_vector+0x46>
    lb = b;
    last = bit_isset(vector, b);
    80006892:	85a6                	mv	a1,s1
    80006894:	854e                	mv	a0,s3
    80006896:	00000097          	auipc	ra,0x0
    8000689a:	f30080e7          	jalr	-208(ra) # 800067c6 <bit_isset>
    8000689e:	892a                	mv	s2,a0
    800068a0:	8aa6                	mv	s5,s1
  for (int b = 0; b < len; b++) {
    800068a2:	2485                	addiw	s1,s1,1
    800068a4:	029a0463          	beq	s4,s1,800068cc <bd_print_vector+0x6a>
    if (last == bit_isset(vector, b))
    800068a8:	85a6                	mv	a1,s1
    800068aa:	854e                	mv	a0,s3
    800068ac:	00000097          	auipc	ra,0x0
    800068b0:	f1a080e7          	jalr	-230(ra) # 800067c6 <bit_isset>
    800068b4:	ff2507e3          	beq	a0,s2,800068a2 <bd_print_vector+0x40>
    if(last == 1)
    800068b8:	fd691de3          	bne	s2,s6,80006892 <bd_print_vector+0x30>
      printf(" [%d, %d)", lb, b);
    800068bc:	8626                	mv	a2,s1
    800068be:	85d6                	mv	a1,s5
    800068c0:	855e                	mv	a0,s7
    800068c2:	ffffa097          	auipc	ra,0xffffa
    800068c6:	cd0080e7          	jalr	-816(ra) # 80000592 <printf>
    800068ca:	b7e1                	j	80006892 <bd_print_vector+0x30>
  }
  if(lb == 0 || last == 1) {
    800068cc:	000a8563          	beqz	s5,800068d6 <bd_print_vector+0x74>
    800068d0:	4785                	li	a5,1
    800068d2:	00f91c63          	bne	s2,a5,800068ea <bd_print_vector+0x88>
    printf(" [%d, %d)", lb, len);
    800068d6:	8652                	mv	a2,s4
    800068d8:	85d6                	mv	a1,s5
    800068da:	00002517          	auipc	a0,0x2
    800068de:	06e50513          	addi	a0,a0,110 # 80008948 <userret+0x8b8>
    800068e2:	ffffa097          	auipc	ra,0xffffa
    800068e6:	cb0080e7          	jalr	-848(ra) # 80000592 <printf>
  }
  printf("\n");
    800068ea:	00002517          	auipc	a0,0x2
    800068ee:	8c650513          	addi	a0,a0,-1850 # 800081b0 <userret+0x120>
    800068f2:	ffffa097          	auipc	ra,0xffffa
    800068f6:	ca0080e7          	jalr	-864(ra) # 80000592 <printf>
}
    800068fa:	60a6                	ld	ra,72(sp)
    800068fc:	6406                	ld	s0,64(sp)
    800068fe:	74e2                	ld	s1,56(sp)
    80006900:	7942                	ld	s2,48(sp)
    80006902:	79a2                	ld	s3,40(sp)
    80006904:	7a02                	ld	s4,32(sp)
    80006906:	6ae2                	ld	s5,24(sp)
    80006908:	6b42                	ld	s6,16(sp)
    8000690a:	6ba2                	ld	s7,8(sp)
    8000690c:	6161                	addi	sp,sp,80
    8000690e:	8082                	ret
  lb = 0;
    80006910:	4a81                	li	s5,0
    80006912:	b7d1                	j	800068d6 <bd_print_vector+0x74>

0000000080006914 <bd_print>:

// Print buddy's data structures
void
bd_print() {
  for (int k = 0; k < nsizes; k++) {
    80006914:	00023697          	auipc	a3,0x23
    80006918:	7446a683          	lw	a3,1860(a3) # 8002a058 <nsizes>
    8000691c:	10d05063          	blez	a3,80006a1c <bd_print+0x108>
bd_print() {
    80006920:	711d                	addi	sp,sp,-96
    80006922:	ec86                	sd	ra,88(sp)
    80006924:	e8a2                	sd	s0,80(sp)
    80006926:	e4a6                	sd	s1,72(sp)
    80006928:	e0ca                	sd	s2,64(sp)
    8000692a:	fc4e                	sd	s3,56(sp)
    8000692c:	f852                	sd	s4,48(sp)
    8000692e:	f456                	sd	s5,40(sp)
    80006930:	f05a                	sd	s6,32(sp)
    80006932:	ec5e                	sd	s7,24(sp)
    80006934:	e862                	sd	s8,16(sp)
    80006936:	e466                	sd	s9,8(sp)
    80006938:	e06a                	sd	s10,0(sp)
    8000693a:	1080                	addi	s0,sp,96
  for (int k = 0; k < nsizes; k++) {
    8000693c:	4481                	li	s1,0
    printf("size %d (blksz %d nblk %d): free list: ", k, BLK_SIZE(k), NBLK(k));
    8000693e:	4a85                	li	s5,1
    80006940:	4c41                	li	s8,16
    80006942:	00002b97          	auipc	s7,0x2
    80006946:	016b8b93          	addi	s7,s7,22 # 80008958 <userret+0x8c8>
    lst_print(&bd_sizes[k].free);
    8000694a:	00023a17          	auipc	s4,0x23
    8000694e:	706a0a13          	addi	s4,s4,1798 # 8002a050 <bd_sizes>
    printf("  alloc:");
    80006952:	00002b17          	auipc	s6,0x2
    80006956:	02eb0b13          	addi	s6,s6,46 # 80008980 <userret+0x8f0>
    bd_print_vector(bd_sizes[k].alloc, NBLK(k));
    8000695a:	00023997          	auipc	s3,0x23
    8000695e:	6fe98993          	addi	s3,s3,1790 # 8002a058 <nsizes>
    if(k > 0) {
      printf("  split:");
    80006962:	00002c97          	auipc	s9,0x2
    80006966:	02ec8c93          	addi	s9,s9,46 # 80008990 <userret+0x900>
    8000696a:	a801                	j	8000697a <bd_print+0x66>
  for (int k = 0; k < nsizes; k++) {
    8000696c:	0009a683          	lw	a3,0(s3)
    80006970:	0485                	addi	s1,s1,1
    80006972:	0004879b          	sext.w	a5,s1
    80006976:	08d7d563          	bge	a5,a3,80006a00 <bd_print+0xec>
    8000697a:	0004891b          	sext.w	s2,s1
    printf("size %d (blksz %d nblk %d): free list: ", k, BLK_SIZE(k), NBLK(k));
    8000697e:	36fd                	addiw	a3,a3,-1
    80006980:	9e85                	subw	a3,a3,s1
    80006982:	00da96bb          	sllw	a3,s5,a3
    80006986:	009c1633          	sll	a2,s8,s1
    8000698a:	85ca                	mv	a1,s2
    8000698c:	855e                	mv	a0,s7
    8000698e:	ffffa097          	auipc	ra,0xffffa
    80006992:	c04080e7          	jalr	-1020(ra) # 80000592 <printf>
    lst_print(&bd_sizes[k].free);
    80006996:	00549d13          	slli	s10,s1,0x5
    8000699a:	000a3503          	ld	a0,0(s4)
    8000699e:	956a                	add	a0,a0,s10
    800069a0:	00001097          	auipc	ra,0x1
    800069a4:	a56080e7          	jalr	-1450(ra) # 800073f6 <lst_print>
    printf("  alloc:");
    800069a8:	855a                	mv	a0,s6
    800069aa:	ffffa097          	auipc	ra,0xffffa
    800069ae:	be8080e7          	jalr	-1048(ra) # 80000592 <printf>
    bd_print_vector(bd_sizes[k].alloc, NBLK(k));
    800069b2:	0009a583          	lw	a1,0(s3)
    800069b6:	35fd                	addiw	a1,a1,-1
    800069b8:	412585bb          	subw	a1,a1,s2
    800069bc:	000a3783          	ld	a5,0(s4)
    800069c0:	97ea                	add	a5,a5,s10
    800069c2:	00ba95bb          	sllw	a1,s5,a1
    800069c6:	6b88                	ld	a0,16(a5)
    800069c8:	00000097          	auipc	ra,0x0
    800069cc:	e9a080e7          	jalr	-358(ra) # 80006862 <bd_print_vector>
    if(k > 0) {
    800069d0:	f9205ee3          	blez	s2,8000696c <bd_print+0x58>
      printf("  split:");
    800069d4:	8566                	mv	a0,s9
    800069d6:	ffffa097          	auipc	ra,0xffffa
    800069da:	bbc080e7          	jalr	-1092(ra) # 80000592 <printf>
      bd_print_vector(bd_sizes[k].split, NBLK(k));
    800069de:	0009a583          	lw	a1,0(s3)
    800069e2:	35fd                	addiw	a1,a1,-1
    800069e4:	412585bb          	subw	a1,a1,s2
    800069e8:	000a3783          	ld	a5,0(s4)
    800069ec:	9d3e                	add	s10,s10,a5
    800069ee:	00ba95bb          	sllw	a1,s5,a1
    800069f2:	018d3503          	ld	a0,24(s10)
    800069f6:	00000097          	auipc	ra,0x0
    800069fa:	e6c080e7          	jalr	-404(ra) # 80006862 <bd_print_vector>
    800069fe:	b7bd                	j	8000696c <bd_print+0x58>
    }
  }
}
    80006a00:	60e6                	ld	ra,88(sp)
    80006a02:	6446                	ld	s0,80(sp)
    80006a04:	64a6                	ld	s1,72(sp)
    80006a06:	6906                	ld	s2,64(sp)
    80006a08:	79e2                	ld	s3,56(sp)
    80006a0a:	7a42                	ld	s4,48(sp)
    80006a0c:	7aa2                	ld	s5,40(sp)
    80006a0e:	7b02                	ld	s6,32(sp)
    80006a10:	6be2                	ld	s7,24(sp)
    80006a12:	6c42                	ld	s8,16(sp)
    80006a14:	6ca2                	ld	s9,8(sp)
    80006a16:	6d02                	ld	s10,0(sp)
    80006a18:	6125                	addi	sp,sp,96
    80006a1a:	8082                	ret
    80006a1c:	8082                	ret

0000000080006a1e <firstk>:

// What is the first k such that 2^k >= n?
int
firstk(uint64 n) {
    80006a1e:	1141                	addi	sp,sp,-16
    80006a20:	e422                	sd	s0,8(sp)
    80006a22:	0800                	addi	s0,sp,16
  int k = 0;
  uint64 size = LEAF_SIZE;

  while (size < n) {
    80006a24:	47c1                	li	a5,16
    80006a26:	00a7fb63          	bgeu	a5,a0,80006a3c <firstk+0x1e>
    80006a2a:	872a                	mv	a4,a0
  int k = 0;
    80006a2c:	4501                	li	a0,0
    k++;
    80006a2e:	2505                	addiw	a0,a0,1
    size *= 2;
    80006a30:	0786                	slli	a5,a5,0x1
  while (size < n) {
    80006a32:	fee7eee3          	bltu	a5,a4,80006a2e <firstk+0x10>
  }
  return k;
}
    80006a36:	6422                	ld	s0,8(sp)
    80006a38:	0141                	addi	sp,sp,16
    80006a3a:	8082                	ret
  int k = 0;
    80006a3c:	4501                	li	a0,0
    80006a3e:	bfe5                	j	80006a36 <firstk+0x18>

0000000080006a40 <blk_index>:

// Compute the block index for address p at size k
int
blk_index(int k, char *p) {
    80006a40:	1141                	addi	sp,sp,-16
    80006a42:	e422                	sd	s0,8(sp)
    80006a44:	0800                	addi	s0,sp,16
  int n = p - (char *) bd_base;
  return n / BLK_SIZE(k);
    80006a46:	00023797          	auipc	a5,0x23
    80006a4a:	6027b783          	ld	a5,1538(a5) # 8002a048 <bd_base>
    80006a4e:	9d9d                	subw	a1,a1,a5
    80006a50:	47c1                	li	a5,16
    80006a52:	00a797b3          	sll	a5,a5,a0
    80006a56:	02f5c5b3          	div	a1,a1,a5
}
    80006a5a:	0005851b          	sext.w	a0,a1
    80006a5e:	6422                	ld	s0,8(sp)
    80006a60:	0141                	addi	sp,sp,16
    80006a62:	8082                	ret

0000000080006a64 <addr>:

// Convert a block index at size k back into an address
void *addr(int k, int bi) {
    80006a64:	1141                	addi	sp,sp,-16
    80006a66:	e422                	sd	s0,8(sp)
    80006a68:	0800                	addi	s0,sp,16
  int n = bi * BLK_SIZE(k);
    80006a6a:	47c1                	li	a5,16
    80006a6c:	00a797b3          	sll	a5,a5,a0
  return (char *) bd_base + n;
    80006a70:	02b787bb          	mulw	a5,a5,a1
}
    80006a74:	00023517          	auipc	a0,0x23
    80006a78:	5d453503          	ld	a0,1492(a0) # 8002a048 <bd_base>
    80006a7c:	953e                	add	a0,a0,a5
    80006a7e:	6422                	ld	s0,8(sp)
    80006a80:	0141                	addi	sp,sp,16
    80006a82:	8082                	ret

0000000080006a84 <bd_malloc>:

// allocate nbytes, but malloc won't return anything smaller than LEAF_SIZE
void *
bd_malloc(uint64 nbytes)
{
    80006a84:	7159                	addi	sp,sp,-112
    80006a86:	f486                	sd	ra,104(sp)
    80006a88:	f0a2                	sd	s0,96(sp)
    80006a8a:	eca6                	sd	s1,88(sp)
    80006a8c:	e8ca                	sd	s2,80(sp)
    80006a8e:	e4ce                	sd	s3,72(sp)
    80006a90:	e0d2                	sd	s4,64(sp)
    80006a92:	fc56                	sd	s5,56(sp)
    80006a94:	f85a                	sd	s6,48(sp)
    80006a96:	f45e                	sd	s7,40(sp)
    80006a98:	f062                	sd	s8,32(sp)
    80006a9a:	ec66                	sd	s9,24(sp)
    80006a9c:	e86a                	sd	s10,16(sp)
    80006a9e:	e46e                	sd	s11,8(sp)
    80006aa0:	1880                	addi	s0,sp,112
    80006aa2:	84aa                	mv	s1,a0
  int fk, k;

  acquire(&lock);
    80006aa4:	00023517          	auipc	a0,0x23
    80006aa8:	55c50513          	addi	a0,a0,1372 # 8002a000 <lock>
    80006aac:	ffffa097          	auipc	ra,0xffffa
    80006ab0:	012080e7          	jalr	18(ra) # 80000abe <acquire>

  // Find a free block >= nbytes, starting with smallest k possible
  fk = firstk(nbytes);
    80006ab4:	8526                	mv	a0,s1
    80006ab6:	00000097          	auipc	ra,0x0
    80006aba:	f68080e7          	jalr	-152(ra) # 80006a1e <firstk>
  for (k = fk; k < nsizes; k++) {
    80006abe:	00023797          	auipc	a5,0x23
    80006ac2:	59a7a783          	lw	a5,1434(a5) # 8002a058 <nsizes>
    80006ac6:	02f55d63          	bge	a0,a5,80006b00 <bd_malloc+0x7c>
    80006aca:	8c2a                	mv	s8,a0
    80006acc:	00551913          	slli	s2,a0,0x5
    80006ad0:	84aa                	mv	s1,a0
    if(!lst_empty(&bd_sizes[k].free))
    80006ad2:	00023997          	auipc	s3,0x23
    80006ad6:	57e98993          	addi	s3,s3,1406 # 8002a050 <bd_sizes>
  for (k = fk; k < nsizes; k++) {
    80006ada:	00023a17          	auipc	s4,0x23
    80006ade:	57ea0a13          	addi	s4,s4,1406 # 8002a058 <nsizes>
    if(!lst_empty(&bd_sizes[k].free))
    80006ae2:	0009b503          	ld	a0,0(s3)
    80006ae6:	954a                	add	a0,a0,s2
    80006ae8:	00001097          	auipc	ra,0x1
    80006aec:	894080e7          	jalr	-1900(ra) # 8000737c <lst_empty>
    80006af0:	c115                	beqz	a0,80006b14 <bd_malloc+0x90>
  for (k = fk; k < nsizes; k++) {
    80006af2:	2485                	addiw	s1,s1,1
    80006af4:	02090913          	addi	s2,s2,32
    80006af8:	000a2783          	lw	a5,0(s4)
    80006afc:	fef4c3e3          	blt	s1,a5,80006ae2 <bd_malloc+0x5e>
      break;
  }
  if(k >= nsizes) { // No free blocks?
    release(&lock);
    80006b00:	00023517          	auipc	a0,0x23
    80006b04:	50050513          	addi	a0,a0,1280 # 8002a000 <lock>
    80006b08:	ffffa097          	auipc	ra,0xffffa
    80006b0c:	01e080e7          	jalr	30(ra) # 80000b26 <release>
    return 0;
    80006b10:	4b01                	li	s6,0
    80006b12:	a0e1                	j	80006bda <bd_malloc+0x156>
  if(k >= nsizes) { // No free blocks?
    80006b14:	00023797          	auipc	a5,0x23
    80006b18:	5447a783          	lw	a5,1348(a5) # 8002a058 <nsizes>
    80006b1c:	fef4d2e3          	bge	s1,a5,80006b00 <bd_malloc+0x7c>
  }

  // Found a block; pop it and potentially split it.
  char *p = lst_pop(&bd_sizes[k].free);
    80006b20:	00549993          	slli	s3,s1,0x5
    80006b24:	00023917          	auipc	s2,0x23
    80006b28:	52c90913          	addi	s2,s2,1324 # 8002a050 <bd_sizes>
    80006b2c:	00093503          	ld	a0,0(s2)
    80006b30:	954e                	add	a0,a0,s3
    80006b32:	00001097          	auipc	ra,0x1
    80006b36:	876080e7          	jalr	-1930(ra) # 800073a8 <lst_pop>
    80006b3a:	8b2a                	mv	s6,a0
  return n / BLK_SIZE(k);
    80006b3c:	00023597          	auipc	a1,0x23
    80006b40:	50c5b583          	ld	a1,1292(a1) # 8002a048 <bd_base>
    80006b44:	40b505bb          	subw	a1,a0,a1
    80006b48:	47c1                	li	a5,16
    80006b4a:	009797b3          	sll	a5,a5,s1
    80006b4e:	02f5c5b3          	div	a1,a1,a5
  bit_set(bd_sizes[k].alloc, blk_index(k, p));
    80006b52:	00093783          	ld	a5,0(s2)
    80006b56:	97ce                	add	a5,a5,s3
    80006b58:	2581                	sext.w	a1,a1
    80006b5a:	6b88                	ld	a0,16(a5)
    80006b5c:	00000097          	auipc	ra,0x0
    80006b60:	ca2080e7          	jalr	-862(ra) # 800067fe <bit_set>
  for(; k > fk; k--) {
    80006b64:	069c5363          	bge	s8,s1,80006bca <bd_malloc+0x146>
    // split a block at size k and mark one half allocated at size k-1
    // and put the buddy on the free list at size k-1
    char *q = p + BLK_SIZE(k-1);   // p's buddy
    80006b68:	4bc1                	li	s7,16
    bit_set(bd_sizes[k].split, blk_index(k, p));
    80006b6a:	8dca                	mv	s11,s2
  int n = p - (char *) bd_base;
    80006b6c:	00023d17          	auipc	s10,0x23
    80006b70:	4dcd0d13          	addi	s10,s10,1244 # 8002a048 <bd_base>
    char *q = p + BLK_SIZE(k-1);   // p's buddy
    80006b74:	85a6                	mv	a1,s1
    80006b76:	34fd                	addiw	s1,s1,-1
    80006b78:	009b9ab3          	sll	s5,s7,s1
    80006b7c:	015b0cb3          	add	s9,s6,s5
    bit_set(bd_sizes[k].split, blk_index(k, p));
    80006b80:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
  int n = p - (char *) bd_base;
    80006b84:	000d3903          	ld	s2,0(s10)
  return n / BLK_SIZE(k);
    80006b88:	412b093b          	subw	s2,s6,s2
    80006b8c:	00bb95b3          	sll	a1,s7,a1
    80006b90:	02b945b3          	div	a1,s2,a1
    bit_set(bd_sizes[k].split, blk_index(k, p));
    80006b94:	013a07b3          	add	a5,s4,s3
    80006b98:	2581                	sext.w	a1,a1
    80006b9a:	6f88                	ld	a0,24(a5)
    80006b9c:	00000097          	auipc	ra,0x0
    80006ba0:	c62080e7          	jalr	-926(ra) # 800067fe <bit_set>
    bit_set(bd_sizes[k-1].alloc, blk_index(k-1, p));
    80006ba4:	1981                	addi	s3,s3,-32
    80006ba6:	9a4e                	add	s4,s4,s3
  return n / BLK_SIZE(k);
    80006ba8:	035945b3          	div	a1,s2,s5
    bit_set(bd_sizes[k-1].alloc, blk_index(k-1, p));
    80006bac:	2581                	sext.w	a1,a1
    80006bae:	010a3503          	ld	a0,16(s4)
    80006bb2:	00000097          	auipc	ra,0x0
    80006bb6:	c4c080e7          	jalr	-948(ra) # 800067fe <bit_set>
    lst_push(&bd_sizes[k-1].free, q);
    80006bba:	85e6                	mv	a1,s9
    80006bbc:	8552                	mv	a0,s4
    80006bbe:	00001097          	auipc	ra,0x1
    80006bc2:	820080e7          	jalr	-2016(ra) # 800073de <lst_push>
  for(; k > fk; k--) {
    80006bc6:	fb8497e3          	bne	s1,s8,80006b74 <bd_malloc+0xf0>
  }
  release(&lock);
    80006bca:	00023517          	auipc	a0,0x23
    80006bce:	43650513          	addi	a0,a0,1078 # 8002a000 <lock>
    80006bd2:	ffffa097          	auipc	ra,0xffffa
    80006bd6:	f54080e7          	jalr	-172(ra) # 80000b26 <release>

  return p;
}
    80006bda:	855a                	mv	a0,s6
    80006bdc:	70a6                	ld	ra,104(sp)
    80006bde:	7406                	ld	s0,96(sp)
    80006be0:	64e6                	ld	s1,88(sp)
    80006be2:	6946                	ld	s2,80(sp)
    80006be4:	69a6                	ld	s3,72(sp)
    80006be6:	6a06                	ld	s4,64(sp)
    80006be8:	7ae2                	ld	s5,56(sp)
    80006bea:	7b42                	ld	s6,48(sp)
    80006bec:	7ba2                	ld	s7,40(sp)
    80006bee:	7c02                	ld	s8,32(sp)
    80006bf0:	6ce2                	ld	s9,24(sp)
    80006bf2:	6d42                	ld	s10,16(sp)
    80006bf4:	6da2                	ld	s11,8(sp)
    80006bf6:	6165                	addi	sp,sp,112
    80006bf8:	8082                	ret

0000000080006bfa <size>:

// Find the size of the block that p points to.
int
size(char *p) {
    80006bfa:	7139                	addi	sp,sp,-64
    80006bfc:	fc06                	sd	ra,56(sp)
    80006bfe:	f822                	sd	s0,48(sp)
    80006c00:	f426                	sd	s1,40(sp)
    80006c02:	f04a                	sd	s2,32(sp)
    80006c04:	ec4e                	sd	s3,24(sp)
    80006c06:	e852                	sd	s4,16(sp)
    80006c08:	e456                	sd	s5,8(sp)
    80006c0a:	e05a                	sd	s6,0(sp)
    80006c0c:	0080                	addi	s0,sp,64
  for (int k = 0; k < nsizes; k++) {
    80006c0e:	00023a97          	auipc	s5,0x23
    80006c12:	44aaaa83          	lw	s5,1098(s5) # 8002a058 <nsizes>
  return n / BLK_SIZE(k);
    80006c16:	00023a17          	auipc	s4,0x23
    80006c1a:	432a3a03          	ld	s4,1074(s4) # 8002a048 <bd_base>
    80006c1e:	41450a3b          	subw	s4,a0,s4
    80006c22:	00023497          	auipc	s1,0x23
    80006c26:	42e4b483          	ld	s1,1070(s1) # 8002a050 <bd_sizes>
    80006c2a:	03848493          	addi	s1,s1,56
  for (int k = 0; k < nsizes; k++) {
    80006c2e:	4901                	li	s2,0
  return n / BLK_SIZE(k);
    80006c30:	4b41                	li	s6,16
  for (int k = 0; k < nsizes; k++) {
    80006c32:	03595363          	bge	s2,s5,80006c58 <size+0x5e>
    if(bit_isset(bd_sizes[k+1].split, blk_index(k+1, p))) {
    80006c36:	0019099b          	addiw	s3,s2,1
  return n / BLK_SIZE(k);
    80006c3a:	013b15b3          	sll	a1,s6,s3
    80006c3e:	02ba45b3          	div	a1,s4,a1
    if(bit_isset(bd_sizes[k+1].split, blk_index(k+1, p))) {
    80006c42:	2581                	sext.w	a1,a1
    80006c44:	6088                	ld	a0,0(s1)
    80006c46:	00000097          	auipc	ra,0x0
    80006c4a:	b80080e7          	jalr	-1152(ra) # 800067c6 <bit_isset>
    80006c4e:	02048493          	addi	s1,s1,32
    80006c52:	e501                	bnez	a0,80006c5a <size+0x60>
  for (int k = 0; k < nsizes; k++) {
    80006c54:	894e                	mv	s2,s3
    80006c56:	bff1                	j	80006c32 <size+0x38>
      return k;
    }
  }
  return 0;
    80006c58:	4901                	li	s2,0
}
    80006c5a:	854a                	mv	a0,s2
    80006c5c:	70e2                	ld	ra,56(sp)
    80006c5e:	7442                	ld	s0,48(sp)
    80006c60:	74a2                	ld	s1,40(sp)
    80006c62:	7902                	ld	s2,32(sp)
    80006c64:	69e2                	ld	s3,24(sp)
    80006c66:	6a42                	ld	s4,16(sp)
    80006c68:	6aa2                	ld	s5,8(sp)
    80006c6a:	6b02                	ld	s6,0(sp)
    80006c6c:	6121                	addi	sp,sp,64
    80006c6e:	8082                	ret

0000000080006c70 <bd_free>:

// Free memory pointed to by p, which was earlier allocated using
// bd_malloc.
void
bd_free(void *p) {
    80006c70:	7159                	addi	sp,sp,-112
    80006c72:	f486                	sd	ra,104(sp)
    80006c74:	f0a2                	sd	s0,96(sp)
    80006c76:	eca6                	sd	s1,88(sp)
    80006c78:	e8ca                	sd	s2,80(sp)
    80006c7a:	e4ce                	sd	s3,72(sp)
    80006c7c:	e0d2                	sd	s4,64(sp)
    80006c7e:	fc56                	sd	s5,56(sp)
    80006c80:	f85a                	sd	s6,48(sp)
    80006c82:	f45e                	sd	s7,40(sp)
    80006c84:	f062                	sd	s8,32(sp)
    80006c86:	ec66                	sd	s9,24(sp)
    80006c88:	e86a                	sd	s10,16(sp)
    80006c8a:	e46e                	sd	s11,8(sp)
    80006c8c:	1880                	addi	s0,sp,112
    80006c8e:	8aaa                	mv	s5,a0
  void *q;
  int k;

  acquire(&lock);
    80006c90:	00023517          	auipc	a0,0x23
    80006c94:	37050513          	addi	a0,a0,880 # 8002a000 <lock>
    80006c98:	ffffa097          	auipc	ra,0xffffa
    80006c9c:	e26080e7          	jalr	-474(ra) # 80000abe <acquire>
  for (k = size(p); k < MAXSIZE; k++) {
    80006ca0:	8556                	mv	a0,s5
    80006ca2:	00000097          	auipc	ra,0x0
    80006ca6:	f58080e7          	jalr	-168(ra) # 80006bfa <size>
    80006caa:	84aa                	mv	s1,a0
    80006cac:	00023797          	auipc	a5,0x23
    80006cb0:	3ac7a783          	lw	a5,940(a5) # 8002a058 <nsizes>
    80006cb4:	37fd                	addiw	a5,a5,-1
    80006cb6:	0cf55063          	bge	a0,a5,80006d76 <bd_free+0x106>
    80006cba:	00150a13          	addi	s4,a0,1
    80006cbe:	0a16                	slli	s4,s4,0x5
  int n = p - (char *) bd_base;
    80006cc0:	00023c17          	auipc	s8,0x23
    80006cc4:	388c0c13          	addi	s8,s8,904 # 8002a048 <bd_base>
  return n / BLK_SIZE(k);
    80006cc8:	4bc1                	li	s7,16
    int bi = blk_index(k, p);
    int buddy = (bi % 2 == 0) ? bi+1 : bi-1;
    bit_clear(bd_sizes[k].alloc, bi);  // free p at size k
    80006cca:	00023b17          	auipc	s6,0x23
    80006cce:	386b0b13          	addi	s6,s6,902 # 8002a050 <bd_sizes>
  for (k = size(p); k < MAXSIZE; k++) {
    80006cd2:	00023c97          	auipc	s9,0x23
    80006cd6:	386c8c93          	addi	s9,s9,902 # 8002a058 <nsizes>
    80006cda:	a82d                	j	80006d14 <bd_free+0xa4>
    int buddy = (bi % 2 == 0) ? bi+1 : bi-1;
    80006cdc:	fff58d9b          	addiw	s11,a1,-1
    80006ce0:	a881                	j	80006d30 <bd_free+0xc0>
    if(buddy % 2 == 0) {
      p = q;
    }
    // at size k+1, mark that the merged buddy pair isn't split
    // anymore
    bit_clear(bd_sizes[k+1].split, blk_index(k+1, p));
    80006ce2:	2485                	addiw	s1,s1,1
  int n = p - (char *) bd_base;
    80006ce4:	000c3583          	ld	a1,0(s8)
  return n / BLK_SIZE(k);
    80006ce8:	40ba85bb          	subw	a1,s5,a1
    80006cec:	009b97b3          	sll	a5,s7,s1
    80006cf0:	02f5c5b3          	div	a1,a1,a5
    bit_clear(bd_sizes[k+1].split, blk_index(k+1, p));
    80006cf4:	000b3783          	ld	a5,0(s6)
    80006cf8:	97d2                	add	a5,a5,s4
    80006cfa:	2581                	sext.w	a1,a1
    80006cfc:	6f88                	ld	a0,24(a5)
    80006cfe:	00000097          	auipc	ra,0x0
    80006d02:	b30080e7          	jalr	-1232(ra) # 8000682e <bit_clear>
  for (k = size(p); k < MAXSIZE; k++) {
    80006d06:	020a0a13          	addi	s4,s4,32
    80006d0a:	000ca783          	lw	a5,0(s9)
    80006d0e:	37fd                	addiw	a5,a5,-1
    80006d10:	06f4d363          	bge	s1,a5,80006d76 <bd_free+0x106>
  int n = p - (char *) bd_base;
    80006d14:	000c3903          	ld	s2,0(s8)
  return n / BLK_SIZE(k);
    80006d18:	009b99b3          	sll	s3,s7,s1
    80006d1c:	412a87bb          	subw	a5,s5,s2
    80006d20:	0337c7b3          	div	a5,a5,s3
    80006d24:	0007859b          	sext.w	a1,a5
    int buddy = (bi % 2 == 0) ? bi+1 : bi-1;
    80006d28:	8b85                	andi	a5,a5,1
    80006d2a:	fbcd                	bnez	a5,80006cdc <bd_free+0x6c>
    80006d2c:	00158d9b          	addiw	s11,a1,1
    bit_clear(bd_sizes[k].alloc, bi);  // free p at size k
    80006d30:	fe0a0d13          	addi	s10,s4,-32
    80006d34:	000b3783          	ld	a5,0(s6)
    80006d38:	9d3e                	add	s10,s10,a5
    80006d3a:	010d3503          	ld	a0,16(s10)
    80006d3e:	00000097          	auipc	ra,0x0
    80006d42:	af0080e7          	jalr	-1296(ra) # 8000682e <bit_clear>
    if (bit_isset(bd_sizes[k].alloc, buddy)) {  // is buddy allocated?
    80006d46:	85ee                	mv	a1,s11
    80006d48:	010d3503          	ld	a0,16(s10)
    80006d4c:	00000097          	auipc	ra,0x0
    80006d50:	a7a080e7          	jalr	-1414(ra) # 800067c6 <bit_isset>
    80006d54:	e10d                	bnez	a0,80006d76 <bd_free+0x106>
  int n = bi * BLK_SIZE(k);
    80006d56:	000d8d1b          	sext.w	s10,s11
  return (char *) bd_base + n;
    80006d5a:	03b989bb          	mulw	s3,s3,s11
    80006d5e:	994e                	add	s2,s2,s3
    lst_remove(q);    // remove buddy from free list
    80006d60:	854a                	mv	a0,s2
    80006d62:	00000097          	auipc	ra,0x0
    80006d66:	630080e7          	jalr	1584(ra) # 80007392 <lst_remove>
    if(buddy % 2 == 0) {
    80006d6a:	001d7d13          	andi	s10,s10,1
    80006d6e:	f60d1ae3          	bnez	s10,80006ce2 <bd_free+0x72>
      p = q;
    80006d72:	8aca                	mv	s5,s2
    80006d74:	b7bd                	j	80006ce2 <bd_free+0x72>
  }
  lst_push(&bd_sizes[k].free, p);
    80006d76:	0496                	slli	s1,s1,0x5
    80006d78:	85d6                	mv	a1,s5
    80006d7a:	00023517          	auipc	a0,0x23
    80006d7e:	2d653503          	ld	a0,726(a0) # 8002a050 <bd_sizes>
    80006d82:	9526                	add	a0,a0,s1
    80006d84:	00000097          	auipc	ra,0x0
    80006d88:	65a080e7          	jalr	1626(ra) # 800073de <lst_push>
  release(&lock);
    80006d8c:	00023517          	auipc	a0,0x23
    80006d90:	27450513          	addi	a0,a0,628 # 8002a000 <lock>
    80006d94:	ffffa097          	auipc	ra,0xffffa
    80006d98:	d92080e7          	jalr	-622(ra) # 80000b26 <release>
}
    80006d9c:	70a6                	ld	ra,104(sp)
    80006d9e:	7406                	ld	s0,96(sp)
    80006da0:	64e6                	ld	s1,88(sp)
    80006da2:	6946                	ld	s2,80(sp)
    80006da4:	69a6                	ld	s3,72(sp)
    80006da6:	6a06                	ld	s4,64(sp)
    80006da8:	7ae2                	ld	s5,56(sp)
    80006daa:	7b42                	ld	s6,48(sp)
    80006dac:	7ba2                	ld	s7,40(sp)
    80006dae:	7c02                	ld	s8,32(sp)
    80006db0:	6ce2                	ld	s9,24(sp)
    80006db2:	6d42                	ld	s10,16(sp)
    80006db4:	6da2                	ld	s11,8(sp)
    80006db6:	6165                	addi	sp,sp,112
    80006db8:	8082                	ret

0000000080006dba <blk_index_next>:

// Compute the first block at size k that doesn't contain p
int
blk_index_next(int k, char *p) {
    80006dba:	1141                	addi	sp,sp,-16
    80006dbc:	e422                	sd	s0,8(sp)
    80006dbe:	0800                	addi	s0,sp,16
  int n = (p - (char *) bd_base) / BLK_SIZE(k);
    80006dc0:	00023797          	auipc	a5,0x23
    80006dc4:	2887b783          	ld	a5,648(a5) # 8002a048 <bd_base>
    80006dc8:	8d9d                	sub	a1,a1,a5
    80006dca:	47c1                	li	a5,16
    80006dcc:	00a797b3          	sll	a5,a5,a0
    80006dd0:	02f5c533          	div	a0,a1,a5
    80006dd4:	2501                	sext.w	a0,a0
  if((p - (char*) bd_base) % BLK_SIZE(k) != 0)
    80006dd6:	02f5e5b3          	rem	a1,a1,a5
    80006dda:	c191                	beqz	a1,80006dde <blk_index_next+0x24>
      n++;
    80006ddc:	2505                	addiw	a0,a0,1
  return n ;
}
    80006dde:	6422                	ld	s0,8(sp)
    80006de0:	0141                	addi	sp,sp,16
    80006de2:	8082                	ret

0000000080006de4 <log2>:

int
log2(uint64 n) {
    80006de4:	1141                	addi	sp,sp,-16
    80006de6:	e422                	sd	s0,8(sp)
    80006de8:	0800                	addi	s0,sp,16
  int k = 0;
  while (n > 1) {
    80006dea:	4705                	li	a4,1
    80006dec:	00a77b63          	bgeu	a4,a0,80006e02 <log2+0x1e>
    80006df0:	87aa                	mv	a5,a0
  int k = 0;
    80006df2:	4501                	li	a0,0
    k++;
    80006df4:	2505                	addiw	a0,a0,1
    n = n >> 1;
    80006df6:	8385                	srli	a5,a5,0x1
  while (n > 1) {
    80006df8:	fef76ee3          	bltu	a4,a5,80006df4 <log2+0x10>
  }
  return k;
}
    80006dfc:	6422                	ld	s0,8(sp)
    80006dfe:	0141                	addi	sp,sp,16
    80006e00:	8082                	ret
  int k = 0;
    80006e02:	4501                	li	a0,0
    80006e04:	bfe5                	j	80006dfc <log2+0x18>

0000000080006e06 <bd_mark>:

// Mark memory from [start, stop), starting at size 0, as allocated. 
void
bd_mark(void *start, void *stop)
{
    80006e06:	711d                	addi	sp,sp,-96
    80006e08:	ec86                	sd	ra,88(sp)
    80006e0a:	e8a2                	sd	s0,80(sp)
    80006e0c:	e4a6                	sd	s1,72(sp)
    80006e0e:	e0ca                	sd	s2,64(sp)
    80006e10:	fc4e                	sd	s3,56(sp)
    80006e12:	f852                	sd	s4,48(sp)
    80006e14:	f456                	sd	s5,40(sp)
    80006e16:	f05a                	sd	s6,32(sp)
    80006e18:	ec5e                	sd	s7,24(sp)
    80006e1a:	e862                	sd	s8,16(sp)
    80006e1c:	e466                	sd	s9,8(sp)
    80006e1e:	e06a                	sd	s10,0(sp)
    80006e20:	1080                	addi	s0,sp,96
  int bi, bj;

  if (((uint64) start % LEAF_SIZE != 0) || ((uint64) stop % LEAF_SIZE != 0))
    80006e22:	00b56933          	or	s2,a0,a1
    80006e26:	00f97913          	andi	s2,s2,15
    80006e2a:	04091263          	bnez	s2,80006e6e <bd_mark+0x68>
    80006e2e:	8b2a                	mv	s6,a0
    80006e30:	8bae                	mv	s7,a1
    panic("bd_mark");

  for (int k = 0; k < nsizes; k++) {
    80006e32:	00023c17          	auipc	s8,0x23
    80006e36:	226c2c03          	lw	s8,550(s8) # 8002a058 <nsizes>
    80006e3a:	4981                	li	s3,0
  int n = p - (char *) bd_base;
    80006e3c:	00023d17          	auipc	s10,0x23
    80006e40:	20cd0d13          	addi	s10,s10,524 # 8002a048 <bd_base>
  return n / BLK_SIZE(k);
    80006e44:	4cc1                	li	s9,16
    bi = blk_index(k, start);
    bj = blk_index_next(k, stop);
    for(; bi < bj; bi++) {
      if(k > 0) {
        // if a block is allocated at size k, mark it as split too.
        bit_set(bd_sizes[k].split, bi);
    80006e46:	00023a97          	auipc	s5,0x23
    80006e4a:	20aa8a93          	addi	s5,s5,522 # 8002a050 <bd_sizes>
  for (int k = 0; k < nsizes; k++) {
    80006e4e:	07804563          	bgtz	s8,80006eb8 <bd_mark+0xb2>
      }
      bit_set(bd_sizes[k].alloc, bi);
    }
  }
}
    80006e52:	60e6                	ld	ra,88(sp)
    80006e54:	6446                	ld	s0,80(sp)
    80006e56:	64a6                	ld	s1,72(sp)
    80006e58:	6906                	ld	s2,64(sp)
    80006e5a:	79e2                	ld	s3,56(sp)
    80006e5c:	7a42                	ld	s4,48(sp)
    80006e5e:	7aa2                	ld	s5,40(sp)
    80006e60:	7b02                	ld	s6,32(sp)
    80006e62:	6be2                	ld	s7,24(sp)
    80006e64:	6c42                	ld	s8,16(sp)
    80006e66:	6ca2                	ld	s9,8(sp)
    80006e68:	6d02                	ld	s10,0(sp)
    80006e6a:	6125                	addi	sp,sp,96
    80006e6c:	8082                	ret
    panic("bd_mark");
    80006e6e:	00002517          	auipc	a0,0x2
    80006e72:	b3250513          	addi	a0,a0,-1230 # 800089a0 <userret+0x910>
    80006e76:	ffff9097          	auipc	ra,0xffff9
    80006e7a:	6d2080e7          	jalr	1746(ra) # 80000548 <panic>
      bit_set(bd_sizes[k].alloc, bi);
    80006e7e:	000ab783          	ld	a5,0(s5)
    80006e82:	97ca                	add	a5,a5,s2
    80006e84:	85a6                	mv	a1,s1
    80006e86:	6b88                	ld	a0,16(a5)
    80006e88:	00000097          	auipc	ra,0x0
    80006e8c:	976080e7          	jalr	-1674(ra) # 800067fe <bit_set>
    for(; bi < bj; bi++) {
    80006e90:	2485                	addiw	s1,s1,1
    80006e92:	009a0e63          	beq	s4,s1,80006eae <bd_mark+0xa8>
      if(k > 0) {
    80006e96:	ff3054e3          	blez	s3,80006e7e <bd_mark+0x78>
        bit_set(bd_sizes[k].split, bi);
    80006e9a:	000ab783          	ld	a5,0(s5)
    80006e9e:	97ca                	add	a5,a5,s2
    80006ea0:	85a6                	mv	a1,s1
    80006ea2:	6f88                	ld	a0,24(a5)
    80006ea4:	00000097          	auipc	ra,0x0
    80006ea8:	95a080e7          	jalr	-1702(ra) # 800067fe <bit_set>
    80006eac:	bfc9                	j	80006e7e <bd_mark+0x78>
  for (int k = 0; k < nsizes; k++) {
    80006eae:	2985                	addiw	s3,s3,1
    80006eb0:	02090913          	addi	s2,s2,32
    80006eb4:	f9898fe3          	beq	s3,s8,80006e52 <bd_mark+0x4c>
  int n = p - (char *) bd_base;
    80006eb8:	000d3483          	ld	s1,0(s10)
  return n / BLK_SIZE(k);
    80006ebc:	409b04bb          	subw	s1,s6,s1
    80006ec0:	013c97b3          	sll	a5,s9,s3
    80006ec4:	02f4c4b3          	div	s1,s1,a5
    80006ec8:	2481                	sext.w	s1,s1
    bj = blk_index_next(k, stop);
    80006eca:	85de                	mv	a1,s7
    80006ecc:	854e                	mv	a0,s3
    80006ece:	00000097          	auipc	ra,0x0
    80006ed2:	eec080e7          	jalr	-276(ra) # 80006dba <blk_index_next>
    80006ed6:	8a2a                	mv	s4,a0
    for(; bi < bj; bi++) {
    80006ed8:	faa4cfe3          	blt	s1,a0,80006e96 <bd_mark+0x90>
    80006edc:	bfc9                	j	80006eae <bd_mark+0xa8>

0000000080006ede <bd_initfree_pair>:

// If a block is marked as allocated and the buddy is free, put the
// buddy on the free list at size k.
int
bd_initfree_pair(int k, int bi) {
    80006ede:	7139                	addi	sp,sp,-64
    80006ee0:	fc06                	sd	ra,56(sp)
    80006ee2:	f822                	sd	s0,48(sp)
    80006ee4:	f426                	sd	s1,40(sp)
    80006ee6:	f04a                	sd	s2,32(sp)
    80006ee8:	ec4e                	sd	s3,24(sp)
    80006eea:	e852                	sd	s4,16(sp)
    80006eec:	e456                	sd	s5,8(sp)
    80006eee:	e05a                	sd	s6,0(sp)
    80006ef0:	0080                	addi	s0,sp,64
    80006ef2:	89aa                	mv	s3,a0
  int buddy = (bi % 2 == 0) ? bi+1 : bi-1;
    80006ef4:	00058a9b          	sext.w	s5,a1
    80006ef8:	0015f793          	andi	a5,a1,1
    80006efc:	ebad                	bnez	a5,80006f6e <bd_initfree_pair+0x90>
    80006efe:	00158a1b          	addiw	s4,a1,1
  int free = 0;
  if(bit_isset(bd_sizes[k].alloc, bi) !=  bit_isset(bd_sizes[k].alloc, buddy)) {
    80006f02:	00599493          	slli	s1,s3,0x5
    80006f06:	00023797          	auipc	a5,0x23
    80006f0a:	14a7b783          	ld	a5,330(a5) # 8002a050 <bd_sizes>
    80006f0e:	94be                	add	s1,s1,a5
    80006f10:	0104bb03          	ld	s6,16(s1)
    80006f14:	855a                	mv	a0,s6
    80006f16:	00000097          	auipc	ra,0x0
    80006f1a:	8b0080e7          	jalr	-1872(ra) # 800067c6 <bit_isset>
    80006f1e:	892a                	mv	s2,a0
    80006f20:	85d2                	mv	a1,s4
    80006f22:	855a                	mv	a0,s6
    80006f24:	00000097          	auipc	ra,0x0
    80006f28:	8a2080e7          	jalr	-1886(ra) # 800067c6 <bit_isset>
  int free = 0;
    80006f2c:	4b01                	li	s6,0
  if(bit_isset(bd_sizes[k].alloc, bi) !=  bit_isset(bd_sizes[k].alloc, buddy)) {
    80006f2e:	02a90563          	beq	s2,a0,80006f58 <bd_initfree_pair+0x7a>
    // one of the pair is free
    free = BLK_SIZE(k);
    80006f32:	45c1                	li	a1,16
    80006f34:	013599b3          	sll	s3,a1,s3
    80006f38:	00098b1b          	sext.w	s6,s3
    if(bit_isset(bd_sizes[k].alloc, bi))
    80006f3c:	02090c63          	beqz	s2,80006f74 <bd_initfree_pair+0x96>
  return (char *) bd_base + n;
    80006f40:	034989bb          	mulw	s3,s3,s4
      lst_push(&bd_sizes[k].free, addr(k, buddy));   // put buddy on free list
    80006f44:	00023597          	auipc	a1,0x23
    80006f48:	1045b583          	ld	a1,260(a1) # 8002a048 <bd_base>
    80006f4c:	95ce                	add	a1,a1,s3
    80006f4e:	8526                	mv	a0,s1
    80006f50:	00000097          	auipc	ra,0x0
    80006f54:	48e080e7          	jalr	1166(ra) # 800073de <lst_push>
    else
      lst_push(&bd_sizes[k].free, addr(k, bi));      // put bi on free list
  }
  return free;
}
    80006f58:	855a                	mv	a0,s6
    80006f5a:	70e2                	ld	ra,56(sp)
    80006f5c:	7442                	ld	s0,48(sp)
    80006f5e:	74a2                	ld	s1,40(sp)
    80006f60:	7902                	ld	s2,32(sp)
    80006f62:	69e2                	ld	s3,24(sp)
    80006f64:	6a42                	ld	s4,16(sp)
    80006f66:	6aa2                	ld	s5,8(sp)
    80006f68:	6b02                	ld	s6,0(sp)
    80006f6a:	6121                	addi	sp,sp,64
    80006f6c:	8082                	ret
  int buddy = (bi % 2 == 0) ? bi+1 : bi-1;
    80006f6e:	fff58a1b          	addiw	s4,a1,-1
    80006f72:	bf41                	j	80006f02 <bd_initfree_pair+0x24>
  return (char *) bd_base + n;
    80006f74:	035989bb          	mulw	s3,s3,s5
      lst_push(&bd_sizes[k].free, addr(k, bi));      // put bi on free list
    80006f78:	00023597          	auipc	a1,0x23
    80006f7c:	0d05b583          	ld	a1,208(a1) # 8002a048 <bd_base>
    80006f80:	95ce                	add	a1,a1,s3
    80006f82:	8526                	mv	a0,s1
    80006f84:	00000097          	auipc	ra,0x0
    80006f88:	45a080e7          	jalr	1114(ra) # 800073de <lst_push>
    80006f8c:	b7f1                	j	80006f58 <bd_initfree_pair+0x7a>

0000000080006f8e <bd_initfree>:
  
// Initialize the free lists for each size k.  For each size k, there
// are only two pairs that may have a buddy that should be on free list:
// bd_left and bd_right.
int
bd_initfree(void *bd_left, void *bd_right) {
    80006f8e:	711d                	addi	sp,sp,-96
    80006f90:	ec86                	sd	ra,88(sp)
    80006f92:	e8a2                	sd	s0,80(sp)
    80006f94:	e4a6                	sd	s1,72(sp)
    80006f96:	e0ca                	sd	s2,64(sp)
    80006f98:	fc4e                	sd	s3,56(sp)
    80006f9a:	f852                	sd	s4,48(sp)
    80006f9c:	f456                	sd	s5,40(sp)
    80006f9e:	f05a                	sd	s6,32(sp)
    80006fa0:	ec5e                	sd	s7,24(sp)
    80006fa2:	e862                	sd	s8,16(sp)
    80006fa4:	e466                	sd	s9,8(sp)
    80006fa6:	e06a                	sd	s10,0(sp)
    80006fa8:	1080                	addi	s0,sp,96
  int free = 0;

  for (int k = 0; k < MAXSIZE; k++) {   // skip max size
    80006faa:	00023717          	auipc	a4,0x23
    80006fae:	0ae72703          	lw	a4,174(a4) # 8002a058 <nsizes>
    80006fb2:	4785                	li	a5,1
    80006fb4:	06e7db63          	bge	a5,a4,8000702a <bd_initfree+0x9c>
    80006fb8:	8aaa                	mv	s5,a0
    80006fba:	8b2e                	mv	s6,a1
    80006fbc:	4901                	li	s2,0
  int free = 0;
    80006fbe:	4a01                	li	s4,0
  int n = p - (char *) bd_base;
    80006fc0:	00023c97          	auipc	s9,0x23
    80006fc4:	088c8c93          	addi	s9,s9,136 # 8002a048 <bd_base>
  return n / BLK_SIZE(k);
    80006fc8:	4c41                	li	s8,16
  for (int k = 0; k < MAXSIZE; k++) {   // skip max size
    80006fca:	00023b97          	auipc	s7,0x23
    80006fce:	08eb8b93          	addi	s7,s7,142 # 8002a058 <nsizes>
    80006fd2:	a039                	j	80006fe0 <bd_initfree+0x52>
    80006fd4:	2905                	addiw	s2,s2,1
    80006fd6:	000ba783          	lw	a5,0(s7)
    80006fda:	37fd                	addiw	a5,a5,-1
    80006fdc:	04f95863          	bge	s2,a5,8000702c <bd_initfree+0x9e>
    int left = blk_index_next(k, bd_left);
    80006fe0:	85d6                	mv	a1,s5
    80006fe2:	854a                	mv	a0,s2
    80006fe4:	00000097          	auipc	ra,0x0
    80006fe8:	dd6080e7          	jalr	-554(ra) # 80006dba <blk_index_next>
    80006fec:	89aa                	mv	s3,a0
  int n = p - (char *) bd_base;
    80006fee:	000cb483          	ld	s1,0(s9)
  return n / BLK_SIZE(k);
    80006ff2:	409b04bb          	subw	s1,s6,s1
    80006ff6:	012c17b3          	sll	a5,s8,s2
    80006ffa:	02f4c4b3          	div	s1,s1,a5
    80006ffe:	2481                	sext.w	s1,s1
    int right = blk_index(k, bd_right);
    free += bd_initfree_pair(k, left);
    80007000:	85aa                	mv	a1,a0
    80007002:	854a                	mv	a0,s2
    80007004:	00000097          	auipc	ra,0x0
    80007008:	eda080e7          	jalr	-294(ra) # 80006ede <bd_initfree_pair>
    8000700c:	01450d3b          	addw	s10,a0,s4
    80007010:	000d0a1b          	sext.w	s4,s10
    if(right <= left)
    80007014:	fc99d0e3          	bge	s3,s1,80006fd4 <bd_initfree+0x46>
      continue;
    free += bd_initfree_pair(k, right);
    80007018:	85a6                	mv	a1,s1
    8000701a:	854a                	mv	a0,s2
    8000701c:	00000097          	auipc	ra,0x0
    80007020:	ec2080e7          	jalr	-318(ra) # 80006ede <bd_initfree_pair>
    80007024:	00ad0a3b          	addw	s4,s10,a0
    80007028:	b775                	j	80006fd4 <bd_initfree+0x46>
  int free = 0;
    8000702a:	4a01                	li	s4,0
  }
  return free;
}
    8000702c:	8552                	mv	a0,s4
    8000702e:	60e6                	ld	ra,88(sp)
    80007030:	6446                	ld	s0,80(sp)
    80007032:	64a6                	ld	s1,72(sp)
    80007034:	6906                	ld	s2,64(sp)
    80007036:	79e2                	ld	s3,56(sp)
    80007038:	7a42                	ld	s4,48(sp)
    8000703a:	7aa2                	ld	s5,40(sp)
    8000703c:	7b02                	ld	s6,32(sp)
    8000703e:	6be2                	ld	s7,24(sp)
    80007040:	6c42                	ld	s8,16(sp)
    80007042:	6ca2                	ld	s9,8(sp)
    80007044:	6d02                	ld	s10,0(sp)
    80007046:	6125                	addi	sp,sp,96
    80007048:	8082                	ret

000000008000704a <bd_mark_data_structures>:

// Mark the range [bd_base,p) as allocated
int
bd_mark_data_structures(char *p) {
    8000704a:	7179                	addi	sp,sp,-48
    8000704c:	f406                	sd	ra,40(sp)
    8000704e:	f022                	sd	s0,32(sp)
    80007050:	ec26                	sd	s1,24(sp)
    80007052:	e84a                	sd	s2,16(sp)
    80007054:	e44e                	sd	s3,8(sp)
    80007056:	1800                	addi	s0,sp,48
    80007058:	892a                	mv	s2,a0
  int meta = p - (char*)bd_base;
    8000705a:	00023997          	auipc	s3,0x23
    8000705e:	fee98993          	addi	s3,s3,-18 # 8002a048 <bd_base>
    80007062:	0009b483          	ld	s1,0(s3)
    80007066:	409504bb          	subw	s1,a0,s1
  printf("bd: %d meta bytes for managing %d bytes of memory\n", meta, BLK_SIZE(MAXSIZE));
    8000706a:	00023797          	auipc	a5,0x23
    8000706e:	fee7a783          	lw	a5,-18(a5) # 8002a058 <nsizes>
    80007072:	37fd                	addiw	a5,a5,-1
    80007074:	4641                	li	a2,16
    80007076:	00f61633          	sll	a2,a2,a5
    8000707a:	85a6                	mv	a1,s1
    8000707c:	00002517          	auipc	a0,0x2
    80007080:	92c50513          	addi	a0,a0,-1748 # 800089a8 <userret+0x918>
    80007084:	ffff9097          	auipc	ra,0xffff9
    80007088:	50e080e7          	jalr	1294(ra) # 80000592 <printf>
  bd_mark(bd_base, p);
    8000708c:	85ca                	mv	a1,s2
    8000708e:	0009b503          	ld	a0,0(s3)
    80007092:	00000097          	auipc	ra,0x0
    80007096:	d74080e7          	jalr	-652(ra) # 80006e06 <bd_mark>
  return meta;
}
    8000709a:	8526                	mv	a0,s1
    8000709c:	70a2                	ld	ra,40(sp)
    8000709e:	7402                	ld	s0,32(sp)
    800070a0:	64e2                	ld	s1,24(sp)
    800070a2:	6942                	ld	s2,16(sp)
    800070a4:	69a2                	ld	s3,8(sp)
    800070a6:	6145                	addi	sp,sp,48
    800070a8:	8082                	ret

00000000800070aa <bd_mark_unavailable>:

// Mark the range [end, HEAPSIZE) as allocated
int
bd_mark_unavailable(void *end, void *left) {
    800070aa:	1101                	addi	sp,sp,-32
    800070ac:	ec06                	sd	ra,24(sp)
    800070ae:	e822                	sd	s0,16(sp)
    800070b0:	e426                	sd	s1,8(sp)
    800070b2:	1000                	addi	s0,sp,32
  int unavailable = BLK_SIZE(MAXSIZE)-(end-bd_base);
    800070b4:	00023497          	auipc	s1,0x23
    800070b8:	fa44a483          	lw	s1,-92(s1) # 8002a058 <nsizes>
    800070bc:	fff4879b          	addiw	a5,s1,-1
    800070c0:	44c1                	li	s1,16
    800070c2:	00f494b3          	sll	s1,s1,a5
    800070c6:	00023797          	auipc	a5,0x23
    800070ca:	f827b783          	ld	a5,-126(a5) # 8002a048 <bd_base>
    800070ce:	8d1d                	sub	a0,a0,a5
    800070d0:	40a4853b          	subw	a0,s1,a0
    800070d4:	0005049b          	sext.w	s1,a0
  if(unavailable > 0)
    800070d8:	00905a63          	blez	s1,800070ec <bd_mark_unavailable+0x42>
    unavailable = ROUNDUP(unavailable, LEAF_SIZE);
    800070dc:	357d                	addiw	a0,a0,-1
    800070de:	41f5549b          	sraiw	s1,a0,0x1f
    800070e2:	01c4d49b          	srliw	s1,s1,0x1c
    800070e6:	9ca9                	addw	s1,s1,a0
    800070e8:	98c1                	andi	s1,s1,-16
    800070ea:	24c1                	addiw	s1,s1,16
  printf("bd: 0x%x bytes unavailable\n", unavailable);
    800070ec:	85a6                	mv	a1,s1
    800070ee:	00002517          	auipc	a0,0x2
    800070f2:	8f250513          	addi	a0,a0,-1806 # 800089e0 <userret+0x950>
    800070f6:	ffff9097          	auipc	ra,0xffff9
    800070fa:	49c080e7          	jalr	1180(ra) # 80000592 <printf>

  void *bd_end = bd_base+BLK_SIZE(MAXSIZE)-unavailable;
    800070fe:	00023717          	auipc	a4,0x23
    80007102:	f4a73703          	ld	a4,-182(a4) # 8002a048 <bd_base>
    80007106:	00023597          	auipc	a1,0x23
    8000710a:	f525a583          	lw	a1,-174(a1) # 8002a058 <nsizes>
    8000710e:	fff5879b          	addiw	a5,a1,-1
    80007112:	45c1                	li	a1,16
    80007114:	00f595b3          	sll	a1,a1,a5
    80007118:	40958533          	sub	a0,a1,s1
  bd_mark(bd_end, bd_base+BLK_SIZE(MAXSIZE));
    8000711c:	95ba                	add	a1,a1,a4
    8000711e:	953a                	add	a0,a0,a4
    80007120:	00000097          	auipc	ra,0x0
    80007124:	ce6080e7          	jalr	-794(ra) # 80006e06 <bd_mark>
  return unavailable;
}
    80007128:	8526                	mv	a0,s1
    8000712a:	60e2                	ld	ra,24(sp)
    8000712c:	6442                	ld	s0,16(sp)
    8000712e:	64a2                	ld	s1,8(sp)
    80007130:	6105                	addi	sp,sp,32
    80007132:	8082                	ret

0000000080007134 <bd_init>:

// Initialize the buddy allocator: it manages memory from [base, end).
void
bd_init(void *base, void *end) {
    80007134:	715d                	addi	sp,sp,-80
    80007136:	e486                	sd	ra,72(sp)
    80007138:	e0a2                	sd	s0,64(sp)
    8000713a:	fc26                	sd	s1,56(sp)
    8000713c:	f84a                	sd	s2,48(sp)
    8000713e:	f44e                	sd	s3,40(sp)
    80007140:	f052                	sd	s4,32(sp)
    80007142:	ec56                	sd	s5,24(sp)
    80007144:	e85a                	sd	s6,16(sp)
    80007146:	e45e                	sd	s7,8(sp)
    80007148:	e062                	sd	s8,0(sp)
    8000714a:	0880                	addi	s0,sp,80
    8000714c:	8c2e                	mv	s8,a1
  char *p = (char *) ROUNDUP((uint64)base, LEAF_SIZE);
    8000714e:	fff50493          	addi	s1,a0,-1
    80007152:	98c1                	andi	s1,s1,-16
    80007154:	04c1                	addi	s1,s1,16
  int sz;

  initlock(&lock, "buddy");
    80007156:	00002597          	auipc	a1,0x2
    8000715a:	8aa58593          	addi	a1,a1,-1878 # 80008a00 <userret+0x970>
    8000715e:	00023517          	auipc	a0,0x23
    80007162:	ea250513          	addi	a0,a0,-350 # 8002a000 <lock>
    80007166:	ffffa097          	auipc	ra,0xffffa
    8000716a:	84a080e7          	jalr	-1974(ra) # 800009b0 <initlock>
  bd_base = (void *) p;
    8000716e:	00023797          	auipc	a5,0x23
    80007172:	ec97bd23          	sd	s1,-294(a5) # 8002a048 <bd_base>

  // compute the number of sizes we need to manage [base, end)
  nsizes = log2(((char *)end-p)/LEAF_SIZE) + 1;
    80007176:	409c0933          	sub	s2,s8,s1
    8000717a:	43f95513          	srai	a0,s2,0x3f
    8000717e:	893d                	andi	a0,a0,15
    80007180:	954a                	add	a0,a0,s2
    80007182:	8511                	srai	a0,a0,0x4
    80007184:	00000097          	auipc	ra,0x0
    80007188:	c60080e7          	jalr	-928(ra) # 80006de4 <log2>
  if((char*)end-p > BLK_SIZE(MAXSIZE)) {
    8000718c:	47c1                	li	a5,16
    8000718e:	00a797b3          	sll	a5,a5,a0
    80007192:	1b27c663          	blt	a5,s2,8000733e <bd_init+0x20a>
  nsizes = log2(((char *)end-p)/LEAF_SIZE) + 1;
    80007196:	2505                	addiw	a0,a0,1
    80007198:	00023797          	auipc	a5,0x23
    8000719c:	eca7a023          	sw	a0,-320(a5) # 8002a058 <nsizes>
    nsizes++;  // round up to the next power of 2
  }

  printf("bd: memory sz is %d bytes; allocate an size array of length %d\n",
    800071a0:	00023997          	auipc	s3,0x23
    800071a4:	eb898993          	addi	s3,s3,-328 # 8002a058 <nsizes>
    800071a8:	0009a603          	lw	a2,0(s3)
    800071ac:	85ca                	mv	a1,s2
    800071ae:	00002517          	auipc	a0,0x2
    800071b2:	85a50513          	addi	a0,a0,-1958 # 80008a08 <userret+0x978>
    800071b6:	ffff9097          	auipc	ra,0xffff9
    800071ba:	3dc080e7          	jalr	988(ra) # 80000592 <printf>
         (char*) end - p, nsizes);

  // allocate bd_sizes array
  bd_sizes = (Sz_info *) p;
    800071be:	00023797          	auipc	a5,0x23
    800071c2:	e897b923          	sd	s1,-366(a5) # 8002a050 <bd_sizes>
  p += sizeof(Sz_info) * nsizes;
    800071c6:	0009a603          	lw	a2,0(s3)
    800071ca:	00561913          	slli	s2,a2,0x5
    800071ce:	9926                	add	s2,s2,s1
  memset(bd_sizes, 0, sizeof(Sz_info) * nsizes);
    800071d0:	0056161b          	slliw	a2,a2,0x5
    800071d4:	4581                	li	a1,0
    800071d6:	8526                	mv	a0,s1
    800071d8:	ffffa097          	auipc	ra,0xffffa
    800071dc:	9aa080e7          	jalr	-1622(ra) # 80000b82 <memset>

  // initialize free list and allocate the alloc array for each size k
  for (int k = 0; k < nsizes; k++) {
    800071e0:	0009a783          	lw	a5,0(s3)
    800071e4:	06f05a63          	blez	a5,80007258 <bd_init+0x124>
    800071e8:	4981                	li	s3,0
    lst_init(&bd_sizes[k].free);
    800071ea:	00023a97          	auipc	s5,0x23
    800071ee:	e66a8a93          	addi	s5,s5,-410 # 8002a050 <bd_sizes>
    sz = sizeof(char)* ROUNDUP(NBLK(k), 8)/8;
    800071f2:	00023a17          	auipc	s4,0x23
    800071f6:	e66a0a13          	addi	s4,s4,-410 # 8002a058 <nsizes>
    800071fa:	4b05                	li	s6,1
    lst_init(&bd_sizes[k].free);
    800071fc:	00599b93          	slli	s7,s3,0x5
    80007200:	000ab503          	ld	a0,0(s5)
    80007204:	955e                	add	a0,a0,s7
    80007206:	00000097          	auipc	ra,0x0
    8000720a:	166080e7          	jalr	358(ra) # 8000736c <lst_init>
    sz = sizeof(char)* ROUNDUP(NBLK(k), 8)/8;
    8000720e:	000a2483          	lw	s1,0(s4)
    80007212:	34fd                	addiw	s1,s1,-1
    80007214:	413484bb          	subw	s1,s1,s3
    80007218:	009b14bb          	sllw	s1,s6,s1
    8000721c:	fff4879b          	addiw	a5,s1,-1
    80007220:	41f7d49b          	sraiw	s1,a5,0x1f
    80007224:	01d4d49b          	srliw	s1,s1,0x1d
    80007228:	9cbd                	addw	s1,s1,a5
    8000722a:	98e1                	andi	s1,s1,-8
    8000722c:	24a1                	addiw	s1,s1,8
    bd_sizes[k].alloc = p;
    8000722e:	000ab783          	ld	a5,0(s5)
    80007232:	9bbe                	add	s7,s7,a5
    80007234:	012bb823          	sd	s2,16(s7)
    memset(bd_sizes[k].alloc, 0, sz);
    80007238:	848d                	srai	s1,s1,0x3
    8000723a:	8626                	mv	a2,s1
    8000723c:	4581                	li	a1,0
    8000723e:	854a                	mv	a0,s2
    80007240:	ffffa097          	auipc	ra,0xffffa
    80007244:	942080e7          	jalr	-1726(ra) # 80000b82 <memset>
    p += sz;
    80007248:	9926                	add	s2,s2,s1
  for (int k = 0; k < nsizes; k++) {
    8000724a:	0985                	addi	s3,s3,1
    8000724c:	000a2703          	lw	a4,0(s4)
    80007250:	0009879b          	sext.w	a5,s3
    80007254:	fae7c4e3          	blt	a5,a4,800071fc <bd_init+0xc8>
  }

  // allocate the split array for each size k, except for k = 0, since
  // we will not split blocks of size k = 0, the smallest size.
  for (int k = 1; k < nsizes; k++) {
    80007258:	00023797          	auipc	a5,0x23
    8000725c:	e007a783          	lw	a5,-512(a5) # 8002a058 <nsizes>
    80007260:	4705                	li	a4,1
    80007262:	06f75163          	bge	a4,a5,800072c4 <bd_init+0x190>
    80007266:	02000a13          	li	s4,32
    8000726a:	4985                	li	s3,1
    sz = sizeof(char)* (ROUNDUP(NBLK(k), 8))/8;
    8000726c:	4b85                	li	s7,1
    bd_sizes[k].split = p;
    8000726e:	00023b17          	auipc	s6,0x23
    80007272:	de2b0b13          	addi	s6,s6,-542 # 8002a050 <bd_sizes>
  for (int k = 1; k < nsizes; k++) {
    80007276:	00023a97          	auipc	s5,0x23
    8000727a:	de2a8a93          	addi	s5,s5,-542 # 8002a058 <nsizes>
    sz = sizeof(char)* (ROUNDUP(NBLK(k), 8))/8;
    8000727e:	37fd                	addiw	a5,a5,-1
    80007280:	413787bb          	subw	a5,a5,s3
    80007284:	00fb94bb          	sllw	s1,s7,a5
    80007288:	fff4879b          	addiw	a5,s1,-1
    8000728c:	41f7d49b          	sraiw	s1,a5,0x1f
    80007290:	01d4d49b          	srliw	s1,s1,0x1d
    80007294:	9cbd                	addw	s1,s1,a5
    80007296:	98e1                	andi	s1,s1,-8
    80007298:	24a1                	addiw	s1,s1,8
    bd_sizes[k].split = p;
    8000729a:	000b3783          	ld	a5,0(s6)
    8000729e:	97d2                	add	a5,a5,s4
    800072a0:	0127bc23          	sd	s2,24(a5)
    memset(bd_sizes[k].split, 0, sz);
    800072a4:	848d                	srai	s1,s1,0x3
    800072a6:	8626                	mv	a2,s1
    800072a8:	4581                	li	a1,0
    800072aa:	854a                	mv	a0,s2
    800072ac:	ffffa097          	auipc	ra,0xffffa
    800072b0:	8d6080e7          	jalr	-1834(ra) # 80000b82 <memset>
    p += sz;
    800072b4:	9926                	add	s2,s2,s1
  for (int k = 1; k < nsizes; k++) {
    800072b6:	2985                	addiw	s3,s3,1
    800072b8:	000aa783          	lw	a5,0(s5)
    800072bc:	020a0a13          	addi	s4,s4,32
    800072c0:	faf9cfe3          	blt	s3,a5,8000727e <bd_init+0x14a>
  }
  p = (char *) ROUNDUP((uint64) p, LEAF_SIZE);
    800072c4:	197d                	addi	s2,s2,-1
    800072c6:	ff097913          	andi	s2,s2,-16
    800072ca:	0941                	addi	s2,s2,16

  // done allocating; mark the memory range [base, p) as allocated, so
  // that buddy will not hand out that memory.
  int meta = bd_mark_data_structures(p);
    800072cc:	854a                	mv	a0,s2
    800072ce:	00000097          	auipc	ra,0x0
    800072d2:	d7c080e7          	jalr	-644(ra) # 8000704a <bd_mark_data_structures>
    800072d6:	8a2a                	mv	s4,a0
  
  // mark the unavailable memory range [end, HEAP_SIZE) as allocated,
  // so that buddy will not hand out that memory.
  int unavailable = bd_mark_unavailable(end, p);
    800072d8:	85ca                	mv	a1,s2
    800072da:	8562                	mv	a0,s8
    800072dc:	00000097          	auipc	ra,0x0
    800072e0:	dce080e7          	jalr	-562(ra) # 800070aa <bd_mark_unavailable>
    800072e4:	89aa                	mv	s3,a0
  void *bd_end = bd_base+BLK_SIZE(MAXSIZE)-unavailable;
    800072e6:	00023a97          	auipc	s5,0x23
    800072ea:	d72a8a93          	addi	s5,s5,-654 # 8002a058 <nsizes>
    800072ee:	000aa783          	lw	a5,0(s5)
    800072f2:	37fd                	addiw	a5,a5,-1
    800072f4:	44c1                	li	s1,16
    800072f6:	00f497b3          	sll	a5,s1,a5
    800072fa:	8f89                	sub	a5,a5,a0
  
  // initialize free lists for each size k
  int free = bd_initfree(p, bd_end);
    800072fc:	00023597          	auipc	a1,0x23
    80007300:	d4c5b583          	ld	a1,-692(a1) # 8002a048 <bd_base>
    80007304:	95be                	add	a1,a1,a5
    80007306:	854a                	mv	a0,s2
    80007308:	00000097          	auipc	ra,0x0
    8000730c:	c86080e7          	jalr	-890(ra) # 80006f8e <bd_initfree>

  // check if the amount that is free is what we expect
  if(free != BLK_SIZE(MAXSIZE)-meta-unavailable) {
    80007310:	000aa603          	lw	a2,0(s5)
    80007314:	367d                	addiw	a2,a2,-1
    80007316:	00c49633          	sll	a2,s1,a2
    8000731a:	41460633          	sub	a2,a2,s4
    8000731e:	41360633          	sub	a2,a2,s3
    80007322:	02c51463          	bne	a0,a2,8000734a <bd_init+0x216>
    printf("free %d %d\n", free, BLK_SIZE(MAXSIZE)-meta-unavailable);
    panic("bd_init: free mem");
  }
}
    80007326:	60a6                	ld	ra,72(sp)
    80007328:	6406                	ld	s0,64(sp)
    8000732a:	74e2                	ld	s1,56(sp)
    8000732c:	7942                	ld	s2,48(sp)
    8000732e:	79a2                	ld	s3,40(sp)
    80007330:	7a02                	ld	s4,32(sp)
    80007332:	6ae2                	ld	s5,24(sp)
    80007334:	6b42                	ld	s6,16(sp)
    80007336:	6ba2                	ld	s7,8(sp)
    80007338:	6c02                	ld	s8,0(sp)
    8000733a:	6161                	addi	sp,sp,80
    8000733c:	8082                	ret
    nsizes++;  // round up to the next power of 2
    8000733e:	2509                	addiw	a0,a0,2
    80007340:	00023797          	auipc	a5,0x23
    80007344:	d0a7ac23          	sw	a0,-744(a5) # 8002a058 <nsizes>
    80007348:	bda1                	j	800071a0 <bd_init+0x6c>
    printf("free %d %d\n", free, BLK_SIZE(MAXSIZE)-meta-unavailable);
    8000734a:	85aa                	mv	a1,a0
    8000734c:	00001517          	auipc	a0,0x1
    80007350:	6fc50513          	addi	a0,a0,1788 # 80008a48 <userret+0x9b8>
    80007354:	ffff9097          	auipc	ra,0xffff9
    80007358:	23e080e7          	jalr	574(ra) # 80000592 <printf>
    panic("bd_init: free mem");
    8000735c:	00001517          	auipc	a0,0x1
    80007360:	6fc50513          	addi	a0,a0,1788 # 80008a58 <userret+0x9c8>
    80007364:	ffff9097          	auipc	ra,0xffff9
    80007368:	1e4080e7          	jalr	484(ra) # 80000548 <panic>

000000008000736c <lst_init>:
// fast. circular simplifies code, because don't have to check for
// empty list in insert and remove.

void
lst_init(struct list *lst)
{
    8000736c:	1141                	addi	sp,sp,-16
    8000736e:	e422                	sd	s0,8(sp)
    80007370:	0800                	addi	s0,sp,16
  lst->next = lst;
    80007372:	e108                	sd	a0,0(a0)
  lst->prev = lst;
    80007374:	e508                	sd	a0,8(a0)
}
    80007376:	6422                	ld	s0,8(sp)
    80007378:	0141                	addi	sp,sp,16
    8000737a:	8082                	ret

000000008000737c <lst_empty>:

int
lst_empty(struct list *lst) {
    8000737c:	1141                	addi	sp,sp,-16
    8000737e:	e422                	sd	s0,8(sp)
    80007380:	0800                	addi	s0,sp,16
  return lst->next == lst;
    80007382:	611c                	ld	a5,0(a0)
    80007384:	40a78533          	sub	a0,a5,a0
}
    80007388:	00153513          	seqz	a0,a0
    8000738c:	6422                	ld	s0,8(sp)
    8000738e:	0141                	addi	sp,sp,16
    80007390:	8082                	ret

0000000080007392 <lst_remove>:

void
lst_remove(struct list *e) {
    80007392:	1141                	addi	sp,sp,-16
    80007394:	e422                	sd	s0,8(sp)
    80007396:	0800                	addi	s0,sp,16
  e->prev->next = e->next;
    80007398:	6518                	ld	a4,8(a0)
    8000739a:	611c                	ld	a5,0(a0)
    8000739c:	e31c                	sd	a5,0(a4)
  e->next->prev = e->prev;
    8000739e:	6518                	ld	a4,8(a0)
    800073a0:	e798                	sd	a4,8(a5)
}
    800073a2:	6422                	ld	s0,8(sp)
    800073a4:	0141                	addi	sp,sp,16
    800073a6:	8082                	ret

00000000800073a8 <lst_pop>:

void*
lst_pop(struct list *lst) {
    800073a8:	1101                	addi	sp,sp,-32
    800073aa:	ec06                	sd	ra,24(sp)
    800073ac:	e822                	sd	s0,16(sp)
    800073ae:	e426                	sd	s1,8(sp)
    800073b0:	1000                	addi	s0,sp,32
  if(lst->next == lst)
    800073b2:	6104                	ld	s1,0(a0)
    800073b4:	00a48d63          	beq	s1,a0,800073ce <lst_pop+0x26>
    panic("lst_pop");
  struct list *p = lst->next;
  lst_remove(p);
    800073b8:	8526                	mv	a0,s1
    800073ba:	00000097          	auipc	ra,0x0
    800073be:	fd8080e7          	jalr	-40(ra) # 80007392 <lst_remove>
  return (void *)p;
}
    800073c2:	8526                	mv	a0,s1
    800073c4:	60e2                	ld	ra,24(sp)
    800073c6:	6442                	ld	s0,16(sp)
    800073c8:	64a2                	ld	s1,8(sp)
    800073ca:	6105                	addi	sp,sp,32
    800073cc:	8082                	ret
    panic("lst_pop");
    800073ce:	00001517          	auipc	a0,0x1
    800073d2:	6a250513          	addi	a0,a0,1698 # 80008a70 <userret+0x9e0>
    800073d6:	ffff9097          	auipc	ra,0xffff9
    800073da:	172080e7          	jalr	370(ra) # 80000548 <panic>

00000000800073de <lst_push>:

void
lst_push(struct list *lst, void *p)
{
    800073de:	1141                	addi	sp,sp,-16
    800073e0:	e422                	sd	s0,8(sp)
    800073e2:	0800                	addi	s0,sp,16
  struct list *e = (struct list *) p;
  e->next = lst->next;
    800073e4:	611c                	ld	a5,0(a0)
    800073e6:	e19c                	sd	a5,0(a1)
  e->prev = lst;
    800073e8:	e588                	sd	a0,8(a1)
  lst->next->prev = p;
    800073ea:	611c                	ld	a5,0(a0)
    800073ec:	e78c                	sd	a1,8(a5)
  lst->next = e;
    800073ee:	e10c                	sd	a1,0(a0)
}
    800073f0:	6422                	ld	s0,8(sp)
    800073f2:	0141                	addi	sp,sp,16
    800073f4:	8082                	ret

00000000800073f6 <lst_print>:

void
lst_print(struct list *lst)
{
    800073f6:	7179                	addi	sp,sp,-48
    800073f8:	f406                	sd	ra,40(sp)
    800073fa:	f022                	sd	s0,32(sp)
    800073fc:	ec26                	sd	s1,24(sp)
    800073fe:	e84a                	sd	s2,16(sp)
    80007400:	e44e                	sd	s3,8(sp)
    80007402:	1800                	addi	s0,sp,48
  for (struct list *p = lst->next; p != lst; p = p->next) {
    80007404:	6104                	ld	s1,0(a0)
    80007406:	02950063          	beq	a0,s1,80007426 <lst_print+0x30>
    8000740a:	892a                	mv	s2,a0
    printf(" %p", p);
    8000740c:	00001997          	auipc	s3,0x1
    80007410:	66c98993          	addi	s3,s3,1644 # 80008a78 <userret+0x9e8>
    80007414:	85a6                	mv	a1,s1
    80007416:	854e                	mv	a0,s3
    80007418:	ffff9097          	auipc	ra,0xffff9
    8000741c:	17a080e7          	jalr	378(ra) # 80000592 <printf>
  for (struct list *p = lst->next; p != lst; p = p->next) {
    80007420:	6084                	ld	s1,0(s1)
    80007422:	fe9919e3          	bne	s2,s1,80007414 <lst_print+0x1e>
  }
  printf("\n");
    80007426:	00001517          	auipc	a0,0x1
    8000742a:	d8a50513          	addi	a0,a0,-630 # 800081b0 <userret+0x120>
    8000742e:	ffff9097          	auipc	ra,0xffff9
    80007432:	164080e7          	jalr	356(ra) # 80000592 <printf>
}
    80007436:	70a2                	ld	ra,40(sp)
    80007438:	7402                	ld	s0,32(sp)
    8000743a:	64e2                	ld	s1,24(sp)
    8000743c:	6942                	ld	s2,16(sp)
    8000743e:	69a2                	ld	s3,8(sp)
    80007440:	6145                	addi	sp,sp,48
    80007442:	8082                	ret
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

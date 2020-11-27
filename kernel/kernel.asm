
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
    80000060:	ca478793          	addi	a5,a5,-860 # 80005d00 <timervec>
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
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd27a3>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e8478793          	addi	a5,a5,-380 # 80000f2a <main>
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
    80000112:	a00080e7          	jalr	-1536(ra) # 80000b0e <acquire>
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
    80000122:	78290913          	addi	s2,s2,1922 # 800128a0 <cons+0xa0>
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
    80000130:	0a04a783          	lw	a5,160(s1)
    80000134:	0a44a703          	lw	a4,164(s1)
    80000138:	02f71463          	bne	a4,a5,80000160 <consoleread+0x80>
      if(myproc()->killed){
    8000013c:	00002097          	auipc	ra,0x2
    80000140:	92a080e7          	jalr	-1750(ra) # 80001a66 <myproc>
    80000144:	5d1c                	lw	a5,56(a0)
    80000146:	e7b5                	bnez	a5,800001b2 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    80000148:	85a6                	mv	a1,s1
    8000014a:	854a                	mv	a0,s2
    8000014c:	00002097          	auipc	ra,0x2
    80000150:	0f0080e7          	jalr	240(ra) # 8000223c <sleep>
    while(cons.r == cons.w){
    80000154:	0a04a783          	lw	a5,160(s1)
    80000158:	0a44a703          	lw	a4,164(s1)
    8000015c:	fef700e3          	beq	a4,a5,8000013c <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    80000160:	0017871b          	addiw	a4,a5,1
    80000164:	0ae4a023          	sw	a4,160(s1)
    80000168:	07f7f713          	andi	a4,a5,127
    8000016c:	9726                	add	a4,a4,s1
    8000016e:	02074703          	lbu	a4,32(a4)
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
    8000018c:	30e080e7          	jalr	782(ra) # 80002496 <either_copyout>
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
    800001a8:	9da080e7          	jalr	-1574(ra) # 80000b7e <release>

  return target - n;
    800001ac:	413b053b          	subw	a0,s6,s3
    800001b0:	a811                	j	800001c4 <consoleread+0xe4>
        release(&cons.lock);
    800001b2:	00012517          	auipc	a0,0x12
    800001b6:	64e50513          	addi	a0,a0,1614 # 80012800 <cons>
    800001ba:	00001097          	auipc	ra,0x1
    800001be:	9c4080e7          	jalr	-1596(ra) # 80000b7e <release>
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
    800001ec:	6af72c23          	sw	a5,1720(a4) # 800128a0 <cons+0xa0>
    800001f0:	b775                	j	8000019c <consoleread+0xbc>

00000000800001f2 <consputc>:
  if(panicked){
    800001f2:	0002c797          	auipc	a5,0x2c
    800001f6:	e2e7a783          	lw	a5,-466(a5) # 8002c020 <panicked>
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
    80000212:	5dc080e7          	jalr	1500(ra) # 800007ea <uartputc>
}
    80000216:	60a2                	ld	ra,8(sp)
    80000218:	6402                	ld	s0,0(sp)
    8000021a:	0141                	addi	sp,sp,16
    8000021c:	8082                	ret
    uartputc('\b'); uartputc(' '); uartputc('\b');
    8000021e:	4521                	li	a0,8
    80000220:	00000097          	auipc	ra,0x0
    80000224:	5ca080e7          	jalr	1482(ra) # 800007ea <uartputc>
    80000228:	02000513          	li	a0,32
    8000022c:	00000097          	auipc	ra,0x0
    80000230:	5be080e7          	jalr	1470(ra) # 800007ea <uartputc>
    80000234:	4521                	li	a0,8
    80000236:	00000097          	auipc	ra,0x0
    8000023a:	5b4080e7          	jalr	1460(ra) # 800007ea <uartputc>
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
    80000264:	8ae080e7          	jalr	-1874(ra) # 80000b0e <acquire>
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
    8000028a:	266080e7          	jalr	614(ra) # 800024ec <either_copyin>
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
    800002b0:	8d2080e7          	jalr	-1838(ra) # 80000b7e <release>
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
    800002de:	00001097          	auipc	ra,0x1
    800002e2:	830080e7          	jalr	-2000(ra) # 80000b0e <acquire>

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
    80000300:	246080e7          	jalr	582(ra) # 80002542 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00012517          	auipc	a0,0x12
    80000308:	4fc50513          	addi	a0,a0,1276 # 80012800 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	872080e7          	jalr	-1934(ra) # 80000b7e <release>
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
    80000330:	0a872783          	lw	a5,168(a4)
    80000334:	0a072703          	lw	a4,160(a4)
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
    8000035a:	0a87a703          	lw	a4,168(a5)
    8000035e:	0017069b          	addiw	a3,a4,1
    80000362:	0006861b          	sext.w	a2,a3
    80000366:	0ad7a423          	sw	a3,168(a5)
    8000036a:	07f77713          	andi	a4,a4,127
    8000036e:	97ba                	add	a5,a5,a4
    80000370:	02978023          	sb	s1,32(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000374:	47a9                	li	a5,10
    80000376:	0cf48563          	beq	s1,a5,80000440 <consoleintr+0x178>
    8000037a:	4791                	li	a5,4
    8000037c:	0cf48263          	beq	s1,a5,80000440 <consoleintr+0x178>
    80000380:	00012797          	auipc	a5,0x12
    80000384:	5207a783          	lw	a5,1312(a5) # 800128a0 <cons+0xa0>
    80000388:	0807879b          	addiw	a5,a5,128
    8000038c:	f6f61ce3          	bne	a2,a5,80000304 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000390:	863e                	mv	a2,a5
    80000392:	a07d                	j	80000440 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000394:	00012717          	auipc	a4,0x12
    80000398:	46c70713          	addi	a4,a4,1132 # 80012800 <cons>
    8000039c:	0a872783          	lw	a5,168(a4)
    800003a0:	0a472703          	lw	a4,164(a4)
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
    800003ba:	02074703          	lbu	a4,32(a4)
    800003be:	f52703e3          	beq	a4,s2,80000304 <consoleintr+0x3c>
      cons.e--;
    800003c2:	0af4a423          	sw	a5,168(s1)
      consputc(BACKSPACE);
    800003c6:	10000513          	li	a0,256
    800003ca:	00000097          	auipc	ra,0x0
    800003ce:	e28080e7          	jalr	-472(ra) # 800001f2 <consputc>
    while(cons.e != cons.w &&
    800003d2:	0a84a783          	lw	a5,168(s1)
    800003d6:	0a44a703          	lw	a4,164(s1)
    800003da:	fcf71ce3          	bne	a4,a5,800003b2 <consoleintr+0xea>
    800003de:	b71d                	j	80000304 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e0:	00012717          	auipc	a4,0x12
    800003e4:	42070713          	addi	a4,a4,1056 # 80012800 <cons>
    800003e8:	0a872783          	lw	a5,168(a4)
    800003ec:	0a472703          	lw	a4,164(a4)
    800003f0:	f0f70ae3          	beq	a4,a5,80000304 <consoleintr+0x3c>
      cons.e--;
    800003f4:	37fd                	addiw	a5,a5,-1
    800003f6:	00012717          	auipc	a4,0x12
    800003fa:	4af72923          	sw	a5,1202(a4) # 800128a8 <cons+0xa8>
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
    80000424:	0a87a703          	lw	a4,168(a5)
    80000428:	0017069b          	addiw	a3,a4,1
    8000042c:	0006861b          	sext.w	a2,a3
    80000430:	0ad7a423          	sw	a3,168(a5)
    80000434:	07f77713          	andi	a4,a4,127
    80000438:	97ba                	add	a5,a5,a4
    8000043a:	4729                	li	a4,10
    8000043c:	02e78023          	sb	a4,32(a5)
        cons.w = cons.e;
    80000440:	00012797          	auipc	a5,0x12
    80000444:	46c7a223          	sw	a2,1124(a5) # 800128a4 <cons+0xa4>
        wakeup(&cons.r);
    80000448:	00012517          	auipc	a0,0x12
    8000044c:	45850513          	addi	a0,a0,1112 # 800128a0 <cons+0xa0>
    80000450:	00002097          	auipc	ra,0x2
    80000454:	f6c080e7          	jalr	-148(ra) # 800023bc <wakeup>
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
    80000476:	54e080e7          	jalr	1358(ra) # 800009c0 <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	33a080e7          	jalr	826(ra) # 800007b4 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00025797          	auipc	a5,0x25
    80000486:	97e78793          	addi	a5,a5,-1666 # 80024e00 <devsw>
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
    800004c8:	5ec60613          	addi	a2,a2,1516 # 80008ab0 <digits>
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
    80000558:	3607ae23          	sw	zero,892(a5) # 800128d0 <pr+0x20>
  printf("PANIC: ");
    8000055c:	00008517          	auipc	a0,0x8
    80000560:	bc450513          	addi	a0,a0,-1084 # 80008120 <userret+0x90>
    80000564:	00000097          	auipc	ra,0x0
    80000568:	03e080e7          	jalr	62(ra) # 800005a2 <printf>
  printf(s);
    8000056c:	8526                	mv	a0,s1
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	034080e7          	jalr	52(ra) # 800005a2 <printf>
  printf("\n");
    80000576:	00008517          	auipc	a0,0x8
    8000057a:	d1a50513          	addi	a0,a0,-742 # 80008290 <userret+0x200>
    8000057e:	00000097          	auipc	ra,0x0
    80000582:	024080e7          	jalr	36(ra) # 800005a2 <printf>
  printf("HINT: restart xv6 using 'make qemu-gdb', type 'b panic' (to set breakpoint in panic) in the gdb window, followed by 'c' (continue), and when the kernel hits the breakpoint, type 'bt' to get a backtrace\n");
    80000586:	00008517          	auipc	a0,0x8
    8000058a:	ba250513          	addi	a0,a0,-1118 # 80008128 <userret+0x98>
    8000058e:	00000097          	auipc	ra,0x0
    80000592:	014080e7          	jalr	20(ra) # 800005a2 <printf>
  panicked = 1; // freeze other CPUs
    80000596:	4785                	li	a5,1
    80000598:	0002c717          	auipc	a4,0x2c
    8000059c:	a8f72423          	sw	a5,-1400(a4) # 8002c020 <panicked>
  for(;;)
    800005a0:	a001                	j	800005a0 <panic+0x58>

00000000800005a2 <printf>:
{
    800005a2:	7131                	addi	sp,sp,-192
    800005a4:	fc86                	sd	ra,120(sp)
    800005a6:	f8a2                	sd	s0,112(sp)
    800005a8:	f4a6                	sd	s1,104(sp)
    800005aa:	f0ca                	sd	s2,96(sp)
    800005ac:	ecce                	sd	s3,88(sp)
    800005ae:	e8d2                	sd	s4,80(sp)
    800005b0:	e4d6                	sd	s5,72(sp)
    800005b2:	e0da                	sd	s6,64(sp)
    800005b4:	fc5e                	sd	s7,56(sp)
    800005b6:	f862                	sd	s8,48(sp)
    800005b8:	f466                	sd	s9,40(sp)
    800005ba:	f06a                	sd	s10,32(sp)
    800005bc:	ec6e                	sd	s11,24(sp)
    800005be:	0100                	addi	s0,sp,128
    800005c0:	8a2a                	mv	s4,a0
    800005c2:	e40c                	sd	a1,8(s0)
    800005c4:	e810                	sd	a2,16(s0)
    800005c6:	ec14                	sd	a3,24(s0)
    800005c8:	f018                	sd	a4,32(s0)
    800005ca:	f41c                	sd	a5,40(s0)
    800005cc:	03043823          	sd	a6,48(s0)
    800005d0:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005d4:	00012d97          	auipc	s11,0x12
    800005d8:	2fcdad83          	lw	s11,764(s11) # 800128d0 <pr+0x20>
  if(locking)
    800005dc:	020d9b63          	bnez	s11,80000612 <printf+0x70>
  if (fmt == 0)
    800005e0:	040a0263          	beqz	s4,80000624 <printf+0x82>
  va_start(ap, fmt);
    800005e4:	00840793          	addi	a5,s0,8
    800005e8:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005ec:	000a4503          	lbu	a0,0(s4)
    800005f0:	14050f63          	beqz	a0,8000074e <printf+0x1ac>
    800005f4:	4981                	li	s3,0
    if(c != '%'){
    800005f6:	02500a93          	li	s5,37
    switch(c){
    800005fa:	07000b93          	li	s7,112
  consputc('x');
    800005fe:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000600:	00008b17          	auipc	s6,0x8
    80000604:	4b0b0b13          	addi	s6,s6,1200 # 80008ab0 <digits>
    switch(c){
    80000608:	07300c93          	li	s9,115
    8000060c:	06400c13          	li	s8,100
    80000610:	a82d                	j	8000064a <printf+0xa8>
    acquire(&pr.lock);
    80000612:	00012517          	auipc	a0,0x12
    80000616:	29e50513          	addi	a0,a0,670 # 800128b0 <pr>
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	4f4080e7          	jalr	1268(ra) # 80000b0e <acquire>
    80000622:	bf7d                	j	800005e0 <printf+0x3e>
    panic("null fmt");
    80000624:	00008517          	auipc	a0,0x8
    80000628:	bdc50513          	addi	a0,a0,-1060 # 80008200 <userret+0x170>
    8000062c:	00000097          	auipc	ra,0x0
    80000630:	f1c080e7          	jalr	-228(ra) # 80000548 <panic>
      consputc(c);
    80000634:	00000097          	auipc	ra,0x0
    80000638:	bbe080e7          	jalr	-1090(ra) # 800001f2 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000063c:	2985                	addiw	s3,s3,1
    8000063e:	013a07b3          	add	a5,s4,s3
    80000642:	0007c503          	lbu	a0,0(a5)
    80000646:	10050463          	beqz	a0,8000074e <printf+0x1ac>
    if(c != '%'){
    8000064a:	ff5515e3          	bne	a0,s5,80000634 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000064e:	2985                	addiw	s3,s3,1
    80000650:	013a07b3          	add	a5,s4,s3
    80000654:	0007c783          	lbu	a5,0(a5)
    80000658:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000065c:	cbed                	beqz	a5,8000074e <printf+0x1ac>
    switch(c){
    8000065e:	05778a63          	beq	a5,s7,800006b2 <printf+0x110>
    80000662:	02fbf663          	bgeu	s7,a5,8000068e <printf+0xec>
    80000666:	09978863          	beq	a5,s9,800006f6 <printf+0x154>
    8000066a:	07800713          	li	a4,120
    8000066e:	0ce79563          	bne	a5,a4,80000738 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000672:	f8843783          	ld	a5,-120(s0)
    80000676:	00878713          	addi	a4,a5,8
    8000067a:	f8e43423          	sd	a4,-120(s0)
    8000067e:	4605                	li	a2,1
    80000680:	85ea                	mv	a1,s10
    80000682:	4388                	lw	a0,0(a5)
    80000684:	00000097          	auipc	ra,0x0
    80000688:	e22080e7          	jalr	-478(ra) # 800004a6 <printint>
      break;
    8000068c:	bf45                	j	8000063c <printf+0x9a>
    switch(c){
    8000068e:	09578f63          	beq	a5,s5,8000072c <printf+0x18a>
    80000692:	0b879363          	bne	a5,s8,80000738 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000696:	f8843783          	ld	a5,-120(s0)
    8000069a:	00878713          	addi	a4,a5,8
    8000069e:	f8e43423          	sd	a4,-120(s0)
    800006a2:	4605                	li	a2,1
    800006a4:	45a9                	li	a1,10
    800006a6:	4388                	lw	a0,0(a5)
    800006a8:	00000097          	auipc	ra,0x0
    800006ac:	dfe080e7          	jalr	-514(ra) # 800004a6 <printint>
      break;
    800006b0:	b771                	j	8000063c <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006b2:	f8843783          	ld	a5,-120(s0)
    800006b6:	00878713          	addi	a4,a5,8
    800006ba:	f8e43423          	sd	a4,-120(s0)
    800006be:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006c2:	03000513          	li	a0,48
    800006c6:	00000097          	auipc	ra,0x0
    800006ca:	b2c080e7          	jalr	-1236(ra) # 800001f2 <consputc>
  consputc('x');
    800006ce:	07800513          	li	a0,120
    800006d2:	00000097          	auipc	ra,0x0
    800006d6:	b20080e7          	jalr	-1248(ra) # 800001f2 <consputc>
    800006da:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006dc:	03c95793          	srli	a5,s2,0x3c
    800006e0:	97da                	add	a5,a5,s6
    800006e2:	0007c503          	lbu	a0,0(a5)
    800006e6:	00000097          	auipc	ra,0x0
    800006ea:	b0c080e7          	jalr	-1268(ra) # 800001f2 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006ee:	0912                	slli	s2,s2,0x4
    800006f0:	34fd                	addiw	s1,s1,-1
    800006f2:	f4ed                	bnez	s1,800006dc <printf+0x13a>
    800006f4:	b7a1                	j	8000063c <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006f6:	f8843783          	ld	a5,-120(s0)
    800006fa:	00878713          	addi	a4,a5,8
    800006fe:	f8e43423          	sd	a4,-120(s0)
    80000702:	6384                	ld	s1,0(a5)
    80000704:	cc89                	beqz	s1,8000071e <printf+0x17c>
      for(; *s; s++)
    80000706:	0004c503          	lbu	a0,0(s1)
    8000070a:	d90d                	beqz	a0,8000063c <printf+0x9a>
        consputc(*s);
    8000070c:	00000097          	auipc	ra,0x0
    80000710:	ae6080e7          	jalr	-1306(ra) # 800001f2 <consputc>
      for(; *s; s++)
    80000714:	0485                	addi	s1,s1,1
    80000716:	0004c503          	lbu	a0,0(s1)
    8000071a:	f96d                	bnez	a0,8000070c <printf+0x16a>
    8000071c:	b705                	j	8000063c <printf+0x9a>
        s = "(null)";
    8000071e:	00008497          	auipc	s1,0x8
    80000722:	ada48493          	addi	s1,s1,-1318 # 800081f8 <userret+0x168>
      for(; *s; s++)
    80000726:	02800513          	li	a0,40
    8000072a:	b7cd                	j	8000070c <printf+0x16a>
      consputc('%');
    8000072c:	8556                	mv	a0,s5
    8000072e:	00000097          	auipc	ra,0x0
    80000732:	ac4080e7          	jalr	-1340(ra) # 800001f2 <consputc>
      break;
    80000736:	b719                	j	8000063c <printf+0x9a>
      consputc('%');
    80000738:	8556                	mv	a0,s5
    8000073a:	00000097          	auipc	ra,0x0
    8000073e:	ab8080e7          	jalr	-1352(ra) # 800001f2 <consputc>
      consputc(c);
    80000742:	8526                	mv	a0,s1
    80000744:	00000097          	auipc	ra,0x0
    80000748:	aae080e7          	jalr	-1362(ra) # 800001f2 <consputc>
      break;
    8000074c:	bdc5                	j	8000063c <printf+0x9a>
  if(locking)
    8000074e:	020d9163          	bnez	s11,80000770 <printf+0x1ce>
}
    80000752:	70e6                	ld	ra,120(sp)
    80000754:	7446                	ld	s0,112(sp)
    80000756:	74a6                	ld	s1,104(sp)
    80000758:	7906                	ld	s2,96(sp)
    8000075a:	69e6                	ld	s3,88(sp)
    8000075c:	6a46                	ld	s4,80(sp)
    8000075e:	6aa6                	ld	s5,72(sp)
    80000760:	6b06                	ld	s6,64(sp)
    80000762:	7be2                	ld	s7,56(sp)
    80000764:	7c42                	ld	s8,48(sp)
    80000766:	7ca2                	ld	s9,40(sp)
    80000768:	7d02                	ld	s10,32(sp)
    8000076a:	6de2                	ld	s11,24(sp)
    8000076c:	6129                	addi	sp,sp,192
    8000076e:	8082                	ret
    release(&pr.lock);
    80000770:	00012517          	auipc	a0,0x12
    80000774:	14050513          	addi	a0,a0,320 # 800128b0 <pr>
    80000778:	00000097          	auipc	ra,0x0
    8000077c:	406080e7          	jalr	1030(ra) # 80000b7e <release>
}
    80000780:	bfc9                	j	80000752 <printf+0x1b0>

0000000080000782 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000782:	1101                	addi	sp,sp,-32
    80000784:	ec06                	sd	ra,24(sp)
    80000786:	e822                	sd	s0,16(sp)
    80000788:	e426                	sd	s1,8(sp)
    8000078a:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000078c:	00012497          	auipc	s1,0x12
    80000790:	12448493          	addi	s1,s1,292 # 800128b0 <pr>
    80000794:	00008597          	auipc	a1,0x8
    80000798:	a7c58593          	addi	a1,a1,-1412 # 80008210 <userret+0x180>
    8000079c:	8526                	mv	a0,s1
    8000079e:	00000097          	auipc	ra,0x0
    800007a2:	222080e7          	jalr	546(ra) # 800009c0 <initlock>
  pr.locking = 1;
    800007a6:	4785                	li	a5,1
    800007a8:	d09c                	sw	a5,32(s1)
}
    800007aa:	60e2                	ld	ra,24(sp)
    800007ac:	6442                	ld	s0,16(sp)
    800007ae:	64a2                	ld	s1,8(sp)
    800007b0:	6105                	addi	sp,sp,32
    800007b2:	8082                	ret

00000000800007b4 <uartinit>:
#define ReadReg(reg) (*(Reg(reg)))
#define WriteReg(reg, v) (*(Reg(reg)) = (v))

void
uartinit(void)
{
    800007b4:	1141                	addi	sp,sp,-16
    800007b6:	e422                	sd	s0,8(sp)
    800007b8:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ba:	100007b7          	lui	a5,0x10000
    800007be:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, 0x80);
    800007c2:	f8000713          	li	a4,-128
    800007c6:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007ca:	470d                	li	a4,3
    800007cc:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007d0:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, 0x03);
    800007d4:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, 0x07);
    800007d8:	471d                	li	a4,7
    800007da:	00e78123          	sb	a4,2(a5)

  // enable receive interrupts.
  WriteReg(IER, 0x01);
    800007de:	4705                	li	a4,1
    800007e0:	00e780a3          	sb	a4,1(a5)
}
    800007e4:	6422                	ld	s0,8(sp)
    800007e6:	0141                	addi	sp,sp,16
    800007e8:	8082                	ret

00000000800007ea <uartputc>:

// write one output character to the UART.
void
uartputc(int c)
{
    800007ea:	1141                	addi	sp,sp,-16
    800007ec:	e422                	sd	s0,8(sp)
    800007ee:	0800                	addi	s0,sp,16
  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & (1 << 5)) == 0)
    800007f0:	10000737          	lui	a4,0x10000
    800007f4:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    800007f8:	0207f793          	andi	a5,a5,32
    800007fc:	dfe5                	beqz	a5,800007f4 <uartputc+0xa>
    ;
  WriteReg(THR, c);
    800007fe:	0ff57513          	andi	a0,a0,255
    80000802:	100007b7          	lui	a5,0x10000
    80000806:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>
}
    8000080a:	6422                	ld	s0,8(sp)
    8000080c:	0141                	addi	sp,sp,16
    8000080e:	8082                	ret

0000000080000810 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000810:	1141                	addi	sp,sp,-16
    80000812:	e422                	sd	s0,8(sp)
    80000814:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000816:	100007b7          	lui	a5,0x10000
    8000081a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000081e:	8b85                	andi	a5,a5,1
    80000820:	cb91                	beqz	a5,80000834 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000822:	100007b7          	lui	a5,0x10000
    80000826:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000082a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000082e:	6422                	ld	s0,8(sp)
    80000830:	0141                	addi	sp,sp,16
    80000832:	8082                	ret
    return -1;
    80000834:	557d                	li	a0,-1
    80000836:	bfe5                	j	8000082e <uartgetc+0x1e>

0000000080000838 <uartintr>:

// trap.c calls here when the uart interrupts.
void
uartintr(void)
{
    80000838:	1101                	addi	sp,sp,-32
    8000083a:	ec06                	sd	ra,24(sp)
    8000083c:	e822                	sd	s0,16(sp)
    8000083e:	e426                	sd	s1,8(sp)
    80000840:	1000                	addi	s0,sp,32
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000842:	54fd                	li	s1,-1
    80000844:	a029                	j	8000084e <uartintr+0x16>
      break;
    consoleintr(c);
    80000846:	00000097          	auipc	ra,0x0
    8000084a:	a82080e7          	jalr	-1406(ra) # 800002c8 <consoleintr>
    int c = uartgetc();
    8000084e:	00000097          	auipc	ra,0x0
    80000852:	fc2080e7          	jalr	-62(ra) # 80000810 <uartgetc>
    if(c == -1)
    80000856:	fe9518e3          	bne	a0,s1,80000846 <uartintr+0xe>
  }
}
    8000085a:	60e2                	ld	ra,24(sp)
    8000085c:	6442                	ld	s0,16(sp)
    8000085e:	64a2                	ld	s1,8(sp)
    80000860:	6105                	addi	sp,sp,32
    80000862:	8082                	ret

0000000080000864 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000864:	1101                	addi	sp,sp,-32
    80000866:	ec06                	sd	ra,24(sp)
    80000868:	e822                	sd	s0,16(sp)
    8000086a:	e426                	sd	s1,8(sp)
    8000086c:	e04a                	sd	s2,0(sp)
    8000086e:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000870:	03451793          	slli	a5,a0,0x34
    80000874:	ebb9                	bnez	a5,800008ca <kfree+0x66>
    80000876:	84aa                	mv	s1,a0
    80000878:	0002b797          	auipc	a5,0x2b
    8000087c:	7e478793          	addi	a5,a5,2020 # 8002c05c <end>
    80000880:	04f56563          	bltu	a0,a5,800008ca <kfree+0x66>
    80000884:	47c5                	li	a5,17
    80000886:	07ee                	slli	a5,a5,0x1b
    80000888:	04f57163          	bgeu	a0,a5,800008ca <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    8000088c:	6605                	lui	a2,0x1
    8000088e:	4585                	li	a1,1
    80000890:	00000097          	auipc	ra,0x0
    80000894:	4ec080e7          	jalr	1260(ra) # 80000d7c <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000898:	00012917          	auipc	s2,0x12
    8000089c:	04090913          	addi	s2,s2,64 # 800128d8 <kmem>
    800008a0:	854a                	mv	a0,s2
    800008a2:	00000097          	auipc	ra,0x0
    800008a6:	26c080e7          	jalr	620(ra) # 80000b0e <acquire>
  r->next = kmem.freelist;
    800008aa:	02093783          	ld	a5,32(s2)
    800008ae:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    800008b0:	02993023          	sd	s1,32(s2)
  release(&kmem.lock);
    800008b4:	854a                	mv	a0,s2
    800008b6:	00000097          	auipc	ra,0x0
    800008ba:	2c8080e7          	jalr	712(ra) # 80000b7e <release>
}
    800008be:	60e2                	ld	ra,24(sp)
    800008c0:	6442                	ld	s0,16(sp)
    800008c2:	64a2                	ld	s1,8(sp)
    800008c4:	6902                	ld	s2,0(sp)
    800008c6:	6105                	addi	sp,sp,32
    800008c8:	8082                	ret
    panic("kfree");
    800008ca:	00008517          	auipc	a0,0x8
    800008ce:	94e50513          	addi	a0,a0,-1714 # 80008218 <userret+0x188>
    800008d2:	00000097          	auipc	ra,0x0
    800008d6:	c76080e7          	jalr	-906(ra) # 80000548 <panic>

00000000800008da <freerange>:
{
    800008da:	7179                	addi	sp,sp,-48
    800008dc:	f406                	sd	ra,40(sp)
    800008de:	f022                	sd	s0,32(sp)
    800008e0:	ec26                	sd	s1,24(sp)
    800008e2:	e84a                	sd	s2,16(sp)
    800008e4:	e44e                	sd	s3,8(sp)
    800008e6:	e052                	sd	s4,0(sp)
    800008e8:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    800008ea:	6785                	lui	a5,0x1
    800008ec:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    800008f0:	94aa                	add	s1,s1,a0
    800008f2:	757d                	lui	a0,0xfffff
    800008f4:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    800008f6:	94be                	add	s1,s1,a5
    800008f8:	0095ee63          	bltu	a1,s1,80000914 <freerange+0x3a>
    800008fc:	892e                	mv	s2,a1
    kfree(p);
    800008fe:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000900:	6985                	lui	s3,0x1
    kfree(p);
    80000902:	01448533          	add	a0,s1,s4
    80000906:	00000097          	auipc	ra,0x0
    8000090a:	f5e080e7          	jalr	-162(ra) # 80000864 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    8000090e:	94ce                	add	s1,s1,s3
    80000910:	fe9979e3          	bgeu	s2,s1,80000902 <freerange+0x28>
}
    80000914:	70a2                	ld	ra,40(sp)
    80000916:	7402                	ld	s0,32(sp)
    80000918:	64e2                	ld	s1,24(sp)
    8000091a:	6942                	ld	s2,16(sp)
    8000091c:	69a2                	ld	s3,8(sp)
    8000091e:	6a02                	ld	s4,0(sp)
    80000920:	6145                	addi	sp,sp,48
    80000922:	8082                	ret

0000000080000924 <kinit>:
{
    80000924:	1141                	addi	sp,sp,-16
    80000926:	e406                	sd	ra,8(sp)
    80000928:	e022                	sd	s0,0(sp)
    8000092a:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    8000092c:	00008597          	auipc	a1,0x8
    80000930:	8f458593          	addi	a1,a1,-1804 # 80008220 <userret+0x190>
    80000934:	00012517          	auipc	a0,0x12
    80000938:	fa450513          	addi	a0,a0,-92 # 800128d8 <kmem>
    8000093c:	00000097          	auipc	ra,0x0
    80000940:	084080e7          	jalr	132(ra) # 800009c0 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000944:	45c5                	li	a1,17
    80000946:	05ee                	slli	a1,a1,0x1b
    80000948:	0002b517          	auipc	a0,0x2b
    8000094c:	71450513          	addi	a0,a0,1812 # 8002c05c <end>
    80000950:	00000097          	auipc	ra,0x0
    80000954:	f8a080e7          	jalr	-118(ra) # 800008da <freerange>
}
    80000958:	60a2                	ld	ra,8(sp)
    8000095a:	6402                	ld	s0,0(sp)
    8000095c:	0141                	addi	sp,sp,16
    8000095e:	8082                	ret

0000000080000960 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000960:	1101                	addi	sp,sp,-32
    80000962:	ec06                	sd	ra,24(sp)
    80000964:	e822                	sd	s0,16(sp)
    80000966:	e426                	sd	s1,8(sp)
    80000968:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    8000096a:	00012497          	auipc	s1,0x12
    8000096e:	f6e48493          	addi	s1,s1,-146 # 800128d8 <kmem>
    80000972:	8526                	mv	a0,s1
    80000974:	00000097          	auipc	ra,0x0
    80000978:	19a080e7          	jalr	410(ra) # 80000b0e <acquire>
  r = kmem.freelist;
    8000097c:	7084                	ld	s1,32(s1)
  if(r)
    8000097e:	c885                	beqz	s1,800009ae <kalloc+0x4e>
    kmem.freelist = r->next;
    80000980:	609c                	ld	a5,0(s1)
    80000982:	00012517          	auipc	a0,0x12
    80000986:	f5650513          	addi	a0,a0,-170 # 800128d8 <kmem>
    8000098a:	f11c                	sd	a5,32(a0)
  release(&kmem.lock);
    8000098c:	00000097          	auipc	ra,0x0
    80000990:	1f2080e7          	jalr	498(ra) # 80000b7e <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000994:	6605                	lui	a2,0x1
    80000996:	4595                	li	a1,5
    80000998:	8526                	mv	a0,s1
    8000099a:	00000097          	auipc	ra,0x0
    8000099e:	3e2080e7          	jalr	994(ra) # 80000d7c <memset>
  return (void*)r;
}
    800009a2:	8526                	mv	a0,s1
    800009a4:	60e2                	ld	ra,24(sp)
    800009a6:	6442                	ld	s0,16(sp)
    800009a8:	64a2                	ld	s1,8(sp)
    800009aa:	6105                	addi	sp,sp,32
    800009ac:	8082                	ret
  release(&kmem.lock);
    800009ae:	00012517          	auipc	a0,0x12
    800009b2:	f2a50513          	addi	a0,a0,-214 # 800128d8 <kmem>
    800009b6:	00000097          	auipc	ra,0x0
    800009ba:	1c8080e7          	jalr	456(ra) # 80000b7e <release>
  if(r)
    800009be:	b7d5                	j	800009a2 <kalloc+0x42>

00000000800009c0 <initlock>:

// assumes locks are not freed
void
initlock(struct spinlock *lk, char *name)
{
  lk->name = name;
    800009c0:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    800009c2:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    800009c6:	00053823          	sd	zero,16(a0)
  lk->nts = 0;
    800009ca:	00052e23          	sw	zero,28(a0)
  lk->n = 0;
    800009ce:	00052c23          	sw	zero,24(a0)
  if(nlock >= NLOCK)
    800009d2:	0002b797          	auipc	a5,0x2b
    800009d6:	6527a783          	lw	a5,1618(a5) # 8002c024 <nlock>
    800009da:	3e700713          	li	a4,999
    800009de:	02f74063          	blt	a4,a5,800009fe <initlock+0x3e>
    panic("initlock");
  locks[nlock] = lk;
    800009e2:	00379693          	slli	a3,a5,0x3
    800009e6:	00012717          	auipc	a4,0x12
    800009ea:	f1a70713          	addi	a4,a4,-230 # 80012900 <locks>
    800009ee:	9736                	add	a4,a4,a3
    800009f0:	e308                	sd	a0,0(a4)
  nlock++;
    800009f2:	2785                	addiw	a5,a5,1
    800009f4:	0002b717          	auipc	a4,0x2b
    800009f8:	62f72823          	sw	a5,1584(a4) # 8002c024 <nlock>
    800009fc:	8082                	ret
{
    800009fe:	1141                	addi	sp,sp,-16
    80000a00:	e406                	sd	ra,8(sp)
    80000a02:	e022                	sd	s0,0(sp)
    80000a04:	0800                	addi	s0,sp,16
    panic("initlock");
    80000a06:	00008517          	auipc	a0,0x8
    80000a0a:	82250513          	addi	a0,a0,-2014 # 80008228 <userret+0x198>
    80000a0e:	00000097          	auipc	ra,0x0
    80000a12:	b3a080e7          	jalr	-1222(ra) # 80000548 <panic>

0000000080000a16 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000a16:	1101                	addi	sp,sp,-32
    80000a18:	ec06                	sd	ra,24(sp)
    80000a1a:	e822                	sd	s0,16(sp)
    80000a1c:	e426                	sd	s1,8(sp)
    80000a1e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000a20:	100024f3          	csrr	s1,sstatus
    80000a24:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000a28:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000a2a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000a2e:	00001097          	auipc	ra,0x1
    80000a32:	01c080e7          	jalr	28(ra) # 80001a4a <mycpu>
    80000a36:	5d3c                	lw	a5,120(a0)
    80000a38:	cf89                	beqz	a5,80000a52 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000a3a:	00001097          	auipc	ra,0x1
    80000a3e:	010080e7          	jalr	16(ra) # 80001a4a <mycpu>
    80000a42:	5d3c                	lw	a5,120(a0)
    80000a44:	2785                	addiw	a5,a5,1
    80000a46:	dd3c                	sw	a5,120(a0)
}
    80000a48:	60e2                	ld	ra,24(sp)
    80000a4a:	6442                	ld	s0,16(sp)
    80000a4c:	64a2                	ld	s1,8(sp)
    80000a4e:	6105                	addi	sp,sp,32
    80000a50:	8082                	ret
    mycpu()->intena = old;
    80000a52:	00001097          	auipc	ra,0x1
    80000a56:	ff8080e7          	jalr	-8(ra) # 80001a4a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000a5a:	8085                	srli	s1,s1,0x1
    80000a5c:	8885                	andi	s1,s1,1
    80000a5e:	dd64                	sw	s1,124(a0)
    80000a60:	bfe9                	j	80000a3a <push_off+0x24>

0000000080000a62 <pop_off>:

void
pop_off(void)
{
    80000a62:	1141                	addi	sp,sp,-16
    80000a64:	e406                	sd	ra,8(sp)
    80000a66:	e022                	sd	s0,0(sp)
    80000a68:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000a6a:	00001097          	auipc	ra,0x1
    80000a6e:	fe0080e7          	jalr	-32(ra) # 80001a4a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000a72:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000a76:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000a78:	eb9d                	bnez	a5,80000aae <pop_off+0x4c>
    panic("pop_off - interruptible");
  c->noff -= 1;
    80000a7a:	5d3c                	lw	a5,120(a0)
    80000a7c:	37fd                	addiw	a5,a5,-1
    80000a7e:	0007871b          	sext.w	a4,a5
    80000a82:	dd3c                	sw	a5,120(a0)
  if(c->noff < 0)
    80000a84:	02074d63          	bltz	a4,80000abe <pop_off+0x5c>
    panic("pop_off");
  if(c->noff == 0 && c->intena)
    80000a88:	ef19                	bnez	a4,80000aa6 <pop_off+0x44>
    80000a8a:	5d7c                	lw	a5,124(a0)
    80000a8c:	cf89                	beqz	a5,80000aa6 <pop_off+0x44>
  asm volatile("csrr %0, sie" : "=r" (x) );
    80000a8e:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    80000a92:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    80000a96:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000a9a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000a9e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000aa2:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000aa6:	60a2                	ld	ra,8(sp)
    80000aa8:	6402                	ld	s0,0(sp)
    80000aaa:	0141                	addi	sp,sp,16
    80000aac:	8082                	ret
    panic("pop_off - interruptible");
    80000aae:	00007517          	auipc	a0,0x7
    80000ab2:	78a50513          	addi	a0,a0,1930 # 80008238 <userret+0x1a8>
    80000ab6:	00000097          	auipc	ra,0x0
    80000aba:	a92080e7          	jalr	-1390(ra) # 80000548 <panic>
    panic("pop_off");
    80000abe:	00007517          	auipc	a0,0x7
    80000ac2:	79250513          	addi	a0,a0,1938 # 80008250 <userret+0x1c0>
    80000ac6:	00000097          	auipc	ra,0x0
    80000aca:	a82080e7          	jalr	-1406(ra) # 80000548 <panic>

0000000080000ace <holding>:
{
    80000ace:	1101                	addi	sp,sp,-32
    80000ad0:	ec06                	sd	ra,24(sp)
    80000ad2:	e822                	sd	s0,16(sp)
    80000ad4:	e426                	sd	s1,8(sp)
    80000ad6:	1000                	addi	s0,sp,32
    80000ad8:	84aa                	mv	s1,a0
  push_off();
    80000ada:	00000097          	auipc	ra,0x0
    80000ade:	f3c080e7          	jalr	-196(ra) # 80000a16 <push_off>
  r = (lk->locked && lk->cpu == mycpu());
    80000ae2:	409c                	lw	a5,0(s1)
    80000ae4:	ef81                	bnez	a5,80000afc <holding+0x2e>
    80000ae6:	4481                	li	s1,0
  pop_off();
    80000ae8:	00000097          	auipc	ra,0x0
    80000aec:	f7a080e7          	jalr	-134(ra) # 80000a62 <pop_off>
}
    80000af0:	8526                	mv	a0,s1
    80000af2:	60e2                	ld	ra,24(sp)
    80000af4:	6442                	ld	s0,16(sp)
    80000af6:	64a2                	ld	s1,8(sp)
    80000af8:	6105                	addi	sp,sp,32
    80000afa:	8082                	ret
  r = (lk->locked && lk->cpu == mycpu());
    80000afc:	6884                	ld	s1,16(s1)
    80000afe:	00001097          	auipc	ra,0x1
    80000b02:	f4c080e7          	jalr	-180(ra) # 80001a4a <mycpu>
    80000b06:	8c89                	sub	s1,s1,a0
    80000b08:	0014b493          	seqz	s1,s1
    80000b0c:	bff1                	j	80000ae8 <holding+0x1a>

0000000080000b0e <acquire>:
{
    80000b0e:	1101                	addi	sp,sp,-32
    80000b10:	ec06                	sd	ra,24(sp)
    80000b12:	e822                	sd	s0,16(sp)
    80000b14:	e426                	sd	s1,8(sp)
    80000b16:	1000                	addi	s0,sp,32
    80000b18:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000b1a:	00000097          	auipc	ra,0x0
    80000b1e:	efc080e7          	jalr	-260(ra) # 80000a16 <push_off>
  if(holding(lk))
    80000b22:	8526                	mv	a0,s1
    80000b24:	00000097          	auipc	ra,0x0
    80000b28:	faa080e7          	jalr	-86(ra) # 80000ace <holding>
    80000b2c:	e911                	bnez	a0,80000b40 <acquire+0x32>
  __sync_fetch_and_add(&(lk->n), 1);
    80000b2e:	4785                	li	a5,1
    80000b30:	01848713          	addi	a4,s1,24
    80000b34:	0f50000f          	fence	iorw,ow
    80000b38:	04f7202f          	amoadd.w.aq	zero,a5,(a4)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000b3c:	4705                	li	a4,1
    80000b3e:	a839                	j	80000b5c <acquire+0x4e>
    panic("acquire");
    80000b40:	00007517          	auipc	a0,0x7
    80000b44:	71850513          	addi	a0,a0,1816 # 80008258 <userret+0x1c8>
    80000b48:	00000097          	auipc	ra,0x0
    80000b4c:	a00080e7          	jalr	-1536(ra) # 80000548 <panic>
     __sync_fetch_and_add(&lk->nts, 1);
    80000b50:	01c48793          	addi	a5,s1,28
    80000b54:	0f50000f          	fence	iorw,ow
    80000b58:	04e7a02f          	amoadd.w.aq	zero,a4,(a5)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000b5c:	87ba                	mv	a5,a4
    80000b5e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000b62:	2781                	sext.w	a5,a5
    80000b64:	f7f5                	bnez	a5,80000b50 <acquire+0x42>
  __sync_synchronize();
    80000b66:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000b6a:	00001097          	auipc	ra,0x1
    80000b6e:	ee0080e7          	jalr	-288(ra) # 80001a4a <mycpu>
    80000b72:	e888                	sd	a0,16(s1)
}
    80000b74:	60e2                	ld	ra,24(sp)
    80000b76:	6442                	ld	s0,16(sp)
    80000b78:	64a2                	ld	s1,8(sp)
    80000b7a:	6105                	addi	sp,sp,32
    80000b7c:	8082                	ret

0000000080000b7e <release>:
{
    80000b7e:	1101                	addi	sp,sp,-32
    80000b80:	ec06                	sd	ra,24(sp)
    80000b82:	e822                	sd	s0,16(sp)
    80000b84:	e426                	sd	s1,8(sp)
    80000b86:	1000                	addi	s0,sp,32
    80000b88:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000b8a:	00000097          	auipc	ra,0x0
    80000b8e:	f44080e7          	jalr	-188(ra) # 80000ace <holding>
    80000b92:	c115                	beqz	a0,80000bb6 <release+0x38>
  lk->cpu = 0;
    80000b94:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000b98:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000b9c:	0f50000f          	fence	iorw,ow
    80000ba0:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000ba4:	00000097          	auipc	ra,0x0
    80000ba8:	ebe080e7          	jalr	-322(ra) # 80000a62 <pop_off>
}
    80000bac:	60e2                	ld	ra,24(sp)
    80000bae:	6442                	ld	s0,16(sp)
    80000bb0:	64a2                	ld	s1,8(sp)
    80000bb2:	6105                	addi	sp,sp,32
    80000bb4:	8082                	ret
    panic("release");
    80000bb6:	00007517          	auipc	a0,0x7
    80000bba:	6aa50513          	addi	a0,a0,1706 # 80008260 <userret+0x1d0>
    80000bbe:	00000097          	auipc	ra,0x0
    80000bc2:	98a080e7          	jalr	-1654(ra) # 80000548 <panic>

0000000080000bc6 <print_lock>:

void
print_lock(struct spinlock *lk)
{
  if(lk->n > 0) 
    80000bc6:	4d14                	lw	a3,24(a0)
    80000bc8:	e291                	bnez	a3,80000bcc <print_lock+0x6>
    80000bca:	8082                	ret
{
    80000bcc:	1141                	addi	sp,sp,-16
    80000bce:	e406                	sd	ra,8(sp)
    80000bd0:	e022                	sd	s0,0(sp)
    80000bd2:	0800                	addi	s0,sp,16
    printf("lock: %s: #test-and-set %d #acquire() %d\n", lk->name, lk->nts, lk->n);
    80000bd4:	4d50                	lw	a2,28(a0)
    80000bd6:	650c                	ld	a1,8(a0)
    80000bd8:	00007517          	auipc	a0,0x7
    80000bdc:	69050513          	addi	a0,a0,1680 # 80008268 <userret+0x1d8>
    80000be0:	00000097          	auipc	ra,0x0
    80000be4:	9c2080e7          	jalr	-1598(ra) # 800005a2 <printf>
}
    80000be8:	60a2                	ld	ra,8(sp)
    80000bea:	6402                	ld	s0,0(sp)
    80000bec:	0141                	addi	sp,sp,16
    80000bee:	8082                	ret

0000000080000bf0 <sys_ntas>:

uint64
sys_ntas(void)
{
    80000bf0:	711d                	addi	sp,sp,-96
    80000bf2:	ec86                	sd	ra,88(sp)
    80000bf4:	e8a2                	sd	s0,80(sp)
    80000bf6:	e4a6                	sd	s1,72(sp)
    80000bf8:	e0ca                	sd	s2,64(sp)
    80000bfa:	fc4e                	sd	s3,56(sp)
    80000bfc:	f852                	sd	s4,48(sp)
    80000bfe:	f456                	sd	s5,40(sp)
    80000c00:	f05a                	sd	s6,32(sp)
    80000c02:	ec5e                	sd	s7,24(sp)
    80000c04:	e862                	sd	s8,16(sp)
    80000c06:	1080                	addi	s0,sp,96
  int zero = 0;
    80000c08:	fa042623          	sw	zero,-84(s0)
  int tot = 0;
  
  if (argint(0, &zero) < 0) {
    80000c0c:	fac40593          	addi	a1,s0,-84
    80000c10:	4501                	li	a0,0
    80000c12:	00002097          	auipc	ra,0x2
    80000c16:	ece080e7          	jalr	-306(ra) # 80002ae0 <argint>
    80000c1a:	14054d63          	bltz	a0,80000d74 <sys_ntas+0x184>
    return -1;
  }
  if(zero == 0) {
    80000c1e:	fac42783          	lw	a5,-84(s0)
    80000c22:	e78d                	bnez	a5,80000c4c <sys_ntas+0x5c>
    80000c24:	00012797          	auipc	a5,0x12
    80000c28:	cdc78793          	addi	a5,a5,-804 # 80012900 <locks>
    80000c2c:	00014697          	auipc	a3,0x14
    80000c30:	c1468693          	addi	a3,a3,-1004 # 80014840 <pid_lock>
    for(int i = 0; i < NLOCK; i++) {
      if(locks[i] == 0)
    80000c34:	6398                	ld	a4,0(a5)
    80000c36:	14070163          	beqz	a4,80000d78 <sys_ntas+0x188>
        break;
      locks[i]->nts = 0;
    80000c3a:	00072e23          	sw	zero,28(a4)
      locks[i]->n = 0;
    80000c3e:	00072c23          	sw	zero,24(a4)
    for(int i = 0; i < NLOCK; i++) {
    80000c42:	07a1                	addi	a5,a5,8
    80000c44:	fed798e3          	bne	a5,a3,80000c34 <sys_ntas+0x44>
    }
    return 0;
    80000c48:	4501                	li	a0,0
    80000c4a:	aa09                	j	80000d5c <sys_ntas+0x16c>
  }

  printf("=== lock kmem/bcache stats\n");
    80000c4c:	00007517          	auipc	a0,0x7
    80000c50:	64c50513          	addi	a0,a0,1612 # 80008298 <userret+0x208>
    80000c54:	00000097          	auipc	ra,0x0
    80000c58:	94e080e7          	jalr	-1714(ra) # 800005a2 <printf>
  for(int i = 0; i < NLOCK; i++) {
    80000c5c:	00012b17          	auipc	s6,0x12
    80000c60:	ca4b0b13          	addi	s6,s6,-860 # 80012900 <locks>
    80000c64:	00014b97          	auipc	s7,0x14
    80000c68:	bdcb8b93          	addi	s7,s7,-1060 # 80014840 <pid_lock>
  printf("=== lock kmem/bcache stats\n");
    80000c6c:	84da                	mv	s1,s6
  int tot = 0;
    80000c6e:	4981                	li	s3,0
    if(locks[i] == 0)
      break;
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000c70:	00007a17          	auipc	s4,0x7
    80000c74:	648a0a13          	addi	s4,s4,1608 # 800082b8 <userret+0x228>
       strncmp(locks[i]->name, "kmem", strlen("kmem")) == 0) {
    80000c78:	00007c17          	auipc	s8,0x7
    80000c7c:	5a8c0c13          	addi	s8,s8,1448 # 80008220 <userret+0x190>
    80000c80:	a829                	j	80000c9a <sys_ntas+0xaa>
      tot += locks[i]->nts;
    80000c82:	00093503          	ld	a0,0(s2)
    80000c86:	4d5c                	lw	a5,28(a0)
    80000c88:	013789bb          	addw	s3,a5,s3
      print_lock(locks[i]);
    80000c8c:	00000097          	auipc	ra,0x0
    80000c90:	f3a080e7          	jalr	-198(ra) # 80000bc6 <print_lock>
  for(int i = 0; i < NLOCK; i++) {
    80000c94:	04a1                	addi	s1,s1,8
    80000c96:	05748763          	beq	s1,s7,80000ce4 <sys_ntas+0xf4>
    if(locks[i] == 0)
    80000c9a:	8926                	mv	s2,s1
    80000c9c:	609c                	ld	a5,0(s1)
    80000c9e:	c3b9                	beqz	a5,80000ce4 <sys_ntas+0xf4>
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000ca0:	0087ba83          	ld	s5,8(a5)
    80000ca4:	8552                	mv	a0,s4
    80000ca6:	00000097          	auipc	ra,0x0
    80000caa:	25a080e7          	jalr	602(ra) # 80000f00 <strlen>
    80000cae:	0005061b          	sext.w	a2,a0
    80000cb2:	85d2                	mv	a1,s4
    80000cb4:	8556                	mv	a0,s5
    80000cb6:	00000097          	auipc	ra,0x0
    80000cba:	19e080e7          	jalr	414(ra) # 80000e54 <strncmp>
    80000cbe:	d171                	beqz	a0,80000c82 <sys_ntas+0x92>
       strncmp(locks[i]->name, "kmem", strlen("kmem")) == 0) {
    80000cc0:	609c                	ld	a5,0(s1)
    80000cc2:	0087ba83          	ld	s5,8(a5)
    80000cc6:	8562                	mv	a0,s8
    80000cc8:	00000097          	auipc	ra,0x0
    80000ccc:	238080e7          	jalr	568(ra) # 80000f00 <strlen>
    80000cd0:	0005061b          	sext.w	a2,a0
    80000cd4:	85e2                	mv	a1,s8
    80000cd6:	8556                	mv	a0,s5
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	17c080e7          	jalr	380(ra) # 80000e54 <strncmp>
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000ce0:	f955                	bnez	a0,80000c94 <sys_ntas+0xa4>
    80000ce2:	b745                	j	80000c82 <sys_ntas+0x92>
    }
  }

  printf("=== top 5 contended locks:\n");
    80000ce4:	00007517          	auipc	a0,0x7
    80000ce8:	5dc50513          	addi	a0,a0,1500 # 800082c0 <userret+0x230>
    80000cec:	00000097          	auipc	ra,0x0
    80000cf0:	8b6080e7          	jalr	-1866(ra) # 800005a2 <printf>
    80000cf4:	4a15                	li	s4,5
  int last = 100000000;
    80000cf6:	05f5e537          	lui	a0,0x5f5e
    80000cfa:	10050513          	addi	a0,a0,256 # 5f5e100 <_entry-0x7a0a1f00>
  // stupid way to compute top 5 contended locks
  for(int t= 0; t < 5; t++) {
    int top = 0;
    for(int i = 0; i < NLOCK; i++) {
    80000cfe:	4a81                	li	s5,0
      if(locks[i] == 0)
        break;
      if(locks[i]->nts > locks[top]->nts && locks[i]->nts < last) {
    80000d00:	00012497          	auipc	s1,0x12
    80000d04:	c0048493          	addi	s1,s1,-1024 # 80012900 <locks>
    for(int i = 0; i < NLOCK; i++) {
    80000d08:	3e800913          	li	s2,1000
    80000d0c:	a091                	j	80000d50 <sys_ntas+0x160>
    80000d0e:	2705                	addiw	a4,a4,1
    80000d10:	06a1                	addi	a3,a3,8
    80000d12:	03270063          	beq	a4,s2,80000d32 <sys_ntas+0x142>
      if(locks[i] == 0)
    80000d16:	629c                	ld	a5,0(a3)
    80000d18:	cf89                	beqz	a5,80000d32 <sys_ntas+0x142>
      if(locks[i]->nts > locks[top]->nts && locks[i]->nts < last) {
    80000d1a:	4fd0                	lw	a2,28(a5)
    80000d1c:	00359793          	slli	a5,a1,0x3
    80000d20:	97a6                	add	a5,a5,s1
    80000d22:	639c                	ld	a5,0(a5)
    80000d24:	4fdc                	lw	a5,28(a5)
    80000d26:	fec7f4e3          	bgeu	a5,a2,80000d0e <sys_ntas+0x11e>
    80000d2a:	fea672e3          	bgeu	a2,a0,80000d0e <sys_ntas+0x11e>
    80000d2e:	85ba                	mv	a1,a4
    80000d30:	bff9                	j	80000d0e <sys_ntas+0x11e>
        top = i;
      }
    }
    print_lock(locks[top]);
    80000d32:	058e                	slli	a1,a1,0x3
    80000d34:	00b48bb3          	add	s7,s1,a1
    80000d38:	000bb503          	ld	a0,0(s7)
    80000d3c:	00000097          	auipc	ra,0x0
    80000d40:	e8a080e7          	jalr	-374(ra) # 80000bc6 <print_lock>
    last = locks[top]->nts;
    80000d44:	000bb783          	ld	a5,0(s7)
    80000d48:	4fc8                	lw	a0,28(a5)
  for(int t= 0; t < 5; t++) {
    80000d4a:	3a7d                	addiw	s4,s4,-1
    80000d4c:	000a0763          	beqz	s4,80000d5a <sys_ntas+0x16a>
  int tot = 0;
    80000d50:	86da                	mv	a3,s6
    for(int i = 0; i < NLOCK; i++) {
    80000d52:	8756                	mv	a4,s5
    int top = 0;
    80000d54:	85d6                	mv	a1,s5
      if(locks[i]->nts > locks[top]->nts && locks[i]->nts < last) {
    80000d56:	2501                	sext.w	a0,a0
    80000d58:	bf7d                	j	80000d16 <sys_ntas+0x126>
  }
  return tot;
    80000d5a:	854e                	mv	a0,s3
}
    80000d5c:	60e6                	ld	ra,88(sp)
    80000d5e:	6446                	ld	s0,80(sp)
    80000d60:	64a6                	ld	s1,72(sp)
    80000d62:	6906                	ld	s2,64(sp)
    80000d64:	79e2                	ld	s3,56(sp)
    80000d66:	7a42                	ld	s4,48(sp)
    80000d68:	7aa2                	ld	s5,40(sp)
    80000d6a:	7b02                	ld	s6,32(sp)
    80000d6c:	6be2                	ld	s7,24(sp)
    80000d6e:	6c42                	ld	s8,16(sp)
    80000d70:	6125                	addi	sp,sp,96
    80000d72:	8082                	ret
    return -1;
    80000d74:	557d                	li	a0,-1
    80000d76:	b7dd                	j	80000d5c <sys_ntas+0x16c>
    return 0;
    80000d78:	4501                	li	a0,0
    80000d7a:	b7cd                	j	80000d5c <sys_ntas+0x16c>

0000000080000d7c <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d7c:	1141                	addi	sp,sp,-16
    80000d7e:	e422                	sd	s0,8(sp)
    80000d80:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d82:	ca19                	beqz	a2,80000d98 <memset+0x1c>
    80000d84:	87aa                	mv	a5,a0
    80000d86:	1602                	slli	a2,a2,0x20
    80000d88:	9201                	srli	a2,a2,0x20
    80000d8a:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d8e:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d92:	0785                	addi	a5,a5,1
    80000d94:	fee79de3          	bne	a5,a4,80000d8e <memset+0x12>
  }
  return dst;
}
    80000d98:	6422                	ld	s0,8(sp)
    80000d9a:	0141                	addi	sp,sp,16
    80000d9c:	8082                	ret

0000000080000d9e <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d9e:	1141                	addi	sp,sp,-16
    80000da0:	e422                	sd	s0,8(sp)
    80000da2:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000da4:	ca05                	beqz	a2,80000dd4 <memcmp+0x36>
    80000da6:	fff6069b          	addiw	a3,a2,-1
    80000daa:	1682                	slli	a3,a3,0x20
    80000dac:	9281                	srli	a3,a3,0x20
    80000dae:	0685                	addi	a3,a3,1
    80000db0:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000db2:	00054783          	lbu	a5,0(a0)
    80000db6:	0005c703          	lbu	a4,0(a1)
    80000dba:	00e79863          	bne	a5,a4,80000dca <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000dbe:	0505                	addi	a0,a0,1
    80000dc0:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000dc2:	fed518e3          	bne	a0,a3,80000db2 <memcmp+0x14>
  }

  return 0;
    80000dc6:	4501                	li	a0,0
    80000dc8:	a019                	j	80000dce <memcmp+0x30>
      return *s1 - *s2;
    80000dca:	40e7853b          	subw	a0,a5,a4
}
    80000dce:	6422                	ld	s0,8(sp)
    80000dd0:	0141                	addi	sp,sp,16
    80000dd2:	8082                	ret
  return 0;
    80000dd4:	4501                	li	a0,0
    80000dd6:	bfe5                	j	80000dce <memcmp+0x30>

0000000080000dd8 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000dd8:	1141                	addi	sp,sp,-16
    80000dda:	e422                	sd	s0,8(sp)
    80000ddc:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000dde:	02a5e563          	bltu	a1,a0,80000e08 <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000de2:	fff6069b          	addiw	a3,a2,-1
    80000de6:	ce11                	beqz	a2,80000e02 <memmove+0x2a>
    80000de8:	1682                	slli	a3,a3,0x20
    80000dea:	9281                	srli	a3,a3,0x20
    80000dec:	0685                	addi	a3,a3,1
    80000dee:	96ae                	add	a3,a3,a1
    80000df0:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000df2:	0585                	addi	a1,a1,1
    80000df4:	0785                	addi	a5,a5,1
    80000df6:	fff5c703          	lbu	a4,-1(a1)
    80000dfa:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000dfe:	fed59ae3          	bne	a1,a3,80000df2 <memmove+0x1a>

  return dst;
}
    80000e02:	6422                	ld	s0,8(sp)
    80000e04:	0141                	addi	sp,sp,16
    80000e06:	8082                	ret
  if(s < d && s + n > d){
    80000e08:	02061713          	slli	a4,a2,0x20
    80000e0c:	9301                	srli	a4,a4,0x20
    80000e0e:	00e587b3          	add	a5,a1,a4
    80000e12:	fcf578e3          	bgeu	a0,a5,80000de2 <memmove+0xa>
    d += n;
    80000e16:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000e18:	fff6069b          	addiw	a3,a2,-1
    80000e1c:	d27d                	beqz	a2,80000e02 <memmove+0x2a>
    80000e1e:	02069613          	slli	a2,a3,0x20
    80000e22:	9201                	srli	a2,a2,0x20
    80000e24:	fff64613          	not	a2,a2
    80000e28:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000e2a:	17fd                	addi	a5,a5,-1
    80000e2c:	177d                	addi	a4,a4,-1
    80000e2e:	0007c683          	lbu	a3,0(a5)
    80000e32:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000e36:	fef61ae3          	bne	a2,a5,80000e2a <memmove+0x52>
    80000e3a:	b7e1                	j	80000e02 <memmove+0x2a>

0000000080000e3c <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e3c:	1141                	addi	sp,sp,-16
    80000e3e:	e406                	sd	ra,8(sp)
    80000e40:	e022                	sd	s0,0(sp)
    80000e42:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e44:	00000097          	auipc	ra,0x0
    80000e48:	f94080e7          	jalr	-108(ra) # 80000dd8 <memmove>
}
    80000e4c:	60a2                	ld	ra,8(sp)
    80000e4e:	6402                	ld	s0,0(sp)
    80000e50:	0141                	addi	sp,sp,16
    80000e52:	8082                	ret

0000000080000e54 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e54:	1141                	addi	sp,sp,-16
    80000e56:	e422                	sd	s0,8(sp)
    80000e58:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e5a:	ce11                	beqz	a2,80000e76 <strncmp+0x22>
    80000e5c:	00054783          	lbu	a5,0(a0)
    80000e60:	cf89                	beqz	a5,80000e7a <strncmp+0x26>
    80000e62:	0005c703          	lbu	a4,0(a1)
    80000e66:	00f71a63          	bne	a4,a5,80000e7a <strncmp+0x26>
    n--, p++, q++;
    80000e6a:	367d                	addiw	a2,a2,-1
    80000e6c:	0505                	addi	a0,a0,1
    80000e6e:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e70:	f675                	bnez	a2,80000e5c <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e72:	4501                	li	a0,0
    80000e74:	a809                	j	80000e86 <strncmp+0x32>
    80000e76:	4501                	li	a0,0
    80000e78:	a039                	j	80000e86 <strncmp+0x32>
  if(n == 0)
    80000e7a:	ca09                	beqz	a2,80000e8c <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e7c:	00054503          	lbu	a0,0(a0)
    80000e80:	0005c783          	lbu	a5,0(a1)
    80000e84:	9d1d                	subw	a0,a0,a5
}
    80000e86:	6422                	ld	s0,8(sp)
    80000e88:	0141                	addi	sp,sp,16
    80000e8a:	8082                	ret
    return 0;
    80000e8c:	4501                	li	a0,0
    80000e8e:	bfe5                	j	80000e86 <strncmp+0x32>

0000000080000e90 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e90:	1141                	addi	sp,sp,-16
    80000e92:	e422                	sd	s0,8(sp)
    80000e94:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e96:	872a                	mv	a4,a0
    80000e98:	8832                	mv	a6,a2
    80000e9a:	367d                	addiw	a2,a2,-1
    80000e9c:	01005963          	blez	a6,80000eae <strncpy+0x1e>
    80000ea0:	0705                	addi	a4,a4,1
    80000ea2:	0005c783          	lbu	a5,0(a1)
    80000ea6:	fef70fa3          	sb	a5,-1(a4)
    80000eaa:	0585                	addi	a1,a1,1
    80000eac:	f7f5                	bnez	a5,80000e98 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000eae:	86ba                	mv	a3,a4
    80000eb0:	00c05c63          	blez	a2,80000ec8 <strncpy+0x38>
    *s++ = 0;
    80000eb4:	0685                	addi	a3,a3,1
    80000eb6:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000eba:	fff6c793          	not	a5,a3
    80000ebe:	9fb9                	addw	a5,a5,a4
    80000ec0:	010787bb          	addw	a5,a5,a6
    80000ec4:	fef048e3          	bgtz	a5,80000eb4 <strncpy+0x24>
  return os;
}
    80000ec8:	6422                	ld	s0,8(sp)
    80000eca:	0141                	addi	sp,sp,16
    80000ecc:	8082                	ret

0000000080000ece <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000ece:	1141                	addi	sp,sp,-16
    80000ed0:	e422                	sd	s0,8(sp)
    80000ed2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000ed4:	02c05363          	blez	a2,80000efa <safestrcpy+0x2c>
    80000ed8:	fff6069b          	addiw	a3,a2,-1
    80000edc:	1682                	slli	a3,a3,0x20
    80000ede:	9281                	srli	a3,a3,0x20
    80000ee0:	96ae                	add	a3,a3,a1
    80000ee2:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000ee4:	00d58963          	beq	a1,a3,80000ef6 <safestrcpy+0x28>
    80000ee8:	0585                	addi	a1,a1,1
    80000eea:	0785                	addi	a5,a5,1
    80000eec:	fff5c703          	lbu	a4,-1(a1)
    80000ef0:	fee78fa3          	sb	a4,-1(a5)
    80000ef4:	fb65                	bnez	a4,80000ee4 <safestrcpy+0x16>
    ;
  *s = 0;
    80000ef6:	00078023          	sb	zero,0(a5)
  return os;
}
    80000efa:	6422                	ld	s0,8(sp)
    80000efc:	0141                	addi	sp,sp,16
    80000efe:	8082                	ret

0000000080000f00 <strlen>:

int
strlen(const char *s)
{
    80000f00:	1141                	addi	sp,sp,-16
    80000f02:	e422                	sd	s0,8(sp)
    80000f04:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f06:	00054783          	lbu	a5,0(a0)
    80000f0a:	cf91                	beqz	a5,80000f26 <strlen+0x26>
    80000f0c:	0505                	addi	a0,a0,1
    80000f0e:	87aa                	mv	a5,a0
    80000f10:	4685                	li	a3,1
    80000f12:	9e89                	subw	a3,a3,a0
    80000f14:	00f6853b          	addw	a0,a3,a5
    80000f18:	0785                	addi	a5,a5,1
    80000f1a:	fff7c703          	lbu	a4,-1(a5)
    80000f1e:	fb7d                	bnez	a4,80000f14 <strlen+0x14>
    ;
  return n;
}
    80000f20:	6422                	ld	s0,8(sp)
    80000f22:	0141                	addi	sp,sp,16
    80000f24:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f26:	4501                	li	a0,0
    80000f28:	bfe5                	j	80000f20 <strlen+0x20>

0000000080000f2a <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f2a:	1141                	addi	sp,sp,-16
    80000f2c:	e406                	sd	ra,8(sp)
    80000f2e:	e022                	sd	s0,0(sp)
    80000f30:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f32:	00001097          	auipc	ra,0x1
    80000f36:	b08080e7          	jalr	-1272(ra) # 80001a3a <cpuid>
    virtio_disk_init(minor(ROOTDEV)); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f3a:	0002b717          	auipc	a4,0x2b
    80000f3e:	0ee70713          	addi	a4,a4,238 # 8002c028 <started>
  if(cpuid() == 0){
    80000f42:	c139                	beqz	a0,80000f88 <main+0x5e>
    while(started == 0)
    80000f44:	431c                	lw	a5,0(a4)
    80000f46:	2781                	sext.w	a5,a5
    80000f48:	dff5                	beqz	a5,80000f44 <main+0x1a>
      ;
    __sync_synchronize();
    80000f4a:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f4e:	00001097          	auipc	ra,0x1
    80000f52:	aec080e7          	jalr	-1300(ra) # 80001a3a <cpuid>
    80000f56:	85aa                	mv	a1,a0
    80000f58:	00007517          	auipc	a0,0x7
    80000f5c:	3a050513          	addi	a0,a0,928 # 800082f8 <userret+0x268>
    80000f60:	fffff097          	auipc	ra,0xfffff
    80000f64:	642080e7          	jalr	1602(ra) # 800005a2 <printf>
    kvminithart();    // turn on paging
    80000f68:	00000097          	auipc	ra,0x0
    80000f6c:	1ea080e7          	jalr	490(ra) # 80001152 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	714080e7          	jalr	1812(ra) # 80002684 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f78:	00005097          	auipc	ra,0x5
    80000f7c:	dc8080e7          	jalr	-568(ra) # 80005d40 <plicinithart>
  }

  scheduler();        
    80000f80:	00001097          	auipc	ra,0x1
    80000f84:	fc4080e7          	jalr	-60(ra) # 80001f44 <scheduler>
    consoleinit();
    80000f88:	fffff097          	auipc	ra,0xfffff
    80000f8c:	4d2080e7          	jalr	1234(ra) # 8000045a <consoleinit>
    printfinit();
    80000f90:	fffff097          	auipc	ra,0xfffff
    80000f94:	7f2080e7          	jalr	2034(ra) # 80000782 <printfinit>
    printf("\n");
    80000f98:	00007517          	auipc	a0,0x7
    80000f9c:	2f850513          	addi	a0,a0,760 # 80008290 <userret+0x200>
    80000fa0:	fffff097          	auipc	ra,0xfffff
    80000fa4:	602080e7          	jalr	1538(ra) # 800005a2 <printf>
    printf("xv6 kernel is booting\n");
    80000fa8:	00007517          	auipc	a0,0x7
    80000fac:	33850513          	addi	a0,a0,824 # 800082e0 <userret+0x250>
    80000fb0:	fffff097          	auipc	ra,0xfffff
    80000fb4:	5f2080e7          	jalr	1522(ra) # 800005a2 <printf>
    printf("\n");
    80000fb8:	00007517          	auipc	a0,0x7
    80000fbc:	2d850513          	addi	a0,a0,728 # 80008290 <userret+0x200>
    80000fc0:	fffff097          	auipc	ra,0xfffff
    80000fc4:	5e2080e7          	jalr	1506(ra) # 800005a2 <printf>
    kinit();         // physical page allocator
    80000fc8:	00000097          	auipc	ra,0x0
    80000fcc:	95c080e7          	jalr	-1700(ra) # 80000924 <kinit>
    kvminit();       // create kernel page table
    80000fd0:	00000097          	auipc	ra,0x0
    80000fd4:	30c080e7          	jalr	780(ra) # 800012dc <kvminit>
    kvminithart();   // turn on paging
    80000fd8:	00000097          	auipc	ra,0x0
    80000fdc:	17a080e7          	jalr	378(ra) # 80001152 <kvminithart>
    procinit();      // process table
    80000fe0:	00001097          	auipc	ra,0x1
    80000fe4:	98a080e7          	jalr	-1654(ra) # 8000196a <procinit>
    trapinit();      // trap vectors
    80000fe8:	00001097          	auipc	ra,0x1
    80000fec:	674080e7          	jalr	1652(ra) # 8000265c <trapinit>
    trapinithart();  // install kernel trap vector
    80000ff0:	00001097          	auipc	ra,0x1
    80000ff4:	694080e7          	jalr	1684(ra) # 80002684 <trapinithart>
    plicinit();      // set up interrupt controller
    80000ff8:	00005097          	auipc	ra,0x5
    80000ffc:	d32080e7          	jalr	-718(ra) # 80005d2a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001000:	00005097          	auipc	ra,0x5
    80001004:	d40080e7          	jalr	-704(ra) # 80005d40 <plicinithart>
    binit();         // buffer cache
    80001008:	00002097          	auipc	ra,0x2
    8000100c:	db8080e7          	jalr	-584(ra) # 80002dc0 <binit>
    iinit();         // inode cache
    80001010:	00002097          	auipc	ra,0x2
    80001014:	44e080e7          	jalr	1102(ra) # 8000345e <iinit>
    fileinit();      // file table
    80001018:	00003097          	auipc	ra,0x3
    8000101c:	4da080e7          	jalr	1242(ra) # 800044f2 <fileinit>
    virtio_disk_init(minor(ROOTDEV)); // emulated hard disk
    80001020:	4501                	li	a0,0
    80001022:	00005097          	auipc	ra,0x5
    80001026:	e40080e7          	jalr	-448(ra) # 80005e62 <virtio_disk_init>
    userinit();      // first user process
    8000102a:	00001097          	auipc	ra,0x1
    8000102e:	cb0080e7          	jalr	-848(ra) # 80001cda <userinit>
    __sync_synchronize();
    80001032:	0ff0000f          	fence
    started = 1;
    80001036:	4785                	li	a5,1
    80001038:	0002b717          	auipc	a4,0x2b
    8000103c:	fef72823          	sw	a5,-16(a4) # 8002c028 <started>
    80001040:	b781                	j	80000f80 <main+0x56>

0000000080001042 <walk>:
//   21..39 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..12 -- 12 bits of byte offset within the page.
static pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001042:	7139                	addi	sp,sp,-64
    80001044:	fc06                	sd	ra,56(sp)
    80001046:	f822                	sd	s0,48(sp)
    80001048:	f426                	sd	s1,40(sp)
    8000104a:	f04a                	sd	s2,32(sp)
    8000104c:	ec4e                	sd	s3,24(sp)
    8000104e:	e852                	sd	s4,16(sp)
    80001050:	e456                	sd	s5,8(sp)
    80001052:	e05a                	sd	s6,0(sp)
    80001054:	0080                	addi	s0,sp,64
    80001056:	84aa                	mv	s1,a0
    80001058:	89ae                	mv	s3,a1
    8000105a:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001062:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001064:	04b7f263          	bgeu	a5,a1,800010a8 <walk+0x66>
    panic("walk");
    80001068:	00007517          	auipc	a0,0x7
    8000106c:	2a850513          	addi	a0,a0,680 # 80008310 <userret+0x280>
    80001070:	fffff097          	auipc	ra,0xfffff
    80001074:	4d8080e7          	jalr	1240(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001078:	060a8663          	beqz	s5,800010e4 <walk+0xa2>
    8000107c:	00000097          	auipc	ra,0x0
    80001080:	8e4080e7          	jalr	-1820(ra) # 80000960 <kalloc>
    80001084:	84aa                	mv	s1,a0
    80001086:	c529                	beqz	a0,800010d0 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001088:	6605                	lui	a2,0x1
    8000108a:	4581                	li	a1,0
    8000108c:	00000097          	auipc	ra,0x0
    80001090:	cf0080e7          	jalr	-784(ra) # 80000d7c <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001094:	00c4d793          	srli	a5,s1,0xc
    80001098:	07aa                	slli	a5,a5,0xa
    8000109a:	0017e793          	ori	a5,a5,1
    8000109e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010a2:	3a5d                	addiw	s4,s4,-9
    800010a4:	036a0063          	beq	s4,s6,800010c4 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010a8:	0149d933          	srl	s2,s3,s4
    800010ac:	1ff97913          	andi	s2,s2,511
    800010b0:	090e                	slli	s2,s2,0x3
    800010b2:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010b4:	00093483          	ld	s1,0(s2)
    800010b8:	0014f793          	andi	a5,s1,1
    800010bc:	dfd5                	beqz	a5,80001078 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010be:	80a9                	srli	s1,s1,0xa
    800010c0:	04b2                	slli	s1,s1,0xc
    800010c2:	b7c5                	j	800010a2 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010c4:	00c9d513          	srli	a0,s3,0xc
    800010c8:	1ff57513          	andi	a0,a0,511
    800010cc:	050e                	slli	a0,a0,0x3
    800010ce:	9526                	add	a0,a0,s1
}
    800010d0:	70e2                	ld	ra,56(sp)
    800010d2:	7442                	ld	s0,48(sp)
    800010d4:	74a2                	ld	s1,40(sp)
    800010d6:	7902                	ld	s2,32(sp)
    800010d8:	69e2                	ld	s3,24(sp)
    800010da:	6a42                	ld	s4,16(sp)
    800010dc:	6aa2                	ld	s5,8(sp)
    800010de:	6b02                	ld	s6,0(sp)
    800010e0:	6121                	addi	sp,sp,64
    800010e2:	8082                	ret
        return 0;
    800010e4:	4501                	li	a0,0
    800010e6:	b7ed                	j	800010d0 <walk+0x8e>

00000000800010e8 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
static void
freewalk(pagetable_t pagetable)
{
    800010e8:	7179                	addi	sp,sp,-48
    800010ea:	f406                	sd	ra,40(sp)
    800010ec:	f022                	sd	s0,32(sp)
    800010ee:	ec26                	sd	s1,24(sp)
    800010f0:	e84a                	sd	s2,16(sp)
    800010f2:	e44e                	sd	s3,8(sp)
    800010f4:	e052                	sd	s4,0(sp)
    800010f6:	1800                	addi	s0,sp,48
    800010f8:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800010fa:	84aa                	mv	s1,a0
    800010fc:	6905                	lui	s2,0x1
    800010fe:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001100:	4985                	li	s3,1
    80001102:	a821                	j	8000111a <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001104:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001106:	0532                	slli	a0,a0,0xc
    80001108:	00000097          	auipc	ra,0x0
    8000110c:	fe0080e7          	jalr	-32(ra) # 800010e8 <freewalk>
      pagetable[i] = 0;
    80001110:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001114:	04a1                	addi	s1,s1,8
    80001116:	03248163          	beq	s1,s2,80001138 <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000111a:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000111c:	00f57793          	andi	a5,a0,15
    80001120:	ff3782e3          	beq	a5,s3,80001104 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001124:	8905                	andi	a0,a0,1
    80001126:	d57d                	beqz	a0,80001114 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001128:	00007517          	auipc	a0,0x7
    8000112c:	1f050513          	addi	a0,a0,496 # 80008318 <userret+0x288>
    80001130:	fffff097          	auipc	ra,0xfffff
    80001134:	418080e7          	jalr	1048(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    80001138:	8552                	mv	a0,s4
    8000113a:	fffff097          	auipc	ra,0xfffff
    8000113e:	72a080e7          	jalr	1834(ra) # 80000864 <kfree>
}
    80001142:	70a2                	ld	ra,40(sp)
    80001144:	7402                	ld	s0,32(sp)
    80001146:	64e2                	ld	s1,24(sp)
    80001148:	6942                	ld	s2,16(sp)
    8000114a:	69a2                	ld	s3,8(sp)
    8000114c:	6a02                	ld	s4,0(sp)
    8000114e:	6145                	addi	sp,sp,48
    80001150:	8082                	ret

0000000080001152 <kvminithart>:
{
    80001152:	1141                	addi	sp,sp,-16
    80001154:	e422                	sd	s0,8(sp)
    80001156:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001158:	0002b797          	auipc	a5,0x2b
    8000115c:	ed87b783          	ld	a5,-296(a5) # 8002c030 <kernel_pagetable>
    80001160:	83b1                	srli	a5,a5,0xc
    80001162:	577d                	li	a4,-1
    80001164:	177e                	slli	a4,a4,0x3f
    80001166:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001168:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000116c:	12000073          	sfence.vma
}
    80001170:	6422                	ld	s0,8(sp)
    80001172:	0141                	addi	sp,sp,16
    80001174:	8082                	ret

0000000080001176 <walkaddr>:
  if(va >= MAXVA)
    80001176:	57fd                	li	a5,-1
    80001178:	83e9                	srli	a5,a5,0x1a
    8000117a:	00b7f463          	bgeu	a5,a1,80001182 <walkaddr+0xc>
    return 0;
    8000117e:	4501                	li	a0,0
}
    80001180:	8082                	ret
{
    80001182:	1141                	addi	sp,sp,-16
    80001184:	e406                	sd	ra,8(sp)
    80001186:	e022                	sd	s0,0(sp)
    80001188:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000118a:	4601                	li	a2,0
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	eb6080e7          	jalr	-330(ra) # 80001042 <walk>
  if(pte == 0)
    80001194:	c105                	beqz	a0,800011b4 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001196:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001198:	0117f693          	andi	a3,a5,17
    8000119c:	4745                	li	a4,17
    return 0;
    8000119e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800011a0:	00e68663          	beq	a3,a4,800011ac <walkaddr+0x36>
}
    800011a4:	60a2                	ld	ra,8(sp)
    800011a6:	6402                	ld	s0,0(sp)
    800011a8:	0141                	addi	sp,sp,16
    800011aa:	8082                	ret
  pa = PTE2PA(*pte);
    800011ac:	00a7d513          	srli	a0,a5,0xa
    800011b0:	0532                	slli	a0,a0,0xc
  return pa;
    800011b2:	bfcd                	j	800011a4 <walkaddr+0x2e>
    return 0;
    800011b4:	4501                	li	a0,0
    800011b6:	b7fd                	j	800011a4 <walkaddr+0x2e>

00000000800011b8 <kvmpa>:
{
    800011b8:	1101                	addi	sp,sp,-32
    800011ba:	ec06                	sd	ra,24(sp)
    800011bc:	e822                	sd	s0,16(sp)
    800011be:	e426                	sd	s1,8(sp)
    800011c0:	1000                	addi	s0,sp,32
    800011c2:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    800011c4:	1552                	slli	a0,a0,0x34
    800011c6:	03455493          	srli	s1,a0,0x34
  pte = walk(kernel_pagetable, va, 0);
    800011ca:	4601                	li	a2,0
    800011cc:	0002b517          	auipc	a0,0x2b
    800011d0:	e6453503          	ld	a0,-412(a0) # 8002c030 <kernel_pagetable>
    800011d4:	00000097          	auipc	ra,0x0
    800011d8:	e6e080e7          	jalr	-402(ra) # 80001042 <walk>
  if(pte == 0)
    800011dc:	cd09                	beqz	a0,800011f6 <kvmpa+0x3e>
  if((*pte & PTE_V) == 0)
    800011de:	6108                	ld	a0,0(a0)
    800011e0:	00157793          	andi	a5,a0,1
    800011e4:	c38d                	beqz	a5,80001206 <kvmpa+0x4e>
  pa = PTE2PA(*pte);
    800011e6:	8129                	srli	a0,a0,0xa
    800011e8:	0532                	slli	a0,a0,0xc
}
    800011ea:	9526                	add	a0,a0,s1
    800011ec:	60e2                	ld	ra,24(sp)
    800011ee:	6442                	ld	s0,16(sp)
    800011f0:	64a2                	ld	s1,8(sp)
    800011f2:	6105                	addi	sp,sp,32
    800011f4:	8082                	ret
    panic("kvmpa");
    800011f6:	00007517          	auipc	a0,0x7
    800011fa:	13250513          	addi	a0,a0,306 # 80008328 <userret+0x298>
    800011fe:	fffff097          	auipc	ra,0xfffff
    80001202:	34a080e7          	jalr	842(ra) # 80000548 <panic>
    panic("kvmpa");
    80001206:	00007517          	auipc	a0,0x7
    8000120a:	12250513          	addi	a0,a0,290 # 80008328 <userret+0x298>
    8000120e:	fffff097          	auipc	ra,0xfffff
    80001212:	33a080e7          	jalr	826(ra) # 80000548 <panic>

0000000080001216 <mappages>:
{
    80001216:	715d                	addi	sp,sp,-80
    80001218:	e486                	sd	ra,72(sp)
    8000121a:	e0a2                	sd	s0,64(sp)
    8000121c:	fc26                	sd	s1,56(sp)
    8000121e:	f84a                	sd	s2,48(sp)
    80001220:	f44e                	sd	s3,40(sp)
    80001222:	f052                	sd	s4,32(sp)
    80001224:	ec56                	sd	s5,24(sp)
    80001226:	e85a                	sd	s6,16(sp)
    80001228:	e45e                	sd	s7,8(sp)
    8000122a:	0880                	addi	s0,sp,80
    8000122c:	8aaa                	mv	s5,a0
    8000122e:	8b3a                	mv	s6,a4
  a = PGROUNDDOWN(va);
    80001230:	777d                	lui	a4,0xfffff
    80001232:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001236:	167d                	addi	a2,a2,-1
    80001238:	00b609b3          	add	s3,a2,a1
    8000123c:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001240:	893e                	mv	s2,a5
    80001242:	40f68a33          	sub	s4,a3,a5
    a += PGSIZE;
    80001246:	6b85                	lui	s7,0x1
    80001248:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000124c:	4605                	li	a2,1
    8000124e:	85ca                	mv	a1,s2
    80001250:	8556                	mv	a0,s5
    80001252:	00000097          	auipc	ra,0x0
    80001256:	df0080e7          	jalr	-528(ra) # 80001042 <walk>
    8000125a:	c51d                	beqz	a0,80001288 <mappages+0x72>
    if(*pte & PTE_V)
    8000125c:	611c                	ld	a5,0(a0)
    8000125e:	8b85                	andi	a5,a5,1
    80001260:	ef81                	bnez	a5,80001278 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001262:	80b1                	srli	s1,s1,0xc
    80001264:	04aa                	slli	s1,s1,0xa
    80001266:	0164e4b3          	or	s1,s1,s6
    8000126a:	0014e493          	ori	s1,s1,1
    8000126e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001270:	03390863          	beq	s2,s3,800012a0 <mappages+0x8a>
    a += PGSIZE;
    80001274:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001276:	bfc9                	j	80001248 <mappages+0x32>
      panic("remap");
    80001278:	00007517          	auipc	a0,0x7
    8000127c:	0b850513          	addi	a0,a0,184 # 80008330 <userret+0x2a0>
    80001280:	fffff097          	auipc	ra,0xfffff
    80001284:	2c8080e7          	jalr	712(ra) # 80000548 <panic>
      return -1;
    80001288:	557d                	li	a0,-1
}
    8000128a:	60a6                	ld	ra,72(sp)
    8000128c:	6406                	ld	s0,64(sp)
    8000128e:	74e2                	ld	s1,56(sp)
    80001290:	7942                	ld	s2,48(sp)
    80001292:	79a2                	ld	s3,40(sp)
    80001294:	7a02                	ld	s4,32(sp)
    80001296:	6ae2                	ld	s5,24(sp)
    80001298:	6b42                	ld	s6,16(sp)
    8000129a:	6ba2                	ld	s7,8(sp)
    8000129c:	6161                	addi	sp,sp,80
    8000129e:	8082                	ret
  return 0;
    800012a0:	4501                	li	a0,0
    800012a2:	b7e5                	j	8000128a <mappages+0x74>

00000000800012a4 <kvmmap>:
{
    800012a4:	1141                	addi	sp,sp,-16
    800012a6:	e406                	sd	ra,8(sp)
    800012a8:	e022                	sd	s0,0(sp)
    800012aa:	0800                	addi	s0,sp,16
    800012ac:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800012ae:	86ae                	mv	a3,a1
    800012b0:	85aa                	mv	a1,a0
    800012b2:	0002b517          	auipc	a0,0x2b
    800012b6:	d7e53503          	ld	a0,-642(a0) # 8002c030 <kernel_pagetable>
    800012ba:	00000097          	auipc	ra,0x0
    800012be:	f5c080e7          	jalr	-164(ra) # 80001216 <mappages>
    800012c2:	e509                	bnez	a0,800012cc <kvmmap+0x28>
}
    800012c4:	60a2                	ld	ra,8(sp)
    800012c6:	6402                	ld	s0,0(sp)
    800012c8:	0141                	addi	sp,sp,16
    800012ca:	8082                	ret
    panic("kvmmap");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	06c50513          	addi	a0,a0,108 # 80008338 <userret+0x2a8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	274080e7          	jalr	628(ra) # 80000548 <panic>

00000000800012dc <kvminit>:
{
    800012dc:	1101                	addi	sp,sp,-32
    800012de:	ec06                	sd	ra,24(sp)
    800012e0:	e822                	sd	s0,16(sp)
    800012e2:	e426                	sd	s1,8(sp)
    800012e4:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    800012e6:	fffff097          	auipc	ra,0xfffff
    800012ea:	67a080e7          	jalr	1658(ra) # 80000960 <kalloc>
    800012ee:	0002b797          	auipc	a5,0x2b
    800012f2:	d4a7b123          	sd	a0,-702(a5) # 8002c030 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    800012f6:	6605                	lui	a2,0x1
    800012f8:	4581                	li	a1,0
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	a82080e7          	jalr	-1406(ra) # 80000d7c <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001302:	4699                	li	a3,6
    80001304:	6605                	lui	a2,0x1
    80001306:	100005b7          	lui	a1,0x10000
    8000130a:	10000537          	lui	a0,0x10000
    8000130e:	00000097          	auipc	ra,0x0
    80001312:	f96080e7          	jalr	-106(ra) # 800012a4 <kvmmap>
  kvmmap(VIRTION(0), VIRTION(0), PGSIZE, PTE_R | PTE_W);
    80001316:	4699                	li	a3,6
    80001318:	6605                	lui	a2,0x1
    8000131a:	100015b7          	lui	a1,0x10001
    8000131e:	10001537          	lui	a0,0x10001
    80001322:	00000097          	auipc	ra,0x0
    80001326:	f82080e7          	jalr	-126(ra) # 800012a4 <kvmmap>
  kvmmap(VIRTION(1), VIRTION(1), PGSIZE, PTE_R | PTE_W);
    8000132a:	4699                	li	a3,6
    8000132c:	6605                	lui	a2,0x1
    8000132e:	100025b7          	lui	a1,0x10002
    80001332:	10002537          	lui	a0,0x10002
    80001336:	00000097          	auipc	ra,0x0
    8000133a:	f6e080e7          	jalr	-146(ra) # 800012a4 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    8000133e:	4699                	li	a3,6
    80001340:	6641                	lui	a2,0x10
    80001342:	020005b7          	lui	a1,0x2000
    80001346:	02000537          	lui	a0,0x2000
    8000134a:	00000097          	auipc	ra,0x0
    8000134e:	f5a080e7          	jalr	-166(ra) # 800012a4 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001352:	4699                	li	a3,6
    80001354:	00400637          	lui	a2,0x400
    80001358:	0c0005b7          	lui	a1,0xc000
    8000135c:	0c000537          	lui	a0,0xc000
    80001360:	00000097          	auipc	ra,0x0
    80001364:	f44080e7          	jalr	-188(ra) # 800012a4 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001368:	00008497          	auipc	s1,0x8
    8000136c:	c9848493          	addi	s1,s1,-872 # 80009000 <initcode>
    80001370:	46a9                	li	a3,10
    80001372:	80008617          	auipc	a2,0x80008
    80001376:	c8e60613          	addi	a2,a2,-882 # 9000 <_entry-0x7fff7000>
    8000137a:	4585                	li	a1,1
    8000137c:	05fe                	slli	a1,a1,0x1f
    8000137e:	852e                	mv	a0,a1
    80001380:	00000097          	auipc	ra,0x0
    80001384:	f24080e7          	jalr	-220(ra) # 800012a4 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001388:	4699                	li	a3,6
    8000138a:	4645                	li	a2,17
    8000138c:	066e                	slli	a2,a2,0x1b
    8000138e:	8e05                	sub	a2,a2,s1
    80001390:	85a6                	mv	a1,s1
    80001392:	8526                	mv	a0,s1
    80001394:	00000097          	auipc	ra,0x0
    80001398:	f10080e7          	jalr	-240(ra) # 800012a4 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000139c:	46a9                	li	a3,10
    8000139e:	6605                	lui	a2,0x1
    800013a0:	00007597          	auipc	a1,0x7
    800013a4:	c6058593          	addi	a1,a1,-928 # 80008000 <trampoline>
    800013a8:	04000537          	lui	a0,0x4000
    800013ac:	157d                	addi	a0,a0,-1
    800013ae:	0532                	slli	a0,a0,0xc
    800013b0:	00000097          	auipc	ra,0x0
    800013b4:	ef4080e7          	jalr	-268(ra) # 800012a4 <kvmmap>
}
    800013b8:	60e2                	ld	ra,24(sp)
    800013ba:	6442                	ld	s0,16(sp)
    800013bc:	64a2                	ld	s1,8(sp)
    800013be:	6105                	addi	sp,sp,32
    800013c0:	8082                	ret

00000000800013c2 <uvmunmap>:
{
    800013c2:	715d                	addi	sp,sp,-80
    800013c4:	e486                	sd	ra,72(sp)
    800013c6:	e0a2                	sd	s0,64(sp)
    800013c8:	fc26                	sd	s1,56(sp)
    800013ca:	f84a                	sd	s2,48(sp)
    800013cc:	f44e                	sd	s3,40(sp)
    800013ce:	f052                	sd	s4,32(sp)
    800013d0:	ec56                	sd	s5,24(sp)
    800013d2:	e85a                	sd	s6,16(sp)
    800013d4:	e45e                	sd	s7,8(sp)
    800013d6:	0880                	addi	s0,sp,80
    800013d8:	8a2a                	mv	s4,a0
    800013da:	8ab6                	mv	s5,a3
  a = PGROUNDDOWN(va);
    800013dc:	77fd                	lui	a5,0xfffff
    800013de:	00f5f933          	and	s2,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800013e2:	167d                	addi	a2,a2,-1
    800013e4:	00b609b3          	add	s3,a2,a1
    800013e8:	00f9f9b3          	and	s3,s3,a5
    if(PTE_FLAGS(*pte) == PTE_V)
    800013ec:	4b05                	li	s6,1
    a += PGSIZE;
    800013ee:	6b85                	lui	s7,0x1
    800013f0:	a0b9                	j	8000143e <uvmunmap+0x7c>
      panic("uvmunmap: walk");
    800013f2:	00007517          	auipc	a0,0x7
    800013f6:	f4e50513          	addi	a0,a0,-178 # 80008340 <userret+0x2b0>
    800013fa:	fffff097          	auipc	ra,0xfffff
    800013fe:	14e080e7          	jalr	334(ra) # 80000548 <panic>
      printf("va=%p pte=%p\n", a, *pte);
    80001402:	85ca                	mv	a1,s2
    80001404:	00007517          	auipc	a0,0x7
    80001408:	f4c50513          	addi	a0,a0,-180 # 80008350 <userret+0x2c0>
    8000140c:	fffff097          	auipc	ra,0xfffff
    80001410:	196080e7          	jalr	406(ra) # 800005a2 <printf>
      panic("uvmunmap: not mapped");
    80001414:	00007517          	auipc	a0,0x7
    80001418:	f4c50513          	addi	a0,a0,-180 # 80008360 <userret+0x2d0>
    8000141c:	fffff097          	auipc	ra,0xfffff
    80001420:	12c080e7          	jalr	300(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    80001424:	00007517          	auipc	a0,0x7
    80001428:	f5450513          	addi	a0,a0,-172 # 80008378 <userret+0x2e8>
    8000142c:	fffff097          	auipc	ra,0xfffff
    80001430:	11c080e7          	jalr	284(ra) # 80000548 <panic>
    *pte = 0;
    80001434:	0004b023          	sd	zero,0(s1)
    if(a == last)
    80001438:	03390e63          	beq	s2,s3,80001474 <uvmunmap+0xb2>
    a += PGSIZE;
    8000143c:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 0)) == 0)
    8000143e:	4601                	li	a2,0
    80001440:	85ca                	mv	a1,s2
    80001442:	8552                	mv	a0,s4
    80001444:	00000097          	auipc	ra,0x0
    80001448:	bfe080e7          	jalr	-1026(ra) # 80001042 <walk>
    8000144c:	84aa                	mv	s1,a0
    8000144e:	d155                	beqz	a0,800013f2 <uvmunmap+0x30>
    if((*pte & PTE_V) == 0){
    80001450:	6110                	ld	a2,0(a0)
    80001452:	00167793          	andi	a5,a2,1
    80001456:	d7d5                	beqz	a5,80001402 <uvmunmap+0x40>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001458:	3ff67793          	andi	a5,a2,1023
    8000145c:	fd6784e3          	beq	a5,s6,80001424 <uvmunmap+0x62>
    if(do_free){
    80001460:	fc0a8ae3          	beqz	s5,80001434 <uvmunmap+0x72>
      pa = PTE2PA(*pte);
    80001464:	8229                	srli	a2,a2,0xa
      kfree((void*)pa);
    80001466:	00c61513          	slli	a0,a2,0xc
    8000146a:	fffff097          	auipc	ra,0xfffff
    8000146e:	3fa080e7          	jalr	1018(ra) # 80000864 <kfree>
    80001472:	b7c9                	j	80001434 <uvmunmap+0x72>
}
    80001474:	60a6                	ld	ra,72(sp)
    80001476:	6406                	ld	s0,64(sp)
    80001478:	74e2                	ld	s1,56(sp)
    8000147a:	7942                	ld	s2,48(sp)
    8000147c:	79a2                	ld	s3,40(sp)
    8000147e:	7a02                	ld	s4,32(sp)
    80001480:	6ae2                	ld	s5,24(sp)
    80001482:	6b42                	ld	s6,16(sp)
    80001484:	6ba2                	ld	s7,8(sp)
    80001486:	6161                	addi	sp,sp,80
    80001488:	8082                	ret

000000008000148a <uvmcreate>:
{
    8000148a:	1101                	addi	sp,sp,-32
    8000148c:	ec06                	sd	ra,24(sp)
    8000148e:	e822                	sd	s0,16(sp)
    80001490:	e426                	sd	s1,8(sp)
    80001492:	1000                	addi	s0,sp,32
  pagetable = (pagetable_t) kalloc();
    80001494:	fffff097          	auipc	ra,0xfffff
    80001498:	4cc080e7          	jalr	1228(ra) # 80000960 <kalloc>
  if(pagetable == 0)
    8000149c:	cd11                	beqz	a0,800014b8 <uvmcreate+0x2e>
    8000149e:	84aa                	mv	s1,a0
  memset(pagetable, 0, PGSIZE);
    800014a0:	6605                	lui	a2,0x1
    800014a2:	4581                	li	a1,0
    800014a4:	00000097          	auipc	ra,0x0
    800014a8:	8d8080e7          	jalr	-1832(ra) # 80000d7c <memset>
}
    800014ac:	8526                	mv	a0,s1
    800014ae:	60e2                	ld	ra,24(sp)
    800014b0:	6442                	ld	s0,16(sp)
    800014b2:	64a2                	ld	s1,8(sp)
    800014b4:	6105                	addi	sp,sp,32
    800014b6:	8082                	ret
    panic("uvmcreate: out of memory");
    800014b8:	00007517          	auipc	a0,0x7
    800014bc:	ed850513          	addi	a0,a0,-296 # 80008390 <userret+0x300>
    800014c0:	fffff097          	auipc	ra,0xfffff
    800014c4:	088080e7          	jalr	136(ra) # 80000548 <panic>

00000000800014c8 <uvminit>:
{
    800014c8:	7179                	addi	sp,sp,-48
    800014ca:	f406                	sd	ra,40(sp)
    800014cc:	f022                	sd	s0,32(sp)
    800014ce:	ec26                	sd	s1,24(sp)
    800014d0:	e84a                	sd	s2,16(sp)
    800014d2:	e44e                	sd	s3,8(sp)
    800014d4:	e052                	sd	s4,0(sp)
    800014d6:	1800                	addi	s0,sp,48
  if(sz >= PGSIZE)
    800014d8:	6785                	lui	a5,0x1
    800014da:	04f67863          	bgeu	a2,a5,8000152a <uvminit+0x62>
    800014de:	8a2a                	mv	s4,a0
    800014e0:	89ae                	mv	s3,a1
    800014e2:	84b2                	mv	s1,a2
  mem = kalloc();
    800014e4:	fffff097          	auipc	ra,0xfffff
    800014e8:	47c080e7          	jalr	1148(ra) # 80000960 <kalloc>
    800014ec:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800014ee:	6605                	lui	a2,0x1
    800014f0:	4581                	li	a1,0
    800014f2:	00000097          	auipc	ra,0x0
    800014f6:	88a080e7          	jalr	-1910(ra) # 80000d7c <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800014fa:	4779                	li	a4,30
    800014fc:	86ca                	mv	a3,s2
    800014fe:	6605                	lui	a2,0x1
    80001500:	4581                	li	a1,0
    80001502:	8552                	mv	a0,s4
    80001504:	00000097          	auipc	ra,0x0
    80001508:	d12080e7          	jalr	-750(ra) # 80001216 <mappages>
  memmove(mem, src, sz);
    8000150c:	8626                	mv	a2,s1
    8000150e:	85ce                	mv	a1,s3
    80001510:	854a                	mv	a0,s2
    80001512:	00000097          	auipc	ra,0x0
    80001516:	8c6080e7          	jalr	-1850(ra) # 80000dd8 <memmove>
}
    8000151a:	70a2                	ld	ra,40(sp)
    8000151c:	7402                	ld	s0,32(sp)
    8000151e:	64e2                	ld	s1,24(sp)
    80001520:	6942                	ld	s2,16(sp)
    80001522:	69a2                	ld	s3,8(sp)
    80001524:	6a02                	ld	s4,0(sp)
    80001526:	6145                	addi	sp,sp,48
    80001528:	8082                	ret
    panic("inituvm: more than a page");
    8000152a:	00007517          	auipc	a0,0x7
    8000152e:	e8650513          	addi	a0,a0,-378 # 800083b0 <userret+0x320>
    80001532:	fffff097          	auipc	ra,0xfffff
    80001536:	016080e7          	jalr	22(ra) # 80000548 <panic>

000000008000153a <uvmdealloc>:
{
    8000153a:	1101                	addi	sp,sp,-32
    8000153c:	ec06                	sd	ra,24(sp)
    8000153e:	e822                	sd	s0,16(sp)
    80001540:	e426                	sd	s1,8(sp)
    80001542:	1000                	addi	s0,sp,32
    return oldsz;
    80001544:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001546:	00b67d63          	bgeu	a2,a1,80001560 <uvmdealloc+0x26>
    8000154a:	84b2                	mv	s1,a2
  uint64 newup = PGROUNDUP(newsz);
    8000154c:	6785                	lui	a5,0x1
    8000154e:	17fd                	addi	a5,a5,-1
    80001550:	00f60733          	add	a4,a2,a5
    80001554:	76fd                	lui	a3,0xfffff
    80001556:	8f75                	and	a4,a4,a3
  if(newup < PGROUNDUP(oldsz))
    80001558:	97ae                	add	a5,a5,a1
    8000155a:	8ff5                	and	a5,a5,a3
    8000155c:	00f76863          	bltu	a4,a5,8000156c <uvmdealloc+0x32>
}
    80001560:	8526                	mv	a0,s1
    80001562:	60e2                	ld	ra,24(sp)
    80001564:	6442                	ld	s0,16(sp)
    80001566:	64a2                	ld	s1,8(sp)
    80001568:	6105                	addi	sp,sp,32
    8000156a:	8082                	ret
    uvmunmap(pagetable, newup, oldsz - newup, 1);
    8000156c:	4685                	li	a3,1
    8000156e:	40e58633          	sub	a2,a1,a4
    80001572:	85ba                	mv	a1,a4
    80001574:	00000097          	auipc	ra,0x0
    80001578:	e4e080e7          	jalr	-434(ra) # 800013c2 <uvmunmap>
    8000157c:	b7d5                	j	80001560 <uvmdealloc+0x26>

000000008000157e <uvmalloc>:
  if(newsz < oldsz)
    8000157e:	0ab66163          	bltu	a2,a1,80001620 <uvmalloc+0xa2>
{
    80001582:	7139                	addi	sp,sp,-64
    80001584:	fc06                	sd	ra,56(sp)
    80001586:	f822                	sd	s0,48(sp)
    80001588:	f426                	sd	s1,40(sp)
    8000158a:	f04a                	sd	s2,32(sp)
    8000158c:	ec4e                	sd	s3,24(sp)
    8000158e:	e852                	sd	s4,16(sp)
    80001590:	e456                	sd	s5,8(sp)
    80001592:	0080                	addi	s0,sp,64
    80001594:	8aaa                	mv	s5,a0
    80001596:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001598:	6985                	lui	s3,0x1
    8000159a:	19fd                	addi	s3,s3,-1
    8000159c:	95ce                	add	a1,a1,s3
    8000159e:	79fd                	lui	s3,0xfffff
    800015a0:	0135f9b3          	and	s3,a1,s3
  for(; a < newsz; a += PGSIZE){
    800015a4:	08c9f063          	bgeu	s3,a2,80001624 <uvmalloc+0xa6>
  a = oldsz;
    800015a8:	894e                	mv	s2,s3
    mem = kalloc();
    800015aa:	fffff097          	auipc	ra,0xfffff
    800015ae:	3b6080e7          	jalr	950(ra) # 80000960 <kalloc>
    800015b2:	84aa                	mv	s1,a0
    if(mem == 0){
    800015b4:	c51d                	beqz	a0,800015e2 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800015b6:	6605                	lui	a2,0x1
    800015b8:	4581                	li	a1,0
    800015ba:	fffff097          	auipc	ra,0xfffff
    800015be:	7c2080e7          	jalr	1986(ra) # 80000d7c <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800015c2:	4779                	li	a4,30
    800015c4:	86a6                	mv	a3,s1
    800015c6:	6605                	lui	a2,0x1
    800015c8:	85ca                	mv	a1,s2
    800015ca:	8556                	mv	a0,s5
    800015cc:	00000097          	auipc	ra,0x0
    800015d0:	c4a080e7          	jalr	-950(ra) # 80001216 <mappages>
    800015d4:	e905                	bnez	a0,80001604 <uvmalloc+0x86>
  for(; a < newsz; a += PGSIZE){
    800015d6:	6785                	lui	a5,0x1
    800015d8:	993e                	add	s2,s2,a5
    800015da:	fd4968e3          	bltu	s2,s4,800015aa <uvmalloc+0x2c>
  return newsz;
    800015de:	8552                	mv	a0,s4
    800015e0:	a809                	j	800015f2 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800015e2:	864e                	mv	a2,s3
    800015e4:	85ca                	mv	a1,s2
    800015e6:	8556                	mv	a0,s5
    800015e8:	00000097          	auipc	ra,0x0
    800015ec:	f52080e7          	jalr	-174(ra) # 8000153a <uvmdealloc>
      return 0;
    800015f0:	4501                	li	a0,0
}
    800015f2:	70e2                	ld	ra,56(sp)
    800015f4:	7442                	ld	s0,48(sp)
    800015f6:	74a2                	ld	s1,40(sp)
    800015f8:	7902                	ld	s2,32(sp)
    800015fa:	69e2                	ld	s3,24(sp)
    800015fc:	6a42                	ld	s4,16(sp)
    800015fe:	6aa2                	ld	s5,8(sp)
    80001600:	6121                	addi	sp,sp,64
    80001602:	8082                	ret
      kfree(mem);
    80001604:	8526                	mv	a0,s1
    80001606:	fffff097          	auipc	ra,0xfffff
    8000160a:	25e080e7          	jalr	606(ra) # 80000864 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000160e:	864e                	mv	a2,s3
    80001610:	85ca                	mv	a1,s2
    80001612:	8556                	mv	a0,s5
    80001614:	00000097          	auipc	ra,0x0
    80001618:	f26080e7          	jalr	-218(ra) # 8000153a <uvmdealloc>
      return 0;
    8000161c:	4501                	li	a0,0
    8000161e:	bfd1                	j	800015f2 <uvmalloc+0x74>
    return oldsz;
    80001620:	852e                	mv	a0,a1
}
    80001622:	8082                	ret
  return newsz;
    80001624:	8532                	mv	a0,a2
    80001626:	b7f1                	j	800015f2 <uvmalloc+0x74>

0000000080001628 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001628:	1101                	addi	sp,sp,-32
    8000162a:	ec06                	sd	ra,24(sp)
    8000162c:	e822                	sd	s0,16(sp)
    8000162e:	e426                	sd	s1,8(sp)
    80001630:	1000                	addi	s0,sp,32
    80001632:	84aa                	mv	s1,a0
    80001634:	862e                	mv	a2,a1
  uvmunmap(pagetable, 0, sz, 1);
    80001636:	4685                	li	a3,1
    80001638:	4581                	li	a1,0
    8000163a:	00000097          	auipc	ra,0x0
    8000163e:	d88080e7          	jalr	-632(ra) # 800013c2 <uvmunmap>
  freewalk(pagetable);
    80001642:	8526                	mv	a0,s1
    80001644:	00000097          	auipc	ra,0x0
    80001648:	aa4080e7          	jalr	-1372(ra) # 800010e8 <freewalk>
}
    8000164c:	60e2                	ld	ra,24(sp)
    8000164e:	6442                	ld	s0,16(sp)
    80001650:	64a2                	ld	s1,8(sp)
    80001652:	6105                	addi	sp,sp,32
    80001654:	8082                	ret

0000000080001656 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001656:	c671                	beqz	a2,80001722 <uvmcopy+0xcc>
{
    80001658:	715d                	addi	sp,sp,-80
    8000165a:	e486                	sd	ra,72(sp)
    8000165c:	e0a2                	sd	s0,64(sp)
    8000165e:	fc26                	sd	s1,56(sp)
    80001660:	f84a                	sd	s2,48(sp)
    80001662:	f44e                	sd	s3,40(sp)
    80001664:	f052                	sd	s4,32(sp)
    80001666:	ec56                	sd	s5,24(sp)
    80001668:	e85a                	sd	s6,16(sp)
    8000166a:	e45e                	sd	s7,8(sp)
    8000166c:	0880                	addi	s0,sp,80
    8000166e:	8b2a                	mv	s6,a0
    80001670:	8aae                	mv	s5,a1
    80001672:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001674:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001676:	4601                	li	a2,0
    80001678:	85ce                	mv	a1,s3
    8000167a:	855a                	mv	a0,s6
    8000167c:	00000097          	auipc	ra,0x0
    80001680:	9c6080e7          	jalr	-1594(ra) # 80001042 <walk>
    80001684:	c531                	beqz	a0,800016d0 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001686:	6118                	ld	a4,0(a0)
    80001688:	00177793          	andi	a5,a4,1
    8000168c:	cbb1                	beqz	a5,800016e0 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000168e:	00a75593          	srli	a1,a4,0xa
    80001692:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001696:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000169a:	fffff097          	auipc	ra,0xfffff
    8000169e:	2c6080e7          	jalr	710(ra) # 80000960 <kalloc>
    800016a2:	892a                	mv	s2,a0
    800016a4:	c939                	beqz	a0,800016fa <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800016a6:	6605                	lui	a2,0x1
    800016a8:	85de                	mv	a1,s7
    800016aa:	fffff097          	auipc	ra,0xfffff
    800016ae:	72e080e7          	jalr	1838(ra) # 80000dd8 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800016b2:	8726                	mv	a4,s1
    800016b4:	86ca                	mv	a3,s2
    800016b6:	6605                	lui	a2,0x1
    800016b8:	85ce                	mv	a1,s3
    800016ba:	8556                	mv	a0,s5
    800016bc:	00000097          	auipc	ra,0x0
    800016c0:	b5a080e7          	jalr	-1190(ra) # 80001216 <mappages>
    800016c4:	e515                	bnez	a0,800016f0 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800016c6:	6785                	lui	a5,0x1
    800016c8:	99be                	add	s3,s3,a5
    800016ca:	fb49e6e3          	bltu	s3,s4,80001676 <uvmcopy+0x20>
    800016ce:	a83d                	j	8000170c <uvmcopy+0xb6>
      panic("uvmcopy: pte should exist");
    800016d0:	00007517          	auipc	a0,0x7
    800016d4:	d0050513          	addi	a0,a0,-768 # 800083d0 <userret+0x340>
    800016d8:	fffff097          	auipc	ra,0xfffff
    800016dc:	e70080e7          	jalr	-400(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    800016e0:	00007517          	auipc	a0,0x7
    800016e4:	d1050513          	addi	a0,a0,-752 # 800083f0 <userret+0x360>
    800016e8:	fffff097          	auipc	ra,0xfffff
    800016ec:	e60080e7          	jalr	-416(ra) # 80000548 <panic>
      kfree(mem);
    800016f0:	854a                	mv	a0,s2
    800016f2:	fffff097          	auipc	ra,0xfffff
    800016f6:	172080e7          	jalr	370(ra) # 80000864 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i, 1);
    800016fa:	4685                	li	a3,1
    800016fc:	864e                	mv	a2,s3
    800016fe:	4581                	li	a1,0
    80001700:	8556                	mv	a0,s5
    80001702:	00000097          	auipc	ra,0x0
    80001706:	cc0080e7          	jalr	-832(ra) # 800013c2 <uvmunmap>
  return -1;
    8000170a:	557d                	li	a0,-1
}
    8000170c:	60a6                	ld	ra,72(sp)
    8000170e:	6406                	ld	s0,64(sp)
    80001710:	74e2                	ld	s1,56(sp)
    80001712:	7942                	ld	s2,48(sp)
    80001714:	79a2                	ld	s3,40(sp)
    80001716:	7a02                	ld	s4,32(sp)
    80001718:	6ae2                	ld	s5,24(sp)
    8000171a:	6b42                	ld	s6,16(sp)
    8000171c:	6ba2                	ld	s7,8(sp)
    8000171e:	6161                	addi	sp,sp,80
    80001720:	8082                	ret
  return 0;
    80001722:	4501                	li	a0,0
}
    80001724:	8082                	ret

0000000080001726 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001726:	1141                	addi	sp,sp,-16
    80001728:	e406                	sd	ra,8(sp)
    8000172a:	e022                	sd	s0,0(sp)
    8000172c:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000172e:	4601                	li	a2,0
    80001730:	00000097          	auipc	ra,0x0
    80001734:	912080e7          	jalr	-1774(ra) # 80001042 <walk>
  if(pte == 0)
    80001738:	c901                	beqz	a0,80001748 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000173a:	611c                	ld	a5,0(a0)
    8000173c:	9bbd                	andi	a5,a5,-17
    8000173e:	e11c                	sd	a5,0(a0)
}
    80001740:	60a2                	ld	ra,8(sp)
    80001742:	6402                	ld	s0,0(sp)
    80001744:	0141                	addi	sp,sp,16
    80001746:	8082                	ret
    panic("uvmclear");
    80001748:	00007517          	auipc	a0,0x7
    8000174c:	cc850513          	addi	a0,a0,-824 # 80008410 <userret+0x380>
    80001750:	fffff097          	auipc	ra,0xfffff
    80001754:	df8080e7          	jalr	-520(ra) # 80000548 <panic>

0000000080001758 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001758:	c6bd                	beqz	a3,800017c6 <copyout+0x6e>
{
    8000175a:	715d                	addi	sp,sp,-80
    8000175c:	e486                	sd	ra,72(sp)
    8000175e:	e0a2                	sd	s0,64(sp)
    80001760:	fc26                	sd	s1,56(sp)
    80001762:	f84a                	sd	s2,48(sp)
    80001764:	f44e                	sd	s3,40(sp)
    80001766:	f052                	sd	s4,32(sp)
    80001768:	ec56                	sd	s5,24(sp)
    8000176a:	e85a                	sd	s6,16(sp)
    8000176c:	e45e                	sd	s7,8(sp)
    8000176e:	e062                	sd	s8,0(sp)
    80001770:	0880                	addi	s0,sp,80
    80001772:	8b2a                	mv	s6,a0
    80001774:	8c2e                	mv	s8,a1
    80001776:	8a32                	mv	s4,a2
    80001778:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000177a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000177c:	6a85                	lui	s5,0x1
    8000177e:	a015                	j	800017a2 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001780:	9562                	add	a0,a0,s8
    80001782:	0004861b          	sext.w	a2,s1
    80001786:	85d2                	mv	a1,s4
    80001788:	41250533          	sub	a0,a0,s2
    8000178c:	fffff097          	auipc	ra,0xfffff
    80001790:	64c080e7          	jalr	1612(ra) # 80000dd8 <memmove>

    len -= n;
    80001794:	409989b3          	sub	s3,s3,s1
    src += n;
    80001798:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000179a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000179e:	02098263          	beqz	s3,800017c2 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800017a2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017a6:	85ca                	mv	a1,s2
    800017a8:	855a                	mv	a0,s6
    800017aa:	00000097          	auipc	ra,0x0
    800017ae:	9cc080e7          	jalr	-1588(ra) # 80001176 <walkaddr>
    if(pa0 == 0)
    800017b2:	cd01                	beqz	a0,800017ca <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800017b4:	418904b3          	sub	s1,s2,s8
    800017b8:	94d6                	add	s1,s1,s5
    if(n > len)
    800017ba:	fc99f3e3          	bgeu	s3,s1,80001780 <copyout+0x28>
    800017be:	84ce                	mv	s1,s3
    800017c0:	b7c1                	j	80001780 <copyout+0x28>
  }
  return 0;
    800017c2:	4501                	li	a0,0
    800017c4:	a021                	j	800017cc <copyout+0x74>
    800017c6:	4501                	li	a0,0
}
    800017c8:	8082                	ret
      return -1;
    800017ca:	557d                	li	a0,-1
}
    800017cc:	60a6                	ld	ra,72(sp)
    800017ce:	6406                	ld	s0,64(sp)
    800017d0:	74e2                	ld	s1,56(sp)
    800017d2:	7942                	ld	s2,48(sp)
    800017d4:	79a2                	ld	s3,40(sp)
    800017d6:	7a02                	ld	s4,32(sp)
    800017d8:	6ae2                	ld	s5,24(sp)
    800017da:	6b42                	ld	s6,16(sp)
    800017dc:	6ba2                	ld	s7,8(sp)
    800017de:	6c02                	ld	s8,0(sp)
    800017e0:	6161                	addi	sp,sp,80
    800017e2:	8082                	ret

00000000800017e4 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017e4:	caa5                	beqz	a3,80001854 <copyin+0x70>
{
    800017e6:	715d                	addi	sp,sp,-80
    800017e8:	e486                	sd	ra,72(sp)
    800017ea:	e0a2                	sd	s0,64(sp)
    800017ec:	fc26                	sd	s1,56(sp)
    800017ee:	f84a                	sd	s2,48(sp)
    800017f0:	f44e                	sd	s3,40(sp)
    800017f2:	f052                	sd	s4,32(sp)
    800017f4:	ec56                	sd	s5,24(sp)
    800017f6:	e85a                	sd	s6,16(sp)
    800017f8:	e45e                	sd	s7,8(sp)
    800017fa:	e062                	sd	s8,0(sp)
    800017fc:	0880                	addi	s0,sp,80
    800017fe:	8b2a                	mv	s6,a0
    80001800:	8a2e                	mv	s4,a1
    80001802:	8c32                	mv	s8,a2
    80001804:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001806:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001808:	6a85                	lui	s5,0x1
    8000180a:	a01d                	j	80001830 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000180c:	018505b3          	add	a1,a0,s8
    80001810:	0004861b          	sext.w	a2,s1
    80001814:	412585b3          	sub	a1,a1,s2
    80001818:	8552                	mv	a0,s4
    8000181a:	fffff097          	auipc	ra,0xfffff
    8000181e:	5be080e7          	jalr	1470(ra) # 80000dd8 <memmove>

    len -= n;
    80001822:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001826:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001828:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000182c:	02098263          	beqz	s3,80001850 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001830:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001834:	85ca                	mv	a1,s2
    80001836:	855a                	mv	a0,s6
    80001838:	00000097          	auipc	ra,0x0
    8000183c:	93e080e7          	jalr	-1730(ra) # 80001176 <walkaddr>
    if(pa0 == 0)
    80001840:	cd01                	beqz	a0,80001858 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001842:	418904b3          	sub	s1,s2,s8
    80001846:	94d6                	add	s1,s1,s5
    if(n > len)
    80001848:	fc99f2e3          	bgeu	s3,s1,8000180c <copyin+0x28>
    8000184c:	84ce                	mv	s1,s3
    8000184e:	bf7d                	j	8000180c <copyin+0x28>
  }
  return 0;
    80001850:	4501                	li	a0,0
    80001852:	a021                	j	8000185a <copyin+0x76>
    80001854:	4501                	li	a0,0
}
    80001856:	8082                	ret
      return -1;
    80001858:	557d                	li	a0,-1
}
    8000185a:	60a6                	ld	ra,72(sp)
    8000185c:	6406                	ld	s0,64(sp)
    8000185e:	74e2                	ld	s1,56(sp)
    80001860:	7942                	ld	s2,48(sp)
    80001862:	79a2                	ld	s3,40(sp)
    80001864:	7a02                	ld	s4,32(sp)
    80001866:	6ae2                	ld	s5,24(sp)
    80001868:	6b42                	ld	s6,16(sp)
    8000186a:	6ba2                	ld	s7,8(sp)
    8000186c:	6c02                	ld	s8,0(sp)
    8000186e:	6161                	addi	sp,sp,80
    80001870:	8082                	ret

0000000080001872 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001872:	c6c5                	beqz	a3,8000191a <copyinstr+0xa8>
{
    80001874:	715d                	addi	sp,sp,-80
    80001876:	e486                	sd	ra,72(sp)
    80001878:	e0a2                	sd	s0,64(sp)
    8000187a:	fc26                	sd	s1,56(sp)
    8000187c:	f84a                	sd	s2,48(sp)
    8000187e:	f44e                	sd	s3,40(sp)
    80001880:	f052                	sd	s4,32(sp)
    80001882:	ec56                	sd	s5,24(sp)
    80001884:	e85a                	sd	s6,16(sp)
    80001886:	e45e                	sd	s7,8(sp)
    80001888:	0880                	addi	s0,sp,80
    8000188a:	8a2a                	mv	s4,a0
    8000188c:	8b2e                	mv	s6,a1
    8000188e:	8bb2                	mv	s7,a2
    80001890:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001892:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001894:	6985                	lui	s3,0x1
    80001896:	a035                	j	800018c2 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001898:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000189c:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000189e:	0017b793          	seqz	a5,a5
    800018a2:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800018a6:	60a6                	ld	ra,72(sp)
    800018a8:	6406                	ld	s0,64(sp)
    800018aa:	74e2                	ld	s1,56(sp)
    800018ac:	7942                	ld	s2,48(sp)
    800018ae:	79a2                	ld	s3,40(sp)
    800018b0:	7a02                	ld	s4,32(sp)
    800018b2:	6ae2                	ld	s5,24(sp)
    800018b4:	6b42                	ld	s6,16(sp)
    800018b6:	6ba2                	ld	s7,8(sp)
    800018b8:	6161                	addi	sp,sp,80
    800018ba:	8082                	ret
    srcva = va0 + PGSIZE;
    800018bc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800018c0:	c8a9                	beqz	s1,80001912 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800018c2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800018c6:	85ca                	mv	a1,s2
    800018c8:	8552                	mv	a0,s4
    800018ca:	00000097          	auipc	ra,0x0
    800018ce:	8ac080e7          	jalr	-1876(ra) # 80001176 <walkaddr>
    if(pa0 == 0)
    800018d2:	c131                	beqz	a0,80001916 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800018d4:	41790833          	sub	a6,s2,s7
    800018d8:	984e                	add	a6,a6,s3
    if(n > max)
    800018da:	0104f363          	bgeu	s1,a6,800018e0 <copyinstr+0x6e>
    800018de:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018e0:	955e                	add	a0,a0,s7
    800018e2:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018e6:	fc080be3          	beqz	a6,800018bc <copyinstr+0x4a>
    800018ea:	985a                	add	a6,a6,s6
    800018ec:	87da                	mv	a5,s6
      if(*p == '\0'){
    800018ee:	41650633          	sub	a2,a0,s6
    800018f2:	14fd                	addi	s1,s1,-1
    800018f4:	9b26                	add	s6,s6,s1
    800018f6:	00f60733          	add	a4,a2,a5
    800018fa:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd2fa4>
    800018fe:	df49                	beqz	a4,80001898 <copyinstr+0x26>
        *dst = *p;
    80001900:	00e78023          	sb	a4,0(a5)
      --max;
    80001904:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001908:	0785                	addi	a5,a5,1
    while(n > 0){
    8000190a:	ff0796e3          	bne	a5,a6,800018f6 <copyinstr+0x84>
      dst++;
    8000190e:	8b42                	mv	s6,a6
    80001910:	b775                	j	800018bc <copyinstr+0x4a>
    80001912:	4781                	li	a5,0
    80001914:	b769                	j	8000189e <copyinstr+0x2c>
      return -1;
    80001916:	557d                	li	a0,-1
    80001918:	b779                	j	800018a6 <copyinstr+0x34>
  int got_null = 0;
    8000191a:	4781                	li	a5,0
  if(got_null){
    8000191c:	0017b793          	seqz	a5,a5
    80001920:	40f00533          	neg	a0,a5
}
    80001924:	8082                	ret

0000000080001926 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001926:	1101                	addi	sp,sp,-32
    80001928:	ec06                	sd	ra,24(sp)
    8000192a:	e822                	sd	s0,16(sp)
    8000192c:	e426                	sd	s1,8(sp)
    8000192e:	1000                	addi	s0,sp,32
    80001930:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001932:	fffff097          	auipc	ra,0xfffff
    80001936:	19c080e7          	jalr	412(ra) # 80000ace <holding>
    8000193a:	c909                	beqz	a0,8000194c <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    8000193c:	789c                	ld	a5,48(s1)
    8000193e:	00978f63          	beq	a5,s1,8000195c <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001942:	60e2                	ld	ra,24(sp)
    80001944:	6442                	ld	s0,16(sp)
    80001946:	64a2                	ld	s1,8(sp)
    80001948:	6105                	addi	sp,sp,32
    8000194a:	8082                	ret
    panic("wakeup1");
    8000194c:	00007517          	auipc	a0,0x7
    80001950:	ad450513          	addi	a0,a0,-1324 # 80008420 <userret+0x390>
    80001954:	fffff097          	auipc	ra,0xfffff
    80001958:	bf4080e7          	jalr	-1036(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    8000195c:	5098                	lw	a4,32(s1)
    8000195e:	4785                	li	a5,1
    80001960:	fef711e3          	bne	a4,a5,80001942 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001964:	4789                	li	a5,2
    80001966:	d09c                	sw	a5,32(s1)
}
    80001968:	bfe9                	j	80001942 <wakeup1+0x1c>

000000008000196a <procinit>:
{
    8000196a:	715d                	addi	sp,sp,-80
    8000196c:	e486                	sd	ra,72(sp)
    8000196e:	e0a2                	sd	s0,64(sp)
    80001970:	fc26                	sd	s1,56(sp)
    80001972:	f84a                	sd	s2,48(sp)
    80001974:	f44e                	sd	s3,40(sp)
    80001976:	f052                	sd	s4,32(sp)
    80001978:	ec56                	sd	s5,24(sp)
    8000197a:	e85a                	sd	s6,16(sp)
    8000197c:	e45e                	sd	s7,8(sp)
    8000197e:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001980:	00007597          	auipc	a1,0x7
    80001984:	aa858593          	addi	a1,a1,-1368 # 80008428 <userret+0x398>
    80001988:	00013517          	auipc	a0,0x13
    8000198c:	eb850513          	addi	a0,a0,-328 # 80014840 <pid_lock>
    80001990:	fffff097          	auipc	ra,0xfffff
    80001994:	030080e7          	jalr	48(ra) # 800009c0 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001998:	00013917          	auipc	s2,0x13
    8000199c:	2c890913          	addi	s2,s2,712 # 80014c60 <proc>
      initlock(&p->lock, "proc");
    800019a0:	00007b97          	auipc	s7,0x7
    800019a4:	a90b8b93          	addi	s7,s7,-1392 # 80008430 <userret+0x3a0>
      uint64 va = KSTACK((int) (p - proc));
    800019a8:	8b4a                	mv	s6,s2
    800019aa:	00007a97          	auipc	s5,0x7
    800019ae:	216a8a93          	addi	s5,s5,534 # 80008bc0 <syscalls+0xb8>
    800019b2:	040009b7          	lui	s3,0x4000
    800019b6:	19fd                	addi	s3,s3,-1
    800019b8:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019ba:	00019a17          	auipc	s4,0x19
    800019be:	ea6a0a13          	addi	s4,s4,-346 # 8001a860 <tickslock>
      initlock(&p->lock, "proc");
    800019c2:	85de                	mv	a1,s7
    800019c4:	854a                	mv	a0,s2
    800019c6:	fffff097          	auipc	ra,0xfffff
    800019ca:	ffa080e7          	jalr	-6(ra) # 800009c0 <initlock>
      char *pa = kalloc();
    800019ce:	fffff097          	auipc	ra,0xfffff
    800019d2:	f92080e7          	jalr	-110(ra) # 80000960 <kalloc>
    800019d6:	85aa                	mv	a1,a0
      if(pa == 0)
    800019d8:	c929                	beqz	a0,80001a2a <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    800019da:	416904b3          	sub	s1,s2,s6
    800019de:	8491                	srai	s1,s1,0x4
    800019e0:	000ab783          	ld	a5,0(s5)
    800019e4:	02f484b3          	mul	s1,s1,a5
    800019e8:	2485                	addiw	s1,s1,1
    800019ea:	00d4949b          	slliw	s1,s1,0xd
    800019ee:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019f2:	4699                	li	a3,6
    800019f4:	6605                	lui	a2,0x1
    800019f6:	8526                	mv	a0,s1
    800019f8:	00000097          	auipc	ra,0x0
    800019fc:	8ac080e7          	jalr	-1876(ra) # 800012a4 <kvmmap>
      p->kstack = va;
    80001a00:	04993423          	sd	s1,72(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a04:	17090913          	addi	s2,s2,368
    80001a08:	fb491de3          	bne	s2,s4,800019c2 <procinit+0x58>
  kvminithart();
    80001a0c:	fffff097          	auipc	ra,0xfffff
    80001a10:	746080e7          	jalr	1862(ra) # 80001152 <kvminithart>
}
    80001a14:	60a6                	ld	ra,72(sp)
    80001a16:	6406                	ld	s0,64(sp)
    80001a18:	74e2                	ld	s1,56(sp)
    80001a1a:	7942                	ld	s2,48(sp)
    80001a1c:	79a2                	ld	s3,40(sp)
    80001a1e:	7a02                	ld	s4,32(sp)
    80001a20:	6ae2                	ld	s5,24(sp)
    80001a22:	6b42                	ld	s6,16(sp)
    80001a24:	6ba2                	ld	s7,8(sp)
    80001a26:	6161                	addi	sp,sp,80
    80001a28:	8082                	ret
        panic("kalloc");
    80001a2a:	00007517          	auipc	a0,0x7
    80001a2e:	a0e50513          	addi	a0,a0,-1522 # 80008438 <userret+0x3a8>
    80001a32:	fffff097          	auipc	ra,0xfffff
    80001a36:	b16080e7          	jalr	-1258(ra) # 80000548 <panic>

0000000080001a3a <cpuid>:
{
    80001a3a:	1141                	addi	sp,sp,-16
    80001a3c:	e422                	sd	s0,8(sp)
    80001a3e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a40:	8512                	mv	a0,tp
}
    80001a42:	2501                	sext.w	a0,a0
    80001a44:	6422                	ld	s0,8(sp)
    80001a46:	0141                	addi	sp,sp,16
    80001a48:	8082                	ret

0000000080001a4a <mycpu>:
mycpu(void) {
    80001a4a:	1141                	addi	sp,sp,-16
    80001a4c:	e422                	sd	s0,8(sp)
    80001a4e:	0800                	addi	s0,sp,16
    80001a50:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001a52:	2781                	sext.w	a5,a5
    80001a54:	079e                	slli	a5,a5,0x7
}
    80001a56:	00013517          	auipc	a0,0x13
    80001a5a:	e0a50513          	addi	a0,a0,-502 # 80014860 <cpus>
    80001a5e:	953e                	add	a0,a0,a5
    80001a60:	6422                	ld	s0,8(sp)
    80001a62:	0141                	addi	sp,sp,16
    80001a64:	8082                	ret

0000000080001a66 <myproc>:
myproc(void) {
    80001a66:	1101                	addi	sp,sp,-32
    80001a68:	ec06                	sd	ra,24(sp)
    80001a6a:	e822                	sd	s0,16(sp)
    80001a6c:	e426                	sd	s1,8(sp)
    80001a6e:	1000                	addi	s0,sp,32
  push_off();
    80001a70:	fffff097          	auipc	ra,0xfffff
    80001a74:	fa6080e7          	jalr	-90(ra) # 80000a16 <push_off>
    80001a78:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a7a:	2781                	sext.w	a5,a5
    80001a7c:	079e                	slli	a5,a5,0x7
    80001a7e:	00013717          	auipc	a4,0x13
    80001a82:	dc270713          	addi	a4,a4,-574 # 80014840 <pid_lock>
    80001a86:	97ba                	add	a5,a5,a4
    80001a88:	7384                	ld	s1,32(a5)
  pop_off();
    80001a8a:	fffff097          	auipc	ra,0xfffff
    80001a8e:	fd8080e7          	jalr	-40(ra) # 80000a62 <pop_off>
}
    80001a92:	8526                	mv	a0,s1
    80001a94:	60e2                	ld	ra,24(sp)
    80001a96:	6442                	ld	s0,16(sp)
    80001a98:	64a2                	ld	s1,8(sp)
    80001a9a:	6105                	addi	sp,sp,32
    80001a9c:	8082                	ret

0000000080001a9e <forkret>:
{
    80001a9e:	1141                	addi	sp,sp,-16
    80001aa0:	e406                	sd	ra,8(sp)
    80001aa2:	e022                	sd	s0,0(sp)
    80001aa4:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001aa6:	00000097          	auipc	ra,0x0
    80001aaa:	fc0080e7          	jalr	-64(ra) # 80001a66 <myproc>
    80001aae:	fffff097          	auipc	ra,0xfffff
    80001ab2:	0d0080e7          	jalr	208(ra) # 80000b7e <release>
  if (first) {
    80001ab6:	00007797          	auipc	a5,0x7
    80001aba:	57e7a783          	lw	a5,1406(a5) # 80009034 <first.1>
    80001abe:	eb89                	bnez	a5,80001ad0 <forkret+0x32>
  usertrapret();
    80001ac0:	00001097          	auipc	ra,0x1
    80001ac4:	bdc080e7          	jalr	-1060(ra) # 8000269c <usertrapret>
}
    80001ac8:	60a2                	ld	ra,8(sp)
    80001aca:	6402                	ld	s0,0(sp)
    80001acc:	0141                	addi	sp,sp,16
    80001ace:	8082                	ret
    first = 0;
    80001ad0:	00007797          	auipc	a5,0x7
    80001ad4:	5607a223          	sw	zero,1380(a5) # 80009034 <first.1>
    fsinit(minor(ROOTDEV));
    80001ad8:	4501                	li	a0,0
    80001ada:	00002097          	auipc	ra,0x2
    80001ade:	904080e7          	jalr	-1788(ra) # 800033de <fsinit>
    80001ae2:	bff9                	j	80001ac0 <forkret+0x22>

0000000080001ae4 <allocpid>:
allocpid() {
    80001ae4:	1101                	addi	sp,sp,-32
    80001ae6:	ec06                	sd	ra,24(sp)
    80001ae8:	e822                	sd	s0,16(sp)
    80001aea:	e426                	sd	s1,8(sp)
    80001aec:	e04a                	sd	s2,0(sp)
    80001aee:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001af0:	00013917          	auipc	s2,0x13
    80001af4:	d5090913          	addi	s2,s2,-688 # 80014840 <pid_lock>
    80001af8:	854a                	mv	a0,s2
    80001afa:	fffff097          	auipc	ra,0xfffff
    80001afe:	014080e7          	jalr	20(ra) # 80000b0e <acquire>
  pid = nextpid;
    80001b02:	00007797          	auipc	a5,0x7
    80001b06:	53678793          	addi	a5,a5,1334 # 80009038 <nextpid>
    80001b0a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b0c:	0014871b          	addiw	a4,s1,1
    80001b10:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b12:	854a                	mv	a0,s2
    80001b14:	fffff097          	auipc	ra,0xfffff
    80001b18:	06a080e7          	jalr	106(ra) # 80000b7e <release>
}
    80001b1c:	8526                	mv	a0,s1
    80001b1e:	60e2                	ld	ra,24(sp)
    80001b20:	6442                	ld	s0,16(sp)
    80001b22:	64a2                	ld	s1,8(sp)
    80001b24:	6902                	ld	s2,0(sp)
    80001b26:	6105                	addi	sp,sp,32
    80001b28:	8082                	ret

0000000080001b2a <proc_pagetable>:
{
    80001b2a:	1101                	addi	sp,sp,-32
    80001b2c:	ec06                	sd	ra,24(sp)
    80001b2e:	e822                	sd	s0,16(sp)
    80001b30:	e426                	sd	s1,8(sp)
    80001b32:	e04a                	sd	s2,0(sp)
    80001b34:	1000                	addi	s0,sp,32
    80001b36:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b38:	00000097          	auipc	ra,0x0
    80001b3c:	952080e7          	jalr	-1710(ra) # 8000148a <uvmcreate>
    80001b40:	84aa                	mv	s1,a0
  mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b42:	4729                	li	a4,10
    80001b44:	00006697          	auipc	a3,0x6
    80001b48:	4bc68693          	addi	a3,a3,1212 # 80008000 <trampoline>
    80001b4c:	6605                	lui	a2,0x1
    80001b4e:	040005b7          	lui	a1,0x4000
    80001b52:	15fd                	addi	a1,a1,-1
    80001b54:	05b2                	slli	a1,a1,0xc
    80001b56:	fffff097          	auipc	ra,0xfffff
    80001b5a:	6c0080e7          	jalr	1728(ra) # 80001216 <mappages>
  mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b5e:	4719                	li	a4,6
    80001b60:	06093683          	ld	a3,96(s2)
    80001b64:	6605                	lui	a2,0x1
    80001b66:	020005b7          	lui	a1,0x2000
    80001b6a:	15fd                	addi	a1,a1,-1
    80001b6c:	05b6                	slli	a1,a1,0xd
    80001b6e:	8526                	mv	a0,s1
    80001b70:	fffff097          	auipc	ra,0xfffff
    80001b74:	6a6080e7          	jalr	1702(ra) # 80001216 <mappages>
}
    80001b78:	8526                	mv	a0,s1
    80001b7a:	60e2                	ld	ra,24(sp)
    80001b7c:	6442                	ld	s0,16(sp)
    80001b7e:	64a2                	ld	s1,8(sp)
    80001b80:	6902                	ld	s2,0(sp)
    80001b82:	6105                	addi	sp,sp,32
    80001b84:	8082                	ret

0000000080001b86 <allocproc>:
{
    80001b86:	1101                	addi	sp,sp,-32
    80001b88:	ec06                	sd	ra,24(sp)
    80001b8a:	e822                	sd	s0,16(sp)
    80001b8c:	e426                	sd	s1,8(sp)
    80001b8e:	e04a                	sd	s2,0(sp)
    80001b90:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b92:	00013497          	auipc	s1,0x13
    80001b96:	0ce48493          	addi	s1,s1,206 # 80014c60 <proc>
    80001b9a:	00019917          	auipc	s2,0x19
    80001b9e:	cc690913          	addi	s2,s2,-826 # 8001a860 <tickslock>
    acquire(&p->lock);
    80001ba2:	8526                	mv	a0,s1
    80001ba4:	fffff097          	auipc	ra,0xfffff
    80001ba8:	f6a080e7          	jalr	-150(ra) # 80000b0e <acquire>
    if(p->state == UNUSED) {
    80001bac:	509c                	lw	a5,32(s1)
    80001bae:	cf81                	beqz	a5,80001bc6 <allocproc+0x40>
      release(&p->lock);
    80001bb0:	8526                	mv	a0,s1
    80001bb2:	fffff097          	auipc	ra,0xfffff
    80001bb6:	fcc080e7          	jalr	-52(ra) # 80000b7e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bba:	17048493          	addi	s1,s1,368
    80001bbe:	ff2492e3          	bne	s1,s2,80001ba2 <allocproc+0x1c>
  return 0;
    80001bc2:	4481                	li	s1,0
    80001bc4:	a0a9                	j	80001c0e <allocproc+0x88>
  p->pid = allocpid();
    80001bc6:	00000097          	auipc	ra,0x0
    80001bca:	f1e080e7          	jalr	-226(ra) # 80001ae4 <allocpid>
    80001bce:	c0a8                	sw	a0,64(s1)
  if((p->tf = (struct trapframe *)kalloc()) == 0){
    80001bd0:	fffff097          	auipc	ra,0xfffff
    80001bd4:	d90080e7          	jalr	-624(ra) # 80000960 <kalloc>
    80001bd8:	892a                	mv	s2,a0
    80001bda:	f0a8                	sd	a0,96(s1)
    80001bdc:	c121                	beqz	a0,80001c1c <allocproc+0x96>
  p->pagetable = proc_pagetable(p);
    80001bde:	8526                	mv	a0,s1
    80001be0:	00000097          	auipc	ra,0x0
    80001be4:	f4a080e7          	jalr	-182(ra) # 80001b2a <proc_pagetable>
    80001be8:	eca8                	sd	a0,88(s1)
  memset(&p->context, 0, sizeof p->context);
    80001bea:	07000613          	li	a2,112
    80001bee:	4581                	li	a1,0
    80001bf0:	06848513          	addi	a0,s1,104
    80001bf4:	fffff097          	auipc	ra,0xfffff
    80001bf8:	188080e7          	jalr	392(ra) # 80000d7c <memset>
  p->context.ra = (uint64)forkret;
    80001bfc:	00000797          	auipc	a5,0x0
    80001c00:	ea278793          	addi	a5,a5,-350 # 80001a9e <forkret>
    80001c04:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c06:	64bc                	ld	a5,72(s1)
    80001c08:	6705                	lui	a4,0x1
    80001c0a:	97ba                	add	a5,a5,a4
    80001c0c:	f8bc                	sd	a5,112(s1)
}
    80001c0e:	8526                	mv	a0,s1
    80001c10:	60e2                	ld	ra,24(sp)
    80001c12:	6442                	ld	s0,16(sp)
    80001c14:	64a2                	ld	s1,8(sp)
    80001c16:	6902                	ld	s2,0(sp)
    80001c18:	6105                	addi	sp,sp,32
    80001c1a:	8082                	ret
    release(&p->lock);
    80001c1c:	8526                	mv	a0,s1
    80001c1e:	fffff097          	auipc	ra,0xfffff
    80001c22:	f60080e7          	jalr	-160(ra) # 80000b7e <release>
    return 0;
    80001c26:	84ca                	mv	s1,s2
    80001c28:	b7dd                	j	80001c0e <allocproc+0x88>

0000000080001c2a <proc_freepagetable>:
{
    80001c2a:	1101                	addi	sp,sp,-32
    80001c2c:	ec06                	sd	ra,24(sp)
    80001c2e:	e822                	sd	s0,16(sp)
    80001c30:	e426                	sd	s1,8(sp)
    80001c32:	e04a                	sd	s2,0(sp)
    80001c34:	1000                	addi	s0,sp,32
    80001c36:	84aa                	mv	s1,a0
    80001c38:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, PGSIZE, 0);
    80001c3a:	4681                	li	a3,0
    80001c3c:	6605                	lui	a2,0x1
    80001c3e:	040005b7          	lui	a1,0x4000
    80001c42:	15fd                	addi	a1,a1,-1
    80001c44:	05b2                	slli	a1,a1,0xc
    80001c46:	fffff097          	auipc	ra,0xfffff
    80001c4a:	77c080e7          	jalr	1916(ra) # 800013c2 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, PGSIZE, 0);
    80001c4e:	4681                	li	a3,0
    80001c50:	6605                	lui	a2,0x1
    80001c52:	020005b7          	lui	a1,0x2000
    80001c56:	15fd                	addi	a1,a1,-1
    80001c58:	05b6                	slli	a1,a1,0xd
    80001c5a:	8526                	mv	a0,s1
    80001c5c:	fffff097          	auipc	ra,0xfffff
    80001c60:	766080e7          	jalr	1894(ra) # 800013c2 <uvmunmap>
  if(sz > 0)
    80001c64:	00091863          	bnez	s2,80001c74 <proc_freepagetable+0x4a>
}
    80001c68:	60e2                	ld	ra,24(sp)
    80001c6a:	6442                	ld	s0,16(sp)
    80001c6c:	64a2                	ld	s1,8(sp)
    80001c6e:	6902                	ld	s2,0(sp)
    80001c70:	6105                	addi	sp,sp,32
    80001c72:	8082                	ret
    uvmfree(pagetable, sz);
    80001c74:	85ca                	mv	a1,s2
    80001c76:	8526                	mv	a0,s1
    80001c78:	00000097          	auipc	ra,0x0
    80001c7c:	9b0080e7          	jalr	-1616(ra) # 80001628 <uvmfree>
}
    80001c80:	b7e5                	j	80001c68 <proc_freepagetable+0x3e>

0000000080001c82 <freeproc>:
{
    80001c82:	1101                	addi	sp,sp,-32
    80001c84:	ec06                	sd	ra,24(sp)
    80001c86:	e822                	sd	s0,16(sp)
    80001c88:	e426                	sd	s1,8(sp)
    80001c8a:	1000                	addi	s0,sp,32
    80001c8c:	84aa                	mv	s1,a0
  if(p->tf)
    80001c8e:	7128                	ld	a0,96(a0)
    80001c90:	c509                	beqz	a0,80001c9a <freeproc+0x18>
    kfree((void*)p->tf);
    80001c92:	fffff097          	auipc	ra,0xfffff
    80001c96:	bd2080e7          	jalr	-1070(ra) # 80000864 <kfree>
  p->tf = 0;
    80001c9a:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001c9e:	6ca8                	ld	a0,88(s1)
    80001ca0:	c511                	beqz	a0,80001cac <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001ca2:	68ac                	ld	a1,80(s1)
    80001ca4:	00000097          	auipc	ra,0x0
    80001ca8:	f86080e7          	jalr	-122(ra) # 80001c2a <proc_freepagetable>
  p->pagetable = 0;
    80001cac:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001cb0:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    80001cb4:	0404a023          	sw	zero,64(s1)
  p->parent = 0;
    80001cb8:	0204b423          	sd	zero,40(s1)
  p->name[0] = 0;
    80001cbc:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001cc0:	0204b823          	sd	zero,48(s1)
  p->killed = 0;
    80001cc4:	0204ac23          	sw	zero,56(s1)
  p->xstate = 0;
    80001cc8:	0204ae23          	sw	zero,60(s1)
  p->state = UNUSED;
    80001ccc:	0204a023          	sw	zero,32(s1)
}
    80001cd0:	60e2                	ld	ra,24(sp)
    80001cd2:	6442                	ld	s0,16(sp)
    80001cd4:	64a2                	ld	s1,8(sp)
    80001cd6:	6105                	addi	sp,sp,32
    80001cd8:	8082                	ret

0000000080001cda <userinit>:
{
    80001cda:	1101                	addi	sp,sp,-32
    80001cdc:	ec06                	sd	ra,24(sp)
    80001cde:	e822                	sd	s0,16(sp)
    80001ce0:	e426                	sd	s1,8(sp)
    80001ce2:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ce4:	00000097          	auipc	ra,0x0
    80001ce8:	ea2080e7          	jalr	-350(ra) # 80001b86 <allocproc>
    80001cec:	84aa                	mv	s1,a0
  initproc = p;
    80001cee:	0002a797          	auipc	a5,0x2a
    80001cf2:	34a7b523          	sd	a0,842(a5) # 8002c038 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cf6:	03300613          	li	a2,51
    80001cfa:	00007597          	auipc	a1,0x7
    80001cfe:	30658593          	addi	a1,a1,774 # 80009000 <initcode>
    80001d02:	6d28                	ld	a0,88(a0)
    80001d04:	fffff097          	auipc	ra,0xfffff
    80001d08:	7c4080e7          	jalr	1988(ra) # 800014c8 <uvminit>
  p->sz = PGSIZE;
    80001d0c:	6785                	lui	a5,0x1
    80001d0e:	e8bc                	sd	a5,80(s1)
  p->tf->epc = 0;      // user program counter
    80001d10:	70b8                	ld	a4,96(s1)
    80001d12:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->tf->sp = PGSIZE;  // user stack pointer
    80001d16:	70b8                	ld	a4,96(s1)
    80001d18:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d1a:	4641                	li	a2,16
    80001d1c:	00006597          	auipc	a1,0x6
    80001d20:	72458593          	addi	a1,a1,1828 # 80008440 <userret+0x3b0>
    80001d24:	16048513          	addi	a0,s1,352
    80001d28:	fffff097          	auipc	ra,0xfffff
    80001d2c:	1a6080e7          	jalr	422(ra) # 80000ece <safestrcpy>
  p->cwd = namei("/");
    80001d30:	00006517          	auipc	a0,0x6
    80001d34:	72050513          	addi	a0,a0,1824 # 80008450 <userret+0x3c0>
    80001d38:	00002097          	auipc	ra,0x2
    80001d3c:	0a8080e7          	jalr	168(ra) # 80003de0 <namei>
    80001d40:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80001d44:	4789                	li	a5,2
    80001d46:	d09c                	sw	a5,32(s1)
  release(&p->lock);
    80001d48:	8526                	mv	a0,s1
    80001d4a:	fffff097          	auipc	ra,0xfffff
    80001d4e:	e34080e7          	jalr	-460(ra) # 80000b7e <release>
}
    80001d52:	60e2                	ld	ra,24(sp)
    80001d54:	6442                	ld	s0,16(sp)
    80001d56:	64a2                	ld	s1,8(sp)
    80001d58:	6105                	addi	sp,sp,32
    80001d5a:	8082                	ret

0000000080001d5c <growproc>:
{
    80001d5c:	1101                	addi	sp,sp,-32
    80001d5e:	ec06                	sd	ra,24(sp)
    80001d60:	e822                	sd	s0,16(sp)
    80001d62:	e426                	sd	s1,8(sp)
    80001d64:	e04a                	sd	s2,0(sp)
    80001d66:	1000                	addi	s0,sp,32
    80001d68:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d6a:	00000097          	auipc	ra,0x0
    80001d6e:	cfc080e7          	jalr	-772(ra) # 80001a66 <myproc>
    80001d72:	892a                	mv	s2,a0
  sz = p->sz;
    80001d74:	692c                	ld	a1,80(a0)
    80001d76:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d7a:	00904f63          	bgtz	s1,80001d98 <growproc+0x3c>
  } else if(n < 0){
    80001d7e:	0204cc63          	bltz	s1,80001db6 <growproc+0x5a>
  p->sz = sz;
    80001d82:	1602                	slli	a2,a2,0x20
    80001d84:	9201                	srli	a2,a2,0x20
    80001d86:	04c93823          	sd	a2,80(s2)
  return 0;
    80001d8a:	4501                	li	a0,0
}
    80001d8c:	60e2                	ld	ra,24(sp)
    80001d8e:	6442                	ld	s0,16(sp)
    80001d90:	64a2                	ld	s1,8(sp)
    80001d92:	6902                	ld	s2,0(sp)
    80001d94:	6105                	addi	sp,sp,32
    80001d96:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d98:	9e25                	addw	a2,a2,s1
    80001d9a:	1602                	slli	a2,a2,0x20
    80001d9c:	9201                	srli	a2,a2,0x20
    80001d9e:	1582                	slli	a1,a1,0x20
    80001da0:	9181                	srli	a1,a1,0x20
    80001da2:	6d28                	ld	a0,88(a0)
    80001da4:	fffff097          	auipc	ra,0xfffff
    80001da8:	7da080e7          	jalr	2010(ra) # 8000157e <uvmalloc>
    80001dac:	0005061b          	sext.w	a2,a0
    80001db0:	fa69                	bnez	a2,80001d82 <growproc+0x26>
      return -1;
    80001db2:	557d                	li	a0,-1
    80001db4:	bfe1                	j	80001d8c <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001db6:	9e25                	addw	a2,a2,s1
    80001db8:	1602                	slli	a2,a2,0x20
    80001dba:	9201                	srli	a2,a2,0x20
    80001dbc:	1582                	slli	a1,a1,0x20
    80001dbe:	9181                	srli	a1,a1,0x20
    80001dc0:	6d28                	ld	a0,88(a0)
    80001dc2:	fffff097          	auipc	ra,0xfffff
    80001dc6:	778080e7          	jalr	1912(ra) # 8000153a <uvmdealloc>
    80001dca:	0005061b          	sext.w	a2,a0
    80001dce:	bf55                	j	80001d82 <growproc+0x26>

0000000080001dd0 <fork>:
{
    80001dd0:	7139                	addi	sp,sp,-64
    80001dd2:	fc06                	sd	ra,56(sp)
    80001dd4:	f822                	sd	s0,48(sp)
    80001dd6:	f426                	sd	s1,40(sp)
    80001dd8:	f04a                	sd	s2,32(sp)
    80001dda:	ec4e                	sd	s3,24(sp)
    80001ddc:	e852                	sd	s4,16(sp)
    80001dde:	e456                	sd	s5,8(sp)
    80001de0:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001de2:	00000097          	auipc	ra,0x0
    80001de6:	c84080e7          	jalr	-892(ra) # 80001a66 <myproc>
    80001dea:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001dec:	00000097          	auipc	ra,0x0
    80001df0:	d9a080e7          	jalr	-614(ra) # 80001b86 <allocproc>
    80001df4:	c17d                	beqz	a0,80001eda <fork+0x10a>
    80001df6:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001df8:	050ab603          	ld	a2,80(s5)
    80001dfc:	6d2c                	ld	a1,88(a0)
    80001dfe:	058ab503          	ld	a0,88(s5)
    80001e02:	00000097          	auipc	ra,0x0
    80001e06:	854080e7          	jalr	-1964(ra) # 80001656 <uvmcopy>
    80001e0a:	04054a63          	bltz	a0,80001e5e <fork+0x8e>
  np->sz = p->sz;
    80001e0e:	050ab783          	ld	a5,80(s5)
    80001e12:	04fa3823          	sd	a5,80(s4)
  np->parent = p;
    80001e16:	035a3423          	sd	s5,40(s4)
  *(np->tf) = *(p->tf);
    80001e1a:	060ab683          	ld	a3,96(s5)
    80001e1e:	87b6                	mv	a5,a3
    80001e20:	060a3703          	ld	a4,96(s4)
    80001e24:	12068693          	addi	a3,a3,288
    80001e28:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e2c:	6788                	ld	a0,8(a5)
    80001e2e:	6b8c                	ld	a1,16(a5)
    80001e30:	6f90                	ld	a2,24(a5)
    80001e32:	01073023          	sd	a6,0(a4)
    80001e36:	e708                	sd	a0,8(a4)
    80001e38:	eb0c                	sd	a1,16(a4)
    80001e3a:	ef10                	sd	a2,24(a4)
    80001e3c:	02078793          	addi	a5,a5,32
    80001e40:	02070713          	addi	a4,a4,32
    80001e44:	fed792e3          	bne	a5,a3,80001e28 <fork+0x58>
  np->tf->a0 = 0;
    80001e48:	060a3783          	ld	a5,96(s4)
    80001e4c:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e50:	0d8a8493          	addi	s1,s5,216
    80001e54:	0d8a0913          	addi	s2,s4,216
    80001e58:	158a8993          	addi	s3,s5,344
    80001e5c:	a00d                	j	80001e7e <fork+0xae>
    freeproc(np);
    80001e5e:	8552                	mv	a0,s4
    80001e60:	00000097          	auipc	ra,0x0
    80001e64:	e22080e7          	jalr	-478(ra) # 80001c82 <freeproc>
    release(&np->lock);
    80001e68:	8552                	mv	a0,s4
    80001e6a:	fffff097          	auipc	ra,0xfffff
    80001e6e:	d14080e7          	jalr	-748(ra) # 80000b7e <release>
    return -1;
    80001e72:	54fd                	li	s1,-1
    80001e74:	a889                	j	80001ec6 <fork+0xf6>
  for(i = 0; i < NOFILE; i++)
    80001e76:	04a1                	addi	s1,s1,8
    80001e78:	0921                	addi	s2,s2,8
    80001e7a:	01348b63          	beq	s1,s3,80001e90 <fork+0xc0>
    if(p->ofile[i])
    80001e7e:	6088                	ld	a0,0(s1)
    80001e80:	d97d                	beqz	a0,80001e76 <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e82:	00002097          	auipc	ra,0x2
    80001e86:	702080e7          	jalr	1794(ra) # 80004584 <filedup>
    80001e8a:	00a93023          	sd	a0,0(s2)
    80001e8e:	b7e5                	j	80001e76 <fork+0xa6>
  np->cwd = idup(p->cwd);
    80001e90:	158ab503          	ld	a0,344(s5)
    80001e94:	00001097          	auipc	ra,0x1
    80001e98:	784080e7          	jalr	1924(ra) # 80003618 <idup>
    80001e9c:	14aa3c23          	sd	a0,344(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ea0:	4641                	li	a2,16
    80001ea2:	160a8593          	addi	a1,s5,352
    80001ea6:	160a0513          	addi	a0,s4,352
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	024080e7          	jalr	36(ra) # 80000ece <safestrcpy>
  pid = np->pid;
    80001eb2:	040a2483          	lw	s1,64(s4)
  np->state = RUNNABLE;
    80001eb6:	4789                	li	a5,2
    80001eb8:	02fa2023          	sw	a5,32(s4)
  release(&np->lock);
    80001ebc:	8552                	mv	a0,s4
    80001ebe:	fffff097          	auipc	ra,0xfffff
    80001ec2:	cc0080e7          	jalr	-832(ra) # 80000b7e <release>
}
    80001ec6:	8526                	mv	a0,s1
    80001ec8:	70e2                	ld	ra,56(sp)
    80001eca:	7442                	ld	s0,48(sp)
    80001ecc:	74a2                	ld	s1,40(sp)
    80001ece:	7902                	ld	s2,32(sp)
    80001ed0:	69e2                	ld	s3,24(sp)
    80001ed2:	6a42                	ld	s4,16(sp)
    80001ed4:	6aa2                	ld	s5,8(sp)
    80001ed6:	6121                	addi	sp,sp,64
    80001ed8:	8082                	ret
    return -1;
    80001eda:	54fd                	li	s1,-1
    80001edc:	b7ed                	j	80001ec6 <fork+0xf6>

0000000080001ede <reparent>:
{
    80001ede:	7179                	addi	sp,sp,-48
    80001ee0:	f406                	sd	ra,40(sp)
    80001ee2:	f022                	sd	s0,32(sp)
    80001ee4:	ec26                	sd	s1,24(sp)
    80001ee6:	e84a                	sd	s2,16(sp)
    80001ee8:	e44e                	sd	s3,8(sp)
    80001eea:	e052                	sd	s4,0(sp)
    80001eec:	1800                	addi	s0,sp,48
    80001eee:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001ef0:	00013497          	auipc	s1,0x13
    80001ef4:	d7048493          	addi	s1,s1,-656 # 80014c60 <proc>
      pp->parent = initproc;
    80001ef8:	0002aa17          	auipc	s4,0x2a
    80001efc:	140a0a13          	addi	s4,s4,320 # 8002c038 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f00:	00019997          	auipc	s3,0x19
    80001f04:	96098993          	addi	s3,s3,-1696 # 8001a860 <tickslock>
    80001f08:	a029                	j	80001f12 <reparent+0x34>
    80001f0a:	17048493          	addi	s1,s1,368
    80001f0e:	03348363          	beq	s1,s3,80001f34 <reparent+0x56>
    if(pp->parent == p){
    80001f12:	749c                	ld	a5,40(s1)
    80001f14:	ff279be3          	bne	a5,s2,80001f0a <reparent+0x2c>
      acquire(&pp->lock);
    80001f18:	8526                	mv	a0,s1
    80001f1a:	fffff097          	auipc	ra,0xfffff
    80001f1e:	bf4080e7          	jalr	-1036(ra) # 80000b0e <acquire>
      pp->parent = initproc;
    80001f22:	000a3783          	ld	a5,0(s4)
    80001f26:	f49c                	sd	a5,40(s1)
      release(&pp->lock);
    80001f28:	8526                	mv	a0,s1
    80001f2a:	fffff097          	auipc	ra,0xfffff
    80001f2e:	c54080e7          	jalr	-940(ra) # 80000b7e <release>
    80001f32:	bfe1                	j	80001f0a <reparent+0x2c>
}
    80001f34:	70a2                	ld	ra,40(sp)
    80001f36:	7402                	ld	s0,32(sp)
    80001f38:	64e2                	ld	s1,24(sp)
    80001f3a:	6942                	ld	s2,16(sp)
    80001f3c:	69a2                	ld	s3,8(sp)
    80001f3e:	6a02                	ld	s4,0(sp)
    80001f40:	6145                	addi	sp,sp,48
    80001f42:	8082                	ret

0000000080001f44 <scheduler>:
{
    80001f44:	715d                	addi	sp,sp,-80
    80001f46:	e486                	sd	ra,72(sp)
    80001f48:	e0a2                	sd	s0,64(sp)
    80001f4a:	fc26                	sd	s1,56(sp)
    80001f4c:	f84a                	sd	s2,48(sp)
    80001f4e:	f44e                	sd	s3,40(sp)
    80001f50:	f052                	sd	s4,32(sp)
    80001f52:	ec56                	sd	s5,24(sp)
    80001f54:	e85a                	sd	s6,16(sp)
    80001f56:	e45e                	sd	s7,8(sp)
    80001f58:	e062                	sd	s8,0(sp)
    80001f5a:	0880                	addi	s0,sp,80
    80001f5c:	8792                	mv	a5,tp
  int id = r_tp();
    80001f5e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f60:	00779b13          	slli	s6,a5,0x7
    80001f64:	00013717          	auipc	a4,0x13
    80001f68:	8dc70713          	addi	a4,a4,-1828 # 80014840 <pid_lock>
    80001f6c:	975a                	add	a4,a4,s6
    80001f6e:	02073023          	sd	zero,32(a4)
        swtch(&c->scheduler, &p->context);
    80001f72:	00013717          	auipc	a4,0x13
    80001f76:	8f670713          	addi	a4,a4,-1802 # 80014868 <cpus+0x8>
    80001f7a:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001f7c:	4c0d                	li	s8,3
        c->proc = p;
    80001f7e:	079e                	slli	a5,a5,0x7
    80001f80:	00013a17          	auipc	s4,0x13
    80001f84:	8c0a0a13          	addi	s4,s4,-1856 # 80014840 <pid_lock>
    80001f88:	9a3e                	add	s4,s4,a5
        found = 1;
    80001f8a:	4b85                	li	s7,1
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f8c:	00019997          	auipc	s3,0x19
    80001f90:	8d498993          	addi	s3,s3,-1836 # 8001a860 <tickslock>
    80001f94:	a08d                	j	80001ff6 <scheduler+0xb2>
      release(&p->lock);
    80001f96:	8526                	mv	a0,s1
    80001f98:	fffff097          	auipc	ra,0xfffff
    80001f9c:	be6080e7          	jalr	-1050(ra) # 80000b7e <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fa0:	17048493          	addi	s1,s1,368
    80001fa4:	03348963          	beq	s1,s3,80001fd6 <scheduler+0x92>
      acquire(&p->lock);
    80001fa8:	8526                	mv	a0,s1
    80001faa:	fffff097          	auipc	ra,0xfffff
    80001fae:	b64080e7          	jalr	-1180(ra) # 80000b0e <acquire>
      if(p->state == RUNNABLE) {
    80001fb2:	509c                	lw	a5,32(s1)
    80001fb4:	ff2791e3          	bne	a5,s2,80001f96 <scheduler+0x52>
        p->state = RUNNING;
    80001fb8:	0384a023          	sw	s8,32(s1)
        c->proc = p;
    80001fbc:	029a3023          	sd	s1,32(s4)
        swtch(&c->scheduler, &p->context);
    80001fc0:	06848593          	addi	a1,s1,104
    80001fc4:	855a                	mv	a0,s6
    80001fc6:	00000097          	auipc	ra,0x0
    80001fca:	62c080e7          	jalr	1580(ra) # 800025f2 <swtch>
        c->proc = 0;
    80001fce:	020a3023          	sd	zero,32(s4)
        found = 1;
    80001fd2:	8ade                	mv	s5,s7
    80001fd4:	b7c9                	j	80001f96 <scheduler+0x52>
    if(found == 0){
    80001fd6:	020a9063          	bnez	s5,80001ff6 <scheduler+0xb2>
  asm volatile("csrr %0, sie" : "=r" (x) );
    80001fda:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    80001fde:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    80001fe2:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fe6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fea:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fee:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80001ff2:	10500073          	wfi
  asm volatile("csrr %0, sie" : "=r" (x) );
    80001ff6:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    80001ffa:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    80001ffe:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002002:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002006:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000200a:	10079073          	csrw	sstatus,a5
    int found = 0;
    8000200e:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80002010:	00013497          	auipc	s1,0x13
    80002014:	c5048493          	addi	s1,s1,-944 # 80014c60 <proc>
      if(p->state == RUNNABLE) {
    80002018:	4909                	li	s2,2
    8000201a:	b779                	j	80001fa8 <scheduler+0x64>

000000008000201c <sched>:
{
    8000201c:	7179                	addi	sp,sp,-48
    8000201e:	f406                	sd	ra,40(sp)
    80002020:	f022                	sd	s0,32(sp)
    80002022:	ec26                	sd	s1,24(sp)
    80002024:	e84a                	sd	s2,16(sp)
    80002026:	e44e                	sd	s3,8(sp)
    80002028:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000202a:	00000097          	auipc	ra,0x0
    8000202e:	a3c080e7          	jalr	-1476(ra) # 80001a66 <myproc>
    80002032:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002034:	fffff097          	auipc	ra,0xfffff
    80002038:	a9a080e7          	jalr	-1382(ra) # 80000ace <holding>
    8000203c:	c93d                	beqz	a0,800020b2 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000203e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002040:	2781                	sext.w	a5,a5
    80002042:	079e                	slli	a5,a5,0x7
    80002044:	00012717          	auipc	a4,0x12
    80002048:	7fc70713          	addi	a4,a4,2044 # 80014840 <pid_lock>
    8000204c:	97ba                	add	a5,a5,a4
    8000204e:	0987a703          	lw	a4,152(a5)
    80002052:	4785                	li	a5,1
    80002054:	06f71763          	bne	a4,a5,800020c2 <sched+0xa6>
  if(p->state == RUNNING)
    80002058:	5098                	lw	a4,32(s1)
    8000205a:	478d                	li	a5,3
    8000205c:	06f70b63          	beq	a4,a5,800020d2 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002060:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002064:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002066:	efb5                	bnez	a5,800020e2 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002068:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000206a:	00012917          	auipc	s2,0x12
    8000206e:	7d690913          	addi	s2,s2,2006 # 80014840 <pid_lock>
    80002072:	2781                	sext.w	a5,a5
    80002074:	079e                	slli	a5,a5,0x7
    80002076:	97ca                	add	a5,a5,s2
    80002078:	09c7a983          	lw	s3,156(a5)
    8000207c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->scheduler);
    8000207e:	2781                	sext.w	a5,a5
    80002080:	079e                	slli	a5,a5,0x7
    80002082:	00012597          	auipc	a1,0x12
    80002086:	7e658593          	addi	a1,a1,2022 # 80014868 <cpus+0x8>
    8000208a:	95be                	add	a1,a1,a5
    8000208c:	06848513          	addi	a0,s1,104
    80002090:	00000097          	auipc	ra,0x0
    80002094:	562080e7          	jalr	1378(ra) # 800025f2 <swtch>
    80002098:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000209a:	2781                	sext.w	a5,a5
    8000209c:	079e                	slli	a5,a5,0x7
    8000209e:	97ca                	add	a5,a5,s2
    800020a0:	0937ae23          	sw	s3,156(a5)
}
    800020a4:	70a2                	ld	ra,40(sp)
    800020a6:	7402                	ld	s0,32(sp)
    800020a8:	64e2                	ld	s1,24(sp)
    800020aa:	6942                	ld	s2,16(sp)
    800020ac:	69a2                	ld	s3,8(sp)
    800020ae:	6145                	addi	sp,sp,48
    800020b0:	8082                	ret
    panic("sched p->lock");
    800020b2:	00006517          	auipc	a0,0x6
    800020b6:	3a650513          	addi	a0,a0,934 # 80008458 <userret+0x3c8>
    800020ba:	ffffe097          	auipc	ra,0xffffe
    800020be:	48e080e7          	jalr	1166(ra) # 80000548 <panic>
    panic("sched locks");
    800020c2:	00006517          	auipc	a0,0x6
    800020c6:	3a650513          	addi	a0,a0,934 # 80008468 <userret+0x3d8>
    800020ca:	ffffe097          	auipc	ra,0xffffe
    800020ce:	47e080e7          	jalr	1150(ra) # 80000548 <panic>
    panic("sched running");
    800020d2:	00006517          	auipc	a0,0x6
    800020d6:	3a650513          	addi	a0,a0,934 # 80008478 <userret+0x3e8>
    800020da:	ffffe097          	auipc	ra,0xffffe
    800020de:	46e080e7          	jalr	1134(ra) # 80000548 <panic>
    panic("sched interruptible");
    800020e2:	00006517          	auipc	a0,0x6
    800020e6:	3a650513          	addi	a0,a0,934 # 80008488 <userret+0x3f8>
    800020ea:	ffffe097          	auipc	ra,0xffffe
    800020ee:	45e080e7          	jalr	1118(ra) # 80000548 <panic>

00000000800020f2 <exit>:
{
    800020f2:	7179                	addi	sp,sp,-48
    800020f4:	f406                	sd	ra,40(sp)
    800020f6:	f022                	sd	s0,32(sp)
    800020f8:	ec26                	sd	s1,24(sp)
    800020fa:	e84a                	sd	s2,16(sp)
    800020fc:	e44e                	sd	s3,8(sp)
    800020fe:	e052                	sd	s4,0(sp)
    80002100:	1800                	addi	s0,sp,48
    80002102:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002104:	00000097          	auipc	ra,0x0
    80002108:	962080e7          	jalr	-1694(ra) # 80001a66 <myproc>
    8000210c:	89aa                	mv	s3,a0
  if(p == initproc)
    8000210e:	0002a797          	auipc	a5,0x2a
    80002112:	f2a7b783          	ld	a5,-214(a5) # 8002c038 <initproc>
    80002116:	0d850493          	addi	s1,a0,216
    8000211a:	15850913          	addi	s2,a0,344
    8000211e:	02a79363          	bne	a5,a0,80002144 <exit+0x52>
    panic("init exiting");
    80002122:	00006517          	auipc	a0,0x6
    80002126:	37e50513          	addi	a0,a0,894 # 800084a0 <userret+0x410>
    8000212a:	ffffe097          	auipc	ra,0xffffe
    8000212e:	41e080e7          	jalr	1054(ra) # 80000548 <panic>
      fileclose(f);
    80002132:	00002097          	auipc	ra,0x2
    80002136:	4a4080e7          	jalr	1188(ra) # 800045d6 <fileclose>
      p->ofile[fd] = 0;
    8000213a:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000213e:	04a1                	addi	s1,s1,8
    80002140:	01248563          	beq	s1,s2,8000214a <exit+0x58>
    if(p->ofile[fd]){
    80002144:	6088                	ld	a0,0(s1)
    80002146:	f575                	bnez	a0,80002132 <exit+0x40>
    80002148:	bfdd                	j	8000213e <exit+0x4c>
  begin_op(ROOTDEV);
    8000214a:	4501                	li	a0,0
    8000214c:	00002097          	auipc	ra,0x2
    80002150:	ef0080e7          	jalr	-272(ra) # 8000403c <begin_op>
  iput(p->cwd);
    80002154:	1589b503          	ld	a0,344(s3)
    80002158:	00001097          	auipc	ra,0x1
    8000215c:	60c080e7          	jalr	1548(ra) # 80003764 <iput>
  end_op(ROOTDEV);
    80002160:	4501                	li	a0,0
    80002162:	00002097          	auipc	ra,0x2
    80002166:	f84080e7          	jalr	-124(ra) # 800040e6 <end_op>
  p->cwd = 0;
    8000216a:	1409bc23          	sd	zero,344(s3)
  acquire(&initproc->lock);
    8000216e:	0002a497          	auipc	s1,0x2a
    80002172:	eca48493          	addi	s1,s1,-310 # 8002c038 <initproc>
    80002176:	6088                	ld	a0,0(s1)
    80002178:	fffff097          	auipc	ra,0xfffff
    8000217c:	996080e7          	jalr	-1642(ra) # 80000b0e <acquire>
  wakeup1(initproc);
    80002180:	6088                	ld	a0,0(s1)
    80002182:	fffff097          	auipc	ra,0xfffff
    80002186:	7a4080e7          	jalr	1956(ra) # 80001926 <wakeup1>
  release(&initproc->lock);
    8000218a:	6088                	ld	a0,0(s1)
    8000218c:	fffff097          	auipc	ra,0xfffff
    80002190:	9f2080e7          	jalr	-1550(ra) # 80000b7e <release>
  acquire(&p->lock);
    80002194:	854e                	mv	a0,s3
    80002196:	fffff097          	auipc	ra,0xfffff
    8000219a:	978080e7          	jalr	-1672(ra) # 80000b0e <acquire>
  struct proc *original_parent = p->parent;
    8000219e:	0289b483          	ld	s1,40(s3)
  release(&p->lock);
    800021a2:	854e                	mv	a0,s3
    800021a4:	fffff097          	auipc	ra,0xfffff
    800021a8:	9da080e7          	jalr	-1574(ra) # 80000b7e <release>
  acquire(&original_parent->lock);
    800021ac:	8526                	mv	a0,s1
    800021ae:	fffff097          	auipc	ra,0xfffff
    800021b2:	960080e7          	jalr	-1696(ra) # 80000b0e <acquire>
  acquire(&p->lock);
    800021b6:	854e                	mv	a0,s3
    800021b8:	fffff097          	auipc	ra,0xfffff
    800021bc:	956080e7          	jalr	-1706(ra) # 80000b0e <acquire>
  reparent(p);
    800021c0:	854e                	mv	a0,s3
    800021c2:	00000097          	auipc	ra,0x0
    800021c6:	d1c080e7          	jalr	-740(ra) # 80001ede <reparent>
  wakeup1(original_parent);
    800021ca:	8526                	mv	a0,s1
    800021cc:	fffff097          	auipc	ra,0xfffff
    800021d0:	75a080e7          	jalr	1882(ra) # 80001926 <wakeup1>
  p->xstate = status;
    800021d4:	0349ae23          	sw	s4,60(s3)
  p->state = ZOMBIE;
    800021d8:	4791                	li	a5,4
    800021da:	02f9a023          	sw	a5,32(s3)
  release(&original_parent->lock);
    800021de:	8526                	mv	a0,s1
    800021e0:	fffff097          	auipc	ra,0xfffff
    800021e4:	99e080e7          	jalr	-1634(ra) # 80000b7e <release>
  sched();
    800021e8:	00000097          	auipc	ra,0x0
    800021ec:	e34080e7          	jalr	-460(ra) # 8000201c <sched>
  panic("zombie exit");
    800021f0:	00006517          	auipc	a0,0x6
    800021f4:	2c050513          	addi	a0,a0,704 # 800084b0 <userret+0x420>
    800021f8:	ffffe097          	auipc	ra,0xffffe
    800021fc:	350080e7          	jalr	848(ra) # 80000548 <panic>

0000000080002200 <yield>:
{
    80002200:	1101                	addi	sp,sp,-32
    80002202:	ec06                	sd	ra,24(sp)
    80002204:	e822                	sd	s0,16(sp)
    80002206:	e426                	sd	s1,8(sp)
    80002208:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000220a:	00000097          	auipc	ra,0x0
    8000220e:	85c080e7          	jalr	-1956(ra) # 80001a66 <myproc>
    80002212:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002214:	fffff097          	auipc	ra,0xfffff
    80002218:	8fa080e7          	jalr	-1798(ra) # 80000b0e <acquire>
  p->state = RUNNABLE;
    8000221c:	4789                	li	a5,2
    8000221e:	d09c                	sw	a5,32(s1)
  sched();
    80002220:	00000097          	auipc	ra,0x0
    80002224:	dfc080e7          	jalr	-516(ra) # 8000201c <sched>
  release(&p->lock);
    80002228:	8526                	mv	a0,s1
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	954080e7          	jalr	-1708(ra) # 80000b7e <release>
}
    80002232:	60e2                	ld	ra,24(sp)
    80002234:	6442                	ld	s0,16(sp)
    80002236:	64a2                	ld	s1,8(sp)
    80002238:	6105                	addi	sp,sp,32
    8000223a:	8082                	ret

000000008000223c <sleep>:
{
    8000223c:	7179                	addi	sp,sp,-48
    8000223e:	f406                	sd	ra,40(sp)
    80002240:	f022                	sd	s0,32(sp)
    80002242:	ec26                	sd	s1,24(sp)
    80002244:	e84a                	sd	s2,16(sp)
    80002246:	e44e                	sd	s3,8(sp)
    80002248:	1800                	addi	s0,sp,48
    8000224a:	89aa                	mv	s3,a0
    8000224c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000224e:	00000097          	auipc	ra,0x0
    80002252:	818080e7          	jalr	-2024(ra) # 80001a66 <myproc>
    80002256:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002258:	05250663          	beq	a0,s2,800022a4 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    8000225c:	fffff097          	auipc	ra,0xfffff
    80002260:	8b2080e7          	jalr	-1870(ra) # 80000b0e <acquire>
    release(lk);
    80002264:	854a                	mv	a0,s2
    80002266:	fffff097          	auipc	ra,0xfffff
    8000226a:	918080e7          	jalr	-1768(ra) # 80000b7e <release>
  p->chan = chan;
    8000226e:	0334b823          	sd	s3,48(s1)
  p->state = SLEEPING;
    80002272:	4785                	li	a5,1
    80002274:	d09c                	sw	a5,32(s1)
  sched();
    80002276:	00000097          	auipc	ra,0x0
    8000227a:	da6080e7          	jalr	-602(ra) # 8000201c <sched>
  p->chan = 0;
    8000227e:	0204b823          	sd	zero,48(s1)
    release(&p->lock);
    80002282:	8526                	mv	a0,s1
    80002284:	fffff097          	auipc	ra,0xfffff
    80002288:	8fa080e7          	jalr	-1798(ra) # 80000b7e <release>
    acquire(lk);
    8000228c:	854a                	mv	a0,s2
    8000228e:	fffff097          	auipc	ra,0xfffff
    80002292:	880080e7          	jalr	-1920(ra) # 80000b0e <acquire>
}
    80002296:	70a2                	ld	ra,40(sp)
    80002298:	7402                	ld	s0,32(sp)
    8000229a:	64e2                	ld	s1,24(sp)
    8000229c:	6942                	ld	s2,16(sp)
    8000229e:	69a2                	ld	s3,8(sp)
    800022a0:	6145                	addi	sp,sp,48
    800022a2:	8082                	ret
  p->chan = chan;
    800022a4:	03353823          	sd	s3,48(a0)
  p->state = SLEEPING;
    800022a8:	4785                	li	a5,1
    800022aa:	d11c                	sw	a5,32(a0)
  sched();
    800022ac:	00000097          	auipc	ra,0x0
    800022b0:	d70080e7          	jalr	-656(ra) # 8000201c <sched>
  p->chan = 0;
    800022b4:	0204b823          	sd	zero,48(s1)
  if(lk != &p->lock){
    800022b8:	bff9                	j	80002296 <sleep+0x5a>

00000000800022ba <wait>:
{
    800022ba:	715d                	addi	sp,sp,-80
    800022bc:	e486                	sd	ra,72(sp)
    800022be:	e0a2                	sd	s0,64(sp)
    800022c0:	fc26                	sd	s1,56(sp)
    800022c2:	f84a                	sd	s2,48(sp)
    800022c4:	f44e                	sd	s3,40(sp)
    800022c6:	f052                	sd	s4,32(sp)
    800022c8:	ec56                	sd	s5,24(sp)
    800022ca:	e85a                	sd	s6,16(sp)
    800022cc:	e45e                	sd	s7,8(sp)
    800022ce:	0880                	addi	s0,sp,80
    800022d0:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022d2:	fffff097          	auipc	ra,0xfffff
    800022d6:	794080e7          	jalr	1940(ra) # 80001a66 <myproc>
    800022da:	892a                	mv	s2,a0
  acquire(&p->lock);
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	832080e7          	jalr	-1998(ra) # 80000b0e <acquire>
    havekids = 0;
    800022e4:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022e6:	4a11                	li	s4,4
        havekids = 1;
    800022e8:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800022ea:	00018997          	auipc	s3,0x18
    800022ee:	57698993          	addi	s3,s3,1398 # 8001a860 <tickslock>
    havekids = 0;
    800022f2:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022f4:	00013497          	auipc	s1,0x13
    800022f8:	96c48493          	addi	s1,s1,-1684 # 80014c60 <proc>
    800022fc:	a08d                	j	8000235e <wait+0xa4>
          pid = np->pid;
    800022fe:	0404a983          	lw	s3,64(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002302:	000b0e63          	beqz	s6,8000231e <wait+0x64>
    80002306:	4691                	li	a3,4
    80002308:	03c48613          	addi	a2,s1,60
    8000230c:	85da                	mv	a1,s6
    8000230e:	05893503          	ld	a0,88(s2)
    80002312:	fffff097          	auipc	ra,0xfffff
    80002316:	446080e7          	jalr	1094(ra) # 80001758 <copyout>
    8000231a:	02054263          	bltz	a0,8000233e <wait+0x84>
          freeproc(np);
    8000231e:	8526                	mv	a0,s1
    80002320:	00000097          	auipc	ra,0x0
    80002324:	962080e7          	jalr	-1694(ra) # 80001c82 <freeproc>
          release(&np->lock);
    80002328:	8526                	mv	a0,s1
    8000232a:	fffff097          	auipc	ra,0xfffff
    8000232e:	854080e7          	jalr	-1964(ra) # 80000b7e <release>
          release(&p->lock);
    80002332:	854a                	mv	a0,s2
    80002334:	fffff097          	auipc	ra,0xfffff
    80002338:	84a080e7          	jalr	-1974(ra) # 80000b7e <release>
          return pid;
    8000233c:	a8a9                	j	80002396 <wait+0xdc>
            release(&np->lock);
    8000233e:	8526                	mv	a0,s1
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	83e080e7          	jalr	-1986(ra) # 80000b7e <release>
            release(&p->lock);
    80002348:	854a                	mv	a0,s2
    8000234a:	fffff097          	auipc	ra,0xfffff
    8000234e:	834080e7          	jalr	-1996(ra) # 80000b7e <release>
            return -1;
    80002352:	59fd                	li	s3,-1
    80002354:	a089                	j	80002396 <wait+0xdc>
    for(np = proc; np < &proc[NPROC]; np++){
    80002356:	17048493          	addi	s1,s1,368
    8000235a:	03348463          	beq	s1,s3,80002382 <wait+0xc8>
      if(np->parent == p){
    8000235e:	749c                	ld	a5,40(s1)
    80002360:	ff279be3          	bne	a5,s2,80002356 <wait+0x9c>
        acquire(&np->lock);
    80002364:	8526                	mv	a0,s1
    80002366:	ffffe097          	auipc	ra,0xffffe
    8000236a:	7a8080e7          	jalr	1960(ra) # 80000b0e <acquire>
        if(np->state == ZOMBIE){
    8000236e:	509c                	lw	a5,32(s1)
    80002370:	f94787e3          	beq	a5,s4,800022fe <wait+0x44>
        release(&np->lock);
    80002374:	8526                	mv	a0,s1
    80002376:	fffff097          	auipc	ra,0xfffff
    8000237a:	808080e7          	jalr	-2040(ra) # 80000b7e <release>
        havekids = 1;
    8000237e:	8756                	mv	a4,s5
    80002380:	bfd9                	j	80002356 <wait+0x9c>
    if(!havekids || p->killed){
    80002382:	c701                	beqz	a4,8000238a <wait+0xd0>
    80002384:	03892783          	lw	a5,56(s2)
    80002388:	c39d                	beqz	a5,800023ae <wait+0xf4>
      release(&p->lock);
    8000238a:	854a                	mv	a0,s2
    8000238c:	ffffe097          	auipc	ra,0xffffe
    80002390:	7f2080e7          	jalr	2034(ra) # 80000b7e <release>
      return -1;
    80002394:	59fd                	li	s3,-1
}
    80002396:	854e                	mv	a0,s3
    80002398:	60a6                	ld	ra,72(sp)
    8000239a:	6406                	ld	s0,64(sp)
    8000239c:	74e2                	ld	s1,56(sp)
    8000239e:	7942                	ld	s2,48(sp)
    800023a0:	79a2                	ld	s3,40(sp)
    800023a2:	7a02                	ld	s4,32(sp)
    800023a4:	6ae2                	ld	s5,24(sp)
    800023a6:	6b42                	ld	s6,16(sp)
    800023a8:	6ba2                	ld	s7,8(sp)
    800023aa:	6161                	addi	sp,sp,80
    800023ac:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800023ae:	85ca                	mv	a1,s2
    800023b0:	854a                	mv	a0,s2
    800023b2:	00000097          	auipc	ra,0x0
    800023b6:	e8a080e7          	jalr	-374(ra) # 8000223c <sleep>
    havekids = 0;
    800023ba:	bf25                	j	800022f2 <wait+0x38>

00000000800023bc <wakeup>:
{
    800023bc:	7139                	addi	sp,sp,-64
    800023be:	fc06                	sd	ra,56(sp)
    800023c0:	f822                	sd	s0,48(sp)
    800023c2:	f426                	sd	s1,40(sp)
    800023c4:	f04a                	sd	s2,32(sp)
    800023c6:	ec4e                	sd	s3,24(sp)
    800023c8:	e852                	sd	s4,16(sp)
    800023ca:	e456                	sd	s5,8(sp)
    800023cc:	0080                	addi	s0,sp,64
    800023ce:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800023d0:	00013497          	auipc	s1,0x13
    800023d4:	89048493          	addi	s1,s1,-1904 # 80014c60 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800023d8:	4985                	li	s3,1
      p->state = RUNNABLE;
    800023da:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800023dc:	00018917          	auipc	s2,0x18
    800023e0:	48490913          	addi	s2,s2,1156 # 8001a860 <tickslock>
    800023e4:	a811                	j	800023f8 <wakeup+0x3c>
    release(&p->lock);
    800023e6:	8526                	mv	a0,s1
    800023e8:	ffffe097          	auipc	ra,0xffffe
    800023ec:	796080e7          	jalr	1942(ra) # 80000b7e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800023f0:	17048493          	addi	s1,s1,368
    800023f4:	03248063          	beq	s1,s2,80002414 <wakeup+0x58>
    acquire(&p->lock);
    800023f8:	8526                	mv	a0,s1
    800023fa:	ffffe097          	auipc	ra,0xffffe
    800023fe:	714080e7          	jalr	1812(ra) # 80000b0e <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002402:	509c                	lw	a5,32(s1)
    80002404:	ff3791e3          	bne	a5,s3,800023e6 <wakeup+0x2a>
    80002408:	789c                	ld	a5,48(s1)
    8000240a:	fd479ee3          	bne	a5,s4,800023e6 <wakeup+0x2a>
      p->state = RUNNABLE;
    8000240e:	0354a023          	sw	s5,32(s1)
    80002412:	bfd1                	j	800023e6 <wakeup+0x2a>
}
    80002414:	70e2                	ld	ra,56(sp)
    80002416:	7442                	ld	s0,48(sp)
    80002418:	74a2                	ld	s1,40(sp)
    8000241a:	7902                	ld	s2,32(sp)
    8000241c:	69e2                	ld	s3,24(sp)
    8000241e:	6a42                	ld	s4,16(sp)
    80002420:	6aa2                	ld	s5,8(sp)
    80002422:	6121                	addi	sp,sp,64
    80002424:	8082                	ret

0000000080002426 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002426:	7179                	addi	sp,sp,-48
    80002428:	f406                	sd	ra,40(sp)
    8000242a:	f022                	sd	s0,32(sp)
    8000242c:	ec26                	sd	s1,24(sp)
    8000242e:	e84a                	sd	s2,16(sp)
    80002430:	e44e                	sd	s3,8(sp)
    80002432:	1800                	addi	s0,sp,48
    80002434:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002436:	00013497          	auipc	s1,0x13
    8000243a:	82a48493          	addi	s1,s1,-2006 # 80014c60 <proc>
    8000243e:	00018997          	auipc	s3,0x18
    80002442:	42298993          	addi	s3,s3,1058 # 8001a860 <tickslock>
    acquire(&p->lock);
    80002446:	8526                	mv	a0,s1
    80002448:	ffffe097          	auipc	ra,0xffffe
    8000244c:	6c6080e7          	jalr	1734(ra) # 80000b0e <acquire>
    if(p->pid == pid){
    80002450:	40bc                	lw	a5,64(s1)
    80002452:	01278d63          	beq	a5,s2,8000246c <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002456:	8526                	mv	a0,s1
    80002458:	ffffe097          	auipc	ra,0xffffe
    8000245c:	726080e7          	jalr	1830(ra) # 80000b7e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002460:	17048493          	addi	s1,s1,368
    80002464:	ff3491e3          	bne	s1,s3,80002446 <kill+0x20>
  }
  return -1;
    80002468:	557d                	li	a0,-1
    8000246a:	a821                	j	80002482 <kill+0x5c>
      p->killed = 1;
    8000246c:	4785                	li	a5,1
    8000246e:	dc9c                	sw	a5,56(s1)
      if(p->state == SLEEPING){
    80002470:	5098                	lw	a4,32(s1)
    80002472:	00f70f63          	beq	a4,a5,80002490 <kill+0x6a>
      release(&p->lock);
    80002476:	8526                	mv	a0,s1
    80002478:	ffffe097          	auipc	ra,0xffffe
    8000247c:	706080e7          	jalr	1798(ra) # 80000b7e <release>
      return 0;
    80002480:	4501                	li	a0,0
}
    80002482:	70a2                	ld	ra,40(sp)
    80002484:	7402                	ld	s0,32(sp)
    80002486:	64e2                	ld	s1,24(sp)
    80002488:	6942                	ld	s2,16(sp)
    8000248a:	69a2                	ld	s3,8(sp)
    8000248c:	6145                	addi	sp,sp,48
    8000248e:	8082                	ret
        p->state = RUNNABLE;
    80002490:	4789                	li	a5,2
    80002492:	d09c                	sw	a5,32(s1)
    80002494:	b7cd                	j	80002476 <kill+0x50>

0000000080002496 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002496:	7179                	addi	sp,sp,-48
    80002498:	f406                	sd	ra,40(sp)
    8000249a:	f022                	sd	s0,32(sp)
    8000249c:	ec26                	sd	s1,24(sp)
    8000249e:	e84a                	sd	s2,16(sp)
    800024a0:	e44e                	sd	s3,8(sp)
    800024a2:	e052                	sd	s4,0(sp)
    800024a4:	1800                	addi	s0,sp,48
    800024a6:	84aa                	mv	s1,a0
    800024a8:	892e                	mv	s2,a1
    800024aa:	89b2                	mv	s3,a2
    800024ac:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024ae:	fffff097          	auipc	ra,0xfffff
    800024b2:	5b8080e7          	jalr	1464(ra) # 80001a66 <myproc>
  if(user_dst){
    800024b6:	c08d                	beqz	s1,800024d8 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024b8:	86d2                	mv	a3,s4
    800024ba:	864e                	mv	a2,s3
    800024bc:	85ca                	mv	a1,s2
    800024be:	6d28                	ld	a0,88(a0)
    800024c0:	fffff097          	auipc	ra,0xfffff
    800024c4:	298080e7          	jalr	664(ra) # 80001758 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024c8:	70a2                	ld	ra,40(sp)
    800024ca:	7402                	ld	s0,32(sp)
    800024cc:	64e2                	ld	s1,24(sp)
    800024ce:	6942                	ld	s2,16(sp)
    800024d0:	69a2                	ld	s3,8(sp)
    800024d2:	6a02                	ld	s4,0(sp)
    800024d4:	6145                	addi	sp,sp,48
    800024d6:	8082                	ret
    memmove((char *)dst, src, len);
    800024d8:	000a061b          	sext.w	a2,s4
    800024dc:	85ce                	mv	a1,s3
    800024de:	854a                	mv	a0,s2
    800024e0:	fffff097          	auipc	ra,0xfffff
    800024e4:	8f8080e7          	jalr	-1800(ra) # 80000dd8 <memmove>
    return 0;
    800024e8:	8526                	mv	a0,s1
    800024ea:	bff9                	j	800024c8 <either_copyout+0x32>

00000000800024ec <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024ec:	7179                	addi	sp,sp,-48
    800024ee:	f406                	sd	ra,40(sp)
    800024f0:	f022                	sd	s0,32(sp)
    800024f2:	ec26                	sd	s1,24(sp)
    800024f4:	e84a                	sd	s2,16(sp)
    800024f6:	e44e                	sd	s3,8(sp)
    800024f8:	e052                	sd	s4,0(sp)
    800024fa:	1800                	addi	s0,sp,48
    800024fc:	892a                	mv	s2,a0
    800024fe:	84ae                	mv	s1,a1
    80002500:	89b2                	mv	s3,a2
    80002502:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002504:	fffff097          	auipc	ra,0xfffff
    80002508:	562080e7          	jalr	1378(ra) # 80001a66 <myproc>
  if(user_src){
    8000250c:	c08d                	beqz	s1,8000252e <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000250e:	86d2                	mv	a3,s4
    80002510:	864e                	mv	a2,s3
    80002512:	85ca                	mv	a1,s2
    80002514:	6d28                	ld	a0,88(a0)
    80002516:	fffff097          	auipc	ra,0xfffff
    8000251a:	2ce080e7          	jalr	718(ra) # 800017e4 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000251e:	70a2                	ld	ra,40(sp)
    80002520:	7402                	ld	s0,32(sp)
    80002522:	64e2                	ld	s1,24(sp)
    80002524:	6942                	ld	s2,16(sp)
    80002526:	69a2                	ld	s3,8(sp)
    80002528:	6a02                	ld	s4,0(sp)
    8000252a:	6145                	addi	sp,sp,48
    8000252c:	8082                	ret
    memmove(dst, (char*)src, len);
    8000252e:	000a061b          	sext.w	a2,s4
    80002532:	85ce                	mv	a1,s3
    80002534:	854a                	mv	a0,s2
    80002536:	fffff097          	auipc	ra,0xfffff
    8000253a:	8a2080e7          	jalr	-1886(ra) # 80000dd8 <memmove>
    return 0;
    8000253e:	8526                	mv	a0,s1
    80002540:	bff9                	j	8000251e <either_copyin+0x32>

0000000080002542 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002542:	715d                	addi	sp,sp,-80
    80002544:	e486                	sd	ra,72(sp)
    80002546:	e0a2                	sd	s0,64(sp)
    80002548:	fc26                	sd	s1,56(sp)
    8000254a:	f84a                	sd	s2,48(sp)
    8000254c:	f44e                	sd	s3,40(sp)
    8000254e:	f052                	sd	s4,32(sp)
    80002550:	ec56                	sd	s5,24(sp)
    80002552:	e85a                	sd	s6,16(sp)
    80002554:	e45e                	sd	s7,8(sp)
    80002556:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002558:	00006517          	auipc	a0,0x6
    8000255c:	d3850513          	addi	a0,a0,-712 # 80008290 <userret+0x200>
    80002560:	ffffe097          	auipc	ra,0xffffe
    80002564:	042080e7          	jalr	66(ra) # 800005a2 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002568:	00013497          	auipc	s1,0x13
    8000256c:	85848493          	addi	s1,s1,-1960 # 80014dc0 <proc+0x160>
    80002570:	00018917          	auipc	s2,0x18
    80002574:	45090913          	addi	s2,s2,1104 # 8001a9c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002578:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    8000257a:	00006997          	auipc	s3,0x6
    8000257e:	f4698993          	addi	s3,s3,-186 # 800084c0 <userret+0x430>
    printf("%d %s %s", p->pid, state, p->name);
    80002582:	00006a97          	auipc	s5,0x6
    80002586:	f46a8a93          	addi	s5,s5,-186 # 800084c8 <userret+0x438>
    printf("\n");
    8000258a:	00006a17          	auipc	s4,0x6
    8000258e:	d06a0a13          	addi	s4,s4,-762 # 80008290 <userret+0x200>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002592:	00006b97          	auipc	s7,0x6
    80002596:	536b8b93          	addi	s7,s7,1334 # 80008ac8 <states.0>
    8000259a:	a00d                	j	800025bc <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000259c:	ee06a583          	lw	a1,-288(a3)
    800025a0:	8556                	mv	a0,s5
    800025a2:	ffffe097          	auipc	ra,0xffffe
    800025a6:	000080e7          	jalr	ra # 800005a2 <printf>
    printf("\n");
    800025aa:	8552                	mv	a0,s4
    800025ac:	ffffe097          	auipc	ra,0xffffe
    800025b0:	ff6080e7          	jalr	-10(ra) # 800005a2 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025b4:	17048493          	addi	s1,s1,368
    800025b8:	03248263          	beq	s1,s2,800025dc <procdump+0x9a>
    if(p->state == UNUSED)
    800025bc:	86a6                	mv	a3,s1
    800025be:	ec04a783          	lw	a5,-320(s1)
    800025c2:	dbed                	beqz	a5,800025b4 <procdump+0x72>
      state = "???";
    800025c4:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025c6:	fcfb6be3          	bltu	s6,a5,8000259c <procdump+0x5a>
    800025ca:	02079713          	slli	a4,a5,0x20
    800025ce:	01d75793          	srli	a5,a4,0x1d
    800025d2:	97de                	add	a5,a5,s7
    800025d4:	6390                	ld	a2,0(a5)
    800025d6:	f279                	bnez	a2,8000259c <procdump+0x5a>
      state = "???";
    800025d8:	864e                	mv	a2,s3
    800025da:	b7c9                	j	8000259c <procdump+0x5a>
  }
}
    800025dc:	60a6                	ld	ra,72(sp)
    800025de:	6406                	ld	s0,64(sp)
    800025e0:	74e2                	ld	s1,56(sp)
    800025e2:	7942                	ld	s2,48(sp)
    800025e4:	79a2                	ld	s3,40(sp)
    800025e6:	7a02                	ld	s4,32(sp)
    800025e8:	6ae2                	ld	s5,24(sp)
    800025ea:	6b42                	ld	s6,16(sp)
    800025ec:	6ba2                	ld	s7,8(sp)
    800025ee:	6161                	addi	sp,sp,80
    800025f0:	8082                	ret

00000000800025f2 <swtch>:
    800025f2:	00153023          	sd	ra,0(a0)
    800025f6:	00253423          	sd	sp,8(a0)
    800025fa:	e900                	sd	s0,16(a0)
    800025fc:	ed04                	sd	s1,24(a0)
    800025fe:	03253023          	sd	s2,32(a0)
    80002602:	03353423          	sd	s3,40(a0)
    80002606:	03453823          	sd	s4,48(a0)
    8000260a:	03553c23          	sd	s5,56(a0)
    8000260e:	05653023          	sd	s6,64(a0)
    80002612:	05753423          	sd	s7,72(a0)
    80002616:	05853823          	sd	s8,80(a0)
    8000261a:	05953c23          	sd	s9,88(a0)
    8000261e:	07a53023          	sd	s10,96(a0)
    80002622:	07b53423          	sd	s11,104(a0)
    80002626:	0005b083          	ld	ra,0(a1)
    8000262a:	0085b103          	ld	sp,8(a1)
    8000262e:	6980                	ld	s0,16(a1)
    80002630:	6d84                	ld	s1,24(a1)
    80002632:	0205b903          	ld	s2,32(a1)
    80002636:	0285b983          	ld	s3,40(a1)
    8000263a:	0305ba03          	ld	s4,48(a1)
    8000263e:	0385ba83          	ld	s5,56(a1)
    80002642:	0405bb03          	ld	s6,64(a1)
    80002646:	0485bb83          	ld	s7,72(a1)
    8000264a:	0505bc03          	ld	s8,80(a1)
    8000264e:	0585bc83          	ld	s9,88(a1)
    80002652:	0605bd03          	ld	s10,96(a1)
    80002656:	0685bd83          	ld	s11,104(a1)
    8000265a:	8082                	ret

000000008000265c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000265c:	1141                	addi	sp,sp,-16
    8000265e:	e406                	sd	ra,8(sp)
    80002660:	e022                	sd	s0,0(sp)
    80002662:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002664:	00006597          	auipc	a1,0x6
    80002668:	e9c58593          	addi	a1,a1,-356 # 80008500 <userret+0x470>
    8000266c:	00018517          	auipc	a0,0x18
    80002670:	1f450513          	addi	a0,a0,500 # 8001a860 <tickslock>
    80002674:	ffffe097          	auipc	ra,0xffffe
    80002678:	34c080e7          	jalr	844(ra) # 800009c0 <initlock>
}
    8000267c:	60a2                	ld	ra,8(sp)
    8000267e:	6402                	ld	s0,0(sp)
    80002680:	0141                	addi	sp,sp,16
    80002682:	8082                	ret

0000000080002684 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002684:	1141                	addi	sp,sp,-16
    80002686:	e422                	sd	s0,8(sp)
    80002688:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000268a:	00003797          	auipc	a5,0x3
    8000268e:	5e678793          	addi	a5,a5,1510 # 80005c70 <kernelvec>
    80002692:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002696:	6422                	ld	s0,8(sp)
    80002698:	0141                	addi	sp,sp,16
    8000269a:	8082                	ret

000000008000269c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000269c:	1141                	addi	sp,sp,-16
    8000269e:	e406                	sd	ra,8(sp)
    800026a0:	e022                	sd	s0,0(sp)
    800026a2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026a4:	fffff097          	auipc	ra,0xfffff
    800026a8:	3c2080e7          	jalr	962(ra) # 80001a66 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026ac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026b0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026b2:	10079073          	csrw	sstatus,a5
  // turn off interrupts, since we're switching
  // now from kerneltrap() to usertrap().
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800026b6:	00006617          	auipc	a2,0x6
    800026ba:	94a60613          	addi	a2,a2,-1718 # 80008000 <trampoline>
    800026be:	00006697          	auipc	a3,0x6
    800026c2:	94268693          	addi	a3,a3,-1726 # 80008000 <trampoline>
    800026c6:	8e91                	sub	a3,a3,a2
    800026c8:	040007b7          	lui	a5,0x4000
    800026cc:	17fd                	addi	a5,a5,-1
    800026ce:	07b2                	slli	a5,a5,0xc
    800026d0:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026d2:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->tf->kernel_satp = r_satp();         // kernel page table
    800026d6:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026d8:	180026f3          	csrr	a3,satp
    800026dc:	e314                	sd	a3,0(a4)
  p->tf->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026de:	7138                	ld	a4,96(a0)
    800026e0:	6534                	ld	a3,72(a0)
    800026e2:	6585                	lui	a1,0x1
    800026e4:	96ae                	add	a3,a3,a1
    800026e6:	e714                	sd	a3,8(a4)
  p->tf->kernel_trap = (uint64)usertrap;
    800026e8:	7138                	ld	a4,96(a0)
    800026ea:	00000697          	auipc	a3,0x0
    800026ee:	12868693          	addi	a3,a3,296 # 80002812 <usertrap>
    800026f2:	eb14                	sd	a3,16(a4)
  p->tf->kernel_hartid = r_tp();         // hartid for cpuid()
    800026f4:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026f6:	8692                	mv	a3,tp
    800026f8:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026fa:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026fe:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002702:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002706:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->tf->epc);
    8000270a:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000270c:	6f18                	ld	a4,24(a4)
    8000270e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002712:	6d2c                	ld	a1,88(a0)
    80002714:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002716:	00006717          	auipc	a4,0x6
    8000271a:	97a70713          	addi	a4,a4,-1670 # 80008090 <userret>
    8000271e:	8f11                	sub	a4,a4,a2
    80002720:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002722:	577d                	li	a4,-1
    80002724:	177e                	slli	a4,a4,0x3f
    80002726:	8dd9                	or	a1,a1,a4
    80002728:	02000537          	lui	a0,0x2000
    8000272c:	157d                	addi	a0,a0,-1
    8000272e:	0536                	slli	a0,a0,0xd
    80002730:	9782                	jalr	a5
}
    80002732:	60a2                	ld	ra,8(sp)
    80002734:	6402                	ld	s0,0(sp)
    80002736:	0141                	addi	sp,sp,16
    80002738:	8082                	ret

000000008000273a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000273a:	1101                	addi	sp,sp,-32
    8000273c:	ec06                	sd	ra,24(sp)
    8000273e:	e822                	sd	s0,16(sp)
    80002740:	e426                	sd	s1,8(sp)
    80002742:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002744:	00018497          	auipc	s1,0x18
    80002748:	11c48493          	addi	s1,s1,284 # 8001a860 <tickslock>
    8000274c:	8526                	mv	a0,s1
    8000274e:	ffffe097          	auipc	ra,0xffffe
    80002752:	3c0080e7          	jalr	960(ra) # 80000b0e <acquire>
  ticks++;
    80002756:	0002a517          	auipc	a0,0x2a
    8000275a:	8ea50513          	addi	a0,a0,-1814 # 8002c040 <ticks>
    8000275e:	411c                	lw	a5,0(a0)
    80002760:	2785                	addiw	a5,a5,1
    80002762:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002764:	00000097          	auipc	ra,0x0
    80002768:	c58080e7          	jalr	-936(ra) # 800023bc <wakeup>
  release(&tickslock);
    8000276c:	8526                	mv	a0,s1
    8000276e:	ffffe097          	auipc	ra,0xffffe
    80002772:	410080e7          	jalr	1040(ra) # 80000b7e <release>
}
    80002776:	60e2                	ld	ra,24(sp)
    80002778:	6442                	ld	s0,16(sp)
    8000277a:	64a2                	ld	s1,8(sp)
    8000277c:	6105                	addi	sp,sp,32
    8000277e:	8082                	ret

0000000080002780 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002780:	1101                	addi	sp,sp,-32
    80002782:	ec06                	sd	ra,24(sp)
    80002784:	e822                	sd	s0,16(sp)
    80002786:	e426                	sd	s1,8(sp)
    80002788:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000278a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000278e:	00074d63          	bltz	a4,800027a8 <devintr+0x28>
      virtio_disk_intr(irq - VIRTIO0_IRQ);
    }

    plic_complete(irq);
    return 1;
  } else if(scause == 0x8000000000000001L){
    80002792:	57fd                	li	a5,-1
    80002794:	17fe                	slli	a5,a5,0x3f
    80002796:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002798:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000279a:	04f70b63          	beq	a4,a5,800027f0 <devintr+0x70>
  }
}
    8000279e:	60e2                	ld	ra,24(sp)
    800027a0:	6442                	ld	s0,16(sp)
    800027a2:	64a2                	ld	s1,8(sp)
    800027a4:	6105                	addi	sp,sp,32
    800027a6:	8082                	ret
     (scause & 0xff) == 9){
    800027a8:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800027ac:	46a5                	li	a3,9
    800027ae:	fed792e3          	bne	a5,a3,80002792 <devintr+0x12>
    int irq = plic_claim();
    800027b2:	00003097          	auipc	ra,0x3
    800027b6:	5c6080e7          	jalr	1478(ra) # 80005d78 <plic_claim>
    800027ba:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027bc:	47a9                	li	a5,10
    800027be:	00f50e63          	beq	a0,a5,800027da <devintr+0x5a>
    } else if(irq == VIRTIO0_IRQ || irq == VIRTIO1_IRQ ){
    800027c2:	fff5079b          	addiw	a5,a0,-1
    800027c6:	4705                	li	a4,1
    800027c8:	00f77e63          	bgeu	a4,a5,800027e4 <devintr+0x64>
    plic_complete(irq);
    800027cc:	8526                	mv	a0,s1
    800027ce:	00003097          	auipc	ra,0x3
    800027d2:	5ce080e7          	jalr	1486(ra) # 80005d9c <plic_complete>
    return 1;
    800027d6:	4505                	li	a0,1
    800027d8:	b7d9                	j	8000279e <devintr+0x1e>
      uartintr();
    800027da:	ffffe097          	auipc	ra,0xffffe
    800027de:	05e080e7          	jalr	94(ra) # 80000838 <uartintr>
    800027e2:	b7ed                	j	800027cc <devintr+0x4c>
      virtio_disk_intr(irq - VIRTIO0_IRQ);
    800027e4:	853e                	mv	a0,a5
    800027e6:	00004097          	auipc	ra,0x4
    800027ea:	b60080e7          	jalr	-1184(ra) # 80006346 <virtio_disk_intr>
    800027ee:	bff9                	j	800027cc <devintr+0x4c>
    if(cpuid() == 0){
    800027f0:	fffff097          	auipc	ra,0xfffff
    800027f4:	24a080e7          	jalr	586(ra) # 80001a3a <cpuid>
    800027f8:	c901                	beqz	a0,80002808 <devintr+0x88>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027fa:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027fe:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002800:	14479073          	csrw	sip,a5
    return 2;
    80002804:	4509                	li	a0,2
    80002806:	bf61                	j	8000279e <devintr+0x1e>
      clockintr();
    80002808:	00000097          	auipc	ra,0x0
    8000280c:	f32080e7          	jalr	-206(ra) # 8000273a <clockintr>
    80002810:	b7ed                	j	800027fa <devintr+0x7a>

0000000080002812 <usertrap>:
{
    80002812:	1101                	addi	sp,sp,-32
    80002814:	ec06                	sd	ra,24(sp)
    80002816:	e822                	sd	s0,16(sp)
    80002818:	e426                	sd	s1,8(sp)
    8000281a:	e04a                	sd	s2,0(sp)
    8000281c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000281e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002822:	1007f793          	andi	a5,a5,256
    80002826:	e7bd                	bnez	a5,80002894 <usertrap+0x82>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002828:	00003797          	auipc	a5,0x3
    8000282c:	44878793          	addi	a5,a5,1096 # 80005c70 <kernelvec>
    80002830:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002834:	fffff097          	auipc	ra,0xfffff
    80002838:	232080e7          	jalr	562(ra) # 80001a66 <myproc>
    8000283c:	84aa                	mv	s1,a0
  p->tf->epc = r_sepc();
    8000283e:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002840:	14102773          	csrr	a4,sepc
    80002844:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002846:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000284a:	47a1                	li	a5,8
    8000284c:	06f71263          	bne	a4,a5,800028b0 <usertrap+0x9e>
    if(p->killed)
    80002850:	5d1c                	lw	a5,56(a0)
    80002852:	eba9                	bnez	a5,800028a4 <usertrap+0x92>
    p->tf->epc += 4;
    80002854:	70b8                	ld	a4,96(s1)
    80002856:	6f1c                	ld	a5,24(a4)
    80002858:	0791                	addi	a5,a5,4
    8000285a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sie" : "=r" (x) );
    8000285c:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    80002860:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    80002864:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002868:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000286c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002870:	10079073          	csrw	sstatus,a5
    syscall();
    80002874:	00000097          	auipc	ra,0x0
    80002878:	2e0080e7          	jalr	736(ra) # 80002b54 <syscall>
  if(p->killed)
    8000287c:	5c9c                	lw	a5,56(s1)
    8000287e:	ebc1                	bnez	a5,8000290e <usertrap+0xfc>
  usertrapret();
    80002880:	00000097          	auipc	ra,0x0
    80002884:	e1c080e7          	jalr	-484(ra) # 8000269c <usertrapret>
}
    80002888:	60e2                	ld	ra,24(sp)
    8000288a:	6442                	ld	s0,16(sp)
    8000288c:	64a2                	ld	s1,8(sp)
    8000288e:	6902                	ld	s2,0(sp)
    80002890:	6105                	addi	sp,sp,32
    80002892:	8082                	ret
    panic("usertrap: not from user mode");
    80002894:	00006517          	auipc	a0,0x6
    80002898:	c7450513          	addi	a0,a0,-908 # 80008508 <userret+0x478>
    8000289c:	ffffe097          	auipc	ra,0xffffe
    800028a0:	cac080e7          	jalr	-852(ra) # 80000548 <panic>
      exit(-1);
    800028a4:	557d                	li	a0,-1
    800028a6:	00000097          	auipc	ra,0x0
    800028aa:	84c080e7          	jalr	-1972(ra) # 800020f2 <exit>
    800028ae:	b75d                	j	80002854 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800028b0:	00000097          	auipc	ra,0x0
    800028b4:	ed0080e7          	jalr	-304(ra) # 80002780 <devintr>
    800028b8:	892a                	mv	s2,a0
    800028ba:	c501                	beqz	a0,800028c2 <usertrap+0xb0>
  if(p->killed)
    800028bc:	5c9c                	lw	a5,56(s1)
    800028be:	c3a1                	beqz	a5,800028fe <usertrap+0xec>
    800028c0:	a815                	j	800028f4 <usertrap+0xe2>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028c2:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028c6:	40b0                	lw	a2,64(s1)
    800028c8:	00006517          	auipc	a0,0x6
    800028cc:	c6050513          	addi	a0,a0,-928 # 80008528 <userret+0x498>
    800028d0:	ffffe097          	auipc	ra,0xffffe
    800028d4:	cd2080e7          	jalr	-814(ra) # 800005a2 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028d8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028dc:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028e0:	00006517          	auipc	a0,0x6
    800028e4:	c7850513          	addi	a0,a0,-904 # 80008558 <userret+0x4c8>
    800028e8:	ffffe097          	auipc	ra,0xffffe
    800028ec:	cba080e7          	jalr	-838(ra) # 800005a2 <printf>
    p->killed = 1;
    800028f0:	4785                	li	a5,1
    800028f2:	dc9c                	sw	a5,56(s1)
    exit(-1);
    800028f4:	557d                	li	a0,-1
    800028f6:	fffff097          	auipc	ra,0xfffff
    800028fa:	7fc080e7          	jalr	2044(ra) # 800020f2 <exit>
  if(which_dev == 2)
    800028fe:	4789                	li	a5,2
    80002900:	f8f910e3          	bne	s2,a5,80002880 <usertrap+0x6e>
    yield();
    80002904:	00000097          	auipc	ra,0x0
    80002908:	8fc080e7          	jalr	-1796(ra) # 80002200 <yield>
    8000290c:	bf95                	j	80002880 <usertrap+0x6e>
  int which_dev = 0;
    8000290e:	4901                	li	s2,0
    80002910:	b7d5                	j	800028f4 <usertrap+0xe2>

0000000080002912 <kerneltrap>:
{
    80002912:	7179                	addi	sp,sp,-48
    80002914:	f406                	sd	ra,40(sp)
    80002916:	f022                	sd	s0,32(sp)
    80002918:	ec26                	sd	s1,24(sp)
    8000291a:	e84a                	sd	s2,16(sp)
    8000291c:	e44e                	sd	s3,8(sp)
    8000291e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002920:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002924:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002928:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000292c:	1004f793          	andi	a5,s1,256
    80002930:	cb85                	beqz	a5,80002960 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002932:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002936:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002938:	ef85                	bnez	a5,80002970 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000293a:	00000097          	auipc	ra,0x0
    8000293e:	e46080e7          	jalr	-442(ra) # 80002780 <devintr>
    80002942:	cd1d                	beqz	a0,80002980 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002944:	4789                	li	a5,2
    80002946:	06f50a63          	beq	a0,a5,800029ba <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000294a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000294e:	10049073          	csrw	sstatus,s1
}
    80002952:	70a2                	ld	ra,40(sp)
    80002954:	7402                	ld	s0,32(sp)
    80002956:	64e2                	ld	s1,24(sp)
    80002958:	6942                	ld	s2,16(sp)
    8000295a:	69a2                	ld	s3,8(sp)
    8000295c:	6145                	addi	sp,sp,48
    8000295e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002960:	00006517          	auipc	a0,0x6
    80002964:	c1850513          	addi	a0,a0,-1000 # 80008578 <userret+0x4e8>
    80002968:	ffffe097          	auipc	ra,0xffffe
    8000296c:	be0080e7          	jalr	-1056(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002970:	00006517          	auipc	a0,0x6
    80002974:	c3050513          	addi	a0,a0,-976 # 800085a0 <userret+0x510>
    80002978:	ffffe097          	auipc	ra,0xffffe
    8000297c:	bd0080e7          	jalr	-1072(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002980:	85ce                	mv	a1,s3
    80002982:	00006517          	auipc	a0,0x6
    80002986:	c3e50513          	addi	a0,a0,-962 # 800085c0 <userret+0x530>
    8000298a:	ffffe097          	auipc	ra,0xffffe
    8000298e:	c18080e7          	jalr	-1000(ra) # 800005a2 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002992:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002996:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000299a:	00006517          	auipc	a0,0x6
    8000299e:	c3650513          	addi	a0,a0,-970 # 800085d0 <userret+0x540>
    800029a2:	ffffe097          	auipc	ra,0xffffe
    800029a6:	c00080e7          	jalr	-1024(ra) # 800005a2 <printf>
    panic("kerneltrap");
    800029aa:	00006517          	auipc	a0,0x6
    800029ae:	c3e50513          	addi	a0,a0,-962 # 800085e8 <userret+0x558>
    800029b2:	ffffe097          	auipc	ra,0xffffe
    800029b6:	b96080e7          	jalr	-1130(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029ba:	fffff097          	auipc	ra,0xfffff
    800029be:	0ac080e7          	jalr	172(ra) # 80001a66 <myproc>
    800029c2:	d541                	beqz	a0,8000294a <kerneltrap+0x38>
    800029c4:	fffff097          	auipc	ra,0xfffff
    800029c8:	0a2080e7          	jalr	162(ra) # 80001a66 <myproc>
    800029cc:	5118                	lw	a4,32(a0)
    800029ce:	478d                	li	a5,3
    800029d0:	f6f71de3          	bne	a4,a5,8000294a <kerneltrap+0x38>
    yield();
    800029d4:	00000097          	auipc	ra,0x0
    800029d8:	82c080e7          	jalr	-2004(ra) # 80002200 <yield>
    800029dc:	b7bd                	j	8000294a <kerneltrap+0x38>

00000000800029de <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800029de:	1101                	addi	sp,sp,-32
    800029e0:	ec06                	sd	ra,24(sp)
    800029e2:	e822                	sd	s0,16(sp)
    800029e4:	e426                	sd	s1,8(sp)
    800029e6:	1000                	addi	s0,sp,32
    800029e8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029ea:	fffff097          	auipc	ra,0xfffff
    800029ee:	07c080e7          	jalr	124(ra) # 80001a66 <myproc>
  switch (n) {
    800029f2:	4795                	li	a5,5
    800029f4:	0497e163          	bltu	a5,s1,80002a36 <argraw+0x58>
    800029f8:	048a                	slli	s1,s1,0x2
    800029fa:	00006717          	auipc	a4,0x6
    800029fe:	0f670713          	addi	a4,a4,246 # 80008af0 <states.0+0x28>
    80002a02:	94ba                	add	s1,s1,a4
    80002a04:	409c                	lw	a5,0(s1)
    80002a06:	97ba                	add	a5,a5,a4
    80002a08:	8782                	jr	a5
  case 0:
    return p->tf->a0;
    80002a0a:	713c                	ld	a5,96(a0)
    80002a0c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->tf->a5;
  }
  panic("argraw");
  return -1;
}
    80002a0e:	60e2                	ld	ra,24(sp)
    80002a10:	6442                	ld	s0,16(sp)
    80002a12:	64a2                	ld	s1,8(sp)
    80002a14:	6105                	addi	sp,sp,32
    80002a16:	8082                	ret
    return p->tf->a1;
    80002a18:	713c                	ld	a5,96(a0)
    80002a1a:	7fa8                	ld	a0,120(a5)
    80002a1c:	bfcd                	j	80002a0e <argraw+0x30>
    return p->tf->a2;
    80002a1e:	713c                	ld	a5,96(a0)
    80002a20:	63c8                	ld	a0,128(a5)
    80002a22:	b7f5                	j	80002a0e <argraw+0x30>
    return p->tf->a3;
    80002a24:	713c                	ld	a5,96(a0)
    80002a26:	67c8                	ld	a0,136(a5)
    80002a28:	b7dd                	j	80002a0e <argraw+0x30>
    return p->tf->a4;
    80002a2a:	713c                	ld	a5,96(a0)
    80002a2c:	6bc8                	ld	a0,144(a5)
    80002a2e:	b7c5                	j	80002a0e <argraw+0x30>
    return p->tf->a5;
    80002a30:	713c                	ld	a5,96(a0)
    80002a32:	6fc8                	ld	a0,152(a5)
    80002a34:	bfe9                	j	80002a0e <argraw+0x30>
  panic("argraw");
    80002a36:	00006517          	auipc	a0,0x6
    80002a3a:	bc250513          	addi	a0,a0,-1086 # 800085f8 <userret+0x568>
    80002a3e:	ffffe097          	auipc	ra,0xffffe
    80002a42:	b0a080e7          	jalr	-1270(ra) # 80000548 <panic>

0000000080002a46 <fetchaddr>:
{
    80002a46:	1101                	addi	sp,sp,-32
    80002a48:	ec06                	sd	ra,24(sp)
    80002a4a:	e822                	sd	s0,16(sp)
    80002a4c:	e426                	sd	s1,8(sp)
    80002a4e:	e04a                	sd	s2,0(sp)
    80002a50:	1000                	addi	s0,sp,32
    80002a52:	84aa                	mv	s1,a0
    80002a54:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a56:	fffff097          	auipc	ra,0xfffff
    80002a5a:	010080e7          	jalr	16(ra) # 80001a66 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002a5e:	693c                	ld	a5,80(a0)
    80002a60:	02f4f863          	bgeu	s1,a5,80002a90 <fetchaddr+0x4a>
    80002a64:	00848713          	addi	a4,s1,8
    80002a68:	02e7e663          	bltu	a5,a4,80002a94 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a6c:	46a1                	li	a3,8
    80002a6e:	8626                	mv	a2,s1
    80002a70:	85ca                	mv	a1,s2
    80002a72:	6d28                	ld	a0,88(a0)
    80002a74:	fffff097          	auipc	ra,0xfffff
    80002a78:	d70080e7          	jalr	-656(ra) # 800017e4 <copyin>
    80002a7c:	00a03533          	snez	a0,a0
    80002a80:	40a00533          	neg	a0,a0
}
    80002a84:	60e2                	ld	ra,24(sp)
    80002a86:	6442                	ld	s0,16(sp)
    80002a88:	64a2                	ld	s1,8(sp)
    80002a8a:	6902                	ld	s2,0(sp)
    80002a8c:	6105                	addi	sp,sp,32
    80002a8e:	8082                	ret
    return -1;
    80002a90:	557d                	li	a0,-1
    80002a92:	bfcd                	j	80002a84 <fetchaddr+0x3e>
    80002a94:	557d                	li	a0,-1
    80002a96:	b7fd                	j	80002a84 <fetchaddr+0x3e>

0000000080002a98 <fetchstr>:
{
    80002a98:	7179                	addi	sp,sp,-48
    80002a9a:	f406                	sd	ra,40(sp)
    80002a9c:	f022                	sd	s0,32(sp)
    80002a9e:	ec26                	sd	s1,24(sp)
    80002aa0:	e84a                	sd	s2,16(sp)
    80002aa2:	e44e                	sd	s3,8(sp)
    80002aa4:	1800                	addi	s0,sp,48
    80002aa6:	892a                	mv	s2,a0
    80002aa8:	84ae                	mv	s1,a1
    80002aaa:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002aac:	fffff097          	auipc	ra,0xfffff
    80002ab0:	fba080e7          	jalr	-70(ra) # 80001a66 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002ab4:	86ce                	mv	a3,s3
    80002ab6:	864a                	mv	a2,s2
    80002ab8:	85a6                	mv	a1,s1
    80002aba:	6d28                	ld	a0,88(a0)
    80002abc:	fffff097          	auipc	ra,0xfffff
    80002ac0:	db6080e7          	jalr	-586(ra) # 80001872 <copyinstr>
  if(err < 0)
    80002ac4:	00054763          	bltz	a0,80002ad2 <fetchstr+0x3a>
  return strlen(buf);
    80002ac8:	8526                	mv	a0,s1
    80002aca:	ffffe097          	auipc	ra,0xffffe
    80002ace:	436080e7          	jalr	1078(ra) # 80000f00 <strlen>
}
    80002ad2:	70a2                	ld	ra,40(sp)
    80002ad4:	7402                	ld	s0,32(sp)
    80002ad6:	64e2                	ld	s1,24(sp)
    80002ad8:	6942                	ld	s2,16(sp)
    80002ada:	69a2                	ld	s3,8(sp)
    80002adc:	6145                	addi	sp,sp,48
    80002ade:	8082                	ret

0000000080002ae0 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002ae0:	1101                	addi	sp,sp,-32
    80002ae2:	ec06                	sd	ra,24(sp)
    80002ae4:	e822                	sd	s0,16(sp)
    80002ae6:	e426                	sd	s1,8(sp)
    80002ae8:	1000                	addi	s0,sp,32
    80002aea:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002aec:	00000097          	auipc	ra,0x0
    80002af0:	ef2080e7          	jalr	-270(ra) # 800029de <argraw>
    80002af4:	c088                	sw	a0,0(s1)
  return 0;
}
    80002af6:	4501                	li	a0,0
    80002af8:	60e2                	ld	ra,24(sp)
    80002afa:	6442                	ld	s0,16(sp)
    80002afc:	64a2                	ld	s1,8(sp)
    80002afe:	6105                	addi	sp,sp,32
    80002b00:	8082                	ret

0000000080002b02 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b02:	1101                	addi	sp,sp,-32
    80002b04:	ec06                	sd	ra,24(sp)
    80002b06:	e822                	sd	s0,16(sp)
    80002b08:	e426                	sd	s1,8(sp)
    80002b0a:	1000                	addi	s0,sp,32
    80002b0c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b0e:	00000097          	auipc	ra,0x0
    80002b12:	ed0080e7          	jalr	-304(ra) # 800029de <argraw>
    80002b16:	e088                	sd	a0,0(s1)
  return 0;
}
    80002b18:	4501                	li	a0,0
    80002b1a:	60e2                	ld	ra,24(sp)
    80002b1c:	6442                	ld	s0,16(sp)
    80002b1e:	64a2                	ld	s1,8(sp)
    80002b20:	6105                	addi	sp,sp,32
    80002b22:	8082                	ret

0000000080002b24 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b24:	1101                	addi	sp,sp,-32
    80002b26:	ec06                	sd	ra,24(sp)
    80002b28:	e822                	sd	s0,16(sp)
    80002b2a:	e426                	sd	s1,8(sp)
    80002b2c:	e04a                	sd	s2,0(sp)
    80002b2e:	1000                	addi	s0,sp,32
    80002b30:	84ae                	mv	s1,a1
    80002b32:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002b34:	00000097          	auipc	ra,0x0
    80002b38:	eaa080e7          	jalr	-342(ra) # 800029de <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002b3c:	864a                	mv	a2,s2
    80002b3e:	85a6                	mv	a1,s1
    80002b40:	00000097          	auipc	ra,0x0
    80002b44:	f58080e7          	jalr	-168(ra) # 80002a98 <fetchstr>
}
    80002b48:	60e2                	ld	ra,24(sp)
    80002b4a:	6442                	ld	s0,16(sp)
    80002b4c:	64a2                	ld	s1,8(sp)
    80002b4e:	6902                	ld	s2,0(sp)
    80002b50:	6105                	addi	sp,sp,32
    80002b52:	8082                	ret

0000000080002b54 <syscall>:
[SYS_ntas]    sys_ntas,
};

void
syscall(void)
{
    80002b54:	1101                	addi	sp,sp,-32
    80002b56:	ec06                	sd	ra,24(sp)
    80002b58:	e822                	sd	s0,16(sp)
    80002b5a:	e426                	sd	s1,8(sp)
    80002b5c:	e04a                	sd	s2,0(sp)
    80002b5e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002b60:	fffff097          	auipc	ra,0xfffff
    80002b64:	f06080e7          	jalr	-250(ra) # 80001a66 <myproc>
    80002b68:	84aa                	mv	s1,a0

  num = p->tf->a7;
    80002b6a:	06053903          	ld	s2,96(a0)
    80002b6e:	0a893783          	ld	a5,168(s2)
    80002b72:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b76:	37fd                	addiw	a5,a5,-1
    80002b78:	4755                	li	a4,21
    80002b7a:	00f76f63          	bltu	a4,a5,80002b98 <syscall+0x44>
    80002b7e:	00369713          	slli	a4,a3,0x3
    80002b82:	00006797          	auipc	a5,0x6
    80002b86:	f8678793          	addi	a5,a5,-122 # 80008b08 <syscalls>
    80002b8a:	97ba                	add	a5,a5,a4
    80002b8c:	639c                	ld	a5,0(a5)
    80002b8e:	c789                	beqz	a5,80002b98 <syscall+0x44>
    p->tf->a0 = syscalls[num]();
    80002b90:	9782                	jalr	a5
    80002b92:	06a93823          	sd	a0,112(s2)
    80002b96:	a839                	j	80002bb4 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b98:	16048613          	addi	a2,s1,352
    80002b9c:	40ac                	lw	a1,64(s1)
    80002b9e:	00006517          	auipc	a0,0x6
    80002ba2:	a6250513          	addi	a0,a0,-1438 # 80008600 <userret+0x570>
    80002ba6:	ffffe097          	auipc	ra,0xffffe
    80002baa:	9fc080e7          	jalr	-1540(ra) # 800005a2 <printf>
            p->pid, p->name, num);
    p->tf->a0 = -1;
    80002bae:	70bc                	ld	a5,96(s1)
    80002bb0:	577d                	li	a4,-1
    80002bb2:	fbb8                	sd	a4,112(a5)
  }
}
    80002bb4:	60e2                	ld	ra,24(sp)
    80002bb6:	6442                	ld	s0,16(sp)
    80002bb8:	64a2                	ld	s1,8(sp)
    80002bba:	6902                	ld	s2,0(sp)
    80002bbc:	6105                	addi	sp,sp,32
    80002bbe:	8082                	ret

0000000080002bc0 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002bc0:	1101                	addi	sp,sp,-32
    80002bc2:	ec06                	sd	ra,24(sp)
    80002bc4:	e822                	sd	s0,16(sp)
    80002bc6:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002bc8:	fec40593          	addi	a1,s0,-20
    80002bcc:	4501                	li	a0,0
    80002bce:	00000097          	auipc	ra,0x0
    80002bd2:	f12080e7          	jalr	-238(ra) # 80002ae0 <argint>
    return -1;
    80002bd6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002bd8:	00054963          	bltz	a0,80002bea <sys_exit+0x2a>
  exit(n);
    80002bdc:	fec42503          	lw	a0,-20(s0)
    80002be0:	fffff097          	auipc	ra,0xfffff
    80002be4:	512080e7          	jalr	1298(ra) # 800020f2 <exit>
  return 0;  // not reached
    80002be8:	4781                	li	a5,0
}
    80002bea:	853e                	mv	a0,a5
    80002bec:	60e2                	ld	ra,24(sp)
    80002bee:	6442                	ld	s0,16(sp)
    80002bf0:	6105                	addi	sp,sp,32
    80002bf2:	8082                	ret

0000000080002bf4 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002bf4:	1141                	addi	sp,sp,-16
    80002bf6:	e406                	sd	ra,8(sp)
    80002bf8:	e022                	sd	s0,0(sp)
    80002bfa:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002bfc:	fffff097          	auipc	ra,0xfffff
    80002c00:	e6a080e7          	jalr	-406(ra) # 80001a66 <myproc>
}
    80002c04:	4128                	lw	a0,64(a0)
    80002c06:	60a2                	ld	ra,8(sp)
    80002c08:	6402                	ld	s0,0(sp)
    80002c0a:	0141                	addi	sp,sp,16
    80002c0c:	8082                	ret

0000000080002c0e <sys_fork>:

uint64
sys_fork(void)
{
    80002c0e:	1141                	addi	sp,sp,-16
    80002c10:	e406                	sd	ra,8(sp)
    80002c12:	e022                	sd	s0,0(sp)
    80002c14:	0800                	addi	s0,sp,16
  return fork();
    80002c16:	fffff097          	auipc	ra,0xfffff
    80002c1a:	1ba080e7          	jalr	442(ra) # 80001dd0 <fork>
}
    80002c1e:	60a2                	ld	ra,8(sp)
    80002c20:	6402                	ld	s0,0(sp)
    80002c22:	0141                	addi	sp,sp,16
    80002c24:	8082                	ret

0000000080002c26 <sys_wait>:

uint64
sys_wait(void)
{
    80002c26:	1101                	addi	sp,sp,-32
    80002c28:	ec06                	sd	ra,24(sp)
    80002c2a:	e822                	sd	s0,16(sp)
    80002c2c:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002c2e:	fe840593          	addi	a1,s0,-24
    80002c32:	4501                	li	a0,0
    80002c34:	00000097          	auipc	ra,0x0
    80002c38:	ece080e7          	jalr	-306(ra) # 80002b02 <argaddr>
    80002c3c:	87aa                	mv	a5,a0
    return -1;
    80002c3e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002c40:	0007c863          	bltz	a5,80002c50 <sys_wait+0x2a>
  return wait(p);
    80002c44:	fe843503          	ld	a0,-24(s0)
    80002c48:	fffff097          	auipc	ra,0xfffff
    80002c4c:	672080e7          	jalr	1650(ra) # 800022ba <wait>
}
    80002c50:	60e2                	ld	ra,24(sp)
    80002c52:	6442                	ld	s0,16(sp)
    80002c54:	6105                	addi	sp,sp,32
    80002c56:	8082                	ret

0000000080002c58 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c58:	7179                	addi	sp,sp,-48
    80002c5a:	f406                	sd	ra,40(sp)
    80002c5c:	f022                	sd	s0,32(sp)
    80002c5e:	ec26                	sd	s1,24(sp)
    80002c60:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002c62:	fdc40593          	addi	a1,s0,-36
    80002c66:	4501                	li	a0,0
    80002c68:	00000097          	auipc	ra,0x0
    80002c6c:	e78080e7          	jalr	-392(ra) # 80002ae0 <argint>
    return -1;
    80002c70:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002c72:	00054f63          	bltz	a0,80002c90 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002c76:	fffff097          	auipc	ra,0xfffff
    80002c7a:	df0080e7          	jalr	-528(ra) # 80001a66 <myproc>
    80002c7e:	4924                	lw	s1,80(a0)
  if(growproc(n) < 0)
    80002c80:	fdc42503          	lw	a0,-36(s0)
    80002c84:	fffff097          	auipc	ra,0xfffff
    80002c88:	0d8080e7          	jalr	216(ra) # 80001d5c <growproc>
    80002c8c:	00054863          	bltz	a0,80002c9c <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002c90:	8526                	mv	a0,s1
    80002c92:	70a2                	ld	ra,40(sp)
    80002c94:	7402                	ld	s0,32(sp)
    80002c96:	64e2                	ld	s1,24(sp)
    80002c98:	6145                	addi	sp,sp,48
    80002c9a:	8082                	ret
    return -1;
    80002c9c:	54fd                	li	s1,-1
    80002c9e:	bfcd                	j	80002c90 <sys_sbrk+0x38>

0000000080002ca0 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002ca0:	7139                	addi	sp,sp,-64
    80002ca2:	fc06                	sd	ra,56(sp)
    80002ca4:	f822                	sd	s0,48(sp)
    80002ca6:	f426                	sd	s1,40(sp)
    80002ca8:	f04a                	sd	s2,32(sp)
    80002caa:	ec4e                	sd	s3,24(sp)
    80002cac:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002cae:	fcc40593          	addi	a1,s0,-52
    80002cb2:	4501                	li	a0,0
    80002cb4:	00000097          	auipc	ra,0x0
    80002cb8:	e2c080e7          	jalr	-468(ra) # 80002ae0 <argint>
    return -1;
    80002cbc:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002cbe:	06054563          	bltz	a0,80002d28 <sys_sleep+0x88>
  acquire(&tickslock);
    80002cc2:	00018517          	auipc	a0,0x18
    80002cc6:	b9e50513          	addi	a0,a0,-1122 # 8001a860 <tickslock>
    80002cca:	ffffe097          	auipc	ra,0xffffe
    80002cce:	e44080e7          	jalr	-444(ra) # 80000b0e <acquire>
  ticks0 = ticks;
    80002cd2:	00029917          	auipc	s2,0x29
    80002cd6:	36e92903          	lw	s2,878(s2) # 8002c040 <ticks>
  while(ticks - ticks0 < n){
    80002cda:	fcc42783          	lw	a5,-52(s0)
    80002cde:	cf85                	beqz	a5,80002d16 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ce0:	00018997          	auipc	s3,0x18
    80002ce4:	b8098993          	addi	s3,s3,-1152 # 8001a860 <tickslock>
    80002ce8:	00029497          	auipc	s1,0x29
    80002cec:	35848493          	addi	s1,s1,856 # 8002c040 <ticks>
    if(myproc()->killed){
    80002cf0:	fffff097          	auipc	ra,0xfffff
    80002cf4:	d76080e7          	jalr	-650(ra) # 80001a66 <myproc>
    80002cf8:	5d1c                	lw	a5,56(a0)
    80002cfa:	ef9d                	bnez	a5,80002d38 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002cfc:	85ce                	mv	a1,s3
    80002cfe:	8526                	mv	a0,s1
    80002d00:	fffff097          	auipc	ra,0xfffff
    80002d04:	53c080e7          	jalr	1340(ra) # 8000223c <sleep>
  while(ticks - ticks0 < n){
    80002d08:	409c                	lw	a5,0(s1)
    80002d0a:	412787bb          	subw	a5,a5,s2
    80002d0e:	fcc42703          	lw	a4,-52(s0)
    80002d12:	fce7efe3          	bltu	a5,a4,80002cf0 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002d16:	00018517          	auipc	a0,0x18
    80002d1a:	b4a50513          	addi	a0,a0,-1206 # 8001a860 <tickslock>
    80002d1e:	ffffe097          	auipc	ra,0xffffe
    80002d22:	e60080e7          	jalr	-416(ra) # 80000b7e <release>
  return 0;
    80002d26:	4781                	li	a5,0
}
    80002d28:	853e                	mv	a0,a5
    80002d2a:	70e2                	ld	ra,56(sp)
    80002d2c:	7442                	ld	s0,48(sp)
    80002d2e:	74a2                	ld	s1,40(sp)
    80002d30:	7902                	ld	s2,32(sp)
    80002d32:	69e2                	ld	s3,24(sp)
    80002d34:	6121                	addi	sp,sp,64
    80002d36:	8082                	ret
      release(&tickslock);
    80002d38:	00018517          	auipc	a0,0x18
    80002d3c:	b2850513          	addi	a0,a0,-1240 # 8001a860 <tickslock>
    80002d40:	ffffe097          	auipc	ra,0xffffe
    80002d44:	e3e080e7          	jalr	-450(ra) # 80000b7e <release>
      return -1;
    80002d48:	57fd                	li	a5,-1
    80002d4a:	bff9                	j	80002d28 <sys_sleep+0x88>

0000000080002d4c <sys_kill>:

uint64
sys_kill(void)
{
    80002d4c:	1101                	addi	sp,sp,-32
    80002d4e:	ec06                	sd	ra,24(sp)
    80002d50:	e822                	sd	s0,16(sp)
    80002d52:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002d54:	fec40593          	addi	a1,s0,-20
    80002d58:	4501                	li	a0,0
    80002d5a:	00000097          	auipc	ra,0x0
    80002d5e:	d86080e7          	jalr	-634(ra) # 80002ae0 <argint>
    80002d62:	87aa                	mv	a5,a0
    return -1;
    80002d64:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002d66:	0007c863          	bltz	a5,80002d76 <sys_kill+0x2a>
  return kill(pid);
    80002d6a:	fec42503          	lw	a0,-20(s0)
    80002d6e:	fffff097          	auipc	ra,0xfffff
    80002d72:	6b8080e7          	jalr	1720(ra) # 80002426 <kill>
}
    80002d76:	60e2                	ld	ra,24(sp)
    80002d78:	6442                	ld	s0,16(sp)
    80002d7a:	6105                	addi	sp,sp,32
    80002d7c:	8082                	ret

0000000080002d7e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d7e:	1101                	addi	sp,sp,-32
    80002d80:	ec06                	sd	ra,24(sp)
    80002d82:	e822                	sd	s0,16(sp)
    80002d84:	e426                	sd	s1,8(sp)
    80002d86:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d88:	00018517          	auipc	a0,0x18
    80002d8c:	ad850513          	addi	a0,a0,-1320 # 8001a860 <tickslock>
    80002d90:	ffffe097          	auipc	ra,0xffffe
    80002d94:	d7e080e7          	jalr	-642(ra) # 80000b0e <acquire>
  xticks = ticks;
    80002d98:	00029497          	auipc	s1,0x29
    80002d9c:	2a84a483          	lw	s1,680(s1) # 8002c040 <ticks>
  release(&tickslock);
    80002da0:	00018517          	auipc	a0,0x18
    80002da4:	ac050513          	addi	a0,a0,-1344 # 8001a860 <tickslock>
    80002da8:	ffffe097          	auipc	ra,0xffffe
    80002dac:	dd6080e7          	jalr	-554(ra) # 80000b7e <release>
  return xticks;
}
    80002db0:	02049513          	slli	a0,s1,0x20
    80002db4:	9101                	srli	a0,a0,0x20
    80002db6:	60e2                	ld	ra,24(sp)
    80002db8:	6442                	ld	s0,16(sp)
    80002dba:	64a2                	ld	s1,8(sp)
    80002dbc:	6105                	addi	sp,sp,32
    80002dbe:	8082                	ret

0000000080002dc0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002dc0:	7179                	addi	sp,sp,-48
    80002dc2:	f406                	sd	ra,40(sp)
    80002dc4:	f022                	sd	s0,32(sp)
    80002dc6:	ec26                	sd	s1,24(sp)
    80002dc8:	e84a                	sd	s2,16(sp)
    80002dca:	e44e                	sd	s3,8(sp)
    80002dcc:	e052                	sd	s4,0(sp)
    80002dce:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002dd0:	00005597          	auipc	a1,0x5
    80002dd4:	4e858593          	addi	a1,a1,1256 # 800082b8 <userret+0x228>
    80002dd8:	00018517          	auipc	a0,0x18
    80002ddc:	aa850513          	addi	a0,a0,-1368 # 8001a880 <bcache>
    80002de0:	ffffe097          	auipc	ra,0xffffe
    80002de4:	be0080e7          	jalr	-1056(ra) # 800009c0 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002de8:	00020797          	auipc	a5,0x20
    80002dec:	a9878793          	addi	a5,a5,-1384 # 80022880 <bcache+0x8000>
    80002df0:	00020717          	auipc	a4,0x20
    80002df4:	df070713          	addi	a4,a4,-528 # 80022be0 <bcache+0x8360>
    80002df8:	3ae7b823          	sd	a4,944(a5)
  bcache.head.next = &bcache.head;
    80002dfc:	3ae7bc23          	sd	a4,952(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e00:	00018497          	auipc	s1,0x18
    80002e04:	aa048493          	addi	s1,s1,-1376 # 8001a8a0 <bcache+0x20>
    b->next = bcache.head.next;
    80002e08:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002e0a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002e0c:	00006a17          	auipc	s4,0x6
    80002e10:	814a0a13          	addi	s4,s4,-2028 # 80008620 <userret+0x590>
    b->next = bcache.head.next;
    80002e14:	3b893783          	ld	a5,952(s2)
    80002e18:	ecbc                	sd	a5,88(s1)
    b->prev = &bcache.head;
    80002e1a:	0534b823          	sd	s3,80(s1)
    initsleeplock(&b->lock, "buffer");
    80002e1e:	85d2                	mv	a1,s4
    80002e20:	01048513          	addi	a0,s1,16
    80002e24:	00001097          	auipc	ra,0x1
    80002e28:	5a4080e7          	jalr	1444(ra) # 800043c8 <initsleeplock>
    bcache.head.next->prev = b;
    80002e2c:	3b893783          	ld	a5,952(s2)
    80002e30:	eba4                	sd	s1,80(a5)
    bcache.head.next = b;
    80002e32:	3a993c23          	sd	s1,952(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e36:	46048493          	addi	s1,s1,1120
    80002e3a:	fd349de3          	bne	s1,s3,80002e14 <binit+0x54>
  }
}
    80002e3e:	70a2                	ld	ra,40(sp)
    80002e40:	7402                	ld	s0,32(sp)
    80002e42:	64e2                	ld	s1,24(sp)
    80002e44:	6942                	ld	s2,16(sp)
    80002e46:	69a2                	ld	s3,8(sp)
    80002e48:	6a02                	ld	s4,0(sp)
    80002e4a:	6145                	addi	sp,sp,48
    80002e4c:	8082                	ret

0000000080002e4e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e4e:	7179                	addi	sp,sp,-48
    80002e50:	f406                	sd	ra,40(sp)
    80002e52:	f022                	sd	s0,32(sp)
    80002e54:	ec26                	sd	s1,24(sp)
    80002e56:	e84a                	sd	s2,16(sp)
    80002e58:	e44e                	sd	s3,8(sp)
    80002e5a:	1800                	addi	s0,sp,48
    80002e5c:	892a                	mv	s2,a0
    80002e5e:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002e60:	00018517          	auipc	a0,0x18
    80002e64:	a2050513          	addi	a0,a0,-1504 # 8001a880 <bcache>
    80002e68:	ffffe097          	auipc	ra,0xffffe
    80002e6c:	ca6080e7          	jalr	-858(ra) # 80000b0e <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e70:	00020497          	auipc	s1,0x20
    80002e74:	dc84b483          	ld	s1,-568(s1) # 80022c38 <bcache+0x83b8>
    80002e78:	00020797          	auipc	a5,0x20
    80002e7c:	d6878793          	addi	a5,a5,-664 # 80022be0 <bcache+0x8360>
    80002e80:	02f48f63          	beq	s1,a5,80002ebe <bread+0x70>
    80002e84:	873e                	mv	a4,a5
    80002e86:	a021                	j	80002e8e <bread+0x40>
    80002e88:	6ca4                	ld	s1,88(s1)
    80002e8a:	02e48a63          	beq	s1,a4,80002ebe <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002e8e:	449c                	lw	a5,8(s1)
    80002e90:	ff279ce3          	bne	a5,s2,80002e88 <bread+0x3a>
    80002e94:	44dc                	lw	a5,12(s1)
    80002e96:	ff3799e3          	bne	a5,s3,80002e88 <bread+0x3a>
      b->refcnt++;
    80002e9a:	44bc                	lw	a5,72(s1)
    80002e9c:	2785                	addiw	a5,a5,1
    80002e9e:	c4bc                	sw	a5,72(s1)
      release(&bcache.lock);
    80002ea0:	00018517          	auipc	a0,0x18
    80002ea4:	9e050513          	addi	a0,a0,-1568 # 8001a880 <bcache>
    80002ea8:	ffffe097          	auipc	ra,0xffffe
    80002eac:	cd6080e7          	jalr	-810(ra) # 80000b7e <release>
      acquiresleep(&b->lock);
    80002eb0:	01048513          	addi	a0,s1,16
    80002eb4:	00001097          	auipc	ra,0x1
    80002eb8:	54e080e7          	jalr	1358(ra) # 80004402 <acquiresleep>
      return b;
    80002ebc:	a8b9                	j	80002f1a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ebe:	00020497          	auipc	s1,0x20
    80002ec2:	d724b483          	ld	s1,-654(s1) # 80022c30 <bcache+0x83b0>
    80002ec6:	00020797          	auipc	a5,0x20
    80002eca:	d1a78793          	addi	a5,a5,-742 # 80022be0 <bcache+0x8360>
    80002ece:	00f48863          	beq	s1,a5,80002ede <bread+0x90>
    80002ed2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002ed4:	44bc                	lw	a5,72(s1)
    80002ed6:	cf81                	beqz	a5,80002eee <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ed8:	68a4                	ld	s1,80(s1)
    80002eda:	fee49de3          	bne	s1,a4,80002ed4 <bread+0x86>
  panic("bget: no buffers");
    80002ede:	00005517          	auipc	a0,0x5
    80002ee2:	74a50513          	addi	a0,a0,1866 # 80008628 <userret+0x598>
    80002ee6:	ffffd097          	auipc	ra,0xffffd
    80002eea:	662080e7          	jalr	1634(ra) # 80000548 <panic>
      b->dev = dev;
    80002eee:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002ef2:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002ef6:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002efa:	4785                	li	a5,1
    80002efc:	c4bc                	sw	a5,72(s1)
      release(&bcache.lock);
    80002efe:	00018517          	auipc	a0,0x18
    80002f02:	98250513          	addi	a0,a0,-1662 # 8001a880 <bcache>
    80002f06:	ffffe097          	auipc	ra,0xffffe
    80002f0a:	c78080e7          	jalr	-904(ra) # 80000b7e <release>
      acquiresleep(&b->lock);
    80002f0e:	01048513          	addi	a0,s1,16
    80002f12:	00001097          	auipc	ra,0x1
    80002f16:	4f0080e7          	jalr	1264(ra) # 80004402 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f1a:	409c                	lw	a5,0(s1)
    80002f1c:	cb89                	beqz	a5,80002f2e <bread+0xe0>
    virtio_disk_rw(b->dev, b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f1e:	8526                	mv	a0,s1
    80002f20:	70a2                	ld	ra,40(sp)
    80002f22:	7402                	ld	s0,32(sp)
    80002f24:	64e2                	ld	s1,24(sp)
    80002f26:	6942                	ld	s2,16(sp)
    80002f28:	69a2                	ld	s3,8(sp)
    80002f2a:	6145                	addi	sp,sp,48
    80002f2c:	8082                	ret
    virtio_disk_rw(b->dev, b, 0);
    80002f2e:	4601                	li	a2,0
    80002f30:	85a6                	mv	a1,s1
    80002f32:	4488                	lw	a0,8(s1)
    80002f34:	00003097          	auipc	ra,0x3
    80002f38:	116080e7          	jalr	278(ra) # 8000604a <virtio_disk_rw>
    b->valid = 1;
    80002f3c:	4785                	li	a5,1
    80002f3e:	c09c                	sw	a5,0(s1)
  return b;
    80002f40:	bff9                	j	80002f1e <bread+0xd0>

0000000080002f42 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f42:	1101                	addi	sp,sp,-32
    80002f44:	ec06                	sd	ra,24(sp)
    80002f46:	e822                	sd	s0,16(sp)
    80002f48:	e426                	sd	s1,8(sp)
    80002f4a:	1000                	addi	s0,sp,32
    80002f4c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f4e:	0541                	addi	a0,a0,16
    80002f50:	00001097          	auipc	ra,0x1
    80002f54:	54c080e7          	jalr	1356(ra) # 8000449c <holdingsleep>
    80002f58:	cd09                	beqz	a0,80002f72 <bwrite+0x30>
    panic("bwrite");
  virtio_disk_rw(b->dev, b, 1);
    80002f5a:	4605                	li	a2,1
    80002f5c:	85a6                	mv	a1,s1
    80002f5e:	4488                	lw	a0,8(s1)
    80002f60:	00003097          	auipc	ra,0x3
    80002f64:	0ea080e7          	jalr	234(ra) # 8000604a <virtio_disk_rw>
}
    80002f68:	60e2                	ld	ra,24(sp)
    80002f6a:	6442                	ld	s0,16(sp)
    80002f6c:	64a2                	ld	s1,8(sp)
    80002f6e:	6105                	addi	sp,sp,32
    80002f70:	8082                	ret
    panic("bwrite");
    80002f72:	00005517          	auipc	a0,0x5
    80002f76:	6ce50513          	addi	a0,a0,1742 # 80008640 <userret+0x5b0>
    80002f7a:	ffffd097          	auipc	ra,0xffffd
    80002f7e:	5ce080e7          	jalr	1486(ra) # 80000548 <panic>

0000000080002f82 <brelse>:

// Release a locked buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
    80002f82:	1101                	addi	sp,sp,-32
    80002f84:	ec06                	sd	ra,24(sp)
    80002f86:	e822                	sd	s0,16(sp)
    80002f88:	e426                	sd	s1,8(sp)
    80002f8a:	e04a                	sd	s2,0(sp)
    80002f8c:	1000                	addi	s0,sp,32
    80002f8e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f90:	01050913          	addi	s2,a0,16
    80002f94:	854a                	mv	a0,s2
    80002f96:	00001097          	auipc	ra,0x1
    80002f9a:	506080e7          	jalr	1286(ra) # 8000449c <holdingsleep>
    80002f9e:	c92d                	beqz	a0,80003010 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002fa0:	854a                	mv	a0,s2
    80002fa2:	00001097          	auipc	ra,0x1
    80002fa6:	4b6080e7          	jalr	1206(ra) # 80004458 <releasesleep>

  acquire(&bcache.lock);
    80002faa:	00018517          	auipc	a0,0x18
    80002fae:	8d650513          	addi	a0,a0,-1834 # 8001a880 <bcache>
    80002fb2:	ffffe097          	auipc	ra,0xffffe
    80002fb6:	b5c080e7          	jalr	-1188(ra) # 80000b0e <acquire>
  b->refcnt--;
    80002fba:	44bc                	lw	a5,72(s1)
    80002fbc:	37fd                	addiw	a5,a5,-1
    80002fbe:	0007871b          	sext.w	a4,a5
    80002fc2:	c4bc                	sw	a5,72(s1)
  if (b->refcnt == 0) {
    80002fc4:	eb05                	bnez	a4,80002ff4 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002fc6:	6cbc                	ld	a5,88(s1)
    80002fc8:	68b8                	ld	a4,80(s1)
    80002fca:	ebb8                	sd	a4,80(a5)
    b->prev->next = b->next;
    80002fcc:	68bc                	ld	a5,80(s1)
    80002fce:	6cb8                	ld	a4,88(s1)
    80002fd0:	efb8                	sd	a4,88(a5)
    b->next = bcache.head.next;
    80002fd2:	00020797          	auipc	a5,0x20
    80002fd6:	8ae78793          	addi	a5,a5,-1874 # 80022880 <bcache+0x8000>
    80002fda:	3b87b703          	ld	a4,952(a5)
    80002fde:	ecb8                	sd	a4,88(s1)
    b->prev = &bcache.head;
    80002fe0:	00020717          	auipc	a4,0x20
    80002fe4:	c0070713          	addi	a4,a4,-1024 # 80022be0 <bcache+0x8360>
    80002fe8:	e8b8                	sd	a4,80(s1)
    bcache.head.next->prev = b;
    80002fea:	3b87b703          	ld	a4,952(a5)
    80002fee:	eb24                	sd	s1,80(a4)
    bcache.head.next = b;
    80002ff0:	3a97bc23          	sd	s1,952(a5)
  }
  
  release(&bcache.lock);
    80002ff4:	00018517          	auipc	a0,0x18
    80002ff8:	88c50513          	addi	a0,a0,-1908 # 8001a880 <bcache>
    80002ffc:	ffffe097          	auipc	ra,0xffffe
    80003000:	b82080e7          	jalr	-1150(ra) # 80000b7e <release>
}
    80003004:	60e2                	ld	ra,24(sp)
    80003006:	6442                	ld	s0,16(sp)
    80003008:	64a2                	ld	s1,8(sp)
    8000300a:	6902                	ld	s2,0(sp)
    8000300c:	6105                	addi	sp,sp,32
    8000300e:	8082                	ret
    panic("brelse");
    80003010:	00005517          	auipc	a0,0x5
    80003014:	63850513          	addi	a0,a0,1592 # 80008648 <userret+0x5b8>
    80003018:	ffffd097          	auipc	ra,0xffffd
    8000301c:	530080e7          	jalr	1328(ra) # 80000548 <panic>

0000000080003020 <bpin>:

void
bpin(struct buf *b) {
    80003020:	1101                	addi	sp,sp,-32
    80003022:	ec06                	sd	ra,24(sp)
    80003024:	e822                	sd	s0,16(sp)
    80003026:	e426                	sd	s1,8(sp)
    80003028:	1000                	addi	s0,sp,32
    8000302a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000302c:	00018517          	auipc	a0,0x18
    80003030:	85450513          	addi	a0,a0,-1964 # 8001a880 <bcache>
    80003034:	ffffe097          	auipc	ra,0xffffe
    80003038:	ada080e7          	jalr	-1318(ra) # 80000b0e <acquire>
  b->refcnt++;
    8000303c:	44bc                	lw	a5,72(s1)
    8000303e:	2785                	addiw	a5,a5,1
    80003040:	c4bc                	sw	a5,72(s1)
  release(&bcache.lock);
    80003042:	00018517          	auipc	a0,0x18
    80003046:	83e50513          	addi	a0,a0,-1986 # 8001a880 <bcache>
    8000304a:	ffffe097          	auipc	ra,0xffffe
    8000304e:	b34080e7          	jalr	-1228(ra) # 80000b7e <release>
}
    80003052:	60e2                	ld	ra,24(sp)
    80003054:	6442                	ld	s0,16(sp)
    80003056:	64a2                	ld	s1,8(sp)
    80003058:	6105                	addi	sp,sp,32
    8000305a:	8082                	ret

000000008000305c <bunpin>:

void
bunpin(struct buf *b) {
    8000305c:	1101                	addi	sp,sp,-32
    8000305e:	ec06                	sd	ra,24(sp)
    80003060:	e822                	sd	s0,16(sp)
    80003062:	e426                	sd	s1,8(sp)
    80003064:	1000                	addi	s0,sp,32
    80003066:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003068:	00018517          	auipc	a0,0x18
    8000306c:	81850513          	addi	a0,a0,-2024 # 8001a880 <bcache>
    80003070:	ffffe097          	auipc	ra,0xffffe
    80003074:	a9e080e7          	jalr	-1378(ra) # 80000b0e <acquire>
  b->refcnt--;
    80003078:	44bc                	lw	a5,72(s1)
    8000307a:	37fd                	addiw	a5,a5,-1
    8000307c:	c4bc                	sw	a5,72(s1)
  release(&bcache.lock);
    8000307e:	00018517          	auipc	a0,0x18
    80003082:	80250513          	addi	a0,a0,-2046 # 8001a880 <bcache>
    80003086:	ffffe097          	auipc	ra,0xffffe
    8000308a:	af8080e7          	jalr	-1288(ra) # 80000b7e <release>
}
    8000308e:	60e2                	ld	ra,24(sp)
    80003090:	6442                	ld	s0,16(sp)
    80003092:	64a2                	ld	s1,8(sp)
    80003094:	6105                	addi	sp,sp,32
    80003096:	8082                	ret

0000000080003098 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003098:	1101                	addi	sp,sp,-32
    8000309a:	ec06                	sd	ra,24(sp)
    8000309c:	e822                	sd	s0,16(sp)
    8000309e:	e426                	sd	s1,8(sp)
    800030a0:	e04a                	sd	s2,0(sp)
    800030a2:	1000                	addi	s0,sp,32
    800030a4:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800030a6:	00d5d59b          	srliw	a1,a1,0xd
    800030aa:	00020797          	auipc	a5,0x20
    800030ae:	fb27a783          	lw	a5,-78(a5) # 8002305c <sb+0x1c>
    800030b2:	9dbd                	addw	a1,a1,a5
    800030b4:	00000097          	auipc	ra,0x0
    800030b8:	d9a080e7          	jalr	-614(ra) # 80002e4e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800030bc:	0074f713          	andi	a4,s1,7
    800030c0:	4785                	li	a5,1
    800030c2:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800030c6:	14ce                	slli	s1,s1,0x33
    800030c8:	90d9                	srli	s1,s1,0x36
    800030ca:	00950733          	add	a4,a0,s1
    800030ce:	06074703          	lbu	a4,96(a4)
    800030d2:	00e7f6b3          	and	a3,a5,a4
    800030d6:	c69d                	beqz	a3,80003104 <bfree+0x6c>
    800030d8:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800030da:	94aa                	add	s1,s1,a0
    800030dc:	fff7c793          	not	a5,a5
    800030e0:	8ff9                	and	a5,a5,a4
    800030e2:	06f48023          	sb	a5,96(s1)
  log_write(bp);
    800030e6:	00001097          	auipc	ra,0x1
    800030ea:	1a2080e7          	jalr	418(ra) # 80004288 <log_write>
  brelse(bp);
    800030ee:	854a                	mv	a0,s2
    800030f0:	00000097          	auipc	ra,0x0
    800030f4:	e92080e7          	jalr	-366(ra) # 80002f82 <brelse>
}
    800030f8:	60e2                	ld	ra,24(sp)
    800030fa:	6442                	ld	s0,16(sp)
    800030fc:	64a2                	ld	s1,8(sp)
    800030fe:	6902                	ld	s2,0(sp)
    80003100:	6105                	addi	sp,sp,32
    80003102:	8082                	ret
    panic("freeing free block");
    80003104:	00005517          	auipc	a0,0x5
    80003108:	54c50513          	addi	a0,a0,1356 # 80008650 <userret+0x5c0>
    8000310c:	ffffd097          	auipc	ra,0xffffd
    80003110:	43c080e7          	jalr	1084(ra) # 80000548 <panic>

0000000080003114 <balloc>:
{
    80003114:	711d                	addi	sp,sp,-96
    80003116:	ec86                	sd	ra,88(sp)
    80003118:	e8a2                	sd	s0,80(sp)
    8000311a:	e4a6                	sd	s1,72(sp)
    8000311c:	e0ca                	sd	s2,64(sp)
    8000311e:	fc4e                	sd	s3,56(sp)
    80003120:	f852                	sd	s4,48(sp)
    80003122:	f456                	sd	s5,40(sp)
    80003124:	f05a                	sd	s6,32(sp)
    80003126:	ec5e                	sd	s7,24(sp)
    80003128:	e862                	sd	s8,16(sp)
    8000312a:	e466                	sd	s9,8(sp)
    8000312c:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000312e:	00020797          	auipc	a5,0x20
    80003132:	f167a783          	lw	a5,-234(a5) # 80023044 <sb+0x4>
    80003136:	cbd1                	beqz	a5,800031ca <balloc+0xb6>
    80003138:	8baa                	mv	s7,a0
    8000313a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000313c:	00020b17          	auipc	s6,0x20
    80003140:	f04b0b13          	addi	s6,s6,-252 # 80023040 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003144:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003146:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003148:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000314a:	6c89                	lui	s9,0x2
    8000314c:	a831                	j	80003168 <balloc+0x54>
    brelse(bp);
    8000314e:	854a                	mv	a0,s2
    80003150:	00000097          	auipc	ra,0x0
    80003154:	e32080e7          	jalr	-462(ra) # 80002f82 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003158:	015c87bb          	addw	a5,s9,s5
    8000315c:	00078a9b          	sext.w	s5,a5
    80003160:	004b2703          	lw	a4,4(s6)
    80003164:	06eaf363          	bgeu	s5,a4,800031ca <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003168:	41fad79b          	sraiw	a5,s5,0x1f
    8000316c:	0137d79b          	srliw	a5,a5,0x13
    80003170:	015787bb          	addw	a5,a5,s5
    80003174:	40d7d79b          	sraiw	a5,a5,0xd
    80003178:	01cb2583          	lw	a1,28(s6)
    8000317c:	9dbd                	addw	a1,a1,a5
    8000317e:	855e                	mv	a0,s7
    80003180:	00000097          	auipc	ra,0x0
    80003184:	cce080e7          	jalr	-818(ra) # 80002e4e <bread>
    80003188:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000318a:	004b2503          	lw	a0,4(s6)
    8000318e:	000a849b          	sext.w	s1,s5
    80003192:	8662                	mv	a2,s8
    80003194:	faa4fde3          	bgeu	s1,a0,8000314e <balloc+0x3a>
      m = 1 << (bi % 8);
    80003198:	41f6579b          	sraiw	a5,a2,0x1f
    8000319c:	01d7d69b          	srliw	a3,a5,0x1d
    800031a0:	00c6873b          	addw	a4,a3,a2
    800031a4:	00777793          	andi	a5,a4,7
    800031a8:	9f95                	subw	a5,a5,a3
    800031aa:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800031ae:	4037571b          	sraiw	a4,a4,0x3
    800031b2:	00e906b3          	add	a3,s2,a4
    800031b6:	0606c683          	lbu	a3,96(a3)
    800031ba:	00d7f5b3          	and	a1,a5,a3
    800031be:	cd91                	beqz	a1,800031da <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031c0:	2605                	addiw	a2,a2,1
    800031c2:	2485                	addiw	s1,s1,1
    800031c4:	fd4618e3          	bne	a2,s4,80003194 <balloc+0x80>
    800031c8:	b759                	j	8000314e <balloc+0x3a>
  panic("balloc: out of blocks");
    800031ca:	00005517          	auipc	a0,0x5
    800031ce:	49e50513          	addi	a0,a0,1182 # 80008668 <userret+0x5d8>
    800031d2:	ffffd097          	auipc	ra,0xffffd
    800031d6:	376080e7          	jalr	886(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800031da:	974a                	add	a4,a4,s2
    800031dc:	8fd5                	or	a5,a5,a3
    800031de:	06f70023          	sb	a5,96(a4)
        log_write(bp);
    800031e2:	854a                	mv	a0,s2
    800031e4:	00001097          	auipc	ra,0x1
    800031e8:	0a4080e7          	jalr	164(ra) # 80004288 <log_write>
        brelse(bp);
    800031ec:	854a                	mv	a0,s2
    800031ee:	00000097          	auipc	ra,0x0
    800031f2:	d94080e7          	jalr	-620(ra) # 80002f82 <brelse>
  bp = bread(dev, bno);
    800031f6:	85a6                	mv	a1,s1
    800031f8:	855e                	mv	a0,s7
    800031fa:	00000097          	auipc	ra,0x0
    800031fe:	c54080e7          	jalr	-940(ra) # 80002e4e <bread>
    80003202:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003204:	40000613          	li	a2,1024
    80003208:	4581                	li	a1,0
    8000320a:	06050513          	addi	a0,a0,96
    8000320e:	ffffe097          	auipc	ra,0xffffe
    80003212:	b6e080e7          	jalr	-1170(ra) # 80000d7c <memset>
  log_write(bp);
    80003216:	854a                	mv	a0,s2
    80003218:	00001097          	auipc	ra,0x1
    8000321c:	070080e7          	jalr	112(ra) # 80004288 <log_write>
  brelse(bp);
    80003220:	854a                	mv	a0,s2
    80003222:	00000097          	auipc	ra,0x0
    80003226:	d60080e7          	jalr	-672(ra) # 80002f82 <brelse>
}
    8000322a:	8526                	mv	a0,s1
    8000322c:	60e6                	ld	ra,88(sp)
    8000322e:	6446                	ld	s0,80(sp)
    80003230:	64a6                	ld	s1,72(sp)
    80003232:	6906                	ld	s2,64(sp)
    80003234:	79e2                	ld	s3,56(sp)
    80003236:	7a42                	ld	s4,48(sp)
    80003238:	7aa2                	ld	s5,40(sp)
    8000323a:	7b02                	ld	s6,32(sp)
    8000323c:	6be2                	ld	s7,24(sp)
    8000323e:	6c42                	ld	s8,16(sp)
    80003240:	6ca2                	ld	s9,8(sp)
    80003242:	6125                	addi	sp,sp,96
    80003244:	8082                	ret

0000000080003246 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003246:	7179                	addi	sp,sp,-48
    80003248:	f406                	sd	ra,40(sp)
    8000324a:	f022                	sd	s0,32(sp)
    8000324c:	ec26                	sd	s1,24(sp)
    8000324e:	e84a                	sd	s2,16(sp)
    80003250:	e44e                	sd	s3,8(sp)
    80003252:	e052                	sd	s4,0(sp)
    80003254:	1800                	addi	s0,sp,48
    80003256:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003258:	47ad                	li	a5,11
    8000325a:	04b7fe63          	bgeu	a5,a1,800032b6 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000325e:	ff45849b          	addiw	s1,a1,-12
    80003262:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003266:	0ff00793          	li	a5,255
    8000326a:	0ae7e463          	bltu	a5,a4,80003312 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000326e:	08852583          	lw	a1,136(a0)
    80003272:	c5b5                	beqz	a1,800032de <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003274:	00092503          	lw	a0,0(s2)
    80003278:	00000097          	auipc	ra,0x0
    8000327c:	bd6080e7          	jalr	-1066(ra) # 80002e4e <bread>
    80003280:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003282:	06050793          	addi	a5,a0,96
    if((addr = a[bn]) == 0){
    80003286:	02049713          	slli	a4,s1,0x20
    8000328a:	01e75593          	srli	a1,a4,0x1e
    8000328e:	00b784b3          	add	s1,a5,a1
    80003292:	0004a983          	lw	s3,0(s1)
    80003296:	04098e63          	beqz	s3,800032f2 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000329a:	8552                	mv	a0,s4
    8000329c:	00000097          	auipc	ra,0x0
    800032a0:	ce6080e7          	jalr	-794(ra) # 80002f82 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800032a4:	854e                	mv	a0,s3
    800032a6:	70a2                	ld	ra,40(sp)
    800032a8:	7402                	ld	s0,32(sp)
    800032aa:	64e2                	ld	s1,24(sp)
    800032ac:	6942                	ld	s2,16(sp)
    800032ae:	69a2                	ld	s3,8(sp)
    800032b0:	6a02                	ld	s4,0(sp)
    800032b2:	6145                	addi	sp,sp,48
    800032b4:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800032b6:	02059793          	slli	a5,a1,0x20
    800032ba:	01e7d593          	srli	a1,a5,0x1e
    800032be:	00b504b3          	add	s1,a0,a1
    800032c2:	0584a983          	lw	s3,88(s1)
    800032c6:	fc099fe3          	bnez	s3,800032a4 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800032ca:	4108                	lw	a0,0(a0)
    800032cc:	00000097          	auipc	ra,0x0
    800032d0:	e48080e7          	jalr	-440(ra) # 80003114 <balloc>
    800032d4:	0005099b          	sext.w	s3,a0
    800032d8:	0534ac23          	sw	s3,88(s1)
    800032dc:	b7e1                	j	800032a4 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800032de:	4108                	lw	a0,0(a0)
    800032e0:	00000097          	auipc	ra,0x0
    800032e4:	e34080e7          	jalr	-460(ra) # 80003114 <balloc>
    800032e8:	0005059b          	sext.w	a1,a0
    800032ec:	08b92423          	sw	a1,136(s2)
    800032f0:	b751                	j	80003274 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800032f2:	00092503          	lw	a0,0(s2)
    800032f6:	00000097          	auipc	ra,0x0
    800032fa:	e1e080e7          	jalr	-482(ra) # 80003114 <balloc>
    800032fe:	0005099b          	sext.w	s3,a0
    80003302:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003306:	8552                	mv	a0,s4
    80003308:	00001097          	auipc	ra,0x1
    8000330c:	f80080e7          	jalr	-128(ra) # 80004288 <log_write>
    80003310:	b769                	j	8000329a <bmap+0x54>
  panic("bmap: out of range");
    80003312:	00005517          	auipc	a0,0x5
    80003316:	36e50513          	addi	a0,a0,878 # 80008680 <userret+0x5f0>
    8000331a:	ffffd097          	auipc	ra,0xffffd
    8000331e:	22e080e7          	jalr	558(ra) # 80000548 <panic>

0000000080003322 <iget>:
{
    80003322:	7179                	addi	sp,sp,-48
    80003324:	f406                	sd	ra,40(sp)
    80003326:	f022                	sd	s0,32(sp)
    80003328:	ec26                	sd	s1,24(sp)
    8000332a:	e84a                	sd	s2,16(sp)
    8000332c:	e44e                	sd	s3,8(sp)
    8000332e:	e052                	sd	s4,0(sp)
    80003330:	1800                	addi	s0,sp,48
    80003332:	89aa                	mv	s3,a0
    80003334:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003336:	00020517          	auipc	a0,0x20
    8000333a:	d2a50513          	addi	a0,a0,-726 # 80023060 <icache>
    8000333e:	ffffd097          	auipc	ra,0xffffd
    80003342:	7d0080e7          	jalr	2000(ra) # 80000b0e <acquire>
  empty = 0;
    80003346:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003348:	00020497          	auipc	s1,0x20
    8000334c:	d3848493          	addi	s1,s1,-712 # 80023080 <icache+0x20>
    80003350:	00022697          	auipc	a3,0x22
    80003354:	95068693          	addi	a3,a3,-1712 # 80024ca0 <log>
    80003358:	a039                	j	80003366 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000335a:	02090b63          	beqz	s2,80003390 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000335e:	09048493          	addi	s1,s1,144
    80003362:	02d48a63          	beq	s1,a3,80003396 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003366:	449c                	lw	a5,8(s1)
    80003368:	fef059e3          	blez	a5,8000335a <iget+0x38>
    8000336c:	4098                	lw	a4,0(s1)
    8000336e:	ff3716e3          	bne	a4,s3,8000335a <iget+0x38>
    80003372:	40d8                	lw	a4,4(s1)
    80003374:	ff4713e3          	bne	a4,s4,8000335a <iget+0x38>
      ip->ref++;
    80003378:	2785                	addiw	a5,a5,1
    8000337a:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    8000337c:	00020517          	auipc	a0,0x20
    80003380:	ce450513          	addi	a0,a0,-796 # 80023060 <icache>
    80003384:	ffffd097          	auipc	ra,0xffffd
    80003388:	7fa080e7          	jalr	2042(ra) # 80000b7e <release>
      return ip;
    8000338c:	8926                	mv	s2,s1
    8000338e:	a03d                	j	800033bc <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003390:	f7f9                	bnez	a5,8000335e <iget+0x3c>
    80003392:	8926                	mv	s2,s1
    80003394:	b7e9                	j	8000335e <iget+0x3c>
  if(empty == 0)
    80003396:	02090c63          	beqz	s2,800033ce <iget+0xac>
  ip->dev = dev;
    8000339a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000339e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800033a2:	4785                	li	a5,1
    800033a4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800033a8:	04092423          	sw	zero,72(s2)
  release(&icache.lock);
    800033ac:	00020517          	auipc	a0,0x20
    800033b0:	cb450513          	addi	a0,a0,-844 # 80023060 <icache>
    800033b4:	ffffd097          	auipc	ra,0xffffd
    800033b8:	7ca080e7          	jalr	1994(ra) # 80000b7e <release>
}
    800033bc:	854a                	mv	a0,s2
    800033be:	70a2                	ld	ra,40(sp)
    800033c0:	7402                	ld	s0,32(sp)
    800033c2:	64e2                	ld	s1,24(sp)
    800033c4:	6942                	ld	s2,16(sp)
    800033c6:	69a2                	ld	s3,8(sp)
    800033c8:	6a02                	ld	s4,0(sp)
    800033ca:	6145                	addi	sp,sp,48
    800033cc:	8082                	ret
    panic("iget: no inodes");
    800033ce:	00005517          	auipc	a0,0x5
    800033d2:	2ca50513          	addi	a0,a0,714 # 80008698 <userret+0x608>
    800033d6:	ffffd097          	auipc	ra,0xffffd
    800033da:	172080e7          	jalr	370(ra) # 80000548 <panic>

00000000800033de <fsinit>:
fsinit(int dev) {
    800033de:	7179                	addi	sp,sp,-48
    800033e0:	f406                	sd	ra,40(sp)
    800033e2:	f022                	sd	s0,32(sp)
    800033e4:	ec26                	sd	s1,24(sp)
    800033e6:	e84a                	sd	s2,16(sp)
    800033e8:	e44e                	sd	s3,8(sp)
    800033ea:	1800                	addi	s0,sp,48
    800033ec:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800033ee:	4585                	li	a1,1
    800033f0:	00000097          	auipc	ra,0x0
    800033f4:	a5e080e7          	jalr	-1442(ra) # 80002e4e <bread>
    800033f8:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800033fa:	00020997          	auipc	s3,0x20
    800033fe:	c4698993          	addi	s3,s3,-954 # 80023040 <sb>
    80003402:	02000613          	li	a2,32
    80003406:	06050593          	addi	a1,a0,96
    8000340a:	854e                	mv	a0,s3
    8000340c:	ffffe097          	auipc	ra,0xffffe
    80003410:	9cc080e7          	jalr	-1588(ra) # 80000dd8 <memmove>
  brelse(bp);
    80003414:	8526                	mv	a0,s1
    80003416:	00000097          	auipc	ra,0x0
    8000341a:	b6c080e7          	jalr	-1172(ra) # 80002f82 <brelse>
  if(sb.magic != FSMAGIC)
    8000341e:	0009a703          	lw	a4,0(s3)
    80003422:	102037b7          	lui	a5,0x10203
    80003426:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000342a:	02f71263          	bne	a4,a5,8000344e <fsinit+0x70>
  initlog(dev, &sb);
    8000342e:	00020597          	auipc	a1,0x20
    80003432:	c1258593          	addi	a1,a1,-1006 # 80023040 <sb>
    80003436:	854a                	mv	a0,s2
    80003438:	00001097          	auipc	ra,0x1
    8000343c:	b38080e7          	jalr	-1224(ra) # 80003f70 <initlog>
}
    80003440:	70a2                	ld	ra,40(sp)
    80003442:	7402                	ld	s0,32(sp)
    80003444:	64e2                	ld	s1,24(sp)
    80003446:	6942                	ld	s2,16(sp)
    80003448:	69a2                	ld	s3,8(sp)
    8000344a:	6145                	addi	sp,sp,48
    8000344c:	8082                	ret
    panic("invalid file system");
    8000344e:	00005517          	auipc	a0,0x5
    80003452:	25a50513          	addi	a0,a0,602 # 800086a8 <userret+0x618>
    80003456:	ffffd097          	auipc	ra,0xffffd
    8000345a:	0f2080e7          	jalr	242(ra) # 80000548 <panic>

000000008000345e <iinit>:
{
    8000345e:	7179                	addi	sp,sp,-48
    80003460:	f406                	sd	ra,40(sp)
    80003462:	f022                	sd	s0,32(sp)
    80003464:	ec26                	sd	s1,24(sp)
    80003466:	e84a                	sd	s2,16(sp)
    80003468:	e44e                	sd	s3,8(sp)
    8000346a:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    8000346c:	00005597          	auipc	a1,0x5
    80003470:	25458593          	addi	a1,a1,596 # 800086c0 <userret+0x630>
    80003474:	00020517          	auipc	a0,0x20
    80003478:	bec50513          	addi	a0,a0,-1044 # 80023060 <icache>
    8000347c:	ffffd097          	auipc	ra,0xffffd
    80003480:	544080e7          	jalr	1348(ra) # 800009c0 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003484:	00020497          	auipc	s1,0x20
    80003488:	c0c48493          	addi	s1,s1,-1012 # 80023090 <icache+0x30>
    8000348c:	00022997          	auipc	s3,0x22
    80003490:	82498993          	addi	s3,s3,-2012 # 80024cb0 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003494:	00005917          	auipc	s2,0x5
    80003498:	23490913          	addi	s2,s2,564 # 800086c8 <userret+0x638>
    8000349c:	85ca                	mv	a1,s2
    8000349e:	8526                	mv	a0,s1
    800034a0:	00001097          	auipc	ra,0x1
    800034a4:	f28080e7          	jalr	-216(ra) # 800043c8 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800034a8:	09048493          	addi	s1,s1,144
    800034ac:	ff3498e3          	bne	s1,s3,8000349c <iinit+0x3e>
}
    800034b0:	70a2                	ld	ra,40(sp)
    800034b2:	7402                	ld	s0,32(sp)
    800034b4:	64e2                	ld	s1,24(sp)
    800034b6:	6942                	ld	s2,16(sp)
    800034b8:	69a2                	ld	s3,8(sp)
    800034ba:	6145                	addi	sp,sp,48
    800034bc:	8082                	ret

00000000800034be <ialloc>:
{
    800034be:	715d                	addi	sp,sp,-80
    800034c0:	e486                	sd	ra,72(sp)
    800034c2:	e0a2                	sd	s0,64(sp)
    800034c4:	fc26                	sd	s1,56(sp)
    800034c6:	f84a                	sd	s2,48(sp)
    800034c8:	f44e                	sd	s3,40(sp)
    800034ca:	f052                	sd	s4,32(sp)
    800034cc:	ec56                	sd	s5,24(sp)
    800034ce:	e85a                	sd	s6,16(sp)
    800034d0:	e45e                	sd	s7,8(sp)
    800034d2:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800034d4:	00020717          	auipc	a4,0x20
    800034d8:	b7872703          	lw	a4,-1160(a4) # 8002304c <sb+0xc>
    800034dc:	4785                	li	a5,1
    800034de:	04e7fa63          	bgeu	a5,a4,80003532 <ialloc+0x74>
    800034e2:	8aaa                	mv	s5,a0
    800034e4:	8bae                	mv	s7,a1
    800034e6:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800034e8:	00020a17          	auipc	s4,0x20
    800034ec:	b58a0a13          	addi	s4,s4,-1192 # 80023040 <sb>
    800034f0:	00048b1b          	sext.w	s6,s1
    800034f4:	0044d793          	srli	a5,s1,0x4
    800034f8:	018a2583          	lw	a1,24(s4)
    800034fc:	9dbd                	addw	a1,a1,a5
    800034fe:	8556                	mv	a0,s5
    80003500:	00000097          	auipc	ra,0x0
    80003504:	94e080e7          	jalr	-1714(ra) # 80002e4e <bread>
    80003508:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000350a:	06050993          	addi	s3,a0,96
    8000350e:	00f4f793          	andi	a5,s1,15
    80003512:	079a                	slli	a5,a5,0x6
    80003514:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003516:	00099783          	lh	a5,0(s3)
    8000351a:	c785                	beqz	a5,80003542 <ialloc+0x84>
    brelse(bp);
    8000351c:	00000097          	auipc	ra,0x0
    80003520:	a66080e7          	jalr	-1434(ra) # 80002f82 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003524:	0485                	addi	s1,s1,1
    80003526:	00ca2703          	lw	a4,12(s4)
    8000352a:	0004879b          	sext.w	a5,s1
    8000352e:	fce7e1e3          	bltu	a5,a4,800034f0 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003532:	00005517          	auipc	a0,0x5
    80003536:	19e50513          	addi	a0,a0,414 # 800086d0 <userret+0x640>
    8000353a:	ffffd097          	auipc	ra,0xffffd
    8000353e:	00e080e7          	jalr	14(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    80003542:	04000613          	li	a2,64
    80003546:	4581                	li	a1,0
    80003548:	854e                	mv	a0,s3
    8000354a:	ffffe097          	auipc	ra,0xffffe
    8000354e:	832080e7          	jalr	-1998(ra) # 80000d7c <memset>
      dip->type = type;
    80003552:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003556:	854a                	mv	a0,s2
    80003558:	00001097          	auipc	ra,0x1
    8000355c:	d30080e7          	jalr	-720(ra) # 80004288 <log_write>
      brelse(bp);
    80003560:	854a                	mv	a0,s2
    80003562:	00000097          	auipc	ra,0x0
    80003566:	a20080e7          	jalr	-1504(ra) # 80002f82 <brelse>
      return iget(dev, inum);
    8000356a:	85da                	mv	a1,s6
    8000356c:	8556                	mv	a0,s5
    8000356e:	00000097          	auipc	ra,0x0
    80003572:	db4080e7          	jalr	-588(ra) # 80003322 <iget>
}
    80003576:	60a6                	ld	ra,72(sp)
    80003578:	6406                	ld	s0,64(sp)
    8000357a:	74e2                	ld	s1,56(sp)
    8000357c:	7942                	ld	s2,48(sp)
    8000357e:	79a2                	ld	s3,40(sp)
    80003580:	7a02                	ld	s4,32(sp)
    80003582:	6ae2                	ld	s5,24(sp)
    80003584:	6b42                	ld	s6,16(sp)
    80003586:	6ba2                	ld	s7,8(sp)
    80003588:	6161                	addi	sp,sp,80
    8000358a:	8082                	ret

000000008000358c <iupdate>:
{
    8000358c:	1101                	addi	sp,sp,-32
    8000358e:	ec06                	sd	ra,24(sp)
    80003590:	e822                	sd	s0,16(sp)
    80003592:	e426                	sd	s1,8(sp)
    80003594:	e04a                	sd	s2,0(sp)
    80003596:	1000                	addi	s0,sp,32
    80003598:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000359a:	415c                	lw	a5,4(a0)
    8000359c:	0047d79b          	srliw	a5,a5,0x4
    800035a0:	00020597          	auipc	a1,0x20
    800035a4:	ab85a583          	lw	a1,-1352(a1) # 80023058 <sb+0x18>
    800035a8:	9dbd                	addw	a1,a1,a5
    800035aa:	4108                	lw	a0,0(a0)
    800035ac:	00000097          	auipc	ra,0x0
    800035b0:	8a2080e7          	jalr	-1886(ra) # 80002e4e <bread>
    800035b4:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800035b6:	06050793          	addi	a5,a0,96
    800035ba:	40c8                	lw	a0,4(s1)
    800035bc:	893d                	andi	a0,a0,15
    800035be:	051a                	slli	a0,a0,0x6
    800035c0:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800035c2:	04c49703          	lh	a4,76(s1)
    800035c6:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800035ca:	04e49703          	lh	a4,78(s1)
    800035ce:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800035d2:	05049703          	lh	a4,80(s1)
    800035d6:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800035da:	05249703          	lh	a4,82(s1)
    800035de:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800035e2:	48f8                	lw	a4,84(s1)
    800035e4:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800035e6:	03400613          	li	a2,52
    800035ea:	05848593          	addi	a1,s1,88
    800035ee:	0531                	addi	a0,a0,12
    800035f0:	ffffd097          	auipc	ra,0xffffd
    800035f4:	7e8080e7          	jalr	2024(ra) # 80000dd8 <memmove>
  log_write(bp);
    800035f8:	854a                	mv	a0,s2
    800035fa:	00001097          	auipc	ra,0x1
    800035fe:	c8e080e7          	jalr	-882(ra) # 80004288 <log_write>
  brelse(bp);
    80003602:	854a                	mv	a0,s2
    80003604:	00000097          	auipc	ra,0x0
    80003608:	97e080e7          	jalr	-1666(ra) # 80002f82 <brelse>
}
    8000360c:	60e2                	ld	ra,24(sp)
    8000360e:	6442                	ld	s0,16(sp)
    80003610:	64a2                	ld	s1,8(sp)
    80003612:	6902                	ld	s2,0(sp)
    80003614:	6105                	addi	sp,sp,32
    80003616:	8082                	ret

0000000080003618 <idup>:
{
    80003618:	1101                	addi	sp,sp,-32
    8000361a:	ec06                	sd	ra,24(sp)
    8000361c:	e822                	sd	s0,16(sp)
    8000361e:	e426                	sd	s1,8(sp)
    80003620:	1000                	addi	s0,sp,32
    80003622:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003624:	00020517          	auipc	a0,0x20
    80003628:	a3c50513          	addi	a0,a0,-1476 # 80023060 <icache>
    8000362c:	ffffd097          	auipc	ra,0xffffd
    80003630:	4e2080e7          	jalr	1250(ra) # 80000b0e <acquire>
  ip->ref++;
    80003634:	449c                	lw	a5,8(s1)
    80003636:	2785                	addiw	a5,a5,1
    80003638:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000363a:	00020517          	auipc	a0,0x20
    8000363e:	a2650513          	addi	a0,a0,-1498 # 80023060 <icache>
    80003642:	ffffd097          	auipc	ra,0xffffd
    80003646:	53c080e7          	jalr	1340(ra) # 80000b7e <release>
}
    8000364a:	8526                	mv	a0,s1
    8000364c:	60e2                	ld	ra,24(sp)
    8000364e:	6442                	ld	s0,16(sp)
    80003650:	64a2                	ld	s1,8(sp)
    80003652:	6105                	addi	sp,sp,32
    80003654:	8082                	ret

0000000080003656 <ilock>:
{
    80003656:	1101                	addi	sp,sp,-32
    80003658:	ec06                	sd	ra,24(sp)
    8000365a:	e822                	sd	s0,16(sp)
    8000365c:	e426                	sd	s1,8(sp)
    8000365e:	e04a                	sd	s2,0(sp)
    80003660:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003662:	c115                	beqz	a0,80003686 <ilock+0x30>
    80003664:	84aa                	mv	s1,a0
    80003666:	451c                	lw	a5,8(a0)
    80003668:	00f05f63          	blez	a5,80003686 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000366c:	0541                	addi	a0,a0,16
    8000366e:	00001097          	auipc	ra,0x1
    80003672:	d94080e7          	jalr	-620(ra) # 80004402 <acquiresleep>
  if(ip->valid == 0){
    80003676:	44bc                	lw	a5,72(s1)
    80003678:	cf99                	beqz	a5,80003696 <ilock+0x40>
}
    8000367a:	60e2                	ld	ra,24(sp)
    8000367c:	6442                	ld	s0,16(sp)
    8000367e:	64a2                	ld	s1,8(sp)
    80003680:	6902                	ld	s2,0(sp)
    80003682:	6105                	addi	sp,sp,32
    80003684:	8082                	ret
    panic("ilock");
    80003686:	00005517          	auipc	a0,0x5
    8000368a:	06250513          	addi	a0,a0,98 # 800086e8 <userret+0x658>
    8000368e:	ffffd097          	auipc	ra,0xffffd
    80003692:	eba080e7          	jalr	-326(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003696:	40dc                	lw	a5,4(s1)
    80003698:	0047d79b          	srliw	a5,a5,0x4
    8000369c:	00020597          	auipc	a1,0x20
    800036a0:	9bc5a583          	lw	a1,-1604(a1) # 80023058 <sb+0x18>
    800036a4:	9dbd                	addw	a1,a1,a5
    800036a6:	4088                	lw	a0,0(s1)
    800036a8:	fffff097          	auipc	ra,0xfffff
    800036ac:	7a6080e7          	jalr	1958(ra) # 80002e4e <bread>
    800036b0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036b2:	06050593          	addi	a1,a0,96
    800036b6:	40dc                	lw	a5,4(s1)
    800036b8:	8bbd                	andi	a5,a5,15
    800036ba:	079a                	slli	a5,a5,0x6
    800036bc:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800036be:	00059783          	lh	a5,0(a1)
    800036c2:	04f49623          	sh	a5,76(s1)
    ip->major = dip->major;
    800036c6:	00259783          	lh	a5,2(a1)
    800036ca:	04f49723          	sh	a5,78(s1)
    ip->minor = dip->minor;
    800036ce:	00459783          	lh	a5,4(a1)
    800036d2:	04f49823          	sh	a5,80(s1)
    ip->nlink = dip->nlink;
    800036d6:	00659783          	lh	a5,6(a1)
    800036da:	04f49923          	sh	a5,82(s1)
    ip->size = dip->size;
    800036de:	459c                	lw	a5,8(a1)
    800036e0:	c8fc                	sw	a5,84(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800036e2:	03400613          	li	a2,52
    800036e6:	05b1                	addi	a1,a1,12
    800036e8:	05848513          	addi	a0,s1,88
    800036ec:	ffffd097          	auipc	ra,0xffffd
    800036f0:	6ec080e7          	jalr	1772(ra) # 80000dd8 <memmove>
    brelse(bp);
    800036f4:	854a                	mv	a0,s2
    800036f6:	00000097          	auipc	ra,0x0
    800036fa:	88c080e7          	jalr	-1908(ra) # 80002f82 <brelse>
    ip->valid = 1;
    800036fe:	4785                	li	a5,1
    80003700:	c4bc                	sw	a5,72(s1)
    if(ip->type == 0)
    80003702:	04c49783          	lh	a5,76(s1)
    80003706:	fbb5                	bnez	a5,8000367a <ilock+0x24>
      panic("ilock: no type");
    80003708:	00005517          	auipc	a0,0x5
    8000370c:	fe850513          	addi	a0,a0,-24 # 800086f0 <userret+0x660>
    80003710:	ffffd097          	auipc	ra,0xffffd
    80003714:	e38080e7          	jalr	-456(ra) # 80000548 <panic>

0000000080003718 <iunlock>:
{
    80003718:	1101                	addi	sp,sp,-32
    8000371a:	ec06                	sd	ra,24(sp)
    8000371c:	e822                	sd	s0,16(sp)
    8000371e:	e426                	sd	s1,8(sp)
    80003720:	e04a                	sd	s2,0(sp)
    80003722:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003724:	c905                	beqz	a0,80003754 <iunlock+0x3c>
    80003726:	84aa                	mv	s1,a0
    80003728:	01050913          	addi	s2,a0,16
    8000372c:	854a                	mv	a0,s2
    8000372e:	00001097          	auipc	ra,0x1
    80003732:	d6e080e7          	jalr	-658(ra) # 8000449c <holdingsleep>
    80003736:	cd19                	beqz	a0,80003754 <iunlock+0x3c>
    80003738:	449c                	lw	a5,8(s1)
    8000373a:	00f05d63          	blez	a5,80003754 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000373e:	854a                	mv	a0,s2
    80003740:	00001097          	auipc	ra,0x1
    80003744:	d18080e7          	jalr	-744(ra) # 80004458 <releasesleep>
}
    80003748:	60e2                	ld	ra,24(sp)
    8000374a:	6442                	ld	s0,16(sp)
    8000374c:	64a2                	ld	s1,8(sp)
    8000374e:	6902                	ld	s2,0(sp)
    80003750:	6105                	addi	sp,sp,32
    80003752:	8082                	ret
    panic("iunlock");
    80003754:	00005517          	auipc	a0,0x5
    80003758:	fac50513          	addi	a0,a0,-84 # 80008700 <userret+0x670>
    8000375c:	ffffd097          	auipc	ra,0xffffd
    80003760:	dec080e7          	jalr	-532(ra) # 80000548 <panic>

0000000080003764 <iput>:
{
    80003764:	7139                	addi	sp,sp,-64
    80003766:	fc06                	sd	ra,56(sp)
    80003768:	f822                	sd	s0,48(sp)
    8000376a:	f426                	sd	s1,40(sp)
    8000376c:	f04a                	sd	s2,32(sp)
    8000376e:	ec4e                	sd	s3,24(sp)
    80003770:	e852                	sd	s4,16(sp)
    80003772:	e456                	sd	s5,8(sp)
    80003774:	0080                	addi	s0,sp,64
    80003776:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003778:	00020517          	auipc	a0,0x20
    8000377c:	8e850513          	addi	a0,a0,-1816 # 80023060 <icache>
    80003780:	ffffd097          	auipc	ra,0xffffd
    80003784:	38e080e7          	jalr	910(ra) # 80000b0e <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003788:	4498                	lw	a4,8(s1)
    8000378a:	4785                	li	a5,1
    8000378c:	02f70663          	beq	a4,a5,800037b8 <iput+0x54>
  ip->ref--;
    80003790:	449c                	lw	a5,8(s1)
    80003792:	37fd                	addiw	a5,a5,-1
    80003794:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003796:	00020517          	auipc	a0,0x20
    8000379a:	8ca50513          	addi	a0,a0,-1846 # 80023060 <icache>
    8000379e:	ffffd097          	auipc	ra,0xffffd
    800037a2:	3e0080e7          	jalr	992(ra) # 80000b7e <release>
}
    800037a6:	70e2                	ld	ra,56(sp)
    800037a8:	7442                	ld	s0,48(sp)
    800037aa:	74a2                	ld	s1,40(sp)
    800037ac:	7902                	ld	s2,32(sp)
    800037ae:	69e2                	ld	s3,24(sp)
    800037b0:	6a42                	ld	s4,16(sp)
    800037b2:	6aa2                	ld	s5,8(sp)
    800037b4:	6121                	addi	sp,sp,64
    800037b6:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800037b8:	44bc                	lw	a5,72(s1)
    800037ba:	dbf9                	beqz	a5,80003790 <iput+0x2c>
    800037bc:	05249783          	lh	a5,82(s1)
    800037c0:	fbe1                	bnez	a5,80003790 <iput+0x2c>
    acquiresleep(&ip->lock);
    800037c2:	01048a13          	addi	s4,s1,16
    800037c6:	8552                	mv	a0,s4
    800037c8:	00001097          	auipc	ra,0x1
    800037cc:	c3a080e7          	jalr	-966(ra) # 80004402 <acquiresleep>
    release(&icache.lock);
    800037d0:	00020517          	auipc	a0,0x20
    800037d4:	89050513          	addi	a0,a0,-1904 # 80023060 <icache>
    800037d8:	ffffd097          	auipc	ra,0xffffd
    800037dc:	3a6080e7          	jalr	934(ra) # 80000b7e <release>
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800037e0:	05848913          	addi	s2,s1,88
    800037e4:	08848993          	addi	s3,s1,136
    800037e8:	a021                	j	800037f0 <iput+0x8c>
    800037ea:	0911                	addi	s2,s2,4
    800037ec:	01390d63          	beq	s2,s3,80003806 <iput+0xa2>
    if(ip->addrs[i]){
    800037f0:	00092583          	lw	a1,0(s2)
    800037f4:	d9fd                	beqz	a1,800037ea <iput+0x86>
      bfree(ip->dev, ip->addrs[i]);
    800037f6:	4088                	lw	a0,0(s1)
    800037f8:	00000097          	auipc	ra,0x0
    800037fc:	8a0080e7          	jalr	-1888(ra) # 80003098 <bfree>
      ip->addrs[i] = 0;
    80003800:	00092023          	sw	zero,0(s2)
    80003804:	b7dd                	j	800037ea <iput+0x86>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003806:	0884a583          	lw	a1,136(s1)
    8000380a:	ed9d                	bnez	a1,80003848 <iput+0xe4>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000380c:	0404aa23          	sw	zero,84(s1)
  iupdate(ip);
    80003810:	8526                	mv	a0,s1
    80003812:	00000097          	auipc	ra,0x0
    80003816:	d7a080e7          	jalr	-646(ra) # 8000358c <iupdate>
    ip->type = 0;
    8000381a:	04049623          	sh	zero,76(s1)
    iupdate(ip);
    8000381e:	8526                	mv	a0,s1
    80003820:	00000097          	auipc	ra,0x0
    80003824:	d6c080e7          	jalr	-660(ra) # 8000358c <iupdate>
    ip->valid = 0;
    80003828:	0404a423          	sw	zero,72(s1)
    releasesleep(&ip->lock);
    8000382c:	8552                	mv	a0,s4
    8000382e:	00001097          	auipc	ra,0x1
    80003832:	c2a080e7          	jalr	-982(ra) # 80004458 <releasesleep>
    acquire(&icache.lock);
    80003836:	00020517          	auipc	a0,0x20
    8000383a:	82a50513          	addi	a0,a0,-2006 # 80023060 <icache>
    8000383e:	ffffd097          	auipc	ra,0xffffd
    80003842:	2d0080e7          	jalr	720(ra) # 80000b0e <acquire>
    80003846:	b7a9                	j	80003790 <iput+0x2c>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003848:	4088                	lw	a0,0(s1)
    8000384a:	fffff097          	auipc	ra,0xfffff
    8000384e:	604080e7          	jalr	1540(ra) # 80002e4e <bread>
    80003852:	8aaa                	mv	s5,a0
    for(j = 0; j < NINDIRECT; j++){
    80003854:	06050913          	addi	s2,a0,96
    80003858:	46050993          	addi	s3,a0,1120
    8000385c:	a021                	j	80003864 <iput+0x100>
    8000385e:	0911                	addi	s2,s2,4
    80003860:	01390b63          	beq	s2,s3,80003876 <iput+0x112>
      if(a[j])
    80003864:	00092583          	lw	a1,0(s2)
    80003868:	d9fd                	beqz	a1,8000385e <iput+0xfa>
        bfree(ip->dev, a[j]);
    8000386a:	4088                	lw	a0,0(s1)
    8000386c:	00000097          	auipc	ra,0x0
    80003870:	82c080e7          	jalr	-2004(ra) # 80003098 <bfree>
    80003874:	b7ed                	j	8000385e <iput+0xfa>
    brelse(bp);
    80003876:	8556                	mv	a0,s5
    80003878:	fffff097          	auipc	ra,0xfffff
    8000387c:	70a080e7          	jalr	1802(ra) # 80002f82 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003880:	0884a583          	lw	a1,136(s1)
    80003884:	4088                	lw	a0,0(s1)
    80003886:	00000097          	auipc	ra,0x0
    8000388a:	812080e7          	jalr	-2030(ra) # 80003098 <bfree>
    ip->addrs[NDIRECT] = 0;
    8000388e:	0804a423          	sw	zero,136(s1)
    80003892:	bfad                	j	8000380c <iput+0xa8>

0000000080003894 <iunlockput>:
{
    80003894:	1101                	addi	sp,sp,-32
    80003896:	ec06                	sd	ra,24(sp)
    80003898:	e822                	sd	s0,16(sp)
    8000389a:	e426                	sd	s1,8(sp)
    8000389c:	1000                	addi	s0,sp,32
    8000389e:	84aa                	mv	s1,a0
  iunlock(ip);
    800038a0:	00000097          	auipc	ra,0x0
    800038a4:	e78080e7          	jalr	-392(ra) # 80003718 <iunlock>
  iput(ip);
    800038a8:	8526                	mv	a0,s1
    800038aa:	00000097          	auipc	ra,0x0
    800038ae:	eba080e7          	jalr	-326(ra) # 80003764 <iput>
}
    800038b2:	60e2                	ld	ra,24(sp)
    800038b4:	6442                	ld	s0,16(sp)
    800038b6:	64a2                	ld	s1,8(sp)
    800038b8:	6105                	addi	sp,sp,32
    800038ba:	8082                	ret

00000000800038bc <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800038bc:	1141                	addi	sp,sp,-16
    800038be:	e422                	sd	s0,8(sp)
    800038c0:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800038c2:	411c                	lw	a5,0(a0)
    800038c4:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800038c6:	415c                	lw	a5,4(a0)
    800038c8:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800038ca:	04c51783          	lh	a5,76(a0)
    800038ce:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800038d2:	05251783          	lh	a5,82(a0)
    800038d6:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800038da:	05456783          	lwu	a5,84(a0)
    800038de:	e99c                	sd	a5,16(a1)
}
    800038e0:	6422                	ld	s0,8(sp)
    800038e2:	0141                	addi	sp,sp,16
    800038e4:	8082                	ret

00000000800038e6 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800038e6:	497c                	lw	a5,84(a0)
    800038e8:	0ed7e563          	bltu	a5,a3,800039d2 <readi+0xec>
{
    800038ec:	7159                	addi	sp,sp,-112
    800038ee:	f486                	sd	ra,104(sp)
    800038f0:	f0a2                	sd	s0,96(sp)
    800038f2:	eca6                	sd	s1,88(sp)
    800038f4:	e8ca                	sd	s2,80(sp)
    800038f6:	e4ce                	sd	s3,72(sp)
    800038f8:	e0d2                	sd	s4,64(sp)
    800038fa:	fc56                	sd	s5,56(sp)
    800038fc:	f85a                	sd	s6,48(sp)
    800038fe:	f45e                	sd	s7,40(sp)
    80003900:	f062                	sd	s8,32(sp)
    80003902:	ec66                	sd	s9,24(sp)
    80003904:	e86a                	sd	s10,16(sp)
    80003906:	e46e                	sd	s11,8(sp)
    80003908:	1880                	addi	s0,sp,112
    8000390a:	8baa                	mv	s7,a0
    8000390c:	8c2e                	mv	s8,a1
    8000390e:	8ab2                	mv	s5,a2
    80003910:	8936                	mv	s2,a3
    80003912:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003914:	9f35                	addw	a4,a4,a3
    80003916:	0cd76063          	bltu	a4,a3,800039d6 <readi+0xf0>
    return -1;
  if(off + n > ip->size)
    8000391a:	00e7f463          	bgeu	a5,a4,80003922 <readi+0x3c>
    n = ip->size - off;
    8000391e:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003922:	080b0763          	beqz	s6,800039b0 <readi+0xca>
    80003926:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003928:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000392c:	5cfd                	li	s9,-1
    8000392e:	a82d                	j	80003968 <readi+0x82>
    80003930:	02099d93          	slli	s11,s3,0x20
    80003934:	020ddd93          	srli	s11,s11,0x20
    80003938:	06048793          	addi	a5,s1,96
    8000393c:	86ee                	mv	a3,s11
    8000393e:	963e                	add	a2,a2,a5
    80003940:	85d6                	mv	a1,s5
    80003942:	8562                	mv	a0,s8
    80003944:	fffff097          	auipc	ra,0xfffff
    80003948:	b52080e7          	jalr	-1198(ra) # 80002496 <either_copyout>
    8000394c:	05950d63          	beq	a0,s9,800039a6 <readi+0xc0>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003950:	8526                	mv	a0,s1
    80003952:	fffff097          	auipc	ra,0xfffff
    80003956:	630080e7          	jalr	1584(ra) # 80002f82 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000395a:	01498a3b          	addw	s4,s3,s4
    8000395e:	0129893b          	addw	s2,s3,s2
    80003962:	9aee                	add	s5,s5,s11
    80003964:	056a7663          	bgeu	s4,s6,800039b0 <readi+0xca>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003968:	000ba483          	lw	s1,0(s7)
    8000396c:	00a9559b          	srliw	a1,s2,0xa
    80003970:	855e                	mv	a0,s7
    80003972:	00000097          	auipc	ra,0x0
    80003976:	8d4080e7          	jalr	-1836(ra) # 80003246 <bmap>
    8000397a:	0005059b          	sext.w	a1,a0
    8000397e:	8526                	mv	a0,s1
    80003980:	fffff097          	auipc	ra,0xfffff
    80003984:	4ce080e7          	jalr	1230(ra) # 80002e4e <bread>
    80003988:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000398a:	3ff97613          	andi	a2,s2,1023
    8000398e:	40cd07bb          	subw	a5,s10,a2
    80003992:	414b073b          	subw	a4,s6,s4
    80003996:	89be                	mv	s3,a5
    80003998:	2781                	sext.w	a5,a5
    8000399a:	0007069b          	sext.w	a3,a4
    8000399e:	f8f6f9e3          	bgeu	a3,a5,80003930 <readi+0x4a>
    800039a2:	89ba                	mv	s3,a4
    800039a4:	b771                	j	80003930 <readi+0x4a>
      brelse(bp);
    800039a6:	8526                	mv	a0,s1
    800039a8:	fffff097          	auipc	ra,0xfffff
    800039ac:	5da080e7          	jalr	1498(ra) # 80002f82 <brelse>
  }
  return n;
    800039b0:	000b051b          	sext.w	a0,s6
}
    800039b4:	70a6                	ld	ra,104(sp)
    800039b6:	7406                	ld	s0,96(sp)
    800039b8:	64e6                	ld	s1,88(sp)
    800039ba:	6946                	ld	s2,80(sp)
    800039bc:	69a6                	ld	s3,72(sp)
    800039be:	6a06                	ld	s4,64(sp)
    800039c0:	7ae2                	ld	s5,56(sp)
    800039c2:	7b42                	ld	s6,48(sp)
    800039c4:	7ba2                	ld	s7,40(sp)
    800039c6:	7c02                	ld	s8,32(sp)
    800039c8:	6ce2                	ld	s9,24(sp)
    800039ca:	6d42                	ld	s10,16(sp)
    800039cc:	6da2                	ld	s11,8(sp)
    800039ce:	6165                	addi	sp,sp,112
    800039d0:	8082                	ret
    return -1;
    800039d2:	557d                	li	a0,-1
}
    800039d4:	8082                	ret
    return -1;
    800039d6:	557d                	li	a0,-1
    800039d8:	bff1                	j	800039b4 <readi+0xce>

00000000800039da <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039da:	497c                	lw	a5,84(a0)
    800039dc:	10d7e663          	bltu	a5,a3,80003ae8 <writei+0x10e>
{
    800039e0:	7159                	addi	sp,sp,-112
    800039e2:	f486                	sd	ra,104(sp)
    800039e4:	f0a2                	sd	s0,96(sp)
    800039e6:	eca6                	sd	s1,88(sp)
    800039e8:	e8ca                	sd	s2,80(sp)
    800039ea:	e4ce                	sd	s3,72(sp)
    800039ec:	e0d2                	sd	s4,64(sp)
    800039ee:	fc56                	sd	s5,56(sp)
    800039f0:	f85a                	sd	s6,48(sp)
    800039f2:	f45e                	sd	s7,40(sp)
    800039f4:	f062                	sd	s8,32(sp)
    800039f6:	ec66                	sd	s9,24(sp)
    800039f8:	e86a                	sd	s10,16(sp)
    800039fa:	e46e                	sd	s11,8(sp)
    800039fc:	1880                	addi	s0,sp,112
    800039fe:	8baa                	mv	s7,a0
    80003a00:	8c2e                	mv	s8,a1
    80003a02:	8ab2                	mv	s5,a2
    80003a04:	8936                	mv	s2,a3
    80003a06:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a08:	00e687bb          	addw	a5,a3,a4
    80003a0c:	0ed7e063          	bltu	a5,a3,80003aec <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a10:	00043737          	lui	a4,0x43
    80003a14:	0cf76e63          	bltu	a4,a5,80003af0 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a18:	0a0b0763          	beqz	s6,80003ac6 <writei+0xec>
    80003a1c:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a1e:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a22:	5cfd                	li	s9,-1
    80003a24:	a091                	j	80003a68 <writei+0x8e>
    80003a26:	02099d93          	slli	s11,s3,0x20
    80003a2a:	020ddd93          	srli	s11,s11,0x20
    80003a2e:	06048793          	addi	a5,s1,96
    80003a32:	86ee                	mv	a3,s11
    80003a34:	8656                	mv	a2,s5
    80003a36:	85e2                	mv	a1,s8
    80003a38:	953e                	add	a0,a0,a5
    80003a3a:	fffff097          	auipc	ra,0xfffff
    80003a3e:	ab2080e7          	jalr	-1358(ra) # 800024ec <either_copyin>
    80003a42:	07950263          	beq	a0,s9,80003aa6 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003a46:	8526                	mv	a0,s1
    80003a48:	00001097          	auipc	ra,0x1
    80003a4c:	840080e7          	jalr	-1984(ra) # 80004288 <log_write>
    brelse(bp);
    80003a50:	8526                	mv	a0,s1
    80003a52:	fffff097          	auipc	ra,0xfffff
    80003a56:	530080e7          	jalr	1328(ra) # 80002f82 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a5a:	01498a3b          	addw	s4,s3,s4
    80003a5e:	0129893b          	addw	s2,s3,s2
    80003a62:	9aee                	add	s5,s5,s11
    80003a64:	056a7663          	bgeu	s4,s6,80003ab0 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a68:	000ba483          	lw	s1,0(s7)
    80003a6c:	00a9559b          	srliw	a1,s2,0xa
    80003a70:	855e                	mv	a0,s7
    80003a72:	fffff097          	auipc	ra,0xfffff
    80003a76:	7d4080e7          	jalr	2004(ra) # 80003246 <bmap>
    80003a7a:	0005059b          	sext.w	a1,a0
    80003a7e:	8526                	mv	a0,s1
    80003a80:	fffff097          	auipc	ra,0xfffff
    80003a84:	3ce080e7          	jalr	974(ra) # 80002e4e <bread>
    80003a88:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a8a:	3ff97513          	andi	a0,s2,1023
    80003a8e:	40ad07bb          	subw	a5,s10,a0
    80003a92:	414b073b          	subw	a4,s6,s4
    80003a96:	89be                	mv	s3,a5
    80003a98:	2781                	sext.w	a5,a5
    80003a9a:	0007069b          	sext.w	a3,a4
    80003a9e:	f8f6f4e3          	bgeu	a3,a5,80003a26 <writei+0x4c>
    80003aa2:	89ba                	mv	s3,a4
    80003aa4:	b749                	j	80003a26 <writei+0x4c>
      brelse(bp);
    80003aa6:	8526                	mv	a0,s1
    80003aa8:	fffff097          	auipc	ra,0xfffff
    80003aac:	4da080e7          	jalr	1242(ra) # 80002f82 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003ab0:	054ba783          	lw	a5,84(s7)
    80003ab4:	0127f463          	bgeu	a5,s2,80003abc <writei+0xe2>
      ip->size = off;
    80003ab8:	052baa23          	sw	s2,84(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003abc:	855e                	mv	a0,s7
    80003abe:	00000097          	auipc	ra,0x0
    80003ac2:	ace080e7          	jalr	-1330(ra) # 8000358c <iupdate>
  }

  return n;
    80003ac6:	000b051b          	sext.w	a0,s6
}
    80003aca:	70a6                	ld	ra,104(sp)
    80003acc:	7406                	ld	s0,96(sp)
    80003ace:	64e6                	ld	s1,88(sp)
    80003ad0:	6946                	ld	s2,80(sp)
    80003ad2:	69a6                	ld	s3,72(sp)
    80003ad4:	6a06                	ld	s4,64(sp)
    80003ad6:	7ae2                	ld	s5,56(sp)
    80003ad8:	7b42                	ld	s6,48(sp)
    80003ada:	7ba2                	ld	s7,40(sp)
    80003adc:	7c02                	ld	s8,32(sp)
    80003ade:	6ce2                	ld	s9,24(sp)
    80003ae0:	6d42                	ld	s10,16(sp)
    80003ae2:	6da2                	ld	s11,8(sp)
    80003ae4:	6165                	addi	sp,sp,112
    80003ae6:	8082                	ret
    return -1;
    80003ae8:	557d                	li	a0,-1
}
    80003aea:	8082                	ret
    return -1;
    80003aec:	557d                	li	a0,-1
    80003aee:	bff1                	j	80003aca <writei+0xf0>
    return -1;
    80003af0:	557d                	li	a0,-1
    80003af2:	bfe1                	j	80003aca <writei+0xf0>

0000000080003af4 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003af4:	1141                	addi	sp,sp,-16
    80003af6:	e406                	sd	ra,8(sp)
    80003af8:	e022                	sd	s0,0(sp)
    80003afa:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003afc:	4639                	li	a2,14
    80003afe:	ffffd097          	auipc	ra,0xffffd
    80003b02:	356080e7          	jalr	854(ra) # 80000e54 <strncmp>
}
    80003b06:	60a2                	ld	ra,8(sp)
    80003b08:	6402                	ld	s0,0(sp)
    80003b0a:	0141                	addi	sp,sp,16
    80003b0c:	8082                	ret

0000000080003b0e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b0e:	7139                	addi	sp,sp,-64
    80003b10:	fc06                	sd	ra,56(sp)
    80003b12:	f822                	sd	s0,48(sp)
    80003b14:	f426                	sd	s1,40(sp)
    80003b16:	f04a                	sd	s2,32(sp)
    80003b18:	ec4e                	sd	s3,24(sp)
    80003b1a:	e852                	sd	s4,16(sp)
    80003b1c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b1e:	04c51703          	lh	a4,76(a0)
    80003b22:	4785                	li	a5,1
    80003b24:	00f71a63          	bne	a4,a5,80003b38 <dirlookup+0x2a>
    80003b28:	892a                	mv	s2,a0
    80003b2a:	89ae                	mv	s3,a1
    80003b2c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b2e:	497c                	lw	a5,84(a0)
    80003b30:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003b32:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b34:	e79d                	bnez	a5,80003b62 <dirlookup+0x54>
    80003b36:	a8a5                	j	80003bae <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003b38:	00005517          	auipc	a0,0x5
    80003b3c:	bd050513          	addi	a0,a0,-1072 # 80008708 <userret+0x678>
    80003b40:	ffffd097          	auipc	ra,0xffffd
    80003b44:	a08080e7          	jalr	-1528(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003b48:	00005517          	auipc	a0,0x5
    80003b4c:	bd850513          	addi	a0,a0,-1064 # 80008720 <userret+0x690>
    80003b50:	ffffd097          	auipc	ra,0xffffd
    80003b54:	9f8080e7          	jalr	-1544(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b58:	24c1                	addiw	s1,s1,16
    80003b5a:	05492783          	lw	a5,84(s2)
    80003b5e:	04f4f763          	bgeu	s1,a5,80003bac <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b62:	4741                	li	a4,16
    80003b64:	86a6                	mv	a3,s1
    80003b66:	fc040613          	addi	a2,s0,-64
    80003b6a:	4581                	li	a1,0
    80003b6c:	854a                	mv	a0,s2
    80003b6e:	00000097          	auipc	ra,0x0
    80003b72:	d78080e7          	jalr	-648(ra) # 800038e6 <readi>
    80003b76:	47c1                	li	a5,16
    80003b78:	fcf518e3          	bne	a0,a5,80003b48 <dirlookup+0x3a>
    if(de.inum == 0)
    80003b7c:	fc045783          	lhu	a5,-64(s0)
    80003b80:	dfe1                	beqz	a5,80003b58 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003b82:	fc240593          	addi	a1,s0,-62
    80003b86:	854e                	mv	a0,s3
    80003b88:	00000097          	auipc	ra,0x0
    80003b8c:	f6c080e7          	jalr	-148(ra) # 80003af4 <namecmp>
    80003b90:	f561                	bnez	a0,80003b58 <dirlookup+0x4a>
      if(poff)
    80003b92:	000a0463          	beqz	s4,80003b9a <dirlookup+0x8c>
        *poff = off;
    80003b96:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003b9a:	fc045583          	lhu	a1,-64(s0)
    80003b9e:	00092503          	lw	a0,0(s2)
    80003ba2:	fffff097          	auipc	ra,0xfffff
    80003ba6:	780080e7          	jalr	1920(ra) # 80003322 <iget>
    80003baa:	a011                	j	80003bae <dirlookup+0xa0>
  return 0;
    80003bac:	4501                	li	a0,0
}
    80003bae:	70e2                	ld	ra,56(sp)
    80003bb0:	7442                	ld	s0,48(sp)
    80003bb2:	74a2                	ld	s1,40(sp)
    80003bb4:	7902                	ld	s2,32(sp)
    80003bb6:	69e2                	ld	s3,24(sp)
    80003bb8:	6a42                	ld	s4,16(sp)
    80003bba:	6121                	addi	sp,sp,64
    80003bbc:	8082                	ret

0000000080003bbe <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003bbe:	711d                	addi	sp,sp,-96
    80003bc0:	ec86                	sd	ra,88(sp)
    80003bc2:	e8a2                	sd	s0,80(sp)
    80003bc4:	e4a6                	sd	s1,72(sp)
    80003bc6:	e0ca                	sd	s2,64(sp)
    80003bc8:	fc4e                	sd	s3,56(sp)
    80003bca:	f852                	sd	s4,48(sp)
    80003bcc:	f456                	sd	s5,40(sp)
    80003bce:	f05a                	sd	s6,32(sp)
    80003bd0:	ec5e                	sd	s7,24(sp)
    80003bd2:	e862                	sd	s8,16(sp)
    80003bd4:	e466                	sd	s9,8(sp)
    80003bd6:	1080                	addi	s0,sp,96
    80003bd8:	84aa                	mv	s1,a0
    80003bda:	8aae                	mv	s5,a1
    80003bdc:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003bde:	00054703          	lbu	a4,0(a0)
    80003be2:	02f00793          	li	a5,47
    80003be6:	02f70363          	beq	a4,a5,80003c0c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003bea:	ffffe097          	auipc	ra,0xffffe
    80003bee:	e7c080e7          	jalr	-388(ra) # 80001a66 <myproc>
    80003bf2:	15853503          	ld	a0,344(a0)
    80003bf6:	00000097          	auipc	ra,0x0
    80003bfa:	a22080e7          	jalr	-1502(ra) # 80003618 <idup>
    80003bfe:	89aa                	mv	s3,a0
  while(*path == '/')
    80003c00:	02f00913          	li	s2,47
  len = path - s;
    80003c04:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003c06:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c08:	4b85                	li	s7,1
    80003c0a:	a865                	j	80003cc2 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003c0c:	4585                	li	a1,1
    80003c0e:	4501                	li	a0,0
    80003c10:	fffff097          	auipc	ra,0xfffff
    80003c14:	712080e7          	jalr	1810(ra) # 80003322 <iget>
    80003c18:	89aa                	mv	s3,a0
    80003c1a:	b7dd                	j	80003c00 <namex+0x42>
      iunlockput(ip);
    80003c1c:	854e                	mv	a0,s3
    80003c1e:	00000097          	auipc	ra,0x0
    80003c22:	c76080e7          	jalr	-906(ra) # 80003894 <iunlockput>
      return 0;
    80003c26:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003c28:	854e                	mv	a0,s3
    80003c2a:	60e6                	ld	ra,88(sp)
    80003c2c:	6446                	ld	s0,80(sp)
    80003c2e:	64a6                	ld	s1,72(sp)
    80003c30:	6906                	ld	s2,64(sp)
    80003c32:	79e2                	ld	s3,56(sp)
    80003c34:	7a42                	ld	s4,48(sp)
    80003c36:	7aa2                	ld	s5,40(sp)
    80003c38:	7b02                	ld	s6,32(sp)
    80003c3a:	6be2                	ld	s7,24(sp)
    80003c3c:	6c42                	ld	s8,16(sp)
    80003c3e:	6ca2                	ld	s9,8(sp)
    80003c40:	6125                	addi	sp,sp,96
    80003c42:	8082                	ret
      iunlock(ip);
    80003c44:	854e                	mv	a0,s3
    80003c46:	00000097          	auipc	ra,0x0
    80003c4a:	ad2080e7          	jalr	-1326(ra) # 80003718 <iunlock>
      return ip;
    80003c4e:	bfe9                	j	80003c28 <namex+0x6a>
      iunlockput(ip);
    80003c50:	854e                	mv	a0,s3
    80003c52:	00000097          	auipc	ra,0x0
    80003c56:	c42080e7          	jalr	-958(ra) # 80003894 <iunlockput>
      return 0;
    80003c5a:	89e6                	mv	s3,s9
    80003c5c:	b7f1                	j	80003c28 <namex+0x6a>
  len = path - s;
    80003c5e:	40b48633          	sub	a2,s1,a1
    80003c62:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003c66:	099c5463          	bge	s8,s9,80003cee <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003c6a:	4639                	li	a2,14
    80003c6c:	8552                	mv	a0,s4
    80003c6e:	ffffd097          	auipc	ra,0xffffd
    80003c72:	16a080e7          	jalr	362(ra) # 80000dd8 <memmove>
  while(*path == '/')
    80003c76:	0004c783          	lbu	a5,0(s1)
    80003c7a:	01279763          	bne	a5,s2,80003c88 <namex+0xca>
    path++;
    80003c7e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003c80:	0004c783          	lbu	a5,0(s1)
    80003c84:	ff278de3          	beq	a5,s2,80003c7e <namex+0xc0>
    ilock(ip);
    80003c88:	854e                	mv	a0,s3
    80003c8a:	00000097          	auipc	ra,0x0
    80003c8e:	9cc080e7          	jalr	-1588(ra) # 80003656 <ilock>
    if(ip->type != T_DIR){
    80003c92:	04c99783          	lh	a5,76(s3)
    80003c96:	f97793e3          	bne	a5,s7,80003c1c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003c9a:	000a8563          	beqz	s5,80003ca4 <namex+0xe6>
    80003c9e:	0004c783          	lbu	a5,0(s1)
    80003ca2:	d3cd                	beqz	a5,80003c44 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003ca4:	865a                	mv	a2,s6
    80003ca6:	85d2                	mv	a1,s4
    80003ca8:	854e                	mv	a0,s3
    80003caa:	00000097          	auipc	ra,0x0
    80003cae:	e64080e7          	jalr	-412(ra) # 80003b0e <dirlookup>
    80003cb2:	8caa                	mv	s9,a0
    80003cb4:	dd51                	beqz	a0,80003c50 <namex+0x92>
    iunlockput(ip);
    80003cb6:	854e                	mv	a0,s3
    80003cb8:	00000097          	auipc	ra,0x0
    80003cbc:	bdc080e7          	jalr	-1060(ra) # 80003894 <iunlockput>
    ip = next;
    80003cc0:	89e6                	mv	s3,s9
  while(*path == '/')
    80003cc2:	0004c783          	lbu	a5,0(s1)
    80003cc6:	05279763          	bne	a5,s2,80003d14 <namex+0x156>
    path++;
    80003cca:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ccc:	0004c783          	lbu	a5,0(s1)
    80003cd0:	ff278de3          	beq	a5,s2,80003cca <namex+0x10c>
  if(*path == 0)
    80003cd4:	c79d                	beqz	a5,80003d02 <namex+0x144>
    path++;
    80003cd6:	85a6                	mv	a1,s1
  len = path - s;
    80003cd8:	8cda                	mv	s9,s6
    80003cda:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003cdc:	01278963          	beq	a5,s2,80003cee <namex+0x130>
    80003ce0:	dfbd                	beqz	a5,80003c5e <namex+0xa0>
    path++;
    80003ce2:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003ce4:	0004c783          	lbu	a5,0(s1)
    80003ce8:	ff279ce3          	bne	a5,s2,80003ce0 <namex+0x122>
    80003cec:	bf8d                	j	80003c5e <namex+0xa0>
    memmove(name, s, len);
    80003cee:	2601                	sext.w	a2,a2
    80003cf0:	8552                	mv	a0,s4
    80003cf2:	ffffd097          	auipc	ra,0xffffd
    80003cf6:	0e6080e7          	jalr	230(ra) # 80000dd8 <memmove>
    name[len] = 0;
    80003cfa:	9cd2                	add	s9,s9,s4
    80003cfc:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003d00:	bf9d                	j	80003c76 <namex+0xb8>
  if(nameiparent){
    80003d02:	f20a83e3          	beqz	s5,80003c28 <namex+0x6a>
    iput(ip);
    80003d06:	854e                	mv	a0,s3
    80003d08:	00000097          	auipc	ra,0x0
    80003d0c:	a5c080e7          	jalr	-1444(ra) # 80003764 <iput>
    return 0;
    80003d10:	4981                	li	s3,0
    80003d12:	bf19                	j	80003c28 <namex+0x6a>
  if(*path == 0)
    80003d14:	d7fd                	beqz	a5,80003d02 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003d16:	0004c783          	lbu	a5,0(s1)
    80003d1a:	85a6                	mv	a1,s1
    80003d1c:	b7d1                	j	80003ce0 <namex+0x122>

0000000080003d1e <dirlink>:
{
    80003d1e:	7139                	addi	sp,sp,-64
    80003d20:	fc06                	sd	ra,56(sp)
    80003d22:	f822                	sd	s0,48(sp)
    80003d24:	f426                	sd	s1,40(sp)
    80003d26:	f04a                	sd	s2,32(sp)
    80003d28:	ec4e                	sd	s3,24(sp)
    80003d2a:	e852                	sd	s4,16(sp)
    80003d2c:	0080                	addi	s0,sp,64
    80003d2e:	892a                	mv	s2,a0
    80003d30:	8a2e                	mv	s4,a1
    80003d32:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003d34:	4601                	li	a2,0
    80003d36:	00000097          	auipc	ra,0x0
    80003d3a:	dd8080e7          	jalr	-552(ra) # 80003b0e <dirlookup>
    80003d3e:	e93d                	bnez	a0,80003db4 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d40:	05492483          	lw	s1,84(s2)
    80003d44:	c49d                	beqz	s1,80003d72 <dirlink+0x54>
    80003d46:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d48:	4741                	li	a4,16
    80003d4a:	86a6                	mv	a3,s1
    80003d4c:	fc040613          	addi	a2,s0,-64
    80003d50:	4581                	li	a1,0
    80003d52:	854a                	mv	a0,s2
    80003d54:	00000097          	auipc	ra,0x0
    80003d58:	b92080e7          	jalr	-1134(ra) # 800038e6 <readi>
    80003d5c:	47c1                	li	a5,16
    80003d5e:	06f51163          	bne	a0,a5,80003dc0 <dirlink+0xa2>
    if(de.inum == 0)
    80003d62:	fc045783          	lhu	a5,-64(s0)
    80003d66:	c791                	beqz	a5,80003d72 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d68:	24c1                	addiw	s1,s1,16
    80003d6a:	05492783          	lw	a5,84(s2)
    80003d6e:	fcf4ede3          	bltu	s1,a5,80003d48 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003d72:	4639                	li	a2,14
    80003d74:	85d2                	mv	a1,s4
    80003d76:	fc240513          	addi	a0,s0,-62
    80003d7a:	ffffd097          	auipc	ra,0xffffd
    80003d7e:	116080e7          	jalr	278(ra) # 80000e90 <strncpy>
  de.inum = inum;
    80003d82:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d86:	4741                	li	a4,16
    80003d88:	86a6                	mv	a3,s1
    80003d8a:	fc040613          	addi	a2,s0,-64
    80003d8e:	4581                	li	a1,0
    80003d90:	854a                	mv	a0,s2
    80003d92:	00000097          	auipc	ra,0x0
    80003d96:	c48080e7          	jalr	-952(ra) # 800039da <writei>
    80003d9a:	872a                	mv	a4,a0
    80003d9c:	47c1                	li	a5,16
  return 0;
    80003d9e:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003da0:	02f71863          	bne	a4,a5,80003dd0 <dirlink+0xb2>
}
    80003da4:	70e2                	ld	ra,56(sp)
    80003da6:	7442                	ld	s0,48(sp)
    80003da8:	74a2                	ld	s1,40(sp)
    80003daa:	7902                	ld	s2,32(sp)
    80003dac:	69e2                	ld	s3,24(sp)
    80003dae:	6a42                	ld	s4,16(sp)
    80003db0:	6121                	addi	sp,sp,64
    80003db2:	8082                	ret
    iput(ip);
    80003db4:	00000097          	auipc	ra,0x0
    80003db8:	9b0080e7          	jalr	-1616(ra) # 80003764 <iput>
    return -1;
    80003dbc:	557d                	li	a0,-1
    80003dbe:	b7dd                	j	80003da4 <dirlink+0x86>
      panic("dirlink read");
    80003dc0:	00005517          	auipc	a0,0x5
    80003dc4:	97050513          	addi	a0,a0,-1680 # 80008730 <userret+0x6a0>
    80003dc8:	ffffc097          	auipc	ra,0xffffc
    80003dcc:	780080e7          	jalr	1920(ra) # 80000548 <panic>
    panic("dirlink");
    80003dd0:	00005517          	auipc	a0,0x5
    80003dd4:	a8050513          	addi	a0,a0,-1408 # 80008850 <userret+0x7c0>
    80003dd8:	ffffc097          	auipc	ra,0xffffc
    80003ddc:	770080e7          	jalr	1904(ra) # 80000548 <panic>

0000000080003de0 <namei>:

struct inode*
namei(char *path)
{
    80003de0:	1101                	addi	sp,sp,-32
    80003de2:	ec06                	sd	ra,24(sp)
    80003de4:	e822                	sd	s0,16(sp)
    80003de6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003de8:	fe040613          	addi	a2,s0,-32
    80003dec:	4581                	li	a1,0
    80003dee:	00000097          	auipc	ra,0x0
    80003df2:	dd0080e7          	jalr	-560(ra) # 80003bbe <namex>
}
    80003df6:	60e2                	ld	ra,24(sp)
    80003df8:	6442                	ld	s0,16(sp)
    80003dfa:	6105                	addi	sp,sp,32
    80003dfc:	8082                	ret

0000000080003dfe <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003dfe:	1141                	addi	sp,sp,-16
    80003e00:	e406                	sd	ra,8(sp)
    80003e02:	e022                	sd	s0,0(sp)
    80003e04:	0800                	addi	s0,sp,16
    80003e06:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003e08:	4585                	li	a1,1
    80003e0a:	00000097          	auipc	ra,0x0
    80003e0e:	db4080e7          	jalr	-588(ra) # 80003bbe <namex>
}
    80003e12:	60a2                	ld	ra,8(sp)
    80003e14:	6402                	ld	s0,0(sp)
    80003e16:	0141                	addi	sp,sp,16
    80003e18:	8082                	ret

0000000080003e1a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(int dev)
{
    80003e1a:	7179                	addi	sp,sp,-48
    80003e1c:	f406                	sd	ra,40(sp)
    80003e1e:	f022                	sd	s0,32(sp)
    80003e20:	ec26                	sd	s1,24(sp)
    80003e22:	e84a                	sd	s2,16(sp)
    80003e24:	e44e                	sd	s3,8(sp)
    80003e26:	1800                	addi	s0,sp,48
    80003e28:	84aa                	mv	s1,a0
  struct buf *buf = bread(dev, log[dev].start);
    80003e2a:	0b000993          	li	s3,176
    80003e2e:	033507b3          	mul	a5,a0,s3
    80003e32:	00021997          	auipc	s3,0x21
    80003e36:	e6e98993          	addi	s3,s3,-402 # 80024ca0 <log>
    80003e3a:	99be                	add	s3,s3,a5
    80003e3c:	0209a583          	lw	a1,32(s3)
    80003e40:	fffff097          	auipc	ra,0xfffff
    80003e44:	00e080e7          	jalr	14(ra) # 80002e4e <bread>
    80003e48:	892a                	mv	s2,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log[dev].lh.n;
    80003e4a:	0349a783          	lw	a5,52(s3)
    80003e4e:	d13c                	sw	a5,96(a0)
  for (i = 0; i < log[dev].lh.n; i++) {
    80003e50:	0349a783          	lw	a5,52(s3)
    80003e54:	02f05763          	blez	a5,80003e82 <write_head+0x68>
    80003e58:	0b000793          	li	a5,176
    80003e5c:	02f487b3          	mul	a5,s1,a5
    80003e60:	00021717          	auipc	a4,0x21
    80003e64:	e7870713          	addi	a4,a4,-392 # 80024cd8 <log+0x38>
    80003e68:	97ba                	add	a5,a5,a4
    80003e6a:	06450693          	addi	a3,a0,100
    80003e6e:	4701                	li	a4,0
    80003e70:	85ce                	mv	a1,s3
    hb->block[i] = log[dev].lh.block[i];
    80003e72:	4390                	lw	a2,0(a5)
    80003e74:	c290                	sw	a2,0(a3)
  for (i = 0; i < log[dev].lh.n; i++) {
    80003e76:	2705                	addiw	a4,a4,1
    80003e78:	0791                	addi	a5,a5,4
    80003e7a:	0691                	addi	a3,a3,4
    80003e7c:	59d0                	lw	a2,52(a1)
    80003e7e:	fec74ae3          	blt	a4,a2,80003e72 <write_head+0x58>
  }
  bwrite(buf);
    80003e82:	854a                	mv	a0,s2
    80003e84:	fffff097          	auipc	ra,0xfffff
    80003e88:	0be080e7          	jalr	190(ra) # 80002f42 <bwrite>
  brelse(buf);
    80003e8c:	854a                	mv	a0,s2
    80003e8e:	fffff097          	auipc	ra,0xfffff
    80003e92:	0f4080e7          	jalr	244(ra) # 80002f82 <brelse>
}
    80003e96:	70a2                	ld	ra,40(sp)
    80003e98:	7402                	ld	s0,32(sp)
    80003e9a:	64e2                	ld	s1,24(sp)
    80003e9c:	6942                	ld	s2,16(sp)
    80003e9e:	69a2                	ld	s3,8(sp)
    80003ea0:	6145                	addi	sp,sp,48
    80003ea2:	8082                	ret

0000000080003ea4 <install_trans>:
  for (tail = 0; tail < log[dev].lh.n; tail++) {
    80003ea4:	0b000793          	li	a5,176
    80003ea8:	02f50733          	mul	a4,a0,a5
    80003eac:	00021797          	auipc	a5,0x21
    80003eb0:	df478793          	addi	a5,a5,-524 # 80024ca0 <log>
    80003eb4:	97ba                	add	a5,a5,a4
    80003eb6:	5bdc                	lw	a5,52(a5)
    80003eb8:	0af05b63          	blez	a5,80003f6e <install_trans+0xca>
{
    80003ebc:	7139                	addi	sp,sp,-64
    80003ebe:	fc06                	sd	ra,56(sp)
    80003ec0:	f822                	sd	s0,48(sp)
    80003ec2:	f426                	sd	s1,40(sp)
    80003ec4:	f04a                	sd	s2,32(sp)
    80003ec6:	ec4e                	sd	s3,24(sp)
    80003ec8:	e852                	sd	s4,16(sp)
    80003eca:	e456                	sd	s5,8(sp)
    80003ecc:	e05a                	sd	s6,0(sp)
    80003ece:	0080                	addi	s0,sp,64
    80003ed0:	00021797          	auipc	a5,0x21
    80003ed4:	e0878793          	addi	a5,a5,-504 # 80024cd8 <log+0x38>
    80003ed8:	00f70a33          	add	s4,a4,a5
  for (tail = 0; tail < log[dev].lh.n; tail++) {
    80003edc:	4981                	li	s3,0
    struct buf *lbuf = bread(dev, log[dev].start+tail+1); // read log block
    80003ede:	00050b1b          	sext.w	s6,a0
    80003ee2:	00021a97          	auipc	s5,0x21
    80003ee6:	dbea8a93          	addi	s5,s5,-578 # 80024ca0 <log>
    80003eea:	9aba                	add	s5,s5,a4
    80003eec:	020aa583          	lw	a1,32(s5)
    80003ef0:	013585bb          	addw	a1,a1,s3
    80003ef4:	2585                	addiw	a1,a1,1
    80003ef6:	855a                	mv	a0,s6
    80003ef8:	fffff097          	auipc	ra,0xfffff
    80003efc:	f56080e7          	jalr	-170(ra) # 80002e4e <bread>
    80003f00:	892a                	mv	s2,a0
    struct buf *dbuf = bread(dev, log[dev].lh.block[tail]); // read dst
    80003f02:	000a2583          	lw	a1,0(s4)
    80003f06:	855a                	mv	a0,s6
    80003f08:	fffff097          	auipc	ra,0xfffff
    80003f0c:	f46080e7          	jalr	-186(ra) # 80002e4e <bread>
    80003f10:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f12:	40000613          	li	a2,1024
    80003f16:	06090593          	addi	a1,s2,96
    80003f1a:	06050513          	addi	a0,a0,96
    80003f1e:	ffffd097          	auipc	ra,0xffffd
    80003f22:	eba080e7          	jalr	-326(ra) # 80000dd8 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003f26:	8526                	mv	a0,s1
    80003f28:	fffff097          	auipc	ra,0xfffff
    80003f2c:	01a080e7          	jalr	26(ra) # 80002f42 <bwrite>
    bunpin(dbuf);
    80003f30:	8526                	mv	a0,s1
    80003f32:	fffff097          	auipc	ra,0xfffff
    80003f36:	12a080e7          	jalr	298(ra) # 8000305c <bunpin>
    brelse(lbuf);
    80003f3a:	854a                	mv	a0,s2
    80003f3c:	fffff097          	auipc	ra,0xfffff
    80003f40:	046080e7          	jalr	70(ra) # 80002f82 <brelse>
    brelse(dbuf);
    80003f44:	8526                	mv	a0,s1
    80003f46:	fffff097          	auipc	ra,0xfffff
    80003f4a:	03c080e7          	jalr	60(ra) # 80002f82 <brelse>
  for (tail = 0; tail < log[dev].lh.n; tail++) {
    80003f4e:	2985                	addiw	s3,s3,1
    80003f50:	0a11                	addi	s4,s4,4
    80003f52:	034aa783          	lw	a5,52(s5)
    80003f56:	f8f9cbe3          	blt	s3,a5,80003eec <install_trans+0x48>
}
    80003f5a:	70e2                	ld	ra,56(sp)
    80003f5c:	7442                	ld	s0,48(sp)
    80003f5e:	74a2                	ld	s1,40(sp)
    80003f60:	7902                	ld	s2,32(sp)
    80003f62:	69e2                	ld	s3,24(sp)
    80003f64:	6a42                	ld	s4,16(sp)
    80003f66:	6aa2                	ld	s5,8(sp)
    80003f68:	6b02                	ld	s6,0(sp)
    80003f6a:	6121                	addi	sp,sp,64
    80003f6c:	8082                	ret
    80003f6e:	8082                	ret

0000000080003f70 <initlog>:
{
    80003f70:	7179                	addi	sp,sp,-48
    80003f72:	f406                	sd	ra,40(sp)
    80003f74:	f022                	sd	s0,32(sp)
    80003f76:	ec26                	sd	s1,24(sp)
    80003f78:	e84a                	sd	s2,16(sp)
    80003f7a:	e44e                	sd	s3,8(sp)
    80003f7c:	e052                	sd	s4,0(sp)
    80003f7e:	1800                	addi	s0,sp,48
    80003f80:	892a                	mv	s2,a0
    80003f82:	8a2e                	mv	s4,a1
  initlock(&log[dev].lock, "log");
    80003f84:	0b000713          	li	a4,176
    80003f88:	02e504b3          	mul	s1,a0,a4
    80003f8c:	00021997          	auipc	s3,0x21
    80003f90:	d1498993          	addi	s3,s3,-748 # 80024ca0 <log>
    80003f94:	99a6                	add	s3,s3,s1
    80003f96:	00004597          	auipc	a1,0x4
    80003f9a:	7aa58593          	addi	a1,a1,1962 # 80008740 <userret+0x6b0>
    80003f9e:	854e                	mv	a0,s3
    80003fa0:	ffffd097          	auipc	ra,0xffffd
    80003fa4:	a20080e7          	jalr	-1504(ra) # 800009c0 <initlock>
  log[dev].start = sb->logstart;
    80003fa8:	014a2583          	lw	a1,20(s4)
    80003fac:	02b9a023          	sw	a1,32(s3)
  log[dev].size = sb->nlog;
    80003fb0:	010a2783          	lw	a5,16(s4)
    80003fb4:	02f9a223          	sw	a5,36(s3)
  log[dev].dev = dev;
    80003fb8:	0329a823          	sw	s2,48(s3)
  struct buf *buf = bread(dev, log[dev].start);
    80003fbc:	854a                	mv	a0,s2
    80003fbe:	fffff097          	auipc	ra,0xfffff
    80003fc2:	e90080e7          	jalr	-368(ra) # 80002e4e <bread>
  log[dev].lh.n = lh->n;
    80003fc6:	5134                	lw	a3,96(a0)
    80003fc8:	02d9aa23          	sw	a3,52(s3)
  for (i = 0; i < log[dev].lh.n; i++) {
    80003fcc:	02d05763          	blez	a3,80003ffa <initlog+0x8a>
    80003fd0:	06450793          	addi	a5,a0,100
    80003fd4:	00021717          	auipc	a4,0x21
    80003fd8:	d0470713          	addi	a4,a4,-764 # 80024cd8 <log+0x38>
    80003fdc:	9726                	add	a4,a4,s1
    80003fde:	36fd                	addiw	a3,a3,-1
    80003fe0:	02069613          	slli	a2,a3,0x20
    80003fe4:	01e65693          	srli	a3,a2,0x1e
    80003fe8:	06850613          	addi	a2,a0,104
    80003fec:	96b2                	add	a3,a3,a2
    log[dev].lh.block[i] = lh->block[i];
    80003fee:	4390                	lw	a2,0(a5)
    80003ff0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log[dev].lh.n; i++) {
    80003ff2:	0791                	addi	a5,a5,4
    80003ff4:	0711                	addi	a4,a4,4
    80003ff6:	fed79ce3          	bne	a5,a3,80003fee <initlog+0x7e>
  brelse(buf);
    80003ffa:	fffff097          	auipc	ra,0xfffff
    80003ffe:	f88080e7          	jalr	-120(ra) # 80002f82 <brelse>

static void
recover_from_log(int dev)
{
  read_head(dev);
  install_trans(dev); // if committed, copy from log to disk
    80004002:	854a                	mv	a0,s2
    80004004:	00000097          	auipc	ra,0x0
    80004008:	ea0080e7          	jalr	-352(ra) # 80003ea4 <install_trans>
  log[dev].lh.n = 0;
    8000400c:	0b000793          	li	a5,176
    80004010:	02f90733          	mul	a4,s2,a5
    80004014:	00021797          	auipc	a5,0x21
    80004018:	c8c78793          	addi	a5,a5,-884 # 80024ca0 <log>
    8000401c:	97ba                	add	a5,a5,a4
    8000401e:	0207aa23          	sw	zero,52(a5)
  write_head(dev); // clear the log
    80004022:	854a                	mv	a0,s2
    80004024:	00000097          	auipc	ra,0x0
    80004028:	df6080e7          	jalr	-522(ra) # 80003e1a <write_head>
}
    8000402c:	70a2                	ld	ra,40(sp)
    8000402e:	7402                	ld	s0,32(sp)
    80004030:	64e2                	ld	s1,24(sp)
    80004032:	6942                	ld	s2,16(sp)
    80004034:	69a2                	ld	s3,8(sp)
    80004036:	6a02                	ld	s4,0(sp)
    80004038:	6145                	addi	sp,sp,48
    8000403a:	8082                	ret

000000008000403c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(int dev)
{
    8000403c:	7139                	addi	sp,sp,-64
    8000403e:	fc06                	sd	ra,56(sp)
    80004040:	f822                	sd	s0,48(sp)
    80004042:	f426                	sd	s1,40(sp)
    80004044:	f04a                	sd	s2,32(sp)
    80004046:	ec4e                	sd	s3,24(sp)
    80004048:	e852                	sd	s4,16(sp)
    8000404a:	e456                	sd	s5,8(sp)
    8000404c:	0080                	addi	s0,sp,64
    8000404e:	8aaa                	mv	s5,a0
  acquire(&log[dev].lock);
    80004050:	0b000913          	li	s2,176
    80004054:	032507b3          	mul	a5,a0,s2
    80004058:	00021917          	auipc	s2,0x21
    8000405c:	c4890913          	addi	s2,s2,-952 # 80024ca0 <log>
    80004060:	993e                	add	s2,s2,a5
    80004062:	854a                	mv	a0,s2
    80004064:	ffffd097          	auipc	ra,0xffffd
    80004068:	aaa080e7          	jalr	-1366(ra) # 80000b0e <acquire>
  while(1){
    if(log[dev].committing){
    8000406c:	00021997          	auipc	s3,0x21
    80004070:	c3498993          	addi	s3,s3,-972 # 80024ca0 <log>
    80004074:	84ca                	mv	s1,s2
      sleep(&log, &log[dev].lock);
    } else if(log[dev].lh.n + (log[dev].outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004076:	4a79                	li	s4,30
    80004078:	a039                	j	80004086 <begin_op+0x4a>
      sleep(&log, &log[dev].lock);
    8000407a:	85ca                	mv	a1,s2
    8000407c:	854e                	mv	a0,s3
    8000407e:	ffffe097          	auipc	ra,0xffffe
    80004082:	1be080e7          	jalr	446(ra) # 8000223c <sleep>
    if(log[dev].committing){
    80004086:	54dc                	lw	a5,44(s1)
    80004088:	fbed                	bnez	a5,8000407a <begin_op+0x3e>
    } else if(log[dev].lh.n + (log[dev].outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000408a:	549c                	lw	a5,40(s1)
    8000408c:	0017871b          	addiw	a4,a5,1
    80004090:	0007069b          	sext.w	a3,a4
    80004094:	0027179b          	slliw	a5,a4,0x2
    80004098:	9fb9                	addw	a5,a5,a4
    8000409a:	0017979b          	slliw	a5,a5,0x1
    8000409e:	58d8                	lw	a4,52(s1)
    800040a0:	9fb9                	addw	a5,a5,a4
    800040a2:	00fa5963          	bge	s4,a5,800040b4 <begin_op+0x78>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log[dev].lock);
    800040a6:	85ca                	mv	a1,s2
    800040a8:	854e                	mv	a0,s3
    800040aa:	ffffe097          	auipc	ra,0xffffe
    800040ae:	192080e7          	jalr	402(ra) # 8000223c <sleep>
    800040b2:	bfd1                	j	80004086 <begin_op+0x4a>
    } else {
      log[dev].outstanding += 1;
    800040b4:	0b000513          	li	a0,176
    800040b8:	02aa8ab3          	mul	s5,s5,a0
    800040bc:	00021797          	auipc	a5,0x21
    800040c0:	be478793          	addi	a5,a5,-1052 # 80024ca0 <log>
    800040c4:	9abe                	add	s5,s5,a5
    800040c6:	02daa423          	sw	a3,40(s5)
      release(&log[dev].lock);
    800040ca:	854a                	mv	a0,s2
    800040cc:	ffffd097          	auipc	ra,0xffffd
    800040d0:	ab2080e7          	jalr	-1358(ra) # 80000b7e <release>
      break;
    }
  }
}
    800040d4:	70e2                	ld	ra,56(sp)
    800040d6:	7442                	ld	s0,48(sp)
    800040d8:	74a2                	ld	s1,40(sp)
    800040da:	7902                	ld	s2,32(sp)
    800040dc:	69e2                	ld	s3,24(sp)
    800040de:	6a42                	ld	s4,16(sp)
    800040e0:	6aa2                	ld	s5,8(sp)
    800040e2:	6121                	addi	sp,sp,64
    800040e4:	8082                	ret

00000000800040e6 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(int dev)
{
    800040e6:	715d                	addi	sp,sp,-80
    800040e8:	e486                	sd	ra,72(sp)
    800040ea:	e0a2                	sd	s0,64(sp)
    800040ec:	fc26                	sd	s1,56(sp)
    800040ee:	f84a                	sd	s2,48(sp)
    800040f0:	f44e                	sd	s3,40(sp)
    800040f2:	f052                	sd	s4,32(sp)
    800040f4:	ec56                	sd	s5,24(sp)
    800040f6:	e85a                	sd	s6,16(sp)
    800040f8:	e45e                	sd	s7,8(sp)
    800040fa:	e062                	sd	s8,0(sp)
    800040fc:	0880                	addi	s0,sp,80
    800040fe:	89aa                	mv	s3,a0
  int do_commit = 0;

  acquire(&log[dev].lock);
    80004100:	0b000913          	li	s2,176
    80004104:	03250933          	mul	s2,a0,s2
    80004108:	00021497          	auipc	s1,0x21
    8000410c:	b9848493          	addi	s1,s1,-1128 # 80024ca0 <log>
    80004110:	94ca                	add	s1,s1,s2
    80004112:	8526                	mv	a0,s1
    80004114:	ffffd097          	auipc	ra,0xffffd
    80004118:	9fa080e7          	jalr	-1542(ra) # 80000b0e <acquire>
  log[dev].outstanding -= 1;
    8000411c:	549c                	lw	a5,40(s1)
    8000411e:	37fd                	addiw	a5,a5,-1
    80004120:	00078a9b          	sext.w	s5,a5
    80004124:	d49c                	sw	a5,40(s1)
  if(log[dev].committing)
    80004126:	54dc                	lw	a5,44(s1)
    80004128:	e3b5                	bnez	a5,8000418c <end_op+0xa6>
    panic("log[dev].committing");
  if(log[dev].outstanding == 0){
    8000412a:	060a9963          	bnez	s5,8000419c <end_op+0xb6>
    do_commit = 1;
    log[dev].committing = 1;
    8000412e:	0b000a13          	li	s4,176
    80004132:	034987b3          	mul	a5,s3,s4
    80004136:	00021a17          	auipc	s4,0x21
    8000413a:	b6aa0a13          	addi	s4,s4,-1174 # 80024ca0 <log>
    8000413e:	9a3e                	add	s4,s4,a5
    80004140:	4785                	li	a5,1
    80004142:	02fa2623          	sw	a5,44(s4)
    // begin_op() may be waiting for log space,
    // and decrementing log[dev].outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log[dev].lock);
    80004146:	8526                	mv	a0,s1
    80004148:	ffffd097          	auipc	ra,0xffffd
    8000414c:	a36080e7          	jalr	-1482(ra) # 80000b7e <release>
}

static void
commit(int dev)
{
  if (log[dev].lh.n > 0) {
    80004150:	034a2783          	lw	a5,52(s4)
    80004154:	06f04d63          	bgtz	a5,800041ce <end_op+0xe8>
    acquire(&log[dev].lock);
    80004158:	8526                	mv	a0,s1
    8000415a:	ffffd097          	auipc	ra,0xffffd
    8000415e:	9b4080e7          	jalr	-1612(ra) # 80000b0e <acquire>
    log[dev].committing = 0;
    80004162:	00021517          	auipc	a0,0x21
    80004166:	b3e50513          	addi	a0,a0,-1218 # 80024ca0 <log>
    8000416a:	0b000793          	li	a5,176
    8000416e:	02f989b3          	mul	s3,s3,a5
    80004172:	99aa                	add	s3,s3,a0
    80004174:	0209a623          	sw	zero,44(s3)
    wakeup(&log);
    80004178:	ffffe097          	auipc	ra,0xffffe
    8000417c:	244080e7          	jalr	580(ra) # 800023bc <wakeup>
    release(&log[dev].lock);
    80004180:	8526                	mv	a0,s1
    80004182:	ffffd097          	auipc	ra,0xffffd
    80004186:	9fc080e7          	jalr	-1540(ra) # 80000b7e <release>
}
    8000418a:	a035                	j	800041b6 <end_op+0xd0>
    panic("log[dev].committing");
    8000418c:	00004517          	auipc	a0,0x4
    80004190:	5bc50513          	addi	a0,a0,1468 # 80008748 <userret+0x6b8>
    80004194:	ffffc097          	auipc	ra,0xffffc
    80004198:	3b4080e7          	jalr	948(ra) # 80000548 <panic>
    wakeup(&log);
    8000419c:	00021517          	auipc	a0,0x21
    800041a0:	b0450513          	addi	a0,a0,-1276 # 80024ca0 <log>
    800041a4:	ffffe097          	auipc	ra,0xffffe
    800041a8:	218080e7          	jalr	536(ra) # 800023bc <wakeup>
  release(&log[dev].lock);
    800041ac:	8526                	mv	a0,s1
    800041ae:	ffffd097          	auipc	ra,0xffffd
    800041b2:	9d0080e7          	jalr	-1584(ra) # 80000b7e <release>
}
    800041b6:	60a6                	ld	ra,72(sp)
    800041b8:	6406                	ld	s0,64(sp)
    800041ba:	74e2                	ld	s1,56(sp)
    800041bc:	7942                	ld	s2,48(sp)
    800041be:	79a2                	ld	s3,40(sp)
    800041c0:	7a02                	ld	s4,32(sp)
    800041c2:	6ae2                	ld	s5,24(sp)
    800041c4:	6b42                	ld	s6,16(sp)
    800041c6:	6ba2                	ld	s7,8(sp)
    800041c8:	6c02                	ld	s8,0(sp)
    800041ca:	6161                	addi	sp,sp,80
    800041cc:	8082                	ret
  for (tail = 0; tail < log[dev].lh.n; tail++) {
    800041ce:	00021797          	auipc	a5,0x21
    800041d2:	b0a78793          	addi	a5,a5,-1270 # 80024cd8 <log+0x38>
    800041d6:	993e                	add	s2,s2,a5
    struct buf *to = bread(dev, log[dev].start+tail+1); // log block
    800041d8:	00098c1b          	sext.w	s8,s3
    800041dc:	0b000b93          	li	s7,176
    800041e0:	037987b3          	mul	a5,s3,s7
    800041e4:	00021b97          	auipc	s7,0x21
    800041e8:	abcb8b93          	addi	s7,s7,-1348 # 80024ca0 <log>
    800041ec:	9bbe                	add	s7,s7,a5
    800041ee:	020ba583          	lw	a1,32(s7)
    800041f2:	015585bb          	addw	a1,a1,s5
    800041f6:	2585                	addiw	a1,a1,1
    800041f8:	8562                	mv	a0,s8
    800041fa:	fffff097          	auipc	ra,0xfffff
    800041fe:	c54080e7          	jalr	-940(ra) # 80002e4e <bread>
    80004202:	8a2a                	mv	s4,a0
    struct buf *from = bread(dev, log[dev].lh.block[tail]); // cache block
    80004204:	00092583          	lw	a1,0(s2)
    80004208:	8562                	mv	a0,s8
    8000420a:	fffff097          	auipc	ra,0xfffff
    8000420e:	c44080e7          	jalr	-956(ra) # 80002e4e <bread>
    80004212:	8b2a                	mv	s6,a0
    memmove(to->data, from->data, BSIZE);
    80004214:	40000613          	li	a2,1024
    80004218:	06050593          	addi	a1,a0,96
    8000421c:	060a0513          	addi	a0,s4,96
    80004220:	ffffd097          	auipc	ra,0xffffd
    80004224:	bb8080e7          	jalr	-1096(ra) # 80000dd8 <memmove>
    bwrite(to);  // write the log
    80004228:	8552                	mv	a0,s4
    8000422a:	fffff097          	auipc	ra,0xfffff
    8000422e:	d18080e7          	jalr	-744(ra) # 80002f42 <bwrite>
    brelse(from);
    80004232:	855a                	mv	a0,s6
    80004234:	fffff097          	auipc	ra,0xfffff
    80004238:	d4e080e7          	jalr	-690(ra) # 80002f82 <brelse>
    brelse(to);
    8000423c:	8552                	mv	a0,s4
    8000423e:	fffff097          	auipc	ra,0xfffff
    80004242:	d44080e7          	jalr	-700(ra) # 80002f82 <brelse>
  for (tail = 0; tail < log[dev].lh.n; tail++) {
    80004246:	2a85                	addiw	s5,s5,1
    80004248:	0911                	addi	s2,s2,4
    8000424a:	034ba783          	lw	a5,52(s7)
    8000424e:	fafac0e3          	blt	s5,a5,800041ee <end_op+0x108>
    write_log(dev);     // Write modified blocks from cache to log
    write_head(dev);    // Write header to disk -- the real commit
    80004252:	854e                	mv	a0,s3
    80004254:	00000097          	auipc	ra,0x0
    80004258:	bc6080e7          	jalr	-1082(ra) # 80003e1a <write_head>
    install_trans(dev); // Now install writes to home locations
    8000425c:	854e                	mv	a0,s3
    8000425e:	00000097          	auipc	ra,0x0
    80004262:	c46080e7          	jalr	-954(ra) # 80003ea4 <install_trans>
    log[dev].lh.n = 0;
    80004266:	0b000793          	li	a5,176
    8000426a:	02f98733          	mul	a4,s3,a5
    8000426e:	00021797          	auipc	a5,0x21
    80004272:	a3278793          	addi	a5,a5,-1486 # 80024ca0 <log>
    80004276:	97ba                	add	a5,a5,a4
    80004278:	0207aa23          	sw	zero,52(a5)
    write_head(dev);    // Erase the transaction from the log
    8000427c:	854e                	mv	a0,s3
    8000427e:	00000097          	auipc	ra,0x0
    80004282:	b9c080e7          	jalr	-1124(ra) # 80003e1a <write_head>
    80004286:	bdc9                	j	80004158 <end_op+0x72>

0000000080004288 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004288:	7179                	addi	sp,sp,-48
    8000428a:	f406                	sd	ra,40(sp)
    8000428c:	f022                	sd	s0,32(sp)
    8000428e:	ec26                	sd	s1,24(sp)
    80004290:	e84a                	sd	s2,16(sp)
    80004292:	e44e                	sd	s3,8(sp)
    80004294:	e052                	sd	s4,0(sp)
    80004296:	1800                	addi	s0,sp,48
  int i;

  int dev = b->dev;
    80004298:	00852903          	lw	s2,8(a0)
  if (log[dev].lh.n >= LOGSIZE || log[dev].lh.n >= log[dev].size - 1)
    8000429c:	0b000793          	li	a5,176
    800042a0:	02f90733          	mul	a4,s2,a5
    800042a4:	00021797          	auipc	a5,0x21
    800042a8:	9fc78793          	addi	a5,a5,-1540 # 80024ca0 <log>
    800042ac:	97ba                	add	a5,a5,a4
    800042ae:	5bd4                	lw	a3,52(a5)
    800042b0:	47f5                	li	a5,29
    800042b2:	0ad7cc63          	blt	a5,a3,8000436a <log_write+0xe2>
    800042b6:	89aa                	mv	s3,a0
    800042b8:	00021797          	auipc	a5,0x21
    800042bc:	9e878793          	addi	a5,a5,-1560 # 80024ca0 <log>
    800042c0:	97ba                	add	a5,a5,a4
    800042c2:	53dc                	lw	a5,36(a5)
    800042c4:	37fd                	addiw	a5,a5,-1
    800042c6:	0af6d263          	bge	a3,a5,8000436a <log_write+0xe2>
    panic("too big a transaction");
  if (log[dev].outstanding < 1)
    800042ca:	0b000793          	li	a5,176
    800042ce:	02f90733          	mul	a4,s2,a5
    800042d2:	00021797          	auipc	a5,0x21
    800042d6:	9ce78793          	addi	a5,a5,-1586 # 80024ca0 <log>
    800042da:	97ba                	add	a5,a5,a4
    800042dc:	579c                	lw	a5,40(a5)
    800042de:	08f05e63          	blez	a5,8000437a <log_write+0xf2>
    panic("log_write outside of trans");

  acquire(&log[dev].lock);
    800042e2:	0b000793          	li	a5,176
    800042e6:	02f904b3          	mul	s1,s2,a5
    800042ea:	00021a17          	auipc	s4,0x21
    800042ee:	9b6a0a13          	addi	s4,s4,-1610 # 80024ca0 <log>
    800042f2:	9a26                	add	s4,s4,s1
    800042f4:	8552                	mv	a0,s4
    800042f6:	ffffd097          	auipc	ra,0xffffd
    800042fa:	818080e7          	jalr	-2024(ra) # 80000b0e <acquire>
  for (i = 0; i < log[dev].lh.n; i++) {
    800042fe:	034a2603          	lw	a2,52(s4)
    80004302:	08c05463          	blez	a2,8000438a <log_write+0x102>
    if (log[dev].lh.block[i] == b->blockno)   // log absorbtion
    80004306:	00c9a583          	lw	a1,12(s3)
    8000430a:	00021797          	auipc	a5,0x21
    8000430e:	9ce78793          	addi	a5,a5,-1586 # 80024cd8 <log+0x38>
    80004312:	97a6                	add	a5,a5,s1
  for (i = 0; i < log[dev].lh.n; i++) {
    80004314:	4701                	li	a4,0
    if (log[dev].lh.block[i] == b->blockno)   // log absorbtion
    80004316:	4394                	lw	a3,0(a5)
    80004318:	06b68a63          	beq	a3,a1,8000438c <log_write+0x104>
  for (i = 0; i < log[dev].lh.n; i++) {
    8000431c:	2705                	addiw	a4,a4,1
    8000431e:	0791                	addi	a5,a5,4
    80004320:	fec71be3          	bne	a4,a2,80004316 <log_write+0x8e>
      break;
  }
  log[dev].lh.block[i] = b->blockno;
    80004324:	02c00793          	li	a5,44
    80004328:	02f907b3          	mul	a5,s2,a5
    8000432c:	97b2                	add	a5,a5,a2
    8000432e:	07b1                	addi	a5,a5,12
    80004330:	078a                	slli	a5,a5,0x2
    80004332:	00021717          	auipc	a4,0x21
    80004336:	96e70713          	addi	a4,a4,-1682 # 80024ca0 <log>
    8000433a:	97ba                	add	a5,a5,a4
    8000433c:	00c9a703          	lw	a4,12(s3)
    80004340:	c798                	sw	a4,8(a5)
  if (i == log[dev].lh.n) {  // Add new block to log?
    bpin(b);
    80004342:	854e                	mv	a0,s3
    80004344:	fffff097          	auipc	ra,0xfffff
    80004348:	cdc080e7          	jalr	-804(ra) # 80003020 <bpin>
    log[dev].lh.n++;
    8000434c:	0b000793          	li	a5,176
    80004350:	02f90933          	mul	s2,s2,a5
    80004354:	00021797          	auipc	a5,0x21
    80004358:	94c78793          	addi	a5,a5,-1716 # 80024ca0 <log>
    8000435c:	993e                	add	s2,s2,a5
    8000435e:	03492783          	lw	a5,52(s2)
    80004362:	2785                	addiw	a5,a5,1
    80004364:	02f92a23          	sw	a5,52(s2)
    80004368:	a099                	j	800043ae <log_write+0x126>
    panic("too big a transaction");
    8000436a:	00004517          	auipc	a0,0x4
    8000436e:	3f650513          	addi	a0,a0,1014 # 80008760 <userret+0x6d0>
    80004372:	ffffc097          	auipc	ra,0xffffc
    80004376:	1d6080e7          	jalr	470(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    8000437a:	00004517          	auipc	a0,0x4
    8000437e:	3fe50513          	addi	a0,a0,1022 # 80008778 <userret+0x6e8>
    80004382:	ffffc097          	auipc	ra,0xffffc
    80004386:	1c6080e7          	jalr	454(ra) # 80000548 <panic>
  for (i = 0; i < log[dev].lh.n; i++) {
    8000438a:	4701                	li	a4,0
  log[dev].lh.block[i] = b->blockno;
    8000438c:	02c00793          	li	a5,44
    80004390:	02f907b3          	mul	a5,s2,a5
    80004394:	97ba                	add	a5,a5,a4
    80004396:	07b1                	addi	a5,a5,12
    80004398:	078a                	slli	a5,a5,0x2
    8000439a:	00021697          	auipc	a3,0x21
    8000439e:	90668693          	addi	a3,a3,-1786 # 80024ca0 <log>
    800043a2:	97b6                	add	a5,a5,a3
    800043a4:	00c9a683          	lw	a3,12(s3)
    800043a8:	c794                	sw	a3,8(a5)
  if (i == log[dev].lh.n) {  // Add new block to log?
    800043aa:	f8e60ce3          	beq	a2,a4,80004342 <log_write+0xba>
  }
  release(&log[dev].lock);
    800043ae:	8552                	mv	a0,s4
    800043b0:	ffffc097          	auipc	ra,0xffffc
    800043b4:	7ce080e7          	jalr	1998(ra) # 80000b7e <release>
}
    800043b8:	70a2                	ld	ra,40(sp)
    800043ba:	7402                	ld	s0,32(sp)
    800043bc:	64e2                	ld	s1,24(sp)
    800043be:	6942                	ld	s2,16(sp)
    800043c0:	69a2                	ld	s3,8(sp)
    800043c2:	6a02                	ld	s4,0(sp)
    800043c4:	6145                	addi	sp,sp,48
    800043c6:	8082                	ret

00000000800043c8 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043c8:	1101                	addi	sp,sp,-32
    800043ca:	ec06                	sd	ra,24(sp)
    800043cc:	e822                	sd	s0,16(sp)
    800043ce:	e426                	sd	s1,8(sp)
    800043d0:	e04a                	sd	s2,0(sp)
    800043d2:	1000                	addi	s0,sp,32
    800043d4:	84aa                	mv	s1,a0
    800043d6:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043d8:	00004597          	auipc	a1,0x4
    800043dc:	3c058593          	addi	a1,a1,960 # 80008798 <userret+0x708>
    800043e0:	0521                	addi	a0,a0,8
    800043e2:	ffffc097          	auipc	ra,0xffffc
    800043e6:	5de080e7          	jalr	1502(ra) # 800009c0 <initlock>
  lk->name = name;
    800043ea:	0324b423          	sd	s2,40(s1)
  lk->locked = 0;
    800043ee:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043f2:	0204a823          	sw	zero,48(s1)
}
    800043f6:	60e2                	ld	ra,24(sp)
    800043f8:	6442                	ld	s0,16(sp)
    800043fa:	64a2                	ld	s1,8(sp)
    800043fc:	6902                	ld	s2,0(sp)
    800043fe:	6105                	addi	sp,sp,32
    80004400:	8082                	ret

0000000080004402 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004402:	1101                	addi	sp,sp,-32
    80004404:	ec06                	sd	ra,24(sp)
    80004406:	e822                	sd	s0,16(sp)
    80004408:	e426                	sd	s1,8(sp)
    8000440a:	e04a                	sd	s2,0(sp)
    8000440c:	1000                	addi	s0,sp,32
    8000440e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004410:	00850913          	addi	s2,a0,8
    80004414:	854a                	mv	a0,s2
    80004416:	ffffc097          	auipc	ra,0xffffc
    8000441a:	6f8080e7          	jalr	1784(ra) # 80000b0e <acquire>
  while (lk->locked) {
    8000441e:	409c                	lw	a5,0(s1)
    80004420:	cb89                	beqz	a5,80004432 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004422:	85ca                	mv	a1,s2
    80004424:	8526                	mv	a0,s1
    80004426:	ffffe097          	auipc	ra,0xffffe
    8000442a:	e16080e7          	jalr	-490(ra) # 8000223c <sleep>
  while (lk->locked) {
    8000442e:	409c                	lw	a5,0(s1)
    80004430:	fbed                	bnez	a5,80004422 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004432:	4785                	li	a5,1
    80004434:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004436:	ffffd097          	auipc	ra,0xffffd
    8000443a:	630080e7          	jalr	1584(ra) # 80001a66 <myproc>
    8000443e:	413c                	lw	a5,64(a0)
    80004440:	d89c                	sw	a5,48(s1)
  release(&lk->lk);
    80004442:	854a                	mv	a0,s2
    80004444:	ffffc097          	auipc	ra,0xffffc
    80004448:	73a080e7          	jalr	1850(ra) # 80000b7e <release>
}
    8000444c:	60e2                	ld	ra,24(sp)
    8000444e:	6442                	ld	s0,16(sp)
    80004450:	64a2                	ld	s1,8(sp)
    80004452:	6902                	ld	s2,0(sp)
    80004454:	6105                	addi	sp,sp,32
    80004456:	8082                	ret

0000000080004458 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004458:	1101                	addi	sp,sp,-32
    8000445a:	ec06                	sd	ra,24(sp)
    8000445c:	e822                	sd	s0,16(sp)
    8000445e:	e426                	sd	s1,8(sp)
    80004460:	e04a                	sd	s2,0(sp)
    80004462:	1000                	addi	s0,sp,32
    80004464:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004466:	00850913          	addi	s2,a0,8
    8000446a:	854a                	mv	a0,s2
    8000446c:	ffffc097          	auipc	ra,0xffffc
    80004470:	6a2080e7          	jalr	1698(ra) # 80000b0e <acquire>
  lk->locked = 0;
    80004474:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004478:	0204a823          	sw	zero,48(s1)
  wakeup(lk);
    8000447c:	8526                	mv	a0,s1
    8000447e:	ffffe097          	auipc	ra,0xffffe
    80004482:	f3e080e7          	jalr	-194(ra) # 800023bc <wakeup>
  release(&lk->lk);
    80004486:	854a                	mv	a0,s2
    80004488:	ffffc097          	auipc	ra,0xffffc
    8000448c:	6f6080e7          	jalr	1782(ra) # 80000b7e <release>
}
    80004490:	60e2                	ld	ra,24(sp)
    80004492:	6442                	ld	s0,16(sp)
    80004494:	64a2                	ld	s1,8(sp)
    80004496:	6902                	ld	s2,0(sp)
    80004498:	6105                	addi	sp,sp,32
    8000449a:	8082                	ret

000000008000449c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000449c:	7179                	addi	sp,sp,-48
    8000449e:	f406                	sd	ra,40(sp)
    800044a0:	f022                	sd	s0,32(sp)
    800044a2:	ec26                	sd	s1,24(sp)
    800044a4:	e84a                	sd	s2,16(sp)
    800044a6:	e44e                	sd	s3,8(sp)
    800044a8:	1800                	addi	s0,sp,48
    800044aa:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044ac:	00850913          	addi	s2,a0,8
    800044b0:	854a                	mv	a0,s2
    800044b2:	ffffc097          	auipc	ra,0xffffc
    800044b6:	65c080e7          	jalr	1628(ra) # 80000b0e <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044ba:	409c                	lw	a5,0(s1)
    800044bc:	ef99                	bnez	a5,800044da <holdingsleep+0x3e>
    800044be:	4481                	li	s1,0
  release(&lk->lk);
    800044c0:	854a                	mv	a0,s2
    800044c2:	ffffc097          	auipc	ra,0xffffc
    800044c6:	6bc080e7          	jalr	1724(ra) # 80000b7e <release>
  return r;
}
    800044ca:	8526                	mv	a0,s1
    800044cc:	70a2                	ld	ra,40(sp)
    800044ce:	7402                	ld	s0,32(sp)
    800044d0:	64e2                	ld	s1,24(sp)
    800044d2:	6942                	ld	s2,16(sp)
    800044d4:	69a2                	ld	s3,8(sp)
    800044d6:	6145                	addi	sp,sp,48
    800044d8:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044da:	0304a983          	lw	s3,48(s1)
    800044de:	ffffd097          	auipc	ra,0xffffd
    800044e2:	588080e7          	jalr	1416(ra) # 80001a66 <myproc>
    800044e6:	4124                	lw	s1,64(a0)
    800044e8:	413484b3          	sub	s1,s1,s3
    800044ec:	0014b493          	seqz	s1,s1
    800044f0:	bfc1                	j	800044c0 <holdingsleep+0x24>

00000000800044f2 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044f2:	1141                	addi	sp,sp,-16
    800044f4:	e406                	sd	ra,8(sp)
    800044f6:	e022                	sd	s0,0(sp)
    800044f8:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044fa:	00004597          	auipc	a1,0x4
    800044fe:	2ae58593          	addi	a1,a1,686 # 800087a8 <userret+0x718>
    80004502:	00021517          	auipc	a0,0x21
    80004506:	99e50513          	addi	a0,a0,-1634 # 80024ea0 <ftable>
    8000450a:	ffffc097          	auipc	ra,0xffffc
    8000450e:	4b6080e7          	jalr	1206(ra) # 800009c0 <initlock>
}
    80004512:	60a2                	ld	ra,8(sp)
    80004514:	6402                	ld	s0,0(sp)
    80004516:	0141                	addi	sp,sp,16
    80004518:	8082                	ret

000000008000451a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000451a:	1101                	addi	sp,sp,-32
    8000451c:	ec06                	sd	ra,24(sp)
    8000451e:	e822                	sd	s0,16(sp)
    80004520:	e426                	sd	s1,8(sp)
    80004522:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004524:	00021517          	auipc	a0,0x21
    80004528:	97c50513          	addi	a0,a0,-1668 # 80024ea0 <ftable>
    8000452c:	ffffc097          	auipc	ra,0xffffc
    80004530:	5e2080e7          	jalr	1506(ra) # 80000b0e <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004534:	00021497          	auipc	s1,0x21
    80004538:	98c48493          	addi	s1,s1,-1652 # 80024ec0 <ftable+0x20>
    8000453c:	00022717          	auipc	a4,0x22
    80004540:	92470713          	addi	a4,a4,-1756 # 80025e60 <ftable+0xfc0>
    if(f->ref == 0){
    80004544:	40dc                	lw	a5,4(s1)
    80004546:	cf99                	beqz	a5,80004564 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004548:	02848493          	addi	s1,s1,40
    8000454c:	fee49ce3          	bne	s1,a4,80004544 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004550:	00021517          	auipc	a0,0x21
    80004554:	95050513          	addi	a0,a0,-1712 # 80024ea0 <ftable>
    80004558:	ffffc097          	auipc	ra,0xffffc
    8000455c:	626080e7          	jalr	1574(ra) # 80000b7e <release>
  return 0;
    80004560:	4481                	li	s1,0
    80004562:	a819                	j	80004578 <filealloc+0x5e>
      f->ref = 1;
    80004564:	4785                	li	a5,1
    80004566:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004568:	00021517          	auipc	a0,0x21
    8000456c:	93850513          	addi	a0,a0,-1736 # 80024ea0 <ftable>
    80004570:	ffffc097          	auipc	ra,0xffffc
    80004574:	60e080e7          	jalr	1550(ra) # 80000b7e <release>
}
    80004578:	8526                	mv	a0,s1
    8000457a:	60e2                	ld	ra,24(sp)
    8000457c:	6442                	ld	s0,16(sp)
    8000457e:	64a2                	ld	s1,8(sp)
    80004580:	6105                	addi	sp,sp,32
    80004582:	8082                	ret

0000000080004584 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004584:	1101                	addi	sp,sp,-32
    80004586:	ec06                	sd	ra,24(sp)
    80004588:	e822                	sd	s0,16(sp)
    8000458a:	e426                	sd	s1,8(sp)
    8000458c:	1000                	addi	s0,sp,32
    8000458e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004590:	00021517          	auipc	a0,0x21
    80004594:	91050513          	addi	a0,a0,-1776 # 80024ea0 <ftable>
    80004598:	ffffc097          	auipc	ra,0xffffc
    8000459c:	576080e7          	jalr	1398(ra) # 80000b0e <acquire>
  if(f->ref < 1)
    800045a0:	40dc                	lw	a5,4(s1)
    800045a2:	02f05263          	blez	a5,800045c6 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800045a6:	2785                	addiw	a5,a5,1
    800045a8:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045aa:	00021517          	auipc	a0,0x21
    800045ae:	8f650513          	addi	a0,a0,-1802 # 80024ea0 <ftable>
    800045b2:	ffffc097          	auipc	ra,0xffffc
    800045b6:	5cc080e7          	jalr	1484(ra) # 80000b7e <release>
  return f;
}
    800045ba:	8526                	mv	a0,s1
    800045bc:	60e2                	ld	ra,24(sp)
    800045be:	6442                	ld	s0,16(sp)
    800045c0:	64a2                	ld	s1,8(sp)
    800045c2:	6105                	addi	sp,sp,32
    800045c4:	8082                	ret
    panic("filedup");
    800045c6:	00004517          	auipc	a0,0x4
    800045ca:	1ea50513          	addi	a0,a0,490 # 800087b0 <userret+0x720>
    800045ce:	ffffc097          	auipc	ra,0xffffc
    800045d2:	f7a080e7          	jalr	-134(ra) # 80000548 <panic>

00000000800045d6 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045d6:	7139                	addi	sp,sp,-64
    800045d8:	fc06                	sd	ra,56(sp)
    800045da:	f822                	sd	s0,48(sp)
    800045dc:	f426                	sd	s1,40(sp)
    800045de:	f04a                	sd	s2,32(sp)
    800045e0:	ec4e                	sd	s3,24(sp)
    800045e2:	e852                	sd	s4,16(sp)
    800045e4:	e456                	sd	s5,8(sp)
    800045e6:	0080                	addi	s0,sp,64
    800045e8:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045ea:	00021517          	auipc	a0,0x21
    800045ee:	8b650513          	addi	a0,a0,-1866 # 80024ea0 <ftable>
    800045f2:	ffffc097          	auipc	ra,0xffffc
    800045f6:	51c080e7          	jalr	1308(ra) # 80000b0e <acquire>
  if(f->ref < 1)
    800045fa:	40dc                	lw	a5,4(s1)
    800045fc:	06f05563          	blez	a5,80004666 <fileclose+0x90>
    panic("fileclose");
  if(--f->ref > 0){
    80004600:	37fd                	addiw	a5,a5,-1
    80004602:	0007871b          	sext.w	a4,a5
    80004606:	c0dc                	sw	a5,4(s1)
    80004608:	06e04763          	bgtz	a4,80004676 <fileclose+0xa0>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000460c:	0004a903          	lw	s2,0(s1)
    80004610:	0094ca83          	lbu	s5,9(s1)
    80004614:	0104ba03          	ld	s4,16(s1)
    80004618:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000461c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004620:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004624:	00021517          	auipc	a0,0x21
    80004628:	87c50513          	addi	a0,a0,-1924 # 80024ea0 <ftable>
    8000462c:	ffffc097          	auipc	ra,0xffffc
    80004630:	552080e7          	jalr	1362(ra) # 80000b7e <release>

  if(ff.type == FD_PIPE){
    80004634:	4785                	li	a5,1
    80004636:	06f90163          	beq	s2,a5,80004698 <fileclose+0xc2>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000463a:	3979                	addiw	s2,s2,-2
    8000463c:	4785                	li	a5,1
    8000463e:	0527e463          	bltu	a5,s2,80004686 <fileclose+0xb0>
    begin_op(ff.ip->dev);
    80004642:	0009a503          	lw	a0,0(s3)
    80004646:	00000097          	auipc	ra,0x0
    8000464a:	9f6080e7          	jalr	-1546(ra) # 8000403c <begin_op>
    iput(ff.ip);
    8000464e:	854e                	mv	a0,s3
    80004650:	fffff097          	auipc	ra,0xfffff
    80004654:	114080e7          	jalr	276(ra) # 80003764 <iput>
    end_op(ff.ip->dev);
    80004658:	0009a503          	lw	a0,0(s3)
    8000465c:	00000097          	auipc	ra,0x0
    80004660:	a8a080e7          	jalr	-1398(ra) # 800040e6 <end_op>
    80004664:	a00d                	j	80004686 <fileclose+0xb0>
    panic("fileclose");
    80004666:	00004517          	auipc	a0,0x4
    8000466a:	15250513          	addi	a0,a0,338 # 800087b8 <userret+0x728>
    8000466e:	ffffc097          	auipc	ra,0xffffc
    80004672:	eda080e7          	jalr	-294(ra) # 80000548 <panic>
    release(&ftable.lock);
    80004676:	00021517          	auipc	a0,0x21
    8000467a:	82a50513          	addi	a0,a0,-2006 # 80024ea0 <ftable>
    8000467e:	ffffc097          	auipc	ra,0xffffc
    80004682:	500080e7          	jalr	1280(ra) # 80000b7e <release>
  }
}
    80004686:	70e2                	ld	ra,56(sp)
    80004688:	7442                	ld	s0,48(sp)
    8000468a:	74a2                	ld	s1,40(sp)
    8000468c:	7902                	ld	s2,32(sp)
    8000468e:	69e2                	ld	s3,24(sp)
    80004690:	6a42                	ld	s4,16(sp)
    80004692:	6aa2                	ld	s5,8(sp)
    80004694:	6121                	addi	sp,sp,64
    80004696:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004698:	85d6                	mv	a1,s5
    8000469a:	8552                	mv	a0,s4
    8000469c:	00000097          	auipc	ra,0x0
    800046a0:	376080e7          	jalr	886(ra) # 80004a12 <pipeclose>
    800046a4:	b7cd                	j	80004686 <fileclose+0xb0>

00000000800046a6 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046a6:	715d                	addi	sp,sp,-80
    800046a8:	e486                	sd	ra,72(sp)
    800046aa:	e0a2                	sd	s0,64(sp)
    800046ac:	fc26                	sd	s1,56(sp)
    800046ae:	f84a                	sd	s2,48(sp)
    800046b0:	f44e                	sd	s3,40(sp)
    800046b2:	0880                	addi	s0,sp,80
    800046b4:	84aa                	mv	s1,a0
    800046b6:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046b8:	ffffd097          	auipc	ra,0xffffd
    800046bc:	3ae080e7          	jalr	942(ra) # 80001a66 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046c0:	409c                	lw	a5,0(s1)
    800046c2:	37f9                	addiw	a5,a5,-2
    800046c4:	4705                	li	a4,1
    800046c6:	04f76763          	bltu	a4,a5,80004714 <filestat+0x6e>
    800046ca:	892a                	mv	s2,a0
    ilock(f->ip);
    800046cc:	6c88                	ld	a0,24(s1)
    800046ce:	fffff097          	auipc	ra,0xfffff
    800046d2:	f88080e7          	jalr	-120(ra) # 80003656 <ilock>
    stati(f->ip, &st);
    800046d6:	fb840593          	addi	a1,s0,-72
    800046da:	6c88                	ld	a0,24(s1)
    800046dc:	fffff097          	auipc	ra,0xfffff
    800046e0:	1e0080e7          	jalr	480(ra) # 800038bc <stati>
    iunlock(f->ip);
    800046e4:	6c88                	ld	a0,24(s1)
    800046e6:	fffff097          	auipc	ra,0xfffff
    800046ea:	032080e7          	jalr	50(ra) # 80003718 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046ee:	46e1                	li	a3,24
    800046f0:	fb840613          	addi	a2,s0,-72
    800046f4:	85ce                	mv	a1,s3
    800046f6:	05893503          	ld	a0,88(s2)
    800046fa:	ffffd097          	auipc	ra,0xffffd
    800046fe:	05e080e7          	jalr	94(ra) # 80001758 <copyout>
    80004702:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004706:	60a6                	ld	ra,72(sp)
    80004708:	6406                	ld	s0,64(sp)
    8000470a:	74e2                	ld	s1,56(sp)
    8000470c:	7942                	ld	s2,48(sp)
    8000470e:	79a2                	ld	s3,40(sp)
    80004710:	6161                	addi	sp,sp,80
    80004712:	8082                	ret
  return -1;
    80004714:	557d                	li	a0,-1
    80004716:	bfc5                	j	80004706 <filestat+0x60>

0000000080004718 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004718:	7179                	addi	sp,sp,-48
    8000471a:	f406                	sd	ra,40(sp)
    8000471c:	f022                	sd	s0,32(sp)
    8000471e:	ec26                	sd	s1,24(sp)
    80004720:	e84a                	sd	s2,16(sp)
    80004722:	e44e                	sd	s3,8(sp)
    80004724:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004726:	00854783          	lbu	a5,8(a0)
    8000472a:	c7c5                	beqz	a5,800047d2 <fileread+0xba>
    8000472c:	84aa                	mv	s1,a0
    8000472e:	89ae                	mv	s3,a1
    80004730:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004732:	411c                	lw	a5,0(a0)
    80004734:	4705                	li	a4,1
    80004736:	04e78963          	beq	a5,a4,80004788 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000473a:	470d                	li	a4,3
    8000473c:	04e78d63          	beq	a5,a4,80004796 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(f, 1, addr, n);
  } else if(f->type == FD_INODE){
    80004740:	4709                	li	a4,2
    80004742:	08e79063          	bne	a5,a4,800047c2 <fileread+0xaa>
    ilock(f->ip);
    80004746:	6d08                	ld	a0,24(a0)
    80004748:	fffff097          	auipc	ra,0xfffff
    8000474c:	f0e080e7          	jalr	-242(ra) # 80003656 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004750:	874a                	mv	a4,s2
    80004752:	5094                	lw	a3,32(s1)
    80004754:	864e                	mv	a2,s3
    80004756:	4585                	li	a1,1
    80004758:	6c88                	ld	a0,24(s1)
    8000475a:	fffff097          	auipc	ra,0xfffff
    8000475e:	18c080e7          	jalr	396(ra) # 800038e6 <readi>
    80004762:	892a                	mv	s2,a0
    80004764:	00a05563          	blez	a0,8000476e <fileread+0x56>
      f->off += r;
    80004768:	509c                	lw	a5,32(s1)
    8000476a:	9fa9                	addw	a5,a5,a0
    8000476c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000476e:	6c88                	ld	a0,24(s1)
    80004770:	fffff097          	auipc	ra,0xfffff
    80004774:	fa8080e7          	jalr	-88(ra) # 80003718 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004778:	854a                	mv	a0,s2
    8000477a:	70a2                	ld	ra,40(sp)
    8000477c:	7402                	ld	s0,32(sp)
    8000477e:	64e2                	ld	s1,24(sp)
    80004780:	6942                	ld	s2,16(sp)
    80004782:	69a2                	ld	s3,8(sp)
    80004784:	6145                	addi	sp,sp,48
    80004786:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004788:	6908                	ld	a0,16(a0)
    8000478a:	00000097          	auipc	ra,0x0
    8000478e:	406080e7          	jalr	1030(ra) # 80004b90 <piperead>
    80004792:	892a                	mv	s2,a0
    80004794:	b7d5                	j	80004778 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004796:	02451783          	lh	a5,36(a0)
    8000479a:	03079693          	slli	a3,a5,0x30
    8000479e:	92c1                	srli	a3,a3,0x30
    800047a0:	4725                	li	a4,9
    800047a2:	02d76a63          	bltu	a4,a3,800047d6 <fileread+0xbe>
    800047a6:	0792                	slli	a5,a5,0x4
    800047a8:	00020717          	auipc	a4,0x20
    800047ac:	65870713          	addi	a4,a4,1624 # 80024e00 <devsw>
    800047b0:	97ba                	add	a5,a5,a4
    800047b2:	639c                	ld	a5,0(a5)
    800047b4:	c39d                	beqz	a5,800047da <fileread+0xc2>
    r = devsw[f->major].read(f, 1, addr, n);
    800047b6:	86b2                	mv	a3,a2
    800047b8:	862e                	mv	a2,a1
    800047ba:	4585                	li	a1,1
    800047bc:	9782                	jalr	a5
    800047be:	892a                	mv	s2,a0
    800047c0:	bf65                	j	80004778 <fileread+0x60>
    panic("fileread");
    800047c2:	00004517          	auipc	a0,0x4
    800047c6:	00650513          	addi	a0,a0,6 # 800087c8 <userret+0x738>
    800047ca:	ffffc097          	auipc	ra,0xffffc
    800047ce:	d7e080e7          	jalr	-642(ra) # 80000548 <panic>
    return -1;
    800047d2:	597d                	li	s2,-1
    800047d4:	b755                	j	80004778 <fileread+0x60>
      return -1;
    800047d6:	597d                	li	s2,-1
    800047d8:	b745                	j	80004778 <fileread+0x60>
    800047da:	597d                	li	s2,-1
    800047dc:	bf71                	j	80004778 <fileread+0x60>

00000000800047de <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800047de:	00954783          	lbu	a5,9(a0)
    800047e2:	14078663          	beqz	a5,8000492e <filewrite+0x150>
{
    800047e6:	715d                	addi	sp,sp,-80
    800047e8:	e486                	sd	ra,72(sp)
    800047ea:	e0a2                	sd	s0,64(sp)
    800047ec:	fc26                	sd	s1,56(sp)
    800047ee:	f84a                	sd	s2,48(sp)
    800047f0:	f44e                	sd	s3,40(sp)
    800047f2:	f052                	sd	s4,32(sp)
    800047f4:	ec56                	sd	s5,24(sp)
    800047f6:	e85a                	sd	s6,16(sp)
    800047f8:	e45e                	sd	s7,8(sp)
    800047fa:	e062                	sd	s8,0(sp)
    800047fc:	0880                	addi	s0,sp,80
    800047fe:	84aa                	mv	s1,a0
    80004800:	8aae                	mv	s5,a1
    80004802:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004804:	411c                	lw	a5,0(a0)
    80004806:	4705                	li	a4,1
    80004808:	02e78263          	beq	a5,a4,8000482c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000480c:	470d                	li	a4,3
    8000480e:	02e78563          	beq	a5,a4,80004838 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(f, 1, addr, n);
  } else if(f->type == FD_INODE){
    80004812:	4709                	li	a4,2
    80004814:	10e79563          	bne	a5,a4,8000491e <filewrite+0x140>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004818:	0ec05f63          	blez	a2,80004916 <filewrite+0x138>
    int i = 0;
    8000481c:	4981                	li	s3,0
    8000481e:	6b05                	lui	s6,0x1
    80004820:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004824:	6b85                	lui	s7,0x1
    80004826:	c00b8b9b          	addiw	s7,s7,-1024
    8000482a:	a851                	j	800048be <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    8000482c:	6908                	ld	a0,16(a0)
    8000482e:	00000097          	auipc	ra,0x0
    80004832:	254080e7          	jalr	596(ra) # 80004a82 <pipewrite>
    80004836:	a865                	j	800048ee <filewrite+0x110>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004838:	02451783          	lh	a5,36(a0)
    8000483c:	03079693          	slli	a3,a5,0x30
    80004840:	92c1                	srli	a3,a3,0x30
    80004842:	4725                	li	a4,9
    80004844:	0ed76763          	bltu	a4,a3,80004932 <filewrite+0x154>
    80004848:	0792                	slli	a5,a5,0x4
    8000484a:	00020717          	auipc	a4,0x20
    8000484e:	5b670713          	addi	a4,a4,1462 # 80024e00 <devsw>
    80004852:	97ba                	add	a5,a5,a4
    80004854:	679c                	ld	a5,8(a5)
    80004856:	c3e5                	beqz	a5,80004936 <filewrite+0x158>
    ret = devsw[f->major].write(f, 1, addr, n);
    80004858:	86b2                	mv	a3,a2
    8000485a:	862e                	mv	a2,a1
    8000485c:	4585                	li	a1,1
    8000485e:	9782                	jalr	a5
    80004860:	a079                	j	800048ee <filewrite+0x110>
    80004862:	00090c1b          	sext.w	s8,s2
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op(f->ip->dev);
    80004866:	6c9c                	ld	a5,24(s1)
    80004868:	4388                	lw	a0,0(a5)
    8000486a:	fffff097          	auipc	ra,0xfffff
    8000486e:	7d2080e7          	jalr	2002(ra) # 8000403c <begin_op>
      ilock(f->ip);
    80004872:	6c88                	ld	a0,24(s1)
    80004874:	fffff097          	auipc	ra,0xfffff
    80004878:	de2080e7          	jalr	-542(ra) # 80003656 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000487c:	8762                	mv	a4,s8
    8000487e:	5094                	lw	a3,32(s1)
    80004880:	01598633          	add	a2,s3,s5
    80004884:	4585                	li	a1,1
    80004886:	6c88                	ld	a0,24(s1)
    80004888:	fffff097          	auipc	ra,0xfffff
    8000488c:	152080e7          	jalr	338(ra) # 800039da <writei>
    80004890:	892a                	mv	s2,a0
    80004892:	02a05e63          	blez	a0,800048ce <filewrite+0xf0>
        f->off += r;
    80004896:	509c                	lw	a5,32(s1)
    80004898:	9fa9                	addw	a5,a5,a0
    8000489a:	d09c                	sw	a5,32(s1)
      iunlock(f->ip);
    8000489c:	6c88                	ld	a0,24(s1)
    8000489e:	fffff097          	auipc	ra,0xfffff
    800048a2:	e7a080e7          	jalr	-390(ra) # 80003718 <iunlock>
      end_op(f->ip->dev);
    800048a6:	6c9c                	ld	a5,24(s1)
    800048a8:	4388                	lw	a0,0(a5)
    800048aa:	00000097          	auipc	ra,0x0
    800048ae:	83c080e7          	jalr	-1988(ra) # 800040e6 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    800048b2:	052c1a63          	bne	s8,s2,80004906 <filewrite+0x128>
        panic("short filewrite");
      i += r;
    800048b6:	013909bb          	addw	s3,s2,s3
    while(i < n){
    800048ba:	0349d763          	bge	s3,s4,800048e8 <filewrite+0x10a>
      int n1 = n - i;
    800048be:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800048c2:	893e                	mv	s2,a5
    800048c4:	2781                	sext.w	a5,a5
    800048c6:	f8fb5ee3          	bge	s6,a5,80004862 <filewrite+0x84>
    800048ca:	895e                	mv	s2,s7
    800048cc:	bf59                	j	80004862 <filewrite+0x84>
      iunlock(f->ip);
    800048ce:	6c88                	ld	a0,24(s1)
    800048d0:	fffff097          	auipc	ra,0xfffff
    800048d4:	e48080e7          	jalr	-440(ra) # 80003718 <iunlock>
      end_op(f->ip->dev);
    800048d8:	6c9c                	ld	a5,24(s1)
    800048da:	4388                	lw	a0,0(a5)
    800048dc:	00000097          	auipc	ra,0x0
    800048e0:	80a080e7          	jalr	-2038(ra) # 800040e6 <end_op>
      if(r < 0)
    800048e4:	fc0957e3          	bgez	s2,800048b2 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    800048e8:	8552                	mv	a0,s4
    800048ea:	033a1863          	bne	s4,s3,8000491a <filewrite+0x13c>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800048ee:	60a6                	ld	ra,72(sp)
    800048f0:	6406                	ld	s0,64(sp)
    800048f2:	74e2                	ld	s1,56(sp)
    800048f4:	7942                	ld	s2,48(sp)
    800048f6:	79a2                	ld	s3,40(sp)
    800048f8:	7a02                	ld	s4,32(sp)
    800048fa:	6ae2                	ld	s5,24(sp)
    800048fc:	6b42                	ld	s6,16(sp)
    800048fe:	6ba2                	ld	s7,8(sp)
    80004900:	6c02                	ld	s8,0(sp)
    80004902:	6161                	addi	sp,sp,80
    80004904:	8082                	ret
        panic("short filewrite");
    80004906:	00004517          	auipc	a0,0x4
    8000490a:	ed250513          	addi	a0,a0,-302 # 800087d8 <userret+0x748>
    8000490e:	ffffc097          	auipc	ra,0xffffc
    80004912:	c3a080e7          	jalr	-966(ra) # 80000548 <panic>
    int i = 0;
    80004916:	4981                	li	s3,0
    80004918:	bfc1                	j	800048e8 <filewrite+0x10a>
    ret = (i == n ? n : -1);
    8000491a:	557d                	li	a0,-1
    8000491c:	bfc9                	j	800048ee <filewrite+0x110>
    panic("filewrite");
    8000491e:	00004517          	auipc	a0,0x4
    80004922:	eca50513          	addi	a0,a0,-310 # 800087e8 <userret+0x758>
    80004926:	ffffc097          	auipc	ra,0xffffc
    8000492a:	c22080e7          	jalr	-990(ra) # 80000548 <panic>
    return -1;
    8000492e:	557d                	li	a0,-1
}
    80004930:	8082                	ret
      return -1;
    80004932:	557d                	li	a0,-1
    80004934:	bf6d                	j	800048ee <filewrite+0x110>
    80004936:	557d                	li	a0,-1
    80004938:	bf5d                	j	800048ee <filewrite+0x110>

000000008000493a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000493a:	7179                	addi	sp,sp,-48
    8000493c:	f406                	sd	ra,40(sp)
    8000493e:	f022                	sd	s0,32(sp)
    80004940:	ec26                	sd	s1,24(sp)
    80004942:	e84a                	sd	s2,16(sp)
    80004944:	e44e                	sd	s3,8(sp)
    80004946:	e052                	sd	s4,0(sp)
    80004948:	1800                	addi	s0,sp,48
    8000494a:	84aa                	mv	s1,a0
    8000494c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000494e:	0005b023          	sd	zero,0(a1)
    80004952:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004956:	00000097          	auipc	ra,0x0
    8000495a:	bc4080e7          	jalr	-1084(ra) # 8000451a <filealloc>
    8000495e:	e088                	sd	a0,0(s1)
    80004960:	c549                	beqz	a0,800049ea <pipealloc+0xb0>
    80004962:	00000097          	auipc	ra,0x0
    80004966:	bb8080e7          	jalr	-1096(ra) # 8000451a <filealloc>
    8000496a:	00aa3023          	sd	a0,0(s4)
    8000496e:	c925                	beqz	a0,800049de <pipealloc+0xa4>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004970:	ffffc097          	auipc	ra,0xffffc
    80004974:	ff0080e7          	jalr	-16(ra) # 80000960 <kalloc>
    80004978:	892a                	mv	s2,a0
    8000497a:	cd39                	beqz	a0,800049d8 <pipealloc+0x9e>
    goto bad;
  pi->readopen = 1;
    8000497c:	4985                	li	s3,1
    8000497e:	23352423          	sw	s3,552(a0)
  pi->writeopen = 1;
    80004982:	23352623          	sw	s3,556(a0)
  pi->nwrite = 0;
    80004986:	22052223          	sw	zero,548(a0)
  pi->nread = 0;
    8000498a:	22052023          	sw	zero,544(a0)
  memset(&pi->lock, 0, sizeof(pi->lock));
    8000498e:	02000613          	li	a2,32
    80004992:	4581                	li	a1,0
    80004994:	ffffc097          	auipc	ra,0xffffc
    80004998:	3e8080e7          	jalr	1000(ra) # 80000d7c <memset>
  (*f0)->type = FD_PIPE;
    8000499c:	609c                	ld	a5,0(s1)
    8000499e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049a2:	609c                	ld	a5,0(s1)
    800049a4:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049a8:	609c                	ld	a5,0(s1)
    800049aa:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049ae:	609c                	ld	a5,0(s1)
    800049b0:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049b4:	000a3783          	ld	a5,0(s4)
    800049b8:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049bc:	000a3783          	ld	a5,0(s4)
    800049c0:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049c4:	000a3783          	ld	a5,0(s4)
    800049c8:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049cc:	000a3783          	ld	a5,0(s4)
    800049d0:	0127b823          	sd	s2,16(a5)
  return 0;
    800049d4:	4501                	li	a0,0
    800049d6:	a025                	j	800049fe <pipealloc+0xc4>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049d8:	6088                	ld	a0,0(s1)
    800049da:	e501                	bnez	a0,800049e2 <pipealloc+0xa8>
    800049dc:	a039                	j	800049ea <pipealloc+0xb0>
    800049de:	6088                	ld	a0,0(s1)
    800049e0:	c51d                	beqz	a0,80004a0e <pipealloc+0xd4>
    fileclose(*f0);
    800049e2:	00000097          	auipc	ra,0x0
    800049e6:	bf4080e7          	jalr	-1036(ra) # 800045d6 <fileclose>
  if(*f1)
    800049ea:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800049ee:	557d                	li	a0,-1
  if(*f1)
    800049f0:	c799                	beqz	a5,800049fe <pipealloc+0xc4>
    fileclose(*f1);
    800049f2:	853e                	mv	a0,a5
    800049f4:	00000097          	auipc	ra,0x0
    800049f8:	be2080e7          	jalr	-1054(ra) # 800045d6 <fileclose>
  return -1;
    800049fc:	557d                	li	a0,-1
}
    800049fe:	70a2                	ld	ra,40(sp)
    80004a00:	7402                	ld	s0,32(sp)
    80004a02:	64e2                	ld	s1,24(sp)
    80004a04:	6942                	ld	s2,16(sp)
    80004a06:	69a2                	ld	s3,8(sp)
    80004a08:	6a02                	ld	s4,0(sp)
    80004a0a:	6145                	addi	sp,sp,48
    80004a0c:	8082                	ret
  return -1;
    80004a0e:	557d                	li	a0,-1
    80004a10:	b7fd                	j	800049fe <pipealloc+0xc4>

0000000080004a12 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a12:	1101                	addi	sp,sp,-32
    80004a14:	ec06                	sd	ra,24(sp)
    80004a16:	e822                	sd	s0,16(sp)
    80004a18:	e426                	sd	s1,8(sp)
    80004a1a:	e04a                	sd	s2,0(sp)
    80004a1c:	1000                	addi	s0,sp,32
    80004a1e:	84aa                	mv	s1,a0
    80004a20:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a22:	ffffc097          	auipc	ra,0xffffc
    80004a26:	0ec080e7          	jalr	236(ra) # 80000b0e <acquire>
  if(writable){
    80004a2a:	02090d63          	beqz	s2,80004a64 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a2e:	2204a623          	sw	zero,556(s1)
    wakeup(&pi->nread);
    80004a32:	22048513          	addi	a0,s1,544
    80004a36:	ffffe097          	auipc	ra,0xffffe
    80004a3a:	986080e7          	jalr	-1658(ra) # 800023bc <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a3e:	2284b783          	ld	a5,552(s1)
    80004a42:	eb95                	bnez	a5,80004a76 <pipeclose+0x64>
    release(&pi->lock);
    80004a44:	8526                	mv	a0,s1
    80004a46:	ffffc097          	auipc	ra,0xffffc
    80004a4a:	138080e7          	jalr	312(ra) # 80000b7e <release>
    kfree((char*)pi);
    80004a4e:	8526                	mv	a0,s1
    80004a50:	ffffc097          	auipc	ra,0xffffc
    80004a54:	e14080e7          	jalr	-492(ra) # 80000864 <kfree>
  } else
    release(&pi->lock);
}
    80004a58:	60e2                	ld	ra,24(sp)
    80004a5a:	6442                	ld	s0,16(sp)
    80004a5c:	64a2                	ld	s1,8(sp)
    80004a5e:	6902                	ld	s2,0(sp)
    80004a60:	6105                	addi	sp,sp,32
    80004a62:	8082                	ret
    pi->readopen = 0;
    80004a64:	2204a423          	sw	zero,552(s1)
    wakeup(&pi->nwrite);
    80004a68:	22448513          	addi	a0,s1,548
    80004a6c:	ffffe097          	auipc	ra,0xffffe
    80004a70:	950080e7          	jalr	-1712(ra) # 800023bc <wakeup>
    80004a74:	b7e9                	j	80004a3e <pipeclose+0x2c>
    release(&pi->lock);
    80004a76:	8526                	mv	a0,s1
    80004a78:	ffffc097          	auipc	ra,0xffffc
    80004a7c:	106080e7          	jalr	262(ra) # 80000b7e <release>
}
    80004a80:	bfe1                	j	80004a58 <pipeclose+0x46>

0000000080004a82 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a82:	711d                	addi	sp,sp,-96
    80004a84:	ec86                	sd	ra,88(sp)
    80004a86:	e8a2                	sd	s0,80(sp)
    80004a88:	e4a6                	sd	s1,72(sp)
    80004a8a:	e0ca                	sd	s2,64(sp)
    80004a8c:	fc4e                	sd	s3,56(sp)
    80004a8e:	f852                	sd	s4,48(sp)
    80004a90:	f456                	sd	s5,40(sp)
    80004a92:	f05a                	sd	s6,32(sp)
    80004a94:	ec5e                	sd	s7,24(sp)
    80004a96:	e862                	sd	s8,16(sp)
    80004a98:	1080                	addi	s0,sp,96
    80004a9a:	84aa                	mv	s1,a0
    80004a9c:	8aae                	mv	s5,a1
    80004a9e:	8a32                	mv	s4,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004aa0:	ffffd097          	auipc	ra,0xffffd
    80004aa4:	fc6080e7          	jalr	-58(ra) # 80001a66 <myproc>
    80004aa8:	8baa                	mv	s7,a0

  acquire(&pi->lock);
    80004aaa:	8526                	mv	a0,s1
    80004aac:	ffffc097          	auipc	ra,0xffffc
    80004ab0:	062080e7          	jalr	98(ra) # 80000b0e <acquire>
  for(i = 0; i < n; i++){
    80004ab4:	09405f63          	blez	s4,80004b52 <pipewrite+0xd0>
    80004ab8:	fffa0b1b          	addiw	s6,s4,-1
    80004abc:	1b02                	slli	s6,s6,0x20
    80004abe:	020b5b13          	srli	s6,s6,0x20
    80004ac2:	001a8793          	addi	a5,s5,1
    80004ac6:	9b3e                	add	s6,s6,a5
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || myproc()->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004ac8:	22048993          	addi	s3,s1,544
      sleep(&pi->nwrite, &pi->lock);
    80004acc:	22448913          	addi	s2,s1,548
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ad0:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004ad2:	2204a783          	lw	a5,544(s1)
    80004ad6:	2244a703          	lw	a4,548(s1)
    80004ada:	2007879b          	addiw	a5,a5,512
    80004ade:	02f71e63          	bne	a4,a5,80004b1a <pipewrite+0x98>
      if(pi->readopen == 0 || myproc()->killed){
    80004ae2:	2284a783          	lw	a5,552(s1)
    80004ae6:	c3d9                	beqz	a5,80004b6c <pipewrite+0xea>
    80004ae8:	ffffd097          	auipc	ra,0xffffd
    80004aec:	f7e080e7          	jalr	-130(ra) # 80001a66 <myproc>
    80004af0:	5d1c                	lw	a5,56(a0)
    80004af2:	efad                	bnez	a5,80004b6c <pipewrite+0xea>
      wakeup(&pi->nread);
    80004af4:	854e                	mv	a0,s3
    80004af6:	ffffe097          	auipc	ra,0xffffe
    80004afa:	8c6080e7          	jalr	-1850(ra) # 800023bc <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004afe:	85a6                	mv	a1,s1
    80004b00:	854a                	mv	a0,s2
    80004b02:	ffffd097          	auipc	ra,0xffffd
    80004b06:	73a080e7          	jalr	1850(ra) # 8000223c <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b0a:	2204a783          	lw	a5,544(s1)
    80004b0e:	2244a703          	lw	a4,548(s1)
    80004b12:	2007879b          	addiw	a5,a5,512
    80004b16:	fcf706e3          	beq	a4,a5,80004ae2 <pipewrite+0x60>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b1a:	4685                	li	a3,1
    80004b1c:	8656                	mv	a2,s5
    80004b1e:	faf40593          	addi	a1,s0,-81
    80004b22:	058bb503          	ld	a0,88(s7) # 1058 <_entry-0x7fffefa8>
    80004b26:	ffffd097          	auipc	ra,0xffffd
    80004b2a:	cbe080e7          	jalr	-834(ra) # 800017e4 <copyin>
    80004b2e:	03850263          	beq	a0,s8,80004b52 <pipewrite+0xd0>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b32:	2244a783          	lw	a5,548(s1)
    80004b36:	0017871b          	addiw	a4,a5,1
    80004b3a:	22e4a223          	sw	a4,548(s1)
    80004b3e:	1ff7f793          	andi	a5,a5,511
    80004b42:	97a6                	add	a5,a5,s1
    80004b44:	faf44703          	lbu	a4,-81(s0)
    80004b48:	02e78023          	sb	a4,32(a5)
  for(i = 0; i < n; i++){
    80004b4c:	0a85                	addi	s5,s5,1
    80004b4e:	f96a92e3          	bne	s5,s6,80004ad2 <pipewrite+0x50>
  }
  wakeup(&pi->nread);
    80004b52:	22048513          	addi	a0,s1,544
    80004b56:	ffffe097          	auipc	ra,0xffffe
    80004b5a:	866080e7          	jalr	-1946(ra) # 800023bc <wakeup>
  release(&pi->lock);
    80004b5e:	8526                	mv	a0,s1
    80004b60:	ffffc097          	auipc	ra,0xffffc
    80004b64:	01e080e7          	jalr	30(ra) # 80000b7e <release>
  return n;
    80004b68:	8552                	mv	a0,s4
    80004b6a:	a039                	j	80004b78 <pipewrite+0xf6>
        release(&pi->lock);
    80004b6c:	8526                	mv	a0,s1
    80004b6e:	ffffc097          	auipc	ra,0xffffc
    80004b72:	010080e7          	jalr	16(ra) # 80000b7e <release>
        return -1;
    80004b76:	557d                	li	a0,-1
}
    80004b78:	60e6                	ld	ra,88(sp)
    80004b7a:	6446                	ld	s0,80(sp)
    80004b7c:	64a6                	ld	s1,72(sp)
    80004b7e:	6906                	ld	s2,64(sp)
    80004b80:	79e2                	ld	s3,56(sp)
    80004b82:	7a42                	ld	s4,48(sp)
    80004b84:	7aa2                	ld	s5,40(sp)
    80004b86:	7b02                	ld	s6,32(sp)
    80004b88:	6be2                	ld	s7,24(sp)
    80004b8a:	6c42                	ld	s8,16(sp)
    80004b8c:	6125                	addi	sp,sp,96
    80004b8e:	8082                	ret

0000000080004b90 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b90:	715d                	addi	sp,sp,-80
    80004b92:	e486                	sd	ra,72(sp)
    80004b94:	e0a2                	sd	s0,64(sp)
    80004b96:	fc26                	sd	s1,56(sp)
    80004b98:	f84a                	sd	s2,48(sp)
    80004b9a:	f44e                	sd	s3,40(sp)
    80004b9c:	f052                	sd	s4,32(sp)
    80004b9e:	ec56                	sd	s5,24(sp)
    80004ba0:	e85a                	sd	s6,16(sp)
    80004ba2:	0880                	addi	s0,sp,80
    80004ba4:	84aa                	mv	s1,a0
    80004ba6:	892e                	mv	s2,a1
    80004ba8:	8a32                	mv	s4,a2
  int i;
  struct proc *pr = myproc();
    80004baa:	ffffd097          	auipc	ra,0xffffd
    80004bae:	ebc080e7          	jalr	-324(ra) # 80001a66 <myproc>
    80004bb2:	8aaa                	mv	s5,a0
  char ch;

  acquire(&pi->lock);
    80004bb4:	8526                	mv	a0,s1
    80004bb6:	ffffc097          	auipc	ra,0xffffc
    80004bba:	f58080e7          	jalr	-168(ra) # 80000b0e <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bbe:	2204a703          	lw	a4,544(s1)
    80004bc2:	2244a783          	lw	a5,548(s1)
    if(myproc()->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bc6:	22048993          	addi	s3,s1,544
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bca:	02f71763          	bne	a4,a5,80004bf8 <piperead+0x68>
    80004bce:	22c4a783          	lw	a5,556(s1)
    80004bd2:	c39d                	beqz	a5,80004bf8 <piperead+0x68>
    if(myproc()->killed){
    80004bd4:	ffffd097          	auipc	ra,0xffffd
    80004bd8:	e92080e7          	jalr	-366(ra) # 80001a66 <myproc>
    80004bdc:	5d1c                	lw	a5,56(a0)
    80004bde:	ebc1                	bnez	a5,80004c6e <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004be0:	85a6                	mv	a1,s1
    80004be2:	854e                	mv	a0,s3
    80004be4:	ffffd097          	auipc	ra,0xffffd
    80004be8:	658080e7          	jalr	1624(ra) # 8000223c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bec:	2204a703          	lw	a4,544(s1)
    80004bf0:	2244a783          	lw	a5,548(s1)
    80004bf4:	fcf70de3          	beq	a4,a5,80004bce <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bf8:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bfa:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bfc:	05405363          	blez	s4,80004c42 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004c00:	2204a783          	lw	a5,544(s1)
    80004c04:	2244a703          	lw	a4,548(s1)
    80004c08:	02f70d63          	beq	a4,a5,80004c42 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c0c:	0017871b          	addiw	a4,a5,1
    80004c10:	22e4a023          	sw	a4,544(s1)
    80004c14:	1ff7f793          	andi	a5,a5,511
    80004c18:	97a6                	add	a5,a5,s1
    80004c1a:	0207c783          	lbu	a5,32(a5)
    80004c1e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c22:	4685                	li	a3,1
    80004c24:	fbf40613          	addi	a2,s0,-65
    80004c28:	85ca                	mv	a1,s2
    80004c2a:	058ab503          	ld	a0,88(s5)
    80004c2e:	ffffd097          	auipc	ra,0xffffd
    80004c32:	b2a080e7          	jalr	-1238(ra) # 80001758 <copyout>
    80004c36:	01650663          	beq	a0,s6,80004c42 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c3a:	2985                	addiw	s3,s3,1
    80004c3c:	0905                	addi	s2,s2,1
    80004c3e:	fd3a11e3          	bne	s4,s3,80004c00 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c42:	22448513          	addi	a0,s1,548
    80004c46:	ffffd097          	auipc	ra,0xffffd
    80004c4a:	776080e7          	jalr	1910(ra) # 800023bc <wakeup>
  release(&pi->lock);
    80004c4e:	8526                	mv	a0,s1
    80004c50:	ffffc097          	auipc	ra,0xffffc
    80004c54:	f2e080e7          	jalr	-210(ra) # 80000b7e <release>
  return i;
}
    80004c58:	854e                	mv	a0,s3
    80004c5a:	60a6                	ld	ra,72(sp)
    80004c5c:	6406                	ld	s0,64(sp)
    80004c5e:	74e2                	ld	s1,56(sp)
    80004c60:	7942                	ld	s2,48(sp)
    80004c62:	79a2                	ld	s3,40(sp)
    80004c64:	7a02                	ld	s4,32(sp)
    80004c66:	6ae2                	ld	s5,24(sp)
    80004c68:	6b42                	ld	s6,16(sp)
    80004c6a:	6161                	addi	sp,sp,80
    80004c6c:	8082                	ret
      release(&pi->lock);
    80004c6e:	8526                	mv	a0,s1
    80004c70:	ffffc097          	auipc	ra,0xffffc
    80004c74:	f0e080e7          	jalr	-242(ra) # 80000b7e <release>
      return -1;
    80004c78:	59fd                	li	s3,-1
    80004c7a:	bff9                	j	80004c58 <piperead+0xc8>

0000000080004c7c <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c7c:	de010113          	addi	sp,sp,-544
    80004c80:	20113c23          	sd	ra,536(sp)
    80004c84:	20813823          	sd	s0,528(sp)
    80004c88:	20913423          	sd	s1,520(sp)
    80004c8c:	21213023          	sd	s2,512(sp)
    80004c90:	ffce                	sd	s3,504(sp)
    80004c92:	fbd2                	sd	s4,496(sp)
    80004c94:	f7d6                	sd	s5,488(sp)
    80004c96:	f3da                	sd	s6,480(sp)
    80004c98:	efde                	sd	s7,472(sp)
    80004c9a:	ebe2                	sd	s8,464(sp)
    80004c9c:	e7e6                	sd	s9,456(sp)
    80004c9e:	e3ea                	sd	s10,448(sp)
    80004ca0:	ff6e                	sd	s11,440(sp)
    80004ca2:	1400                	addi	s0,sp,544
    80004ca4:	892a                	mv	s2,a0
    80004ca6:	dea43423          	sd	a0,-536(s0)
    80004caa:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cae:	ffffd097          	auipc	ra,0xffffd
    80004cb2:	db8080e7          	jalr	-584(ra) # 80001a66 <myproc>
    80004cb6:	84aa                	mv	s1,a0

  begin_op(ROOTDEV);
    80004cb8:	4501                	li	a0,0
    80004cba:	fffff097          	auipc	ra,0xfffff
    80004cbe:	382080e7          	jalr	898(ra) # 8000403c <begin_op>

  if((ip = namei(path)) == 0){
    80004cc2:	854a                	mv	a0,s2
    80004cc4:	fffff097          	auipc	ra,0xfffff
    80004cc8:	11c080e7          	jalr	284(ra) # 80003de0 <namei>
    80004ccc:	cd25                	beqz	a0,80004d44 <exec+0xc8>
    80004cce:	8aaa                	mv	s5,a0
    end_op(ROOTDEV);
    return -1;
  }
  ilock(ip);
    80004cd0:	fffff097          	auipc	ra,0xfffff
    80004cd4:	986080e7          	jalr	-1658(ra) # 80003656 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004cd8:	04000713          	li	a4,64
    80004cdc:	4681                	li	a3,0
    80004cde:	e4840613          	addi	a2,s0,-440
    80004ce2:	4581                	li	a1,0
    80004ce4:	8556                	mv	a0,s5
    80004ce6:	fffff097          	auipc	ra,0xfffff
    80004cea:	c00080e7          	jalr	-1024(ra) # 800038e6 <readi>
    80004cee:	04000793          	li	a5,64
    80004cf2:	00f51a63          	bne	a0,a5,80004d06 <exec+0x8a>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004cf6:	e4842703          	lw	a4,-440(s0)
    80004cfa:	464c47b7          	lui	a5,0x464c4
    80004cfe:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d02:	04f70863          	beq	a4,a5,80004d52 <exec+0xd6>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d06:	8556                	mv	a0,s5
    80004d08:	fffff097          	auipc	ra,0xfffff
    80004d0c:	b8c080e7          	jalr	-1140(ra) # 80003894 <iunlockput>
    end_op(ROOTDEV);
    80004d10:	4501                	li	a0,0
    80004d12:	fffff097          	auipc	ra,0xfffff
    80004d16:	3d4080e7          	jalr	980(ra) # 800040e6 <end_op>
  }
  return -1;
    80004d1a:	557d                	li	a0,-1
}
    80004d1c:	21813083          	ld	ra,536(sp)
    80004d20:	21013403          	ld	s0,528(sp)
    80004d24:	20813483          	ld	s1,520(sp)
    80004d28:	20013903          	ld	s2,512(sp)
    80004d2c:	79fe                	ld	s3,504(sp)
    80004d2e:	7a5e                	ld	s4,496(sp)
    80004d30:	7abe                	ld	s5,488(sp)
    80004d32:	7b1e                	ld	s6,480(sp)
    80004d34:	6bfe                	ld	s7,472(sp)
    80004d36:	6c5e                	ld	s8,464(sp)
    80004d38:	6cbe                	ld	s9,456(sp)
    80004d3a:	6d1e                	ld	s10,448(sp)
    80004d3c:	7dfa                	ld	s11,440(sp)
    80004d3e:	22010113          	addi	sp,sp,544
    80004d42:	8082                	ret
    end_op(ROOTDEV);
    80004d44:	4501                	li	a0,0
    80004d46:	fffff097          	auipc	ra,0xfffff
    80004d4a:	3a0080e7          	jalr	928(ra) # 800040e6 <end_op>
    return -1;
    80004d4e:	557d                	li	a0,-1
    80004d50:	b7f1                	j	80004d1c <exec+0xa0>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d52:	8526                	mv	a0,s1
    80004d54:	ffffd097          	auipc	ra,0xffffd
    80004d58:	dd6080e7          	jalr	-554(ra) # 80001b2a <proc_pagetable>
    80004d5c:	8b2a                	mv	s6,a0
    80004d5e:	d545                	beqz	a0,80004d06 <exec+0x8a>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d60:	e6842783          	lw	a5,-408(s0)
    80004d64:	e8045703          	lhu	a4,-384(s0)
    80004d68:	10070263          	beqz	a4,80004e6c <exec+0x1f0>
  sz = 0;
    80004d6c:	de043c23          	sd	zero,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d70:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004d74:	6a05                	lui	s4,0x1
    80004d76:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004d7a:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004d7e:	6d85                	lui	s11,0x1
    80004d80:	7d7d                	lui	s10,0xfffff
    80004d82:	a88d                	j	80004df4 <exec+0x178>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d84:	00004517          	auipc	a0,0x4
    80004d88:	a7450513          	addi	a0,a0,-1420 # 800087f8 <userret+0x768>
    80004d8c:	ffffb097          	auipc	ra,0xffffb
    80004d90:	7bc080e7          	jalr	1980(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d94:	874a                	mv	a4,s2
    80004d96:	009c86bb          	addw	a3,s9,s1
    80004d9a:	4581                	li	a1,0
    80004d9c:	8556                	mv	a0,s5
    80004d9e:	fffff097          	auipc	ra,0xfffff
    80004da2:	b48080e7          	jalr	-1208(ra) # 800038e6 <readi>
    80004da6:	2501                	sext.w	a0,a0
    80004da8:	10a91863          	bne	s2,a0,80004eb8 <exec+0x23c>
  for(i = 0; i < sz; i += PGSIZE){
    80004dac:	009d84bb          	addw	s1,s11,s1
    80004db0:	013d09bb          	addw	s3,s10,s3
    80004db4:	0374f263          	bgeu	s1,s7,80004dd8 <exec+0x15c>
    pa = walkaddr(pagetable, va + i);
    80004db8:	02049593          	slli	a1,s1,0x20
    80004dbc:	9181                	srli	a1,a1,0x20
    80004dbe:	95e2                	add	a1,a1,s8
    80004dc0:	855a                	mv	a0,s6
    80004dc2:	ffffc097          	auipc	ra,0xffffc
    80004dc6:	3b4080e7          	jalr	948(ra) # 80001176 <walkaddr>
    80004dca:	862a                	mv	a2,a0
    if(pa == 0)
    80004dcc:	dd45                	beqz	a0,80004d84 <exec+0x108>
      n = PGSIZE;
    80004dce:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004dd0:	fd49f2e3          	bgeu	s3,s4,80004d94 <exec+0x118>
      n = sz - i;
    80004dd4:	894e                	mv	s2,s3
    80004dd6:	bf7d                	j	80004d94 <exec+0x118>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dd8:	e0843783          	ld	a5,-504(s0)
    80004ddc:	0017869b          	addiw	a3,a5,1
    80004de0:	e0d43423          	sd	a3,-504(s0)
    80004de4:	e0043783          	ld	a5,-512(s0)
    80004de8:	0387879b          	addiw	a5,a5,56
    80004dec:	e8045703          	lhu	a4,-384(s0)
    80004df0:	08e6d063          	bge	a3,a4,80004e70 <exec+0x1f4>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004df4:	2781                	sext.w	a5,a5
    80004df6:	e0f43023          	sd	a5,-512(s0)
    80004dfa:	03800713          	li	a4,56
    80004dfe:	86be                	mv	a3,a5
    80004e00:	e1040613          	addi	a2,s0,-496
    80004e04:	4581                	li	a1,0
    80004e06:	8556                	mv	a0,s5
    80004e08:	fffff097          	auipc	ra,0xfffff
    80004e0c:	ade080e7          	jalr	-1314(ra) # 800038e6 <readi>
    80004e10:	03800793          	li	a5,56
    80004e14:	0af51263          	bne	a0,a5,80004eb8 <exec+0x23c>
    if(ph.type != ELF_PROG_LOAD)
    80004e18:	e1042783          	lw	a5,-496(s0)
    80004e1c:	4705                	li	a4,1
    80004e1e:	fae79de3          	bne	a5,a4,80004dd8 <exec+0x15c>
    if(ph.memsz < ph.filesz)
    80004e22:	e3843603          	ld	a2,-456(s0)
    80004e26:	e3043783          	ld	a5,-464(s0)
    80004e2a:	08f66763          	bltu	a2,a5,80004eb8 <exec+0x23c>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004e2e:	e2043783          	ld	a5,-480(s0)
    80004e32:	963e                	add	a2,a2,a5
    80004e34:	08f66263          	bltu	a2,a5,80004eb8 <exec+0x23c>
    if((sz = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e38:	df843583          	ld	a1,-520(s0)
    80004e3c:	855a                	mv	a0,s6
    80004e3e:	ffffc097          	auipc	ra,0xffffc
    80004e42:	740080e7          	jalr	1856(ra) # 8000157e <uvmalloc>
    80004e46:	dea43c23          	sd	a0,-520(s0)
    80004e4a:	c53d                	beqz	a0,80004eb8 <exec+0x23c>
    if(ph.vaddr % PGSIZE != 0)
    80004e4c:	e2043c03          	ld	s8,-480(s0)
    80004e50:	de043783          	ld	a5,-544(s0)
    80004e54:	00fc77b3          	and	a5,s8,a5
    80004e58:	e3a5                	bnez	a5,80004eb8 <exec+0x23c>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004e5a:	e1842c83          	lw	s9,-488(s0)
    80004e5e:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004e62:	f60b8be3          	beqz	s7,80004dd8 <exec+0x15c>
    80004e66:	89de                	mv	s3,s7
    80004e68:	4481                	li	s1,0
    80004e6a:	b7b9                	j	80004db8 <exec+0x13c>
  sz = 0;
    80004e6c:	de043c23          	sd	zero,-520(s0)
  iunlockput(ip);
    80004e70:	8556                	mv	a0,s5
    80004e72:	fffff097          	auipc	ra,0xfffff
    80004e76:	a22080e7          	jalr	-1502(ra) # 80003894 <iunlockput>
  end_op(ROOTDEV);
    80004e7a:	4501                	li	a0,0
    80004e7c:	fffff097          	auipc	ra,0xfffff
    80004e80:	26a080e7          	jalr	618(ra) # 800040e6 <end_op>
  p = myproc();
    80004e84:	ffffd097          	auipc	ra,0xffffd
    80004e88:	be2080e7          	jalr	-1054(ra) # 80001a66 <myproc>
    80004e8c:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004e8e:	05053c83          	ld	s9,80(a0)
  sz = PGROUNDUP(sz);
    80004e92:	6585                	lui	a1,0x1
    80004e94:	15fd                	addi	a1,a1,-1
    80004e96:	df843783          	ld	a5,-520(s0)
    80004e9a:	95be                	add	a1,a1,a5
    80004e9c:	77fd                	lui	a5,0xfffff
    80004e9e:	8dfd                	and	a1,a1,a5
  if((sz = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ea0:	6609                	lui	a2,0x2
    80004ea2:	962e                	add	a2,a2,a1
    80004ea4:	855a                	mv	a0,s6
    80004ea6:	ffffc097          	auipc	ra,0xffffc
    80004eaa:	6d8080e7          	jalr	1752(ra) # 8000157e <uvmalloc>
    80004eae:	892a                	mv	s2,a0
    80004eb0:	dea43c23          	sd	a0,-520(s0)
  ip = 0;
    80004eb4:	4a81                	li	s5,0
  if((sz = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004eb6:	ed01                	bnez	a0,80004ece <exec+0x252>
    proc_freepagetable(pagetable, sz);
    80004eb8:	df843583          	ld	a1,-520(s0)
    80004ebc:	855a                	mv	a0,s6
    80004ebe:	ffffd097          	auipc	ra,0xffffd
    80004ec2:	d6c080e7          	jalr	-660(ra) # 80001c2a <proc_freepagetable>
  if(ip){
    80004ec6:	e40a90e3          	bnez	s5,80004d06 <exec+0x8a>
  return -1;
    80004eca:	557d                	li	a0,-1
    80004ecc:	bd81                	j	80004d1c <exec+0xa0>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004ece:	75f9                	lui	a1,0xffffe
    80004ed0:	95aa                	add	a1,a1,a0
    80004ed2:	855a                	mv	a0,s6
    80004ed4:	ffffd097          	auipc	ra,0xffffd
    80004ed8:	852080e7          	jalr	-1966(ra) # 80001726 <uvmclear>
  stackbase = sp - PGSIZE;
    80004edc:	7c7d                	lui	s8,0xfffff
    80004ede:	9c4a                	add	s8,s8,s2
  for(argc = 0; argv[argc]; argc++) {
    80004ee0:	df043783          	ld	a5,-528(s0)
    80004ee4:	6388                	ld	a0,0(a5)
    80004ee6:	c52d                	beqz	a0,80004f50 <exec+0x2d4>
    80004ee8:	e8840993          	addi	s3,s0,-376
    80004eec:	f8840a93          	addi	s5,s0,-120
    80004ef0:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004ef2:	ffffc097          	auipc	ra,0xffffc
    80004ef6:	00e080e7          	jalr	14(ra) # 80000f00 <strlen>
    80004efa:	0015079b          	addiw	a5,a0,1
    80004efe:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f02:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f06:	0f896b63          	bltu	s2,s8,80004ffc <exec+0x380>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f0a:	df043d03          	ld	s10,-528(s0)
    80004f0e:	000d3a03          	ld	s4,0(s10) # fffffffffffff000 <end+0xffffffff7ffd2fa4>
    80004f12:	8552                	mv	a0,s4
    80004f14:	ffffc097          	auipc	ra,0xffffc
    80004f18:	fec080e7          	jalr	-20(ra) # 80000f00 <strlen>
    80004f1c:	0015069b          	addiw	a3,a0,1
    80004f20:	8652                	mv	a2,s4
    80004f22:	85ca                	mv	a1,s2
    80004f24:	855a                	mv	a0,s6
    80004f26:	ffffd097          	auipc	ra,0xffffd
    80004f2a:	832080e7          	jalr	-1998(ra) # 80001758 <copyout>
    80004f2e:	0c054963          	bltz	a0,80005000 <exec+0x384>
    ustack[argc] = sp;
    80004f32:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f36:	0485                	addi	s1,s1,1
    80004f38:	008d0793          	addi	a5,s10,8
    80004f3c:	def43823          	sd	a5,-528(s0)
    80004f40:	008d3503          	ld	a0,8(s10)
    80004f44:	c909                	beqz	a0,80004f56 <exec+0x2da>
    if(argc >= MAXARG)
    80004f46:	09a1                	addi	s3,s3,8
    80004f48:	fb3a95e3          	bne	s5,s3,80004ef2 <exec+0x276>
  ip = 0;
    80004f4c:	4a81                	li	s5,0
    80004f4e:	b7ad                	j	80004eb8 <exec+0x23c>
  sp = sz;
    80004f50:	df843903          	ld	s2,-520(s0)
  for(argc = 0; argv[argc]; argc++) {
    80004f54:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f56:	00349793          	slli	a5,s1,0x3
    80004f5a:	f9040713          	addi	a4,s0,-112
    80004f5e:	97ba                	add	a5,a5,a4
    80004f60:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd2e9c>
  sp -= (argc+1) * sizeof(uint64);
    80004f64:	00148693          	addi	a3,s1,1
    80004f68:	068e                	slli	a3,a3,0x3
    80004f6a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f6e:	ff097913          	andi	s2,s2,-16
  ip = 0;
    80004f72:	4a81                	li	s5,0
  if(sp < stackbase)
    80004f74:	f58962e3          	bltu	s2,s8,80004eb8 <exec+0x23c>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f78:	e8840613          	addi	a2,s0,-376
    80004f7c:	85ca                	mv	a1,s2
    80004f7e:	855a                	mv	a0,s6
    80004f80:	ffffc097          	auipc	ra,0xffffc
    80004f84:	7d8080e7          	jalr	2008(ra) # 80001758 <copyout>
    80004f88:	06054e63          	bltz	a0,80005004 <exec+0x388>
  p->tf->a1 = sp;
    80004f8c:	060bb783          	ld	a5,96(s7)
    80004f90:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f94:	de843783          	ld	a5,-536(s0)
    80004f98:	0007c703          	lbu	a4,0(a5)
    80004f9c:	cf11                	beqz	a4,80004fb8 <exec+0x33c>
    80004f9e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004fa0:	02f00693          	li	a3,47
    80004fa4:	a039                	j	80004fb2 <exec+0x336>
      last = s+1;
    80004fa6:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004faa:	0785                	addi	a5,a5,1
    80004fac:	fff7c703          	lbu	a4,-1(a5)
    80004fb0:	c701                	beqz	a4,80004fb8 <exec+0x33c>
    if(*s == '/')
    80004fb2:	fed71ce3          	bne	a4,a3,80004faa <exec+0x32e>
    80004fb6:	bfc5                	j	80004fa6 <exec+0x32a>
  safestrcpy(p->name, last, sizeof(p->name));
    80004fb8:	4641                	li	a2,16
    80004fba:	de843583          	ld	a1,-536(s0)
    80004fbe:	160b8513          	addi	a0,s7,352
    80004fc2:	ffffc097          	auipc	ra,0xffffc
    80004fc6:	f0c080e7          	jalr	-244(ra) # 80000ece <safestrcpy>
  oldpagetable = p->pagetable;
    80004fca:	058bb503          	ld	a0,88(s7)
  p->pagetable = pagetable;
    80004fce:	056bbc23          	sd	s6,88(s7)
  p->sz = sz;
    80004fd2:	df843783          	ld	a5,-520(s0)
    80004fd6:	04fbb823          	sd	a5,80(s7)
  p->tf->epc = elf.entry;  // initial program counter = main
    80004fda:	060bb783          	ld	a5,96(s7)
    80004fde:	e6043703          	ld	a4,-416(s0)
    80004fe2:	ef98                	sd	a4,24(a5)
  p->tf->sp = sp; // initial stack pointer
    80004fe4:	060bb783          	ld	a5,96(s7)
    80004fe8:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004fec:	85e6                	mv	a1,s9
    80004fee:	ffffd097          	auipc	ra,0xffffd
    80004ff2:	c3c080e7          	jalr	-964(ra) # 80001c2a <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004ff6:	0004851b          	sext.w	a0,s1
    80004ffa:	b30d                	j	80004d1c <exec+0xa0>
  ip = 0;
    80004ffc:	4a81                	li	s5,0
    80004ffe:	bd6d                	j	80004eb8 <exec+0x23c>
    80005000:	4a81                	li	s5,0
    80005002:	bd5d                	j	80004eb8 <exec+0x23c>
    80005004:	4a81                	li	s5,0
    80005006:	bd4d                	j	80004eb8 <exec+0x23c>

0000000080005008 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005008:	7179                	addi	sp,sp,-48
    8000500a:	f406                	sd	ra,40(sp)
    8000500c:	f022                	sd	s0,32(sp)
    8000500e:	ec26                	sd	s1,24(sp)
    80005010:	e84a                	sd	s2,16(sp)
    80005012:	1800                	addi	s0,sp,48
    80005014:	892e                	mv	s2,a1
    80005016:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005018:	fdc40593          	addi	a1,s0,-36
    8000501c:	ffffe097          	auipc	ra,0xffffe
    80005020:	ac4080e7          	jalr	-1340(ra) # 80002ae0 <argint>
    80005024:	04054063          	bltz	a0,80005064 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005028:	fdc42703          	lw	a4,-36(s0)
    8000502c:	47bd                	li	a5,15
    8000502e:	02e7ed63          	bltu	a5,a4,80005068 <argfd+0x60>
    80005032:	ffffd097          	auipc	ra,0xffffd
    80005036:	a34080e7          	jalr	-1484(ra) # 80001a66 <myproc>
    8000503a:	fdc42703          	lw	a4,-36(s0)
    8000503e:	01a70793          	addi	a5,a4,26
    80005042:	078e                	slli	a5,a5,0x3
    80005044:	953e                	add	a0,a0,a5
    80005046:	651c                	ld	a5,8(a0)
    80005048:	c395                	beqz	a5,8000506c <argfd+0x64>
    return -1;
  if(pfd)
    8000504a:	00090463          	beqz	s2,80005052 <argfd+0x4a>
    *pfd = fd;
    8000504e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005052:	4501                	li	a0,0
  if(pf)
    80005054:	c091                	beqz	s1,80005058 <argfd+0x50>
    *pf = f;
    80005056:	e09c                	sd	a5,0(s1)
}
    80005058:	70a2                	ld	ra,40(sp)
    8000505a:	7402                	ld	s0,32(sp)
    8000505c:	64e2                	ld	s1,24(sp)
    8000505e:	6942                	ld	s2,16(sp)
    80005060:	6145                	addi	sp,sp,48
    80005062:	8082                	ret
    return -1;
    80005064:	557d                	li	a0,-1
    80005066:	bfcd                	j	80005058 <argfd+0x50>
    return -1;
    80005068:	557d                	li	a0,-1
    8000506a:	b7fd                	j	80005058 <argfd+0x50>
    8000506c:	557d                	li	a0,-1
    8000506e:	b7ed                	j	80005058 <argfd+0x50>

0000000080005070 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005070:	1101                	addi	sp,sp,-32
    80005072:	ec06                	sd	ra,24(sp)
    80005074:	e822                	sd	s0,16(sp)
    80005076:	e426                	sd	s1,8(sp)
    80005078:	1000                	addi	s0,sp,32
    8000507a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000507c:	ffffd097          	auipc	ra,0xffffd
    80005080:	9ea080e7          	jalr	-1558(ra) # 80001a66 <myproc>
    80005084:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005086:	0d850793          	addi	a5,a0,216
    8000508a:	4501                	li	a0,0
    8000508c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000508e:	6398                	ld	a4,0(a5)
    80005090:	cb19                	beqz	a4,800050a6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005092:	2505                	addiw	a0,a0,1
    80005094:	07a1                	addi	a5,a5,8
    80005096:	fed51ce3          	bne	a0,a3,8000508e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000509a:	557d                	li	a0,-1
}
    8000509c:	60e2                	ld	ra,24(sp)
    8000509e:	6442                	ld	s0,16(sp)
    800050a0:	64a2                	ld	s1,8(sp)
    800050a2:	6105                	addi	sp,sp,32
    800050a4:	8082                	ret
      p->ofile[fd] = f;
    800050a6:	01a50793          	addi	a5,a0,26
    800050aa:	078e                	slli	a5,a5,0x3
    800050ac:	963e                	add	a2,a2,a5
    800050ae:	e604                	sd	s1,8(a2)
      return fd;
    800050b0:	b7f5                	j	8000509c <fdalloc+0x2c>

00000000800050b2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050b2:	715d                	addi	sp,sp,-80
    800050b4:	e486                	sd	ra,72(sp)
    800050b6:	e0a2                	sd	s0,64(sp)
    800050b8:	fc26                	sd	s1,56(sp)
    800050ba:	f84a                	sd	s2,48(sp)
    800050bc:	f44e                	sd	s3,40(sp)
    800050be:	f052                	sd	s4,32(sp)
    800050c0:	ec56                	sd	s5,24(sp)
    800050c2:	0880                	addi	s0,sp,80
    800050c4:	89ae                	mv	s3,a1
    800050c6:	8ab2                	mv	s5,a2
    800050c8:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050ca:	fb040593          	addi	a1,s0,-80
    800050ce:	fffff097          	auipc	ra,0xfffff
    800050d2:	d30080e7          	jalr	-720(ra) # 80003dfe <nameiparent>
    800050d6:	892a                	mv	s2,a0
    800050d8:	12050e63          	beqz	a0,80005214 <create+0x162>
    return 0;

  ilock(dp);
    800050dc:	ffffe097          	auipc	ra,0xffffe
    800050e0:	57a080e7          	jalr	1402(ra) # 80003656 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800050e4:	4601                	li	a2,0
    800050e6:	fb040593          	addi	a1,s0,-80
    800050ea:	854a                	mv	a0,s2
    800050ec:	fffff097          	auipc	ra,0xfffff
    800050f0:	a22080e7          	jalr	-1502(ra) # 80003b0e <dirlookup>
    800050f4:	84aa                	mv	s1,a0
    800050f6:	c921                	beqz	a0,80005146 <create+0x94>
    iunlockput(dp);
    800050f8:	854a                	mv	a0,s2
    800050fa:	ffffe097          	auipc	ra,0xffffe
    800050fe:	79a080e7          	jalr	1946(ra) # 80003894 <iunlockput>
    ilock(ip);
    80005102:	8526                	mv	a0,s1
    80005104:	ffffe097          	auipc	ra,0xffffe
    80005108:	552080e7          	jalr	1362(ra) # 80003656 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000510c:	2981                	sext.w	s3,s3
    8000510e:	4789                	li	a5,2
    80005110:	02f99463          	bne	s3,a5,80005138 <create+0x86>
    80005114:	04c4d783          	lhu	a5,76(s1)
    80005118:	37f9                	addiw	a5,a5,-2
    8000511a:	17c2                	slli	a5,a5,0x30
    8000511c:	93c1                	srli	a5,a5,0x30
    8000511e:	4705                	li	a4,1
    80005120:	00f76c63          	bltu	a4,a5,80005138 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005124:	8526                	mv	a0,s1
    80005126:	60a6                	ld	ra,72(sp)
    80005128:	6406                	ld	s0,64(sp)
    8000512a:	74e2                	ld	s1,56(sp)
    8000512c:	7942                	ld	s2,48(sp)
    8000512e:	79a2                	ld	s3,40(sp)
    80005130:	7a02                	ld	s4,32(sp)
    80005132:	6ae2                	ld	s5,24(sp)
    80005134:	6161                	addi	sp,sp,80
    80005136:	8082                	ret
    iunlockput(ip);
    80005138:	8526                	mv	a0,s1
    8000513a:	ffffe097          	auipc	ra,0xffffe
    8000513e:	75a080e7          	jalr	1882(ra) # 80003894 <iunlockput>
    return 0;
    80005142:	4481                	li	s1,0
    80005144:	b7c5                	j	80005124 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005146:	85ce                	mv	a1,s3
    80005148:	00092503          	lw	a0,0(s2)
    8000514c:	ffffe097          	auipc	ra,0xffffe
    80005150:	372080e7          	jalr	882(ra) # 800034be <ialloc>
    80005154:	84aa                	mv	s1,a0
    80005156:	c521                	beqz	a0,8000519e <create+0xec>
  ilock(ip);
    80005158:	ffffe097          	auipc	ra,0xffffe
    8000515c:	4fe080e7          	jalr	1278(ra) # 80003656 <ilock>
  ip->major = major;
    80005160:	05549723          	sh	s5,78(s1)
  ip->minor = minor;
    80005164:	05449823          	sh	s4,80(s1)
  ip->nlink = 1;
    80005168:	4a05                	li	s4,1
    8000516a:	05449923          	sh	s4,82(s1)
  iupdate(ip);
    8000516e:	8526                	mv	a0,s1
    80005170:	ffffe097          	auipc	ra,0xffffe
    80005174:	41c080e7          	jalr	1052(ra) # 8000358c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005178:	2981                	sext.w	s3,s3
    8000517a:	03498a63          	beq	s3,s4,800051ae <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000517e:	40d0                	lw	a2,4(s1)
    80005180:	fb040593          	addi	a1,s0,-80
    80005184:	854a                	mv	a0,s2
    80005186:	fffff097          	auipc	ra,0xfffff
    8000518a:	b98080e7          	jalr	-1128(ra) # 80003d1e <dirlink>
    8000518e:	06054b63          	bltz	a0,80005204 <create+0x152>
  iunlockput(dp);
    80005192:	854a                	mv	a0,s2
    80005194:	ffffe097          	auipc	ra,0xffffe
    80005198:	700080e7          	jalr	1792(ra) # 80003894 <iunlockput>
  return ip;
    8000519c:	b761                	j	80005124 <create+0x72>
    panic("create: ialloc");
    8000519e:	00003517          	auipc	a0,0x3
    800051a2:	67a50513          	addi	a0,a0,1658 # 80008818 <userret+0x788>
    800051a6:	ffffb097          	auipc	ra,0xffffb
    800051aa:	3a2080e7          	jalr	930(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    800051ae:	05295783          	lhu	a5,82(s2)
    800051b2:	2785                	addiw	a5,a5,1
    800051b4:	04f91923          	sh	a5,82(s2)
    iupdate(dp);
    800051b8:	854a                	mv	a0,s2
    800051ba:	ffffe097          	auipc	ra,0xffffe
    800051be:	3d2080e7          	jalr	978(ra) # 8000358c <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051c2:	40d0                	lw	a2,4(s1)
    800051c4:	00003597          	auipc	a1,0x3
    800051c8:	66458593          	addi	a1,a1,1636 # 80008828 <userret+0x798>
    800051cc:	8526                	mv	a0,s1
    800051ce:	fffff097          	auipc	ra,0xfffff
    800051d2:	b50080e7          	jalr	-1200(ra) # 80003d1e <dirlink>
    800051d6:	00054f63          	bltz	a0,800051f4 <create+0x142>
    800051da:	00492603          	lw	a2,4(s2)
    800051de:	00003597          	auipc	a1,0x3
    800051e2:	65258593          	addi	a1,a1,1618 # 80008830 <userret+0x7a0>
    800051e6:	8526                	mv	a0,s1
    800051e8:	fffff097          	auipc	ra,0xfffff
    800051ec:	b36080e7          	jalr	-1226(ra) # 80003d1e <dirlink>
    800051f0:	f80557e3          	bgez	a0,8000517e <create+0xcc>
      panic("create dots");
    800051f4:	00003517          	auipc	a0,0x3
    800051f8:	64450513          	addi	a0,a0,1604 # 80008838 <userret+0x7a8>
    800051fc:	ffffb097          	auipc	ra,0xffffb
    80005200:	34c080e7          	jalr	844(ra) # 80000548 <panic>
    panic("create: dirlink");
    80005204:	00003517          	auipc	a0,0x3
    80005208:	64450513          	addi	a0,a0,1604 # 80008848 <userret+0x7b8>
    8000520c:	ffffb097          	auipc	ra,0xffffb
    80005210:	33c080e7          	jalr	828(ra) # 80000548 <panic>
    return 0;
    80005214:	84aa                	mv	s1,a0
    80005216:	b739                	j	80005124 <create+0x72>

0000000080005218 <sys_dup>:
{
    80005218:	7179                	addi	sp,sp,-48
    8000521a:	f406                	sd	ra,40(sp)
    8000521c:	f022                	sd	s0,32(sp)
    8000521e:	ec26                	sd	s1,24(sp)
    80005220:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005222:	fd840613          	addi	a2,s0,-40
    80005226:	4581                	li	a1,0
    80005228:	4501                	li	a0,0
    8000522a:	00000097          	auipc	ra,0x0
    8000522e:	dde080e7          	jalr	-546(ra) # 80005008 <argfd>
    return -1;
    80005232:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005234:	02054363          	bltz	a0,8000525a <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005238:	fd843503          	ld	a0,-40(s0)
    8000523c:	00000097          	auipc	ra,0x0
    80005240:	e34080e7          	jalr	-460(ra) # 80005070 <fdalloc>
    80005244:	84aa                	mv	s1,a0
    return -1;
    80005246:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005248:	00054963          	bltz	a0,8000525a <sys_dup+0x42>
  filedup(f);
    8000524c:	fd843503          	ld	a0,-40(s0)
    80005250:	fffff097          	auipc	ra,0xfffff
    80005254:	334080e7          	jalr	820(ra) # 80004584 <filedup>
  return fd;
    80005258:	87a6                	mv	a5,s1
}
    8000525a:	853e                	mv	a0,a5
    8000525c:	70a2                	ld	ra,40(sp)
    8000525e:	7402                	ld	s0,32(sp)
    80005260:	64e2                	ld	s1,24(sp)
    80005262:	6145                	addi	sp,sp,48
    80005264:	8082                	ret

0000000080005266 <sys_read>:
{
    80005266:	7179                	addi	sp,sp,-48
    80005268:	f406                	sd	ra,40(sp)
    8000526a:	f022                	sd	s0,32(sp)
    8000526c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000526e:	fe840613          	addi	a2,s0,-24
    80005272:	4581                	li	a1,0
    80005274:	4501                	li	a0,0
    80005276:	00000097          	auipc	ra,0x0
    8000527a:	d92080e7          	jalr	-622(ra) # 80005008 <argfd>
    return -1;
    8000527e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005280:	04054163          	bltz	a0,800052c2 <sys_read+0x5c>
    80005284:	fe440593          	addi	a1,s0,-28
    80005288:	4509                	li	a0,2
    8000528a:	ffffe097          	auipc	ra,0xffffe
    8000528e:	856080e7          	jalr	-1962(ra) # 80002ae0 <argint>
    return -1;
    80005292:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005294:	02054763          	bltz	a0,800052c2 <sys_read+0x5c>
    80005298:	fd840593          	addi	a1,s0,-40
    8000529c:	4505                	li	a0,1
    8000529e:	ffffe097          	auipc	ra,0xffffe
    800052a2:	864080e7          	jalr	-1948(ra) # 80002b02 <argaddr>
    return -1;
    800052a6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052a8:	00054d63          	bltz	a0,800052c2 <sys_read+0x5c>
  return fileread(f, p, n);
    800052ac:	fe442603          	lw	a2,-28(s0)
    800052b0:	fd843583          	ld	a1,-40(s0)
    800052b4:	fe843503          	ld	a0,-24(s0)
    800052b8:	fffff097          	auipc	ra,0xfffff
    800052bc:	460080e7          	jalr	1120(ra) # 80004718 <fileread>
    800052c0:	87aa                	mv	a5,a0
}
    800052c2:	853e                	mv	a0,a5
    800052c4:	70a2                	ld	ra,40(sp)
    800052c6:	7402                	ld	s0,32(sp)
    800052c8:	6145                	addi	sp,sp,48
    800052ca:	8082                	ret

00000000800052cc <sys_write>:
{
    800052cc:	7179                	addi	sp,sp,-48
    800052ce:	f406                	sd	ra,40(sp)
    800052d0:	f022                	sd	s0,32(sp)
    800052d2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052d4:	fe840613          	addi	a2,s0,-24
    800052d8:	4581                	li	a1,0
    800052da:	4501                	li	a0,0
    800052dc:	00000097          	auipc	ra,0x0
    800052e0:	d2c080e7          	jalr	-724(ra) # 80005008 <argfd>
    return -1;
    800052e4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052e6:	04054163          	bltz	a0,80005328 <sys_write+0x5c>
    800052ea:	fe440593          	addi	a1,s0,-28
    800052ee:	4509                	li	a0,2
    800052f0:	ffffd097          	auipc	ra,0xffffd
    800052f4:	7f0080e7          	jalr	2032(ra) # 80002ae0 <argint>
    return -1;
    800052f8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052fa:	02054763          	bltz	a0,80005328 <sys_write+0x5c>
    800052fe:	fd840593          	addi	a1,s0,-40
    80005302:	4505                	li	a0,1
    80005304:	ffffd097          	auipc	ra,0xffffd
    80005308:	7fe080e7          	jalr	2046(ra) # 80002b02 <argaddr>
    return -1;
    8000530c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000530e:	00054d63          	bltz	a0,80005328 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005312:	fe442603          	lw	a2,-28(s0)
    80005316:	fd843583          	ld	a1,-40(s0)
    8000531a:	fe843503          	ld	a0,-24(s0)
    8000531e:	fffff097          	auipc	ra,0xfffff
    80005322:	4c0080e7          	jalr	1216(ra) # 800047de <filewrite>
    80005326:	87aa                	mv	a5,a0
}
    80005328:	853e                	mv	a0,a5
    8000532a:	70a2                	ld	ra,40(sp)
    8000532c:	7402                	ld	s0,32(sp)
    8000532e:	6145                	addi	sp,sp,48
    80005330:	8082                	ret

0000000080005332 <sys_close>:
{
    80005332:	1101                	addi	sp,sp,-32
    80005334:	ec06                	sd	ra,24(sp)
    80005336:	e822                	sd	s0,16(sp)
    80005338:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000533a:	fe040613          	addi	a2,s0,-32
    8000533e:	fec40593          	addi	a1,s0,-20
    80005342:	4501                	li	a0,0
    80005344:	00000097          	auipc	ra,0x0
    80005348:	cc4080e7          	jalr	-828(ra) # 80005008 <argfd>
    return -1;
    8000534c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000534e:	02054463          	bltz	a0,80005376 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005352:	ffffc097          	auipc	ra,0xffffc
    80005356:	714080e7          	jalr	1812(ra) # 80001a66 <myproc>
    8000535a:	fec42783          	lw	a5,-20(s0)
    8000535e:	07e9                	addi	a5,a5,26
    80005360:	078e                	slli	a5,a5,0x3
    80005362:	97aa                	add	a5,a5,a0
    80005364:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80005368:	fe043503          	ld	a0,-32(s0)
    8000536c:	fffff097          	auipc	ra,0xfffff
    80005370:	26a080e7          	jalr	618(ra) # 800045d6 <fileclose>
  return 0;
    80005374:	4781                	li	a5,0
}
    80005376:	853e                	mv	a0,a5
    80005378:	60e2                	ld	ra,24(sp)
    8000537a:	6442                	ld	s0,16(sp)
    8000537c:	6105                	addi	sp,sp,32
    8000537e:	8082                	ret

0000000080005380 <sys_fstat>:
{
    80005380:	1101                	addi	sp,sp,-32
    80005382:	ec06                	sd	ra,24(sp)
    80005384:	e822                	sd	s0,16(sp)
    80005386:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005388:	fe840613          	addi	a2,s0,-24
    8000538c:	4581                	li	a1,0
    8000538e:	4501                	li	a0,0
    80005390:	00000097          	auipc	ra,0x0
    80005394:	c78080e7          	jalr	-904(ra) # 80005008 <argfd>
    return -1;
    80005398:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000539a:	02054563          	bltz	a0,800053c4 <sys_fstat+0x44>
    8000539e:	fe040593          	addi	a1,s0,-32
    800053a2:	4505                	li	a0,1
    800053a4:	ffffd097          	auipc	ra,0xffffd
    800053a8:	75e080e7          	jalr	1886(ra) # 80002b02 <argaddr>
    return -1;
    800053ac:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053ae:	00054b63          	bltz	a0,800053c4 <sys_fstat+0x44>
  return filestat(f, st);
    800053b2:	fe043583          	ld	a1,-32(s0)
    800053b6:	fe843503          	ld	a0,-24(s0)
    800053ba:	fffff097          	auipc	ra,0xfffff
    800053be:	2ec080e7          	jalr	748(ra) # 800046a6 <filestat>
    800053c2:	87aa                	mv	a5,a0
}
    800053c4:	853e                	mv	a0,a5
    800053c6:	60e2                	ld	ra,24(sp)
    800053c8:	6442                	ld	s0,16(sp)
    800053ca:	6105                	addi	sp,sp,32
    800053cc:	8082                	ret

00000000800053ce <sys_link>:
{
    800053ce:	7169                	addi	sp,sp,-304
    800053d0:	f606                	sd	ra,296(sp)
    800053d2:	f222                	sd	s0,288(sp)
    800053d4:	ee26                	sd	s1,280(sp)
    800053d6:	ea4a                	sd	s2,272(sp)
    800053d8:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053da:	08000613          	li	a2,128
    800053de:	ed040593          	addi	a1,s0,-304
    800053e2:	4501                	li	a0,0
    800053e4:	ffffd097          	auipc	ra,0xffffd
    800053e8:	740080e7          	jalr	1856(ra) # 80002b24 <argstr>
    return -1;
    800053ec:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053ee:	12054363          	bltz	a0,80005514 <sys_link+0x146>
    800053f2:	08000613          	li	a2,128
    800053f6:	f5040593          	addi	a1,s0,-176
    800053fa:	4505                	li	a0,1
    800053fc:	ffffd097          	auipc	ra,0xffffd
    80005400:	728080e7          	jalr	1832(ra) # 80002b24 <argstr>
    return -1;
    80005404:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005406:	10054763          	bltz	a0,80005514 <sys_link+0x146>
  begin_op(ROOTDEV);
    8000540a:	4501                	li	a0,0
    8000540c:	fffff097          	auipc	ra,0xfffff
    80005410:	c30080e7          	jalr	-976(ra) # 8000403c <begin_op>
  if((ip = namei(old)) == 0){
    80005414:	ed040513          	addi	a0,s0,-304
    80005418:	fffff097          	auipc	ra,0xfffff
    8000541c:	9c8080e7          	jalr	-1592(ra) # 80003de0 <namei>
    80005420:	84aa                	mv	s1,a0
    80005422:	c559                	beqz	a0,800054b0 <sys_link+0xe2>
  ilock(ip);
    80005424:	ffffe097          	auipc	ra,0xffffe
    80005428:	232080e7          	jalr	562(ra) # 80003656 <ilock>
  if(ip->type == T_DIR){
    8000542c:	04c49703          	lh	a4,76(s1)
    80005430:	4785                	li	a5,1
    80005432:	08f70663          	beq	a4,a5,800054be <sys_link+0xf0>
  ip->nlink++;
    80005436:	0524d783          	lhu	a5,82(s1)
    8000543a:	2785                	addiw	a5,a5,1
    8000543c:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    80005440:	8526                	mv	a0,s1
    80005442:	ffffe097          	auipc	ra,0xffffe
    80005446:	14a080e7          	jalr	330(ra) # 8000358c <iupdate>
  iunlock(ip);
    8000544a:	8526                	mv	a0,s1
    8000544c:	ffffe097          	auipc	ra,0xffffe
    80005450:	2cc080e7          	jalr	716(ra) # 80003718 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005454:	fd040593          	addi	a1,s0,-48
    80005458:	f5040513          	addi	a0,s0,-176
    8000545c:	fffff097          	auipc	ra,0xfffff
    80005460:	9a2080e7          	jalr	-1630(ra) # 80003dfe <nameiparent>
    80005464:	892a                	mv	s2,a0
    80005466:	cd2d                	beqz	a0,800054e0 <sys_link+0x112>
  ilock(dp);
    80005468:	ffffe097          	auipc	ra,0xffffe
    8000546c:	1ee080e7          	jalr	494(ra) # 80003656 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005470:	00092703          	lw	a4,0(s2)
    80005474:	409c                	lw	a5,0(s1)
    80005476:	06f71063          	bne	a4,a5,800054d6 <sys_link+0x108>
    8000547a:	40d0                	lw	a2,4(s1)
    8000547c:	fd040593          	addi	a1,s0,-48
    80005480:	854a                	mv	a0,s2
    80005482:	fffff097          	auipc	ra,0xfffff
    80005486:	89c080e7          	jalr	-1892(ra) # 80003d1e <dirlink>
    8000548a:	04054663          	bltz	a0,800054d6 <sys_link+0x108>
  iunlockput(dp);
    8000548e:	854a                	mv	a0,s2
    80005490:	ffffe097          	auipc	ra,0xffffe
    80005494:	404080e7          	jalr	1028(ra) # 80003894 <iunlockput>
  iput(ip);
    80005498:	8526                	mv	a0,s1
    8000549a:	ffffe097          	auipc	ra,0xffffe
    8000549e:	2ca080e7          	jalr	714(ra) # 80003764 <iput>
  end_op(ROOTDEV);
    800054a2:	4501                	li	a0,0
    800054a4:	fffff097          	auipc	ra,0xfffff
    800054a8:	c42080e7          	jalr	-958(ra) # 800040e6 <end_op>
  return 0;
    800054ac:	4781                	li	a5,0
    800054ae:	a09d                	j	80005514 <sys_link+0x146>
    end_op(ROOTDEV);
    800054b0:	4501                	li	a0,0
    800054b2:	fffff097          	auipc	ra,0xfffff
    800054b6:	c34080e7          	jalr	-972(ra) # 800040e6 <end_op>
    return -1;
    800054ba:	57fd                	li	a5,-1
    800054bc:	a8a1                	j	80005514 <sys_link+0x146>
    iunlockput(ip);
    800054be:	8526                	mv	a0,s1
    800054c0:	ffffe097          	auipc	ra,0xffffe
    800054c4:	3d4080e7          	jalr	980(ra) # 80003894 <iunlockput>
    end_op(ROOTDEV);
    800054c8:	4501                	li	a0,0
    800054ca:	fffff097          	auipc	ra,0xfffff
    800054ce:	c1c080e7          	jalr	-996(ra) # 800040e6 <end_op>
    return -1;
    800054d2:	57fd                	li	a5,-1
    800054d4:	a081                	j	80005514 <sys_link+0x146>
    iunlockput(dp);
    800054d6:	854a                	mv	a0,s2
    800054d8:	ffffe097          	auipc	ra,0xffffe
    800054dc:	3bc080e7          	jalr	956(ra) # 80003894 <iunlockput>
  ilock(ip);
    800054e0:	8526                	mv	a0,s1
    800054e2:	ffffe097          	auipc	ra,0xffffe
    800054e6:	174080e7          	jalr	372(ra) # 80003656 <ilock>
  ip->nlink--;
    800054ea:	0524d783          	lhu	a5,82(s1)
    800054ee:	37fd                	addiw	a5,a5,-1
    800054f0:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    800054f4:	8526                	mv	a0,s1
    800054f6:	ffffe097          	auipc	ra,0xffffe
    800054fa:	096080e7          	jalr	150(ra) # 8000358c <iupdate>
  iunlockput(ip);
    800054fe:	8526                	mv	a0,s1
    80005500:	ffffe097          	auipc	ra,0xffffe
    80005504:	394080e7          	jalr	916(ra) # 80003894 <iunlockput>
  end_op(ROOTDEV);
    80005508:	4501                	li	a0,0
    8000550a:	fffff097          	auipc	ra,0xfffff
    8000550e:	bdc080e7          	jalr	-1060(ra) # 800040e6 <end_op>
  return -1;
    80005512:	57fd                	li	a5,-1
}
    80005514:	853e                	mv	a0,a5
    80005516:	70b2                	ld	ra,296(sp)
    80005518:	7412                	ld	s0,288(sp)
    8000551a:	64f2                	ld	s1,280(sp)
    8000551c:	6952                	ld	s2,272(sp)
    8000551e:	6155                	addi	sp,sp,304
    80005520:	8082                	ret

0000000080005522 <sys_unlink>:
{
    80005522:	7151                	addi	sp,sp,-240
    80005524:	f586                	sd	ra,232(sp)
    80005526:	f1a2                	sd	s0,224(sp)
    80005528:	eda6                	sd	s1,216(sp)
    8000552a:	e9ca                	sd	s2,208(sp)
    8000552c:	e5ce                	sd	s3,200(sp)
    8000552e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005530:	08000613          	li	a2,128
    80005534:	f3040593          	addi	a1,s0,-208
    80005538:	4501                	li	a0,0
    8000553a:	ffffd097          	auipc	ra,0xffffd
    8000553e:	5ea080e7          	jalr	1514(ra) # 80002b24 <argstr>
    80005542:	18054463          	bltz	a0,800056ca <sys_unlink+0x1a8>
  begin_op(ROOTDEV);
    80005546:	4501                	li	a0,0
    80005548:	fffff097          	auipc	ra,0xfffff
    8000554c:	af4080e7          	jalr	-1292(ra) # 8000403c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005550:	fb040593          	addi	a1,s0,-80
    80005554:	f3040513          	addi	a0,s0,-208
    80005558:	fffff097          	auipc	ra,0xfffff
    8000555c:	8a6080e7          	jalr	-1882(ra) # 80003dfe <nameiparent>
    80005560:	84aa                	mv	s1,a0
    80005562:	cd61                	beqz	a0,8000563a <sys_unlink+0x118>
  ilock(dp);
    80005564:	ffffe097          	auipc	ra,0xffffe
    80005568:	0f2080e7          	jalr	242(ra) # 80003656 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000556c:	00003597          	auipc	a1,0x3
    80005570:	2bc58593          	addi	a1,a1,700 # 80008828 <userret+0x798>
    80005574:	fb040513          	addi	a0,s0,-80
    80005578:	ffffe097          	auipc	ra,0xffffe
    8000557c:	57c080e7          	jalr	1404(ra) # 80003af4 <namecmp>
    80005580:	14050c63          	beqz	a0,800056d8 <sys_unlink+0x1b6>
    80005584:	00003597          	auipc	a1,0x3
    80005588:	2ac58593          	addi	a1,a1,684 # 80008830 <userret+0x7a0>
    8000558c:	fb040513          	addi	a0,s0,-80
    80005590:	ffffe097          	auipc	ra,0xffffe
    80005594:	564080e7          	jalr	1380(ra) # 80003af4 <namecmp>
    80005598:	14050063          	beqz	a0,800056d8 <sys_unlink+0x1b6>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000559c:	f2c40613          	addi	a2,s0,-212
    800055a0:	fb040593          	addi	a1,s0,-80
    800055a4:	8526                	mv	a0,s1
    800055a6:	ffffe097          	auipc	ra,0xffffe
    800055aa:	568080e7          	jalr	1384(ra) # 80003b0e <dirlookup>
    800055ae:	892a                	mv	s2,a0
    800055b0:	12050463          	beqz	a0,800056d8 <sys_unlink+0x1b6>
  ilock(ip);
    800055b4:	ffffe097          	auipc	ra,0xffffe
    800055b8:	0a2080e7          	jalr	162(ra) # 80003656 <ilock>
  if(ip->nlink < 1)
    800055bc:	05291783          	lh	a5,82(s2)
    800055c0:	08f05463          	blez	a5,80005648 <sys_unlink+0x126>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055c4:	04c91703          	lh	a4,76(s2)
    800055c8:	4785                	li	a5,1
    800055ca:	08f70763          	beq	a4,a5,80005658 <sys_unlink+0x136>
  memset(&de, 0, sizeof(de));
    800055ce:	4641                	li	a2,16
    800055d0:	4581                	li	a1,0
    800055d2:	fc040513          	addi	a0,s0,-64
    800055d6:	ffffb097          	auipc	ra,0xffffb
    800055da:	7a6080e7          	jalr	1958(ra) # 80000d7c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055de:	4741                	li	a4,16
    800055e0:	f2c42683          	lw	a3,-212(s0)
    800055e4:	fc040613          	addi	a2,s0,-64
    800055e8:	4581                	li	a1,0
    800055ea:	8526                	mv	a0,s1
    800055ec:	ffffe097          	auipc	ra,0xffffe
    800055f0:	3ee080e7          	jalr	1006(ra) # 800039da <writei>
    800055f4:	47c1                	li	a5,16
    800055f6:	0af51763          	bne	a0,a5,800056a4 <sys_unlink+0x182>
  if(ip->type == T_DIR){
    800055fa:	04c91703          	lh	a4,76(s2)
    800055fe:	4785                	li	a5,1
    80005600:	0af70a63          	beq	a4,a5,800056b4 <sys_unlink+0x192>
  iunlockput(dp);
    80005604:	8526                	mv	a0,s1
    80005606:	ffffe097          	auipc	ra,0xffffe
    8000560a:	28e080e7          	jalr	654(ra) # 80003894 <iunlockput>
  ip->nlink--;
    8000560e:	05295783          	lhu	a5,82(s2)
    80005612:	37fd                	addiw	a5,a5,-1
    80005614:	04f91923          	sh	a5,82(s2)
  iupdate(ip);
    80005618:	854a                	mv	a0,s2
    8000561a:	ffffe097          	auipc	ra,0xffffe
    8000561e:	f72080e7          	jalr	-142(ra) # 8000358c <iupdate>
  iunlockput(ip);
    80005622:	854a                	mv	a0,s2
    80005624:	ffffe097          	auipc	ra,0xffffe
    80005628:	270080e7          	jalr	624(ra) # 80003894 <iunlockput>
  end_op(ROOTDEV);
    8000562c:	4501                	li	a0,0
    8000562e:	fffff097          	auipc	ra,0xfffff
    80005632:	ab8080e7          	jalr	-1352(ra) # 800040e6 <end_op>
  return 0;
    80005636:	4501                	li	a0,0
    80005638:	a85d                	j	800056ee <sys_unlink+0x1cc>
    end_op(ROOTDEV);
    8000563a:	4501                	li	a0,0
    8000563c:	fffff097          	auipc	ra,0xfffff
    80005640:	aaa080e7          	jalr	-1366(ra) # 800040e6 <end_op>
    return -1;
    80005644:	557d                	li	a0,-1
    80005646:	a065                	j	800056ee <sys_unlink+0x1cc>
    panic("unlink: nlink < 1");
    80005648:	00003517          	auipc	a0,0x3
    8000564c:	21050513          	addi	a0,a0,528 # 80008858 <userret+0x7c8>
    80005650:	ffffb097          	auipc	ra,0xffffb
    80005654:	ef8080e7          	jalr	-264(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005658:	05492703          	lw	a4,84(s2)
    8000565c:	02000793          	li	a5,32
    80005660:	f6e7f7e3          	bgeu	a5,a4,800055ce <sys_unlink+0xac>
    80005664:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005668:	4741                	li	a4,16
    8000566a:	86ce                	mv	a3,s3
    8000566c:	f1840613          	addi	a2,s0,-232
    80005670:	4581                	li	a1,0
    80005672:	854a                	mv	a0,s2
    80005674:	ffffe097          	auipc	ra,0xffffe
    80005678:	272080e7          	jalr	626(ra) # 800038e6 <readi>
    8000567c:	47c1                	li	a5,16
    8000567e:	00f51b63          	bne	a0,a5,80005694 <sys_unlink+0x172>
    if(de.inum != 0)
    80005682:	f1845783          	lhu	a5,-232(s0)
    80005686:	e7a1                	bnez	a5,800056ce <sys_unlink+0x1ac>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005688:	29c1                	addiw	s3,s3,16
    8000568a:	05492783          	lw	a5,84(s2)
    8000568e:	fcf9ede3          	bltu	s3,a5,80005668 <sys_unlink+0x146>
    80005692:	bf35                	j	800055ce <sys_unlink+0xac>
      panic("isdirempty: readi");
    80005694:	00003517          	auipc	a0,0x3
    80005698:	1dc50513          	addi	a0,a0,476 # 80008870 <userret+0x7e0>
    8000569c:	ffffb097          	auipc	ra,0xffffb
    800056a0:	eac080e7          	jalr	-340(ra) # 80000548 <panic>
    panic("unlink: writei");
    800056a4:	00003517          	auipc	a0,0x3
    800056a8:	1e450513          	addi	a0,a0,484 # 80008888 <userret+0x7f8>
    800056ac:	ffffb097          	auipc	ra,0xffffb
    800056b0:	e9c080e7          	jalr	-356(ra) # 80000548 <panic>
    dp->nlink--;
    800056b4:	0524d783          	lhu	a5,82(s1)
    800056b8:	37fd                	addiw	a5,a5,-1
    800056ba:	04f49923          	sh	a5,82(s1)
    iupdate(dp);
    800056be:	8526                	mv	a0,s1
    800056c0:	ffffe097          	auipc	ra,0xffffe
    800056c4:	ecc080e7          	jalr	-308(ra) # 8000358c <iupdate>
    800056c8:	bf35                	j	80005604 <sys_unlink+0xe2>
    return -1;
    800056ca:	557d                	li	a0,-1
    800056cc:	a00d                	j	800056ee <sys_unlink+0x1cc>
    iunlockput(ip);
    800056ce:	854a                	mv	a0,s2
    800056d0:	ffffe097          	auipc	ra,0xffffe
    800056d4:	1c4080e7          	jalr	452(ra) # 80003894 <iunlockput>
  iunlockput(dp);
    800056d8:	8526                	mv	a0,s1
    800056da:	ffffe097          	auipc	ra,0xffffe
    800056de:	1ba080e7          	jalr	442(ra) # 80003894 <iunlockput>
  end_op(ROOTDEV);
    800056e2:	4501                	li	a0,0
    800056e4:	fffff097          	auipc	ra,0xfffff
    800056e8:	a02080e7          	jalr	-1534(ra) # 800040e6 <end_op>
  return -1;
    800056ec:	557d                	li	a0,-1
}
    800056ee:	70ae                	ld	ra,232(sp)
    800056f0:	740e                	ld	s0,224(sp)
    800056f2:	64ee                	ld	s1,216(sp)
    800056f4:	694e                	ld	s2,208(sp)
    800056f6:	69ae                	ld	s3,200(sp)
    800056f8:	616d                	addi	sp,sp,240
    800056fa:	8082                	ret

00000000800056fc <sys_open>:

uint64
sys_open(void)
{
    800056fc:	7131                	addi	sp,sp,-192
    800056fe:	fd06                	sd	ra,184(sp)
    80005700:	f922                	sd	s0,176(sp)
    80005702:	f526                	sd	s1,168(sp)
    80005704:	f14a                	sd	s2,160(sp)
    80005706:	ed4e                	sd	s3,152(sp)
    80005708:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000570a:	08000613          	li	a2,128
    8000570e:	f5040593          	addi	a1,s0,-176
    80005712:	4501                	li	a0,0
    80005714:	ffffd097          	auipc	ra,0xffffd
    80005718:	410080e7          	jalr	1040(ra) # 80002b24 <argstr>
    return -1;
    8000571c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000571e:	0a054963          	bltz	a0,800057d0 <sys_open+0xd4>
    80005722:	f4c40593          	addi	a1,s0,-180
    80005726:	4505                	li	a0,1
    80005728:	ffffd097          	auipc	ra,0xffffd
    8000572c:	3b8080e7          	jalr	952(ra) # 80002ae0 <argint>
    80005730:	0a054063          	bltz	a0,800057d0 <sys_open+0xd4>

  begin_op(ROOTDEV);
    80005734:	4501                	li	a0,0
    80005736:	fffff097          	auipc	ra,0xfffff
    8000573a:	906080e7          	jalr	-1786(ra) # 8000403c <begin_op>

  if(omode & O_CREATE){
    8000573e:	f4c42783          	lw	a5,-180(s0)
    80005742:	2007f793          	andi	a5,a5,512
    80005746:	c3dd                	beqz	a5,800057ec <sys_open+0xf0>
    ip = create(path, T_FILE, 0, 0);
    80005748:	4681                	li	a3,0
    8000574a:	4601                	li	a2,0
    8000574c:	4589                	li	a1,2
    8000574e:	f5040513          	addi	a0,s0,-176
    80005752:	00000097          	auipc	ra,0x0
    80005756:	960080e7          	jalr	-1696(ra) # 800050b2 <create>
    8000575a:	892a                	mv	s2,a0
    if(ip == 0){
    8000575c:	c151                	beqz	a0,800057e0 <sys_open+0xe4>
      end_op(ROOTDEV);
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000575e:	04c91703          	lh	a4,76(s2)
    80005762:	478d                	li	a5,3
    80005764:	00f71763          	bne	a4,a5,80005772 <sys_open+0x76>
    80005768:	04e95703          	lhu	a4,78(s2)
    8000576c:	47a5                	li	a5,9
    8000576e:	0ce7e663          	bltu	a5,a4,8000583a <sys_open+0x13e>
    iunlockput(ip);
    end_op(ROOTDEV);
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005772:	fffff097          	auipc	ra,0xfffff
    80005776:	da8080e7          	jalr	-600(ra) # 8000451a <filealloc>
    8000577a:	89aa                	mv	s3,a0
    8000577c:	c97d                	beqz	a0,80005872 <sys_open+0x176>
    8000577e:	00000097          	auipc	ra,0x0
    80005782:	8f2080e7          	jalr	-1806(ra) # 80005070 <fdalloc>
    80005786:	84aa                	mv	s1,a0
    80005788:	0e054063          	bltz	a0,80005868 <sys_open+0x16c>
    iunlockput(ip);
    end_op(ROOTDEV);
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000578c:	04c91703          	lh	a4,76(s2)
    80005790:	478d                	li	a5,3
    80005792:	0cf70063          	beq	a4,a5,80005852 <sys_open+0x156>
    f->type = FD_DEVICE;
    f->major = ip->major;
    f->minor = ip->minor;
  } else {
    f->type = FD_INODE;
    80005796:	4789                	li	a5,2
    80005798:	00f9a023          	sw	a5,0(s3)
  }
  f->ip = ip;
    8000579c:	0129bc23          	sd	s2,24(s3)
  f->off = 0;
    800057a0:	0209a023          	sw	zero,32(s3)
  f->readable = !(omode & O_WRONLY);
    800057a4:	f4c42783          	lw	a5,-180(s0)
    800057a8:	0017c713          	xori	a4,a5,1
    800057ac:	8b05                	andi	a4,a4,1
    800057ae:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057b2:	8b8d                	andi	a5,a5,3
    800057b4:	00f037b3          	snez	a5,a5
    800057b8:	00f984a3          	sb	a5,9(s3)

  iunlock(ip);
    800057bc:	854a                	mv	a0,s2
    800057be:	ffffe097          	auipc	ra,0xffffe
    800057c2:	f5a080e7          	jalr	-166(ra) # 80003718 <iunlock>
  end_op(ROOTDEV);
    800057c6:	4501                	li	a0,0
    800057c8:	fffff097          	auipc	ra,0xfffff
    800057cc:	91e080e7          	jalr	-1762(ra) # 800040e6 <end_op>

  return fd;
}
    800057d0:	8526                	mv	a0,s1
    800057d2:	70ea                	ld	ra,184(sp)
    800057d4:	744a                	ld	s0,176(sp)
    800057d6:	74aa                	ld	s1,168(sp)
    800057d8:	790a                	ld	s2,160(sp)
    800057da:	69ea                	ld	s3,152(sp)
    800057dc:	6129                	addi	sp,sp,192
    800057de:	8082                	ret
      end_op(ROOTDEV);
    800057e0:	4501                	li	a0,0
    800057e2:	fffff097          	auipc	ra,0xfffff
    800057e6:	904080e7          	jalr	-1788(ra) # 800040e6 <end_op>
      return -1;
    800057ea:	b7dd                	j	800057d0 <sys_open+0xd4>
    if((ip = namei(path)) == 0){
    800057ec:	f5040513          	addi	a0,s0,-176
    800057f0:	ffffe097          	auipc	ra,0xffffe
    800057f4:	5f0080e7          	jalr	1520(ra) # 80003de0 <namei>
    800057f8:	892a                	mv	s2,a0
    800057fa:	c90d                	beqz	a0,8000582c <sys_open+0x130>
    ilock(ip);
    800057fc:	ffffe097          	auipc	ra,0xffffe
    80005800:	e5a080e7          	jalr	-422(ra) # 80003656 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005804:	04c91703          	lh	a4,76(s2)
    80005808:	4785                	li	a5,1
    8000580a:	f4f71ae3          	bne	a4,a5,8000575e <sys_open+0x62>
    8000580e:	f4c42783          	lw	a5,-180(s0)
    80005812:	d3a5                	beqz	a5,80005772 <sys_open+0x76>
      iunlockput(ip);
    80005814:	854a                	mv	a0,s2
    80005816:	ffffe097          	auipc	ra,0xffffe
    8000581a:	07e080e7          	jalr	126(ra) # 80003894 <iunlockput>
      end_op(ROOTDEV);
    8000581e:	4501                	li	a0,0
    80005820:	fffff097          	auipc	ra,0xfffff
    80005824:	8c6080e7          	jalr	-1850(ra) # 800040e6 <end_op>
      return -1;
    80005828:	54fd                	li	s1,-1
    8000582a:	b75d                	j	800057d0 <sys_open+0xd4>
      end_op(ROOTDEV);
    8000582c:	4501                	li	a0,0
    8000582e:	fffff097          	auipc	ra,0xfffff
    80005832:	8b8080e7          	jalr	-1864(ra) # 800040e6 <end_op>
      return -1;
    80005836:	54fd                	li	s1,-1
    80005838:	bf61                	j	800057d0 <sys_open+0xd4>
    iunlockput(ip);
    8000583a:	854a                	mv	a0,s2
    8000583c:	ffffe097          	auipc	ra,0xffffe
    80005840:	058080e7          	jalr	88(ra) # 80003894 <iunlockput>
    end_op(ROOTDEV);
    80005844:	4501                	li	a0,0
    80005846:	fffff097          	auipc	ra,0xfffff
    8000584a:	8a0080e7          	jalr	-1888(ra) # 800040e6 <end_op>
    return -1;
    8000584e:	54fd                	li	s1,-1
    80005850:	b741                	j	800057d0 <sys_open+0xd4>
    f->type = FD_DEVICE;
    80005852:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005856:	04e91783          	lh	a5,78(s2)
    8000585a:	02f99223          	sh	a5,36(s3)
    f->minor = ip->minor;
    8000585e:	05091783          	lh	a5,80(s2)
    80005862:	02f99323          	sh	a5,38(s3)
    80005866:	bf1d                	j	8000579c <sys_open+0xa0>
      fileclose(f);
    80005868:	854e                	mv	a0,s3
    8000586a:	fffff097          	auipc	ra,0xfffff
    8000586e:	d6c080e7          	jalr	-660(ra) # 800045d6 <fileclose>
    iunlockput(ip);
    80005872:	854a                	mv	a0,s2
    80005874:	ffffe097          	auipc	ra,0xffffe
    80005878:	020080e7          	jalr	32(ra) # 80003894 <iunlockput>
    end_op(ROOTDEV);
    8000587c:	4501                	li	a0,0
    8000587e:	fffff097          	auipc	ra,0xfffff
    80005882:	868080e7          	jalr	-1944(ra) # 800040e6 <end_op>
    return -1;
    80005886:	54fd                	li	s1,-1
    80005888:	b7a1                	j	800057d0 <sys_open+0xd4>

000000008000588a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000588a:	7175                	addi	sp,sp,-144
    8000588c:	e506                	sd	ra,136(sp)
    8000588e:	e122                	sd	s0,128(sp)
    80005890:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op(ROOTDEV);
    80005892:	4501                	li	a0,0
    80005894:	ffffe097          	auipc	ra,0xffffe
    80005898:	7a8080e7          	jalr	1960(ra) # 8000403c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000589c:	08000613          	li	a2,128
    800058a0:	f7040593          	addi	a1,s0,-144
    800058a4:	4501                	li	a0,0
    800058a6:	ffffd097          	auipc	ra,0xffffd
    800058aa:	27e080e7          	jalr	638(ra) # 80002b24 <argstr>
    800058ae:	02054a63          	bltz	a0,800058e2 <sys_mkdir+0x58>
    800058b2:	4681                	li	a3,0
    800058b4:	4601                	li	a2,0
    800058b6:	4585                	li	a1,1
    800058b8:	f7040513          	addi	a0,s0,-144
    800058bc:	fffff097          	auipc	ra,0xfffff
    800058c0:	7f6080e7          	jalr	2038(ra) # 800050b2 <create>
    800058c4:	cd19                	beqz	a0,800058e2 <sys_mkdir+0x58>
    end_op(ROOTDEV);
    return -1;
  }
  iunlockput(ip);
    800058c6:	ffffe097          	auipc	ra,0xffffe
    800058ca:	fce080e7          	jalr	-50(ra) # 80003894 <iunlockput>
  end_op(ROOTDEV);
    800058ce:	4501                	li	a0,0
    800058d0:	fffff097          	auipc	ra,0xfffff
    800058d4:	816080e7          	jalr	-2026(ra) # 800040e6 <end_op>
  return 0;
    800058d8:	4501                	li	a0,0
}
    800058da:	60aa                	ld	ra,136(sp)
    800058dc:	640a                	ld	s0,128(sp)
    800058de:	6149                	addi	sp,sp,144
    800058e0:	8082                	ret
    end_op(ROOTDEV);
    800058e2:	4501                	li	a0,0
    800058e4:	fffff097          	auipc	ra,0xfffff
    800058e8:	802080e7          	jalr	-2046(ra) # 800040e6 <end_op>
    return -1;
    800058ec:	557d                	li	a0,-1
    800058ee:	b7f5                	j	800058da <sys_mkdir+0x50>

00000000800058f0 <sys_mknod>:

uint64
sys_mknod(void)
{
    800058f0:	7135                	addi	sp,sp,-160
    800058f2:	ed06                	sd	ra,152(sp)
    800058f4:	e922                	sd	s0,144(sp)
    800058f6:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op(ROOTDEV);
    800058f8:	4501                	li	a0,0
    800058fa:	ffffe097          	auipc	ra,0xffffe
    800058fe:	742080e7          	jalr	1858(ra) # 8000403c <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005902:	08000613          	li	a2,128
    80005906:	f7040593          	addi	a1,s0,-144
    8000590a:	4501                	li	a0,0
    8000590c:	ffffd097          	auipc	ra,0xffffd
    80005910:	218080e7          	jalr	536(ra) # 80002b24 <argstr>
    80005914:	04054b63          	bltz	a0,8000596a <sys_mknod+0x7a>
     argint(1, &major) < 0 ||
    80005918:	f6c40593          	addi	a1,s0,-148
    8000591c:	4505                	li	a0,1
    8000591e:	ffffd097          	auipc	ra,0xffffd
    80005922:	1c2080e7          	jalr	450(ra) # 80002ae0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005926:	04054263          	bltz	a0,8000596a <sys_mknod+0x7a>
     argint(2, &minor) < 0 ||
    8000592a:	f6840593          	addi	a1,s0,-152
    8000592e:	4509                	li	a0,2
    80005930:	ffffd097          	auipc	ra,0xffffd
    80005934:	1b0080e7          	jalr	432(ra) # 80002ae0 <argint>
     argint(1, &major) < 0 ||
    80005938:	02054963          	bltz	a0,8000596a <sys_mknod+0x7a>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000593c:	f6841683          	lh	a3,-152(s0)
    80005940:	f6c41603          	lh	a2,-148(s0)
    80005944:	458d                	li	a1,3
    80005946:	f7040513          	addi	a0,s0,-144
    8000594a:	fffff097          	auipc	ra,0xfffff
    8000594e:	768080e7          	jalr	1896(ra) # 800050b2 <create>
     argint(2, &minor) < 0 ||
    80005952:	cd01                	beqz	a0,8000596a <sys_mknod+0x7a>
    end_op(ROOTDEV);
    return -1;
  }
  iunlockput(ip);
    80005954:	ffffe097          	auipc	ra,0xffffe
    80005958:	f40080e7          	jalr	-192(ra) # 80003894 <iunlockput>
  end_op(ROOTDEV);
    8000595c:	4501                	li	a0,0
    8000595e:	ffffe097          	auipc	ra,0xffffe
    80005962:	788080e7          	jalr	1928(ra) # 800040e6 <end_op>
  return 0;
    80005966:	4501                	li	a0,0
    80005968:	a039                	j	80005976 <sys_mknod+0x86>
    end_op(ROOTDEV);
    8000596a:	4501                	li	a0,0
    8000596c:	ffffe097          	auipc	ra,0xffffe
    80005970:	77a080e7          	jalr	1914(ra) # 800040e6 <end_op>
    return -1;
    80005974:	557d                	li	a0,-1
}
    80005976:	60ea                	ld	ra,152(sp)
    80005978:	644a                	ld	s0,144(sp)
    8000597a:	610d                	addi	sp,sp,160
    8000597c:	8082                	ret

000000008000597e <sys_chdir>:

uint64
sys_chdir(void)
{
    8000597e:	7135                	addi	sp,sp,-160
    80005980:	ed06                	sd	ra,152(sp)
    80005982:	e922                	sd	s0,144(sp)
    80005984:	e526                	sd	s1,136(sp)
    80005986:	e14a                	sd	s2,128(sp)
    80005988:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000598a:	ffffc097          	auipc	ra,0xffffc
    8000598e:	0dc080e7          	jalr	220(ra) # 80001a66 <myproc>
    80005992:	892a                	mv	s2,a0
  
  begin_op(ROOTDEV);
    80005994:	4501                	li	a0,0
    80005996:	ffffe097          	auipc	ra,0xffffe
    8000599a:	6a6080e7          	jalr	1702(ra) # 8000403c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000599e:	08000613          	li	a2,128
    800059a2:	f6040593          	addi	a1,s0,-160
    800059a6:	4501                	li	a0,0
    800059a8:	ffffd097          	auipc	ra,0xffffd
    800059ac:	17c080e7          	jalr	380(ra) # 80002b24 <argstr>
    800059b0:	04054c63          	bltz	a0,80005a08 <sys_chdir+0x8a>
    800059b4:	f6040513          	addi	a0,s0,-160
    800059b8:	ffffe097          	auipc	ra,0xffffe
    800059bc:	428080e7          	jalr	1064(ra) # 80003de0 <namei>
    800059c0:	84aa                	mv	s1,a0
    800059c2:	c139                	beqz	a0,80005a08 <sys_chdir+0x8a>
    end_op(ROOTDEV);
    return -1;
  }
  ilock(ip);
    800059c4:	ffffe097          	auipc	ra,0xffffe
    800059c8:	c92080e7          	jalr	-878(ra) # 80003656 <ilock>
  if(ip->type != T_DIR){
    800059cc:	04c49703          	lh	a4,76(s1)
    800059d0:	4785                	li	a5,1
    800059d2:	04f71263          	bne	a4,a5,80005a16 <sys_chdir+0x98>
    iunlockput(ip);
    end_op(ROOTDEV);
    return -1;
  }
  iunlock(ip);
    800059d6:	8526                	mv	a0,s1
    800059d8:	ffffe097          	auipc	ra,0xffffe
    800059dc:	d40080e7          	jalr	-704(ra) # 80003718 <iunlock>
  iput(p->cwd);
    800059e0:	15893503          	ld	a0,344(s2)
    800059e4:	ffffe097          	auipc	ra,0xffffe
    800059e8:	d80080e7          	jalr	-640(ra) # 80003764 <iput>
  end_op(ROOTDEV);
    800059ec:	4501                	li	a0,0
    800059ee:	ffffe097          	auipc	ra,0xffffe
    800059f2:	6f8080e7          	jalr	1784(ra) # 800040e6 <end_op>
  p->cwd = ip;
    800059f6:	14993c23          	sd	s1,344(s2)
  return 0;
    800059fa:	4501                	li	a0,0
}
    800059fc:	60ea                	ld	ra,152(sp)
    800059fe:	644a                	ld	s0,144(sp)
    80005a00:	64aa                	ld	s1,136(sp)
    80005a02:	690a                	ld	s2,128(sp)
    80005a04:	610d                	addi	sp,sp,160
    80005a06:	8082                	ret
    end_op(ROOTDEV);
    80005a08:	4501                	li	a0,0
    80005a0a:	ffffe097          	auipc	ra,0xffffe
    80005a0e:	6dc080e7          	jalr	1756(ra) # 800040e6 <end_op>
    return -1;
    80005a12:	557d                	li	a0,-1
    80005a14:	b7e5                	j	800059fc <sys_chdir+0x7e>
    iunlockput(ip);
    80005a16:	8526                	mv	a0,s1
    80005a18:	ffffe097          	auipc	ra,0xffffe
    80005a1c:	e7c080e7          	jalr	-388(ra) # 80003894 <iunlockput>
    end_op(ROOTDEV);
    80005a20:	4501                	li	a0,0
    80005a22:	ffffe097          	auipc	ra,0xffffe
    80005a26:	6c4080e7          	jalr	1732(ra) # 800040e6 <end_op>
    return -1;
    80005a2a:	557d                	li	a0,-1
    80005a2c:	bfc1                	j	800059fc <sys_chdir+0x7e>

0000000080005a2e <sys_exec>:

uint64
sys_exec(void)
{
    80005a2e:	7145                	addi	sp,sp,-464
    80005a30:	e786                	sd	ra,456(sp)
    80005a32:	e3a2                	sd	s0,448(sp)
    80005a34:	ff26                	sd	s1,440(sp)
    80005a36:	fb4a                	sd	s2,432(sp)
    80005a38:	f74e                	sd	s3,424(sp)
    80005a3a:	f352                	sd	s4,416(sp)
    80005a3c:	ef56                	sd	s5,408(sp)
    80005a3e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a40:	08000613          	li	a2,128
    80005a44:	f4040593          	addi	a1,s0,-192
    80005a48:	4501                	li	a0,0
    80005a4a:	ffffd097          	auipc	ra,0xffffd
    80005a4e:	0da080e7          	jalr	218(ra) # 80002b24 <argstr>
    80005a52:	0e054663          	bltz	a0,80005b3e <sys_exec+0x110>
    80005a56:	e3840593          	addi	a1,s0,-456
    80005a5a:	4505                	li	a0,1
    80005a5c:	ffffd097          	auipc	ra,0xffffd
    80005a60:	0a6080e7          	jalr	166(ra) # 80002b02 <argaddr>
    80005a64:	0e054763          	bltz	a0,80005b52 <sys_exec+0x124>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
    80005a68:	10000613          	li	a2,256
    80005a6c:	4581                	li	a1,0
    80005a6e:	e4040513          	addi	a0,s0,-448
    80005a72:	ffffb097          	auipc	ra,0xffffb
    80005a76:	30a080e7          	jalr	778(ra) # 80000d7c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a7a:	e4040913          	addi	s2,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a7e:	89ca                	mv	s3,s2
    80005a80:	4481                	li	s1,0
    if(i >= NELEM(argv)){
    80005a82:	02000a13          	li	s4,32
    80005a86:	00048a9b          	sext.w	s5,s1
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a8a:	00349793          	slli	a5,s1,0x3
    80005a8e:	e3040593          	addi	a1,s0,-464
    80005a92:	e3843503          	ld	a0,-456(s0)
    80005a96:	953e                	add	a0,a0,a5
    80005a98:	ffffd097          	auipc	ra,0xffffd
    80005a9c:	fae080e7          	jalr	-82(ra) # 80002a46 <fetchaddr>
    80005aa0:	02054a63          	bltz	a0,80005ad4 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005aa4:	e3043783          	ld	a5,-464(s0)
    80005aa8:	c7a1                	beqz	a5,80005af0 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005aaa:	ffffb097          	auipc	ra,0xffffb
    80005aae:	eb6080e7          	jalr	-330(ra) # 80000960 <kalloc>
    80005ab2:	85aa                	mv	a1,a0
    80005ab4:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ab8:	c92d                	beqz	a0,80005b2a <sys_exec+0xfc>
      panic("sys_exec kalloc");
    if(fetchstr(uarg, argv[i], PGSIZE) < 0){
    80005aba:	6605                	lui	a2,0x1
    80005abc:	e3043503          	ld	a0,-464(s0)
    80005ac0:	ffffd097          	auipc	ra,0xffffd
    80005ac4:	fd8080e7          	jalr	-40(ra) # 80002a98 <fetchstr>
    80005ac8:	00054663          	bltz	a0,80005ad4 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005acc:	0485                	addi	s1,s1,1
    80005ace:	09a1                	addi	s3,s3,8
    80005ad0:	fb449be3          	bne	s1,s4,80005a86 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ad4:	10090493          	addi	s1,s2,256
    80005ad8:	00093503          	ld	a0,0(s2)
    80005adc:	cd39                	beqz	a0,80005b3a <sys_exec+0x10c>
    kfree(argv[i]);
    80005ade:	ffffb097          	auipc	ra,0xffffb
    80005ae2:	d86080e7          	jalr	-634(ra) # 80000864 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ae6:	0921                	addi	s2,s2,8
    80005ae8:	fe9918e3          	bne	s2,s1,80005ad8 <sys_exec+0xaa>
  return -1;
    80005aec:	557d                	li	a0,-1
    80005aee:	a889                	j	80005b40 <sys_exec+0x112>
      argv[i] = 0;
    80005af0:	0a8e                	slli	s5,s5,0x3
    80005af2:	fc040793          	addi	a5,s0,-64
    80005af6:	9abe                	add	s5,s5,a5
    80005af8:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005afc:	e4040593          	addi	a1,s0,-448
    80005b00:	f4040513          	addi	a0,s0,-192
    80005b04:	fffff097          	auipc	ra,0xfffff
    80005b08:	178080e7          	jalr	376(ra) # 80004c7c <exec>
    80005b0c:	84aa                	mv	s1,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b0e:	10090993          	addi	s3,s2,256
    80005b12:	00093503          	ld	a0,0(s2)
    80005b16:	c901                	beqz	a0,80005b26 <sys_exec+0xf8>
    kfree(argv[i]);
    80005b18:	ffffb097          	auipc	ra,0xffffb
    80005b1c:	d4c080e7          	jalr	-692(ra) # 80000864 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b20:	0921                	addi	s2,s2,8
    80005b22:	ff3918e3          	bne	s2,s3,80005b12 <sys_exec+0xe4>
  return ret;
    80005b26:	8526                	mv	a0,s1
    80005b28:	a821                	j	80005b40 <sys_exec+0x112>
      panic("sys_exec kalloc");
    80005b2a:	00003517          	auipc	a0,0x3
    80005b2e:	d6e50513          	addi	a0,a0,-658 # 80008898 <userret+0x808>
    80005b32:	ffffb097          	auipc	ra,0xffffb
    80005b36:	a16080e7          	jalr	-1514(ra) # 80000548 <panic>
  return -1;
    80005b3a:	557d                	li	a0,-1
    80005b3c:	a011                	j	80005b40 <sys_exec+0x112>
    return -1;
    80005b3e:	557d                	li	a0,-1
}
    80005b40:	60be                	ld	ra,456(sp)
    80005b42:	641e                	ld	s0,448(sp)
    80005b44:	74fa                	ld	s1,440(sp)
    80005b46:	795a                	ld	s2,432(sp)
    80005b48:	79ba                	ld	s3,424(sp)
    80005b4a:	7a1a                	ld	s4,416(sp)
    80005b4c:	6afa                	ld	s5,408(sp)
    80005b4e:	6179                	addi	sp,sp,464
    80005b50:	8082                	ret
    return -1;
    80005b52:	557d                	li	a0,-1
    80005b54:	b7f5                	j	80005b40 <sys_exec+0x112>

0000000080005b56 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b56:	7139                	addi	sp,sp,-64
    80005b58:	fc06                	sd	ra,56(sp)
    80005b5a:	f822                	sd	s0,48(sp)
    80005b5c:	f426                	sd	s1,40(sp)
    80005b5e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b60:	ffffc097          	auipc	ra,0xffffc
    80005b64:	f06080e7          	jalr	-250(ra) # 80001a66 <myproc>
    80005b68:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b6a:	fd840593          	addi	a1,s0,-40
    80005b6e:	4501                	li	a0,0
    80005b70:	ffffd097          	auipc	ra,0xffffd
    80005b74:	f92080e7          	jalr	-110(ra) # 80002b02 <argaddr>
    return -1;
    80005b78:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b7a:	0e054063          	bltz	a0,80005c5a <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b7e:	fc840593          	addi	a1,s0,-56
    80005b82:	fd040513          	addi	a0,s0,-48
    80005b86:	fffff097          	auipc	ra,0xfffff
    80005b8a:	db4080e7          	jalr	-588(ra) # 8000493a <pipealloc>
    return -1;
    80005b8e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b90:	0c054563          	bltz	a0,80005c5a <sys_pipe+0x104>
  fd0 = -1;
    80005b94:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b98:	fd043503          	ld	a0,-48(s0)
    80005b9c:	fffff097          	auipc	ra,0xfffff
    80005ba0:	4d4080e7          	jalr	1236(ra) # 80005070 <fdalloc>
    80005ba4:	fca42223          	sw	a0,-60(s0)
    80005ba8:	08054c63          	bltz	a0,80005c40 <sys_pipe+0xea>
    80005bac:	fc843503          	ld	a0,-56(s0)
    80005bb0:	fffff097          	auipc	ra,0xfffff
    80005bb4:	4c0080e7          	jalr	1216(ra) # 80005070 <fdalloc>
    80005bb8:	fca42023          	sw	a0,-64(s0)
    80005bbc:	06054863          	bltz	a0,80005c2c <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bc0:	4691                	li	a3,4
    80005bc2:	fc440613          	addi	a2,s0,-60
    80005bc6:	fd843583          	ld	a1,-40(s0)
    80005bca:	6ca8                	ld	a0,88(s1)
    80005bcc:	ffffc097          	auipc	ra,0xffffc
    80005bd0:	b8c080e7          	jalr	-1140(ra) # 80001758 <copyout>
    80005bd4:	02054063          	bltz	a0,80005bf4 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bd8:	4691                	li	a3,4
    80005bda:	fc040613          	addi	a2,s0,-64
    80005bde:	fd843583          	ld	a1,-40(s0)
    80005be2:	0591                	addi	a1,a1,4
    80005be4:	6ca8                	ld	a0,88(s1)
    80005be6:	ffffc097          	auipc	ra,0xffffc
    80005bea:	b72080e7          	jalr	-1166(ra) # 80001758 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005bee:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bf0:	06055563          	bgez	a0,80005c5a <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005bf4:	fc442783          	lw	a5,-60(s0)
    80005bf8:	07e9                	addi	a5,a5,26
    80005bfa:	078e                	slli	a5,a5,0x3
    80005bfc:	97a6                	add	a5,a5,s1
    80005bfe:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005c02:	fc042503          	lw	a0,-64(s0)
    80005c06:	0569                	addi	a0,a0,26
    80005c08:	050e                	slli	a0,a0,0x3
    80005c0a:	9526                	add	a0,a0,s1
    80005c0c:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005c10:	fd043503          	ld	a0,-48(s0)
    80005c14:	fffff097          	auipc	ra,0xfffff
    80005c18:	9c2080e7          	jalr	-1598(ra) # 800045d6 <fileclose>
    fileclose(wf);
    80005c1c:	fc843503          	ld	a0,-56(s0)
    80005c20:	fffff097          	auipc	ra,0xfffff
    80005c24:	9b6080e7          	jalr	-1610(ra) # 800045d6 <fileclose>
    return -1;
    80005c28:	57fd                	li	a5,-1
    80005c2a:	a805                	j	80005c5a <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c2c:	fc442783          	lw	a5,-60(s0)
    80005c30:	0007c863          	bltz	a5,80005c40 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c34:	01a78513          	addi	a0,a5,26
    80005c38:	050e                	slli	a0,a0,0x3
    80005c3a:	9526                	add	a0,a0,s1
    80005c3c:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005c40:	fd043503          	ld	a0,-48(s0)
    80005c44:	fffff097          	auipc	ra,0xfffff
    80005c48:	992080e7          	jalr	-1646(ra) # 800045d6 <fileclose>
    fileclose(wf);
    80005c4c:	fc843503          	ld	a0,-56(s0)
    80005c50:	fffff097          	auipc	ra,0xfffff
    80005c54:	986080e7          	jalr	-1658(ra) # 800045d6 <fileclose>
    return -1;
    80005c58:	57fd                	li	a5,-1
}
    80005c5a:	853e                	mv	a0,a5
    80005c5c:	70e2                	ld	ra,56(sp)
    80005c5e:	7442                	ld	s0,48(sp)
    80005c60:	74a2                	ld	s1,40(sp)
    80005c62:	6121                	addi	sp,sp,64
    80005c64:	8082                	ret
	...

0000000080005c70 <kernelvec>:
    80005c70:	7111                	addi	sp,sp,-256
    80005c72:	e006                	sd	ra,0(sp)
    80005c74:	e40a                	sd	sp,8(sp)
    80005c76:	e80e                	sd	gp,16(sp)
    80005c78:	ec12                	sd	tp,24(sp)
    80005c7a:	f016                	sd	t0,32(sp)
    80005c7c:	f41a                	sd	t1,40(sp)
    80005c7e:	f81e                	sd	t2,48(sp)
    80005c80:	fc22                	sd	s0,56(sp)
    80005c82:	e0a6                	sd	s1,64(sp)
    80005c84:	e4aa                	sd	a0,72(sp)
    80005c86:	e8ae                	sd	a1,80(sp)
    80005c88:	ecb2                	sd	a2,88(sp)
    80005c8a:	f0b6                	sd	a3,96(sp)
    80005c8c:	f4ba                	sd	a4,104(sp)
    80005c8e:	f8be                	sd	a5,112(sp)
    80005c90:	fcc2                	sd	a6,120(sp)
    80005c92:	e146                	sd	a7,128(sp)
    80005c94:	e54a                	sd	s2,136(sp)
    80005c96:	e94e                	sd	s3,144(sp)
    80005c98:	ed52                	sd	s4,152(sp)
    80005c9a:	f156                	sd	s5,160(sp)
    80005c9c:	f55a                	sd	s6,168(sp)
    80005c9e:	f95e                	sd	s7,176(sp)
    80005ca0:	fd62                	sd	s8,184(sp)
    80005ca2:	e1e6                	sd	s9,192(sp)
    80005ca4:	e5ea                	sd	s10,200(sp)
    80005ca6:	e9ee                	sd	s11,208(sp)
    80005ca8:	edf2                	sd	t3,216(sp)
    80005caa:	f1f6                	sd	t4,224(sp)
    80005cac:	f5fa                	sd	t5,232(sp)
    80005cae:	f9fe                	sd	t6,240(sp)
    80005cb0:	c63fc0ef          	jal	ra,80002912 <kerneltrap>
    80005cb4:	6082                	ld	ra,0(sp)
    80005cb6:	6122                	ld	sp,8(sp)
    80005cb8:	61c2                	ld	gp,16(sp)
    80005cba:	7282                	ld	t0,32(sp)
    80005cbc:	7322                	ld	t1,40(sp)
    80005cbe:	73c2                	ld	t2,48(sp)
    80005cc0:	7462                	ld	s0,56(sp)
    80005cc2:	6486                	ld	s1,64(sp)
    80005cc4:	6526                	ld	a0,72(sp)
    80005cc6:	65c6                	ld	a1,80(sp)
    80005cc8:	6666                	ld	a2,88(sp)
    80005cca:	7686                	ld	a3,96(sp)
    80005ccc:	7726                	ld	a4,104(sp)
    80005cce:	77c6                	ld	a5,112(sp)
    80005cd0:	7866                	ld	a6,120(sp)
    80005cd2:	688a                	ld	a7,128(sp)
    80005cd4:	692a                	ld	s2,136(sp)
    80005cd6:	69ca                	ld	s3,144(sp)
    80005cd8:	6a6a                	ld	s4,152(sp)
    80005cda:	7a8a                	ld	s5,160(sp)
    80005cdc:	7b2a                	ld	s6,168(sp)
    80005cde:	7bca                	ld	s7,176(sp)
    80005ce0:	7c6a                	ld	s8,184(sp)
    80005ce2:	6c8e                	ld	s9,192(sp)
    80005ce4:	6d2e                	ld	s10,200(sp)
    80005ce6:	6dce                	ld	s11,208(sp)
    80005ce8:	6e6e                	ld	t3,216(sp)
    80005cea:	7e8e                	ld	t4,224(sp)
    80005cec:	7f2e                	ld	t5,232(sp)
    80005cee:	7fce                	ld	t6,240(sp)
    80005cf0:	6111                	addi	sp,sp,256
    80005cf2:	10200073          	sret
    80005cf6:	00000013          	nop
    80005cfa:	00000013          	nop
    80005cfe:	0001                	nop

0000000080005d00 <timervec>:
    80005d00:	34051573          	csrrw	a0,mscratch,a0
    80005d04:	e10c                	sd	a1,0(a0)
    80005d06:	e510                	sd	a2,8(a0)
    80005d08:	e914                	sd	a3,16(a0)
    80005d0a:	710c                	ld	a1,32(a0)
    80005d0c:	7510                	ld	a2,40(a0)
    80005d0e:	6194                	ld	a3,0(a1)
    80005d10:	96b2                	add	a3,a3,a2
    80005d12:	e194                	sd	a3,0(a1)
    80005d14:	4589                	li	a1,2
    80005d16:	14459073          	csrw	sip,a1
    80005d1a:	6914                	ld	a3,16(a0)
    80005d1c:	6510                	ld	a2,8(a0)
    80005d1e:	610c                	ld	a1,0(a0)
    80005d20:	34051573          	csrrw	a0,mscratch,a0
    80005d24:	30200073          	mret
	...

0000000080005d2a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d2a:	1141                	addi	sp,sp,-16
    80005d2c:	e422                	sd	s0,8(sp)
    80005d2e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d30:	0c0007b7          	lui	a5,0xc000
    80005d34:	4705                	li	a4,1
    80005d36:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d38:	c3d8                	sw	a4,4(a5)
}
    80005d3a:	6422                	ld	s0,8(sp)
    80005d3c:	0141                	addi	sp,sp,16
    80005d3e:	8082                	ret

0000000080005d40 <plicinithart>:

void
plicinithart(void)
{
    80005d40:	1141                	addi	sp,sp,-16
    80005d42:	e406                	sd	ra,8(sp)
    80005d44:	e022                	sd	s0,0(sp)
    80005d46:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d48:	ffffc097          	auipc	ra,0xffffc
    80005d4c:	cf2080e7          	jalr	-782(ra) # 80001a3a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d50:	0085171b          	slliw	a4,a0,0x8
    80005d54:	0c0027b7          	lui	a5,0xc002
    80005d58:	97ba                	add	a5,a5,a4
    80005d5a:	40200713          	li	a4,1026
    80005d5e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d62:	00d5151b          	slliw	a0,a0,0xd
    80005d66:	0c2017b7          	lui	a5,0xc201
    80005d6a:	953e                	add	a0,a0,a5
    80005d6c:	00052023          	sw	zero,0(a0)
}
    80005d70:	60a2                	ld	ra,8(sp)
    80005d72:	6402                	ld	s0,0(sp)
    80005d74:	0141                	addi	sp,sp,16
    80005d76:	8082                	ret

0000000080005d78 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d78:	1141                	addi	sp,sp,-16
    80005d7a:	e406                	sd	ra,8(sp)
    80005d7c:	e022                	sd	s0,0(sp)
    80005d7e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d80:	ffffc097          	auipc	ra,0xffffc
    80005d84:	cba080e7          	jalr	-838(ra) # 80001a3a <cpuid>
  //int irq = *(uint32*)(PLIC + 0x201004);
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d88:	00d5179b          	slliw	a5,a0,0xd
    80005d8c:	0c201537          	lui	a0,0xc201
    80005d90:	953e                	add	a0,a0,a5
  return irq;
}
    80005d92:	4148                	lw	a0,4(a0)
    80005d94:	60a2                	ld	ra,8(sp)
    80005d96:	6402                	ld	s0,0(sp)
    80005d98:	0141                	addi	sp,sp,16
    80005d9a:	8082                	ret

0000000080005d9c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d9c:	1101                	addi	sp,sp,-32
    80005d9e:	ec06                	sd	ra,24(sp)
    80005da0:	e822                	sd	s0,16(sp)
    80005da2:	e426                	sd	s1,8(sp)
    80005da4:	1000                	addi	s0,sp,32
    80005da6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005da8:	ffffc097          	auipc	ra,0xffffc
    80005dac:	c92080e7          	jalr	-878(ra) # 80001a3a <cpuid>
  //*(uint32*)(PLIC + 0x201004) = irq;
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005db0:	00d5151b          	slliw	a0,a0,0xd
    80005db4:	0c2017b7          	lui	a5,0xc201
    80005db8:	97aa                	add	a5,a5,a0
    80005dba:	c3c4                	sw	s1,4(a5)
}
    80005dbc:	60e2                	ld	ra,24(sp)
    80005dbe:	6442                	ld	s0,16(sp)
    80005dc0:	64a2                	ld	s1,8(sp)
    80005dc2:	6105                	addi	sp,sp,32
    80005dc4:	8082                	ret

0000000080005dc6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int n, int i)
{
    80005dc6:	1141                	addi	sp,sp,-16
    80005dc8:	e406                	sd	ra,8(sp)
    80005dca:	e022                	sd	s0,0(sp)
    80005dcc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dce:	479d                	li	a5,7
    80005dd0:	06b7c963          	blt	a5,a1,80005e42 <free_desc+0x7c>
    panic("virtio_disk_intr 1");
  if(disk[n].free[i])
    80005dd4:	00151793          	slli	a5,a0,0x1
    80005dd8:	97aa                	add	a5,a5,a0
    80005dda:	00c79713          	slli	a4,a5,0xc
    80005dde:	00020797          	auipc	a5,0x20
    80005de2:	22278793          	addi	a5,a5,546 # 80026000 <disk>
    80005de6:	97ba                	add	a5,a5,a4
    80005de8:	97ae                	add	a5,a5,a1
    80005dea:	6709                	lui	a4,0x2
    80005dec:	97ba                	add	a5,a5,a4
    80005dee:	0187c783          	lbu	a5,24(a5)
    80005df2:	e3a5                	bnez	a5,80005e52 <free_desc+0x8c>
    panic("virtio_disk_intr 2");
  disk[n].desc[i].addr = 0;
    80005df4:	00020817          	auipc	a6,0x20
    80005df8:	20c80813          	addi	a6,a6,524 # 80026000 <disk>
    80005dfc:	00151693          	slli	a3,a0,0x1
    80005e00:	00a68733          	add	a4,a3,a0
    80005e04:	0732                	slli	a4,a4,0xc
    80005e06:	00e807b3          	add	a5,a6,a4
    80005e0a:	6709                	lui	a4,0x2
    80005e0c:	00f70633          	add	a2,a4,a5
    80005e10:	6210                	ld	a2,0(a2)
    80005e12:	00459893          	slli	a7,a1,0x4
    80005e16:	9646                	add	a2,a2,a7
    80005e18:	00063023          	sd	zero,0(a2) # 1000 <_entry-0x7ffff000>
  disk[n].free[i] = 1;
    80005e1c:	97ae                	add	a5,a5,a1
    80005e1e:	97ba                	add	a5,a5,a4
    80005e20:	4605                	li	a2,1
    80005e22:	00c78c23          	sb	a2,24(a5)
  wakeup(&disk[n].free[0]);
    80005e26:	96aa                	add	a3,a3,a0
    80005e28:	06b2                	slli	a3,a3,0xc
    80005e2a:	0761                	addi	a4,a4,24
    80005e2c:	96ba                	add	a3,a3,a4
    80005e2e:	00d80533          	add	a0,a6,a3
    80005e32:	ffffc097          	auipc	ra,0xffffc
    80005e36:	58a080e7          	jalr	1418(ra) # 800023bc <wakeup>
}
    80005e3a:	60a2                	ld	ra,8(sp)
    80005e3c:	6402                	ld	s0,0(sp)
    80005e3e:	0141                	addi	sp,sp,16
    80005e40:	8082                	ret
    panic("virtio_disk_intr 1");
    80005e42:	00003517          	auipc	a0,0x3
    80005e46:	a6650513          	addi	a0,a0,-1434 # 800088a8 <userret+0x818>
    80005e4a:	ffffa097          	auipc	ra,0xffffa
    80005e4e:	6fe080e7          	jalr	1790(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80005e52:	00003517          	auipc	a0,0x3
    80005e56:	a6e50513          	addi	a0,a0,-1426 # 800088c0 <userret+0x830>
    80005e5a:	ffffa097          	auipc	ra,0xffffa
    80005e5e:	6ee080e7          	jalr	1774(ra) # 80000548 <panic>

0000000080005e62 <virtio_disk_init>:
  __sync_synchronize();
    80005e62:	0ff0000f          	fence
  if(disk[n].init)
    80005e66:	00151793          	slli	a5,a0,0x1
    80005e6a:	97aa                	add	a5,a5,a0
    80005e6c:	07b2                	slli	a5,a5,0xc
    80005e6e:	00020717          	auipc	a4,0x20
    80005e72:	19270713          	addi	a4,a4,402 # 80026000 <disk>
    80005e76:	973e                	add	a4,a4,a5
    80005e78:	6789                	lui	a5,0x2
    80005e7a:	97ba                	add	a5,a5,a4
    80005e7c:	0a87a783          	lw	a5,168(a5) # 20a8 <_entry-0x7fffdf58>
    80005e80:	c391                	beqz	a5,80005e84 <virtio_disk_init+0x22>
    80005e82:	8082                	ret
{
    80005e84:	7139                	addi	sp,sp,-64
    80005e86:	fc06                	sd	ra,56(sp)
    80005e88:	f822                	sd	s0,48(sp)
    80005e8a:	f426                	sd	s1,40(sp)
    80005e8c:	f04a                	sd	s2,32(sp)
    80005e8e:	ec4e                	sd	s3,24(sp)
    80005e90:	e852                	sd	s4,16(sp)
    80005e92:	e456                	sd	s5,8(sp)
    80005e94:	0080                	addi	s0,sp,64
    80005e96:	84aa                	mv	s1,a0
  printf("virtio disk init %d\n", n);
    80005e98:	85aa                	mv	a1,a0
    80005e9a:	00003517          	auipc	a0,0x3
    80005e9e:	a3e50513          	addi	a0,a0,-1474 # 800088d8 <userret+0x848>
    80005ea2:	ffffa097          	auipc	ra,0xffffa
    80005ea6:	700080e7          	jalr	1792(ra) # 800005a2 <printf>
  initlock(&disk[n].vdisk_lock, "virtio_disk");
    80005eaa:	00149993          	slli	s3,s1,0x1
    80005eae:	99a6                	add	s3,s3,s1
    80005eb0:	09b2                	slli	s3,s3,0xc
    80005eb2:	6789                	lui	a5,0x2
    80005eb4:	0b078793          	addi	a5,a5,176 # 20b0 <_entry-0x7fffdf50>
    80005eb8:	97ce                	add	a5,a5,s3
    80005eba:	00003597          	auipc	a1,0x3
    80005ebe:	a3658593          	addi	a1,a1,-1482 # 800088f0 <userret+0x860>
    80005ec2:	00020517          	auipc	a0,0x20
    80005ec6:	13e50513          	addi	a0,a0,318 # 80026000 <disk>
    80005eca:	953e                	add	a0,a0,a5
    80005ecc:	ffffb097          	auipc	ra,0xffffb
    80005ed0:	af4080e7          	jalr	-1292(ra) # 800009c0 <initlock>
  if(*R(n, VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ed4:	0014891b          	addiw	s2,s1,1
    80005ed8:	00c9191b          	slliw	s2,s2,0xc
    80005edc:	100007b7          	lui	a5,0x10000
    80005ee0:	97ca                	add	a5,a5,s2
    80005ee2:	4398                	lw	a4,0(a5)
    80005ee4:	2701                	sext.w	a4,a4
    80005ee6:	747277b7          	lui	a5,0x74727
    80005eea:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005eee:	12f71663          	bne	a4,a5,8000601a <virtio_disk_init+0x1b8>
     *R(n, VIRTIO_MMIO_VERSION) != 1 ||
    80005ef2:	100007b7          	lui	a5,0x10000
    80005ef6:	0791                	addi	a5,a5,4
    80005ef8:	97ca                	add	a5,a5,s2
    80005efa:	439c                	lw	a5,0(a5)
    80005efc:	2781                	sext.w	a5,a5
  if(*R(n, VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005efe:	4705                	li	a4,1
    80005f00:	10e79d63          	bne	a5,a4,8000601a <virtio_disk_init+0x1b8>
     *R(n, VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f04:	100007b7          	lui	a5,0x10000
    80005f08:	07a1                	addi	a5,a5,8
    80005f0a:	97ca                	add	a5,a5,s2
    80005f0c:	439c                	lw	a5,0(a5)
    80005f0e:	2781                	sext.w	a5,a5
     *R(n, VIRTIO_MMIO_VERSION) != 1 ||
    80005f10:	4709                	li	a4,2
    80005f12:	10e79463          	bne	a5,a4,8000601a <virtio_disk_init+0x1b8>
     *R(n, VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f16:	100007b7          	lui	a5,0x10000
    80005f1a:	07b1                	addi	a5,a5,12
    80005f1c:	97ca                	add	a5,a5,s2
    80005f1e:	4398                	lw	a4,0(a5)
    80005f20:	2701                	sext.w	a4,a4
     *R(n, VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f22:	554d47b7          	lui	a5,0x554d4
    80005f26:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f2a:	0ef71863          	bne	a4,a5,8000601a <virtio_disk_init+0x1b8>
  *R(n, VIRTIO_MMIO_STATUS) = status;
    80005f2e:	100007b7          	lui	a5,0x10000
    80005f32:	07078693          	addi	a3,a5,112 # 10000070 <_entry-0x6fffff90>
    80005f36:	96ca                	add	a3,a3,s2
    80005f38:	4705                	li	a4,1
    80005f3a:	c298                	sw	a4,0(a3)
  *R(n, VIRTIO_MMIO_STATUS) = status;
    80005f3c:	470d                	li	a4,3
    80005f3e:	c298                	sw	a4,0(a3)
  uint64 features = *R(n, VIRTIO_MMIO_DEVICE_FEATURES);
    80005f40:	01078713          	addi	a4,a5,16
    80005f44:	974a                	add	a4,a4,s2
    80005f46:	430c                	lw	a1,0(a4)
  *R(n, VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f48:	02078613          	addi	a2,a5,32
    80005f4c:	964a                	add	a2,a2,s2
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f4e:	c7ffe737          	lui	a4,0xc7ffe
    80005f52:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd2703>
    80005f56:	8f6d                	and	a4,a4,a1
  *R(n, VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f58:	2701                	sext.w	a4,a4
    80005f5a:	c218                	sw	a4,0(a2)
  *R(n, VIRTIO_MMIO_STATUS) = status;
    80005f5c:	472d                	li	a4,11
    80005f5e:	c298                	sw	a4,0(a3)
  *R(n, VIRTIO_MMIO_STATUS) = status;
    80005f60:	473d                	li	a4,15
    80005f62:	c298                	sw	a4,0(a3)
  *R(n, VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005f64:	02878713          	addi	a4,a5,40
    80005f68:	974a                	add	a4,a4,s2
    80005f6a:	6685                	lui	a3,0x1
    80005f6c:	c314                	sw	a3,0(a4)
  *R(n, VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f6e:	03078713          	addi	a4,a5,48
    80005f72:	974a                	add	a4,a4,s2
    80005f74:	00072023          	sw	zero,0(a4)
  uint32 max = *R(n, VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f78:	03478793          	addi	a5,a5,52
    80005f7c:	97ca                	add	a5,a5,s2
    80005f7e:	439c                	lw	a5,0(a5)
    80005f80:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f82:	c7c5                	beqz	a5,8000602a <virtio_disk_init+0x1c8>
  if(max < NUM)
    80005f84:	471d                	li	a4,7
    80005f86:	0af77a63          	bgeu	a4,a5,8000603a <virtio_disk_init+0x1d8>
  *R(n, VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f8a:	10000ab7          	lui	s5,0x10000
    80005f8e:	038a8793          	addi	a5,s5,56 # 10000038 <_entry-0x6fffffc8>
    80005f92:	97ca                	add	a5,a5,s2
    80005f94:	4721                	li	a4,8
    80005f96:	c398                	sw	a4,0(a5)
  memset(disk[n].pages, 0, sizeof(disk[n].pages));
    80005f98:	00020a17          	auipc	s4,0x20
    80005f9c:	068a0a13          	addi	s4,s4,104 # 80026000 <disk>
    80005fa0:	99d2                	add	s3,s3,s4
    80005fa2:	6609                	lui	a2,0x2
    80005fa4:	4581                	li	a1,0
    80005fa6:	854e                	mv	a0,s3
    80005fa8:	ffffb097          	auipc	ra,0xffffb
    80005fac:	dd4080e7          	jalr	-556(ra) # 80000d7c <memset>
  *R(n, VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk[n].pages) >> PGSHIFT;
    80005fb0:	040a8a93          	addi	s5,s5,64
    80005fb4:	9956                	add	s2,s2,s5
    80005fb6:	00c9d793          	srli	a5,s3,0xc
    80005fba:	2781                	sext.w	a5,a5
    80005fbc:	00f92023          	sw	a5,0(s2)
  disk[n].desc = (struct VRingDesc *) disk[n].pages;
    80005fc0:	00149693          	slli	a3,s1,0x1
    80005fc4:	009687b3          	add	a5,a3,s1
    80005fc8:	07b2                	slli	a5,a5,0xc
    80005fca:	97d2                	add	a5,a5,s4
    80005fcc:	6609                	lui	a2,0x2
    80005fce:	97b2                	add	a5,a5,a2
    80005fd0:	0137b023          	sd	s3,0(a5)
  disk[n].avail = (uint16*)(((char*)disk[n].desc) + NUM*sizeof(struct VRingDesc));
    80005fd4:	08098713          	addi	a4,s3,128
    80005fd8:	e798                	sd	a4,8(a5)
  disk[n].used = (struct UsedArea *) (disk[n].pages + PGSIZE);
    80005fda:	6705                	lui	a4,0x1
    80005fdc:	99ba                	add	s3,s3,a4
    80005fde:	0137b823          	sd	s3,16(a5)
    disk[n].free[i] = 1;
    80005fe2:	4705                	li	a4,1
    80005fe4:	00e78c23          	sb	a4,24(a5)
    80005fe8:	00e78ca3          	sb	a4,25(a5)
    80005fec:	00e78d23          	sb	a4,26(a5)
    80005ff0:	00e78da3          	sb	a4,27(a5)
    80005ff4:	00e78e23          	sb	a4,28(a5)
    80005ff8:	00e78ea3          	sb	a4,29(a5)
    80005ffc:	00e78f23          	sb	a4,30(a5)
    80006000:	00e78fa3          	sb	a4,31(a5)
  disk[n].init = 1;
    80006004:	0ae7a423          	sw	a4,168(a5)
}
    80006008:	70e2                	ld	ra,56(sp)
    8000600a:	7442                	ld	s0,48(sp)
    8000600c:	74a2                	ld	s1,40(sp)
    8000600e:	7902                	ld	s2,32(sp)
    80006010:	69e2                	ld	s3,24(sp)
    80006012:	6a42                	ld	s4,16(sp)
    80006014:	6aa2                	ld	s5,8(sp)
    80006016:	6121                	addi	sp,sp,64
    80006018:	8082                	ret
    panic("could not find virtio disk");
    8000601a:	00003517          	auipc	a0,0x3
    8000601e:	8e650513          	addi	a0,a0,-1818 # 80008900 <userret+0x870>
    80006022:	ffffa097          	auipc	ra,0xffffa
    80006026:	526080e7          	jalr	1318(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    8000602a:	00003517          	auipc	a0,0x3
    8000602e:	8f650513          	addi	a0,a0,-1802 # 80008920 <userret+0x890>
    80006032:	ffffa097          	auipc	ra,0xffffa
    80006036:	516080e7          	jalr	1302(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    8000603a:	00003517          	auipc	a0,0x3
    8000603e:	90650513          	addi	a0,a0,-1786 # 80008940 <userret+0x8b0>
    80006042:	ffffa097          	auipc	ra,0xffffa
    80006046:	506080e7          	jalr	1286(ra) # 80000548 <panic>

000000008000604a <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(int n, struct buf *b, int write)
{
    8000604a:	7135                	addi	sp,sp,-160
    8000604c:	ed06                	sd	ra,152(sp)
    8000604e:	e922                	sd	s0,144(sp)
    80006050:	e526                	sd	s1,136(sp)
    80006052:	e14a                	sd	s2,128(sp)
    80006054:	fcce                	sd	s3,120(sp)
    80006056:	f8d2                	sd	s4,112(sp)
    80006058:	f4d6                	sd	s5,104(sp)
    8000605a:	f0da                	sd	s6,96(sp)
    8000605c:	ecde                	sd	s7,88(sp)
    8000605e:	e8e2                	sd	s8,80(sp)
    80006060:	e4e6                	sd	s9,72(sp)
    80006062:	e0ea                	sd	s10,64(sp)
    80006064:	fc6e                	sd	s11,56(sp)
    80006066:	1100                	addi	s0,sp,160
    80006068:	8aaa                	mv	s5,a0
    8000606a:	8c2e                	mv	s8,a1
    8000606c:	8db2                	mv	s11,a2
  uint64 sector = b->blockno * (BSIZE / 512);
    8000606e:	45dc                	lw	a5,12(a1)
    80006070:	0017979b          	slliw	a5,a5,0x1
    80006074:	1782                	slli	a5,a5,0x20
    80006076:	9381                	srli	a5,a5,0x20
    80006078:	f6f43423          	sd	a5,-152(s0)

  acquire(&disk[n].vdisk_lock);
    8000607c:	00151493          	slli	s1,a0,0x1
    80006080:	94aa                	add	s1,s1,a0
    80006082:	04b2                	slli	s1,s1,0xc
    80006084:	6909                	lui	s2,0x2
    80006086:	0b090c93          	addi	s9,s2,176 # 20b0 <_entry-0x7fffdf50>
    8000608a:	9ca6                	add	s9,s9,s1
    8000608c:	00020997          	auipc	s3,0x20
    80006090:	f7498993          	addi	s3,s3,-140 # 80026000 <disk>
    80006094:	9cce                	add	s9,s9,s3
    80006096:	8566                	mv	a0,s9
    80006098:	ffffb097          	auipc	ra,0xffffb
    8000609c:	a76080e7          	jalr	-1418(ra) # 80000b0e <acquire>
  int idx[3];
  while(1){
    if(alloc3_desc(n, idx) == 0) {
      break;
    }
    sleep(&disk[n].free[0], &disk[n].vdisk_lock);
    800060a0:	0961                	addi	s2,s2,24
    800060a2:	94ca                	add	s1,s1,s2
    800060a4:	99a6                	add	s3,s3,s1
  for(int i = 0; i < 3; i++){
    800060a6:	4a01                	li	s4,0
  for(int i = 0; i < NUM; i++){
    800060a8:	44a1                	li	s1,8
      disk[n].free[i] = 0;
    800060aa:	001a9793          	slli	a5,s5,0x1
    800060ae:	97d6                	add	a5,a5,s5
    800060b0:	07b2                	slli	a5,a5,0xc
    800060b2:	00020b97          	auipc	s7,0x20
    800060b6:	f4eb8b93          	addi	s7,s7,-178 # 80026000 <disk>
    800060ba:	9bbe                	add	s7,s7,a5
    800060bc:	a8a9                	j	80006116 <virtio_disk_rw+0xcc>
    800060be:	00fb8733          	add	a4,s7,a5
    800060c2:	9742                	add	a4,a4,a6
    800060c4:	00070c23          	sb	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    idx[i] = alloc_desc(n);
    800060c8:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800060ca:	0207c263          	bltz	a5,800060ee <virtio_disk_rw+0xa4>
  for(int i = 0; i < 3; i++){
    800060ce:	2905                	addiw	s2,s2,1
    800060d0:	0611                	addi	a2,a2,4
    800060d2:	1ca90463          	beq	s2,a0,8000629a <virtio_disk_rw+0x250>
    idx[i] = alloc_desc(n);
    800060d6:	85b2                	mv	a1,a2
    800060d8:	874e                	mv	a4,s3
  for(int i = 0; i < NUM; i++){
    800060da:	87d2                	mv	a5,s4
    if(disk[n].free[i]){
    800060dc:	00074683          	lbu	a3,0(a4)
    800060e0:	fef9                	bnez	a3,800060be <virtio_disk_rw+0x74>
  for(int i = 0; i < NUM; i++){
    800060e2:	2785                	addiw	a5,a5,1
    800060e4:	0705                	addi	a4,a4,1
    800060e6:	fe979be3          	bne	a5,s1,800060dc <virtio_disk_rw+0x92>
    idx[i] = alloc_desc(n);
    800060ea:	57fd                	li	a5,-1
    800060ec:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800060ee:	01205e63          	blez	s2,8000610a <virtio_disk_rw+0xc0>
    800060f2:	8d52                	mv	s10,s4
        free_desc(n, idx[j]);
    800060f4:	000b2583          	lw	a1,0(s6)
    800060f8:	8556                	mv	a0,s5
    800060fa:	00000097          	auipc	ra,0x0
    800060fe:	ccc080e7          	jalr	-820(ra) # 80005dc6 <free_desc>
      for(int j = 0; j < i; j++)
    80006102:	2d05                	addiw	s10,s10,1
    80006104:	0b11                	addi	s6,s6,4
    80006106:	ffa917e3          	bne	s2,s10,800060f4 <virtio_disk_rw+0xaa>
    sleep(&disk[n].free[0], &disk[n].vdisk_lock);
    8000610a:	85e6                	mv	a1,s9
    8000610c:	854e                	mv	a0,s3
    8000610e:	ffffc097          	auipc	ra,0xffffc
    80006112:	12e080e7          	jalr	302(ra) # 8000223c <sleep>
  for(int i = 0; i < 3; i++){
    80006116:	f8040b13          	addi	s6,s0,-128
{
    8000611a:	865a                	mv	a2,s6
  for(int i = 0; i < 3; i++){
    8000611c:	8952                	mv	s2,s4
      disk[n].free[i] = 0;
    8000611e:	6809                	lui	a6,0x2
  for(int i = 0; i < 3; i++){
    80006120:	450d                	li	a0,3
    80006122:	bf55                	j	800060d6 <virtio_disk_rw+0x8c>
  disk[n].desc[idx[0]].next = idx[1];

  disk[n].desc[idx[1]].addr = (uint64) b->data;
  disk[n].desc[idx[1]].len = BSIZE;
  if(write)
    disk[n].desc[idx[1]].flags = 0; // device reads b->data
    80006124:	001a9793          	slli	a5,s5,0x1
    80006128:	97d6                	add	a5,a5,s5
    8000612a:	07b2                	slli	a5,a5,0xc
    8000612c:	00020717          	auipc	a4,0x20
    80006130:	ed470713          	addi	a4,a4,-300 # 80026000 <disk>
    80006134:	973e                	add	a4,a4,a5
    80006136:	6789                	lui	a5,0x2
    80006138:	97ba                	add	a5,a5,a4
    8000613a:	639c                	ld	a5,0(a5)
    8000613c:	97b6                	add	a5,a5,a3
    8000613e:	00079623          	sh	zero,12(a5) # 200c <_entry-0x7fffdff4>
  else
    disk[n].desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk[n].desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006142:	00020517          	auipc	a0,0x20
    80006146:	ebe50513          	addi	a0,a0,-322 # 80026000 <disk>
    8000614a:	001a9793          	slli	a5,s5,0x1
    8000614e:	01578733          	add	a4,a5,s5
    80006152:	0732                	slli	a4,a4,0xc
    80006154:	972a                	add	a4,a4,a0
    80006156:	6609                	lui	a2,0x2
    80006158:	9732                	add	a4,a4,a2
    8000615a:	6310                	ld	a2,0(a4)
    8000615c:	9636                	add	a2,a2,a3
    8000615e:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006162:	0015e593          	ori	a1,a1,1
    80006166:	00b61623          	sh	a1,12(a2)
  disk[n].desc[idx[1]].next = idx[2];
    8000616a:	f8842603          	lw	a2,-120(s0)
    8000616e:	630c                	ld	a1,0(a4)
    80006170:	96ae                	add	a3,a3,a1
    80006172:	00c69723          	sh	a2,14(a3) # 100e <_entry-0x7fffeff2>

  disk[n].info[idx[0]].status = 0;
    80006176:	97d6                	add	a5,a5,s5
    80006178:	07a2                	slli	a5,a5,0x8
    8000617a:	97a6                	add	a5,a5,s1
    8000617c:	20078793          	addi	a5,a5,512
    80006180:	0792                	slli	a5,a5,0x4
    80006182:	97aa                	add	a5,a5,a0
    80006184:	02078823          	sb	zero,48(a5)
  disk[n].desc[idx[2]].addr = (uint64) &disk[n].info[idx[0]].status;
    80006188:	00461693          	slli	a3,a2,0x4
    8000618c:	00073803          	ld	a6,0(a4)
    80006190:	9836                	add	a6,a6,a3
    80006192:	20348613          	addi	a2,s1,515
    80006196:	001a9593          	slli	a1,s5,0x1
    8000619a:	95d6                	add	a1,a1,s5
    8000619c:	05a2                	slli	a1,a1,0x8
    8000619e:	962e                	add	a2,a2,a1
    800061a0:	0612                	slli	a2,a2,0x4
    800061a2:	962a                	add	a2,a2,a0
    800061a4:	00c83023          	sd	a2,0(a6) # 2000 <_entry-0x7fffe000>
  disk[n].desc[idx[2]].len = 1;
    800061a8:	630c                	ld	a1,0(a4)
    800061aa:	95b6                	add	a1,a1,a3
    800061ac:	4605                	li	a2,1
    800061ae:	c590                	sw	a2,8(a1)
  disk[n].desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061b0:	630c                	ld	a1,0(a4)
    800061b2:	95b6                	add	a1,a1,a3
    800061b4:	4509                	li	a0,2
    800061b6:	00a59623          	sh	a0,12(a1)
  disk[n].desc[idx[2]].next = 0;
    800061ba:	630c                	ld	a1,0(a4)
    800061bc:	96ae                	add	a3,a3,a1
    800061be:	00069723          	sh	zero,14(a3)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800061c2:	00cc2223          	sw	a2,4(s8) # fffffffffffff004 <end+0xffffffff7ffd2fa8>
  disk[n].info[idx[0]].b = b;
    800061c6:	0387b423          	sd	s8,40(a5)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk[n].avail[2 + (disk[n].avail[1] % NUM)] = idx[0];
    800061ca:	6714                	ld	a3,8(a4)
    800061cc:	0026d783          	lhu	a5,2(a3)
    800061d0:	8b9d                	andi	a5,a5,7
    800061d2:	0789                	addi	a5,a5,2
    800061d4:	0786                	slli	a5,a5,0x1
    800061d6:	97b6                	add	a5,a5,a3
    800061d8:	00979023          	sh	s1,0(a5)
  __sync_synchronize();
    800061dc:	0ff0000f          	fence
  disk[n].avail[1] = disk[n].avail[1] + 1;
    800061e0:	6718                	ld	a4,8(a4)
    800061e2:	00275783          	lhu	a5,2(a4)
    800061e6:	2785                	addiw	a5,a5,1
    800061e8:	00f71123          	sh	a5,2(a4)

  *R(n, VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800061ec:	001a879b          	addiw	a5,s5,1
    800061f0:	00c7979b          	slliw	a5,a5,0xc
    800061f4:	10000737          	lui	a4,0x10000
    800061f8:	05070713          	addi	a4,a4,80 # 10000050 <_entry-0x6fffffb0>
    800061fc:	97ba                	add	a5,a5,a4
    800061fe:	0007a023          	sw	zero,0(a5)

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006202:	004c2783          	lw	a5,4(s8)
    80006206:	00c79d63          	bne	a5,a2,80006220 <virtio_disk_rw+0x1d6>
    8000620a:	4485                	li	s1,1
    sleep(b, &disk[n].vdisk_lock);
    8000620c:	85e6                	mv	a1,s9
    8000620e:	8562                	mv	a0,s8
    80006210:	ffffc097          	auipc	ra,0xffffc
    80006214:	02c080e7          	jalr	44(ra) # 8000223c <sleep>
  while(b->disk == 1) {
    80006218:	004c2783          	lw	a5,4(s8)
    8000621c:	fe9788e3          	beq	a5,s1,8000620c <virtio_disk_rw+0x1c2>
  }

  disk[n].info[idx[0]].b = 0;
    80006220:	f8042483          	lw	s1,-128(s0)
    80006224:	001a9793          	slli	a5,s5,0x1
    80006228:	97d6                	add	a5,a5,s5
    8000622a:	07a2                	slli	a5,a5,0x8
    8000622c:	97a6                	add	a5,a5,s1
    8000622e:	20078793          	addi	a5,a5,512
    80006232:	0792                	slli	a5,a5,0x4
    80006234:	00020717          	auipc	a4,0x20
    80006238:	dcc70713          	addi	a4,a4,-564 # 80026000 <disk>
    8000623c:	97ba                	add	a5,a5,a4
    8000623e:	0207b423          	sd	zero,40(a5)
    if(disk[n].desc[i].flags & VRING_DESC_F_NEXT)
    80006242:	001a9793          	slli	a5,s5,0x1
    80006246:	97d6                	add	a5,a5,s5
    80006248:	07b2                	slli	a5,a5,0xc
    8000624a:	97ba                	add	a5,a5,a4
    8000624c:	6909                	lui	s2,0x2
    8000624e:	993e                	add	s2,s2,a5
    80006250:	a019                	j	80006256 <virtio_disk_rw+0x20c>
      i = disk[n].desc[i].next;
    80006252:	00e4d483          	lhu	s1,14(s1)
    free_desc(n, i);
    80006256:	85a6                	mv	a1,s1
    80006258:	8556                	mv	a0,s5
    8000625a:	00000097          	auipc	ra,0x0
    8000625e:	b6c080e7          	jalr	-1172(ra) # 80005dc6 <free_desc>
    if(disk[n].desc[i].flags & VRING_DESC_F_NEXT)
    80006262:	0492                	slli	s1,s1,0x4
    80006264:	00093783          	ld	a5,0(s2) # 2000 <_entry-0x7fffe000>
    80006268:	94be                	add	s1,s1,a5
    8000626a:	00c4d783          	lhu	a5,12(s1)
    8000626e:	8b85                	andi	a5,a5,1
    80006270:	f3ed                	bnez	a5,80006252 <virtio_disk_rw+0x208>
  free_chain(n, idx[0]);

  release(&disk[n].vdisk_lock);
    80006272:	8566                	mv	a0,s9
    80006274:	ffffb097          	auipc	ra,0xffffb
    80006278:	90a080e7          	jalr	-1782(ra) # 80000b7e <release>
}
    8000627c:	60ea                	ld	ra,152(sp)
    8000627e:	644a                	ld	s0,144(sp)
    80006280:	64aa                	ld	s1,136(sp)
    80006282:	690a                	ld	s2,128(sp)
    80006284:	79e6                	ld	s3,120(sp)
    80006286:	7a46                	ld	s4,112(sp)
    80006288:	7aa6                	ld	s5,104(sp)
    8000628a:	7b06                	ld	s6,96(sp)
    8000628c:	6be6                	ld	s7,88(sp)
    8000628e:	6c46                	ld	s8,80(sp)
    80006290:	6ca6                	ld	s9,72(sp)
    80006292:	6d06                	ld	s10,64(sp)
    80006294:	7de2                	ld	s11,56(sp)
    80006296:	610d                	addi	sp,sp,160
    80006298:	8082                	ret
  if(write)
    8000629a:	01b037b3          	snez	a5,s11
    8000629e:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    800062a2:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    800062a6:	f6843783          	ld	a5,-152(s0)
    800062aa:	f6f43c23          	sd	a5,-136(s0)
  disk[n].desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    800062ae:	f8042483          	lw	s1,-128(s0)
    800062b2:	00449993          	slli	s3,s1,0x4
    800062b6:	001a9793          	slli	a5,s5,0x1
    800062ba:	97d6                	add	a5,a5,s5
    800062bc:	07b2                	slli	a5,a5,0xc
    800062be:	00020917          	auipc	s2,0x20
    800062c2:	d4290913          	addi	s2,s2,-702 # 80026000 <disk>
    800062c6:	97ca                	add	a5,a5,s2
    800062c8:	6909                	lui	s2,0x2
    800062ca:	993e                	add	s2,s2,a5
    800062cc:	00093a03          	ld	s4,0(s2) # 2000 <_entry-0x7fffe000>
    800062d0:	9a4e                	add	s4,s4,s3
    800062d2:	f7040513          	addi	a0,s0,-144
    800062d6:	ffffb097          	auipc	ra,0xffffb
    800062da:	ee2080e7          	jalr	-286(ra) # 800011b8 <kvmpa>
    800062de:	00aa3023          	sd	a0,0(s4)
  disk[n].desc[idx[0]].len = sizeof(buf0);
    800062e2:	00093783          	ld	a5,0(s2)
    800062e6:	97ce                	add	a5,a5,s3
    800062e8:	4741                	li	a4,16
    800062ea:	c798                	sw	a4,8(a5)
  disk[n].desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800062ec:	00093783          	ld	a5,0(s2)
    800062f0:	97ce                	add	a5,a5,s3
    800062f2:	4705                	li	a4,1
    800062f4:	00e79623          	sh	a4,12(a5)
  disk[n].desc[idx[0]].next = idx[1];
    800062f8:	f8442683          	lw	a3,-124(s0)
    800062fc:	00093783          	ld	a5,0(s2)
    80006300:	99be                	add	s3,s3,a5
    80006302:	00d99723          	sh	a3,14(s3)
  disk[n].desc[idx[1]].addr = (uint64) b->data;
    80006306:	0692                	slli	a3,a3,0x4
    80006308:	00093783          	ld	a5,0(s2)
    8000630c:	97b6                	add	a5,a5,a3
    8000630e:	060c0713          	addi	a4,s8,96
    80006312:	e398                	sd	a4,0(a5)
  disk[n].desc[idx[1]].len = BSIZE;
    80006314:	00093783          	ld	a5,0(s2)
    80006318:	97b6                	add	a5,a5,a3
    8000631a:	40000713          	li	a4,1024
    8000631e:	c798                	sw	a4,8(a5)
  if(write)
    80006320:	e00d92e3          	bnez	s11,80006124 <virtio_disk_rw+0xda>
    disk[n].desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006324:	001a9793          	slli	a5,s5,0x1
    80006328:	97d6                	add	a5,a5,s5
    8000632a:	07b2                	slli	a5,a5,0xc
    8000632c:	00020717          	auipc	a4,0x20
    80006330:	cd470713          	addi	a4,a4,-812 # 80026000 <disk>
    80006334:	973e                	add	a4,a4,a5
    80006336:	6789                	lui	a5,0x2
    80006338:	97ba                	add	a5,a5,a4
    8000633a:	639c                	ld	a5,0(a5)
    8000633c:	97b6                	add	a5,a5,a3
    8000633e:	4709                	li	a4,2
    80006340:	00e79623          	sh	a4,12(a5) # 200c <_entry-0x7fffdff4>
    80006344:	bbfd                	j	80006142 <virtio_disk_rw+0xf8>

0000000080006346 <virtio_disk_intr>:

void
virtio_disk_intr(int n)
{
    80006346:	7139                	addi	sp,sp,-64
    80006348:	fc06                	sd	ra,56(sp)
    8000634a:	f822                	sd	s0,48(sp)
    8000634c:	f426                	sd	s1,40(sp)
    8000634e:	f04a                	sd	s2,32(sp)
    80006350:	ec4e                	sd	s3,24(sp)
    80006352:	e852                	sd	s4,16(sp)
    80006354:	e456                	sd	s5,8(sp)
    80006356:	0080                	addi	s0,sp,64
    80006358:	84aa                	mv	s1,a0
  acquire(&disk[n].vdisk_lock);
    8000635a:	00151913          	slli	s2,a0,0x1
    8000635e:	00a90a33          	add	s4,s2,a0
    80006362:	0a32                	slli	s4,s4,0xc
    80006364:	6989                	lui	s3,0x2
    80006366:	0b098793          	addi	a5,s3,176 # 20b0 <_entry-0x7fffdf50>
    8000636a:	9a3e                	add	s4,s4,a5
    8000636c:	00020a97          	auipc	s5,0x20
    80006370:	c94a8a93          	addi	s5,s5,-876 # 80026000 <disk>
    80006374:	9a56                	add	s4,s4,s5
    80006376:	8552                	mv	a0,s4
    80006378:	ffffa097          	auipc	ra,0xffffa
    8000637c:	796080e7          	jalr	1942(ra) # 80000b0e <acquire>

  while((disk[n].used_idx % NUM) != (disk[n].used->id % NUM)){
    80006380:	9926                	add	s2,s2,s1
    80006382:	0932                	slli	s2,s2,0xc
    80006384:	9956                	add	s2,s2,s5
    80006386:	99ca                	add	s3,s3,s2
    80006388:	0209d783          	lhu	a5,32(s3)
    8000638c:	0109b703          	ld	a4,16(s3)
    80006390:	00275683          	lhu	a3,2(a4)
    80006394:	8ebd                	xor	a3,a3,a5
    80006396:	8a9d                	andi	a3,a3,7
    80006398:	c2a5                	beqz	a3,800063f8 <virtio_disk_intr+0xb2>
    int id = disk[n].used->elems[disk[n].used_idx].id;

    if(disk[n].info[id].status != 0)
    8000639a:	8956                	mv	s2,s5
    8000639c:	00149693          	slli	a3,s1,0x1
    800063a0:	96a6                	add	a3,a3,s1
    800063a2:	00869993          	slli	s3,a3,0x8
      panic("virtio_disk_intr status");
    
    disk[n].info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk[n].info[id].b);

    disk[n].used_idx = (disk[n].used_idx + 1) % NUM;
    800063a6:	06b2                	slli	a3,a3,0xc
    800063a8:	96d6                	add	a3,a3,s5
    800063aa:	6489                	lui	s1,0x2
    800063ac:	94b6                	add	s1,s1,a3
    int id = disk[n].used->elems[disk[n].used_idx].id;
    800063ae:	078e                	slli	a5,a5,0x3
    800063b0:	97ba                	add	a5,a5,a4
    800063b2:	43dc                	lw	a5,4(a5)
    if(disk[n].info[id].status != 0)
    800063b4:	00f98733          	add	a4,s3,a5
    800063b8:	20070713          	addi	a4,a4,512
    800063bc:	0712                	slli	a4,a4,0x4
    800063be:	974a                	add	a4,a4,s2
    800063c0:	03074703          	lbu	a4,48(a4)
    800063c4:	eb21                	bnez	a4,80006414 <virtio_disk_intr+0xce>
    disk[n].info[id].b->disk = 0;   // disk is done with buf
    800063c6:	97ce                	add	a5,a5,s3
    800063c8:	20078793          	addi	a5,a5,512
    800063cc:	0792                	slli	a5,a5,0x4
    800063ce:	97ca                	add	a5,a5,s2
    800063d0:	7798                	ld	a4,40(a5)
    800063d2:	00072223          	sw	zero,4(a4)
    wakeup(disk[n].info[id].b);
    800063d6:	7788                	ld	a0,40(a5)
    800063d8:	ffffc097          	auipc	ra,0xffffc
    800063dc:	fe4080e7          	jalr	-28(ra) # 800023bc <wakeup>
    disk[n].used_idx = (disk[n].used_idx + 1) % NUM;
    800063e0:	0204d783          	lhu	a5,32(s1) # 2020 <_entry-0x7fffdfe0>
    800063e4:	2785                	addiw	a5,a5,1
    800063e6:	8b9d                	andi	a5,a5,7
    800063e8:	02f49023          	sh	a5,32(s1)
  while((disk[n].used_idx % NUM) != (disk[n].used->id % NUM)){
    800063ec:	6898                	ld	a4,16(s1)
    800063ee:	00275683          	lhu	a3,2(a4)
    800063f2:	8a9d                	andi	a3,a3,7
    800063f4:	faf69de3          	bne	a3,a5,800063ae <virtio_disk_intr+0x68>
  }

  release(&disk[n].vdisk_lock);
    800063f8:	8552                	mv	a0,s4
    800063fa:	ffffa097          	auipc	ra,0xffffa
    800063fe:	784080e7          	jalr	1924(ra) # 80000b7e <release>
}
    80006402:	70e2                	ld	ra,56(sp)
    80006404:	7442                	ld	s0,48(sp)
    80006406:	74a2                	ld	s1,40(sp)
    80006408:	7902                	ld	s2,32(sp)
    8000640a:	69e2                	ld	s3,24(sp)
    8000640c:	6a42                	ld	s4,16(sp)
    8000640e:	6aa2                	ld	s5,8(sp)
    80006410:	6121                	addi	sp,sp,64
    80006412:	8082                	ret
      panic("virtio_disk_intr status");
    80006414:	00002517          	auipc	a0,0x2
    80006418:	54c50513          	addi	a0,a0,1356 # 80008960 <userret+0x8d0>
    8000641c:	ffffa097          	auipc	ra,0xffffa
    80006420:	12c080e7          	jalr	300(ra) # 80000548 <panic>

0000000080006424 <bit_isset>:
static Sz_info *bd_sizes; 
static void *bd_base;   // start address of memory managed by the buddy allocator
static struct spinlock lock;

// Return 1 if bit at position index in array is set to 1
int bit_isset(char *array, int index) {
    80006424:	1141                	addi	sp,sp,-16
    80006426:	e422                	sd	s0,8(sp)
    80006428:	0800                	addi	s0,sp,16
  char b = array[index/8];
  char m = (1 << (index % 8));
    8000642a:	41f5d79b          	sraiw	a5,a1,0x1f
    8000642e:	01d7d79b          	srliw	a5,a5,0x1d
    80006432:	9dbd                	addw	a1,a1,a5
    80006434:	0075f713          	andi	a4,a1,7
    80006438:	9f1d                	subw	a4,a4,a5
    8000643a:	4785                	li	a5,1
    8000643c:	00e797bb          	sllw	a5,a5,a4
    80006440:	0ff7f793          	andi	a5,a5,255
  char b = array[index/8];
    80006444:	4035d59b          	sraiw	a1,a1,0x3
    80006448:	95aa                	add	a1,a1,a0
  return (b & m) == m;
    8000644a:	0005c503          	lbu	a0,0(a1)
    8000644e:	8d7d                	and	a0,a0,a5
    80006450:	8d1d                	sub	a0,a0,a5
}
    80006452:	00153513          	seqz	a0,a0
    80006456:	6422                	ld	s0,8(sp)
    80006458:	0141                	addi	sp,sp,16
    8000645a:	8082                	ret

000000008000645c <bit_set>:

// Set bit at position index in array to 1
void bit_set(char *array, int index) {
    8000645c:	1141                	addi	sp,sp,-16
    8000645e:	e422                	sd	s0,8(sp)
    80006460:	0800                	addi	s0,sp,16
  char b = array[index/8];
    80006462:	41f5d79b          	sraiw	a5,a1,0x1f
    80006466:	01d7d79b          	srliw	a5,a5,0x1d
    8000646a:	9dbd                	addw	a1,a1,a5
    8000646c:	4035d71b          	sraiw	a4,a1,0x3
    80006470:	953a                	add	a0,a0,a4
  char m = (1 << (index % 8));
    80006472:	899d                	andi	a1,a1,7
    80006474:	9d9d                	subw	a1,a1,a5
    80006476:	4785                	li	a5,1
    80006478:	00b795bb          	sllw	a1,a5,a1
  array[index/8] = (b | m);
    8000647c:	00054783          	lbu	a5,0(a0)
    80006480:	8ddd                	or	a1,a1,a5
    80006482:	00b50023          	sb	a1,0(a0)
}
    80006486:	6422                	ld	s0,8(sp)
    80006488:	0141                	addi	sp,sp,16
    8000648a:	8082                	ret

000000008000648c <bit_clear>:

// Clear bit at position index in array
void bit_clear(char *array, int index) {
    8000648c:	1141                	addi	sp,sp,-16
    8000648e:	e422                	sd	s0,8(sp)
    80006490:	0800                	addi	s0,sp,16
  char b = array[index/8];
    80006492:	41f5d79b          	sraiw	a5,a1,0x1f
    80006496:	01d7d79b          	srliw	a5,a5,0x1d
    8000649a:	9dbd                	addw	a1,a1,a5
    8000649c:	4035d71b          	sraiw	a4,a1,0x3
    800064a0:	953a                	add	a0,a0,a4
  char m = (1 << (index % 8));
    800064a2:	899d                	andi	a1,a1,7
    800064a4:	9d9d                	subw	a1,a1,a5
    800064a6:	4785                	li	a5,1
    800064a8:	00b795bb          	sllw	a1,a5,a1
  array[index/8] = (b & ~m);
    800064ac:	fff5c593          	not	a1,a1
    800064b0:	00054783          	lbu	a5,0(a0)
    800064b4:	8dfd                	and	a1,a1,a5
    800064b6:	00b50023          	sb	a1,0(a0)
}
    800064ba:	6422                	ld	s0,8(sp)
    800064bc:	0141                	addi	sp,sp,16
    800064be:	8082                	ret

00000000800064c0 <bd_print_vector>:

// Print a bit vector as a list of ranges of 1 bits
void
bd_print_vector(char *vector, int len) {
    800064c0:	715d                	addi	sp,sp,-80
    800064c2:	e486                	sd	ra,72(sp)
    800064c4:	e0a2                	sd	s0,64(sp)
    800064c6:	fc26                	sd	s1,56(sp)
    800064c8:	f84a                	sd	s2,48(sp)
    800064ca:	f44e                	sd	s3,40(sp)
    800064cc:	f052                	sd	s4,32(sp)
    800064ce:	ec56                	sd	s5,24(sp)
    800064d0:	e85a                	sd	s6,16(sp)
    800064d2:	e45e                	sd	s7,8(sp)
    800064d4:	0880                	addi	s0,sp,80
    800064d6:	8a2e                	mv	s4,a1
  int last, lb;
  
  last = 1;
  lb = 0;
  for (int b = 0; b < len; b++) {
    800064d8:	08b05b63          	blez	a1,8000656e <bd_print_vector+0xae>
    800064dc:	89aa                	mv	s3,a0
    800064de:	4481                	li	s1,0
  lb = 0;
    800064e0:	4a81                	li	s5,0
  last = 1;
    800064e2:	4905                	li	s2,1
    if (last == bit_isset(vector, b))
      continue;
    if(last == 1)
    800064e4:	4b05                	li	s6,1
      printf(" [%d, %d)", lb, b);
    800064e6:	00002b97          	auipc	s7,0x2
    800064ea:	492b8b93          	addi	s7,s7,1170 # 80008978 <userret+0x8e8>
    800064ee:	a821                	j	80006506 <bd_print_vector+0x46>
    lb = b;
    last = bit_isset(vector, b);
    800064f0:	85a6                	mv	a1,s1
    800064f2:	854e                	mv	a0,s3
    800064f4:	00000097          	auipc	ra,0x0
    800064f8:	f30080e7          	jalr	-208(ra) # 80006424 <bit_isset>
    800064fc:	892a                	mv	s2,a0
    800064fe:	8aa6                	mv	s5,s1
  for (int b = 0; b < len; b++) {
    80006500:	2485                	addiw	s1,s1,1
    80006502:	029a0463          	beq	s4,s1,8000652a <bd_print_vector+0x6a>
    if (last == bit_isset(vector, b))
    80006506:	85a6                	mv	a1,s1
    80006508:	854e                	mv	a0,s3
    8000650a:	00000097          	auipc	ra,0x0
    8000650e:	f1a080e7          	jalr	-230(ra) # 80006424 <bit_isset>
    80006512:	ff2507e3          	beq	a0,s2,80006500 <bd_print_vector+0x40>
    if(last == 1)
    80006516:	fd691de3          	bne	s2,s6,800064f0 <bd_print_vector+0x30>
      printf(" [%d, %d)", lb, b);
    8000651a:	8626                	mv	a2,s1
    8000651c:	85d6                	mv	a1,s5
    8000651e:	855e                	mv	a0,s7
    80006520:	ffffa097          	auipc	ra,0xffffa
    80006524:	082080e7          	jalr	130(ra) # 800005a2 <printf>
    80006528:	b7e1                	j	800064f0 <bd_print_vector+0x30>
  }
  if(lb == 0 || last == 1) {
    8000652a:	000a8563          	beqz	s5,80006534 <bd_print_vector+0x74>
    8000652e:	4785                	li	a5,1
    80006530:	00f91c63          	bne	s2,a5,80006548 <bd_print_vector+0x88>
    printf(" [%d, %d)", lb, len);
    80006534:	8652                	mv	a2,s4
    80006536:	85d6                	mv	a1,s5
    80006538:	00002517          	auipc	a0,0x2
    8000653c:	44050513          	addi	a0,a0,1088 # 80008978 <userret+0x8e8>
    80006540:	ffffa097          	auipc	ra,0xffffa
    80006544:	062080e7          	jalr	98(ra) # 800005a2 <printf>
  }
  printf("\n");
    80006548:	00002517          	auipc	a0,0x2
    8000654c:	d4850513          	addi	a0,a0,-696 # 80008290 <userret+0x200>
    80006550:	ffffa097          	auipc	ra,0xffffa
    80006554:	052080e7          	jalr	82(ra) # 800005a2 <printf>
}
    80006558:	60a6                	ld	ra,72(sp)
    8000655a:	6406                	ld	s0,64(sp)
    8000655c:	74e2                	ld	s1,56(sp)
    8000655e:	7942                	ld	s2,48(sp)
    80006560:	79a2                	ld	s3,40(sp)
    80006562:	7a02                	ld	s4,32(sp)
    80006564:	6ae2                	ld	s5,24(sp)
    80006566:	6b42                	ld	s6,16(sp)
    80006568:	6ba2                	ld	s7,8(sp)
    8000656a:	6161                	addi	sp,sp,80
    8000656c:	8082                	ret
  lb = 0;
    8000656e:	4a81                	li	s5,0
    80006570:	b7d1                	j	80006534 <bd_print_vector+0x74>

0000000080006572 <bd_print>:

// Print buddy's data structures
void
bd_print() {
  for (int k = 0; k < nsizes; k++) {
    80006572:	00026697          	auipc	a3,0x26
    80006576:	ae66a683          	lw	a3,-1306(a3) # 8002c058 <nsizes>
    8000657a:	10d05063          	blez	a3,8000667a <bd_print+0x108>
bd_print() {
    8000657e:	711d                	addi	sp,sp,-96
    80006580:	ec86                	sd	ra,88(sp)
    80006582:	e8a2                	sd	s0,80(sp)
    80006584:	e4a6                	sd	s1,72(sp)
    80006586:	e0ca                	sd	s2,64(sp)
    80006588:	fc4e                	sd	s3,56(sp)
    8000658a:	f852                	sd	s4,48(sp)
    8000658c:	f456                	sd	s5,40(sp)
    8000658e:	f05a                	sd	s6,32(sp)
    80006590:	ec5e                	sd	s7,24(sp)
    80006592:	e862                	sd	s8,16(sp)
    80006594:	e466                	sd	s9,8(sp)
    80006596:	e06a                	sd	s10,0(sp)
    80006598:	1080                	addi	s0,sp,96
  for (int k = 0; k < nsizes; k++) {
    8000659a:	4481                	li	s1,0
    printf("size %d (blksz %d nblk %d): free list: ", k, BLK_SIZE(k), NBLK(k));
    8000659c:	4a85                	li	s5,1
    8000659e:	4c41                	li	s8,16
    800065a0:	00002b97          	auipc	s7,0x2
    800065a4:	3e8b8b93          	addi	s7,s7,1000 # 80008988 <userret+0x8f8>
    lst_print(&bd_sizes[k].free);
    800065a8:	00026a17          	auipc	s4,0x26
    800065ac:	aa8a0a13          	addi	s4,s4,-1368 # 8002c050 <bd_sizes>
    printf("  alloc:");
    800065b0:	00002b17          	auipc	s6,0x2
    800065b4:	400b0b13          	addi	s6,s6,1024 # 800089b0 <userret+0x920>
    bd_print_vector(bd_sizes[k].alloc, NBLK(k));
    800065b8:	00026997          	auipc	s3,0x26
    800065bc:	aa098993          	addi	s3,s3,-1376 # 8002c058 <nsizes>
    if(k > 0) {
      printf("  split:");
    800065c0:	00002c97          	auipc	s9,0x2
    800065c4:	400c8c93          	addi	s9,s9,1024 # 800089c0 <userret+0x930>
    800065c8:	a801                	j	800065d8 <bd_print+0x66>
  for (int k = 0; k < nsizes; k++) {
    800065ca:	0009a683          	lw	a3,0(s3)
    800065ce:	0485                	addi	s1,s1,1
    800065d0:	0004879b          	sext.w	a5,s1
    800065d4:	08d7d563          	bge	a5,a3,8000665e <bd_print+0xec>
    800065d8:	0004891b          	sext.w	s2,s1
    printf("size %d (blksz %d nblk %d): free list: ", k, BLK_SIZE(k), NBLK(k));
    800065dc:	36fd                	addiw	a3,a3,-1
    800065de:	9e85                	subw	a3,a3,s1
    800065e0:	00da96bb          	sllw	a3,s5,a3
    800065e4:	009c1633          	sll	a2,s8,s1
    800065e8:	85ca                	mv	a1,s2
    800065ea:	855e                	mv	a0,s7
    800065ec:	ffffa097          	auipc	ra,0xffffa
    800065f0:	fb6080e7          	jalr	-74(ra) # 800005a2 <printf>
    lst_print(&bd_sizes[k].free);
    800065f4:	00549d13          	slli	s10,s1,0x5
    800065f8:	000a3503          	ld	a0,0(s4)
    800065fc:	956a                	add	a0,a0,s10
    800065fe:	00001097          	auipc	ra,0x1
    80006602:	a56080e7          	jalr	-1450(ra) # 80007054 <lst_print>
    printf("  alloc:");
    80006606:	855a                	mv	a0,s6
    80006608:	ffffa097          	auipc	ra,0xffffa
    8000660c:	f9a080e7          	jalr	-102(ra) # 800005a2 <printf>
    bd_print_vector(bd_sizes[k].alloc, NBLK(k));
    80006610:	0009a583          	lw	a1,0(s3)
    80006614:	35fd                	addiw	a1,a1,-1
    80006616:	412585bb          	subw	a1,a1,s2
    8000661a:	000a3783          	ld	a5,0(s4)
    8000661e:	97ea                	add	a5,a5,s10
    80006620:	00ba95bb          	sllw	a1,s5,a1
    80006624:	6b88                	ld	a0,16(a5)
    80006626:	00000097          	auipc	ra,0x0
    8000662a:	e9a080e7          	jalr	-358(ra) # 800064c0 <bd_print_vector>
    if(k > 0) {
    8000662e:	f9205ee3          	blez	s2,800065ca <bd_print+0x58>
      printf("  split:");
    80006632:	8566                	mv	a0,s9
    80006634:	ffffa097          	auipc	ra,0xffffa
    80006638:	f6e080e7          	jalr	-146(ra) # 800005a2 <printf>
      bd_print_vector(bd_sizes[k].split, NBLK(k));
    8000663c:	0009a583          	lw	a1,0(s3)
    80006640:	35fd                	addiw	a1,a1,-1
    80006642:	412585bb          	subw	a1,a1,s2
    80006646:	000a3783          	ld	a5,0(s4)
    8000664a:	9d3e                	add	s10,s10,a5
    8000664c:	00ba95bb          	sllw	a1,s5,a1
    80006650:	018d3503          	ld	a0,24(s10)
    80006654:	00000097          	auipc	ra,0x0
    80006658:	e6c080e7          	jalr	-404(ra) # 800064c0 <bd_print_vector>
    8000665c:	b7bd                	j	800065ca <bd_print+0x58>
    }
  }
}
    8000665e:	60e6                	ld	ra,88(sp)
    80006660:	6446                	ld	s0,80(sp)
    80006662:	64a6                	ld	s1,72(sp)
    80006664:	6906                	ld	s2,64(sp)
    80006666:	79e2                	ld	s3,56(sp)
    80006668:	7a42                	ld	s4,48(sp)
    8000666a:	7aa2                	ld	s5,40(sp)
    8000666c:	7b02                	ld	s6,32(sp)
    8000666e:	6be2                	ld	s7,24(sp)
    80006670:	6c42                	ld	s8,16(sp)
    80006672:	6ca2                	ld	s9,8(sp)
    80006674:	6d02                	ld	s10,0(sp)
    80006676:	6125                	addi	sp,sp,96
    80006678:	8082                	ret
    8000667a:	8082                	ret

000000008000667c <firstk>:

// What is the first k such that 2^k >= n?
int
firstk(uint64 n) {
    8000667c:	1141                	addi	sp,sp,-16
    8000667e:	e422                	sd	s0,8(sp)
    80006680:	0800                	addi	s0,sp,16
  int k = 0;
  uint64 size = LEAF_SIZE;

  while (size < n) {
    80006682:	47c1                	li	a5,16
    80006684:	00a7fb63          	bgeu	a5,a0,8000669a <firstk+0x1e>
    80006688:	872a                	mv	a4,a0
  int k = 0;
    8000668a:	4501                	li	a0,0
    k++;
    8000668c:	2505                	addiw	a0,a0,1
    size *= 2;
    8000668e:	0786                	slli	a5,a5,0x1
  while (size < n) {
    80006690:	fee7eee3          	bltu	a5,a4,8000668c <firstk+0x10>
  }
  return k;
}
    80006694:	6422                	ld	s0,8(sp)
    80006696:	0141                	addi	sp,sp,16
    80006698:	8082                	ret
  int k = 0;
    8000669a:	4501                	li	a0,0
    8000669c:	bfe5                	j	80006694 <firstk+0x18>

000000008000669e <blk_index>:

// Compute the block index for address p at size k
int
blk_index(int k, char *p) {
    8000669e:	1141                	addi	sp,sp,-16
    800066a0:	e422                	sd	s0,8(sp)
    800066a2:	0800                	addi	s0,sp,16
  int n = p - (char *) bd_base;
  return n / BLK_SIZE(k);
    800066a4:	00026797          	auipc	a5,0x26
    800066a8:	9a47b783          	ld	a5,-1628(a5) # 8002c048 <bd_base>
    800066ac:	9d9d                	subw	a1,a1,a5
    800066ae:	47c1                	li	a5,16
    800066b0:	00a797b3          	sll	a5,a5,a0
    800066b4:	02f5c5b3          	div	a1,a1,a5
}
    800066b8:	0005851b          	sext.w	a0,a1
    800066bc:	6422                	ld	s0,8(sp)
    800066be:	0141                	addi	sp,sp,16
    800066c0:	8082                	ret

00000000800066c2 <addr>:

// Convert a block index at size k back into an address
void *addr(int k, int bi) {
    800066c2:	1141                	addi	sp,sp,-16
    800066c4:	e422                	sd	s0,8(sp)
    800066c6:	0800                	addi	s0,sp,16
  int n = bi * BLK_SIZE(k);
    800066c8:	47c1                	li	a5,16
    800066ca:	00a797b3          	sll	a5,a5,a0
  return (char *) bd_base + n;
    800066ce:	02b787bb          	mulw	a5,a5,a1
}
    800066d2:	00026517          	auipc	a0,0x26
    800066d6:	97653503          	ld	a0,-1674(a0) # 8002c048 <bd_base>
    800066da:	953e                	add	a0,a0,a5
    800066dc:	6422                	ld	s0,8(sp)
    800066de:	0141                	addi	sp,sp,16
    800066e0:	8082                	ret

00000000800066e2 <bd_malloc>:

// allocate nbytes, but malloc won't return anything smaller than LEAF_SIZE
void *
bd_malloc(uint64 nbytes)
{
    800066e2:	7159                	addi	sp,sp,-112
    800066e4:	f486                	sd	ra,104(sp)
    800066e6:	f0a2                	sd	s0,96(sp)
    800066e8:	eca6                	sd	s1,88(sp)
    800066ea:	e8ca                	sd	s2,80(sp)
    800066ec:	e4ce                	sd	s3,72(sp)
    800066ee:	e0d2                	sd	s4,64(sp)
    800066f0:	fc56                	sd	s5,56(sp)
    800066f2:	f85a                	sd	s6,48(sp)
    800066f4:	f45e                	sd	s7,40(sp)
    800066f6:	f062                	sd	s8,32(sp)
    800066f8:	ec66                	sd	s9,24(sp)
    800066fa:	e86a                	sd	s10,16(sp)
    800066fc:	e46e                	sd	s11,8(sp)
    800066fe:	1880                	addi	s0,sp,112
    80006700:	84aa                	mv	s1,a0
  int fk, k;

  acquire(&lock);
    80006702:	00026517          	auipc	a0,0x26
    80006706:	8fe50513          	addi	a0,a0,-1794 # 8002c000 <lock>
    8000670a:	ffffa097          	auipc	ra,0xffffa
    8000670e:	404080e7          	jalr	1028(ra) # 80000b0e <acquire>

  // Find a free block >= nbytes, starting with smallest k possible
  fk = firstk(nbytes);
    80006712:	8526                	mv	a0,s1
    80006714:	00000097          	auipc	ra,0x0
    80006718:	f68080e7          	jalr	-152(ra) # 8000667c <firstk>
  for (k = fk; k < nsizes; k++) {
    8000671c:	00026797          	auipc	a5,0x26
    80006720:	93c7a783          	lw	a5,-1732(a5) # 8002c058 <nsizes>
    80006724:	02f55d63          	bge	a0,a5,8000675e <bd_malloc+0x7c>
    80006728:	8c2a                	mv	s8,a0
    8000672a:	00551913          	slli	s2,a0,0x5
    8000672e:	84aa                	mv	s1,a0
    if(!lst_empty(&bd_sizes[k].free))
    80006730:	00026997          	auipc	s3,0x26
    80006734:	92098993          	addi	s3,s3,-1760 # 8002c050 <bd_sizes>
  for (k = fk; k < nsizes; k++) {
    80006738:	00026a17          	auipc	s4,0x26
    8000673c:	920a0a13          	addi	s4,s4,-1760 # 8002c058 <nsizes>
    if(!lst_empty(&bd_sizes[k].free))
    80006740:	0009b503          	ld	a0,0(s3)
    80006744:	954a                	add	a0,a0,s2
    80006746:	00001097          	auipc	ra,0x1
    8000674a:	894080e7          	jalr	-1900(ra) # 80006fda <lst_empty>
    8000674e:	c115                	beqz	a0,80006772 <bd_malloc+0x90>
  for (k = fk; k < nsizes; k++) {
    80006750:	2485                	addiw	s1,s1,1
    80006752:	02090913          	addi	s2,s2,32
    80006756:	000a2783          	lw	a5,0(s4)
    8000675a:	fef4c3e3          	blt	s1,a5,80006740 <bd_malloc+0x5e>
      break;
  }
  if(k >= nsizes) { // No free blocks?
    release(&lock);
    8000675e:	00026517          	auipc	a0,0x26
    80006762:	8a250513          	addi	a0,a0,-1886 # 8002c000 <lock>
    80006766:	ffffa097          	auipc	ra,0xffffa
    8000676a:	418080e7          	jalr	1048(ra) # 80000b7e <release>
    return 0;
    8000676e:	4b01                	li	s6,0
    80006770:	a0e1                	j	80006838 <bd_malloc+0x156>
  if(k >= nsizes) { // No free blocks?
    80006772:	00026797          	auipc	a5,0x26
    80006776:	8e67a783          	lw	a5,-1818(a5) # 8002c058 <nsizes>
    8000677a:	fef4d2e3          	bge	s1,a5,8000675e <bd_malloc+0x7c>
  }

  // Found a block; pop it and potentially split it.
  char *p = lst_pop(&bd_sizes[k].free);
    8000677e:	00549993          	slli	s3,s1,0x5
    80006782:	00026917          	auipc	s2,0x26
    80006786:	8ce90913          	addi	s2,s2,-1842 # 8002c050 <bd_sizes>
    8000678a:	00093503          	ld	a0,0(s2)
    8000678e:	954e                	add	a0,a0,s3
    80006790:	00001097          	auipc	ra,0x1
    80006794:	876080e7          	jalr	-1930(ra) # 80007006 <lst_pop>
    80006798:	8b2a                	mv	s6,a0
  return n / BLK_SIZE(k);
    8000679a:	00026597          	auipc	a1,0x26
    8000679e:	8ae5b583          	ld	a1,-1874(a1) # 8002c048 <bd_base>
    800067a2:	40b505bb          	subw	a1,a0,a1
    800067a6:	47c1                	li	a5,16
    800067a8:	009797b3          	sll	a5,a5,s1
    800067ac:	02f5c5b3          	div	a1,a1,a5
  bit_set(bd_sizes[k].alloc, blk_index(k, p));
    800067b0:	00093783          	ld	a5,0(s2)
    800067b4:	97ce                	add	a5,a5,s3
    800067b6:	2581                	sext.w	a1,a1
    800067b8:	6b88                	ld	a0,16(a5)
    800067ba:	00000097          	auipc	ra,0x0
    800067be:	ca2080e7          	jalr	-862(ra) # 8000645c <bit_set>
  for(; k > fk; k--) {
    800067c2:	069c5363          	bge	s8,s1,80006828 <bd_malloc+0x146>
    // split a block at size k and mark one half allocated at size k-1
    // and put the buddy on the free list at size k-1
    char *q = p + BLK_SIZE(k-1);   // p's buddy
    800067c6:	4bc1                	li	s7,16
    bit_set(bd_sizes[k].split, blk_index(k, p));
    800067c8:	8dca                	mv	s11,s2
  int n = p - (char *) bd_base;
    800067ca:	00026d17          	auipc	s10,0x26
    800067ce:	87ed0d13          	addi	s10,s10,-1922 # 8002c048 <bd_base>
    char *q = p + BLK_SIZE(k-1);   // p's buddy
    800067d2:	85a6                	mv	a1,s1
    800067d4:	34fd                	addiw	s1,s1,-1
    800067d6:	009b9ab3          	sll	s5,s7,s1
    800067da:	015b0cb3          	add	s9,s6,s5
    bit_set(bd_sizes[k].split, blk_index(k, p));
    800067de:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
  int n = p - (char *) bd_base;
    800067e2:	000d3903          	ld	s2,0(s10)
  return n / BLK_SIZE(k);
    800067e6:	412b093b          	subw	s2,s6,s2
    800067ea:	00bb95b3          	sll	a1,s7,a1
    800067ee:	02b945b3          	div	a1,s2,a1
    bit_set(bd_sizes[k].split, blk_index(k, p));
    800067f2:	013a07b3          	add	a5,s4,s3
    800067f6:	2581                	sext.w	a1,a1
    800067f8:	6f88                	ld	a0,24(a5)
    800067fa:	00000097          	auipc	ra,0x0
    800067fe:	c62080e7          	jalr	-926(ra) # 8000645c <bit_set>
    bit_set(bd_sizes[k-1].alloc, blk_index(k-1, p));
    80006802:	1981                	addi	s3,s3,-32
    80006804:	9a4e                	add	s4,s4,s3
  return n / BLK_SIZE(k);
    80006806:	035945b3          	div	a1,s2,s5
    bit_set(bd_sizes[k-1].alloc, blk_index(k-1, p));
    8000680a:	2581                	sext.w	a1,a1
    8000680c:	010a3503          	ld	a0,16(s4)
    80006810:	00000097          	auipc	ra,0x0
    80006814:	c4c080e7          	jalr	-948(ra) # 8000645c <bit_set>
    lst_push(&bd_sizes[k-1].free, q);
    80006818:	85e6                	mv	a1,s9
    8000681a:	8552                	mv	a0,s4
    8000681c:	00001097          	auipc	ra,0x1
    80006820:	820080e7          	jalr	-2016(ra) # 8000703c <lst_push>
  for(; k > fk; k--) {
    80006824:	fb8497e3          	bne	s1,s8,800067d2 <bd_malloc+0xf0>
  }
  release(&lock);
    80006828:	00025517          	auipc	a0,0x25
    8000682c:	7d850513          	addi	a0,a0,2008 # 8002c000 <lock>
    80006830:	ffffa097          	auipc	ra,0xffffa
    80006834:	34e080e7          	jalr	846(ra) # 80000b7e <release>

  return p;
}
    80006838:	855a                	mv	a0,s6
    8000683a:	70a6                	ld	ra,104(sp)
    8000683c:	7406                	ld	s0,96(sp)
    8000683e:	64e6                	ld	s1,88(sp)
    80006840:	6946                	ld	s2,80(sp)
    80006842:	69a6                	ld	s3,72(sp)
    80006844:	6a06                	ld	s4,64(sp)
    80006846:	7ae2                	ld	s5,56(sp)
    80006848:	7b42                	ld	s6,48(sp)
    8000684a:	7ba2                	ld	s7,40(sp)
    8000684c:	7c02                	ld	s8,32(sp)
    8000684e:	6ce2                	ld	s9,24(sp)
    80006850:	6d42                	ld	s10,16(sp)
    80006852:	6da2                	ld	s11,8(sp)
    80006854:	6165                	addi	sp,sp,112
    80006856:	8082                	ret

0000000080006858 <size>:

// Find the size of the block that p points to.
int
size(char *p) {
    80006858:	7139                	addi	sp,sp,-64
    8000685a:	fc06                	sd	ra,56(sp)
    8000685c:	f822                	sd	s0,48(sp)
    8000685e:	f426                	sd	s1,40(sp)
    80006860:	f04a                	sd	s2,32(sp)
    80006862:	ec4e                	sd	s3,24(sp)
    80006864:	e852                	sd	s4,16(sp)
    80006866:	e456                	sd	s5,8(sp)
    80006868:	e05a                	sd	s6,0(sp)
    8000686a:	0080                	addi	s0,sp,64
  for (int k = 0; k < nsizes; k++) {
    8000686c:	00025a97          	auipc	s5,0x25
    80006870:	7ecaaa83          	lw	s5,2028(s5) # 8002c058 <nsizes>
  return n / BLK_SIZE(k);
    80006874:	00025a17          	auipc	s4,0x25
    80006878:	7d4a3a03          	ld	s4,2004(s4) # 8002c048 <bd_base>
    8000687c:	41450a3b          	subw	s4,a0,s4
    80006880:	00025497          	auipc	s1,0x25
    80006884:	7d04b483          	ld	s1,2000(s1) # 8002c050 <bd_sizes>
    80006888:	03848493          	addi	s1,s1,56
  for (int k = 0; k < nsizes; k++) {
    8000688c:	4901                	li	s2,0
  return n / BLK_SIZE(k);
    8000688e:	4b41                	li	s6,16
  for (int k = 0; k < nsizes; k++) {
    80006890:	03595363          	bge	s2,s5,800068b6 <size+0x5e>
    if(bit_isset(bd_sizes[k+1].split, blk_index(k+1, p))) {
    80006894:	0019099b          	addiw	s3,s2,1
  return n / BLK_SIZE(k);
    80006898:	013b15b3          	sll	a1,s6,s3
    8000689c:	02ba45b3          	div	a1,s4,a1
    if(bit_isset(bd_sizes[k+1].split, blk_index(k+1, p))) {
    800068a0:	2581                	sext.w	a1,a1
    800068a2:	6088                	ld	a0,0(s1)
    800068a4:	00000097          	auipc	ra,0x0
    800068a8:	b80080e7          	jalr	-1152(ra) # 80006424 <bit_isset>
    800068ac:	02048493          	addi	s1,s1,32
    800068b0:	e501                	bnez	a0,800068b8 <size+0x60>
  for (int k = 0; k < nsizes; k++) {
    800068b2:	894e                	mv	s2,s3
    800068b4:	bff1                	j	80006890 <size+0x38>
      return k;
    }
  }
  return 0;
    800068b6:	4901                	li	s2,0
}
    800068b8:	854a                	mv	a0,s2
    800068ba:	70e2                	ld	ra,56(sp)
    800068bc:	7442                	ld	s0,48(sp)
    800068be:	74a2                	ld	s1,40(sp)
    800068c0:	7902                	ld	s2,32(sp)
    800068c2:	69e2                	ld	s3,24(sp)
    800068c4:	6a42                	ld	s4,16(sp)
    800068c6:	6aa2                	ld	s5,8(sp)
    800068c8:	6b02                	ld	s6,0(sp)
    800068ca:	6121                	addi	sp,sp,64
    800068cc:	8082                	ret

00000000800068ce <bd_free>:

// Free memory pointed to by p, which was earlier allocated using
// bd_malloc.
void
bd_free(void *p) {
    800068ce:	7159                	addi	sp,sp,-112
    800068d0:	f486                	sd	ra,104(sp)
    800068d2:	f0a2                	sd	s0,96(sp)
    800068d4:	eca6                	sd	s1,88(sp)
    800068d6:	e8ca                	sd	s2,80(sp)
    800068d8:	e4ce                	sd	s3,72(sp)
    800068da:	e0d2                	sd	s4,64(sp)
    800068dc:	fc56                	sd	s5,56(sp)
    800068de:	f85a                	sd	s6,48(sp)
    800068e0:	f45e                	sd	s7,40(sp)
    800068e2:	f062                	sd	s8,32(sp)
    800068e4:	ec66                	sd	s9,24(sp)
    800068e6:	e86a                	sd	s10,16(sp)
    800068e8:	e46e                	sd	s11,8(sp)
    800068ea:	1880                	addi	s0,sp,112
    800068ec:	8aaa                	mv	s5,a0
  void *q;
  int k;

  acquire(&lock);
    800068ee:	00025517          	auipc	a0,0x25
    800068f2:	71250513          	addi	a0,a0,1810 # 8002c000 <lock>
    800068f6:	ffffa097          	auipc	ra,0xffffa
    800068fa:	218080e7          	jalr	536(ra) # 80000b0e <acquire>
  for (k = size(p); k < MAXSIZE; k++) {
    800068fe:	8556                	mv	a0,s5
    80006900:	00000097          	auipc	ra,0x0
    80006904:	f58080e7          	jalr	-168(ra) # 80006858 <size>
    80006908:	84aa                	mv	s1,a0
    8000690a:	00025797          	auipc	a5,0x25
    8000690e:	74e7a783          	lw	a5,1870(a5) # 8002c058 <nsizes>
    80006912:	37fd                	addiw	a5,a5,-1
    80006914:	0cf55063          	bge	a0,a5,800069d4 <bd_free+0x106>
    80006918:	00150a13          	addi	s4,a0,1
    8000691c:	0a16                	slli	s4,s4,0x5
  int n = p - (char *) bd_base;
    8000691e:	00025c17          	auipc	s8,0x25
    80006922:	72ac0c13          	addi	s8,s8,1834 # 8002c048 <bd_base>
  return n / BLK_SIZE(k);
    80006926:	4bc1                	li	s7,16
    int bi = blk_index(k, p);
    int buddy = (bi % 2 == 0) ? bi+1 : bi-1;
    bit_clear(bd_sizes[k].alloc, bi);  // free p at size k
    80006928:	00025b17          	auipc	s6,0x25
    8000692c:	728b0b13          	addi	s6,s6,1832 # 8002c050 <bd_sizes>
  for (k = size(p); k < MAXSIZE; k++) {
    80006930:	00025c97          	auipc	s9,0x25
    80006934:	728c8c93          	addi	s9,s9,1832 # 8002c058 <nsizes>
    80006938:	a82d                	j	80006972 <bd_free+0xa4>
    int buddy = (bi % 2 == 0) ? bi+1 : bi-1;
    8000693a:	fff58d9b          	addiw	s11,a1,-1
    8000693e:	a881                	j	8000698e <bd_free+0xc0>
    if(buddy % 2 == 0) {
      p = q;
    }
    // at size k+1, mark that the merged buddy pair isn't split
    // anymore
    bit_clear(bd_sizes[k+1].split, blk_index(k+1, p));
    80006940:	2485                	addiw	s1,s1,1
  int n = p - (char *) bd_base;
    80006942:	000c3583          	ld	a1,0(s8)
  return n / BLK_SIZE(k);
    80006946:	40ba85bb          	subw	a1,s5,a1
    8000694a:	009b97b3          	sll	a5,s7,s1
    8000694e:	02f5c5b3          	div	a1,a1,a5
    bit_clear(bd_sizes[k+1].split, blk_index(k+1, p));
    80006952:	000b3783          	ld	a5,0(s6)
    80006956:	97d2                	add	a5,a5,s4
    80006958:	2581                	sext.w	a1,a1
    8000695a:	6f88                	ld	a0,24(a5)
    8000695c:	00000097          	auipc	ra,0x0
    80006960:	b30080e7          	jalr	-1232(ra) # 8000648c <bit_clear>
  for (k = size(p); k < MAXSIZE; k++) {
    80006964:	020a0a13          	addi	s4,s4,32
    80006968:	000ca783          	lw	a5,0(s9)
    8000696c:	37fd                	addiw	a5,a5,-1
    8000696e:	06f4d363          	bge	s1,a5,800069d4 <bd_free+0x106>
  int n = p - (char *) bd_base;
    80006972:	000c3903          	ld	s2,0(s8)
  return n / BLK_SIZE(k);
    80006976:	009b99b3          	sll	s3,s7,s1
    8000697a:	412a87bb          	subw	a5,s5,s2
    8000697e:	0337c7b3          	div	a5,a5,s3
    80006982:	0007859b          	sext.w	a1,a5
    int buddy = (bi % 2 == 0) ? bi+1 : bi-1;
    80006986:	8b85                	andi	a5,a5,1
    80006988:	fbcd                	bnez	a5,8000693a <bd_free+0x6c>
    8000698a:	00158d9b          	addiw	s11,a1,1
    bit_clear(bd_sizes[k].alloc, bi);  // free p at size k
    8000698e:	fe0a0d13          	addi	s10,s4,-32
    80006992:	000b3783          	ld	a5,0(s6)
    80006996:	9d3e                	add	s10,s10,a5
    80006998:	010d3503          	ld	a0,16(s10)
    8000699c:	00000097          	auipc	ra,0x0
    800069a0:	af0080e7          	jalr	-1296(ra) # 8000648c <bit_clear>
    if (bit_isset(bd_sizes[k].alloc, buddy)) {  // is buddy allocated?
    800069a4:	85ee                	mv	a1,s11
    800069a6:	010d3503          	ld	a0,16(s10)
    800069aa:	00000097          	auipc	ra,0x0
    800069ae:	a7a080e7          	jalr	-1414(ra) # 80006424 <bit_isset>
    800069b2:	e10d                	bnez	a0,800069d4 <bd_free+0x106>
  int n = bi * BLK_SIZE(k);
    800069b4:	000d8d1b          	sext.w	s10,s11
  return (char *) bd_base + n;
    800069b8:	03b989bb          	mulw	s3,s3,s11
    800069bc:	994e                	add	s2,s2,s3
    lst_remove(q);    // remove buddy from free list
    800069be:	854a                	mv	a0,s2
    800069c0:	00000097          	auipc	ra,0x0
    800069c4:	630080e7          	jalr	1584(ra) # 80006ff0 <lst_remove>
    if(buddy % 2 == 0) {
    800069c8:	001d7d13          	andi	s10,s10,1
    800069cc:	f60d1ae3          	bnez	s10,80006940 <bd_free+0x72>
      p = q;
    800069d0:	8aca                	mv	s5,s2
    800069d2:	b7bd                	j	80006940 <bd_free+0x72>
  }
  lst_push(&bd_sizes[k].free, p);
    800069d4:	0496                	slli	s1,s1,0x5
    800069d6:	85d6                	mv	a1,s5
    800069d8:	00025517          	auipc	a0,0x25
    800069dc:	67853503          	ld	a0,1656(a0) # 8002c050 <bd_sizes>
    800069e0:	9526                	add	a0,a0,s1
    800069e2:	00000097          	auipc	ra,0x0
    800069e6:	65a080e7          	jalr	1626(ra) # 8000703c <lst_push>
  release(&lock);
    800069ea:	00025517          	auipc	a0,0x25
    800069ee:	61650513          	addi	a0,a0,1558 # 8002c000 <lock>
    800069f2:	ffffa097          	auipc	ra,0xffffa
    800069f6:	18c080e7          	jalr	396(ra) # 80000b7e <release>
}
    800069fa:	70a6                	ld	ra,104(sp)
    800069fc:	7406                	ld	s0,96(sp)
    800069fe:	64e6                	ld	s1,88(sp)
    80006a00:	6946                	ld	s2,80(sp)
    80006a02:	69a6                	ld	s3,72(sp)
    80006a04:	6a06                	ld	s4,64(sp)
    80006a06:	7ae2                	ld	s5,56(sp)
    80006a08:	7b42                	ld	s6,48(sp)
    80006a0a:	7ba2                	ld	s7,40(sp)
    80006a0c:	7c02                	ld	s8,32(sp)
    80006a0e:	6ce2                	ld	s9,24(sp)
    80006a10:	6d42                	ld	s10,16(sp)
    80006a12:	6da2                	ld	s11,8(sp)
    80006a14:	6165                	addi	sp,sp,112
    80006a16:	8082                	ret

0000000080006a18 <blk_index_next>:

// Compute the first block at size k that doesn't contain p
int
blk_index_next(int k, char *p) {
    80006a18:	1141                	addi	sp,sp,-16
    80006a1a:	e422                	sd	s0,8(sp)
    80006a1c:	0800                	addi	s0,sp,16
  int n = (p - (char *) bd_base) / BLK_SIZE(k);
    80006a1e:	00025797          	auipc	a5,0x25
    80006a22:	62a7b783          	ld	a5,1578(a5) # 8002c048 <bd_base>
    80006a26:	8d9d                	sub	a1,a1,a5
    80006a28:	47c1                	li	a5,16
    80006a2a:	00a797b3          	sll	a5,a5,a0
    80006a2e:	02f5c533          	div	a0,a1,a5
    80006a32:	2501                	sext.w	a0,a0
  if((p - (char*) bd_base) % BLK_SIZE(k) != 0)
    80006a34:	02f5e5b3          	rem	a1,a1,a5
    80006a38:	c191                	beqz	a1,80006a3c <blk_index_next+0x24>
      n++;
    80006a3a:	2505                	addiw	a0,a0,1
  return n ;
}
    80006a3c:	6422                	ld	s0,8(sp)
    80006a3e:	0141                	addi	sp,sp,16
    80006a40:	8082                	ret

0000000080006a42 <log2>:

int
log2(uint64 n) {
    80006a42:	1141                	addi	sp,sp,-16
    80006a44:	e422                	sd	s0,8(sp)
    80006a46:	0800                	addi	s0,sp,16
  int k = 0;
  while (n > 1) {
    80006a48:	4705                	li	a4,1
    80006a4a:	00a77b63          	bgeu	a4,a0,80006a60 <log2+0x1e>
    80006a4e:	87aa                	mv	a5,a0
  int k = 0;
    80006a50:	4501                	li	a0,0
    k++;
    80006a52:	2505                	addiw	a0,a0,1
    n = n >> 1;
    80006a54:	8385                	srli	a5,a5,0x1
  while (n > 1) {
    80006a56:	fef76ee3          	bltu	a4,a5,80006a52 <log2+0x10>
  }
  return k;
}
    80006a5a:	6422                	ld	s0,8(sp)
    80006a5c:	0141                	addi	sp,sp,16
    80006a5e:	8082                	ret
  int k = 0;
    80006a60:	4501                	li	a0,0
    80006a62:	bfe5                	j	80006a5a <log2+0x18>

0000000080006a64 <bd_mark>:

// Mark memory from [start, stop), starting at size 0, as allocated. 
void
bd_mark(void *start, void *stop)
{
    80006a64:	711d                	addi	sp,sp,-96
    80006a66:	ec86                	sd	ra,88(sp)
    80006a68:	e8a2                	sd	s0,80(sp)
    80006a6a:	e4a6                	sd	s1,72(sp)
    80006a6c:	e0ca                	sd	s2,64(sp)
    80006a6e:	fc4e                	sd	s3,56(sp)
    80006a70:	f852                	sd	s4,48(sp)
    80006a72:	f456                	sd	s5,40(sp)
    80006a74:	f05a                	sd	s6,32(sp)
    80006a76:	ec5e                	sd	s7,24(sp)
    80006a78:	e862                	sd	s8,16(sp)
    80006a7a:	e466                	sd	s9,8(sp)
    80006a7c:	e06a                	sd	s10,0(sp)
    80006a7e:	1080                	addi	s0,sp,96
  int bi, bj;

  if (((uint64) start % LEAF_SIZE != 0) || ((uint64) stop % LEAF_SIZE != 0))
    80006a80:	00b56933          	or	s2,a0,a1
    80006a84:	00f97913          	andi	s2,s2,15
    80006a88:	04091263          	bnez	s2,80006acc <bd_mark+0x68>
    80006a8c:	8b2a                	mv	s6,a0
    80006a8e:	8bae                	mv	s7,a1
    panic("bd_mark");

  for (int k = 0; k < nsizes; k++) {
    80006a90:	00025c17          	auipc	s8,0x25
    80006a94:	5c8c2c03          	lw	s8,1480(s8) # 8002c058 <nsizes>
    80006a98:	4981                	li	s3,0
  int n = p - (char *) bd_base;
    80006a9a:	00025d17          	auipc	s10,0x25
    80006a9e:	5aed0d13          	addi	s10,s10,1454 # 8002c048 <bd_base>
  return n / BLK_SIZE(k);
    80006aa2:	4cc1                	li	s9,16
    bi = blk_index(k, start);
    bj = blk_index_next(k, stop);
    for(; bi < bj; bi++) {
      if(k > 0) {
        // if a block is allocated at size k, mark it as split too.
        bit_set(bd_sizes[k].split, bi);
    80006aa4:	00025a97          	auipc	s5,0x25
    80006aa8:	5aca8a93          	addi	s5,s5,1452 # 8002c050 <bd_sizes>
  for (int k = 0; k < nsizes; k++) {
    80006aac:	07804563          	bgtz	s8,80006b16 <bd_mark+0xb2>
      }
      bit_set(bd_sizes[k].alloc, bi);
    }
  }
}
    80006ab0:	60e6                	ld	ra,88(sp)
    80006ab2:	6446                	ld	s0,80(sp)
    80006ab4:	64a6                	ld	s1,72(sp)
    80006ab6:	6906                	ld	s2,64(sp)
    80006ab8:	79e2                	ld	s3,56(sp)
    80006aba:	7a42                	ld	s4,48(sp)
    80006abc:	7aa2                	ld	s5,40(sp)
    80006abe:	7b02                	ld	s6,32(sp)
    80006ac0:	6be2                	ld	s7,24(sp)
    80006ac2:	6c42                	ld	s8,16(sp)
    80006ac4:	6ca2                	ld	s9,8(sp)
    80006ac6:	6d02                	ld	s10,0(sp)
    80006ac8:	6125                	addi	sp,sp,96
    80006aca:	8082                	ret
    panic("bd_mark");
    80006acc:	00002517          	auipc	a0,0x2
    80006ad0:	f0450513          	addi	a0,a0,-252 # 800089d0 <userret+0x940>
    80006ad4:	ffffa097          	auipc	ra,0xffffa
    80006ad8:	a74080e7          	jalr	-1420(ra) # 80000548 <panic>
      bit_set(bd_sizes[k].alloc, bi);
    80006adc:	000ab783          	ld	a5,0(s5)
    80006ae0:	97ca                	add	a5,a5,s2
    80006ae2:	85a6                	mv	a1,s1
    80006ae4:	6b88                	ld	a0,16(a5)
    80006ae6:	00000097          	auipc	ra,0x0
    80006aea:	976080e7          	jalr	-1674(ra) # 8000645c <bit_set>
    for(; bi < bj; bi++) {
    80006aee:	2485                	addiw	s1,s1,1
    80006af0:	009a0e63          	beq	s4,s1,80006b0c <bd_mark+0xa8>
      if(k > 0) {
    80006af4:	ff3054e3          	blez	s3,80006adc <bd_mark+0x78>
        bit_set(bd_sizes[k].split, bi);
    80006af8:	000ab783          	ld	a5,0(s5)
    80006afc:	97ca                	add	a5,a5,s2
    80006afe:	85a6                	mv	a1,s1
    80006b00:	6f88                	ld	a0,24(a5)
    80006b02:	00000097          	auipc	ra,0x0
    80006b06:	95a080e7          	jalr	-1702(ra) # 8000645c <bit_set>
    80006b0a:	bfc9                	j	80006adc <bd_mark+0x78>
  for (int k = 0; k < nsizes; k++) {
    80006b0c:	2985                	addiw	s3,s3,1
    80006b0e:	02090913          	addi	s2,s2,32
    80006b12:	f9898fe3          	beq	s3,s8,80006ab0 <bd_mark+0x4c>
  int n = p - (char *) bd_base;
    80006b16:	000d3483          	ld	s1,0(s10)
  return n / BLK_SIZE(k);
    80006b1a:	409b04bb          	subw	s1,s6,s1
    80006b1e:	013c97b3          	sll	a5,s9,s3
    80006b22:	02f4c4b3          	div	s1,s1,a5
    80006b26:	2481                	sext.w	s1,s1
    bj = blk_index_next(k, stop);
    80006b28:	85de                	mv	a1,s7
    80006b2a:	854e                	mv	a0,s3
    80006b2c:	00000097          	auipc	ra,0x0
    80006b30:	eec080e7          	jalr	-276(ra) # 80006a18 <blk_index_next>
    80006b34:	8a2a                	mv	s4,a0
    for(; bi < bj; bi++) {
    80006b36:	faa4cfe3          	blt	s1,a0,80006af4 <bd_mark+0x90>
    80006b3a:	bfc9                	j	80006b0c <bd_mark+0xa8>

0000000080006b3c <bd_initfree_pair>:

// If a block is marked as allocated and the buddy is free, put the
// buddy on the free list at size k.
int
bd_initfree_pair(int k, int bi) {
    80006b3c:	7139                	addi	sp,sp,-64
    80006b3e:	fc06                	sd	ra,56(sp)
    80006b40:	f822                	sd	s0,48(sp)
    80006b42:	f426                	sd	s1,40(sp)
    80006b44:	f04a                	sd	s2,32(sp)
    80006b46:	ec4e                	sd	s3,24(sp)
    80006b48:	e852                	sd	s4,16(sp)
    80006b4a:	e456                	sd	s5,8(sp)
    80006b4c:	e05a                	sd	s6,0(sp)
    80006b4e:	0080                	addi	s0,sp,64
    80006b50:	89aa                	mv	s3,a0
  int buddy = (bi % 2 == 0) ? bi+1 : bi-1;
    80006b52:	00058a9b          	sext.w	s5,a1
    80006b56:	0015f793          	andi	a5,a1,1
    80006b5a:	ebad                	bnez	a5,80006bcc <bd_initfree_pair+0x90>
    80006b5c:	00158a1b          	addiw	s4,a1,1
  int free = 0;
  if(bit_isset(bd_sizes[k].alloc, bi) !=  bit_isset(bd_sizes[k].alloc, buddy)) {
    80006b60:	00599493          	slli	s1,s3,0x5
    80006b64:	00025797          	auipc	a5,0x25
    80006b68:	4ec7b783          	ld	a5,1260(a5) # 8002c050 <bd_sizes>
    80006b6c:	94be                	add	s1,s1,a5
    80006b6e:	0104bb03          	ld	s6,16(s1)
    80006b72:	855a                	mv	a0,s6
    80006b74:	00000097          	auipc	ra,0x0
    80006b78:	8b0080e7          	jalr	-1872(ra) # 80006424 <bit_isset>
    80006b7c:	892a                	mv	s2,a0
    80006b7e:	85d2                	mv	a1,s4
    80006b80:	855a                	mv	a0,s6
    80006b82:	00000097          	auipc	ra,0x0
    80006b86:	8a2080e7          	jalr	-1886(ra) # 80006424 <bit_isset>
  int free = 0;
    80006b8a:	4b01                	li	s6,0
  if(bit_isset(bd_sizes[k].alloc, bi) !=  bit_isset(bd_sizes[k].alloc, buddy)) {
    80006b8c:	02a90563          	beq	s2,a0,80006bb6 <bd_initfree_pair+0x7a>
    // one of the pair is free
    free = BLK_SIZE(k);
    80006b90:	45c1                	li	a1,16
    80006b92:	013599b3          	sll	s3,a1,s3
    80006b96:	00098b1b          	sext.w	s6,s3
    if(bit_isset(bd_sizes[k].alloc, bi))
    80006b9a:	02090c63          	beqz	s2,80006bd2 <bd_initfree_pair+0x96>
  return (char *) bd_base + n;
    80006b9e:	034989bb          	mulw	s3,s3,s4
      lst_push(&bd_sizes[k].free, addr(k, buddy));   // put buddy on free list
    80006ba2:	00025597          	auipc	a1,0x25
    80006ba6:	4a65b583          	ld	a1,1190(a1) # 8002c048 <bd_base>
    80006baa:	95ce                	add	a1,a1,s3
    80006bac:	8526                	mv	a0,s1
    80006bae:	00000097          	auipc	ra,0x0
    80006bb2:	48e080e7          	jalr	1166(ra) # 8000703c <lst_push>
    else
      lst_push(&bd_sizes[k].free, addr(k, bi));      // put bi on free list
  }
  return free;
}
    80006bb6:	855a                	mv	a0,s6
    80006bb8:	70e2                	ld	ra,56(sp)
    80006bba:	7442                	ld	s0,48(sp)
    80006bbc:	74a2                	ld	s1,40(sp)
    80006bbe:	7902                	ld	s2,32(sp)
    80006bc0:	69e2                	ld	s3,24(sp)
    80006bc2:	6a42                	ld	s4,16(sp)
    80006bc4:	6aa2                	ld	s5,8(sp)
    80006bc6:	6b02                	ld	s6,0(sp)
    80006bc8:	6121                	addi	sp,sp,64
    80006bca:	8082                	ret
  int buddy = (bi % 2 == 0) ? bi+1 : bi-1;
    80006bcc:	fff58a1b          	addiw	s4,a1,-1
    80006bd0:	bf41                	j	80006b60 <bd_initfree_pair+0x24>
  return (char *) bd_base + n;
    80006bd2:	035989bb          	mulw	s3,s3,s5
      lst_push(&bd_sizes[k].free, addr(k, bi));      // put bi on free list
    80006bd6:	00025597          	auipc	a1,0x25
    80006bda:	4725b583          	ld	a1,1138(a1) # 8002c048 <bd_base>
    80006bde:	95ce                	add	a1,a1,s3
    80006be0:	8526                	mv	a0,s1
    80006be2:	00000097          	auipc	ra,0x0
    80006be6:	45a080e7          	jalr	1114(ra) # 8000703c <lst_push>
    80006bea:	b7f1                	j	80006bb6 <bd_initfree_pair+0x7a>

0000000080006bec <bd_initfree>:
  
// Initialize the free lists for each size k.  For each size k, there
// are only two pairs that may have a buddy that should be on free list:
// bd_left and bd_right.
int
bd_initfree(void *bd_left, void *bd_right) {
    80006bec:	711d                	addi	sp,sp,-96
    80006bee:	ec86                	sd	ra,88(sp)
    80006bf0:	e8a2                	sd	s0,80(sp)
    80006bf2:	e4a6                	sd	s1,72(sp)
    80006bf4:	e0ca                	sd	s2,64(sp)
    80006bf6:	fc4e                	sd	s3,56(sp)
    80006bf8:	f852                	sd	s4,48(sp)
    80006bfa:	f456                	sd	s5,40(sp)
    80006bfc:	f05a                	sd	s6,32(sp)
    80006bfe:	ec5e                	sd	s7,24(sp)
    80006c00:	e862                	sd	s8,16(sp)
    80006c02:	e466                	sd	s9,8(sp)
    80006c04:	e06a                	sd	s10,0(sp)
    80006c06:	1080                	addi	s0,sp,96
  int free = 0;

  for (int k = 0; k < MAXSIZE; k++) {   // skip max size
    80006c08:	00025717          	auipc	a4,0x25
    80006c0c:	45072703          	lw	a4,1104(a4) # 8002c058 <nsizes>
    80006c10:	4785                	li	a5,1
    80006c12:	06e7db63          	bge	a5,a4,80006c88 <bd_initfree+0x9c>
    80006c16:	8aaa                	mv	s5,a0
    80006c18:	8b2e                	mv	s6,a1
    80006c1a:	4901                	li	s2,0
  int free = 0;
    80006c1c:	4a01                	li	s4,0
  int n = p - (char *) bd_base;
    80006c1e:	00025c97          	auipc	s9,0x25
    80006c22:	42ac8c93          	addi	s9,s9,1066 # 8002c048 <bd_base>
  return n / BLK_SIZE(k);
    80006c26:	4c41                	li	s8,16
  for (int k = 0; k < MAXSIZE; k++) {   // skip max size
    80006c28:	00025b97          	auipc	s7,0x25
    80006c2c:	430b8b93          	addi	s7,s7,1072 # 8002c058 <nsizes>
    80006c30:	a039                	j	80006c3e <bd_initfree+0x52>
    80006c32:	2905                	addiw	s2,s2,1
    80006c34:	000ba783          	lw	a5,0(s7)
    80006c38:	37fd                	addiw	a5,a5,-1
    80006c3a:	04f95863          	bge	s2,a5,80006c8a <bd_initfree+0x9e>
    int left = blk_index_next(k, bd_left);
    80006c3e:	85d6                	mv	a1,s5
    80006c40:	854a                	mv	a0,s2
    80006c42:	00000097          	auipc	ra,0x0
    80006c46:	dd6080e7          	jalr	-554(ra) # 80006a18 <blk_index_next>
    80006c4a:	89aa                	mv	s3,a0
  int n = p - (char *) bd_base;
    80006c4c:	000cb483          	ld	s1,0(s9)
  return n / BLK_SIZE(k);
    80006c50:	409b04bb          	subw	s1,s6,s1
    80006c54:	012c17b3          	sll	a5,s8,s2
    80006c58:	02f4c4b3          	div	s1,s1,a5
    80006c5c:	2481                	sext.w	s1,s1
    int right = blk_index(k, bd_right);
    free += bd_initfree_pair(k, left);
    80006c5e:	85aa                	mv	a1,a0
    80006c60:	854a                	mv	a0,s2
    80006c62:	00000097          	auipc	ra,0x0
    80006c66:	eda080e7          	jalr	-294(ra) # 80006b3c <bd_initfree_pair>
    80006c6a:	01450d3b          	addw	s10,a0,s4
    80006c6e:	000d0a1b          	sext.w	s4,s10
    if(right <= left)
    80006c72:	fc99d0e3          	bge	s3,s1,80006c32 <bd_initfree+0x46>
      continue;
    free += bd_initfree_pair(k, right);
    80006c76:	85a6                	mv	a1,s1
    80006c78:	854a                	mv	a0,s2
    80006c7a:	00000097          	auipc	ra,0x0
    80006c7e:	ec2080e7          	jalr	-318(ra) # 80006b3c <bd_initfree_pair>
    80006c82:	00ad0a3b          	addw	s4,s10,a0
    80006c86:	b775                	j	80006c32 <bd_initfree+0x46>
  int free = 0;
    80006c88:	4a01                	li	s4,0
  }
  return free;
}
    80006c8a:	8552                	mv	a0,s4
    80006c8c:	60e6                	ld	ra,88(sp)
    80006c8e:	6446                	ld	s0,80(sp)
    80006c90:	64a6                	ld	s1,72(sp)
    80006c92:	6906                	ld	s2,64(sp)
    80006c94:	79e2                	ld	s3,56(sp)
    80006c96:	7a42                	ld	s4,48(sp)
    80006c98:	7aa2                	ld	s5,40(sp)
    80006c9a:	7b02                	ld	s6,32(sp)
    80006c9c:	6be2                	ld	s7,24(sp)
    80006c9e:	6c42                	ld	s8,16(sp)
    80006ca0:	6ca2                	ld	s9,8(sp)
    80006ca2:	6d02                	ld	s10,0(sp)
    80006ca4:	6125                	addi	sp,sp,96
    80006ca6:	8082                	ret

0000000080006ca8 <bd_mark_data_structures>:

// Mark the range [bd_base,p) as allocated
int
bd_mark_data_structures(char *p) {
    80006ca8:	7179                	addi	sp,sp,-48
    80006caa:	f406                	sd	ra,40(sp)
    80006cac:	f022                	sd	s0,32(sp)
    80006cae:	ec26                	sd	s1,24(sp)
    80006cb0:	e84a                	sd	s2,16(sp)
    80006cb2:	e44e                	sd	s3,8(sp)
    80006cb4:	1800                	addi	s0,sp,48
    80006cb6:	892a                	mv	s2,a0
  int meta = p - (char*)bd_base;
    80006cb8:	00025997          	auipc	s3,0x25
    80006cbc:	39098993          	addi	s3,s3,912 # 8002c048 <bd_base>
    80006cc0:	0009b483          	ld	s1,0(s3)
    80006cc4:	409504bb          	subw	s1,a0,s1
  printf("bd: %d meta bytes for managing %d bytes of memory\n", meta, BLK_SIZE(MAXSIZE));
    80006cc8:	00025797          	auipc	a5,0x25
    80006ccc:	3907a783          	lw	a5,912(a5) # 8002c058 <nsizes>
    80006cd0:	37fd                	addiw	a5,a5,-1
    80006cd2:	4641                	li	a2,16
    80006cd4:	00f61633          	sll	a2,a2,a5
    80006cd8:	85a6                	mv	a1,s1
    80006cda:	00002517          	auipc	a0,0x2
    80006cde:	cfe50513          	addi	a0,a0,-770 # 800089d8 <userret+0x948>
    80006ce2:	ffffa097          	auipc	ra,0xffffa
    80006ce6:	8c0080e7          	jalr	-1856(ra) # 800005a2 <printf>
  bd_mark(bd_base, p);
    80006cea:	85ca                	mv	a1,s2
    80006cec:	0009b503          	ld	a0,0(s3)
    80006cf0:	00000097          	auipc	ra,0x0
    80006cf4:	d74080e7          	jalr	-652(ra) # 80006a64 <bd_mark>
  return meta;
}
    80006cf8:	8526                	mv	a0,s1
    80006cfa:	70a2                	ld	ra,40(sp)
    80006cfc:	7402                	ld	s0,32(sp)
    80006cfe:	64e2                	ld	s1,24(sp)
    80006d00:	6942                	ld	s2,16(sp)
    80006d02:	69a2                	ld	s3,8(sp)
    80006d04:	6145                	addi	sp,sp,48
    80006d06:	8082                	ret

0000000080006d08 <bd_mark_unavailable>:

// Mark the range [end, HEAPSIZE) as allocated
int
bd_mark_unavailable(void *end, void *left) {
    80006d08:	1101                	addi	sp,sp,-32
    80006d0a:	ec06                	sd	ra,24(sp)
    80006d0c:	e822                	sd	s0,16(sp)
    80006d0e:	e426                	sd	s1,8(sp)
    80006d10:	1000                	addi	s0,sp,32
  int unavailable = BLK_SIZE(MAXSIZE)-(end-bd_base);
    80006d12:	00025497          	auipc	s1,0x25
    80006d16:	3464a483          	lw	s1,838(s1) # 8002c058 <nsizes>
    80006d1a:	fff4879b          	addiw	a5,s1,-1
    80006d1e:	44c1                	li	s1,16
    80006d20:	00f494b3          	sll	s1,s1,a5
    80006d24:	00025797          	auipc	a5,0x25
    80006d28:	3247b783          	ld	a5,804(a5) # 8002c048 <bd_base>
    80006d2c:	8d1d                	sub	a0,a0,a5
    80006d2e:	40a4853b          	subw	a0,s1,a0
    80006d32:	0005049b          	sext.w	s1,a0
  if(unavailable > 0)
    80006d36:	00905a63          	blez	s1,80006d4a <bd_mark_unavailable+0x42>
    unavailable = ROUNDUP(unavailable, LEAF_SIZE);
    80006d3a:	357d                	addiw	a0,a0,-1
    80006d3c:	41f5549b          	sraiw	s1,a0,0x1f
    80006d40:	01c4d49b          	srliw	s1,s1,0x1c
    80006d44:	9ca9                	addw	s1,s1,a0
    80006d46:	98c1                	andi	s1,s1,-16
    80006d48:	24c1                	addiw	s1,s1,16
  printf("bd: 0x%x bytes unavailable\n", unavailable);
    80006d4a:	85a6                	mv	a1,s1
    80006d4c:	00002517          	auipc	a0,0x2
    80006d50:	cc450513          	addi	a0,a0,-828 # 80008a10 <userret+0x980>
    80006d54:	ffffa097          	auipc	ra,0xffffa
    80006d58:	84e080e7          	jalr	-1970(ra) # 800005a2 <printf>

  void *bd_end = bd_base+BLK_SIZE(MAXSIZE)-unavailable;
    80006d5c:	00025717          	auipc	a4,0x25
    80006d60:	2ec73703          	ld	a4,748(a4) # 8002c048 <bd_base>
    80006d64:	00025597          	auipc	a1,0x25
    80006d68:	2f45a583          	lw	a1,756(a1) # 8002c058 <nsizes>
    80006d6c:	fff5879b          	addiw	a5,a1,-1
    80006d70:	45c1                	li	a1,16
    80006d72:	00f595b3          	sll	a1,a1,a5
    80006d76:	40958533          	sub	a0,a1,s1
  bd_mark(bd_end, bd_base+BLK_SIZE(MAXSIZE));
    80006d7a:	95ba                	add	a1,a1,a4
    80006d7c:	953a                	add	a0,a0,a4
    80006d7e:	00000097          	auipc	ra,0x0
    80006d82:	ce6080e7          	jalr	-794(ra) # 80006a64 <bd_mark>
  return unavailable;
}
    80006d86:	8526                	mv	a0,s1
    80006d88:	60e2                	ld	ra,24(sp)
    80006d8a:	6442                	ld	s0,16(sp)
    80006d8c:	64a2                	ld	s1,8(sp)
    80006d8e:	6105                	addi	sp,sp,32
    80006d90:	8082                	ret

0000000080006d92 <bd_init>:

// Initialize the buddy allocator: it manages memory from [base, end).
void
bd_init(void *base, void *end) {
    80006d92:	715d                	addi	sp,sp,-80
    80006d94:	e486                	sd	ra,72(sp)
    80006d96:	e0a2                	sd	s0,64(sp)
    80006d98:	fc26                	sd	s1,56(sp)
    80006d9a:	f84a                	sd	s2,48(sp)
    80006d9c:	f44e                	sd	s3,40(sp)
    80006d9e:	f052                	sd	s4,32(sp)
    80006da0:	ec56                	sd	s5,24(sp)
    80006da2:	e85a                	sd	s6,16(sp)
    80006da4:	e45e                	sd	s7,8(sp)
    80006da6:	e062                	sd	s8,0(sp)
    80006da8:	0880                	addi	s0,sp,80
    80006daa:	8c2e                	mv	s8,a1
  char *p = (char *) ROUNDUP((uint64)base, LEAF_SIZE);
    80006dac:	fff50493          	addi	s1,a0,-1
    80006db0:	98c1                	andi	s1,s1,-16
    80006db2:	04c1                	addi	s1,s1,16
  int sz;

  initlock(&lock, "buddy");
    80006db4:	00002597          	auipc	a1,0x2
    80006db8:	c7c58593          	addi	a1,a1,-900 # 80008a30 <userret+0x9a0>
    80006dbc:	00025517          	auipc	a0,0x25
    80006dc0:	24450513          	addi	a0,a0,580 # 8002c000 <lock>
    80006dc4:	ffffa097          	auipc	ra,0xffffa
    80006dc8:	bfc080e7          	jalr	-1028(ra) # 800009c0 <initlock>
  bd_base = (void *) p;
    80006dcc:	00025797          	auipc	a5,0x25
    80006dd0:	2697be23          	sd	s1,636(a5) # 8002c048 <bd_base>

  // compute the number of sizes we need to manage [base, end)
  nsizes = log2(((char *)end-p)/LEAF_SIZE) + 1;
    80006dd4:	409c0933          	sub	s2,s8,s1
    80006dd8:	43f95513          	srai	a0,s2,0x3f
    80006ddc:	893d                	andi	a0,a0,15
    80006dde:	954a                	add	a0,a0,s2
    80006de0:	8511                	srai	a0,a0,0x4
    80006de2:	00000097          	auipc	ra,0x0
    80006de6:	c60080e7          	jalr	-928(ra) # 80006a42 <log2>
  if((char*)end-p > BLK_SIZE(MAXSIZE)) {
    80006dea:	47c1                	li	a5,16
    80006dec:	00a797b3          	sll	a5,a5,a0
    80006df0:	1b27c663          	blt	a5,s2,80006f9c <bd_init+0x20a>
  nsizes = log2(((char *)end-p)/LEAF_SIZE) + 1;
    80006df4:	2505                	addiw	a0,a0,1
    80006df6:	00025797          	auipc	a5,0x25
    80006dfa:	26a7a123          	sw	a0,610(a5) # 8002c058 <nsizes>
    nsizes++;  // round up to the next power of 2
  }

  printf("bd: memory sz is %d bytes; allocate an size array of length %d\n",
    80006dfe:	00025997          	auipc	s3,0x25
    80006e02:	25a98993          	addi	s3,s3,602 # 8002c058 <nsizes>
    80006e06:	0009a603          	lw	a2,0(s3)
    80006e0a:	85ca                	mv	a1,s2
    80006e0c:	00002517          	auipc	a0,0x2
    80006e10:	c2c50513          	addi	a0,a0,-980 # 80008a38 <userret+0x9a8>
    80006e14:	ffff9097          	auipc	ra,0xffff9
    80006e18:	78e080e7          	jalr	1934(ra) # 800005a2 <printf>
         (char*) end - p, nsizes);

  // allocate bd_sizes array
  bd_sizes = (Sz_info *) p;
    80006e1c:	00025797          	auipc	a5,0x25
    80006e20:	2297ba23          	sd	s1,564(a5) # 8002c050 <bd_sizes>
  p += sizeof(Sz_info) * nsizes;
    80006e24:	0009a603          	lw	a2,0(s3)
    80006e28:	00561913          	slli	s2,a2,0x5
    80006e2c:	9926                	add	s2,s2,s1
  memset(bd_sizes, 0, sizeof(Sz_info) * nsizes);
    80006e2e:	0056161b          	slliw	a2,a2,0x5
    80006e32:	4581                	li	a1,0
    80006e34:	8526                	mv	a0,s1
    80006e36:	ffffa097          	auipc	ra,0xffffa
    80006e3a:	f46080e7          	jalr	-186(ra) # 80000d7c <memset>

  // initialize free list and allocate the alloc array for each size k
  for (int k = 0; k < nsizes; k++) {
    80006e3e:	0009a783          	lw	a5,0(s3)
    80006e42:	06f05a63          	blez	a5,80006eb6 <bd_init+0x124>
    80006e46:	4981                	li	s3,0
    lst_init(&bd_sizes[k].free);
    80006e48:	00025a97          	auipc	s5,0x25
    80006e4c:	208a8a93          	addi	s5,s5,520 # 8002c050 <bd_sizes>
    sz = sizeof(char)* ROUNDUP(NBLK(k), 8)/8;
    80006e50:	00025a17          	auipc	s4,0x25
    80006e54:	208a0a13          	addi	s4,s4,520 # 8002c058 <nsizes>
    80006e58:	4b05                	li	s6,1
    lst_init(&bd_sizes[k].free);
    80006e5a:	00599b93          	slli	s7,s3,0x5
    80006e5e:	000ab503          	ld	a0,0(s5)
    80006e62:	955e                	add	a0,a0,s7
    80006e64:	00000097          	auipc	ra,0x0
    80006e68:	166080e7          	jalr	358(ra) # 80006fca <lst_init>
    sz = sizeof(char)* ROUNDUP(NBLK(k), 8)/8;
    80006e6c:	000a2483          	lw	s1,0(s4)
    80006e70:	34fd                	addiw	s1,s1,-1
    80006e72:	413484bb          	subw	s1,s1,s3
    80006e76:	009b14bb          	sllw	s1,s6,s1
    80006e7a:	fff4879b          	addiw	a5,s1,-1
    80006e7e:	41f7d49b          	sraiw	s1,a5,0x1f
    80006e82:	01d4d49b          	srliw	s1,s1,0x1d
    80006e86:	9cbd                	addw	s1,s1,a5
    80006e88:	98e1                	andi	s1,s1,-8
    80006e8a:	24a1                	addiw	s1,s1,8
    bd_sizes[k].alloc = p;
    80006e8c:	000ab783          	ld	a5,0(s5)
    80006e90:	9bbe                	add	s7,s7,a5
    80006e92:	012bb823          	sd	s2,16(s7)
    memset(bd_sizes[k].alloc, 0, sz);
    80006e96:	848d                	srai	s1,s1,0x3
    80006e98:	8626                	mv	a2,s1
    80006e9a:	4581                	li	a1,0
    80006e9c:	854a                	mv	a0,s2
    80006e9e:	ffffa097          	auipc	ra,0xffffa
    80006ea2:	ede080e7          	jalr	-290(ra) # 80000d7c <memset>
    p += sz;
    80006ea6:	9926                	add	s2,s2,s1
  for (int k = 0; k < nsizes; k++) {
    80006ea8:	0985                	addi	s3,s3,1
    80006eaa:	000a2703          	lw	a4,0(s4)
    80006eae:	0009879b          	sext.w	a5,s3
    80006eb2:	fae7c4e3          	blt	a5,a4,80006e5a <bd_init+0xc8>
  }

  // allocate the split array for each size k, except for k = 0, since
  // we will not split blocks of size k = 0, the smallest size.
  for (int k = 1; k < nsizes; k++) {
    80006eb6:	00025797          	auipc	a5,0x25
    80006eba:	1a27a783          	lw	a5,418(a5) # 8002c058 <nsizes>
    80006ebe:	4705                	li	a4,1
    80006ec0:	06f75163          	bge	a4,a5,80006f22 <bd_init+0x190>
    80006ec4:	02000a13          	li	s4,32
    80006ec8:	4985                	li	s3,1
    sz = sizeof(char)* (ROUNDUP(NBLK(k), 8))/8;
    80006eca:	4b85                	li	s7,1
    bd_sizes[k].split = p;
    80006ecc:	00025b17          	auipc	s6,0x25
    80006ed0:	184b0b13          	addi	s6,s6,388 # 8002c050 <bd_sizes>
  for (int k = 1; k < nsizes; k++) {
    80006ed4:	00025a97          	auipc	s5,0x25
    80006ed8:	184a8a93          	addi	s5,s5,388 # 8002c058 <nsizes>
    sz = sizeof(char)* (ROUNDUP(NBLK(k), 8))/8;
    80006edc:	37fd                	addiw	a5,a5,-1
    80006ede:	413787bb          	subw	a5,a5,s3
    80006ee2:	00fb94bb          	sllw	s1,s7,a5
    80006ee6:	fff4879b          	addiw	a5,s1,-1
    80006eea:	41f7d49b          	sraiw	s1,a5,0x1f
    80006eee:	01d4d49b          	srliw	s1,s1,0x1d
    80006ef2:	9cbd                	addw	s1,s1,a5
    80006ef4:	98e1                	andi	s1,s1,-8
    80006ef6:	24a1                	addiw	s1,s1,8
    bd_sizes[k].split = p;
    80006ef8:	000b3783          	ld	a5,0(s6)
    80006efc:	97d2                	add	a5,a5,s4
    80006efe:	0127bc23          	sd	s2,24(a5)
    memset(bd_sizes[k].split, 0, sz);
    80006f02:	848d                	srai	s1,s1,0x3
    80006f04:	8626                	mv	a2,s1
    80006f06:	4581                	li	a1,0
    80006f08:	854a                	mv	a0,s2
    80006f0a:	ffffa097          	auipc	ra,0xffffa
    80006f0e:	e72080e7          	jalr	-398(ra) # 80000d7c <memset>
    p += sz;
    80006f12:	9926                	add	s2,s2,s1
  for (int k = 1; k < nsizes; k++) {
    80006f14:	2985                	addiw	s3,s3,1
    80006f16:	000aa783          	lw	a5,0(s5)
    80006f1a:	020a0a13          	addi	s4,s4,32
    80006f1e:	faf9cfe3          	blt	s3,a5,80006edc <bd_init+0x14a>
  }
  p = (char *) ROUNDUP((uint64) p, LEAF_SIZE);
    80006f22:	197d                	addi	s2,s2,-1
    80006f24:	ff097913          	andi	s2,s2,-16
    80006f28:	0941                	addi	s2,s2,16

  // done allocating; mark the memory range [base, p) as allocated, so
  // that buddy will not hand out that memory.
  int meta = bd_mark_data_structures(p);
    80006f2a:	854a                	mv	a0,s2
    80006f2c:	00000097          	auipc	ra,0x0
    80006f30:	d7c080e7          	jalr	-644(ra) # 80006ca8 <bd_mark_data_structures>
    80006f34:	8a2a                	mv	s4,a0
  
  // mark the unavailable memory range [end, HEAP_SIZE) as allocated,
  // so that buddy will not hand out that memory.
  int unavailable = bd_mark_unavailable(end, p);
    80006f36:	85ca                	mv	a1,s2
    80006f38:	8562                	mv	a0,s8
    80006f3a:	00000097          	auipc	ra,0x0
    80006f3e:	dce080e7          	jalr	-562(ra) # 80006d08 <bd_mark_unavailable>
    80006f42:	89aa                	mv	s3,a0
  void *bd_end = bd_base+BLK_SIZE(MAXSIZE)-unavailable;
    80006f44:	00025a97          	auipc	s5,0x25
    80006f48:	114a8a93          	addi	s5,s5,276 # 8002c058 <nsizes>
    80006f4c:	000aa783          	lw	a5,0(s5)
    80006f50:	37fd                	addiw	a5,a5,-1
    80006f52:	44c1                	li	s1,16
    80006f54:	00f497b3          	sll	a5,s1,a5
    80006f58:	8f89                	sub	a5,a5,a0
  
  // initialize free lists for each size k
  int free = bd_initfree(p, bd_end);
    80006f5a:	00025597          	auipc	a1,0x25
    80006f5e:	0ee5b583          	ld	a1,238(a1) # 8002c048 <bd_base>
    80006f62:	95be                	add	a1,a1,a5
    80006f64:	854a                	mv	a0,s2
    80006f66:	00000097          	auipc	ra,0x0
    80006f6a:	c86080e7          	jalr	-890(ra) # 80006bec <bd_initfree>

  // check if the amount that is free is what we expect
  if(free != BLK_SIZE(MAXSIZE)-meta-unavailable) {
    80006f6e:	000aa603          	lw	a2,0(s5)
    80006f72:	367d                	addiw	a2,a2,-1
    80006f74:	00c49633          	sll	a2,s1,a2
    80006f78:	41460633          	sub	a2,a2,s4
    80006f7c:	41360633          	sub	a2,a2,s3
    80006f80:	02c51463          	bne	a0,a2,80006fa8 <bd_init+0x216>
    printf("free %d %d\n", free, BLK_SIZE(MAXSIZE)-meta-unavailable);
    panic("bd_init: free mem");
  }
}
    80006f84:	60a6                	ld	ra,72(sp)
    80006f86:	6406                	ld	s0,64(sp)
    80006f88:	74e2                	ld	s1,56(sp)
    80006f8a:	7942                	ld	s2,48(sp)
    80006f8c:	79a2                	ld	s3,40(sp)
    80006f8e:	7a02                	ld	s4,32(sp)
    80006f90:	6ae2                	ld	s5,24(sp)
    80006f92:	6b42                	ld	s6,16(sp)
    80006f94:	6ba2                	ld	s7,8(sp)
    80006f96:	6c02                	ld	s8,0(sp)
    80006f98:	6161                	addi	sp,sp,80
    80006f9a:	8082                	ret
    nsizes++;  // round up to the next power of 2
    80006f9c:	2509                	addiw	a0,a0,2
    80006f9e:	00025797          	auipc	a5,0x25
    80006fa2:	0aa7ad23          	sw	a0,186(a5) # 8002c058 <nsizes>
    80006fa6:	bda1                	j	80006dfe <bd_init+0x6c>
    printf("free %d %d\n", free, BLK_SIZE(MAXSIZE)-meta-unavailable);
    80006fa8:	85aa                	mv	a1,a0
    80006faa:	00002517          	auipc	a0,0x2
    80006fae:	ace50513          	addi	a0,a0,-1330 # 80008a78 <userret+0x9e8>
    80006fb2:	ffff9097          	auipc	ra,0xffff9
    80006fb6:	5f0080e7          	jalr	1520(ra) # 800005a2 <printf>
    panic("bd_init: free mem");
    80006fba:	00002517          	auipc	a0,0x2
    80006fbe:	ace50513          	addi	a0,a0,-1330 # 80008a88 <userret+0x9f8>
    80006fc2:	ffff9097          	auipc	ra,0xffff9
    80006fc6:	586080e7          	jalr	1414(ra) # 80000548 <panic>

0000000080006fca <lst_init>:
// fast. circular simplifies code, because don't have to check for
// empty list in insert and remove.

void
lst_init(struct list *lst)
{
    80006fca:	1141                	addi	sp,sp,-16
    80006fcc:	e422                	sd	s0,8(sp)
    80006fce:	0800                	addi	s0,sp,16
  lst->next = lst;
    80006fd0:	e108                	sd	a0,0(a0)
  lst->prev = lst;
    80006fd2:	e508                	sd	a0,8(a0)
}
    80006fd4:	6422                	ld	s0,8(sp)
    80006fd6:	0141                	addi	sp,sp,16
    80006fd8:	8082                	ret

0000000080006fda <lst_empty>:

int
lst_empty(struct list *lst) {
    80006fda:	1141                	addi	sp,sp,-16
    80006fdc:	e422                	sd	s0,8(sp)
    80006fde:	0800                	addi	s0,sp,16
  return lst->next == lst;
    80006fe0:	611c                	ld	a5,0(a0)
    80006fe2:	40a78533          	sub	a0,a5,a0
}
    80006fe6:	00153513          	seqz	a0,a0
    80006fea:	6422                	ld	s0,8(sp)
    80006fec:	0141                	addi	sp,sp,16
    80006fee:	8082                	ret

0000000080006ff0 <lst_remove>:

void
lst_remove(struct list *e) {
    80006ff0:	1141                	addi	sp,sp,-16
    80006ff2:	e422                	sd	s0,8(sp)
    80006ff4:	0800                	addi	s0,sp,16
  e->prev->next = e->next;
    80006ff6:	6518                	ld	a4,8(a0)
    80006ff8:	611c                	ld	a5,0(a0)
    80006ffa:	e31c                	sd	a5,0(a4)
  e->next->prev = e->prev;
    80006ffc:	6518                	ld	a4,8(a0)
    80006ffe:	e798                	sd	a4,8(a5)
}
    80007000:	6422                	ld	s0,8(sp)
    80007002:	0141                	addi	sp,sp,16
    80007004:	8082                	ret

0000000080007006 <lst_pop>:

void*
lst_pop(struct list *lst) {
    80007006:	1101                	addi	sp,sp,-32
    80007008:	ec06                	sd	ra,24(sp)
    8000700a:	e822                	sd	s0,16(sp)
    8000700c:	e426                	sd	s1,8(sp)
    8000700e:	1000                	addi	s0,sp,32
  if(lst->next == lst)
    80007010:	6104                	ld	s1,0(a0)
    80007012:	00a48d63          	beq	s1,a0,8000702c <lst_pop+0x26>
    panic("lst_pop");
  struct list *p = lst->next;
  lst_remove(p);
    80007016:	8526                	mv	a0,s1
    80007018:	00000097          	auipc	ra,0x0
    8000701c:	fd8080e7          	jalr	-40(ra) # 80006ff0 <lst_remove>
  return (void *)p;
}
    80007020:	8526                	mv	a0,s1
    80007022:	60e2                	ld	ra,24(sp)
    80007024:	6442                	ld	s0,16(sp)
    80007026:	64a2                	ld	s1,8(sp)
    80007028:	6105                	addi	sp,sp,32
    8000702a:	8082                	ret
    panic("lst_pop");
    8000702c:	00002517          	auipc	a0,0x2
    80007030:	a7450513          	addi	a0,a0,-1420 # 80008aa0 <userret+0xa10>
    80007034:	ffff9097          	auipc	ra,0xffff9
    80007038:	514080e7          	jalr	1300(ra) # 80000548 <panic>

000000008000703c <lst_push>:

void
lst_push(struct list *lst, void *p)
{
    8000703c:	1141                	addi	sp,sp,-16
    8000703e:	e422                	sd	s0,8(sp)
    80007040:	0800                	addi	s0,sp,16
  struct list *e = (struct list *) p;
  e->next = lst->next;
    80007042:	611c                	ld	a5,0(a0)
    80007044:	e19c                	sd	a5,0(a1)
  e->prev = lst;
    80007046:	e588                	sd	a0,8(a1)
  lst->next->prev = p;
    80007048:	611c                	ld	a5,0(a0)
    8000704a:	e78c                	sd	a1,8(a5)
  lst->next = e;
    8000704c:	e10c                	sd	a1,0(a0)
}
    8000704e:	6422                	ld	s0,8(sp)
    80007050:	0141                	addi	sp,sp,16
    80007052:	8082                	ret

0000000080007054 <lst_print>:

void
lst_print(struct list *lst)
{
    80007054:	7179                	addi	sp,sp,-48
    80007056:	f406                	sd	ra,40(sp)
    80007058:	f022                	sd	s0,32(sp)
    8000705a:	ec26                	sd	s1,24(sp)
    8000705c:	e84a                	sd	s2,16(sp)
    8000705e:	e44e                	sd	s3,8(sp)
    80007060:	1800                	addi	s0,sp,48
  for (struct list *p = lst->next; p != lst; p = p->next) {
    80007062:	6104                	ld	s1,0(a0)
    80007064:	02950063          	beq	a0,s1,80007084 <lst_print+0x30>
    80007068:	892a                	mv	s2,a0
    printf(" %p", p);
    8000706a:	00002997          	auipc	s3,0x2
    8000706e:	a3e98993          	addi	s3,s3,-1474 # 80008aa8 <userret+0xa18>
    80007072:	85a6                	mv	a1,s1
    80007074:	854e                	mv	a0,s3
    80007076:	ffff9097          	auipc	ra,0xffff9
    8000707a:	52c080e7          	jalr	1324(ra) # 800005a2 <printf>
  for (struct list *p = lst->next; p != lst; p = p->next) {
    8000707e:	6084                	ld	s1,0(s1)
    80007080:	fe9919e3          	bne	s2,s1,80007072 <lst_print+0x1e>
  }
  printf("\n");
    80007084:	00001517          	auipc	a0,0x1
    80007088:	20c50513          	addi	a0,a0,524 # 80008290 <userret+0x200>
    8000708c:	ffff9097          	auipc	ra,0xffff9
    80007090:	516080e7          	jalr	1302(ra) # 800005a2 <printf>
}
    80007094:	70a2                	ld	ra,40(sp)
    80007096:	7402                	ld	s0,32(sp)
    80007098:	64e2                	ld	s1,24(sp)
    8000709a:	6942                	ld	s2,16(sp)
    8000709c:	69a2                	ld	s3,8(sp)
    8000709e:	6145                	addi	sp,sp,48
    800070a0:	8082                	ret
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

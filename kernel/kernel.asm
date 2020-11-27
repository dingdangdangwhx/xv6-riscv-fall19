
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
    80000060:	d7478793          	addi	a5,a5,-652 # 80005dd0 <timervec>
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
    800000aa:	f5a78793          	addi	a5,a5,-166 # 80001000 <main>
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
    80000112:	ad6080e7          	jalr	-1322(ra) # 80000be4 <acquire>
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
    80000140:	a00080e7          	jalr	-1536(ra) # 80001b3c <myproc>
    80000144:	5d1c                	lw	a5,56(a0)
    80000146:	e7b5                	bnez	a5,800001b2 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    80000148:	85a6                	mv	a1,s1
    8000014a:	854a                	mv	a0,s2
    8000014c:	00002097          	auipc	ra,0x2
    80000150:	1c6080e7          	jalr	454(ra) # 80002312 <sleep>
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
    8000018c:	3e4080e7          	jalr	996(ra) # 8000256c <either_copyout>
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
    800001a8:	ab0080e7          	jalr	-1360(ra) # 80000c54 <release>

  return target - n;
    800001ac:	413b053b          	subw	a0,s6,s3
    800001b0:	a811                	j	800001c4 <consoleread+0xe4>
        release(&cons.lock);
    800001b2:	00012517          	auipc	a0,0x12
    800001b6:	64e50513          	addi	a0,a0,1614 # 80012800 <cons>
    800001ba:	00001097          	auipc	ra,0x1
    800001be:	a9a080e7          	jalr	-1382(ra) # 80000c54 <release>
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
    80000264:	984080e7          	jalr	-1660(ra) # 80000be4 <acquire>
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
    8000028a:	33c080e7          	jalr	828(ra) # 800025c2 <either_copyin>
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
    800002b0:	9a8080e7          	jalr	-1624(ra) # 80000c54 <release>
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
    800002e2:	906080e7          	jalr	-1786(ra) # 80000be4 <acquire>

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
    80000300:	31c080e7          	jalr	796(ra) # 80002618 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00012517          	auipc	a0,0x12
    80000308:	4fc50513          	addi	a0,a0,1276 # 80012800 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	948080e7          	jalr	-1720(ra) # 80000c54 <release>
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
    80000454:	042080e7          	jalr	66(ra) # 80002492 <wakeup>
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
    80000476:	624080e7          	jalr	1572(ra) # 80000a96 <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	33a080e7          	jalr	826(ra) # 800007b4 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00025797          	auipc	a5,0x25
    80000486:	a9678793          	addi	a5,a5,-1386 # 80024f18 <devsw>
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
    8000061e:	5ca080e7          	jalr	1482(ra) # 80000be4 <acquire>
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
    8000077c:	4dc080e7          	jalr	1244(ra) # 80000c54 <release>
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
    800007a2:	2f8080e7          	jalr	760(ra) # 80000a96 <initlock>
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
    80000864:	7139                	addi	sp,sp,-64
    80000866:	fc06                	sd	ra,56(sp)
    80000868:	f822                	sd	s0,48(sp)
    8000086a:	f426                	sd	s1,40(sp)
    8000086c:	f04a                	sd	s2,32(sp)
    8000086e:	ec4e                	sd	s3,24(sp)
    80000870:	e852                	sd	s4,16(sp)
    80000872:	e456                	sd	s5,8(sp)
    80000874:	0080                	addi	s0,sp,64
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000876:	03451793          	slli	a5,a0,0x34
    8000087a:	e3c1                	bnez	a5,800008fa <kfree+0x96>
    8000087c:	84aa                	mv	s1,a0
    8000087e:	0002b797          	auipc	a5,0x2b
    80000882:	7de78793          	addi	a5,a5,2014 # 8002c05c <end>
    80000886:	06f56a63          	bltu	a0,a5,800008fa <kfree+0x96>
    8000088a:	47c5                	li	a5,17
    8000088c:	07ee                	slli	a5,a5,0x1b
    8000088e:	06f57663          	bgeu	a0,a5,800008fa <kfree+0x96>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000892:	6605                	lui	a2,0x1
    80000894:	4585                	li	a1,1
    80000896:	00000097          	auipc	ra,0x0
    8000089a:	5bc080e7          	jalr	1468(ra) # 80000e52 <memset>

  r = (struct run*)pa;

  push_off();
    8000089e:	00000097          	auipc	ra,0x0
    800008a2:	24e080e7          	jalr	590(ra) # 80000aec <push_off>
  int cpu = cpuid();
    800008a6:	00001097          	auipc	ra,0x1
    800008aa:	26a080e7          	jalr	618(ra) # 80001b10 <cpuid>
  acquire(&kmem[cpu].lock);
    800008ae:	00012a97          	auipc	s5,0x12
    800008b2:	02aa8a93          	addi	s5,s5,42 # 800128d8 <kmem>
    800008b6:	00251993          	slli	s3,a0,0x2
    800008ba:	00a98933          	add	s2,s3,a0
    800008be:	090e                	slli	s2,s2,0x3
    800008c0:	9956                	add	s2,s2,s5
    800008c2:	854a                	mv	a0,s2
    800008c4:	00000097          	auipc	ra,0x0
    800008c8:	320080e7          	jalr	800(ra) # 80000be4 <acquire>
  r->next = kmem[cpu].freelist;
    800008cc:	02093783          	ld	a5,32(s2)
    800008d0:	e09c                	sd	a5,0(s1)
  kmem[cpu].freelist = r;
    800008d2:	02993023          	sd	s1,32(s2)
  release(&kmem[cpu].lock);
    800008d6:	854a                	mv	a0,s2
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	37c080e7          	jalr	892(ra) # 80000c54 <release>
  pop_off();
    800008e0:	00000097          	auipc	ra,0x0
    800008e4:	258080e7          	jalr	600(ra) # 80000b38 <pop_off>
}
    800008e8:	70e2                	ld	ra,56(sp)
    800008ea:	7442                	ld	s0,48(sp)
    800008ec:	74a2                	ld	s1,40(sp)
    800008ee:	7902                	ld	s2,32(sp)
    800008f0:	69e2                	ld	s3,24(sp)
    800008f2:	6a42                	ld	s4,16(sp)
    800008f4:	6aa2                	ld	s5,8(sp)
    800008f6:	6121                	addi	sp,sp,64
    800008f8:	8082                	ret
    panic("kfree");
    800008fa:	00008517          	auipc	a0,0x8
    800008fe:	91e50513          	addi	a0,a0,-1762 # 80008218 <userret+0x188>
    80000902:	00000097          	auipc	ra,0x0
    80000906:	c46080e7          	jalr	-954(ra) # 80000548 <panic>

000000008000090a <freerange>:
{
    8000090a:	7179                	addi	sp,sp,-48
    8000090c:	f406                	sd	ra,40(sp)
    8000090e:	f022                	sd	s0,32(sp)
    80000910:	ec26                	sd	s1,24(sp)
    80000912:	e84a                	sd	s2,16(sp)
    80000914:	e44e                	sd	s3,8(sp)
    80000916:	e052                	sd	s4,0(sp)
    80000918:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    8000091a:	6785                	lui	a5,0x1
    8000091c:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000920:	94aa                	add	s1,s1,a0
    80000922:	757d                	lui	a0,0xfffff
    80000924:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000926:	94be                	add	s1,s1,a5
    80000928:	0095ee63          	bltu	a1,s1,80000944 <freerange+0x3a>
    8000092c:	892e                	mv	s2,a1
    kfree(p);
    8000092e:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000930:	6985                	lui	s3,0x1
    kfree(p);
    80000932:	01448533          	add	a0,s1,s4
    80000936:	00000097          	auipc	ra,0x0
    8000093a:	f2e080e7          	jalr	-210(ra) # 80000864 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    8000093e:	94ce                	add	s1,s1,s3
    80000940:	fe9979e3          	bgeu	s2,s1,80000932 <freerange+0x28>
}
    80000944:	70a2                	ld	ra,40(sp)
    80000946:	7402                	ld	s0,32(sp)
    80000948:	64e2                	ld	s1,24(sp)
    8000094a:	6942                	ld	s2,16(sp)
    8000094c:	69a2                	ld	s3,8(sp)
    8000094e:	6a02                	ld	s4,0(sp)
    80000950:	6145                	addi	sp,sp,48
    80000952:	8082                	ret

0000000080000954 <kinit>:
{
    80000954:	7179                	addi	sp,sp,-48
    80000956:	f406                	sd	ra,40(sp)
    80000958:	f022                	sd	s0,32(sp)
    8000095a:	ec26                	sd	s1,24(sp)
    8000095c:	e84a                	sd	s2,16(sp)
    8000095e:	e44e                	sd	s3,8(sp)
    80000960:	1800                	addi	s0,sp,48
  for(int i = 0; i < NCPU; i++)
    80000962:	00012497          	auipc	s1,0x12
    80000966:	f7648493          	addi	s1,s1,-138 # 800128d8 <kmem>
    8000096a:	00012997          	auipc	s3,0x12
    8000096e:	0ae98993          	addi	s3,s3,174 # 80012a18 <locks>
    initlock(&kmem[i].lock, "kmem");
    80000972:	00008917          	auipc	s2,0x8
    80000976:	8ae90913          	addi	s2,s2,-1874 # 80008220 <userret+0x190>
    8000097a:	85ca                	mv	a1,s2
    8000097c:	8526                	mv	a0,s1
    8000097e:	00000097          	auipc	ra,0x0
    80000982:	118080e7          	jalr	280(ra) # 80000a96 <initlock>
  for(int i = 0; i < NCPU; i++)
    80000986:	02848493          	addi	s1,s1,40
    8000098a:	ff3498e3          	bne	s1,s3,8000097a <kinit+0x26>
  freerange(end, (void*)PHYSTOP);
    8000098e:	45c5                	li	a1,17
    80000990:	05ee                	slli	a1,a1,0x1b
    80000992:	0002b517          	auipc	a0,0x2b
    80000996:	6ca50513          	addi	a0,a0,1738 # 8002c05c <end>
    8000099a:	00000097          	auipc	ra,0x0
    8000099e:	f70080e7          	jalr	-144(ra) # 8000090a <freerange>
}
    800009a2:	70a2                	ld	ra,40(sp)
    800009a4:	7402                	ld	s0,32(sp)
    800009a6:	64e2                	ld	s1,24(sp)
    800009a8:	6942                	ld	s2,16(sp)
    800009aa:	69a2                	ld	s3,8(sp)
    800009ac:	6145                	addi	sp,sp,48
    800009ae:	8082                	ret

00000000800009b0 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    800009b0:	7179                	addi	sp,sp,-48
    800009b2:	f406                	sd	ra,40(sp)
    800009b4:	f022                	sd	s0,32(sp)
    800009b6:	ec26                	sd	s1,24(sp)
    800009b8:	e84a                	sd	s2,16(sp)
    800009ba:	e44e                	sd	s3,8(sp)
    800009bc:	e052                	sd	s4,0(sp)
    800009be:	1800                	addi	s0,sp,48
  struct run *r;
  struct run *tmp;

  push_off();
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	12c080e7          	jalr	300(ra) # 80000aec <push_off>
  int cpu = cpuid();
    800009c8:	00001097          	auipc	ra,0x1
    800009cc:	148080e7          	jalr	328(ra) # 80001b10 <cpuid>
  acquire(&kmem[cpu].lock);
    800009d0:	00251913          	slli	s2,a0,0x2
    800009d4:	992a                	add	s2,s2,a0
    800009d6:	00391793          	slli	a5,s2,0x3
    800009da:	00012917          	auipc	s2,0x12
    800009de:	efe90913          	addi	s2,s2,-258 # 800128d8 <kmem>
    800009e2:	993e                	add	s2,s2,a5
    800009e4:	854a                	mv	a0,s2
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	1fe080e7          	jalr	510(ra) # 80000be4 <acquire>
  r = kmem[cpu].freelist;
    800009ee:	02093a03          	ld	s4,32(s2)
  if(r)
    800009f2:	060a0563          	beqz	s4,80000a5c <kalloc+0xac>
    kmem[cpu].freelist = r->next;
    800009f6:	000a3703          	ld	a4,0(s4) # fffffffffffff000 <end+0xffffffff7ffd2fa4>
    800009fa:	02e93023          	sd	a4,32(s2)
  release(&kmem[cpu].lock);
    800009fe:	854a                	mv	a0,s2
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	254080e7          	jalr	596(ra) # 80000c54 <release>
  pop_off();
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	130080e7          	jalr	304(ra) # 80000b38 <pop_off>
    for(int i = 0; i < NCPU; i++)
      release(&kmem[i].lock);
  }

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4595                	li	a1,5
    80000a14:	8552                	mv	a0,s4
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	43c080e7          	jalr	1084(ra) # 80000e52 <memset>
  return (void*)r;
}
    80000a1e:	8552                	mv	a0,s4
    80000a20:	70a2                	ld	ra,40(sp)
    80000a22:	7402                	ld	s0,32(sp)
    80000a24:	64e2                	ld	s1,24(sp)
    80000a26:	6942                	ld	s2,16(sp)
    80000a28:	69a2                	ld	s3,8(sp)
    80000a2a:	6a02                	ld	s4,0(sp)
    80000a2c:	6145                	addi	sp,sp,48
    80000a2e:	8082                	ret
          kmem[i].freelist = r->next;
    80000a30:	6314                	ld	a3,0(a4)
    80000a32:	f394                	sd	a3,32(a5)
        r = kmem[i].freelist;
    80000a34:	8a3a                	mv	s4,a4
    for(int i = 0; i < NCPU; i++){
    80000a36:	02878793          	addi	a5,a5,40
    80000a3a:	01378563          	beq	a5,s3,80000a44 <kalloc+0x94>
      tmp = kmem[i].freelist;
    80000a3e:	7398                	ld	a4,32(a5)
      if(tmp){
    80000a40:	fb65                	bnez	a4,80000a30 <kalloc+0x80>
    80000a42:	bfd5                	j	80000a36 <kalloc+0x86>
      release(&kmem[i].lock);
    80000a44:	8526                	mv	a0,s1
    80000a46:	00000097          	auipc	ra,0x0
    80000a4a:	20e080e7          	jalr	526(ra) # 80000c54 <release>
    for(int i = 0; i < NCPU; i++)
    80000a4e:	02848493          	addi	s1,s1,40
    80000a52:	ff3499e3          	bne	s1,s3,80000a44 <kalloc+0x94>
  if(r)
    80000a56:	fc0a04e3          	beqz	s4,80000a1e <kalloc+0x6e>
    80000a5a:	bf5d                	j	80000a10 <kalloc+0x60>
  release(&kmem[cpu].lock);
    80000a5c:	854a                	mv	a0,s2
    80000a5e:	00000097          	auipc	ra,0x0
    80000a62:	1f6080e7          	jalr	502(ra) # 80000c54 <release>
  pop_off();
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	0d2080e7          	jalr	210(ra) # 80000b38 <pop_off>
    for(int i = 0; i < NCPU; i++)
    80000a6e:	00012497          	auipc	s1,0x12
    80000a72:	e6a48493          	addi	s1,s1,-406 # 800128d8 <kmem>
    80000a76:	00012997          	auipc	s3,0x12
    80000a7a:	fa298993          	addi	s3,s3,-94 # 80012a18 <locks>
  pop_off();
    80000a7e:	8926                	mv	s2,s1
      acquire(&kmem[i].lock);
    80000a80:	854a                	mv	a0,s2
    80000a82:	00000097          	auipc	ra,0x0
    80000a86:	162080e7          	jalr	354(ra) # 80000be4 <acquire>
    for(int i = 0; i < NCPU; i++)
    80000a8a:	02890913          	addi	s2,s2,40
    80000a8e:	ff3919e3          	bne	s2,s3,80000a80 <kalloc+0xd0>
    80000a92:	87a6                	mv	a5,s1
    80000a94:	b76d                	j	80000a3e <kalloc+0x8e>

0000000080000a96 <initlock>:

// assumes locks are not freed
void
initlock(struct spinlock *lk, char *name)
{
  lk->name = name;
    80000a96:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000a98:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000a9c:	00053823          	sd	zero,16(a0)
  lk->nts = 0;
    80000aa0:	00052e23          	sw	zero,28(a0)
  lk->n = 0;
    80000aa4:	00052c23          	sw	zero,24(a0)
  if(nlock >= NLOCK)
    80000aa8:	0002b797          	auipc	a5,0x2b
    80000aac:	57c7a783          	lw	a5,1404(a5) # 8002c024 <nlock>
    80000ab0:	3e700713          	li	a4,999
    80000ab4:	02f74063          	blt	a4,a5,80000ad4 <initlock+0x3e>
    panic("initlock");
  locks[nlock] = lk;
    80000ab8:	00379693          	slli	a3,a5,0x3
    80000abc:	00012717          	auipc	a4,0x12
    80000ac0:	f5c70713          	addi	a4,a4,-164 # 80012a18 <locks>
    80000ac4:	9736                	add	a4,a4,a3
    80000ac6:	e308                	sd	a0,0(a4)
  nlock++;
    80000ac8:	2785                	addiw	a5,a5,1
    80000aca:	0002b717          	auipc	a4,0x2b
    80000ace:	54f72d23          	sw	a5,1370(a4) # 8002c024 <nlock>
    80000ad2:	8082                	ret
{
    80000ad4:	1141                	addi	sp,sp,-16
    80000ad6:	e406                	sd	ra,8(sp)
    80000ad8:	e022                	sd	s0,0(sp)
    80000ada:	0800                	addi	s0,sp,16
    panic("initlock");
    80000adc:	00007517          	auipc	a0,0x7
    80000ae0:	74c50513          	addi	a0,a0,1868 # 80008228 <userret+0x198>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	a64080e7          	jalr	-1436(ra) # 80000548 <panic>

0000000080000aec <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000aec:	1101                	addi	sp,sp,-32
    80000aee:	ec06                	sd	ra,24(sp)
    80000af0:	e822                	sd	s0,16(sp)
    80000af2:	e426                	sd	s1,8(sp)
    80000af4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000af6:	100024f3          	csrr	s1,sstatus
    80000afa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000afe:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b00:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b04:	00001097          	auipc	ra,0x1
    80000b08:	01c080e7          	jalr	28(ra) # 80001b20 <mycpu>
    80000b0c:	5d3c                	lw	a5,120(a0)
    80000b0e:	cf89                	beqz	a5,80000b28 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b10:	00001097          	auipc	ra,0x1
    80000b14:	010080e7          	jalr	16(ra) # 80001b20 <mycpu>
    80000b18:	5d3c                	lw	a5,120(a0)
    80000b1a:	2785                	addiw	a5,a5,1
    80000b1c:	dd3c                	sw	a5,120(a0)
}
    80000b1e:	60e2                	ld	ra,24(sp)
    80000b20:	6442                	ld	s0,16(sp)
    80000b22:	64a2                	ld	s1,8(sp)
    80000b24:	6105                	addi	sp,sp,32
    80000b26:	8082                	ret
    mycpu()->intena = old;
    80000b28:	00001097          	auipc	ra,0x1
    80000b2c:	ff8080e7          	jalr	-8(ra) # 80001b20 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000b30:	8085                	srli	s1,s1,0x1
    80000b32:	8885                	andi	s1,s1,1
    80000b34:	dd64                	sw	s1,124(a0)
    80000b36:	bfe9                	j	80000b10 <push_off+0x24>

0000000080000b38 <pop_off>:

void
pop_off(void)
{
    80000b38:	1141                	addi	sp,sp,-16
    80000b3a:	e406                	sd	ra,8(sp)
    80000b3c:	e022                	sd	s0,0(sp)
    80000b3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000b40:	00001097          	auipc	ra,0x1
    80000b44:	fe0080e7          	jalr	-32(ra) # 80001b20 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000b4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000b4e:	eb9d                	bnez	a5,80000b84 <pop_off+0x4c>
    panic("pop_off - interruptible");
  c->noff -= 1;
    80000b50:	5d3c                	lw	a5,120(a0)
    80000b52:	37fd                	addiw	a5,a5,-1
    80000b54:	0007871b          	sext.w	a4,a5
    80000b58:	dd3c                	sw	a5,120(a0)
  if(c->noff < 0)
    80000b5a:	02074d63          	bltz	a4,80000b94 <pop_off+0x5c>
    panic("pop_off");
  if(c->noff == 0 && c->intena)
    80000b5e:	ef19                	bnez	a4,80000b7c <pop_off+0x44>
    80000b60:	5d7c                	lw	a5,124(a0)
    80000b62:	cf89                	beqz	a5,80000b7c <pop_off+0x44>
  asm volatile("csrr %0, sie" : "=r" (x) );
    80000b64:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    80000b68:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    80000b6c:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b70:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000b74:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b78:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000b7c:	60a2                	ld	ra,8(sp)
    80000b7e:	6402                	ld	s0,0(sp)
    80000b80:	0141                	addi	sp,sp,16
    80000b82:	8082                	ret
    panic("pop_off - interruptible");
    80000b84:	00007517          	auipc	a0,0x7
    80000b88:	6b450513          	addi	a0,a0,1716 # 80008238 <userret+0x1a8>
    80000b8c:	00000097          	auipc	ra,0x0
    80000b90:	9bc080e7          	jalr	-1604(ra) # 80000548 <panic>
    panic("pop_off");
    80000b94:	00007517          	auipc	a0,0x7
    80000b98:	6bc50513          	addi	a0,a0,1724 # 80008250 <userret+0x1c0>
    80000b9c:	00000097          	auipc	ra,0x0
    80000ba0:	9ac080e7          	jalr	-1620(ra) # 80000548 <panic>

0000000080000ba4 <holding>:
{
    80000ba4:	1101                	addi	sp,sp,-32
    80000ba6:	ec06                	sd	ra,24(sp)
    80000ba8:	e822                	sd	s0,16(sp)
    80000baa:	e426                	sd	s1,8(sp)
    80000bac:	1000                	addi	s0,sp,32
    80000bae:	84aa                	mv	s1,a0
  push_off();
    80000bb0:	00000097          	auipc	ra,0x0
    80000bb4:	f3c080e7          	jalr	-196(ra) # 80000aec <push_off>
  r = (lk->locked && lk->cpu == mycpu());
    80000bb8:	409c                	lw	a5,0(s1)
    80000bba:	ef81                	bnez	a5,80000bd2 <holding+0x2e>
    80000bbc:	4481                	li	s1,0
  pop_off();
    80000bbe:	00000097          	auipc	ra,0x0
    80000bc2:	f7a080e7          	jalr	-134(ra) # 80000b38 <pop_off>
}
    80000bc6:	8526                	mv	a0,s1
    80000bc8:	60e2                	ld	ra,24(sp)
    80000bca:	6442                	ld	s0,16(sp)
    80000bcc:	64a2                	ld	s1,8(sp)
    80000bce:	6105                	addi	sp,sp,32
    80000bd0:	8082                	ret
  r = (lk->locked && lk->cpu == mycpu());
    80000bd2:	6884                	ld	s1,16(s1)
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	f4c080e7          	jalr	-180(ra) # 80001b20 <mycpu>
    80000bdc:	8c89                	sub	s1,s1,a0
    80000bde:	0014b493          	seqz	s1,s1
    80000be2:	bff1                	j	80000bbe <holding+0x1a>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	efc080e7          	jalr	-260(ra) # 80000aec <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	faa080e7          	jalr	-86(ra) # 80000ba4 <holding>
    80000c02:	e911                	bnez	a0,80000c16 <acquire+0x32>
  __sync_fetch_and_add(&(lk->n), 1);
    80000c04:	4785                	li	a5,1
    80000c06:	01848713          	addi	a4,s1,24
    80000c0a:	0f50000f          	fence	iorw,ow
    80000c0e:	04f7202f          	amoadd.w.aq	zero,a5,(a4)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000c12:	4705                	li	a4,1
    80000c14:	a839                	j	80000c32 <acquire+0x4e>
    panic("acquire");
    80000c16:	00007517          	auipc	a0,0x7
    80000c1a:	64250513          	addi	a0,a0,1602 # 80008258 <userret+0x1c8>
    80000c1e:	00000097          	auipc	ra,0x0
    80000c22:	92a080e7          	jalr	-1750(ra) # 80000548 <panic>
     __sync_fetch_and_add(&lk->nts, 1);
    80000c26:	01c48793          	addi	a5,s1,28
    80000c2a:	0f50000f          	fence	iorw,ow
    80000c2e:	04e7a02f          	amoadd.w.aq	zero,a4,(a5)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000c32:	87ba                	mv	a5,a4
    80000c34:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c38:	2781                	sext.w	a5,a5
    80000c3a:	f7f5                	bnez	a5,80000c26 <acquire+0x42>
  __sync_synchronize();
    80000c3c:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	ee0080e7          	jalr	-288(ra) # 80001b20 <mycpu>
    80000c48:	e888                	sd	a0,16(s1)
}
    80000c4a:	60e2                	ld	ra,24(sp)
    80000c4c:	6442                	ld	s0,16(sp)
    80000c4e:	64a2                	ld	s1,8(sp)
    80000c50:	6105                	addi	sp,sp,32
    80000c52:	8082                	ret

0000000080000c54 <release>:
{
    80000c54:	1101                	addi	sp,sp,-32
    80000c56:	ec06                	sd	ra,24(sp)
    80000c58:	e822                	sd	s0,16(sp)
    80000c5a:	e426                	sd	s1,8(sp)
    80000c5c:	1000                	addi	s0,sp,32
    80000c5e:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c60:	00000097          	auipc	ra,0x0
    80000c64:	f44080e7          	jalr	-188(ra) # 80000ba4 <holding>
    80000c68:	c115                	beqz	a0,80000c8c <release+0x38>
  lk->cpu = 0;
    80000c6a:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c6e:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000c72:	0f50000f          	fence	iorw,ow
    80000c76:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000c7a:	00000097          	auipc	ra,0x0
    80000c7e:	ebe080e7          	jalr	-322(ra) # 80000b38 <pop_off>
}
    80000c82:	60e2                	ld	ra,24(sp)
    80000c84:	6442                	ld	s0,16(sp)
    80000c86:	64a2                	ld	s1,8(sp)
    80000c88:	6105                	addi	sp,sp,32
    80000c8a:	8082                	ret
    panic("release");
    80000c8c:	00007517          	auipc	a0,0x7
    80000c90:	5d450513          	addi	a0,a0,1492 # 80008260 <userret+0x1d0>
    80000c94:	00000097          	auipc	ra,0x0
    80000c98:	8b4080e7          	jalr	-1868(ra) # 80000548 <panic>

0000000080000c9c <print_lock>:

void
print_lock(struct spinlock *lk)
{
  if(lk->n > 0) 
    80000c9c:	4d14                	lw	a3,24(a0)
    80000c9e:	e291                	bnez	a3,80000ca2 <print_lock+0x6>
    80000ca0:	8082                	ret
{
    80000ca2:	1141                	addi	sp,sp,-16
    80000ca4:	e406                	sd	ra,8(sp)
    80000ca6:	e022                	sd	s0,0(sp)
    80000ca8:	0800                	addi	s0,sp,16
    printf("lock: %s: #test-and-set %d #acquire() %d\n", lk->name, lk->nts, lk->n);
    80000caa:	4d50                	lw	a2,28(a0)
    80000cac:	650c                	ld	a1,8(a0)
    80000cae:	00007517          	auipc	a0,0x7
    80000cb2:	5ba50513          	addi	a0,a0,1466 # 80008268 <userret+0x1d8>
    80000cb6:	00000097          	auipc	ra,0x0
    80000cba:	8ec080e7          	jalr	-1812(ra) # 800005a2 <printf>
}
    80000cbe:	60a2                	ld	ra,8(sp)
    80000cc0:	6402                	ld	s0,0(sp)
    80000cc2:	0141                	addi	sp,sp,16
    80000cc4:	8082                	ret

0000000080000cc6 <sys_ntas>:

uint64
sys_ntas(void)
{
    80000cc6:	711d                	addi	sp,sp,-96
    80000cc8:	ec86                	sd	ra,88(sp)
    80000cca:	e8a2                	sd	s0,80(sp)
    80000ccc:	e4a6                	sd	s1,72(sp)
    80000cce:	e0ca                	sd	s2,64(sp)
    80000cd0:	fc4e                	sd	s3,56(sp)
    80000cd2:	f852                	sd	s4,48(sp)
    80000cd4:	f456                	sd	s5,40(sp)
    80000cd6:	f05a                	sd	s6,32(sp)
    80000cd8:	ec5e                	sd	s7,24(sp)
    80000cda:	e862                	sd	s8,16(sp)
    80000cdc:	1080                	addi	s0,sp,96
  int zero = 0;
    80000cde:	fa042623          	sw	zero,-84(s0)
  int tot = 0;
  
  if (argint(0, &zero) < 0) {
    80000ce2:	fac40593          	addi	a1,s0,-84
    80000ce6:	4501                	li	a0,0
    80000ce8:	00002097          	auipc	ra,0x2
    80000cec:	ece080e7          	jalr	-306(ra) # 80002bb6 <argint>
    80000cf0:	14054d63          	bltz	a0,80000e4a <sys_ntas+0x184>
    return -1;
  }
  if(zero == 0) {
    80000cf4:	fac42783          	lw	a5,-84(s0)
    80000cf8:	e78d                	bnez	a5,80000d22 <sys_ntas+0x5c>
    80000cfa:	00012797          	auipc	a5,0x12
    80000cfe:	d1e78793          	addi	a5,a5,-738 # 80012a18 <locks>
    80000d02:	00014697          	auipc	a3,0x14
    80000d06:	c5668693          	addi	a3,a3,-938 # 80014958 <pid_lock>
    for(int i = 0; i < NLOCK; i++) {
      if(locks[i] == 0)
    80000d0a:	6398                	ld	a4,0(a5)
    80000d0c:	14070163          	beqz	a4,80000e4e <sys_ntas+0x188>
        break;
      locks[i]->nts = 0;
    80000d10:	00072e23          	sw	zero,28(a4)
      locks[i]->n = 0;
    80000d14:	00072c23          	sw	zero,24(a4)
    for(int i = 0; i < NLOCK; i++) {
    80000d18:	07a1                	addi	a5,a5,8
    80000d1a:	fed798e3          	bne	a5,a3,80000d0a <sys_ntas+0x44>
    }
    return 0;
    80000d1e:	4501                	li	a0,0
    80000d20:	aa09                	j	80000e32 <sys_ntas+0x16c>
  }

  printf("=== lock kmem/bcache stats\n");
    80000d22:	00007517          	auipc	a0,0x7
    80000d26:	57650513          	addi	a0,a0,1398 # 80008298 <userret+0x208>
    80000d2a:	00000097          	auipc	ra,0x0
    80000d2e:	878080e7          	jalr	-1928(ra) # 800005a2 <printf>
  for(int i = 0; i < NLOCK; i++) {
    80000d32:	00012b17          	auipc	s6,0x12
    80000d36:	ce6b0b13          	addi	s6,s6,-794 # 80012a18 <locks>
    80000d3a:	00014b97          	auipc	s7,0x14
    80000d3e:	c1eb8b93          	addi	s7,s7,-994 # 80014958 <pid_lock>
  printf("=== lock kmem/bcache stats\n");
    80000d42:	84da                	mv	s1,s6
  int tot = 0;
    80000d44:	4981                	li	s3,0
    if(locks[i] == 0)
      break;
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000d46:	00007a17          	auipc	s4,0x7
    80000d4a:	572a0a13          	addi	s4,s4,1394 # 800082b8 <userret+0x228>
       strncmp(locks[i]->name, "kmem", strlen("kmem")) == 0) {
    80000d4e:	00007c17          	auipc	s8,0x7
    80000d52:	4d2c0c13          	addi	s8,s8,1234 # 80008220 <userret+0x190>
    80000d56:	a829                	j	80000d70 <sys_ntas+0xaa>
      tot += locks[i]->nts;
    80000d58:	00093503          	ld	a0,0(s2)
    80000d5c:	4d5c                	lw	a5,28(a0)
    80000d5e:	013789bb          	addw	s3,a5,s3
      print_lock(locks[i]);
    80000d62:	00000097          	auipc	ra,0x0
    80000d66:	f3a080e7          	jalr	-198(ra) # 80000c9c <print_lock>
  for(int i = 0; i < NLOCK; i++) {
    80000d6a:	04a1                	addi	s1,s1,8
    80000d6c:	05748763          	beq	s1,s7,80000dba <sys_ntas+0xf4>
    if(locks[i] == 0)
    80000d70:	8926                	mv	s2,s1
    80000d72:	609c                	ld	a5,0(s1)
    80000d74:	c3b9                	beqz	a5,80000dba <sys_ntas+0xf4>
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000d76:	0087ba83          	ld	s5,8(a5)
    80000d7a:	8552                	mv	a0,s4
    80000d7c:	00000097          	auipc	ra,0x0
    80000d80:	25a080e7          	jalr	602(ra) # 80000fd6 <strlen>
    80000d84:	0005061b          	sext.w	a2,a0
    80000d88:	85d2                	mv	a1,s4
    80000d8a:	8556                	mv	a0,s5
    80000d8c:	00000097          	auipc	ra,0x0
    80000d90:	19e080e7          	jalr	414(ra) # 80000f2a <strncmp>
    80000d94:	d171                	beqz	a0,80000d58 <sys_ntas+0x92>
       strncmp(locks[i]->name, "kmem", strlen("kmem")) == 0) {
    80000d96:	609c                	ld	a5,0(s1)
    80000d98:	0087ba83          	ld	s5,8(a5)
    80000d9c:	8562                	mv	a0,s8
    80000d9e:	00000097          	auipc	ra,0x0
    80000da2:	238080e7          	jalr	568(ra) # 80000fd6 <strlen>
    80000da6:	0005061b          	sext.w	a2,a0
    80000daa:	85e2                	mv	a1,s8
    80000dac:	8556                	mv	a0,s5
    80000dae:	00000097          	auipc	ra,0x0
    80000db2:	17c080e7          	jalr	380(ra) # 80000f2a <strncmp>
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000db6:	f955                	bnez	a0,80000d6a <sys_ntas+0xa4>
    80000db8:	b745                	j	80000d58 <sys_ntas+0x92>
    }
  }

  printf("=== top 5 contended locks:\n");
    80000dba:	00007517          	auipc	a0,0x7
    80000dbe:	50650513          	addi	a0,a0,1286 # 800082c0 <userret+0x230>
    80000dc2:	fffff097          	auipc	ra,0xfffff
    80000dc6:	7e0080e7          	jalr	2016(ra) # 800005a2 <printf>
    80000dca:	4a15                	li	s4,5
  int last = 100000000;
    80000dcc:	05f5e537          	lui	a0,0x5f5e
    80000dd0:	10050513          	addi	a0,a0,256 # 5f5e100 <_entry-0x7a0a1f00>
  // stupid way to compute top 5 contended locks
  for(int t= 0; t < 5; t++) {
    int top = 0;
    for(int i = 0; i < NLOCK; i++) {
    80000dd4:	4a81                	li	s5,0
      if(locks[i] == 0)
        break;
      if(locks[i]->nts > locks[top]->nts && locks[i]->nts < last) {
    80000dd6:	00012497          	auipc	s1,0x12
    80000dda:	c4248493          	addi	s1,s1,-958 # 80012a18 <locks>
    for(int i = 0; i < NLOCK; i++) {
    80000dde:	3e800913          	li	s2,1000
    80000de2:	a091                	j	80000e26 <sys_ntas+0x160>
    80000de4:	2705                	addiw	a4,a4,1
    80000de6:	06a1                	addi	a3,a3,8
    80000de8:	03270063          	beq	a4,s2,80000e08 <sys_ntas+0x142>
      if(locks[i] == 0)
    80000dec:	629c                	ld	a5,0(a3)
    80000dee:	cf89                	beqz	a5,80000e08 <sys_ntas+0x142>
      if(locks[i]->nts > locks[top]->nts && locks[i]->nts < last) {
    80000df0:	4fd0                	lw	a2,28(a5)
    80000df2:	00359793          	slli	a5,a1,0x3
    80000df6:	97a6                	add	a5,a5,s1
    80000df8:	639c                	ld	a5,0(a5)
    80000dfa:	4fdc                	lw	a5,28(a5)
    80000dfc:	fec7f4e3          	bgeu	a5,a2,80000de4 <sys_ntas+0x11e>
    80000e00:	fea672e3          	bgeu	a2,a0,80000de4 <sys_ntas+0x11e>
    80000e04:	85ba                	mv	a1,a4
    80000e06:	bff9                	j	80000de4 <sys_ntas+0x11e>
        top = i;
      }
    }
    print_lock(locks[top]);
    80000e08:	058e                	slli	a1,a1,0x3
    80000e0a:	00b48bb3          	add	s7,s1,a1
    80000e0e:	000bb503          	ld	a0,0(s7)
    80000e12:	00000097          	auipc	ra,0x0
    80000e16:	e8a080e7          	jalr	-374(ra) # 80000c9c <print_lock>
    last = locks[top]->nts;
    80000e1a:	000bb783          	ld	a5,0(s7)
    80000e1e:	4fc8                	lw	a0,28(a5)
  for(int t= 0; t < 5; t++) {
    80000e20:	3a7d                	addiw	s4,s4,-1
    80000e22:	000a0763          	beqz	s4,80000e30 <sys_ntas+0x16a>
  int tot = 0;
    80000e26:	86da                	mv	a3,s6
    for(int i = 0; i < NLOCK; i++) {
    80000e28:	8756                	mv	a4,s5
    int top = 0;
    80000e2a:	85d6                	mv	a1,s5
      if(locks[i]->nts > locks[top]->nts && locks[i]->nts < last) {
    80000e2c:	2501                	sext.w	a0,a0
    80000e2e:	bf7d                	j	80000dec <sys_ntas+0x126>
  }
  return tot;
    80000e30:	854e                	mv	a0,s3
}
    80000e32:	60e6                	ld	ra,88(sp)
    80000e34:	6446                	ld	s0,80(sp)
    80000e36:	64a6                	ld	s1,72(sp)
    80000e38:	6906                	ld	s2,64(sp)
    80000e3a:	79e2                	ld	s3,56(sp)
    80000e3c:	7a42                	ld	s4,48(sp)
    80000e3e:	7aa2                	ld	s5,40(sp)
    80000e40:	7b02                	ld	s6,32(sp)
    80000e42:	6be2                	ld	s7,24(sp)
    80000e44:	6c42                	ld	s8,16(sp)
    80000e46:	6125                	addi	sp,sp,96
    80000e48:	8082                	ret
    return -1;
    80000e4a:	557d                	li	a0,-1
    80000e4c:	b7dd                	j	80000e32 <sys_ntas+0x16c>
    return 0;
    80000e4e:	4501                	li	a0,0
    80000e50:	b7cd                	j	80000e32 <sys_ntas+0x16c>

0000000080000e52 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000e52:	1141                	addi	sp,sp,-16
    80000e54:	e422                	sd	s0,8(sp)
    80000e56:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000e58:	ca19                	beqz	a2,80000e6e <memset+0x1c>
    80000e5a:	87aa                	mv	a5,a0
    80000e5c:	1602                	slli	a2,a2,0x20
    80000e5e:	9201                	srli	a2,a2,0x20
    80000e60:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000e64:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000e68:	0785                	addi	a5,a5,1
    80000e6a:	fee79de3          	bne	a5,a4,80000e64 <memset+0x12>
  }
  return dst;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret

0000000080000e74 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000e74:	1141                	addi	sp,sp,-16
    80000e76:	e422                	sd	s0,8(sp)
    80000e78:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000e7a:	ca05                	beqz	a2,80000eaa <memcmp+0x36>
    80000e7c:	fff6069b          	addiw	a3,a2,-1
    80000e80:	1682                	slli	a3,a3,0x20
    80000e82:	9281                	srli	a3,a3,0x20
    80000e84:	0685                	addi	a3,a3,1
    80000e86:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000e88:	00054783          	lbu	a5,0(a0)
    80000e8c:	0005c703          	lbu	a4,0(a1)
    80000e90:	00e79863          	bne	a5,a4,80000ea0 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000e94:	0505                	addi	a0,a0,1
    80000e96:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000e98:	fed518e3          	bne	a0,a3,80000e88 <memcmp+0x14>
  }

  return 0;
    80000e9c:	4501                	li	a0,0
    80000e9e:	a019                	j	80000ea4 <memcmp+0x30>
      return *s1 - *s2;
    80000ea0:	40e7853b          	subw	a0,a5,a4
}
    80000ea4:	6422                	ld	s0,8(sp)
    80000ea6:	0141                	addi	sp,sp,16
    80000ea8:	8082                	ret
  return 0;
    80000eaa:	4501                	li	a0,0
    80000eac:	bfe5                	j	80000ea4 <memcmp+0x30>

0000000080000eae <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000eae:	1141                	addi	sp,sp,-16
    80000eb0:	e422                	sd	s0,8(sp)
    80000eb2:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000eb4:	02a5e563          	bltu	a1,a0,80000ede <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000eb8:	fff6069b          	addiw	a3,a2,-1
    80000ebc:	ce11                	beqz	a2,80000ed8 <memmove+0x2a>
    80000ebe:	1682                	slli	a3,a3,0x20
    80000ec0:	9281                	srli	a3,a3,0x20
    80000ec2:	0685                	addi	a3,a3,1
    80000ec4:	96ae                	add	a3,a3,a1
    80000ec6:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000ec8:	0585                	addi	a1,a1,1
    80000eca:	0785                	addi	a5,a5,1
    80000ecc:	fff5c703          	lbu	a4,-1(a1)
    80000ed0:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000ed4:	fed59ae3          	bne	a1,a3,80000ec8 <memmove+0x1a>

  return dst;
}
    80000ed8:	6422                	ld	s0,8(sp)
    80000eda:	0141                	addi	sp,sp,16
    80000edc:	8082                	ret
  if(s < d && s + n > d){
    80000ede:	02061713          	slli	a4,a2,0x20
    80000ee2:	9301                	srli	a4,a4,0x20
    80000ee4:	00e587b3          	add	a5,a1,a4
    80000ee8:	fcf578e3          	bgeu	a0,a5,80000eb8 <memmove+0xa>
    d += n;
    80000eec:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000eee:	fff6069b          	addiw	a3,a2,-1
    80000ef2:	d27d                	beqz	a2,80000ed8 <memmove+0x2a>
    80000ef4:	02069613          	slli	a2,a3,0x20
    80000ef8:	9201                	srli	a2,a2,0x20
    80000efa:	fff64613          	not	a2,a2
    80000efe:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000f00:	17fd                	addi	a5,a5,-1
    80000f02:	177d                	addi	a4,a4,-1
    80000f04:	0007c683          	lbu	a3,0(a5)
    80000f08:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000f0c:	fef61ae3          	bne	a2,a5,80000f00 <memmove+0x52>
    80000f10:	b7e1                	j	80000ed8 <memmove+0x2a>

0000000080000f12 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000f12:	1141                	addi	sp,sp,-16
    80000f14:	e406                	sd	ra,8(sp)
    80000f16:	e022                	sd	s0,0(sp)
    80000f18:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000f1a:	00000097          	auipc	ra,0x0
    80000f1e:	f94080e7          	jalr	-108(ra) # 80000eae <memmove>
}
    80000f22:	60a2                	ld	ra,8(sp)
    80000f24:	6402                	ld	s0,0(sp)
    80000f26:	0141                	addi	sp,sp,16
    80000f28:	8082                	ret

0000000080000f2a <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000f2a:	1141                	addi	sp,sp,-16
    80000f2c:	e422                	sd	s0,8(sp)
    80000f2e:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000f30:	ce11                	beqz	a2,80000f4c <strncmp+0x22>
    80000f32:	00054783          	lbu	a5,0(a0)
    80000f36:	cf89                	beqz	a5,80000f50 <strncmp+0x26>
    80000f38:	0005c703          	lbu	a4,0(a1)
    80000f3c:	00f71a63          	bne	a4,a5,80000f50 <strncmp+0x26>
    n--, p++, q++;
    80000f40:	367d                	addiw	a2,a2,-1
    80000f42:	0505                	addi	a0,a0,1
    80000f44:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000f46:	f675                	bnez	a2,80000f32 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000f48:	4501                	li	a0,0
    80000f4a:	a809                	j	80000f5c <strncmp+0x32>
    80000f4c:	4501                	li	a0,0
    80000f4e:	a039                	j	80000f5c <strncmp+0x32>
  if(n == 0)
    80000f50:	ca09                	beqz	a2,80000f62 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000f52:	00054503          	lbu	a0,0(a0)
    80000f56:	0005c783          	lbu	a5,0(a1)
    80000f5a:	9d1d                	subw	a0,a0,a5
}
    80000f5c:	6422                	ld	s0,8(sp)
    80000f5e:	0141                	addi	sp,sp,16
    80000f60:	8082                	ret
    return 0;
    80000f62:	4501                	li	a0,0
    80000f64:	bfe5                	j	80000f5c <strncmp+0x32>

0000000080000f66 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000f66:	1141                	addi	sp,sp,-16
    80000f68:	e422                	sd	s0,8(sp)
    80000f6a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000f6c:	872a                	mv	a4,a0
    80000f6e:	8832                	mv	a6,a2
    80000f70:	367d                	addiw	a2,a2,-1
    80000f72:	01005963          	blez	a6,80000f84 <strncpy+0x1e>
    80000f76:	0705                	addi	a4,a4,1
    80000f78:	0005c783          	lbu	a5,0(a1)
    80000f7c:	fef70fa3          	sb	a5,-1(a4)
    80000f80:	0585                	addi	a1,a1,1
    80000f82:	f7f5                	bnez	a5,80000f6e <strncpy+0x8>
    ;
  while(n-- > 0)
    80000f84:	86ba                	mv	a3,a4
    80000f86:	00c05c63          	blez	a2,80000f9e <strncpy+0x38>
    *s++ = 0;
    80000f8a:	0685                	addi	a3,a3,1
    80000f8c:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000f90:	fff6c793          	not	a5,a3
    80000f94:	9fb9                	addw	a5,a5,a4
    80000f96:	010787bb          	addw	a5,a5,a6
    80000f9a:	fef048e3          	bgtz	a5,80000f8a <strncpy+0x24>
  return os;
}
    80000f9e:	6422                	ld	s0,8(sp)
    80000fa0:	0141                	addi	sp,sp,16
    80000fa2:	8082                	ret

0000000080000fa4 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000faa:	02c05363          	blez	a2,80000fd0 <safestrcpy+0x2c>
    80000fae:	fff6069b          	addiw	a3,a2,-1
    80000fb2:	1682                	slli	a3,a3,0x20
    80000fb4:	9281                	srli	a3,a3,0x20
    80000fb6:	96ae                	add	a3,a3,a1
    80000fb8:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000fba:	00d58963          	beq	a1,a3,80000fcc <safestrcpy+0x28>
    80000fbe:	0585                	addi	a1,a1,1
    80000fc0:	0785                	addi	a5,a5,1
    80000fc2:	fff5c703          	lbu	a4,-1(a1)
    80000fc6:	fee78fa3          	sb	a4,-1(a5)
    80000fca:	fb65                	bnez	a4,80000fba <safestrcpy+0x16>
    ;
  *s = 0;
    80000fcc:	00078023          	sb	zero,0(a5)
  return os;
}
    80000fd0:	6422                	ld	s0,8(sp)
    80000fd2:	0141                	addi	sp,sp,16
    80000fd4:	8082                	ret

0000000080000fd6 <strlen>:

int
strlen(const char *s)
{
    80000fd6:	1141                	addi	sp,sp,-16
    80000fd8:	e422                	sd	s0,8(sp)
    80000fda:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000fdc:	00054783          	lbu	a5,0(a0)
    80000fe0:	cf91                	beqz	a5,80000ffc <strlen+0x26>
    80000fe2:	0505                	addi	a0,a0,1
    80000fe4:	87aa                	mv	a5,a0
    80000fe6:	4685                	li	a3,1
    80000fe8:	9e89                	subw	a3,a3,a0
    80000fea:	00f6853b          	addw	a0,a3,a5
    80000fee:	0785                	addi	a5,a5,1
    80000ff0:	fff7c703          	lbu	a4,-1(a5)
    80000ff4:	fb7d                	bnez	a4,80000fea <strlen+0x14>
    ;
  return n;
}
    80000ff6:	6422                	ld	s0,8(sp)
    80000ff8:	0141                	addi	sp,sp,16
    80000ffa:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ffc:	4501                	li	a0,0
    80000ffe:	bfe5                	j	80000ff6 <strlen+0x20>

0000000080001000 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80001000:	1141                	addi	sp,sp,-16
    80001002:	e406                	sd	ra,8(sp)
    80001004:	e022                	sd	s0,0(sp)
    80001006:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80001008:	00001097          	auipc	ra,0x1
    8000100c:	b08080e7          	jalr	-1272(ra) # 80001b10 <cpuid>
    virtio_disk_init(minor(ROOTDEV)); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80001010:	0002b717          	auipc	a4,0x2b
    80001014:	01870713          	addi	a4,a4,24 # 8002c028 <started>
  if(cpuid() == 0){
    80001018:	c139                	beqz	a0,8000105e <main+0x5e>
    while(started == 0)
    8000101a:	431c                	lw	a5,0(a4)
    8000101c:	2781                	sext.w	a5,a5
    8000101e:	dff5                	beqz	a5,8000101a <main+0x1a>
      ;
    __sync_synchronize();
    80001020:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80001024:	00001097          	auipc	ra,0x1
    80001028:	aec080e7          	jalr	-1300(ra) # 80001b10 <cpuid>
    8000102c:	85aa                	mv	a1,a0
    8000102e:	00007517          	auipc	a0,0x7
    80001032:	2ca50513          	addi	a0,a0,714 # 800082f8 <userret+0x268>
    80001036:	fffff097          	auipc	ra,0xfffff
    8000103a:	56c080e7          	jalr	1388(ra) # 800005a2 <printf>
    kvminithart();    // turn on paging
    8000103e:	00000097          	auipc	ra,0x0
    80001042:	1ea080e7          	jalr	490(ra) # 80001228 <kvminithart>
    trapinithart();   // install kernel trap vector
    80001046:	00001097          	auipc	ra,0x1
    8000104a:	714080e7          	jalr	1812(ra) # 8000275a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    8000104e:	00005097          	auipc	ra,0x5
    80001052:	dc2080e7          	jalr	-574(ra) # 80005e10 <plicinithart>
  }

  scheduler();        
    80001056:	00001097          	auipc	ra,0x1
    8000105a:	fc4080e7          	jalr	-60(ra) # 8000201a <scheduler>
    consoleinit();
    8000105e:	fffff097          	auipc	ra,0xfffff
    80001062:	3fc080e7          	jalr	1020(ra) # 8000045a <consoleinit>
    printfinit();
    80001066:	fffff097          	auipc	ra,0xfffff
    8000106a:	71c080e7          	jalr	1820(ra) # 80000782 <printfinit>
    printf("\n");
    8000106e:	00007517          	auipc	a0,0x7
    80001072:	22250513          	addi	a0,a0,546 # 80008290 <userret+0x200>
    80001076:	fffff097          	auipc	ra,0xfffff
    8000107a:	52c080e7          	jalr	1324(ra) # 800005a2 <printf>
    printf("xv6 kernel is booting\n");
    8000107e:	00007517          	auipc	a0,0x7
    80001082:	26250513          	addi	a0,a0,610 # 800082e0 <userret+0x250>
    80001086:	fffff097          	auipc	ra,0xfffff
    8000108a:	51c080e7          	jalr	1308(ra) # 800005a2 <printf>
    printf("\n");
    8000108e:	00007517          	auipc	a0,0x7
    80001092:	20250513          	addi	a0,a0,514 # 80008290 <userret+0x200>
    80001096:	fffff097          	auipc	ra,0xfffff
    8000109a:	50c080e7          	jalr	1292(ra) # 800005a2 <printf>
    kinit();         // physical page allocator
    8000109e:	00000097          	auipc	ra,0x0
    800010a2:	8b6080e7          	jalr	-1866(ra) # 80000954 <kinit>
    kvminit();       // create kernel page table
    800010a6:	00000097          	auipc	ra,0x0
    800010aa:	30c080e7          	jalr	780(ra) # 800013b2 <kvminit>
    kvminithart();   // turn on paging
    800010ae:	00000097          	auipc	ra,0x0
    800010b2:	17a080e7          	jalr	378(ra) # 80001228 <kvminithart>
    procinit();      // process table
    800010b6:	00001097          	auipc	ra,0x1
    800010ba:	98a080e7          	jalr	-1654(ra) # 80001a40 <procinit>
    trapinit();      // trap vectors
    800010be:	00001097          	auipc	ra,0x1
    800010c2:	674080e7          	jalr	1652(ra) # 80002732 <trapinit>
    trapinithart();  // install kernel trap vector
    800010c6:	00001097          	auipc	ra,0x1
    800010ca:	694080e7          	jalr	1684(ra) # 8000275a <trapinithart>
    plicinit();      // set up interrupt controller
    800010ce:	00005097          	auipc	ra,0x5
    800010d2:	d2c080e7          	jalr	-724(ra) # 80005dfa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    800010d6:	00005097          	auipc	ra,0x5
    800010da:	d3a080e7          	jalr	-710(ra) # 80005e10 <plicinithart>
    binit();         // buffer cache
    800010de:	00002097          	auipc	ra,0x2
    800010e2:	db8080e7          	jalr	-584(ra) # 80002e96 <binit>
    iinit();         // inode cache
    800010e6:	00002097          	auipc	ra,0x2
    800010ea:	44e080e7          	jalr	1102(ra) # 80003534 <iinit>
    fileinit();      // file table
    800010ee:	00003097          	auipc	ra,0x3
    800010f2:	4da080e7          	jalr	1242(ra) # 800045c8 <fileinit>
    virtio_disk_init(minor(ROOTDEV)); // emulated hard disk
    800010f6:	4501                	li	a0,0
    800010f8:	00005097          	auipc	ra,0x5
    800010fc:	e3a080e7          	jalr	-454(ra) # 80005f32 <virtio_disk_init>
    userinit();      // first user process
    80001100:	00001097          	auipc	ra,0x1
    80001104:	cb0080e7          	jalr	-848(ra) # 80001db0 <userinit>
    __sync_synchronize();
    80001108:	0ff0000f          	fence
    started = 1;
    8000110c:	4785                	li	a5,1
    8000110e:	0002b717          	auipc	a4,0x2b
    80001112:	f0f72d23          	sw	a5,-230(a4) # 8002c028 <started>
    80001116:	b781                	j	80001056 <main+0x56>

0000000080001118 <walk>:
//   21..39 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..12 -- 12 bits of byte offset within the page.
static pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001118:	7139                	addi	sp,sp,-64
    8000111a:	fc06                	sd	ra,56(sp)
    8000111c:	f822                	sd	s0,48(sp)
    8000111e:	f426                	sd	s1,40(sp)
    80001120:	f04a                	sd	s2,32(sp)
    80001122:	ec4e                	sd	s3,24(sp)
    80001124:	e852                	sd	s4,16(sp)
    80001126:	e456                	sd	s5,8(sp)
    80001128:	e05a                	sd	s6,0(sp)
    8000112a:	0080                	addi	s0,sp,64
    8000112c:	84aa                	mv	s1,a0
    8000112e:	89ae                	mv	s3,a1
    80001130:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001132:	57fd                	li	a5,-1
    80001134:	83e9                	srli	a5,a5,0x1a
    80001136:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001138:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000113a:	04b7f263          	bgeu	a5,a1,8000117e <walk+0x66>
    panic("walk");
    8000113e:	00007517          	auipc	a0,0x7
    80001142:	1d250513          	addi	a0,a0,466 # 80008310 <userret+0x280>
    80001146:	fffff097          	auipc	ra,0xfffff
    8000114a:	402080e7          	jalr	1026(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000114e:	060a8663          	beqz	s5,800011ba <walk+0xa2>
    80001152:	00000097          	auipc	ra,0x0
    80001156:	85e080e7          	jalr	-1954(ra) # 800009b0 <kalloc>
    8000115a:	84aa                	mv	s1,a0
    8000115c:	c529                	beqz	a0,800011a6 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000115e:	6605                	lui	a2,0x1
    80001160:	4581                	li	a1,0
    80001162:	00000097          	auipc	ra,0x0
    80001166:	cf0080e7          	jalr	-784(ra) # 80000e52 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000116a:	00c4d793          	srli	a5,s1,0xc
    8000116e:	07aa                	slli	a5,a5,0xa
    80001170:	0017e793          	ori	a5,a5,1
    80001174:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001178:	3a5d                	addiw	s4,s4,-9
    8000117a:	036a0063          	beq	s4,s6,8000119a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000117e:	0149d933          	srl	s2,s3,s4
    80001182:	1ff97913          	andi	s2,s2,511
    80001186:	090e                	slli	s2,s2,0x3
    80001188:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000118a:	00093483          	ld	s1,0(s2)
    8000118e:	0014f793          	andi	a5,s1,1
    80001192:	dfd5                	beqz	a5,8000114e <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001194:	80a9                	srli	s1,s1,0xa
    80001196:	04b2                	slli	s1,s1,0xc
    80001198:	b7c5                	j	80001178 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000119a:	00c9d513          	srli	a0,s3,0xc
    8000119e:	1ff57513          	andi	a0,a0,511
    800011a2:	050e                	slli	a0,a0,0x3
    800011a4:	9526                	add	a0,a0,s1
}
    800011a6:	70e2                	ld	ra,56(sp)
    800011a8:	7442                	ld	s0,48(sp)
    800011aa:	74a2                	ld	s1,40(sp)
    800011ac:	7902                	ld	s2,32(sp)
    800011ae:	69e2                	ld	s3,24(sp)
    800011b0:	6a42                	ld	s4,16(sp)
    800011b2:	6aa2                	ld	s5,8(sp)
    800011b4:	6b02                	ld	s6,0(sp)
    800011b6:	6121                	addi	sp,sp,64
    800011b8:	8082                	ret
        return 0;
    800011ba:	4501                	li	a0,0
    800011bc:	b7ed                	j	800011a6 <walk+0x8e>

00000000800011be <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
static void
freewalk(pagetable_t pagetable)
{
    800011be:	7179                	addi	sp,sp,-48
    800011c0:	f406                	sd	ra,40(sp)
    800011c2:	f022                	sd	s0,32(sp)
    800011c4:	ec26                	sd	s1,24(sp)
    800011c6:	e84a                	sd	s2,16(sp)
    800011c8:	e44e                	sd	s3,8(sp)
    800011ca:	e052                	sd	s4,0(sp)
    800011cc:	1800                	addi	s0,sp,48
    800011ce:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800011d0:	84aa                	mv	s1,a0
    800011d2:	6905                	lui	s2,0x1
    800011d4:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800011d6:	4985                	li	s3,1
    800011d8:	a821                	j	800011f0 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800011da:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800011dc:	0532                	slli	a0,a0,0xc
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	fe0080e7          	jalr	-32(ra) # 800011be <freewalk>
      pagetable[i] = 0;
    800011e6:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800011ea:	04a1                	addi	s1,s1,8
    800011ec:	03248163          	beq	s1,s2,8000120e <freewalk+0x50>
    pte_t pte = pagetable[i];
    800011f0:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800011f2:	00f57793          	andi	a5,a0,15
    800011f6:	ff3782e3          	beq	a5,s3,800011da <freewalk+0x1c>
    } else if(pte & PTE_V){
    800011fa:	8905                	andi	a0,a0,1
    800011fc:	d57d                	beqz	a0,800011ea <freewalk+0x2c>
      panic("freewalk: leaf");
    800011fe:	00007517          	auipc	a0,0x7
    80001202:	11a50513          	addi	a0,a0,282 # 80008318 <userret+0x288>
    80001206:	fffff097          	auipc	ra,0xfffff
    8000120a:	342080e7          	jalr	834(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    8000120e:	8552                	mv	a0,s4
    80001210:	fffff097          	auipc	ra,0xfffff
    80001214:	654080e7          	jalr	1620(ra) # 80000864 <kfree>
}
    80001218:	70a2                	ld	ra,40(sp)
    8000121a:	7402                	ld	s0,32(sp)
    8000121c:	64e2                	ld	s1,24(sp)
    8000121e:	6942                	ld	s2,16(sp)
    80001220:	69a2                	ld	s3,8(sp)
    80001222:	6a02                	ld	s4,0(sp)
    80001224:	6145                	addi	sp,sp,48
    80001226:	8082                	ret

0000000080001228 <kvminithart>:
{
    80001228:	1141                	addi	sp,sp,-16
    8000122a:	e422                	sd	s0,8(sp)
    8000122c:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    8000122e:	0002b797          	auipc	a5,0x2b
    80001232:	e027b783          	ld	a5,-510(a5) # 8002c030 <kernel_pagetable>
    80001236:	83b1                	srli	a5,a5,0xc
    80001238:	577d                	li	a4,-1
    8000123a:	177e                	slli	a4,a4,0x3f
    8000123c:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    8000123e:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001242:	12000073          	sfence.vma
}
    80001246:	6422                	ld	s0,8(sp)
    80001248:	0141                	addi	sp,sp,16
    8000124a:	8082                	ret

000000008000124c <walkaddr>:
  if(va >= MAXVA)
    8000124c:	57fd                	li	a5,-1
    8000124e:	83e9                	srli	a5,a5,0x1a
    80001250:	00b7f463          	bgeu	a5,a1,80001258 <walkaddr+0xc>
    return 0;
    80001254:	4501                	li	a0,0
}
    80001256:	8082                	ret
{
    80001258:	1141                	addi	sp,sp,-16
    8000125a:	e406                	sd	ra,8(sp)
    8000125c:	e022                	sd	s0,0(sp)
    8000125e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001260:	4601                	li	a2,0
    80001262:	00000097          	auipc	ra,0x0
    80001266:	eb6080e7          	jalr	-330(ra) # 80001118 <walk>
  if(pte == 0)
    8000126a:	c105                	beqz	a0,8000128a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000126c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000126e:	0117f693          	andi	a3,a5,17
    80001272:	4745                	li	a4,17
    return 0;
    80001274:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001276:	00e68663          	beq	a3,a4,80001282 <walkaddr+0x36>
}
    8000127a:	60a2                	ld	ra,8(sp)
    8000127c:	6402                	ld	s0,0(sp)
    8000127e:	0141                	addi	sp,sp,16
    80001280:	8082                	ret
  pa = PTE2PA(*pte);
    80001282:	00a7d513          	srli	a0,a5,0xa
    80001286:	0532                	slli	a0,a0,0xc
  return pa;
    80001288:	bfcd                	j	8000127a <walkaddr+0x2e>
    return 0;
    8000128a:	4501                	li	a0,0
    8000128c:	b7fd                	j	8000127a <walkaddr+0x2e>

000000008000128e <kvmpa>:
{
    8000128e:	1101                	addi	sp,sp,-32
    80001290:	ec06                	sd	ra,24(sp)
    80001292:	e822                	sd	s0,16(sp)
    80001294:	e426                	sd	s1,8(sp)
    80001296:	1000                	addi	s0,sp,32
    80001298:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    8000129a:	1552                	slli	a0,a0,0x34
    8000129c:	03455493          	srli	s1,a0,0x34
  pte = walk(kernel_pagetable, va, 0);
    800012a0:	4601                	li	a2,0
    800012a2:	0002b517          	auipc	a0,0x2b
    800012a6:	d8e53503          	ld	a0,-626(a0) # 8002c030 <kernel_pagetable>
    800012aa:	00000097          	auipc	ra,0x0
    800012ae:	e6e080e7          	jalr	-402(ra) # 80001118 <walk>
  if(pte == 0)
    800012b2:	cd09                	beqz	a0,800012cc <kvmpa+0x3e>
  if((*pte & PTE_V) == 0)
    800012b4:	6108                	ld	a0,0(a0)
    800012b6:	00157793          	andi	a5,a0,1
    800012ba:	c38d                	beqz	a5,800012dc <kvmpa+0x4e>
  pa = PTE2PA(*pte);
    800012bc:	8129                	srli	a0,a0,0xa
    800012be:	0532                	slli	a0,a0,0xc
}
    800012c0:	9526                	add	a0,a0,s1
    800012c2:	60e2                	ld	ra,24(sp)
    800012c4:	6442                	ld	s0,16(sp)
    800012c6:	64a2                	ld	s1,8(sp)
    800012c8:	6105                	addi	sp,sp,32
    800012ca:	8082                	ret
    panic("kvmpa");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	05c50513          	addi	a0,a0,92 # 80008328 <userret+0x298>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	274080e7          	jalr	628(ra) # 80000548 <panic>
    panic("kvmpa");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	04c50513          	addi	a0,a0,76 # 80008328 <userret+0x298>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	264080e7          	jalr	612(ra) # 80000548 <panic>

00000000800012ec <mappages>:
{
    800012ec:	715d                	addi	sp,sp,-80
    800012ee:	e486                	sd	ra,72(sp)
    800012f0:	e0a2                	sd	s0,64(sp)
    800012f2:	fc26                	sd	s1,56(sp)
    800012f4:	f84a                	sd	s2,48(sp)
    800012f6:	f44e                	sd	s3,40(sp)
    800012f8:	f052                	sd	s4,32(sp)
    800012fa:	ec56                	sd	s5,24(sp)
    800012fc:	e85a                	sd	s6,16(sp)
    800012fe:	e45e                	sd	s7,8(sp)
    80001300:	0880                	addi	s0,sp,80
    80001302:	8aaa                	mv	s5,a0
    80001304:	8b3a                	mv	s6,a4
  a = PGROUNDDOWN(va);
    80001306:	777d                	lui	a4,0xfffff
    80001308:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000130c:	167d                	addi	a2,a2,-1
    8000130e:	00b609b3          	add	s3,a2,a1
    80001312:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001316:	893e                	mv	s2,a5
    80001318:	40f68a33          	sub	s4,a3,a5
    a += PGSIZE;
    8000131c:	6b85                	lui	s7,0x1
    8000131e:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001322:	4605                	li	a2,1
    80001324:	85ca                	mv	a1,s2
    80001326:	8556                	mv	a0,s5
    80001328:	00000097          	auipc	ra,0x0
    8000132c:	df0080e7          	jalr	-528(ra) # 80001118 <walk>
    80001330:	c51d                	beqz	a0,8000135e <mappages+0x72>
    if(*pte & PTE_V)
    80001332:	611c                	ld	a5,0(a0)
    80001334:	8b85                	andi	a5,a5,1
    80001336:	ef81                	bnez	a5,8000134e <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001338:	80b1                	srli	s1,s1,0xc
    8000133a:	04aa                	slli	s1,s1,0xa
    8000133c:	0164e4b3          	or	s1,s1,s6
    80001340:	0014e493          	ori	s1,s1,1
    80001344:	e104                	sd	s1,0(a0)
    if(a == last)
    80001346:	03390863          	beq	s2,s3,80001376 <mappages+0x8a>
    a += PGSIZE;
    8000134a:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000134c:	bfc9                	j	8000131e <mappages+0x32>
      panic("remap");
    8000134e:	00007517          	auipc	a0,0x7
    80001352:	fe250513          	addi	a0,a0,-30 # 80008330 <userret+0x2a0>
    80001356:	fffff097          	auipc	ra,0xfffff
    8000135a:	1f2080e7          	jalr	498(ra) # 80000548 <panic>
      return -1;
    8000135e:	557d                	li	a0,-1
}
    80001360:	60a6                	ld	ra,72(sp)
    80001362:	6406                	ld	s0,64(sp)
    80001364:	74e2                	ld	s1,56(sp)
    80001366:	7942                	ld	s2,48(sp)
    80001368:	79a2                	ld	s3,40(sp)
    8000136a:	7a02                	ld	s4,32(sp)
    8000136c:	6ae2                	ld	s5,24(sp)
    8000136e:	6b42                	ld	s6,16(sp)
    80001370:	6ba2                	ld	s7,8(sp)
    80001372:	6161                	addi	sp,sp,80
    80001374:	8082                	ret
  return 0;
    80001376:	4501                	li	a0,0
    80001378:	b7e5                	j	80001360 <mappages+0x74>

000000008000137a <kvmmap>:
{
    8000137a:	1141                	addi	sp,sp,-16
    8000137c:	e406                	sd	ra,8(sp)
    8000137e:	e022                	sd	s0,0(sp)
    80001380:	0800                	addi	s0,sp,16
    80001382:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001384:	86ae                	mv	a3,a1
    80001386:	85aa                	mv	a1,a0
    80001388:	0002b517          	auipc	a0,0x2b
    8000138c:	ca853503          	ld	a0,-856(a0) # 8002c030 <kernel_pagetable>
    80001390:	00000097          	auipc	ra,0x0
    80001394:	f5c080e7          	jalr	-164(ra) # 800012ec <mappages>
    80001398:	e509                	bnez	a0,800013a2 <kvmmap+0x28>
}
    8000139a:	60a2                	ld	ra,8(sp)
    8000139c:	6402                	ld	s0,0(sp)
    8000139e:	0141                	addi	sp,sp,16
    800013a0:	8082                	ret
    panic("kvmmap");
    800013a2:	00007517          	auipc	a0,0x7
    800013a6:	f9650513          	addi	a0,a0,-106 # 80008338 <userret+0x2a8>
    800013aa:	fffff097          	auipc	ra,0xfffff
    800013ae:	19e080e7          	jalr	414(ra) # 80000548 <panic>

00000000800013b2 <kvminit>:
{
    800013b2:	1101                	addi	sp,sp,-32
    800013b4:	ec06                	sd	ra,24(sp)
    800013b6:	e822                	sd	s0,16(sp)
    800013b8:	e426                	sd	s1,8(sp)
    800013ba:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    800013bc:	fffff097          	auipc	ra,0xfffff
    800013c0:	5f4080e7          	jalr	1524(ra) # 800009b0 <kalloc>
    800013c4:	0002b797          	auipc	a5,0x2b
    800013c8:	c6a7b623          	sd	a0,-916(a5) # 8002c030 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    800013cc:	6605                	lui	a2,0x1
    800013ce:	4581                	li	a1,0
    800013d0:	00000097          	auipc	ra,0x0
    800013d4:	a82080e7          	jalr	-1406(ra) # 80000e52 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800013d8:	4699                	li	a3,6
    800013da:	6605                	lui	a2,0x1
    800013dc:	100005b7          	lui	a1,0x10000
    800013e0:	10000537          	lui	a0,0x10000
    800013e4:	00000097          	auipc	ra,0x0
    800013e8:	f96080e7          	jalr	-106(ra) # 8000137a <kvmmap>
  kvmmap(VIRTION(0), VIRTION(0), PGSIZE, PTE_R | PTE_W);
    800013ec:	4699                	li	a3,6
    800013ee:	6605                	lui	a2,0x1
    800013f0:	100015b7          	lui	a1,0x10001
    800013f4:	10001537          	lui	a0,0x10001
    800013f8:	00000097          	auipc	ra,0x0
    800013fc:	f82080e7          	jalr	-126(ra) # 8000137a <kvmmap>
  kvmmap(VIRTION(1), VIRTION(1), PGSIZE, PTE_R | PTE_W);
    80001400:	4699                	li	a3,6
    80001402:	6605                	lui	a2,0x1
    80001404:	100025b7          	lui	a1,0x10002
    80001408:	10002537          	lui	a0,0x10002
    8000140c:	00000097          	auipc	ra,0x0
    80001410:	f6e080e7          	jalr	-146(ra) # 8000137a <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    80001414:	4699                	li	a3,6
    80001416:	6641                	lui	a2,0x10
    80001418:	020005b7          	lui	a1,0x2000
    8000141c:	02000537          	lui	a0,0x2000
    80001420:	00000097          	auipc	ra,0x0
    80001424:	f5a080e7          	jalr	-166(ra) # 8000137a <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001428:	4699                	li	a3,6
    8000142a:	00400637          	lui	a2,0x400
    8000142e:	0c0005b7          	lui	a1,0xc000
    80001432:	0c000537          	lui	a0,0xc000
    80001436:	00000097          	auipc	ra,0x0
    8000143a:	f44080e7          	jalr	-188(ra) # 8000137a <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000143e:	00008497          	auipc	s1,0x8
    80001442:	bc248493          	addi	s1,s1,-1086 # 80009000 <initcode>
    80001446:	46a9                	li	a3,10
    80001448:	80008617          	auipc	a2,0x80008
    8000144c:	bb860613          	addi	a2,a2,-1096 # 9000 <_entry-0x7fff7000>
    80001450:	4585                	li	a1,1
    80001452:	05fe                	slli	a1,a1,0x1f
    80001454:	852e                	mv	a0,a1
    80001456:	00000097          	auipc	ra,0x0
    8000145a:	f24080e7          	jalr	-220(ra) # 8000137a <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000145e:	4699                	li	a3,6
    80001460:	4645                	li	a2,17
    80001462:	066e                	slli	a2,a2,0x1b
    80001464:	8e05                	sub	a2,a2,s1
    80001466:	85a6                	mv	a1,s1
    80001468:	8526                	mv	a0,s1
    8000146a:	00000097          	auipc	ra,0x0
    8000146e:	f10080e7          	jalr	-240(ra) # 8000137a <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001472:	46a9                	li	a3,10
    80001474:	6605                	lui	a2,0x1
    80001476:	00007597          	auipc	a1,0x7
    8000147a:	b8a58593          	addi	a1,a1,-1142 # 80008000 <trampoline>
    8000147e:	04000537          	lui	a0,0x4000
    80001482:	157d                	addi	a0,a0,-1
    80001484:	0532                	slli	a0,a0,0xc
    80001486:	00000097          	auipc	ra,0x0
    8000148a:	ef4080e7          	jalr	-268(ra) # 8000137a <kvmmap>
}
    8000148e:	60e2                	ld	ra,24(sp)
    80001490:	6442                	ld	s0,16(sp)
    80001492:	64a2                	ld	s1,8(sp)
    80001494:	6105                	addi	sp,sp,32
    80001496:	8082                	ret

0000000080001498 <uvmunmap>:
{
    80001498:	715d                	addi	sp,sp,-80
    8000149a:	e486                	sd	ra,72(sp)
    8000149c:	e0a2                	sd	s0,64(sp)
    8000149e:	fc26                	sd	s1,56(sp)
    800014a0:	f84a                	sd	s2,48(sp)
    800014a2:	f44e                	sd	s3,40(sp)
    800014a4:	f052                	sd	s4,32(sp)
    800014a6:	ec56                	sd	s5,24(sp)
    800014a8:	e85a                	sd	s6,16(sp)
    800014aa:	e45e                	sd	s7,8(sp)
    800014ac:	0880                	addi	s0,sp,80
    800014ae:	8a2a                	mv	s4,a0
    800014b0:	8ab6                	mv	s5,a3
  a = PGROUNDDOWN(va);
    800014b2:	77fd                	lui	a5,0xfffff
    800014b4:	00f5f933          	and	s2,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800014b8:	167d                	addi	a2,a2,-1
    800014ba:	00b609b3          	add	s3,a2,a1
    800014be:	00f9f9b3          	and	s3,s3,a5
    if(PTE_FLAGS(*pte) == PTE_V)
    800014c2:	4b05                	li	s6,1
    a += PGSIZE;
    800014c4:	6b85                	lui	s7,0x1
    800014c6:	a0b9                	j	80001514 <uvmunmap+0x7c>
      panic("uvmunmap: walk");
    800014c8:	00007517          	auipc	a0,0x7
    800014cc:	e7850513          	addi	a0,a0,-392 # 80008340 <userret+0x2b0>
    800014d0:	fffff097          	auipc	ra,0xfffff
    800014d4:	078080e7          	jalr	120(ra) # 80000548 <panic>
      printf("va=%p pte=%p\n", a, *pte);
    800014d8:	85ca                	mv	a1,s2
    800014da:	00007517          	auipc	a0,0x7
    800014de:	e7650513          	addi	a0,a0,-394 # 80008350 <userret+0x2c0>
    800014e2:	fffff097          	auipc	ra,0xfffff
    800014e6:	0c0080e7          	jalr	192(ra) # 800005a2 <printf>
      panic("uvmunmap: not mapped");
    800014ea:	00007517          	auipc	a0,0x7
    800014ee:	e7650513          	addi	a0,a0,-394 # 80008360 <userret+0x2d0>
    800014f2:	fffff097          	auipc	ra,0xfffff
    800014f6:	056080e7          	jalr	86(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    800014fa:	00007517          	auipc	a0,0x7
    800014fe:	e7e50513          	addi	a0,a0,-386 # 80008378 <userret+0x2e8>
    80001502:	fffff097          	auipc	ra,0xfffff
    80001506:	046080e7          	jalr	70(ra) # 80000548 <panic>
    *pte = 0;
    8000150a:	0004b023          	sd	zero,0(s1)
    if(a == last)
    8000150e:	03390e63          	beq	s2,s3,8000154a <uvmunmap+0xb2>
    a += PGSIZE;
    80001512:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 0)) == 0)
    80001514:	4601                	li	a2,0
    80001516:	85ca                	mv	a1,s2
    80001518:	8552                	mv	a0,s4
    8000151a:	00000097          	auipc	ra,0x0
    8000151e:	bfe080e7          	jalr	-1026(ra) # 80001118 <walk>
    80001522:	84aa                	mv	s1,a0
    80001524:	d155                	beqz	a0,800014c8 <uvmunmap+0x30>
    if((*pte & PTE_V) == 0){
    80001526:	6110                	ld	a2,0(a0)
    80001528:	00167793          	andi	a5,a2,1
    8000152c:	d7d5                	beqz	a5,800014d8 <uvmunmap+0x40>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000152e:	3ff67793          	andi	a5,a2,1023
    80001532:	fd6784e3          	beq	a5,s6,800014fa <uvmunmap+0x62>
    if(do_free){
    80001536:	fc0a8ae3          	beqz	s5,8000150a <uvmunmap+0x72>
      pa = PTE2PA(*pte);
    8000153a:	8229                	srli	a2,a2,0xa
      kfree((void*)pa);
    8000153c:	00c61513          	slli	a0,a2,0xc
    80001540:	fffff097          	auipc	ra,0xfffff
    80001544:	324080e7          	jalr	804(ra) # 80000864 <kfree>
    80001548:	b7c9                	j	8000150a <uvmunmap+0x72>
}
    8000154a:	60a6                	ld	ra,72(sp)
    8000154c:	6406                	ld	s0,64(sp)
    8000154e:	74e2                	ld	s1,56(sp)
    80001550:	7942                	ld	s2,48(sp)
    80001552:	79a2                	ld	s3,40(sp)
    80001554:	7a02                	ld	s4,32(sp)
    80001556:	6ae2                	ld	s5,24(sp)
    80001558:	6b42                	ld	s6,16(sp)
    8000155a:	6ba2                	ld	s7,8(sp)
    8000155c:	6161                	addi	sp,sp,80
    8000155e:	8082                	ret

0000000080001560 <uvmcreate>:
{
    80001560:	1101                	addi	sp,sp,-32
    80001562:	ec06                	sd	ra,24(sp)
    80001564:	e822                	sd	s0,16(sp)
    80001566:	e426                	sd	s1,8(sp)
    80001568:	1000                	addi	s0,sp,32
  pagetable = (pagetable_t) kalloc();
    8000156a:	fffff097          	auipc	ra,0xfffff
    8000156e:	446080e7          	jalr	1094(ra) # 800009b0 <kalloc>
  if(pagetable == 0)
    80001572:	cd11                	beqz	a0,8000158e <uvmcreate+0x2e>
    80001574:	84aa                	mv	s1,a0
  memset(pagetable, 0, PGSIZE);
    80001576:	6605                	lui	a2,0x1
    80001578:	4581                	li	a1,0
    8000157a:	00000097          	auipc	ra,0x0
    8000157e:	8d8080e7          	jalr	-1832(ra) # 80000e52 <memset>
}
    80001582:	8526                	mv	a0,s1
    80001584:	60e2                	ld	ra,24(sp)
    80001586:	6442                	ld	s0,16(sp)
    80001588:	64a2                	ld	s1,8(sp)
    8000158a:	6105                	addi	sp,sp,32
    8000158c:	8082                	ret
    panic("uvmcreate: out of memory");
    8000158e:	00007517          	auipc	a0,0x7
    80001592:	e0250513          	addi	a0,a0,-510 # 80008390 <userret+0x300>
    80001596:	fffff097          	auipc	ra,0xfffff
    8000159a:	fb2080e7          	jalr	-78(ra) # 80000548 <panic>

000000008000159e <uvminit>:
{
    8000159e:	7179                	addi	sp,sp,-48
    800015a0:	f406                	sd	ra,40(sp)
    800015a2:	f022                	sd	s0,32(sp)
    800015a4:	ec26                	sd	s1,24(sp)
    800015a6:	e84a                	sd	s2,16(sp)
    800015a8:	e44e                	sd	s3,8(sp)
    800015aa:	e052                	sd	s4,0(sp)
    800015ac:	1800                	addi	s0,sp,48
  if(sz >= PGSIZE)
    800015ae:	6785                	lui	a5,0x1
    800015b0:	04f67863          	bgeu	a2,a5,80001600 <uvminit+0x62>
    800015b4:	8a2a                	mv	s4,a0
    800015b6:	89ae                	mv	s3,a1
    800015b8:	84b2                	mv	s1,a2
  mem = kalloc();
    800015ba:	fffff097          	auipc	ra,0xfffff
    800015be:	3f6080e7          	jalr	1014(ra) # 800009b0 <kalloc>
    800015c2:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800015c4:	6605                	lui	a2,0x1
    800015c6:	4581                	li	a1,0
    800015c8:	00000097          	auipc	ra,0x0
    800015cc:	88a080e7          	jalr	-1910(ra) # 80000e52 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800015d0:	4779                	li	a4,30
    800015d2:	86ca                	mv	a3,s2
    800015d4:	6605                	lui	a2,0x1
    800015d6:	4581                	li	a1,0
    800015d8:	8552                	mv	a0,s4
    800015da:	00000097          	auipc	ra,0x0
    800015de:	d12080e7          	jalr	-750(ra) # 800012ec <mappages>
  memmove(mem, src, sz);
    800015e2:	8626                	mv	a2,s1
    800015e4:	85ce                	mv	a1,s3
    800015e6:	854a                	mv	a0,s2
    800015e8:	00000097          	auipc	ra,0x0
    800015ec:	8c6080e7          	jalr	-1850(ra) # 80000eae <memmove>
}
    800015f0:	70a2                	ld	ra,40(sp)
    800015f2:	7402                	ld	s0,32(sp)
    800015f4:	64e2                	ld	s1,24(sp)
    800015f6:	6942                	ld	s2,16(sp)
    800015f8:	69a2                	ld	s3,8(sp)
    800015fa:	6a02                	ld	s4,0(sp)
    800015fc:	6145                	addi	sp,sp,48
    800015fe:	8082                	ret
    panic("inituvm: more than a page");
    80001600:	00007517          	auipc	a0,0x7
    80001604:	db050513          	addi	a0,a0,-592 # 800083b0 <userret+0x320>
    80001608:	fffff097          	auipc	ra,0xfffff
    8000160c:	f40080e7          	jalr	-192(ra) # 80000548 <panic>

0000000080001610 <uvmdealloc>:
{
    80001610:	1101                	addi	sp,sp,-32
    80001612:	ec06                	sd	ra,24(sp)
    80001614:	e822                	sd	s0,16(sp)
    80001616:	e426                	sd	s1,8(sp)
    80001618:	1000                	addi	s0,sp,32
    return oldsz;
    8000161a:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000161c:	00b67d63          	bgeu	a2,a1,80001636 <uvmdealloc+0x26>
    80001620:	84b2                	mv	s1,a2
  uint64 newup = PGROUNDUP(newsz);
    80001622:	6785                	lui	a5,0x1
    80001624:	17fd                	addi	a5,a5,-1
    80001626:	00f60733          	add	a4,a2,a5
    8000162a:	76fd                	lui	a3,0xfffff
    8000162c:	8f75                	and	a4,a4,a3
  if(newup < PGROUNDUP(oldsz))
    8000162e:	97ae                	add	a5,a5,a1
    80001630:	8ff5                	and	a5,a5,a3
    80001632:	00f76863          	bltu	a4,a5,80001642 <uvmdealloc+0x32>
}
    80001636:	8526                	mv	a0,s1
    80001638:	60e2                	ld	ra,24(sp)
    8000163a:	6442                	ld	s0,16(sp)
    8000163c:	64a2                	ld	s1,8(sp)
    8000163e:	6105                	addi	sp,sp,32
    80001640:	8082                	ret
    uvmunmap(pagetable, newup, oldsz - newup, 1);
    80001642:	4685                	li	a3,1
    80001644:	40e58633          	sub	a2,a1,a4
    80001648:	85ba                	mv	a1,a4
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	e4e080e7          	jalr	-434(ra) # 80001498 <uvmunmap>
    80001652:	b7d5                	j	80001636 <uvmdealloc+0x26>

0000000080001654 <uvmalloc>:
  if(newsz < oldsz)
    80001654:	0ab66163          	bltu	a2,a1,800016f6 <uvmalloc+0xa2>
{
    80001658:	7139                	addi	sp,sp,-64
    8000165a:	fc06                	sd	ra,56(sp)
    8000165c:	f822                	sd	s0,48(sp)
    8000165e:	f426                	sd	s1,40(sp)
    80001660:	f04a                	sd	s2,32(sp)
    80001662:	ec4e                	sd	s3,24(sp)
    80001664:	e852                	sd	s4,16(sp)
    80001666:	e456                	sd	s5,8(sp)
    80001668:	0080                	addi	s0,sp,64
    8000166a:	8aaa                	mv	s5,a0
    8000166c:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000166e:	6985                	lui	s3,0x1
    80001670:	19fd                	addi	s3,s3,-1
    80001672:	95ce                	add	a1,a1,s3
    80001674:	79fd                	lui	s3,0xfffff
    80001676:	0135f9b3          	and	s3,a1,s3
  for(; a < newsz; a += PGSIZE){
    8000167a:	08c9f063          	bgeu	s3,a2,800016fa <uvmalloc+0xa6>
  a = oldsz;
    8000167e:	894e                	mv	s2,s3
    mem = kalloc();
    80001680:	fffff097          	auipc	ra,0xfffff
    80001684:	330080e7          	jalr	816(ra) # 800009b0 <kalloc>
    80001688:	84aa                	mv	s1,a0
    if(mem == 0){
    8000168a:	c51d                	beqz	a0,800016b8 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000168c:	6605                	lui	a2,0x1
    8000168e:	4581                	li	a1,0
    80001690:	fffff097          	auipc	ra,0xfffff
    80001694:	7c2080e7          	jalr	1986(ra) # 80000e52 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001698:	4779                	li	a4,30
    8000169a:	86a6                	mv	a3,s1
    8000169c:	6605                	lui	a2,0x1
    8000169e:	85ca                	mv	a1,s2
    800016a0:	8556                	mv	a0,s5
    800016a2:	00000097          	auipc	ra,0x0
    800016a6:	c4a080e7          	jalr	-950(ra) # 800012ec <mappages>
    800016aa:	e905                	bnez	a0,800016da <uvmalloc+0x86>
  for(; a < newsz; a += PGSIZE){
    800016ac:	6785                	lui	a5,0x1
    800016ae:	993e                	add	s2,s2,a5
    800016b0:	fd4968e3          	bltu	s2,s4,80001680 <uvmalloc+0x2c>
  return newsz;
    800016b4:	8552                	mv	a0,s4
    800016b6:	a809                	j	800016c8 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800016b8:	864e                	mv	a2,s3
    800016ba:	85ca                	mv	a1,s2
    800016bc:	8556                	mv	a0,s5
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	f52080e7          	jalr	-174(ra) # 80001610 <uvmdealloc>
      return 0;
    800016c6:	4501                	li	a0,0
}
    800016c8:	70e2                	ld	ra,56(sp)
    800016ca:	7442                	ld	s0,48(sp)
    800016cc:	74a2                	ld	s1,40(sp)
    800016ce:	7902                	ld	s2,32(sp)
    800016d0:	69e2                	ld	s3,24(sp)
    800016d2:	6a42                	ld	s4,16(sp)
    800016d4:	6aa2                	ld	s5,8(sp)
    800016d6:	6121                	addi	sp,sp,64
    800016d8:	8082                	ret
      kfree(mem);
    800016da:	8526                	mv	a0,s1
    800016dc:	fffff097          	auipc	ra,0xfffff
    800016e0:	188080e7          	jalr	392(ra) # 80000864 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800016e4:	864e                	mv	a2,s3
    800016e6:	85ca                	mv	a1,s2
    800016e8:	8556                	mv	a0,s5
    800016ea:	00000097          	auipc	ra,0x0
    800016ee:	f26080e7          	jalr	-218(ra) # 80001610 <uvmdealloc>
      return 0;
    800016f2:	4501                	li	a0,0
    800016f4:	bfd1                	j	800016c8 <uvmalloc+0x74>
    return oldsz;
    800016f6:	852e                	mv	a0,a1
}
    800016f8:	8082                	ret
  return newsz;
    800016fa:	8532                	mv	a0,a2
    800016fc:	b7f1                	j	800016c8 <uvmalloc+0x74>

00000000800016fe <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800016fe:	1101                	addi	sp,sp,-32
    80001700:	ec06                	sd	ra,24(sp)
    80001702:	e822                	sd	s0,16(sp)
    80001704:	e426                	sd	s1,8(sp)
    80001706:	1000                	addi	s0,sp,32
    80001708:	84aa                	mv	s1,a0
    8000170a:	862e                	mv	a2,a1
  uvmunmap(pagetable, 0, sz, 1);
    8000170c:	4685                	li	a3,1
    8000170e:	4581                	li	a1,0
    80001710:	00000097          	auipc	ra,0x0
    80001714:	d88080e7          	jalr	-632(ra) # 80001498 <uvmunmap>
  freewalk(pagetable);
    80001718:	8526                	mv	a0,s1
    8000171a:	00000097          	auipc	ra,0x0
    8000171e:	aa4080e7          	jalr	-1372(ra) # 800011be <freewalk>
}
    80001722:	60e2                	ld	ra,24(sp)
    80001724:	6442                	ld	s0,16(sp)
    80001726:	64a2                	ld	s1,8(sp)
    80001728:	6105                	addi	sp,sp,32
    8000172a:	8082                	ret

000000008000172c <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000172c:	c671                	beqz	a2,800017f8 <uvmcopy+0xcc>
{
    8000172e:	715d                	addi	sp,sp,-80
    80001730:	e486                	sd	ra,72(sp)
    80001732:	e0a2                	sd	s0,64(sp)
    80001734:	fc26                	sd	s1,56(sp)
    80001736:	f84a                	sd	s2,48(sp)
    80001738:	f44e                	sd	s3,40(sp)
    8000173a:	f052                	sd	s4,32(sp)
    8000173c:	ec56                	sd	s5,24(sp)
    8000173e:	e85a                	sd	s6,16(sp)
    80001740:	e45e                	sd	s7,8(sp)
    80001742:	0880                	addi	s0,sp,80
    80001744:	8b2a                	mv	s6,a0
    80001746:	8aae                	mv	s5,a1
    80001748:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000174a:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000174c:	4601                	li	a2,0
    8000174e:	85ce                	mv	a1,s3
    80001750:	855a                	mv	a0,s6
    80001752:	00000097          	auipc	ra,0x0
    80001756:	9c6080e7          	jalr	-1594(ra) # 80001118 <walk>
    8000175a:	c531                	beqz	a0,800017a6 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000175c:	6118                	ld	a4,0(a0)
    8000175e:	00177793          	andi	a5,a4,1
    80001762:	cbb1                	beqz	a5,800017b6 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001764:	00a75593          	srli	a1,a4,0xa
    80001768:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000176c:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001770:	fffff097          	auipc	ra,0xfffff
    80001774:	240080e7          	jalr	576(ra) # 800009b0 <kalloc>
    80001778:	892a                	mv	s2,a0
    8000177a:	c939                	beqz	a0,800017d0 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000177c:	6605                	lui	a2,0x1
    8000177e:	85de                	mv	a1,s7
    80001780:	fffff097          	auipc	ra,0xfffff
    80001784:	72e080e7          	jalr	1838(ra) # 80000eae <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001788:	8726                	mv	a4,s1
    8000178a:	86ca                	mv	a3,s2
    8000178c:	6605                	lui	a2,0x1
    8000178e:	85ce                	mv	a1,s3
    80001790:	8556                	mv	a0,s5
    80001792:	00000097          	auipc	ra,0x0
    80001796:	b5a080e7          	jalr	-1190(ra) # 800012ec <mappages>
    8000179a:	e515                	bnez	a0,800017c6 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000179c:	6785                	lui	a5,0x1
    8000179e:	99be                	add	s3,s3,a5
    800017a0:	fb49e6e3          	bltu	s3,s4,8000174c <uvmcopy+0x20>
    800017a4:	a83d                	j	800017e2 <uvmcopy+0xb6>
      panic("uvmcopy: pte should exist");
    800017a6:	00007517          	auipc	a0,0x7
    800017aa:	c2a50513          	addi	a0,a0,-982 # 800083d0 <userret+0x340>
    800017ae:	fffff097          	auipc	ra,0xfffff
    800017b2:	d9a080e7          	jalr	-614(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    800017b6:	00007517          	auipc	a0,0x7
    800017ba:	c3a50513          	addi	a0,a0,-966 # 800083f0 <userret+0x360>
    800017be:	fffff097          	auipc	ra,0xfffff
    800017c2:	d8a080e7          	jalr	-630(ra) # 80000548 <panic>
      kfree(mem);
    800017c6:	854a                	mv	a0,s2
    800017c8:	fffff097          	auipc	ra,0xfffff
    800017cc:	09c080e7          	jalr	156(ra) # 80000864 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i, 1);
    800017d0:	4685                	li	a3,1
    800017d2:	864e                	mv	a2,s3
    800017d4:	4581                	li	a1,0
    800017d6:	8556                	mv	a0,s5
    800017d8:	00000097          	auipc	ra,0x0
    800017dc:	cc0080e7          	jalr	-832(ra) # 80001498 <uvmunmap>
  return -1;
    800017e0:	557d                	li	a0,-1
}
    800017e2:	60a6                	ld	ra,72(sp)
    800017e4:	6406                	ld	s0,64(sp)
    800017e6:	74e2                	ld	s1,56(sp)
    800017e8:	7942                	ld	s2,48(sp)
    800017ea:	79a2                	ld	s3,40(sp)
    800017ec:	7a02                	ld	s4,32(sp)
    800017ee:	6ae2                	ld	s5,24(sp)
    800017f0:	6b42                	ld	s6,16(sp)
    800017f2:	6ba2                	ld	s7,8(sp)
    800017f4:	6161                	addi	sp,sp,80
    800017f6:	8082                	ret
  return 0;
    800017f8:	4501                	li	a0,0
}
    800017fa:	8082                	ret

00000000800017fc <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800017fc:	1141                	addi	sp,sp,-16
    800017fe:	e406                	sd	ra,8(sp)
    80001800:	e022                	sd	s0,0(sp)
    80001802:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001804:	4601                	li	a2,0
    80001806:	00000097          	auipc	ra,0x0
    8000180a:	912080e7          	jalr	-1774(ra) # 80001118 <walk>
  if(pte == 0)
    8000180e:	c901                	beqz	a0,8000181e <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001810:	611c                	ld	a5,0(a0)
    80001812:	9bbd                	andi	a5,a5,-17
    80001814:	e11c                	sd	a5,0(a0)
}
    80001816:	60a2                	ld	ra,8(sp)
    80001818:	6402                	ld	s0,0(sp)
    8000181a:	0141                	addi	sp,sp,16
    8000181c:	8082                	ret
    panic("uvmclear");
    8000181e:	00007517          	auipc	a0,0x7
    80001822:	bf250513          	addi	a0,a0,-1038 # 80008410 <userret+0x380>
    80001826:	fffff097          	auipc	ra,0xfffff
    8000182a:	d22080e7          	jalr	-734(ra) # 80000548 <panic>

000000008000182e <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000182e:	c6bd                	beqz	a3,8000189c <copyout+0x6e>
{
    80001830:	715d                	addi	sp,sp,-80
    80001832:	e486                	sd	ra,72(sp)
    80001834:	e0a2                	sd	s0,64(sp)
    80001836:	fc26                	sd	s1,56(sp)
    80001838:	f84a                	sd	s2,48(sp)
    8000183a:	f44e                	sd	s3,40(sp)
    8000183c:	f052                	sd	s4,32(sp)
    8000183e:	ec56                	sd	s5,24(sp)
    80001840:	e85a                	sd	s6,16(sp)
    80001842:	e45e                	sd	s7,8(sp)
    80001844:	e062                	sd	s8,0(sp)
    80001846:	0880                	addi	s0,sp,80
    80001848:	8b2a                	mv	s6,a0
    8000184a:	8c2e                	mv	s8,a1
    8000184c:	8a32                	mv	s4,a2
    8000184e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001850:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001852:	6a85                	lui	s5,0x1
    80001854:	a015                	j	80001878 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001856:	9562                	add	a0,a0,s8
    80001858:	0004861b          	sext.w	a2,s1
    8000185c:	85d2                	mv	a1,s4
    8000185e:	41250533          	sub	a0,a0,s2
    80001862:	fffff097          	auipc	ra,0xfffff
    80001866:	64c080e7          	jalr	1612(ra) # 80000eae <memmove>

    len -= n;
    8000186a:	409989b3          	sub	s3,s3,s1
    src += n;
    8000186e:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001870:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001874:	02098263          	beqz	s3,80001898 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001878:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000187c:	85ca                	mv	a1,s2
    8000187e:	855a                	mv	a0,s6
    80001880:	00000097          	auipc	ra,0x0
    80001884:	9cc080e7          	jalr	-1588(ra) # 8000124c <walkaddr>
    if(pa0 == 0)
    80001888:	cd01                	beqz	a0,800018a0 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000188a:	418904b3          	sub	s1,s2,s8
    8000188e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001890:	fc99f3e3          	bgeu	s3,s1,80001856 <copyout+0x28>
    80001894:	84ce                	mv	s1,s3
    80001896:	b7c1                	j	80001856 <copyout+0x28>
  }
  return 0;
    80001898:	4501                	li	a0,0
    8000189a:	a021                	j	800018a2 <copyout+0x74>
    8000189c:	4501                	li	a0,0
}
    8000189e:	8082                	ret
      return -1;
    800018a0:	557d                	li	a0,-1
}
    800018a2:	60a6                	ld	ra,72(sp)
    800018a4:	6406                	ld	s0,64(sp)
    800018a6:	74e2                	ld	s1,56(sp)
    800018a8:	7942                	ld	s2,48(sp)
    800018aa:	79a2                	ld	s3,40(sp)
    800018ac:	7a02                	ld	s4,32(sp)
    800018ae:	6ae2                	ld	s5,24(sp)
    800018b0:	6b42                	ld	s6,16(sp)
    800018b2:	6ba2                	ld	s7,8(sp)
    800018b4:	6c02                	ld	s8,0(sp)
    800018b6:	6161                	addi	sp,sp,80
    800018b8:	8082                	ret

00000000800018ba <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800018ba:	caa5                	beqz	a3,8000192a <copyin+0x70>
{
    800018bc:	715d                	addi	sp,sp,-80
    800018be:	e486                	sd	ra,72(sp)
    800018c0:	e0a2                	sd	s0,64(sp)
    800018c2:	fc26                	sd	s1,56(sp)
    800018c4:	f84a                	sd	s2,48(sp)
    800018c6:	f44e                	sd	s3,40(sp)
    800018c8:	f052                	sd	s4,32(sp)
    800018ca:	ec56                	sd	s5,24(sp)
    800018cc:	e85a                	sd	s6,16(sp)
    800018ce:	e45e                	sd	s7,8(sp)
    800018d0:	e062                	sd	s8,0(sp)
    800018d2:	0880                	addi	s0,sp,80
    800018d4:	8b2a                	mv	s6,a0
    800018d6:	8a2e                	mv	s4,a1
    800018d8:	8c32                	mv	s8,a2
    800018da:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800018dc:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018de:	6a85                	lui	s5,0x1
    800018e0:	a01d                	j	80001906 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800018e2:	018505b3          	add	a1,a0,s8
    800018e6:	0004861b          	sext.w	a2,s1
    800018ea:	412585b3          	sub	a1,a1,s2
    800018ee:	8552                	mv	a0,s4
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	5be080e7          	jalr	1470(ra) # 80000eae <memmove>

    len -= n;
    800018f8:	409989b3          	sub	s3,s3,s1
    dst += n;
    800018fc:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800018fe:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001902:	02098263          	beqz	s3,80001926 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001906:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000190a:	85ca                	mv	a1,s2
    8000190c:	855a                	mv	a0,s6
    8000190e:	00000097          	auipc	ra,0x0
    80001912:	93e080e7          	jalr	-1730(ra) # 8000124c <walkaddr>
    if(pa0 == 0)
    80001916:	cd01                	beqz	a0,8000192e <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001918:	418904b3          	sub	s1,s2,s8
    8000191c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000191e:	fc99f2e3          	bgeu	s3,s1,800018e2 <copyin+0x28>
    80001922:	84ce                	mv	s1,s3
    80001924:	bf7d                	j	800018e2 <copyin+0x28>
  }
  return 0;
    80001926:	4501                	li	a0,0
    80001928:	a021                	j	80001930 <copyin+0x76>
    8000192a:	4501                	li	a0,0
}
    8000192c:	8082                	ret
      return -1;
    8000192e:	557d                	li	a0,-1
}
    80001930:	60a6                	ld	ra,72(sp)
    80001932:	6406                	ld	s0,64(sp)
    80001934:	74e2                	ld	s1,56(sp)
    80001936:	7942                	ld	s2,48(sp)
    80001938:	79a2                	ld	s3,40(sp)
    8000193a:	7a02                	ld	s4,32(sp)
    8000193c:	6ae2                	ld	s5,24(sp)
    8000193e:	6b42                	ld	s6,16(sp)
    80001940:	6ba2                	ld	s7,8(sp)
    80001942:	6c02                	ld	s8,0(sp)
    80001944:	6161                	addi	sp,sp,80
    80001946:	8082                	ret

0000000080001948 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001948:	c6c5                	beqz	a3,800019f0 <copyinstr+0xa8>
{
    8000194a:	715d                	addi	sp,sp,-80
    8000194c:	e486                	sd	ra,72(sp)
    8000194e:	e0a2                	sd	s0,64(sp)
    80001950:	fc26                	sd	s1,56(sp)
    80001952:	f84a                	sd	s2,48(sp)
    80001954:	f44e                	sd	s3,40(sp)
    80001956:	f052                	sd	s4,32(sp)
    80001958:	ec56                	sd	s5,24(sp)
    8000195a:	e85a                	sd	s6,16(sp)
    8000195c:	e45e                	sd	s7,8(sp)
    8000195e:	0880                	addi	s0,sp,80
    80001960:	8a2a                	mv	s4,a0
    80001962:	8b2e                	mv	s6,a1
    80001964:	8bb2                	mv	s7,a2
    80001966:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001968:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000196a:	6985                	lui	s3,0x1
    8000196c:	a035                	j	80001998 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000196e:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001972:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001974:	0017b793          	seqz	a5,a5
    80001978:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000197c:	60a6                	ld	ra,72(sp)
    8000197e:	6406                	ld	s0,64(sp)
    80001980:	74e2                	ld	s1,56(sp)
    80001982:	7942                	ld	s2,48(sp)
    80001984:	79a2                	ld	s3,40(sp)
    80001986:	7a02                	ld	s4,32(sp)
    80001988:	6ae2                	ld	s5,24(sp)
    8000198a:	6b42                	ld	s6,16(sp)
    8000198c:	6ba2                	ld	s7,8(sp)
    8000198e:	6161                	addi	sp,sp,80
    80001990:	8082                	ret
    srcva = va0 + PGSIZE;
    80001992:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001996:	c8a9                	beqz	s1,800019e8 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001998:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000199c:	85ca                	mv	a1,s2
    8000199e:	8552                	mv	a0,s4
    800019a0:	00000097          	auipc	ra,0x0
    800019a4:	8ac080e7          	jalr	-1876(ra) # 8000124c <walkaddr>
    if(pa0 == 0)
    800019a8:	c131                	beqz	a0,800019ec <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800019aa:	41790833          	sub	a6,s2,s7
    800019ae:	984e                	add	a6,a6,s3
    if(n > max)
    800019b0:	0104f363          	bgeu	s1,a6,800019b6 <copyinstr+0x6e>
    800019b4:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800019b6:	955e                	add	a0,a0,s7
    800019b8:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800019bc:	fc080be3          	beqz	a6,80001992 <copyinstr+0x4a>
    800019c0:	985a                	add	a6,a6,s6
    800019c2:	87da                	mv	a5,s6
      if(*p == '\0'){
    800019c4:	41650633          	sub	a2,a0,s6
    800019c8:	14fd                	addi	s1,s1,-1
    800019ca:	9b26                	add	s6,s6,s1
    800019cc:	00f60733          	add	a4,a2,a5
    800019d0:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd2fa4>
    800019d4:	df49                	beqz	a4,8000196e <copyinstr+0x26>
        *dst = *p;
    800019d6:	00e78023          	sb	a4,0(a5)
      --max;
    800019da:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800019de:	0785                	addi	a5,a5,1
    while(n > 0){
    800019e0:	ff0796e3          	bne	a5,a6,800019cc <copyinstr+0x84>
      dst++;
    800019e4:	8b42                	mv	s6,a6
    800019e6:	b775                	j	80001992 <copyinstr+0x4a>
    800019e8:	4781                	li	a5,0
    800019ea:	b769                	j	80001974 <copyinstr+0x2c>
      return -1;
    800019ec:	557d                	li	a0,-1
    800019ee:	b779                	j	8000197c <copyinstr+0x34>
  int got_null = 0;
    800019f0:	4781                	li	a5,0
  if(got_null){
    800019f2:	0017b793          	seqz	a5,a5
    800019f6:	40f00533          	neg	a0,a5
}
    800019fa:	8082                	ret

00000000800019fc <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    800019fc:	1101                	addi	sp,sp,-32
    800019fe:	ec06                	sd	ra,24(sp)
    80001a00:	e822                	sd	s0,16(sp)
    80001a02:	e426                	sd	s1,8(sp)
    80001a04:	1000                	addi	s0,sp,32
    80001a06:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001a08:	fffff097          	auipc	ra,0xfffff
    80001a0c:	19c080e7          	jalr	412(ra) # 80000ba4 <holding>
    80001a10:	c909                	beqz	a0,80001a22 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001a12:	789c                	ld	a5,48(s1)
    80001a14:	00978f63          	beq	a5,s1,80001a32 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001a18:	60e2                	ld	ra,24(sp)
    80001a1a:	6442                	ld	s0,16(sp)
    80001a1c:	64a2                	ld	s1,8(sp)
    80001a1e:	6105                	addi	sp,sp,32
    80001a20:	8082                	ret
    panic("wakeup1");
    80001a22:	00007517          	auipc	a0,0x7
    80001a26:	9fe50513          	addi	a0,a0,-1538 # 80008420 <userret+0x390>
    80001a2a:	fffff097          	auipc	ra,0xfffff
    80001a2e:	b1e080e7          	jalr	-1250(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001a32:	5098                	lw	a4,32(s1)
    80001a34:	4785                	li	a5,1
    80001a36:	fef711e3          	bne	a4,a5,80001a18 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001a3a:	4789                	li	a5,2
    80001a3c:	d09c                	sw	a5,32(s1)
}
    80001a3e:	bfe9                	j	80001a18 <wakeup1+0x1c>

0000000080001a40 <procinit>:
{
    80001a40:	715d                	addi	sp,sp,-80
    80001a42:	e486                	sd	ra,72(sp)
    80001a44:	e0a2                	sd	s0,64(sp)
    80001a46:	fc26                	sd	s1,56(sp)
    80001a48:	f84a                	sd	s2,48(sp)
    80001a4a:	f44e                	sd	s3,40(sp)
    80001a4c:	f052                	sd	s4,32(sp)
    80001a4e:	ec56                	sd	s5,24(sp)
    80001a50:	e85a                	sd	s6,16(sp)
    80001a52:	e45e                	sd	s7,8(sp)
    80001a54:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001a56:	00007597          	auipc	a1,0x7
    80001a5a:	9d258593          	addi	a1,a1,-1582 # 80008428 <userret+0x398>
    80001a5e:	00013517          	auipc	a0,0x13
    80001a62:	efa50513          	addi	a0,a0,-262 # 80014958 <pid_lock>
    80001a66:	fffff097          	auipc	ra,0xfffff
    80001a6a:	030080e7          	jalr	48(ra) # 80000a96 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a6e:	00013917          	auipc	s2,0x13
    80001a72:	30a90913          	addi	s2,s2,778 # 80014d78 <proc>
      initlock(&p->lock, "proc");
    80001a76:	00007b97          	auipc	s7,0x7
    80001a7a:	9bab8b93          	addi	s7,s7,-1606 # 80008430 <userret+0x3a0>
      uint64 va = KSTACK((int) (p - proc));
    80001a7e:	8b4a                	mv	s6,s2
    80001a80:	00007a97          	auipc	s5,0x7
    80001a84:	140a8a93          	addi	s5,s5,320 # 80008bc0 <syscalls+0xb8>
    80001a88:	040009b7          	lui	s3,0x4000
    80001a8c:	19fd                	addi	s3,s3,-1
    80001a8e:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a90:	00019a17          	auipc	s4,0x19
    80001a94:	ee8a0a13          	addi	s4,s4,-280 # 8001a978 <tickslock>
      initlock(&p->lock, "proc");
    80001a98:	85de                	mv	a1,s7
    80001a9a:	854a                	mv	a0,s2
    80001a9c:	fffff097          	auipc	ra,0xfffff
    80001aa0:	ffa080e7          	jalr	-6(ra) # 80000a96 <initlock>
      char *pa = kalloc();
    80001aa4:	fffff097          	auipc	ra,0xfffff
    80001aa8:	f0c080e7          	jalr	-244(ra) # 800009b0 <kalloc>
    80001aac:	85aa                	mv	a1,a0
      if(pa == 0)
    80001aae:	c929                	beqz	a0,80001b00 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001ab0:	416904b3          	sub	s1,s2,s6
    80001ab4:	8491                	srai	s1,s1,0x4
    80001ab6:	000ab783          	ld	a5,0(s5)
    80001aba:	02f484b3          	mul	s1,s1,a5
    80001abe:	2485                	addiw	s1,s1,1
    80001ac0:	00d4949b          	slliw	s1,s1,0xd
    80001ac4:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001ac8:	4699                	li	a3,6
    80001aca:	6605                	lui	a2,0x1
    80001acc:	8526                	mv	a0,s1
    80001ace:	00000097          	auipc	ra,0x0
    80001ad2:	8ac080e7          	jalr	-1876(ra) # 8000137a <kvmmap>
      p->kstack = va;
    80001ad6:	04993423          	sd	s1,72(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ada:	17090913          	addi	s2,s2,368
    80001ade:	fb491de3          	bne	s2,s4,80001a98 <procinit+0x58>
  kvminithart();
    80001ae2:	fffff097          	auipc	ra,0xfffff
    80001ae6:	746080e7          	jalr	1862(ra) # 80001228 <kvminithart>
}
    80001aea:	60a6                	ld	ra,72(sp)
    80001aec:	6406                	ld	s0,64(sp)
    80001aee:	74e2                	ld	s1,56(sp)
    80001af0:	7942                	ld	s2,48(sp)
    80001af2:	79a2                	ld	s3,40(sp)
    80001af4:	7a02                	ld	s4,32(sp)
    80001af6:	6ae2                	ld	s5,24(sp)
    80001af8:	6b42                	ld	s6,16(sp)
    80001afa:	6ba2                	ld	s7,8(sp)
    80001afc:	6161                	addi	sp,sp,80
    80001afe:	8082                	ret
        panic("kalloc");
    80001b00:	00007517          	auipc	a0,0x7
    80001b04:	93850513          	addi	a0,a0,-1736 # 80008438 <userret+0x3a8>
    80001b08:	fffff097          	auipc	ra,0xfffff
    80001b0c:	a40080e7          	jalr	-1472(ra) # 80000548 <panic>

0000000080001b10 <cpuid>:
{
    80001b10:	1141                	addi	sp,sp,-16
    80001b12:	e422                	sd	s0,8(sp)
    80001b14:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b16:	8512                	mv	a0,tp
}
    80001b18:	2501                	sext.w	a0,a0
    80001b1a:	6422                	ld	s0,8(sp)
    80001b1c:	0141                	addi	sp,sp,16
    80001b1e:	8082                	ret

0000000080001b20 <mycpu>:
mycpu(void) {
    80001b20:	1141                	addi	sp,sp,-16
    80001b22:	e422                	sd	s0,8(sp)
    80001b24:	0800                	addi	s0,sp,16
    80001b26:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001b28:	2781                	sext.w	a5,a5
    80001b2a:	079e                	slli	a5,a5,0x7
}
    80001b2c:	00013517          	auipc	a0,0x13
    80001b30:	e4c50513          	addi	a0,a0,-436 # 80014978 <cpus>
    80001b34:	953e                	add	a0,a0,a5
    80001b36:	6422                	ld	s0,8(sp)
    80001b38:	0141                	addi	sp,sp,16
    80001b3a:	8082                	ret

0000000080001b3c <myproc>:
myproc(void) {
    80001b3c:	1101                	addi	sp,sp,-32
    80001b3e:	ec06                	sd	ra,24(sp)
    80001b40:	e822                	sd	s0,16(sp)
    80001b42:	e426                	sd	s1,8(sp)
    80001b44:	1000                	addi	s0,sp,32
  push_off();
    80001b46:	fffff097          	auipc	ra,0xfffff
    80001b4a:	fa6080e7          	jalr	-90(ra) # 80000aec <push_off>
    80001b4e:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001b50:	2781                	sext.w	a5,a5
    80001b52:	079e                	slli	a5,a5,0x7
    80001b54:	00013717          	auipc	a4,0x13
    80001b58:	e0470713          	addi	a4,a4,-508 # 80014958 <pid_lock>
    80001b5c:	97ba                	add	a5,a5,a4
    80001b5e:	7384                	ld	s1,32(a5)
  pop_off();
    80001b60:	fffff097          	auipc	ra,0xfffff
    80001b64:	fd8080e7          	jalr	-40(ra) # 80000b38 <pop_off>
}
    80001b68:	8526                	mv	a0,s1
    80001b6a:	60e2                	ld	ra,24(sp)
    80001b6c:	6442                	ld	s0,16(sp)
    80001b6e:	64a2                	ld	s1,8(sp)
    80001b70:	6105                	addi	sp,sp,32
    80001b72:	8082                	ret

0000000080001b74 <forkret>:
{
    80001b74:	1141                	addi	sp,sp,-16
    80001b76:	e406                	sd	ra,8(sp)
    80001b78:	e022                	sd	s0,0(sp)
    80001b7a:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001b7c:	00000097          	auipc	ra,0x0
    80001b80:	fc0080e7          	jalr	-64(ra) # 80001b3c <myproc>
    80001b84:	fffff097          	auipc	ra,0xfffff
    80001b88:	0d0080e7          	jalr	208(ra) # 80000c54 <release>
  if (first) {
    80001b8c:	00007797          	auipc	a5,0x7
    80001b90:	4a87a783          	lw	a5,1192(a5) # 80009034 <first.1>
    80001b94:	eb89                	bnez	a5,80001ba6 <forkret+0x32>
  usertrapret();
    80001b96:	00001097          	auipc	ra,0x1
    80001b9a:	bdc080e7          	jalr	-1060(ra) # 80002772 <usertrapret>
}
    80001b9e:	60a2                	ld	ra,8(sp)
    80001ba0:	6402                	ld	s0,0(sp)
    80001ba2:	0141                	addi	sp,sp,16
    80001ba4:	8082                	ret
    first = 0;
    80001ba6:	00007797          	auipc	a5,0x7
    80001baa:	4807a723          	sw	zero,1166(a5) # 80009034 <first.1>
    fsinit(minor(ROOTDEV));
    80001bae:	4501                	li	a0,0
    80001bb0:	00002097          	auipc	ra,0x2
    80001bb4:	904080e7          	jalr	-1788(ra) # 800034b4 <fsinit>
    80001bb8:	bff9                	j	80001b96 <forkret+0x22>

0000000080001bba <allocpid>:
allocpid() {
    80001bba:	1101                	addi	sp,sp,-32
    80001bbc:	ec06                	sd	ra,24(sp)
    80001bbe:	e822                	sd	s0,16(sp)
    80001bc0:	e426                	sd	s1,8(sp)
    80001bc2:	e04a                	sd	s2,0(sp)
    80001bc4:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001bc6:	00013917          	auipc	s2,0x13
    80001bca:	d9290913          	addi	s2,s2,-622 # 80014958 <pid_lock>
    80001bce:	854a                	mv	a0,s2
    80001bd0:	fffff097          	auipc	ra,0xfffff
    80001bd4:	014080e7          	jalr	20(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001bd8:	00007797          	auipc	a5,0x7
    80001bdc:	46078793          	addi	a5,a5,1120 # 80009038 <nextpid>
    80001be0:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001be2:	0014871b          	addiw	a4,s1,1
    80001be6:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001be8:	854a                	mv	a0,s2
    80001bea:	fffff097          	auipc	ra,0xfffff
    80001bee:	06a080e7          	jalr	106(ra) # 80000c54 <release>
}
    80001bf2:	8526                	mv	a0,s1
    80001bf4:	60e2                	ld	ra,24(sp)
    80001bf6:	6442                	ld	s0,16(sp)
    80001bf8:	64a2                	ld	s1,8(sp)
    80001bfa:	6902                	ld	s2,0(sp)
    80001bfc:	6105                	addi	sp,sp,32
    80001bfe:	8082                	ret

0000000080001c00 <proc_pagetable>:
{
    80001c00:	1101                	addi	sp,sp,-32
    80001c02:	ec06                	sd	ra,24(sp)
    80001c04:	e822                	sd	s0,16(sp)
    80001c06:	e426                	sd	s1,8(sp)
    80001c08:	e04a                	sd	s2,0(sp)
    80001c0a:	1000                	addi	s0,sp,32
    80001c0c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c0e:	00000097          	auipc	ra,0x0
    80001c12:	952080e7          	jalr	-1710(ra) # 80001560 <uvmcreate>
    80001c16:	84aa                	mv	s1,a0
  mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c18:	4729                	li	a4,10
    80001c1a:	00006697          	auipc	a3,0x6
    80001c1e:	3e668693          	addi	a3,a3,998 # 80008000 <trampoline>
    80001c22:	6605                	lui	a2,0x1
    80001c24:	040005b7          	lui	a1,0x4000
    80001c28:	15fd                	addi	a1,a1,-1
    80001c2a:	05b2                	slli	a1,a1,0xc
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	6c0080e7          	jalr	1728(ra) # 800012ec <mappages>
  mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c34:	4719                	li	a4,6
    80001c36:	06093683          	ld	a3,96(s2)
    80001c3a:	6605                	lui	a2,0x1
    80001c3c:	020005b7          	lui	a1,0x2000
    80001c40:	15fd                	addi	a1,a1,-1
    80001c42:	05b6                	slli	a1,a1,0xd
    80001c44:	8526                	mv	a0,s1
    80001c46:	fffff097          	auipc	ra,0xfffff
    80001c4a:	6a6080e7          	jalr	1702(ra) # 800012ec <mappages>
}
    80001c4e:	8526                	mv	a0,s1
    80001c50:	60e2                	ld	ra,24(sp)
    80001c52:	6442                	ld	s0,16(sp)
    80001c54:	64a2                	ld	s1,8(sp)
    80001c56:	6902                	ld	s2,0(sp)
    80001c58:	6105                	addi	sp,sp,32
    80001c5a:	8082                	ret

0000000080001c5c <allocproc>:
{
    80001c5c:	1101                	addi	sp,sp,-32
    80001c5e:	ec06                	sd	ra,24(sp)
    80001c60:	e822                	sd	s0,16(sp)
    80001c62:	e426                	sd	s1,8(sp)
    80001c64:	e04a                	sd	s2,0(sp)
    80001c66:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c68:	00013497          	auipc	s1,0x13
    80001c6c:	11048493          	addi	s1,s1,272 # 80014d78 <proc>
    80001c70:	00019917          	auipc	s2,0x19
    80001c74:	d0890913          	addi	s2,s2,-760 # 8001a978 <tickslock>
    acquire(&p->lock);
    80001c78:	8526                	mv	a0,s1
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	f6a080e7          	jalr	-150(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001c82:	509c                	lw	a5,32(s1)
    80001c84:	cf81                	beqz	a5,80001c9c <allocproc+0x40>
      release(&p->lock);
    80001c86:	8526                	mv	a0,s1
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	fcc080e7          	jalr	-52(ra) # 80000c54 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c90:	17048493          	addi	s1,s1,368
    80001c94:	ff2492e3          	bne	s1,s2,80001c78 <allocproc+0x1c>
  return 0;
    80001c98:	4481                	li	s1,0
    80001c9a:	a0a9                	j	80001ce4 <allocproc+0x88>
  p->pid = allocpid();
    80001c9c:	00000097          	auipc	ra,0x0
    80001ca0:	f1e080e7          	jalr	-226(ra) # 80001bba <allocpid>
    80001ca4:	c0a8                	sw	a0,64(s1)
  if((p->tf = (struct trapframe *)kalloc()) == 0){
    80001ca6:	fffff097          	auipc	ra,0xfffff
    80001caa:	d0a080e7          	jalr	-758(ra) # 800009b0 <kalloc>
    80001cae:	892a                	mv	s2,a0
    80001cb0:	f0a8                	sd	a0,96(s1)
    80001cb2:	c121                	beqz	a0,80001cf2 <allocproc+0x96>
  p->pagetable = proc_pagetable(p);
    80001cb4:	8526                	mv	a0,s1
    80001cb6:	00000097          	auipc	ra,0x0
    80001cba:	f4a080e7          	jalr	-182(ra) # 80001c00 <proc_pagetable>
    80001cbe:	eca8                	sd	a0,88(s1)
  memset(&p->context, 0, sizeof p->context);
    80001cc0:	07000613          	li	a2,112
    80001cc4:	4581                	li	a1,0
    80001cc6:	06848513          	addi	a0,s1,104
    80001cca:	fffff097          	auipc	ra,0xfffff
    80001cce:	188080e7          	jalr	392(ra) # 80000e52 <memset>
  p->context.ra = (uint64)forkret;
    80001cd2:	00000797          	auipc	a5,0x0
    80001cd6:	ea278793          	addi	a5,a5,-350 # 80001b74 <forkret>
    80001cda:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cdc:	64bc                	ld	a5,72(s1)
    80001cde:	6705                	lui	a4,0x1
    80001ce0:	97ba                	add	a5,a5,a4
    80001ce2:	f8bc                	sd	a5,112(s1)
}
    80001ce4:	8526                	mv	a0,s1
    80001ce6:	60e2                	ld	ra,24(sp)
    80001ce8:	6442                	ld	s0,16(sp)
    80001cea:	64a2                	ld	s1,8(sp)
    80001cec:	6902                	ld	s2,0(sp)
    80001cee:	6105                	addi	sp,sp,32
    80001cf0:	8082                	ret
    release(&p->lock);
    80001cf2:	8526                	mv	a0,s1
    80001cf4:	fffff097          	auipc	ra,0xfffff
    80001cf8:	f60080e7          	jalr	-160(ra) # 80000c54 <release>
    return 0;
    80001cfc:	84ca                	mv	s1,s2
    80001cfe:	b7dd                	j	80001ce4 <allocproc+0x88>

0000000080001d00 <proc_freepagetable>:
{
    80001d00:	1101                	addi	sp,sp,-32
    80001d02:	ec06                	sd	ra,24(sp)
    80001d04:	e822                	sd	s0,16(sp)
    80001d06:	e426                	sd	s1,8(sp)
    80001d08:	e04a                	sd	s2,0(sp)
    80001d0a:	1000                	addi	s0,sp,32
    80001d0c:	84aa                	mv	s1,a0
    80001d0e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, PGSIZE, 0);
    80001d10:	4681                	li	a3,0
    80001d12:	6605                	lui	a2,0x1
    80001d14:	040005b7          	lui	a1,0x4000
    80001d18:	15fd                	addi	a1,a1,-1
    80001d1a:	05b2                	slli	a1,a1,0xc
    80001d1c:	fffff097          	auipc	ra,0xfffff
    80001d20:	77c080e7          	jalr	1916(ra) # 80001498 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, PGSIZE, 0);
    80001d24:	4681                	li	a3,0
    80001d26:	6605                	lui	a2,0x1
    80001d28:	020005b7          	lui	a1,0x2000
    80001d2c:	15fd                	addi	a1,a1,-1
    80001d2e:	05b6                	slli	a1,a1,0xd
    80001d30:	8526                	mv	a0,s1
    80001d32:	fffff097          	auipc	ra,0xfffff
    80001d36:	766080e7          	jalr	1894(ra) # 80001498 <uvmunmap>
  if(sz > 0)
    80001d3a:	00091863          	bnez	s2,80001d4a <proc_freepagetable+0x4a>
}
    80001d3e:	60e2                	ld	ra,24(sp)
    80001d40:	6442                	ld	s0,16(sp)
    80001d42:	64a2                	ld	s1,8(sp)
    80001d44:	6902                	ld	s2,0(sp)
    80001d46:	6105                	addi	sp,sp,32
    80001d48:	8082                	ret
    uvmfree(pagetable, sz);
    80001d4a:	85ca                	mv	a1,s2
    80001d4c:	8526                	mv	a0,s1
    80001d4e:	00000097          	auipc	ra,0x0
    80001d52:	9b0080e7          	jalr	-1616(ra) # 800016fe <uvmfree>
}
    80001d56:	b7e5                	j	80001d3e <proc_freepagetable+0x3e>

0000000080001d58 <freeproc>:
{
    80001d58:	1101                	addi	sp,sp,-32
    80001d5a:	ec06                	sd	ra,24(sp)
    80001d5c:	e822                	sd	s0,16(sp)
    80001d5e:	e426                	sd	s1,8(sp)
    80001d60:	1000                	addi	s0,sp,32
    80001d62:	84aa                	mv	s1,a0
  if(p->tf)
    80001d64:	7128                	ld	a0,96(a0)
    80001d66:	c509                	beqz	a0,80001d70 <freeproc+0x18>
    kfree((void*)p->tf);
    80001d68:	fffff097          	auipc	ra,0xfffff
    80001d6c:	afc080e7          	jalr	-1284(ra) # 80000864 <kfree>
  p->tf = 0;
    80001d70:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001d74:	6ca8                	ld	a0,88(s1)
    80001d76:	c511                	beqz	a0,80001d82 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d78:	68ac                	ld	a1,80(s1)
    80001d7a:	00000097          	auipc	ra,0x0
    80001d7e:	f86080e7          	jalr	-122(ra) # 80001d00 <proc_freepagetable>
  p->pagetable = 0;
    80001d82:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001d86:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    80001d8a:	0404a023          	sw	zero,64(s1)
  p->parent = 0;
    80001d8e:	0204b423          	sd	zero,40(s1)
  p->name[0] = 0;
    80001d92:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001d96:	0204b823          	sd	zero,48(s1)
  p->killed = 0;
    80001d9a:	0204ac23          	sw	zero,56(s1)
  p->xstate = 0;
    80001d9e:	0204ae23          	sw	zero,60(s1)
  p->state = UNUSED;
    80001da2:	0204a023          	sw	zero,32(s1)
}
    80001da6:	60e2                	ld	ra,24(sp)
    80001da8:	6442                	ld	s0,16(sp)
    80001daa:	64a2                	ld	s1,8(sp)
    80001dac:	6105                	addi	sp,sp,32
    80001dae:	8082                	ret

0000000080001db0 <userinit>:
{
    80001db0:	1101                	addi	sp,sp,-32
    80001db2:	ec06                	sd	ra,24(sp)
    80001db4:	e822                	sd	s0,16(sp)
    80001db6:	e426                	sd	s1,8(sp)
    80001db8:	1000                	addi	s0,sp,32
  p = allocproc();
    80001dba:	00000097          	auipc	ra,0x0
    80001dbe:	ea2080e7          	jalr	-350(ra) # 80001c5c <allocproc>
    80001dc2:	84aa                	mv	s1,a0
  initproc = p;
    80001dc4:	0002a797          	auipc	a5,0x2a
    80001dc8:	26a7ba23          	sd	a0,628(a5) # 8002c038 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001dcc:	03300613          	li	a2,51
    80001dd0:	00007597          	auipc	a1,0x7
    80001dd4:	23058593          	addi	a1,a1,560 # 80009000 <initcode>
    80001dd8:	6d28                	ld	a0,88(a0)
    80001dda:	fffff097          	auipc	ra,0xfffff
    80001dde:	7c4080e7          	jalr	1988(ra) # 8000159e <uvminit>
  p->sz = PGSIZE;
    80001de2:	6785                	lui	a5,0x1
    80001de4:	e8bc                	sd	a5,80(s1)
  p->tf->epc = 0;      // user program counter
    80001de6:	70b8                	ld	a4,96(s1)
    80001de8:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->tf->sp = PGSIZE;  // user stack pointer
    80001dec:	70b8                	ld	a4,96(s1)
    80001dee:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001df0:	4641                	li	a2,16
    80001df2:	00006597          	auipc	a1,0x6
    80001df6:	64e58593          	addi	a1,a1,1614 # 80008440 <userret+0x3b0>
    80001dfa:	16048513          	addi	a0,s1,352
    80001dfe:	fffff097          	auipc	ra,0xfffff
    80001e02:	1a6080e7          	jalr	422(ra) # 80000fa4 <safestrcpy>
  p->cwd = namei("/");
    80001e06:	00006517          	auipc	a0,0x6
    80001e0a:	64a50513          	addi	a0,a0,1610 # 80008450 <userret+0x3c0>
    80001e0e:	00002097          	auipc	ra,0x2
    80001e12:	0a8080e7          	jalr	168(ra) # 80003eb6 <namei>
    80001e16:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80001e1a:	4789                	li	a5,2
    80001e1c:	d09c                	sw	a5,32(s1)
  release(&p->lock);
    80001e1e:	8526                	mv	a0,s1
    80001e20:	fffff097          	auipc	ra,0xfffff
    80001e24:	e34080e7          	jalr	-460(ra) # 80000c54 <release>
}
    80001e28:	60e2                	ld	ra,24(sp)
    80001e2a:	6442                	ld	s0,16(sp)
    80001e2c:	64a2                	ld	s1,8(sp)
    80001e2e:	6105                	addi	sp,sp,32
    80001e30:	8082                	ret

0000000080001e32 <growproc>:
{
    80001e32:	1101                	addi	sp,sp,-32
    80001e34:	ec06                	sd	ra,24(sp)
    80001e36:	e822                	sd	s0,16(sp)
    80001e38:	e426                	sd	s1,8(sp)
    80001e3a:	e04a                	sd	s2,0(sp)
    80001e3c:	1000                	addi	s0,sp,32
    80001e3e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001e40:	00000097          	auipc	ra,0x0
    80001e44:	cfc080e7          	jalr	-772(ra) # 80001b3c <myproc>
    80001e48:	892a                	mv	s2,a0
  sz = p->sz;
    80001e4a:	692c                	ld	a1,80(a0)
    80001e4c:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001e50:	00904f63          	bgtz	s1,80001e6e <growproc+0x3c>
  } else if(n < 0){
    80001e54:	0204cc63          	bltz	s1,80001e8c <growproc+0x5a>
  p->sz = sz;
    80001e58:	1602                	slli	a2,a2,0x20
    80001e5a:	9201                	srli	a2,a2,0x20
    80001e5c:	04c93823          	sd	a2,80(s2)
  return 0;
    80001e60:	4501                	li	a0,0
}
    80001e62:	60e2                	ld	ra,24(sp)
    80001e64:	6442                	ld	s0,16(sp)
    80001e66:	64a2                	ld	s1,8(sp)
    80001e68:	6902                	ld	s2,0(sp)
    80001e6a:	6105                	addi	sp,sp,32
    80001e6c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001e6e:	9e25                	addw	a2,a2,s1
    80001e70:	1602                	slli	a2,a2,0x20
    80001e72:	9201                	srli	a2,a2,0x20
    80001e74:	1582                	slli	a1,a1,0x20
    80001e76:	9181                	srli	a1,a1,0x20
    80001e78:	6d28                	ld	a0,88(a0)
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	7da080e7          	jalr	2010(ra) # 80001654 <uvmalloc>
    80001e82:	0005061b          	sext.w	a2,a0
    80001e86:	fa69                	bnez	a2,80001e58 <growproc+0x26>
      return -1;
    80001e88:	557d                	li	a0,-1
    80001e8a:	bfe1                	j	80001e62 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e8c:	9e25                	addw	a2,a2,s1
    80001e8e:	1602                	slli	a2,a2,0x20
    80001e90:	9201                	srli	a2,a2,0x20
    80001e92:	1582                	slli	a1,a1,0x20
    80001e94:	9181                	srli	a1,a1,0x20
    80001e96:	6d28                	ld	a0,88(a0)
    80001e98:	fffff097          	auipc	ra,0xfffff
    80001e9c:	778080e7          	jalr	1912(ra) # 80001610 <uvmdealloc>
    80001ea0:	0005061b          	sext.w	a2,a0
    80001ea4:	bf55                	j	80001e58 <growproc+0x26>

0000000080001ea6 <fork>:
{
    80001ea6:	7139                	addi	sp,sp,-64
    80001ea8:	fc06                	sd	ra,56(sp)
    80001eaa:	f822                	sd	s0,48(sp)
    80001eac:	f426                	sd	s1,40(sp)
    80001eae:	f04a                	sd	s2,32(sp)
    80001eb0:	ec4e                	sd	s3,24(sp)
    80001eb2:	e852                	sd	s4,16(sp)
    80001eb4:	e456                	sd	s5,8(sp)
    80001eb6:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001eb8:	00000097          	auipc	ra,0x0
    80001ebc:	c84080e7          	jalr	-892(ra) # 80001b3c <myproc>
    80001ec0:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001ec2:	00000097          	auipc	ra,0x0
    80001ec6:	d9a080e7          	jalr	-614(ra) # 80001c5c <allocproc>
    80001eca:	c17d                	beqz	a0,80001fb0 <fork+0x10a>
    80001ecc:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001ece:	050ab603          	ld	a2,80(s5)
    80001ed2:	6d2c                	ld	a1,88(a0)
    80001ed4:	058ab503          	ld	a0,88(s5)
    80001ed8:	00000097          	auipc	ra,0x0
    80001edc:	854080e7          	jalr	-1964(ra) # 8000172c <uvmcopy>
    80001ee0:	04054a63          	bltz	a0,80001f34 <fork+0x8e>
  np->sz = p->sz;
    80001ee4:	050ab783          	ld	a5,80(s5)
    80001ee8:	04fa3823          	sd	a5,80(s4)
  np->parent = p;
    80001eec:	035a3423          	sd	s5,40(s4)
  *(np->tf) = *(p->tf);
    80001ef0:	060ab683          	ld	a3,96(s5)
    80001ef4:	87b6                	mv	a5,a3
    80001ef6:	060a3703          	ld	a4,96(s4)
    80001efa:	12068693          	addi	a3,a3,288
    80001efe:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f02:	6788                	ld	a0,8(a5)
    80001f04:	6b8c                	ld	a1,16(a5)
    80001f06:	6f90                	ld	a2,24(a5)
    80001f08:	01073023          	sd	a6,0(a4)
    80001f0c:	e708                	sd	a0,8(a4)
    80001f0e:	eb0c                	sd	a1,16(a4)
    80001f10:	ef10                	sd	a2,24(a4)
    80001f12:	02078793          	addi	a5,a5,32
    80001f16:	02070713          	addi	a4,a4,32
    80001f1a:	fed792e3          	bne	a5,a3,80001efe <fork+0x58>
  np->tf->a0 = 0;
    80001f1e:	060a3783          	ld	a5,96(s4)
    80001f22:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001f26:	0d8a8493          	addi	s1,s5,216
    80001f2a:	0d8a0913          	addi	s2,s4,216
    80001f2e:	158a8993          	addi	s3,s5,344
    80001f32:	a00d                	j	80001f54 <fork+0xae>
    freeproc(np);
    80001f34:	8552                	mv	a0,s4
    80001f36:	00000097          	auipc	ra,0x0
    80001f3a:	e22080e7          	jalr	-478(ra) # 80001d58 <freeproc>
    release(&np->lock);
    80001f3e:	8552                	mv	a0,s4
    80001f40:	fffff097          	auipc	ra,0xfffff
    80001f44:	d14080e7          	jalr	-748(ra) # 80000c54 <release>
    return -1;
    80001f48:	54fd                	li	s1,-1
    80001f4a:	a889                	j	80001f9c <fork+0xf6>
  for(i = 0; i < NOFILE; i++)
    80001f4c:	04a1                	addi	s1,s1,8
    80001f4e:	0921                	addi	s2,s2,8
    80001f50:	01348b63          	beq	s1,s3,80001f66 <fork+0xc0>
    if(p->ofile[i])
    80001f54:	6088                	ld	a0,0(s1)
    80001f56:	d97d                	beqz	a0,80001f4c <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f58:	00002097          	auipc	ra,0x2
    80001f5c:	702080e7          	jalr	1794(ra) # 8000465a <filedup>
    80001f60:	00a93023          	sd	a0,0(s2)
    80001f64:	b7e5                	j	80001f4c <fork+0xa6>
  np->cwd = idup(p->cwd);
    80001f66:	158ab503          	ld	a0,344(s5)
    80001f6a:	00001097          	auipc	ra,0x1
    80001f6e:	784080e7          	jalr	1924(ra) # 800036ee <idup>
    80001f72:	14aa3c23          	sd	a0,344(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f76:	4641                	li	a2,16
    80001f78:	160a8593          	addi	a1,s5,352
    80001f7c:	160a0513          	addi	a0,s4,352
    80001f80:	fffff097          	auipc	ra,0xfffff
    80001f84:	024080e7          	jalr	36(ra) # 80000fa4 <safestrcpy>
  pid = np->pid;
    80001f88:	040a2483          	lw	s1,64(s4)
  np->state = RUNNABLE;
    80001f8c:	4789                	li	a5,2
    80001f8e:	02fa2023          	sw	a5,32(s4)
  release(&np->lock);
    80001f92:	8552                	mv	a0,s4
    80001f94:	fffff097          	auipc	ra,0xfffff
    80001f98:	cc0080e7          	jalr	-832(ra) # 80000c54 <release>
}
    80001f9c:	8526                	mv	a0,s1
    80001f9e:	70e2                	ld	ra,56(sp)
    80001fa0:	7442                	ld	s0,48(sp)
    80001fa2:	74a2                	ld	s1,40(sp)
    80001fa4:	7902                	ld	s2,32(sp)
    80001fa6:	69e2                	ld	s3,24(sp)
    80001fa8:	6a42                	ld	s4,16(sp)
    80001faa:	6aa2                	ld	s5,8(sp)
    80001fac:	6121                	addi	sp,sp,64
    80001fae:	8082                	ret
    return -1;
    80001fb0:	54fd                	li	s1,-1
    80001fb2:	b7ed                	j	80001f9c <fork+0xf6>

0000000080001fb4 <reparent>:
{
    80001fb4:	7179                	addi	sp,sp,-48
    80001fb6:	f406                	sd	ra,40(sp)
    80001fb8:	f022                	sd	s0,32(sp)
    80001fba:	ec26                	sd	s1,24(sp)
    80001fbc:	e84a                	sd	s2,16(sp)
    80001fbe:	e44e                	sd	s3,8(sp)
    80001fc0:	e052                	sd	s4,0(sp)
    80001fc2:	1800                	addi	s0,sp,48
    80001fc4:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001fc6:	00013497          	auipc	s1,0x13
    80001fca:	db248493          	addi	s1,s1,-590 # 80014d78 <proc>
      pp->parent = initproc;
    80001fce:	0002aa17          	auipc	s4,0x2a
    80001fd2:	06aa0a13          	addi	s4,s4,106 # 8002c038 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001fd6:	00019997          	auipc	s3,0x19
    80001fda:	9a298993          	addi	s3,s3,-1630 # 8001a978 <tickslock>
    80001fde:	a029                	j	80001fe8 <reparent+0x34>
    80001fe0:	17048493          	addi	s1,s1,368
    80001fe4:	03348363          	beq	s1,s3,8000200a <reparent+0x56>
    if(pp->parent == p){
    80001fe8:	749c                	ld	a5,40(s1)
    80001fea:	ff279be3          	bne	a5,s2,80001fe0 <reparent+0x2c>
      acquire(&pp->lock);
    80001fee:	8526                	mv	a0,s1
    80001ff0:	fffff097          	auipc	ra,0xfffff
    80001ff4:	bf4080e7          	jalr	-1036(ra) # 80000be4 <acquire>
      pp->parent = initproc;
    80001ff8:	000a3783          	ld	a5,0(s4)
    80001ffc:	f49c                	sd	a5,40(s1)
      release(&pp->lock);
    80001ffe:	8526                	mv	a0,s1
    80002000:	fffff097          	auipc	ra,0xfffff
    80002004:	c54080e7          	jalr	-940(ra) # 80000c54 <release>
    80002008:	bfe1                	j	80001fe0 <reparent+0x2c>
}
    8000200a:	70a2                	ld	ra,40(sp)
    8000200c:	7402                	ld	s0,32(sp)
    8000200e:	64e2                	ld	s1,24(sp)
    80002010:	6942                	ld	s2,16(sp)
    80002012:	69a2                	ld	s3,8(sp)
    80002014:	6a02                	ld	s4,0(sp)
    80002016:	6145                	addi	sp,sp,48
    80002018:	8082                	ret

000000008000201a <scheduler>:
{
    8000201a:	715d                	addi	sp,sp,-80
    8000201c:	e486                	sd	ra,72(sp)
    8000201e:	e0a2                	sd	s0,64(sp)
    80002020:	fc26                	sd	s1,56(sp)
    80002022:	f84a                	sd	s2,48(sp)
    80002024:	f44e                	sd	s3,40(sp)
    80002026:	f052                	sd	s4,32(sp)
    80002028:	ec56                	sd	s5,24(sp)
    8000202a:	e85a                	sd	s6,16(sp)
    8000202c:	e45e                	sd	s7,8(sp)
    8000202e:	e062                	sd	s8,0(sp)
    80002030:	0880                	addi	s0,sp,80
    80002032:	8792                	mv	a5,tp
  int id = r_tp();
    80002034:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002036:	00779b13          	slli	s6,a5,0x7
    8000203a:	00013717          	auipc	a4,0x13
    8000203e:	91e70713          	addi	a4,a4,-1762 # 80014958 <pid_lock>
    80002042:	975a                	add	a4,a4,s6
    80002044:	02073023          	sd	zero,32(a4)
        swtch(&c->scheduler, &p->context);
    80002048:	00013717          	auipc	a4,0x13
    8000204c:	93870713          	addi	a4,a4,-1736 # 80014980 <cpus+0x8>
    80002050:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80002052:	4c0d                	li	s8,3
        c->proc = p;
    80002054:	079e                	slli	a5,a5,0x7
    80002056:	00013a17          	auipc	s4,0x13
    8000205a:	902a0a13          	addi	s4,s4,-1790 # 80014958 <pid_lock>
    8000205e:	9a3e                	add	s4,s4,a5
        found = 1;
    80002060:	4b85                	li	s7,1
    for(p = proc; p < &proc[NPROC]; p++) {
    80002062:	00019997          	auipc	s3,0x19
    80002066:	91698993          	addi	s3,s3,-1770 # 8001a978 <tickslock>
    8000206a:	a08d                	j	800020cc <scheduler+0xb2>
      release(&p->lock);
    8000206c:	8526                	mv	a0,s1
    8000206e:	fffff097          	auipc	ra,0xfffff
    80002072:	be6080e7          	jalr	-1050(ra) # 80000c54 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002076:	17048493          	addi	s1,s1,368
    8000207a:	03348963          	beq	s1,s3,800020ac <scheduler+0x92>
      acquire(&p->lock);
    8000207e:	8526                	mv	a0,s1
    80002080:	fffff097          	auipc	ra,0xfffff
    80002084:	b64080e7          	jalr	-1180(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    80002088:	509c                	lw	a5,32(s1)
    8000208a:	ff2791e3          	bne	a5,s2,8000206c <scheduler+0x52>
        p->state = RUNNING;
    8000208e:	0384a023          	sw	s8,32(s1)
        c->proc = p;
    80002092:	029a3023          	sd	s1,32(s4)
        swtch(&c->scheduler, &p->context);
    80002096:	06848593          	addi	a1,s1,104
    8000209a:	855a                	mv	a0,s6
    8000209c:	00000097          	auipc	ra,0x0
    800020a0:	62c080e7          	jalr	1580(ra) # 800026c8 <swtch>
        c->proc = 0;
    800020a4:	020a3023          	sd	zero,32(s4)
        found = 1;
    800020a8:	8ade                	mv	s5,s7
    800020aa:	b7c9                	j	8000206c <scheduler+0x52>
    if(found == 0){
    800020ac:	020a9063          	bnez	s5,800020cc <scheduler+0xb2>
  asm volatile("csrr %0, sie" : "=r" (x) );
    800020b0:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800020b4:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800020b8:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020bc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020c0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020c4:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    800020c8:	10500073          	wfi
  asm volatile("csrr %0, sie" : "=r" (x) );
    800020cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800020d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800020d4:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020d8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020dc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020e0:	10079073          	csrw	sstatus,a5
    int found = 0;
    800020e4:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    800020e6:	00013497          	auipc	s1,0x13
    800020ea:	c9248493          	addi	s1,s1,-878 # 80014d78 <proc>
      if(p->state == RUNNABLE) {
    800020ee:	4909                	li	s2,2
    800020f0:	b779                	j	8000207e <scheduler+0x64>

00000000800020f2 <sched>:
{
    800020f2:	7179                	addi	sp,sp,-48
    800020f4:	f406                	sd	ra,40(sp)
    800020f6:	f022                	sd	s0,32(sp)
    800020f8:	ec26                	sd	s1,24(sp)
    800020fa:	e84a                	sd	s2,16(sp)
    800020fc:	e44e                	sd	s3,8(sp)
    800020fe:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002100:	00000097          	auipc	ra,0x0
    80002104:	a3c080e7          	jalr	-1476(ra) # 80001b3c <myproc>
    80002108:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000210a:	fffff097          	auipc	ra,0xfffff
    8000210e:	a9a080e7          	jalr	-1382(ra) # 80000ba4 <holding>
    80002112:	c93d                	beqz	a0,80002188 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002114:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002116:	2781                	sext.w	a5,a5
    80002118:	079e                	slli	a5,a5,0x7
    8000211a:	00013717          	auipc	a4,0x13
    8000211e:	83e70713          	addi	a4,a4,-1986 # 80014958 <pid_lock>
    80002122:	97ba                	add	a5,a5,a4
    80002124:	0987a703          	lw	a4,152(a5)
    80002128:	4785                	li	a5,1
    8000212a:	06f71763          	bne	a4,a5,80002198 <sched+0xa6>
  if(p->state == RUNNING)
    8000212e:	5098                	lw	a4,32(s1)
    80002130:	478d                	li	a5,3
    80002132:	06f70b63          	beq	a4,a5,800021a8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002136:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000213a:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000213c:	efb5                	bnez	a5,800021b8 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000213e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002140:	00013917          	auipc	s2,0x13
    80002144:	81890913          	addi	s2,s2,-2024 # 80014958 <pid_lock>
    80002148:	2781                	sext.w	a5,a5
    8000214a:	079e                	slli	a5,a5,0x7
    8000214c:	97ca                	add	a5,a5,s2
    8000214e:	09c7a983          	lw	s3,156(a5)
    80002152:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->scheduler);
    80002154:	2781                	sext.w	a5,a5
    80002156:	079e                	slli	a5,a5,0x7
    80002158:	00013597          	auipc	a1,0x13
    8000215c:	82858593          	addi	a1,a1,-2008 # 80014980 <cpus+0x8>
    80002160:	95be                	add	a1,a1,a5
    80002162:	06848513          	addi	a0,s1,104
    80002166:	00000097          	auipc	ra,0x0
    8000216a:	562080e7          	jalr	1378(ra) # 800026c8 <swtch>
    8000216e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002170:	2781                	sext.w	a5,a5
    80002172:	079e                	slli	a5,a5,0x7
    80002174:	97ca                	add	a5,a5,s2
    80002176:	0937ae23          	sw	s3,156(a5)
}
    8000217a:	70a2                	ld	ra,40(sp)
    8000217c:	7402                	ld	s0,32(sp)
    8000217e:	64e2                	ld	s1,24(sp)
    80002180:	6942                	ld	s2,16(sp)
    80002182:	69a2                	ld	s3,8(sp)
    80002184:	6145                	addi	sp,sp,48
    80002186:	8082                	ret
    panic("sched p->lock");
    80002188:	00006517          	auipc	a0,0x6
    8000218c:	2d050513          	addi	a0,a0,720 # 80008458 <userret+0x3c8>
    80002190:	ffffe097          	auipc	ra,0xffffe
    80002194:	3b8080e7          	jalr	952(ra) # 80000548 <panic>
    panic("sched locks");
    80002198:	00006517          	auipc	a0,0x6
    8000219c:	2d050513          	addi	a0,a0,720 # 80008468 <userret+0x3d8>
    800021a0:	ffffe097          	auipc	ra,0xffffe
    800021a4:	3a8080e7          	jalr	936(ra) # 80000548 <panic>
    panic("sched running");
    800021a8:	00006517          	auipc	a0,0x6
    800021ac:	2d050513          	addi	a0,a0,720 # 80008478 <userret+0x3e8>
    800021b0:	ffffe097          	auipc	ra,0xffffe
    800021b4:	398080e7          	jalr	920(ra) # 80000548 <panic>
    panic("sched interruptible");
    800021b8:	00006517          	auipc	a0,0x6
    800021bc:	2d050513          	addi	a0,a0,720 # 80008488 <userret+0x3f8>
    800021c0:	ffffe097          	auipc	ra,0xffffe
    800021c4:	388080e7          	jalr	904(ra) # 80000548 <panic>

00000000800021c8 <exit>:
{
    800021c8:	7179                	addi	sp,sp,-48
    800021ca:	f406                	sd	ra,40(sp)
    800021cc:	f022                	sd	s0,32(sp)
    800021ce:	ec26                	sd	s1,24(sp)
    800021d0:	e84a                	sd	s2,16(sp)
    800021d2:	e44e                	sd	s3,8(sp)
    800021d4:	e052                	sd	s4,0(sp)
    800021d6:	1800                	addi	s0,sp,48
    800021d8:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021da:	00000097          	auipc	ra,0x0
    800021de:	962080e7          	jalr	-1694(ra) # 80001b3c <myproc>
    800021e2:	89aa                	mv	s3,a0
  if(p == initproc)
    800021e4:	0002a797          	auipc	a5,0x2a
    800021e8:	e547b783          	ld	a5,-428(a5) # 8002c038 <initproc>
    800021ec:	0d850493          	addi	s1,a0,216
    800021f0:	15850913          	addi	s2,a0,344
    800021f4:	02a79363          	bne	a5,a0,8000221a <exit+0x52>
    panic("init exiting");
    800021f8:	00006517          	auipc	a0,0x6
    800021fc:	2a850513          	addi	a0,a0,680 # 800084a0 <userret+0x410>
    80002200:	ffffe097          	auipc	ra,0xffffe
    80002204:	348080e7          	jalr	840(ra) # 80000548 <panic>
      fileclose(f);
    80002208:	00002097          	auipc	ra,0x2
    8000220c:	4a4080e7          	jalr	1188(ra) # 800046ac <fileclose>
      p->ofile[fd] = 0;
    80002210:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002214:	04a1                	addi	s1,s1,8
    80002216:	01248563          	beq	s1,s2,80002220 <exit+0x58>
    if(p->ofile[fd]){
    8000221a:	6088                	ld	a0,0(s1)
    8000221c:	f575                	bnez	a0,80002208 <exit+0x40>
    8000221e:	bfdd                	j	80002214 <exit+0x4c>
  begin_op(ROOTDEV);
    80002220:	4501                	li	a0,0
    80002222:	00002097          	auipc	ra,0x2
    80002226:	ef0080e7          	jalr	-272(ra) # 80004112 <begin_op>
  iput(p->cwd);
    8000222a:	1589b503          	ld	a0,344(s3)
    8000222e:	00001097          	auipc	ra,0x1
    80002232:	60c080e7          	jalr	1548(ra) # 8000383a <iput>
  end_op(ROOTDEV);
    80002236:	4501                	li	a0,0
    80002238:	00002097          	auipc	ra,0x2
    8000223c:	f84080e7          	jalr	-124(ra) # 800041bc <end_op>
  p->cwd = 0;
    80002240:	1409bc23          	sd	zero,344(s3)
  acquire(&initproc->lock);
    80002244:	0002a497          	auipc	s1,0x2a
    80002248:	df448493          	addi	s1,s1,-524 # 8002c038 <initproc>
    8000224c:	6088                	ld	a0,0(s1)
    8000224e:	fffff097          	auipc	ra,0xfffff
    80002252:	996080e7          	jalr	-1642(ra) # 80000be4 <acquire>
  wakeup1(initproc);
    80002256:	6088                	ld	a0,0(s1)
    80002258:	fffff097          	auipc	ra,0xfffff
    8000225c:	7a4080e7          	jalr	1956(ra) # 800019fc <wakeup1>
  release(&initproc->lock);
    80002260:	6088                	ld	a0,0(s1)
    80002262:	fffff097          	auipc	ra,0xfffff
    80002266:	9f2080e7          	jalr	-1550(ra) # 80000c54 <release>
  acquire(&p->lock);
    8000226a:	854e                	mv	a0,s3
    8000226c:	fffff097          	auipc	ra,0xfffff
    80002270:	978080e7          	jalr	-1672(ra) # 80000be4 <acquire>
  struct proc *original_parent = p->parent;
    80002274:	0289b483          	ld	s1,40(s3)
  release(&p->lock);
    80002278:	854e                	mv	a0,s3
    8000227a:	fffff097          	auipc	ra,0xfffff
    8000227e:	9da080e7          	jalr	-1574(ra) # 80000c54 <release>
  acquire(&original_parent->lock);
    80002282:	8526                	mv	a0,s1
    80002284:	fffff097          	auipc	ra,0xfffff
    80002288:	960080e7          	jalr	-1696(ra) # 80000be4 <acquire>
  acquire(&p->lock);
    8000228c:	854e                	mv	a0,s3
    8000228e:	fffff097          	auipc	ra,0xfffff
    80002292:	956080e7          	jalr	-1706(ra) # 80000be4 <acquire>
  reparent(p);
    80002296:	854e                	mv	a0,s3
    80002298:	00000097          	auipc	ra,0x0
    8000229c:	d1c080e7          	jalr	-740(ra) # 80001fb4 <reparent>
  wakeup1(original_parent);
    800022a0:	8526                	mv	a0,s1
    800022a2:	fffff097          	auipc	ra,0xfffff
    800022a6:	75a080e7          	jalr	1882(ra) # 800019fc <wakeup1>
  p->xstate = status;
    800022aa:	0349ae23          	sw	s4,60(s3)
  p->state = ZOMBIE;
    800022ae:	4791                	li	a5,4
    800022b0:	02f9a023          	sw	a5,32(s3)
  release(&original_parent->lock);
    800022b4:	8526                	mv	a0,s1
    800022b6:	fffff097          	auipc	ra,0xfffff
    800022ba:	99e080e7          	jalr	-1634(ra) # 80000c54 <release>
  sched();
    800022be:	00000097          	auipc	ra,0x0
    800022c2:	e34080e7          	jalr	-460(ra) # 800020f2 <sched>
  panic("zombie exit");
    800022c6:	00006517          	auipc	a0,0x6
    800022ca:	1ea50513          	addi	a0,a0,490 # 800084b0 <userret+0x420>
    800022ce:	ffffe097          	auipc	ra,0xffffe
    800022d2:	27a080e7          	jalr	634(ra) # 80000548 <panic>

00000000800022d6 <yield>:
{
    800022d6:	1101                	addi	sp,sp,-32
    800022d8:	ec06                	sd	ra,24(sp)
    800022da:	e822                	sd	s0,16(sp)
    800022dc:	e426                	sd	s1,8(sp)
    800022de:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800022e0:	00000097          	auipc	ra,0x0
    800022e4:	85c080e7          	jalr	-1956(ra) # 80001b3c <myproc>
    800022e8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022ea:	fffff097          	auipc	ra,0xfffff
    800022ee:	8fa080e7          	jalr	-1798(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800022f2:	4789                	li	a5,2
    800022f4:	d09c                	sw	a5,32(s1)
  sched();
    800022f6:	00000097          	auipc	ra,0x0
    800022fa:	dfc080e7          	jalr	-516(ra) # 800020f2 <sched>
  release(&p->lock);
    800022fe:	8526                	mv	a0,s1
    80002300:	fffff097          	auipc	ra,0xfffff
    80002304:	954080e7          	jalr	-1708(ra) # 80000c54 <release>
}
    80002308:	60e2                	ld	ra,24(sp)
    8000230a:	6442                	ld	s0,16(sp)
    8000230c:	64a2                	ld	s1,8(sp)
    8000230e:	6105                	addi	sp,sp,32
    80002310:	8082                	ret

0000000080002312 <sleep>:
{
    80002312:	7179                	addi	sp,sp,-48
    80002314:	f406                	sd	ra,40(sp)
    80002316:	f022                	sd	s0,32(sp)
    80002318:	ec26                	sd	s1,24(sp)
    8000231a:	e84a                	sd	s2,16(sp)
    8000231c:	e44e                	sd	s3,8(sp)
    8000231e:	1800                	addi	s0,sp,48
    80002320:	89aa                	mv	s3,a0
    80002322:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002324:	00000097          	auipc	ra,0x0
    80002328:	818080e7          	jalr	-2024(ra) # 80001b3c <myproc>
    8000232c:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    8000232e:	05250663          	beq	a0,s2,8000237a <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002332:	fffff097          	auipc	ra,0xfffff
    80002336:	8b2080e7          	jalr	-1870(ra) # 80000be4 <acquire>
    release(lk);
    8000233a:	854a                	mv	a0,s2
    8000233c:	fffff097          	auipc	ra,0xfffff
    80002340:	918080e7          	jalr	-1768(ra) # 80000c54 <release>
  p->chan = chan;
    80002344:	0334b823          	sd	s3,48(s1)
  p->state = SLEEPING;
    80002348:	4785                	li	a5,1
    8000234a:	d09c                	sw	a5,32(s1)
  sched();
    8000234c:	00000097          	auipc	ra,0x0
    80002350:	da6080e7          	jalr	-602(ra) # 800020f2 <sched>
  p->chan = 0;
    80002354:	0204b823          	sd	zero,48(s1)
    release(&p->lock);
    80002358:	8526                	mv	a0,s1
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	8fa080e7          	jalr	-1798(ra) # 80000c54 <release>
    acquire(lk);
    80002362:	854a                	mv	a0,s2
    80002364:	fffff097          	auipc	ra,0xfffff
    80002368:	880080e7          	jalr	-1920(ra) # 80000be4 <acquire>
}
    8000236c:	70a2                	ld	ra,40(sp)
    8000236e:	7402                	ld	s0,32(sp)
    80002370:	64e2                	ld	s1,24(sp)
    80002372:	6942                	ld	s2,16(sp)
    80002374:	69a2                	ld	s3,8(sp)
    80002376:	6145                	addi	sp,sp,48
    80002378:	8082                	ret
  p->chan = chan;
    8000237a:	03353823          	sd	s3,48(a0)
  p->state = SLEEPING;
    8000237e:	4785                	li	a5,1
    80002380:	d11c                	sw	a5,32(a0)
  sched();
    80002382:	00000097          	auipc	ra,0x0
    80002386:	d70080e7          	jalr	-656(ra) # 800020f2 <sched>
  p->chan = 0;
    8000238a:	0204b823          	sd	zero,48(s1)
  if(lk != &p->lock){
    8000238e:	bff9                	j	8000236c <sleep+0x5a>

0000000080002390 <wait>:
{
    80002390:	715d                	addi	sp,sp,-80
    80002392:	e486                	sd	ra,72(sp)
    80002394:	e0a2                	sd	s0,64(sp)
    80002396:	fc26                	sd	s1,56(sp)
    80002398:	f84a                	sd	s2,48(sp)
    8000239a:	f44e                	sd	s3,40(sp)
    8000239c:	f052                	sd	s4,32(sp)
    8000239e:	ec56                	sd	s5,24(sp)
    800023a0:	e85a                	sd	s6,16(sp)
    800023a2:	e45e                	sd	s7,8(sp)
    800023a4:	0880                	addi	s0,sp,80
    800023a6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023a8:	fffff097          	auipc	ra,0xfffff
    800023ac:	794080e7          	jalr	1940(ra) # 80001b3c <myproc>
    800023b0:	892a                	mv	s2,a0
  acquire(&p->lock);
    800023b2:	fffff097          	auipc	ra,0xfffff
    800023b6:	832080e7          	jalr	-1998(ra) # 80000be4 <acquire>
    havekids = 0;
    800023ba:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800023bc:	4a11                	li	s4,4
        havekids = 1;
    800023be:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800023c0:	00018997          	auipc	s3,0x18
    800023c4:	5b898993          	addi	s3,s3,1464 # 8001a978 <tickslock>
    havekids = 0;
    800023c8:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800023ca:	00013497          	auipc	s1,0x13
    800023ce:	9ae48493          	addi	s1,s1,-1618 # 80014d78 <proc>
    800023d2:	a08d                	j	80002434 <wait+0xa4>
          pid = np->pid;
    800023d4:	0404a983          	lw	s3,64(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800023d8:	000b0e63          	beqz	s6,800023f4 <wait+0x64>
    800023dc:	4691                	li	a3,4
    800023de:	03c48613          	addi	a2,s1,60
    800023e2:	85da                	mv	a1,s6
    800023e4:	05893503          	ld	a0,88(s2)
    800023e8:	fffff097          	auipc	ra,0xfffff
    800023ec:	446080e7          	jalr	1094(ra) # 8000182e <copyout>
    800023f0:	02054263          	bltz	a0,80002414 <wait+0x84>
          freeproc(np);
    800023f4:	8526                	mv	a0,s1
    800023f6:	00000097          	auipc	ra,0x0
    800023fa:	962080e7          	jalr	-1694(ra) # 80001d58 <freeproc>
          release(&np->lock);
    800023fe:	8526                	mv	a0,s1
    80002400:	fffff097          	auipc	ra,0xfffff
    80002404:	854080e7          	jalr	-1964(ra) # 80000c54 <release>
          release(&p->lock);
    80002408:	854a                	mv	a0,s2
    8000240a:	fffff097          	auipc	ra,0xfffff
    8000240e:	84a080e7          	jalr	-1974(ra) # 80000c54 <release>
          return pid;
    80002412:	a8a9                	j	8000246c <wait+0xdc>
            release(&np->lock);
    80002414:	8526                	mv	a0,s1
    80002416:	fffff097          	auipc	ra,0xfffff
    8000241a:	83e080e7          	jalr	-1986(ra) # 80000c54 <release>
            release(&p->lock);
    8000241e:	854a                	mv	a0,s2
    80002420:	fffff097          	auipc	ra,0xfffff
    80002424:	834080e7          	jalr	-1996(ra) # 80000c54 <release>
            return -1;
    80002428:	59fd                	li	s3,-1
    8000242a:	a089                	j	8000246c <wait+0xdc>
    for(np = proc; np < &proc[NPROC]; np++){
    8000242c:	17048493          	addi	s1,s1,368
    80002430:	03348463          	beq	s1,s3,80002458 <wait+0xc8>
      if(np->parent == p){
    80002434:	749c                	ld	a5,40(s1)
    80002436:	ff279be3          	bne	a5,s2,8000242c <wait+0x9c>
        acquire(&np->lock);
    8000243a:	8526                	mv	a0,s1
    8000243c:	ffffe097          	auipc	ra,0xffffe
    80002440:	7a8080e7          	jalr	1960(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002444:	509c                	lw	a5,32(s1)
    80002446:	f94787e3          	beq	a5,s4,800023d4 <wait+0x44>
        release(&np->lock);
    8000244a:	8526                	mv	a0,s1
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	808080e7          	jalr	-2040(ra) # 80000c54 <release>
        havekids = 1;
    80002454:	8756                	mv	a4,s5
    80002456:	bfd9                	j	8000242c <wait+0x9c>
    if(!havekids || p->killed){
    80002458:	c701                	beqz	a4,80002460 <wait+0xd0>
    8000245a:	03892783          	lw	a5,56(s2)
    8000245e:	c39d                	beqz	a5,80002484 <wait+0xf4>
      release(&p->lock);
    80002460:	854a                	mv	a0,s2
    80002462:	ffffe097          	auipc	ra,0xffffe
    80002466:	7f2080e7          	jalr	2034(ra) # 80000c54 <release>
      return -1;
    8000246a:	59fd                	li	s3,-1
}
    8000246c:	854e                	mv	a0,s3
    8000246e:	60a6                	ld	ra,72(sp)
    80002470:	6406                	ld	s0,64(sp)
    80002472:	74e2                	ld	s1,56(sp)
    80002474:	7942                	ld	s2,48(sp)
    80002476:	79a2                	ld	s3,40(sp)
    80002478:	7a02                	ld	s4,32(sp)
    8000247a:	6ae2                	ld	s5,24(sp)
    8000247c:	6b42                	ld	s6,16(sp)
    8000247e:	6ba2                	ld	s7,8(sp)
    80002480:	6161                	addi	sp,sp,80
    80002482:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002484:	85ca                	mv	a1,s2
    80002486:	854a                	mv	a0,s2
    80002488:	00000097          	auipc	ra,0x0
    8000248c:	e8a080e7          	jalr	-374(ra) # 80002312 <sleep>
    havekids = 0;
    80002490:	bf25                	j	800023c8 <wait+0x38>

0000000080002492 <wakeup>:
{
    80002492:	7139                	addi	sp,sp,-64
    80002494:	fc06                	sd	ra,56(sp)
    80002496:	f822                	sd	s0,48(sp)
    80002498:	f426                	sd	s1,40(sp)
    8000249a:	f04a                	sd	s2,32(sp)
    8000249c:	ec4e                	sd	s3,24(sp)
    8000249e:	e852                	sd	s4,16(sp)
    800024a0:	e456                	sd	s5,8(sp)
    800024a2:	0080                	addi	s0,sp,64
    800024a4:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800024a6:	00013497          	auipc	s1,0x13
    800024aa:	8d248493          	addi	s1,s1,-1838 # 80014d78 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800024ae:	4985                	li	s3,1
      p->state = RUNNABLE;
    800024b0:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800024b2:	00018917          	auipc	s2,0x18
    800024b6:	4c690913          	addi	s2,s2,1222 # 8001a978 <tickslock>
    800024ba:	a811                	j	800024ce <wakeup+0x3c>
    release(&p->lock);
    800024bc:	8526                	mv	a0,s1
    800024be:	ffffe097          	auipc	ra,0xffffe
    800024c2:	796080e7          	jalr	1942(ra) # 80000c54 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800024c6:	17048493          	addi	s1,s1,368
    800024ca:	03248063          	beq	s1,s2,800024ea <wakeup+0x58>
    acquire(&p->lock);
    800024ce:	8526                	mv	a0,s1
    800024d0:	ffffe097          	auipc	ra,0xffffe
    800024d4:	714080e7          	jalr	1812(ra) # 80000be4 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800024d8:	509c                	lw	a5,32(s1)
    800024da:	ff3791e3          	bne	a5,s3,800024bc <wakeup+0x2a>
    800024de:	789c                	ld	a5,48(s1)
    800024e0:	fd479ee3          	bne	a5,s4,800024bc <wakeup+0x2a>
      p->state = RUNNABLE;
    800024e4:	0354a023          	sw	s5,32(s1)
    800024e8:	bfd1                	j	800024bc <wakeup+0x2a>
}
    800024ea:	70e2                	ld	ra,56(sp)
    800024ec:	7442                	ld	s0,48(sp)
    800024ee:	74a2                	ld	s1,40(sp)
    800024f0:	7902                	ld	s2,32(sp)
    800024f2:	69e2                	ld	s3,24(sp)
    800024f4:	6a42                	ld	s4,16(sp)
    800024f6:	6aa2                	ld	s5,8(sp)
    800024f8:	6121                	addi	sp,sp,64
    800024fa:	8082                	ret

00000000800024fc <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800024fc:	7179                	addi	sp,sp,-48
    800024fe:	f406                	sd	ra,40(sp)
    80002500:	f022                	sd	s0,32(sp)
    80002502:	ec26                	sd	s1,24(sp)
    80002504:	e84a                	sd	s2,16(sp)
    80002506:	e44e                	sd	s3,8(sp)
    80002508:	1800                	addi	s0,sp,48
    8000250a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000250c:	00013497          	auipc	s1,0x13
    80002510:	86c48493          	addi	s1,s1,-1940 # 80014d78 <proc>
    80002514:	00018997          	auipc	s3,0x18
    80002518:	46498993          	addi	s3,s3,1124 # 8001a978 <tickslock>
    acquire(&p->lock);
    8000251c:	8526                	mv	a0,s1
    8000251e:	ffffe097          	auipc	ra,0xffffe
    80002522:	6c6080e7          	jalr	1734(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002526:	40bc                	lw	a5,64(s1)
    80002528:	01278d63          	beq	a5,s2,80002542 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000252c:	8526                	mv	a0,s1
    8000252e:	ffffe097          	auipc	ra,0xffffe
    80002532:	726080e7          	jalr	1830(ra) # 80000c54 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002536:	17048493          	addi	s1,s1,368
    8000253a:	ff3491e3          	bne	s1,s3,8000251c <kill+0x20>
  }
  return -1;
    8000253e:	557d                	li	a0,-1
    80002540:	a821                	j	80002558 <kill+0x5c>
      p->killed = 1;
    80002542:	4785                	li	a5,1
    80002544:	dc9c                	sw	a5,56(s1)
      if(p->state == SLEEPING){
    80002546:	5098                	lw	a4,32(s1)
    80002548:	00f70f63          	beq	a4,a5,80002566 <kill+0x6a>
      release(&p->lock);
    8000254c:	8526                	mv	a0,s1
    8000254e:	ffffe097          	auipc	ra,0xffffe
    80002552:	706080e7          	jalr	1798(ra) # 80000c54 <release>
      return 0;
    80002556:	4501                	li	a0,0
}
    80002558:	70a2                	ld	ra,40(sp)
    8000255a:	7402                	ld	s0,32(sp)
    8000255c:	64e2                	ld	s1,24(sp)
    8000255e:	6942                	ld	s2,16(sp)
    80002560:	69a2                	ld	s3,8(sp)
    80002562:	6145                	addi	sp,sp,48
    80002564:	8082                	ret
        p->state = RUNNABLE;
    80002566:	4789                	li	a5,2
    80002568:	d09c                	sw	a5,32(s1)
    8000256a:	b7cd                	j	8000254c <kill+0x50>

000000008000256c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000256c:	7179                	addi	sp,sp,-48
    8000256e:	f406                	sd	ra,40(sp)
    80002570:	f022                	sd	s0,32(sp)
    80002572:	ec26                	sd	s1,24(sp)
    80002574:	e84a                	sd	s2,16(sp)
    80002576:	e44e                	sd	s3,8(sp)
    80002578:	e052                	sd	s4,0(sp)
    8000257a:	1800                	addi	s0,sp,48
    8000257c:	84aa                	mv	s1,a0
    8000257e:	892e                	mv	s2,a1
    80002580:	89b2                	mv	s3,a2
    80002582:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002584:	fffff097          	auipc	ra,0xfffff
    80002588:	5b8080e7          	jalr	1464(ra) # 80001b3c <myproc>
  if(user_dst){
    8000258c:	c08d                	beqz	s1,800025ae <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000258e:	86d2                	mv	a3,s4
    80002590:	864e                	mv	a2,s3
    80002592:	85ca                	mv	a1,s2
    80002594:	6d28                	ld	a0,88(a0)
    80002596:	fffff097          	auipc	ra,0xfffff
    8000259a:	298080e7          	jalr	664(ra) # 8000182e <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000259e:	70a2                	ld	ra,40(sp)
    800025a0:	7402                	ld	s0,32(sp)
    800025a2:	64e2                	ld	s1,24(sp)
    800025a4:	6942                	ld	s2,16(sp)
    800025a6:	69a2                	ld	s3,8(sp)
    800025a8:	6a02                	ld	s4,0(sp)
    800025aa:	6145                	addi	sp,sp,48
    800025ac:	8082                	ret
    memmove((char *)dst, src, len);
    800025ae:	000a061b          	sext.w	a2,s4
    800025b2:	85ce                	mv	a1,s3
    800025b4:	854a                	mv	a0,s2
    800025b6:	fffff097          	auipc	ra,0xfffff
    800025ba:	8f8080e7          	jalr	-1800(ra) # 80000eae <memmove>
    return 0;
    800025be:	8526                	mv	a0,s1
    800025c0:	bff9                	j	8000259e <either_copyout+0x32>

00000000800025c2 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800025c2:	7179                	addi	sp,sp,-48
    800025c4:	f406                	sd	ra,40(sp)
    800025c6:	f022                	sd	s0,32(sp)
    800025c8:	ec26                	sd	s1,24(sp)
    800025ca:	e84a                	sd	s2,16(sp)
    800025cc:	e44e                	sd	s3,8(sp)
    800025ce:	e052                	sd	s4,0(sp)
    800025d0:	1800                	addi	s0,sp,48
    800025d2:	892a                	mv	s2,a0
    800025d4:	84ae                	mv	s1,a1
    800025d6:	89b2                	mv	s3,a2
    800025d8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025da:	fffff097          	auipc	ra,0xfffff
    800025de:	562080e7          	jalr	1378(ra) # 80001b3c <myproc>
  if(user_src){
    800025e2:	c08d                	beqz	s1,80002604 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800025e4:	86d2                	mv	a3,s4
    800025e6:	864e                	mv	a2,s3
    800025e8:	85ca                	mv	a1,s2
    800025ea:	6d28                	ld	a0,88(a0)
    800025ec:	fffff097          	auipc	ra,0xfffff
    800025f0:	2ce080e7          	jalr	718(ra) # 800018ba <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800025f4:	70a2                	ld	ra,40(sp)
    800025f6:	7402                	ld	s0,32(sp)
    800025f8:	64e2                	ld	s1,24(sp)
    800025fa:	6942                	ld	s2,16(sp)
    800025fc:	69a2                	ld	s3,8(sp)
    800025fe:	6a02                	ld	s4,0(sp)
    80002600:	6145                	addi	sp,sp,48
    80002602:	8082                	ret
    memmove(dst, (char*)src, len);
    80002604:	000a061b          	sext.w	a2,s4
    80002608:	85ce                	mv	a1,s3
    8000260a:	854a                	mv	a0,s2
    8000260c:	fffff097          	auipc	ra,0xfffff
    80002610:	8a2080e7          	jalr	-1886(ra) # 80000eae <memmove>
    return 0;
    80002614:	8526                	mv	a0,s1
    80002616:	bff9                	j	800025f4 <either_copyin+0x32>

0000000080002618 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002618:	715d                	addi	sp,sp,-80
    8000261a:	e486                	sd	ra,72(sp)
    8000261c:	e0a2                	sd	s0,64(sp)
    8000261e:	fc26                	sd	s1,56(sp)
    80002620:	f84a                	sd	s2,48(sp)
    80002622:	f44e                	sd	s3,40(sp)
    80002624:	f052                	sd	s4,32(sp)
    80002626:	ec56                	sd	s5,24(sp)
    80002628:	e85a                	sd	s6,16(sp)
    8000262a:	e45e                	sd	s7,8(sp)
    8000262c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000262e:	00006517          	auipc	a0,0x6
    80002632:	c6250513          	addi	a0,a0,-926 # 80008290 <userret+0x200>
    80002636:	ffffe097          	auipc	ra,0xffffe
    8000263a:	f6c080e7          	jalr	-148(ra) # 800005a2 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000263e:	00013497          	auipc	s1,0x13
    80002642:	89a48493          	addi	s1,s1,-1894 # 80014ed8 <proc+0x160>
    80002646:	00018917          	auipc	s2,0x18
    8000264a:	49290913          	addi	s2,s2,1170 # 8001aad8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000264e:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002650:	00006997          	auipc	s3,0x6
    80002654:	e7098993          	addi	s3,s3,-400 # 800084c0 <userret+0x430>
    printf("%d %s %s", p->pid, state, p->name);
    80002658:	00006a97          	auipc	s5,0x6
    8000265c:	e70a8a93          	addi	s5,s5,-400 # 800084c8 <userret+0x438>
    printf("\n");
    80002660:	00006a17          	auipc	s4,0x6
    80002664:	c30a0a13          	addi	s4,s4,-976 # 80008290 <userret+0x200>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002668:	00006b97          	auipc	s7,0x6
    8000266c:	460b8b93          	addi	s7,s7,1120 # 80008ac8 <states.0>
    80002670:	a00d                	j	80002692 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002672:	ee06a583          	lw	a1,-288(a3)
    80002676:	8556                	mv	a0,s5
    80002678:	ffffe097          	auipc	ra,0xffffe
    8000267c:	f2a080e7          	jalr	-214(ra) # 800005a2 <printf>
    printf("\n");
    80002680:	8552                	mv	a0,s4
    80002682:	ffffe097          	auipc	ra,0xffffe
    80002686:	f20080e7          	jalr	-224(ra) # 800005a2 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000268a:	17048493          	addi	s1,s1,368
    8000268e:	03248263          	beq	s1,s2,800026b2 <procdump+0x9a>
    if(p->state == UNUSED)
    80002692:	86a6                	mv	a3,s1
    80002694:	ec04a783          	lw	a5,-320(s1)
    80002698:	dbed                	beqz	a5,8000268a <procdump+0x72>
      state = "???";
    8000269a:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000269c:	fcfb6be3          	bltu	s6,a5,80002672 <procdump+0x5a>
    800026a0:	02079713          	slli	a4,a5,0x20
    800026a4:	01d75793          	srli	a5,a4,0x1d
    800026a8:	97de                	add	a5,a5,s7
    800026aa:	6390                	ld	a2,0(a5)
    800026ac:	f279                	bnez	a2,80002672 <procdump+0x5a>
      state = "???";
    800026ae:	864e                	mv	a2,s3
    800026b0:	b7c9                	j	80002672 <procdump+0x5a>
  }
}
    800026b2:	60a6                	ld	ra,72(sp)
    800026b4:	6406                	ld	s0,64(sp)
    800026b6:	74e2                	ld	s1,56(sp)
    800026b8:	7942                	ld	s2,48(sp)
    800026ba:	79a2                	ld	s3,40(sp)
    800026bc:	7a02                	ld	s4,32(sp)
    800026be:	6ae2                	ld	s5,24(sp)
    800026c0:	6b42                	ld	s6,16(sp)
    800026c2:	6ba2                	ld	s7,8(sp)
    800026c4:	6161                	addi	sp,sp,80
    800026c6:	8082                	ret

00000000800026c8 <swtch>:
    800026c8:	00153023          	sd	ra,0(a0)
    800026cc:	00253423          	sd	sp,8(a0)
    800026d0:	e900                	sd	s0,16(a0)
    800026d2:	ed04                	sd	s1,24(a0)
    800026d4:	03253023          	sd	s2,32(a0)
    800026d8:	03353423          	sd	s3,40(a0)
    800026dc:	03453823          	sd	s4,48(a0)
    800026e0:	03553c23          	sd	s5,56(a0)
    800026e4:	05653023          	sd	s6,64(a0)
    800026e8:	05753423          	sd	s7,72(a0)
    800026ec:	05853823          	sd	s8,80(a0)
    800026f0:	05953c23          	sd	s9,88(a0)
    800026f4:	07a53023          	sd	s10,96(a0)
    800026f8:	07b53423          	sd	s11,104(a0)
    800026fc:	0005b083          	ld	ra,0(a1)
    80002700:	0085b103          	ld	sp,8(a1)
    80002704:	6980                	ld	s0,16(a1)
    80002706:	6d84                	ld	s1,24(a1)
    80002708:	0205b903          	ld	s2,32(a1)
    8000270c:	0285b983          	ld	s3,40(a1)
    80002710:	0305ba03          	ld	s4,48(a1)
    80002714:	0385ba83          	ld	s5,56(a1)
    80002718:	0405bb03          	ld	s6,64(a1)
    8000271c:	0485bb83          	ld	s7,72(a1)
    80002720:	0505bc03          	ld	s8,80(a1)
    80002724:	0585bc83          	ld	s9,88(a1)
    80002728:	0605bd03          	ld	s10,96(a1)
    8000272c:	0685bd83          	ld	s11,104(a1)
    80002730:	8082                	ret

0000000080002732 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002732:	1141                	addi	sp,sp,-16
    80002734:	e406                	sd	ra,8(sp)
    80002736:	e022                	sd	s0,0(sp)
    80002738:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000273a:	00006597          	auipc	a1,0x6
    8000273e:	dc658593          	addi	a1,a1,-570 # 80008500 <userret+0x470>
    80002742:	00018517          	auipc	a0,0x18
    80002746:	23650513          	addi	a0,a0,566 # 8001a978 <tickslock>
    8000274a:	ffffe097          	auipc	ra,0xffffe
    8000274e:	34c080e7          	jalr	844(ra) # 80000a96 <initlock>
}
    80002752:	60a2                	ld	ra,8(sp)
    80002754:	6402                	ld	s0,0(sp)
    80002756:	0141                	addi	sp,sp,16
    80002758:	8082                	ret

000000008000275a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000275a:	1141                	addi	sp,sp,-16
    8000275c:	e422                	sd	s0,8(sp)
    8000275e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002760:	00003797          	auipc	a5,0x3
    80002764:	5e078793          	addi	a5,a5,1504 # 80005d40 <kernelvec>
    80002768:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000276c:	6422                	ld	s0,8(sp)
    8000276e:	0141                	addi	sp,sp,16
    80002770:	8082                	ret

0000000080002772 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002772:	1141                	addi	sp,sp,-16
    80002774:	e406                	sd	ra,8(sp)
    80002776:	e022                	sd	s0,0(sp)
    80002778:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000277a:	fffff097          	auipc	ra,0xfffff
    8000277e:	3c2080e7          	jalr	962(ra) # 80001b3c <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002782:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002786:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002788:	10079073          	csrw	sstatus,a5
  // turn off interrupts, since we're switching
  // now from kerneltrap() to usertrap().
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000278c:	00006617          	auipc	a2,0x6
    80002790:	87460613          	addi	a2,a2,-1932 # 80008000 <trampoline>
    80002794:	00006697          	auipc	a3,0x6
    80002798:	86c68693          	addi	a3,a3,-1940 # 80008000 <trampoline>
    8000279c:	8e91                	sub	a3,a3,a2
    8000279e:	040007b7          	lui	a5,0x4000
    800027a2:	17fd                	addi	a5,a5,-1
    800027a4:	07b2                	slli	a5,a5,0xc
    800027a6:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027a8:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->tf->kernel_satp = r_satp();         // kernel page table
    800027ac:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800027ae:	180026f3          	csrr	a3,satp
    800027b2:	e314                	sd	a3,0(a4)
  p->tf->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800027b4:	7138                	ld	a4,96(a0)
    800027b6:	6534                	ld	a3,72(a0)
    800027b8:	6585                	lui	a1,0x1
    800027ba:	96ae                	add	a3,a3,a1
    800027bc:	e714                	sd	a3,8(a4)
  p->tf->kernel_trap = (uint64)usertrap;
    800027be:	7138                	ld	a4,96(a0)
    800027c0:	00000697          	auipc	a3,0x0
    800027c4:	12868693          	addi	a3,a3,296 # 800028e8 <usertrap>
    800027c8:	eb14                	sd	a3,16(a4)
  p->tf->kernel_hartid = r_tp();         // hartid for cpuid()
    800027ca:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800027cc:	8692                	mv	a3,tp
    800027ce:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027d0:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800027d4:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800027d8:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027dc:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->tf->epc);
    800027e0:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027e2:	6f18                	ld	a4,24(a4)
    800027e4:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027e8:	6d2c                	ld	a1,88(a0)
    800027ea:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800027ec:	00006717          	auipc	a4,0x6
    800027f0:	8a470713          	addi	a4,a4,-1884 # 80008090 <userret>
    800027f4:	8f11                	sub	a4,a4,a2
    800027f6:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800027f8:	577d                	li	a4,-1
    800027fa:	177e                	slli	a4,a4,0x3f
    800027fc:	8dd9                	or	a1,a1,a4
    800027fe:	02000537          	lui	a0,0x2000
    80002802:	157d                	addi	a0,a0,-1
    80002804:	0536                	slli	a0,a0,0xd
    80002806:	9782                	jalr	a5
}
    80002808:	60a2                	ld	ra,8(sp)
    8000280a:	6402                	ld	s0,0(sp)
    8000280c:	0141                	addi	sp,sp,16
    8000280e:	8082                	ret

0000000080002810 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002810:	1101                	addi	sp,sp,-32
    80002812:	ec06                	sd	ra,24(sp)
    80002814:	e822                	sd	s0,16(sp)
    80002816:	e426                	sd	s1,8(sp)
    80002818:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000281a:	00018497          	auipc	s1,0x18
    8000281e:	15e48493          	addi	s1,s1,350 # 8001a978 <tickslock>
    80002822:	8526                	mv	a0,s1
    80002824:	ffffe097          	auipc	ra,0xffffe
    80002828:	3c0080e7          	jalr	960(ra) # 80000be4 <acquire>
  ticks++;
    8000282c:	0002a517          	auipc	a0,0x2a
    80002830:	81450513          	addi	a0,a0,-2028 # 8002c040 <ticks>
    80002834:	411c                	lw	a5,0(a0)
    80002836:	2785                	addiw	a5,a5,1
    80002838:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000283a:	00000097          	auipc	ra,0x0
    8000283e:	c58080e7          	jalr	-936(ra) # 80002492 <wakeup>
  release(&tickslock);
    80002842:	8526                	mv	a0,s1
    80002844:	ffffe097          	auipc	ra,0xffffe
    80002848:	410080e7          	jalr	1040(ra) # 80000c54 <release>
}
    8000284c:	60e2                	ld	ra,24(sp)
    8000284e:	6442                	ld	s0,16(sp)
    80002850:	64a2                	ld	s1,8(sp)
    80002852:	6105                	addi	sp,sp,32
    80002854:	8082                	ret

0000000080002856 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002856:	1101                	addi	sp,sp,-32
    80002858:	ec06                	sd	ra,24(sp)
    8000285a:	e822                	sd	s0,16(sp)
    8000285c:	e426                	sd	s1,8(sp)
    8000285e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002860:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002864:	00074d63          	bltz	a4,8000287e <devintr+0x28>
      virtio_disk_intr(irq - VIRTIO0_IRQ);
    }

    plic_complete(irq);
    return 1;
  } else if(scause == 0x8000000000000001L){
    80002868:	57fd                	li	a5,-1
    8000286a:	17fe                	slli	a5,a5,0x3f
    8000286c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000286e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002870:	04f70b63          	beq	a4,a5,800028c6 <devintr+0x70>
  }
}
    80002874:	60e2                	ld	ra,24(sp)
    80002876:	6442                	ld	s0,16(sp)
    80002878:	64a2                	ld	s1,8(sp)
    8000287a:	6105                	addi	sp,sp,32
    8000287c:	8082                	ret
     (scause & 0xff) == 9){
    8000287e:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002882:	46a5                	li	a3,9
    80002884:	fed792e3          	bne	a5,a3,80002868 <devintr+0x12>
    int irq = plic_claim();
    80002888:	00003097          	auipc	ra,0x3
    8000288c:	5c0080e7          	jalr	1472(ra) # 80005e48 <plic_claim>
    80002890:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002892:	47a9                	li	a5,10
    80002894:	00f50e63          	beq	a0,a5,800028b0 <devintr+0x5a>
    } else if(irq == VIRTIO0_IRQ || irq == VIRTIO1_IRQ ){
    80002898:	fff5079b          	addiw	a5,a0,-1
    8000289c:	4705                	li	a4,1
    8000289e:	00f77e63          	bgeu	a4,a5,800028ba <devintr+0x64>
    plic_complete(irq);
    800028a2:	8526                	mv	a0,s1
    800028a4:	00003097          	auipc	ra,0x3
    800028a8:	5c8080e7          	jalr	1480(ra) # 80005e6c <plic_complete>
    return 1;
    800028ac:	4505                	li	a0,1
    800028ae:	b7d9                	j	80002874 <devintr+0x1e>
      uartintr();
    800028b0:	ffffe097          	auipc	ra,0xffffe
    800028b4:	f88080e7          	jalr	-120(ra) # 80000838 <uartintr>
    800028b8:	b7ed                	j	800028a2 <devintr+0x4c>
      virtio_disk_intr(irq - VIRTIO0_IRQ);
    800028ba:	853e                	mv	a0,a5
    800028bc:	00004097          	auipc	ra,0x4
    800028c0:	b5a080e7          	jalr	-1190(ra) # 80006416 <virtio_disk_intr>
    800028c4:	bff9                	j	800028a2 <devintr+0x4c>
    if(cpuid() == 0){
    800028c6:	fffff097          	auipc	ra,0xfffff
    800028ca:	24a080e7          	jalr	586(ra) # 80001b10 <cpuid>
    800028ce:	c901                	beqz	a0,800028de <devintr+0x88>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028d0:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028d4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028d6:	14479073          	csrw	sip,a5
    return 2;
    800028da:	4509                	li	a0,2
    800028dc:	bf61                	j	80002874 <devintr+0x1e>
      clockintr();
    800028de:	00000097          	auipc	ra,0x0
    800028e2:	f32080e7          	jalr	-206(ra) # 80002810 <clockintr>
    800028e6:	b7ed                	j	800028d0 <devintr+0x7a>

00000000800028e8 <usertrap>:
{
    800028e8:	1101                	addi	sp,sp,-32
    800028ea:	ec06                	sd	ra,24(sp)
    800028ec:	e822                	sd	s0,16(sp)
    800028ee:	e426                	sd	s1,8(sp)
    800028f0:	e04a                	sd	s2,0(sp)
    800028f2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028f4:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028f8:	1007f793          	andi	a5,a5,256
    800028fc:	e7bd                	bnez	a5,8000296a <usertrap+0x82>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028fe:	00003797          	auipc	a5,0x3
    80002902:	44278793          	addi	a5,a5,1090 # 80005d40 <kernelvec>
    80002906:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000290a:	fffff097          	auipc	ra,0xfffff
    8000290e:	232080e7          	jalr	562(ra) # 80001b3c <myproc>
    80002912:	84aa                	mv	s1,a0
  p->tf->epc = r_sepc();
    80002914:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002916:	14102773          	csrr	a4,sepc
    8000291a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000291c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002920:	47a1                	li	a5,8
    80002922:	06f71263          	bne	a4,a5,80002986 <usertrap+0x9e>
    if(p->killed)
    80002926:	5d1c                	lw	a5,56(a0)
    80002928:	eba9                	bnez	a5,8000297a <usertrap+0x92>
    p->tf->epc += 4;
    8000292a:	70b8                	ld	a4,96(s1)
    8000292c:	6f1c                	ld	a5,24(a4)
    8000292e:	0791                	addi	a5,a5,4
    80002930:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sie" : "=r" (x) );
    80002932:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    80002936:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    8000293a:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000293e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002942:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002946:	10079073          	csrw	sstatus,a5
    syscall();
    8000294a:	00000097          	auipc	ra,0x0
    8000294e:	2e0080e7          	jalr	736(ra) # 80002c2a <syscall>
  if(p->killed)
    80002952:	5c9c                	lw	a5,56(s1)
    80002954:	ebc1                	bnez	a5,800029e4 <usertrap+0xfc>
  usertrapret();
    80002956:	00000097          	auipc	ra,0x0
    8000295a:	e1c080e7          	jalr	-484(ra) # 80002772 <usertrapret>
}
    8000295e:	60e2                	ld	ra,24(sp)
    80002960:	6442                	ld	s0,16(sp)
    80002962:	64a2                	ld	s1,8(sp)
    80002964:	6902                	ld	s2,0(sp)
    80002966:	6105                	addi	sp,sp,32
    80002968:	8082                	ret
    panic("usertrap: not from user mode");
    8000296a:	00006517          	auipc	a0,0x6
    8000296e:	b9e50513          	addi	a0,a0,-1122 # 80008508 <userret+0x478>
    80002972:	ffffe097          	auipc	ra,0xffffe
    80002976:	bd6080e7          	jalr	-1066(ra) # 80000548 <panic>
      exit(-1);
    8000297a:	557d                	li	a0,-1
    8000297c:	00000097          	auipc	ra,0x0
    80002980:	84c080e7          	jalr	-1972(ra) # 800021c8 <exit>
    80002984:	b75d                	j	8000292a <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002986:	00000097          	auipc	ra,0x0
    8000298a:	ed0080e7          	jalr	-304(ra) # 80002856 <devintr>
    8000298e:	892a                	mv	s2,a0
    80002990:	c501                	beqz	a0,80002998 <usertrap+0xb0>
  if(p->killed)
    80002992:	5c9c                	lw	a5,56(s1)
    80002994:	c3a1                	beqz	a5,800029d4 <usertrap+0xec>
    80002996:	a815                	j	800029ca <usertrap+0xe2>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002998:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000299c:	40b0                	lw	a2,64(s1)
    8000299e:	00006517          	auipc	a0,0x6
    800029a2:	b8a50513          	addi	a0,a0,-1142 # 80008528 <userret+0x498>
    800029a6:	ffffe097          	auipc	ra,0xffffe
    800029aa:	bfc080e7          	jalr	-1028(ra) # 800005a2 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029ae:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029b2:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029b6:	00006517          	auipc	a0,0x6
    800029ba:	ba250513          	addi	a0,a0,-1118 # 80008558 <userret+0x4c8>
    800029be:	ffffe097          	auipc	ra,0xffffe
    800029c2:	be4080e7          	jalr	-1052(ra) # 800005a2 <printf>
    p->killed = 1;
    800029c6:	4785                	li	a5,1
    800029c8:	dc9c                	sw	a5,56(s1)
    exit(-1);
    800029ca:	557d                	li	a0,-1
    800029cc:	fffff097          	auipc	ra,0xfffff
    800029d0:	7fc080e7          	jalr	2044(ra) # 800021c8 <exit>
  if(which_dev == 2)
    800029d4:	4789                	li	a5,2
    800029d6:	f8f910e3          	bne	s2,a5,80002956 <usertrap+0x6e>
    yield();
    800029da:	00000097          	auipc	ra,0x0
    800029de:	8fc080e7          	jalr	-1796(ra) # 800022d6 <yield>
    800029e2:	bf95                	j	80002956 <usertrap+0x6e>
  int which_dev = 0;
    800029e4:	4901                	li	s2,0
    800029e6:	b7d5                	j	800029ca <usertrap+0xe2>

00000000800029e8 <kerneltrap>:
{
    800029e8:	7179                	addi	sp,sp,-48
    800029ea:	f406                	sd	ra,40(sp)
    800029ec:	f022                	sd	s0,32(sp)
    800029ee:	ec26                	sd	s1,24(sp)
    800029f0:	e84a                	sd	s2,16(sp)
    800029f2:	e44e                	sd	s3,8(sp)
    800029f4:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029f6:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029fa:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029fe:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a02:	1004f793          	andi	a5,s1,256
    80002a06:	cb85                	beqz	a5,80002a36 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a08:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a0c:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a0e:	ef85                	bnez	a5,80002a46 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a10:	00000097          	auipc	ra,0x0
    80002a14:	e46080e7          	jalr	-442(ra) # 80002856 <devintr>
    80002a18:	cd1d                	beqz	a0,80002a56 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a1a:	4789                	li	a5,2
    80002a1c:	06f50a63          	beq	a0,a5,80002a90 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a20:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a24:	10049073          	csrw	sstatus,s1
}
    80002a28:	70a2                	ld	ra,40(sp)
    80002a2a:	7402                	ld	s0,32(sp)
    80002a2c:	64e2                	ld	s1,24(sp)
    80002a2e:	6942                	ld	s2,16(sp)
    80002a30:	69a2                	ld	s3,8(sp)
    80002a32:	6145                	addi	sp,sp,48
    80002a34:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a36:	00006517          	auipc	a0,0x6
    80002a3a:	b4250513          	addi	a0,a0,-1214 # 80008578 <userret+0x4e8>
    80002a3e:	ffffe097          	auipc	ra,0xffffe
    80002a42:	b0a080e7          	jalr	-1270(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a46:	00006517          	auipc	a0,0x6
    80002a4a:	b5a50513          	addi	a0,a0,-1190 # 800085a0 <userret+0x510>
    80002a4e:	ffffe097          	auipc	ra,0xffffe
    80002a52:	afa080e7          	jalr	-1286(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002a56:	85ce                	mv	a1,s3
    80002a58:	00006517          	auipc	a0,0x6
    80002a5c:	b6850513          	addi	a0,a0,-1176 # 800085c0 <userret+0x530>
    80002a60:	ffffe097          	auipc	ra,0xffffe
    80002a64:	b42080e7          	jalr	-1214(ra) # 800005a2 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a68:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a6c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a70:	00006517          	auipc	a0,0x6
    80002a74:	b6050513          	addi	a0,a0,-1184 # 800085d0 <userret+0x540>
    80002a78:	ffffe097          	auipc	ra,0xffffe
    80002a7c:	b2a080e7          	jalr	-1238(ra) # 800005a2 <printf>
    panic("kerneltrap");
    80002a80:	00006517          	auipc	a0,0x6
    80002a84:	b6850513          	addi	a0,a0,-1176 # 800085e8 <userret+0x558>
    80002a88:	ffffe097          	auipc	ra,0xffffe
    80002a8c:	ac0080e7          	jalr	-1344(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a90:	fffff097          	auipc	ra,0xfffff
    80002a94:	0ac080e7          	jalr	172(ra) # 80001b3c <myproc>
    80002a98:	d541                	beqz	a0,80002a20 <kerneltrap+0x38>
    80002a9a:	fffff097          	auipc	ra,0xfffff
    80002a9e:	0a2080e7          	jalr	162(ra) # 80001b3c <myproc>
    80002aa2:	5118                	lw	a4,32(a0)
    80002aa4:	478d                	li	a5,3
    80002aa6:	f6f71de3          	bne	a4,a5,80002a20 <kerneltrap+0x38>
    yield();
    80002aaa:	00000097          	auipc	ra,0x0
    80002aae:	82c080e7          	jalr	-2004(ra) # 800022d6 <yield>
    80002ab2:	b7bd                	j	80002a20 <kerneltrap+0x38>

0000000080002ab4 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ab4:	1101                	addi	sp,sp,-32
    80002ab6:	ec06                	sd	ra,24(sp)
    80002ab8:	e822                	sd	s0,16(sp)
    80002aba:	e426                	sd	s1,8(sp)
    80002abc:	1000                	addi	s0,sp,32
    80002abe:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ac0:	fffff097          	auipc	ra,0xfffff
    80002ac4:	07c080e7          	jalr	124(ra) # 80001b3c <myproc>
  switch (n) {
    80002ac8:	4795                	li	a5,5
    80002aca:	0497e163          	bltu	a5,s1,80002b0c <argraw+0x58>
    80002ace:	048a                	slli	s1,s1,0x2
    80002ad0:	00006717          	auipc	a4,0x6
    80002ad4:	02070713          	addi	a4,a4,32 # 80008af0 <states.0+0x28>
    80002ad8:	94ba                	add	s1,s1,a4
    80002ada:	409c                	lw	a5,0(s1)
    80002adc:	97ba                	add	a5,a5,a4
    80002ade:	8782                	jr	a5
  case 0:
    return p->tf->a0;
    80002ae0:	713c                	ld	a5,96(a0)
    80002ae2:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->tf->a5;
  }
  panic("argraw");
  return -1;
}
    80002ae4:	60e2                	ld	ra,24(sp)
    80002ae6:	6442                	ld	s0,16(sp)
    80002ae8:	64a2                	ld	s1,8(sp)
    80002aea:	6105                	addi	sp,sp,32
    80002aec:	8082                	ret
    return p->tf->a1;
    80002aee:	713c                	ld	a5,96(a0)
    80002af0:	7fa8                	ld	a0,120(a5)
    80002af2:	bfcd                	j	80002ae4 <argraw+0x30>
    return p->tf->a2;
    80002af4:	713c                	ld	a5,96(a0)
    80002af6:	63c8                	ld	a0,128(a5)
    80002af8:	b7f5                	j	80002ae4 <argraw+0x30>
    return p->tf->a3;
    80002afa:	713c                	ld	a5,96(a0)
    80002afc:	67c8                	ld	a0,136(a5)
    80002afe:	b7dd                	j	80002ae4 <argraw+0x30>
    return p->tf->a4;
    80002b00:	713c                	ld	a5,96(a0)
    80002b02:	6bc8                	ld	a0,144(a5)
    80002b04:	b7c5                	j	80002ae4 <argraw+0x30>
    return p->tf->a5;
    80002b06:	713c                	ld	a5,96(a0)
    80002b08:	6fc8                	ld	a0,152(a5)
    80002b0a:	bfe9                	j	80002ae4 <argraw+0x30>
  panic("argraw");
    80002b0c:	00006517          	auipc	a0,0x6
    80002b10:	aec50513          	addi	a0,a0,-1300 # 800085f8 <userret+0x568>
    80002b14:	ffffe097          	auipc	ra,0xffffe
    80002b18:	a34080e7          	jalr	-1484(ra) # 80000548 <panic>

0000000080002b1c <fetchaddr>:
{
    80002b1c:	1101                	addi	sp,sp,-32
    80002b1e:	ec06                	sd	ra,24(sp)
    80002b20:	e822                	sd	s0,16(sp)
    80002b22:	e426                	sd	s1,8(sp)
    80002b24:	e04a                	sd	s2,0(sp)
    80002b26:	1000                	addi	s0,sp,32
    80002b28:	84aa                	mv	s1,a0
    80002b2a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b2c:	fffff097          	auipc	ra,0xfffff
    80002b30:	010080e7          	jalr	16(ra) # 80001b3c <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002b34:	693c                	ld	a5,80(a0)
    80002b36:	02f4f863          	bgeu	s1,a5,80002b66 <fetchaddr+0x4a>
    80002b3a:	00848713          	addi	a4,s1,8
    80002b3e:	02e7e663          	bltu	a5,a4,80002b6a <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b42:	46a1                	li	a3,8
    80002b44:	8626                	mv	a2,s1
    80002b46:	85ca                	mv	a1,s2
    80002b48:	6d28                	ld	a0,88(a0)
    80002b4a:	fffff097          	auipc	ra,0xfffff
    80002b4e:	d70080e7          	jalr	-656(ra) # 800018ba <copyin>
    80002b52:	00a03533          	snez	a0,a0
    80002b56:	40a00533          	neg	a0,a0
}
    80002b5a:	60e2                	ld	ra,24(sp)
    80002b5c:	6442                	ld	s0,16(sp)
    80002b5e:	64a2                	ld	s1,8(sp)
    80002b60:	6902                	ld	s2,0(sp)
    80002b62:	6105                	addi	sp,sp,32
    80002b64:	8082                	ret
    return -1;
    80002b66:	557d                	li	a0,-1
    80002b68:	bfcd                	j	80002b5a <fetchaddr+0x3e>
    80002b6a:	557d                	li	a0,-1
    80002b6c:	b7fd                	j	80002b5a <fetchaddr+0x3e>

0000000080002b6e <fetchstr>:
{
    80002b6e:	7179                	addi	sp,sp,-48
    80002b70:	f406                	sd	ra,40(sp)
    80002b72:	f022                	sd	s0,32(sp)
    80002b74:	ec26                	sd	s1,24(sp)
    80002b76:	e84a                	sd	s2,16(sp)
    80002b78:	e44e                	sd	s3,8(sp)
    80002b7a:	1800                	addi	s0,sp,48
    80002b7c:	892a                	mv	s2,a0
    80002b7e:	84ae                	mv	s1,a1
    80002b80:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b82:	fffff097          	auipc	ra,0xfffff
    80002b86:	fba080e7          	jalr	-70(ra) # 80001b3c <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b8a:	86ce                	mv	a3,s3
    80002b8c:	864a                	mv	a2,s2
    80002b8e:	85a6                	mv	a1,s1
    80002b90:	6d28                	ld	a0,88(a0)
    80002b92:	fffff097          	auipc	ra,0xfffff
    80002b96:	db6080e7          	jalr	-586(ra) # 80001948 <copyinstr>
  if(err < 0)
    80002b9a:	00054763          	bltz	a0,80002ba8 <fetchstr+0x3a>
  return strlen(buf);
    80002b9e:	8526                	mv	a0,s1
    80002ba0:	ffffe097          	auipc	ra,0xffffe
    80002ba4:	436080e7          	jalr	1078(ra) # 80000fd6 <strlen>
}
    80002ba8:	70a2                	ld	ra,40(sp)
    80002baa:	7402                	ld	s0,32(sp)
    80002bac:	64e2                	ld	s1,24(sp)
    80002bae:	6942                	ld	s2,16(sp)
    80002bb0:	69a2                	ld	s3,8(sp)
    80002bb2:	6145                	addi	sp,sp,48
    80002bb4:	8082                	ret

0000000080002bb6 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002bb6:	1101                	addi	sp,sp,-32
    80002bb8:	ec06                	sd	ra,24(sp)
    80002bba:	e822                	sd	s0,16(sp)
    80002bbc:	e426                	sd	s1,8(sp)
    80002bbe:	1000                	addi	s0,sp,32
    80002bc0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bc2:	00000097          	auipc	ra,0x0
    80002bc6:	ef2080e7          	jalr	-270(ra) # 80002ab4 <argraw>
    80002bca:	c088                	sw	a0,0(s1)
  return 0;
}
    80002bcc:	4501                	li	a0,0
    80002bce:	60e2                	ld	ra,24(sp)
    80002bd0:	6442                	ld	s0,16(sp)
    80002bd2:	64a2                	ld	s1,8(sp)
    80002bd4:	6105                	addi	sp,sp,32
    80002bd6:	8082                	ret

0000000080002bd8 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002bd8:	1101                	addi	sp,sp,-32
    80002bda:	ec06                	sd	ra,24(sp)
    80002bdc:	e822                	sd	s0,16(sp)
    80002bde:	e426                	sd	s1,8(sp)
    80002be0:	1000                	addi	s0,sp,32
    80002be2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002be4:	00000097          	auipc	ra,0x0
    80002be8:	ed0080e7          	jalr	-304(ra) # 80002ab4 <argraw>
    80002bec:	e088                	sd	a0,0(s1)
  return 0;
}
    80002bee:	4501                	li	a0,0
    80002bf0:	60e2                	ld	ra,24(sp)
    80002bf2:	6442                	ld	s0,16(sp)
    80002bf4:	64a2                	ld	s1,8(sp)
    80002bf6:	6105                	addi	sp,sp,32
    80002bf8:	8082                	ret

0000000080002bfa <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bfa:	1101                	addi	sp,sp,-32
    80002bfc:	ec06                	sd	ra,24(sp)
    80002bfe:	e822                	sd	s0,16(sp)
    80002c00:	e426                	sd	s1,8(sp)
    80002c02:	e04a                	sd	s2,0(sp)
    80002c04:	1000                	addi	s0,sp,32
    80002c06:	84ae                	mv	s1,a1
    80002c08:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c0a:	00000097          	auipc	ra,0x0
    80002c0e:	eaa080e7          	jalr	-342(ra) # 80002ab4 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c12:	864a                	mv	a2,s2
    80002c14:	85a6                	mv	a1,s1
    80002c16:	00000097          	auipc	ra,0x0
    80002c1a:	f58080e7          	jalr	-168(ra) # 80002b6e <fetchstr>
}
    80002c1e:	60e2                	ld	ra,24(sp)
    80002c20:	6442                	ld	s0,16(sp)
    80002c22:	64a2                	ld	s1,8(sp)
    80002c24:	6902                	ld	s2,0(sp)
    80002c26:	6105                	addi	sp,sp,32
    80002c28:	8082                	ret

0000000080002c2a <syscall>:
[SYS_ntas]    sys_ntas,
};

void
syscall(void)
{
    80002c2a:	1101                	addi	sp,sp,-32
    80002c2c:	ec06                	sd	ra,24(sp)
    80002c2e:	e822                	sd	s0,16(sp)
    80002c30:	e426                	sd	s1,8(sp)
    80002c32:	e04a                	sd	s2,0(sp)
    80002c34:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c36:	fffff097          	auipc	ra,0xfffff
    80002c3a:	f06080e7          	jalr	-250(ra) # 80001b3c <myproc>
    80002c3e:	84aa                	mv	s1,a0

  num = p->tf->a7;
    80002c40:	06053903          	ld	s2,96(a0)
    80002c44:	0a893783          	ld	a5,168(s2)
    80002c48:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c4c:	37fd                	addiw	a5,a5,-1
    80002c4e:	4755                	li	a4,21
    80002c50:	00f76f63          	bltu	a4,a5,80002c6e <syscall+0x44>
    80002c54:	00369713          	slli	a4,a3,0x3
    80002c58:	00006797          	auipc	a5,0x6
    80002c5c:	eb078793          	addi	a5,a5,-336 # 80008b08 <syscalls>
    80002c60:	97ba                	add	a5,a5,a4
    80002c62:	639c                	ld	a5,0(a5)
    80002c64:	c789                	beqz	a5,80002c6e <syscall+0x44>
    p->tf->a0 = syscalls[num]();
    80002c66:	9782                	jalr	a5
    80002c68:	06a93823          	sd	a0,112(s2)
    80002c6c:	a839                	j	80002c8a <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c6e:	16048613          	addi	a2,s1,352
    80002c72:	40ac                	lw	a1,64(s1)
    80002c74:	00006517          	auipc	a0,0x6
    80002c78:	98c50513          	addi	a0,a0,-1652 # 80008600 <userret+0x570>
    80002c7c:	ffffe097          	auipc	ra,0xffffe
    80002c80:	926080e7          	jalr	-1754(ra) # 800005a2 <printf>
            p->pid, p->name, num);
    p->tf->a0 = -1;
    80002c84:	70bc                	ld	a5,96(s1)
    80002c86:	577d                	li	a4,-1
    80002c88:	fbb8                	sd	a4,112(a5)
  }
}
    80002c8a:	60e2                	ld	ra,24(sp)
    80002c8c:	6442                	ld	s0,16(sp)
    80002c8e:	64a2                	ld	s1,8(sp)
    80002c90:	6902                	ld	s2,0(sp)
    80002c92:	6105                	addi	sp,sp,32
    80002c94:	8082                	ret

0000000080002c96 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c96:	1101                	addi	sp,sp,-32
    80002c98:	ec06                	sd	ra,24(sp)
    80002c9a:	e822                	sd	s0,16(sp)
    80002c9c:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c9e:	fec40593          	addi	a1,s0,-20
    80002ca2:	4501                	li	a0,0
    80002ca4:	00000097          	auipc	ra,0x0
    80002ca8:	f12080e7          	jalr	-238(ra) # 80002bb6 <argint>
    return -1;
    80002cac:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002cae:	00054963          	bltz	a0,80002cc0 <sys_exit+0x2a>
  exit(n);
    80002cb2:	fec42503          	lw	a0,-20(s0)
    80002cb6:	fffff097          	auipc	ra,0xfffff
    80002cba:	512080e7          	jalr	1298(ra) # 800021c8 <exit>
  return 0;  // not reached
    80002cbe:	4781                	li	a5,0
}
    80002cc0:	853e                	mv	a0,a5
    80002cc2:	60e2                	ld	ra,24(sp)
    80002cc4:	6442                	ld	s0,16(sp)
    80002cc6:	6105                	addi	sp,sp,32
    80002cc8:	8082                	ret

0000000080002cca <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cca:	1141                	addi	sp,sp,-16
    80002ccc:	e406                	sd	ra,8(sp)
    80002cce:	e022                	sd	s0,0(sp)
    80002cd0:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002cd2:	fffff097          	auipc	ra,0xfffff
    80002cd6:	e6a080e7          	jalr	-406(ra) # 80001b3c <myproc>
}
    80002cda:	4128                	lw	a0,64(a0)
    80002cdc:	60a2                	ld	ra,8(sp)
    80002cde:	6402                	ld	s0,0(sp)
    80002ce0:	0141                	addi	sp,sp,16
    80002ce2:	8082                	ret

0000000080002ce4 <sys_fork>:

uint64
sys_fork(void)
{
    80002ce4:	1141                	addi	sp,sp,-16
    80002ce6:	e406                	sd	ra,8(sp)
    80002ce8:	e022                	sd	s0,0(sp)
    80002cea:	0800                	addi	s0,sp,16
  return fork();
    80002cec:	fffff097          	auipc	ra,0xfffff
    80002cf0:	1ba080e7          	jalr	442(ra) # 80001ea6 <fork>
}
    80002cf4:	60a2                	ld	ra,8(sp)
    80002cf6:	6402                	ld	s0,0(sp)
    80002cf8:	0141                	addi	sp,sp,16
    80002cfa:	8082                	ret

0000000080002cfc <sys_wait>:

uint64
sys_wait(void)
{
    80002cfc:	1101                	addi	sp,sp,-32
    80002cfe:	ec06                	sd	ra,24(sp)
    80002d00:	e822                	sd	s0,16(sp)
    80002d02:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002d04:	fe840593          	addi	a1,s0,-24
    80002d08:	4501                	li	a0,0
    80002d0a:	00000097          	auipc	ra,0x0
    80002d0e:	ece080e7          	jalr	-306(ra) # 80002bd8 <argaddr>
    80002d12:	87aa                	mv	a5,a0
    return -1;
    80002d14:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002d16:	0007c863          	bltz	a5,80002d26 <sys_wait+0x2a>
  return wait(p);
    80002d1a:	fe843503          	ld	a0,-24(s0)
    80002d1e:	fffff097          	auipc	ra,0xfffff
    80002d22:	672080e7          	jalr	1650(ra) # 80002390 <wait>
}
    80002d26:	60e2                	ld	ra,24(sp)
    80002d28:	6442                	ld	s0,16(sp)
    80002d2a:	6105                	addi	sp,sp,32
    80002d2c:	8082                	ret

0000000080002d2e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d2e:	7179                	addi	sp,sp,-48
    80002d30:	f406                	sd	ra,40(sp)
    80002d32:	f022                	sd	s0,32(sp)
    80002d34:	ec26                	sd	s1,24(sp)
    80002d36:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d38:	fdc40593          	addi	a1,s0,-36
    80002d3c:	4501                	li	a0,0
    80002d3e:	00000097          	auipc	ra,0x0
    80002d42:	e78080e7          	jalr	-392(ra) # 80002bb6 <argint>
    return -1;
    80002d46:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002d48:	00054f63          	bltz	a0,80002d66 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002d4c:	fffff097          	auipc	ra,0xfffff
    80002d50:	df0080e7          	jalr	-528(ra) # 80001b3c <myproc>
    80002d54:	4924                	lw	s1,80(a0)
  if(growproc(n) < 0)
    80002d56:	fdc42503          	lw	a0,-36(s0)
    80002d5a:	fffff097          	auipc	ra,0xfffff
    80002d5e:	0d8080e7          	jalr	216(ra) # 80001e32 <growproc>
    80002d62:	00054863          	bltz	a0,80002d72 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002d66:	8526                	mv	a0,s1
    80002d68:	70a2                	ld	ra,40(sp)
    80002d6a:	7402                	ld	s0,32(sp)
    80002d6c:	64e2                	ld	s1,24(sp)
    80002d6e:	6145                	addi	sp,sp,48
    80002d70:	8082                	ret
    return -1;
    80002d72:	54fd                	li	s1,-1
    80002d74:	bfcd                	j	80002d66 <sys_sbrk+0x38>

0000000080002d76 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d76:	7139                	addi	sp,sp,-64
    80002d78:	fc06                	sd	ra,56(sp)
    80002d7a:	f822                	sd	s0,48(sp)
    80002d7c:	f426                	sd	s1,40(sp)
    80002d7e:	f04a                	sd	s2,32(sp)
    80002d80:	ec4e                	sd	s3,24(sp)
    80002d82:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d84:	fcc40593          	addi	a1,s0,-52
    80002d88:	4501                	li	a0,0
    80002d8a:	00000097          	auipc	ra,0x0
    80002d8e:	e2c080e7          	jalr	-468(ra) # 80002bb6 <argint>
    return -1;
    80002d92:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d94:	06054563          	bltz	a0,80002dfe <sys_sleep+0x88>
  acquire(&tickslock);
    80002d98:	00018517          	auipc	a0,0x18
    80002d9c:	be050513          	addi	a0,a0,-1056 # 8001a978 <tickslock>
    80002da0:	ffffe097          	auipc	ra,0xffffe
    80002da4:	e44080e7          	jalr	-444(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002da8:	00029917          	auipc	s2,0x29
    80002dac:	29892903          	lw	s2,664(s2) # 8002c040 <ticks>
  while(ticks - ticks0 < n){
    80002db0:	fcc42783          	lw	a5,-52(s0)
    80002db4:	cf85                	beqz	a5,80002dec <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002db6:	00018997          	auipc	s3,0x18
    80002dba:	bc298993          	addi	s3,s3,-1086 # 8001a978 <tickslock>
    80002dbe:	00029497          	auipc	s1,0x29
    80002dc2:	28248493          	addi	s1,s1,642 # 8002c040 <ticks>
    if(myproc()->killed){
    80002dc6:	fffff097          	auipc	ra,0xfffff
    80002dca:	d76080e7          	jalr	-650(ra) # 80001b3c <myproc>
    80002dce:	5d1c                	lw	a5,56(a0)
    80002dd0:	ef9d                	bnez	a5,80002e0e <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002dd2:	85ce                	mv	a1,s3
    80002dd4:	8526                	mv	a0,s1
    80002dd6:	fffff097          	auipc	ra,0xfffff
    80002dda:	53c080e7          	jalr	1340(ra) # 80002312 <sleep>
  while(ticks - ticks0 < n){
    80002dde:	409c                	lw	a5,0(s1)
    80002de0:	412787bb          	subw	a5,a5,s2
    80002de4:	fcc42703          	lw	a4,-52(s0)
    80002de8:	fce7efe3          	bltu	a5,a4,80002dc6 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002dec:	00018517          	auipc	a0,0x18
    80002df0:	b8c50513          	addi	a0,a0,-1140 # 8001a978 <tickslock>
    80002df4:	ffffe097          	auipc	ra,0xffffe
    80002df8:	e60080e7          	jalr	-416(ra) # 80000c54 <release>
  return 0;
    80002dfc:	4781                	li	a5,0
}
    80002dfe:	853e                	mv	a0,a5
    80002e00:	70e2                	ld	ra,56(sp)
    80002e02:	7442                	ld	s0,48(sp)
    80002e04:	74a2                	ld	s1,40(sp)
    80002e06:	7902                	ld	s2,32(sp)
    80002e08:	69e2                	ld	s3,24(sp)
    80002e0a:	6121                	addi	sp,sp,64
    80002e0c:	8082                	ret
      release(&tickslock);
    80002e0e:	00018517          	auipc	a0,0x18
    80002e12:	b6a50513          	addi	a0,a0,-1174 # 8001a978 <tickslock>
    80002e16:	ffffe097          	auipc	ra,0xffffe
    80002e1a:	e3e080e7          	jalr	-450(ra) # 80000c54 <release>
      return -1;
    80002e1e:	57fd                	li	a5,-1
    80002e20:	bff9                	j	80002dfe <sys_sleep+0x88>

0000000080002e22 <sys_kill>:

uint64
sys_kill(void)
{
    80002e22:	1101                	addi	sp,sp,-32
    80002e24:	ec06                	sd	ra,24(sp)
    80002e26:	e822                	sd	s0,16(sp)
    80002e28:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e2a:	fec40593          	addi	a1,s0,-20
    80002e2e:	4501                	li	a0,0
    80002e30:	00000097          	auipc	ra,0x0
    80002e34:	d86080e7          	jalr	-634(ra) # 80002bb6 <argint>
    80002e38:	87aa                	mv	a5,a0
    return -1;
    80002e3a:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e3c:	0007c863          	bltz	a5,80002e4c <sys_kill+0x2a>
  return kill(pid);
    80002e40:	fec42503          	lw	a0,-20(s0)
    80002e44:	fffff097          	auipc	ra,0xfffff
    80002e48:	6b8080e7          	jalr	1720(ra) # 800024fc <kill>
}
    80002e4c:	60e2                	ld	ra,24(sp)
    80002e4e:	6442                	ld	s0,16(sp)
    80002e50:	6105                	addi	sp,sp,32
    80002e52:	8082                	ret

0000000080002e54 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e54:	1101                	addi	sp,sp,-32
    80002e56:	ec06                	sd	ra,24(sp)
    80002e58:	e822                	sd	s0,16(sp)
    80002e5a:	e426                	sd	s1,8(sp)
    80002e5c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e5e:	00018517          	auipc	a0,0x18
    80002e62:	b1a50513          	addi	a0,a0,-1254 # 8001a978 <tickslock>
    80002e66:	ffffe097          	auipc	ra,0xffffe
    80002e6a:	d7e080e7          	jalr	-642(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002e6e:	00029497          	auipc	s1,0x29
    80002e72:	1d24a483          	lw	s1,466(s1) # 8002c040 <ticks>
  release(&tickslock);
    80002e76:	00018517          	auipc	a0,0x18
    80002e7a:	b0250513          	addi	a0,a0,-1278 # 8001a978 <tickslock>
    80002e7e:	ffffe097          	auipc	ra,0xffffe
    80002e82:	dd6080e7          	jalr	-554(ra) # 80000c54 <release>
  return xticks;
}
    80002e86:	02049513          	slli	a0,s1,0x20
    80002e8a:	9101                	srli	a0,a0,0x20
    80002e8c:	60e2                	ld	ra,24(sp)
    80002e8e:	6442                	ld	s0,16(sp)
    80002e90:	64a2                	ld	s1,8(sp)
    80002e92:	6105                	addi	sp,sp,32
    80002e94:	8082                	ret

0000000080002e96 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e96:	7179                	addi	sp,sp,-48
    80002e98:	f406                	sd	ra,40(sp)
    80002e9a:	f022                	sd	s0,32(sp)
    80002e9c:	ec26                	sd	s1,24(sp)
    80002e9e:	e84a                	sd	s2,16(sp)
    80002ea0:	e44e                	sd	s3,8(sp)
    80002ea2:	e052                	sd	s4,0(sp)
    80002ea4:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ea6:	00005597          	auipc	a1,0x5
    80002eaa:	41258593          	addi	a1,a1,1042 # 800082b8 <userret+0x228>
    80002eae:	00018517          	auipc	a0,0x18
    80002eb2:	aea50513          	addi	a0,a0,-1302 # 8001a998 <bcache>
    80002eb6:	ffffe097          	auipc	ra,0xffffe
    80002eba:	be0080e7          	jalr	-1056(ra) # 80000a96 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002ebe:	00020797          	auipc	a5,0x20
    80002ec2:	ada78793          	addi	a5,a5,-1318 # 80022998 <bcache+0x8000>
    80002ec6:	00020717          	auipc	a4,0x20
    80002eca:	e3270713          	addi	a4,a4,-462 # 80022cf8 <bcache+0x8360>
    80002ece:	3ae7b823          	sd	a4,944(a5)
  bcache.head.next = &bcache.head;
    80002ed2:	3ae7bc23          	sd	a4,952(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ed6:	00018497          	auipc	s1,0x18
    80002eda:	ae248493          	addi	s1,s1,-1310 # 8001a9b8 <bcache+0x20>
    b->next = bcache.head.next;
    80002ede:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002ee0:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002ee2:	00005a17          	auipc	s4,0x5
    80002ee6:	73ea0a13          	addi	s4,s4,1854 # 80008620 <userret+0x590>
    b->next = bcache.head.next;
    80002eea:	3b893783          	ld	a5,952(s2)
    80002eee:	ecbc                	sd	a5,88(s1)
    b->prev = &bcache.head;
    80002ef0:	0534b823          	sd	s3,80(s1)
    initsleeplock(&b->lock, "buffer");
    80002ef4:	85d2                	mv	a1,s4
    80002ef6:	01048513          	addi	a0,s1,16
    80002efa:	00001097          	auipc	ra,0x1
    80002efe:	5a4080e7          	jalr	1444(ra) # 8000449e <initsleeplock>
    bcache.head.next->prev = b;
    80002f02:	3b893783          	ld	a5,952(s2)
    80002f06:	eba4                	sd	s1,80(a5)
    bcache.head.next = b;
    80002f08:	3a993c23          	sd	s1,952(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f0c:	46048493          	addi	s1,s1,1120
    80002f10:	fd349de3          	bne	s1,s3,80002eea <binit+0x54>
  }
}
    80002f14:	70a2                	ld	ra,40(sp)
    80002f16:	7402                	ld	s0,32(sp)
    80002f18:	64e2                	ld	s1,24(sp)
    80002f1a:	6942                	ld	s2,16(sp)
    80002f1c:	69a2                	ld	s3,8(sp)
    80002f1e:	6a02                	ld	s4,0(sp)
    80002f20:	6145                	addi	sp,sp,48
    80002f22:	8082                	ret

0000000080002f24 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f24:	7179                	addi	sp,sp,-48
    80002f26:	f406                	sd	ra,40(sp)
    80002f28:	f022                	sd	s0,32(sp)
    80002f2a:	ec26                	sd	s1,24(sp)
    80002f2c:	e84a                	sd	s2,16(sp)
    80002f2e:	e44e                	sd	s3,8(sp)
    80002f30:	1800                	addi	s0,sp,48
    80002f32:	892a                	mv	s2,a0
    80002f34:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002f36:	00018517          	auipc	a0,0x18
    80002f3a:	a6250513          	addi	a0,a0,-1438 # 8001a998 <bcache>
    80002f3e:	ffffe097          	auipc	ra,0xffffe
    80002f42:	ca6080e7          	jalr	-858(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f46:	00020497          	auipc	s1,0x20
    80002f4a:	e0a4b483          	ld	s1,-502(s1) # 80022d50 <bcache+0x83b8>
    80002f4e:	00020797          	auipc	a5,0x20
    80002f52:	daa78793          	addi	a5,a5,-598 # 80022cf8 <bcache+0x8360>
    80002f56:	02f48f63          	beq	s1,a5,80002f94 <bread+0x70>
    80002f5a:	873e                	mv	a4,a5
    80002f5c:	a021                	j	80002f64 <bread+0x40>
    80002f5e:	6ca4                	ld	s1,88(s1)
    80002f60:	02e48a63          	beq	s1,a4,80002f94 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f64:	449c                	lw	a5,8(s1)
    80002f66:	ff279ce3          	bne	a5,s2,80002f5e <bread+0x3a>
    80002f6a:	44dc                	lw	a5,12(s1)
    80002f6c:	ff3799e3          	bne	a5,s3,80002f5e <bread+0x3a>
      b->refcnt++;
    80002f70:	44bc                	lw	a5,72(s1)
    80002f72:	2785                	addiw	a5,a5,1
    80002f74:	c4bc                	sw	a5,72(s1)
      release(&bcache.lock);
    80002f76:	00018517          	auipc	a0,0x18
    80002f7a:	a2250513          	addi	a0,a0,-1502 # 8001a998 <bcache>
    80002f7e:	ffffe097          	auipc	ra,0xffffe
    80002f82:	cd6080e7          	jalr	-810(ra) # 80000c54 <release>
      acquiresleep(&b->lock);
    80002f86:	01048513          	addi	a0,s1,16
    80002f8a:	00001097          	auipc	ra,0x1
    80002f8e:	54e080e7          	jalr	1358(ra) # 800044d8 <acquiresleep>
      return b;
    80002f92:	a8b9                	j	80002ff0 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f94:	00020497          	auipc	s1,0x20
    80002f98:	db44b483          	ld	s1,-588(s1) # 80022d48 <bcache+0x83b0>
    80002f9c:	00020797          	auipc	a5,0x20
    80002fa0:	d5c78793          	addi	a5,a5,-676 # 80022cf8 <bcache+0x8360>
    80002fa4:	00f48863          	beq	s1,a5,80002fb4 <bread+0x90>
    80002fa8:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002faa:	44bc                	lw	a5,72(s1)
    80002fac:	cf81                	beqz	a5,80002fc4 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fae:	68a4                	ld	s1,80(s1)
    80002fb0:	fee49de3          	bne	s1,a4,80002faa <bread+0x86>
  panic("bget: no buffers");
    80002fb4:	00005517          	auipc	a0,0x5
    80002fb8:	67450513          	addi	a0,a0,1652 # 80008628 <userret+0x598>
    80002fbc:	ffffd097          	auipc	ra,0xffffd
    80002fc0:	58c080e7          	jalr	1420(ra) # 80000548 <panic>
      b->dev = dev;
    80002fc4:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002fc8:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002fcc:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002fd0:	4785                	li	a5,1
    80002fd2:	c4bc                	sw	a5,72(s1)
      release(&bcache.lock);
    80002fd4:	00018517          	auipc	a0,0x18
    80002fd8:	9c450513          	addi	a0,a0,-1596 # 8001a998 <bcache>
    80002fdc:	ffffe097          	auipc	ra,0xffffe
    80002fe0:	c78080e7          	jalr	-904(ra) # 80000c54 <release>
      acquiresleep(&b->lock);
    80002fe4:	01048513          	addi	a0,s1,16
    80002fe8:	00001097          	auipc	ra,0x1
    80002fec:	4f0080e7          	jalr	1264(ra) # 800044d8 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002ff0:	409c                	lw	a5,0(s1)
    80002ff2:	cb89                	beqz	a5,80003004 <bread+0xe0>
    virtio_disk_rw(b->dev, b, 0);
    b->valid = 1;
  }
  return b;
}
    80002ff4:	8526                	mv	a0,s1
    80002ff6:	70a2                	ld	ra,40(sp)
    80002ff8:	7402                	ld	s0,32(sp)
    80002ffa:	64e2                	ld	s1,24(sp)
    80002ffc:	6942                	ld	s2,16(sp)
    80002ffe:	69a2                	ld	s3,8(sp)
    80003000:	6145                	addi	sp,sp,48
    80003002:	8082                	ret
    virtio_disk_rw(b->dev, b, 0);
    80003004:	4601                	li	a2,0
    80003006:	85a6                	mv	a1,s1
    80003008:	4488                	lw	a0,8(s1)
    8000300a:	00003097          	auipc	ra,0x3
    8000300e:	110080e7          	jalr	272(ra) # 8000611a <virtio_disk_rw>
    b->valid = 1;
    80003012:	4785                	li	a5,1
    80003014:	c09c                	sw	a5,0(s1)
  return b;
    80003016:	bff9                	j	80002ff4 <bread+0xd0>

0000000080003018 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003018:	1101                	addi	sp,sp,-32
    8000301a:	ec06                	sd	ra,24(sp)
    8000301c:	e822                	sd	s0,16(sp)
    8000301e:	e426                	sd	s1,8(sp)
    80003020:	1000                	addi	s0,sp,32
    80003022:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003024:	0541                	addi	a0,a0,16
    80003026:	00001097          	auipc	ra,0x1
    8000302a:	54c080e7          	jalr	1356(ra) # 80004572 <holdingsleep>
    8000302e:	cd09                	beqz	a0,80003048 <bwrite+0x30>
    panic("bwrite");
  virtio_disk_rw(b->dev, b, 1);
    80003030:	4605                	li	a2,1
    80003032:	85a6                	mv	a1,s1
    80003034:	4488                	lw	a0,8(s1)
    80003036:	00003097          	auipc	ra,0x3
    8000303a:	0e4080e7          	jalr	228(ra) # 8000611a <virtio_disk_rw>
}
    8000303e:	60e2                	ld	ra,24(sp)
    80003040:	6442                	ld	s0,16(sp)
    80003042:	64a2                	ld	s1,8(sp)
    80003044:	6105                	addi	sp,sp,32
    80003046:	8082                	ret
    panic("bwrite");
    80003048:	00005517          	auipc	a0,0x5
    8000304c:	5f850513          	addi	a0,a0,1528 # 80008640 <userret+0x5b0>
    80003050:	ffffd097          	auipc	ra,0xffffd
    80003054:	4f8080e7          	jalr	1272(ra) # 80000548 <panic>

0000000080003058 <brelse>:

// Release a locked buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
    80003058:	1101                	addi	sp,sp,-32
    8000305a:	ec06                	sd	ra,24(sp)
    8000305c:	e822                	sd	s0,16(sp)
    8000305e:	e426                	sd	s1,8(sp)
    80003060:	e04a                	sd	s2,0(sp)
    80003062:	1000                	addi	s0,sp,32
    80003064:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003066:	01050913          	addi	s2,a0,16
    8000306a:	854a                	mv	a0,s2
    8000306c:	00001097          	auipc	ra,0x1
    80003070:	506080e7          	jalr	1286(ra) # 80004572 <holdingsleep>
    80003074:	c92d                	beqz	a0,800030e6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003076:	854a                	mv	a0,s2
    80003078:	00001097          	auipc	ra,0x1
    8000307c:	4b6080e7          	jalr	1206(ra) # 8000452e <releasesleep>

  acquire(&bcache.lock);
    80003080:	00018517          	auipc	a0,0x18
    80003084:	91850513          	addi	a0,a0,-1768 # 8001a998 <bcache>
    80003088:	ffffe097          	auipc	ra,0xffffe
    8000308c:	b5c080e7          	jalr	-1188(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003090:	44bc                	lw	a5,72(s1)
    80003092:	37fd                	addiw	a5,a5,-1
    80003094:	0007871b          	sext.w	a4,a5
    80003098:	c4bc                	sw	a5,72(s1)
  if (b->refcnt == 0) {
    8000309a:	eb05                	bnez	a4,800030ca <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000309c:	6cbc                	ld	a5,88(s1)
    8000309e:	68b8                	ld	a4,80(s1)
    800030a0:	ebb8                	sd	a4,80(a5)
    b->prev->next = b->next;
    800030a2:	68bc                	ld	a5,80(s1)
    800030a4:	6cb8                	ld	a4,88(s1)
    800030a6:	efb8                	sd	a4,88(a5)
    b->next = bcache.head.next;
    800030a8:	00020797          	auipc	a5,0x20
    800030ac:	8f078793          	addi	a5,a5,-1808 # 80022998 <bcache+0x8000>
    800030b0:	3b87b703          	ld	a4,952(a5)
    800030b4:	ecb8                	sd	a4,88(s1)
    b->prev = &bcache.head;
    800030b6:	00020717          	auipc	a4,0x20
    800030ba:	c4270713          	addi	a4,a4,-958 # 80022cf8 <bcache+0x8360>
    800030be:	e8b8                	sd	a4,80(s1)
    bcache.head.next->prev = b;
    800030c0:	3b87b703          	ld	a4,952(a5)
    800030c4:	eb24                	sd	s1,80(a4)
    bcache.head.next = b;
    800030c6:	3a97bc23          	sd	s1,952(a5)
  }
  
  release(&bcache.lock);
    800030ca:	00018517          	auipc	a0,0x18
    800030ce:	8ce50513          	addi	a0,a0,-1842 # 8001a998 <bcache>
    800030d2:	ffffe097          	auipc	ra,0xffffe
    800030d6:	b82080e7          	jalr	-1150(ra) # 80000c54 <release>
}
    800030da:	60e2                	ld	ra,24(sp)
    800030dc:	6442                	ld	s0,16(sp)
    800030de:	64a2                	ld	s1,8(sp)
    800030e0:	6902                	ld	s2,0(sp)
    800030e2:	6105                	addi	sp,sp,32
    800030e4:	8082                	ret
    panic("brelse");
    800030e6:	00005517          	auipc	a0,0x5
    800030ea:	56250513          	addi	a0,a0,1378 # 80008648 <userret+0x5b8>
    800030ee:	ffffd097          	auipc	ra,0xffffd
    800030f2:	45a080e7          	jalr	1114(ra) # 80000548 <panic>

00000000800030f6 <bpin>:

void
bpin(struct buf *b) {
    800030f6:	1101                	addi	sp,sp,-32
    800030f8:	ec06                	sd	ra,24(sp)
    800030fa:	e822                	sd	s0,16(sp)
    800030fc:	e426                	sd	s1,8(sp)
    800030fe:	1000                	addi	s0,sp,32
    80003100:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003102:	00018517          	auipc	a0,0x18
    80003106:	89650513          	addi	a0,a0,-1898 # 8001a998 <bcache>
    8000310a:	ffffe097          	auipc	ra,0xffffe
    8000310e:	ada080e7          	jalr	-1318(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003112:	44bc                	lw	a5,72(s1)
    80003114:	2785                	addiw	a5,a5,1
    80003116:	c4bc                	sw	a5,72(s1)
  release(&bcache.lock);
    80003118:	00018517          	auipc	a0,0x18
    8000311c:	88050513          	addi	a0,a0,-1920 # 8001a998 <bcache>
    80003120:	ffffe097          	auipc	ra,0xffffe
    80003124:	b34080e7          	jalr	-1228(ra) # 80000c54 <release>
}
    80003128:	60e2                	ld	ra,24(sp)
    8000312a:	6442                	ld	s0,16(sp)
    8000312c:	64a2                	ld	s1,8(sp)
    8000312e:	6105                	addi	sp,sp,32
    80003130:	8082                	ret

0000000080003132 <bunpin>:

void
bunpin(struct buf *b) {
    80003132:	1101                	addi	sp,sp,-32
    80003134:	ec06                	sd	ra,24(sp)
    80003136:	e822                	sd	s0,16(sp)
    80003138:	e426                	sd	s1,8(sp)
    8000313a:	1000                	addi	s0,sp,32
    8000313c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000313e:	00018517          	auipc	a0,0x18
    80003142:	85a50513          	addi	a0,a0,-1958 # 8001a998 <bcache>
    80003146:	ffffe097          	auipc	ra,0xffffe
    8000314a:	a9e080e7          	jalr	-1378(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000314e:	44bc                	lw	a5,72(s1)
    80003150:	37fd                	addiw	a5,a5,-1
    80003152:	c4bc                	sw	a5,72(s1)
  release(&bcache.lock);
    80003154:	00018517          	auipc	a0,0x18
    80003158:	84450513          	addi	a0,a0,-1980 # 8001a998 <bcache>
    8000315c:	ffffe097          	auipc	ra,0xffffe
    80003160:	af8080e7          	jalr	-1288(ra) # 80000c54 <release>
}
    80003164:	60e2                	ld	ra,24(sp)
    80003166:	6442                	ld	s0,16(sp)
    80003168:	64a2                	ld	s1,8(sp)
    8000316a:	6105                	addi	sp,sp,32
    8000316c:	8082                	ret

000000008000316e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000316e:	1101                	addi	sp,sp,-32
    80003170:	ec06                	sd	ra,24(sp)
    80003172:	e822                	sd	s0,16(sp)
    80003174:	e426                	sd	s1,8(sp)
    80003176:	e04a                	sd	s2,0(sp)
    80003178:	1000                	addi	s0,sp,32
    8000317a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000317c:	00d5d59b          	srliw	a1,a1,0xd
    80003180:	00020797          	auipc	a5,0x20
    80003184:	ff47a783          	lw	a5,-12(a5) # 80023174 <sb+0x1c>
    80003188:	9dbd                	addw	a1,a1,a5
    8000318a:	00000097          	auipc	ra,0x0
    8000318e:	d9a080e7          	jalr	-614(ra) # 80002f24 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003192:	0074f713          	andi	a4,s1,7
    80003196:	4785                	li	a5,1
    80003198:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000319c:	14ce                	slli	s1,s1,0x33
    8000319e:	90d9                	srli	s1,s1,0x36
    800031a0:	00950733          	add	a4,a0,s1
    800031a4:	06074703          	lbu	a4,96(a4)
    800031a8:	00e7f6b3          	and	a3,a5,a4
    800031ac:	c69d                	beqz	a3,800031da <bfree+0x6c>
    800031ae:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031b0:	94aa                	add	s1,s1,a0
    800031b2:	fff7c793          	not	a5,a5
    800031b6:	8ff9                	and	a5,a5,a4
    800031b8:	06f48023          	sb	a5,96(s1)
  log_write(bp);
    800031bc:	00001097          	auipc	ra,0x1
    800031c0:	1a2080e7          	jalr	418(ra) # 8000435e <log_write>
  brelse(bp);
    800031c4:	854a                	mv	a0,s2
    800031c6:	00000097          	auipc	ra,0x0
    800031ca:	e92080e7          	jalr	-366(ra) # 80003058 <brelse>
}
    800031ce:	60e2                	ld	ra,24(sp)
    800031d0:	6442                	ld	s0,16(sp)
    800031d2:	64a2                	ld	s1,8(sp)
    800031d4:	6902                	ld	s2,0(sp)
    800031d6:	6105                	addi	sp,sp,32
    800031d8:	8082                	ret
    panic("freeing free block");
    800031da:	00005517          	auipc	a0,0x5
    800031de:	47650513          	addi	a0,a0,1142 # 80008650 <userret+0x5c0>
    800031e2:	ffffd097          	auipc	ra,0xffffd
    800031e6:	366080e7          	jalr	870(ra) # 80000548 <panic>

00000000800031ea <balloc>:
{
    800031ea:	711d                	addi	sp,sp,-96
    800031ec:	ec86                	sd	ra,88(sp)
    800031ee:	e8a2                	sd	s0,80(sp)
    800031f0:	e4a6                	sd	s1,72(sp)
    800031f2:	e0ca                	sd	s2,64(sp)
    800031f4:	fc4e                	sd	s3,56(sp)
    800031f6:	f852                	sd	s4,48(sp)
    800031f8:	f456                	sd	s5,40(sp)
    800031fa:	f05a                	sd	s6,32(sp)
    800031fc:	ec5e                	sd	s7,24(sp)
    800031fe:	e862                	sd	s8,16(sp)
    80003200:	e466                	sd	s9,8(sp)
    80003202:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003204:	00020797          	auipc	a5,0x20
    80003208:	f587a783          	lw	a5,-168(a5) # 8002315c <sb+0x4>
    8000320c:	cbd1                	beqz	a5,800032a0 <balloc+0xb6>
    8000320e:	8baa                	mv	s7,a0
    80003210:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003212:	00020b17          	auipc	s6,0x20
    80003216:	f46b0b13          	addi	s6,s6,-186 # 80023158 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000321a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000321c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000321e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003220:	6c89                	lui	s9,0x2
    80003222:	a831                	j	8000323e <balloc+0x54>
    brelse(bp);
    80003224:	854a                	mv	a0,s2
    80003226:	00000097          	auipc	ra,0x0
    8000322a:	e32080e7          	jalr	-462(ra) # 80003058 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000322e:	015c87bb          	addw	a5,s9,s5
    80003232:	00078a9b          	sext.w	s5,a5
    80003236:	004b2703          	lw	a4,4(s6)
    8000323a:	06eaf363          	bgeu	s5,a4,800032a0 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000323e:	41fad79b          	sraiw	a5,s5,0x1f
    80003242:	0137d79b          	srliw	a5,a5,0x13
    80003246:	015787bb          	addw	a5,a5,s5
    8000324a:	40d7d79b          	sraiw	a5,a5,0xd
    8000324e:	01cb2583          	lw	a1,28(s6)
    80003252:	9dbd                	addw	a1,a1,a5
    80003254:	855e                	mv	a0,s7
    80003256:	00000097          	auipc	ra,0x0
    8000325a:	cce080e7          	jalr	-818(ra) # 80002f24 <bread>
    8000325e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003260:	004b2503          	lw	a0,4(s6)
    80003264:	000a849b          	sext.w	s1,s5
    80003268:	8662                	mv	a2,s8
    8000326a:	faa4fde3          	bgeu	s1,a0,80003224 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000326e:	41f6579b          	sraiw	a5,a2,0x1f
    80003272:	01d7d69b          	srliw	a3,a5,0x1d
    80003276:	00c6873b          	addw	a4,a3,a2
    8000327a:	00777793          	andi	a5,a4,7
    8000327e:	9f95                	subw	a5,a5,a3
    80003280:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003284:	4037571b          	sraiw	a4,a4,0x3
    80003288:	00e906b3          	add	a3,s2,a4
    8000328c:	0606c683          	lbu	a3,96(a3)
    80003290:	00d7f5b3          	and	a1,a5,a3
    80003294:	cd91                	beqz	a1,800032b0 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003296:	2605                	addiw	a2,a2,1
    80003298:	2485                	addiw	s1,s1,1
    8000329a:	fd4618e3          	bne	a2,s4,8000326a <balloc+0x80>
    8000329e:	b759                	j	80003224 <balloc+0x3a>
  panic("balloc: out of blocks");
    800032a0:	00005517          	auipc	a0,0x5
    800032a4:	3c850513          	addi	a0,a0,968 # 80008668 <userret+0x5d8>
    800032a8:	ffffd097          	auipc	ra,0xffffd
    800032ac:	2a0080e7          	jalr	672(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032b0:	974a                	add	a4,a4,s2
    800032b2:	8fd5                	or	a5,a5,a3
    800032b4:	06f70023          	sb	a5,96(a4)
        log_write(bp);
    800032b8:	854a                	mv	a0,s2
    800032ba:	00001097          	auipc	ra,0x1
    800032be:	0a4080e7          	jalr	164(ra) # 8000435e <log_write>
        brelse(bp);
    800032c2:	854a                	mv	a0,s2
    800032c4:	00000097          	auipc	ra,0x0
    800032c8:	d94080e7          	jalr	-620(ra) # 80003058 <brelse>
  bp = bread(dev, bno);
    800032cc:	85a6                	mv	a1,s1
    800032ce:	855e                	mv	a0,s7
    800032d0:	00000097          	auipc	ra,0x0
    800032d4:	c54080e7          	jalr	-940(ra) # 80002f24 <bread>
    800032d8:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032da:	40000613          	li	a2,1024
    800032de:	4581                	li	a1,0
    800032e0:	06050513          	addi	a0,a0,96
    800032e4:	ffffe097          	auipc	ra,0xffffe
    800032e8:	b6e080e7          	jalr	-1170(ra) # 80000e52 <memset>
  log_write(bp);
    800032ec:	854a                	mv	a0,s2
    800032ee:	00001097          	auipc	ra,0x1
    800032f2:	070080e7          	jalr	112(ra) # 8000435e <log_write>
  brelse(bp);
    800032f6:	854a                	mv	a0,s2
    800032f8:	00000097          	auipc	ra,0x0
    800032fc:	d60080e7          	jalr	-672(ra) # 80003058 <brelse>
}
    80003300:	8526                	mv	a0,s1
    80003302:	60e6                	ld	ra,88(sp)
    80003304:	6446                	ld	s0,80(sp)
    80003306:	64a6                	ld	s1,72(sp)
    80003308:	6906                	ld	s2,64(sp)
    8000330a:	79e2                	ld	s3,56(sp)
    8000330c:	7a42                	ld	s4,48(sp)
    8000330e:	7aa2                	ld	s5,40(sp)
    80003310:	7b02                	ld	s6,32(sp)
    80003312:	6be2                	ld	s7,24(sp)
    80003314:	6c42                	ld	s8,16(sp)
    80003316:	6ca2                	ld	s9,8(sp)
    80003318:	6125                	addi	sp,sp,96
    8000331a:	8082                	ret

000000008000331c <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000331c:	7179                	addi	sp,sp,-48
    8000331e:	f406                	sd	ra,40(sp)
    80003320:	f022                	sd	s0,32(sp)
    80003322:	ec26                	sd	s1,24(sp)
    80003324:	e84a                	sd	s2,16(sp)
    80003326:	e44e                	sd	s3,8(sp)
    80003328:	e052                	sd	s4,0(sp)
    8000332a:	1800                	addi	s0,sp,48
    8000332c:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000332e:	47ad                	li	a5,11
    80003330:	04b7fe63          	bgeu	a5,a1,8000338c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003334:	ff45849b          	addiw	s1,a1,-12
    80003338:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000333c:	0ff00793          	li	a5,255
    80003340:	0ae7e463          	bltu	a5,a4,800033e8 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003344:	08852583          	lw	a1,136(a0)
    80003348:	c5b5                	beqz	a1,800033b4 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000334a:	00092503          	lw	a0,0(s2)
    8000334e:	00000097          	auipc	ra,0x0
    80003352:	bd6080e7          	jalr	-1066(ra) # 80002f24 <bread>
    80003356:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003358:	06050793          	addi	a5,a0,96
    if((addr = a[bn]) == 0){
    8000335c:	02049713          	slli	a4,s1,0x20
    80003360:	01e75593          	srli	a1,a4,0x1e
    80003364:	00b784b3          	add	s1,a5,a1
    80003368:	0004a983          	lw	s3,0(s1)
    8000336c:	04098e63          	beqz	s3,800033c8 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003370:	8552                	mv	a0,s4
    80003372:	00000097          	auipc	ra,0x0
    80003376:	ce6080e7          	jalr	-794(ra) # 80003058 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000337a:	854e                	mv	a0,s3
    8000337c:	70a2                	ld	ra,40(sp)
    8000337e:	7402                	ld	s0,32(sp)
    80003380:	64e2                	ld	s1,24(sp)
    80003382:	6942                	ld	s2,16(sp)
    80003384:	69a2                	ld	s3,8(sp)
    80003386:	6a02                	ld	s4,0(sp)
    80003388:	6145                	addi	sp,sp,48
    8000338a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000338c:	02059793          	slli	a5,a1,0x20
    80003390:	01e7d593          	srli	a1,a5,0x1e
    80003394:	00b504b3          	add	s1,a0,a1
    80003398:	0584a983          	lw	s3,88(s1)
    8000339c:	fc099fe3          	bnez	s3,8000337a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800033a0:	4108                	lw	a0,0(a0)
    800033a2:	00000097          	auipc	ra,0x0
    800033a6:	e48080e7          	jalr	-440(ra) # 800031ea <balloc>
    800033aa:	0005099b          	sext.w	s3,a0
    800033ae:	0534ac23          	sw	s3,88(s1)
    800033b2:	b7e1                	j	8000337a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800033b4:	4108                	lw	a0,0(a0)
    800033b6:	00000097          	auipc	ra,0x0
    800033ba:	e34080e7          	jalr	-460(ra) # 800031ea <balloc>
    800033be:	0005059b          	sext.w	a1,a0
    800033c2:	08b92423          	sw	a1,136(s2)
    800033c6:	b751                	j	8000334a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800033c8:	00092503          	lw	a0,0(s2)
    800033cc:	00000097          	auipc	ra,0x0
    800033d0:	e1e080e7          	jalr	-482(ra) # 800031ea <balloc>
    800033d4:	0005099b          	sext.w	s3,a0
    800033d8:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800033dc:	8552                	mv	a0,s4
    800033de:	00001097          	auipc	ra,0x1
    800033e2:	f80080e7          	jalr	-128(ra) # 8000435e <log_write>
    800033e6:	b769                	j	80003370 <bmap+0x54>
  panic("bmap: out of range");
    800033e8:	00005517          	auipc	a0,0x5
    800033ec:	29850513          	addi	a0,a0,664 # 80008680 <userret+0x5f0>
    800033f0:	ffffd097          	auipc	ra,0xffffd
    800033f4:	158080e7          	jalr	344(ra) # 80000548 <panic>

00000000800033f8 <iget>:
{
    800033f8:	7179                	addi	sp,sp,-48
    800033fa:	f406                	sd	ra,40(sp)
    800033fc:	f022                	sd	s0,32(sp)
    800033fe:	ec26                	sd	s1,24(sp)
    80003400:	e84a                	sd	s2,16(sp)
    80003402:	e44e                	sd	s3,8(sp)
    80003404:	e052                	sd	s4,0(sp)
    80003406:	1800                	addi	s0,sp,48
    80003408:	89aa                	mv	s3,a0
    8000340a:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000340c:	00020517          	auipc	a0,0x20
    80003410:	d6c50513          	addi	a0,a0,-660 # 80023178 <icache>
    80003414:	ffffd097          	auipc	ra,0xffffd
    80003418:	7d0080e7          	jalr	2000(ra) # 80000be4 <acquire>
  empty = 0;
    8000341c:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000341e:	00020497          	auipc	s1,0x20
    80003422:	d7a48493          	addi	s1,s1,-646 # 80023198 <icache+0x20>
    80003426:	00022697          	auipc	a3,0x22
    8000342a:	99268693          	addi	a3,a3,-1646 # 80024db8 <log>
    8000342e:	a039                	j	8000343c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003430:	02090b63          	beqz	s2,80003466 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003434:	09048493          	addi	s1,s1,144
    80003438:	02d48a63          	beq	s1,a3,8000346c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000343c:	449c                	lw	a5,8(s1)
    8000343e:	fef059e3          	blez	a5,80003430 <iget+0x38>
    80003442:	4098                	lw	a4,0(s1)
    80003444:	ff3716e3          	bne	a4,s3,80003430 <iget+0x38>
    80003448:	40d8                	lw	a4,4(s1)
    8000344a:	ff4713e3          	bne	a4,s4,80003430 <iget+0x38>
      ip->ref++;
    8000344e:	2785                	addiw	a5,a5,1
    80003450:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003452:	00020517          	auipc	a0,0x20
    80003456:	d2650513          	addi	a0,a0,-730 # 80023178 <icache>
    8000345a:	ffffd097          	auipc	ra,0xffffd
    8000345e:	7fa080e7          	jalr	2042(ra) # 80000c54 <release>
      return ip;
    80003462:	8926                	mv	s2,s1
    80003464:	a03d                	j	80003492 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003466:	f7f9                	bnez	a5,80003434 <iget+0x3c>
    80003468:	8926                	mv	s2,s1
    8000346a:	b7e9                	j	80003434 <iget+0x3c>
  if(empty == 0)
    8000346c:	02090c63          	beqz	s2,800034a4 <iget+0xac>
  ip->dev = dev;
    80003470:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003474:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003478:	4785                	li	a5,1
    8000347a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000347e:	04092423          	sw	zero,72(s2)
  release(&icache.lock);
    80003482:	00020517          	auipc	a0,0x20
    80003486:	cf650513          	addi	a0,a0,-778 # 80023178 <icache>
    8000348a:	ffffd097          	auipc	ra,0xffffd
    8000348e:	7ca080e7          	jalr	1994(ra) # 80000c54 <release>
}
    80003492:	854a                	mv	a0,s2
    80003494:	70a2                	ld	ra,40(sp)
    80003496:	7402                	ld	s0,32(sp)
    80003498:	64e2                	ld	s1,24(sp)
    8000349a:	6942                	ld	s2,16(sp)
    8000349c:	69a2                	ld	s3,8(sp)
    8000349e:	6a02                	ld	s4,0(sp)
    800034a0:	6145                	addi	sp,sp,48
    800034a2:	8082                	ret
    panic("iget: no inodes");
    800034a4:	00005517          	auipc	a0,0x5
    800034a8:	1f450513          	addi	a0,a0,500 # 80008698 <userret+0x608>
    800034ac:	ffffd097          	auipc	ra,0xffffd
    800034b0:	09c080e7          	jalr	156(ra) # 80000548 <panic>

00000000800034b4 <fsinit>:
fsinit(int dev) {
    800034b4:	7179                	addi	sp,sp,-48
    800034b6:	f406                	sd	ra,40(sp)
    800034b8:	f022                	sd	s0,32(sp)
    800034ba:	ec26                	sd	s1,24(sp)
    800034bc:	e84a                	sd	s2,16(sp)
    800034be:	e44e                	sd	s3,8(sp)
    800034c0:	1800                	addi	s0,sp,48
    800034c2:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034c4:	4585                	li	a1,1
    800034c6:	00000097          	auipc	ra,0x0
    800034ca:	a5e080e7          	jalr	-1442(ra) # 80002f24 <bread>
    800034ce:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034d0:	00020997          	auipc	s3,0x20
    800034d4:	c8898993          	addi	s3,s3,-888 # 80023158 <sb>
    800034d8:	02000613          	li	a2,32
    800034dc:	06050593          	addi	a1,a0,96
    800034e0:	854e                	mv	a0,s3
    800034e2:	ffffe097          	auipc	ra,0xffffe
    800034e6:	9cc080e7          	jalr	-1588(ra) # 80000eae <memmove>
  brelse(bp);
    800034ea:	8526                	mv	a0,s1
    800034ec:	00000097          	auipc	ra,0x0
    800034f0:	b6c080e7          	jalr	-1172(ra) # 80003058 <brelse>
  if(sb.magic != FSMAGIC)
    800034f4:	0009a703          	lw	a4,0(s3)
    800034f8:	102037b7          	lui	a5,0x10203
    800034fc:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003500:	02f71263          	bne	a4,a5,80003524 <fsinit+0x70>
  initlog(dev, &sb);
    80003504:	00020597          	auipc	a1,0x20
    80003508:	c5458593          	addi	a1,a1,-940 # 80023158 <sb>
    8000350c:	854a                	mv	a0,s2
    8000350e:	00001097          	auipc	ra,0x1
    80003512:	b38080e7          	jalr	-1224(ra) # 80004046 <initlog>
}
    80003516:	70a2                	ld	ra,40(sp)
    80003518:	7402                	ld	s0,32(sp)
    8000351a:	64e2                	ld	s1,24(sp)
    8000351c:	6942                	ld	s2,16(sp)
    8000351e:	69a2                	ld	s3,8(sp)
    80003520:	6145                	addi	sp,sp,48
    80003522:	8082                	ret
    panic("invalid file system");
    80003524:	00005517          	auipc	a0,0x5
    80003528:	18450513          	addi	a0,a0,388 # 800086a8 <userret+0x618>
    8000352c:	ffffd097          	auipc	ra,0xffffd
    80003530:	01c080e7          	jalr	28(ra) # 80000548 <panic>

0000000080003534 <iinit>:
{
    80003534:	7179                	addi	sp,sp,-48
    80003536:	f406                	sd	ra,40(sp)
    80003538:	f022                	sd	s0,32(sp)
    8000353a:	ec26                	sd	s1,24(sp)
    8000353c:	e84a                	sd	s2,16(sp)
    8000353e:	e44e                	sd	s3,8(sp)
    80003540:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003542:	00005597          	auipc	a1,0x5
    80003546:	17e58593          	addi	a1,a1,382 # 800086c0 <userret+0x630>
    8000354a:	00020517          	auipc	a0,0x20
    8000354e:	c2e50513          	addi	a0,a0,-978 # 80023178 <icache>
    80003552:	ffffd097          	auipc	ra,0xffffd
    80003556:	544080e7          	jalr	1348(ra) # 80000a96 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000355a:	00020497          	auipc	s1,0x20
    8000355e:	c4e48493          	addi	s1,s1,-946 # 800231a8 <icache+0x30>
    80003562:	00022997          	auipc	s3,0x22
    80003566:	86698993          	addi	s3,s3,-1946 # 80024dc8 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000356a:	00005917          	auipc	s2,0x5
    8000356e:	15e90913          	addi	s2,s2,350 # 800086c8 <userret+0x638>
    80003572:	85ca                	mv	a1,s2
    80003574:	8526                	mv	a0,s1
    80003576:	00001097          	auipc	ra,0x1
    8000357a:	f28080e7          	jalr	-216(ra) # 8000449e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000357e:	09048493          	addi	s1,s1,144
    80003582:	ff3498e3          	bne	s1,s3,80003572 <iinit+0x3e>
}
    80003586:	70a2                	ld	ra,40(sp)
    80003588:	7402                	ld	s0,32(sp)
    8000358a:	64e2                	ld	s1,24(sp)
    8000358c:	6942                	ld	s2,16(sp)
    8000358e:	69a2                	ld	s3,8(sp)
    80003590:	6145                	addi	sp,sp,48
    80003592:	8082                	ret

0000000080003594 <ialloc>:
{
    80003594:	715d                	addi	sp,sp,-80
    80003596:	e486                	sd	ra,72(sp)
    80003598:	e0a2                	sd	s0,64(sp)
    8000359a:	fc26                	sd	s1,56(sp)
    8000359c:	f84a                	sd	s2,48(sp)
    8000359e:	f44e                	sd	s3,40(sp)
    800035a0:	f052                	sd	s4,32(sp)
    800035a2:	ec56                	sd	s5,24(sp)
    800035a4:	e85a                	sd	s6,16(sp)
    800035a6:	e45e                	sd	s7,8(sp)
    800035a8:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035aa:	00020717          	auipc	a4,0x20
    800035ae:	bba72703          	lw	a4,-1094(a4) # 80023164 <sb+0xc>
    800035b2:	4785                	li	a5,1
    800035b4:	04e7fa63          	bgeu	a5,a4,80003608 <ialloc+0x74>
    800035b8:	8aaa                	mv	s5,a0
    800035ba:	8bae                	mv	s7,a1
    800035bc:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035be:	00020a17          	auipc	s4,0x20
    800035c2:	b9aa0a13          	addi	s4,s4,-1126 # 80023158 <sb>
    800035c6:	00048b1b          	sext.w	s6,s1
    800035ca:	0044d793          	srli	a5,s1,0x4
    800035ce:	018a2583          	lw	a1,24(s4)
    800035d2:	9dbd                	addw	a1,a1,a5
    800035d4:	8556                	mv	a0,s5
    800035d6:	00000097          	auipc	ra,0x0
    800035da:	94e080e7          	jalr	-1714(ra) # 80002f24 <bread>
    800035de:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035e0:	06050993          	addi	s3,a0,96
    800035e4:	00f4f793          	andi	a5,s1,15
    800035e8:	079a                	slli	a5,a5,0x6
    800035ea:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035ec:	00099783          	lh	a5,0(s3)
    800035f0:	c785                	beqz	a5,80003618 <ialloc+0x84>
    brelse(bp);
    800035f2:	00000097          	auipc	ra,0x0
    800035f6:	a66080e7          	jalr	-1434(ra) # 80003058 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800035fa:	0485                	addi	s1,s1,1
    800035fc:	00ca2703          	lw	a4,12(s4)
    80003600:	0004879b          	sext.w	a5,s1
    80003604:	fce7e1e3          	bltu	a5,a4,800035c6 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003608:	00005517          	auipc	a0,0x5
    8000360c:	0c850513          	addi	a0,a0,200 # 800086d0 <userret+0x640>
    80003610:	ffffd097          	auipc	ra,0xffffd
    80003614:	f38080e7          	jalr	-200(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    80003618:	04000613          	li	a2,64
    8000361c:	4581                	li	a1,0
    8000361e:	854e                	mv	a0,s3
    80003620:	ffffe097          	auipc	ra,0xffffe
    80003624:	832080e7          	jalr	-1998(ra) # 80000e52 <memset>
      dip->type = type;
    80003628:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000362c:	854a                	mv	a0,s2
    8000362e:	00001097          	auipc	ra,0x1
    80003632:	d30080e7          	jalr	-720(ra) # 8000435e <log_write>
      brelse(bp);
    80003636:	854a                	mv	a0,s2
    80003638:	00000097          	auipc	ra,0x0
    8000363c:	a20080e7          	jalr	-1504(ra) # 80003058 <brelse>
      return iget(dev, inum);
    80003640:	85da                	mv	a1,s6
    80003642:	8556                	mv	a0,s5
    80003644:	00000097          	auipc	ra,0x0
    80003648:	db4080e7          	jalr	-588(ra) # 800033f8 <iget>
}
    8000364c:	60a6                	ld	ra,72(sp)
    8000364e:	6406                	ld	s0,64(sp)
    80003650:	74e2                	ld	s1,56(sp)
    80003652:	7942                	ld	s2,48(sp)
    80003654:	79a2                	ld	s3,40(sp)
    80003656:	7a02                	ld	s4,32(sp)
    80003658:	6ae2                	ld	s5,24(sp)
    8000365a:	6b42                	ld	s6,16(sp)
    8000365c:	6ba2                	ld	s7,8(sp)
    8000365e:	6161                	addi	sp,sp,80
    80003660:	8082                	ret

0000000080003662 <iupdate>:
{
    80003662:	1101                	addi	sp,sp,-32
    80003664:	ec06                	sd	ra,24(sp)
    80003666:	e822                	sd	s0,16(sp)
    80003668:	e426                	sd	s1,8(sp)
    8000366a:	e04a                	sd	s2,0(sp)
    8000366c:	1000                	addi	s0,sp,32
    8000366e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003670:	415c                	lw	a5,4(a0)
    80003672:	0047d79b          	srliw	a5,a5,0x4
    80003676:	00020597          	auipc	a1,0x20
    8000367a:	afa5a583          	lw	a1,-1286(a1) # 80023170 <sb+0x18>
    8000367e:	9dbd                	addw	a1,a1,a5
    80003680:	4108                	lw	a0,0(a0)
    80003682:	00000097          	auipc	ra,0x0
    80003686:	8a2080e7          	jalr	-1886(ra) # 80002f24 <bread>
    8000368a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000368c:	06050793          	addi	a5,a0,96
    80003690:	40c8                	lw	a0,4(s1)
    80003692:	893d                	andi	a0,a0,15
    80003694:	051a                	slli	a0,a0,0x6
    80003696:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003698:	04c49703          	lh	a4,76(s1)
    8000369c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800036a0:	04e49703          	lh	a4,78(s1)
    800036a4:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800036a8:	05049703          	lh	a4,80(s1)
    800036ac:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800036b0:	05249703          	lh	a4,82(s1)
    800036b4:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800036b8:	48f8                	lw	a4,84(s1)
    800036ba:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036bc:	03400613          	li	a2,52
    800036c0:	05848593          	addi	a1,s1,88
    800036c4:	0531                	addi	a0,a0,12
    800036c6:	ffffd097          	auipc	ra,0xffffd
    800036ca:	7e8080e7          	jalr	2024(ra) # 80000eae <memmove>
  log_write(bp);
    800036ce:	854a                	mv	a0,s2
    800036d0:	00001097          	auipc	ra,0x1
    800036d4:	c8e080e7          	jalr	-882(ra) # 8000435e <log_write>
  brelse(bp);
    800036d8:	854a                	mv	a0,s2
    800036da:	00000097          	auipc	ra,0x0
    800036de:	97e080e7          	jalr	-1666(ra) # 80003058 <brelse>
}
    800036e2:	60e2                	ld	ra,24(sp)
    800036e4:	6442                	ld	s0,16(sp)
    800036e6:	64a2                	ld	s1,8(sp)
    800036e8:	6902                	ld	s2,0(sp)
    800036ea:	6105                	addi	sp,sp,32
    800036ec:	8082                	ret

00000000800036ee <idup>:
{
    800036ee:	1101                	addi	sp,sp,-32
    800036f0:	ec06                	sd	ra,24(sp)
    800036f2:	e822                	sd	s0,16(sp)
    800036f4:	e426                	sd	s1,8(sp)
    800036f6:	1000                	addi	s0,sp,32
    800036f8:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800036fa:	00020517          	auipc	a0,0x20
    800036fe:	a7e50513          	addi	a0,a0,-1410 # 80023178 <icache>
    80003702:	ffffd097          	auipc	ra,0xffffd
    80003706:	4e2080e7          	jalr	1250(ra) # 80000be4 <acquire>
  ip->ref++;
    8000370a:	449c                	lw	a5,8(s1)
    8000370c:	2785                	addiw	a5,a5,1
    8000370e:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003710:	00020517          	auipc	a0,0x20
    80003714:	a6850513          	addi	a0,a0,-1432 # 80023178 <icache>
    80003718:	ffffd097          	auipc	ra,0xffffd
    8000371c:	53c080e7          	jalr	1340(ra) # 80000c54 <release>
}
    80003720:	8526                	mv	a0,s1
    80003722:	60e2                	ld	ra,24(sp)
    80003724:	6442                	ld	s0,16(sp)
    80003726:	64a2                	ld	s1,8(sp)
    80003728:	6105                	addi	sp,sp,32
    8000372a:	8082                	ret

000000008000372c <ilock>:
{
    8000372c:	1101                	addi	sp,sp,-32
    8000372e:	ec06                	sd	ra,24(sp)
    80003730:	e822                	sd	s0,16(sp)
    80003732:	e426                	sd	s1,8(sp)
    80003734:	e04a                	sd	s2,0(sp)
    80003736:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003738:	c115                	beqz	a0,8000375c <ilock+0x30>
    8000373a:	84aa                	mv	s1,a0
    8000373c:	451c                	lw	a5,8(a0)
    8000373e:	00f05f63          	blez	a5,8000375c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003742:	0541                	addi	a0,a0,16
    80003744:	00001097          	auipc	ra,0x1
    80003748:	d94080e7          	jalr	-620(ra) # 800044d8 <acquiresleep>
  if(ip->valid == 0){
    8000374c:	44bc                	lw	a5,72(s1)
    8000374e:	cf99                	beqz	a5,8000376c <ilock+0x40>
}
    80003750:	60e2                	ld	ra,24(sp)
    80003752:	6442                	ld	s0,16(sp)
    80003754:	64a2                	ld	s1,8(sp)
    80003756:	6902                	ld	s2,0(sp)
    80003758:	6105                	addi	sp,sp,32
    8000375a:	8082                	ret
    panic("ilock");
    8000375c:	00005517          	auipc	a0,0x5
    80003760:	f8c50513          	addi	a0,a0,-116 # 800086e8 <userret+0x658>
    80003764:	ffffd097          	auipc	ra,0xffffd
    80003768:	de4080e7          	jalr	-540(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000376c:	40dc                	lw	a5,4(s1)
    8000376e:	0047d79b          	srliw	a5,a5,0x4
    80003772:	00020597          	auipc	a1,0x20
    80003776:	9fe5a583          	lw	a1,-1538(a1) # 80023170 <sb+0x18>
    8000377a:	9dbd                	addw	a1,a1,a5
    8000377c:	4088                	lw	a0,0(s1)
    8000377e:	fffff097          	auipc	ra,0xfffff
    80003782:	7a6080e7          	jalr	1958(ra) # 80002f24 <bread>
    80003786:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003788:	06050593          	addi	a1,a0,96
    8000378c:	40dc                	lw	a5,4(s1)
    8000378e:	8bbd                	andi	a5,a5,15
    80003790:	079a                	slli	a5,a5,0x6
    80003792:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003794:	00059783          	lh	a5,0(a1)
    80003798:	04f49623          	sh	a5,76(s1)
    ip->major = dip->major;
    8000379c:	00259783          	lh	a5,2(a1)
    800037a0:	04f49723          	sh	a5,78(s1)
    ip->minor = dip->minor;
    800037a4:	00459783          	lh	a5,4(a1)
    800037a8:	04f49823          	sh	a5,80(s1)
    ip->nlink = dip->nlink;
    800037ac:	00659783          	lh	a5,6(a1)
    800037b0:	04f49923          	sh	a5,82(s1)
    ip->size = dip->size;
    800037b4:	459c                	lw	a5,8(a1)
    800037b6:	c8fc                	sw	a5,84(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037b8:	03400613          	li	a2,52
    800037bc:	05b1                	addi	a1,a1,12
    800037be:	05848513          	addi	a0,s1,88
    800037c2:	ffffd097          	auipc	ra,0xffffd
    800037c6:	6ec080e7          	jalr	1772(ra) # 80000eae <memmove>
    brelse(bp);
    800037ca:	854a                	mv	a0,s2
    800037cc:	00000097          	auipc	ra,0x0
    800037d0:	88c080e7          	jalr	-1908(ra) # 80003058 <brelse>
    ip->valid = 1;
    800037d4:	4785                	li	a5,1
    800037d6:	c4bc                	sw	a5,72(s1)
    if(ip->type == 0)
    800037d8:	04c49783          	lh	a5,76(s1)
    800037dc:	fbb5                	bnez	a5,80003750 <ilock+0x24>
      panic("ilock: no type");
    800037de:	00005517          	auipc	a0,0x5
    800037e2:	f1250513          	addi	a0,a0,-238 # 800086f0 <userret+0x660>
    800037e6:	ffffd097          	auipc	ra,0xffffd
    800037ea:	d62080e7          	jalr	-670(ra) # 80000548 <panic>

00000000800037ee <iunlock>:
{
    800037ee:	1101                	addi	sp,sp,-32
    800037f0:	ec06                	sd	ra,24(sp)
    800037f2:	e822                	sd	s0,16(sp)
    800037f4:	e426                	sd	s1,8(sp)
    800037f6:	e04a                	sd	s2,0(sp)
    800037f8:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800037fa:	c905                	beqz	a0,8000382a <iunlock+0x3c>
    800037fc:	84aa                	mv	s1,a0
    800037fe:	01050913          	addi	s2,a0,16
    80003802:	854a                	mv	a0,s2
    80003804:	00001097          	auipc	ra,0x1
    80003808:	d6e080e7          	jalr	-658(ra) # 80004572 <holdingsleep>
    8000380c:	cd19                	beqz	a0,8000382a <iunlock+0x3c>
    8000380e:	449c                	lw	a5,8(s1)
    80003810:	00f05d63          	blez	a5,8000382a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003814:	854a                	mv	a0,s2
    80003816:	00001097          	auipc	ra,0x1
    8000381a:	d18080e7          	jalr	-744(ra) # 8000452e <releasesleep>
}
    8000381e:	60e2                	ld	ra,24(sp)
    80003820:	6442                	ld	s0,16(sp)
    80003822:	64a2                	ld	s1,8(sp)
    80003824:	6902                	ld	s2,0(sp)
    80003826:	6105                	addi	sp,sp,32
    80003828:	8082                	ret
    panic("iunlock");
    8000382a:	00005517          	auipc	a0,0x5
    8000382e:	ed650513          	addi	a0,a0,-298 # 80008700 <userret+0x670>
    80003832:	ffffd097          	auipc	ra,0xffffd
    80003836:	d16080e7          	jalr	-746(ra) # 80000548 <panic>

000000008000383a <iput>:
{
    8000383a:	7139                	addi	sp,sp,-64
    8000383c:	fc06                	sd	ra,56(sp)
    8000383e:	f822                	sd	s0,48(sp)
    80003840:	f426                	sd	s1,40(sp)
    80003842:	f04a                	sd	s2,32(sp)
    80003844:	ec4e                	sd	s3,24(sp)
    80003846:	e852                	sd	s4,16(sp)
    80003848:	e456                	sd	s5,8(sp)
    8000384a:	0080                	addi	s0,sp,64
    8000384c:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000384e:	00020517          	auipc	a0,0x20
    80003852:	92a50513          	addi	a0,a0,-1750 # 80023178 <icache>
    80003856:	ffffd097          	auipc	ra,0xffffd
    8000385a:	38e080e7          	jalr	910(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000385e:	4498                	lw	a4,8(s1)
    80003860:	4785                	li	a5,1
    80003862:	02f70663          	beq	a4,a5,8000388e <iput+0x54>
  ip->ref--;
    80003866:	449c                	lw	a5,8(s1)
    80003868:	37fd                	addiw	a5,a5,-1
    8000386a:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000386c:	00020517          	auipc	a0,0x20
    80003870:	90c50513          	addi	a0,a0,-1780 # 80023178 <icache>
    80003874:	ffffd097          	auipc	ra,0xffffd
    80003878:	3e0080e7          	jalr	992(ra) # 80000c54 <release>
}
    8000387c:	70e2                	ld	ra,56(sp)
    8000387e:	7442                	ld	s0,48(sp)
    80003880:	74a2                	ld	s1,40(sp)
    80003882:	7902                	ld	s2,32(sp)
    80003884:	69e2                	ld	s3,24(sp)
    80003886:	6a42                	ld	s4,16(sp)
    80003888:	6aa2                	ld	s5,8(sp)
    8000388a:	6121                	addi	sp,sp,64
    8000388c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000388e:	44bc                	lw	a5,72(s1)
    80003890:	dbf9                	beqz	a5,80003866 <iput+0x2c>
    80003892:	05249783          	lh	a5,82(s1)
    80003896:	fbe1                	bnez	a5,80003866 <iput+0x2c>
    acquiresleep(&ip->lock);
    80003898:	01048a13          	addi	s4,s1,16
    8000389c:	8552                	mv	a0,s4
    8000389e:	00001097          	auipc	ra,0x1
    800038a2:	c3a080e7          	jalr	-966(ra) # 800044d8 <acquiresleep>
    release(&icache.lock);
    800038a6:	00020517          	auipc	a0,0x20
    800038aa:	8d250513          	addi	a0,a0,-1838 # 80023178 <icache>
    800038ae:	ffffd097          	auipc	ra,0xffffd
    800038b2:	3a6080e7          	jalr	934(ra) # 80000c54 <release>
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038b6:	05848913          	addi	s2,s1,88
    800038ba:	08848993          	addi	s3,s1,136
    800038be:	a021                	j	800038c6 <iput+0x8c>
    800038c0:	0911                	addi	s2,s2,4
    800038c2:	01390d63          	beq	s2,s3,800038dc <iput+0xa2>
    if(ip->addrs[i]){
    800038c6:	00092583          	lw	a1,0(s2)
    800038ca:	d9fd                	beqz	a1,800038c0 <iput+0x86>
      bfree(ip->dev, ip->addrs[i]);
    800038cc:	4088                	lw	a0,0(s1)
    800038ce:	00000097          	auipc	ra,0x0
    800038d2:	8a0080e7          	jalr	-1888(ra) # 8000316e <bfree>
      ip->addrs[i] = 0;
    800038d6:	00092023          	sw	zero,0(s2)
    800038da:	b7dd                	j	800038c0 <iput+0x86>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038dc:	0884a583          	lw	a1,136(s1)
    800038e0:	ed9d                	bnez	a1,8000391e <iput+0xe4>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038e2:	0404aa23          	sw	zero,84(s1)
  iupdate(ip);
    800038e6:	8526                	mv	a0,s1
    800038e8:	00000097          	auipc	ra,0x0
    800038ec:	d7a080e7          	jalr	-646(ra) # 80003662 <iupdate>
    ip->type = 0;
    800038f0:	04049623          	sh	zero,76(s1)
    iupdate(ip);
    800038f4:	8526                	mv	a0,s1
    800038f6:	00000097          	auipc	ra,0x0
    800038fa:	d6c080e7          	jalr	-660(ra) # 80003662 <iupdate>
    ip->valid = 0;
    800038fe:	0404a423          	sw	zero,72(s1)
    releasesleep(&ip->lock);
    80003902:	8552                	mv	a0,s4
    80003904:	00001097          	auipc	ra,0x1
    80003908:	c2a080e7          	jalr	-982(ra) # 8000452e <releasesleep>
    acquire(&icache.lock);
    8000390c:	00020517          	auipc	a0,0x20
    80003910:	86c50513          	addi	a0,a0,-1940 # 80023178 <icache>
    80003914:	ffffd097          	auipc	ra,0xffffd
    80003918:	2d0080e7          	jalr	720(ra) # 80000be4 <acquire>
    8000391c:	b7a9                	j	80003866 <iput+0x2c>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000391e:	4088                	lw	a0,0(s1)
    80003920:	fffff097          	auipc	ra,0xfffff
    80003924:	604080e7          	jalr	1540(ra) # 80002f24 <bread>
    80003928:	8aaa                	mv	s5,a0
    for(j = 0; j < NINDIRECT; j++){
    8000392a:	06050913          	addi	s2,a0,96
    8000392e:	46050993          	addi	s3,a0,1120
    80003932:	a021                	j	8000393a <iput+0x100>
    80003934:	0911                	addi	s2,s2,4
    80003936:	01390b63          	beq	s2,s3,8000394c <iput+0x112>
      if(a[j])
    8000393a:	00092583          	lw	a1,0(s2)
    8000393e:	d9fd                	beqz	a1,80003934 <iput+0xfa>
        bfree(ip->dev, a[j]);
    80003940:	4088                	lw	a0,0(s1)
    80003942:	00000097          	auipc	ra,0x0
    80003946:	82c080e7          	jalr	-2004(ra) # 8000316e <bfree>
    8000394a:	b7ed                	j	80003934 <iput+0xfa>
    brelse(bp);
    8000394c:	8556                	mv	a0,s5
    8000394e:	fffff097          	auipc	ra,0xfffff
    80003952:	70a080e7          	jalr	1802(ra) # 80003058 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003956:	0884a583          	lw	a1,136(s1)
    8000395a:	4088                	lw	a0,0(s1)
    8000395c:	00000097          	auipc	ra,0x0
    80003960:	812080e7          	jalr	-2030(ra) # 8000316e <bfree>
    ip->addrs[NDIRECT] = 0;
    80003964:	0804a423          	sw	zero,136(s1)
    80003968:	bfad                	j	800038e2 <iput+0xa8>

000000008000396a <iunlockput>:
{
    8000396a:	1101                	addi	sp,sp,-32
    8000396c:	ec06                	sd	ra,24(sp)
    8000396e:	e822                	sd	s0,16(sp)
    80003970:	e426                	sd	s1,8(sp)
    80003972:	1000                	addi	s0,sp,32
    80003974:	84aa                	mv	s1,a0
  iunlock(ip);
    80003976:	00000097          	auipc	ra,0x0
    8000397a:	e78080e7          	jalr	-392(ra) # 800037ee <iunlock>
  iput(ip);
    8000397e:	8526                	mv	a0,s1
    80003980:	00000097          	auipc	ra,0x0
    80003984:	eba080e7          	jalr	-326(ra) # 8000383a <iput>
}
    80003988:	60e2                	ld	ra,24(sp)
    8000398a:	6442                	ld	s0,16(sp)
    8000398c:	64a2                	ld	s1,8(sp)
    8000398e:	6105                	addi	sp,sp,32
    80003990:	8082                	ret

0000000080003992 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003992:	1141                	addi	sp,sp,-16
    80003994:	e422                	sd	s0,8(sp)
    80003996:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003998:	411c                	lw	a5,0(a0)
    8000399a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000399c:	415c                	lw	a5,4(a0)
    8000399e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039a0:	04c51783          	lh	a5,76(a0)
    800039a4:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039a8:	05251783          	lh	a5,82(a0)
    800039ac:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039b0:	05456783          	lwu	a5,84(a0)
    800039b4:	e99c                	sd	a5,16(a1)
}
    800039b6:	6422                	ld	s0,8(sp)
    800039b8:	0141                	addi	sp,sp,16
    800039ba:	8082                	ret

00000000800039bc <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039bc:	497c                	lw	a5,84(a0)
    800039be:	0ed7e563          	bltu	a5,a3,80003aa8 <readi+0xec>
{
    800039c2:	7159                	addi	sp,sp,-112
    800039c4:	f486                	sd	ra,104(sp)
    800039c6:	f0a2                	sd	s0,96(sp)
    800039c8:	eca6                	sd	s1,88(sp)
    800039ca:	e8ca                	sd	s2,80(sp)
    800039cc:	e4ce                	sd	s3,72(sp)
    800039ce:	e0d2                	sd	s4,64(sp)
    800039d0:	fc56                	sd	s5,56(sp)
    800039d2:	f85a                	sd	s6,48(sp)
    800039d4:	f45e                	sd	s7,40(sp)
    800039d6:	f062                	sd	s8,32(sp)
    800039d8:	ec66                	sd	s9,24(sp)
    800039da:	e86a                	sd	s10,16(sp)
    800039dc:	e46e                	sd	s11,8(sp)
    800039de:	1880                	addi	s0,sp,112
    800039e0:	8baa                	mv	s7,a0
    800039e2:	8c2e                	mv	s8,a1
    800039e4:	8ab2                	mv	s5,a2
    800039e6:	8936                	mv	s2,a3
    800039e8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800039ea:	9f35                	addw	a4,a4,a3
    800039ec:	0cd76063          	bltu	a4,a3,80003aac <readi+0xf0>
    return -1;
  if(off + n > ip->size)
    800039f0:	00e7f463          	bgeu	a5,a4,800039f8 <readi+0x3c>
    n = ip->size - off;
    800039f4:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039f8:	080b0763          	beqz	s6,80003a86 <readi+0xca>
    800039fc:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800039fe:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a02:	5cfd                	li	s9,-1
    80003a04:	a82d                	j	80003a3e <readi+0x82>
    80003a06:	02099d93          	slli	s11,s3,0x20
    80003a0a:	020ddd93          	srli	s11,s11,0x20
    80003a0e:	06048793          	addi	a5,s1,96
    80003a12:	86ee                	mv	a3,s11
    80003a14:	963e                	add	a2,a2,a5
    80003a16:	85d6                	mv	a1,s5
    80003a18:	8562                	mv	a0,s8
    80003a1a:	fffff097          	auipc	ra,0xfffff
    80003a1e:	b52080e7          	jalr	-1198(ra) # 8000256c <either_copyout>
    80003a22:	05950d63          	beq	a0,s9,80003a7c <readi+0xc0>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003a26:	8526                	mv	a0,s1
    80003a28:	fffff097          	auipc	ra,0xfffff
    80003a2c:	630080e7          	jalr	1584(ra) # 80003058 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a30:	01498a3b          	addw	s4,s3,s4
    80003a34:	0129893b          	addw	s2,s3,s2
    80003a38:	9aee                	add	s5,s5,s11
    80003a3a:	056a7663          	bgeu	s4,s6,80003a86 <readi+0xca>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a3e:	000ba483          	lw	s1,0(s7)
    80003a42:	00a9559b          	srliw	a1,s2,0xa
    80003a46:	855e                	mv	a0,s7
    80003a48:	00000097          	auipc	ra,0x0
    80003a4c:	8d4080e7          	jalr	-1836(ra) # 8000331c <bmap>
    80003a50:	0005059b          	sext.w	a1,a0
    80003a54:	8526                	mv	a0,s1
    80003a56:	fffff097          	auipc	ra,0xfffff
    80003a5a:	4ce080e7          	jalr	1230(ra) # 80002f24 <bread>
    80003a5e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a60:	3ff97613          	andi	a2,s2,1023
    80003a64:	40cd07bb          	subw	a5,s10,a2
    80003a68:	414b073b          	subw	a4,s6,s4
    80003a6c:	89be                	mv	s3,a5
    80003a6e:	2781                	sext.w	a5,a5
    80003a70:	0007069b          	sext.w	a3,a4
    80003a74:	f8f6f9e3          	bgeu	a3,a5,80003a06 <readi+0x4a>
    80003a78:	89ba                	mv	s3,a4
    80003a7a:	b771                	j	80003a06 <readi+0x4a>
      brelse(bp);
    80003a7c:	8526                	mv	a0,s1
    80003a7e:	fffff097          	auipc	ra,0xfffff
    80003a82:	5da080e7          	jalr	1498(ra) # 80003058 <brelse>
  }
  return n;
    80003a86:	000b051b          	sext.w	a0,s6
}
    80003a8a:	70a6                	ld	ra,104(sp)
    80003a8c:	7406                	ld	s0,96(sp)
    80003a8e:	64e6                	ld	s1,88(sp)
    80003a90:	6946                	ld	s2,80(sp)
    80003a92:	69a6                	ld	s3,72(sp)
    80003a94:	6a06                	ld	s4,64(sp)
    80003a96:	7ae2                	ld	s5,56(sp)
    80003a98:	7b42                	ld	s6,48(sp)
    80003a9a:	7ba2                	ld	s7,40(sp)
    80003a9c:	7c02                	ld	s8,32(sp)
    80003a9e:	6ce2                	ld	s9,24(sp)
    80003aa0:	6d42                	ld	s10,16(sp)
    80003aa2:	6da2                	ld	s11,8(sp)
    80003aa4:	6165                	addi	sp,sp,112
    80003aa6:	8082                	ret
    return -1;
    80003aa8:	557d                	li	a0,-1
}
    80003aaa:	8082                	ret
    return -1;
    80003aac:	557d                	li	a0,-1
    80003aae:	bff1                	j	80003a8a <readi+0xce>

0000000080003ab0 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ab0:	497c                	lw	a5,84(a0)
    80003ab2:	10d7e663          	bltu	a5,a3,80003bbe <writei+0x10e>
{
    80003ab6:	7159                	addi	sp,sp,-112
    80003ab8:	f486                	sd	ra,104(sp)
    80003aba:	f0a2                	sd	s0,96(sp)
    80003abc:	eca6                	sd	s1,88(sp)
    80003abe:	e8ca                	sd	s2,80(sp)
    80003ac0:	e4ce                	sd	s3,72(sp)
    80003ac2:	e0d2                	sd	s4,64(sp)
    80003ac4:	fc56                	sd	s5,56(sp)
    80003ac6:	f85a                	sd	s6,48(sp)
    80003ac8:	f45e                	sd	s7,40(sp)
    80003aca:	f062                	sd	s8,32(sp)
    80003acc:	ec66                	sd	s9,24(sp)
    80003ace:	e86a                	sd	s10,16(sp)
    80003ad0:	e46e                	sd	s11,8(sp)
    80003ad2:	1880                	addi	s0,sp,112
    80003ad4:	8baa                	mv	s7,a0
    80003ad6:	8c2e                	mv	s8,a1
    80003ad8:	8ab2                	mv	s5,a2
    80003ada:	8936                	mv	s2,a3
    80003adc:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ade:	00e687bb          	addw	a5,a3,a4
    80003ae2:	0ed7e063          	bltu	a5,a3,80003bc2 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ae6:	00043737          	lui	a4,0x43
    80003aea:	0cf76e63          	bltu	a4,a5,80003bc6 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003aee:	0a0b0763          	beqz	s6,80003b9c <writei+0xec>
    80003af2:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003af4:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003af8:	5cfd                	li	s9,-1
    80003afa:	a091                	j	80003b3e <writei+0x8e>
    80003afc:	02099d93          	slli	s11,s3,0x20
    80003b00:	020ddd93          	srli	s11,s11,0x20
    80003b04:	06048793          	addi	a5,s1,96
    80003b08:	86ee                	mv	a3,s11
    80003b0a:	8656                	mv	a2,s5
    80003b0c:	85e2                	mv	a1,s8
    80003b0e:	953e                	add	a0,a0,a5
    80003b10:	fffff097          	auipc	ra,0xfffff
    80003b14:	ab2080e7          	jalr	-1358(ra) # 800025c2 <either_copyin>
    80003b18:	07950263          	beq	a0,s9,80003b7c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b1c:	8526                	mv	a0,s1
    80003b1e:	00001097          	auipc	ra,0x1
    80003b22:	840080e7          	jalr	-1984(ra) # 8000435e <log_write>
    brelse(bp);
    80003b26:	8526                	mv	a0,s1
    80003b28:	fffff097          	auipc	ra,0xfffff
    80003b2c:	530080e7          	jalr	1328(ra) # 80003058 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b30:	01498a3b          	addw	s4,s3,s4
    80003b34:	0129893b          	addw	s2,s3,s2
    80003b38:	9aee                	add	s5,s5,s11
    80003b3a:	056a7663          	bgeu	s4,s6,80003b86 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b3e:	000ba483          	lw	s1,0(s7)
    80003b42:	00a9559b          	srliw	a1,s2,0xa
    80003b46:	855e                	mv	a0,s7
    80003b48:	fffff097          	auipc	ra,0xfffff
    80003b4c:	7d4080e7          	jalr	2004(ra) # 8000331c <bmap>
    80003b50:	0005059b          	sext.w	a1,a0
    80003b54:	8526                	mv	a0,s1
    80003b56:	fffff097          	auipc	ra,0xfffff
    80003b5a:	3ce080e7          	jalr	974(ra) # 80002f24 <bread>
    80003b5e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b60:	3ff97513          	andi	a0,s2,1023
    80003b64:	40ad07bb          	subw	a5,s10,a0
    80003b68:	414b073b          	subw	a4,s6,s4
    80003b6c:	89be                	mv	s3,a5
    80003b6e:	2781                	sext.w	a5,a5
    80003b70:	0007069b          	sext.w	a3,a4
    80003b74:	f8f6f4e3          	bgeu	a3,a5,80003afc <writei+0x4c>
    80003b78:	89ba                	mv	s3,a4
    80003b7a:	b749                	j	80003afc <writei+0x4c>
      brelse(bp);
    80003b7c:	8526                	mv	a0,s1
    80003b7e:	fffff097          	auipc	ra,0xfffff
    80003b82:	4da080e7          	jalr	1242(ra) # 80003058 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003b86:	054ba783          	lw	a5,84(s7)
    80003b8a:	0127f463          	bgeu	a5,s2,80003b92 <writei+0xe2>
      ip->size = off;
    80003b8e:	052baa23          	sw	s2,84(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003b92:	855e                	mv	a0,s7
    80003b94:	00000097          	auipc	ra,0x0
    80003b98:	ace080e7          	jalr	-1330(ra) # 80003662 <iupdate>
  }

  return n;
    80003b9c:	000b051b          	sext.w	a0,s6
}
    80003ba0:	70a6                	ld	ra,104(sp)
    80003ba2:	7406                	ld	s0,96(sp)
    80003ba4:	64e6                	ld	s1,88(sp)
    80003ba6:	6946                	ld	s2,80(sp)
    80003ba8:	69a6                	ld	s3,72(sp)
    80003baa:	6a06                	ld	s4,64(sp)
    80003bac:	7ae2                	ld	s5,56(sp)
    80003bae:	7b42                	ld	s6,48(sp)
    80003bb0:	7ba2                	ld	s7,40(sp)
    80003bb2:	7c02                	ld	s8,32(sp)
    80003bb4:	6ce2                	ld	s9,24(sp)
    80003bb6:	6d42                	ld	s10,16(sp)
    80003bb8:	6da2                	ld	s11,8(sp)
    80003bba:	6165                	addi	sp,sp,112
    80003bbc:	8082                	ret
    return -1;
    80003bbe:	557d                	li	a0,-1
}
    80003bc0:	8082                	ret
    return -1;
    80003bc2:	557d                	li	a0,-1
    80003bc4:	bff1                	j	80003ba0 <writei+0xf0>
    return -1;
    80003bc6:	557d                	li	a0,-1
    80003bc8:	bfe1                	j	80003ba0 <writei+0xf0>

0000000080003bca <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003bca:	1141                	addi	sp,sp,-16
    80003bcc:	e406                	sd	ra,8(sp)
    80003bce:	e022                	sd	s0,0(sp)
    80003bd0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003bd2:	4639                	li	a2,14
    80003bd4:	ffffd097          	auipc	ra,0xffffd
    80003bd8:	356080e7          	jalr	854(ra) # 80000f2a <strncmp>
}
    80003bdc:	60a2                	ld	ra,8(sp)
    80003bde:	6402                	ld	s0,0(sp)
    80003be0:	0141                	addi	sp,sp,16
    80003be2:	8082                	ret

0000000080003be4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003be4:	7139                	addi	sp,sp,-64
    80003be6:	fc06                	sd	ra,56(sp)
    80003be8:	f822                	sd	s0,48(sp)
    80003bea:	f426                	sd	s1,40(sp)
    80003bec:	f04a                	sd	s2,32(sp)
    80003bee:	ec4e                	sd	s3,24(sp)
    80003bf0:	e852                	sd	s4,16(sp)
    80003bf2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003bf4:	04c51703          	lh	a4,76(a0)
    80003bf8:	4785                	li	a5,1
    80003bfa:	00f71a63          	bne	a4,a5,80003c0e <dirlookup+0x2a>
    80003bfe:	892a                	mv	s2,a0
    80003c00:	89ae                	mv	s3,a1
    80003c02:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c04:	497c                	lw	a5,84(a0)
    80003c06:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c08:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c0a:	e79d                	bnez	a5,80003c38 <dirlookup+0x54>
    80003c0c:	a8a5                	j	80003c84 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c0e:	00005517          	auipc	a0,0x5
    80003c12:	afa50513          	addi	a0,a0,-1286 # 80008708 <userret+0x678>
    80003c16:	ffffd097          	auipc	ra,0xffffd
    80003c1a:	932080e7          	jalr	-1742(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003c1e:	00005517          	auipc	a0,0x5
    80003c22:	b0250513          	addi	a0,a0,-1278 # 80008720 <userret+0x690>
    80003c26:	ffffd097          	auipc	ra,0xffffd
    80003c2a:	922080e7          	jalr	-1758(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c2e:	24c1                	addiw	s1,s1,16
    80003c30:	05492783          	lw	a5,84(s2)
    80003c34:	04f4f763          	bgeu	s1,a5,80003c82 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c38:	4741                	li	a4,16
    80003c3a:	86a6                	mv	a3,s1
    80003c3c:	fc040613          	addi	a2,s0,-64
    80003c40:	4581                	li	a1,0
    80003c42:	854a                	mv	a0,s2
    80003c44:	00000097          	auipc	ra,0x0
    80003c48:	d78080e7          	jalr	-648(ra) # 800039bc <readi>
    80003c4c:	47c1                	li	a5,16
    80003c4e:	fcf518e3          	bne	a0,a5,80003c1e <dirlookup+0x3a>
    if(de.inum == 0)
    80003c52:	fc045783          	lhu	a5,-64(s0)
    80003c56:	dfe1                	beqz	a5,80003c2e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c58:	fc240593          	addi	a1,s0,-62
    80003c5c:	854e                	mv	a0,s3
    80003c5e:	00000097          	auipc	ra,0x0
    80003c62:	f6c080e7          	jalr	-148(ra) # 80003bca <namecmp>
    80003c66:	f561                	bnez	a0,80003c2e <dirlookup+0x4a>
      if(poff)
    80003c68:	000a0463          	beqz	s4,80003c70 <dirlookup+0x8c>
        *poff = off;
    80003c6c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c70:	fc045583          	lhu	a1,-64(s0)
    80003c74:	00092503          	lw	a0,0(s2)
    80003c78:	fffff097          	auipc	ra,0xfffff
    80003c7c:	780080e7          	jalr	1920(ra) # 800033f8 <iget>
    80003c80:	a011                	j	80003c84 <dirlookup+0xa0>
  return 0;
    80003c82:	4501                	li	a0,0
}
    80003c84:	70e2                	ld	ra,56(sp)
    80003c86:	7442                	ld	s0,48(sp)
    80003c88:	74a2                	ld	s1,40(sp)
    80003c8a:	7902                	ld	s2,32(sp)
    80003c8c:	69e2                	ld	s3,24(sp)
    80003c8e:	6a42                	ld	s4,16(sp)
    80003c90:	6121                	addi	sp,sp,64
    80003c92:	8082                	ret

0000000080003c94 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c94:	711d                	addi	sp,sp,-96
    80003c96:	ec86                	sd	ra,88(sp)
    80003c98:	e8a2                	sd	s0,80(sp)
    80003c9a:	e4a6                	sd	s1,72(sp)
    80003c9c:	e0ca                	sd	s2,64(sp)
    80003c9e:	fc4e                	sd	s3,56(sp)
    80003ca0:	f852                	sd	s4,48(sp)
    80003ca2:	f456                	sd	s5,40(sp)
    80003ca4:	f05a                	sd	s6,32(sp)
    80003ca6:	ec5e                	sd	s7,24(sp)
    80003ca8:	e862                	sd	s8,16(sp)
    80003caa:	e466                	sd	s9,8(sp)
    80003cac:	1080                	addi	s0,sp,96
    80003cae:	84aa                	mv	s1,a0
    80003cb0:	8aae                	mv	s5,a1
    80003cb2:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003cb4:	00054703          	lbu	a4,0(a0)
    80003cb8:	02f00793          	li	a5,47
    80003cbc:	02f70363          	beq	a4,a5,80003ce2 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003cc0:	ffffe097          	auipc	ra,0xffffe
    80003cc4:	e7c080e7          	jalr	-388(ra) # 80001b3c <myproc>
    80003cc8:	15853503          	ld	a0,344(a0)
    80003ccc:	00000097          	auipc	ra,0x0
    80003cd0:	a22080e7          	jalr	-1502(ra) # 800036ee <idup>
    80003cd4:	89aa                	mv	s3,a0
  while(*path == '/')
    80003cd6:	02f00913          	li	s2,47
  len = path - s;
    80003cda:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003cdc:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003cde:	4b85                	li	s7,1
    80003ce0:	a865                	j	80003d98 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003ce2:	4585                	li	a1,1
    80003ce4:	4501                	li	a0,0
    80003ce6:	fffff097          	auipc	ra,0xfffff
    80003cea:	712080e7          	jalr	1810(ra) # 800033f8 <iget>
    80003cee:	89aa                	mv	s3,a0
    80003cf0:	b7dd                	j	80003cd6 <namex+0x42>
      iunlockput(ip);
    80003cf2:	854e                	mv	a0,s3
    80003cf4:	00000097          	auipc	ra,0x0
    80003cf8:	c76080e7          	jalr	-906(ra) # 8000396a <iunlockput>
      return 0;
    80003cfc:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003cfe:	854e                	mv	a0,s3
    80003d00:	60e6                	ld	ra,88(sp)
    80003d02:	6446                	ld	s0,80(sp)
    80003d04:	64a6                	ld	s1,72(sp)
    80003d06:	6906                	ld	s2,64(sp)
    80003d08:	79e2                	ld	s3,56(sp)
    80003d0a:	7a42                	ld	s4,48(sp)
    80003d0c:	7aa2                	ld	s5,40(sp)
    80003d0e:	7b02                	ld	s6,32(sp)
    80003d10:	6be2                	ld	s7,24(sp)
    80003d12:	6c42                	ld	s8,16(sp)
    80003d14:	6ca2                	ld	s9,8(sp)
    80003d16:	6125                	addi	sp,sp,96
    80003d18:	8082                	ret
      iunlock(ip);
    80003d1a:	854e                	mv	a0,s3
    80003d1c:	00000097          	auipc	ra,0x0
    80003d20:	ad2080e7          	jalr	-1326(ra) # 800037ee <iunlock>
      return ip;
    80003d24:	bfe9                	j	80003cfe <namex+0x6a>
      iunlockput(ip);
    80003d26:	854e                	mv	a0,s3
    80003d28:	00000097          	auipc	ra,0x0
    80003d2c:	c42080e7          	jalr	-958(ra) # 8000396a <iunlockput>
      return 0;
    80003d30:	89e6                	mv	s3,s9
    80003d32:	b7f1                	j	80003cfe <namex+0x6a>
  len = path - s;
    80003d34:	40b48633          	sub	a2,s1,a1
    80003d38:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003d3c:	099c5463          	bge	s8,s9,80003dc4 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003d40:	4639                	li	a2,14
    80003d42:	8552                	mv	a0,s4
    80003d44:	ffffd097          	auipc	ra,0xffffd
    80003d48:	16a080e7          	jalr	362(ra) # 80000eae <memmove>
  while(*path == '/')
    80003d4c:	0004c783          	lbu	a5,0(s1)
    80003d50:	01279763          	bne	a5,s2,80003d5e <namex+0xca>
    path++;
    80003d54:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d56:	0004c783          	lbu	a5,0(s1)
    80003d5a:	ff278de3          	beq	a5,s2,80003d54 <namex+0xc0>
    ilock(ip);
    80003d5e:	854e                	mv	a0,s3
    80003d60:	00000097          	auipc	ra,0x0
    80003d64:	9cc080e7          	jalr	-1588(ra) # 8000372c <ilock>
    if(ip->type != T_DIR){
    80003d68:	04c99783          	lh	a5,76(s3)
    80003d6c:	f97793e3          	bne	a5,s7,80003cf2 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003d70:	000a8563          	beqz	s5,80003d7a <namex+0xe6>
    80003d74:	0004c783          	lbu	a5,0(s1)
    80003d78:	d3cd                	beqz	a5,80003d1a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d7a:	865a                	mv	a2,s6
    80003d7c:	85d2                	mv	a1,s4
    80003d7e:	854e                	mv	a0,s3
    80003d80:	00000097          	auipc	ra,0x0
    80003d84:	e64080e7          	jalr	-412(ra) # 80003be4 <dirlookup>
    80003d88:	8caa                	mv	s9,a0
    80003d8a:	dd51                	beqz	a0,80003d26 <namex+0x92>
    iunlockput(ip);
    80003d8c:	854e                	mv	a0,s3
    80003d8e:	00000097          	auipc	ra,0x0
    80003d92:	bdc080e7          	jalr	-1060(ra) # 8000396a <iunlockput>
    ip = next;
    80003d96:	89e6                	mv	s3,s9
  while(*path == '/')
    80003d98:	0004c783          	lbu	a5,0(s1)
    80003d9c:	05279763          	bne	a5,s2,80003dea <namex+0x156>
    path++;
    80003da0:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003da2:	0004c783          	lbu	a5,0(s1)
    80003da6:	ff278de3          	beq	a5,s2,80003da0 <namex+0x10c>
  if(*path == 0)
    80003daa:	c79d                	beqz	a5,80003dd8 <namex+0x144>
    path++;
    80003dac:	85a6                	mv	a1,s1
  len = path - s;
    80003dae:	8cda                	mv	s9,s6
    80003db0:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003db2:	01278963          	beq	a5,s2,80003dc4 <namex+0x130>
    80003db6:	dfbd                	beqz	a5,80003d34 <namex+0xa0>
    path++;
    80003db8:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003dba:	0004c783          	lbu	a5,0(s1)
    80003dbe:	ff279ce3          	bne	a5,s2,80003db6 <namex+0x122>
    80003dc2:	bf8d                	j	80003d34 <namex+0xa0>
    memmove(name, s, len);
    80003dc4:	2601                	sext.w	a2,a2
    80003dc6:	8552                	mv	a0,s4
    80003dc8:	ffffd097          	auipc	ra,0xffffd
    80003dcc:	0e6080e7          	jalr	230(ra) # 80000eae <memmove>
    name[len] = 0;
    80003dd0:	9cd2                	add	s9,s9,s4
    80003dd2:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003dd6:	bf9d                	j	80003d4c <namex+0xb8>
  if(nameiparent){
    80003dd8:	f20a83e3          	beqz	s5,80003cfe <namex+0x6a>
    iput(ip);
    80003ddc:	854e                	mv	a0,s3
    80003dde:	00000097          	auipc	ra,0x0
    80003de2:	a5c080e7          	jalr	-1444(ra) # 8000383a <iput>
    return 0;
    80003de6:	4981                	li	s3,0
    80003de8:	bf19                	j	80003cfe <namex+0x6a>
  if(*path == 0)
    80003dea:	d7fd                	beqz	a5,80003dd8 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003dec:	0004c783          	lbu	a5,0(s1)
    80003df0:	85a6                	mv	a1,s1
    80003df2:	b7d1                	j	80003db6 <namex+0x122>

0000000080003df4 <dirlink>:
{
    80003df4:	7139                	addi	sp,sp,-64
    80003df6:	fc06                	sd	ra,56(sp)
    80003df8:	f822                	sd	s0,48(sp)
    80003dfa:	f426                	sd	s1,40(sp)
    80003dfc:	f04a                	sd	s2,32(sp)
    80003dfe:	ec4e                	sd	s3,24(sp)
    80003e00:	e852                	sd	s4,16(sp)
    80003e02:	0080                	addi	s0,sp,64
    80003e04:	892a                	mv	s2,a0
    80003e06:	8a2e                	mv	s4,a1
    80003e08:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e0a:	4601                	li	a2,0
    80003e0c:	00000097          	auipc	ra,0x0
    80003e10:	dd8080e7          	jalr	-552(ra) # 80003be4 <dirlookup>
    80003e14:	e93d                	bnez	a0,80003e8a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e16:	05492483          	lw	s1,84(s2)
    80003e1a:	c49d                	beqz	s1,80003e48 <dirlink+0x54>
    80003e1c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e1e:	4741                	li	a4,16
    80003e20:	86a6                	mv	a3,s1
    80003e22:	fc040613          	addi	a2,s0,-64
    80003e26:	4581                	li	a1,0
    80003e28:	854a                	mv	a0,s2
    80003e2a:	00000097          	auipc	ra,0x0
    80003e2e:	b92080e7          	jalr	-1134(ra) # 800039bc <readi>
    80003e32:	47c1                	li	a5,16
    80003e34:	06f51163          	bne	a0,a5,80003e96 <dirlink+0xa2>
    if(de.inum == 0)
    80003e38:	fc045783          	lhu	a5,-64(s0)
    80003e3c:	c791                	beqz	a5,80003e48 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e3e:	24c1                	addiw	s1,s1,16
    80003e40:	05492783          	lw	a5,84(s2)
    80003e44:	fcf4ede3          	bltu	s1,a5,80003e1e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e48:	4639                	li	a2,14
    80003e4a:	85d2                	mv	a1,s4
    80003e4c:	fc240513          	addi	a0,s0,-62
    80003e50:	ffffd097          	auipc	ra,0xffffd
    80003e54:	116080e7          	jalr	278(ra) # 80000f66 <strncpy>
  de.inum = inum;
    80003e58:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e5c:	4741                	li	a4,16
    80003e5e:	86a6                	mv	a3,s1
    80003e60:	fc040613          	addi	a2,s0,-64
    80003e64:	4581                	li	a1,0
    80003e66:	854a                	mv	a0,s2
    80003e68:	00000097          	auipc	ra,0x0
    80003e6c:	c48080e7          	jalr	-952(ra) # 80003ab0 <writei>
    80003e70:	872a                	mv	a4,a0
    80003e72:	47c1                	li	a5,16
  return 0;
    80003e74:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e76:	02f71863          	bne	a4,a5,80003ea6 <dirlink+0xb2>
}
    80003e7a:	70e2                	ld	ra,56(sp)
    80003e7c:	7442                	ld	s0,48(sp)
    80003e7e:	74a2                	ld	s1,40(sp)
    80003e80:	7902                	ld	s2,32(sp)
    80003e82:	69e2                	ld	s3,24(sp)
    80003e84:	6a42                	ld	s4,16(sp)
    80003e86:	6121                	addi	sp,sp,64
    80003e88:	8082                	ret
    iput(ip);
    80003e8a:	00000097          	auipc	ra,0x0
    80003e8e:	9b0080e7          	jalr	-1616(ra) # 8000383a <iput>
    return -1;
    80003e92:	557d                	li	a0,-1
    80003e94:	b7dd                	j	80003e7a <dirlink+0x86>
      panic("dirlink read");
    80003e96:	00005517          	auipc	a0,0x5
    80003e9a:	89a50513          	addi	a0,a0,-1894 # 80008730 <userret+0x6a0>
    80003e9e:	ffffc097          	auipc	ra,0xffffc
    80003ea2:	6aa080e7          	jalr	1706(ra) # 80000548 <panic>
    panic("dirlink");
    80003ea6:	00005517          	auipc	a0,0x5
    80003eaa:	9aa50513          	addi	a0,a0,-1622 # 80008850 <userret+0x7c0>
    80003eae:	ffffc097          	auipc	ra,0xffffc
    80003eb2:	69a080e7          	jalr	1690(ra) # 80000548 <panic>

0000000080003eb6 <namei>:

struct inode*
namei(char *path)
{
    80003eb6:	1101                	addi	sp,sp,-32
    80003eb8:	ec06                	sd	ra,24(sp)
    80003eba:	e822                	sd	s0,16(sp)
    80003ebc:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003ebe:	fe040613          	addi	a2,s0,-32
    80003ec2:	4581                	li	a1,0
    80003ec4:	00000097          	auipc	ra,0x0
    80003ec8:	dd0080e7          	jalr	-560(ra) # 80003c94 <namex>
}
    80003ecc:	60e2                	ld	ra,24(sp)
    80003ece:	6442                	ld	s0,16(sp)
    80003ed0:	6105                	addi	sp,sp,32
    80003ed2:	8082                	ret

0000000080003ed4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003ed4:	1141                	addi	sp,sp,-16
    80003ed6:	e406                	sd	ra,8(sp)
    80003ed8:	e022                	sd	s0,0(sp)
    80003eda:	0800                	addi	s0,sp,16
    80003edc:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003ede:	4585                	li	a1,1
    80003ee0:	00000097          	auipc	ra,0x0
    80003ee4:	db4080e7          	jalr	-588(ra) # 80003c94 <namex>
}
    80003ee8:	60a2                	ld	ra,8(sp)
    80003eea:	6402                	ld	s0,0(sp)
    80003eec:	0141                	addi	sp,sp,16
    80003eee:	8082                	ret

0000000080003ef0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(int dev)
{
    80003ef0:	7179                	addi	sp,sp,-48
    80003ef2:	f406                	sd	ra,40(sp)
    80003ef4:	f022                	sd	s0,32(sp)
    80003ef6:	ec26                	sd	s1,24(sp)
    80003ef8:	e84a                	sd	s2,16(sp)
    80003efa:	e44e                	sd	s3,8(sp)
    80003efc:	1800                	addi	s0,sp,48
    80003efe:	84aa                	mv	s1,a0
  struct buf *buf = bread(dev, log[dev].start);
    80003f00:	0b000993          	li	s3,176
    80003f04:	033507b3          	mul	a5,a0,s3
    80003f08:	00021997          	auipc	s3,0x21
    80003f0c:	eb098993          	addi	s3,s3,-336 # 80024db8 <log>
    80003f10:	99be                	add	s3,s3,a5
    80003f12:	0209a583          	lw	a1,32(s3)
    80003f16:	fffff097          	auipc	ra,0xfffff
    80003f1a:	00e080e7          	jalr	14(ra) # 80002f24 <bread>
    80003f1e:	892a                	mv	s2,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log[dev].lh.n;
    80003f20:	0349a783          	lw	a5,52(s3)
    80003f24:	d13c                	sw	a5,96(a0)
  for (i = 0; i < log[dev].lh.n; i++) {
    80003f26:	0349a783          	lw	a5,52(s3)
    80003f2a:	02f05763          	blez	a5,80003f58 <write_head+0x68>
    80003f2e:	0b000793          	li	a5,176
    80003f32:	02f487b3          	mul	a5,s1,a5
    80003f36:	00021717          	auipc	a4,0x21
    80003f3a:	eba70713          	addi	a4,a4,-326 # 80024df0 <log+0x38>
    80003f3e:	97ba                	add	a5,a5,a4
    80003f40:	06450693          	addi	a3,a0,100
    80003f44:	4701                	li	a4,0
    80003f46:	85ce                	mv	a1,s3
    hb->block[i] = log[dev].lh.block[i];
    80003f48:	4390                	lw	a2,0(a5)
    80003f4a:	c290                	sw	a2,0(a3)
  for (i = 0; i < log[dev].lh.n; i++) {
    80003f4c:	2705                	addiw	a4,a4,1
    80003f4e:	0791                	addi	a5,a5,4
    80003f50:	0691                	addi	a3,a3,4
    80003f52:	59d0                	lw	a2,52(a1)
    80003f54:	fec74ae3          	blt	a4,a2,80003f48 <write_head+0x58>
  }
  bwrite(buf);
    80003f58:	854a                	mv	a0,s2
    80003f5a:	fffff097          	auipc	ra,0xfffff
    80003f5e:	0be080e7          	jalr	190(ra) # 80003018 <bwrite>
  brelse(buf);
    80003f62:	854a                	mv	a0,s2
    80003f64:	fffff097          	auipc	ra,0xfffff
    80003f68:	0f4080e7          	jalr	244(ra) # 80003058 <brelse>
}
    80003f6c:	70a2                	ld	ra,40(sp)
    80003f6e:	7402                	ld	s0,32(sp)
    80003f70:	64e2                	ld	s1,24(sp)
    80003f72:	6942                	ld	s2,16(sp)
    80003f74:	69a2                	ld	s3,8(sp)
    80003f76:	6145                	addi	sp,sp,48
    80003f78:	8082                	ret

0000000080003f7a <install_trans>:
  for (tail = 0; tail < log[dev].lh.n; tail++) {
    80003f7a:	0b000793          	li	a5,176
    80003f7e:	02f50733          	mul	a4,a0,a5
    80003f82:	00021797          	auipc	a5,0x21
    80003f86:	e3678793          	addi	a5,a5,-458 # 80024db8 <log>
    80003f8a:	97ba                	add	a5,a5,a4
    80003f8c:	5bdc                	lw	a5,52(a5)
    80003f8e:	0af05b63          	blez	a5,80004044 <install_trans+0xca>
{
    80003f92:	7139                	addi	sp,sp,-64
    80003f94:	fc06                	sd	ra,56(sp)
    80003f96:	f822                	sd	s0,48(sp)
    80003f98:	f426                	sd	s1,40(sp)
    80003f9a:	f04a                	sd	s2,32(sp)
    80003f9c:	ec4e                	sd	s3,24(sp)
    80003f9e:	e852                	sd	s4,16(sp)
    80003fa0:	e456                	sd	s5,8(sp)
    80003fa2:	e05a                	sd	s6,0(sp)
    80003fa4:	0080                	addi	s0,sp,64
    80003fa6:	00021797          	auipc	a5,0x21
    80003faa:	e4a78793          	addi	a5,a5,-438 # 80024df0 <log+0x38>
    80003fae:	00f70a33          	add	s4,a4,a5
  for (tail = 0; tail < log[dev].lh.n; tail++) {
    80003fb2:	4981                	li	s3,0
    struct buf *lbuf = bread(dev, log[dev].start+tail+1); // read log block
    80003fb4:	00050b1b          	sext.w	s6,a0
    80003fb8:	00021a97          	auipc	s5,0x21
    80003fbc:	e00a8a93          	addi	s5,s5,-512 # 80024db8 <log>
    80003fc0:	9aba                	add	s5,s5,a4
    80003fc2:	020aa583          	lw	a1,32(s5)
    80003fc6:	013585bb          	addw	a1,a1,s3
    80003fca:	2585                	addiw	a1,a1,1
    80003fcc:	855a                	mv	a0,s6
    80003fce:	fffff097          	auipc	ra,0xfffff
    80003fd2:	f56080e7          	jalr	-170(ra) # 80002f24 <bread>
    80003fd6:	892a                	mv	s2,a0
    struct buf *dbuf = bread(dev, log[dev].lh.block[tail]); // read dst
    80003fd8:	000a2583          	lw	a1,0(s4)
    80003fdc:	855a                	mv	a0,s6
    80003fde:	fffff097          	auipc	ra,0xfffff
    80003fe2:	f46080e7          	jalr	-186(ra) # 80002f24 <bread>
    80003fe6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003fe8:	40000613          	li	a2,1024
    80003fec:	06090593          	addi	a1,s2,96
    80003ff0:	06050513          	addi	a0,a0,96
    80003ff4:	ffffd097          	auipc	ra,0xffffd
    80003ff8:	eba080e7          	jalr	-326(ra) # 80000eae <memmove>
    bwrite(dbuf);  // write dst to disk
    80003ffc:	8526                	mv	a0,s1
    80003ffe:	fffff097          	auipc	ra,0xfffff
    80004002:	01a080e7          	jalr	26(ra) # 80003018 <bwrite>
    bunpin(dbuf);
    80004006:	8526                	mv	a0,s1
    80004008:	fffff097          	auipc	ra,0xfffff
    8000400c:	12a080e7          	jalr	298(ra) # 80003132 <bunpin>
    brelse(lbuf);
    80004010:	854a                	mv	a0,s2
    80004012:	fffff097          	auipc	ra,0xfffff
    80004016:	046080e7          	jalr	70(ra) # 80003058 <brelse>
    brelse(dbuf);
    8000401a:	8526                	mv	a0,s1
    8000401c:	fffff097          	auipc	ra,0xfffff
    80004020:	03c080e7          	jalr	60(ra) # 80003058 <brelse>
  for (tail = 0; tail < log[dev].lh.n; tail++) {
    80004024:	2985                	addiw	s3,s3,1
    80004026:	0a11                	addi	s4,s4,4
    80004028:	034aa783          	lw	a5,52(s5)
    8000402c:	f8f9cbe3          	blt	s3,a5,80003fc2 <install_trans+0x48>
}
    80004030:	70e2                	ld	ra,56(sp)
    80004032:	7442                	ld	s0,48(sp)
    80004034:	74a2                	ld	s1,40(sp)
    80004036:	7902                	ld	s2,32(sp)
    80004038:	69e2                	ld	s3,24(sp)
    8000403a:	6a42                	ld	s4,16(sp)
    8000403c:	6aa2                	ld	s5,8(sp)
    8000403e:	6b02                	ld	s6,0(sp)
    80004040:	6121                	addi	sp,sp,64
    80004042:	8082                	ret
    80004044:	8082                	ret

0000000080004046 <initlog>:
{
    80004046:	7179                	addi	sp,sp,-48
    80004048:	f406                	sd	ra,40(sp)
    8000404a:	f022                	sd	s0,32(sp)
    8000404c:	ec26                	sd	s1,24(sp)
    8000404e:	e84a                	sd	s2,16(sp)
    80004050:	e44e                	sd	s3,8(sp)
    80004052:	e052                	sd	s4,0(sp)
    80004054:	1800                	addi	s0,sp,48
    80004056:	892a                	mv	s2,a0
    80004058:	8a2e                	mv	s4,a1
  initlock(&log[dev].lock, "log");
    8000405a:	0b000713          	li	a4,176
    8000405e:	02e504b3          	mul	s1,a0,a4
    80004062:	00021997          	auipc	s3,0x21
    80004066:	d5698993          	addi	s3,s3,-682 # 80024db8 <log>
    8000406a:	99a6                	add	s3,s3,s1
    8000406c:	00004597          	auipc	a1,0x4
    80004070:	6d458593          	addi	a1,a1,1748 # 80008740 <userret+0x6b0>
    80004074:	854e                	mv	a0,s3
    80004076:	ffffd097          	auipc	ra,0xffffd
    8000407a:	a20080e7          	jalr	-1504(ra) # 80000a96 <initlock>
  log[dev].start = sb->logstart;
    8000407e:	014a2583          	lw	a1,20(s4)
    80004082:	02b9a023          	sw	a1,32(s3)
  log[dev].size = sb->nlog;
    80004086:	010a2783          	lw	a5,16(s4)
    8000408a:	02f9a223          	sw	a5,36(s3)
  log[dev].dev = dev;
    8000408e:	0329a823          	sw	s2,48(s3)
  struct buf *buf = bread(dev, log[dev].start);
    80004092:	854a                	mv	a0,s2
    80004094:	fffff097          	auipc	ra,0xfffff
    80004098:	e90080e7          	jalr	-368(ra) # 80002f24 <bread>
  log[dev].lh.n = lh->n;
    8000409c:	5134                	lw	a3,96(a0)
    8000409e:	02d9aa23          	sw	a3,52(s3)
  for (i = 0; i < log[dev].lh.n; i++) {
    800040a2:	02d05763          	blez	a3,800040d0 <initlog+0x8a>
    800040a6:	06450793          	addi	a5,a0,100
    800040aa:	00021717          	auipc	a4,0x21
    800040ae:	d4670713          	addi	a4,a4,-698 # 80024df0 <log+0x38>
    800040b2:	9726                	add	a4,a4,s1
    800040b4:	36fd                	addiw	a3,a3,-1
    800040b6:	02069613          	slli	a2,a3,0x20
    800040ba:	01e65693          	srli	a3,a2,0x1e
    800040be:	06850613          	addi	a2,a0,104
    800040c2:	96b2                	add	a3,a3,a2
    log[dev].lh.block[i] = lh->block[i];
    800040c4:	4390                	lw	a2,0(a5)
    800040c6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log[dev].lh.n; i++) {
    800040c8:	0791                	addi	a5,a5,4
    800040ca:	0711                	addi	a4,a4,4
    800040cc:	fed79ce3          	bne	a5,a3,800040c4 <initlog+0x7e>
  brelse(buf);
    800040d0:	fffff097          	auipc	ra,0xfffff
    800040d4:	f88080e7          	jalr	-120(ra) # 80003058 <brelse>

static void
recover_from_log(int dev)
{
  read_head(dev);
  install_trans(dev); // if committed, copy from log to disk
    800040d8:	854a                	mv	a0,s2
    800040da:	00000097          	auipc	ra,0x0
    800040de:	ea0080e7          	jalr	-352(ra) # 80003f7a <install_trans>
  log[dev].lh.n = 0;
    800040e2:	0b000793          	li	a5,176
    800040e6:	02f90733          	mul	a4,s2,a5
    800040ea:	00021797          	auipc	a5,0x21
    800040ee:	cce78793          	addi	a5,a5,-818 # 80024db8 <log>
    800040f2:	97ba                	add	a5,a5,a4
    800040f4:	0207aa23          	sw	zero,52(a5)
  write_head(dev); // clear the log
    800040f8:	854a                	mv	a0,s2
    800040fa:	00000097          	auipc	ra,0x0
    800040fe:	df6080e7          	jalr	-522(ra) # 80003ef0 <write_head>
}
    80004102:	70a2                	ld	ra,40(sp)
    80004104:	7402                	ld	s0,32(sp)
    80004106:	64e2                	ld	s1,24(sp)
    80004108:	6942                	ld	s2,16(sp)
    8000410a:	69a2                	ld	s3,8(sp)
    8000410c:	6a02                	ld	s4,0(sp)
    8000410e:	6145                	addi	sp,sp,48
    80004110:	8082                	ret

0000000080004112 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(int dev)
{
    80004112:	7139                	addi	sp,sp,-64
    80004114:	fc06                	sd	ra,56(sp)
    80004116:	f822                	sd	s0,48(sp)
    80004118:	f426                	sd	s1,40(sp)
    8000411a:	f04a                	sd	s2,32(sp)
    8000411c:	ec4e                	sd	s3,24(sp)
    8000411e:	e852                	sd	s4,16(sp)
    80004120:	e456                	sd	s5,8(sp)
    80004122:	0080                	addi	s0,sp,64
    80004124:	8aaa                	mv	s5,a0
  acquire(&log[dev].lock);
    80004126:	0b000913          	li	s2,176
    8000412a:	032507b3          	mul	a5,a0,s2
    8000412e:	00021917          	auipc	s2,0x21
    80004132:	c8a90913          	addi	s2,s2,-886 # 80024db8 <log>
    80004136:	993e                	add	s2,s2,a5
    80004138:	854a                	mv	a0,s2
    8000413a:	ffffd097          	auipc	ra,0xffffd
    8000413e:	aaa080e7          	jalr	-1366(ra) # 80000be4 <acquire>
  while(1){
    if(log[dev].committing){
    80004142:	00021997          	auipc	s3,0x21
    80004146:	c7698993          	addi	s3,s3,-906 # 80024db8 <log>
    8000414a:	84ca                	mv	s1,s2
      sleep(&log, &log[dev].lock);
    } else if(log[dev].lh.n + (log[dev].outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000414c:	4a79                	li	s4,30
    8000414e:	a039                	j	8000415c <begin_op+0x4a>
      sleep(&log, &log[dev].lock);
    80004150:	85ca                	mv	a1,s2
    80004152:	854e                	mv	a0,s3
    80004154:	ffffe097          	auipc	ra,0xffffe
    80004158:	1be080e7          	jalr	446(ra) # 80002312 <sleep>
    if(log[dev].committing){
    8000415c:	54dc                	lw	a5,44(s1)
    8000415e:	fbed                	bnez	a5,80004150 <begin_op+0x3e>
    } else if(log[dev].lh.n + (log[dev].outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004160:	549c                	lw	a5,40(s1)
    80004162:	0017871b          	addiw	a4,a5,1
    80004166:	0007069b          	sext.w	a3,a4
    8000416a:	0027179b          	slliw	a5,a4,0x2
    8000416e:	9fb9                	addw	a5,a5,a4
    80004170:	0017979b          	slliw	a5,a5,0x1
    80004174:	58d8                	lw	a4,52(s1)
    80004176:	9fb9                	addw	a5,a5,a4
    80004178:	00fa5963          	bge	s4,a5,8000418a <begin_op+0x78>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log[dev].lock);
    8000417c:	85ca                	mv	a1,s2
    8000417e:	854e                	mv	a0,s3
    80004180:	ffffe097          	auipc	ra,0xffffe
    80004184:	192080e7          	jalr	402(ra) # 80002312 <sleep>
    80004188:	bfd1                	j	8000415c <begin_op+0x4a>
    } else {
      log[dev].outstanding += 1;
    8000418a:	0b000513          	li	a0,176
    8000418e:	02aa8ab3          	mul	s5,s5,a0
    80004192:	00021797          	auipc	a5,0x21
    80004196:	c2678793          	addi	a5,a5,-986 # 80024db8 <log>
    8000419a:	9abe                	add	s5,s5,a5
    8000419c:	02daa423          	sw	a3,40(s5)
      release(&log[dev].lock);
    800041a0:	854a                	mv	a0,s2
    800041a2:	ffffd097          	auipc	ra,0xffffd
    800041a6:	ab2080e7          	jalr	-1358(ra) # 80000c54 <release>
      break;
    }
  }
}
    800041aa:	70e2                	ld	ra,56(sp)
    800041ac:	7442                	ld	s0,48(sp)
    800041ae:	74a2                	ld	s1,40(sp)
    800041b0:	7902                	ld	s2,32(sp)
    800041b2:	69e2                	ld	s3,24(sp)
    800041b4:	6a42                	ld	s4,16(sp)
    800041b6:	6aa2                	ld	s5,8(sp)
    800041b8:	6121                	addi	sp,sp,64
    800041ba:	8082                	ret

00000000800041bc <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(int dev)
{
    800041bc:	715d                	addi	sp,sp,-80
    800041be:	e486                	sd	ra,72(sp)
    800041c0:	e0a2                	sd	s0,64(sp)
    800041c2:	fc26                	sd	s1,56(sp)
    800041c4:	f84a                	sd	s2,48(sp)
    800041c6:	f44e                	sd	s3,40(sp)
    800041c8:	f052                	sd	s4,32(sp)
    800041ca:	ec56                	sd	s5,24(sp)
    800041cc:	e85a                	sd	s6,16(sp)
    800041ce:	e45e                	sd	s7,8(sp)
    800041d0:	e062                	sd	s8,0(sp)
    800041d2:	0880                	addi	s0,sp,80
    800041d4:	89aa                	mv	s3,a0
  int do_commit = 0;

  acquire(&log[dev].lock);
    800041d6:	0b000913          	li	s2,176
    800041da:	03250933          	mul	s2,a0,s2
    800041de:	00021497          	auipc	s1,0x21
    800041e2:	bda48493          	addi	s1,s1,-1062 # 80024db8 <log>
    800041e6:	94ca                	add	s1,s1,s2
    800041e8:	8526                	mv	a0,s1
    800041ea:	ffffd097          	auipc	ra,0xffffd
    800041ee:	9fa080e7          	jalr	-1542(ra) # 80000be4 <acquire>
  log[dev].outstanding -= 1;
    800041f2:	549c                	lw	a5,40(s1)
    800041f4:	37fd                	addiw	a5,a5,-1
    800041f6:	00078a9b          	sext.w	s5,a5
    800041fa:	d49c                	sw	a5,40(s1)
  if(log[dev].committing)
    800041fc:	54dc                	lw	a5,44(s1)
    800041fe:	e3b5                	bnez	a5,80004262 <end_op+0xa6>
    panic("log[dev].committing");
  if(log[dev].outstanding == 0){
    80004200:	060a9963          	bnez	s5,80004272 <end_op+0xb6>
    do_commit = 1;
    log[dev].committing = 1;
    80004204:	0b000a13          	li	s4,176
    80004208:	034987b3          	mul	a5,s3,s4
    8000420c:	00021a17          	auipc	s4,0x21
    80004210:	baca0a13          	addi	s4,s4,-1108 # 80024db8 <log>
    80004214:	9a3e                	add	s4,s4,a5
    80004216:	4785                	li	a5,1
    80004218:	02fa2623          	sw	a5,44(s4)
    // begin_op() may be waiting for log space,
    // and decrementing log[dev].outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log[dev].lock);
    8000421c:	8526                	mv	a0,s1
    8000421e:	ffffd097          	auipc	ra,0xffffd
    80004222:	a36080e7          	jalr	-1482(ra) # 80000c54 <release>
}

static void
commit(int dev)
{
  if (log[dev].lh.n > 0) {
    80004226:	034a2783          	lw	a5,52(s4)
    8000422a:	06f04d63          	bgtz	a5,800042a4 <end_op+0xe8>
    acquire(&log[dev].lock);
    8000422e:	8526                	mv	a0,s1
    80004230:	ffffd097          	auipc	ra,0xffffd
    80004234:	9b4080e7          	jalr	-1612(ra) # 80000be4 <acquire>
    log[dev].committing = 0;
    80004238:	00021517          	auipc	a0,0x21
    8000423c:	b8050513          	addi	a0,a0,-1152 # 80024db8 <log>
    80004240:	0b000793          	li	a5,176
    80004244:	02f989b3          	mul	s3,s3,a5
    80004248:	99aa                	add	s3,s3,a0
    8000424a:	0209a623          	sw	zero,44(s3)
    wakeup(&log);
    8000424e:	ffffe097          	auipc	ra,0xffffe
    80004252:	244080e7          	jalr	580(ra) # 80002492 <wakeup>
    release(&log[dev].lock);
    80004256:	8526                	mv	a0,s1
    80004258:	ffffd097          	auipc	ra,0xffffd
    8000425c:	9fc080e7          	jalr	-1540(ra) # 80000c54 <release>
}
    80004260:	a035                	j	8000428c <end_op+0xd0>
    panic("log[dev].committing");
    80004262:	00004517          	auipc	a0,0x4
    80004266:	4e650513          	addi	a0,a0,1254 # 80008748 <userret+0x6b8>
    8000426a:	ffffc097          	auipc	ra,0xffffc
    8000426e:	2de080e7          	jalr	734(ra) # 80000548 <panic>
    wakeup(&log);
    80004272:	00021517          	auipc	a0,0x21
    80004276:	b4650513          	addi	a0,a0,-1210 # 80024db8 <log>
    8000427a:	ffffe097          	auipc	ra,0xffffe
    8000427e:	218080e7          	jalr	536(ra) # 80002492 <wakeup>
  release(&log[dev].lock);
    80004282:	8526                	mv	a0,s1
    80004284:	ffffd097          	auipc	ra,0xffffd
    80004288:	9d0080e7          	jalr	-1584(ra) # 80000c54 <release>
}
    8000428c:	60a6                	ld	ra,72(sp)
    8000428e:	6406                	ld	s0,64(sp)
    80004290:	74e2                	ld	s1,56(sp)
    80004292:	7942                	ld	s2,48(sp)
    80004294:	79a2                	ld	s3,40(sp)
    80004296:	7a02                	ld	s4,32(sp)
    80004298:	6ae2                	ld	s5,24(sp)
    8000429a:	6b42                	ld	s6,16(sp)
    8000429c:	6ba2                	ld	s7,8(sp)
    8000429e:	6c02                	ld	s8,0(sp)
    800042a0:	6161                	addi	sp,sp,80
    800042a2:	8082                	ret
  for (tail = 0; tail < log[dev].lh.n; tail++) {
    800042a4:	00021797          	auipc	a5,0x21
    800042a8:	b4c78793          	addi	a5,a5,-1204 # 80024df0 <log+0x38>
    800042ac:	993e                	add	s2,s2,a5
    struct buf *to = bread(dev, log[dev].start+tail+1); // log block
    800042ae:	00098c1b          	sext.w	s8,s3
    800042b2:	0b000b93          	li	s7,176
    800042b6:	037987b3          	mul	a5,s3,s7
    800042ba:	00021b97          	auipc	s7,0x21
    800042be:	afeb8b93          	addi	s7,s7,-1282 # 80024db8 <log>
    800042c2:	9bbe                	add	s7,s7,a5
    800042c4:	020ba583          	lw	a1,32(s7)
    800042c8:	015585bb          	addw	a1,a1,s5
    800042cc:	2585                	addiw	a1,a1,1
    800042ce:	8562                	mv	a0,s8
    800042d0:	fffff097          	auipc	ra,0xfffff
    800042d4:	c54080e7          	jalr	-940(ra) # 80002f24 <bread>
    800042d8:	8a2a                	mv	s4,a0
    struct buf *from = bread(dev, log[dev].lh.block[tail]); // cache block
    800042da:	00092583          	lw	a1,0(s2)
    800042de:	8562                	mv	a0,s8
    800042e0:	fffff097          	auipc	ra,0xfffff
    800042e4:	c44080e7          	jalr	-956(ra) # 80002f24 <bread>
    800042e8:	8b2a                	mv	s6,a0
    memmove(to->data, from->data, BSIZE);
    800042ea:	40000613          	li	a2,1024
    800042ee:	06050593          	addi	a1,a0,96
    800042f2:	060a0513          	addi	a0,s4,96
    800042f6:	ffffd097          	auipc	ra,0xffffd
    800042fa:	bb8080e7          	jalr	-1096(ra) # 80000eae <memmove>
    bwrite(to);  // write the log
    800042fe:	8552                	mv	a0,s4
    80004300:	fffff097          	auipc	ra,0xfffff
    80004304:	d18080e7          	jalr	-744(ra) # 80003018 <bwrite>
    brelse(from);
    80004308:	855a                	mv	a0,s6
    8000430a:	fffff097          	auipc	ra,0xfffff
    8000430e:	d4e080e7          	jalr	-690(ra) # 80003058 <brelse>
    brelse(to);
    80004312:	8552                	mv	a0,s4
    80004314:	fffff097          	auipc	ra,0xfffff
    80004318:	d44080e7          	jalr	-700(ra) # 80003058 <brelse>
  for (tail = 0; tail < log[dev].lh.n; tail++) {
    8000431c:	2a85                	addiw	s5,s5,1
    8000431e:	0911                	addi	s2,s2,4
    80004320:	034ba783          	lw	a5,52(s7)
    80004324:	fafac0e3          	blt	s5,a5,800042c4 <end_op+0x108>
    write_log(dev);     // Write modified blocks from cache to log
    write_head(dev);    // Write header to disk -- the real commit
    80004328:	854e                	mv	a0,s3
    8000432a:	00000097          	auipc	ra,0x0
    8000432e:	bc6080e7          	jalr	-1082(ra) # 80003ef0 <write_head>
    install_trans(dev); // Now install writes to home locations
    80004332:	854e                	mv	a0,s3
    80004334:	00000097          	auipc	ra,0x0
    80004338:	c46080e7          	jalr	-954(ra) # 80003f7a <install_trans>
    log[dev].lh.n = 0;
    8000433c:	0b000793          	li	a5,176
    80004340:	02f98733          	mul	a4,s3,a5
    80004344:	00021797          	auipc	a5,0x21
    80004348:	a7478793          	addi	a5,a5,-1420 # 80024db8 <log>
    8000434c:	97ba                	add	a5,a5,a4
    8000434e:	0207aa23          	sw	zero,52(a5)
    write_head(dev);    // Erase the transaction from the log
    80004352:	854e                	mv	a0,s3
    80004354:	00000097          	auipc	ra,0x0
    80004358:	b9c080e7          	jalr	-1124(ra) # 80003ef0 <write_head>
    8000435c:	bdc9                	j	8000422e <end_op+0x72>

000000008000435e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000435e:	7179                	addi	sp,sp,-48
    80004360:	f406                	sd	ra,40(sp)
    80004362:	f022                	sd	s0,32(sp)
    80004364:	ec26                	sd	s1,24(sp)
    80004366:	e84a                	sd	s2,16(sp)
    80004368:	e44e                	sd	s3,8(sp)
    8000436a:	e052                	sd	s4,0(sp)
    8000436c:	1800                	addi	s0,sp,48
  int i;

  int dev = b->dev;
    8000436e:	00852903          	lw	s2,8(a0)
  if (log[dev].lh.n >= LOGSIZE || log[dev].lh.n >= log[dev].size - 1)
    80004372:	0b000793          	li	a5,176
    80004376:	02f90733          	mul	a4,s2,a5
    8000437a:	00021797          	auipc	a5,0x21
    8000437e:	a3e78793          	addi	a5,a5,-1474 # 80024db8 <log>
    80004382:	97ba                	add	a5,a5,a4
    80004384:	5bd4                	lw	a3,52(a5)
    80004386:	47f5                	li	a5,29
    80004388:	0ad7cc63          	blt	a5,a3,80004440 <log_write+0xe2>
    8000438c:	89aa                	mv	s3,a0
    8000438e:	00021797          	auipc	a5,0x21
    80004392:	a2a78793          	addi	a5,a5,-1494 # 80024db8 <log>
    80004396:	97ba                	add	a5,a5,a4
    80004398:	53dc                	lw	a5,36(a5)
    8000439a:	37fd                	addiw	a5,a5,-1
    8000439c:	0af6d263          	bge	a3,a5,80004440 <log_write+0xe2>
    panic("too big a transaction");
  if (log[dev].outstanding < 1)
    800043a0:	0b000793          	li	a5,176
    800043a4:	02f90733          	mul	a4,s2,a5
    800043a8:	00021797          	auipc	a5,0x21
    800043ac:	a1078793          	addi	a5,a5,-1520 # 80024db8 <log>
    800043b0:	97ba                	add	a5,a5,a4
    800043b2:	579c                	lw	a5,40(a5)
    800043b4:	08f05e63          	blez	a5,80004450 <log_write+0xf2>
    panic("log_write outside of trans");

  acquire(&log[dev].lock);
    800043b8:	0b000793          	li	a5,176
    800043bc:	02f904b3          	mul	s1,s2,a5
    800043c0:	00021a17          	auipc	s4,0x21
    800043c4:	9f8a0a13          	addi	s4,s4,-1544 # 80024db8 <log>
    800043c8:	9a26                	add	s4,s4,s1
    800043ca:	8552                	mv	a0,s4
    800043cc:	ffffd097          	auipc	ra,0xffffd
    800043d0:	818080e7          	jalr	-2024(ra) # 80000be4 <acquire>
  for (i = 0; i < log[dev].lh.n; i++) {
    800043d4:	034a2603          	lw	a2,52(s4)
    800043d8:	08c05463          	blez	a2,80004460 <log_write+0x102>
    if (log[dev].lh.block[i] == b->blockno)   // log absorbtion
    800043dc:	00c9a583          	lw	a1,12(s3)
    800043e0:	00021797          	auipc	a5,0x21
    800043e4:	a1078793          	addi	a5,a5,-1520 # 80024df0 <log+0x38>
    800043e8:	97a6                	add	a5,a5,s1
  for (i = 0; i < log[dev].lh.n; i++) {
    800043ea:	4701                	li	a4,0
    if (log[dev].lh.block[i] == b->blockno)   // log absorbtion
    800043ec:	4394                	lw	a3,0(a5)
    800043ee:	06b68a63          	beq	a3,a1,80004462 <log_write+0x104>
  for (i = 0; i < log[dev].lh.n; i++) {
    800043f2:	2705                	addiw	a4,a4,1
    800043f4:	0791                	addi	a5,a5,4
    800043f6:	fec71be3          	bne	a4,a2,800043ec <log_write+0x8e>
      break;
  }
  log[dev].lh.block[i] = b->blockno;
    800043fa:	02c00793          	li	a5,44
    800043fe:	02f907b3          	mul	a5,s2,a5
    80004402:	97b2                	add	a5,a5,a2
    80004404:	07b1                	addi	a5,a5,12
    80004406:	078a                	slli	a5,a5,0x2
    80004408:	00021717          	auipc	a4,0x21
    8000440c:	9b070713          	addi	a4,a4,-1616 # 80024db8 <log>
    80004410:	97ba                	add	a5,a5,a4
    80004412:	00c9a703          	lw	a4,12(s3)
    80004416:	c798                	sw	a4,8(a5)
  if (i == log[dev].lh.n) {  // Add new block to log?
    bpin(b);
    80004418:	854e                	mv	a0,s3
    8000441a:	fffff097          	auipc	ra,0xfffff
    8000441e:	cdc080e7          	jalr	-804(ra) # 800030f6 <bpin>
    log[dev].lh.n++;
    80004422:	0b000793          	li	a5,176
    80004426:	02f90933          	mul	s2,s2,a5
    8000442a:	00021797          	auipc	a5,0x21
    8000442e:	98e78793          	addi	a5,a5,-1650 # 80024db8 <log>
    80004432:	993e                	add	s2,s2,a5
    80004434:	03492783          	lw	a5,52(s2)
    80004438:	2785                	addiw	a5,a5,1
    8000443a:	02f92a23          	sw	a5,52(s2)
    8000443e:	a099                	j	80004484 <log_write+0x126>
    panic("too big a transaction");
    80004440:	00004517          	auipc	a0,0x4
    80004444:	32050513          	addi	a0,a0,800 # 80008760 <userret+0x6d0>
    80004448:	ffffc097          	auipc	ra,0xffffc
    8000444c:	100080e7          	jalr	256(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    80004450:	00004517          	auipc	a0,0x4
    80004454:	32850513          	addi	a0,a0,808 # 80008778 <userret+0x6e8>
    80004458:	ffffc097          	auipc	ra,0xffffc
    8000445c:	0f0080e7          	jalr	240(ra) # 80000548 <panic>
  for (i = 0; i < log[dev].lh.n; i++) {
    80004460:	4701                	li	a4,0
  log[dev].lh.block[i] = b->blockno;
    80004462:	02c00793          	li	a5,44
    80004466:	02f907b3          	mul	a5,s2,a5
    8000446a:	97ba                	add	a5,a5,a4
    8000446c:	07b1                	addi	a5,a5,12
    8000446e:	078a                	slli	a5,a5,0x2
    80004470:	00021697          	auipc	a3,0x21
    80004474:	94868693          	addi	a3,a3,-1720 # 80024db8 <log>
    80004478:	97b6                	add	a5,a5,a3
    8000447a:	00c9a683          	lw	a3,12(s3)
    8000447e:	c794                	sw	a3,8(a5)
  if (i == log[dev].lh.n) {  // Add new block to log?
    80004480:	f8e60ce3          	beq	a2,a4,80004418 <log_write+0xba>
  }
  release(&log[dev].lock);
    80004484:	8552                	mv	a0,s4
    80004486:	ffffc097          	auipc	ra,0xffffc
    8000448a:	7ce080e7          	jalr	1998(ra) # 80000c54 <release>
}
    8000448e:	70a2                	ld	ra,40(sp)
    80004490:	7402                	ld	s0,32(sp)
    80004492:	64e2                	ld	s1,24(sp)
    80004494:	6942                	ld	s2,16(sp)
    80004496:	69a2                	ld	s3,8(sp)
    80004498:	6a02                	ld	s4,0(sp)
    8000449a:	6145                	addi	sp,sp,48
    8000449c:	8082                	ret

000000008000449e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000449e:	1101                	addi	sp,sp,-32
    800044a0:	ec06                	sd	ra,24(sp)
    800044a2:	e822                	sd	s0,16(sp)
    800044a4:	e426                	sd	s1,8(sp)
    800044a6:	e04a                	sd	s2,0(sp)
    800044a8:	1000                	addi	s0,sp,32
    800044aa:	84aa                	mv	s1,a0
    800044ac:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800044ae:	00004597          	auipc	a1,0x4
    800044b2:	2ea58593          	addi	a1,a1,746 # 80008798 <userret+0x708>
    800044b6:	0521                	addi	a0,a0,8
    800044b8:	ffffc097          	auipc	ra,0xffffc
    800044bc:	5de080e7          	jalr	1502(ra) # 80000a96 <initlock>
  lk->name = name;
    800044c0:	0324b423          	sd	s2,40(s1)
  lk->locked = 0;
    800044c4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044c8:	0204a823          	sw	zero,48(s1)
}
    800044cc:	60e2                	ld	ra,24(sp)
    800044ce:	6442                	ld	s0,16(sp)
    800044d0:	64a2                	ld	s1,8(sp)
    800044d2:	6902                	ld	s2,0(sp)
    800044d4:	6105                	addi	sp,sp,32
    800044d6:	8082                	ret

00000000800044d8 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800044d8:	1101                	addi	sp,sp,-32
    800044da:	ec06                	sd	ra,24(sp)
    800044dc:	e822                	sd	s0,16(sp)
    800044de:	e426                	sd	s1,8(sp)
    800044e0:	e04a                	sd	s2,0(sp)
    800044e2:	1000                	addi	s0,sp,32
    800044e4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044e6:	00850913          	addi	s2,a0,8
    800044ea:	854a                	mv	a0,s2
    800044ec:	ffffc097          	auipc	ra,0xffffc
    800044f0:	6f8080e7          	jalr	1784(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800044f4:	409c                	lw	a5,0(s1)
    800044f6:	cb89                	beqz	a5,80004508 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800044f8:	85ca                	mv	a1,s2
    800044fa:	8526                	mv	a0,s1
    800044fc:	ffffe097          	auipc	ra,0xffffe
    80004500:	e16080e7          	jalr	-490(ra) # 80002312 <sleep>
  while (lk->locked) {
    80004504:	409c                	lw	a5,0(s1)
    80004506:	fbed                	bnez	a5,800044f8 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004508:	4785                	li	a5,1
    8000450a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000450c:	ffffd097          	auipc	ra,0xffffd
    80004510:	630080e7          	jalr	1584(ra) # 80001b3c <myproc>
    80004514:	413c                	lw	a5,64(a0)
    80004516:	d89c                	sw	a5,48(s1)
  release(&lk->lk);
    80004518:	854a                	mv	a0,s2
    8000451a:	ffffc097          	auipc	ra,0xffffc
    8000451e:	73a080e7          	jalr	1850(ra) # 80000c54 <release>
}
    80004522:	60e2                	ld	ra,24(sp)
    80004524:	6442                	ld	s0,16(sp)
    80004526:	64a2                	ld	s1,8(sp)
    80004528:	6902                	ld	s2,0(sp)
    8000452a:	6105                	addi	sp,sp,32
    8000452c:	8082                	ret

000000008000452e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000452e:	1101                	addi	sp,sp,-32
    80004530:	ec06                	sd	ra,24(sp)
    80004532:	e822                	sd	s0,16(sp)
    80004534:	e426                	sd	s1,8(sp)
    80004536:	e04a                	sd	s2,0(sp)
    80004538:	1000                	addi	s0,sp,32
    8000453a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000453c:	00850913          	addi	s2,a0,8
    80004540:	854a                	mv	a0,s2
    80004542:	ffffc097          	auipc	ra,0xffffc
    80004546:	6a2080e7          	jalr	1698(ra) # 80000be4 <acquire>
  lk->locked = 0;
    8000454a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000454e:	0204a823          	sw	zero,48(s1)
  wakeup(lk);
    80004552:	8526                	mv	a0,s1
    80004554:	ffffe097          	auipc	ra,0xffffe
    80004558:	f3e080e7          	jalr	-194(ra) # 80002492 <wakeup>
  release(&lk->lk);
    8000455c:	854a                	mv	a0,s2
    8000455e:	ffffc097          	auipc	ra,0xffffc
    80004562:	6f6080e7          	jalr	1782(ra) # 80000c54 <release>
}
    80004566:	60e2                	ld	ra,24(sp)
    80004568:	6442                	ld	s0,16(sp)
    8000456a:	64a2                	ld	s1,8(sp)
    8000456c:	6902                	ld	s2,0(sp)
    8000456e:	6105                	addi	sp,sp,32
    80004570:	8082                	ret

0000000080004572 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004572:	7179                	addi	sp,sp,-48
    80004574:	f406                	sd	ra,40(sp)
    80004576:	f022                	sd	s0,32(sp)
    80004578:	ec26                	sd	s1,24(sp)
    8000457a:	e84a                	sd	s2,16(sp)
    8000457c:	e44e                	sd	s3,8(sp)
    8000457e:	1800                	addi	s0,sp,48
    80004580:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004582:	00850913          	addi	s2,a0,8
    80004586:	854a                	mv	a0,s2
    80004588:	ffffc097          	auipc	ra,0xffffc
    8000458c:	65c080e7          	jalr	1628(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004590:	409c                	lw	a5,0(s1)
    80004592:	ef99                	bnez	a5,800045b0 <holdingsleep+0x3e>
    80004594:	4481                	li	s1,0
  release(&lk->lk);
    80004596:	854a                	mv	a0,s2
    80004598:	ffffc097          	auipc	ra,0xffffc
    8000459c:	6bc080e7          	jalr	1724(ra) # 80000c54 <release>
  return r;
}
    800045a0:	8526                	mv	a0,s1
    800045a2:	70a2                	ld	ra,40(sp)
    800045a4:	7402                	ld	s0,32(sp)
    800045a6:	64e2                	ld	s1,24(sp)
    800045a8:	6942                	ld	s2,16(sp)
    800045aa:	69a2                	ld	s3,8(sp)
    800045ac:	6145                	addi	sp,sp,48
    800045ae:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800045b0:	0304a983          	lw	s3,48(s1)
    800045b4:	ffffd097          	auipc	ra,0xffffd
    800045b8:	588080e7          	jalr	1416(ra) # 80001b3c <myproc>
    800045bc:	4124                	lw	s1,64(a0)
    800045be:	413484b3          	sub	s1,s1,s3
    800045c2:	0014b493          	seqz	s1,s1
    800045c6:	bfc1                	j	80004596 <holdingsleep+0x24>

00000000800045c8 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800045c8:	1141                	addi	sp,sp,-16
    800045ca:	e406                	sd	ra,8(sp)
    800045cc:	e022                	sd	s0,0(sp)
    800045ce:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800045d0:	00004597          	auipc	a1,0x4
    800045d4:	1d858593          	addi	a1,a1,472 # 800087a8 <userret+0x718>
    800045d8:	00021517          	auipc	a0,0x21
    800045dc:	9e050513          	addi	a0,a0,-1568 # 80024fb8 <ftable>
    800045e0:	ffffc097          	auipc	ra,0xffffc
    800045e4:	4b6080e7          	jalr	1206(ra) # 80000a96 <initlock>
}
    800045e8:	60a2                	ld	ra,8(sp)
    800045ea:	6402                	ld	s0,0(sp)
    800045ec:	0141                	addi	sp,sp,16
    800045ee:	8082                	ret

00000000800045f0 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800045f0:	1101                	addi	sp,sp,-32
    800045f2:	ec06                	sd	ra,24(sp)
    800045f4:	e822                	sd	s0,16(sp)
    800045f6:	e426                	sd	s1,8(sp)
    800045f8:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800045fa:	00021517          	auipc	a0,0x21
    800045fe:	9be50513          	addi	a0,a0,-1602 # 80024fb8 <ftable>
    80004602:	ffffc097          	auipc	ra,0xffffc
    80004606:	5e2080e7          	jalr	1506(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000460a:	00021497          	auipc	s1,0x21
    8000460e:	9ce48493          	addi	s1,s1,-1586 # 80024fd8 <ftable+0x20>
    80004612:	00022717          	auipc	a4,0x22
    80004616:	96670713          	addi	a4,a4,-1690 # 80025f78 <ftable+0xfc0>
    if(f->ref == 0){
    8000461a:	40dc                	lw	a5,4(s1)
    8000461c:	cf99                	beqz	a5,8000463a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000461e:	02848493          	addi	s1,s1,40
    80004622:	fee49ce3          	bne	s1,a4,8000461a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004626:	00021517          	auipc	a0,0x21
    8000462a:	99250513          	addi	a0,a0,-1646 # 80024fb8 <ftable>
    8000462e:	ffffc097          	auipc	ra,0xffffc
    80004632:	626080e7          	jalr	1574(ra) # 80000c54 <release>
  return 0;
    80004636:	4481                	li	s1,0
    80004638:	a819                	j	8000464e <filealloc+0x5e>
      f->ref = 1;
    8000463a:	4785                	li	a5,1
    8000463c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000463e:	00021517          	auipc	a0,0x21
    80004642:	97a50513          	addi	a0,a0,-1670 # 80024fb8 <ftable>
    80004646:	ffffc097          	auipc	ra,0xffffc
    8000464a:	60e080e7          	jalr	1550(ra) # 80000c54 <release>
}
    8000464e:	8526                	mv	a0,s1
    80004650:	60e2                	ld	ra,24(sp)
    80004652:	6442                	ld	s0,16(sp)
    80004654:	64a2                	ld	s1,8(sp)
    80004656:	6105                	addi	sp,sp,32
    80004658:	8082                	ret

000000008000465a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000465a:	1101                	addi	sp,sp,-32
    8000465c:	ec06                	sd	ra,24(sp)
    8000465e:	e822                	sd	s0,16(sp)
    80004660:	e426                	sd	s1,8(sp)
    80004662:	1000                	addi	s0,sp,32
    80004664:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004666:	00021517          	auipc	a0,0x21
    8000466a:	95250513          	addi	a0,a0,-1710 # 80024fb8 <ftable>
    8000466e:	ffffc097          	auipc	ra,0xffffc
    80004672:	576080e7          	jalr	1398(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004676:	40dc                	lw	a5,4(s1)
    80004678:	02f05263          	blez	a5,8000469c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000467c:	2785                	addiw	a5,a5,1
    8000467e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004680:	00021517          	auipc	a0,0x21
    80004684:	93850513          	addi	a0,a0,-1736 # 80024fb8 <ftable>
    80004688:	ffffc097          	auipc	ra,0xffffc
    8000468c:	5cc080e7          	jalr	1484(ra) # 80000c54 <release>
  return f;
}
    80004690:	8526                	mv	a0,s1
    80004692:	60e2                	ld	ra,24(sp)
    80004694:	6442                	ld	s0,16(sp)
    80004696:	64a2                	ld	s1,8(sp)
    80004698:	6105                	addi	sp,sp,32
    8000469a:	8082                	ret
    panic("filedup");
    8000469c:	00004517          	auipc	a0,0x4
    800046a0:	11450513          	addi	a0,a0,276 # 800087b0 <userret+0x720>
    800046a4:	ffffc097          	auipc	ra,0xffffc
    800046a8:	ea4080e7          	jalr	-348(ra) # 80000548 <panic>

00000000800046ac <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046ac:	7139                	addi	sp,sp,-64
    800046ae:	fc06                	sd	ra,56(sp)
    800046b0:	f822                	sd	s0,48(sp)
    800046b2:	f426                	sd	s1,40(sp)
    800046b4:	f04a                	sd	s2,32(sp)
    800046b6:	ec4e                	sd	s3,24(sp)
    800046b8:	e852                	sd	s4,16(sp)
    800046ba:	e456                	sd	s5,8(sp)
    800046bc:	0080                	addi	s0,sp,64
    800046be:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800046c0:	00021517          	auipc	a0,0x21
    800046c4:	8f850513          	addi	a0,a0,-1800 # 80024fb8 <ftable>
    800046c8:	ffffc097          	auipc	ra,0xffffc
    800046cc:	51c080e7          	jalr	1308(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800046d0:	40dc                	lw	a5,4(s1)
    800046d2:	06f05563          	blez	a5,8000473c <fileclose+0x90>
    panic("fileclose");
  if(--f->ref > 0){
    800046d6:	37fd                	addiw	a5,a5,-1
    800046d8:	0007871b          	sext.w	a4,a5
    800046dc:	c0dc                	sw	a5,4(s1)
    800046de:	06e04763          	bgtz	a4,8000474c <fileclose+0xa0>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800046e2:	0004a903          	lw	s2,0(s1)
    800046e6:	0094ca83          	lbu	s5,9(s1)
    800046ea:	0104ba03          	ld	s4,16(s1)
    800046ee:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800046f2:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800046f6:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800046fa:	00021517          	auipc	a0,0x21
    800046fe:	8be50513          	addi	a0,a0,-1858 # 80024fb8 <ftable>
    80004702:	ffffc097          	auipc	ra,0xffffc
    80004706:	552080e7          	jalr	1362(ra) # 80000c54 <release>

  if(ff.type == FD_PIPE){
    8000470a:	4785                	li	a5,1
    8000470c:	06f90163          	beq	s2,a5,8000476e <fileclose+0xc2>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004710:	3979                	addiw	s2,s2,-2
    80004712:	4785                	li	a5,1
    80004714:	0527e463          	bltu	a5,s2,8000475c <fileclose+0xb0>
    begin_op(ff.ip->dev);
    80004718:	0009a503          	lw	a0,0(s3)
    8000471c:	00000097          	auipc	ra,0x0
    80004720:	9f6080e7          	jalr	-1546(ra) # 80004112 <begin_op>
    iput(ff.ip);
    80004724:	854e                	mv	a0,s3
    80004726:	fffff097          	auipc	ra,0xfffff
    8000472a:	114080e7          	jalr	276(ra) # 8000383a <iput>
    end_op(ff.ip->dev);
    8000472e:	0009a503          	lw	a0,0(s3)
    80004732:	00000097          	auipc	ra,0x0
    80004736:	a8a080e7          	jalr	-1398(ra) # 800041bc <end_op>
    8000473a:	a00d                	j	8000475c <fileclose+0xb0>
    panic("fileclose");
    8000473c:	00004517          	auipc	a0,0x4
    80004740:	07c50513          	addi	a0,a0,124 # 800087b8 <userret+0x728>
    80004744:	ffffc097          	auipc	ra,0xffffc
    80004748:	e04080e7          	jalr	-508(ra) # 80000548 <panic>
    release(&ftable.lock);
    8000474c:	00021517          	auipc	a0,0x21
    80004750:	86c50513          	addi	a0,a0,-1940 # 80024fb8 <ftable>
    80004754:	ffffc097          	auipc	ra,0xffffc
    80004758:	500080e7          	jalr	1280(ra) # 80000c54 <release>
  }
}
    8000475c:	70e2                	ld	ra,56(sp)
    8000475e:	7442                	ld	s0,48(sp)
    80004760:	74a2                	ld	s1,40(sp)
    80004762:	7902                	ld	s2,32(sp)
    80004764:	69e2                	ld	s3,24(sp)
    80004766:	6a42                	ld	s4,16(sp)
    80004768:	6aa2                	ld	s5,8(sp)
    8000476a:	6121                	addi	sp,sp,64
    8000476c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000476e:	85d6                	mv	a1,s5
    80004770:	8552                	mv	a0,s4
    80004772:	00000097          	auipc	ra,0x0
    80004776:	376080e7          	jalr	886(ra) # 80004ae8 <pipeclose>
    8000477a:	b7cd                	j	8000475c <fileclose+0xb0>

000000008000477c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000477c:	715d                	addi	sp,sp,-80
    8000477e:	e486                	sd	ra,72(sp)
    80004780:	e0a2                	sd	s0,64(sp)
    80004782:	fc26                	sd	s1,56(sp)
    80004784:	f84a                	sd	s2,48(sp)
    80004786:	f44e                	sd	s3,40(sp)
    80004788:	0880                	addi	s0,sp,80
    8000478a:	84aa                	mv	s1,a0
    8000478c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000478e:	ffffd097          	auipc	ra,0xffffd
    80004792:	3ae080e7          	jalr	942(ra) # 80001b3c <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004796:	409c                	lw	a5,0(s1)
    80004798:	37f9                	addiw	a5,a5,-2
    8000479a:	4705                	li	a4,1
    8000479c:	04f76763          	bltu	a4,a5,800047ea <filestat+0x6e>
    800047a0:	892a                	mv	s2,a0
    ilock(f->ip);
    800047a2:	6c88                	ld	a0,24(s1)
    800047a4:	fffff097          	auipc	ra,0xfffff
    800047a8:	f88080e7          	jalr	-120(ra) # 8000372c <ilock>
    stati(f->ip, &st);
    800047ac:	fb840593          	addi	a1,s0,-72
    800047b0:	6c88                	ld	a0,24(s1)
    800047b2:	fffff097          	auipc	ra,0xfffff
    800047b6:	1e0080e7          	jalr	480(ra) # 80003992 <stati>
    iunlock(f->ip);
    800047ba:	6c88                	ld	a0,24(s1)
    800047bc:	fffff097          	auipc	ra,0xfffff
    800047c0:	032080e7          	jalr	50(ra) # 800037ee <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800047c4:	46e1                	li	a3,24
    800047c6:	fb840613          	addi	a2,s0,-72
    800047ca:	85ce                	mv	a1,s3
    800047cc:	05893503          	ld	a0,88(s2)
    800047d0:	ffffd097          	auipc	ra,0xffffd
    800047d4:	05e080e7          	jalr	94(ra) # 8000182e <copyout>
    800047d8:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800047dc:	60a6                	ld	ra,72(sp)
    800047de:	6406                	ld	s0,64(sp)
    800047e0:	74e2                	ld	s1,56(sp)
    800047e2:	7942                	ld	s2,48(sp)
    800047e4:	79a2                	ld	s3,40(sp)
    800047e6:	6161                	addi	sp,sp,80
    800047e8:	8082                	ret
  return -1;
    800047ea:	557d                	li	a0,-1
    800047ec:	bfc5                	j	800047dc <filestat+0x60>

00000000800047ee <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800047ee:	7179                	addi	sp,sp,-48
    800047f0:	f406                	sd	ra,40(sp)
    800047f2:	f022                	sd	s0,32(sp)
    800047f4:	ec26                	sd	s1,24(sp)
    800047f6:	e84a                	sd	s2,16(sp)
    800047f8:	e44e                	sd	s3,8(sp)
    800047fa:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800047fc:	00854783          	lbu	a5,8(a0)
    80004800:	c7c5                	beqz	a5,800048a8 <fileread+0xba>
    80004802:	84aa                	mv	s1,a0
    80004804:	89ae                	mv	s3,a1
    80004806:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004808:	411c                	lw	a5,0(a0)
    8000480a:	4705                	li	a4,1
    8000480c:	04e78963          	beq	a5,a4,8000485e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004810:	470d                	li	a4,3
    80004812:	04e78d63          	beq	a5,a4,8000486c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(f, 1, addr, n);
  } else if(f->type == FD_INODE){
    80004816:	4709                	li	a4,2
    80004818:	08e79063          	bne	a5,a4,80004898 <fileread+0xaa>
    ilock(f->ip);
    8000481c:	6d08                	ld	a0,24(a0)
    8000481e:	fffff097          	auipc	ra,0xfffff
    80004822:	f0e080e7          	jalr	-242(ra) # 8000372c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004826:	874a                	mv	a4,s2
    80004828:	5094                	lw	a3,32(s1)
    8000482a:	864e                	mv	a2,s3
    8000482c:	4585                	li	a1,1
    8000482e:	6c88                	ld	a0,24(s1)
    80004830:	fffff097          	auipc	ra,0xfffff
    80004834:	18c080e7          	jalr	396(ra) # 800039bc <readi>
    80004838:	892a                	mv	s2,a0
    8000483a:	00a05563          	blez	a0,80004844 <fileread+0x56>
      f->off += r;
    8000483e:	509c                	lw	a5,32(s1)
    80004840:	9fa9                	addw	a5,a5,a0
    80004842:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004844:	6c88                	ld	a0,24(s1)
    80004846:	fffff097          	auipc	ra,0xfffff
    8000484a:	fa8080e7          	jalr	-88(ra) # 800037ee <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000484e:	854a                	mv	a0,s2
    80004850:	70a2                	ld	ra,40(sp)
    80004852:	7402                	ld	s0,32(sp)
    80004854:	64e2                	ld	s1,24(sp)
    80004856:	6942                	ld	s2,16(sp)
    80004858:	69a2                	ld	s3,8(sp)
    8000485a:	6145                	addi	sp,sp,48
    8000485c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000485e:	6908                	ld	a0,16(a0)
    80004860:	00000097          	auipc	ra,0x0
    80004864:	406080e7          	jalr	1030(ra) # 80004c66 <piperead>
    80004868:	892a                	mv	s2,a0
    8000486a:	b7d5                	j	8000484e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000486c:	02451783          	lh	a5,36(a0)
    80004870:	03079693          	slli	a3,a5,0x30
    80004874:	92c1                	srli	a3,a3,0x30
    80004876:	4725                	li	a4,9
    80004878:	02d76a63          	bltu	a4,a3,800048ac <fileread+0xbe>
    8000487c:	0792                	slli	a5,a5,0x4
    8000487e:	00020717          	auipc	a4,0x20
    80004882:	69a70713          	addi	a4,a4,1690 # 80024f18 <devsw>
    80004886:	97ba                	add	a5,a5,a4
    80004888:	639c                	ld	a5,0(a5)
    8000488a:	c39d                	beqz	a5,800048b0 <fileread+0xc2>
    r = devsw[f->major].read(f, 1, addr, n);
    8000488c:	86b2                	mv	a3,a2
    8000488e:	862e                	mv	a2,a1
    80004890:	4585                	li	a1,1
    80004892:	9782                	jalr	a5
    80004894:	892a                	mv	s2,a0
    80004896:	bf65                	j	8000484e <fileread+0x60>
    panic("fileread");
    80004898:	00004517          	auipc	a0,0x4
    8000489c:	f3050513          	addi	a0,a0,-208 # 800087c8 <userret+0x738>
    800048a0:	ffffc097          	auipc	ra,0xffffc
    800048a4:	ca8080e7          	jalr	-856(ra) # 80000548 <panic>
    return -1;
    800048a8:	597d                	li	s2,-1
    800048aa:	b755                	j	8000484e <fileread+0x60>
      return -1;
    800048ac:	597d                	li	s2,-1
    800048ae:	b745                	j	8000484e <fileread+0x60>
    800048b0:	597d                	li	s2,-1
    800048b2:	bf71                	j	8000484e <fileread+0x60>

00000000800048b4 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800048b4:	00954783          	lbu	a5,9(a0)
    800048b8:	14078663          	beqz	a5,80004a04 <filewrite+0x150>
{
    800048bc:	715d                	addi	sp,sp,-80
    800048be:	e486                	sd	ra,72(sp)
    800048c0:	e0a2                	sd	s0,64(sp)
    800048c2:	fc26                	sd	s1,56(sp)
    800048c4:	f84a                	sd	s2,48(sp)
    800048c6:	f44e                	sd	s3,40(sp)
    800048c8:	f052                	sd	s4,32(sp)
    800048ca:	ec56                	sd	s5,24(sp)
    800048cc:	e85a                	sd	s6,16(sp)
    800048ce:	e45e                	sd	s7,8(sp)
    800048d0:	e062                	sd	s8,0(sp)
    800048d2:	0880                	addi	s0,sp,80
    800048d4:	84aa                	mv	s1,a0
    800048d6:	8aae                	mv	s5,a1
    800048d8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800048da:	411c                	lw	a5,0(a0)
    800048dc:	4705                	li	a4,1
    800048de:	02e78263          	beq	a5,a4,80004902 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048e2:	470d                	li	a4,3
    800048e4:	02e78563          	beq	a5,a4,8000490e <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(f, 1, addr, n);
  } else if(f->type == FD_INODE){
    800048e8:	4709                	li	a4,2
    800048ea:	10e79563          	bne	a5,a4,800049f4 <filewrite+0x140>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800048ee:	0ec05f63          	blez	a2,800049ec <filewrite+0x138>
    int i = 0;
    800048f2:	4981                	li	s3,0
    800048f4:	6b05                	lui	s6,0x1
    800048f6:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800048fa:	6b85                	lui	s7,0x1
    800048fc:	c00b8b9b          	addiw	s7,s7,-1024
    80004900:	a851                	j	80004994 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004902:	6908                	ld	a0,16(a0)
    80004904:	00000097          	auipc	ra,0x0
    80004908:	254080e7          	jalr	596(ra) # 80004b58 <pipewrite>
    8000490c:	a865                	j	800049c4 <filewrite+0x110>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000490e:	02451783          	lh	a5,36(a0)
    80004912:	03079693          	slli	a3,a5,0x30
    80004916:	92c1                	srli	a3,a3,0x30
    80004918:	4725                	li	a4,9
    8000491a:	0ed76763          	bltu	a4,a3,80004a08 <filewrite+0x154>
    8000491e:	0792                	slli	a5,a5,0x4
    80004920:	00020717          	auipc	a4,0x20
    80004924:	5f870713          	addi	a4,a4,1528 # 80024f18 <devsw>
    80004928:	97ba                	add	a5,a5,a4
    8000492a:	679c                	ld	a5,8(a5)
    8000492c:	c3e5                	beqz	a5,80004a0c <filewrite+0x158>
    ret = devsw[f->major].write(f, 1, addr, n);
    8000492e:	86b2                	mv	a3,a2
    80004930:	862e                	mv	a2,a1
    80004932:	4585                	li	a1,1
    80004934:	9782                	jalr	a5
    80004936:	a079                	j	800049c4 <filewrite+0x110>
    80004938:	00090c1b          	sext.w	s8,s2
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op(f->ip->dev);
    8000493c:	6c9c                	ld	a5,24(s1)
    8000493e:	4388                	lw	a0,0(a5)
    80004940:	fffff097          	auipc	ra,0xfffff
    80004944:	7d2080e7          	jalr	2002(ra) # 80004112 <begin_op>
      ilock(f->ip);
    80004948:	6c88                	ld	a0,24(s1)
    8000494a:	fffff097          	auipc	ra,0xfffff
    8000494e:	de2080e7          	jalr	-542(ra) # 8000372c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004952:	8762                	mv	a4,s8
    80004954:	5094                	lw	a3,32(s1)
    80004956:	01598633          	add	a2,s3,s5
    8000495a:	4585                	li	a1,1
    8000495c:	6c88                	ld	a0,24(s1)
    8000495e:	fffff097          	auipc	ra,0xfffff
    80004962:	152080e7          	jalr	338(ra) # 80003ab0 <writei>
    80004966:	892a                	mv	s2,a0
    80004968:	02a05e63          	blez	a0,800049a4 <filewrite+0xf0>
        f->off += r;
    8000496c:	509c                	lw	a5,32(s1)
    8000496e:	9fa9                	addw	a5,a5,a0
    80004970:	d09c                	sw	a5,32(s1)
      iunlock(f->ip);
    80004972:	6c88                	ld	a0,24(s1)
    80004974:	fffff097          	auipc	ra,0xfffff
    80004978:	e7a080e7          	jalr	-390(ra) # 800037ee <iunlock>
      end_op(f->ip->dev);
    8000497c:	6c9c                	ld	a5,24(s1)
    8000497e:	4388                	lw	a0,0(a5)
    80004980:	00000097          	auipc	ra,0x0
    80004984:	83c080e7          	jalr	-1988(ra) # 800041bc <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004988:	052c1a63          	bne	s8,s2,800049dc <filewrite+0x128>
        panic("short filewrite");
      i += r;
    8000498c:	013909bb          	addw	s3,s2,s3
    while(i < n){
    80004990:	0349d763          	bge	s3,s4,800049be <filewrite+0x10a>
      int n1 = n - i;
    80004994:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004998:	893e                	mv	s2,a5
    8000499a:	2781                	sext.w	a5,a5
    8000499c:	f8fb5ee3          	bge	s6,a5,80004938 <filewrite+0x84>
    800049a0:	895e                	mv	s2,s7
    800049a2:	bf59                	j	80004938 <filewrite+0x84>
      iunlock(f->ip);
    800049a4:	6c88                	ld	a0,24(s1)
    800049a6:	fffff097          	auipc	ra,0xfffff
    800049aa:	e48080e7          	jalr	-440(ra) # 800037ee <iunlock>
      end_op(f->ip->dev);
    800049ae:	6c9c                	ld	a5,24(s1)
    800049b0:	4388                	lw	a0,0(a5)
    800049b2:	00000097          	auipc	ra,0x0
    800049b6:	80a080e7          	jalr	-2038(ra) # 800041bc <end_op>
      if(r < 0)
    800049ba:	fc0957e3          	bgez	s2,80004988 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    800049be:	8552                	mv	a0,s4
    800049c0:	033a1863          	bne	s4,s3,800049f0 <filewrite+0x13c>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800049c4:	60a6                	ld	ra,72(sp)
    800049c6:	6406                	ld	s0,64(sp)
    800049c8:	74e2                	ld	s1,56(sp)
    800049ca:	7942                	ld	s2,48(sp)
    800049cc:	79a2                	ld	s3,40(sp)
    800049ce:	7a02                	ld	s4,32(sp)
    800049d0:	6ae2                	ld	s5,24(sp)
    800049d2:	6b42                	ld	s6,16(sp)
    800049d4:	6ba2                	ld	s7,8(sp)
    800049d6:	6c02                	ld	s8,0(sp)
    800049d8:	6161                	addi	sp,sp,80
    800049da:	8082                	ret
        panic("short filewrite");
    800049dc:	00004517          	auipc	a0,0x4
    800049e0:	dfc50513          	addi	a0,a0,-516 # 800087d8 <userret+0x748>
    800049e4:	ffffc097          	auipc	ra,0xffffc
    800049e8:	b64080e7          	jalr	-1180(ra) # 80000548 <panic>
    int i = 0;
    800049ec:	4981                	li	s3,0
    800049ee:	bfc1                	j	800049be <filewrite+0x10a>
    ret = (i == n ? n : -1);
    800049f0:	557d                	li	a0,-1
    800049f2:	bfc9                	j	800049c4 <filewrite+0x110>
    panic("filewrite");
    800049f4:	00004517          	auipc	a0,0x4
    800049f8:	df450513          	addi	a0,a0,-524 # 800087e8 <userret+0x758>
    800049fc:	ffffc097          	auipc	ra,0xffffc
    80004a00:	b4c080e7          	jalr	-1204(ra) # 80000548 <panic>
    return -1;
    80004a04:	557d                	li	a0,-1
}
    80004a06:	8082                	ret
      return -1;
    80004a08:	557d                	li	a0,-1
    80004a0a:	bf6d                	j	800049c4 <filewrite+0x110>
    80004a0c:	557d                	li	a0,-1
    80004a0e:	bf5d                	j	800049c4 <filewrite+0x110>

0000000080004a10 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a10:	7179                	addi	sp,sp,-48
    80004a12:	f406                	sd	ra,40(sp)
    80004a14:	f022                	sd	s0,32(sp)
    80004a16:	ec26                	sd	s1,24(sp)
    80004a18:	e84a                	sd	s2,16(sp)
    80004a1a:	e44e                	sd	s3,8(sp)
    80004a1c:	e052                	sd	s4,0(sp)
    80004a1e:	1800                	addi	s0,sp,48
    80004a20:	84aa                	mv	s1,a0
    80004a22:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a24:	0005b023          	sd	zero,0(a1)
    80004a28:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a2c:	00000097          	auipc	ra,0x0
    80004a30:	bc4080e7          	jalr	-1084(ra) # 800045f0 <filealloc>
    80004a34:	e088                	sd	a0,0(s1)
    80004a36:	c549                	beqz	a0,80004ac0 <pipealloc+0xb0>
    80004a38:	00000097          	auipc	ra,0x0
    80004a3c:	bb8080e7          	jalr	-1096(ra) # 800045f0 <filealloc>
    80004a40:	00aa3023          	sd	a0,0(s4)
    80004a44:	c925                	beqz	a0,80004ab4 <pipealloc+0xa4>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a46:	ffffc097          	auipc	ra,0xffffc
    80004a4a:	f6a080e7          	jalr	-150(ra) # 800009b0 <kalloc>
    80004a4e:	892a                	mv	s2,a0
    80004a50:	cd39                	beqz	a0,80004aae <pipealloc+0x9e>
    goto bad;
  pi->readopen = 1;
    80004a52:	4985                	li	s3,1
    80004a54:	23352423          	sw	s3,552(a0)
  pi->writeopen = 1;
    80004a58:	23352623          	sw	s3,556(a0)
  pi->nwrite = 0;
    80004a5c:	22052223          	sw	zero,548(a0)
  pi->nread = 0;
    80004a60:	22052023          	sw	zero,544(a0)
  memset(&pi->lock, 0, sizeof(pi->lock));
    80004a64:	02000613          	li	a2,32
    80004a68:	4581                	li	a1,0
    80004a6a:	ffffc097          	auipc	ra,0xffffc
    80004a6e:	3e8080e7          	jalr	1000(ra) # 80000e52 <memset>
  (*f0)->type = FD_PIPE;
    80004a72:	609c                	ld	a5,0(s1)
    80004a74:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a78:	609c                	ld	a5,0(s1)
    80004a7a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a7e:	609c                	ld	a5,0(s1)
    80004a80:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a84:	609c                	ld	a5,0(s1)
    80004a86:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a8a:	000a3783          	ld	a5,0(s4)
    80004a8e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a92:	000a3783          	ld	a5,0(s4)
    80004a96:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a9a:	000a3783          	ld	a5,0(s4)
    80004a9e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004aa2:	000a3783          	ld	a5,0(s4)
    80004aa6:	0127b823          	sd	s2,16(a5)
  return 0;
    80004aaa:	4501                	li	a0,0
    80004aac:	a025                	j	80004ad4 <pipealloc+0xc4>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004aae:	6088                	ld	a0,0(s1)
    80004ab0:	e501                	bnez	a0,80004ab8 <pipealloc+0xa8>
    80004ab2:	a039                	j	80004ac0 <pipealloc+0xb0>
    80004ab4:	6088                	ld	a0,0(s1)
    80004ab6:	c51d                	beqz	a0,80004ae4 <pipealloc+0xd4>
    fileclose(*f0);
    80004ab8:	00000097          	auipc	ra,0x0
    80004abc:	bf4080e7          	jalr	-1036(ra) # 800046ac <fileclose>
  if(*f1)
    80004ac0:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004ac4:	557d                	li	a0,-1
  if(*f1)
    80004ac6:	c799                	beqz	a5,80004ad4 <pipealloc+0xc4>
    fileclose(*f1);
    80004ac8:	853e                	mv	a0,a5
    80004aca:	00000097          	auipc	ra,0x0
    80004ace:	be2080e7          	jalr	-1054(ra) # 800046ac <fileclose>
  return -1;
    80004ad2:	557d                	li	a0,-1
}
    80004ad4:	70a2                	ld	ra,40(sp)
    80004ad6:	7402                	ld	s0,32(sp)
    80004ad8:	64e2                	ld	s1,24(sp)
    80004ada:	6942                	ld	s2,16(sp)
    80004adc:	69a2                	ld	s3,8(sp)
    80004ade:	6a02                	ld	s4,0(sp)
    80004ae0:	6145                	addi	sp,sp,48
    80004ae2:	8082                	ret
  return -1;
    80004ae4:	557d                	li	a0,-1
    80004ae6:	b7fd                	j	80004ad4 <pipealloc+0xc4>

0000000080004ae8 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ae8:	1101                	addi	sp,sp,-32
    80004aea:	ec06                	sd	ra,24(sp)
    80004aec:	e822                	sd	s0,16(sp)
    80004aee:	e426                	sd	s1,8(sp)
    80004af0:	e04a                	sd	s2,0(sp)
    80004af2:	1000                	addi	s0,sp,32
    80004af4:	84aa                	mv	s1,a0
    80004af6:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004af8:	ffffc097          	auipc	ra,0xffffc
    80004afc:	0ec080e7          	jalr	236(ra) # 80000be4 <acquire>
  if(writable){
    80004b00:	02090d63          	beqz	s2,80004b3a <pipeclose+0x52>
    pi->writeopen = 0;
    80004b04:	2204a623          	sw	zero,556(s1)
    wakeup(&pi->nread);
    80004b08:	22048513          	addi	a0,s1,544
    80004b0c:	ffffe097          	auipc	ra,0xffffe
    80004b10:	986080e7          	jalr	-1658(ra) # 80002492 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b14:	2284b783          	ld	a5,552(s1)
    80004b18:	eb95                	bnez	a5,80004b4c <pipeclose+0x64>
    release(&pi->lock);
    80004b1a:	8526                	mv	a0,s1
    80004b1c:	ffffc097          	auipc	ra,0xffffc
    80004b20:	138080e7          	jalr	312(ra) # 80000c54 <release>
    kfree((char*)pi);
    80004b24:	8526                	mv	a0,s1
    80004b26:	ffffc097          	auipc	ra,0xffffc
    80004b2a:	d3e080e7          	jalr	-706(ra) # 80000864 <kfree>
  } else
    release(&pi->lock);
}
    80004b2e:	60e2                	ld	ra,24(sp)
    80004b30:	6442                	ld	s0,16(sp)
    80004b32:	64a2                	ld	s1,8(sp)
    80004b34:	6902                	ld	s2,0(sp)
    80004b36:	6105                	addi	sp,sp,32
    80004b38:	8082                	ret
    pi->readopen = 0;
    80004b3a:	2204a423          	sw	zero,552(s1)
    wakeup(&pi->nwrite);
    80004b3e:	22448513          	addi	a0,s1,548
    80004b42:	ffffe097          	auipc	ra,0xffffe
    80004b46:	950080e7          	jalr	-1712(ra) # 80002492 <wakeup>
    80004b4a:	b7e9                	j	80004b14 <pipeclose+0x2c>
    release(&pi->lock);
    80004b4c:	8526                	mv	a0,s1
    80004b4e:	ffffc097          	auipc	ra,0xffffc
    80004b52:	106080e7          	jalr	262(ra) # 80000c54 <release>
}
    80004b56:	bfe1                	j	80004b2e <pipeclose+0x46>

0000000080004b58 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b58:	711d                	addi	sp,sp,-96
    80004b5a:	ec86                	sd	ra,88(sp)
    80004b5c:	e8a2                	sd	s0,80(sp)
    80004b5e:	e4a6                	sd	s1,72(sp)
    80004b60:	e0ca                	sd	s2,64(sp)
    80004b62:	fc4e                	sd	s3,56(sp)
    80004b64:	f852                	sd	s4,48(sp)
    80004b66:	f456                	sd	s5,40(sp)
    80004b68:	f05a                	sd	s6,32(sp)
    80004b6a:	ec5e                	sd	s7,24(sp)
    80004b6c:	e862                	sd	s8,16(sp)
    80004b6e:	1080                	addi	s0,sp,96
    80004b70:	84aa                	mv	s1,a0
    80004b72:	8aae                	mv	s5,a1
    80004b74:	8a32                	mv	s4,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004b76:	ffffd097          	auipc	ra,0xffffd
    80004b7a:	fc6080e7          	jalr	-58(ra) # 80001b3c <myproc>
    80004b7e:	8baa                	mv	s7,a0

  acquire(&pi->lock);
    80004b80:	8526                	mv	a0,s1
    80004b82:	ffffc097          	auipc	ra,0xffffc
    80004b86:	062080e7          	jalr	98(ra) # 80000be4 <acquire>
  for(i = 0; i < n; i++){
    80004b8a:	09405f63          	blez	s4,80004c28 <pipewrite+0xd0>
    80004b8e:	fffa0b1b          	addiw	s6,s4,-1
    80004b92:	1b02                	slli	s6,s6,0x20
    80004b94:	020b5b13          	srli	s6,s6,0x20
    80004b98:	001a8793          	addi	a5,s5,1
    80004b9c:	9b3e                	add	s6,s6,a5
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || myproc()->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004b9e:	22048993          	addi	s3,s1,544
      sleep(&pi->nwrite, &pi->lock);
    80004ba2:	22448913          	addi	s2,s1,548
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ba6:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004ba8:	2204a783          	lw	a5,544(s1)
    80004bac:	2244a703          	lw	a4,548(s1)
    80004bb0:	2007879b          	addiw	a5,a5,512
    80004bb4:	02f71e63          	bne	a4,a5,80004bf0 <pipewrite+0x98>
      if(pi->readopen == 0 || myproc()->killed){
    80004bb8:	2284a783          	lw	a5,552(s1)
    80004bbc:	c3d9                	beqz	a5,80004c42 <pipewrite+0xea>
    80004bbe:	ffffd097          	auipc	ra,0xffffd
    80004bc2:	f7e080e7          	jalr	-130(ra) # 80001b3c <myproc>
    80004bc6:	5d1c                	lw	a5,56(a0)
    80004bc8:	efad                	bnez	a5,80004c42 <pipewrite+0xea>
      wakeup(&pi->nread);
    80004bca:	854e                	mv	a0,s3
    80004bcc:	ffffe097          	auipc	ra,0xffffe
    80004bd0:	8c6080e7          	jalr	-1850(ra) # 80002492 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004bd4:	85a6                	mv	a1,s1
    80004bd6:	854a                	mv	a0,s2
    80004bd8:	ffffd097          	auipc	ra,0xffffd
    80004bdc:	73a080e7          	jalr	1850(ra) # 80002312 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004be0:	2204a783          	lw	a5,544(s1)
    80004be4:	2244a703          	lw	a4,548(s1)
    80004be8:	2007879b          	addiw	a5,a5,512
    80004bec:	fcf706e3          	beq	a4,a5,80004bb8 <pipewrite+0x60>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bf0:	4685                	li	a3,1
    80004bf2:	8656                	mv	a2,s5
    80004bf4:	faf40593          	addi	a1,s0,-81
    80004bf8:	058bb503          	ld	a0,88(s7) # 1058 <_entry-0x7fffefa8>
    80004bfc:	ffffd097          	auipc	ra,0xffffd
    80004c00:	cbe080e7          	jalr	-834(ra) # 800018ba <copyin>
    80004c04:	03850263          	beq	a0,s8,80004c28 <pipewrite+0xd0>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c08:	2244a783          	lw	a5,548(s1)
    80004c0c:	0017871b          	addiw	a4,a5,1
    80004c10:	22e4a223          	sw	a4,548(s1)
    80004c14:	1ff7f793          	andi	a5,a5,511
    80004c18:	97a6                	add	a5,a5,s1
    80004c1a:	faf44703          	lbu	a4,-81(s0)
    80004c1e:	02e78023          	sb	a4,32(a5)
  for(i = 0; i < n; i++){
    80004c22:	0a85                	addi	s5,s5,1
    80004c24:	f96a92e3          	bne	s5,s6,80004ba8 <pipewrite+0x50>
  }
  wakeup(&pi->nread);
    80004c28:	22048513          	addi	a0,s1,544
    80004c2c:	ffffe097          	auipc	ra,0xffffe
    80004c30:	866080e7          	jalr	-1946(ra) # 80002492 <wakeup>
  release(&pi->lock);
    80004c34:	8526                	mv	a0,s1
    80004c36:	ffffc097          	auipc	ra,0xffffc
    80004c3a:	01e080e7          	jalr	30(ra) # 80000c54 <release>
  return n;
    80004c3e:	8552                	mv	a0,s4
    80004c40:	a039                	j	80004c4e <pipewrite+0xf6>
        release(&pi->lock);
    80004c42:	8526                	mv	a0,s1
    80004c44:	ffffc097          	auipc	ra,0xffffc
    80004c48:	010080e7          	jalr	16(ra) # 80000c54 <release>
        return -1;
    80004c4c:	557d                	li	a0,-1
}
    80004c4e:	60e6                	ld	ra,88(sp)
    80004c50:	6446                	ld	s0,80(sp)
    80004c52:	64a6                	ld	s1,72(sp)
    80004c54:	6906                	ld	s2,64(sp)
    80004c56:	79e2                	ld	s3,56(sp)
    80004c58:	7a42                	ld	s4,48(sp)
    80004c5a:	7aa2                	ld	s5,40(sp)
    80004c5c:	7b02                	ld	s6,32(sp)
    80004c5e:	6be2                	ld	s7,24(sp)
    80004c60:	6c42                	ld	s8,16(sp)
    80004c62:	6125                	addi	sp,sp,96
    80004c64:	8082                	ret

0000000080004c66 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c66:	715d                	addi	sp,sp,-80
    80004c68:	e486                	sd	ra,72(sp)
    80004c6a:	e0a2                	sd	s0,64(sp)
    80004c6c:	fc26                	sd	s1,56(sp)
    80004c6e:	f84a                	sd	s2,48(sp)
    80004c70:	f44e                	sd	s3,40(sp)
    80004c72:	f052                	sd	s4,32(sp)
    80004c74:	ec56                	sd	s5,24(sp)
    80004c76:	e85a                	sd	s6,16(sp)
    80004c78:	0880                	addi	s0,sp,80
    80004c7a:	84aa                	mv	s1,a0
    80004c7c:	892e                	mv	s2,a1
    80004c7e:	8a32                	mv	s4,a2
  int i;
  struct proc *pr = myproc();
    80004c80:	ffffd097          	auipc	ra,0xffffd
    80004c84:	ebc080e7          	jalr	-324(ra) # 80001b3c <myproc>
    80004c88:	8aaa                	mv	s5,a0
  char ch;

  acquire(&pi->lock);
    80004c8a:	8526                	mv	a0,s1
    80004c8c:	ffffc097          	auipc	ra,0xffffc
    80004c90:	f58080e7          	jalr	-168(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c94:	2204a703          	lw	a4,544(s1)
    80004c98:	2244a783          	lw	a5,548(s1)
    if(myproc()->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c9c:	22048993          	addi	s3,s1,544
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ca0:	02f71763          	bne	a4,a5,80004cce <piperead+0x68>
    80004ca4:	22c4a783          	lw	a5,556(s1)
    80004ca8:	c39d                	beqz	a5,80004cce <piperead+0x68>
    if(myproc()->killed){
    80004caa:	ffffd097          	auipc	ra,0xffffd
    80004cae:	e92080e7          	jalr	-366(ra) # 80001b3c <myproc>
    80004cb2:	5d1c                	lw	a5,56(a0)
    80004cb4:	ebc1                	bnez	a5,80004d44 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cb6:	85a6                	mv	a1,s1
    80004cb8:	854e                	mv	a0,s3
    80004cba:	ffffd097          	auipc	ra,0xffffd
    80004cbe:	658080e7          	jalr	1624(ra) # 80002312 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cc2:	2204a703          	lw	a4,544(s1)
    80004cc6:	2244a783          	lw	a5,548(s1)
    80004cca:	fcf70de3          	beq	a4,a5,80004ca4 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cce:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cd0:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cd2:	05405363          	blez	s4,80004d18 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004cd6:	2204a783          	lw	a5,544(s1)
    80004cda:	2244a703          	lw	a4,548(s1)
    80004cde:	02f70d63          	beq	a4,a5,80004d18 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ce2:	0017871b          	addiw	a4,a5,1
    80004ce6:	22e4a023          	sw	a4,544(s1)
    80004cea:	1ff7f793          	andi	a5,a5,511
    80004cee:	97a6                	add	a5,a5,s1
    80004cf0:	0207c783          	lbu	a5,32(a5)
    80004cf4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cf8:	4685                	li	a3,1
    80004cfa:	fbf40613          	addi	a2,s0,-65
    80004cfe:	85ca                	mv	a1,s2
    80004d00:	058ab503          	ld	a0,88(s5)
    80004d04:	ffffd097          	auipc	ra,0xffffd
    80004d08:	b2a080e7          	jalr	-1238(ra) # 8000182e <copyout>
    80004d0c:	01650663          	beq	a0,s6,80004d18 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d10:	2985                	addiw	s3,s3,1
    80004d12:	0905                	addi	s2,s2,1
    80004d14:	fd3a11e3          	bne	s4,s3,80004cd6 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d18:	22448513          	addi	a0,s1,548
    80004d1c:	ffffd097          	auipc	ra,0xffffd
    80004d20:	776080e7          	jalr	1910(ra) # 80002492 <wakeup>
  release(&pi->lock);
    80004d24:	8526                	mv	a0,s1
    80004d26:	ffffc097          	auipc	ra,0xffffc
    80004d2a:	f2e080e7          	jalr	-210(ra) # 80000c54 <release>
  return i;
}
    80004d2e:	854e                	mv	a0,s3
    80004d30:	60a6                	ld	ra,72(sp)
    80004d32:	6406                	ld	s0,64(sp)
    80004d34:	74e2                	ld	s1,56(sp)
    80004d36:	7942                	ld	s2,48(sp)
    80004d38:	79a2                	ld	s3,40(sp)
    80004d3a:	7a02                	ld	s4,32(sp)
    80004d3c:	6ae2                	ld	s5,24(sp)
    80004d3e:	6b42                	ld	s6,16(sp)
    80004d40:	6161                	addi	sp,sp,80
    80004d42:	8082                	ret
      release(&pi->lock);
    80004d44:	8526                	mv	a0,s1
    80004d46:	ffffc097          	auipc	ra,0xffffc
    80004d4a:	f0e080e7          	jalr	-242(ra) # 80000c54 <release>
      return -1;
    80004d4e:	59fd                	li	s3,-1
    80004d50:	bff9                	j	80004d2e <piperead+0xc8>

0000000080004d52 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d52:	de010113          	addi	sp,sp,-544
    80004d56:	20113c23          	sd	ra,536(sp)
    80004d5a:	20813823          	sd	s0,528(sp)
    80004d5e:	20913423          	sd	s1,520(sp)
    80004d62:	21213023          	sd	s2,512(sp)
    80004d66:	ffce                	sd	s3,504(sp)
    80004d68:	fbd2                	sd	s4,496(sp)
    80004d6a:	f7d6                	sd	s5,488(sp)
    80004d6c:	f3da                	sd	s6,480(sp)
    80004d6e:	efde                	sd	s7,472(sp)
    80004d70:	ebe2                	sd	s8,464(sp)
    80004d72:	e7e6                	sd	s9,456(sp)
    80004d74:	e3ea                	sd	s10,448(sp)
    80004d76:	ff6e                	sd	s11,440(sp)
    80004d78:	1400                	addi	s0,sp,544
    80004d7a:	892a                	mv	s2,a0
    80004d7c:	dea43423          	sd	a0,-536(s0)
    80004d80:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d84:	ffffd097          	auipc	ra,0xffffd
    80004d88:	db8080e7          	jalr	-584(ra) # 80001b3c <myproc>
    80004d8c:	84aa                	mv	s1,a0

  begin_op(ROOTDEV);
    80004d8e:	4501                	li	a0,0
    80004d90:	fffff097          	auipc	ra,0xfffff
    80004d94:	382080e7          	jalr	898(ra) # 80004112 <begin_op>

  if((ip = namei(path)) == 0){
    80004d98:	854a                	mv	a0,s2
    80004d9a:	fffff097          	auipc	ra,0xfffff
    80004d9e:	11c080e7          	jalr	284(ra) # 80003eb6 <namei>
    80004da2:	cd25                	beqz	a0,80004e1a <exec+0xc8>
    80004da4:	8aaa                	mv	s5,a0
    end_op(ROOTDEV);
    return -1;
  }
  ilock(ip);
    80004da6:	fffff097          	auipc	ra,0xfffff
    80004daa:	986080e7          	jalr	-1658(ra) # 8000372c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004dae:	04000713          	li	a4,64
    80004db2:	4681                	li	a3,0
    80004db4:	e4840613          	addi	a2,s0,-440
    80004db8:	4581                	li	a1,0
    80004dba:	8556                	mv	a0,s5
    80004dbc:	fffff097          	auipc	ra,0xfffff
    80004dc0:	c00080e7          	jalr	-1024(ra) # 800039bc <readi>
    80004dc4:	04000793          	li	a5,64
    80004dc8:	00f51a63          	bne	a0,a5,80004ddc <exec+0x8a>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004dcc:	e4842703          	lw	a4,-440(s0)
    80004dd0:	464c47b7          	lui	a5,0x464c4
    80004dd4:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004dd8:	04f70863          	beq	a4,a5,80004e28 <exec+0xd6>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ddc:	8556                	mv	a0,s5
    80004dde:	fffff097          	auipc	ra,0xfffff
    80004de2:	b8c080e7          	jalr	-1140(ra) # 8000396a <iunlockput>
    end_op(ROOTDEV);
    80004de6:	4501                	li	a0,0
    80004de8:	fffff097          	auipc	ra,0xfffff
    80004dec:	3d4080e7          	jalr	980(ra) # 800041bc <end_op>
  }
  return -1;
    80004df0:	557d                	li	a0,-1
}
    80004df2:	21813083          	ld	ra,536(sp)
    80004df6:	21013403          	ld	s0,528(sp)
    80004dfa:	20813483          	ld	s1,520(sp)
    80004dfe:	20013903          	ld	s2,512(sp)
    80004e02:	79fe                	ld	s3,504(sp)
    80004e04:	7a5e                	ld	s4,496(sp)
    80004e06:	7abe                	ld	s5,488(sp)
    80004e08:	7b1e                	ld	s6,480(sp)
    80004e0a:	6bfe                	ld	s7,472(sp)
    80004e0c:	6c5e                	ld	s8,464(sp)
    80004e0e:	6cbe                	ld	s9,456(sp)
    80004e10:	6d1e                	ld	s10,448(sp)
    80004e12:	7dfa                	ld	s11,440(sp)
    80004e14:	22010113          	addi	sp,sp,544
    80004e18:	8082                	ret
    end_op(ROOTDEV);
    80004e1a:	4501                	li	a0,0
    80004e1c:	fffff097          	auipc	ra,0xfffff
    80004e20:	3a0080e7          	jalr	928(ra) # 800041bc <end_op>
    return -1;
    80004e24:	557d                	li	a0,-1
    80004e26:	b7f1                	j	80004df2 <exec+0xa0>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e28:	8526                	mv	a0,s1
    80004e2a:	ffffd097          	auipc	ra,0xffffd
    80004e2e:	dd6080e7          	jalr	-554(ra) # 80001c00 <proc_pagetable>
    80004e32:	8b2a                	mv	s6,a0
    80004e34:	d545                	beqz	a0,80004ddc <exec+0x8a>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e36:	e6842783          	lw	a5,-408(s0)
    80004e3a:	e8045703          	lhu	a4,-384(s0)
    80004e3e:	10070263          	beqz	a4,80004f42 <exec+0x1f0>
  sz = 0;
    80004e42:	de043c23          	sd	zero,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e46:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004e4a:	6a05                	lui	s4,0x1
    80004e4c:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004e50:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004e54:	6d85                	lui	s11,0x1
    80004e56:	7d7d                	lui	s10,0xfffff
    80004e58:	a88d                	j	80004eca <exec+0x178>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e5a:	00004517          	auipc	a0,0x4
    80004e5e:	99e50513          	addi	a0,a0,-1634 # 800087f8 <userret+0x768>
    80004e62:	ffffb097          	auipc	ra,0xffffb
    80004e66:	6e6080e7          	jalr	1766(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e6a:	874a                	mv	a4,s2
    80004e6c:	009c86bb          	addw	a3,s9,s1
    80004e70:	4581                	li	a1,0
    80004e72:	8556                	mv	a0,s5
    80004e74:	fffff097          	auipc	ra,0xfffff
    80004e78:	b48080e7          	jalr	-1208(ra) # 800039bc <readi>
    80004e7c:	2501                	sext.w	a0,a0
    80004e7e:	10a91863          	bne	s2,a0,80004f8e <exec+0x23c>
  for(i = 0; i < sz; i += PGSIZE){
    80004e82:	009d84bb          	addw	s1,s11,s1
    80004e86:	013d09bb          	addw	s3,s10,s3
    80004e8a:	0374f263          	bgeu	s1,s7,80004eae <exec+0x15c>
    pa = walkaddr(pagetable, va + i);
    80004e8e:	02049593          	slli	a1,s1,0x20
    80004e92:	9181                	srli	a1,a1,0x20
    80004e94:	95e2                	add	a1,a1,s8
    80004e96:	855a                	mv	a0,s6
    80004e98:	ffffc097          	auipc	ra,0xffffc
    80004e9c:	3b4080e7          	jalr	948(ra) # 8000124c <walkaddr>
    80004ea0:	862a                	mv	a2,a0
    if(pa == 0)
    80004ea2:	dd45                	beqz	a0,80004e5a <exec+0x108>
      n = PGSIZE;
    80004ea4:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004ea6:	fd49f2e3          	bgeu	s3,s4,80004e6a <exec+0x118>
      n = sz - i;
    80004eaa:	894e                	mv	s2,s3
    80004eac:	bf7d                	j	80004e6a <exec+0x118>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004eae:	e0843783          	ld	a5,-504(s0)
    80004eb2:	0017869b          	addiw	a3,a5,1
    80004eb6:	e0d43423          	sd	a3,-504(s0)
    80004eba:	e0043783          	ld	a5,-512(s0)
    80004ebe:	0387879b          	addiw	a5,a5,56
    80004ec2:	e8045703          	lhu	a4,-384(s0)
    80004ec6:	08e6d063          	bge	a3,a4,80004f46 <exec+0x1f4>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004eca:	2781                	sext.w	a5,a5
    80004ecc:	e0f43023          	sd	a5,-512(s0)
    80004ed0:	03800713          	li	a4,56
    80004ed4:	86be                	mv	a3,a5
    80004ed6:	e1040613          	addi	a2,s0,-496
    80004eda:	4581                	li	a1,0
    80004edc:	8556                	mv	a0,s5
    80004ede:	fffff097          	auipc	ra,0xfffff
    80004ee2:	ade080e7          	jalr	-1314(ra) # 800039bc <readi>
    80004ee6:	03800793          	li	a5,56
    80004eea:	0af51263          	bne	a0,a5,80004f8e <exec+0x23c>
    if(ph.type != ELF_PROG_LOAD)
    80004eee:	e1042783          	lw	a5,-496(s0)
    80004ef2:	4705                	li	a4,1
    80004ef4:	fae79de3          	bne	a5,a4,80004eae <exec+0x15c>
    if(ph.memsz < ph.filesz)
    80004ef8:	e3843603          	ld	a2,-456(s0)
    80004efc:	e3043783          	ld	a5,-464(s0)
    80004f00:	08f66763          	bltu	a2,a5,80004f8e <exec+0x23c>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f04:	e2043783          	ld	a5,-480(s0)
    80004f08:	963e                	add	a2,a2,a5
    80004f0a:	08f66263          	bltu	a2,a5,80004f8e <exec+0x23c>
    if((sz = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f0e:	df843583          	ld	a1,-520(s0)
    80004f12:	855a                	mv	a0,s6
    80004f14:	ffffc097          	auipc	ra,0xffffc
    80004f18:	740080e7          	jalr	1856(ra) # 80001654 <uvmalloc>
    80004f1c:	dea43c23          	sd	a0,-520(s0)
    80004f20:	c53d                	beqz	a0,80004f8e <exec+0x23c>
    if(ph.vaddr % PGSIZE != 0)
    80004f22:	e2043c03          	ld	s8,-480(s0)
    80004f26:	de043783          	ld	a5,-544(s0)
    80004f2a:	00fc77b3          	and	a5,s8,a5
    80004f2e:	e3a5                	bnez	a5,80004f8e <exec+0x23c>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f30:	e1842c83          	lw	s9,-488(s0)
    80004f34:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004f38:	f60b8be3          	beqz	s7,80004eae <exec+0x15c>
    80004f3c:	89de                	mv	s3,s7
    80004f3e:	4481                	li	s1,0
    80004f40:	b7b9                	j	80004e8e <exec+0x13c>
  sz = 0;
    80004f42:	de043c23          	sd	zero,-520(s0)
  iunlockput(ip);
    80004f46:	8556                	mv	a0,s5
    80004f48:	fffff097          	auipc	ra,0xfffff
    80004f4c:	a22080e7          	jalr	-1502(ra) # 8000396a <iunlockput>
  end_op(ROOTDEV);
    80004f50:	4501                	li	a0,0
    80004f52:	fffff097          	auipc	ra,0xfffff
    80004f56:	26a080e7          	jalr	618(ra) # 800041bc <end_op>
  p = myproc();
    80004f5a:	ffffd097          	auipc	ra,0xffffd
    80004f5e:	be2080e7          	jalr	-1054(ra) # 80001b3c <myproc>
    80004f62:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004f64:	05053c83          	ld	s9,80(a0)
  sz = PGROUNDUP(sz);
    80004f68:	6585                	lui	a1,0x1
    80004f6a:	15fd                	addi	a1,a1,-1
    80004f6c:	df843783          	ld	a5,-520(s0)
    80004f70:	95be                	add	a1,a1,a5
    80004f72:	77fd                	lui	a5,0xfffff
    80004f74:	8dfd                	and	a1,a1,a5
  if((sz = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f76:	6609                	lui	a2,0x2
    80004f78:	962e                	add	a2,a2,a1
    80004f7a:	855a                	mv	a0,s6
    80004f7c:	ffffc097          	auipc	ra,0xffffc
    80004f80:	6d8080e7          	jalr	1752(ra) # 80001654 <uvmalloc>
    80004f84:	892a                	mv	s2,a0
    80004f86:	dea43c23          	sd	a0,-520(s0)
  ip = 0;
    80004f8a:	4a81                	li	s5,0
  if((sz = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f8c:	ed01                	bnez	a0,80004fa4 <exec+0x252>
    proc_freepagetable(pagetable, sz);
    80004f8e:	df843583          	ld	a1,-520(s0)
    80004f92:	855a                	mv	a0,s6
    80004f94:	ffffd097          	auipc	ra,0xffffd
    80004f98:	d6c080e7          	jalr	-660(ra) # 80001d00 <proc_freepagetable>
  if(ip){
    80004f9c:	e40a90e3          	bnez	s5,80004ddc <exec+0x8a>
  return -1;
    80004fa0:	557d                	li	a0,-1
    80004fa2:	bd81                	j	80004df2 <exec+0xa0>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004fa4:	75f9                	lui	a1,0xffffe
    80004fa6:	95aa                	add	a1,a1,a0
    80004fa8:	855a                	mv	a0,s6
    80004faa:	ffffd097          	auipc	ra,0xffffd
    80004fae:	852080e7          	jalr	-1966(ra) # 800017fc <uvmclear>
  stackbase = sp - PGSIZE;
    80004fb2:	7c7d                	lui	s8,0xfffff
    80004fb4:	9c4a                	add	s8,s8,s2
  for(argc = 0; argv[argc]; argc++) {
    80004fb6:	df043783          	ld	a5,-528(s0)
    80004fba:	6388                	ld	a0,0(a5)
    80004fbc:	c52d                	beqz	a0,80005026 <exec+0x2d4>
    80004fbe:	e8840993          	addi	s3,s0,-376
    80004fc2:	f8840a93          	addi	s5,s0,-120
    80004fc6:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004fc8:	ffffc097          	auipc	ra,0xffffc
    80004fcc:	00e080e7          	jalr	14(ra) # 80000fd6 <strlen>
    80004fd0:	0015079b          	addiw	a5,a0,1
    80004fd4:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004fd8:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004fdc:	0f896b63          	bltu	s2,s8,800050d2 <exec+0x380>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004fe0:	df043d03          	ld	s10,-528(s0)
    80004fe4:	000d3a03          	ld	s4,0(s10) # fffffffffffff000 <end+0xffffffff7ffd2fa4>
    80004fe8:	8552                	mv	a0,s4
    80004fea:	ffffc097          	auipc	ra,0xffffc
    80004fee:	fec080e7          	jalr	-20(ra) # 80000fd6 <strlen>
    80004ff2:	0015069b          	addiw	a3,a0,1
    80004ff6:	8652                	mv	a2,s4
    80004ff8:	85ca                	mv	a1,s2
    80004ffa:	855a                	mv	a0,s6
    80004ffc:	ffffd097          	auipc	ra,0xffffd
    80005000:	832080e7          	jalr	-1998(ra) # 8000182e <copyout>
    80005004:	0c054963          	bltz	a0,800050d6 <exec+0x384>
    ustack[argc] = sp;
    80005008:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000500c:	0485                	addi	s1,s1,1
    8000500e:	008d0793          	addi	a5,s10,8
    80005012:	def43823          	sd	a5,-528(s0)
    80005016:	008d3503          	ld	a0,8(s10)
    8000501a:	c909                	beqz	a0,8000502c <exec+0x2da>
    if(argc >= MAXARG)
    8000501c:	09a1                	addi	s3,s3,8
    8000501e:	fb3a95e3          	bne	s5,s3,80004fc8 <exec+0x276>
  ip = 0;
    80005022:	4a81                	li	s5,0
    80005024:	b7ad                	j	80004f8e <exec+0x23c>
  sp = sz;
    80005026:	df843903          	ld	s2,-520(s0)
  for(argc = 0; argv[argc]; argc++) {
    8000502a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000502c:	00349793          	slli	a5,s1,0x3
    80005030:	f9040713          	addi	a4,s0,-112
    80005034:	97ba                	add	a5,a5,a4
    80005036:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd2e9c>
  sp -= (argc+1) * sizeof(uint64);
    8000503a:	00148693          	addi	a3,s1,1
    8000503e:	068e                	slli	a3,a3,0x3
    80005040:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005044:	ff097913          	andi	s2,s2,-16
  ip = 0;
    80005048:	4a81                	li	s5,0
  if(sp < stackbase)
    8000504a:	f58962e3          	bltu	s2,s8,80004f8e <exec+0x23c>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000504e:	e8840613          	addi	a2,s0,-376
    80005052:	85ca                	mv	a1,s2
    80005054:	855a                	mv	a0,s6
    80005056:	ffffc097          	auipc	ra,0xffffc
    8000505a:	7d8080e7          	jalr	2008(ra) # 8000182e <copyout>
    8000505e:	06054e63          	bltz	a0,800050da <exec+0x388>
  p->tf->a1 = sp;
    80005062:	060bb783          	ld	a5,96(s7)
    80005066:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000506a:	de843783          	ld	a5,-536(s0)
    8000506e:	0007c703          	lbu	a4,0(a5)
    80005072:	cf11                	beqz	a4,8000508e <exec+0x33c>
    80005074:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005076:	02f00693          	li	a3,47
    8000507a:	a039                	j	80005088 <exec+0x336>
      last = s+1;
    8000507c:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005080:	0785                	addi	a5,a5,1
    80005082:	fff7c703          	lbu	a4,-1(a5)
    80005086:	c701                	beqz	a4,8000508e <exec+0x33c>
    if(*s == '/')
    80005088:	fed71ce3          	bne	a4,a3,80005080 <exec+0x32e>
    8000508c:	bfc5                	j	8000507c <exec+0x32a>
  safestrcpy(p->name, last, sizeof(p->name));
    8000508e:	4641                	li	a2,16
    80005090:	de843583          	ld	a1,-536(s0)
    80005094:	160b8513          	addi	a0,s7,352
    80005098:	ffffc097          	auipc	ra,0xffffc
    8000509c:	f0c080e7          	jalr	-244(ra) # 80000fa4 <safestrcpy>
  oldpagetable = p->pagetable;
    800050a0:	058bb503          	ld	a0,88(s7)
  p->pagetable = pagetable;
    800050a4:	056bbc23          	sd	s6,88(s7)
  p->sz = sz;
    800050a8:	df843783          	ld	a5,-520(s0)
    800050ac:	04fbb823          	sd	a5,80(s7)
  p->tf->epc = elf.entry;  // initial program counter = main
    800050b0:	060bb783          	ld	a5,96(s7)
    800050b4:	e6043703          	ld	a4,-416(s0)
    800050b8:	ef98                	sd	a4,24(a5)
  p->tf->sp = sp; // initial stack pointer
    800050ba:	060bb783          	ld	a5,96(s7)
    800050be:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800050c2:	85e6                	mv	a1,s9
    800050c4:	ffffd097          	auipc	ra,0xffffd
    800050c8:	c3c080e7          	jalr	-964(ra) # 80001d00 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800050cc:	0004851b          	sext.w	a0,s1
    800050d0:	b30d                	j	80004df2 <exec+0xa0>
  ip = 0;
    800050d2:	4a81                	li	s5,0
    800050d4:	bd6d                	j	80004f8e <exec+0x23c>
    800050d6:	4a81                	li	s5,0
    800050d8:	bd5d                	j	80004f8e <exec+0x23c>
    800050da:	4a81                	li	s5,0
    800050dc:	bd4d                	j	80004f8e <exec+0x23c>

00000000800050de <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800050de:	7179                	addi	sp,sp,-48
    800050e0:	f406                	sd	ra,40(sp)
    800050e2:	f022                	sd	s0,32(sp)
    800050e4:	ec26                	sd	s1,24(sp)
    800050e6:	e84a                	sd	s2,16(sp)
    800050e8:	1800                	addi	s0,sp,48
    800050ea:	892e                	mv	s2,a1
    800050ec:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800050ee:	fdc40593          	addi	a1,s0,-36
    800050f2:	ffffe097          	auipc	ra,0xffffe
    800050f6:	ac4080e7          	jalr	-1340(ra) # 80002bb6 <argint>
    800050fa:	04054063          	bltz	a0,8000513a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050fe:	fdc42703          	lw	a4,-36(s0)
    80005102:	47bd                	li	a5,15
    80005104:	02e7ed63          	bltu	a5,a4,8000513e <argfd+0x60>
    80005108:	ffffd097          	auipc	ra,0xffffd
    8000510c:	a34080e7          	jalr	-1484(ra) # 80001b3c <myproc>
    80005110:	fdc42703          	lw	a4,-36(s0)
    80005114:	01a70793          	addi	a5,a4,26
    80005118:	078e                	slli	a5,a5,0x3
    8000511a:	953e                	add	a0,a0,a5
    8000511c:	651c                	ld	a5,8(a0)
    8000511e:	c395                	beqz	a5,80005142 <argfd+0x64>
    return -1;
  if(pfd)
    80005120:	00090463          	beqz	s2,80005128 <argfd+0x4a>
    *pfd = fd;
    80005124:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005128:	4501                	li	a0,0
  if(pf)
    8000512a:	c091                	beqz	s1,8000512e <argfd+0x50>
    *pf = f;
    8000512c:	e09c                	sd	a5,0(s1)
}
    8000512e:	70a2                	ld	ra,40(sp)
    80005130:	7402                	ld	s0,32(sp)
    80005132:	64e2                	ld	s1,24(sp)
    80005134:	6942                	ld	s2,16(sp)
    80005136:	6145                	addi	sp,sp,48
    80005138:	8082                	ret
    return -1;
    8000513a:	557d                	li	a0,-1
    8000513c:	bfcd                	j	8000512e <argfd+0x50>
    return -1;
    8000513e:	557d                	li	a0,-1
    80005140:	b7fd                	j	8000512e <argfd+0x50>
    80005142:	557d                	li	a0,-1
    80005144:	b7ed                	j	8000512e <argfd+0x50>

0000000080005146 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005146:	1101                	addi	sp,sp,-32
    80005148:	ec06                	sd	ra,24(sp)
    8000514a:	e822                	sd	s0,16(sp)
    8000514c:	e426                	sd	s1,8(sp)
    8000514e:	1000                	addi	s0,sp,32
    80005150:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005152:	ffffd097          	auipc	ra,0xffffd
    80005156:	9ea080e7          	jalr	-1558(ra) # 80001b3c <myproc>
    8000515a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000515c:	0d850793          	addi	a5,a0,216
    80005160:	4501                	li	a0,0
    80005162:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005164:	6398                	ld	a4,0(a5)
    80005166:	cb19                	beqz	a4,8000517c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005168:	2505                	addiw	a0,a0,1
    8000516a:	07a1                	addi	a5,a5,8
    8000516c:	fed51ce3          	bne	a0,a3,80005164 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005170:	557d                	li	a0,-1
}
    80005172:	60e2                	ld	ra,24(sp)
    80005174:	6442                	ld	s0,16(sp)
    80005176:	64a2                	ld	s1,8(sp)
    80005178:	6105                	addi	sp,sp,32
    8000517a:	8082                	ret
      p->ofile[fd] = f;
    8000517c:	01a50793          	addi	a5,a0,26
    80005180:	078e                	slli	a5,a5,0x3
    80005182:	963e                	add	a2,a2,a5
    80005184:	e604                	sd	s1,8(a2)
      return fd;
    80005186:	b7f5                	j	80005172 <fdalloc+0x2c>

0000000080005188 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005188:	715d                	addi	sp,sp,-80
    8000518a:	e486                	sd	ra,72(sp)
    8000518c:	e0a2                	sd	s0,64(sp)
    8000518e:	fc26                	sd	s1,56(sp)
    80005190:	f84a                	sd	s2,48(sp)
    80005192:	f44e                	sd	s3,40(sp)
    80005194:	f052                	sd	s4,32(sp)
    80005196:	ec56                	sd	s5,24(sp)
    80005198:	0880                	addi	s0,sp,80
    8000519a:	89ae                	mv	s3,a1
    8000519c:	8ab2                	mv	s5,a2
    8000519e:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800051a0:	fb040593          	addi	a1,s0,-80
    800051a4:	fffff097          	auipc	ra,0xfffff
    800051a8:	d30080e7          	jalr	-720(ra) # 80003ed4 <nameiparent>
    800051ac:	892a                	mv	s2,a0
    800051ae:	12050e63          	beqz	a0,800052ea <create+0x162>
    return 0;

  ilock(dp);
    800051b2:	ffffe097          	auipc	ra,0xffffe
    800051b6:	57a080e7          	jalr	1402(ra) # 8000372c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800051ba:	4601                	li	a2,0
    800051bc:	fb040593          	addi	a1,s0,-80
    800051c0:	854a                	mv	a0,s2
    800051c2:	fffff097          	auipc	ra,0xfffff
    800051c6:	a22080e7          	jalr	-1502(ra) # 80003be4 <dirlookup>
    800051ca:	84aa                	mv	s1,a0
    800051cc:	c921                	beqz	a0,8000521c <create+0x94>
    iunlockput(dp);
    800051ce:	854a                	mv	a0,s2
    800051d0:	ffffe097          	auipc	ra,0xffffe
    800051d4:	79a080e7          	jalr	1946(ra) # 8000396a <iunlockput>
    ilock(ip);
    800051d8:	8526                	mv	a0,s1
    800051da:	ffffe097          	auipc	ra,0xffffe
    800051de:	552080e7          	jalr	1362(ra) # 8000372c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051e2:	2981                	sext.w	s3,s3
    800051e4:	4789                	li	a5,2
    800051e6:	02f99463          	bne	s3,a5,8000520e <create+0x86>
    800051ea:	04c4d783          	lhu	a5,76(s1)
    800051ee:	37f9                	addiw	a5,a5,-2
    800051f0:	17c2                	slli	a5,a5,0x30
    800051f2:	93c1                	srli	a5,a5,0x30
    800051f4:	4705                	li	a4,1
    800051f6:	00f76c63          	bltu	a4,a5,8000520e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800051fa:	8526                	mv	a0,s1
    800051fc:	60a6                	ld	ra,72(sp)
    800051fe:	6406                	ld	s0,64(sp)
    80005200:	74e2                	ld	s1,56(sp)
    80005202:	7942                	ld	s2,48(sp)
    80005204:	79a2                	ld	s3,40(sp)
    80005206:	7a02                	ld	s4,32(sp)
    80005208:	6ae2                	ld	s5,24(sp)
    8000520a:	6161                	addi	sp,sp,80
    8000520c:	8082                	ret
    iunlockput(ip);
    8000520e:	8526                	mv	a0,s1
    80005210:	ffffe097          	auipc	ra,0xffffe
    80005214:	75a080e7          	jalr	1882(ra) # 8000396a <iunlockput>
    return 0;
    80005218:	4481                	li	s1,0
    8000521a:	b7c5                	j	800051fa <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000521c:	85ce                	mv	a1,s3
    8000521e:	00092503          	lw	a0,0(s2)
    80005222:	ffffe097          	auipc	ra,0xffffe
    80005226:	372080e7          	jalr	882(ra) # 80003594 <ialloc>
    8000522a:	84aa                	mv	s1,a0
    8000522c:	c521                	beqz	a0,80005274 <create+0xec>
  ilock(ip);
    8000522e:	ffffe097          	auipc	ra,0xffffe
    80005232:	4fe080e7          	jalr	1278(ra) # 8000372c <ilock>
  ip->major = major;
    80005236:	05549723          	sh	s5,78(s1)
  ip->minor = minor;
    8000523a:	05449823          	sh	s4,80(s1)
  ip->nlink = 1;
    8000523e:	4a05                	li	s4,1
    80005240:	05449923          	sh	s4,82(s1)
  iupdate(ip);
    80005244:	8526                	mv	a0,s1
    80005246:	ffffe097          	auipc	ra,0xffffe
    8000524a:	41c080e7          	jalr	1052(ra) # 80003662 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000524e:	2981                	sext.w	s3,s3
    80005250:	03498a63          	beq	s3,s4,80005284 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005254:	40d0                	lw	a2,4(s1)
    80005256:	fb040593          	addi	a1,s0,-80
    8000525a:	854a                	mv	a0,s2
    8000525c:	fffff097          	auipc	ra,0xfffff
    80005260:	b98080e7          	jalr	-1128(ra) # 80003df4 <dirlink>
    80005264:	06054b63          	bltz	a0,800052da <create+0x152>
  iunlockput(dp);
    80005268:	854a                	mv	a0,s2
    8000526a:	ffffe097          	auipc	ra,0xffffe
    8000526e:	700080e7          	jalr	1792(ra) # 8000396a <iunlockput>
  return ip;
    80005272:	b761                	j	800051fa <create+0x72>
    panic("create: ialloc");
    80005274:	00003517          	auipc	a0,0x3
    80005278:	5a450513          	addi	a0,a0,1444 # 80008818 <userret+0x788>
    8000527c:	ffffb097          	auipc	ra,0xffffb
    80005280:	2cc080e7          	jalr	716(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    80005284:	05295783          	lhu	a5,82(s2)
    80005288:	2785                	addiw	a5,a5,1
    8000528a:	04f91923          	sh	a5,82(s2)
    iupdate(dp);
    8000528e:	854a                	mv	a0,s2
    80005290:	ffffe097          	auipc	ra,0xffffe
    80005294:	3d2080e7          	jalr	978(ra) # 80003662 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005298:	40d0                	lw	a2,4(s1)
    8000529a:	00003597          	auipc	a1,0x3
    8000529e:	58e58593          	addi	a1,a1,1422 # 80008828 <userret+0x798>
    800052a2:	8526                	mv	a0,s1
    800052a4:	fffff097          	auipc	ra,0xfffff
    800052a8:	b50080e7          	jalr	-1200(ra) # 80003df4 <dirlink>
    800052ac:	00054f63          	bltz	a0,800052ca <create+0x142>
    800052b0:	00492603          	lw	a2,4(s2)
    800052b4:	00003597          	auipc	a1,0x3
    800052b8:	57c58593          	addi	a1,a1,1404 # 80008830 <userret+0x7a0>
    800052bc:	8526                	mv	a0,s1
    800052be:	fffff097          	auipc	ra,0xfffff
    800052c2:	b36080e7          	jalr	-1226(ra) # 80003df4 <dirlink>
    800052c6:	f80557e3          	bgez	a0,80005254 <create+0xcc>
      panic("create dots");
    800052ca:	00003517          	auipc	a0,0x3
    800052ce:	56e50513          	addi	a0,a0,1390 # 80008838 <userret+0x7a8>
    800052d2:	ffffb097          	auipc	ra,0xffffb
    800052d6:	276080e7          	jalr	630(ra) # 80000548 <panic>
    panic("create: dirlink");
    800052da:	00003517          	auipc	a0,0x3
    800052de:	56e50513          	addi	a0,a0,1390 # 80008848 <userret+0x7b8>
    800052e2:	ffffb097          	auipc	ra,0xffffb
    800052e6:	266080e7          	jalr	614(ra) # 80000548 <panic>
    return 0;
    800052ea:	84aa                	mv	s1,a0
    800052ec:	b739                	j	800051fa <create+0x72>

00000000800052ee <sys_dup>:
{
    800052ee:	7179                	addi	sp,sp,-48
    800052f0:	f406                	sd	ra,40(sp)
    800052f2:	f022                	sd	s0,32(sp)
    800052f4:	ec26                	sd	s1,24(sp)
    800052f6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052f8:	fd840613          	addi	a2,s0,-40
    800052fc:	4581                	li	a1,0
    800052fe:	4501                	li	a0,0
    80005300:	00000097          	auipc	ra,0x0
    80005304:	dde080e7          	jalr	-546(ra) # 800050de <argfd>
    return -1;
    80005308:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000530a:	02054363          	bltz	a0,80005330 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000530e:	fd843503          	ld	a0,-40(s0)
    80005312:	00000097          	auipc	ra,0x0
    80005316:	e34080e7          	jalr	-460(ra) # 80005146 <fdalloc>
    8000531a:	84aa                	mv	s1,a0
    return -1;
    8000531c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000531e:	00054963          	bltz	a0,80005330 <sys_dup+0x42>
  filedup(f);
    80005322:	fd843503          	ld	a0,-40(s0)
    80005326:	fffff097          	auipc	ra,0xfffff
    8000532a:	334080e7          	jalr	820(ra) # 8000465a <filedup>
  return fd;
    8000532e:	87a6                	mv	a5,s1
}
    80005330:	853e                	mv	a0,a5
    80005332:	70a2                	ld	ra,40(sp)
    80005334:	7402                	ld	s0,32(sp)
    80005336:	64e2                	ld	s1,24(sp)
    80005338:	6145                	addi	sp,sp,48
    8000533a:	8082                	ret

000000008000533c <sys_read>:
{
    8000533c:	7179                	addi	sp,sp,-48
    8000533e:	f406                	sd	ra,40(sp)
    80005340:	f022                	sd	s0,32(sp)
    80005342:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005344:	fe840613          	addi	a2,s0,-24
    80005348:	4581                	li	a1,0
    8000534a:	4501                	li	a0,0
    8000534c:	00000097          	auipc	ra,0x0
    80005350:	d92080e7          	jalr	-622(ra) # 800050de <argfd>
    return -1;
    80005354:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005356:	04054163          	bltz	a0,80005398 <sys_read+0x5c>
    8000535a:	fe440593          	addi	a1,s0,-28
    8000535e:	4509                	li	a0,2
    80005360:	ffffe097          	auipc	ra,0xffffe
    80005364:	856080e7          	jalr	-1962(ra) # 80002bb6 <argint>
    return -1;
    80005368:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000536a:	02054763          	bltz	a0,80005398 <sys_read+0x5c>
    8000536e:	fd840593          	addi	a1,s0,-40
    80005372:	4505                	li	a0,1
    80005374:	ffffe097          	auipc	ra,0xffffe
    80005378:	864080e7          	jalr	-1948(ra) # 80002bd8 <argaddr>
    return -1;
    8000537c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000537e:	00054d63          	bltz	a0,80005398 <sys_read+0x5c>
  return fileread(f, p, n);
    80005382:	fe442603          	lw	a2,-28(s0)
    80005386:	fd843583          	ld	a1,-40(s0)
    8000538a:	fe843503          	ld	a0,-24(s0)
    8000538e:	fffff097          	auipc	ra,0xfffff
    80005392:	460080e7          	jalr	1120(ra) # 800047ee <fileread>
    80005396:	87aa                	mv	a5,a0
}
    80005398:	853e                	mv	a0,a5
    8000539a:	70a2                	ld	ra,40(sp)
    8000539c:	7402                	ld	s0,32(sp)
    8000539e:	6145                	addi	sp,sp,48
    800053a0:	8082                	ret

00000000800053a2 <sys_write>:
{
    800053a2:	7179                	addi	sp,sp,-48
    800053a4:	f406                	sd	ra,40(sp)
    800053a6:	f022                	sd	s0,32(sp)
    800053a8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053aa:	fe840613          	addi	a2,s0,-24
    800053ae:	4581                	li	a1,0
    800053b0:	4501                	li	a0,0
    800053b2:	00000097          	auipc	ra,0x0
    800053b6:	d2c080e7          	jalr	-724(ra) # 800050de <argfd>
    return -1;
    800053ba:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053bc:	04054163          	bltz	a0,800053fe <sys_write+0x5c>
    800053c0:	fe440593          	addi	a1,s0,-28
    800053c4:	4509                	li	a0,2
    800053c6:	ffffd097          	auipc	ra,0xffffd
    800053ca:	7f0080e7          	jalr	2032(ra) # 80002bb6 <argint>
    return -1;
    800053ce:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053d0:	02054763          	bltz	a0,800053fe <sys_write+0x5c>
    800053d4:	fd840593          	addi	a1,s0,-40
    800053d8:	4505                	li	a0,1
    800053da:	ffffd097          	auipc	ra,0xffffd
    800053de:	7fe080e7          	jalr	2046(ra) # 80002bd8 <argaddr>
    return -1;
    800053e2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053e4:	00054d63          	bltz	a0,800053fe <sys_write+0x5c>
  return filewrite(f, p, n);
    800053e8:	fe442603          	lw	a2,-28(s0)
    800053ec:	fd843583          	ld	a1,-40(s0)
    800053f0:	fe843503          	ld	a0,-24(s0)
    800053f4:	fffff097          	auipc	ra,0xfffff
    800053f8:	4c0080e7          	jalr	1216(ra) # 800048b4 <filewrite>
    800053fc:	87aa                	mv	a5,a0
}
    800053fe:	853e                	mv	a0,a5
    80005400:	70a2                	ld	ra,40(sp)
    80005402:	7402                	ld	s0,32(sp)
    80005404:	6145                	addi	sp,sp,48
    80005406:	8082                	ret

0000000080005408 <sys_close>:
{
    80005408:	1101                	addi	sp,sp,-32
    8000540a:	ec06                	sd	ra,24(sp)
    8000540c:	e822                	sd	s0,16(sp)
    8000540e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005410:	fe040613          	addi	a2,s0,-32
    80005414:	fec40593          	addi	a1,s0,-20
    80005418:	4501                	li	a0,0
    8000541a:	00000097          	auipc	ra,0x0
    8000541e:	cc4080e7          	jalr	-828(ra) # 800050de <argfd>
    return -1;
    80005422:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005424:	02054463          	bltz	a0,8000544c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005428:	ffffc097          	auipc	ra,0xffffc
    8000542c:	714080e7          	jalr	1812(ra) # 80001b3c <myproc>
    80005430:	fec42783          	lw	a5,-20(s0)
    80005434:	07e9                	addi	a5,a5,26
    80005436:	078e                	slli	a5,a5,0x3
    80005438:	97aa                	add	a5,a5,a0
    8000543a:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    8000543e:	fe043503          	ld	a0,-32(s0)
    80005442:	fffff097          	auipc	ra,0xfffff
    80005446:	26a080e7          	jalr	618(ra) # 800046ac <fileclose>
  return 0;
    8000544a:	4781                	li	a5,0
}
    8000544c:	853e                	mv	a0,a5
    8000544e:	60e2                	ld	ra,24(sp)
    80005450:	6442                	ld	s0,16(sp)
    80005452:	6105                	addi	sp,sp,32
    80005454:	8082                	ret

0000000080005456 <sys_fstat>:
{
    80005456:	1101                	addi	sp,sp,-32
    80005458:	ec06                	sd	ra,24(sp)
    8000545a:	e822                	sd	s0,16(sp)
    8000545c:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000545e:	fe840613          	addi	a2,s0,-24
    80005462:	4581                	li	a1,0
    80005464:	4501                	li	a0,0
    80005466:	00000097          	auipc	ra,0x0
    8000546a:	c78080e7          	jalr	-904(ra) # 800050de <argfd>
    return -1;
    8000546e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005470:	02054563          	bltz	a0,8000549a <sys_fstat+0x44>
    80005474:	fe040593          	addi	a1,s0,-32
    80005478:	4505                	li	a0,1
    8000547a:	ffffd097          	auipc	ra,0xffffd
    8000547e:	75e080e7          	jalr	1886(ra) # 80002bd8 <argaddr>
    return -1;
    80005482:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005484:	00054b63          	bltz	a0,8000549a <sys_fstat+0x44>
  return filestat(f, st);
    80005488:	fe043583          	ld	a1,-32(s0)
    8000548c:	fe843503          	ld	a0,-24(s0)
    80005490:	fffff097          	auipc	ra,0xfffff
    80005494:	2ec080e7          	jalr	748(ra) # 8000477c <filestat>
    80005498:	87aa                	mv	a5,a0
}
    8000549a:	853e                	mv	a0,a5
    8000549c:	60e2                	ld	ra,24(sp)
    8000549e:	6442                	ld	s0,16(sp)
    800054a0:	6105                	addi	sp,sp,32
    800054a2:	8082                	ret

00000000800054a4 <sys_link>:
{
    800054a4:	7169                	addi	sp,sp,-304
    800054a6:	f606                	sd	ra,296(sp)
    800054a8:	f222                	sd	s0,288(sp)
    800054aa:	ee26                	sd	s1,280(sp)
    800054ac:	ea4a                	sd	s2,272(sp)
    800054ae:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054b0:	08000613          	li	a2,128
    800054b4:	ed040593          	addi	a1,s0,-304
    800054b8:	4501                	li	a0,0
    800054ba:	ffffd097          	auipc	ra,0xffffd
    800054be:	740080e7          	jalr	1856(ra) # 80002bfa <argstr>
    return -1;
    800054c2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054c4:	12054363          	bltz	a0,800055ea <sys_link+0x146>
    800054c8:	08000613          	li	a2,128
    800054cc:	f5040593          	addi	a1,s0,-176
    800054d0:	4505                	li	a0,1
    800054d2:	ffffd097          	auipc	ra,0xffffd
    800054d6:	728080e7          	jalr	1832(ra) # 80002bfa <argstr>
    return -1;
    800054da:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054dc:	10054763          	bltz	a0,800055ea <sys_link+0x146>
  begin_op(ROOTDEV);
    800054e0:	4501                	li	a0,0
    800054e2:	fffff097          	auipc	ra,0xfffff
    800054e6:	c30080e7          	jalr	-976(ra) # 80004112 <begin_op>
  if((ip = namei(old)) == 0){
    800054ea:	ed040513          	addi	a0,s0,-304
    800054ee:	fffff097          	auipc	ra,0xfffff
    800054f2:	9c8080e7          	jalr	-1592(ra) # 80003eb6 <namei>
    800054f6:	84aa                	mv	s1,a0
    800054f8:	c559                	beqz	a0,80005586 <sys_link+0xe2>
  ilock(ip);
    800054fa:	ffffe097          	auipc	ra,0xffffe
    800054fe:	232080e7          	jalr	562(ra) # 8000372c <ilock>
  if(ip->type == T_DIR){
    80005502:	04c49703          	lh	a4,76(s1)
    80005506:	4785                	li	a5,1
    80005508:	08f70663          	beq	a4,a5,80005594 <sys_link+0xf0>
  ip->nlink++;
    8000550c:	0524d783          	lhu	a5,82(s1)
    80005510:	2785                	addiw	a5,a5,1
    80005512:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    80005516:	8526                	mv	a0,s1
    80005518:	ffffe097          	auipc	ra,0xffffe
    8000551c:	14a080e7          	jalr	330(ra) # 80003662 <iupdate>
  iunlock(ip);
    80005520:	8526                	mv	a0,s1
    80005522:	ffffe097          	auipc	ra,0xffffe
    80005526:	2cc080e7          	jalr	716(ra) # 800037ee <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000552a:	fd040593          	addi	a1,s0,-48
    8000552e:	f5040513          	addi	a0,s0,-176
    80005532:	fffff097          	auipc	ra,0xfffff
    80005536:	9a2080e7          	jalr	-1630(ra) # 80003ed4 <nameiparent>
    8000553a:	892a                	mv	s2,a0
    8000553c:	cd2d                	beqz	a0,800055b6 <sys_link+0x112>
  ilock(dp);
    8000553e:	ffffe097          	auipc	ra,0xffffe
    80005542:	1ee080e7          	jalr	494(ra) # 8000372c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005546:	00092703          	lw	a4,0(s2)
    8000554a:	409c                	lw	a5,0(s1)
    8000554c:	06f71063          	bne	a4,a5,800055ac <sys_link+0x108>
    80005550:	40d0                	lw	a2,4(s1)
    80005552:	fd040593          	addi	a1,s0,-48
    80005556:	854a                	mv	a0,s2
    80005558:	fffff097          	auipc	ra,0xfffff
    8000555c:	89c080e7          	jalr	-1892(ra) # 80003df4 <dirlink>
    80005560:	04054663          	bltz	a0,800055ac <sys_link+0x108>
  iunlockput(dp);
    80005564:	854a                	mv	a0,s2
    80005566:	ffffe097          	auipc	ra,0xffffe
    8000556a:	404080e7          	jalr	1028(ra) # 8000396a <iunlockput>
  iput(ip);
    8000556e:	8526                	mv	a0,s1
    80005570:	ffffe097          	auipc	ra,0xffffe
    80005574:	2ca080e7          	jalr	714(ra) # 8000383a <iput>
  end_op(ROOTDEV);
    80005578:	4501                	li	a0,0
    8000557a:	fffff097          	auipc	ra,0xfffff
    8000557e:	c42080e7          	jalr	-958(ra) # 800041bc <end_op>
  return 0;
    80005582:	4781                	li	a5,0
    80005584:	a09d                	j	800055ea <sys_link+0x146>
    end_op(ROOTDEV);
    80005586:	4501                	li	a0,0
    80005588:	fffff097          	auipc	ra,0xfffff
    8000558c:	c34080e7          	jalr	-972(ra) # 800041bc <end_op>
    return -1;
    80005590:	57fd                	li	a5,-1
    80005592:	a8a1                	j	800055ea <sys_link+0x146>
    iunlockput(ip);
    80005594:	8526                	mv	a0,s1
    80005596:	ffffe097          	auipc	ra,0xffffe
    8000559a:	3d4080e7          	jalr	980(ra) # 8000396a <iunlockput>
    end_op(ROOTDEV);
    8000559e:	4501                	li	a0,0
    800055a0:	fffff097          	auipc	ra,0xfffff
    800055a4:	c1c080e7          	jalr	-996(ra) # 800041bc <end_op>
    return -1;
    800055a8:	57fd                	li	a5,-1
    800055aa:	a081                	j	800055ea <sys_link+0x146>
    iunlockput(dp);
    800055ac:	854a                	mv	a0,s2
    800055ae:	ffffe097          	auipc	ra,0xffffe
    800055b2:	3bc080e7          	jalr	956(ra) # 8000396a <iunlockput>
  ilock(ip);
    800055b6:	8526                	mv	a0,s1
    800055b8:	ffffe097          	auipc	ra,0xffffe
    800055bc:	174080e7          	jalr	372(ra) # 8000372c <ilock>
  ip->nlink--;
    800055c0:	0524d783          	lhu	a5,82(s1)
    800055c4:	37fd                	addiw	a5,a5,-1
    800055c6:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    800055ca:	8526                	mv	a0,s1
    800055cc:	ffffe097          	auipc	ra,0xffffe
    800055d0:	096080e7          	jalr	150(ra) # 80003662 <iupdate>
  iunlockput(ip);
    800055d4:	8526                	mv	a0,s1
    800055d6:	ffffe097          	auipc	ra,0xffffe
    800055da:	394080e7          	jalr	916(ra) # 8000396a <iunlockput>
  end_op(ROOTDEV);
    800055de:	4501                	li	a0,0
    800055e0:	fffff097          	auipc	ra,0xfffff
    800055e4:	bdc080e7          	jalr	-1060(ra) # 800041bc <end_op>
  return -1;
    800055e8:	57fd                	li	a5,-1
}
    800055ea:	853e                	mv	a0,a5
    800055ec:	70b2                	ld	ra,296(sp)
    800055ee:	7412                	ld	s0,288(sp)
    800055f0:	64f2                	ld	s1,280(sp)
    800055f2:	6952                	ld	s2,272(sp)
    800055f4:	6155                	addi	sp,sp,304
    800055f6:	8082                	ret

00000000800055f8 <sys_unlink>:
{
    800055f8:	7151                	addi	sp,sp,-240
    800055fa:	f586                	sd	ra,232(sp)
    800055fc:	f1a2                	sd	s0,224(sp)
    800055fe:	eda6                	sd	s1,216(sp)
    80005600:	e9ca                	sd	s2,208(sp)
    80005602:	e5ce                	sd	s3,200(sp)
    80005604:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005606:	08000613          	li	a2,128
    8000560a:	f3040593          	addi	a1,s0,-208
    8000560e:	4501                	li	a0,0
    80005610:	ffffd097          	auipc	ra,0xffffd
    80005614:	5ea080e7          	jalr	1514(ra) # 80002bfa <argstr>
    80005618:	18054463          	bltz	a0,800057a0 <sys_unlink+0x1a8>
  begin_op(ROOTDEV);
    8000561c:	4501                	li	a0,0
    8000561e:	fffff097          	auipc	ra,0xfffff
    80005622:	af4080e7          	jalr	-1292(ra) # 80004112 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005626:	fb040593          	addi	a1,s0,-80
    8000562a:	f3040513          	addi	a0,s0,-208
    8000562e:	fffff097          	auipc	ra,0xfffff
    80005632:	8a6080e7          	jalr	-1882(ra) # 80003ed4 <nameiparent>
    80005636:	84aa                	mv	s1,a0
    80005638:	cd61                	beqz	a0,80005710 <sys_unlink+0x118>
  ilock(dp);
    8000563a:	ffffe097          	auipc	ra,0xffffe
    8000563e:	0f2080e7          	jalr	242(ra) # 8000372c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005642:	00003597          	auipc	a1,0x3
    80005646:	1e658593          	addi	a1,a1,486 # 80008828 <userret+0x798>
    8000564a:	fb040513          	addi	a0,s0,-80
    8000564e:	ffffe097          	auipc	ra,0xffffe
    80005652:	57c080e7          	jalr	1404(ra) # 80003bca <namecmp>
    80005656:	14050c63          	beqz	a0,800057ae <sys_unlink+0x1b6>
    8000565a:	00003597          	auipc	a1,0x3
    8000565e:	1d658593          	addi	a1,a1,470 # 80008830 <userret+0x7a0>
    80005662:	fb040513          	addi	a0,s0,-80
    80005666:	ffffe097          	auipc	ra,0xffffe
    8000566a:	564080e7          	jalr	1380(ra) # 80003bca <namecmp>
    8000566e:	14050063          	beqz	a0,800057ae <sys_unlink+0x1b6>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005672:	f2c40613          	addi	a2,s0,-212
    80005676:	fb040593          	addi	a1,s0,-80
    8000567a:	8526                	mv	a0,s1
    8000567c:	ffffe097          	auipc	ra,0xffffe
    80005680:	568080e7          	jalr	1384(ra) # 80003be4 <dirlookup>
    80005684:	892a                	mv	s2,a0
    80005686:	12050463          	beqz	a0,800057ae <sys_unlink+0x1b6>
  ilock(ip);
    8000568a:	ffffe097          	auipc	ra,0xffffe
    8000568e:	0a2080e7          	jalr	162(ra) # 8000372c <ilock>
  if(ip->nlink < 1)
    80005692:	05291783          	lh	a5,82(s2)
    80005696:	08f05463          	blez	a5,8000571e <sys_unlink+0x126>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000569a:	04c91703          	lh	a4,76(s2)
    8000569e:	4785                	li	a5,1
    800056a0:	08f70763          	beq	a4,a5,8000572e <sys_unlink+0x136>
  memset(&de, 0, sizeof(de));
    800056a4:	4641                	li	a2,16
    800056a6:	4581                	li	a1,0
    800056a8:	fc040513          	addi	a0,s0,-64
    800056ac:	ffffb097          	auipc	ra,0xffffb
    800056b0:	7a6080e7          	jalr	1958(ra) # 80000e52 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056b4:	4741                	li	a4,16
    800056b6:	f2c42683          	lw	a3,-212(s0)
    800056ba:	fc040613          	addi	a2,s0,-64
    800056be:	4581                	li	a1,0
    800056c0:	8526                	mv	a0,s1
    800056c2:	ffffe097          	auipc	ra,0xffffe
    800056c6:	3ee080e7          	jalr	1006(ra) # 80003ab0 <writei>
    800056ca:	47c1                	li	a5,16
    800056cc:	0af51763          	bne	a0,a5,8000577a <sys_unlink+0x182>
  if(ip->type == T_DIR){
    800056d0:	04c91703          	lh	a4,76(s2)
    800056d4:	4785                	li	a5,1
    800056d6:	0af70a63          	beq	a4,a5,8000578a <sys_unlink+0x192>
  iunlockput(dp);
    800056da:	8526                	mv	a0,s1
    800056dc:	ffffe097          	auipc	ra,0xffffe
    800056e0:	28e080e7          	jalr	654(ra) # 8000396a <iunlockput>
  ip->nlink--;
    800056e4:	05295783          	lhu	a5,82(s2)
    800056e8:	37fd                	addiw	a5,a5,-1
    800056ea:	04f91923          	sh	a5,82(s2)
  iupdate(ip);
    800056ee:	854a                	mv	a0,s2
    800056f0:	ffffe097          	auipc	ra,0xffffe
    800056f4:	f72080e7          	jalr	-142(ra) # 80003662 <iupdate>
  iunlockput(ip);
    800056f8:	854a                	mv	a0,s2
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	270080e7          	jalr	624(ra) # 8000396a <iunlockput>
  end_op(ROOTDEV);
    80005702:	4501                	li	a0,0
    80005704:	fffff097          	auipc	ra,0xfffff
    80005708:	ab8080e7          	jalr	-1352(ra) # 800041bc <end_op>
  return 0;
    8000570c:	4501                	li	a0,0
    8000570e:	a85d                	j	800057c4 <sys_unlink+0x1cc>
    end_op(ROOTDEV);
    80005710:	4501                	li	a0,0
    80005712:	fffff097          	auipc	ra,0xfffff
    80005716:	aaa080e7          	jalr	-1366(ra) # 800041bc <end_op>
    return -1;
    8000571a:	557d                	li	a0,-1
    8000571c:	a065                	j	800057c4 <sys_unlink+0x1cc>
    panic("unlink: nlink < 1");
    8000571e:	00003517          	auipc	a0,0x3
    80005722:	13a50513          	addi	a0,a0,314 # 80008858 <userret+0x7c8>
    80005726:	ffffb097          	auipc	ra,0xffffb
    8000572a:	e22080e7          	jalr	-478(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000572e:	05492703          	lw	a4,84(s2)
    80005732:	02000793          	li	a5,32
    80005736:	f6e7f7e3          	bgeu	a5,a4,800056a4 <sys_unlink+0xac>
    8000573a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000573e:	4741                	li	a4,16
    80005740:	86ce                	mv	a3,s3
    80005742:	f1840613          	addi	a2,s0,-232
    80005746:	4581                	li	a1,0
    80005748:	854a                	mv	a0,s2
    8000574a:	ffffe097          	auipc	ra,0xffffe
    8000574e:	272080e7          	jalr	626(ra) # 800039bc <readi>
    80005752:	47c1                	li	a5,16
    80005754:	00f51b63          	bne	a0,a5,8000576a <sys_unlink+0x172>
    if(de.inum != 0)
    80005758:	f1845783          	lhu	a5,-232(s0)
    8000575c:	e7a1                	bnez	a5,800057a4 <sys_unlink+0x1ac>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000575e:	29c1                	addiw	s3,s3,16
    80005760:	05492783          	lw	a5,84(s2)
    80005764:	fcf9ede3          	bltu	s3,a5,8000573e <sys_unlink+0x146>
    80005768:	bf35                	j	800056a4 <sys_unlink+0xac>
      panic("isdirempty: readi");
    8000576a:	00003517          	auipc	a0,0x3
    8000576e:	10650513          	addi	a0,a0,262 # 80008870 <userret+0x7e0>
    80005772:	ffffb097          	auipc	ra,0xffffb
    80005776:	dd6080e7          	jalr	-554(ra) # 80000548 <panic>
    panic("unlink: writei");
    8000577a:	00003517          	auipc	a0,0x3
    8000577e:	10e50513          	addi	a0,a0,270 # 80008888 <userret+0x7f8>
    80005782:	ffffb097          	auipc	ra,0xffffb
    80005786:	dc6080e7          	jalr	-570(ra) # 80000548 <panic>
    dp->nlink--;
    8000578a:	0524d783          	lhu	a5,82(s1)
    8000578e:	37fd                	addiw	a5,a5,-1
    80005790:	04f49923          	sh	a5,82(s1)
    iupdate(dp);
    80005794:	8526                	mv	a0,s1
    80005796:	ffffe097          	auipc	ra,0xffffe
    8000579a:	ecc080e7          	jalr	-308(ra) # 80003662 <iupdate>
    8000579e:	bf35                	j	800056da <sys_unlink+0xe2>
    return -1;
    800057a0:	557d                	li	a0,-1
    800057a2:	a00d                	j	800057c4 <sys_unlink+0x1cc>
    iunlockput(ip);
    800057a4:	854a                	mv	a0,s2
    800057a6:	ffffe097          	auipc	ra,0xffffe
    800057aa:	1c4080e7          	jalr	452(ra) # 8000396a <iunlockput>
  iunlockput(dp);
    800057ae:	8526                	mv	a0,s1
    800057b0:	ffffe097          	auipc	ra,0xffffe
    800057b4:	1ba080e7          	jalr	442(ra) # 8000396a <iunlockput>
  end_op(ROOTDEV);
    800057b8:	4501                	li	a0,0
    800057ba:	fffff097          	auipc	ra,0xfffff
    800057be:	a02080e7          	jalr	-1534(ra) # 800041bc <end_op>
  return -1;
    800057c2:	557d                	li	a0,-1
}
    800057c4:	70ae                	ld	ra,232(sp)
    800057c6:	740e                	ld	s0,224(sp)
    800057c8:	64ee                	ld	s1,216(sp)
    800057ca:	694e                	ld	s2,208(sp)
    800057cc:	69ae                	ld	s3,200(sp)
    800057ce:	616d                	addi	sp,sp,240
    800057d0:	8082                	ret

00000000800057d2 <sys_open>:

uint64
sys_open(void)
{
    800057d2:	7131                	addi	sp,sp,-192
    800057d4:	fd06                	sd	ra,184(sp)
    800057d6:	f922                	sd	s0,176(sp)
    800057d8:	f526                	sd	s1,168(sp)
    800057da:	f14a                	sd	s2,160(sp)
    800057dc:	ed4e                	sd	s3,152(sp)
    800057de:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057e0:	08000613          	li	a2,128
    800057e4:	f5040593          	addi	a1,s0,-176
    800057e8:	4501                	li	a0,0
    800057ea:	ffffd097          	auipc	ra,0xffffd
    800057ee:	410080e7          	jalr	1040(ra) # 80002bfa <argstr>
    return -1;
    800057f2:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057f4:	0a054963          	bltz	a0,800058a6 <sys_open+0xd4>
    800057f8:	f4c40593          	addi	a1,s0,-180
    800057fc:	4505                	li	a0,1
    800057fe:	ffffd097          	auipc	ra,0xffffd
    80005802:	3b8080e7          	jalr	952(ra) # 80002bb6 <argint>
    80005806:	0a054063          	bltz	a0,800058a6 <sys_open+0xd4>

  begin_op(ROOTDEV);
    8000580a:	4501                	li	a0,0
    8000580c:	fffff097          	auipc	ra,0xfffff
    80005810:	906080e7          	jalr	-1786(ra) # 80004112 <begin_op>

  if(omode & O_CREATE){
    80005814:	f4c42783          	lw	a5,-180(s0)
    80005818:	2007f793          	andi	a5,a5,512
    8000581c:	c3dd                	beqz	a5,800058c2 <sys_open+0xf0>
    ip = create(path, T_FILE, 0, 0);
    8000581e:	4681                	li	a3,0
    80005820:	4601                	li	a2,0
    80005822:	4589                	li	a1,2
    80005824:	f5040513          	addi	a0,s0,-176
    80005828:	00000097          	auipc	ra,0x0
    8000582c:	960080e7          	jalr	-1696(ra) # 80005188 <create>
    80005830:	892a                	mv	s2,a0
    if(ip == 0){
    80005832:	c151                	beqz	a0,800058b6 <sys_open+0xe4>
      end_op(ROOTDEV);
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005834:	04c91703          	lh	a4,76(s2)
    80005838:	478d                	li	a5,3
    8000583a:	00f71763          	bne	a4,a5,80005848 <sys_open+0x76>
    8000583e:	04e95703          	lhu	a4,78(s2)
    80005842:	47a5                	li	a5,9
    80005844:	0ce7e663          	bltu	a5,a4,80005910 <sys_open+0x13e>
    iunlockput(ip);
    end_op(ROOTDEV);
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005848:	fffff097          	auipc	ra,0xfffff
    8000584c:	da8080e7          	jalr	-600(ra) # 800045f0 <filealloc>
    80005850:	89aa                	mv	s3,a0
    80005852:	c97d                	beqz	a0,80005948 <sys_open+0x176>
    80005854:	00000097          	auipc	ra,0x0
    80005858:	8f2080e7          	jalr	-1806(ra) # 80005146 <fdalloc>
    8000585c:	84aa                	mv	s1,a0
    8000585e:	0e054063          	bltz	a0,8000593e <sys_open+0x16c>
    iunlockput(ip);
    end_op(ROOTDEV);
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005862:	04c91703          	lh	a4,76(s2)
    80005866:	478d                	li	a5,3
    80005868:	0cf70063          	beq	a4,a5,80005928 <sys_open+0x156>
    f->type = FD_DEVICE;
    f->major = ip->major;
    f->minor = ip->minor;
  } else {
    f->type = FD_INODE;
    8000586c:	4789                	li	a5,2
    8000586e:	00f9a023          	sw	a5,0(s3)
  }
  f->ip = ip;
    80005872:	0129bc23          	sd	s2,24(s3)
  f->off = 0;
    80005876:	0209a023          	sw	zero,32(s3)
  f->readable = !(omode & O_WRONLY);
    8000587a:	f4c42783          	lw	a5,-180(s0)
    8000587e:	0017c713          	xori	a4,a5,1
    80005882:	8b05                	andi	a4,a4,1
    80005884:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005888:	8b8d                	andi	a5,a5,3
    8000588a:	00f037b3          	snez	a5,a5
    8000588e:	00f984a3          	sb	a5,9(s3)

  iunlock(ip);
    80005892:	854a                	mv	a0,s2
    80005894:	ffffe097          	auipc	ra,0xffffe
    80005898:	f5a080e7          	jalr	-166(ra) # 800037ee <iunlock>
  end_op(ROOTDEV);
    8000589c:	4501                	li	a0,0
    8000589e:	fffff097          	auipc	ra,0xfffff
    800058a2:	91e080e7          	jalr	-1762(ra) # 800041bc <end_op>

  return fd;
}
    800058a6:	8526                	mv	a0,s1
    800058a8:	70ea                	ld	ra,184(sp)
    800058aa:	744a                	ld	s0,176(sp)
    800058ac:	74aa                	ld	s1,168(sp)
    800058ae:	790a                	ld	s2,160(sp)
    800058b0:	69ea                	ld	s3,152(sp)
    800058b2:	6129                	addi	sp,sp,192
    800058b4:	8082                	ret
      end_op(ROOTDEV);
    800058b6:	4501                	li	a0,0
    800058b8:	fffff097          	auipc	ra,0xfffff
    800058bc:	904080e7          	jalr	-1788(ra) # 800041bc <end_op>
      return -1;
    800058c0:	b7dd                	j	800058a6 <sys_open+0xd4>
    if((ip = namei(path)) == 0){
    800058c2:	f5040513          	addi	a0,s0,-176
    800058c6:	ffffe097          	auipc	ra,0xffffe
    800058ca:	5f0080e7          	jalr	1520(ra) # 80003eb6 <namei>
    800058ce:	892a                	mv	s2,a0
    800058d0:	c90d                	beqz	a0,80005902 <sys_open+0x130>
    ilock(ip);
    800058d2:	ffffe097          	auipc	ra,0xffffe
    800058d6:	e5a080e7          	jalr	-422(ra) # 8000372c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800058da:	04c91703          	lh	a4,76(s2)
    800058de:	4785                	li	a5,1
    800058e0:	f4f71ae3          	bne	a4,a5,80005834 <sys_open+0x62>
    800058e4:	f4c42783          	lw	a5,-180(s0)
    800058e8:	d3a5                	beqz	a5,80005848 <sys_open+0x76>
      iunlockput(ip);
    800058ea:	854a                	mv	a0,s2
    800058ec:	ffffe097          	auipc	ra,0xffffe
    800058f0:	07e080e7          	jalr	126(ra) # 8000396a <iunlockput>
      end_op(ROOTDEV);
    800058f4:	4501                	li	a0,0
    800058f6:	fffff097          	auipc	ra,0xfffff
    800058fa:	8c6080e7          	jalr	-1850(ra) # 800041bc <end_op>
      return -1;
    800058fe:	54fd                	li	s1,-1
    80005900:	b75d                	j	800058a6 <sys_open+0xd4>
      end_op(ROOTDEV);
    80005902:	4501                	li	a0,0
    80005904:	fffff097          	auipc	ra,0xfffff
    80005908:	8b8080e7          	jalr	-1864(ra) # 800041bc <end_op>
      return -1;
    8000590c:	54fd                	li	s1,-1
    8000590e:	bf61                	j	800058a6 <sys_open+0xd4>
    iunlockput(ip);
    80005910:	854a                	mv	a0,s2
    80005912:	ffffe097          	auipc	ra,0xffffe
    80005916:	058080e7          	jalr	88(ra) # 8000396a <iunlockput>
    end_op(ROOTDEV);
    8000591a:	4501                	li	a0,0
    8000591c:	fffff097          	auipc	ra,0xfffff
    80005920:	8a0080e7          	jalr	-1888(ra) # 800041bc <end_op>
    return -1;
    80005924:	54fd                	li	s1,-1
    80005926:	b741                	j	800058a6 <sys_open+0xd4>
    f->type = FD_DEVICE;
    80005928:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000592c:	04e91783          	lh	a5,78(s2)
    80005930:	02f99223          	sh	a5,36(s3)
    f->minor = ip->minor;
    80005934:	05091783          	lh	a5,80(s2)
    80005938:	02f99323          	sh	a5,38(s3)
    8000593c:	bf1d                	j	80005872 <sys_open+0xa0>
      fileclose(f);
    8000593e:	854e                	mv	a0,s3
    80005940:	fffff097          	auipc	ra,0xfffff
    80005944:	d6c080e7          	jalr	-660(ra) # 800046ac <fileclose>
    iunlockput(ip);
    80005948:	854a                	mv	a0,s2
    8000594a:	ffffe097          	auipc	ra,0xffffe
    8000594e:	020080e7          	jalr	32(ra) # 8000396a <iunlockput>
    end_op(ROOTDEV);
    80005952:	4501                	li	a0,0
    80005954:	fffff097          	auipc	ra,0xfffff
    80005958:	868080e7          	jalr	-1944(ra) # 800041bc <end_op>
    return -1;
    8000595c:	54fd                	li	s1,-1
    8000595e:	b7a1                	j	800058a6 <sys_open+0xd4>

0000000080005960 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005960:	7175                	addi	sp,sp,-144
    80005962:	e506                	sd	ra,136(sp)
    80005964:	e122                	sd	s0,128(sp)
    80005966:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op(ROOTDEV);
    80005968:	4501                	li	a0,0
    8000596a:	ffffe097          	auipc	ra,0xffffe
    8000596e:	7a8080e7          	jalr	1960(ra) # 80004112 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005972:	08000613          	li	a2,128
    80005976:	f7040593          	addi	a1,s0,-144
    8000597a:	4501                	li	a0,0
    8000597c:	ffffd097          	auipc	ra,0xffffd
    80005980:	27e080e7          	jalr	638(ra) # 80002bfa <argstr>
    80005984:	02054a63          	bltz	a0,800059b8 <sys_mkdir+0x58>
    80005988:	4681                	li	a3,0
    8000598a:	4601                	li	a2,0
    8000598c:	4585                	li	a1,1
    8000598e:	f7040513          	addi	a0,s0,-144
    80005992:	fffff097          	auipc	ra,0xfffff
    80005996:	7f6080e7          	jalr	2038(ra) # 80005188 <create>
    8000599a:	cd19                	beqz	a0,800059b8 <sys_mkdir+0x58>
    end_op(ROOTDEV);
    return -1;
  }
  iunlockput(ip);
    8000599c:	ffffe097          	auipc	ra,0xffffe
    800059a0:	fce080e7          	jalr	-50(ra) # 8000396a <iunlockput>
  end_op(ROOTDEV);
    800059a4:	4501                	li	a0,0
    800059a6:	fffff097          	auipc	ra,0xfffff
    800059aa:	816080e7          	jalr	-2026(ra) # 800041bc <end_op>
  return 0;
    800059ae:	4501                	li	a0,0
}
    800059b0:	60aa                	ld	ra,136(sp)
    800059b2:	640a                	ld	s0,128(sp)
    800059b4:	6149                	addi	sp,sp,144
    800059b6:	8082                	ret
    end_op(ROOTDEV);
    800059b8:	4501                	li	a0,0
    800059ba:	fffff097          	auipc	ra,0xfffff
    800059be:	802080e7          	jalr	-2046(ra) # 800041bc <end_op>
    return -1;
    800059c2:	557d                	li	a0,-1
    800059c4:	b7f5                	j	800059b0 <sys_mkdir+0x50>

00000000800059c6 <sys_mknod>:

uint64
sys_mknod(void)
{
    800059c6:	7135                	addi	sp,sp,-160
    800059c8:	ed06                	sd	ra,152(sp)
    800059ca:	e922                	sd	s0,144(sp)
    800059cc:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op(ROOTDEV);
    800059ce:	4501                	li	a0,0
    800059d0:	ffffe097          	auipc	ra,0xffffe
    800059d4:	742080e7          	jalr	1858(ra) # 80004112 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059d8:	08000613          	li	a2,128
    800059dc:	f7040593          	addi	a1,s0,-144
    800059e0:	4501                	li	a0,0
    800059e2:	ffffd097          	auipc	ra,0xffffd
    800059e6:	218080e7          	jalr	536(ra) # 80002bfa <argstr>
    800059ea:	04054b63          	bltz	a0,80005a40 <sys_mknod+0x7a>
     argint(1, &major) < 0 ||
    800059ee:	f6c40593          	addi	a1,s0,-148
    800059f2:	4505                	li	a0,1
    800059f4:	ffffd097          	auipc	ra,0xffffd
    800059f8:	1c2080e7          	jalr	450(ra) # 80002bb6 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059fc:	04054263          	bltz	a0,80005a40 <sys_mknod+0x7a>
     argint(2, &minor) < 0 ||
    80005a00:	f6840593          	addi	a1,s0,-152
    80005a04:	4509                	li	a0,2
    80005a06:	ffffd097          	auipc	ra,0xffffd
    80005a0a:	1b0080e7          	jalr	432(ra) # 80002bb6 <argint>
     argint(1, &major) < 0 ||
    80005a0e:	02054963          	bltz	a0,80005a40 <sys_mknod+0x7a>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a12:	f6841683          	lh	a3,-152(s0)
    80005a16:	f6c41603          	lh	a2,-148(s0)
    80005a1a:	458d                	li	a1,3
    80005a1c:	f7040513          	addi	a0,s0,-144
    80005a20:	fffff097          	auipc	ra,0xfffff
    80005a24:	768080e7          	jalr	1896(ra) # 80005188 <create>
     argint(2, &minor) < 0 ||
    80005a28:	cd01                	beqz	a0,80005a40 <sys_mknod+0x7a>
    end_op(ROOTDEV);
    return -1;
  }
  iunlockput(ip);
    80005a2a:	ffffe097          	auipc	ra,0xffffe
    80005a2e:	f40080e7          	jalr	-192(ra) # 8000396a <iunlockput>
  end_op(ROOTDEV);
    80005a32:	4501                	li	a0,0
    80005a34:	ffffe097          	auipc	ra,0xffffe
    80005a38:	788080e7          	jalr	1928(ra) # 800041bc <end_op>
  return 0;
    80005a3c:	4501                	li	a0,0
    80005a3e:	a039                	j	80005a4c <sys_mknod+0x86>
    end_op(ROOTDEV);
    80005a40:	4501                	li	a0,0
    80005a42:	ffffe097          	auipc	ra,0xffffe
    80005a46:	77a080e7          	jalr	1914(ra) # 800041bc <end_op>
    return -1;
    80005a4a:	557d                	li	a0,-1
}
    80005a4c:	60ea                	ld	ra,152(sp)
    80005a4e:	644a                	ld	s0,144(sp)
    80005a50:	610d                	addi	sp,sp,160
    80005a52:	8082                	ret

0000000080005a54 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a54:	7135                	addi	sp,sp,-160
    80005a56:	ed06                	sd	ra,152(sp)
    80005a58:	e922                	sd	s0,144(sp)
    80005a5a:	e526                	sd	s1,136(sp)
    80005a5c:	e14a                	sd	s2,128(sp)
    80005a5e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a60:	ffffc097          	auipc	ra,0xffffc
    80005a64:	0dc080e7          	jalr	220(ra) # 80001b3c <myproc>
    80005a68:	892a                	mv	s2,a0
  
  begin_op(ROOTDEV);
    80005a6a:	4501                	li	a0,0
    80005a6c:	ffffe097          	auipc	ra,0xffffe
    80005a70:	6a6080e7          	jalr	1702(ra) # 80004112 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a74:	08000613          	li	a2,128
    80005a78:	f6040593          	addi	a1,s0,-160
    80005a7c:	4501                	li	a0,0
    80005a7e:	ffffd097          	auipc	ra,0xffffd
    80005a82:	17c080e7          	jalr	380(ra) # 80002bfa <argstr>
    80005a86:	04054c63          	bltz	a0,80005ade <sys_chdir+0x8a>
    80005a8a:	f6040513          	addi	a0,s0,-160
    80005a8e:	ffffe097          	auipc	ra,0xffffe
    80005a92:	428080e7          	jalr	1064(ra) # 80003eb6 <namei>
    80005a96:	84aa                	mv	s1,a0
    80005a98:	c139                	beqz	a0,80005ade <sys_chdir+0x8a>
    end_op(ROOTDEV);
    return -1;
  }
  ilock(ip);
    80005a9a:	ffffe097          	auipc	ra,0xffffe
    80005a9e:	c92080e7          	jalr	-878(ra) # 8000372c <ilock>
  if(ip->type != T_DIR){
    80005aa2:	04c49703          	lh	a4,76(s1)
    80005aa6:	4785                	li	a5,1
    80005aa8:	04f71263          	bne	a4,a5,80005aec <sys_chdir+0x98>
    iunlockput(ip);
    end_op(ROOTDEV);
    return -1;
  }
  iunlock(ip);
    80005aac:	8526                	mv	a0,s1
    80005aae:	ffffe097          	auipc	ra,0xffffe
    80005ab2:	d40080e7          	jalr	-704(ra) # 800037ee <iunlock>
  iput(p->cwd);
    80005ab6:	15893503          	ld	a0,344(s2)
    80005aba:	ffffe097          	auipc	ra,0xffffe
    80005abe:	d80080e7          	jalr	-640(ra) # 8000383a <iput>
  end_op(ROOTDEV);
    80005ac2:	4501                	li	a0,0
    80005ac4:	ffffe097          	auipc	ra,0xffffe
    80005ac8:	6f8080e7          	jalr	1784(ra) # 800041bc <end_op>
  p->cwd = ip;
    80005acc:	14993c23          	sd	s1,344(s2)
  return 0;
    80005ad0:	4501                	li	a0,0
}
    80005ad2:	60ea                	ld	ra,152(sp)
    80005ad4:	644a                	ld	s0,144(sp)
    80005ad6:	64aa                	ld	s1,136(sp)
    80005ad8:	690a                	ld	s2,128(sp)
    80005ada:	610d                	addi	sp,sp,160
    80005adc:	8082                	ret
    end_op(ROOTDEV);
    80005ade:	4501                	li	a0,0
    80005ae0:	ffffe097          	auipc	ra,0xffffe
    80005ae4:	6dc080e7          	jalr	1756(ra) # 800041bc <end_op>
    return -1;
    80005ae8:	557d                	li	a0,-1
    80005aea:	b7e5                	j	80005ad2 <sys_chdir+0x7e>
    iunlockput(ip);
    80005aec:	8526                	mv	a0,s1
    80005aee:	ffffe097          	auipc	ra,0xffffe
    80005af2:	e7c080e7          	jalr	-388(ra) # 8000396a <iunlockput>
    end_op(ROOTDEV);
    80005af6:	4501                	li	a0,0
    80005af8:	ffffe097          	auipc	ra,0xffffe
    80005afc:	6c4080e7          	jalr	1732(ra) # 800041bc <end_op>
    return -1;
    80005b00:	557d                	li	a0,-1
    80005b02:	bfc1                	j	80005ad2 <sys_chdir+0x7e>

0000000080005b04 <sys_exec>:

uint64
sys_exec(void)
{
    80005b04:	7145                	addi	sp,sp,-464
    80005b06:	e786                	sd	ra,456(sp)
    80005b08:	e3a2                	sd	s0,448(sp)
    80005b0a:	ff26                	sd	s1,440(sp)
    80005b0c:	fb4a                	sd	s2,432(sp)
    80005b0e:	f74e                	sd	s3,424(sp)
    80005b10:	f352                	sd	s4,416(sp)
    80005b12:	ef56                	sd	s5,408(sp)
    80005b14:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b16:	08000613          	li	a2,128
    80005b1a:	f4040593          	addi	a1,s0,-192
    80005b1e:	4501                	li	a0,0
    80005b20:	ffffd097          	auipc	ra,0xffffd
    80005b24:	0da080e7          	jalr	218(ra) # 80002bfa <argstr>
    80005b28:	0e054663          	bltz	a0,80005c14 <sys_exec+0x110>
    80005b2c:	e3840593          	addi	a1,s0,-456
    80005b30:	4505                	li	a0,1
    80005b32:	ffffd097          	auipc	ra,0xffffd
    80005b36:	0a6080e7          	jalr	166(ra) # 80002bd8 <argaddr>
    80005b3a:	0e054763          	bltz	a0,80005c28 <sys_exec+0x124>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
    80005b3e:	10000613          	li	a2,256
    80005b42:	4581                	li	a1,0
    80005b44:	e4040513          	addi	a0,s0,-448
    80005b48:	ffffb097          	auipc	ra,0xffffb
    80005b4c:	30a080e7          	jalr	778(ra) # 80000e52 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b50:	e4040913          	addi	s2,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b54:	89ca                	mv	s3,s2
    80005b56:	4481                	li	s1,0
    if(i >= NELEM(argv)){
    80005b58:	02000a13          	li	s4,32
    80005b5c:	00048a9b          	sext.w	s5,s1
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b60:	00349793          	slli	a5,s1,0x3
    80005b64:	e3040593          	addi	a1,s0,-464
    80005b68:	e3843503          	ld	a0,-456(s0)
    80005b6c:	953e                	add	a0,a0,a5
    80005b6e:	ffffd097          	auipc	ra,0xffffd
    80005b72:	fae080e7          	jalr	-82(ra) # 80002b1c <fetchaddr>
    80005b76:	02054a63          	bltz	a0,80005baa <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005b7a:	e3043783          	ld	a5,-464(s0)
    80005b7e:	c7a1                	beqz	a5,80005bc6 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b80:	ffffb097          	auipc	ra,0xffffb
    80005b84:	e30080e7          	jalr	-464(ra) # 800009b0 <kalloc>
    80005b88:	85aa                	mv	a1,a0
    80005b8a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b8e:	c92d                	beqz	a0,80005c00 <sys_exec+0xfc>
      panic("sys_exec kalloc");
    if(fetchstr(uarg, argv[i], PGSIZE) < 0){
    80005b90:	6605                	lui	a2,0x1
    80005b92:	e3043503          	ld	a0,-464(s0)
    80005b96:	ffffd097          	auipc	ra,0xffffd
    80005b9a:	fd8080e7          	jalr	-40(ra) # 80002b6e <fetchstr>
    80005b9e:	00054663          	bltz	a0,80005baa <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005ba2:	0485                	addi	s1,s1,1
    80005ba4:	09a1                	addi	s3,s3,8
    80005ba6:	fb449be3          	bne	s1,s4,80005b5c <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005baa:	10090493          	addi	s1,s2,256
    80005bae:	00093503          	ld	a0,0(s2)
    80005bb2:	cd39                	beqz	a0,80005c10 <sys_exec+0x10c>
    kfree(argv[i]);
    80005bb4:	ffffb097          	auipc	ra,0xffffb
    80005bb8:	cb0080e7          	jalr	-848(ra) # 80000864 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bbc:	0921                	addi	s2,s2,8
    80005bbe:	fe9918e3          	bne	s2,s1,80005bae <sys_exec+0xaa>
  return -1;
    80005bc2:	557d                	li	a0,-1
    80005bc4:	a889                	j	80005c16 <sys_exec+0x112>
      argv[i] = 0;
    80005bc6:	0a8e                	slli	s5,s5,0x3
    80005bc8:	fc040793          	addi	a5,s0,-64
    80005bcc:	9abe                	add	s5,s5,a5
    80005bce:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005bd2:	e4040593          	addi	a1,s0,-448
    80005bd6:	f4040513          	addi	a0,s0,-192
    80005bda:	fffff097          	auipc	ra,0xfffff
    80005bde:	178080e7          	jalr	376(ra) # 80004d52 <exec>
    80005be2:	84aa                	mv	s1,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005be4:	10090993          	addi	s3,s2,256
    80005be8:	00093503          	ld	a0,0(s2)
    80005bec:	c901                	beqz	a0,80005bfc <sys_exec+0xf8>
    kfree(argv[i]);
    80005bee:	ffffb097          	auipc	ra,0xffffb
    80005bf2:	c76080e7          	jalr	-906(ra) # 80000864 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bf6:	0921                	addi	s2,s2,8
    80005bf8:	ff3918e3          	bne	s2,s3,80005be8 <sys_exec+0xe4>
  return ret;
    80005bfc:	8526                	mv	a0,s1
    80005bfe:	a821                	j	80005c16 <sys_exec+0x112>
      panic("sys_exec kalloc");
    80005c00:	00003517          	auipc	a0,0x3
    80005c04:	c9850513          	addi	a0,a0,-872 # 80008898 <userret+0x808>
    80005c08:	ffffb097          	auipc	ra,0xffffb
    80005c0c:	940080e7          	jalr	-1728(ra) # 80000548 <panic>
  return -1;
    80005c10:	557d                	li	a0,-1
    80005c12:	a011                	j	80005c16 <sys_exec+0x112>
    return -1;
    80005c14:	557d                	li	a0,-1
}
    80005c16:	60be                	ld	ra,456(sp)
    80005c18:	641e                	ld	s0,448(sp)
    80005c1a:	74fa                	ld	s1,440(sp)
    80005c1c:	795a                	ld	s2,432(sp)
    80005c1e:	79ba                	ld	s3,424(sp)
    80005c20:	7a1a                	ld	s4,416(sp)
    80005c22:	6afa                	ld	s5,408(sp)
    80005c24:	6179                	addi	sp,sp,464
    80005c26:	8082                	ret
    return -1;
    80005c28:	557d                	li	a0,-1
    80005c2a:	b7f5                	j	80005c16 <sys_exec+0x112>

0000000080005c2c <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c2c:	7139                	addi	sp,sp,-64
    80005c2e:	fc06                	sd	ra,56(sp)
    80005c30:	f822                	sd	s0,48(sp)
    80005c32:	f426                	sd	s1,40(sp)
    80005c34:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c36:	ffffc097          	auipc	ra,0xffffc
    80005c3a:	f06080e7          	jalr	-250(ra) # 80001b3c <myproc>
    80005c3e:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c40:	fd840593          	addi	a1,s0,-40
    80005c44:	4501                	li	a0,0
    80005c46:	ffffd097          	auipc	ra,0xffffd
    80005c4a:	f92080e7          	jalr	-110(ra) # 80002bd8 <argaddr>
    return -1;
    80005c4e:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c50:	0e054063          	bltz	a0,80005d30 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c54:	fc840593          	addi	a1,s0,-56
    80005c58:	fd040513          	addi	a0,s0,-48
    80005c5c:	fffff097          	auipc	ra,0xfffff
    80005c60:	db4080e7          	jalr	-588(ra) # 80004a10 <pipealloc>
    return -1;
    80005c64:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c66:	0c054563          	bltz	a0,80005d30 <sys_pipe+0x104>
  fd0 = -1;
    80005c6a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c6e:	fd043503          	ld	a0,-48(s0)
    80005c72:	fffff097          	auipc	ra,0xfffff
    80005c76:	4d4080e7          	jalr	1236(ra) # 80005146 <fdalloc>
    80005c7a:	fca42223          	sw	a0,-60(s0)
    80005c7e:	08054c63          	bltz	a0,80005d16 <sys_pipe+0xea>
    80005c82:	fc843503          	ld	a0,-56(s0)
    80005c86:	fffff097          	auipc	ra,0xfffff
    80005c8a:	4c0080e7          	jalr	1216(ra) # 80005146 <fdalloc>
    80005c8e:	fca42023          	sw	a0,-64(s0)
    80005c92:	06054863          	bltz	a0,80005d02 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c96:	4691                	li	a3,4
    80005c98:	fc440613          	addi	a2,s0,-60
    80005c9c:	fd843583          	ld	a1,-40(s0)
    80005ca0:	6ca8                	ld	a0,88(s1)
    80005ca2:	ffffc097          	auipc	ra,0xffffc
    80005ca6:	b8c080e7          	jalr	-1140(ra) # 8000182e <copyout>
    80005caa:	02054063          	bltz	a0,80005cca <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005cae:	4691                	li	a3,4
    80005cb0:	fc040613          	addi	a2,s0,-64
    80005cb4:	fd843583          	ld	a1,-40(s0)
    80005cb8:	0591                	addi	a1,a1,4
    80005cba:	6ca8                	ld	a0,88(s1)
    80005cbc:	ffffc097          	auipc	ra,0xffffc
    80005cc0:	b72080e7          	jalr	-1166(ra) # 8000182e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005cc4:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cc6:	06055563          	bgez	a0,80005d30 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005cca:	fc442783          	lw	a5,-60(s0)
    80005cce:	07e9                	addi	a5,a5,26
    80005cd0:	078e                	slli	a5,a5,0x3
    80005cd2:	97a6                	add	a5,a5,s1
    80005cd4:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005cd8:	fc042503          	lw	a0,-64(s0)
    80005cdc:	0569                	addi	a0,a0,26
    80005cde:	050e                	slli	a0,a0,0x3
    80005ce0:	9526                	add	a0,a0,s1
    80005ce2:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005ce6:	fd043503          	ld	a0,-48(s0)
    80005cea:	fffff097          	auipc	ra,0xfffff
    80005cee:	9c2080e7          	jalr	-1598(ra) # 800046ac <fileclose>
    fileclose(wf);
    80005cf2:	fc843503          	ld	a0,-56(s0)
    80005cf6:	fffff097          	auipc	ra,0xfffff
    80005cfa:	9b6080e7          	jalr	-1610(ra) # 800046ac <fileclose>
    return -1;
    80005cfe:	57fd                	li	a5,-1
    80005d00:	a805                	j	80005d30 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005d02:	fc442783          	lw	a5,-60(s0)
    80005d06:	0007c863          	bltz	a5,80005d16 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005d0a:	01a78513          	addi	a0,a5,26
    80005d0e:	050e                	slli	a0,a0,0x3
    80005d10:	9526                	add	a0,a0,s1
    80005d12:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005d16:	fd043503          	ld	a0,-48(s0)
    80005d1a:	fffff097          	auipc	ra,0xfffff
    80005d1e:	992080e7          	jalr	-1646(ra) # 800046ac <fileclose>
    fileclose(wf);
    80005d22:	fc843503          	ld	a0,-56(s0)
    80005d26:	fffff097          	auipc	ra,0xfffff
    80005d2a:	986080e7          	jalr	-1658(ra) # 800046ac <fileclose>
    return -1;
    80005d2e:	57fd                	li	a5,-1
}
    80005d30:	853e                	mv	a0,a5
    80005d32:	70e2                	ld	ra,56(sp)
    80005d34:	7442                	ld	s0,48(sp)
    80005d36:	74a2                	ld	s1,40(sp)
    80005d38:	6121                	addi	sp,sp,64
    80005d3a:	8082                	ret
    80005d3c:	0000                	unimp
	...

0000000080005d40 <kernelvec>:
    80005d40:	7111                	addi	sp,sp,-256
    80005d42:	e006                	sd	ra,0(sp)
    80005d44:	e40a                	sd	sp,8(sp)
    80005d46:	e80e                	sd	gp,16(sp)
    80005d48:	ec12                	sd	tp,24(sp)
    80005d4a:	f016                	sd	t0,32(sp)
    80005d4c:	f41a                	sd	t1,40(sp)
    80005d4e:	f81e                	sd	t2,48(sp)
    80005d50:	fc22                	sd	s0,56(sp)
    80005d52:	e0a6                	sd	s1,64(sp)
    80005d54:	e4aa                	sd	a0,72(sp)
    80005d56:	e8ae                	sd	a1,80(sp)
    80005d58:	ecb2                	sd	a2,88(sp)
    80005d5a:	f0b6                	sd	a3,96(sp)
    80005d5c:	f4ba                	sd	a4,104(sp)
    80005d5e:	f8be                	sd	a5,112(sp)
    80005d60:	fcc2                	sd	a6,120(sp)
    80005d62:	e146                	sd	a7,128(sp)
    80005d64:	e54a                	sd	s2,136(sp)
    80005d66:	e94e                	sd	s3,144(sp)
    80005d68:	ed52                	sd	s4,152(sp)
    80005d6a:	f156                	sd	s5,160(sp)
    80005d6c:	f55a                	sd	s6,168(sp)
    80005d6e:	f95e                	sd	s7,176(sp)
    80005d70:	fd62                	sd	s8,184(sp)
    80005d72:	e1e6                	sd	s9,192(sp)
    80005d74:	e5ea                	sd	s10,200(sp)
    80005d76:	e9ee                	sd	s11,208(sp)
    80005d78:	edf2                	sd	t3,216(sp)
    80005d7a:	f1f6                	sd	t4,224(sp)
    80005d7c:	f5fa                	sd	t5,232(sp)
    80005d7e:	f9fe                	sd	t6,240(sp)
    80005d80:	c69fc0ef          	jal	ra,800029e8 <kerneltrap>
    80005d84:	6082                	ld	ra,0(sp)
    80005d86:	6122                	ld	sp,8(sp)
    80005d88:	61c2                	ld	gp,16(sp)
    80005d8a:	7282                	ld	t0,32(sp)
    80005d8c:	7322                	ld	t1,40(sp)
    80005d8e:	73c2                	ld	t2,48(sp)
    80005d90:	7462                	ld	s0,56(sp)
    80005d92:	6486                	ld	s1,64(sp)
    80005d94:	6526                	ld	a0,72(sp)
    80005d96:	65c6                	ld	a1,80(sp)
    80005d98:	6666                	ld	a2,88(sp)
    80005d9a:	7686                	ld	a3,96(sp)
    80005d9c:	7726                	ld	a4,104(sp)
    80005d9e:	77c6                	ld	a5,112(sp)
    80005da0:	7866                	ld	a6,120(sp)
    80005da2:	688a                	ld	a7,128(sp)
    80005da4:	692a                	ld	s2,136(sp)
    80005da6:	69ca                	ld	s3,144(sp)
    80005da8:	6a6a                	ld	s4,152(sp)
    80005daa:	7a8a                	ld	s5,160(sp)
    80005dac:	7b2a                	ld	s6,168(sp)
    80005dae:	7bca                	ld	s7,176(sp)
    80005db0:	7c6a                	ld	s8,184(sp)
    80005db2:	6c8e                	ld	s9,192(sp)
    80005db4:	6d2e                	ld	s10,200(sp)
    80005db6:	6dce                	ld	s11,208(sp)
    80005db8:	6e6e                	ld	t3,216(sp)
    80005dba:	7e8e                	ld	t4,224(sp)
    80005dbc:	7f2e                	ld	t5,232(sp)
    80005dbe:	7fce                	ld	t6,240(sp)
    80005dc0:	6111                	addi	sp,sp,256
    80005dc2:	10200073          	sret
    80005dc6:	00000013          	nop
    80005dca:	00000013          	nop
    80005dce:	0001                	nop

0000000080005dd0 <timervec>:
    80005dd0:	34051573          	csrrw	a0,mscratch,a0
    80005dd4:	e10c                	sd	a1,0(a0)
    80005dd6:	e510                	sd	a2,8(a0)
    80005dd8:	e914                	sd	a3,16(a0)
    80005dda:	710c                	ld	a1,32(a0)
    80005ddc:	7510                	ld	a2,40(a0)
    80005dde:	6194                	ld	a3,0(a1)
    80005de0:	96b2                	add	a3,a3,a2
    80005de2:	e194                	sd	a3,0(a1)
    80005de4:	4589                	li	a1,2
    80005de6:	14459073          	csrw	sip,a1
    80005dea:	6914                	ld	a3,16(a0)
    80005dec:	6510                	ld	a2,8(a0)
    80005dee:	610c                	ld	a1,0(a0)
    80005df0:	34051573          	csrrw	a0,mscratch,a0
    80005df4:	30200073          	mret
	...

0000000080005dfa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005dfa:	1141                	addi	sp,sp,-16
    80005dfc:	e422                	sd	s0,8(sp)
    80005dfe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e00:	0c0007b7          	lui	a5,0xc000
    80005e04:	4705                	li	a4,1
    80005e06:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e08:	c3d8                	sw	a4,4(a5)
}
    80005e0a:	6422                	ld	s0,8(sp)
    80005e0c:	0141                	addi	sp,sp,16
    80005e0e:	8082                	ret

0000000080005e10 <plicinithart>:

void
plicinithart(void)
{
    80005e10:	1141                	addi	sp,sp,-16
    80005e12:	e406                	sd	ra,8(sp)
    80005e14:	e022                	sd	s0,0(sp)
    80005e16:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e18:	ffffc097          	auipc	ra,0xffffc
    80005e1c:	cf8080e7          	jalr	-776(ra) # 80001b10 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e20:	0085171b          	slliw	a4,a0,0x8
    80005e24:	0c0027b7          	lui	a5,0xc002
    80005e28:	97ba                	add	a5,a5,a4
    80005e2a:	40200713          	li	a4,1026
    80005e2e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e32:	00d5151b          	slliw	a0,a0,0xd
    80005e36:	0c2017b7          	lui	a5,0xc201
    80005e3a:	953e                	add	a0,a0,a5
    80005e3c:	00052023          	sw	zero,0(a0)
}
    80005e40:	60a2                	ld	ra,8(sp)
    80005e42:	6402                	ld	s0,0(sp)
    80005e44:	0141                	addi	sp,sp,16
    80005e46:	8082                	ret

0000000080005e48 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e48:	1141                	addi	sp,sp,-16
    80005e4a:	e406                	sd	ra,8(sp)
    80005e4c:	e022                	sd	s0,0(sp)
    80005e4e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e50:	ffffc097          	auipc	ra,0xffffc
    80005e54:	cc0080e7          	jalr	-832(ra) # 80001b10 <cpuid>
  //int irq = *(uint32*)(PLIC + 0x201004);
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e58:	00d5179b          	slliw	a5,a0,0xd
    80005e5c:	0c201537          	lui	a0,0xc201
    80005e60:	953e                	add	a0,a0,a5
  return irq;
}
    80005e62:	4148                	lw	a0,4(a0)
    80005e64:	60a2                	ld	ra,8(sp)
    80005e66:	6402                	ld	s0,0(sp)
    80005e68:	0141                	addi	sp,sp,16
    80005e6a:	8082                	ret

0000000080005e6c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e6c:	1101                	addi	sp,sp,-32
    80005e6e:	ec06                	sd	ra,24(sp)
    80005e70:	e822                	sd	s0,16(sp)
    80005e72:	e426                	sd	s1,8(sp)
    80005e74:	1000                	addi	s0,sp,32
    80005e76:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e78:	ffffc097          	auipc	ra,0xffffc
    80005e7c:	c98080e7          	jalr	-872(ra) # 80001b10 <cpuid>
  //*(uint32*)(PLIC + 0x201004) = irq;
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e80:	00d5151b          	slliw	a0,a0,0xd
    80005e84:	0c2017b7          	lui	a5,0xc201
    80005e88:	97aa                	add	a5,a5,a0
    80005e8a:	c3c4                	sw	s1,4(a5)
}
    80005e8c:	60e2                	ld	ra,24(sp)
    80005e8e:	6442                	ld	s0,16(sp)
    80005e90:	64a2                	ld	s1,8(sp)
    80005e92:	6105                	addi	sp,sp,32
    80005e94:	8082                	ret

0000000080005e96 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int n, int i)
{
    80005e96:	1141                	addi	sp,sp,-16
    80005e98:	e406                	sd	ra,8(sp)
    80005e9a:	e022                	sd	s0,0(sp)
    80005e9c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e9e:	479d                	li	a5,7
    80005ea0:	06b7c963          	blt	a5,a1,80005f12 <free_desc+0x7c>
    panic("virtio_disk_intr 1");
  if(disk[n].free[i])
    80005ea4:	00151793          	slli	a5,a0,0x1
    80005ea8:	97aa                	add	a5,a5,a0
    80005eaa:	00c79713          	slli	a4,a5,0xc
    80005eae:	00020797          	auipc	a5,0x20
    80005eb2:	15278793          	addi	a5,a5,338 # 80026000 <disk>
    80005eb6:	97ba                	add	a5,a5,a4
    80005eb8:	97ae                	add	a5,a5,a1
    80005eba:	6709                	lui	a4,0x2
    80005ebc:	97ba                	add	a5,a5,a4
    80005ebe:	0187c783          	lbu	a5,24(a5)
    80005ec2:	e3a5                	bnez	a5,80005f22 <free_desc+0x8c>
    panic("virtio_disk_intr 2");
  disk[n].desc[i].addr = 0;
    80005ec4:	00020817          	auipc	a6,0x20
    80005ec8:	13c80813          	addi	a6,a6,316 # 80026000 <disk>
    80005ecc:	00151693          	slli	a3,a0,0x1
    80005ed0:	00a68733          	add	a4,a3,a0
    80005ed4:	0732                	slli	a4,a4,0xc
    80005ed6:	00e807b3          	add	a5,a6,a4
    80005eda:	6709                	lui	a4,0x2
    80005edc:	00f70633          	add	a2,a4,a5
    80005ee0:	6210                	ld	a2,0(a2)
    80005ee2:	00459893          	slli	a7,a1,0x4
    80005ee6:	9646                	add	a2,a2,a7
    80005ee8:	00063023          	sd	zero,0(a2) # 1000 <_entry-0x7ffff000>
  disk[n].free[i] = 1;
    80005eec:	97ae                	add	a5,a5,a1
    80005eee:	97ba                	add	a5,a5,a4
    80005ef0:	4605                	li	a2,1
    80005ef2:	00c78c23          	sb	a2,24(a5)
  wakeup(&disk[n].free[0]);
    80005ef6:	96aa                	add	a3,a3,a0
    80005ef8:	06b2                	slli	a3,a3,0xc
    80005efa:	0761                	addi	a4,a4,24
    80005efc:	96ba                	add	a3,a3,a4
    80005efe:	00d80533          	add	a0,a6,a3
    80005f02:	ffffc097          	auipc	ra,0xffffc
    80005f06:	590080e7          	jalr	1424(ra) # 80002492 <wakeup>
}
    80005f0a:	60a2                	ld	ra,8(sp)
    80005f0c:	6402                	ld	s0,0(sp)
    80005f0e:	0141                	addi	sp,sp,16
    80005f10:	8082                	ret
    panic("virtio_disk_intr 1");
    80005f12:	00003517          	auipc	a0,0x3
    80005f16:	99650513          	addi	a0,a0,-1642 # 800088a8 <userret+0x818>
    80005f1a:	ffffa097          	auipc	ra,0xffffa
    80005f1e:	62e080e7          	jalr	1582(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80005f22:	00003517          	auipc	a0,0x3
    80005f26:	99e50513          	addi	a0,a0,-1634 # 800088c0 <userret+0x830>
    80005f2a:	ffffa097          	auipc	ra,0xffffa
    80005f2e:	61e080e7          	jalr	1566(ra) # 80000548 <panic>

0000000080005f32 <virtio_disk_init>:
  __sync_synchronize();
    80005f32:	0ff0000f          	fence
  if(disk[n].init)
    80005f36:	00151793          	slli	a5,a0,0x1
    80005f3a:	97aa                	add	a5,a5,a0
    80005f3c:	07b2                	slli	a5,a5,0xc
    80005f3e:	00020717          	auipc	a4,0x20
    80005f42:	0c270713          	addi	a4,a4,194 # 80026000 <disk>
    80005f46:	973e                	add	a4,a4,a5
    80005f48:	6789                	lui	a5,0x2
    80005f4a:	97ba                	add	a5,a5,a4
    80005f4c:	0a87a783          	lw	a5,168(a5) # 20a8 <_entry-0x7fffdf58>
    80005f50:	c391                	beqz	a5,80005f54 <virtio_disk_init+0x22>
    80005f52:	8082                	ret
{
    80005f54:	7139                	addi	sp,sp,-64
    80005f56:	fc06                	sd	ra,56(sp)
    80005f58:	f822                	sd	s0,48(sp)
    80005f5a:	f426                	sd	s1,40(sp)
    80005f5c:	f04a                	sd	s2,32(sp)
    80005f5e:	ec4e                	sd	s3,24(sp)
    80005f60:	e852                	sd	s4,16(sp)
    80005f62:	e456                	sd	s5,8(sp)
    80005f64:	0080                	addi	s0,sp,64
    80005f66:	84aa                	mv	s1,a0
  printf("virtio disk init %d\n", n);
    80005f68:	85aa                	mv	a1,a0
    80005f6a:	00003517          	auipc	a0,0x3
    80005f6e:	96e50513          	addi	a0,a0,-1682 # 800088d8 <userret+0x848>
    80005f72:	ffffa097          	auipc	ra,0xffffa
    80005f76:	630080e7          	jalr	1584(ra) # 800005a2 <printf>
  initlock(&disk[n].vdisk_lock, "virtio_disk");
    80005f7a:	00149993          	slli	s3,s1,0x1
    80005f7e:	99a6                	add	s3,s3,s1
    80005f80:	09b2                	slli	s3,s3,0xc
    80005f82:	6789                	lui	a5,0x2
    80005f84:	0b078793          	addi	a5,a5,176 # 20b0 <_entry-0x7fffdf50>
    80005f88:	97ce                	add	a5,a5,s3
    80005f8a:	00003597          	auipc	a1,0x3
    80005f8e:	96658593          	addi	a1,a1,-1690 # 800088f0 <userret+0x860>
    80005f92:	00020517          	auipc	a0,0x20
    80005f96:	06e50513          	addi	a0,a0,110 # 80026000 <disk>
    80005f9a:	953e                	add	a0,a0,a5
    80005f9c:	ffffb097          	auipc	ra,0xffffb
    80005fa0:	afa080e7          	jalr	-1286(ra) # 80000a96 <initlock>
  if(*R(n, VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fa4:	0014891b          	addiw	s2,s1,1
    80005fa8:	00c9191b          	slliw	s2,s2,0xc
    80005fac:	100007b7          	lui	a5,0x10000
    80005fb0:	97ca                	add	a5,a5,s2
    80005fb2:	4398                	lw	a4,0(a5)
    80005fb4:	2701                	sext.w	a4,a4
    80005fb6:	747277b7          	lui	a5,0x74727
    80005fba:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005fbe:	12f71663          	bne	a4,a5,800060ea <virtio_disk_init+0x1b8>
     *R(n, VIRTIO_MMIO_VERSION) != 1 ||
    80005fc2:	100007b7          	lui	a5,0x10000
    80005fc6:	0791                	addi	a5,a5,4
    80005fc8:	97ca                	add	a5,a5,s2
    80005fca:	439c                	lw	a5,0(a5)
    80005fcc:	2781                	sext.w	a5,a5
  if(*R(n, VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fce:	4705                	li	a4,1
    80005fd0:	10e79d63          	bne	a5,a4,800060ea <virtio_disk_init+0x1b8>
     *R(n, VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fd4:	100007b7          	lui	a5,0x10000
    80005fd8:	07a1                	addi	a5,a5,8
    80005fda:	97ca                	add	a5,a5,s2
    80005fdc:	439c                	lw	a5,0(a5)
    80005fde:	2781                	sext.w	a5,a5
     *R(n, VIRTIO_MMIO_VERSION) != 1 ||
    80005fe0:	4709                	li	a4,2
    80005fe2:	10e79463          	bne	a5,a4,800060ea <virtio_disk_init+0x1b8>
     *R(n, VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005fe6:	100007b7          	lui	a5,0x10000
    80005fea:	07b1                	addi	a5,a5,12
    80005fec:	97ca                	add	a5,a5,s2
    80005fee:	4398                	lw	a4,0(a5)
    80005ff0:	2701                	sext.w	a4,a4
     *R(n, VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ff2:	554d47b7          	lui	a5,0x554d4
    80005ff6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005ffa:	0ef71863          	bne	a4,a5,800060ea <virtio_disk_init+0x1b8>
  *R(n, VIRTIO_MMIO_STATUS) = status;
    80005ffe:	100007b7          	lui	a5,0x10000
    80006002:	07078693          	addi	a3,a5,112 # 10000070 <_entry-0x6fffff90>
    80006006:	96ca                	add	a3,a3,s2
    80006008:	4705                	li	a4,1
    8000600a:	c298                	sw	a4,0(a3)
  *R(n, VIRTIO_MMIO_STATUS) = status;
    8000600c:	470d                	li	a4,3
    8000600e:	c298                	sw	a4,0(a3)
  uint64 features = *R(n, VIRTIO_MMIO_DEVICE_FEATURES);
    80006010:	01078713          	addi	a4,a5,16
    80006014:	974a                	add	a4,a4,s2
    80006016:	430c                	lw	a1,0(a4)
  *R(n, VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006018:	02078613          	addi	a2,a5,32
    8000601c:	964a                	add	a2,a2,s2
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    8000601e:	c7ffe737          	lui	a4,0xc7ffe
    80006022:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd2703>
    80006026:	8f6d                	and	a4,a4,a1
  *R(n, VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006028:	2701                	sext.w	a4,a4
    8000602a:	c218                	sw	a4,0(a2)
  *R(n, VIRTIO_MMIO_STATUS) = status;
    8000602c:	472d                	li	a4,11
    8000602e:	c298                	sw	a4,0(a3)
  *R(n, VIRTIO_MMIO_STATUS) = status;
    80006030:	473d                	li	a4,15
    80006032:	c298                	sw	a4,0(a3)
  *R(n, VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006034:	02878713          	addi	a4,a5,40
    80006038:	974a                	add	a4,a4,s2
    8000603a:	6685                	lui	a3,0x1
    8000603c:	c314                	sw	a3,0(a4)
  *R(n, VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000603e:	03078713          	addi	a4,a5,48
    80006042:	974a                	add	a4,a4,s2
    80006044:	00072023          	sw	zero,0(a4)
  uint32 max = *R(n, VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006048:	03478793          	addi	a5,a5,52
    8000604c:	97ca                	add	a5,a5,s2
    8000604e:	439c                	lw	a5,0(a5)
    80006050:	2781                	sext.w	a5,a5
  if(max == 0)
    80006052:	c7c5                	beqz	a5,800060fa <virtio_disk_init+0x1c8>
  if(max < NUM)
    80006054:	471d                	li	a4,7
    80006056:	0af77a63          	bgeu	a4,a5,8000610a <virtio_disk_init+0x1d8>
  *R(n, VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000605a:	10000ab7          	lui	s5,0x10000
    8000605e:	038a8793          	addi	a5,s5,56 # 10000038 <_entry-0x6fffffc8>
    80006062:	97ca                	add	a5,a5,s2
    80006064:	4721                	li	a4,8
    80006066:	c398                	sw	a4,0(a5)
  memset(disk[n].pages, 0, sizeof(disk[n].pages));
    80006068:	00020a17          	auipc	s4,0x20
    8000606c:	f98a0a13          	addi	s4,s4,-104 # 80026000 <disk>
    80006070:	99d2                	add	s3,s3,s4
    80006072:	6609                	lui	a2,0x2
    80006074:	4581                	li	a1,0
    80006076:	854e                	mv	a0,s3
    80006078:	ffffb097          	auipc	ra,0xffffb
    8000607c:	dda080e7          	jalr	-550(ra) # 80000e52 <memset>
  *R(n, VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk[n].pages) >> PGSHIFT;
    80006080:	040a8a93          	addi	s5,s5,64
    80006084:	9956                	add	s2,s2,s5
    80006086:	00c9d793          	srli	a5,s3,0xc
    8000608a:	2781                	sext.w	a5,a5
    8000608c:	00f92023          	sw	a5,0(s2)
  disk[n].desc = (struct VRingDesc *) disk[n].pages;
    80006090:	00149693          	slli	a3,s1,0x1
    80006094:	009687b3          	add	a5,a3,s1
    80006098:	07b2                	slli	a5,a5,0xc
    8000609a:	97d2                	add	a5,a5,s4
    8000609c:	6609                	lui	a2,0x2
    8000609e:	97b2                	add	a5,a5,a2
    800060a0:	0137b023          	sd	s3,0(a5)
  disk[n].avail = (uint16*)(((char*)disk[n].desc) + NUM*sizeof(struct VRingDesc));
    800060a4:	08098713          	addi	a4,s3,128
    800060a8:	e798                	sd	a4,8(a5)
  disk[n].used = (struct UsedArea *) (disk[n].pages + PGSIZE);
    800060aa:	6705                	lui	a4,0x1
    800060ac:	99ba                	add	s3,s3,a4
    800060ae:	0137b823          	sd	s3,16(a5)
    disk[n].free[i] = 1;
    800060b2:	4705                	li	a4,1
    800060b4:	00e78c23          	sb	a4,24(a5)
    800060b8:	00e78ca3          	sb	a4,25(a5)
    800060bc:	00e78d23          	sb	a4,26(a5)
    800060c0:	00e78da3          	sb	a4,27(a5)
    800060c4:	00e78e23          	sb	a4,28(a5)
    800060c8:	00e78ea3          	sb	a4,29(a5)
    800060cc:	00e78f23          	sb	a4,30(a5)
    800060d0:	00e78fa3          	sb	a4,31(a5)
  disk[n].init = 1;
    800060d4:	0ae7a423          	sw	a4,168(a5)
}
    800060d8:	70e2                	ld	ra,56(sp)
    800060da:	7442                	ld	s0,48(sp)
    800060dc:	74a2                	ld	s1,40(sp)
    800060de:	7902                	ld	s2,32(sp)
    800060e0:	69e2                	ld	s3,24(sp)
    800060e2:	6a42                	ld	s4,16(sp)
    800060e4:	6aa2                	ld	s5,8(sp)
    800060e6:	6121                	addi	sp,sp,64
    800060e8:	8082                	ret
    panic("could not find virtio disk");
    800060ea:	00003517          	auipc	a0,0x3
    800060ee:	81650513          	addi	a0,a0,-2026 # 80008900 <userret+0x870>
    800060f2:	ffffa097          	auipc	ra,0xffffa
    800060f6:	456080e7          	jalr	1110(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    800060fa:	00003517          	auipc	a0,0x3
    800060fe:	82650513          	addi	a0,a0,-2010 # 80008920 <userret+0x890>
    80006102:	ffffa097          	auipc	ra,0xffffa
    80006106:	446080e7          	jalr	1094(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    8000610a:	00003517          	auipc	a0,0x3
    8000610e:	83650513          	addi	a0,a0,-1994 # 80008940 <userret+0x8b0>
    80006112:	ffffa097          	auipc	ra,0xffffa
    80006116:	436080e7          	jalr	1078(ra) # 80000548 <panic>

000000008000611a <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(int n, struct buf *b, int write)
{
    8000611a:	7135                	addi	sp,sp,-160
    8000611c:	ed06                	sd	ra,152(sp)
    8000611e:	e922                	sd	s0,144(sp)
    80006120:	e526                	sd	s1,136(sp)
    80006122:	e14a                	sd	s2,128(sp)
    80006124:	fcce                	sd	s3,120(sp)
    80006126:	f8d2                	sd	s4,112(sp)
    80006128:	f4d6                	sd	s5,104(sp)
    8000612a:	f0da                	sd	s6,96(sp)
    8000612c:	ecde                	sd	s7,88(sp)
    8000612e:	e8e2                	sd	s8,80(sp)
    80006130:	e4e6                	sd	s9,72(sp)
    80006132:	e0ea                	sd	s10,64(sp)
    80006134:	fc6e                	sd	s11,56(sp)
    80006136:	1100                	addi	s0,sp,160
    80006138:	8aaa                	mv	s5,a0
    8000613a:	8c2e                	mv	s8,a1
    8000613c:	8db2                	mv	s11,a2
  uint64 sector = b->blockno * (BSIZE / 512);
    8000613e:	45dc                	lw	a5,12(a1)
    80006140:	0017979b          	slliw	a5,a5,0x1
    80006144:	1782                	slli	a5,a5,0x20
    80006146:	9381                	srli	a5,a5,0x20
    80006148:	f6f43423          	sd	a5,-152(s0)

  acquire(&disk[n].vdisk_lock);
    8000614c:	00151493          	slli	s1,a0,0x1
    80006150:	94aa                	add	s1,s1,a0
    80006152:	04b2                	slli	s1,s1,0xc
    80006154:	6909                	lui	s2,0x2
    80006156:	0b090c93          	addi	s9,s2,176 # 20b0 <_entry-0x7fffdf50>
    8000615a:	9ca6                	add	s9,s9,s1
    8000615c:	00020997          	auipc	s3,0x20
    80006160:	ea498993          	addi	s3,s3,-348 # 80026000 <disk>
    80006164:	9cce                	add	s9,s9,s3
    80006166:	8566                	mv	a0,s9
    80006168:	ffffb097          	auipc	ra,0xffffb
    8000616c:	a7c080e7          	jalr	-1412(ra) # 80000be4 <acquire>
  int idx[3];
  while(1){
    if(alloc3_desc(n, idx) == 0) {
      break;
    }
    sleep(&disk[n].free[0], &disk[n].vdisk_lock);
    80006170:	0961                	addi	s2,s2,24
    80006172:	94ca                	add	s1,s1,s2
    80006174:	99a6                	add	s3,s3,s1
  for(int i = 0; i < 3; i++){
    80006176:	4a01                	li	s4,0
  for(int i = 0; i < NUM; i++){
    80006178:	44a1                	li	s1,8
      disk[n].free[i] = 0;
    8000617a:	001a9793          	slli	a5,s5,0x1
    8000617e:	97d6                	add	a5,a5,s5
    80006180:	07b2                	slli	a5,a5,0xc
    80006182:	00020b97          	auipc	s7,0x20
    80006186:	e7eb8b93          	addi	s7,s7,-386 # 80026000 <disk>
    8000618a:	9bbe                	add	s7,s7,a5
    8000618c:	a8a9                	j	800061e6 <virtio_disk_rw+0xcc>
    8000618e:	00fb8733          	add	a4,s7,a5
    80006192:	9742                	add	a4,a4,a6
    80006194:	00070c23          	sb	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    idx[i] = alloc_desc(n);
    80006198:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    8000619a:	0207c263          	bltz	a5,800061be <virtio_disk_rw+0xa4>
  for(int i = 0; i < 3; i++){
    8000619e:	2905                	addiw	s2,s2,1
    800061a0:	0611                	addi	a2,a2,4
    800061a2:	1ca90463          	beq	s2,a0,8000636a <virtio_disk_rw+0x250>
    idx[i] = alloc_desc(n);
    800061a6:	85b2                	mv	a1,a2
    800061a8:	874e                	mv	a4,s3
  for(int i = 0; i < NUM; i++){
    800061aa:	87d2                	mv	a5,s4
    if(disk[n].free[i]){
    800061ac:	00074683          	lbu	a3,0(a4)
    800061b0:	fef9                	bnez	a3,8000618e <virtio_disk_rw+0x74>
  for(int i = 0; i < NUM; i++){
    800061b2:	2785                	addiw	a5,a5,1
    800061b4:	0705                	addi	a4,a4,1
    800061b6:	fe979be3          	bne	a5,s1,800061ac <virtio_disk_rw+0x92>
    idx[i] = alloc_desc(n);
    800061ba:	57fd                	li	a5,-1
    800061bc:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800061be:	01205e63          	blez	s2,800061da <virtio_disk_rw+0xc0>
    800061c2:	8d52                	mv	s10,s4
        free_desc(n, idx[j]);
    800061c4:	000b2583          	lw	a1,0(s6)
    800061c8:	8556                	mv	a0,s5
    800061ca:	00000097          	auipc	ra,0x0
    800061ce:	ccc080e7          	jalr	-820(ra) # 80005e96 <free_desc>
      for(int j = 0; j < i; j++)
    800061d2:	2d05                	addiw	s10,s10,1
    800061d4:	0b11                	addi	s6,s6,4
    800061d6:	ffa917e3          	bne	s2,s10,800061c4 <virtio_disk_rw+0xaa>
    sleep(&disk[n].free[0], &disk[n].vdisk_lock);
    800061da:	85e6                	mv	a1,s9
    800061dc:	854e                	mv	a0,s3
    800061de:	ffffc097          	auipc	ra,0xffffc
    800061e2:	134080e7          	jalr	308(ra) # 80002312 <sleep>
  for(int i = 0; i < 3; i++){
    800061e6:	f8040b13          	addi	s6,s0,-128
{
    800061ea:	865a                	mv	a2,s6
  for(int i = 0; i < 3; i++){
    800061ec:	8952                	mv	s2,s4
      disk[n].free[i] = 0;
    800061ee:	6809                	lui	a6,0x2
  for(int i = 0; i < 3; i++){
    800061f0:	450d                	li	a0,3
    800061f2:	bf55                	j	800061a6 <virtio_disk_rw+0x8c>
  disk[n].desc[idx[0]].next = idx[1];

  disk[n].desc[idx[1]].addr = (uint64) b->data;
  disk[n].desc[idx[1]].len = BSIZE;
  if(write)
    disk[n].desc[idx[1]].flags = 0; // device reads b->data
    800061f4:	001a9793          	slli	a5,s5,0x1
    800061f8:	97d6                	add	a5,a5,s5
    800061fa:	07b2                	slli	a5,a5,0xc
    800061fc:	00020717          	auipc	a4,0x20
    80006200:	e0470713          	addi	a4,a4,-508 # 80026000 <disk>
    80006204:	973e                	add	a4,a4,a5
    80006206:	6789                	lui	a5,0x2
    80006208:	97ba                	add	a5,a5,a4
    8000620a:	639c                	ld	a5,0(a5)
    8000620c:	97b6                	add	a5,a5,a3
    8000620e:	00079623          	sh	zero,12(a5) # 200c <_entry-0x7fffdff4>
  else
    disk[n].desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk[n].desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006212:	00020517          	auipc	a0,0x20
    80006216:	dee50513          	addi	a0,a0,-530 # 80026000 <disk>
    8000621a:	001a9793          	slli	a5,s5,0x1
    8000621e:	01578733          	add	a4,a5,s5
    80006222:	0732                	slli	a4,a4,0xc
    80006224:	972a                	add	a4,a4,a0
    80006226:	6609                	lui	a2,0x2
    80006228:	9732                	add	a4,a4,a2
    8000622a:	6310                	ld	a2,0(a4)
    8000622c:	9636                	add	a2,a2,a3
    8000622e:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006232:	0015e593          	ori	a1,a1,1
    80006236:	00b61623          	sh	a1,12(a2)
  disk[n].desc[idx[1]].next = idx[2];
    8000623a:	f8842603          	lw	a2,-120(s0)
    8000623e:	630c                	ld	a1,0(a4)
    80006240:	96ae                	add	a3,a3,a1
    80006242:	00c69723          	sh	a2,14(a3) # 100e <_entry-0x7fffeff2>

  disk[n].info[idx[0]].status = 0;
    80006246:	97d6                	add	a5,a5,s5
    80006248:	07a2                	slli	a5,a5,0x8
    8000624a:	97a6                	add	a5,a5,s1
    8000624c:	20078793          	addi	a5,a5,512
    80006250:	0792                	slli	a5,a5,0x4
    80006252:	97aa                	add	a5,a5,a0
    80006254:	02078823          	sb	zero,48(a5)
  disk[n].desc[idx[2]].addr = (uint64) &disk[n].info[idx[0]].status;
    80006258:	00461693          	slli	a3,a2,0x4
    8000625c:	00073803          	ld	a6,0(a4)
    80006260:	9836                	add	a6,a6,a3
    80006262:	20348613          	addi	a2,s1,515
    80006266:	001a9593          	slli	a1,s5,0x1
    8000626a:	95d6                	add	a1,a1,s5
    8000626c:	05a2                	slli	a1,a1,0x8
    8000626e:	962e                	add	a2,a2,a1
    80006270:	0612                	slli	a2,a2,0x4
    80006272:	962a                	add	a2,a2,a0
    80006274:	00c83023          	sd	a2,0(a6) # 2000 <_entry-0x7fffe000>
  disk[n].desc[idx[2]].len = 1;
    80006278:	630c                	ld	a1,0(a4)
    8000627a:	95b6                	add	a1,a1,a3
    8000627c:	4605                	li	a2,1
    8000627e:	c590                	sw	a2,8(a1)
  disk[n].desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006280:	630c                	ld	a1,0(a4)
    80006282:	95b6                	add	a1,a1,a3
    80006284:	4509                	li	a0,2
    80006286:	00a59623          	sh	a0,12(a1)
  disk[n].desc[idx[2]].next = 0;
    8000628a:	630c                	ld	a1,0(a4)
    8000628c:	96ae                	add	a3,a3,a1
    8000628e:	00069723          	sh	zero,14(a3)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006292:	00cc2223          	sw	a2,4(s8) # fffffffffffff004 <end+0xffffffff7ffd2fa8>
  disk[n].info[idx[0]].b = b;
    80006296:	0387b423          	sd	s8,40(a5)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk[n].avail[2 + (disk[n].avail[1] % NUM)] = idx[0];
    8000629a:	6714                	ld	a3,8(a4)
    8000629c:	0026d783          	lhu	a5,2(a3)
    800062a0:	8b9d                	andi	a5,a5,7
    800062a2:	0789                	addi	a5,a5,2
    800062a4:	0786                	slli	a5,a5,0x1
    800062a6:	97b6                	add	a5,a5,a3
    800062a8:	00979023          	sh	s1,0(a5)
  __sync_synchronize();
    800062ac:	0ff0000f          	fence
  disk[n].avail[1] = disk[n].avail[1] + 1;
    800062b0:	6718                	ld	a4,8(a4)
    800062b2:	00275783          	lhu	a5,2(a4)
    800062b6:	2785                	addiw	a5,a5,1
    800062b8:	00f71123          	sh	a5,2(a4)

  *R(n, VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800062bc:	001a879b          	addiw	a5,s5,1
    800062c0:	00c7979b          	slliw	a5,a5,0xc
    800062c4:	10000737          	lui	a4,0x10000
    800062c8:	05070713          	addi	a4,a4,80 # 10000050 <_entry-0x6fffffb0>
    800062cc:	97ba                	add	a5,a5,a4
    800062ce:	0007a023          	sw	zero,0(a5)

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800062d2:	004c2783          	lw	a5,4(s8)
    800062d6:	00c79d63          	bne	a5,a2,800062f0 <virtio_disk_rw+0x1d6>
    800062da:	4485                	li	s1,1
    sleep(b, &disk[n].vdisk_lock);
    800062dc:	85e6                	mv	a1,s9
    800062de:	8562                	mv	a0,s8
    800062e0:	ffffc097          	auipc	ra,0xffffc
    800062e4:	032080e7          	jalr	50(ra) # 80002312 <sleep>
  while(b->disk == 1) {
    800062e8:	004c2783          	lw	a5,4(s8)
    800062ec:	fe9788e3          	beq	a5,s1,800062dc <virtio_disk_rw+0x1c2>
  }

  disk[n].info[idx[0]].b = 0;
    800062f0:	f8042483          	lw	s1,-128(s0)
    800062f4:	001a9793          	slli	a5,s5,0x1
    800062f8:	97d6                	add	a5,a5,s5
    800062fa:	07a2                	slli	a5,a5,0x8
    800062fc:	97a6                	add	a5,a5,s1
    800062fe:	20078793          	addi	a5,a5,512
    80006302:	0792                	slli	a5,a5,0x4
    80006304:	00020717          	auipc	a4,0x20
    80006308:	cfc70713          	addi	a4,a4,-772 # 80026000 <disk>
    8000630c:	97ba                	add	a5,a5,a4
    8000630e:	0207b423          	sd	zero,40(a5)
    if(disk[n].desc[i].flags & VRING_DESC_F_NEXT)
    80006312:	001a9793          	slli	a5,s5,0x1
    80006316:	97d6                	add	a5,a5,s5
    80006318:	07b2                	slli	a5,a5,0xc
    8000631a:	97ba                	add	a5,a5,a4
    8000631c:	6909                	lui	s2,0x2
    8000631e:	993e                	add	s2,s2,a5
    80006320:	a019                	j	80006326 <virtio_disk_rw+0x20c>
      i = disk[n].desc[i].next;
    80006322:	00e4d483          	lhu	s1,14(s1)
    free_desc(n, i);
    80006326:	85a6                	mv	a1,s1
    80006328:	8556                	mv	a0,s5
    8000632a:	00000097          	auipc	ra,0x0
    8000632e:	b6c080e7          	jalr	-1172(ra) # 80005e96 <free_desc>
    if(disk[n].desc[i].flags & VRING_DESC_F_NEXT)
    80006332:	0492                	slli	s1,s1,0x4
    80006334:	00093783          	ld	a5,0(s2) # 2000 <_entry-0x7fffe000>
    80006338:	94be                	add	s1,s1,a5
    8000633a:	00c4d783          	lhu	a5,12(s1)
    8000633e:	8b85                	andi	a5,a5,1
    80006340:	f3ed                	bnez	a5,80006322 <virtio_disk_rw+0x208>
  free_chain(n, idx[0]);

  release(&disk[n].vdisk_lock);
    80006342:	8566                	mv	a0,s9
    80006344:	ffffb097          	auipc	ra,0xffffb
    80006348:	910080e7          	jalr	-1776(ra) # 80000c54 <release>
}
    8000634c:	60ea                	ld	ra,152(sp)
    8000634e:	644a                	ld	s0,144(sp)
    80006350:	64aa                	ld	s1,136(sp)
    80006352:	690a                	ld	s2,128(sp)
    80006354:	79e6                	ld	s3,120(sp)
    80006356:	7a46                	ld	s4,112(sp)
    80006358:	7aa6                	ld	s5,104(sp)
    8000635a:	7b06                	ld	s6,96(sp)
    8000635c:	6be6                	ld	s7,88(sp)
    8000635e:	6c46                	ld	s8,80(sp)
    80006360:	6ca6                	ld	s9,72(sp)
    80006362:	6d06                	ld	s10,64(sp)
    80006364:	7de2                	ld	s11,56(sp)
    80006366:	610d                	addi	sp,sp,160
    80006368:	8082                	ret
  if(write)
    8000636a:	01b037b3          	snez	a5,s11
    8000636e:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    80006372:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    80006376:	f6843783          	ld	a5,-152(s0)
    8000637a:	f6f43c23          	sd	a5,-136(s0)
  disk[n].desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    8000637e:	f8042483          	lw	s1,-128(s0)
    80006382:	00449993          	slli	s3,s1,0x4
    80006386:	001a9793          	slli	a5,s5,0x1
    8000638a:	97d6                	add	a5,a5,s5
    8000638c:	07b2                	slli	a5,a5,0xc
    8000638e:	00020917          	auipc	s2,0x20
    80006392:	c7290913          	addi	s2,s2,-910 # 80026000 <disk>
    80006396:	97ca                	add	a5,a5,s2
    80006398:	6909                	lui	s2,0x2
    8000639a:	993e                	add	s2,s2,a5
    8000639c:	00093a03          	ld	s4,0(s2) # 2000 <_entry-0x7fffe000>
    800063a0:	9a4e                	add	s4,s4,s3
    800063a2:	f7040513          	addi	a0,s0,-144
    800063a6:	ffffb097          	auipc	ra,0xffffb
    800063aa:	ee8080e7          	jalr	-280(ra) # 8000128e <kvmpa>
    800063ae:	00aa3023          	sd	a0,0(s4)
  disk[n].desc[idx[0]].len = sizeof(buf0);
    800063b2:	00093783          	ld	a5,0(s2)
    800063b6:	97ce                	add	a5,a5,s3
    800063b8:	4741                	li	a4,16
    800063ba:	c798                	sw	a4,8(a5)
  disk[n].desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800063bc:	00093783          	ld	a5,0(s2)
    800063c0:	97ce                	add	a5,a5,s3
    800063c2:	4705                	li	a4,1
    800063c4:	00e79623          	sh	a4,12(a5)
  disk[n].desc[idx[0]].next = idx[1];
    800063c8:	f8442683          	lw	a3,-124(s0)
    800063cc:	00093783          	ld	a5,0(s2)
    800063d0:	99be                	add	s3,s3,a5
    800063d2:	00d99723          	sh	a3,14(s3)
  disk[n].desc[idx[1]].addr = (uint64) b->data;
    800063d6:	0692                	slli	a3,a3,0x4
    800063d8:	00093783          	ld	a5,0(s2)
    800063dc:	97b6                	add	a5,a5,a3
    800063de:	060c0713          	addi	a4,s8,96
    800063e2:	e398                	sd	a4,0(a5)
  disk[n].desc[idx[1]].len = BSIZE;
    800063e4:	00093783          	ld	a5,0(s2)
    800063e8:	97b6                	add	a5,a5,a3
    800063ea:	40000713          	li	a4,1024
    800063ee:	c798                	sw	a4,8(a5)
  if(write)
    800063f0:	e00d92e3          	bnez	s11,800061f4 <virtio_disk_rw+0xda>
    disk[n].desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800063f4:	001a9793          	slli	a5,s5,0x1
    800063f8:	97d6                	add	a5,a5,s5
    800063fa:	07b2                	slli	a5,a5,0xc
    800063fc:	00020717          	auipc	a4,0x20
    80006400:	c0470713          	addi	a4,a4,-1020 # 80026000 <disk>
    80006404:	973e                	add	a4,a4,a5
    80006406:	6789                	lui	a5,0x2
    80006408:	97ba                	add	a5,a5,a4
    8000640a:	639c                	ld	a5,0(a5)
    8000640c:	97b6                	add	a5,a5,a3
    8000640e:	4709                	li	a4,2
    80006410:	00e79623          	sh	a4,12(a5) # 200c <_entry-0x7fffdff4>
    80006414:	bbfd                	j	80006212 <virtio_disk_rw+0xf8>

0000000080006416 <virtio_disk_intr>:

void
virtio_disk_intr(int n)
{
    80006416:	7139                	addi	sp,sp,-64
    80006418:	fc06                	sd	ra,56(sp)
    8000641a:	f822                	sd	s0,48(sp)
    8000641c:	f426                	sd	s1,40(sp)
    8000641e:	f04a                	sd	s2,32(sp)
    80006420:	ec4e                	sd	s3,24(sp)
    80006422:	e852                	sd	s4,16(sp)
    80006424:	e456                	sd	s5,8(sp)
    80006426:	0080                	addi	s0,sp,64
    80006428:	84aa                	mv	s1,a0
  acquire(&disk[n].vdisk_lock);
    8000642a:	00151913          	slli	s2,a0,0x1
    8000642e:	00a90a33          	add	s4,s2,a0
    80006432:	0a32                	slli	s4,s4,0xc
    80006434:	6989                	lui	s3,0x2
    80006436:	0b098793          	addi	a5,s3,176 # 20b0 <_entry-0x7fffdf50>
    8000643a:	9a3e                	add	s4,s4,a5
    8000643c:	00020a97          	auipc	s5,0x20
    80006440:	bc4a8a93          	addi	s5,s5,-1084 # 80026000 <disk>
    80006444:	9a56                	add	s4,s4,s5
    80006446:	8552                	mv	a0,s4
    80006448:	ffffa097          	auipc	ra,0xffffa
    8000644c:	79c080e7          	jalr	1948(ra) # 80000be4 <acquire>

  while((disk[n].used_idx % NUM) != (disk[n].used->id % NUM)){
    80006450:	9926                	add	s2,s2,s1
    80006452:	0932                	slli	s2,s2,0xc
    80006454:	9956                	add	s2,s2,s5
    80006456:	99ca                	add	s3,s3,s2
    80006458:	0209d783          	lhu	a5,32(s3)
    8000645c:	0109b703          	ld	a4,16(s3)
    80006460:	00275683          	lhu	a3,2(a4)
    80006464:	8ebd                	xor	a3,a3,a5
    80006466:	8a9d                	andi	a3,a3,7
    80006468:	c2a5                	beqz	a3,800064c8 <virtio_disk_intr+0xb2>
    int id = disk[n].used->elems[disk[n].used_idx].id;

    if(disk[n].info[id].status != 0)
    8000646a:	8956                	mv	s2,s5
    8000646c:	00149693          	slli	a3,s1,0x1
    80006470:	96a6                	add	a3,a3,s1
    80006472:	00869993          	slli	s3,a3,0x8
      panic("virtio_disk_intr status");
    
    disk[n].info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk[n].info[id].b);

    disk[n].used_idx = (disk[n].used_idx + 1) % NUM;
    80006476:	06b2                	slli	a3,a3,0xc
    80006478:	96d6                	add	a3,a3,s5
    8000647a:	6489                	lui	s1,0x2
    8000647c:	94b6                	add	s1,s1,a3
    int id = disk[n].used->elems[disk[n].used_idx].id;
    8000647e:	078e                	slli	a5,a5,0x3
    80006480:	97ba                	add	a5,a5,a4
    80006482:	43dc                	lw	a5,4(a5)
    if(disk[n].info[id].status != 0)
    80006484:	00f98733          	add	a4,s3,a5
    80006488:	20070713          	addi	a4,a4,512
    8000648c:	0712                	slli	a4,a4,0x4
    8000648e:	974a                	add	a4,a4,s2
    80006490:	03074703          	lbu	a4,48(a4)
    80006494:	eb21                	bnez	a4,800064e4 <virtio_disk_intr+0xce>
    disk[n].info[id].b->disk = 0;   // disk is done with buf
    80006496:	97ce                	add	a5,a5,s3
    80006498:	20078793          	addi	a5,a5,512
    8000649c:	0792                	slli	a5,a5,0x4
    8000649e:	97ca                	add	a5,a5,s2
    800064a0:	7798                	ld	a4,40(a5)
    800064a2:	00072223          	sw	zero,4(a4)
    wakeup(disk[n].info[id].b);
    800064a6:	7788                	ld	a0,40(a5)
    800064a8:	ffffc097          	auipc	ra,0xffffc
    800064ac:	fea080e7          	jalr	-22(ra) # 80002492 <wakeup>
    disk[n].used_idx = (disk[n].used_idx + 1) % NUM;
    800064b0:	0204d783          	lhu	a5,32(s1) # 2020 <_entry-0x7fffdfe0>
    800064b4:	2785                	addiw	a5,a5,1
    800064b6:	8b9d                	andi	a5,a5,7
    800064b8:	02f49023          	sh	a5,32(s1)
  while((disk[n].used_idx % NUM) != (disk[n].used->id % NUM)){
    800064bc:	6898                	ld	a4,16(s1)
    800064be:	00275683          	lhu	a3,2(a4)
    800064c2:	8a9d                	andi	a3,a3,7
    800064c4:	faf69de3          	bne	a3,a5,8000647e <virtio_disk_intr+0x68>
  }

  release(&disk[n].vdisk_lock);
    800064c8:	8552                	mv	a0,s4
    800064ca:	ffffa097          	auipc	ra,0xffffa
    800064ce:	78a080e7          	jalr	1930(ra) # 80000c54 <release>
}
    800064d2:	70e2                	ld	ra,56(sp)
    800064d4:	7442                	ld	s0,48(sp)
    800064d6:	74a2                	ld	s1,40(sp)
    800064d8:	7902                	ld	s2,32(sp)
    800064da:	69e2                	ld	s3,24(sp)
    800064dc:	6a42                	ld	s4,16(sp)
    800064de:	6aa2                	ld	s5,8(sp)
    800064e0:	6121                	addi	sp,sp,64
    800064e2:	8082                	ret
      panic("virtio_disk_intr status");
    800064e4:	00002517          	auipc	a0,0x2
    800064e8:	47c50513          	addi	a0,a0,1148 # 80008960 <userret+0x8d0>
    800064ec:	ffffa097          	auipc	ra,0xffffa
    800064f0:	05c080e7          	jalr	92(ra) # 80000548 <panic>

00000000800064f4 <bit_isset>:
static Sz_info *bd_sizes; 
static void *bd_base;   // start address of memory managed by the buddy allocator
static struct spinlock lock;

// Return 1 if bit at position index in array is set to 1
int bit_isset(char *array, int index) {
    800064f4:	1141                	addi	sp,sp,-16
    800064f6:	e422                	sd	s0,8(sp)
    800064f8:	0800                	addi	s0,sp,16
  char b = array[index/8];
  char m = (1 << (index % 8));
    800064fa:	41f5d79b          	sraiw	a5,a1,0x1f
    800064fe:	01d7d79b          	srliw	a5,a5,0x1d
    80006502:	9dbd                	addw	a1,a1,a5
    80006504:	0075f713          	andi	a4,a1,7
    80006508:	9f1d                	subw	a4,a4,a5
    8000650a:	4785                	li	a5,1
    8000650c:	00e797bb          	sllw	a5,a5,a4
    80006510:	0ff7f793          	andi	a5,a5,255
  char b = array[index/8];
    80006514:	4035d59b          	sraiw	a1,a1,0x3
    80006518:	95aa                	add	a1,a1,a0
  return (b & m) == m;
    8000651a:	0005c503          	lbu	a0,0(a1)
    8000651e:	8d7d                	and	a0,a0,a5
    80006520:	8d1d                	sub	a0,a0,a5
}
    80006522:	00153513          	seqz	a0,a0
    80006526:	6422                	ld	s0,8(sp)
    80006528:	0141                	addi	sp,sp,16
    8000652a:	8082                	ret

000000008000652c <bit_set>:

// Set bit at position index in array to 1
void bit_set(char *array, int index) {
    8000652c:	1141                	addi	sp,sp,-16
    8000652e:	e422                	sd	s0,8(sp)
    80006530:	0800                	addi	s0,sp,16
  char b = array[index/8];
    80006532:	41f5d79b          	sraiw	a5,a1,0x1f
    80006536:	01d7d79b          	srliw	a5,a5,0x1d
    8000653a:	9dbd                	addw	a1,a1,a5
    8000653c:	4035d71b          	sraiw	a4,a1,0x3
    80006540:	953a                	add	a0,a0,a4
  char m = (1 << (index % 8));
    80006542:	899d                	andi	a1,a1,7
    80006544:	9d9d                	subw	a1,a1,a5
    80006546:	4785                	li	a5,1
    80006548:	00b795bb          	sllw	a1,a5,a1
  array[index/8] = (b | m);
    8000654c:	00054783          	lbu	a5,0(a0)
    80006550:	8ddd                	or	a1,a1,a5
    80006552:	00b50023          	sb	a1,0(a0)
}
    80006556:	6422                	ld	s0,8(sp)
    80006558:	0141                	addi	sp,sp,16
    8000655a:	8082                	ret

000000008000655c <bit_clear>:

// Clear bit at position index in array
void bit_clear(char *array, int index) {
    8000655c:	1141                	addi	sp,sp,-16
    8000655e:	e422                	sd	s0,8(sp)
    80006560:	0800                	addi	s0,sp,16
  char b = array[index/8];
    80006562:	41f5d79b          	sraiw	a5,a1,0x1f
    80006566:	01d7d79b          	srliw	a5,a5,0x1d
    8000656a:	9dbd                	addw	a1,a1,a5
    8000656c:	4035d71b          	sraiw	a4,a1,0x3
    80006570:	953a                	add	a0,a0,a4
  char m = (1 << (index % 8));
    80006572:	899d                	andi	a1,a1,7
    80006574:	9d9d                	subw	a1,a1,a5
    80006576:	4785                	li	a5,1
    80006578:	00b795bb          	sllw	a1,a5,a1
  array[index/8] = (b & ~m);
    8000657c:	fff5c593          	not	a1,a1
    80006580:	00054783          	lbu	a5,0(a0)
    80006584:	8dfd                	and	a1,a1,a5
    80006586:	00b50023          	sb	a1,0(a0)
}
    8000658a:	6422                	ld	s0,8(sp)
    8000658c:	0141                	addi	sp,sp,16
    8000658e:	8082                	ret

0000000080006590 <bd_print_vector>:

// Print a bit vector as a list of ranges of 1 bits
void
bd_print_vector(char *vector, int len) {
    80006590:	715d                	addi	sp,sp,-80
    80006592:	e486                	sd	ra,72(sp)
    80006594:	e0a2                	sd	s0,64(sp)
    80006596:	fc26                	sd	s1,56(sp)
    80006598:	f84a                	sd	s2,48(sp)
    8000659a:	f44e                	sd	s3,40(sp)
    8000659c:	f052                	sd	s4,32(sp)
    8000659e:	ec56                	sd	s5,24(sp)
    800065a0:	e85a                	sd	s6,16(sp)
    800065a2:	e45e                	sd	s7,8(sp)
    800065a4:	0880                	addi	s0,sp,80
    800065a6:	8a2e                	mv	s4,a1
  int last, lb;
  
  last = 1;
  lb = 0;
  for (int b = 0; b < len; b++) {
    800065a8:	08b05b63          	blez	a1,8000663e <bd_print_vector+0xae>
    800065ac:	89aa                	mv	s3,a0
    800065ae:	4481                	li	s1,0
  lb = 0;
    800065b0:	4a81                	li	s5,0
  last = 1;
    800065b2:	4905                	li	s2,1
    if (last == bit_isset(vector, b))
      continue;
    if(last == 1)
    800065b4:	4b05                	li	s6,1
      printf(" [%d, %d)", lb, b);
    800065b6:	00002b97          	auipc	s7,0x2
    800065ba:	3c2b8b93          	addi	s7,s7,962 # 80008978 <userret+0x8e8>
    800065be:	a821                	j	800065d6 <bd_print_vector+0x46>
    lb = b;
    last = bit_isset(vector, b);
    800065c0:	85a6                	mv	a1,s1
    800065c2:	854e                	mv	a0,s3
    800065c4:	00000097          	auipc	ra,0x0
    800065c8:	f30080e7          	jalr	-208(ra) # 800064f4 <bit_isset>
    800065cc:	892a                	mv	s2,a0
    800065ce:	8aa6                	mv	s5,s1
  for (int b = 0; b < len; b++) {
    800065d0:	2485                	addiw	s1,s1,1
    800065d2:	029a0463          	beq	s4,s1,800065fa <bd_print_vector+0x6a>
    if (last == bit_isset(vector, b))
    800065d6:	85a6                	mv	a1,s1
    800065d8:	854e                	mv	a0,s3
    800065da:	00000097          	auipc	ra,0x0
    800065de:	f1a080e7          	jalr	-230(ra) # 800064f4 <bit_isset>
    800065e2:	ff2507e3          	beq	a0,s2,800065d0 <bd_print_vector+0x40>
    if(last == 1)
    800065e6:	fd691de3          	bne	s2,s6,800065c0 <bd_print_vector+0x30>
      printf(" [%d, %d)", lb, b);
    800065ea:	8626                	mv	a2,s1
    800065ec:	85d6                	mv	a1,s5
    800065ee:	855e                	mv	a0,s7
    800065f0:	ffffa097          	auipc	ra,0xffffa
    800065f4:	fb2080e7          	jalr	-78(ra) # 800005a2 <printf>
    800065f8:	b7e1                	j	800065c0 <bd_print_vector+0x30>
  }
  if(lb == 0 || last == 1) {
    800065fa:	000a8563          	beqz	s5,80006604 <bd_print_vector+0x74>
    800065fe:	4785                	li	a5,1
    80006600:	00f91c63          	bne	s2,a5,80006618 <bd_print_vector+0x88>
    printf(" [%d, %d)", lb, len);
    80006604:	8652                	mv	a2,s4
    80006606:	85d6                	mv	a1,s5
    80006608:	00002517          	auipc	a0,0x2
    8000660c:	37050513          	addi	a0,a0,880 # 80008978 <userret+0x8e8>
    80006610:	ffffa097          	auipc	ra,0xffffa
    80006614:	f92080e7          	jalr	-110(ra) # 800005a2 <printf>
  }
  printf("\n");
    80006618:	00002517          	auipc	a0,0x2
    8000661c:	c7850513          	addi	a0,a0,-904 # 80008290 <userret+0x200>
    80006620:	ffffa097          	auipc	ra,0xffffa
    80006624:	f82080e7          	jalr	-126(ra) # 800005a2 <printf>
}
    80006628:	60a6                	ld	ra,72(sp)
    8000662a:	6406                	ld	s0,64(sp)
    8000662c:	74e2                	ld	s1,56(sp)
    8000662e:	7942                	ld	s2,48(sp)
    80006630:	79a2                	ld	s3,40(sp)
    80006632:	7a02                	ld	s4,32(sp)
    80006634:	6ae2                	ld	s5,24(sp)
    80006636:	6b42                	ld	s6,16(sp)
    80006638:	6ba2                	ld	s7,8(sp)
    8000663a:	6161                	addi	sp,sp,80
    8000663c:	8082                	ret
  lb = 0;
    8000663e:	4a81                	li	s5,0
    80006640:	b7d1                	j	80006604 <bd_print_vector+0x74>

0000000080006642 <bd_print>:

// Print buddy's data structures
void
bd_print() {
  for (int k = 0; k < nsizes; k++) {
    80006642:	00026697          	auipc	a3,0x26
    80006646:	a166a683          	lw	a3,-1514(a3) # 8002c058 <nsizes>
    8000664a:	10d05063          	blez	a3,8000674a <bd_print+0x108>
bd_print() {
    8000664e:	711d                	addi	sp,sp,-96
    80006650:	ec86                	sd	ra,88(sp)
    80006652:	e8a2                	sd	s0,80(sp)
    80006654:	e4a6                	sd	s1,72(sp)
    80006656:	e0ca                	sd	s2,64(sp)
    80006658:	fc4e                	sd	s3,56(sp)
    8000665a:	f852                	sd	s4,48(sp)
    8000665c:	f456                	sd	s5,40(sp)
    8000665e:	f05a                	sd	s6,32(sp)
    80006660:	ec5e                	sd	s7,24(sp)
    80006662:	e862                	sd	s8,16(sp)
    80006664:	e466                	sd	s9,8(sp)
    80006666:	e06a                	sd	s10,0(sp)
    80006668:	1080                	addi	s0,sp,96
  for (int k = 0; k < nsizes; k++) {
    8000666a:	4481                	li	s1,0
    printf("size %d (blksz %d nblk %d): free list: ", k, BLK_SIZE(k), NBLK(k));
    8000666c:	4a85                	li	s5,1
    8000666e:	4c41                	li	s8,16
    80006670:	00002b97          	auipc	s7,0x2
    80006674:	318b8b93          	addi	s7,s7,792 # 80008988 <userret+0x8f8>
    lst_print(&bd_sizes[k].free);
    80006678:	00026a17          	auipc	s4,0x26
    8000667c:	9d8a0a13          	addi	s4,s4,-1576 # 8002c050 <bd_sizes>
    printf("  alloc:");
    80006680:	00002b17          	auipc	s6,0x2
    80006684:	330b0b13          	addi	s6,s6,816 # 800089b0 <userret+0x920>
    bd_print_vector(bd_sizes[k].alloc, NBLK(k));
    80006688:	00026997          	auipc	s3,0x26
    8000668c:	9d098993          	addi	s3,s3,-1584 # 8002c058 <nsizes>
    if(k > 0) {
      printf("  split:");
    80006690:	00002c97          	auipc	s9,0x2
    80006694:	330c8c93          	addi	s9,s9,816 # 800089c0 <userret+0x930>
    80006698:	a801                	j	800066a8 <bd_print+0x66>
  for (int k = 0; k < nsizes; k++) {
    8000669a:	0009a683          	lw	a3,0(s3)
    8000669e:	0485                	addi	s1,s1,1
    800066a0:	0004879b          	sext.w	a5,s1
    800066a4:	08d7d563          	bge	a5,a3,8000672e <bd_print+0xec>
    800066a8:	0004891b          	sext.w	s2,s1
    printf("size %d (blksz %d nblk %d): free list: ", k, BLK_SIZE(k), NBLK(k));
    800066ac:	36fd                	addiw	a3,a3,-1
    800066ae:	9e85                	subw	a3,a3,s1
    800066b0:	00da96bb          	sllw	a3,s5,a3
    800066b4:	009c1633          	sll	a2,s8,s1
    800066b8:	85ca                	mv	a1,s2
    800066ba:	855e                	mv	a0,s7
    800066bc:	ffffa097          	auipc	ra,0xffffa
    800066c0:	ee6080e7          	jalr	-282(ra) # 800005a2 <printf>
    lst_print(&bd_sizes[k].free);
    800066c4:	00549d13          	slli	s10,s1,0x5
    800066c8:	000a3503          	ld	a0,0(s4)
    800066cc:	956a                	add	a0,a0,s10
    800066ce:	00001097          	auipc	ra,0x1
    800066d2:	a56080e7          	jalr	-1450(ra) # 80007124 <lst_print>
    printf("  alloc:");
    800066d6:	855a                	mv	a0,s6
    800066d8:	ffffa097          	auipc	ra,0xffffa
    800066dc:	eca080e7          	jalr	-310(ra) # 800005a2 <printf>
    bd_print_vector(bd_sizes[k].alloc, NBLK(k));
    800066e0:	0009a583          	lw	a1,0(s3)
    800066e4:	35fd                	addiw	a1,a1,-1
    800066e6:	412585bb          	subw	a1,a1,s2
    800066ea:	000a3783          	ld	a5,0(s4)
    800066ee:	97ea                	add	a5,a5,s10
    800066f0:	00ba95bb          	sllw	a1,s5,a1
    800066f4:	6b88                	ld	a0,16(a5)
    800066f6:	00000097          	auipc	ra,0x0
    800066fa:	e9a080e7          	jalr	-358(ra) # 80006590 <bd_print_vector>
    if(k > 0) {
    800066fe:	f9205ee3          	blez	s2,8000669a <bd_print+0x58>
      printf("  split:");
    80006702:	8566                	mv	a0,s9
    80006704:	ffffa097          	auipc	ra,0xffffa
    80006708:	e9e080e7          	jalr	-354(ra) # 800005a2 <printf>
      bd_print_vector(bd_sizes[k].split, NBLK(k));
    8000670c:	0009a583          	lw	a1,0(s3)
    80006710:	35fd                	addiw	a1,a1,-1
    80006712:	412585bb          	subw	a1,a1,s2
    80006716:	000a3783          	ld	a5,0(s4)
    8000671a:	9d3e                	add	s10,s10,a5
    8000671c:	00ba95bb          	sllw	a1,s5,a1
    80006720:	018d3503          	ld	a0,24(s10)
    80006724:	00000097          	auipc	ra,0x0
    80006728:	e6c080e7          	jalr	-404(ra) # 80006590 <bd_print_vector>
    8000672c:	b7bd                	j	8000669a <bd_print+0x58>
    }
  }
}
    8000672e:	60e6                	ld	ra,88(sp)
    80006730:	6446                	ld	s0,80(sp)
    80006732:	64a6                	ld	s1,72(sp)
    80006734:	6906                	ld	s2,64(sp)
    80006736:	79e2                	ld	s3,56(sp)
    80006738:	7a42                	ld	s4,48(sp)
    8000673a:	7aa2                	ld	s5,40(sp)
    8000673c:	7b02                	ld	s6,32(sp)
    8000673e:	6be2                	ld	s7,24(sp)
    80006740:	6c42                	ld	s8,16(sp)
    80006742:	6ca2                	ld	s9,8(sp)
    80006744:	6d02                	ld	s10,0(sp)
    80006746:	6125                	addi	sp,sp,96
    80006748:	8082                	ret
    8000674a:	8082                	ret

000000008000674c <firstk>:

// What is the first k such that 2^k >= n?
int
firstk(uint64 n) {
    8000674c:	1141                	addi	sp,sp,-16
    8000674e:	e422                	sd	s0,8(sp)
    80006750:	0800                	addi	s0,sp,16
  int k = 0;
  uint64 size = LEAF_SIZE;

  while (size < n) {
    80006752:	47c1                	li	a5,16
    80006754:	00a7fb63          	bgeu	a5,a0,8000676a <firstk+0x1e>
    80006758:	872a                	mv	a4,a0
  int k = 0;
    8000675a:	4501                	li	a0,0
    k++;
    8000675c:	2505                	addiw	a0,a0,1
    size *= 2;
    8000675e:	0786                	slli	a5,a5,0x1
  while (size < n) {
    80006760:	fee7eee3          	bltu	a5,a4,8000675c <firstk+0x10>
  }
  return k;
}
    80006764:	6422                	ld	s0,8(sp)
    80006766:	0141                	addi	sp,sp,16
    80006768:	8082                	ret
  int k = 0;
    8000676a:	4501                	li	a0,0
    8000676c:	bfe5                	j	80006764 <firstk+0x18>

000000008000676e <blk_index>:

// Compute the block index for address p at size k
int
blk_index(int k, char *p) {
    8000676e:	1141                	addi	sp,sp,-16
    80006770:	e422                	sd	s0,8(sp)
    80006772:	0800                	addi	s0,sp,16
  int n = p - (char *) bd_base;
  return n / BLK_SIZE(k);
    80006774:	00026797          	auipc	a5,0x26
    80006778:	8d47b783          	ld	a5,-1836(a5) # 8002c048 <bd_base>
    8000677c:	9d9d                	subw	a1,a1,a5
    8000677e:	47c1                	li	a5,16
    80006780:	00a797b3          	sll	a5,a5,a0
    80006784:	02f5c5b3          	div	a1,a1,a5
}
    80006788:	0005851b          	sext.w	a0,a1
    8000678c:	6422                	ld	s0,8(sp)
    8000678e:	0141                	addi	sp,sp,16
    80006790:	8082                	ret

0000000080006792 <addr>:

// Convert a block index at size k back into an address
void *addr(int k, int bi) {
    80006792:	1141                	addi	sp,sp,-16
    80006794:	e422                	sd	s0,8(sp)
    80006796:	0800                	addi	s0,sp,16
  int n = bi * BLK_SIZE(k);
    80006798:	47c1                	li	a5,16
    8000679a:	00a797b3          	sll	a5,a5,a0
  return (char *) bd_base + n;
    8000679e:	02b787bb          	mulw	a5,a5,a1
}
    800067a2:	00026517          	auipc	a0,0x26
    800067a6:	8a653503          	ld	a0,-1882(a0) # 8002c048 <bd_base>
    800067aa:	953e                	add	a0,a0,a5
    800067ac:	6422                	ld	s0,8(sp)
    800067ae:	0141                	addi	sp,sp,16
    800067b0:	8082                	ret

00000000800067b2 <bd_malloc>:

// allocate nbytes, but malloc won't return anything smaller than LEAF_SIZE
void *
bd_malloc(uint64 nbytes)
{
    800067b2:	7159                	addi	sp,sp,-112
    800067b4:	f486                	sd	ra,104(sp)
    800067b6:	f0a2                	sd	s0,96(sp)
    800067b8:	eca6                	sd	s1,88(sp)
    800067ba:	e8ca                	sd	s2,80(sp)
    800067bc:	e4ce                	sd	s3,72(sp)
    800067be:	e0d2                	sd	s4,64(sp)
    800067c0:	fc56                	sd	s5,56(sp)
    800067c2:	f85a                	sd	s6,48(sp)
    800067c4:	f45e                	sd	s7,40(sp)
    800067c6:	f062                	sd	s8,32(sp)
    800067c8:	ec66                	sd	s9,24(sp)
    800067ca:	e86a                	sd	s10,16(sp)
    800067cc:	e46e                	sd	s11,8(sp)
    800067ce:	1880                	addi	s0,sp,112
    800067d0:	84aa                	mv	s1,a0
  int fk, k;

  acquire(&lock);
    800067d2:	00026517          	auipc	a0,0x26
    800067d6:	82e50513          	addi	a0,a0,-2002 # 8002c000 <lock>
    800067da:	ffffa097          	auipc	ra,0xffffa
    800067de:	40a080e7          	jalr	1034(ra) # 80000be4 <acquire>

  // Find a free block >= nbytes, starting with smallest k possible
  fk = firstk(nbytes);
    800067e2:	8526                	mv	a0,s1
    800067e4:	00000097          	auipc	ra,0x0
    800067e8:	f68080e7          	jalr	-152(ra) # 8000674c <firstk>
  for (k = fk; k < nsizes; k++) {
    800067ec:	00026797          	auipc	a5,0x26
    800067f0:	86c7a783          	lw	a5,-1940(a5) # 8002c058 <nsizes>
    800067f4:	02f55d63          	bge	a0,a5,8000682e <bd_malloc+0x7c>
    800067f8:	8c2a                	mv	s8,a0
    800067fa:	00551913          	slli	s2,a0,0x5
    800067fe:	84aa                	mv	s1,a0
    if(!lst_empty(&bd_sizes[k].free))
    80006800:	00026997          	auipc	s3,0x26
    80006804:	85098993          	addi	s3,s3,-1968 # 8002c050 <bd_sizes>
  for (k = fk; k < nsizes; k++) {
    80006808:	00026a17          	auipc	s4,0x26
    8000680c:	850a0a13          	addi	s4,s4,-1968 # 8002c058 <nsizes>
    if(!lst_empty(&bd_sizes[k].free))
    80006810:	0009b503          	ld	a0,0(s3)
    80006814:	954a                	add	a0,a0,s2
    80006816:	00001097          	auipc	ra,0x1
    8000681a:	894080e7          	jalr	-1900(ra) # 800070aa <lst_empty>
    8000681e:	c115                	beqz	a0,80006842 <bd_malloc+0x90>
  for (k = fk; k < nsizes; k++) {
    80006820:	2485                	addiw	s1,s1,1
    80006822:	02090913          	addi	s2,s2,32
    80006826:	000a2783          	lw	a5,0(s4)
    8000682a:	fef4c3e3          	blt	s1,a5,80006810 <bd_malloc+0x5e>
      break;
  }
  if(k >= nsizes) { // No free blocks?
    release(&lock);
    8000682e:	00025517          	auipc	a0,0x25
    80006832:	7d250513          	addi	a0,a0,2002 # 8002c000 <lock>
    80006836:	ffffa097          	auipc	ra,0xffffa
    8000683a:	41e080e7          	jalr	1054(ra) # 80000c54 <release>
    return 0;
    8000683e:	4b01                	li	s6,0
    80006840:	a0e1                	j	80006908 <bd_malloc+0x156>
  if(k >= nsizes) { // No free blocks?
    80006842:	00026797          	auipc	a5,0x26
    80006846:	8167a783          	lw	a5,-2026(a5) # 8002c058 <nsizes>
    8000684a:	fef4d2e3          	bge	s1,a5,8000682e <bd_malloc+0x7c>
  }

  // Found a block; pop it and potentially split it.
  char *p = lst_pop(&bd_sizes[k].free);
    8000684e:	00549993          	slli	s3,s1,0x5
    80006852:	00025917          	auipc	s2,0x25
    80006856:	7fe90913          	addi	s2,s2,2046 # 8002c050 <bd_sizes>
    8000685a:	00093503          	ld	a0,0(s2)
    8000685e:	954e                	add	a0,a0,s3
    80006860:	00001097          	auipc	ra,0x1
    80006864:	876080e7          	jalr	-1930(ra) # 800070d6 <lst_pop>
    80006868:	8b2a                	mv	s6,a0
  return n / BLK_SIZE(k);
    8000686a:	00025597          	auipc	a1,0x25
    8000686e:	7de5b583          	ld	a1,2014(a1) # 8002c048 <bd_base>
    80006872:	40b505bb          	subw	a1,a0,a1
    80006876:	47c1                	li	a5,16
    80006878:	009797b3          	sll	a5,a5,s1
    8000687c:	02f5c5b3          	div	a1,a1,a5
  bit_set(bd_sizes[k].alloc, blk_index(k, p));
    80006880:	00093783          	ld	a5,0(s2)
    80006884:	97ce                	add	a5,a5,s3
    80006886:	2581                	sext.w	a1,a1
    80006888:	6b88                	ld	a0,16(a5)
    8000688a:	00000097          	auipc	ra,0x0
    8000688e:	ca2080e7          	jalr	-862(ra) # 8000652c <bit_set>
  for(; k > fk; k--) {
    80006892:	069c5363          	bge	s8,s1,800068f8 <bd_malloc+0x146>
    // split a block at size k and mark one half allocated at size k-1
    // and put the buddy on the free list at size k-1
    char *q = p + BLK_SIZE(k-1);   // p's buddy
    80006896:	4bc1                	li	s7,16
    bit_set(bd_sizes[k].split, blk_index(k, p));
    80006898:	8dca                	mv	s11,s2
  int n = p - (char *) bd_base;
    8000689a:	00025d17          	auipc	s10,0x25
    8000689e:	7aed0d13          	addi	s10,s10,1966 # 8002c048 <bd_base>
    char *q = p + BLK_SIZE(k-1);   // p's buddy
    800068a2:	85a6                	mv	a1,s1
    800068a4:	34fd                	addiw	s1,s1,-1
    800068a6:	009b9ab3          	sll	s5,s7,s1
    800068aa:	015b0cb3          	add	s9,s6,s5
    bit_set(bd_sizes[k].split, blk_index(k, p));
    800068ae:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
  int n = p - (char *) bd_base;
    800068b2:	000d3903          	ld	s2,0(s10)
  return n / BLK_SIZE(k);
    800068b6:	412b093b          	subw	s2,s6,s2
    800068ba:	00bb95b3          	sll	a1,s7,a1
    800068be:	02b945b3          	div	a1,s2,a1
    bit_set(bd_sizes[k].split, blk_index(k, p));
    800068c2:	013a07b3          	add	a5,s4,s3
    800068c6:	2581                	sext.w	a1,a1
    800068c8:	6f88                	ld	a0,24(a5)
    800068ca:	00000097          	auipc	ra,0x0
    800068ce:	c62080e7          	jalr	-926(ra) # 8000652c <bit_set>
    bit_set(bd_sizes[k-1].alloc, blk_index(k-1, p));
    800068d2:	1981                	addi	s3,s3,-32
    800068d4:	9a4e                	add	s4,s4,s3
  return n / BLK_SIZE(k);
    800068d6:	035945b3          	div	a1,s2,s5
    bit_set(bd_sizes[k-1].alloc, blk_index(k-1, p));
    800068da:	2581                	sext.w	a1,a1
    800068dc:	010a3503          	ld	a0,16(s4)
    800068e0:	00000097          	auipc	ra,0x0
    800068e4:	c4c080e7          	jalr	-948(ra) # 8000652c <bit_set>
    lst_push(&bd_sizes[k-1].free, q);
    800068e8:	85e6                	mv	a1,s9
    800068ea:	8552                	mv	a0,s4
    800068ec:	00001097          	auipc	ra,0x1
    800068f0:	820080e7          	jalr	-2016(ra) # 8000710c <lst_push>
  for(; k > fk; k--) {
    800068f4:	fb8497e3          	bne	s1,s8,800068a2 <bd_malloc+0xf0>
  }
  release(&lock);
    800068f8:	00025517          	auipc	a0,0x25
    800068fc:	70850513          	addi	a0,a0,1800 # 8002c000 <lock>
    80006900:	ffffa097          	auipc	ra,0xffffa
    80006904:	354080e7          	jalr	852(ra) # 80000c54 <release>

  return p;
}
    80006908:	855a                	mv	a0,s6
    8000690a:	70a6                	ld	ra,104(sp)
    8000690c:	7406                	ld	s0,96(sp)
    8000690e:	64e6                	ld	s1,88(sp)
    80006910:	6946                	ld	s2,80(sp)
    80006912:	69a6                	ld	s3,72(sp)
    80006914:	6a06                	ld	s4,64(sp)
    80006916:	7ae2                	ld	s5,56(sp)
    80006918:	7b42                	ld	s6,48(sp)
    8000691a:	7ba2                	ld	s7,40(sp)
    8000691c:	7c02                	ld	s8,32(sp)
    8000691e:	6ce2                	ld	s9,24(sp)
    80006920:	6d42                	ld	s10,16(sp)
    80006922:	6da2                	ld	s11,8(sp)
    80006924:	6165                	addi	sp,sp,112
    80006926:	8082                	ret

0000000080006928 <size>:

// Find the size of the block that p points to.
int
size(char *p) {
    80006928:	7139                	addi	sp,sp,-64
    8000692a:	fc06                	sd	ra,56(sp)
    8000692c:	f822                	sd	s0,48(sp)
    8000692e:	f426                	sd	s1,40(sp)
    80006930:	f04a                	sd	s2,32(sp)
    80006932:	ec4e                	sd	s3,24(sp)
    80006934:	e852                	sd	s4,16(sp)
    80006936:	e456                	sd	s5,8(sp)
    80006938:	e05a                	sd	s6,0(sp)
    8000693a:	0080                	addi	s0,sp,64
  for (int k = 0; k < nsizes; k++) {
    8000693c:	00025a97          	auipc	s5,0x25
    80006940:	71caaa83          	lw	s5,1820(s5) # 8002c058 <nsizes>
  return n / BLK_SIZE(k);
    80006944:	00025a17          	auipc	s4,0x25
    80006948:	704a3a03          	ld	s4,1796(s4) # 8002c048 <bd_base>
    8000694c:	41450a3b          	subw	s4,a0,s4
    80006950:	00025497          	auipc	s1,0x25
    80006954:	7004b483          	ld	s1,1792(s1) # 8002c050 <bd_sizes>
    80006958:	03848493          	addi	s1,s1,56
  for (int k = 0; k < nsizes; k++) {
    8000695c:	4901                	li	s2,0
  return n / BLK_SIZE(k);
    8000695e:	4b41                	li	s6,16
  for (int k = 0; k < nsizes; k++) {
    80006960:	03595363          	bge	s2,s5,80006986 <size+0x5e>
    if(bit_isset(bd_sizes[k+1].split, blk_index(k+1, p))) {
    80006964:	0019099b          	addiw	s3,s2,1
  return n / BLK_SIZE(k);
    80006968:	013b15b3          	sll	a1,s6,s3
    8000696c:	02ba45b3          	div	a1,s4,a1
    if(bit_isset(bd_sizes[k+1].split, blk_index(k+1, p))) {
    80006970:	2581                	sext.w	a1,a1
    80006972:	6088                	ld	a0,0(s1)
    80006974:	00000097          	auipc	ra,0x0
    80006978:	b80080e7          	jalr	-1152(ra) # 800064f4 <bit_isset>
    8000697c:	02048493          	addi	s1,s1,32
    80006980:	e501                	bnez	a0,80006988 <size+0x60>
  for (int k = 0; k < nsizes; k++) {
    80006982:	894e                	mv	s2,s3
    80006984:	bff1                	j	80006960 <size+0x38>
      return k;
    }
  }
  return 0;
    80006986:	4901                	li	s2,0
}
    80006988:	854a                	mv	a0,s2
    8000698a:	70e2                	ld	ra,56(sp)
    8000698c:	7442                	ld	s0,48(sp)
    8000698e:	74a2                	ld	s1,40(sp)
    80006990:	7902                	ld	s2,32(sp)
    80006992:	69e2                	ld	s3,24(sp)
    80006994:	6a42                	ld	s4,16(sp)
    80006996:	6aa2                	ld	s5,8(sp)
    80006998:	6b02                	ld	s6,0(sp)
    8000699a:	6121                	addi	sp,sp,64
    8000699c:	8082                	ret

000000008000699e <bd_free>:

// Free memory pointed to by p, which was earlier allocated using
// bd_malloc.
void
bd_free(void *p) {
    8000699e:	7159                	addi	sp,sp,-112
    800069a0:	f486                	sd	ra,104(sp)
    800069a2:	f0a2                	sd	s0,96(sp)
    800069a4:	eca6                	sd	s1,88(sp)
    800069a6:	e8ca                	sd	s2,80(sp)
    800069a8:	e4ce                	sd	s3,72(sp)
    800069aa:	e0d2                	sd	s4,64(sp)
    800069ac:	fc56                	sd	s5,56(sp)
    800069ae:	f85a                	sd	s6,48(sp)
    800069b0:	f45e                	sd	s7,40(sp)
    800069b2:	f062                	sd	s8,32(sp)
    800069b4:	ec66                	sd	s9,24(sp)
    800069b6:	e86a                	sd	s10,16(sp)
    800069b8:	e46e                	sd	s11,8(sp)
    800069ba:	1880                	addi	s0,sp,112
    800069bc:	8aaa                	mv	s5,a0
  void *q;
  int k;

  acquire(&lock);
    800069be:	00025517          	auipc	a0,0x25
    800069c2:	64250513          	addi	a0,a0,1602 # 8002c000 <lock>
    800069c6:	ffffa097          	auipc	ra,0xffffa
    800069ca:	21e080e7          	jalr	542(ra) # 80000be4 <acquire>
  for (k = size(p); k < MAXSIZE; k++) {
    800069ce:	8556                	mv	a0,s5
    800069d0:	00000097          	auipc	ra,0x0
    800069d4:	f58080e7          	jalr	-168(ra) # 80006928 <size>
    800069d8:	84aa                	mv	s1,a0
    800069da:	00025797          	auipc	a5,0x25
    800069de:	67e7a783          	lw	a5,1662(a5) # 8002c058 <nsizes>
    800069e2:	37fd                	addiw	a5,a5,-1
    800069e4:	0cf55063          	bge	a0,a5,80006aa4 <bd_free+0x106>
    800069e8:	00150a13          	addi	s4,a0,1
    800069ec:	0a16                	slli	s4,s4,0x5
  int n = p - (char *) bd_base;
    800069ee:	00025c17          	auipc	s8,0x25
    800069f2:	65ac0c13          	addi	s8,s8,1626 # 8002c048 <bd_base>
  return n / BLK_SIZE(k);
    800069f6:	4bc1                	li	s7,16
    int bi = blk_index(k, p);
    int buddy = (bi % 2 == 0) ? bi+1 : bi-1;
    bit_clear(bd_sizes[k].alloc, bi);  // free p at size k
    800069f8:	00025b17          	auipc	s6,0x25
    800069fc:	658b0b13          	addi	s6,s6,1624 # 8002c050 <bd_sizes>
  for (k = size(p); k < MAXSIZE; k++) {
    80006a00:	00025c97          	auipc	s9,0x25
    80006a04:	658c8c93          	addi	s9,s9,1624 # 8002c058 <nsizes>
    80006a08:	a82d                	j	80006a42 <bd_free+0xa4>
    int buddy = (bi % 2 == 0) ? bi+1 : bi-1;
    80006a0a:	fff58d9b          	addiw	s11,a1,-1
    80006a0e:	a881                	j	80006a5e <bd_free+0xc0>
    if(buddy % 2 == 0) {
      p = q;
    }
    // at size k+1, mark that the merged buddy pair isn't split
    // anymore
    bit_clear(bd_sizes[k+1].split, blk_index(k+1, p));
    80006a10:	2485                	addiw	s1,s1,1
  int n = p - (char *) bd_base;
    80006a12:	000c3583          	ld	a1,0(s8)
  return n / BLK_SIZE(k);
    80006a16:	40ba85bb          	subw	a1,s5,a1
    80006a1a:	009b97b3          	sll	a5,s7,s1
    80006a1e:	02f5c5b3          	div	a1,a1,a5
    bit_clear(bd_sizes[k+1].split, blk_index(k+1, p));
    80006a22:	000b3783          	ld	a5,0(s6)
    80006a26:	97d2                	add	a5,a5,s4
    80006a28:	2581                	sext.w	a1,a1
    80006a2a:	6f88                	ld	a0,24(a5)
    80006a2c:	00000097          	auipc	ra,0x0
    80006a30:	b30080e7          	jalr	-1232(ra) # 8000655c <bit_clear>
  for (k = size(p); k < MAXSIZE; k++) {
    80006a34:	020a0a13          	addi	s4,s4,32
    80006a38:	000ca783          	lw	a5,0(s9)
    80006a3c:	37fd                	addiw	a5,a5,-1
    80006a3e:	06f4d363          	bge	s1,a5,80006aa4 <bd_free+0x106>
  int n = p - (char *) bd_base;
    80006a42:	000c3903          	ld	s2,0(s8)
  return n / BLK_SIZE(k);
    80006a46:	009b99b3          	sll	s3,s7,s1
    80006a4a:	412a87bb          	subw	a5,s5,s2
    80006a4e:	0337c7b3          	div	a5,a5,s3
    80006a52:	0007859b          	sext.w	a1,a5
    int buddy = (bi % 2 == 0) ? bi+1 : bi-1;
    80006a56:	8b85                	andi	a5,a5,1
    80006a58:	fbcd                	bnez	a5,80006a0a <bd_free+0x6c>
    80006a5a:	00158d9b          	addiw	s11,a1,1
    bit_clear(bd_sizes[k].alloc, bi);  // free p at size k
    80006a5e:	fe0a0d13          	addi	s10,s4,-32
    80006a62:	000b3783          	ld	a5,0(s6)
    80006a66:	9d3e                	add	s10,s10,a5
    80006a68:	010d3503          	ld	a0,16(s10)
    80006a6c:	00000097          	auipc	ra,0x0
    80006a70:	af0080e7          	jalr	-1296(ra) # 8000655c <bit_clear>
    if (bit_isset(bd_sizes[k].alloc, buddy)) {  // is buddy allocated?
    80006a74:	85ee                	mv	a1,s11
    80006a76:	010d3503          	ld	a0,16(s10)
    80006a7a:	00000097          	auipc	ra,0x0
    80006a7e:	a7a080e7          	jalr	-1414(ra) # 800064f4 <bit_isset>
    80006a82:	e10d                	bnez	a0,80006aa4 <bd_free+0x106>
  int n = bi * BLK_SIZE(k);
    80006a84:	000d8d1b          	sext.w	s10,s11
  return (char *) bd_base + n;
    80006a88:	03b989bb          	mulw	s3,s3,s11
    80006a8c:	994e                	add	s2,s2,s3
    lst_remove(q);    // remove buddy from free list
    80006a8e:	854a                	mv	a0,s2
    80006a90:	00000097          	auipc	ra,0x0
    80006a94:	630080e7          	jalr	1584(ra) # 800070c0 <lst_remove>
    if(buddy % 2 == 0) {
    80006a98:	001d7d13          	andi	s10,s10,1
    80006a9c:	f60d1ae3          	bnez	s10,80006a10 <bd_free+0x72>
      p = q;
    80006aa0:	8aca                	mv	s5,s2
    80006aa2:	b7bd                	j	80006a10 <bd_free+0x72>
  }
  lst_push(&bd_sizes[k].free, p);
    80006aa4:	0496                	slli	s1,s1,0x5
    80006aa6:	85d6                	mv	a1,s5
    80006aa8:	00025517          	auipc	a0,0x25
    80006aac:	5a853503          	ld	a0,1448(a0) # 8002c050 <bd_sizes>
    80006ab0:	9526                	add	a0,a0,s1
    80006ab2:	00000097          	auipc	ra,0x0
    80006ab6:	65a080e7          	jalr	1626(ra) # 8000710c <lst_push>
  release(&lock);
    80006aba:	00025517          	auipc	a0,0x25
    80006abe:	54650513          	addi	a0,a0,1350 # 8002c000 <lock>
    80006ac2:	ffffa097          	auipc	ra,0xffffa
    80006ac6:	192080e7          	jalr	402(ra) # 80000c54 <release>
}
    80006aca:	70a6                	ld	ra,104(sp)
    80006acc:	7406                	ld	s0,96(sp)
    80006ace:	64e6                	ld	s1,88(sp)
    80006ad0:	6946                	ld	s2,80(sp)
    80006ad2:	69a6                	ld	s3,72(sp)
    80006ad4:	6a06                	ld	s4,64(sp)
    80006ad6:	7ae2                	ld	s5,56(sp)
    80006ad8:	7b42                	ld	s6,48(sp)
    80006ada:	7ba2                	ld	s7,40(sp)
    80006adc:	7c02                	ld	s8,32(sp)
    80006ade:	6ce2                	ld	s9,24(sp)
    80006ae0:	6d42                	ld	s10,16(sp)
    80006ae2:	6da2                	ld	s11,8(sp)
    80006ae4:	6165                	addi	sp,sp,112
    80006ae6:	8082                	ret

0000000080006ae8 <blk_index_next>:

// Compute the first block at size k that doesn't contain p
int
blk_index_next(int k, char *p) {
    80006ae8:	1141                	addi	sp,sp,-16
    80006aea:	e422                	sd	s0,8(sp)
    80006aec:	0800                	addi	s0,sp,16
  int n = (p - (char *) bd_base) / BLK_SIZE(k);
    80006aee:	00025797          	auipc	a5,0x25
    80006af2:	55a7b783          	ld	a5,1370(a5) # 8002c048 <bd_base>
    80006af6:	8d9d                	sub	a1,a1,a5
    80006af8:	47c1                	li	a5,16
    80006afa:	00a797b3          	sll	a5,a5,a0
    80006afe:	02f5c533          	div	a0,a1,a5
    80006b02:	2501                	sext.w	a0,a0
  if((p - (char*) bd_base) % BLK_SIZE(k) != 0)
    80006b04:	02f5e5b3          	rem	a1,a1,a5
    80006b08:	c191                	beqz	a1,80006b0c <blk_index_next+0x24>
      n++;
    80006b0a:	2505                	addiw	a0,a0,1
  return n ;
}
    80006b0c:	6422                	ld	s0,8(sp)
    80006b0e:	0141                	addi	sp,sp,16
    80006b10:	8082                	ret

0000000080006b12 <log2>:

int
log2(uint64 n) {
    80006b12:	1141                	addi	sp,sp,-16
    80006b14:	e422                	sd	s0,8(sp)
    80006b16:	0800                	addi	s0,sp,16
  int k = 0;
  while (n > 1) {
    80006b18:	4705                	li	a4,1
    80006b1a:	00a77b63          	bgeu	a4,a0,80006b30 <log2+0x1e>
    80006b1e:	87aa                	mv	a5,a0
  int k = 0;
    80006b20:	4501                	li	a0,0
    k++;
    80006b22:	2505                	addiw	a0,a0,1
    n = n >> 1;
    80006b24:	8385                	srli	a5,a5,0x1
  while (n > 1) {
    80006b26:	fef76ee3          	bltu	a4,a5,80006b22 <log2+0x10>
  }
  return k;
}
    80006b2a:	6422                	ld	s0,8(sp)
    80006b2c:	0141                	addi	sp,sp,16
    80006b2e:	8082                	ret
  int k = 0;
    80006b30:	4501                	li	a0,0
    80006b32:	bfe5                	j	80006b2a <log2+0x18>

0000000080006b34 <bd_mark>:

// Mark memory from [start, stop), starting at size 0, as allocated. 
void
bd_mark(void *start, void *stop)
{
    80006b34:	711d                	addi	sp,sp,-96
    80006b36:	ec86                	sd	ra,88(sp)
    80006b38:	e8a2                	sd	s0,80(sp)
    80006b3a:	e4a6                	sd	s1,72(sp)
    80006b3c:	e0ca                	sd	s2,64(sp)
    80006b3e:	fc4e                	sd	s3,56(sp)
    80006b40:	f852                	sd	s4,48(sp)
    80006b42:	f456                	sd	s5,40(sp)
    80006b44:	f05a                	sd	s6,32(sp)
    80006b46:	ec5e                	sd	s7,24(sp)
    80006b48:	e862                	sd	s8,16(sp)
    80006b4a:	e466                	sd	s9,8(sp)
    80006b4c:	e06a                	sd	s10,0(sp)
    80006b4e:	1080                	addi	s0,sp,96
  int bi, bj;

  if (((uint64) start % LEAF_SIZE != 0) || ((uint64) stop % LEAF_SIZE != 0))
    80006b50:	00b56933          	or	s2,a0,a1
    80006b54:	00f97913          	andi	s2,s2,15
    80006b58:	04091263          	bnez	s2,80006b9c <bd_mark+0x68>
    80006b5c:	8b2a                	mv	s6,a0
    80006b5e:	8bae                	mv	s7,a1
    panic("bd_mark");

  for (int k = 0; k < nsizes; k++) {
    80006b60:	00025c17          	auipc	s8,0x25
    80006b64:	4f8c2c03          	lw	s8,1272(s8) # 8002c058 <nsizes>
    80006b68:	4981                	li	s3,0
  int n = p - (char *) bd_base;
    80006b6a:	00025d17          	auipc	s10,0x25
    80006b6e:	4ded0d13          	addi	s10,s10,1246 # 8002c048 <bd_base>
  return n / BLK_SIZE(k);
    80006b72:	4cc1                	li	s9,16
    bi = blk_index(k, start);
    bj = blk_index_next(k, stop);
    for(; bi < bj; bi++) {
      if(k > 0) {
        // if a block is allocated at size k, mark it as split too.
        bit_set(bd_sizes[k].split, bi);
    80006b74:	00025a97          	auipc	s5,0x25
    80006b78:	4dca8a93          	addi	s5,s5,1244 # 8002c050 <bd_sizes>
  for (int k = 0; k < nsizes; k++) {
    80006b7c:	07804563          	bgtz	s8,80006be6 <bd_mark+0xb2>
      }
      bit_set(bd_sizes[k].alloc, bi);
    }
  }
}
    80006b80:	60e6                	ld	ra,88(sp)
    80006b82:	6446                	ld	s0,80(sp)
    80006b84:	64a6                	ld	s1,72(sp)
    80006b86:	6906                	ld	s2,64(sp)
    80006b88:	79e2                	ld	s3,56(sp)
    80006b8a:	7a42                	ld	s4,48(sp)
    80006b8c:	7aa2                	ld	s5,40(sp)
    80006b8e:	7b02                	ld	s6,32(sp)
    80006b90:	6be2                	ld	s7,24(sp)
    80006b92:	6c42                	ld	s8,16(sp)
    80006b94:	6ca2                	ld	s9,8(sp)
    80006b96:	6d02                	ld	s10,0(sp)
    80006b98:	6125                	addi	sp,sp,96
    80006b9a:	8082                	ret
    panic("bd_mark");
    80006b9c:	00002517          	auipc	a0,0x2
    80006ba0:	e3450513          	addi	a0,a0,-460 # 800089d0 <userret+0x940>
    80006ba4:	ffffa097          	auipc	ra,0xffffa
    80006ba8:	9a4080e7          	jalr	-1628(ra) # 80000548 <panic>
      bit_set(bd_sizes[k].alloc, bi);
    80006bac:	000ab783          	ld	a5,0(s5)
    80006bb0:	97ca                	add	a5,a5,s2
    80006bb2:	85a6                	mv	a1,s1
    80006bb4:	6b88                	ld	a0,16(a5)
    80006bb6:	00000097          	auipc	ra,0x0
    80006bba:	976080e7          	jalr	-1674(ra) # 8000652c <bit_set>
    for(; bi < bj; bi++) {
    80006bbe:	2485                	addiw	s1,s1,1
    80006bc0:	009a0e63          	beq	s4,s1,80006bdc <bd_mark+0xa8>
      if(k > 0) {
    80006bc4:	ff3054e3          	blez	s3,80006bac <bd_mark+0x78>
        bit_set(bd_sizes[k].split, bi);
    80006bc8:	000ab783          	ld	a5,0(s5)
    80006bcc:	97ca                	add	a5,a5,s2
    80006bce:	85a6                	mv	a1,s1
    80006bd0:	6f88                	ld	a0,24(a5)
    80006bd2:	00000097          	auipc	ra,0x0
    80006bd6:	95a080e7          	jalr	-1702(ra) # 8000652c <bit_set>
    80006bda:	bfc9                	j	80006bac <bd_mark+0x78>
  for (int k = 0; k < nsizes; k++) {
    80006bdc:	2985                	addiw	s3,s3,1
    80006bde:	02090913          	addi	s2,s2,32
    80006be2:	f9898fe3          	beq	s3,s8,80006b80 <bd_mark+0x4c>
  int n = p - (char *) bd_base;
    80006be6:	000d3483          	ld	s1,0(s10)
  return n / BLK_SIZE(k);
    80006bea:	409b04bb          	subw	s1,s6,s1
    80006bee:	013c97b3          	sll	a5,s9,s3
    80006bf2:	02f4c4b3          	div	s1,s1,a5
    80006bf6:	2481                	sext.w	s1,s1
    bj = blk_index_next(k, stop);
    80006bf8:	85de                	mv	a1,s7
    80006bfa:	854e                	mv	a0,s3
    80006bfc:	00000097          	auipc	ra,0x0
    80006c00:	eec080e7          	jalr	-276(ra) # 80006ae8 <blk_index_next>
    80006c04:	8a2a                	mv	s4,a0
    for(; bi < bj; bi++) {
    80006c06:	faa4cfe3          	blt	s1,a0,80006bc4 <bd_mark+0x90>
    80006c0a:	bfc9                	j	80006bdc <bd_mark+0xa8>

0000000080006c0c <bd_initfree_pair>:

// If a block is marked as allocated and the buddy is free, put the
// buddy on the free list at size k.
int
bd_initfree_pair(int k, int bi) {
    80006c0c:	7139                	addi	sp,sp,-64
    80006c0e:	fc06                	sd	ra,56(sp)
    80006c10:	f822                	sd	s0,48(sp)
    80006c12:	f426                	sd	s1,40(sp)
    80006c14:	f04a                	sd	s2,32(sp)
    80006c16:	ec4e                	sd	s3,24(sp)
    80006c18:	e852                	sd	s4,16(sp)
    80006c1a:	e456                	sd	s5,8(sp)
    80006c1c:	e05a                	sd	s6,0(sp)
    80006c1e:	0080                	addi	s0,sp,64
    80006c20:	89aa                	mv	s3,a0
  int buddy = (bi % 2 == 0) ? bi+1 : bi-1;
    80006c22:	00058a9b          	sext.w	s5,a1
    80006c26:	0015f793          	andi	a5,a1,1
    80006c2a:	ebad                	bnez	a5,80006c9c <bd_initfree_pair+0x90>
    80006c2c:	00158a1b          	addiw	s4,a1,1
  int free = 0;
  if(bit_isset(bd_sizes[k].alloc, bi) !=  bit_isset(bd_sizes[k].alloc, buddy)) {
    80006c30:	00599493          	slli	s1,s3,0x5
    80006c34:	00025797          	auipc	a5,0x25
    80006c38:	41c7b783          	ld	a5,1052(a5) # 8002c050 <bd_sizes>
    80006c3c:	94be                	add	s1,s1,a5
    80006c3e:	0104bb03          	ld	s6,16(s1)
    80006c42:	855a                	mv	a0,s6
    80006c44:	00000097          	auipc	ra,0x0
    80006c48:	8b0080e7          	jalr	-1872(ra) # 800064f4 <bit_isset>
    80006c4c:	892a                	mv	s2,a0
    80006c4e:	85d2                	mv	a1,s4
    80006c50:	855a                	mv	a0,s6
    80006c52:	00000097          	auipc	ra,0x0
    80006c56:	8a2080e7          	jalr	-1886(ra) # 800064f4 <bit_isset>
  int free = 0;
    80006c5a:	4b01                	li	s6,0
  if(bit_isset(bd_sizes[k].alloc, bi) !=  bit_isset(bd_sizes[k].alloc, buddy)) {
    80006c5c:	02a90563          	beq	s2,a0,80006c86 <bd_initfree_pair+0x7a>
    // one of the pair is free
    free = BLK_SIZE(k);
    80006c60:	45c1                	li	a1,16
    80006c62:	013599b3          	sll	s3,a1,s3
    80006c66:	00098b1b          	sext.w	s6,s3
    if(bit_isset(bd_sizes[k].alloc, bi))
    80006c6a:	02090c63          	beqz	s2,80006ca2 <bd_initfree_pair+0x96>
  return (char *) bd_base + n;
    80006c6e:	034989bb          	mulw	s3,s3,s4
      lst_push(&bd_sizes[k].free, addr(k, buddy));   // put buddy on free list
    80006c72:	00025597          	auipc	a1,0x25
    80006c76:	3d65b583          	ld	a1,982(a1) # 8002c048 <bd_base>
    80006c7a:	95ce                	add	a1,a1,s3
    80006c7c:	8526                	mv	a0,s1
    80006c7e:	00000097          	auipc	ra,0x0
    80006c82:	48e080e7          	jalr	1166(ra) # 8000710c <lst_push>
    else
      lst_push(&bd_sizes[k].free, addr(k, bi));      // put bi on free list
  }
  return free;
}
    80006c86:	855a                	mv	a0,s6
    80006c88:	70e2                	ld	ra,56(sp)
    80006c8a:	7442                	ld	s0,48(sp)
    80006c8c:	74a2                	ld	s1,40(sp)
    80006c8e:	7902                	ld	s2,32(sp)
    80006c90:	69e2                	ld	s3,24(sp)
    80006c92:	6a42                	ld	s4,16(sp)
    80006c94:	6aa2                	ld	s5,8(sp)
    80006c96:	6b02                	ld	s6,0(sp)
    80006c98:	6121                	addi	sp,sp,64
    80006c9a:	8082                	ret
  int buddy = (bi % 2 == 0) ? bi+1 : bi-1;
    80006c9c:	fff58a1b          	addiw	s4,a1,-1
    80006ca0:	bf41                	j	80006c30 <bd_initfree_pair+0x24>
  return (char *) bd_base + n;
    80006ca2:	035989bb          	mulw	s3,s3,s5
      lst_push(&bd_sizes[k].free, addr(k, bi));      // put bi on free list
    80006ca6:	00025597          	auipc	a1,0x25
    80006caa:	3a25b583          	ld	a1,930(a1) # 8002c048 <bd_base>
    80006cae:	95ce                	add	a1,a1,s3
    80006cb0:	8526                	mv	a0,s1
    80006cb2:	00000097          	auipc	ra,0x0
    80006cb6:	45a080e7          	jalr	1114(ra) # 8000710c <lst_push>
    80006cba:	b7f1                	j	80006c86 <bd_initfree_pair+0x7a>

0000000080006cbc <bd_initfree>:
  
// Initialize the free lists for each size k.  For each size k, there
// are only two pairs that may have a buddy that should be on free list:
// bd_left and bd_right.
int
bd_initfree(void *bd_left, void *bd_right) {
    80006cbc:	711d                	addi	sp,sp,-96
    80006cbe:	ec86                	sd	ra,88(sp)
    80006cc0:	e8a2                	sd	s0,80(sp)
    80006cc2:	e4a6                	sd	s1,72(sp)
    80006cc4:	e0ca                	sd	s2,64(sp)
    80006cc6:	fc4e                	sd	s3,56(sp)
    80006cc8:	f852                	sd	s4,48(sp)
    80006cca:	f456                	sd	s5,40(sp)
    80006ccc:	f05a                	sd	s6,32(sp)
    80006cce:	ec5e                	sd	s7,24(sp)
    80006cd0:	e862                	sd	s8,16(sp)
    80006cd2:	e466                	sd	s9,8(sp)
    80006cd4:	e06a                	sd	s10,0(sp)
    80006cd6:	1080                	addi	s0,sp,96
  int free = 0;

  for (int k = 0; k < MAXSIZE; k++) {   // skip max size
    80006cd8:	00025717          	auipc	a4,0x25
    80006cdc:	38072703          	lw	a4,896(a4) # 8002c058 <nsizes>
    80006ce0:	4785                	li	a5,1
    80006ce2:	06e7db63          	bge	a5,a4,80006d58 <bd_initfree+0x9c>
    80006ce6:	8aaa                	mv	s5,a0
    80006ce8:	8b2e                	mv	s6,a1
    80006cea:	4901                	li	s2,0
  int free = 0;
    80006cec:	4a01                	li	s4,0
  int n = p - (char *) bd_base;
    80006cee:	00025c97          	auipc	s9,0x25
    80006cf2:	35ac8c93          	addi	s9,s9,858 # 8002c048 <bd_base>
  return n / BLK_SIZE(k);
    80006cf6:	4c41                	li	s8,16
  for (int k = 0; k < MAXSIZE; k++) {   // skip max size
    80006cf8:	00025b97          	auipc	s7,0x25
    80006cfc:	360b8b93          	addi	s7,s7,864 # 8002c058 <nsizes>
    80006d00:	a039                	j	80006d0e <bd_initfree+0x52>
    80006d02:	2905                	addiw	s2,s2,1
    80006d04:	000ba783          	lw	a5,0(s7)
    80006d08:	37fd                	addiw	a5,a5,-1
    80006d0a:	04f95863          	bge	s2,a5,80006d5a <bd_initfree+0x9e>
    int left = blk_index_next(k, bd_left);
    80006d0e:	85d6                	mv	a1,s5
    80006d10:	854a                	mv	a0,s2
    80006d12:	00000097          	auipc	ra,0x0
    80006d16:	dd6080e7          	jalr	-554(ra) # 80006ae8 <blk_index_next>
    80006d1a:	89aa                	mv	s3,a0
  int n = p - (char *) bd_base;
    80006d1c:	000cb483          	ld	s1,0(s9)
  return n / BLK_SIZE(k);
    80006d20:	409b04bb          	subw	s1,s6,s1
    80006d24:	012c17b3          	sll	a5,s8,s2
    80006d28:	02f4c4b3          	div	s1,s1,a5
    80006d2c:	2481                	sext.w	s1,s1
    int right = blk_index(k, bd_right);
    free += bd_initfree_pair(k, left);
    80006d2e:	85aa                	mv	a1,a0
    80006d30:	854a                	mv	a0,s2
    80006d32:	00000097          	auipc	ra,0x0
    80006d36:	eda080e7          	jalr	-294(ra) # 80006c0c <bd_initfree_pair>
    80006d3a:	01450d3b          	addw	s10,a0,s4
    80006d3e:	000d0a1b          	sext.w	s4,s10
    if(right <= left)
    80006d42:	fc99d0e3          	bge	s3,s1,80006d02 <bd_initfree+0x46>
      continue;
    free += bd_initfree_pair(k, right);
    80006d46:	85a6                	mv	a1,s1
    80006d48:	854a                	mv	a0,s2
    80006d4a:	00000097          	auipc	ra,0x0
    80006d4e:	ec2080e7          	jalr	-318(ra) # 80006c0c <bd_initfree_pair>
    80006d52:	00ad0a3b          	addw	s4,s10,a0
    80006d56:	b775                	j	80006d02 <bd_initfree+0x46>
  int free = 0;
    80006d58:	4a01                	li	s4,0
  }
  return free;
}
    80006d5a:	8552                	mv	a0,s4
    80006d5c:	60e6                	ld	ra,88(sp)
    80006d5e:	6446                	ld	s0,80(sp)
    80006d60:	64a6                	ld	s1,72(sp)
    80006d62:	6906                	ld	s2,64(sp)
    80006d64:	79e2                	ld	s3,56(sp)
    80006d66:	7a42                	ld	s4,48(sp)
    80006d68:	7aa2                	ld	s5,40(sp)
    80006d6a:	7b02                	ld	s6,32(sp)
    80006d6c:	6be2                	ld	s7,24(sp)
    80006d6e:	6c42                	ld	s8,16(sp)
    80006d70:	6ca2                	ld	s9,8(sp)
    80006d72:	6d02                	ld	s10,0(sp)
    80006d74:	6125                	addi	sp,sp,96
    80006d76:	8082                	ret

0000000080006d78 <bd_mark_data_structures>:

// Mark the range [bd_base,p) as allocated
int
bd_mark_data_structures(char *p) {
    80006d78:	7179                	addi	sp,sp,-48
    80006d7a:	f406                	sd	ra,40(sp)
    80006d7c:	f022                	sd	s0,32(sp)
    80006d7e:	ec26                	sd	s1,24(sp)
    80006d80:	e84a                	sd	s2,16(sp)
    80006d82:	e44e                	sd	s3,8(sp)
    80006d84:	1800                	addi	s0,sp,48
    80006d86:	892a                	mv	s2,a0
  int meta = p - (char*)bd_base;
    80006d88:	00025997          	auipc	s3,0x25
    80006d8c:	2c098993          	addi	s3,s3,704 # 8002c048 <bd_base>
    80006d90:	0009b483          	ld	s1,0(s3)
    80006d94:	409504bb          	subw	s1,a0,s1
  printf("bd: %d meta bytes for managing %d bytes of memory\n", meta, BLK_SIZE(MAXSIZE));
    80006d98:	00025797          	auipc	a5,0x25
    80006d9c:	2c07a783          	lw	a5,704(a5) # 8002c058 <nsizes>
    80006da0:	37fd                	addiw	a5,a5,-1
    80006da2:	4641                	li	a2,16
    80006da4:	00f61633          	sll	a2,a2,a5
    80006da8:	85a6                	mv	a1,s1
    80006daa:	00002517          	auipc	a0,0x2
    80006dae:	c2e50513          	addi	a0,a0,-978 # 800089d8 <userret+0x948>
    80006db2:	ffff9097          	auipc	ra,0xffff9
    80006db6:	7f0080e7          	jalr	2032(ra) # 800005a2 <printf>
  bd_mark(bd_base, p);
    80006dba:	85ca                	mv	a1,s2
    80006dbc:	0009b503          	ld	a0,0(s3)
    80006dc0:	00000097          	auipc	ra,0x0
    80006dc4:	d74080e7          	jalr	-652(ra) # 80006b34 <bd_mark>
  return meta;
}
    80006dc8:	8526                	mv	a0,s1
    80006dca:	70a2                	ld	ra,40(sp)
    80006dcc:	7402                	ld	s0,32(sp)
    80006dce:	64e2                	ld	s1,24(sp)
    80006dd0:	6942                	ld	s2,16(sp)
    80006dd2:	69a2                	ld	s3,8(sp)
    80006dd4:	6145                	addi	sp,sp,48
    80006dd6:	8082                	ret

0000000080006dd8 <bd_mark_unavailable>:

// Mark the range [end, HEAPSIZE) as allocated
int
bd_mark_unavailable(void *end, void *left) {
    80006dd8:	1101                	addi	sp,sp,-32
    80006dda:	ec06                	sd	ra,24(sp)
    80006ddc:	e822                	sd	s0,16(sp)
    80006dde:	e426                	sd	s1,8(sp)
    80006de0:	1000                	addi	s0,sp,32
  int unavailable = BLK_SIZE(MAXSIZE)-(end-bd_base);
    80006de2:	00025497          	auipc	s1,0x25
    80006de6:	2764a483          	lw	s1,630(s1) # 8002c058 <nsizes>
    80006dea:	fff4879b          	addiw	a5,s1,-1
    80006dee:	44c1                	li	s1,16
    80006df0:	00f494b3          	sll	s1,s1,a5
    80006df4:	00025797          	auipc	a5,0x25
    80006df8:	2547b783          	ld	a5,596(a5) # 8002c048 <bd_base>
    80006dfc:	8d1d                	sub	a0,a0,a5
    80006dfe:	40a4853b          	subw	a0,s1,a0
    80006e02:	0005049b          	sext.w	s1,a0
  if(unavailable > 0)
    80006e06:	00905a63          	blez	s1,80006e1a <bd_mark_unavailable+0x42>
    unavailable = ROUNDUP(unavailable, LEAF_SIZE);
    80006e0a:	357d                	addiw	a0,a0,-1
    80006e0c:	41f5549b          	sraiw	s1,a0,0x1f
    80006e10:	01c4d49b          	srliw	s1,s1,0x1c
    80006e14:	9ca9                	addw	s1,s1,a0
    80006e16:	98c1                	andi	s1,s1,-16
    80006e18:	24c1                	addiw	s1,s1,16
  printf("bd: 0x%x bytes unavailable\n", unavailable);
    80006e1a:	85a6                	mv	a1,s1
    80006e1c:	00002517          	auipc	a0,0x2
    80006e20:	bf450513          	addi	a0,a0,-1036 # 80008a10 <userret+0x980>
    80006e24:	ffff9097          	auipc	ra,0xffff9
    80006e28:	77e080e7          	jalr	1918(ra) # 800005a2 <printf>

  void *bd_end = bd_base+BLK_SIZE(MAXSIZE)-unavailable;
    80006e2c:	00025717          	auipc	a4,0x25
    80006e30:	21c73703          	ld	a4,540(a4) # 8002c048 <bd_base>
    80006e34:	00025597          	auipc	a1,0x25
    80006e38:	2245a583          	lw	a1,548(a1) # 8002c058 <nsizes>
    80006e3c:	fff5879b          	addiw	a5,a1,-1
    80006e40:	45c1                	li	a1,16
    80006e42:	00f595b3          	sll	a1,a1,a5
    80006e46:	40958533          	sub	a0,a1,s1
  bd_mark(bd_end, bd_base+BLK_SIZE(MAXSIZE));
    80006e4a:	95ba                	add	a1,a1,a4
    80006e4c:	953a                	add	a0,a0,a4
    80006e4e:	00000097          	auipc	ra,0x0
    80006e52:	ce6080e7          	jalr	-794(ra) # 80006b34 <bd_mark>
  return unavailable;
}
    80006e56:	8526                	mv	a0,s1
    80006e58:	60e2                	ld	ra,24(sp)
    80006e5a:	6442                	ld	s0,16(sp)
    80006e5c:	64a2                	ld	s1,8(sp)
    80006e5e:	6105                	addi	sp,sp,32
    80006e60:	8082                	ret

0000000080006e62 <bd_init>:

// Initialize the buddy allocator: it manages memory from [base, end).
void
bd_init(void *base, void *end) {
    80006e62:	715d                	addi	sp,sp,-80
    80006e64:	e486                	sd	ra,72(sp)
    80006e66:	e0a2                	sd	s0,64(sp)
    80006e68:	fc26                	sd	s1,56(sp)
    80006e6a:	f84a                	sd	s2,48(sp)
    80006e6c:	f44e                	sd	s3,40(sp)
    80006e6e:	f052                	sd	s4,32(sp)
    80006e70:	ec56                	sd	s5,24(sp)
    80006e72:	e85a                	sd	s6,16(sp)
    80006e74:	e45e                	sd	s7,8(sp)
    80006e76:	e062                	sd	s8,0(sp)
    80006e78:	0880                	addi	s0,sp,80
    80006e7a:	8c2e                	mv	s8,a1
  char *p = (char *) ROUNDUP((uint64)base, LEAF_SIZE);
    80006e7c:	fff50493          	addi	s1,a0,-1
    80006e80:	98c1                	andi	s1,s1,-16
    80006e82:	04c1                	addi	s1,s1,16
  int sz;

  initlock(&lock, "buddy");
    80006e84:	00002597          	auipc	a1,0x2
    80006e88:	bac58593          	addi	a1,a1,-1108 # 80008a30 <userret+0x9a0>
    80006e8c:	00025517          	auipc	a0,0x25
    80006e90:	17450513          	addi	a0,a0,372 # 8002c000 <lock>
    80006e94:	ffffa097          	auipc	ra,0xffffa
    80006e98:	c02080e7          	jalr	-1022(ra) # 80000a96 <initlock>
  bd_base = (void *) p;
    80006e9c:	00025797          	auipc	a5,0x25
    80006ea0:	1a97b623          	sd	s1,428(a5) # 8002c048 <bd_base>

  // compute the number of sizes we need to manage [base, end)
  nsizes = log2(((char *)end-p)/LEAF_SIZE) + 1;
    80006ea4:	409c0933          	sub	s2,s8,s1
    80006ea8:	43f95513          	srai	a0,s2,0x3f
    80006eac:	893d                	andi	a0,a0,15
    80006eae:	954a                	add	a0,a0,s2
    80006eb0:	8511                	srai	a0,a0,0x4
    80006eb2:	00000097          	auipc	ra,0x0
    80006eb6:	c60080e7          	jalr	-928(ra) # 80006b12 <log2>
  if((char*)end-p > BLK_SIZE(MAXSIZE)) {
    80006eba:	47c1                	li	a5,16
    80006ebc:	00a797b3          	sll	a5,a5,a0
    80006ec0:	1b27c663          	blt	a5,s2,8000706c <bd_init+0x20a>
  nsizes = log2(((char *)end-p)/LEAF_SIZE) + 1;
    80006ec4:	2505                	addiw	a0,a0,1
    80006ec6:	00025797          	auipc	a5,0x25
    80006eca:	18a7a923          	sw	a0,402(a5) # 8002c058 <nsizes>
    nsizes++;  // round up to the next power of 2
  }

  printf("bd: memory sz is %d bytes; allocate an size array of length %d\n",
    80006ece:	00025997          	auipc	s3,0x25
    80006ed2:	18a98993          	addi	s3,s3,394 # 8002c058 <nsizes>
    80006ed6:	0009a603          	lw	a2,0(s3)
    80006eda:	85ca                	mv	a1,s2
    80006edc:	00002517          	auipc	a0,0x2
    80006ee0:	b5c50513          	addi	a0,a0,-1188 # 80008a38 <userret+0x9a8>
    80006ee4:	ffff9097          	auipc	ra,0xffff9
    80006ee8:	6be080e7          	jalr	1726(ra) # 800005a2 <printf>
         (char*) end - p, nsizes);

  // allocate bd_sizes array
  bd_sizes = (Sz_info *) p;
    80006eec:	00025797          	auipc	a5,0x25
    80006ef0:	1697b223          	sd	s1,356(a5) # 8002c050 <bd_sizes>
  p += sizeof(Sz_info) * nsizes;
    80006ef4:	0009a603          	lw	a2,0(s3)
    80006ef8:	00561913          	slli	s2,a2,0x5
    80006efc:	9926                	add	s2,s2,s1
  memset(bd_sizes, 0, sizeof(Sz_info) * nsizes);
    80006efe:	0056161b          	slliw	a2,a2,0x5
    80006f02:	4581                	li	a1,0
    80006f04:	8526                	mv	a0,s1
    80006f06:	ffffa097          	auipc	ra,0xffffa
    80006f0a:	f4c080e7          	jalr	-180(ra) # 80000e52 <memset>

  // initialize free list and allocate the alloc array for each size k
  for (int k = 0; k < nsizes; k++) {
    80006f0e:	0009a783          	lw	a5,0(s3)
    80006f12:	06f05a63          	blez	a5,80006f86 <bd_init+0x124>
    80006f16:	4981                	li	s3,0
    lst_init(&bd_sizes[k].free);
    80006f18:	00025a97          	auipc	s5,0x25
    80006f1c:	138a8a93          	addi	s5,s5,312 # 8002c050 <bd_sizes>
    sz = sizeof(char)* ROUNDUP(NBLK(k), 8)/8;
    80006f20:	00025a17          	auipc	s4,0x25
    80006f24:	138a0a13          	addi	s4,s4,312 # 8002c058 <nsizes>
    80006f28:	4b05                	li	s6,1
    lst_init(&bd_sizes[k].free);
    80006f2a:	00599b93          	slli	s7,s3,0x5
    80006f2e:	000ab503          	ld	a0,0(s5)
    80006f32:	955e                	add	a0,a0,s7
    80006f34:	00000097          	auipc	ra,0x0
    80006f38:	166080e7          	jalr	358(ra) # 8000709a <lst_init>
    sz = sizeof(char)* ROUNDUP(NBLK(k), 8)/8;
    80006f3c:	000a2483          	lw	s1,0(s4)
    80006f40:	34fd                	addiw	s1,s1,-1
    80006f42:	413484bb          	subw	s1,s1,s3
    80006f46:	009b14bb          	sllw	s1,s6,s1
    80006f4a:	fff4879b          	addiw	a5,s1,-1
    80006f4e:	41f7d49b          	sraiw	s1,a5,0x1f
    80006f52:	01d4d49b          	srliw	s1,s1,0x1d
    80006f56:	9cbd                	addw	s1,s1,a5
    80006f58:	98e1                	andi	s1,s1,-8
    80006f5a:	24a1                	addiw	s1,s1,8
    bd_sizes[k].alloc = p;
    80006f5c:	000ab783          	ld	a5,0(s5)
    80006f60:	9bbe                	add	s7,s7,a5
    80006f62:	012bb823          	sd	s2,16(s7)
    memset(bd_sizes[k].alloc, 0, sz);
    80006f66:	848d                	srai	s1,s1,0x3
    80006f68:	8626                	mv	a2,s1
    80006f6a:	4581                	li	a1,0
    80006f6c:	854a                	mv	a0,s2
    80006f6e:	ffffa097          	auipc	ra,0xffffa
    80006f72:	ee4080e7          	jalr	-284(ra) # 80000e52 <memset>
    p += sz;
    80006f76:	9926                	add	s2,s2,s1
  for (int k = 0; k < nsizes; k++) {
    80006f78:	0985                	addi	s3,s3,1
    80006f7a:	000a2703          	lw	a4,0(s4)
    80006f7e:	0009879b          	sext.w	a5,s3
    80006f82:	fae7c4e3          	blt	a5,a4,80006f2a <bd_init+0xc8>
  }

  // allocate the split array for each size k, except for k = 0, since
  // we will not split blocks of size k = 0, the smallest size.
  for (int k = 1; k < nsizes; k++) {
    80006f86:	00025797          	auipc	a5,0x25
    80006f8a:	0d27a783          	lw	a5,210(a5) # 8002c058 <nsizes>
    80006f8e:	4705                	li	a4,1
    80006f90:	06f75163          	bge	a4,a5,80006ff2 <bd_init+0x190>
    80006f94:	02000a13          	li	s4,32
    80006f98:	4985                	li	s3,1
    sz = sizeof(char)* (ROUNDUP(NBLK(k), 8))/8;
    80006f9a:	4b85                	li	s7,1
    bd_sizes[k].split = p;
    80006f9c:	00025b17          	auipc	s6,0x25
    80006fa0:	0b4b0b13          	addi	s6,s6,180 # 8002c050 <bd_sizes>
  for (int k = 1; k < nsizes; k++) {
    80006fa4:	00025a97          	auipc	s5,0x25
    80006fa8:	0b4a8a93          	addi	s5,s5,180 # 8002c058 <nsizes>
    sz = sizeof(char)* (ROUNDUP(NBLK(k), 8))/8;
    80006fac:	37fd                	addiw	a5,a5,-1
    80006fae:	413787bb          	subw	a5,a5,s3
    80006fb2:	00fb94bb          	sllw	s1,s7,a5
    80006fb6:	fff4879b          	addiw	a5,s1,-1
    80006fba:	41f7d49b          	sraiw	s1,a5,0x1f
    80006fbe:	01d4d49b          	srliw	s1,s1,0x1d
    80006fc2:	9cbd                	addw	s1,s1,a5
    80006fc4:	98e1                	andi	s1,s1,-8
    80006fc6:	24a1                	addiw	s1,s1,8
    bd_sizes[k].split = p;
    80006fc8:	000b3783          	ld	a5,0(s6)
    80006fcc:	97d2                	add	a5,a5,s4
    80006fce:	0127bc23          	sd	s2,24(a5)
    memset(bd_sizes[k].split, 0, sz);
    80006fd2:	848d                	srai	s1,s1,0x3
    80006fd4:	8626                	mv	a2,s1
    80006fd6:	4581                	li	a1,0
    80006fd8:	854a                	mv	a0,s2
    80006fda:	ffffa097          	auipc	ra,0xffffa
    80006fde:	e78080e7          	jalr	-392(ra) # 80000e52 <memset>
    p += sz;
    80006fe2:	9926                	add	s2,s2,s1
  for (int k = 1; k < nsizes; k++) {
    80006fe4:	2985                	addiw	s3,s3,1
    80006fe6:	000aa783          	lw	a5,0(s5)
    80006fea:	020a0a13          	addi	s4,s4,32
    80006fee:	faf9cfe3          	blt	s3,a5,80006fac <bd_init+0x14a>
  }
  p = (char *) ROUNDUP((uint64) p, LEAF_SIZE);
    80006ff2:	197d                	addi	s2,s2,-1
    80006ff4:	ff097913          	andi	s2,s2,-16
    80006ff8:	0941                	addi	s2,s2,16

  // done allocating; mark the memory range [base, p) as allocated, so
  // that buddy will not hand out that memory.
  int meta = bd_mark_data_structures(p);
    80006ffa:	854a                	mv	a0,s2
    80006ffc:	00000097          	auipc	ra,0x0
    80007000:	d7c080e7          	jalr	-644(ra) # 80006d78 <bd_mark_data_structures>
    80007004:	8a2a                	mv	s4,a0
  
  // mark the unavailable memory range [end, HEAP_SIZE) as allocated,
  // so that buddy will not hand out that memory.
  int unavailable = bd_mark_unavailable(end, p);
    80007006:	85ca                	mv	a1,s2
    80007008:	8562                	mv	a0,s8
    8000700a:	00000097          	auipc	ra,0x0
    8000700e:	dce080e7          	jalr	-562(ra) # 80006dd8 <bd_mark_unavailable>
    80007012:	89aa                	mv	s3,a0
  void *bd_end = bd_base+BLK_SIZE(MAXSIZE)-unavailable;
    80007014:	00025a97          	auipc	s5,0x25
    80007018:	044a8a93          	addi	s5,s5,68 # 8002c058 <nsizes>
    8000701c:	000aa783          	lw	a5,0(s5)
    80007020:	37fd                	addiw	a5,a5,-1
    80007022:	44c1                	li	s1,16
    80007024:	00f497b3          	sll	a5,s1,a5
    80007028:	8f89                	sub	a5,a5,a0
  
  // initialize free lists for each size k
  int free = bd_initfree(p, bd_end);
    8000702a:	00025597          	auipc	a1,0x25
    8000702e:	01e5b583          	ld	a1,30(a1) # 8002c048 <bd_base>
    80007032:	95be                	add	a1,a1,a5
    80007034:	854a                	mv	a0,s2
    80007036:	00000097          	auipc	ra,0x0
    8000703a:	c86080e7          	jalr	-890(ra) # 80006cbc <bd_initfree>

  // check if the amount that is free is what we expect
  if(free != BLK_SIZE(MAXSIZE)-meta-unavailable) {
    8000703e:	000aa603          	lw	a2,0(s5)
    80007042:	367d                	addiw	a2,a2,-1
    80007044:	00c49633          	sll	a2,s1,a2
    80007048:	41460633          	sub	a2,a2,s4
    8000704c:	41360633          	sub	a2,a2,s3
    80007050:	02c51463          	bne	a0,a2,80007078 <bd_init+0x216>
    printf("free %d %d\n", free, BLK_SIZE(MAXSIZE)-meta-unavailable);
    panic("bd_init: free mem");
  }
}
    80007054:	60a6                	ld	ra,72(sp)
    80007056:	6406                	ld	s0,64(sp)
    80007058:	74e2                	ld	s1,56(sp)
    8000705a:	7942                	ld	s2,48(sp)
    8000705c:	79a2                	ld	s3,40(sp)
    8000705e:	7a02                	ld	s4,32(sp)
    80007060:	6ae2                	ld	s5,24(sp)
    80007062:	6b42                	ld	s6,16(sp)
    80007064:	6ba2                	ld	s7,8(sp)
    80007066:	6c02                	ld	s8,0(sp)
    80007068:	6161                	addi	sp,sp,80
    8000706a:	8082                	ret
    nsizes++;  // round up to the next power of 2
    8000706c:	2509                	addiw	a0,a0,2
    8000706e:	00025797          	auipc	a5,0x25
    80007072:	fea7a523          	sw	a0,-22(a5) # 8002c058 <nsizes>
    80007076:	bda1                	j	80006ece <bd_init+0x6c>
    printf("free %d %d\n", free, BLK_SIZE(MAXSIZE)-meta-unavailable);
    80007078:	85aa                	mv	a1,a0
    8000707a:	00002517          	auipc	a0,0x2
    8000707e:	9fe50513          	addi	a0,a0,-1538 # 80008a78 <userret+0x9e8>
    80007082:	ffff9097          	auipc	ra,0xffff9
    80007086:	520080e7          	jalr	1312(ra) # 800005a2 <printf>
    panic("bd_init: free mem");
    8000708a:	00002517          	auipc	a0,0x2
    8000708e:	9fe50513          	addi	a0,a0,-1538 # 80008a88 <userret+0x9f8>
    80007092:	ffff9097          	auipc	ra,0xffff9
    80007096:	4b6080e7          	jalr	1206(ra) # 80000548 <panic>

000000008000709a <lst_init>:
// fast. circular simplifies code, because don't have to check for
// empty list in insert and remove.

void
lst_init(struct list *lst)
{
    8000709a:	1141                	addi	sp,sp,-16
    8000709c:	e422                	sd	s0,8(sp)
    8000709e:	0800                	addi	s0,sp,16
  lst->next = lst;
    800070a0:	e108                	sd	a0,0(a0)
  lst->prev = lst;
    800070a2:	e508                	sd	a0,8(a0)
}
    800070a4:	6422                	ld	s0,8(sp)
    800070a6:	0141                	addi	sp,sp,16
    800070a8:	8082                	ret

00000000800070aa <lst_empty>:

int
lst_empty(struct list *lst) {
    800070aa:	1141                	addi	sp,sp,-16
    800070ac:	e422                	sd	s0,8(sp)
    800070ae:	0800                	addi	s0,sp,16
  return lst->next == lst;
    800070b0:	611c                	ld	a5,0(a0)
    800070b2:	40a78533          	sub	a0,a5,a0
}
    800070b6:	00153513          	seqz	a0,a0
    800070ba:	6422                	ld	s0,8(sp)
    800070bc:	0141                	addi	sp,sp,16
    800070be:	8082                	ret

00000000800070c0 <lst_remove>:

void
lst_remove(struct list *e) {
    800070c0:	1141                	addi	sp,sp,-16
    800070c2:	e422                	sd	s0,8(sp)
    800070c4:	0800                	addi	s0,sp,16
  e->prev->next = e->next;
    800070c6:	6518                	ld	a4,8(a0)
    800070c8:	611c                	ld	a5,0(a0)
    800070ca:	e31c                	sd	a5,0(a4)
  e->next->prev = e->prev;
    800070cc:	6518                	ld	a4,8(a0)
    800070ce:	e798                	sd	a4,8(a5)
}
    800070d0:	6422                	ld	s0,8(sp)
    800070d2:	0141                	addi	sp,sp,16
    800070d4:	8082                	ret

00000000800070d6 <lst_pop>:

void*
lst_pop(struct list *lst) {
    800070d6:	1101                	addi	sp,sp,-32
    800070d8:	ec06                	sd	ra,24(sp)
    800070da:	e822                	sd	s0,16(sp)
    800070dc:	e426                	sd	s1,8(sp)
    800070de:	1000                	addi	s0,sp,32
  if(lst->next == lst)
    800070e0:	6104                	ld	s1,0(a0)
    800070e2:	00a48d63          	beq	s1,a0,800070fc <lst_pop+0x26>
    panic("lst_pop");
  struct list *p = lst->next;
  lst_remove(p);
    800070e6:	8526                	mv	a0,s1
    800070e8:	00000097          	auipc	ra,0x0
    800070ec:	fd8080e7          	jalr	-40(ra) # 800070c0 <lst_remove>
  return (void *)p;
}
    800070f0:	8526                	mv	a0,s1
    800070f2:	60e2                	ld	ra,24(sp)
    800070f4:	6442                	ld	s0,16(sp)
    800070f6:	64a2                	ld	s1,8(sp)
    800070f8:	6105                	addi	sp,sp,32
    800070fa:	8082                	ret
    panic("lst_pop");
    800070fc:	00002517          	auipc	a0,0x2
    80007100:	9a450513          	addi	a0,a0,-1628 # 80008aa0 <userret+0xa10>
    80007104:	ffff9097          	auipc	ra,0xffff9
    80007108:	444080e7          	jalr	1092(ra) # 80000548 <panic>

000000008000710c <lst_push>:

void
lst_push(struct list *lst, void *p)
{
    8000710c:	1141                	addi	sp,sp,-16
    8000710e:	e422                	sd	s0,8(sp)
    80007110:	0800                	addi	s0,sp,16
  struct list *e = (struct list *) p;
  e->next = lst->next;
    80007112:	611c                	ld	a5,0(a0)
    80007114:	e19c                	sd	a5,0(a1)
  e->prev = lst;
    80007116:	e588                	sd	a0,8(a1)
  lst->next->prev = p;
    80007118:	611c                	ld	a5,0(a0)
    8000711a:	e78c                	sd	a1,8(a5)
  lst->next = e;
    8000711c:	e10c                	sd	a1,0(a0)
}
    8000711e:	6422                	ld	s0,8(sp)
    80007120:	0141                	addi	sp,sp,16
    80007122:	8082                	ret

0000000080007124 <lst_print>:

void
lst_print(struct list *lst)
{
    80007124:	7179                	addi	sp,sp,-48
    80007126:	f406                	sd	ra,40(sp)
    80007128:	f022                	sd	s0,32(sp)
    8000712a:	ec26                	sd	s1,24(sp)
    8000712c:	e84a                	sd	s2,16(sp)
    8000712e:	e44e                	sd	s3,8(sp)
    80007130:	1800                	addi	s0,sp,48
  for (struct list *p = lst->next; p != lst; p = p->next) {
    80007132:	6104                	ld	s1,0(a0)
    80007134:	02950063          	beq	a0,s1,80007154 <lst_print+0x30>
    80007138:	892a                	mv	s2,a0
    printf(" %p", p);
    8000713a:	00002997          	auipc	s3,0x2
    8000713e:	96e98993          	addi	s3,s3,-1682 # 80008aa8 <userret+0xa18>
    80007142:	85a6                	mv	a1,s1
    80007144:	854e                	mv	a0,s3
    80007146:	ffff9097          	auipc	ra,0xffff9
    8000714a:	45c080e7          	jalr	1116(ra) # 800005a2 <printf>
  for (struct list *p = lst->next; p != lst; p = p->next) {
    8000714e:	6084                	ld	s1,0(s1)
    80007150:	fe9919e3          	bne	s2,s1,80007142 <lst_print+0x1e>
  }
  printf("\n");
    80007154:	00001517          	auipc	a0,0x1
    80007158:	13c50513          	addi	a0,a0,316 # 80008290 <userret+0x200>
    8000715c:	ffff9097          	auipc	ra,0xffff9
    80007160:	446080e7          	jalr	1094(ra) # 800005a2 <printf>
}
    80007164:	70a2                	ld	ra,40(sp)
    80007166:	7402                	ld	s0,32(sp)
    80007168:	64e2                	ld	s1,24(sp)
    8000716a:	6942                	ld	s2,16(sp)
    8000716c:	69a2                	ld	s3,8(sp)
    8000716e:	6145                	addi	sp,sp,48
    80007170:	8082                	ret
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

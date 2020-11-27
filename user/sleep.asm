
user/_sleep：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "user/user.h"

int main(int argn, char *argv[]){
   0:	1101                	addi	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	e426                	sd	s1,8(sp)
   8:	1000                	addi	s0,sp,32
	if(argn != 2){
   a:	4789                	li	a5,2
   c:	00f50e63          	beq	a0,a5,28 <main+0x28>
		printf("must 1 argument for sleep\n");
  10:	00000517          	auipc	a0,0x0
  14:	77050513          	addi	a0,a0,1904 # 780 <malloc+0xe6>
  18:	00000097          	auipc	ra,0x0
  1c:	5c4080e7          	jalr	1476(ra) # 5dc <printf>
		exit();
  20:	00000097          	auipc	ra,0x0
  24:	224080e7          	jalr	548(ra) # 244 <exit>
	}
	int sleepNum = atoi(argv[1]);
  28:	6588                	ld	a0,8(a1)
  2a:	00000097          	auipc	ra,0x0
  2e:	19e080e7          	jalr	414(ra) # 1c8 <atoi>
  32:	84aa                	mv	s1,a0
	printf("(nothing happens for a little while)\n");
  34:	00000517          	auipc	a0,0x0
  38:	76c50513          	addi	a0,a0,1900 # 7a0 <malloc+0x106>
  3c:	00000097          	auipc	ra,0x0
  40:	5a0080e7          	jalr	1440(ra) # 5dc <printf>
	sleep(sleepNum);
  44:	8526                	mv	a0,s1
  46:	00000097          	auipc	ra,0x0
  4a:	28e080e7          	jalr	654(ra) # 2d4 <sleep>
	exit();
  4e:	00000097          	auipc	ra,0x0
  52:	1f6080e7          	jalr	502(ra) # 244 <exit>

0000000000000056 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  56:	1141                	addi	sp,sp,-16
  58:	e422                	sd	s0,8(sp)
  5a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  5c:	87aa                	mv	a5,a0
  5e:	0585                	addi	a1,a1,1
  60:	0785                	addi	a5,a5,1
  62:	fff5c703          	lbu	a4,-1(a1)
  66:	fee78fa3          	sb	a4,-1(a5)
  6a:	fb75                	bnez	a4,5e <strcpy+0x8>
    ;
  return os;
}
  6c:	6422                	ld	s0,8(sp)
  6e:	0141                	addi	sp,sp,16
  70:	8082                	ret

0000000000000072 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  72:	1141                	addi	sp,sp,-16
  74:	e422                	sd	s0,8(sp)
  76:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  78:	00054783          	lbu	a5,0(a0)
  7c:	cb91                	beqz	a5,90 <strcmp+0x1e>
  7e:	0005c703          	lbu	a4,0(a1)
  82:	00f71763          	bne	a4,a5,90 <strcmp+0x1e>
    p++, q++;
  86:	0505                	addi	a0,a0,1
  88:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  8a:	00054783          	lbu	a5,0(a0)
  8e:	fbe5                	bnez	a5,7e <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  90:	0005c503          	lbu	a0,0(a1)
}
  94:	40a7853b          	subw	a0,a5,a0
  98:	6422                	ld	s0,8(sp)
  9a:	0141                	addi	sp,sp,16
  9c:	8082                	ret

000000000000009e <strlen>:

uint
strlen(const char *s)
{
  9e:	1141                	addi	sp,sp,-16
  a0:	e422                	sd	s0,8(sp)
  a2:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  a4:	00054783          	lbu	a5,0(a0)
  a8:	cf91                	beqz	a5,c4 <strlen+0x26>
  aa:	0505                	addi	a0,a0,1
  ac:	87aa                	mv	a5,a0
  ae:	4685                	li	a3,1
  b0:	9e89                	subw	a3,a3,a0
  b2:	00f6853b          	addw	a0,a3,a5
  b6:	0785                	addi	a5,a5,1
  b8:	fff7c703          	lbu	a4,-1(a5)
  bc:	fb7d                	bnez	a4,b2 <strlen+0x14>
    ;
  return n;
}
  be:	6422                	ld	s0,8(sp)
  c0:	0141                	addi	sp,sp,16
  c2:	8082                	ret
  for(n = 0; s[n]; n++)
  c4:	4501                	li	a0,0
  c6:	bfe5                	j	be <strlen+0x20>

00000000000000c8 <memset>:

void*
memset(void *dst, int c, uint n)
{
  c8:	1141                	addi	sp,sp,-16
  ca:	e422                	sd	s0,8(sp)
  cc:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  ce:	ca19                	beqz	a2,e4 <memset+0x1c>
  d0:	87aa                	mv	a5,a0
  d2:	1602                	slli	a2,a2,0x20
  d4:	9201                	srli	a2,a2,0x20
  d6:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
  da:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
  de:	0785                	addi	a5,a5,1
  e0:	fee79de3          	bne	a5,a4,da <memset+0x12>
  }
  return dst;
}
  e4:	6422                	ld	s0,8(sp)
  e6:	0141                	addi	sp,sp,16
  e8:	8082                	ret

00000000000000ea <strchr>:

char*
strchr(const char *s, char c)
{
  ea:	1141                	addi	sp,sp,-16
  ec:	e422                	sd	s0,8(sp)
  ee:	0800                	addi	s0,sp,16
  for(; *s; s++)
  f0:	00054783          	lbu	a5,0(a0)
  f4:	cb99                	beqz	a5,10a <strchr+0x20>
    if(*s == c)
  f6:	00f58763          	beq	a1,a5,104 <strchr+0x1a>
  for(; *s; s++)
  fa:	0505                	addi	a0,a0,1
  fc:	00054783          	lbu	a5,0(a0)
 100:	fbfd                	bnez	a5,f6 <strchr+0xc>
      return (char*)s;
  return 0;
 102:	4501                	li	a0,0
}
 104:	6422                	ld	s0,8(sp)
 106:	0141                	addi	sp,sp,16
 108:	8082                	ret
  return 0;
 10a:	4501                	li	a0,0
 10c:	bfe5                	j	104 <strchr+0x1a>

000000000000010e <gets>:

char*
gets(char *buf, int max)
{
 10e:	711d                	addi	sp,sp,-96
 110:	ec86                	sd	ra,88(sp)
 112:	e8a2                	sd	s0,80(sp)
 114:	e4a6                	sd	s1,72(sp)
 116:	e0ca                	sd	s2,64(sp)
 118:	fc4e                	sd	s3,56(sp)
 11a:	f852                	sd	s4,48(sp)
 11c:	f456                	sd	s5,40(sp)
 11e:	f05a                	sd	s6,32(sp)
 120:	ec5e                	sd	s7,24(sp)
 122:	1080                	addi	s0,sp,96
 124:	8baa                	mv	s7,a0
 126:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 128:	892a                	mv	s2,a0
 12a:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 12c:	4aa9                	li	s5,10
 12e:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 130:	89a6                	mv	s3,s1
 132:	2485                	addiw	s1,s1,1
 134:	0344d863          	bge	s1,s4,164 <gets+0x56>
    cc = read(0, &c, 1);
 138:	4605                	li	a2,1
 13a:	faf40593          	addi	a1,s0,-81
 13e:	4501                	li	a0,0
 140:	00000097          	auipc	ra,0x0
 144:	11c080e7          	jalr	284(ra) # 25c <read>
    if(cc < 1)
 148:	00a05e63          	blez	a0,164 <gets+0x56>
    buf[i++] = c;
 14c:	faf44783          	lbu	a5,-81(s0)
 150:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 154:	01578763          	beq	a5,s5,162 <gets+0x54>
 158:	0905                	addi	s2,s2,1
 15a:	fd679be3          	bne	a5,s6,130 <gets+0x22>
  for(i=0; i+1 < max; ){
 15e:	89a6                	mv	s3,s1
 160:	a011                	j	164 <gets+0x56>
 162:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 164:	99de                	add	s3,s3,s7
 166:	00098023          	sb	zero,0(s3)
  return buf;
}
 16a:	855e                	mv	a0,s7
 16c:	60e6                	ld	ra,88(sp)
 16e:	6446                	ld	s0,80(sp)
 170:	64a6                	ld	s1,72(sp)
 172:	6906                	ld	s2,64(sp)
 174:	79e2                	ld	s3,56(sp)
 176:	7a42                	ld	s4,48(sp)
 178:	7aa2                	ld	s5,40(sp)
 17a:	7b02                	ld	s6,32(sp)
 17c:	6be2                	ld	s7,24(sp)
 17e:	6125                	addi	sp,sp,96
 180:	8082                	ret

0000000000000182 <stat>:

int
stat(const char *n, struct stat *st)
{
 182:	1101                	addi	sp,sp,-32
 184:	ec06                	sd	ra,24(sp)
 186:	e822                	sd	s0,16(sp)
 188:	e426                	sd	s1,8(sp)
 18a:	e04a                	sd	s2,0(sp)
 18c:	1000                	addi	s0,sp,32
 18e:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 190:	4581                	li	a1,0
 192:	00000097          	auipc	ra,0x0
 196:	0f2080e7          	jalr	242(ra) # 284 <open>
  if(fd < 0)
 19a:	02054563          	bltz	a0,1c4 <stat+0x42>
 19e:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1a0:	85ca                	mv	a1,s2
 1a2:	00000097          	auipc	ra,0x0
 1a6:	0fa080e7          	jalr	250(ra) # 29c <fstat>
 1aa:	892a                	mv	s2,a0
  close(fd);
 1ac:	8526                	mv	a0,s1
 1ae:	00000097          	auipc	ra,0x0
 1b2:	0be080e7          	jalr	190(ra) # 26c <close>
  return r;
}
 1b6:	854a                	mv	a0,s2
 1b8:	60e2                	ld	ra,24(sp)
 1ba:	6442                	ld	s0,16(sp)
 1bc:	64a2                	ld	s1,8(sp)
 1be:	6902                	ld	s2,0(sp)
 1c0:	6105                	addi	sp,sp,32
 1c2:	8082                	ret
    return -1;
 1c4:	597d                	li	s2,-1
 1c6:	bfc5                	j	1b6 <stat+0x34>

00000000000001c8 <atoi>:

int
atoi(const char *s)
{
 1c8:	1141                	addi	sp,sp,-16
 1ca:	e422                	sd	s0,8(sp)
 1cc:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1ce:	00054603          	lbu	a2,0(a0)
 1d2:	fd06079b          	addiw	a5,a2,-48
 1d6:	0ff7f793          	andi	a5,a5,255
 1da:	4725                	li	a4,9
 1dc:	02f76963          	bltu	a4,a5,20e <atoi+0x46>
 1e0:	86aa                	mv	a3,a0
  n = 0;
 1e2:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 1e4:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 1e6:	0685                	addi	a3,a3,1
 1e8:	0025179b          	slliw	a5,a0,0x2
 1ec:	9fa9                	addw	a5,a5,a0
 1ee:	0017979b          	slliw	a5,a5,0x1
 1f2:	9fb1                	addw	a5,a5,a2
 1f4:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 1f8:	0006c603          	lbu	a2,0(a3)
 1fc:	fd06071b          	addiw	a4,a2,-48
 200:	0ff77713          	andi	a4,a4,255
 204:	fee5f1e3          	bgeu	a1,a4,1e6 <atoi+0x1e>
  return n;
}
 208:	6422                	ld	s0,8(sp)
 20a:	0141                	addi	sp,sp,16
 20c:	8082                	ret
  n = 0;
 20e:	4501                	li	a0,0
 210:	bfe5                	j	208 <atoi+0x40>

0000000000000212 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 212:	1141                	addi	sp,sp,-16
 214:	e422                	sd	s0,8(sp)
 216:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  while(n-- > 0)
 218:	00c05f63          	blez	a2,236 <memmove+0x24>
 21c:	1602                	slli	a2,a2,0x20
 21e:	9201                	srli	a2,a2,0x20
 220:	00c506b3          	add	a3,a0,a2
  dst = vdst;
 224:	87aa                	mv	a5,a0
    *dst++ = *src++;
 226:	0585                	addi	a1,a1,1
 228:	0785                	addi	a5,a5,1
 22a:	fff5c703          	lbu	a4,-1(a1)
 22e:	fee78fa3          	sb	a4,-1(a5)
  while(n-- > 0)
 232:	fed79ae3          	bne	a5,a3,226 <memmove+0x14>
  return vdst;
}
 236:	6422                	ld	s0,8(sp)
 238:	0141                	addi	sp,sp,16
 23a:	8082                	ret

000000000000023c <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 23c:	4885                	li	a7,1
 ecall
 23e:	00000073          	ecall
 ret
 242:	8082                	ret

0000000000000244 <exit>:
.global exit
exit:
 li a7, SYS_exit
 244:	4889                	li	a7,2
 ecall
 246:	00000073          	ecall
 ret
 24a:	8082                	ret

000000000000024c <wait>:
.global wait
wait:
 li a7, SYS_wait
 24c:	488d                	li	a7,3
 ecall
 24e:	00000073          	ecall
 ret
 252:	8082                	ret

0000000000000254 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 254:	4891                	li	a7,4
 ecall
 256:	00000073          	ecall
 ret
 25a:	8082                	ret

000000000000025c <read>:
.global read
read:
 li a7, SYS_read
 25c:	4895                	li	a7,5
 ecall
 25e:	00000073          	ecall
 ret
 262:	8082                	ret

0000000000000264 <write>:
.global write
write:
 li a7, SYS_write
 264:	48c1                	li	a7,16
 ecall
 266:	00000073          	ecall
 ret
 26a:	8082                	ret

000000000000026c <close>:
.global close
close:
 li a7, SYS_close
 26c:	48d5                	li	a7,21
 ecall
 26e:	00000073          	ecall
 ret
 272:	8082                	ret

0000000000000274 <kill>:
.global kill
kill:
 li a7, SYS_kill
 274:	4899                	li	a7,6
 ecall
 276:	00000073          	ecall
 ret
 27a:	8082                	ret

000000000000027c <exec>:
.global exec
exec:
 li a7, SYS_exec
 27c:	489d                	li	a7,7
 ecall
 27e:	00000073          	ecall
 ret
 282:	8082                	ret

0000000000000284 <open>:
.global open
open:
 li a7, SYS_open
 284:	48bd                	li	a7,15
 ecall
 286:	00000073          	ecall
 ret
 28a:	8082                	ret

000000000000028c <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 28c:	48c5                	li	a7,17
 ecall
 28e:	00000073          	ecall
 ret
 292:	8082                	ret

0000000000000294 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 294:	48c9                	li	a7,18
 ecall
 296:	00000073          	ecall
 ret
 29a:	8082                	ret

000000000000029c <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 29c:	48a1                	li	a7,8
 ecall
 29e:	00000073          	ecall
 ret
 2a2:	8082                	ret

00000000000002a4 <link>:
.global link
link:
 li a7, SYS_link
 2a4:	48cd                	li	a7,19
 ecall
 2a6:	00000073          	ecall
 ret
 2aa:	8082                	ret

00000000000002ac <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 2ac:	48d1                	li	a7,20
 ecall
 2ae:	00000073          	ecall
 ret
 2b2:	8082                	ret

00000000000002b4 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 2b4:	48a5                	li	a7,9
 ecall
 2b6:	00000073          	ecall
 ret
 2ba:	8082                	ret

00000000000002bc <dup>:
.global dup
dup:
 li a7, SYS_dup
 2bc:	48a9                	li	a7,10
 ecall
 2be:	00000073          	ecall
 ret
 2c2:	8082                	ret

00000000000002c4 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 2c4:	48ad                	li	a7,11
 ecall
 2c6:	00000073          	ecall
 ret
 2ca:	8082                	ret

00000000000002cc <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 2cc:	48b1                	li	a7,12
 ecall
 2ce:	00000073          	ecall
 ret
 2d2:	8082                	ret

00000000000002d4 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 2d4:	48b5                	li	a7,13
 ecall
 2d6:	00000073          	ecall
 ret
 2da:	8082                	ret

00000000000002dc <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 2dc:	48b9                	li	a7,14
 ecall
 2de:	00000073          	ecall
 ret
 2e2:	8082                	ret

00000000000002e4 <ntas>:
.global ntas
ntas:
 li a7, SYS_ntas
 2e4:	48d9                	li	a7,22
 ecall
 2e6:	00000073          	ecall
 ret
 2ea:	8082                	ret

00000000000002ec <crash>:
.global crash
crash:
 li a7, SYS_crash
 2ec:	48dd                	li	a7,23
 ecall
 2ee:	00000073          	ecall
 ret
 2f2:	8082                	ret

00000000000002f4 <mount>:
.global mount
mount:
 li a7, SYS_mount
 2f4:	48e1                	li	a7,24
 ecall
 2f6:	00000073          	ecall
 ret
 2fa:	8082                	ret

00000000000002fc <umount>:
.global umount
umount:
 li a7, SYS_umount
 2fc:	48e5                	li	a7,25
 ecall
 2fe:	00000073          	ecall
 ret
 302:	8082                	ret

0000000000000304 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 304:	1101                	addi	sp,sp,-32
 306:	ec06                	sd	ra,24(sp)
 308:	e822                	sd	s0,16(sp)
 30a:	1000                	addi	s0,sp,32
 30c:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 310:	4605                	li	a2,1
 312:	fef40593          	addi	a1,s0,-17
 316:	00000097          	auipc	ra,0x0
 31a:	f4e080e7          	jalr	-178(ra) # 264 <write>
}
 31e:	60e2                	ld	ra,24(sp)
 320:	6442                	ld	s0,16(sp)
 322:	6105                	addi	sp,sp,32
 324:	8082                	ret

0000000000000326 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 326:	7139                	addi	sp,sp,-64
 328:	fc06                	sd	ra,56(sp)
 32a:	f822                	sd	s0,48(sp)
 32c:	f426                	sd	s1,40(sp)
 32e:	f04a                	sd	s2,32(sp)
 330:	ec4e                	sd	s3,24(sp)
 332:	0080                	addi	s0,sp,64
 334:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 336:	c299                	beqz	a3,33c <printint+0x16>
 338:	0805c863          	bltz	a1,3c8 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 33c:	2581                	sext.w	a1,a1
  neg = 0;
 33e:	4881                	li	a7,0
 340:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 344:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 346:	2601                	sext.w	a2,a2
 348:	00000517          	auipc	a0,0x0
 34c:	48850513          	addi	a0,a0,1160 # 7d0 <digits>
 350:	883a                	mv	a6,a4
 352:	2705                	addiw	a4,a4,1
 354:	02c5f7bb          	remuw	a5,a1,a2
 358:	1782                	slli	a5,a5,0x20
 35a:	9381                	srli	a5,a5,0x20
 35c:	97aa                	add	a5,a5,a0
 35e:	0007c783          	lbu	a5,0(a5)
 362:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 366:	0005879b          	sext.w	a5,a1
 36a:	02c5d5bb          	divuw	a1,a1,a2
 36e:	0685                	addi	a3,a3,1
 370:	fec7f0e3          	bgeu	a5,a2,350 <printint+0x2a>
  if(neg)
 374:	00088b63          	beqz	a7,38a <printint+0x64>
    buf[i++] = '-';
 378:	fd040793          	addi	a5,s0,-48
 37c:	973e                	add	a4,a4,a5
 37e:	02d00793          	li	a5,45
 382:	fef70823          	sb	a5,-16(a4)
 386:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 38a:	02e05863          	blez	a4,3ba <printint+0x94>
 38e:	fc040793          	addi	a5,s0,-64
 392:	00e78933          	add	s2,a5,a4
 396:	fff78993          	addi	s3,a5,-1
 39a:	99ba                	add	s3,s3,a4
 39c:	377d                	addiw	a4,a4,-1
 39e:	1702                	slli	a4,a4,0x20
 3a0:	9301                	srli	a4,a4,0x20
 3a2:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 3a6:	fff94583          	lbu	a1,-1(s2)
 3aa:	8526                	mv	a0,s1
 3ac:	00000097          	auipc	ra,0x0
 3b0:	f58080e7          	jalr	-168(ra) # 304 <putc>
  while(--i >= 0)
 3b4:	197d                	addi	s2,s2,-1
 3b6:	ff3918e3          	bne	s2,s3,3a6 <printint+0x80>
}
 3ba:	70e2                	ld	ra,56(sp)
 3bc:	7442                	ld	s0,48(sp)
 3be:	74a2                	ld	s1,40(sp)
 3c0:	7902                	ld	s2,32(sp)
 3c2:	69e2                	ld	s3,24(sp)
 3c4:	6121                	addi	sp,sp,64
 3c6:	8082                	ret
    x = -xx;
 3c8:	40b005bb          	negw	a1,a1
    neg = 1;
 3cc:	4885                	li	a7,1
    x = -xx;
 3ce:	bf8d                	j	340 <printint+0x1a>

00000000000003d0 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 3d0:	7119                	addi	sp,sp,-128
 3d2:	fc86                	sd	ra,120(sp)
 3d4:	f8a2                	sd	s0,112(sp)
 3d6:	f4a6                	sd	s1,104(sp)
 3d8:	f0ca                	sd	s2,96(sp)
 3da:	ecce                	sd	s3,88(sp)
 3dc:	e8d2                	sd	s4,80(sp)
 3de:	e4d6                	sd	s5,72(sp)
 3e0:	e0da                	sd	s6,64(sp)
 3e2:	fc5e                	sd	s7,56(sp)
 3e4:	f862                	sd	s8,48(sp)
 3e6:	f466                	sd	s9,40(sp)
 3e8:	f06a                	sd	s10,32(sp)
 3ea:	ec6e                	sd	s11,24(sp)
 3ec:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 3ee:	0005c903          	lbu	s2,0(a1)
 3f2:	18090f63          	beqz	s2,590 <vprintf+0x1c0>
 3f6:	8aaa                	mv	s5,a0
 3f8:	8b32                	mv	s6,a2
 3fa:	00158493          	addi	s1,a1,1
  state = 0;
 3fe:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 400:	02500a13          	li	s4,37
      if(c == 'd'){
 404:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 408:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 40c:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 410:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 414:	00000b97          	auipc	s7,0x0
 418:	3bcb8b93          	addi	s7,s7,956 # 7d0 <digits>
 41c:	a839                	j	43a <vprintf+0x6a>
        putc(fd, c);
 41e:	85ca                	mv	a1,s2
 420:	8556                	mv	a0,s5
 422:	00000097          	auipc	ra,0x0
 426:	ee2080e7          	jalr	-286(ra) # 304 <putc>
 42a:	a019                	j	430 <vprintf+0x60>
    } else if(state == '%'){
 42c:	01498f63          	beq	s3,s4,44a <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 430:	0485                	addi	s1,s1,1
 432:	fff4c903          	lbu	s2,-1(s1)
 436:	14090d63          	beqz	s2,590 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 43a:	0009079b          	sext.w	a5,s2
    if(state == 0){
 43e:	fe0997e3          	bnez	s3,42c <vprintf+0x5c>
      if(c == '%'){
 442:	fd479ee3          	bne	a5,s4,41e <vprintf+0x4e>
        state = '%';
 446:	89be                	mv	s3,a5
 448:	b7e5                	j	430 <vprintf+0x60>
      if(c == 'd'){
 44a:	05878063          	beq	a5,s8,48a <vprintf+0xba>
      } else if(c == 'l') {
 44e:	05978c63          	beq	a5,s9,4a6 <vprintf+0xd6>
      } else if(c == 'x') {
 452:	07a78863          	beq	a5,s10,4c2 <vprintf+0xf2>
      } else if(c == 'p') {
 456:	09b78463          	beq	a5,s11,4de <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 45a:	07300713          	li	a4,115
 45e:	0ce78663          	beq	a5,a4,52a <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 462:	06300713          	li	a4,99
 466:	0ee78e63          	beq	a5,a4,562 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 46a:	11478863          	beq	a5,s4,57a <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 46e:	85d2                	mv	a1,s4
 470:	8556                	mv	a0,s5
 472:	00000097          	auipc	ra,0x0
 476:	e92080e7          	jalr	-366(ra) # 304 <putc>
        putc(fd, c);
 47a:	85ca                	mv	a1,s2
 47c:	8556                	mv	a0,s5
 47e:	00000097          	auipc	ra,0x0
 482:	e86080e7          	jalr	-378(ra) # 304 <putc>
      }
      state = 0;
 486:	4981                	li	s3,0
 488:	b765                	j	430 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 48a:	008b0913          	addi	s2,s6,8
 48e:	4685                	li	a3,1
 490:	4629                	li	a2,10
 492:	000b2583          	lw	a1,0(s6)
 496:	8556                	mv	a0,s5
 498:	00000097          	auipc	ra,0x0
 49c:	e8e080e7          	jalr	-370(ra) # 326 <printint>
 4a0:	8b4a                	mv	s6,s2
      state = 0;
 4a2:	4981                	li	s3,0
 4a4:	b771                	j	430 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 4a6:	008b0913          	addi	s2,s6,8
 4aa:	4681                	li	a3,0
 4ac:	4629                	li	a2,10
 4ae:	000b2583          	lw	a1,0(s6)
 4b2:	8556                	mv	a0,s5
 4b4:	00000097          	auipc	ra,0x0
 4b8:	e72080e7          	jalr	-398(ra) # 326 <printint>
 4bc:	8b4a                	mv	s6,s2
      state = 0;
 4be:	4981                	li	s3,0
 4c0:	bf85                	j	430 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 4c2:	008b0913          	addi	s2,s6,8
 4c6:	4681                	li	a3,0
 4c8:	4641                	li	a2,16
 4ca:	000b2583          	lw	a1,0(s6)
 4ce:	8556                	mv	a0,s5
 4d0:	00000097          	auipc	ra,0x0
 4d4:	e56080e7          	jalr	-426(ra) # 326 <printint>
 4d8:	8b4a                	mv	s6,s2
      state = 0;
 4da:	4981                	li	s3,0
 4dc:	bf91                	j	430 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 4de:	008b0793          	addi	a5,s6,8
 4e2:	f8f43423          	sd	a5,-120(s0)
 4e6:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 4ea:	03000593          	li	a1,48
 4ee:	8556                	mv	a0,s5
 4f0:	00000097          	auipc	ra,0x0
 4f4:	e14080e7          	jalr	-492(ra) # 304 <putc>
  putc(fd, 'x');
 4f8:	85ea                	mv	a1,s10
 4fa:	8556                	mv	a0,s5
 4fc:	00000097          	auipc	ra,0x0
 500:	e08080e7          	jalr	-504(ra) # 304 <putc>
 504:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 506:	03c9d793          	srli	a5,s3,0x3c
 50a:	97de                	add	a5,a5,s7
 50c:	0007c583          	lbu	a1,0(a5)
 510:	8556                	mv	a0,s5
 512:	00000097          	auipc	ra,0x0
 516:	df2080e7          	jalr	-526(ra) # 304 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 51a:	0992                	slli	s3,s3,0x4
 51c:	397d                	addiw	s2,s2,-1
 51e:	fe0914e3          	bnez	s2,506 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 522:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 526:	4981                	li	s3,0
 528:	b721                	j	430 <vprintf+0x60>
        s = va_arg(ap, char*);
 52a:	008b0993          	addi	s3,s6,8
 52e:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 532:	02090163          	beqz	s2,554 <vprintf+0x184>
        while(*s != 0){
 536:	00094583          	lbu	a1,0(s2)
 53a:	c9a1                	beqz	a1,58a <vprintf+0x1ba>
          putc(fd, *s);
 53c:	8556                	mv	a0,s5
 53e:	00000097          	auipc	ra,0x0
 542:	dc6080e7          	jalr	-570(ra) # 304 <putc>
          s++;
 546:	0905                	addi	s2,s2,1
        while(*s != 0){
 548:	00094583          	lbu	a1,0(s2)
 54c:	f9e5                	bnez	a1,53c <vprintf+0x16c>
        s = va_arg(ap, char*);
 54e:	8b4e                	mv	s6,s3
      state = 0;
 550:	4981                	li	s3,0
 552:	bdf9                	j	430 <vprintf+0x60>
          s = "(null)";
 554:	00000917          	auipc	s2,0x0
 558:	27490913          	addi	s2,s2,628 # 7c8 <malloc+0x12e>
        while(*s != 0){
 55c:	02800593          	li	a1,40
 560:	bff1                	j	53c <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 562:	008b0913          	addi	s2,s6,8
 566:	000b4583          	lbu	a1,0(s6)
 56a:	8556                	mv	a0,s5
 56c:	00000097          	auipc	ra,0x0
 570:	d98080e7          	jalr	-616(ra) # 304 <putc>
 574:	8b4a                	mv	s6,s2
      state = 0;
 576:	4981                	li	s3,0
 578:	bd65                	j	430 <vprintf+0x60>
        putc(fd, c);
 57a:	85d2                	mv	a1,s4
 57c:	8556                	mv	a0,s5
 57e:	00000097          	auipc	ra,0x0
 582:	d86080e7          	jalr	-634(ra) # 304 <putc>
      state = 0;
 586:	4981                	li	s3,0
 588:	b565                	j	430 <vprintf+0x60>
        s = va_arg(ap, char*);
 58a:	8b4e                	mv	s6,s3
      state = 0;
 58c:	4981                	li	s3,0
 58e:	b54d                	j	430 <vprintf+0x60>
    }
  }
}
 590:	70e6                	ld	ra,120(sp)
 592:	7446                	ld	s0,112(sp)
 594:	74a6                	ld	s1,104(sp)
 596:	7906                	ld	s2,96(sp)
 598:	69e6                	ld	s3,88(sp)
 59a:	6a46                	ld	s4,80(sp)
 59c:	6aa6                	ld	s5,72(sp)
 59e:	6b06                	ld	s6,64(sp)
 5a0:	7be2                	ld	s7,56(sp)
 5a2:	7c42                	ld	s8,48(sp)
 5a4:	7ca2                	ld	s9,40(sp)
 5a6:	7d02                	ld	s10,32(sp)
 5a8:	6de2                	ld	s11,24(sp)
 5aa:	6109                	addi	sp,sp,128
 5ac:	8082                	ret

00000000000005ae <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 5ae:	715d                	addi	sp,sp,-80
 5b0:	ec06                	sd	ra,24(sp)
 5b2:	e822                	sd	s0,16(sp)
 5b4:	1000                	addi	s0,sp,32
 5b6:	e010                	sd	a2,0(s0)
 5b8:	e414                	sd	a3,8(s0)
 5ba:	e818                	sd	a4,16(s0)
 5bc:	ec1c                	sd	a5,24(s0)
 5be:	03043023          	sd	a6,32(s0)
 5c2:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 5c6:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 5ca:	8622                	mv	a2,s0
 5cc:	00000097          	auipc	ra,0x0
 5d0:	e04080e7          	jalr	-508(ra) # 3d0 <vprintf>
}
 5d4:	60e2                	ld	ra,24(sp)
 5d6:	6442                	ld	s0,16(sp)
 5d8:	6161                	addi	sp,sp,80
 5da:	8082                	ret

00000000000005dc <printf>:

void
printf(const char *fmt, ...)
{
 5dc:	711d                	addi	sp,sp,-96
 5de:	ec06                	sd	ra,24(sp)
 5e0:	e822                	sd	s0,16(sp)
 5e2:	1000                	addi	s0,sp,32
 5e4:	e40c                	sd	a1,8(s0)
 5e6:	e810                	sd	a2,16(s0)
 5e8:	ec14                	sd	a3,24(s0)
 5ea:	f018                	sd	a4,32(s0)
 5ec:	f41c                	sd	a5,40(s0)
 5ee:	03043823          	sd	a6,48(s0)
 5f2:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 5f6:	00840613          	addi	a2,s0,8
 5fa:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 5fe:	85aa                	mv	a1,a0
 600:	4505                	li	a0,1
 602:	00000097          	auipc	ra,0x0
 606:	dce080e7          	jalr	-562(ra) # 3d0 <vprintf>
}
 60a:	60e2                	ld	ra,24(sp)
 60c:	6442                	ld	s0,16(sp)
 60e:	6125                	addi	sp,sp,96
 610:	8082                	ret

0000000000000612 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 612:	1141                	addi	sp,sp,-16
 614:	e422                	sd	s0,8(sp)
 616:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 618:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 61c:	00000797          	auipc	a5,0x0
 620:	1cc7b783          	ld	a5,460(a5) # 7e8 <freep>
 624:	a805                	j	654 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 626:	4618                	lw	a4,8(a2)
 628:	9db9                	addw	a1,a1,a4
 62a:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 62e:	6398                	ld	a4,0(a5)
 630:	6318                	ld	a4,0(a4)
 632:	fee53823          	sd	a4,-16(a0)
 636:	a091                	j	67a <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 638:	ff852703          	lw	a4,-8(a0)
 63c:	9e39                	addw	a2,a2,a4
 63e:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 640:	ff053703          	ld	a4,-16(a0)
 644:	e398                	sd	a4,0(a5)
 646:	a099                	j	68c <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 648:	6398                	ld	a4,0(a5)
 64a:	00e7e463          	bltu	a5,a4,652 <free+0x40>
 64e:	00e6ea63          	bltu	a3,a4,662 <free+0x50>
{
 652:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 654:	fed7fae3          	bgeu	a5,a3,648 <free+0x36>
 658:	6398                	ld	a4,0(a5)
 65a:	00e6e463          	bltu	a3,a4,662 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 65e:	fee7eae3          	bltu	a5,a4,652 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 662:	ff852583          	lw	a1,-8(a0)
 666:	6390                	ld	a2,0(a5)
 668:	02059813          	slli	a6,a1,0x20
 66c:	01c85713          	srli	a4,a6,0x1c
 670:	9736                	add	a4,a4,a3
 672:	fae60ae3          	beq	a2,a4,626 <free+0x14>
    bp->s.ptr = p->s.ptr;
 676:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 67a:	4790                	lw	a2,8(a5)
 67c:	02061593          	slli	a1,a2,0x20
 680:	01c5d713          	srli	a4,a1,0x1c
 684:	973e                	add	a4,a4,a5
 686:	fae689e3          	beq	a3,a4,638 <free+0x26>
  } else
    p->s.ptr = bp;
 68a:	e394                	sd	a3,0(a5)
  freep = p;
 68c:	00000717          	auipc	a4,0x0
 690:	14f73e23          	sd	a5,348(a4) # 7e8 <freep>
}
 694:	6422                	ld	s0,8(sp)
 696:	0141                	addi	sp,sp,16
 698:	8082                	ret

000000000000069a <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 69a:	7139                	addi	sp,sp,-64
 69c:	fc06                	sd	ra,56(sp)
 69e:	f822                	sd	s0,48(sp)
 6a0:	f426                	sd	s1,40(sp)
 6a2:	f04a                	sd	s2,32(sp)
 6a4:	ec4e                	sd	s3,24(sp)
 6a6:	e852                	sd	s4,16(sp)
 6a8:	e456                	sd	s5,8(sp)
 6aa:	e05a                	sd	s6,0(sp)
 6ac:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 6ae:	02051493          	slli	s1,a0,0x20
 6b2:	9081                	srli	s1,s1,0x20
 6b4:	04bd                	addi	s1,s1,15
 6b6:	8091                	srli	s1,s1,0x4
 6b8:	0014899b          	addiw	s3,s1,1
 6bc:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 6be:	00000517          	auipc	a0,0x0
 6c2:	12a53503          	ld	a0,298(a0) # 7e8 <freep>
 6c6:	c515                	beqz	a0,6f2 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 6c8:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 6ca:	4798                	lw	a4,8(a5)
 6cc:	02977f63          	bgeu	a4,s1,70a <malloc+0x70>
 6d0:	8a4e                	mv	s4,s3
 6d2:	0009871b          	sext.w	a4,s3
 6d6:	6685                	lui	a3,0x1
 6d8:	00d77363          	bgeu	a4,a3,6de <malloc+0x44>
 6dc:	6a05                	lui	s4,0x1
 6de:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 6e2:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 6e6:	00000917          	auipc	s2,0x0
 6ea:	10290913          	addi	s2,s2,258 # 7e8 <freep>
  if(p == (char*)-1)
 6ee:	5afd                	li	s5,-1
 6f0:	a895                	j	764 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 6f2:	00000797          	auipc	a5,0x0
 6f6:	0fe78793          	addi	a5,a5,254 # 7f0 <base>
 6fa:	00000717          	auipc	a4,0x0
 6fe:	0ef73723          	sd	a5,238(a4) # 7e8 <freep>
 702:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 704:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 708:	b7e1                	j	6d0 <malloc+0x36>
      if(p->s.size == nunits)
 70a:	02e48c63          	beq	s1,a4,742 <malloc+0xa8>
        p->s.size -= nunits;
 70e:	4137073b          	subw	a4,a4,s3
 712:	c798                	sw	a4,8(a5)
        p += p->s.size;
 714:	02071693          	slli	a3,a4,0x20
 718:	01c6d713          	srli	a4,a3,0x1c
 71c:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 71e:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 722:	00000717          	auipc	a4,0x0
 726:	0ca73323          	sd	a0,198(a4) # 7e8 <freep>
      return (void*)(p + 1);
 72a:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 72e:	70e2                	ld	ra,56(sp)
 730:	7442                	ld	s0,48(sp)
 732:	74a2                	ld	s1,40(sp)
 734:	7902                	ld	s2,32(sp)
 736:	69e2                	ld	s3,24(sp)
 738:	6a42                	ld	s4,16(sp)
 73a:	6aa2                	ld	s5,8(sp)
 73c:	6b02                	ld	s6,0(sp)
 73e:	6121                	addi	sp,sp,64
 740:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 742:	6398                	ld	a4,0(a5)
 744:	e118                	sd	a4,0(a0)
 746:	bff1                	j	722 <malloc+0x88>
  hp->s.size = nu;
 748:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 74c:	0541                	addi	a0,a0,16
 74e:	00000097          	auipc	ra,0x0
 752:	ec4080e7          	jalr	-316(ra) # 612 <free>
  return freep;
 756:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 75a:	d971                	beqz	a0,72e <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 75c:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 75e:	4798                	lw	a4,8(a5)
 760:	fa9775e3          	bgeu	a4,s1,70a <malloc+0x70>
    if(p == freep)
 764:	00093703          	ld	a4,0(s2)
 768:	853e                	mv	a0,a5
 76a:	fef719e3          	bne	a4,a5,75c <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 76e:	8552                	mv	a0,s4
 770:	00000097          	auipc	ra,0x0
 774:	b5c080e7          	jalr	-1188(ra) # 2cc <sbrk>
  if(p == (char*)-1)
 778:	fd5518e3          	bne	a0,s5,748 <malloc+0xae>
        return 0;
 77c:	4501                	li	a0,0
 77e:	bf45                	j	72e <malloc+0x94>

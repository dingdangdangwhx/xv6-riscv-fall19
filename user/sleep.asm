
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
   c:	00f50f63          	beq	a0,a5,2a <main+0x2a>
		fprintf(2, "must 1 argument for sleep\n");
  10:	00000597          	auipc	a1,0x0
  14:	77858593          	addi	a1,a1,1912 # 788 <malloc+0xec>
  18:	4509                	li	a0,2
  1a:	00000097          	auipc	ra,0x0
  1e:	596080e7          	jalr	1430(ra) # 5b0 <fprintf>
		exit();
  22:	00000097          	auipc	ra,0x0
  26:	224080e7          	jalr	548(ra) # 246 <exit>
	}
	int sleepNum = atoi(argv[1]);
  2a:	6588                	ld	a0,8(a1)
  2c:	00000097          	auipc	ra,0x0
  30:	19e080e7          	jalr	414(ra) # 1ca <atoi>
  34:	84aa                	mv	s1,a0
	printf("(nothing happens for a little while)\n");
  36:	00000517          	auipc	a0,0x0
  3a:	77250513          	addi	a0,a0,1906 # 7a8 <malloc+0x10c>
  3e:	00000097          	auipc	ra,0x0
  42:	5a0080e7          	jalr	1440(ra) # 5de <printf>
	sleep(sleepNum);
  46:	8526                	mv	a0,s1
  48:	00000097          	auipc	ra,0x0
  4c:	28e080e7          	jalr	654(ra) # 2d6 <sleep>
	exit();
  50:	00000097          	auipc	ra,0x0
  54:	1f6080e7          	jalr	502(ra) # 246 <exit>

0000000000000058 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  58:	1141                	addi	sp,sp,-16
  5a:	e422                	sd	s0,8(sp)
  5c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  5e:	87aa                	mv	a5,a0
  60:	0585                	addi	a1,a1,1
  62:	0785                	addi	a5,a5,1
  64:	fff5c703          	lbu	a4,-1(a1)
  68:	fee78fa3          	sb	a4,-1(a5)
  6c:	fb75                	bnez	a4,60 <strcpy+0x8>
    ;
  return os;
}
  6e:	6422                	ld	s0,8(sp)
  70:	0141                	addi	sp,sp,16
  72:	8082                	ret

0000000000000074 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  74:	1141                	addi	sp,sp,-16
  76:	e422                	sd	s0,8(sp)
  78:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  7a:	00054783          	lbu	a5,0(a0)
  7e:	cb91                	beqz	a5,92 <strcmp+0x1e>
  80:	0005c703          	lbu	a4,0(a1)
  84:	00f71763          	bne	a4,a5,92 <strcmp+0x1e>
    p++, q++;
  88:	0505                	addi	a0,a0,1
  8a:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  8c:	00054783          	lbu	a5,0(a0)
  90:	fbe5                	bnez	a5,80 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  92:	0005c503          	lbu	a0,0(a1)
}
  96:	40a7853b          	subw	a0,a5,a0
  9a:	6422                	ld	s0,8(sp)
  9c:	0141                	addi	sp,sp,16
  9e:	8082                	ret

00000000000000a0 <strlen>:

uint
strlen(const char *s)
{
  a0:	1141                	addi	sp,sp,-16
  a2:	e422                	sd	s0,8(sp)
  a4:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  a6:	00054783          	lbu	a5,0(a0)
  aa:	cf91                	beqz	a5,c6 <strlen+0x26>
  ac:	0505                	addi	a0,a0,1
  ae:	87aa                	mv	a5,a0
  b0:	4685                	li	a3,1
  b2:	9e89                	subw	a3,a3,a0
  b4:	00f6853b          	addw	a0,a3,a5
  b8:	0785                	addi	a5,a5,1
  ba:	fff7c703          	lbu	a4,-1(a5)
  be:	fb7d                	bnez	a4,b4 <strlen+0x14>
    ;
  return n;
}
  c0:	6422                	ld	s0,8(sp)
  c2:	0141                	addi	sp,sp,16
  c4:	8082                	ret
  for(n = 0; s[n]; n++)
  c6:	4501                	li	a0,0
  c8:	bfe5                	j	c0 <strlen+0x20>

00000000000000ca <memset>:

void*
memset(void *dst, int c, uint n)
{
  ca:	1141                	addi	sp,sp,-16
  cc:	e422                	sd	s0,8(sp)
  ce:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  d0:	ca19                	beqz	a2,e6 <memset+0x1c>
  d2:	87aa                	mv	a5,a0
  d4:	1602                	slli	a2,a2,0x20
  d6:	9201                	srli	a2,a2,0x20
  d8:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
  dc:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
  e0:	0785                	addi	a5,a5,1
  e2:	fee79de3          	bne	a5,a4,dc <memset+0x12>
  }
  return dst;
}
  e6:	6422                	ld	s0,8(sp)
  e8:	0141                	addi	sp,sp,16
  ea:	8082                	ret

00000000000000ec <strchr>:

char*
strchr(const char *s, char c)
{
  ec:	1141                	addi	sp,sp,-16
  ee:	e422                	sd	s0,8(sp)
  f0:	0800                	addi	s0,sp,16
  for(; *s; s++)
  f2:	00054783          	lbu	a5,0(a0)
  f6:	cb99                	beqz	a5,10c <strchr+0x20>
    if(*s == c)
  f8:	00f58763          	beq	a1,a5,106 <strchr+0x1a>
  for(; *s; s++)
  fc:	0505                	addi	a0,a0,1
  fe:	00054783          	lbu	a5,0(a0)
 102:	fbfd                	bnez	a5,f8 <strchr+0xc>
      return (char*)s;
  return 0;
 104:	4501                	li	a0,0
}
 106:	6422                	ld	s0,8(sp)
 108:	0141                	addi	sp,sp,16
 10a:	8082                	ret
  return 0;
 10c:	4501                	li	a0,0
 10e:	bfe5                	j	106 <strchr+0x1a>

0000000000000110 <gets>:

char*
gets(char *buf, int max)
{
 110:	711d                	addi	sp,sp,-96
 112:	ec86                	sd	ra,88(sp)
 114:	e8a2                	sd	s0,80(sp)
 116:	e4a6                	sd	s1,72(sp)
 118:	e0ca                	sd	s2,64(sp)
 11a:	fc4e                	sd	s3,56(sp)
 11c:	f852                	sd	s4,48(sp)
 11e:	f456                	sd	s5,40(sp)
 120:	f05a                	sd	s6,32(sp)
 122:	ec5e                	sd	s7,24(sp)
 124:	1080                	addi	s0,sp,96
 126:	8baa                	mv	s7,a0
 128:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 12a:	892a                	mv	s2,a0
 12c:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 12e:	4aa9                	li	s5,10
 130:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 132:	89a6                	mv	s3,s1
 134:	2485                	addiw	s1,s1,1
 136:	0344d863          	bge	s1,s4,166 <gets+0x56>
    cc = read(0, &c, 1);
 13a:	4605                	li	a2,1
 13c:	faf40593          	addi	a1,s0,-81
 140:	4501                	li	a0,0
 142:	00000097          	auipc	ra,0x0
 146:	11c080e7          	jalr	284(ra) # 25e <read>
    if(cc < 1)
 14a:	00a05e63          	blez	a0,166 <gets+0x56>
    buf[i++] = c;
 14e:	faf44783          	lbu	a5,-81(s0)
 152:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 156:	01578763          	beq	a5,s5,164 <gets+0x54>
 15a:	0905                	addi	s2,s2,1
 15c:	fd679be3          	bne	a5,s6,132 <gets+0x22>
  for(i=0; i+1 < max; ){
 160:	89a6                	mv	s3,s1
 162:	a011                	j	166 <gets+0x56>
 164:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 166:	99de                	add	s3,s3,s7
 168:	00098023          	sb	zero,0(s3)
  return buf;
}
 16c:	855e                	mv	a0,s7
 16e:	60e6                	ld	ra,88(sp)
 170:	6446                	ld	s0,80(sp)
 172:	64a6                	ld	s1,72(sp)
 174:	6906                	ld	s2,64(sp)
 176:	79e2                	ld	s3,56(sp)
 178:	7a42                	ld	s4,48(sp)
 17a:	7aa2                	ld	s5,40(sp)
 17c:	7b02                	ld	s6,32(sp)
 17e:	6be2                	ld	s7,24(sp)
 180:	6125                	addi	sp,sp,96
 182:	8082                	ret

0000000000000184 <stat>:

int
stat(const char *n, struct stat *st)
{
 184:	1101                	addi	sp,sp,-32
 186:	ec06                	sd	ra,24(sp)
 188:	e822                	sd	s0,16(sp)
 18a:	e426                	sd	s1,8(sp)
 18c:	e04a                	sd	s2,0(sp)
 18e:	1000                	addi	s0,sp,32
 190:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 192:	4581                	li	a1,0
 194:	00000097          	auipc	ra,0x0
 198:	0f2080e7          	jalr	242(ra) # 286 <open>
  if(fd < 0)
 19c:	02054563          	bltz	a0,1c6 <stat+0x42>
 1a0:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1a2:	85ca                	mv	a1,s2
 1a4:	00000097          	auipc	ra,0x0
 1a8:	0fa080e7          	jalr	250(ra) # 29e <fstat>
 1ac:	892a                	mv	s2,a0
  close(fd);
 1ae:	8526                	mv	a0,s1
 1b0:	00000097          	auipc	ra,0x0
 1b4:	0be080e7          	jalr	190(ra) # 26e <close>
  return r;
}
 1b8:	854a                	mv	a0,s2
 1ba:	60e2                	ld	ra,24(sp)
 1bc:	6442                	ld	s0,16(sp)
 1be:	64a2                	ld	s1,8(sp)
 1c0:	6902                	ld	s2,0(sp)
 1c2:	6105                	addi	sp,sp,32
 1c4:	8082                	ret
    return -1;
 1c6:	597d                	li	s2,-1
 1c8:	bfc5                	j	1b8 <stat+0x34>

00000000000001ca <atoi>:

int
atoi(const char *s)
{
 1ca:	1141                	addi	sp,sp,-16
 1cc:	e422                	sd	s0,8(sp)
 1ce:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1d0:	00054603          	lbu	a2,0(a0)
 1d4:	fd06079b          	addiw	a5,a2,-48
 1d8:	0ff7f793          	andi	a5,a5,255
 1dc:	4725                	li	a4,9
 1de:	02f76963          	bltu	a4,a5,210 <atoi+0x46>
 1e2:	86aa                	mv	a3,a0
  n = 0;
 1e4:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 1e6:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 1e8:	0685                	addi	a3,a3,1
 1ea:	0025179b          	slliw	a5,a0,0x2
 1ee:	9fa9                	addw	a5,a5,a0
 1f0:	0017979b          	slliw	a5,a5,0x1
 1f4:	9fb1                	addw	a5,a5,a2
 1f6:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 1fa:	0006c603          	lbu	a2,0(a3)
 1fe:	fd06071b          	addiw	a4,a2,-48
 202:	0ff77713          	andi	a4,a4,255
 206:	fee5f1e3          	bgeu	a1,a4,1e8 <atoi+0x1e>
  return n;
}
 20a:	6422                	ld	s0,8(sp)
 20c:	0141                	addi	sp,sp,16
 20e:	8082                	ret
  n = 0;
 210:	4501                	li	a0,0
 212:	bfe5                	j	20a <atoi+0x40>

0000000000000214 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 214:	1141                	addi	sp,sp,-16
 216:	e422                	sd	s0,8(sp)
 218:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  while(n-- > 0)
 21a:	00c05f63          	blez	a2,238 <memmove+0x24>
 21e:	1602                	slli	a2,a2,0x20
 220:	9201                	srli	a2,a2,0x20
 222:	00c506b3          	add	a3,a0,a2
  dst = vdst;
 226:	87aa                	mv	a5,a0
    *dst++ = *src++;
 228:	0585                	addi	a1,a1,1
 22a:	0785                	addi	a5,a5,1
 22c:	fff5c703          	lbu	a4,-1(a1)
 230:	fee78fa3          	sb	a4,-1(a5)
  while(n-- > 0)
 234:	fed79ae3          	bne	a5,a3,228 <memmove+0x14>
  return vdst;
}
 238:	6422                	ld	s0,8(sp)
 23a:	0141                	addi	sp,sp,16
 23c:	8082                	ret

000000000000023e <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 23e:	4885                	li	a7,1
 ecall
 240:	00000073          	ecall
 ret
 244:	8082                	ret

0000000000000246 <exit>:
.global exit
exit:
 li a7, SYS_exit
 246:	4889                	li	a7,2
 ecall
 248:	00000073          	ecall
 ret
 24c:	8082                	ret

000000000000024e <wait>:
.global wait
wait:
 li a7, SYS_wait
 24e:	488d                	li	a7,3
 ecall
 250:	00000073          	ecall
 ret
 254:	8082                	ret

0000000000000256 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 256:	4891                	li	a7,4
 ecall
 258:	00000073          	ecall
 ret
 25c:	8082                	ret

000000000000025e <read>:
.global read
read:
 li a7, SYS_read
 25e:	4895                	li	a7,5
 ecall
 260:	00000073          	ecall
 ret
 264:	8082                	ret

0000000000000266 <write>:
.global write
write:
 li a7, SYS_write
 266:	48c1                	li	a7,16
 ecall
 268:	00000073          	ecall
 ret
 26c:	8082                	ret

000000000000026e <close>:
.global close
close:
 li a7, SYS_close
 26e:	48d5                	li	a7,21
 ecall
 270:	00000073          	ecall
 ret
 274:	8082                	ret

0000000000000276 <kill>:
.global kill
kill:
 li a7, SYS_kill
 276:	4899                	li	a7,6
 ecall
 278:	00000073          	ecall
 ret
 27c:	8082                	ret

000000000000027e <exec>:
.global exec
exec:
 li a7, SYS_exec
 27e:	489d                	li	a7,7
 ecall
 280:	00000073          	ecall
 ret
 284:	8082                	ret

0000000000000286 <open>:
.global open
open:
 li a7, SYS_open
 286:	48bd                	li	a7,15
 ecall
 288:	00000073          	ecall
 ret
 28c:	8082                	ret

000000000000028e <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 28e:	48c5                	li	a7,17
 ecall
 290:	00000073          	ecall
 ret
 294:	8082                	ret

0000000000000296 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 296:	48c9                	li	a7,18
 ecall
 298:	00000073          	ecall
 ret
 29c:	8082                	ret

000000000000029e <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 29e:	48a1                	li	a7,8
 ecall
 2a0:	00000073          	ecall
 ret
 2a4:	8082                	ret

00000000000002a6 <link>:
.global link
link:
 li a7, SYS_link
 2a6:	48cd                	li	a7,19
 ecall
 2a8:	00000073          	ecall
 ret
 2ac:	8082                	ret

00000000000002ae <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 2ae:	48d1                	li	a7,20
 ecall
 2b0:	00000073          	ecall
 ret
 2b4:	8082                	ret

00000000000002b6 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 2b6:	48a5                	li	a7,9
 ecall
 2b8:	00000073          	ecall
 ret
 2bc:	8082                	ret

00000000000002be <dup>:
.global dup
dup:
 li a7, SYS_dup
 2be:	48a9                	li	a7,10
 ecall
 2c0:	00000073          	ecall
 ret
 2c4:	8082                	ret

00000000000002c6 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 2c6:	48ad                	li	a7,11
 ecall
 2c8:	00000073          	ecall
 ret
 2cc:	8082                	ret

00000000000002ce <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 2ce:	48b1                	li	a7,12
 ecall
 2d0:	00000073          	ecall
 ret
 2d4:	8082                	ret

00000000000002d6 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 2d6:	48b5                	li	a7,13
 ecall
 2d8:	00000073          	ecall
 ret
 2dc:	8082                	ret

00000000000002de <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 2de:	48b9                	li	a7,14
 ecall
 2e0:	00000073          	ecall
 ret
 2e4:	8082                	ret

00000000000002e6 <ntas>:
.global ntas
ntas:
 li a7, SYS_ntas
 2e6:	48d9                	li	a7,22
 ecall
 2e8:	00000073          	ecall
 ret
 2ec:	8082                	ret

00000000000002ee <crash>:
.global crash
crash:
 li a7, SYS_crash
 2ee:	48dd                	li	a7,23
 ecall
 2f0:	00000073          	ecall
 ret
 2f4:	8082                	ret

00000000000002f6 <mount>:
.global mount
mount:
 li a7, SYS_mount
 2f6:	48e1                	li	a7,24
 ecall
 2f8:	00000073          	ecall
 ret
 2fc:	8082                	ret

00000000000002fe <umount>:
.global umount
umount:
 li a7, SYS_umount
 2fe:	48e5                	li	a7,25
 ecall
 300:	00000073          	ecall
 ret
 304:	8082                	ret

0000000000000306 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 306:	1101                	addi	sp,sp,-32
 308:	ec06                	sd	ra,24(sp)
 30a:	e822                	sd	s0,16(sp)
 30c:	1000                	addi	s0,sp,32
 30e:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 312:	4605                	li	a2,1
 314:	fef40593          	addi	a1,s0,-17
 318:	00000097          	auipc	ra,0x0
 31c:	f4e080e7          	jalr	-178(ra) # 266 <write>
}
 320:	60e2                	ld	ra,24(sp)
 322:	6442                	ld	s0,16(sp)
 324:	6105                	addi	sp,sp,32
 326:	8082                	ret

0000000000000328 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 328:	7139                	addi	sp,sp,-64
 32a:	fc06                	sd	ra,56(sp)
 32c:	f822                	sd	s0,48(sp)
 32e:	f426                	sd	s1,40(sp)
 330:	f04a                	sd	s2,32(sp)
 332:	ec4e                	sd	s3,24(sp)
 334:	0080                	addi	s0,sp,64
 336:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 338:	c299                	beqz	a3,33e <printint+0x16>
 33a:	0805c863          	bltz	a1,3ca <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 33e:	2581                	sext.w	a1,a1
  neg = 0;
 340:	4881                	li	a7,0
 342:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 346:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 348:	2601                	sext.w	a2,a2
 34a:	00000517          	auipc	a0,0x0
 34e:	48e50513          	addi	a0,a0,1166 # 7d8 <digits>
 352:	883a                	mv	a6,a4
 354:	2705                	addiw	a4,a4,1
 356:	02c5f7bb          	remuw	a5,a1,a2
 35a:	1782                	slli	a5,a5,0x20
 35c:	9381                	srli	a5,a5,0x20
 35e:	97aa                	add	a5,a5,a0
 360:	0007c783          	lbu	a5,0(a5)
 364:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 368:	0005879b          	sext.w	a5,a1
 36c:	02c5d5bb          	divuw	a1,a1,a2
 370:	0685                	addi	a3,a3,1
 372:	fec7f0e3          	bgeu	a5,a2,352 <printint+0x2a>
  if(neg)
 376:	00088b63          	beqz	a7,38c <printint+0x64>
    buf[i++] = '-';
 37a:	fd040793          	addi	a5,s0,-48
 37e:	973e                	add	a4,a4,a5
 380:	02d00793          	li	a5,45
 384:	fef70823          	sb	a5,-16(a4)
 388:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 38c:	02e05863          	blez	a4,3bc <printint+0x94>
 390:	fc040793          	addi	a5,s0,-64
 394:	00e78933          	add	s2,a5,a4
 398:	fff78993          	addi	s3,a5,-1
 39c:	99ba                	add	s3,s3,a4
 39e:	377d                	addiw	a4,a4,-1
 3a0:	1702                	slli	a4,a4,0x20
 3a2:	9301                	srli	a4,a4,0x20
 3a4:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 3a8:	fff94583          	lbu	a1,-1(s2)
 3ac:	8526                	mv	a0,s1
 3ae:	00000097          	auipc	ra,0x0
 3b2:	f58080e7          	jalr	-168(ra) # 306 <putc>
  while(--i >= 0)
 3b6:	197d                	addi	s2,s2,-1
 3b8:	ff3918e3          	bne	s2,s3,3a8 <printint+0x80>
}
 3bc:	70e2                	ld	ra,56(sp)
 3be:	7442                	ld	s0,48(sp)
 3c0:	74a2                	ld	s1,40(sp)
 3c2:	7902                	ld	s2,32(sp)
 3c4:	69e2                	ld	s3,24(sp)
 3c6:	6121                	addi	sp,sp,64
 3c8:	8082                	ret
    x = -xx;
 3ca:	40b005bb          	negw	a1,a1
    neg = 1;
 3ce:	4885                	li	a7,1
    x = -xx;
 3d0:	bf8d                	j	342 <printint+0x1a>

00000000000003d2 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 3d2:	7119                	addi	sp,sp,-128
 3d4:	fc86                	sd	ra,120(sp)
 3d6:	f8a2                	sd	s0,112(sp)
 3d8:	f4a6                	sd	s1,104(sp)
 3da:	f0ca                	sd	s2,96(sp)
 3dc:	ecce                	sd	s3,88(sp)
 3de:	e8d2                	sd	s4,80(sp)
 3e0:	e4d6                	sd	s5,72(sp)
 3e2:	e0da                	sd	s6,64(sp)
 3e4:	fc5e                	sd	s7,56(sp)
 3e6:	f862                	sd	s8,48(sp)
 3e8:	f466                	sd	s9,40(sp)
 3ea:	f06a                	sd	s10,32(sp)
 3ec:	ec6e                	sd	s11,24(sp)
 3ee:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 3f0:	0005c903          	lbu	s2,0(a1)
 3f4:	18090f63          	beqz	s2,592 <vprintf+0x1c0>
 3f8:	8aaa                	mv	s5,a0
 3fa:	8b32                	mv	s6,a2
 3fc:	00158493          	addi	s1,a1,1
  state = 0;
 400:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 402:	02500a13          	li	s4,37
      if(c == 'd'){
 406:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 40a:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 40e:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 412:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 416:	00000b97          	auipc	s7,0x0
 41a:	3c2b8b93          	addi	s7,s7,962 # 7d8 <digits>
 41e:	a839                	j	43c <vprintf+0x6a>
        putc(fd, c);
 420:	85ca                	mv	a1,s2
 422:	8556                	mv	a0,s5
 424:	00000097          	auipc	ra,0x0
 428:	ee2080e7          	jalr	-286(ra) # 306 <putc>
 42c:	a019                	j	432 <vprintf+0x60>
    } else if(state == '%'){
 42e:	01498f63          	beq	s3,s4,44c <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 432:	0485                	addi	s1,s1,1
 434:	fff4c903          	lbu	s2,-1(s1)
 438:	14090d63          	beqz	s2,592 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 43c:	0009079b          	sext.w	a5,s2
    if(state == 0){
 440:	fe0997e3          	bnez	s3,42e <vprintf+0x5c>
      if(c == '%'){
 444:	fd479ee3          	bne	a5,s4,420 <vprintf+0x4e>
        state = '%';
 448:	89be                	mv	s3,a5
 44a:	b7e5                	j	432 <vprintf+0x60>
      if(c == 'd'){
 44c:	05878063          	beq	a5,s8,48c <vprintf+0xba>
      } else if(c == 'l') {
 450:	05978c63          	beq	a5,s9,4a8 <vprintf+0xd6>
      } else if(c == 'x') {
 454:	07a78863          	beq	a5,s10,4c4 <vprintf+0xf2>
      } else if(c == 'p') {
 458:	09b78463          	beq	a5,s11,4e0 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 45c:	07300713          	li	a4,115
 460:	0ce78663          	beq	a5,a4,52c <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 464:	06300713          	li	a4,99
 468:	0ee78e63          	beq	a5,a4,564 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 46c:	11478863          	beq	a5,s4,57c <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 470:	85d2                	mv	a1,s4
 472:	8556                	mv	a0,s5
 474:	00000097          	auipc	ra,0x0
 478:	e92080e7          	jalr	-366(ra) # 306 <putc>
        putc(fd, c);
 47c:	85ca                	mv	a1,s2
 47e:	8556                	mv	a0,s5
 480:	00000097          	auipc	ra,0x0
 484:	e86080e7          	jalr	-378(ra) # 306 <putc>
      }
      state = 0;
 488:	4981                	li	s3,0
 48a:	b765                	j	432 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 48c:	008b0913          	addi	s2,s6,8
 490:	4685                	li	a3,1
 492:	4629                	li	a2,10
 494:	000b2583          	lw	a1,0(s6)
 498:	8556                	mv	a0,s5
 49a:	00000097          	auipc	ra,0x0
 49e:	e8e080e7          	jalr	-370(ra) # 328 <printint>
 4a2:	8b4a                	mv	s6,s2
      state = 0;
 4a4:	4981                	li	s3,0
 4a6:	b771                	j	432 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 4a8:	008b0913          	addi	s2,s6,8
 4ac:	4681                	li	a3,0
 4ae:	4629                	li	a2,10
 4b0:	000b2583          	lw	a1,0(s6)
 4b4:	8556                	mv	a0,s5
 4b6:	00000097          	auipc	ra,0x0
 4ba:	e72080e7          	jalr	-398(ra) # 328 <printint>
 4be:	8b4a                	mv	s6,s2
      state = 0;
 4c0:	4981                	li	s3,0
 4c2:	bf85                	j	432 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 4c4:	008b0913          	addi	s2,s6,8
 4c8:	4681                	li	a3,0
 4ca:	4641                	li	a2,16
 4cc:	000b2583          	lw	a1,0(s6)
 4d0:	8556                	mv	a0,s5
 4d2:	00000097          	auipc	ra,0x0
 4d6:	e56080e7          	jalr	-426(ra) # 328 <printint>
 4da:	8b4a                	mv	s6,s2
      state = 0;
 4dc:	4981                	li	s3,0
 4de:	bf91                	j	432 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 4e0:	008b0793          	addi	a5,s6,8
 4e4:	f8f43423          	sd	a5,-120(s0)
 4e8:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 4ec:	03000593          	li	a1,48
 4f0:	8556                	mv	a0,s5
 4f2:	00000097          	auipc	ra,0x0
 4f6:	e14080e7          	jalr	-492(ra) # 306 <putc>
  putc(fd, 'x');
 4fa:	85ea                	mv	a1,s10
 4fc:	8556                	mv	a0,s5
 4fe:	00000097          	auipc	ra,0x0
 502:	e08080e7          	jalr	-504(ra) # 306 <putc>
 506:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 508:	03c9d793          	srli	a5,s3,0x3c
 50c:	97de                	add	a5,a5,s7
 50e:	0007c583          	lbu	a1,0(a5)
 512:	8556                	mv	a0,s5
 514:	00000097          	auipc	ra,0x0
 518:	df2080e7          	jalr	-526(ra) # 306 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 51c:	0992                	slli	s3,s3,0x4
 51e:	397d                	addiw	s2,s2,-1
 520:	fe0914e3          	bnez	s2,508 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 524:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 528:	4981                	li	s3,0
 52a:	b721                	j	432 <vprintf+0x60>
        s = va_arg(ap, char*);
 52c:	008b0993          	addi	s3,s6,8
 530:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 534:	02090163          	beqz	s2,556 <vprintf+0x184>
        while(*s != 0){
 538:	00094583          	lbu	a1,0(s2)
 53c:	c9a1                	beqz	a1,58c <vprintf+0x1ba>
          putc(fd, *s);
 53e:	8556                	mv	a0,s5
 540:	00000097          	auipc	ra,0x0
 544:	dc6080e7          	jalr	-570(ra) # 306 <putc>
          s++;
 548:	0905                	addi	s2,s2,1
        while(*s != 0){
 54a:	00094583          	lbu	a1,0(s2)
 54e:	f9e5                	bnez	a1,53e <vprintf+0x16c>
        s = va_arg(ap, char*);
 550:	8b4e                	mv	s6,s3
      state = 0;
 552:	4981                	li	s3,0
 554:	bdf9                	j	432 <vprintf+0x60>
          s = "(null)";
 556:	00000917          	auipc	s2,0x0
 55a:	27a90913          	addi	s2,s2,634 # 7d0 <malloc+0x134>
        while(*s != 0){
 55e:	02800593          	li	a1,40
 562:	bff1                	j	53e <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 564:	008b0913          	addi	s2,s6,8
 568:	000b4583          	lbu	a1,0(s6)
 56c:	8556                	mv	a0,s5
 56e:	00000097          	auipc	ra,0x0
 572:	d98080e7          	jalr	-616(ra) # 306 <putc>
 576:	8b4a                	mv	s6,s2
      state = 0;
 578:	4981                	li	s3,0
 57a:	bd65                	j	432 <vprintf+0x60>
        putc(fd, c);
 57c:	85d2                	mv	a1,s4
 57e:	8556                	mv	a0,s5
 580:	00000097          	auipc	ra,0x0
 584:	d86080e7          	jalr	-634(ra) # 306 <putc>
      state = 0;
 588:	4981                	li	s3,0
 58a:	b565                	j	432 <vprintf+0x60>
        s = va_arg(ap, char*);
 58c:	8b4e                	mv	s6,s3
      state = 0;
 58e:	4981                	li	s3,0
 590:	b54d                	j	432 <vprintf+0x60>
    }
  }
}
 592:	70e6                	ld	ra,120(sp)
 594:	7446                	ld	s0,112(sp)
 596:	74a6                	ld	s1,104(sp)
 598:	7906                	ld	s2,96(sp)
 59a:	69e6                	ld	s3,88(sp)
 59c:	6a46                	ld	s4,80(sp)
 59e:	6aa6                	ld	s5,72(sp)
 5a0:	6b06                	ld	s6,64(sp)
 5a2:	7be2                	ld	s7,56(sp)
 5a4:	7c42                	ld	s8,48(sp)
 5a6:	7ca2                	ld	s9,40(sp)
 5a8:	7d02                	ld	s10,32(sp)
 5aa:	6de2                	ld	s11,24(sp)
 5ac:	6109                	addi	sp,sp,128
 5ae:	8082                	ret

00000000000005b0 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 5b0:	715d                	addi	sp,sp,-80
 5b2:	ec06                	sd	ra,24(sp)
 5b4:	e822                	sd	s0,16(sp)
 5b6:	1000                	addi	s0,sp,32
 5b8:	e010                	sd	a2,0(s0)
 5ba:	e414                	sd	a3,8(s0)
 5bc:	e818                	sd	a4,16(s0)
 5be:	ec1c                	sd	a5,24(s0)
 5c0:	03043023          	sd	a6,32(s0)
 5c4:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 5c8:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 5cc:	8622                	mv	a2,s0
 5ce:	00000097          	auipc	ra,0x0
 5d2:	e04080e7          	jalr	-508(ra) # 3d2 <vprintf>
}
 5d6:	60e2                	ld	ra,24(sp)
 5d8:	6442                	ld	s0,16(sp)
 5da:	6161                	addi	sp,sp,80
 5dc:	8082                	ret

00000000000005de <printf>:

void
printf(const char *fmt, ...)
{
 5de:	711d                	addi	sp,sp,-96
 5e0:	ec06                	sd	ra,24(sp)
 5e2:	e822                	sd	s0,16(sp)
 5e4:	1000                	addi	s0,sp,32
 5e6:	e40c                	sd	a1,8(s0)
 5e8:	e810                	sd	a2,16(s0)
 5ea:	ec14                	sd	a3,24(s0)
 5ec:	f018                	sd	a4,32(s0)
 5ee:	f41c                	sd	a5,40(s0)
 5f0:	03043823          	sd	a6,48(s0)
 5f4:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 5f8:	00840613          	addi	a2,s0,8
 5fc:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 600:	85aa                	mv	a1,a0
 602:	4505                	li	a0,1
 604:	00000097          	auipc	ra,0x0
 608:	dce080e7          	jalr	-562(ra) # 3d2 <vprintf>
}
 60c:	60e2                	ld	ra,24(sp)
 60e:	6442                	ld	s0,16(sp)
 610:	6125                	addi	sp,sp,96
 612:	8082                	ret

0000000000000614 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 614:	1141                	addi	sp,sp,-16
 616:	e422                	sd	s0,8(sp)
 618:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 61a:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 61e:	00000797          	auipc	a5,0x0
 622:	1d27b783          	ld	a5,466(a5) # 7f0 <freep>
 626:	a805                	j	656 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 628:	4618                	lw	a4,8(a2)
 62a:	9db9                	addw	a1,a1,a4
 62c:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 630:	6398                	ld	a4,0(a5)
 632:	6318                	ld	a4,0(a4)
 634:	fee53823          	sd	a4,-16(a0)
 638:	a091                	j	67c <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 63a:	ff852703          	lw	a4,-8(a0)
 63e:	9e39                	addw	a2,a2,a4
 640:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 642:	ff053703          	ld	a4,-16(a0)
 646:	e398                	sd	a4,0(a5)
 648:	a099                	j	68e <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 64a:	6398                	ld	a4,0(a5)
 64c:	00e7e463          	bltu	a5,a4,654 <free+0x40>
 650:	00e6ea63          	bltu	a3,a4,664 <free+0x50>
{
 654:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 656:	fed7fae3          	bgeu	a5,a3,64a <free+0x36>
 65a:	6398                	ld	a4,0(a5)
 65c:	00e6e463          	bltu	a3,a4,664 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 660:	fee7eae3          	bltu	a5,a4,654 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 664:	ff852583          	lw	a1,-8(a0)
 668:	6390                	ld	a2,0(a5)
 66a:	02059813          	slli	a6,a1,0x20
 66e:	01c85713          	srli	a4,a6,0x1c
 672:	9736                	add	a4,a4,a3
 674:	fae60ae3          	beq	a2,a4,628 <free+0x14>
    bp->s.ptr = p->s.ptr;
 678:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 67c:	4790                	lw	a2,8(a5)
 67e:	02061593          	slli	a1,a2,0x20
 682:	01c5d713          	srli	a4,a1,0x1c
 686:	973e                	add	a4,a4,a5
 688:	fae689e3          	beq	a3,a4,63a <free+0x26>
  } else
    p->s.ptr = bp;
 68c:	e394                	sd	a3,0(a5)
  freep = p;
 68e:	00000717          	auipc	a4,0x0
 692:	16f73123          	sd	a5,354(a4) # 7f0 <freep>
}
 696:	6422                	ld	s0,8(sp)
 698:	0141                	addi	sp,sp,16
 69a:	8082                	ret

000000000000069c <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 69c:	7139                	addi	sp,sp,-64
 69e:	fc06                	sd	ra,56(sp)
 6a0:	f822                	sd	s0,48(sp)
 6a2:	f426                	sd	s1,40(sp)
 6a4:	f04a                	sd	s2,32(sp)
 6a6:	ec4e                	sd	s3,24(sp)
 6a8:	e852                	sd	s4,16(sp)
 6aa:	e456                	sd	s5,8(sp)
 6ac:	e05a                	sd	s6,0(sp)
 6ae:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 6b0:	02051493          	slli	s1,a0,0x20
 6b4:	9081                	srli	s1,s1,0x20
 6b6:	04bd                	addi	s1,s1,15
 6b8:	8091                	srli	s1,s1,0x4
 6ba:	0014899b          	addiw	s3,s1,1
 6be:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 6c0:	00000517          	auipc	a0,0x0
 6c4:	13053503          	ld	a0,304(a0) # 7f0 <freep>
 6c8:	c515                	beqz	a0,6f4 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 6ca:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 6cc:	4798                	lw	a4,8(a5)
 6ce:	02977f63          	bgeu	a4,s1,70c <malloc+0x70>
 6d2:	8a4e                	mv	s4,s3
 6d4:	0009871b          	sext.w	a4,s3
 6d8:	6685                	lui	a3,0x1
 6da:	00d77363          	bgeu	a4,a3,6e0 <malloc+0x44>
 6de:	6a05                	lui	s4,0x1
 6e0:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 6e4:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 6e8:	00000917          	auipc	s2,0x0
 6ec:	10890913          	addi	s2,s2,264 # 7f0 <freep>
  if(p == (char*)-1)
 6f0:	5afd                	li	s5,-1
 6f2:	a895                	j	766 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 6f4:	00000797          	auipc	a5,0x0
 6f8:	10478793          	addi	a5,a5,260 # 7f8 <base>
 6fc:	00000717          	auipc	a4,0x0
 700:	0ef73a23          	sd	a5,244(a4) # 7f0 <freep>
 704:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 706:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 70a:	b7e1                	j	6d2 <malloc+0x36>
      if(p->s.size == nunits)
 70c:	02e48c63          	beq	s1,a4,744 <malloc+0xa8>
        p->s.size -= nunits;
 710:	4137073b          	subw	a4,a4,s3
 714:	c798                	sw	a4,8(a5)
        p += p->s.size;
 716:	02071693          	slli	a3,a4,0x20
 71a:	01c6d713          	srli	a4,a3,0x1c
 71e:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 720:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 724:	00000717          	auipc	a4,0x0
 728:	0ca73623          	sd	a0,204(a4) # 7f0 <freep>
      return (void*)(p + 1);
 72c:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 730:	70e2                	ld	ra,56(sp)
 732:	7442                	ld	s0,48(sp)
 734:	74a2                	ld	s1,40(sp)
 736:	7902                	ld	s2,32(sp)
 738:	69e2                	ld	s3,24(sp)
 73a:	6a42                	ld	s4,16(sp)
 73c:	6aa2                	ld	s5,8(sp)
 73e:	6b02                	ld	s6,0(sp)
 740:	6121                	addi	sp,sp,64
 742:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 744:	6398                	ld	a4,0(a5)
 746:	e118                	sd	a4,0(a0)
 748:	bff1                	j	724 <malloc+0x88>
  hp->s.size = nu;
 74a:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 74e:	0541                	addi	a0,a0,16
 750:	00000097          	auipc	ra,0x0
 754:	ec4080e7          	jalr	-316(ra) # 614 <free>
  return freep;
 758:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 75c:	d971                	beqz	a0,730 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 75e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 760:	4798                	lw	a4,8(a5)
 762:	fa9775e3          	bgeu	a4,s1,70c <malloc+0x70>
    if(p == freep)
 766:	00093703          	ld	a4,0(s2)
 76a:	853e                	mv	a0,a5
 76c:	fef719e3          	bne	a4,a5,75e <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 770:	8552                	mv	a0,s4
 772:	00000097          	auipc	ra,0x0
 776:	b5c080e7          	jalr	-1188(ra) # 2ce <sbrk>
  if(p == (char*)-1)
 77a:	fd5518e3          	bne	a0,s5,74a <malloc+0xae>
        return 0;
 77e:	4501                	li	a0,0
 780:	bf45                	j	730 <malloc+0x94>

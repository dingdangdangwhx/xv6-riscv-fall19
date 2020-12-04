
user/_primes：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000000000000 <func>:
#include "kernel/types.h"
#include "user/user.h"

void func(int *input, int num){
   0:	7139                	addi	sp,sp,-64
   2:	fc06                	sd	ra,56(sp)
   4:	f822                	sd	s0,48(sp)
   6:	f426                	sd	s1,40(sp)
   8:	f04a                	sd	s2,32(sp)
   a:	ec4e                	sd	s3,24(sp)
   c:	0080                	addi	s0,sp,64
   e:	892a                	mv	s2,a0
	if(num == 1){
  10:	4785                	li	a5,1
  12:	06f58463          	beq	a1,a5,7a <func+0x7a>
  16:	84ae                	mv	s1,a1
		printf("prime %d\n", *input);
		return;
	}
	int p[2],i;
	int prime = *input;
  18:	00052983          	lw	s3,0(a0)
	int temp;
	printf("prime %d\n", prime);
  1c:	85ce                	mv	a1,s3
  1e:	00001517          	auipc	a0,0x1
  22:	85250513          	addi	a0,a0,-1966 # 870 <malloc+0xe8>
  26:	00000097          	auipc	ra,0x0
  2a:	6a4080e7          	jalr	1700(ra) # 6ca <printf>
	pipe(p);
  2e:	fc840513          	addi	a0,s0,-56
  32:	00000097          	auipc	ra,0x0
  36:	310080e7          	jalr	784(ra) # 342 <pipe>
    if(fork() == 0){
  3a:	00000097          	auipc	ra,0x0
  3e:	2f0080e7          	jalr	752(ra) # 32a <fork>
  42:	c531                	beqz	a0,8e <func+0x8e>
            temp = *(input + i);
			write(p[1], (char *)(&temp), 4);
		}
        exit();
    }
	close(p[1]);
  44:	fcc42503          	lw	a0,-52(s0)
  48:	00000097          	auipc	ra,0x0
  4c:	312080e7          	jalr	786(ra) # 35a <close>
	if(fork() == 0){
  50:	00000097          	auipc	ra,0x0
  54:	2da080e7          	jalr	730(ra) # 32a <fork>
  58:	84aa                	mv	s1,a0
  5a:	c925                	beqz	a0,ca <func+0xca>
			}
		}
		func(input - counter, counter);
		exit();
    }
	wait();
  5c:	00000097          	auipc	ra,0x0
  60:	2de080e7          	jalr	734(ra) # 33a <wait>
	wait();
  64:	00000097          	auipc	ra,0x0
  68:	2d6080e7          	jalr	726(ra) # 33a <wait>
}
  6c:	70e2                	ld	ra,56(sp)
  6e:	7442                	ld	s0,48(sp)
  70:	74a2                	ld	s1,40(sp)
  72:	7902                	ld	s2,32(sp)
  74:	69e2                	ld	s3,24(sp)
  76:	6121                	addi	sp,sp,64
  78:	8082                	ret
		printf("prime %d\n", *input);
  7a:	410c                	lw	a1,0(a0)
  7c:	00000517          	auipc	a0,0x0
  80:	7f450513          	addi	a0,a0,2036 # 870 <malloc+0xe8>
  84:	00000097          	auipc	ra,0x0
  88:	646080e7          	jalr	1606(ra) # 6ca <printf>
		return;
  8c:	b7c5                	j	6c <func+0x6c>
        for(i = 0; i < num; i++){
  8e:	02905a63          	blez	s1,c2 <func+0xc2>
  92:	89ca                	mv	s3,s2
  94:	34fd                	addiw	s1,s1,-1
  96:	02049793          	slli	a5,s1,0x20
  9a:	01e7d493          	srli	s1,a5,0x1e
  9e:	0911                	addi	s2,s2,4
  a0:	94ca                	add	s1,s1,s2
            temp = *(input + i);
  a2:	0009a783          	lw	a5,0(s3)
  a6:	fcf42223          	sw	a5,-60(s0)
			write(p[1], (char *)(&temp), 4);
  aa:	4611                	li	a2,4
  ac:	fc440593          	addi	a1,s0,-60
  b0:	fcc42503          	lw	a0,-52(s0)
  b4:	00000097          	auipc	ra,0x0
  b8:	29e080e7          	jalr	670(ra) # 352 <write>
        for(i = 0; i < num; i++){
  bc:	0991                	addi	s3,s3,4
  be:	fe9992e3          	bne	s3,s1,a2 <func+0xa2>
        exit();
  c2:	00000097          	auipc	ra,0x0
  c6:	270080e7          	jalr	624(ra) # 332 <exit>
		while(read(p[0], buffer, 4) != 0){
  ca:	4611                	li	a2,4
  cc:	fc040593          	addi	a1,s0,-64
  d0:	fc842503          	lw	a0,-56(s0)
  d4:	00000097          	auipc	ra,0x0
  d8:	276080e7          	jalr	630(ra) # 34a <read>
  dc:	cd09                	beqz	a0,f6 <func+0xf6>
			temp = *((int *)buffer);
  de:	fc042783          	lw	a5,-64(s0)
  e2:	fcf42223          	sw	a5,-60(s0)
			if(temp % prime != 0){
  e6:	0337e73b          	remw	a4,a5,s3
  ea:	d365                	beqz	a4,ca <func+0xca>
				*input = temp;
  ec:	00f92023          	sw	a5,0(s2)
				input += 1;
  f0:	0911                	addi	s2,s2,4
				counter++;
  f2:	2485                	addiw	s1,s1,1
  f4:	bfd9                	j	ca <func+0xca>
		func(input - counter, counter);
  f6:	00249513          	slli	a0,s1,0x2
  fa:	85a6                	mv	a1,s1
  fc:	40a90533          	sub	a0,s2,a0
 100:	00000097          	auipc	ra,0x0
 104:	f00080e7          	jalr	-256(ra) # 0 <func>
		exit();
 108:	00000097          	auipc	ra,0x0
 10c:	22a080e7          	jalr	554(ra) # 332 <exit>

0000000000000110 <main>:

int main(){
 110:	7135                	addi	sp,sp,-160
 112:	ed06                	sd	ra,152(sp)
 114:	e922                	sd	s0,144(sp)
 116:	1100                	addi	s0,sp,160
    int input[34];
	int i = 0;
	for(; i < 34; i++){
 118:	f6840793          	addi	a5,s0,-152
 11c:	ff040693          	addi	a3,s0,-16
int main(){
 120:	4709                	li	a4,2
		input[i] = i+2;
 122:	c398                	sw	a4,0(a5)
	for(; i < 34; i++){
 124:	2705                	addiw	a4,a4,1
 126:	0791                	addi	a5,a5,4
 128:	fed79de3          	bne	a5,a3,122 <main+0x12>
	}
	func(input, 34);
 12c:	02200593          	li	a1,34
 130:	f6840513          	addi	a0,s0,-152
 134:	00000097          	auipc	ra,0x0
 138:	ecc080e7          	jalr	-308(ra) # 0 <func>
    exit();
 13c:	00000097          	auipc	ra,0x0
 140:	1f6080e7          	jalr	502(ra) # 332 <exit>

0000000000000144 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 144:	1141                	addi	sp,sp,-16
 146:	e422                	sd	s0,8(sp)
 148:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 14a:	87aa                	mv	a5,a0
 14c:	0585                	addi	a1,a1,1
 14e:	0785                	addi	a5,a5,1
 150:	fff5c703          	lbu	a4,-1(a1)
 154:	fee78fa3          	sb	a4,-1(a5)
 158:	fb75                	bnez	a4,14c <strcpy+0x8>
    ;
  return os;
}
 15a:	6422                	ld	s0,8(sp)
 15c:	0141                	addi	sp,sp,16
 15e:	8082                	ret

0000000000000160 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 160:	1141                	addi	sp,sp,-16
 162:	e422                	sd	s0,8(sp)
 164:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 166:	00054783          	lbu	a5,0(a0)
 16a:	cb91                	beqz	a5,17e <strcmp+0x1e>
 16c:	0005c703          	lbu	a4,0(a1)
 170:	00f71763          	bne	a4,a5,17e <strcmp+0x1e>
    p++, q++;
 174:	0505                	addi	a0,a0,1
 176:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 178:	00054783          	lbu	a5,0(a0)
 17c:	fbe5                	bnez	a5,16c <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 17e:	0005c503          	lbu	a0,0(a1)
}
 182:	40a7853b          	subw	a0,a5,a0
 186:	6422                	ld	s0,8(sp)
 188:	0141                	addi	sp,sp,16
 18a:	8082                	ret

000000000000018c <strlen>:

uint
strlen(const char *s)
{
 18c:	1141                	addi	sp,sp,-16
 18e:	e422                	sd	s0,8(sp)
 190:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 192:	00054783          	lbu	a5,0(a0)
 196:	cf91                	beqz	a5,1b2 <strlen+0x26>
 198:	0505                	addi	a0,a0,1
 19a:	87aa                	mv	a5,a0
 19c:	4685                	li	a3,1
 19e:	9e89                	subw	a3,a3,a0
 1a0:	00f6853b          	addw	a0,a3,a5
 1a4:	0785                	addi	a5,a5,1
 1a6:	fff7c703          	lbu	a4,-1(a5)
 1aa:	fb7d                	bnez	a4,1a0 <strlen+0x14>
    ;
  return n;
}
 1ac:	6422                	ld	s0,8(sp)
 1ae:	0141                	addi	sp,sp,16
 1b0:	8082                	ret
  for(n = 0; s[n]; n++)
 1b2:	4501                	li	a0,0
 1b4:	bfe5                	j	1ac <strlen+0x20>

00000000000001b6 <memset>:

void*
memset(void *dst, int c, uint n)
{
 1b6:	1141                	addi	sp,sp,-16
 1b8:	e422                	sd	s0,8(sp)
 1ba:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 1bc:	ca19                	beqz	a2,1d2 <memset+0x1c>
 1be:	87aa                	mv	a5,a0
 1c0:	1602                	slli	a2,a2,0x20
 1c2:	9201                	srli	a2,a2,0x20
 1c4:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 1c8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 1cc:	0785                	addi	a5,a5,1
 1ce:	fee79de3          	bne	a5,a4,1c8 <memset+0x12>
  }
  return dst;
}
 1d2:	6422                	ld	s0,8(sp)
 1d4:	0141                	addi	sp,sp,16
 1d6:	8082                	ret

00000000000001d8 <strchr>:

char*
strchr(const char *s, char c)
{
 1d8:	1141                	addi	sp,sp,-16
 1da:	e422                	sd	s0,8(sp)
 1dc:	0800                	addi	s0,sp,16
  for(; *s; s++)
 1de:	00054783          	lbu	a5,0(a0)
 1e2:	cb99                	beqz	a5,1f8 <strchr+0x20>
    if(*s == c)
 1e4:	00f58763          	beq	a1,a5,1f2 <strchr+0x1a>
  for(; *s; s++)
 1e8:	0505                	addi	a0,a0,1
 1ea:	00054783          	lbu	a5,0(a0)
 1ee:	fbfd                	bnez	a5,1e4 <strchr+0xc>
      return (char*)s;
  return 0;
 1f0:	4501                	li	a0,0
}
 1f2:	6422                	ld	s0,8(sp)
 1f4:	0141                	addi	sp,sp,16
 1f6:	8082                	ret
  return 0;
 1f8:	4501                	li	a0,0
 1fa:	bfe5                	j	1f2 <strchr+0x1a>

00000000000001fc <gets>:

char*
gets(char *buf, int max)
{
 1fc:	711d                	addi	sp,sp,-96
 1fe:	ec86                	sd	ra,88(sp)
 200:	e8a2                	sd	s0,80(sp)
 202:	e4a6                	sd	s1,72(sp)
 204:	e0ca                	sd	s2,64(sp)
 206:	fc4e                	sd	s3,56(sp)
 208:	f852                	sd	s4,48(sp)
 20a:	f456                	sd	s5,40(sp)
 20c:	f05a                	sd	s6,32(sp)
 20e:	ec5e                	sd	s7,24(sp)
 210:	1080                	addi	s0,sp,96
 212:	8baa                	mv	s7,a0
 214:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 216:	892a                	mv	s2,a0
 218:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 21a:	4aa9                	li	s5,10
 21c:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 21e:	89a6                	mv	s3,s1
 220:	2485                	addiw	s1,s1,1
 222:	0344d863          	bge	s1,s4,252 <gets+0x56>
    cc = read(0, &c, 1);
 226:	4605                	li	a2,1
 228:	faf40593          	addi	a1,s0,-81
 22c:	4501                	li	a0,0
 22e:	00000097          	auipc	ra,0x0
 232:	11c080e7          	jalr	284(ra) # 34a <read>
    if(cc < 1)
 236:	00a05e63          	blez	a0,252 <gets+0x56>
    buf[i++] = c;
 23a:	faf44783          	lbu	a5,-81(s0)
 23e:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 242:	01578763          	beq	a5,s5,250 <gets+0x54>
 246:	0905                	addi	s2,s2,1
 248:	fd679be3          	bne	a5,s6,21e <gets+0x22>
  for(i=0; i+1 < max; ){
 24c:	89a6                	mv	s3,s1
 24e:	a011                	j	252 <gets+0x56>
 250:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 252:	99de                	add	s3,s3,s7
 254:	00098023          	sb	zero,0(s3)
  return buf;
}
 258:	855e                	mv	a0,s7
 25a:	60e6                	ld	ra,88(sp)
 25c:	6446                	ld	s0,80(sp)
 25e:	64a6                	ld	s1,72(sp)
 260:	6906                	ld	s2,64(sp)
 262:	79e2                	ld	s3,56(sp)
 264:	7a42                	ld	s4,48(sp)
 266:	7aa2                	ld	s5,40(sp)
 268:	7b02                	ld	s6,32(sp)
 26a:	6be2                	ld	s7,24(sp)
 26c:	6125                	addi	sp,sp,96
 26e:	8082                	ret

0000000000000270 <stat>:

int
stat(const char *n, struct stat *st)
{
 270:	1101                	addi	sp,sp,-32
 272:	ec06                	sd	ra,24(sp)
 274:	e822                	sd	s0,16(sp)
 276:	e426                	sd	s1,8(sp)
 278:	e04a                	sd	s2,0(sp)
 27a:	1000                	addi	s0,sp,32
 27c:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 27e:	4581                	li	a1,0
 280:	00000097          	auipc	ra,0x0
 284:	0f2080e7          	jalr	242(ra) # 372 <open>
  if(fd < 0)
 288:	02054563          	bltz	a0,2b2 <stat+0x42>
 28c:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 28e:	85ca                	mv	a1,s2
 290:	00000097          	auipc	ra,0x0
 294:	0fa080e7          	jalr	250(ra) # 38a <fstat>
 298:	892a                	mv	s2,a0
  close(fd);
 29a:	8526                	mv	a0,s1
 29c:	00000097          	auipc	ra,0x0
 2a0:	0be080e7          	jalr	190(ra) # 35a <close>
  return r;
}
 2a4:	854a                	mv	a0,s2
 2a6:	60e2                	ld	ra,24(sp)
 2a8:	6442                	ld	s0,16(sp)
 2aa:	64a2                	ld	s1,8(sp)
 2ac:	6902                	ld	s2,0(sp)
 2ae:	6105                	addi	sp,sp,32
 2b0:	8082                	ret
    return -1;
 2b2:	597d                	li	s2,-1
 2b4:	bfc5                	j	2a4 <stat+0x34>

00000000000002b6 <atoi>:

int
atoi(const char *s)
{
 2b6:	1141                	addi	sp,sp,-16
 2b8:	e422                	sd	s0,8(sp)
 2ba:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 2bc:	00054603          	lbu	a2,0(a0)
 2c0:	fd06079b          	addiw	a5,a2,-48
 2c4:	0ff7f793          	andi	a5,a5,255
 2c8:	4725                	li	a4,9
 2ca:	02f76963          	bltu	a4,a5,2fc <atoi+0x46>
 2ce:	86aa                	mv	a3,a0
  n = 0;
 2d0:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 2d2:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 2d4:	0685                	addi	a3,a3,1
 2d6:	0025179b          	slliw	a5,a0,0x2
 2da:	9fa9                	addw	a5,a5,a0
 2dc:	0017979b          	slliw	a5,a5,0x1
 2e0:	9fb1                	addw	a5,a5,a2
 2e2:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 2e6:	0006c603          	lbu	a2,0(a3)
 2ea:	fd06071b          	addiw	a4,a2,-48
 2ee:	0ff77713          	andi	a4,a4,255
 2f2:	fee5f1e3          	bgeu	a1,a4,2d4 <atoi+0x1e>
  return n;
}
 2f6:	6422                	ld	s0,8(sp)
 2f8:	0141                	addi	sp,sp,16
 2fa:	8082                	ret
  n = 0;
 2fc:	4501                	li	a0,0
 2fe:	bfe5                	j	2f6 <atoi+0x40>

0000000000000300 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 300:	1141                	addi	sp,sp,-16
 302:	e422                	sd	s0,8(sp)
 304:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  while(n-- > 0)
 306:	00c05f63          	blez	a2,324 <memmove+0x24>
 30a:	1602                	slli	a2,a2,0x20
 30c:	9201                	srli	a2,a2,0x20
 30e:	00c506b3          	add	a3,a0,a2
  dst = vdst;
 312:	87aa                	mv	a5,a0
    *dst++ = *src++;
 314:	0585                	addi	a1,a1,1
 316:	0785                	addi	a5,a5,1
 318:	fff5c703          	lbu	a4,-1(a1)
 31c:	fee78fa3          	sb	a4,-1(a5)
  while(n-- > 0)
 320:	fed79ae3          	bne	a5,a3,314 <memmove+0x14>
  return vdst;
}
 324:	6422                	ld	s0,8(sp)
 326:	0141                	addi	sp,sp,16
 328:	8082                	ret

000000000000032a <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 32a:	4885                	li	a7,1
 ecall
 32c:	00000073          	ecall
 ret
 330:	8082                	ret

0000000000000332 <exit>:
.global exit
exit:
 li a7, SYS_exit
 332:	4889                	li	a7,2
 ecall
 334:	00000073          	ecall
 ret
 338:	8082                	ret

000000000000033a <wait>:
.global wait
wait:
 li a7, SYS_wait
 33a:	488d                	li	a7,3
 ecall
 33c:	00000073          	ecall
 ret
 340:	8082                	ret

0000000000000342 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 342:	4891                	li	a7,4
 ecall
 344:	00000073          	ecall
 ret
 348:	8082                	ret

000000000000034a <read>:
.global read
read:
 li a7, SYS_read
 34a:	4895                	li	a7,5
 ecall
 34c:	00000073          	ecall
 ret
 350:	8082                	ret

0000000000000352 <write>:
.global write
write:
 li a7, SYS_write
 352:	48c1                	li	a7,16
 ecall
 354:	00000073          	ecall
 ret
 358:	8082                	ret

000000000000035a <close>:
.global close
close:
 li a7, SYS_close
 35a:	48d5                	li	a7,21
 ecall
 35c:	00000073          	ecall
 ret
 360:	8082                	ret

0000000000000362 <kill>:
.global kill
kill:
 li a7, SYS_kill
 362:	4899                	li	a7,6
 ecall
 364:	00000073          	ecall
 ret
 368:	8082                	ret

000000000000036a <exec>:
.global exec
exec:
 li a7, SYS_exec
 36a:	489d                	li	a7,7
 ecall
 36c:	00000073          	ecall
 ret
 370:	8082                	ret

0000000000000372 <open>:
.global open
open:
 li a7, SYS_open
 372:	48bd                	li	a7,15
 ecall
 374:	00000073          	ecall
 ret
 378:	8082                	ret

000000000000037a <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 37a:	48c5                	li	a7,17
 ecall
 37c:	00000073          	ecall
 ret
 380:	8082                	ret

0000000000000382 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 382:	48c9                	li	a7,18
 ecall
 384:	00000073          	ecall
 ret
 388:	8082                	ret

000000000000038a <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 38a:	48a1                	li	a7,8
 ecall
 38c:	00000073          	ecall
 ret
 390:	8082                	ret

0000000000000392 <link>:
.global link
link:
 li a7, SYS_link
 392:	48cd                	li	a7,19
 ecall
 394:	00000073          	ecall
 ret
 398:	8082                	ret

000000000000039a <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 39a:	48d1                	li	a7,20
 ecall
 39c:	00000073          	ecall
 ret
 3a0:	8082                	ret

00000000000003a2 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 3a2:	48a5                	li	a7,9
 ecall
 3a4:	00000073          	ecall
 ret
 3a8:	8082                	ret

00000000000003aa <dup>:
.global dup
dup:
 li a7, SYS_dup
 3aa:	48a9                	li	a7,10
 ecall
 3ac:	00000073          	ecall
 ret
 3b0:	8082                	ret

00000000000003b2 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 3b2:	48ad                	li	a7,11
 ecall
 3b4:	00000073          	ecall
 ret
 3b8:	8082                	ret

00000000000003ba <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 3ba:	48b1                	li	a7,12
 ecall
 3bc:	00000073          	ecall
 ret
 3c0:	8082                	ret

00000000000003c2 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 3c2:	48b5                	li	a7,13
 ecall
 3c4:	00000073          	ecall
 ret
 3c8:	8082                	ret

00000000000003ca <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 3ca:	48b9                	li	a7,14
 ecall
 3cc:	00000073          	ecall
 ret
 3d0:	8082                	ret

00000000000003d2 <ntas>:
.global ntas
ntas:
 li a7, SYS_ntas
 3d2:	48d9                	li	a7,22
 ecall
 3d4:	00000073          	ecall
 ret
 3d8:	8082                	ret

00000000000003da <crash>:
.global crash
crash:
 li a7, SYS_crash
 3da:	48dd                	li	a7,23
 ecall
 3dc:	00000073          	ecall
 ret
 3e0:	8082                	ret

00000000000003e2 <mount>:
.global mount
mount:
 li a7, SYS_mount
 3e2:	48e1                	li	a7,24
 ecall
 3e4:	00000073          	ecall
 ret
 3e8:	8082                	ret

00000000000003ea <umount>:
.global umount
umount:
 li a7, SYS_umount
 3ea:	48e5                	li	a7,25
 ecall
 3ec:	00000073          	ecall
 ret
 3f0:	8082                	ret

00000000000003f2 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3f2:	1101                	addi	sp,sp,-32
 3f4:	ec06                	sd	ra,24(sp)
 3f6:	e822                	sd	s0,16(sp)
 3f8:	1000                	addi	s0,sp,32
 3fa:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3fe:	4605                	li	a2,1
 400:	fef40593          	addi	a1,s0,-17
 404:	00000097          	auipc	ra,0x0
 408:	f4e080e7          	jalr	-178(ra) # 352 <write>
}
 40c:	60e2                	ld	ra,24(sp)
 40e:	6442                	ld	s0,16(sp)
 410:	6105                	addi	sp,sp,32
 412:	8082                	ret

0000000000000414 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 414:	7139                	addi	sp,sp,-64
 416:	fc06                	sd	ra,56(sp)
 418:	f822                	sd	s0,48(sp)
 41a:	f426                	sd	s1,40(sp)
 41c:	f04a                	sd	s2,32(sp)
 41e:	ec4e                	sd	s3,24(sp)
 420:	0080                	addi	s0,sp,64
 422:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 424:	c299                	beqz	a3,42a <printint+0x16>
 426:	0805c863          	bltz	a1,4b6 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 42a:	2581                	sext.w	a1,a1
  neg = 0;
 42c:	4881                	li	a7,0
 42e:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 432:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 434:	2601                	sext.w	a2,a2
 436:	00000517          	auipc	a0,0x0
 43a:	45250513          	addi	a0,a0,1106 # 888 <digits>
 43e:	883a                	mv	a6,a4
 440:	2705                	addiw	a4,a4,1
 442:	02c5f7bb          	remuw	a5,a1,a2
 446:	1782                	slli	a5,a5,0x20
 448:	9381                	srli	a5,a5,0x20
 44a:	97aa                	add	a5,a5,a0
 44c:	0007c783          	lbu	a5,0(a5)
 450:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 454:	0005879b          	sext.w	a5,a1
 458:	02c5d5bb          	divuw	a1,a1,a2
 45c:	0685                	addi	a3,a3,1
 45e:	fec7f0e3          	bgeu	a5,a2,43e <printint+0x2a>
  if(neg)
 462:	00088b63          	beqz	a7,478 <printint+0x64>
    buf[i++] = '-';
 466:	fd040793          	addi	a5,s0,-48
 46a:	973e                	add	a4,a4,a5
 46c:	02d00793          	li	a5,45
 470:	fef70823          	sb	a5,-16(a4)
 474:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 478:	02e05863          	blez	a4,4a8 <printint+0x94>
 47c:	fc040793          	addi	a5,s0,-64
 480:	00e78933          	add	s2,a5,a4
 484:	fff78993          	addi	s3,a5,-1
 488:	99ba                	add	s3,s3,a4
 48a:	377d                	addiw	a4,a4,-1
 48c:	1702                	slli	a4,a4,0x20
 48e:	9301                	srli	a4,a4,0x20
 490:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 494:	fff94583          	lbu	a1,-1(s2)
 498:	8526                	mv	a0,s1
 49a:	00000097          	auipc	ra,0x0
 49e:	f58080e7          	jalr	-168(ra) # 3f2 <putc>
  while(--i >= 0)
 4a2:	197d                	addi	s2,s2,-1
 4a4:	ff3918e3          	bne	s2,s3,494 <printint+0x80>
}
 4a8:	70e2                	ld	ra,56(sp)
 4aa:	7442                	ld	s0,48(sp)
 4ac:	74a2                	ld	s1,40(sp)
 4ae:	7902                	ld	s2,32(sp)
 4b0:	69e2                	ld	s3,24(sp)
 4b2:	6121                	addi	sp,sp,64
 4b4:	8082                	ret
    x = -xx;
 4b6:	40b005bb          	negw	a1,a1
    neg = 1;
 4ba:	4885                	li	a7,1
    x = -xx;
 4bc:	bf8d                	j	42e <printint+0x1a>

00000000000004be <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4be:	7119                	addi	sp,sp,-128
 4c0:	fc86                	sd	ra,120(sp)
 4c2:	f8a2                	sd	s0,112(sp)
 4c4:	f4a6                	sd	s1,104(sp)
 4c6:	f0ca                	sd	s2,96(sp)
 4c8:	ecce                	sd	s3,88(sp)
 4ca:	e8d2                	sd	s4,80(sp)
 4cc:	e4d6                	sd	s5,72(sp)
 4ce:	e0da                	sd	s6,64(sp)
 4d0:	fc5e                	sd	s7,56(sp)
 4d2:	f862                	sd	s8,48(sp)
 4d4:	f466                	sd	s9,40(sp)
 4d6:	f06a                	sd	s10,32(sp)
 4d8:	ec6e                	sd	s11,24(sp)
 4da:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4dc:	0005c903          	lbu	s2,0(a1)
 4e0:	18090f63          	beqz	s2,67e <vprintf+0x1c0>
 4e4:	8aaa                	mv	s5,a0
 4e6:	8b32                	mv	s6,a2
 4e8:	00158493          	addi	s1,a1,1
  state = 0;
 4ec:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4ee:	02500a13          	li	s4,37
      if(c == 'd'){
 4f2:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 4f6:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 4fa:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 4fe:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 502:	00000b97          	auipc	s7,0x0
 506:	386b8b93          	addi	s7,s7,902 # 888 <digits>
 50a:	a839                	j	528 <vprintf+0x6a>
        putc(fd, c);
 50c:	85ca                	mv	a1,s2
 50e:	8556                	mv	a0,s5
 510:	00000097          	auipc	ra,0x0
 514:	ee2080e7          	jalr	-286(ra) # 3f2 <putc>
 518:	a019                	j	51e <vprintf+0x60>
    } else if(state == '%'){
 51a:	01498f63          	beq	s3,s4,538 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 51e:	0485                	addi	s1,s1,1
 520:	fff4c903          	lbu	s2,-1(s1)
 524:	14090d63          	beqz	s2,67e <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 528:	0009079b          	sext.w	a5,s2
    if(state == 0){
 52c:	fe0997e3          	bnez	s3,51a <vprintf+0x5c>
      if(c == '%'){
 530:	fd479ee3          	bne	a5,s4,50c <vprintf+0x4e>
        state = '%';
 534:	89be                	mv	s3,a5
 536:	b7e5                	j	51e <vprintf+0x60>
      if(c == 'd'){
 538:	05878063          	beq	a5,s8,578 <vprintf+0xba>
      } else if(c == 'l') {
 53c:	05978c63          	beq	a5,s9,594 <vprintf+0xd6>
      } else if(c == 'x') {
 540:	07a78863          	beq	a5,s10,5b0 <vprintf+0xf2>
      } else if(c == 'p') {
 544:	09b78463          	beq	a5,s11,5cc <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 548:	07300713          	li	a4,115
 54c:	0ce78663          	beq	a5,a4,618 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 550:	06300713          	li	a4,99
 554:	0ee78e63          	beq	a5,a4,650 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 558:	11478863          	beq	a5,s4,668 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 55c:	85d2                	mv	a1,s4
 55e:	8556                	mv	a0,s5
 560:	00000097          	auipc	ra,0x0
 564:	e92080e7          	jalr	-366(ra) # 3f2 <putc>
        putc(fd, c);
 568:	85ca                	mv	a1,s2
 56a:	8556                	mv	a0,s5
 56c:	00000097          	auipc	ra,0x0
 570:	e86080e7          	jalr	-378(ra) # 3f2 <putc>
      }
      state = 0;
 574:	4981                	li	s3,0
 576:	b765                	j	51e <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 578:	008b0913          	addi	s2,s6,8
 57c:	4685                	li	a3,1
 57e:	4629                	li	a2,10
 580:	000b2583          	lw	a1,0(s6)
 584:	8556                	mv	a0,s5
 586:	00000097          	auipc	ra,0x0
 58a:	e8e080e7          	jalr	-370(ra) # 414 <printint>
 58e:	8b4a                	mv	s6,s2
      state = 0;
 590:	4981                	li	s3,0
 592:	b771                	j	51e <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 594:	008b0913          	addi	s2,s6,8
 598:	4681                	li	a3,0
 59a:	4629                	li	a2,10
 59c:	000b2583          	lw	a1,0(s6)
 5a0:	8556                	mv	a0,s5
 5a2:	00000097          	auipc	ra,0x0
 5a6:	e72080e7          	jalr	-398(ra) # 414 <printint>
 5aa:	8b4a                	mv	s6,s2
      state = 0;
 5ac:	4981                	li	s3,0
 5ae:	bf85                	j	51e <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 5b0:	008b0913          	addi	s2,s6,8
 5b4:	4681                	li	a3,0
 5b6:	4641                	li	a2,16
 5b8:	000b2583          	lw	a1,0(s6)
 5bc:	8556                	mv	a0,s5
 5be:	00000097          	auipc	ra,0x0
 5c2:	e56080e7          	jalr	-426(ra) # 414 <printint>
 5c6:	8b4a                	mv	s6,s2
      state = 0;
 5c8:	4981                	li	s3,0
 5ca:	bf91                	j	51e <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 5cc:	008b0793          	addi	a5,s6,8
 5d0:	f8f43423          	sd	a5,-120(s0)
 5d4:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 5d8:	03000593          	li	a1,48
 5dc:	8556                	mv	a0,s5
 5de:	00000097          	auipc	ra,0x0
 5e2:	e14080e7          	jalr	-492(ra) # 3f2 <putc>
  putc(fd, 'x');
 5e6:	85ea                	mv	a1,s10
 5e8:	8556                	mv	a0,s5
 5ea:	00000097          	auipc	ra,0x0
 5ee:	e08080e7          	jalr	-504(ra) # 3f2 <putc>
 5f2:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5f4:	03c9d793          	srli	a5,s3,0x3c
 5f8:	97de                	add	a5,a5,s7
 5fa:	0007c583          	lbu	a1,0(a5)
 5fe:	8556                	mv	a0,s5
 600:	00000097          	auipc	ra,0x0
 604:	df2080e7          	jalr	-526(ra) # 3f2 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 608:	0992                	slli	s3,s3,0x4
 60a:	397d                	addiw	s2,s2,-1
 60c:	fe0914e3          	bnez	s2,5f4 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 610:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 614:	4981                	li	s3,0
 616:	b721                	j	51e <vprintf+0x60>
        s = va_arg(ap, char*);
 618:	008b0993          	addi	s3,s6,8
 61c:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 620:	02090163          	beqz	s2,642 <vprintf+0x184>
        while(*s != 0){
 624:	00094583          	lbu	a1,0(s2)
 628:	c9a1                	beqz	a1,678 <vprintf+0x1ba>
          putc(fd, *s);
 62a:	8556                	mv	a0,s5
 62c:	00000097          	auipc	ra,0x0
 630:	dc6080e7          	jalr	-570(ra) # 3f2 <putc>
          s++;
 634:	0905                	addi	s2,s2,1
        while(*s != 0){
 636:	00094583          	lbu	a1,0(s2)
 63a:	f9e5                	bnez	a1,62a <vprintf+0x16c>
        s = va_arg(ap, char*);
 63c:	8b4e                	mv	s6,s3
      state = 0;
 63e:	4981                	li	s3,0
 640:	bdf9                	j	51e <vprintf+0x60>
          s = "(null)";
 642:	00000917          	auipc	s2,0x0
 646:	23e90913          	addi	s2,s2,574 # 880 <malloc+0xf8>
        while(*s != 0){
 64a:	02800593          	li	a1,40
 64e:	bff1                	j	62a <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 650:	008b0913          	addi	s2,s6,8
 654:	000b4583          	lbu	a1,0(s6)
 658:	8556                	mv	a0,s5
 65a:	00000097          	auipc	ra,0x0
 65e:	d98080e7          	jalr	-616(ra) # 3f2 <putc>
 662:	8b4a                	mv	s6,s2
      state = 0;
 664:	4981                	li	s3,0
 666:	bd65                	j	51e <vprintf+0x60>
        putc(fd, c);
 668:	85d2                	mv	a1,s4
 66a:	8556                	mv	a0,s5
 66c:	00000097          	auipc	ra,0x0
 670:	d86080e7          	jalr	-634(ra) # 3f2 <putc>
      state = 0;
 674:	4981                	li	s3,0
 676:	b565                	j	51e <vprintf+0x60>
        s = va_arg(ap, char*);
 678:	8b4e                	mv	s6,s3
      state = 0;
 67a:	4981                	li	s3,0
 67c:	b54d                	j	51e <vprintf+0x60>
    }
  }
}
 67e:	70e6                	ld	ra,120(sp)
 680:	7446                	ld	s0,112(sp)
 682:	74a6                	ld	s1,104(sp)
 684:	7906                	ld	s2,96(sp)
 686:	69e6                	ld	s3,88(sp)
 688:	6a46                	ld	s4,80(sp)
 68a:	6aa6                	ld	s5,72(sp)
 68c:	6b06                	ld	s6,64(sp)
 68e:	7be2                	ld	s7,56(sp)
 690:	7c42                	ld	s8,48(sp)
 692:	7ca2                	ld	s9,40(sp)
 694:	7d02                	ld	s10,32(sp)
 696:	6de2                	ld	s11,24(sp)
 698:	6109                	addi	sp,sp,128
 69a:	8082                	ret

000000000000069c <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 69c:	715d                	addi	sp,sp,-80
 69e:	ec06                	sd	ra,24(sp)
 6a0:	e822                	sd	s0,16(sp)
 6a2:	1000                	addi	s0,sp,32
 6a4:	e010                	sd	a2,0(s0)
 6a6:	e414                	sd	a3,8(s0)
 6a8:	e818                	sd	a4,16(s0)
 6aa:	ec1c                	sd	a5,24(s0)
 6ac:	03043023          	sd	a6,32(s0)
 6b0:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 6b4:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 6b8:	8622                	mv	a2,s0
 6ba:	00000097          	auipc	ra,0x0
 6be:	e04080e7          	jalr	-508(ra) # 4be <vprintf>
}
 6c2:	60e2                	ld	ra,24(sp)
 6c4:	6442                	ld	s0,16(sp)
 6c6:	6161                	addi	sp,sp,80
 6c8:	8082                	ret

00000000000006ca <printf>:

void
printf(const char *fmt, ...)
{
 6ca:	711d                	addi	sp,sp,-96
 6cc:	ec06                	sd	ra,24(sp)
 6ce:	e822                	sd	s0,16(sp)
 6d0:	1000                	addi	s0,sp,32
 6d2:	e40c                	sd	a1,8(s0)
 6d4:	e810                	sd	a2,16(s0)
 6d6:	ec14                	sd	a3,24(s0)
 6d8:	f018                	sd	a4,32(s0)
 6da:	f41c                	sd	a5,40(s0)
 6dc:	03043823          	sd	a6,48(s0)
 6e0:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 6e4:	00840613          	addi	a2,s0,8
 6e8:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6ec:	85aa                	mv	a1,a0
 6ee:	4505                	li	a0,1
 6f0:	00000097          	auipc	ra,0x0
 6f4:	dce080e7          	jalr	-562(ra) # 4be <vprintf>
}
 6f8:	60e2                	ld	ra,24(sp)
 6fa:	6442                	ld	s0,16(sp)
 6fc:	6125                	addi	sp,sp,96
 6fe:	8082                	ret

0000000000000700 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 700:	1141                	addi	sp,sp,-16
 702:	e422                	sd	s0,8(sp)
 704:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 706:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 70a:	00000797          	auipc	a5,0x0
 70e:	1967b783          	ld	a5,406(a5) # 8a0 <freep>
 712:	a805                	j	742 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 714:	4618                	lw	a4,8(a2)
 716:	9db9                	addw	a1,a1,a4
 718:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 71c:	6398                	ld	a4,0(a5)
 71e:	6318                	ld	a4,0(a4)
 720:	fee53823          	sd	a4,-16(a0)
 724:	a091                	j	768 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 726:	ff852703          	lw	a4,-8(a0)
 72a:	9e39                	addw	a2,a2,a4
 72c:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 72e:	ff053703          	ld	a4,-16(a0)
 732:	e398                	sd	a4,0(a5)
 734:	a099                	j	77a <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 736:	6398                	ld	a4,0(a5)
 738:	00e7e463          	bltu	a5,a4,740 <free+0x40>
 73c:	00e6ea63          	bltu	a3,a4,750 <free+0x50>
{
 740:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 742:	fed7fae3          	bgeu	a5,a3,736 <free+0x36>
 746:	6398                	ld	a4,0(a5)
 748:	00e6e463          	bltu	a3,a4,750 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 74c:	fee7eae3          	bltu	a5,a4,740 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 750:	ff852583          	lw	a1,-8(a0)
 754:	6390                	ld	a2,0(a5)
 756:	02059813          	slli	a6,a1,0x20
 75a:	01c85713          	srli	a4,a6,0x1c
 75e:	9736                	add	a4,a4,a3
 760:	fae60ae3          	beq	a2,a4,714 <free+0x14>
    bp->s.ptr = p->s.ptr;
 764:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 768:	4790                	lw	a2,8(a5)
 76a:	02061593          	slli	a1,a2,0x20
 76e:	01c5d713          	srli	a4,a1,0x1c
 772:	973e                	add	a4,a4,a5
 774:	fae689e3          	beq	a3,a4,726 <free+0x26>
  } else
    p->s.ptr = bp;
 778:	e394                	sd	a3,0(a5)
  freep = p;
 77a:	00000717          	auipc	a4,0x0
 77e:	12f73323          	sd	a5,294(a4) # 8a0 <freep>
}
 782:	6422                	ld	s0,8(sp)
 784:	0141                	addi	sp,sp,16
 786:	8082                	ret

0000000000000788 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 788:	7139                	addi	sp,sp,-64
 78a:	fc06                	sd	ra,56(sp)
 78c:	f822                	sd	s0,48(sp)
 78e:	f426                	sd	s1,40(sp)
 790:	f04a                	sd	s2,32(sp)
 792:	ec4e                	sd	s3,24(sp)
 794:	e852                	sd	s4,16(sp)
 796:	e456                	sd	s5,8(sp)
 798:	e05a                	sd	s6,0(sp)
 79a:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 79c:	02051493          	slli	s1,a0,0x20
 7a0:	9081                	srli	s1,s1,0x20
 7a2:	04bd                	addi	s1,s1,15
 7a4:	8091                	srli	s1,s1,0x4
 7a6:	0014899b          	addiw	s3,s1,1
 7aa:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 7ac:	00000517          	auipc	a0,0x0
 7b0:	0f453503          	ld	a0,244(a0) # 8a0 <freep>
 7b4:	c515                	beqz	a0,7e0 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7b6:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7b8:	4798                	lw	a4,8(a5)
 7ba:	02977f63          	bgeu	a4,s1,7f8 <malloc+0x70>
 7be:	8a4e                	mv	s4,s3
 7c0:	0009871b          	sext.w	a4,s3
 7c4:	6685                	lui	a3,0x1
 7c6:	00d77363          	bgeu	a4,a3,7cc <malloc+0x44>
 7ca:	6a05                	lui	s4,0x1
 7cc:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 7d0:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 7d4:	00000917          	auipc	s2,0x0
 7d8:	0cc90913          	addi	s2,s2,204 # 8a0 <freep>
  if(p == (char*)-1)
 7dc:	5afd                	li	s5,-1
 7de:	a895                	j	852 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 7e0:	00000797          	auipc	a5,0x0
 7e4:	0c878793          	addi	a5,a5,200 # 8a8 <base>
 7e8:	00000717          	auipc	a4,0x0
 7ec:	0af73c23          	sd	a5,184(a4) # 8a0 <freep>
 7f0:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7f2:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7f6:	b7e1                	j	7be <malloc+0x36>
      if(p->s.size == nunits)
 7f8:	02e48c63          	beq	s1,a4,830 <malloc+0xa8>
        p->s.size -= nunits;
 7fc:	4137073b          	subw	a4,a4,s3
 800:	c798                	sw	a4,8(a5)
        p += p->s.size;
 802:	02071693          	slli	a3,a4,0x20
 806:	01c6d713          	srli	a4,a3,0x1c
 80a:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 80c:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 810:	00000717          	auipc	a4,0x0
 814:	08a73823          	sd	a0,144(a4) # 8a0 <freep>
      return (void*)(p + 1);
 818:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 81c:	70e2                	ld	ra,56(sp)
 81e:	7442                	ld	s0,48(sp)
 820:	74a2                	ld	s1,40(sp)
 822:	7902                	ld	s2,32(sp)
 824:	69e2                	ld	s3,24(sp)
 826:	6a42                	ld	s4,16(sp)
 828:	6aa2                	ld	s5,8(sp)
 82a:	6b02                	ld	s6,0(sp)
 82c:	6121                	addi	sp,sp,64
 82e:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 830:	6398                	ld	a4,0(a5)
 832:	e118                	sd	a4,0(a0)
 834:	bff1                	j	810 <malloc+0x88>
  hp->s.size = nu;
 836:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 83a:	0541                	addi	a0,a0,16
 83c:	00000097          	auipc	ra,0x0
 840:	ec4080e7          	jalr	-316(ra) # 700 <free>
  return freep;
 844:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 848:	d971                	beqz	a0,81c <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 84a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 84c:	4798                	lw	a4,8(a5)
 84e:	fa9775e3          	bgeu	a4,s1,7f8 <malloc+0x70>
    if(p == freep)
 852:	00093703          	ld	a4,0(s2)
 856:	853e                	mv	a0,a5
 858:	fef719e3          	bne	a4,a5,84a <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 85c:	8552                	mv	a0,s4
 85e:	00000097          	auipc	ra,0x0
 862:	b5c080e7          	jalr	-1188(ra) # 3ba <sbrk>
  if(p == (char*)-1)
 866:	fd5518e3          	bne	a0,s5,836 <malloc+0xae>
        return 0;
 86a:	4501                	li	a0,0
 86c:	bf45                	j	81c <malloc+0x94>

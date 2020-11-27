
user/_find：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000000000000 <fmt_name>:
#include "user/user.h"

/*
	将路径格式化为文件名
*/
char* fmt_name(char *path){
   0:	1101                	addi	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	e426                	sd	s1,8(sp)
   8:	e04a                	sd	s2,0(sp)
   a:	1000                	addi	s0,sp,32
   c:	84aa                	mv	s1,a0
  static char buf[DIRSIZ+1];
  char *p;

  // Find first character after last slash.
  for(p=path+strlen(path); p >= path && *p != '/'; p--);
   e:	00000097          	auipc	ra,0x0
  12:	2de080e7          	jalr	734(ra) # 2ec <strlen>
  16:	02051593          	slli	a1,a0,0x20
  1a:	9181                	srli	a1,a1,0x20
  1c:	95a6                	add	a1,a1,s1
  1e:	02f00713          	li	a4,47
  22:	0095e963          	bltu	a1,s1,34 <fmt_name+0x34>
  26:	0005c783          	lbu	a5,0(a1)
  2a:	00e78563          	beq	a5,a4,34 <fmt_name+0x34>
  2e:	15fd                	addi	a1,a1,-1
  30:	fe95fbe3          	bgeu	a1,s1,26 <fmt_name+0x26>
  p++;
  34:	00158493          	addi	s1,a1,1
  memmove(buf, p, strlen(p)+1);
  38:	8526                	mv	a0,s1
  3a:	00000097          	auipc	ra,0x0
  3e:	2b2080e7          	jalr	690(ra) # 2ec <strlen>
  42:	00001917          	auipc	s2,0x1
  46:	a3690913          	addi	s2,s2,-1482 # a78 <buf.0>
  4a:	0015061b          	addiw	a2,a0,1
  4e:	85a6                	mv	a1,s1
  50:	854a                	mv	a0,s2
  52:	00000097          	auipc	ra,0x0
  56:	40e080e7          	jalr	1038(ra) # 460 <memmove>
  return buf;
}
  5a:	854a                	mv	a0,s2
  5c:	60e2                	ld	ra,24(sp)
  5e:	6442                	ld	s0,16(sp)
  60:	64a2                	ld	s1,8(sp)
  62:	6902                	ld	s2,0(sp)
  64:	6105                	addi	sp,sp,32
  66:	8082                	ret

0000000000000068 <eq_print>:
/*
	系统文件名与要查找的文件名，若一致，打印系统文件完整路径
*/
void eq_print(char *fileName, char *findName){
  68:	1101                	addi	sp,sp,-32
  6a:	ec06                	sd	ra,24(sp)
  6c:	e822                	sd	s0,16(sp)
  6e:	e426                	sd	s1,8(sp)
  70:	e04a                	sd	s2,0(sp)
  72:	1000                	addi	s0,sp,32
  74:	892a                	mv	s2,a0
  76:	84ae                	mv	s1,a1
	if(strcmp(fmt_name(fileName), findName) == 0){
  78:	00000097          	auipc	ra,0x0
  7c:	f88080e7          	jalr	-120(ra) # 0 <fmt_name>
  80:	85a6                	mv	a1,s1
  82:	00000097          	auipc	ra,0x0
  86:	23e080e7          	jalr	574(ra) # 2c0 <strcmp>
  8a:	c519                	beqz	a0,98 <eq_print+0x30>
		printf("%s\n", fileName);
	}
}
  8c:	60e2                	ld	ra,24(sp)
  8e:	6442                	ld	s0,16(sp)
  90:	64a2                	ld	s1,8(sp)
  92:	6902                	ld	s2,0(sp)
  94:	6105                	addi	sp,sp,32
  96:	8082                	ret
		printf("%s\n", fileName);
  98:	85ca                	mv	a1,s2
  9a:	00001517          	auipc	a0,0x1
  9e:	93650513          	addi	a0,a0,-1738 # 9d0 <malloc+0xe8>
  a2:	00000097          	auipc	ra,0x0
  a6:	788080e7          	jalr	1928(ra) # 82a <printf>
}
  aa:	b7cd                	j	8c <eq_print+0x24>

00000000000000ac <find>:
/*
	在某路径中查找某文件
*/
void find(char *path, char *findName){
  ac:	d9010113          	addi	sp,sp,-624
  b0:	26113423          	sd	ra,616(sp)
  b4:	26813023          	sd	s0,608(sp)
  b8:	24913c23          	sd	s1,600(sp)
  bc:	25213823          	sd	s2,592(sp)
  c0:	25313423          	sd	s3,584(sp)
  c4:	25413023          	sd	s4,576(sp)
  c8:	23513c23          	sd	s5,568(sp)
  cc:	23613823          	sd	s6,560(sp)
  d0:	1c80                	addi	s0,sp,624
  d2:	892a                	mv	s2,a0
  d4:	89ae                	mv	s3,a1
	int fd;
	struct stat st;	
	if((fd = open(path, O_RDONLY)) < 0){
  d6:	4581                	li	a1,0
  d8:	00000097          	auipc	ra,0x0
  dc:	3fa080e7          	jalr	1018(ra) # 4d2 <open>
  e0:	06054363          	bltz	a0,146 <find+0x9a>
  e4:	84aa                	mv	s1,a0
		fprintf(2, "find: cannot open %s\n", path);
		return;
	}
	if(fstat(fd, &st) < 0){
  e6:	fa840593          	addi	a1,s0,-88
  ea:	00000097          	auipc	ra,0x0
  ee:	400080e7          	jalr	1024(ra) # 4ea <fstat>
  f2:	06054563          	bltz	a0,15c <find+0xb0>
		close(fd);
		return;
	}
	char buf[512], *p;	
	struct dirent de;
	switch(st.type){	
  f6:	fb041783          	lh	a5,-80(s0)
  fa:	0007869b          	sext.w	a3,a5
  fe:	4705                	li	a4,1
 100:	06e68e63          	beq	a3,a4,17c <find+0xd0>
 104:	4709                	li	a4,2
 106:	00e69863          	bne	a3,a4,116 <find+0x6a>
		case T_FILE:
			eq_print(path, findName);			
 10a:	85ce                	mv	a1,s3
 10c:	854a                	mv	a0,s2
 10e:	00000097          	auipc	ra,0x0
 112:	f5a080e7          	jalr	-166(ra) # 68 <eq_print>
				p[strlen(de.name)] = 0;
				find(buf, findName);
			}
			break;
	}
	close(fd);	
 116:	8526                	mv	a0,s1
 118:	00000097          	auipc	ra,0x0
 11c:	3a2080e7          	jalr	930(ra) # 4ba <close>
}
 120:	26813083          	ld	ra,616(sp)
 124:	26013403          	ld	s0,608(sp)
 128:	25813483          	ld	s1,600(sp)
 12c:	25013903          	ld	s2,592(sp)
 130:	24813983          	ld	s3,584(sp)
 134:	24013a03          	ld	s4,576(sp)
 138:	23813a83          	ld	s5,568(sp)
 13c:	23013b03          	ld	s6,560(sp)
 140:	27010113          	addi	sp,sp,624
 144:	8082                	ret
		fprintf(2, "find: cannot open %s\n", path);
 146:	864a                	mv	a2,s2
 148:	00001597          	auipc	a1,0x1
 14c:	89058593          	addi	a1,a1,-1904 # 9d8 <malloc+0xf0>
 150:	4509                	li	a0,2
 152:	00000097          	auipc	ra,0x0
 156:	6aa080e7          	jalr	1706(ra) # 7fc <fprintf>
		return;
 15a:	b7d9                	j	120 <find+0x74>
		fprintf(2, "find: cannot stat %s\n", path);
 15c:	864a                	mv	a2,s2
 15e:	00001597          	auipc	a1,0x1
 162:	89258593          	addi	a1,a1,-1902 # 9f0 <malloc+0x108>
 166:	4509                	li	a0,2
 168:	00000097          	auipc	ra,0x0
 16c:	694080e7          	jalr	1684(ra) # 7fc <fprintf>
		close(fd);
 170:	8526                	mv	a0,s1
 172:	00000097          	auipc	ra,0x0
 176:	348080e7          	jalr	840(ra) # 4ba <close>
		return;
 17a:	b75d                	j	120 <find+0x74>
			if(strlen(path) + 1 + DIRSIZ + 1 > sizeof buf){
 17c:	854a                	mv	a0,s2
 17e:	00000097          	auipc	ra,0x0
 182:	16e080e7          	jalr	366(ra) # 2ec <strlen>
 186:	2541                	addiw	a0,a0,16
 188:	20000793          	li	a5,512
 18c:	00a7fb63          	bgeu	a5,a0,1a2 <find+0xf6>
				printf("find: path too long\n");
 190:	00001517          	auipc	a0,0x1
 194:	87850513          	addi	a0,a0,-1928 # a08 <malloc+0x120>
 198:	00000097          	auipc	ra,0x0
 19c:	692080e7          	jalr	1682(ra) # 82a <printf>
				break;
 1a0:	bf9d                	j	116 <find+0x6a>
			strcpy(buf, path);
 1a2:	85ca                	mv	a1,s2
 1a4:	da840513          	addi	a0,s0,-600
 1a8:	00000097          	auipc	ra,0x0
 1ac:	0fc080e7          	jalr	252(ra) # 2a4 <strcpy>
			p = buf+strlen(buf);
 1b0:	da840513          	addi	a0,s0,-600
 1b4:	00000097          	auipc	ra,0x0
 1b8:	138080e7          	jalr	312(ra) # 2ec <strlen>
 1bc:	1502                	slli	a0,a0,0x20
 1be:	9101                	srli	a0,a0,0x20
 1c0:	da840793          	addi	a5,s0,-600
 1c4:	953e                	add	a0,a0,a5
			*p++ = '/';
 1c6:	00150a93          	addi	s5,a0,1
 1ca:	02f00793          	li	a5,47
 1ce:	00f50023          	sb	a5,0(a0)
				if(de.inum == 0 || de.inum == 1 || strcmp(de.name, ".")==0 || strcmp(de.name, "..")==0)
 1d2:	4905                	li	s2,1
 1d4:	00001a17          	auipc	s4,0x1
 1d8:	84ca0a13          	addi	s4,s4,-1972 # a20 <malloc+0x138>
 1dc:	00001b17          	auipc	s6,0x1
 1e0:	84cb0b13          	addi	s6,s6,-1972 # a28 <malloc+0x140>
			while(read(fd, &de, sizeof(de)) == sizeof(de)){
 1e4:	4641                	li	a2,16
 1e6:	d9840593          	addi	a1,s0,-616
 1ea:	8526                	mv	a0,s1
 1ec:	00000097          	auipc	ra,0x0
 1f0:	2be080e7          	jalr	702(ra) # 4aa <read>
 1f4:	47c1                	li	a5,16
 1f6:	f2f510e3          	bne	a0,a5,116 <find+0x6a>
				if(de.inum == 0 || de.inum == 1 || strcmp(de.name, ".")==0 || strcmp(de.name, "..")==0)
 1fa:	d9845783          	lhu	a5,-616(s0)
 1fe:	fef973e3          	bgeu	s2,a5,1e4 <find+0x138>
 202:	85d2                	mv	a1,s4
 204:	d9a40513          	addi	a0,s0,-614
 208:	00000097          	auipc	ra,0x0
 20c:	0b8080e7          	jalr	184(ra) # 2c0 <strcmp>
 210:	d971                	beqz	a0,1e4 <find+0x138>
 212:	85da                	mv	a1,s6
 214:	d9a40513          	addi	a0,s0,-614
 218:	00000097          	auipc	ra,0x0
 21c:	0a8080e7          	jalr	168(ra) # 2c0 <strcmp>
 220:	d171                	beqz	a0,1e4 <find+0x138>
				memmove(p, de.name, strlen(de.name));
 222:	d9a40513          	addi	a0,s0,-614
 226:	00000097          	auipc	ra,0x0
 22a:	0c6080e7          	jalr	198(ra) # 2ec <strlen>
 22e:	0005061b          	sext.w	a2,a0
 232:	d9a40593          	addi	a1,s0,-614
 236:	8556                	mv	a0,s5
 238:	00000097          	auipc	ra,0x0
 23c:	228080e7          	jalr	552(ra) # 460 <memmove>
				p[strlen(de.name)] = 0;
 240:	d9a40513          	addi	a0,s0,-614
 244:	00000097          	auipc	ra,0x0
 248:	0a8080e7          	jalr	168(ra) # 2ec <strlen>
 24c:	02051793          	slli	a5,a0,0x20
 250:	9381                	srli	a5,a5,0x20
 252:	97d6                	add	a5,a5,s5
 254:	00078023          	sb	zero,0(a5)
				find(buf, findName);
 258:	85ce                	mv	a1,s3
 25a:	da840513          	addi	a0,s0,-600
 25e:	00000097          	auipc	ra,0x0
 262:	e4e080e7          	jalr	-434(ra) # ac <find>
 266:	bfbd                	j	1e4 <find+0x138>

0000000000000268 <main>:

int main(int argc, char *argv[]){
 268:	1141                	addi	sp,sp,-16
 26a:	e406                	sd	ra,8(sp)
 26c:	e022                	sd	s0,0(sp)
 26e:	0800                	addi	s0,sp,16
	if(argc < 3){
 270:	4709                	li	a4,2
 272:	00a74e63          	blt	a4,a0,28e <main+0x26>
		printf("find: find <path> <fileName>\n");
 276:	00000517          	auipc	a0,0x0
 27a:	7ba50513          	addi	a0,a0,1978 # a30 <malloc+0x148>
 27e:	00000097          	auipc	ra,0x0
 282:	5ac080e7          	jalr	1452(ra) # 82a <printf>
		exit();
 286:	00000097          	auipc	ra,0x0
 28a:	20c080e7          	jalr	524(ra) # 492 <exit>
 28e:	87ae                	mv	a5,a1
	}
	find(argv[1], argv[2]);
 290:	698c                	ld	a1,16(a1)
 292:	6788                	ld	a0,8(a5)
 294:	00000097          	auipc	ra,0x0
 298:	e18080e7          	jalr	-488(ra) # ac <find>
	exit();
 29c:	00000097          	auipc	ra,0x0
 2a0:	1f6080e7          	jalr	502(ra) # 492 <exit>

00000000000002a4 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 2a4:	1141                	addi	sp,sp,-16
 2a6:	e422                	sd	s0,8(sp)
 2a8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 2aa:	87aa                	mv	a5,a0
 2ac:	0585                	addi	a1,a1,1
 2ae:	0785                	addi	a5,a5,1
 2b0:	fff5c703          	lbu	a4,-1(a1)
 2b4:	fee78fa3          	sb	a4,-1(a5)
 2b8:	fb75                	bnez	a4,2ac <strcpy+0x8>
    ;
  return os;
}
 2ba:	6422                	ld	s0,8(sp)
 2bc:	0141                	addi	sp,sp,16
 2be:	8082                	ret

00000000000002c0 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 2c0:	1141                	addi	sp,sp,-16
 2c2:	e422                	sd	s0,8(sp)
 2c4:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 2c6:	00054783          	lbu	a5,0(a0)
 2ca:	cb91                	beqz	a5,2de <strcmp+0x1e>
 2cc:	0005c703          	lbu	a4,0(a1)
 2d0:	00f71763          	bne	a4,a5,2de <strcmp+0x1e>
    p++, q++;
 2d4:	0505                	addi	a0,a0,1
 2d6:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 2d8:	00054783          	lbu	a5,0(a0)
 2dc:	fbe5                	bnez	a5,2cc <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 2de:	0005c503          	lbu	a0,0(a1)
}
 2e2:	40a7853b          	subw	a0,a5,a0
 2e6:	6422                	ld	s0,8(sp)
 2e8:	0141                	addi	sp,sp,16
 2ea:	8082                	ret

00000000000002ec <strlen>:

uint
strlen(const char *s)
{
 2ec:	1141                	addi	sp,sp,-16
 2ee:	e422                	sd	s0,8(sp)
 2f0:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 2f2:	00054783          	lbu	a5,0(a0)
 2f6:	cf91                	beqz	a5,312 <strlen+0x26>
 2f8:	0505                	addi	a0,a0,1
 2fa:	87aa                	mv	a5,a0
 2fc:	4685                	li	a3,1
 2fe:	9e89                	subw	a3,a3,a0
 300:	00f6853b          	addw	a0,a3,a5
 304:	0785                	addi	a5,a5,1
 306:	fff7c703          	lbu	a4,-1(a5)
 30a:	fb7d                	bnez	a4,300 <strlen+0x14>
    ;
  return n;
}
 30c:	6422                	ld	s0,8(sp)
 30e:	0141                	addi	sp,sp,16
 310:	8082                	ret
  for(n = 0; s[n]; n++)
 312:	4501                	li	a0,0
 314:	bfe5                	j	30c <strlen+0x20>

0000000000000316 <memset>:

void*
memset(void *dst, int c, uint n)
{
 316:	1141                	addi	sp,sp,-16
 318:	e422                	sd	s0,8(sp)
 31a:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 31c:	ca19                	beqz	a2,332 <memset+0x1c>
 31e:	87aa                	mv	a5,a0
 320:	1602                	slli	a2,a2,0x20
 322:	9201                	srli	a2,a2,0x20
 324:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 328:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 32c:	0785                	addi	a5,a5,1
 32e:	fee79de3          	bne	a5,a4,328 <memset+0x12>
  }
  return dst;
}
 332:	6422                	ld	s0,8(sp)
 334:	0141                	addi	sp,sp,16
 336:	8082                	ret

0000000000000338 <strchr>:

char*
strchr(const char *s, char c)
{
 338:	1141                	addi	sp,sp,-16
 33a:	e422                	sd	s0,8(sp)
 33c:	0800                	addi	s0,sp,16
  for(; *s; s++)
 33e:	00054783          	lbu	a5,0(a0)
 342:	cb99                	beqz	a5,358 <strchr+0x20>
    if(*s == c)
 344:	00f58763          	beq	a1,a5,352 <strchr+0x1a>
  for(; *s; s++)
 348:	0505                	addi	a0,a0,1
 34a:	00054783          	lbu	a5,0(a0)
 34e:	fbfd                	bnez	a5,344 <strchr+0xc>
      return (char*)s;
  return 0;
 350:	4501                	li	a0,0
}
 352:	6422                	ld	s0,8(sp)
 354:	0141                	addi	sp,sp,16
 356:	8082                	ret
  return 0;
 358:	4501                	li	a0,0
 35a:	bfe5                	j	352 <strchr+0x1a>

000000000000035c <gets>:

char*
gets(char *buf, int max)
{
 35c:	711d                	addi	sp,sp,-96
 35e:	ec86                	sd	ra,88(sp)
 360:	e8a2                	sd	s0,80(sp)
 362:	e4a6                	sd	s1,72(sp)
 364:	e0ca                	sd	s2,64(sp)
 366:	fc4e                	sd	s3,56(sp)
 368:	f852                	sd	s4,48(sp)
 36a:	f456                	sd	s5,40(sp)
 36c:	f05a                	sd	s6,32(sp)
 36e:	ec5e                	sd	s7,24(sp)
 370:	1080                	addi	s0,sp,96
 372:	8baa                	mv	s7,a0
 374:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 376:	892a                	mv	s2,a0
 378:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 37a:	4aa9                	li	s5,10
 37c:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 37e:	89a6                	mv	s3,s1
 380:	2485                	addiw	s1,s1,1
 382:	0344d863          	bge	s1,s4,3b2 <gets+0x56>
    cc = read(0, &c, 1);
 386:	4605                	li	a2,1
 388:	faf40593          	addi	a1,s0,-81
 38c:	4501                	li	a0,0
 38e:	00000097          	auipc	ra,0x0
 392:	11c080e7          	jalr	284(ra) # 4aa <read>
    if(cc < 1)
 396:	00a05e63          	blez	a0,3b2 <gets+0x56>
    buf[i++] = c;
 39a:	faf44783          	lbu	a5,-81(s0)
 39e:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 3a2:	01578763          	beq	a5,s5,3b0 <gets+0x54>
 3a6:	0905                	addi	s2,s2,1
 3a8:	fd679be3          	bne	a5,s6,37e <gets+0x22>
  for(i=0; i+1 < max; ){
 3ac:	89a6                	mv	s3,s1
 3ae:	a011                	j	3b2 <gets+0x56>
 3b0:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 3b2:	99de                	add	s3,s3,s7
 3b4:	00098023          	sb	zero,0(s3)
  return buf;
}
 3b8:	855e                	mv	a0,s7
 3ba:	60e6                	ld	ra,88(sp)
 3bc:	6446                	ld	s0,80(sp)
 3be:	64a6                	ld	s1,72(sp)
 3c0:	6906                	ld	s2,64(sp)
 3c2:	79e2                	ld	s3,56(sp)
 3c4:	7a42                	ld	s4,48(sp)
 3c6:	7aa2                	ld	s5,40(sp)
 3c8:	7b02                	ld	s6,32(sp)
 3ca:	6be2                	ld	s7,24(sp)
 3cc:	6125                	addi	sp,sp,96
 3ce:	8082                	ret

00000000000003d0 <stat>:

int
stat(const char *n, struct stat *st)
{
 3d0:	1101                	addi	sp,sp,-32
 3d2:	ec06                	sd	ra,24(sp)
 3d4:	e822                	sd	s0,16(sp)
 3d6:	e426                	sd	s1,8(sp)
 3d8:	e04a                	sd	s2,0(sp)
 3da:	1000                	addi	s0,sp,32
 3dc:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 3de:	4581                	li	a1,0
 3e0:	00000097          	auipc	ra,0x0
 3e4:	0f2080e7          	jalr	242(ra) # 4d2 <open>
  if(fd < 0)
 3e8:	02054563          	bltz	a0,412 <stat+0x42>
 3ec:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 3ee:	85ca                	mv	a1,s2
 3f0:	00000097          	auipc	ra,0x0
 3f4:	0fa080e7          	jalr	250(ra) # 4ea <fstat>
 3f8:	892a                	mv	s2,a0
  close(fd);
 3fa:	8526                	mv	a0,s1
 3fc:	00000097          	auipc	ra,0x0
 400:	0be080e7          	jalr	190(ra) # 4ba <close>
  return r;
}
 404:	854a                	mv	a0,s2
 406:	60e2                	ld	ra,24(sp)
 408:	6442                	ld	s0,16(sp)
 40a:	64a2                	ld	s1,8(sp)
 40c:	6902                	ld	s2,0(sp)
 40e:	6105                	addi	sp,sp,32
 410:	8082                	ret
    return -1;
 412:	597d                	li	s2,-1
 414:	bfc5                	j	404 <stat+0x34>

0000000000000416 <atoi>:

int
atoi(const char *s)
{
 416:	1141                	addi	sp,sp,-16
 418:	e422                	sd	s0,8(sp)
 41a:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 41c:	00054603          	lbu	a2,0(a0)
 420:	fd06079b          	addiw	a5,a2,-48
 424:	0ff7f793          	andi	a5,a5,255
 428:	4725                	li	a4,9
 42a:	02f76963          	bltu	a4,a5,45c <atoi+0x46>
 42e:	86aa                	mv	a3,a0
  n = 0;
 430:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 432:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 434:	0685                	addi	a3,a3,1
 436:	0025179b          	slliw	a5,a0,0x2
 43a:	9fa9                	addw	a5,a5,a0
 43c:	0017979b          	slliw	a5,a5,0x1
 440:	9fb1                	addw	a5,a5,a2
 442:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 446:	0006c603          	lbu	a2,0(a3)
 44a:	fd06071b          	addiw	a4,a2,-48
 44e:	0ff77713          	andi	a4,a4,255
 452:	fee5f1e3          	bgeu	a1,a4,434 <atoi+0x1e>
  return n;
}
 456:	6422                	ld	s0,8(sp)
 458:	0141                	addi	sp,sp,16
 45a:	8082                	ret
  n = 0;
 45c:	4501                	li	a0,0
 45e:	bfe5                	j	456 <atoi+0x40>

0000000000000460 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 460:	1141                	addi	sp,sp,-16
 462:	e422                	sd	s0,8(sp)
 464:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  while(n-- > 0)
 466:	00c05f63          	blez	a2,484 <memmove+0x24>
 46a:	1602                	slli	a2,a2,0x20
 46c:	9201                	srli	a2,a2,0x20
 46e:	00c506b3          	add	a3,a0,a2
  dst = vdst;
 472:	87aa                	mv	a5,a0
    *dst++ = *src++;
 474:	0585                	addi	a1,a1,1
 476:	0785                	addi	a5,a5,1
 478:	fff5c703          	lbu	a4,-1(a1)
 47c:	fee78fa3          	sb	a4,-1(a5)
  while(n-- > 0)
 480:	fed79ae3          	bne	a5,a3,474 <memmove+0x14>
  return vdst;
}
 484:	6422                	ld	s0,8(sp)
 486:	0141                	addi	sp,sp,16
 488:	8082                	ret

000000000000048a <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 48a:	4885                	li	a7,1
 ecall
 48c:	00000073          	ecall
 ret
 490:	8082                	ret

0000000000000492 <exit>:
.global exit
exit:
 li a7, SYS_exit
 492:	4889                	li	a7,2
 ecall
 494:	00000073          	ecall
 ret
 498:	8082                	ret

000000000000049a <wait>:
.global wait
wait:
 li a7, SYS_wait
 49a:	488d                	li	a7,3
 ecall
 49c:	00000073          	ecall
 ret
 4a0:	8082                	ret

00000000000004a2 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 4a2:	4891                	li	a7,4
 ecall
 4a4:	00000073          	ecall
 ret
 4a8:	8082                	ret

00000000000004aa <read>:
.global read
read:
 li a7, SYS_read
 4aa:	4895                	li	a7,5
 ecall
 4ac:	00000073          	ecall
 ret
 4b0:	8082                	ret

00000000000004b2 <write>:
.global write
write:
 li a7, SYS_write
 4b2:	48c1                	li	a7,16
 ecall
 4b4:	00000073          	ecall
 ret
 4b8:	8082                	ret

00000000000004ba <close>:
.global close
close:
 li a7, SYS_close
 4ba:	48d5                	li	a7,21
 ecall
 4bc:	00000073          	ecall
 ret
 4c0:	8082                	ret

00000000000004c2 <kill>:
.global kill
kill:
 li a7, SYS_kill
 4c2:	4899                	li	a7,6
 ecall
 4c4:	00000073          	ecall
 ret
 4c8:	8082                	ret

00000000000004ca <exec>:
.global exec
exec:
 li a7, SYS_exec
 4ca:	489d                	li	a7,7
 ecall
 4cc:	00000073          	ecall
 ret
 4d0:	8082                	ret

00000000000004d2 <open>:
.global open
open:
 li a7, SYS_open
 4d2:	48bd                	li	a7,15
 ecall
 4d4:	00000073          	ecall
 ret
 4d8:	8082                	ret

00000000000004da <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 4da:	48c5                	li	a7,17
 ecall
 4dc:	00000073          	ecall
 ret
 4e0:	8082                	ret

00000000000004e2 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 4e2:	48c9                	li	a7,18
 ecall
 4e4:	00000073          	ecall
 ret
 4e8:	8082                	ret

00000000000004ea <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 4ea:	48a1                	li	a7,8
 ecall
 4ec:	00000073          	ecall
 ret
 4f0:	8082                	ret

00000000000004f2 <link>:
.global link
link:
 li a7, SYS_link
 4f2:	48cd                	li	a7,19
 ecall
 4f4:	00000073          	ecall
 ret
 4f8:	8082                	ret

00000000000004fa <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 4fa:	48d1                	li	a7,20
 ecall
 4fc:	00000073          	ecall
 ret
 500:	8082                	ret

0000000000000502 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 502:	48a5                	li	a7,9
 ecall
 504:	00000073          	ecall
 ret
 508:	8082                	ret

000000000000050a <dup>:
.global dup
dup:
 li a7, SYS_dup
 50a:	48a9                	li	a7,10
 ecall
 50c:	00000073          	ecall
 ret
 510:	8082                	ret

0000000000000512 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 512:	48ad                	li	a7,11
 ecall
 514:	00000073          	ecall
 ret
 518:	8082                	ret

000000000000051a <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 51a:	48b1                	li	a7,12
 ecall
 51c:	00000073          	ecall
 ret
 520:	8082                	ret

0000000000000522 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 522:	48b5                	li	a7,13
 ecall
 524:	00000073          	ecall
 ret
 528:	8082                	ret

000000000000052a <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 52a:	48b9                	li	a7,14
 ecall
 52c:	00000073          	ecall
 ret
 530:	8082                	ret

0000000000000532 <ntas>:
.global ntas
ntas:
 li a7, SYS_ntas
 532:	48d9                	li	a7,22
 ecall
 534:	00000073          	ecall
 ret
 538:	8082                	ret

000000000000053a <crash>:
.global crash
crash:
 li a7, SYS_crash
 53a:	48dd                	li	a7,23
 ecall
 53c:	00000073          	ecall
 ret
 540:	8082                	ret

0000000000000542 <mount>:
.global mount
mount:
 li a7, SYS_mount
 542:	48e1                	li	a7,24
 ecall
 544:	00000073          	ecall
 ret
 548:	8082                	ret

000000000000054a <umount>:
.global umount
umount:
 li a7, SYS_umount
 54a:	48e5                	li	a7,25
 ecall
 54c:	00000073          	ecall
 ret
 550:	8082                	ret

0000000000000552 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 552:	1101                	addi	sp,sp,-32
 554:	ec06                	sd	ra,24(sp)
 556:	e822                	sd	s0,16(sp)
 558:	1000                	addi	s0,sp,32
 55a:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 55e:	4605                	li	a2,1
 560:	fef40593          	addi	a1,s0,-17
 564:	00000097          	auipc	ra,0x0
 568:	f4e080e7          	jalr	-178(ra) # 4b2 <write>
}
 56c:	60e2                	ld	ra,24(sp)
 56e:	6442                	ld	s0,16(sp)
 570:	6105                	addi	sp,sp,32
 572:	8082                	ret

0000000000000574 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 574:	7139                	addi	sp,sp,-64
 576:	fc06                	sd	ra,56(sp)
 578:	f822                	sd	s0,48(sp)
 57a:	f426                	sd	s1,40(sp)
 57c:	f04a                	sd	s2,32(sp)
 57e:	ec4e                	sd	s3,24(sp)
 580:	0080                	addi	s0,sp,64
 582:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 584:	c299                	beqz	a3,58a <printint+0x16>
 586:	0805c863          	bltz	a1,616 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 58a:	2581                	sext.w	a1,a1
  neg = 0;
 58c:	4881                	li	a7,0
 58e:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 592:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 594:	2601                	sext.w	a2,a2
 596:	00000517          	auipc	a0,0x0
 59a:	4c250513          	addi	a0,a0,1218 # a58 <digits>
 59e:	883a                	mv	a6,a4
 5a0:	2705                	addiw	a4,a4,1
 5a2:	02c5f7bb          	remuw	a5,a1,a2
 5a6:	1782                	slli	a5,a5,0x20
 5a8:	9381                	srli	a5,a5,0x20
 5aa:	97aa                	add	a5,a5,a0
 5ac:	0007c783          	lbu	a5,0(a5)
 5b0:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 5b4:	0005879b          	sext.w	a5,a1
 5b8:	02c5d5bb          	divuw	a1,a1,a2
 5bc:	0685                	addi	a3,a3,1
 5be:	fec7f0e3          	bgeu	a5,a2,59e <printint+0x2a>
  if(neg)
 5c2:	00088b63          	beqz	a7,5d8 <printint+0x64>
    buf[i++] = '-';
 5c6:	fd040793          	addi	a5,s0,-48
 5ca:	973e                	add	a4,a4,a5
 5cc:	02d00793          	li	a5,45
 5d0:	fef70823          	sb	a5,-16(a4)
 5d4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 5d8:	02e05863          	blez	a4,608 <printint+0x94>
 5dc:	fc040793          	addi	a5,s0,-64
 5e0:	00e78933          	add	s2,a5,a4
 5e4:	fff78993          	addi	s3,a5,-1
 5e8:	99ba                	add	s3,s3,a4
 5ea:	377d                	addiw	a4,a4,-1
 5ec:	1702                	slli	a4,a4,0x20
 5ee:	9301                	srli	a4,a4,0x20
 5f0:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 5f4:	fff94583          	lbu	a1,-1(s2)
 5f8:	8526                	mv	a0,s1
 5fa:	00000097          	auipc	ra,0x0
 5fe:	f58080e7          	jalr	-168(ra) # 552 <putc>
  while(--i >= 0)
 602:	197d                	addi	s2,s2,-1
 604:	ff3918e3          	bne	s2,s3,5f4 <printint+0x80>
}
 608:	70e2                	ld	ra,56(sp)
 60a:	7442                	ld	s0,48(sp)
 60c:	74a2                	ld	s1,40(sp)
 60e:	7902                	ld	s2,32(sp)
 610:	69e2                	ld	s3,24(sp)
 612:	6121                	addi	sp,sp,64
 614:	8082                	ret
    x = -xx;
 616:	40b005bb          	negw	a1,a1
    neg = 1;
 61a:	4885                	li	a7,1
    x = -xx;
 61c:	bf8d                	j	58e <printint+0x1a>

000000000000061e <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 61e:	7119                	addi	sp,sp,-128
 620:	fc86                	sd	ra,120(sp)
 622:	f8a2                	sd	s0,112(sp)
 624:	f4a6                	sd	s1,104(sp)
 626:	f0ca                	sd	s2,96(sp)
 628:	ecce                	sd	s3,88(sp)
 62a:	e8d2                	sd	s4,80(sp)
 62c:	e4d6                	sd	s5,72(sp)
 62e:	e0da                	sd	s6,64(sp)
 630:	fc5e                	sd	s7,56(sp)
 632:	f862                	sd	s8,48(sp)
 634:	f466                	sd	s9,40(sp)
 636:	f06a                	sd	s10,32(sp)
 638:	ec6e                	sd	s11,24(sp)
 63a:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 63c:	0005c903          	lbu	s2,0(a1)
 640:	18090f63          	beqz	s2,7de <vprintf+0x1c0>
 644:	8aaa                	mv	s5,a0
 646:	8b32                	mv	s6,a2
 648:	00158493          	addi	s1,a1,1
  state = 0;
 64c:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 64e:	02500a13          	li	s4,37
      if(c == 'd'){
 652:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 656:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 65a:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 65e:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 662:	00000b97          	auipc	s7,0x0
 666:	3f6b8b93          	addi	s7,s7,1014 # a58 <digits>
 66a:	a839                	j	688 <vprintf+0x6a>
        putc(fd, c);
 66c:	85ca                	mv	a1,s2
 66e:	8556                	mv	a0,s5
 670:	00000097          	auipc	ra,0x0
 674:	ee2080e7          	jalr	-286(ra) # 552 <putc>
 678:	a019                	j	67e <vprintf+0x60>
    } else if(state == '%'){
 67a:	01498f63          	beq	s3,s4,698 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 67e:	0485                	addi	s1,s1,1
 680:	fff4c903          	lbu	s2,-1(s1)
 684:	14090d63          	beqz	s2,7de <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 688:	0009079b          	sext.w	a5,s2
    if(state == 0){
 68c:	fe0997e3          	bnez	s3,67a <vprintf+0x5c>
      if(c == '%'){
 690:	fd479ee3          	bne	a5,s4,66c <vprintf+0x4e>
        state = '%';
 694:	89be                	mv	s3,a5
 696:	b7e5                	j	67e <vprintf+0x60>
      if(c == 'd'){
 698:	05878063          	beq	a5,s8,6d8 <vprintf+0xba>
      } else if(c == 'l') {
 69c:	05978c63          	beq	a5,s9,6f4 <vprintf+0xd6>
      } else if(c == 'x') {
 6a0:	07a78863          	beq	a5,s10,710 <vprintf+0xf2>
      } else if(c == 'p') {
 6a4:	09b78463          	beq	a5,s11,72c <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 6a8:	07300713          	li	a4,115
 6ac:	0ce78663          	beq	a5,a4,778 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 6b0:	06300713          	li	a4,99
 6b4:	0ee78e63          	beq	a5,a4,7b0 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 6b8:	11478863          	beq	a5,s4,7c8 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 6bc:	85d2                	mv	a1,s4
 6be:	8556                	mv	a0,s5
 6c0:	00000097          	auipc	ra,0x0
 6c4:	e92080e7          	jalr	-366(ra) # 552 <putc>
        putc(fd, c);
 6c8:	85ca                	mv	a1,s2
 6ca:	8556                	mv	a0,s5
 6cc:	00000097          	auipc	ra,0x0
 6d0:	e86080e7          	jalr	-378(ra) # 552 <putc>
      }
      state = 0;
 6d4:	4981                	li	s3,0
 6d6:	b765                	j	67e <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 6d8:	008b0913          	addi	s2,s6,8
 6dc:	4685                	li	a3,1
 6de:	4629                	li	a2,10
 6e0:	000b2583          	lw	a1,0(s6)
 6e4:	8556                	mv	a0,s5
 6e6:	00000097          	auipc	ra,0x0
 6ea:	e8e080e7          	jalr	-370(ra) # 574 <printint>
 6ee:	8b4a                	mv	s6,s2
      state = 0;
 6f0:	4981                	li	s3,0
 6f2:	b771                	j	67e <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 6f4:	008b0913          	addi	s2,s6,8
 6f8:	4681                	li	a3,0
 6fa:	4629                	li	a2,10
 6fc:	000b2583          	lw	a1,0(s6)
 700:	8556                	mv	a0,s5
 702:	00000097          	auipc	ra,0x0
 706:	e72080e7          	jalr	-398(ra) # 574 <printint>
 70a:	8b4a                	mv	s6,s2
      state = 0;
 70c:	4981                	li	s3,0
 70e:	bf85                	j	67e <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 710:	008b0913          	addi	s2,s6,8
 714:	4681                	li	a3,0
 716:	4641                	li	a2,16
 718:	000b2583          	lw	a1,0(s6)
 71c:	8556                	mv	a0,s5
 71e:	00000097          	auipc	ra,0x0
 722:	e56080e7          	jalr	-426(ra) # 574 <printint>
 726:	8b4a                	mv	s6,s2
      state = 0;
 728:	4981                	li	s3,0
 72a:	bf91                	j	67e <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 72c:	008b0793          	addi	a5,s6,8
 730:	f8f43423          	sd	a5,-120(s0)
 734:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 738:	03000593          	li	a1,48
 73c:	8556                	mv	a0,s5
 73e:	00000097          	auipc	ra,0x0
 742:	e14080e7          	jalr	-492(ra) # 552 <putc>
  putc(fd, 'x');
 746:	85ea                	mv	a1,s10
 748:	8556                	mv	a0,s5
 74a:	00000097          	auipc	ra,0x0
 74e:	e08080e7          	jalr	-504(ra) # 552 <putc>
 752:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 754:	03c9d793          	srli	a5,s3,0x3c
 758:	97de                	add	a5,a5,s7
 75a:	0007c583          	lbu	a1,0(a5)
 75e:	8556                	mv	a0,s5
 760:	00000097          	auipc	ra,0x0
 764:	df2080e7          	jalr	-526(ra) # 552 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 768:	0992                	slli	s3,s3,0x4
 76a:	397d                	addiw	s2,s2,-1
 76c:	fe0914e3          	bnez	s2,754 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 770:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 774:	4981                	li	s3,0
 776:	b721                	j	67e <vprintf+0x60>
        s = va_arg(ap, char*);
 778:	008b0993          	addi	s3,s6,8
 77c:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 780:	02090163          	beqz	s2,7a2 <vprintf+0x184>
        while(*s != 0){
 784:	00094583          	lbu	a1,0(s2)
 788:	c9a1                	beqz	a1,7d8 <vprintf+0x1ba>
          putc(fd, *s);
 78a:	8556                	mv	a0,s5
 78c:	00000097          	auipc	ra,0x0
 790:	dc6080e7          	jalr	-570(ra) # 552 <putc>
          s++;
 794:	0905                	addi	s2,s2,1
        while(*s != 0){
 796:	00094583          	lbu	a1,0(s2)
 79a:	f9e5                	bnez	a1,78a <vprintf+0x16c>
        s = va_arg(ap, char*);
 79c:	8b4e                	mv	s6,s3
      state = 0;
 79e:	4981                	li	s3,0
 7a0:	bdf9                	j	67e <vprintf+0x60>
          s = "(null)";
 7a2:	00000917          	auipc	s2,0x0
 7a6:	2ae90913          	addi	s2,s2,686 # a50 <malloc+0x168>
        while(*s != 0){
 7aa:	02800593          	li	a1,40
 7ae:	bff1                	j	78a <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 7b0:	008b0913          	addi	s2,s6,8
 7b4:	000b4583          	lbu	a1,0(s6)
 7b8:	8556                	mv	a0,s5
 7ba:	00000097          	auipc	ra,0x0
 7be:	d98080e7          	jalr	-616(ra) # 552 <putc>
 7c2:	8b4a                	mv	s6,s2
      state = 0;
 7c4:	4981                	li	s3,0
 7c6:	bd65                	j	67e <vprintf+0x60>
        putc(fd, c);
 7c8:	85d2                	mv	a1,s4
 7ca:	8556                	mv	a0,s5
 7cc:	00000097          	auipc	ra,0x0
 7d0:	d86080e7          	jalr	-634(ra) # 552 <putc>
      state = 0;
 7d4:	4981                	li	s3,0
 7d6:	b565                	j	67e <vprintf+0x60>
        s = va_arg(ap, char*);
 7d8:	8b4e                	mv	s6,s3
      state = 0;
 7da:	4981                	li	s3,0
 7dc:	b54d                	j	67e <vprintf+0x60>
    }
  }
}
 7de:	70e6                	ld	ra,120(sp)
 7e0:	7446                	ld	s0,112(sp)
 7e2:	74a6                	ld	s1,104(sp)
 7e4:	7906                	ld	s2,96(sp)
 7e6:	69e6                	ld	s3,88(sp)
 7e8:	6a46                	ld	s4,80(sp)
 7ea:	6aa6                	ld	s5,72(sp)
 7ec:	6b06                	ld	s6,64(sp)
 7ee:	7be2                	ld	s7,56(sp)
 7f0:	7c42                	ld	s8,48(sp)
 7f2:	7ca2                	ld	s9,40(sp)
 7f4:	7d02                	ld	s10,32(sp)
 7f6:	6de2                	ld	s11,24(sp)
 7f8:	6109                	addi	sp,sp,128
 7fa:	8082                	ret

00000000000007fc <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 7fc:	715d                	addi	sp,sp,-80
 7fe:	ec06                	sd	ra,24(sp)
 800:	e822                	sd	s0,16(sp)
 802:	1000                	addi	s0,sp,32
 804:	e010                	sd	a2,0(s0)
 806:	e414                	sd	a3,8(s0)
 808:	e818                	sd	a4,16(s0)
 80a:	ec1c                	sd	a5,24(s0)
 80c:	03043023          	sd	a6,32(s0)
 810:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 814:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 818:	8622                	mv	a2,s0
 81a:	00000097          	auipc	ra,0x0
 81e:	e04080e7          	jalr	-508(ra) # 61e <vprintf>
}
 822:	60e2                	ld	ra,24(sp)
 824:	6442                	ld	s0,16(sp)
 826:	6161                	addi	sp,sp,80
 828:	8082                	ret

000000000000082a <printf>:

void
printf(const char *fmt, ...)
{
 82a:	711d                	addi	sp,sp,-96
 82c:	ec06                	sd	ra,24(sp)
 82e:	e822                	sd	s0,16(sp)
 830:	1000                	addi	s0,sp,32
 832:	e40c                	sd	a1,8(s0)
 834:	e810                	sd	a2,16(s0)
 836:	ec14                	sd	a3,24(s0)
 838:	f018                	sd	a4,32(s0)
 83a:	f41c                	sd	a5,40(s0)
 83c:	03043823          	sd	a6,48(s0)
 840:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 844:	00840613          	addi	a2,s0,8
 848:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 84c:	85aa                	mv	a1,a0
 84e:	4505                	li	a0,1
 850:	00000097          	auipc	ra,0x0
 854:	dce080e7          	jalr	-562(ra) # 61e <vprintf>
}
 858:	60e2                	ld	ra,24(sp)
 85a:	6442                	ld	s0,16(sp)
 85c:	6125                	addi	sp,sp,96
 85e:	8082                	ret

0000000000000860 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 860:	1141                	addi	sp,sp,-16
 862:	e422                	sd	s0,8(sp)
 864:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 866:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 86a:	00000797          	auipc	a5,0x0
 86e:	2067b783          	ld	a5,518(a5) # a70 <freep>
 872:	a805                	j	8a2 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 874:	4618                	lw	a4,8(a2)
 876:	9db9                	addw	a1,a1,a4
 878:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 87c:	6398                	ld	a4,0(a5)
 87e:	6318                	ld	a4,0(a4)
 880:	fee53823          	sd	a4,-16(a0)
 884:	a091                	j	8c8 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 886:	ff852703          	lw	a4,-8(a0)
 88a:	9e39                	addw	a2,a2,a4
 88c:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 88e:	ff053703          	ld	a4,-16(a0)
 892:	e398                	sd	a4,0(a5)
 894:	a099                	j	8da <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 896:	6398                	ld	a4,0(a5)
 898:	00e7e463          	bltu	a5,a4,8a0 <free+0x40>
 89c:	00e6ea63          	bltu	a3,a4,8b0 <free+0x50>
{
 8a0:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 8a2:	fed7fae3          	bgeu	a5,a3,896 <free+0x36>
 8a6:	6398                	ld	a4,0(a5)
 8a8:	00e6e463          	bltu	a3,a4,8b0 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 8ac:	fee7eae3          	bltu	a5,a4,8a0 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 8b0:	ff852583          	lw	a1,-8(a0)
 8b4:	6390                	ld	a2,0(a5)
 8b6:	02059813          	slli	a6,a1,0x20
 8ba:	01c85713          	srli	a4,a6,0x1c
 8be:	9736                	add	a4,a4,a3
 8c0:	fae60ae3          	beq	a2,a4,874 <free+0x14>
    bp->s.ptr = p->s.ptr;
 8c4:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 8c8:	4790                	lw	a2,8(a5)
 8ca:	02061593          	slli	a1,a2,0x20
 8ce:	01c5d713          	srli	a4,a1,0x1c
 8d2:	973e                	add	a4,a4,a5
 8d4:	fae689e3          	beq	a3,a4,886 <free+0x26>
  } else
    p->s.ptr = bp;
 8d8:	e394                	sd	a3,0(a5)
  freep = p;
 8da:	00000717          	auipc	a4,0x0
 8de:	18f73b23          	sd	a5,406(a4) # a70 <freep>
}
 8e2:	6422                	ld	s0,8(sp)
 8e4:	0141                	addi	sp,sp,16
 8e6:	8082                	ret

00000000000008e8 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 8e8:	7139                	addi	sp,sp,-64
 8ea:	fc06                	sd	ra,56(sp)
 8ec:	f822                	sd	s0,48(sp)
 8ee:	f426                	sd	s1,40(sp)
 8f0:	f04a                	sd	s2,32(sp)
 8f2:	ec4e                	sd	s3,24(sp)
 8f4:	e852                	sd	s4,16(sp)
 8f6:	e456                	sd	s5,8(sp)
 8f8:	e05a                	sd	s6,0(sp)
 8fa:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 8fc:	02051493          	slli	s1,a0,0x20
 900:	9081                	srli	s1,s1,0x20
 902:	04bd                	addi	s1,s1,15
 904:	8091                	srli	s1,s1,0x4
 906:	0014899b          	addiw	s3,s1,1
 90a:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 90c:	00000517          	auipc	a0,0x0
 910:	16453503          	ld	a0,356(a0) # a70 <freep>
 914:	c515                	beqz	a0,940 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 916:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 918:	4798                	lw	a4,8(a5)
 91a:	02977f63          	bgeu	a4,s1,958 <malloc+0x70>
 91e:	8a4e                	mv	s4,s3
 920:	0009871b          	sext.w	a4,s3
 924:	6685                	lui	a3,0x1
 926:	00d77363          	bgeu	a4,a3,92c <malloc+0x44>
 92a:	6a05                	lui	s4,0x1
 92c:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 930:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 934:	00000917          	auipc	s2,0x0
 938:	13c90913          	addi	s2,s2,316 # a70 <freep>
  if(p == (char*)-1)
 93c:	5afd                	li	s5,-1
 93e:	a895                	j	9b2 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 940:	00000797          	auipc	a5,0x0
 944:	14878793          	addi	a5,a5,328 # a88 <base>
 948:	00000717          	auipc	a4,0x0
 94c:	12f73423          	sd	a5,296(a4) # a70 <freep>
 950:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 952:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 956:	b7e1                	j	91e <malloc+0x36>
      if(p->s.size == nunits)
 958:	02e48c63          	beq	s1,a4,990 <malloc+0xa8>
        p->s.size -= nunits;
 95c:	4137073b          	subw	a4,a4,s3
 960:	c798                	sw	a4,8(a5)
        p += p->s.size;
 962:	02071693          	slli	a3,a4,0x20
 966:	01c6d713          	srli	a4,a3,0x1c
 96a:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 96c:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 970:	00000717          	auipc	a4,0x0
 974:	10a73023          	sd	a0,256(a4) # a70 <freep>
      return (void*)(p + 1);
 978:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 97c:	70e2                	ld	ra,56(sp)
 97e:	7442                	ld	s0,48(sp)
 980:	74a2                	ld	s1,40(sp)
 982:	7902                	ld	s2,32(sp)
 984:	69e2                	ld	s3,24(sp)
 986:	6a42                	ld	s4,16(sp)
 988:	6aa2                	ld	s5,8(sp)
 98a:	6b02                	ld	s6,0(sp)
 98c:	6121                	addi	sp,sp,64
 98e:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 990:	6398                	ld	a4,0(a5)
 992:	e118                	sd	a4,0(a0)
 994:	bff1                	j	970 <malloc+0x88>
  hp->s.size = nu;
 996:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 99a:	0541                	addi	a0,a0,16
 99c:	00000097          	auipc	ra,0x0
 9a0:	ec4080e7          	jalr	-316(ra) # 860 <free>
  return freep;
 9a4:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 9a8:	d971                	beqz	a0,97c <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 9aa:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 9ac:	4798                	lw	a4,8(a5)
 9ae:	fa9775e3          	bgeu	a4,s1,958 <malloc+0x70>
    if(p == freep)
 9b2:	00093703          	ld	a4,0(s2)
 9b6:	853e                	mv	a0,a5
 9b8:	fef719e3          	bne	a4,a5,9aa <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 9bc:	8552                	mv	a0,s4
 9be:	00000097          	auipc	ra,0x0
 9c2:	b5c080e7          	jalr	-1188(ra) # 51a <sbrk>
  if(p == (char*)-1)
 9c6:	fd5518e3          	bne	a0,s5,996 <malloc+0xae>
        return 0;
 9ca:	4501                	li	a0,0
 9cc:	bf45                	j	97c <malloc+0x94>

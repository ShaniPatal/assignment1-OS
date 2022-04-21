
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	95013103          	ld	sp,-1712(sp) # 80008950 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

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
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	00e70713          	addi	a4,a4,14 # 80009060 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	19c78793          	addi	a5,a5,412 # 80006200 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdf7ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00003097          	auipc	ra,0x3
    80000130:	8e2080e7          	jalr	-1822(ra) # 80002a0e <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	0000a517          	auipc	a0,0xa
    80000190:	f0450513          	addi	a0,a0,-252 # 8000a090 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	0000a497          	auipc	s1,0xa
    800001a0:	ef448493          	addi	s1,s1,-268 # 8000a090 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	0000a917          	auipc	s2,0xa
    800001aa:	f8290913          	addi	s2,s2,-126 # 8000a128 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	804080e7          	jalr	-2044(ra) # 800019c8 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	260080e7          	jalr	608(ra) # 80002434 <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	7a8080e7          	jalr	1960(ra) # 800029b8 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	0000a517          	auipc	a0,0xa
    80000228:	e6c50513          	addi	a0,a0,-404 # 8000a090 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	0000a517          	auipc	a0,0xa
    8000023e:	e5650513          	addi	a0,a0,-426 # 8000a090 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	0000a717          	auipc	a4,0xa
    80000276:	eaf72b23          	sw	a5,-330(a4) # 8000a128 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	0000a517          	auipc	a0,0xa
    800002d0:	dc450513          	addi	a0,a0,-572 # 8000a090 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	772080e7          	jalr	1906(ra) # 80002a64 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	0000a517          	auipc	a0,0xa
    800002fe:	d9650513          	addi	a0,a0,-618 # 8000a090 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	0000a717          	auipc	a4,0xa
    80000322:	d7270713          	addi	a4,a4,-654 # 8000a090 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	0000a797          	auipc	a5,0xa
    8000034c:	d4878793          	addi	a5,a5,-696 # 8000a090 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	0000a797          	auipc	a5,0xa
    8000037a:	db27a783          	lw	a5,-590(a5) # 8000a128 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	0000a717          	auipc	a4,0xa
    8000038e:	d0670713          	addi	a4,a4,-762 # 8000a090 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	0000a497          	auipc	s1,0xa
    8000039e:	cf648493          	addi	s1,s1,-778 # 8000a090 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	0000a717          	auipc	a4,0xa
    800003da:	cba70713          	addi	a4,a4,-838 # 8000a090 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	0000a717          	auipc	a4,0xa
    800003f0:	d4f72223          	sw	a5,-700(a4) # 8000a130 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	0000a797          	auipc	a5,0xa
    80000416:	c7e78793          	addi	a5,a5,-898 # 8000a090 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	0000a797          	auipc	a5,0xa
    8000043a:	cec7ab23          	sw	a2,-778(a5) # 8000a12c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	0000a517          	auipc	a0,0xa
    80000442:	cea50513          	addi	a0,a0,-790 # 8000a128 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	196080e7          	jalr	406(ra) # 800025dc <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	0000a517          	auipc	a0,0xa
    80000464:	c3050513          	addi	a0,a0,-976 # 8000a090 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	0001a797          	auipc	a5,0x1a
    8000047c:	23078793          	addi	a5,a5,560 # 8001a6a8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	0000a797          	auipc	a5,0xa
    8000054e:	c007a323          	sw	zero,-1018(a5) # 8000a150 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	df450513          	addi	a0,a0,-524 # 80008360 <digits+0x320>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	0000ad97          	auipc	s11,0xa
    800005be:	b96dad83          	lw	s11,-1130(s11) # 8000a150 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	0000a517          	auipc	a0,0xa
    800005fc:	b4050513          	addi	a0,a0,-1216 # 8000a138 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	0000a517          	auipc	a0,0xa
    80000760:	9dc50513          	addi	a0,a0,-1572 # 8000a138 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	0000a497          	auipc	s1,0xa
    8000077c:	9c048493          	addi	s1,s1,-1600 # 8000a138 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	0000a517          	auipc	a0,0xa
    800007dc:	98050513          	addi	a0,a0,-1664 # 8000a158 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	0000aa17          	auipc	s4,0xa
    8000086e:	8eea0a13          	addi	s4,s4,-1810 # 8000a158 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	d3c080e7          	jalr	-708(ra) # 800025dc <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	0000a517          	auipc	a0,0xa
    800008e0:	87c50513          	addi	a0,a0,-1924 # 8000a158 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	0000aa17          	auipc	s4,0xa
    80000914:	848a0a13          	addi	s4,s4,-1976 # 8000a158 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	b08080e7          	jalr	-1272(ra) # 80002434 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	0000a497          	auipc	s1,0xa
    80000946:	81648493          	addi	s1,s1,-2026 # 8000a158 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00009497          	auipc	s1,0x9
    800009ce:	78e48493          	addi	s1,s1,1934 # 8000a158 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	0001e797          	auipc	a5,0x1e
    80000a10:	5f478793          	addi	a5,a5,1524 # 8001f000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00009917          	auipc	s2,0x9
    80000a30:	76490913          	addi	s2,s2,1892 # 8000a190 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00009517          	auipc	a0,0x9
    80000acc:	6c850513          	addi	a0,a0,1736 # 8000a190 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	0001e517          	auipc	a0,0x1e
    80000ae0:	52450513          	addi	a0,a0,1316 # 8001f000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00009497          	auipc	s1,0x9
    80000b02:	69248493          	addi	s1,s1,1682 # 8000a190 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00009517          	auipc	a0,0x9
    80000b1a:	67a50513          	addi	a0,a0,1658 # 8000a190 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00009517          	auipc	a0,0x9
    80000b46:	64e50513          	addi	a0,a0,1614 # 8000a190 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	e2e080e7          	jalr	-466(ra) # 800019ac <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	dfc080e7          	jalr	-516(ra) # 800019ac <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	df0080e7          	jalr	-528(ra) # 800019ac <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	dd8080e7          	jalr	-552(ra) # 800019ac <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

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
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	d98080e7          	jalr	-616(ra) # 800019ac <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	d6c080e7          	jalr	-660(ra) # 800019ac <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	b06080e7          	jalr	-1274(ra) # 8000199c <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c539                	beqz	a0,80000ef4 <main+0x66>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	aea080e7          	jalr	-1302(ra) # 8000199c <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0e0080e7          	jalr	224(ra) # 80000fac <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	da6080e7          	jalr	-602(ra) # 80002c7a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	364080e7          	jalr	868(ra) # 80006240 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	136080e7          	jalr	310(ra) # 8000201a <scheduler>
}
    80000eec:	60a2                	ld	ra,8(sp)
    80000eee:	6402                	ld	s0,0(sp)
    80000ef0:	0141                	addi	sp,sp,16
    80000ef2:	8082                	ret
    consoleinit();
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	55c080e7          	jalr	1372(ra) # 80000450 <consoleinit>
    printfinit();
    80000efc:	00000097          	auipc	ra,0x0
    80000f00:	872080e7          	jalr	-1934(ra) # 8000076e <printfinit>
    printf("\n");
    80000f04:	00007517          	auipc	a0,0x7
    80000f08:	45c50513          	addi	a0,a0,1116 # 80008360 <digits+0x320>
    80000f0c:	fffff097          	auipc	ra,0xfffff
    80000f10:	67c080e7          	jalr	1660(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f14:	00007517          	auipc	a0,0x7
    80000f18:	18c50513          	addi	a0,a0,396 # 800080a0 <digits+0x60>
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	66c080e7          	jalr	1644(ra) # 80000588 <printf>
    printf("\n");
    80000f24:	00007517          	auipc	a0,0x7
    80000f28:	43c50513          	addi	a0,a0,1084 # 80008360 <digits+0x320>
    80000f2c:	fffff097          	auipc	ra,0xfffff
    80000f30:	65c080e7          	jalr	1628(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	b84080e7          	jalr	-1148(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	322080e7          	jalr	802(ra) # 8000125e <kvminit>
    kvminithart();   // turn on paging
    80000f44:	00000097          	auipc	ra,0x0
    80000f48:	068080e7          	jalr	104(ra) # 80000fac <kvminithart>
    procinit();      // process table
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	990080e7          	jalr	-1648(ra) # 800018dc <procinit>
    trapinit();      // trap vectors
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	cfe080e7          	jalr	-770(ra) # 80002c52 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5c:	00002097          	auipc	ra,0x2
    80000f60:	d1e080e7          	jalr	-738(ra) # 80002c7a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	2c6080e7          	jalr	710(ra) # 8000622a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6c:	00005097          	auipc	ra,0x5
    80000f70:	2d4080e7          	jalr	724(ra) # 80006240 <plicinithart>
    binit();         // buffer cache
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	4ac080e7          	jalr	1196(ra) # 80003420 <binit>
    iinit();         // inode table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	b3c080e7          	jalr	-1220(ra) # 80003ab8 <iinit>
    fileinit();      // file table
    80000f84:	00004097          	auipc	ra,0x4
    80000f88:	ae6080e7          	jalr	-1306(ra) # 80004a6a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	3d6080e7          	jalr	982(ra) # 80006362 <virtio_disk_init>
    userinit();      // first user process
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	d20080e7          	jalr	-736(ra) # 80001cb4 <userinit>
    __sync_synchronize();
    80000f9c:	0ff0000f          	fence
    started = 1;
    80000fa0:	4785                	li	a5,1
    80000fa2:	00008717          	auipc	a4,0x8
    80000fa6:	06f72b23          	sw	a5,118(a4) # 80009018 <started>
    80000faa:	bf2d                	j	80000ee4 <main+0x56>

0000000080000fac <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fac:	1141                	addi	sp,sp,-16
    80000fae:	e422                	sd	s0,8(sp)
    80000fb0:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb2:	00008797          	auipc	a5,0x8
    80000fb6:	06e7b783          	ld	a5,110(a5) # 80009020 <kernel_pagetable>
    80000fba:	83b1                	srli	a5,a5,0xc
    80000fbc:	577d                	li	a4,-1
    80000fbe:	177e                	slli	a4,a4,0x3f
    80000fc0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc2:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fc6:	12000073          	sfence.vma
  sfence_vma();
}
    80000fca:	6422                	ld	s0,8(sp)
    80000fcc:	0141                	addi	sp,sp,16
    80000fce:	8082                	ret

0000000080000fd0 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd0:	7139                	addi	sp,sp,-64
    80000fd2:	fc06                	sd	ra,56(sp)
    80000fd4:	f822                	sd	s0,48(sp)
    80000fd6:	f426                	sd	s1,40(sp)
    80000fd8:	f04a                	sd	s2,32(sp)
    80000fda:	ec4e                	sd	s3,24(sp)
    80000fdc:	e852                	sd	s4,16(sp)
    80000fde:	e456                	sd	s5,8(sp)
    80000fe0:	e05a                	sd	s6,0(sp)
    80000fe2:	0080                	addi	s0,sp,64
    80000fe4:	84aa                	mv	s1,a0
    80000fe6:	89ae                	mv	s3,a1
    80000fe8:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fea:	57fd                	li	a5,-1
    80000fec:	83e9                	srli	a5,a5,0x1a
    80000fee:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff0:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff2:	04b7f263          	bgeu	a5,a1,80001036 <walk+0x66>
    panic("walk");
    80000ff6:	00007517          	auipc	a0,0x7
    80000ffa:	0da50513          	addi	a0,a0,218 # 800080d0 <digits+0x90>
    80000ffe:	fffff097          	auipc	ra,0xfffff
    80001002:	540080e7          	jalr	1344(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001006:	060a8663          	beqz	s5,80001072 <walk+0xa2>
    8000100a:	00000097          	auipc	ra,0x0
    8000100e:	aea080e7          	jalr	-1302(ra) # 80000af4 <kalloc>
    80001012:	84aa                	mv	s1,a0
    80001014:	c529                	beqz	a0,8000105e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001016:	6605                	lui	a2,0x1
    80001018:	4581                	li	a1,0
    8000101a:	00000097          	auipc	ra,0x0
    8000101e:	cc6080e7          	jalr	-826(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001022:	00c4d793          	srli	a5,s1,0xc
    80001026:	07aa                	slli	a5,a5,0xa
    80001028:	0017e793          	ori	a5,a5,1
    8000102c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001030:	3a5d                	addiw	s4,s4,-9
    80001032:	036a0063          	beq	s4,s6,80001052 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001036:	0149d933          	srl	s2,s3,s4
    8000103a:	1ff97913          	andi	s2,s2,511
    8000103e:	090e                	slli	s2,s2,0x3
    80001040:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001042:	00093483          	ld	s1,0(s2)
    80001046:	0014f793          	andi	a5,s1,1
    8000104a:	dfd5                	beqz	a5,80001006 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000104c:	80a9                	srli	s1,s1,0xa
    8000104e:	04b2                	slli	s1,s1,0xc
    80001050:	b7c5                	j	80001030 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001052:	00c9d513          	srli	a0,s3,0xc
    80001056:	1ff57513          	andi	a0,a0,511
    8000105a:	050e                	slli	a0,a0,0x3
    8000105c:	9526                	add	a0,a0,s1
}
    8000105e:	70e2                	ld	ra,56(sp)
    80001060:	7442                	ld	s0,48(sp)
    80001062:	74a2                	ld	s1,40(sp)
    80001064:	7902                	ld	s2,32(sp)
    80001066:	69e2                	ld	s3,24(sp)
    80001068:	6a42                	ld	s4,16(sp)
    8000106a:	6aa2                	ld	s5,8(sp)
    8000106c:	6b02                	ld	s6,0(sp)
    8000106e:	6121                	addi	sp,sp,64
    80001070:	8082                	ret
        return 0;
    80001072:	4501                	li	a0,0
    80001074:	b7ed                	j	8000105e <walk+0x8e>

0000000080001076 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001076:	57fd                	li	a5,-1
    80001078:	83e9                	srli	a5,a5,0x1a
    8000107a:	00b7f463          	bgeu	a5,a1,80001082 <walkaddr+0xc>
    return 0;
    8000107e:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001080:	8082                	ret
{
    80001082:	1141                	addi	sp,sp,-16
    80001084:	e406                	sd	ra,8(sp)
    80001086:	e022                	sd	s0,0(sp)
    80001088:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000108a:	4601                	li	a2,0
    8000108c:	00000097          	auipc	ra,0x0
    80001090:	f44080e7          	jalr	-188(ra) # 80000fd0 <walk>
  if(pte == 0)
    80001094:	c105                	beqz	a0,800010b4 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001096:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001098:	0117f693          	andi	a3,a5,17
    8000109c:	4745                	li	a4,17
    return 0;
    8000109e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a0:	00e68663          	beq	a3,a4,800010ac <walkaddr+0x36>
}
    800010a4:	60a2                	ld	ra,8(sp)
    800010a6:	6402                	ld	s0,0(sp)
    800010a8:	0141                	addi	sp,sp,16
    800010aa:	8082                	ret
  pa = PTE2PA(*pte);
    800010ac:	00a7d513          	srli	a0,a5,0xa
    800010b0:	0532                	slli	a0,a0,0xc
  return pa;
    800010b2:	bfcd                	j	800010a4 <walkaddr+0x2e>
    return 0;
    800010b4:	4501                	li	a0,0
    800010b6:	b7fd                	j	800010a4 <walkaddr+0x2e>

00000000800010b8 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b8:	715d                	addi	sp,sp,-80
    800010ba:	e486                	sd	ra,72(sp)
    800010bc:	e0a2                	sd	s0,64(sp)
    800010be:	fc26                	sd	s1,56(sp)
    800010c0:	f84a                	sd	s2,48(sp)
    800010c2:	f44e                	sd	s3,40(sp)
    800010c4:	f052                	sd	s4,32(sp)
    800010c6:	ec56                	sd	s5,24(sp)
    800010c8:	e85a                	sd	s6,16(sp)
    800010ca:	e45e                	sd	s7,8(sp)
    800010cc:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010ce:	c205                	beqz	a2,800010ee <mappages+0x36>
    800010d0:	8aaa                	mv	s5,a0
    800010d2:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010d4:	77fd                	lui	a5,0xfffff
    800010d6:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010da:	15fd                	addi	a1,a1,-1
    800010dc:	00c589b3          	add	s3,a1,a2
    800010e0:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010e4:	8952                	mv	s2,s4
    800010e6:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ea:	6b85                	lui	s7,0x1
    800010ec:	a015                	j	80001110 <mappages+0x58>
    panic("mappages: size");
    800010ee:	00007517          	auipc	a0,0x7
    800010f2:	fea50513          	addi	a0,a0,-22 # 800080d8 <digits+0x98>
    800010f6:	fffff097          	auipc	ra,0xfffff
    800010fa:	448080e7          	jalr	1096(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010fe:	00007517          	auipc	a0,0x7
    80001102:	fea50513          	addi	a0,a0,-22 # 800080e8 <digits+0xa8>
    80001106:	fffff097          	auipc	ra,0xfffff
    8000110a:	438080e7          	jalr	1080(ra) # 8000053e <panic>
    a += PGSIZE;
    8000110e:	995e                	add	s2,s2,s7
  for(;;){
    80001110:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001114:	4605                	li	a2,1
    80001116:	85ca                	mv	a1,s2
    80001118:	8556                	mv	a0,s5
    8000111a:	00000097          	auipc	ra,0x0
    8000111e:	eb6080e7          	jalr	-330(ra) # 80000fd0 <walk>
    80001122:	cd19                	beqz	a0,80001140 <mappages+0x88>
    if(*pte & PTE_V)
    80001124:	611c                	ld	a5,0(a0)
    80001126:	8b85                	andi	a5,a5,1
    80001128:	fbf9                	bnez	a5,800010fe <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000112a:	80b1                	srli	s1,s1,0xc
    8000112c:	04aa                	slli	s1,s1,0xa
    8000112e:	0164e4b3          	or	s1,s1,s6
    80001132:	0014e493          	ori	s1,s1,1
    80001136:	e104                	sd	s1,0(a0)
    if(a == last)
    80001138:	fd391be3          	bne	s2,s3,8000110e <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    8000113c:	4501                	li	a0,0
    8000113e:	a011                	j	80001142 <mappages+0x8a>
      return -1;
    80001140:	557d                	li	a0,-1
}
    80001142:	60a6                	ld	ra,72(sp)
    80001144:	6406                	ld	s0,64(sp)
    80001146:	74e2                	ld	s1,56(sp)
    80001148:	7942                	ld	s2,48(sp)
    8000114a:	79a2                	ld	s3,40(sp)
    8000114c:	7a02                	ld	s4,32(sp)
    8000114e:	6ae2                	ld	s5,24(sp)
    80001150:	6b42                	ld	s6,16(sp)
    80001152:	6ba2                	ld	s7,8(sp)
    80001154:	6161                	addi	sp,sp,80
    80001156:	8082                	ret

0000000080001158 <kvmmap>:
{
    80001158:	1141                	addi	sp,sp,-16
    8000115a:	e406                	sd	ra,8(sp)
    8000115c:	e022                	sd	s0,0(sp)
    8000115e:	0800                	addi	s0,sp,16
    80001160:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001162:	86b2                	mv	a3,a2
    80001164:	863e                	mv	a2,a5
    80001166:	00000097          	auipc	ra,0x0
    8000116a:	f52080e7          	jalr	-174(ra) # 800010b8 <mappages>
    8000116e:	e509                	bnez	a0,80001178 <kvmmap+0x20>
}
    80001170:	60a2                	ld	ra,8(sp)
    80001172:	6402                	ld	s0,0(sp)
    80001174:	0141                	addi	sp,sp,16
    80001176:	8082                	ret
    panic("kvmmap");
    80001178:	00007517          	auipc	a0,0x7
    8000117c:	f8050513          	addi	a0,a0,-128 # 800080f8 <digits+0xb8>
    80001180:	fffff097          	auipc	ra,0xfffff
    80001184:	3be080e7          	jalr	958(ra) # 8000053e <panic>

0000000080001188 <kvmmake>:
{
    80001188:	1101                	addi	sp,sp,-32
    8000118a:	ec06                	sd	ra,24(sp)
    8000118c:	e822                	sd	s0,16(sp)
    8000118e:	e426                	sd	s1,8(sp)
    80001190:	e04a                	sd	s2,0(sp)
    80001192:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001194:	00000097          	auipc	ra,0x0
    80001198:	960080e7          	jalr	-1696(ra) # 80000af4 <kalloc>
    8000119c:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000119e:	6605                	lui	a2,0x1
    800011a0:	4581                	li	a1,0
    800011a2:	00000097          	auipc	ra,0x0
    800011a6:	b3e080e7          	jalr	-1218(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011aa:	4719                	li	a4,6
    800011ac:	6685                	lui	a3,0x1
    800011ae:	10000637          	lui	a2,0x10000
    800011b2:	100005b7          	lui	a1,0x10000
    800011b6:	8526                	mv	a0,s1
    800011b8:	00000097          	auipc	ra,0x0
    800011bc:	fa0080e7          	jalr	-96(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c0:	4719                	li	a4,6
    800011c2:	6685                	lui	a3,0x1
    800011c4:	10001637          	lui	a2,0x10001
    800011c8:	100015b7          	lui	a1,0x10001
    800011cc:	8526                	mv	a0,s1
    800011ce:	00000097          	auipc	ra,0x0
    800011d2:	f8a080e7          	jalr	-118(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011d6:	4719                	li	a4,6
    800011d8:	004006b7          	lui	a3,0x400
    800011dc:	0c000637          	lui	a2,0xc000
    800011e0:	0c0005b7          	lui	a1,0xc000
    800011e4:	8526                	mv	a0,s1
    800011e6:	00000097          	auipc	ra,0x0
    800011ea:	f72080e7          	jalr	-142(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ee:	00007917          	auipc	s2,0x7
    800011f2:	e1290913          	addi	s2,s2,-494 # 80008000 <etext>
    800011f6:	4729                	li	a4,10
    800011f8:	80007697          	auipc	a3,0x80007
    800011fc:	e0868693          	addi	a3,a3,-504 # 8000 <_entry-0x7fff8000>
    80001200:	4605                	li	a2,1
    80001202:	067e                	slli	a2,a2,0x1f
    80001204:	85b2                	mv	a1,a2
    80001206:	8526                	mv	a0,s1
    80001208:	00000097          	auipc	ra,0x0
    8000120c:	f50080e7          	jalr	-176(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001210:	4719                	li	a4,6
    80001212:	46c5                	li	a3,17
    80001214:	06ee                	slli	a3,a3,0x1b
    80001216:	412686b3          	sub	a3,a3,s2
    8000121a:	864a                	mv	a2,s2
    8000121c:	85ca                	mv	a1,s2
    8000121e:	8526                	mv	a0,s1
    80001220:	00000097          	auipc	ra,0x0
    80001224:	f38080e7          	jalr	-200(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001228:	4729                	li	a4,10
    8000122a:	6685                	lui	a3,0x1
    8000122c:	00006617          	auipc	a2,0x6
    80001230:	dd460613          	addi	a2,a2,-556 # 80007000 <_trampoline>
    80001234:	040005b7          	lui	a1,0x4000
    80001238:	15fd                	addi	a1,a1,-1
    8000123a:	05b2                	slli	a1,a1,0xc
    8000123c:	8526                	mv	a0,s1
    8000123e:	00000097          	auipc	ra,0x0
    80001242:	f1a080e7          	jalr	-230(ra) # 80001158 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001246:	8526                	mv	a0,s1
    80001248:	00000097          	auipc	ra,0x0
    8000124c:	5fe080e7          	jalr	1534(ra) # 80001846 <proc_mapstacks>
}
    80001250:	8526                	mv	a0,s1
    80001252:	60e2                	ld	ra,24(sp)
    80001254:	6442                	ld	s0,16(sp)
    80001256:	64a2                	ld	s1,8(sp)
    80001258:	6902                	ld	s2,0(sp)
    8000125a:	6105                	addi	sp,sp,32
    8000125c:	8082                	ret

000000008000125e <kvminit>:
{
    8000125e:	1141                	addi	sp,sp,-16
    80001260:	e406                	sd	ra,8(sp)
    80001262:	e022                	sd	s0,0(sp)
    80001264:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001266:	00000097          	auipc	ra,0x0
    8000126a:	f22080e7          	jalr	-222(ra) # 80001188 <kvmmake>
    8000126e:	00008797          	auipc	a5,0x8
    80001272:	daa7b923          	sd	a0,-590(a5) # 80009020 <kernel_pagetable>
}
    80001276:	60a2                	ld	ra,8(sp)
    80001278:	6402                	ld	s0,0(sp)
    8000127a:	0141                	addi	sp,sp,16
    8000127c:	8082                	ret

000000008000127e <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000127e:	715d                	addi	sp,sp,-80
    80001280:	e486                	sd	ra,72(sp)
    80001282:	e0a2                	sd	s0,64(sp)
    80001284:	fc26                	sd	s1,56(sp)
    80001286:	f84a                	sd	s2,48(sp)
    80001288:	f44e                	sd	s3,40(sp)
    8000128a:	f052                	sd	s4,32(sp)
    8000128c:	ec56                	sd	s5,24(sp)
    8000128e:	e85a                	sd	s6,16(sp)
    80001290:	e45e                	sd	s7,8(sp)
    80001292:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001294:	03459793          	slli	a5,a1,0x34
    80001298:	e795                	bnez	a5,800012c4 <uvmunmap+0x46>
    8000129a:	8a2a                	mv	s4,a0
    8000129c:	892e                	mv	s2,a1
    8000129e:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	0632                	slli	a2,a2,0xc
    800012a2:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012a6:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a8:	6b05                	lui	s6,0x1
    800012aa:	0735e863          	bltu	a1,s3,8000131a <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012ae:	60a6                	ld	ra,72(sp)
    800012b0:	6406                	ld	s0,64(sp)
    800012b2:	74e2                	ld	s1,56(sp)
    800012b4:	7942                	ld	s2,48(sp)
    800012b6:	79a2                	ld	s3,40(sp)
    800012b8:	7a02                	ld	s4,32(sp)
    800012ba:	6ae2                	ld	s5,24(sp)
    800012bc:	6b42                	ld	s6,16(sp)
    800012be:	6ba2                	ld	s7,8(sp)
    800012c0:	6161                	addi	sp,sp,80
    800012c2:	8082                	ret
    panic("uvmunmap: not aligned");
    800012c4:	00007517          	auipc	a0,0x7
    800012c8:	e3c50513          	addi	a0,a0,-452 # 80008100 <digits+0xc0>
    800012cc:	fffff097          	auipc	ra,0xfffff
    800012d0:	272080e7          	jalr	626(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012d4:	00007517          	auipc	a0,0x7
    800012d8:	e4450513          	addi	a0,a0,-444 # 80008118 <digits+0xd8>
    800012dc:	fffff097          	auipc	ra,0xfffff
    800012e0:	262080e7          	jalr	610(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012e4:	00007517          	auipc	a0,0x7
    800012e8:	e4450513          	addi	a0,a0,-444 # 80008128 <digits+0xe8>
    800012ec:	fffff097          	auipc	ra,0xfffff
    800012f0:	252080e7          	jalr	594(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012f4:	00007517          	auipc	a0,0x7
    800012f8:	e4c50513          	addi	a0,a0,-436 # 80008140 <digits+0x100>
    800012fc:	fffff097          	auipc	ra,0xfffff
    80001300:	242080e7          	jalr	578(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    80001304:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001306:	0532                	slli	a0,a0,0xc
    80001308:	fffff097          	auipc	ra,0xfffff
    8000130c:	6f0080e7          	jalr	1776(ra) # 800009f8 <kfree>
    *pte = 0;
    80001310:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001314:	995a                	add	s2,s2,s6
    80001316:	f9397ce3          	bgeu	s2,s3,800012ae <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000131a:	4601                	li	a2,0
    8000131c:	85ca                	mv	a1,s2
    8000131e:	8552                	mv	a0,s4
    80001320:	00000097          	auipc	ra,0x0
    80001324:	cb0080e7          	jalr	-848(ra) # 80000fd0 <walk>
    80001328:	84aa                	mv	s1,a0
    8000132a:	d54d                	beqz	a0,800012d4 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000132c:	6108                	ld	a0,0(a0)
    8000132e:	00157793          	andi	a5,a0,1
    80001332:	dbcd                	beqz	a5,800012e4 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001334:	3ff57793          	andi	a5,a0,1023
    80001338:	fb778ee3          	beq	a5,s7,800012f4 <uvmunmap+0x76>
    if(do_free){
    8000133c:	fc0a8ae3          	beqz	s5,80001310 <uvmunmap+0x92>
    80001340:	b7d1                	j	80001304 <uvmunmap+0x86>

0000000080001342 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001342:	1101                	addi	sp,sp,-32
    80001344:	ec06                	sd	ra,24(sp)
    80001346:	e822                	sd	s0,16(sp)
    80001348:	e426                	sd	s1,8(sp)
    8000134a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000134c:	fffff097          	auipc	ra,0xfffff
    80001350:	7a8080e7          	jalr	1960(ra) # 80000af4 <kalloc>
    80001354:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001356:	c519                	beqz	a0,80001364 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001358:	6605                	lui	a2,0x1
    8000135a:	4581                	li	a1,0
    8000135c:	00000097          	auipc	ra,0x0
    80001360:	984080e7          	jalr	-1660(ra) # 80000ce0 <memset>
  return pagetable;
}
    80001364:	8526                	mv	a0,s1
    80001366:	60e2                	ld	ra,24(sp)
    80001368:	6442                	ld	s0,16(sp)
    8000136a:	64a2                	ld	s1,8(sp)
    8000136c:	6105                	addi	sp,sp,32
    8000136e:	8082                	ret

0000000080001370 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001370:	7179                	addi	sp,sp,-48
    80001372:	f406                	sd	ra,40(sp)
    80001374:	f022                	sd	s0,32(sp)
    80001376:	ec26                	sd	s1,24(sp)
    80001378:	e84a                	sd	s2,16(sp)
    8000137a:	e44e                	sd	s3,8(sp)
    8000137c:	e052                	sd	s4,0(sp)
    8000137e:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001380:	6785                	lui	a5,0x1
    80001382:	04f67863          	bgeu	a2,a5,800013d2 <uvminit+0x62>
    80001386:	8a2a                	mv	s4,a0
    80001388:	89ae                	mv	s3,a1
    8000138a:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000138c:	fffff097          	auipc	ra,0xfffff
    80001390:	768080e7          	jalr	1896(ra) # 80000af4 <kalloc>
    80001394:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001396:	6605                	lui	a2,0x1
    80001398:	4581                	li	a1,0
    8000139a:	00000097          	auipc	ra,0x0
    8000139e:	946080e7          	jalr	-1722(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013a2:	4779                	li	a4,30
    800013a4:	86ca                	mv	a3,s2
    800013a6:	6605                	lui	a2,0x1
    800013a8:	4581                	li	a1,0
    800013aa:	8552                	mv	a0,s4
    800013ac:	00000097          	auipc	ra,0x0
    800013b0:	d0c080e7          	jalr	-756(ra) # 800010b8 <mappages>
  memmove(mem, src, sz);
    800013b4:	8626                	mv	a2,s1
    800013b6:	85ce                	mv	a1,s3
    800013b8:	854a                	mv	a0,s2
    800013ba:	00000097          	auipc	ra,0x0
    800013be:	986080e7          	jalr	-1658(ra) # 80000d40 <memmove>
}
    800013c2:	70a2                	ld	ra,40(sp)
    800013c4:	7402                	ld	s0,32(sp)
    800013c6:	64e2                	ld	s1,24(sp)
    800013c8:	6942                	ld	s2,16(sp)
    800013ca:	69a2                	ld	s3,8(sp)
    800013cc:	6a02                	ld	s4,0(sp)
    800013ce:	6145                	addi	sp,sp,48
    800013d0:	8082                	ret
    panic("inituvm: more than a page");
    800013d2:	00007517          	auipc	a0,0x7
    800013d6:	d8650513          	addi	a0,a0,-634 # 80008158 <digits+0x118>
    800013da:	fffff097          	auipc	ra,0xfffff
    800013de:	164080e7          	jalr	356(ra) # 8000053e <panic>

00000000800013e2 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013e2:	1101                	addi	sp,sp,-32
    800013e4:	ec06                	sd	ra,24(sp)
    800013e6:	e822                	sd	s0,16(sp)
    800013e8:	e426                	sd	s1,8(sp)
    800013ea:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013ec:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ee:	00b67d63          	bgeu	a2,a1,80001408 <uvmdealloc+0x26>
    800013f2:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013f4:	6785                	lui	a5,0x1
    800013f6:	17fd                	addi	a5,a5,-1
    800013f8:	00f60733          	add	a4,a2,a5
    800013fc:	767d                	lui	a2,0xfffff
    800013fe:	8f71                	and	a4,a4,a2
    80001400:	97ae                	add	a5,a5,a1
    80001402:	8ff1                	and	a5,a5,a2
    80001404:	00f76863          	bltu	a4,a5,80001414 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001408:	8526                	mv	a0,s1
    8000140a:	60e2                	ld	ra,24(sp)
    8000140c:	6442                	ld	s0,16(sp)
    8000140e:	64a2                	ld	s1,8(sp)
    80001410:	6105                	addi	sp,sp,32
    80001412:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001414:	8f99                	sub	a5,a5,a4
    80001416:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001418:	4685                	li	a3,1
    8000141a:	0007861b          	sext.w	a2,a5
    8000141e:	85ba                	mv	a1,a4
    80001420:	00000097          	auipc	ra,0x0
    80001424:	e5e080e7          	jalr	-418(ra) # 8000127e <uvmunmap>
    80001428:	b7c5                	j	80001408 <uvmdealloc+0x26>

000000008000142a <uvmalloc>:
  if(newsz < oldsz)
    8000142a:	0ab66163          	bltu	a2,a1,800014cc <uvmalloc+0xa2>
{
    8000142e:	7139                	addi	sp,sp,-64
    80001430:	fc06                	sd	ra,56(sp)
    80001432:	f822                	sd	s0,48(sp)
    80001434:	f426                	sd	s1,40(sp)
    80001436:	f04a                	sd	s2,32(sp)
    80001438:	ec4e                	sd	s3,24(sp)
    8000143a:	e852                	sd	s4,16(sp)
    8000143c:	e456                	sd	s5,8(sp)
    8000143e:	0080                	addi	s0,sp,64
    80001440:	8aaa                	mv	s5,a0
    80001442:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001444:	6985                	lui	s3,0x1
    80001446:	19fd                	addi	s3,s3,-1
    80001448:	95ce                	add	a1,a1,s3
    8000144a:	79fd                	lui	s3,0xfffff
    8000144c:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001450:	08c9f063          	bgeu	s3,a2,800014d0 <uvmalloc+0xa6>
    80001454:	894e                	mv	s2,s3
    mem = kalloc();
    80001456:	fffff097          	auipc	ra,0xfffff
    8000145a:	69e080e7          	jalr	1694(ra) # 80000af4 <kalloc>
    8000145e:	84aa                	mv	s1,a0
    if(mem == 0){
    80001460:	c51d                	beqz	a0,8000148e <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001462:	6605                	lui	a2,0x1
    80001464:	4581                	li	a1,0
    80001466:	00000097          	auipc	ra,0x0
    8000146a:	87a080e7          	jalr	-1926(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000146e:	4779                	li	a4,30
    80001470:	86a6                	mv	a3,s1
    80001472:	6605                	lui	a2,0x1
    80001474:	85ca                	mv	a1,s2
    80001476:	8556                	mv	a0,s5
    80001478:	00000097          	auipc	ra,0x0
    8000147c:	c40080e7          	jalr	-960(ra) # 800010b8 <mappages>
    80001480:	e905                	bnez	a0,800014b0 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001482:	6785                	lui	a5,0x1
    80001484:	993e                	add	s2,s2,a5
    80001486:	fd4968e3          	bltu	s2,s4,80001456 <uvmalloc+0x2c>
  return newsz;
    8000148a:	8552                	mv	a0,s4
    8000148c:	a809                	j	8000149e <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000148e:	864e                	mv	a2,s3
    80001490:	85ca                	mv	a1,s2
    80001492:	8556                	mv	a0,s5
    80001494:	00000097          	auipc	ra,0x0
    80001498:	f4e080e7          	jalr	-178(ra) # 800013e2 <uvmdealloc>
      return 0;
    8000149c:	4501                	li	a0,0
}
    8000149e:	70e2                	ld	ra,56(sp)
    800014a0:	7442                	ld	s0,48(sp)
    800014a2:	74a2                	ld	s1,40(sp)
    800014a4:	7902                	ld	s2,32(sp)
    800014a6:	69e2                	ld	s3,24(sp)
    800014a8:	6a42                	ld	s4,16(sp)
    800014aa:	6aa2                	ld	s5,8(sp)
    800014ac:	6121                	addi	sp,sp,64
    800014ae:	8082                	ret
      kfree(mem);
    800014b0:	8526                	mv	a0,s1
    800014b2:	fffff097          	auipc	ra,0xfffff
    800014b6:	546080e7          	jalr	1350(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014ba:	864e                	mv	a2,s3
    800014bc:	85ca                	mv	a1,s2
    800014be:	8556                	mv	a0,s5
    800014c0:	00000097          	auipc	ra,0x0
    800014c4:	f22080e7          	jalr	-222(ra) # 800013e2 <uvmdealloc>
      return 0;
    800014c8:	4501                	li	a0,0
    800014ca:	bfd1                	j	8000149e <uvmalloc+0x74>
    return oldsz;
    800014cc:	852e                	mv	a0,a1
}
    800014ce:	8082                	ret
  return newsz;
    800014d0:	8532                	mv	a0,a2
    800014d2:	b7f1                	j	8000149e <uvmalloc+0x74>

00000000800014d4 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014d4:	7179                	addi	sp,sp,-48
    800014d6:	f406                	sd	ra,40(sp)
    800014d8:	f022                	sd	s0,32(sp)
    800014da:	ec26                	sd	s1,24(sp)
    800014dc:	e84a                	sd	s2,16(sp)
    800014de:	e44e                	sd	s3,8(sp)
    800014e0:	e052                	sd	s4,0(sp)
    800014e2:	1800                	addi	s0,sp,48
    800014e4:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014e6:	84aa                	mv	s1,a0
    800014e8:	6905                	lui	s2,0x1
    800014ea:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014ec:	4985                	li	s3,1
    800014ee:	a821                	j	80001506 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014f0:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014f2:	0532                	slli	a0,a0,0xc
    800014f4:	00000097          	auipc	ra,0x0
    800014f8:	fe0080e7          	jalr	-32(ra) # 800014d4 <freewalk>
      pagetable[i] = 0;
    800014fc:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001500:	04a1                	addi	s1,s1,8
    80001502:	03248163          	beq	s1,s2,80001524 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001506:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001508:	00f57793          	andi	a5,a0,15
    8000150c:	ff3782e3          	beq	a5,s3,800014f0 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001510:	8905                	andi	a0,a0,1
    80001512:	d57d                	beqz	a0,80001500 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001514:	00007517          	auipc	a0,0x7
    80001518:	c6450513          	addi	a0,a0,-924 # 80008178 <digits+0x138>
    8000151c:	fffff097          	auipc	ra,0xfffff
    80001520:	022080e7          	jalr	34(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001524:	8552                	mv	a0,s4
    80001526:	fffff097          	auipc	ra,0xfffff
    8000152a:	4d2080e7          	jalr	1234(ra) # 800009f8 <kfree>
}
    8000152e:	70a2                	ld	ra,40(sp)
    80001530:	7402                	ld	s0,32(sp)
    80001532:	64e2                	ld	s1,24(sp)
    80001534:	6942                	ld	s2,16(sp)
    80001536:	69a2                	ld	s3,8(sp)
    80001538:	6a02                	ld	s4,0(sp)
    8000153a:	6145                	addi	sp,sp,48
    8000153c:	8082                	ret

000000008000153e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000153e:	1101                	addi	sp,sp,-32
    80001540:	ec06                	sd	ra,24(sp)
    80001542:	e822                	sd	s0,16(sp)
    80001544:	e426                	sd	s1,8(sp)
    80001546:	1000                	addi	s0,sp,32
    80001548:	84aa                	mv	s1,a0
  if(sz > 0)
    8000154a:	e999                	bnez	a1,80001560 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000154c:	8526                	mv	a0,s1
    8000154e:	00000097          	auipc	ra,0x0
    80001552:	f86080e7          	jalr	-122(ra) # 800014d4 <freewalk>
}
    80001556:	60e2                	ld	ra,24(sp)
    80001558:	6442                	ld	s0,16(sp)
    8000155a:	64a2                	ld	s1,8(sp)
    8000155c:	6105                	addi	sp,sp,32
    8000155e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001560:	6605                	lui	a2,0x1
    80001562:	167d                	addi	a2,a2,-1
    80001564:	962e                	add	a2,a2,a1
    80001566:	4685                	li	a3,1
    80001568:	8231                	srli	a2,a2,0xc
    8000156a:	4581                	li	a1,0
    8000156c:	00000097          	auipc	ra,0x0
    80001570:	d12080e7          	jalr	-750(ra) # 8000127e <uvmunmap>
    80001574:	bfe1                	j	8000154c <uvmfree+0xe>

0000000080001576 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001576:	c679                	beqz	a2,80001644 <uvmcopy+0xce>
{
    80001578:	715d                	addi	sp,sp,-80
    8000157a:	e486                	sd	ra,72(sp)
    8000157c:	e0a2                	sd	s0,64(sp)
    8000157e:	fc26                	sd	s1,56(sp)
    80001580:	f84a                	sd	s2,48(sp)
    80001582:	f44e                	sd	s3,40(sp)
    80001584:	f052                	sd	s4,32(sp)
    80001586:	ec56                	sd	s5,24(sp)
    80001588:	e85a                	sd	s6,16(sp)
    8000158a:	e45e                	sd	s7,8(sp)
    8000158c:	0880                	addi	s0,sp,80
    8000158e:	8b2a                	mv	s6,a0
    80001590:	8aae                	mv	s5,a1
    80001592:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001594:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001596:	4601                	li	a2,0
    80001598:	85ce                	mv	a1,s3
    8000159a:	855a                	mv	a0,s6
    8000159c:	00000097          	auipc	ra,0x0
    800015a0:	a34080e7          	jalr	-1484(ra) # 80000fd0 <walk>
    800015a4:	c531                	beqz	a0,800015f0 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015a6:	6118                	ld	a4,0(a0)
    800015a8:	00177793          	andi	a5,a4,1
    800015ac:	cbb1                	beqz	a5,80001600 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015ae:	00a75593          	srli	a1,a4,0xa
    800015b2:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015b6:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ba:	fffff097          	auipc	ra,0xfffff
    800015be:	53a080e7          	jalr	1338(ra) # 80000af4 <kalloc>
    800015c2:	892a                	mv	s2,a0
    800015c4:	c939                	beqz	a0,8000161a <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015c6:	6605                	lui	a2,0x1
    800015c8:	85de                	mv	a1,s7
    800015ca:	fffff097          	auipc	ra,0xfffff
    800015ce:	776080e7          	jalr	1910(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015d2:	8726                	mv	a4,s1
    800015d4:	86ca                	mv	a3,s2
    800015d6:	6605                	lui	a2,0x1
    800015d8:	85ce                	mv	a1,s3
    800015da:	8556                	mv	a0,s5
    800015dc:	00000097          	auipc	ra,0x0
    800015e0:	adc080e7          	jalr	-1316(ra) # 800010b8 <mappages>
    800015e4:	e515                	bnez	a0,80001610 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015e6:	6785                	lui	a5,0x1
    800015e8:	99be                	add	s3,s3,a5
    800015ea:	fb49e6e3          	bltu	s3,s4,80001596 <uvmcopy+0x20>
    800015ee:	a081                	j	8000162e <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015f0:	00007517          	auipc	a0,0x7
    800015f4:	b9850513          	addi	a0,a0,-1128 # 80008188 <digits+0x148>
    800015f8:	fffff097          	auipc	ra,0xfffff
    800015fc:	f46080e7          	jalr	-186(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    80001600:	00007517          	auipc	a0,0x7
    80001604:	ba850513          	addi	a0,a0,-1112 # 800081a8 <digits+0x168>
    80001608:	fffff097          	auipc	ra,0xfffff
    8000160c:	f36080e7          	jalr	-202(ra) # 8000053e <panic>
      kfree(mem);
    80001610:	854a                	mv	a0,s2
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	3e6080e7          	jalr	998(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000161a:	4685                	li	a3,1
    8000161c:	00c9d613          	srli	a2,s3,0xc
    80001620:	4581                	li	a1,0
    80001622:	8556                	mv	a0,s5
    80001624:	00000097          	auipc	ra,0x0
    80001628:	c5a080e7          	jalr	-934(ra) # 8000127e <uvmunmap>
  return -1;
    8000162c:	557d                	li	a0,-1
}
    8000162e:	60a6                	ld	ra,72(sp)
    80001630:	6406                	ld	s0,64(sp)
    80001632:	74e2                	ld	s1,56(sp)
    80001634:	7942                	ld	s2,48(sp)
    80001636:	79a2                	ld	s3,40(sp)
    80001638:	7a02                	ld	s4,32(sp)
    8000163a:	6ae2                	ld	s5,24(sp)
    8000163c:	6b42                	ld	s6,16(sp)
    8000163e:	6ba2                	ld	s7,8(sp)
    80001640:	6161                	addi	sp,sp,80
    80001642:	8082                	ret
  return 0;
    80001644:	4501                	li	a0,0
}
    80001646:	8082                	ret

0000000080001648 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001648:	1141                	addi	sp,sp,-16
    8000164a:	e406                	sd	ra,8(sp)
    8000164c:	e022                	sd	s0,0(sp)
    8000164e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001650:	4601                	li	a2,0
    80001652:	00000097          	auipc	ra,0x0
    80001656:	97e080e7          	jalr	-1666(ra) # 80000fd0 <walk>
  if(pte == 0)
    8000165a:	c901                	beqz	a0,8000166a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000165c:	611c                	ld	a5,0(a0)
    8000165e:	9bbd                	andi	a5,a5,-17
    80001660:	e11c                	sd	a5,0(a0)
}
    80001662:	60a2                	ld	ra,8(sp)
    80001664:	6402                	ld	s0,0(sp)
    80001666:	0141                	addi	sp,sp,16
    80001668:	8082                	ret
    panic("uvmclear");
    8000166a:	00007517          	auipc	a0,0x7
    8000166e:	b5e50513          	addi	a0,a0,-1186 # 800081c8 <digits+0x188>
    80001672:	fffff097          	auipc	ra,0xfffff
    80001676:	ecc080e7          	jalr	-308(ra) # 8000053e <panic>

000000008000167a <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000167a:	c6bd                	beqz	a3,800016e8 <copyout+0x6e>
{
    8000167c:	715d                	addi	sp,sp,-80
    8000167e:	e486                	sd	ra,72(sp)
    80001680:	e0a2                	sd	s0,64(sp)
    80001682:	fc26                	sd	s1,56(sp)
    80001684:	f84a                	sd	s2,48(sp)
    80001686:	f44e                	sd	s3,40(sp)
    80001688:	f052                	sd	s4,32(sp)
    8000168a:	ec56                	sd	s5,24(sp)
    8000168c:	e85a                	sd	s6,16(sp)
    8000168e:	e45e                	sd	s7,8(sp)
    80001690:	e062                	sd	s8,0(sp)
    80001692:	0880                	addi	s0,sp,80
    80001694:	8b2a                	mv	s6,a0
    80001696:	8c2e                	mv	s8,a1
    80001698:	8a32                	mv	s4,a2
    8000169a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000169c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000169e:	6a85                	lui	s5,0x1
    800016a0:	a015                	j	800016c4 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016a2:	9562                	add	a0,a0,s8
    800016a4:	0004861b          	sext.w	a2,s1
    800016a8:	85d2                	mv	a1,s4
    800016aa:	41250533          	sub	a0,a0,s2
    800016ae:	fffff097          	auipc	ra,0xfffff
    800016b2:	692080e7          	jalr	1682(ra) # 80000d40 <memmove>

    len -= n;
    800016b6:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ba:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016bc:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016c0:	02098263          	beqz	s3,800016e4 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016c4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c8:	85ca                	mv	a1,s2
    800016ca:	855a                	mv	a0,s6
    800016cc:	00000097          	auipc	ra,0x0
    800016d0:	9aa080e7          	jalr	-1622(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    800016d4:	cd01                	beqz	a0,800016ec <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016d6:	418904b3          	sub	s1,s2,s8
    800016da:	94d6                	add	s1,s1,s5
    if(n > len)
    800016dc:	fc99f3e3          	bgeu	s3,s1,800016a2 <copyout+0x28>
    800016e0:	84ce                	mv	s1,s3
    800016e2:	b7c1                	j	800016a2 <copyout+0x28>
  }
  return 0;
    800016e4:	4501                	li	a0,0
    800016e6:	a021                	j	800016ee <copyout+0x74>
    800016e8:	4501                	li	a0,0
}
    800016ea:	8082                	ret
      return -1;
    800016ec:	557d                	li	a0,-1
}
    800016ee:	60a6                	ld	ra,72(sp)
    800016f0:	6406                	ld	s0,64(sp)
    800016f2:	74e2                	ld	s1,56(sp)
    800016f4:	7942                	ld	s2,48(sp)
    800016f6:	79a2                	ld	s3,40(sp)
    800016f8:	7a02                	ld	s4,32(sp)
    800016fa:	6ae2                	ld	s5,24(sp)
    800016fc:	6b42                	ld	s6,16(sp)
    800016fe:	6ba2                	ld	s7,8(sp)
    80001700:	6c02                	ld	s8,0(sp)
    80001702:	6161                	addi	sp,sp,80
    80001704:	8082                	ret

0000000080001706 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001706:	c6bd                	beqz	a3,80001774 <copyin+0x6e>
{
    80001708:	715d                	addi	sp,sp,-80
    8000170a:	e486                	sd	ra,72(sp)
    8000170c:	e0a2                	sd	s0,64(sp)
    8000170e:	fc26                	sd	s1,56(sp)
    80001710:	f84a                	sd	s2,48(sp)
    80001712:	f44e                	sd	s3,40(sp)
    80001714:	f052                	sd	s4,32(sp)
    80001716:	ec56                	sd	s5,24(sp)
    80001718:	e85a                	sd	s6,16(sp)
    8000171a:	e45e                	sd	s7,8(sp)
    8000171c:	e062                	sd	s8,0(sp)
    8000171e:	0880                	addi	s0,sp,80
    80001720:	8b2a                	mv	s6,a0
    80001722:	8a2e                	mv	s4,a1
    80001724:	8c32                	mv	s8,a2
    80001726:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001728:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000172a:	6a85                	lui	s5,0x1
    8000172c:	a015                	j	80001750 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000172e:	9562                	add	a0,a0,s8
    80001730:	0004861b          	sext.w	a2,s1
    80001734:	412505b3          	sub	a1,a0,s2
    80001738:	8552                	mv	a0,s4
    8000173a:	fffff097          	auipc	ra,0xfffff
    8000173e:	606080e7          	jalr	1542(ra) # 80000d40 <memmove>

    len -= n;
    80001742:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001746:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001748:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000174c:	02098263          	beqz	s3,80001770 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001750:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001754:	85ca                	mv	a1,s2
    80001756:	855a                	mv	a0,s6
    80001758:	00000097          	auipc	ra,0x0
    8000175c:	91e080e7          	jalr	-1762(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    80001760:	cd01                	beqz	a0,80001778 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001762:	418904b3          	sub	s1,s2,s8
    80001766:	94d6                	add	s1,s1,s5
    if(n > len)
    80001768:	fc99f3e3          	bgeu	s3,s1,8000172e <copyin+0x28>
    8000176c:	84ce                	mv	s1,s3
    8000176e:	b7c1                	j	8000172e <copyin+0x28>
  }
  return 0;
    80001770:	4501                	li	a0,0
    80001772:	a021                	j	8000177a <copyin+0x74>
    80001774:	4501                	li	a0,0
}
    80001776:	8082                	ret
      return -1;
    80001778:	557d                	li	a0,-1
}
    8000177a:	60a6                	ld	ra,72(sp)
    8000177c:	6406                	ld	s0,64(sp)
    8000177e:	74e2                	ld	s1,56(sp)
    80001780:	7942                	ld	s2,48(sp)
    80001782:	79a2                	ld	s3,40(sp)
    80001784:	7a02                	ld	s4,32(sp)
    80001786:	6ae2                	ld	s5,24(sp)
    80001788:	6b42                	ld	s6,16(sp)
    8000178a:	6ba2                	ld	s7,8(sp)
    8000178c:	6c02                	ld	s8,0(sp)
    8000178e:	6161                	addi	sp,sp,80
    80001790:	8082                	ret

0000000080001792 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001792:	c6c5                	beqz	a3,8000183a <copyinstr+0xa8>
{
    80001794:	715d                	addi	sp,sp,-80
    80001796:	e486                	sd	ra,72(sp)
    80001798:	e0a2                	sd	s0,64(sp)
    8000179a:	fc26                	sd	s1,56(sp)
    8000179c:	f84a                	sd	s2,48(sp)
    8000179e:	f44e                	sd	s3,40(sp)
    800017a0:	f052                	sd	s4,32(sp)
    800017a2:	ec56                	sd	s5,24(sp)
    800017a4:	e85a                	sd	s6,16(sp)
    800017a6:	e45e                	sd	s7,8(sp)
    800017a8:	0880                	addi	s0,sp,80
    800017aa:	8a2a                	mv	s4,a0
    800017ac:	8b2e                	mv	s6,a1
    800017ae:	8bb2                	mv	s7,a2
    800017b0:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017b2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017b4:	6985                	lui	s3,0x1
    800017b6:	a035                	j	800017e2 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017bc:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017be:	0017b793          	seqz	a5,a5
    800017c2:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017c6:	60a6                	ld	ra,72(sp)
    800017c8:	6406                	ld	s0,64(sp)
    800017ca:	74e2                	ld	s1,56(sp)
    800017cc:	7942                	ld	s2,48(sp)
    800017ce:	79a2                	ld	s3,40(sp)
    800017d0:	7a02                	ld	s4,32(sp)
    800017d2:	6ae2                	ld	s5,24(sp)
    800017d4:	6b42                	ld	s6,16(sp)
    800017d6:	6ba2                	ld	s7,8(sp)
    800017d8:	6161                	addi	sp,sp,80
    800017da:	8082                	ret
    srcva = va0 + PGSIZE;
    800017dc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017e0:	c8a9                	beqz	s1,80001832 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017e2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017e6:	85ca                	mv	a1,s2
    800017e8:	8552                	mv	a0,s4
    800017ea:	00000097          	auipc	ra,0x0
    800017ee:	88c080e7          	jalr	-1908(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    800017f2:	c131                	beqz	a0,80001836 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017f4:	41790833          	sub	a6,s2,s7
    800017f8:	984e                	add	a6,a6,s3
    if(n > max)
    800017fa:	0104f363          	bgeu	s1,a6,80001800 <copyinstr+0x6e>
    800017fe:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001800:	955e                	add	a0,a0,s7
    80001802:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001806:	fc080be3          	beqz	a6,800017dc <copyinstr+0x4a>
    8000180a:	985a                	add	a6,a6,s6
    8000180c:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000180e:	41650633          	sub	a2,a0,s6
    80001812:	14fd                	addi	s1,s1,-1
    80001814:	9b26                	add	s6,s6,s1
    80001816:	00f60733          	add	a4,a2,a5
    8000181a:	00074703          	lbu	a4,0(a4)
    8000181e:	df49                	beqz	a4,800017b8 <copyinstr+0x26>
        *dst = *p;
    80001820:	00e78023          	sb	a4,0(a5)
      --max;
    80001824:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001828:	0785                	addi	a5,a5,1
    while(n > 0){
    8000182a:	ff0796e3          	bne	a5,a6,80001816 <copyinstr+0x84>
      dst++;
    8000182e:	8b42                	mv	s6,a6
    80001830:	b775                	j	800017dc <copyinstr+0x4a>
    80001832:	4781                	li	a5,0
    80001834:	b769                	j	800017be <copyinstr+0x2c>
      return -1;
    80001836:	557d                	li	a0,-1
    80001838:	b779                	j	800017c6 <copyinstr+0x34>
  int got_null = 0;
    8000183a:	4781                	li	a5,0
  if(got_null){
    8000183c:	0017b793          	seqz	a5,a5
    80001840:	40f00533          	neg	a0,a5
}
    80001844:	8082                	ret

0000000080001846 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001846:	7139                	addi	sp,sp,-64
    80001848:	fc06                	sd	ra,56(sp)
    8000184a:	f822                	sd	s0,48(sp)
    8000184c:	f426                	sd	s1,40(sp)
    8000184e:	f04a                	sd	s2,32(sp)
    80001850:	ec4e                	sd	s3,24(sp)
    80001852:	e852                	sd	s4,16(sp)
    80001854:	e456                	sd	s5,8(sp)
    80001856:	e05a                	sd	s6,0(sp)
    80001858:	0080                	addi	s0,sp,64
    8000185a:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000185c:	00009497          	auipc	s1,0x9
    80001860:	a0448493          	addi	s1,s1,-1532 # 8000a260 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001864:	8b26                	mv	s6,s1
    80001866:	00006a97          	auipc	s5,0x6
    8000186a:	79aa8a93          	addi	s5,s5,1946 # 80008000 <etext>
    8000186e:	04000937          	lui	s2,0x4000
    80001872:	197d                	addi	s2,s2,-1
    80001874:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001876:	0000fa17          	auipc	s4,0xf
    8000187a:	beaa0a13          	addi	s4,s4,-1046 # 80010460 <tickslock>
    char *pa = kalloc();
    8000187e:	fffff097          	auipc	ra,0xfffff
    80001882:	276080e7          	jalr	630(ra) # 80000af4 <kalloc>
    80001886:	862a                	mv	a2,a0
    if(pa == 0)
    80001888:	c131                	beqz	a0,800018cc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000188a:	416485b3          	sub	a1,s1,s6
    8000188e:	858d                	srai	a1,a1,0x3
    80001890:	000ab783          	ld	a5,0(s5)
    80001894:	02f585b3          	mul	a1,a1,a5
    80001898:	2585                	addiw	a1,a1,1
    8000189a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000189e:	4719                	li	a4,6
    800018a0:	6685                	lui	a3,0x1
    800018a2:	40b905b3          	sub	a1,s2,a1
    800018a6:	854e                	mv	a0,s3
    800018a8:	00000097          	auipc	ra,0x0
    800018ac:	8b0080e7          	jalr	-1872(ra) # 80001158 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018b0:	18848493          	addi	s1,s1,392
    800018b4:	fd4495e3          	bne	s1,s4,8000187e <proc_mapstacks+0x38>
  }
}
    800018b8:	70e2                	ld	ra,56(sp)
    800018ba:	7442                	ld	s0,48(sp)
    800018bc:	74a2                	ld	s1,40(sp)
    800018be:	7902                	ld	s2,32(sp)
    800018c0:	69e2                	ld	s3,24(sp)
    800018c2:	6a42                	ld	s4,16(sp)
    800018c4:	6aa2                	ld	s5,8(sp)
    800018c6:	6b02                	ld	s6,0(sp)
    800018c8:	6121                	addi	sp,sp,64
    800018ca:	8082                	ret
      panic("kalloc");
    800018cc:	00007517          	auipc	a0,0x7
    800018d0:	90c50513          	addi	a0,a0,-1780 # 800081d8 <digits+0x198>
    800018d4:	fffff097          	auipc	ra,0xfffff
    800018d8:	c6a080e7          	jalr	-918(ra) # 8000053e <panic>

00000000800018dc <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018dc:	7139                	addi	sp,sp,-64
    800018de:	fc06                	sd	ra,56(sp)
    800018e0:	f822                	sd	s0,48(sp)
    800018e2:	f426                	sd	s1,40(sp)
    800018e4:	f04a                	sd	s2,32(sp)
    800018e6:	ec4e                	sd	s3,24(sp)
    800018e8:	e852                	sd	s4,16(sp)
    800018ea:	e456                	sd	s5,8(sp)
    800018ec:	e05a                	sd	s6,0(sp)
    800018ee:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018f0:	00007597          	auipc	a1,0x7
    800018f4:	8f058593          	addi	a1,a1,-1808 # 800081e0 <digits+0x1a0>
    800018f8:	00009517          	auipc	a0,0x9
    800018fc:	8b850513          	addi	a0,a0,-1864 # 8000a1b0 <pid_lock>
    80001900:	fffff097          	auipc	ra,0xfffff
    80001904:	254080e7          	jalr	596(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001908:	00007597          	auipc	a1,0x7
    8000190c:	8e058593          	addi	a1,a1,-1824 # 800081e8 <digits+0x1a8>
    80001910:	00009517          	auipc	a0,0x9
    80001914:	8b850513          	addi	a0,a0,-1864 # 8000a1c8 <wait_lock>
    80001918:	fffff097          	auipc	ra,0xfffff
    8000191c:	23c080e7          	jalr	572(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001920:	00009497          	auipc	s1,0x9
    80001924:	94048493          	addi	s1,s1,-1728 # 8000a260 <proc>
      initlock(&p->lock, "proc");
    80001928:	00007b17          	auipc	s6,0x7
    8000192c:	8d0b0b13          	addi	s6,s6,-1840 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    80001930:	8aa6                	mv	s5,s1
    80001932:	00006a17          	auipc	s4,0x6
    80001936:	6cea0a13          	addi	s4,s4,1742 # 80008000 <etext>
    8000193a:	04000937          	lui	s2,0x4000
    8000193e:	197d                	addi	s2,s2,-1
    80001940:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001942:	0000f997          	auipc	s3,0xf
    80001946:	b1e98993          	addi	s3,s3,-1250 # 80010460 <tickslock>
      initlock(&p->lock, "proc");
    8000194a:	85da                	mv	a1,s6
    8000194c:	8526                	mv	a0,s1
    8000194e:	fffff097          	auipc	ra,0xfffff
    80001952:	206080e7          	jalr	518(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001956:	415487b3          	sub	a5,s1,s5
    8000195a:	878d                	srai	a5,a5,0x3
    8000195c:	000a3703          	ld	a4,0(s4)
    80001960:	02e787b3          	mul	a5,a5,a4
    80001964:	2785                	addiw	a5,a5,1
    80001966:	00d7979b          	slliw	a5,a5,0xd
    8000196a:	40f907b3          	sub	a5,s2,a5
    8000196e:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001970:	18848493          	addi	s1,s1,392
    80001974:	fd349be3          	bne	s1,s3,8000194a <procinit+0x6e>
  }
  start_time = ticks;
    80001978:	00007797          	auipc	a5,0x7
    8000197c:	6e07a783          	lw	a5,1760(a5) # 80009058 <ticks>
    80001980:	00007717          	auipc	a4,0x7
    80001984:	6af72423          	sw	a5,1704(a4) # 80009028 <start_time>
}
    80001988:	70e2                	ld	ra,56(sp)
    8000198a:	7442                	ld	s0,48(sp)
    8000198c:	74a2                	ld	s1,40(sp)
    8000198e:	7902                	ld	s2,32(sp)
    80001990:	69e2                	ld	s3,24(sp)
    80001992:	6a42                	ld	s4,16(sp)
    80001994:	6aa2                	ld	s5,8(sp)
    80001996:	6b02                	ld	s6,0(sp)
    80001998:	6121                	addi	sp,sp,64
    8000199a:	8082                	ret

000000008000199c <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000199c:	1141                	addi	sp,sp,-16
    8000199e:	e422                	sd	s0,8(sp)
    800019a0:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019a2:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019a4:	2501                	sext.w	a0,a0
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800019ac:	1141                	addi	sp,sp,-16
    800019ae:	e422                	sd	s0,8(sp)
    800019b0:	0800                	addi	s0,sp,16
    800019b2:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019b4:	2781                	sext.w	a5,a5
    800019b6:	079e                	slli	a5,a5,0x7
  return c;
}
    800019b8:	00009517          	auipc	a0,0x9
    800019bc:	82850513          	addi	a0,a0,-2008 # 8000a1e0 <cpus>
    800019c0:	953e                	add	a0,a0,a5
    800019c2:	6422                	ld	s0,8(sp)
    800019c4:	0141                	addi	sp,sp,16
    800019c6:	8082                	ret

00000000800019c8 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019c8:	1101                	addi	sp,sp,-32
    800019ca:	ec06                	sd	ra,24(sp)
    800019cc:	e822                	sd	s0,16(sp)
    800019ce:	e426                	sd	s1,8(sp)
    800019d0:	1000                	addi	s0,sp,32
  push_off();
    800019d2:	fffff097          	auipc	ra,0xfffff
    800019d6:	1c6080e7          	jalr	454(ra) # 80000b98 <push_off>
    800019da:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019dc:	2781                	sext.w	a5,a5
    800019de:	079e                	slli	a5,a5,0x7
    800019e0:	00008717          	auipc	a4,0x8
    800019e4:	7d070713          	addi	a4,a4,2000 # 8000a1b0 <pid_lock>
    800019e8:	97ba                	add	a5,a5,a4
    800019ea:	7b84                	ld	s1,48(a5)
  pop_off();
    800019ec:	fffff097          	auipc	ra,0xfffff
    800019f0:	24c080e7          	jalr	588(ra) # 80000c38 <pop_off>
  return p;
}
    800019f4:	8526                	mv	a0,s1
    800019f6:	60e2                	ld	ra,24(sp)
    800019f8:	6442                	ld	s0,16(sp)
    800019fa:	64a2                	ld	s1,8(sp)
    800019fc:	6105                	addi	sp,sp,32
    800019fe:	8082                	ret

0000000080001a00 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a00:	1141                	addi	sp,sp,-16
    80001a02:	e406                	sd	ra,8(sp)
    80001a04:	e022                	sd	s0,0(sp)
    80001a06:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a08:	00000097          	auipc	ra,0x0
    80001a0c:	fc0080e7          	jalr	-64(ra) # 800019c8 <myproc>
    80001a10:	fffff097          	auipc	ra,0xfffff
    80001a14:	288080e7          	jalr	648(ra) # 80000c98 <release>

  if (first) {
    80001a18:	00007797          	auipc	a5,0x7
    80001a1c:	ee87a783          	lw	a5,-280(a5) # 80008900 <first.1826>
    80001a20:	eb89                	bnez	a5,80001a32 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a22:	00001097          	auipc	ra,0x1
    80001a26:	270080e7          	jalr	624(ra) # 80002c92 <usertrapret>
}
    80001a2a:	60a2                	ld	ra,8(sp)
    80001a2c:	6402                	ld	s0,0(sp)
    80001a2e:	0141                	addi	sp,sp,16
    80001a30:	8082                	ret
    first = 0;
    80001a32:	00007797          	auipc	a5,0x7
    80001a36:	ec07a723          	sw	zero,-306(a5) # 80008900 <first.1826>
    fsinit(ROOTDEV);
    80001a3a:	4505                	li	a0,1
    80001a3c:	00002097          	auipc	ra,0x2
    80001a40:	ffc080e7          	jalr	-4(ra) # 80003a38 <fsinit>
    80001a44:	bff9                	j	80001a22 <forkret+0x22>

0000000080001a46 <allocpid>:
allocpid() {
    80001a46:	1101                	addi	sp,sp,-32
    80001a48:	ec06                	sd	ra,24(sp)
    80001a4a:	e822                	sd	s0,16(sp)
    80001a4c:	e426                	sd	s1,8(sp)
    80001a4e:	e04a                	sd	s2,0(sp)
    80001a50:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a52:	00008917          	auipc	s2,0x8
    80001a56:	75e90913          	addi	s2,s2,1886 # 8000a1b0 <pid_lock>
    80001a5a:	854a                	mv	a0,s2
    80001a5c:	fffff097          	auipc	ra,0xfffff
    80001a60:	188080e7          	jalr	392(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a64:	00007797          	auipc	a5,0x7
    80001a68:	ea478793          	addi	a5,a5,-348 # 80008908 <nextpid>
    80001a6c:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a6e:	0014871b          	addiw	a4,s1,1
    80001a72:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a74:	854a                	mv	a0,s2
    80001a76:	fffff097          	auipc	ra,0xfffff
    80001a7a:	222080e7          	jalr	546(ra) # 80000c98 <release>
}
    80001a7e:	8526                	mv	a0,s1
    80001a80:	60e2                	ld	ra,24(sp)
    80001a82:	6442                	ld	s0,16(sp)
    80001a84:	64a2                	ld	s1,8(sp)
    80001a86:	6902                	ld	s2,0(sp)
    80001a88:	6105                	addi	sp,sp,32
    80001a8a:	8082                	ret

0000000080001a8c <proc_pagetable>:
{
    80001a8c:	1101                	addi	sp,sp,-32
    80001a8e:	ec06                	sd	ra,24(sp)
    80001a90:	e822                	sd	s0,16(sp)
    80001a92:	e426                	sd	s1,8(sp)
    80001a94:	e04a                	sd	s2,0(sp)
    80001a96:	1000                	addi	s0,sp,32
    80001a98:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a9a:	00000097          	auipc	ra,0x0
    80001a9e:	8a8080e7          	jalr	-1880(ra) # 80001342 <uvmcreate>
    80001aa2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001aa4:	c121                	beqz	a0,80001ae4 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aa6:	4729                	li	a4,10
    80001aa8:	00005697          	auipc	a3,0x5
    80001aac:	55868693          	addi	a3,a3,1368 # 80007000 <_trampoline>
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	040005b7          	lui	a1,0x4000
    80001ab6:	15fd                	addi	a1,a1,-1
    80001ab8:	05b2                	slli	a1,a1,0xc
    80001aba:	fffff097          	auipc	ra,0xfffff
    80001abe:	5fe080e7          	jalr	1534(ra) # 800010b8 <mappages>
    80001ac2:	02054863          	bltz	a0,80001af2 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ac6:	4719                	li	a4,6
    80001ac8:	05893683          	ld	a3,88(s2)
    80001acc:	6605                	lui	a2,0x1
    80001ace:	020005b7          	lui	a1,0x2000
    80001ad2:	15fd                	addi	a1,a1,-1
    80001ad4:	05b6                	slli	a1,a1,0xd
    80001ad6:	8526                	mv	a0,s1
    80001ad8:	fffff097          	auipc	ra,0xfffff
    80001adc:	5e0080e7          	jalr	1504(ra) # 800010b8 <mappages>
    80001ae0:	02054163          	bltz	a0,80001b02 <proc_pagetable+0x76>
}
    80001ae4:	8526                	mv	a0,s1
    80001ae6:	60e2                	ld	ra,24(sp)
    80001ae8:	6442                	ld	s0,16(sp)
    80001aea:	64a2                	ld	s1,8(sp)
    80001aec:	6902                	ld	s2,0(sp)
    80001aee:	6105                	addi	sp,sp,32
    80001af0:	8082                	ret
    uvmfree(pagetable, 0);
    80001af2:	4581                	li	a1,0
    80001af4:	8526                	mv	a0,s1
    80001af6:	00000097          	auipc	ra,0x0
    80001afa:	a48080e7          	jalr	-1464(ra) # 8000153e <uvmfree>
    return 0;
    80001afe:	4481                	li	s1,0
    80001b00:	b7d5                	j	80001ae4 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b02:	4681                	li	a3,0
    80001b04:	4605                	li	a2,1
    80001b06:	040005b7          	lui	a1,0x4000
    80001b0a:	15fd                	addi	a1,a1,-1
    80001b0c:	05b2                	slli	a1,a1,0xc
    80001b0e:	8526                	mv	a0,s1
    80001b10:	fffff097          	auipc	ra,0xfffff
    80001b14:	76e080e7          	jalr	1902(ra) # 8000127e <uvmunmap>
    uvmfree(pagetable, 0);
    80001b18:	4581                	li	a1,0
    80001b1a:	8526                	mv	a0,s1
    80001b1c:	00000097          	auipc	ra,0x0
    80001b20:	a22080e7          	jalr	-1502(ra) # 8000153e <uvmfree>
    return 0;
    80001b24:	4481                	li	s1,0
    80001b26:	bf7d                	j	80001ae4 <proc_pagetable+0x58>

0000000080001b28 <proc_freepagetable>:
{
    80001b28:	1101                	addi	sp,sp,-32
    80001b2a:	ec06                	sd	ra,24(sp)
    80001b2c:	e822                	sd	s0,16(sp)
    80001b2e:	e426                	sd	s1,8(sp)
    80001b30:	e04a                	sd	s2,0(sp)
    80001b32:	1000                	addi	s0,sp,32
    80001b34:	84aa                	mv	s1,a0
    80001b36:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b38:	4681                	li	a3,0
    80001b3a:	4605                	li	a2,1
    80001b3c:	040005b7          	lui	a1,0x4000
    80001b40:	15fd                	addi	a1,a1,-1
    80001b42:	05b2                	slli	a1,a1,0xc
    80001b44:	fffff097          	auipc	ra,0xfffff
    80001b48:	73a080e7          	jalr	1850(ra) # 8000127e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b4c:	4681                	li	a3,0
    80001b4e:	4605                	li	a2,1
    80001b50:	020005b7          	lui	a1,0x2000
    80001b54:	15fd                	addi	a1,a1,-1
    80001b56:	05b6                	slli	a1,a1,0xd
    80001b58:	8526                	mv	a0,s1
    80001b5a:	fffff097          	auipc	ra,0xfffff
    80001b5e:	724080e7          	jalr	1828(ra) # 8000127e <uvmunmap>
  uvmfree(pagetable, sz);
    80001b62:	85ca                	mv	a1,s2
    80001b64:	8526                	mv	a0,s1
    80001b66:	00000097          	auipc	ra,0x0
    80001b6a:	9d8080e7          	jalr	-1576(ra) # 8000153e <uvmfree>
}
    80001b6e:	60e2                	ld	ra,24(sp)
    80001b70:	6442                	ld	s0,16(sp)
    80001b72:	64a2                	ld	s1,8(sp)
    80001b74:	6902                	ld	s2,0(sp)
    80001b76:	6105                	addi	sp,sp,32
    80001b78:	8082                	ret

0000000080001b7a <freeproc>:
{
    80001b7a:	1101                	addi	sp,sp,-32
    80001b7c:	ec06                	sd	ra,24(sp)
    80001b7e:	e822                	sd	s0,16(sp)
    80001b80:	e426                	sd	s1,8(sp)
    80001b82:	1000                	addi	s0,sp,32
    80001b84:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b86:	6d28                	ld	a0,88(a0)
    80001b88:	c509                	beqz	a0,80001b92 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b8a:	fffff097          	auipc	ra,0xfffff
    80001b8e:	e6e080e7          	jalr	-402(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b92:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b96:	68a8                	ld	a0,80(s1)
    80001b98:	c511                	beqz	a0,80001ba4 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b9a:	64ac                	ld	a1,72(s1)
    80001b9c:	00000097          	auipc	ra,0x0
    80001ba0:	f8c080e7          	jalr	-116(ra) # 80001b28 <proc_freepagetable>
  p->pagetable = 0;
    80001ba4:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001ba8:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bac:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bb0:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bb4:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bb8:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bbc:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bc0:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bc4:	0004ac23          	sw	zero,24(s1)
}
    80001bc8:	60e2                	ld	ra,24(sp)
    80001bca:	6442                	ld	s0,16(sp)
    80001bcc:	64a2                	ld	s1,8(sp)
    80001bce:	6105                	addi	sp,sp,32
    80001bd0:	8082                	ret

0000000080001bd2 <allocproc>:
{
    80001bd2:	1101                	addi	sp,sp,-32
    80001bd4:	ec06                	sd	ra,24(sp)
    80001bd6:	e822                	sd	s0,16(sp)
    80001bd8:	e426                	sd	s1,8(sp)
    80001bda:	e04a                	sd	s2,0(sp)
    80001bdc:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bde:	00008497          	auipc	s1,0x8
    80001be2:	68248493          	addi	s1,s1,1666 # 8000a260 <proc>
    80001be6:	0000f917          	auipc	s2,0xf
    80001bea:	87a90913          	addi	s2,s2,-1926 # 80010460 <tickslock>
    acquire(&p->lock);
    80001bee:	8526                	mv	a0,s1
    80001bf0:	fffff097          	auipc	ra,0xfffff
    80001bf4:	ff4080e7          	jalr	-12(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001bf8:	4c9c                	lw	a5,24(s1)
    80001bfa:	cf81                	beqz	a5,80001c12 <allocproc+0x40>
      release(&p->lock);
    80001bfc:	8526                	mv	a0,s1
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	09a080e7          	jalr	154(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c06:	18848493          	addi	s1,s1,392
    80001c0a:	ff2492e3          	bne	s1,s2,80001bee <allocproc+0x1c>
  return 0;
    80001c0e:	4481                	li	s1,0
    80001c10:	a09d                	j	80001c76 <allocproc+0xa4>
  p->pid = allocpid();
    80001c12:	00000097          	auipc	ra,0x0
    80001c16:	e34080e7          	jalr	-460(ra) # 80001a46 <allocpid>
    80001c1a:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c1c:	4785                	li	a5,1
    80001c1e:	cc9c                	sw	a5,24(s1)
  p->mean_ticks = 0;
    80001c20:	1604a423          	sw	zero,360(s1)
  p->last_ticks = 0;
    80001c24:	1604a623          	sw	zero,364(s1)
  p->start_cpu_burst = 0;
    80001c28:	1604a823          	sw	zero,368(s1)
  p->last_runnable_time = 0;
    80001c2c:	1604aa23          	sw	zero,372(s1)
  p->start_sleeping = 0;
    80001c30:	1804a223          	sw	zero,388(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c34:	fffff097          	auipc	ra,0xfffff
    80001c38:	ec0080e7          	jalr	-320(ra) # 80000af4 <kalloc>
    80001c3c:	892a                	mv	s2,a0
    80001c3e:	eca8                	sd	a0,88(s1)
    80001c40:	c131                	beqz	a0,80001c84 <allocproc+0xb2>
  p->pagetable = proc_pagetable(p);
    80001c42:	8526                	mv	a0,s1
    80001c44:	00000097          	auipc	ra,0x0
    80001c48:	e48080e7          	jalr	-440(ra) # 80001a8c <proc_pagetable>
    80001c4c:	892a                	mv	s2,a0
    80001c4e:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c50:	c531                	beqz	a0,80001c9c <allocproc+0xca>
  memset(&p->context, 0, sizeof(p->context));
    80001c52:	07000613          	li	a2,112
    80001c56:	4581                	li	a1,0
    80001c58:	06048513          	addi	a0,s1,96
    80001c5c:	fffff097          	auipc	ra,0xfffff
    80001c60:	084080e7          	jalr	132(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c64:	00000797          	auipc	a5,0x0
    80001c68:	d9c78793          	addi	a5,a5,-612 # 80001a00 <forkret>
    80001c6c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c6e:	60bc                	ld	a5,64(s1)
    80001c70:	6705                	lui	a4,0x1
    80001c72:	97ba                	add	a5,a5,a4
    80001c74:	f4bc                	sd	a5,104(s1)
}
    80001c76:	8526                	mv	a0,s1
    80001c78:	60e2                	ld	ra,24(sp)
    80001c7a:	6442                	ld	s0,16(sp)
    80001c7c:	64a2                	ld	s1,8(sp)
    80001c7e:	6902                	ld	s2,0(sp)
    80001c80:	6105                	addi	sp,sp,32
    80001c82:	8082                	ret
    freeproc(p);
    80001c84:	8526                	mv	a0,s1
    80001c86:	00000097          	auipc	ra,0x0
    80001c8a:	ef4080e7          	jalr	-268(ra) # 80001b7a <freeproc>
    release(&p->lock);
    80001c8e:	8526                	mv	a0,s1
    80001c90:	fffff097          	auipc	ra,0xfffff
    80001c94:	008080e7          	jalr	8(ra) # 80000c98 <release>
    return 0;
    80001c98:	84ca                	mv	s1,s2
    80001c9a:	bff1                	j	80001c76 <allocproc+0xa4>
    freeproc(p);
    80001c9c:	8526                	mv	a0,s1
    80001c9e:	00000097          	auipc	ra,0x0
    80001ca2:	edc080e7          	jalr	-292(ra) # 80001b7a <freeproc>
    release(&p->lock);
    80001ca6:	8526                	mv	a0,s1
    80001ca8:	fffff097          	auipc	ra,0xfffff
    80001cac:	ff0080e7          	jalr	-16(ra) # 80000c98 <release>
    return 0;
    80001cb0:	84ca                	mv	s1,s2
    80001cb2:	b7d1                	j	80001c76 <allocproc+0xa4>

0000000080001cb4 <userinit>:
{
    80001cb4:	1101                	addi	sp,sp,-32
    80001cb6:	ec06                	sd	ra,24(sp)
    80001cb8:	e822                	sd	s0,16(sp)
    80001cba:	e426                	sd	s1,8(sp)
    80001cbc:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cbe:	00000097          	auipc	ra,0x0
    80001cc2:	f14080e7          	jalr	-236(ra) # 80001bd2 <allocproc>
    80001cc6:	84aa                	mv	s1,a0
  initproc = p;
    80001cc8:	00007797          	auipc	a5,0x7
    80001ccc:	38a7b423          	sd	a0,904(a5) # 80009050 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cd0:	03400613          	li	a2,52
    80001cd4:	00007597          	auipc	a1,0x7
    80001cd8:	c3c58593          	addi	a1,a1,-964 # 80008910 <initcode>
    80001cdc:	6928                	ld	a0,80(a0)
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	692080e7          	jalr	1682(ra) # 80001370 <uvminit>
  p->sz = PGSIZE;
    80001ce6:	6785                	lui	a5,0x1
    80001ce8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cea:	6cb8                	ld	a4,88(s1)
    80001cec:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cf0:	6cb8                	ld	a4,88(s1)
    80001cf2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cf4:	4641                	li	a2,16
    80001cf6:	00006597          	auipc	a1,0x6
    80001cfa:	50a58593          	addi	a1,a1,1290 # 80008200 <digits+0x1c0>
    80001cfe:	15848513          	addi	a0,s1,344
    80001d02:	fffff097          	auipc	ra,0xfffff
    80001d06:	130080e7          	jalr	304(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001d0a:	00006517          	auipc	a0,0x6
    80001d0e:	50650513          	addi	a0,a0,1286 # 80008210 <digits+0x1d0>
    80001d12:	00002097          	auipc	ra,0x2
    80001d16:	754080e7          	jalr	1876(ra) # 80004466 <namei>
    80001d1a:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d1e:	478d                	li	a5,3
    80001d20:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;
    80001d22:	00007797          	auipc	a5,0x7
    80001d26:	3367a783          	lw	a5,822(a5) # 80009058 <ticks>
    80001d2a:	16f4aa23          	sw	a5,372(s1)
  release(&p->lock);
    80001d2e:	8526                	mv	a0,s1
    80001d30:	fffff097          	auipc	ra,0xfffff
    80001d34:	f68080e7          	jalr	-152(ra) # 80000c98 <release>
}
    80001d38:	60e2                	ld	ra,24(sp)
    80001d3a:	6442                	ld	s0,16(sp)
    80001d3c:	64a2                	ld	s1,8(sp)
    80001d3e:	6105                	addi	sp,sp,32
    80001d40:	8082                	ret

0000000080001d42 <growproc>:
{
    80001d42:	1101                	addi	sp,sp,-32
    80001d44:	ec06                	sd	ra,24(sp)
    80001d46:	e822                	sd	s0,16(sp)
    80001d48:	e426                	sd	s1,8(sp)
    80001d4a:	e04a                	sd	s2,0(sp)
    80001d4c:	1000                	addi	s0,sp,32
    80001d4e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d50:	00000097          	auipc	ra,0x0
    80001d54:	c78080e7          	jalr	-904(ra) # 800019c8 <myproc>
    80001d58:	892a                	mv	s2,a0
  sz = p->sz;
    80001d5a:	652c                	ld	a1,72(a0)
    80001d5c:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d60:	00904f63          	bgtz	s1,80001d7e <growproc+0x3c>
  } else if(n < 0){
    80001d64:	0204cc63          	bltz	s1,80001d9c <growproc+0x5a>
  p->sz = sz;
    80001d68:	1602                	slli	a2,a2,0x20
    80001d6a:	9201                	srli	a2,a2,0x20
    80001d6c:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d70:	4501                	li	a0,0
}
    80001d72:	60e2                	ld	ra,24(sp)
    80001d74:	6442                	ld	s0,16(sp)
    80001d76:	64a2                	ld	s1,8(sp)
    80001d78:	6902                	ld	s2,0(sp)
    80001d7a:	6105                	addi	sp,sp,32
    80001d7c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d7e:	9e25                	addw	a2,a2,s1
    80001d80:	1602                	slli	a2,a2,0x20
    80001d82:	9201                	srli	a2,a2,0x20
    80001d84:	1582                	slli	a1,a1,0x20
    80001d86:	9181                	srli	a1,a1,0x20
    80001d88:	6928                	ld	a0,80(a0)
    80001d8a:	fffff097          	auipc	ra,0xfffff
    80001d8e:	6a0080e7          	jalr	1696(ra) # 8000142a <uvmalloc>
    80001d92:	0005061b          	sext.w	a2,a0
    80001d96:	fa69                	bnez	a2,80001d68 <growproc+0x26>
      return -1;
    80001d98:	557d                	li	a0,-1
    80001d9a:	bfe1                	j	80001d72 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d9c:	9e25                	addw	a2,a2,s1
    80001d9e:	1602                	slli	a2,a2,0x20
    80001da0:	9201                	srli	a2,a2,0x20
    80001da2:	1582                	slli	a1,a1,0x20
    80001da4:	9181                	srli	a1,a1,0x20
    80001da6:	6928                	ld	a0,80(a0)
    80001da8:	fffff097          	auipc	ra,0xfffff
    80001dac:	63a080e7          	jalr	1594(ra) # 800013e2 <uvmdealloc>
    80001db0:	0005061b          	sext.w	a2,a0
    80001db4:	bf55                	j	80001d68 <growproc+0x26>

0000000080001db6 <fork>:
{
    80001db6:	7179                	addi	sp,sp,-48
    80001db8:	f406                	sd	ra,40(sp)
    80001dba:	f022                	sd	s0,32(sp)
    80001dbc:	ec26                	sd	s1,24(sp)
    80001dbe:	e84a                	sd	s2,16(sp)
    80001dc0:	e44e                	sd	s3,8(sp)
    80001dc2:	e052                	sd	s4,0(sp)
    80001dc4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001dc6:	00000097          	auipc	ra,0x0
    80001dca:	c02080e7          	jalr	-1022(ra) # 800019c8 <myproc>
    80001dce:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001dd0:	00000097          	auipc	ra,0x0
    80001dd4:	e02080e7          	jalr	-510(ra) # 80001bd2 <allocproc>
    80001dd8:	12050163          	beqz	a0,80001efa <fork+0x144>
    80001ddc:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dde:	04893603          	ld	a2,72(s2)
    80001de2:	692c                	ld	a1,80(a0)
    80001de4:	05093503          	ld	a0,80(s2)
    80001de8:	fffff097          	auipc	ra,0xfffff
    80001dec:	78e080e7          	jalr	1934(ra) # 80001576 <uvmcopy>
    80001df0:	04054663          	bltz	a0,80001e3c <fork+0x86>
  np->sz = p->sz;
    80001df4:	04893783          	ld	a5,72(s2)
    80001df8:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dfc:	05893683          	ld	a3,88(s2)
    80001e00:	87b6                	mv	a5,a3
    80001e02:	0589b703          	ld	a4,88(s3)
    80001e06:	12068693          	addi	a3,a3,288
    80001e0a:	0007b803          	ld	a6,0(a5)
    80001e0e:	6788                	ld	a0,8(a5)
    80001e10:	6b8c                	ld	a1,16(a5)
    80001e12:	6f90                	ld	a2,24(a5)
    80001e14:	01073023          	sd	a6,0(a4)
    80001e18:	e708                	sd	a0,8(a4)
    80001e1a:	eb0c                	sd	a1,16(a4)
    80001e1c:	ef10                	sd	a2,24(a4)
    80001e1e:	02078793          	addi	a5,a5,32
    80001e22:	02070713          	addi	a4,a4,32
    80001e26:	fed792e3          	bne	a5,a3,80001e0a <fork+0x54>
  np->trapframe->a0 = 0;
    80001e2a:	0589b783          	ld	a5,88(s3)
    80001e2e:	0607b823          	sd	zero,112(a5)
    80001e32:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e36:	15000a13          	li	s4,336
    80001e3a:	a03d                	j	80001e68 <fork+0xb2>
    freeproc(np);
    80001e3c:	854e                	mv	a0,s3
    80001e3e:	00000097          	auipc	ra,0x0
    80001e42:	d3c080e7          	jalr	-708(ra) # 80001b7a <freeproc>
    release(&np->lock);
    80001e46:	854e                	mv	a0,s3
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	e50080e7          	jalr	-432(ra) # 80000c98 <release>
    return -1;
    80001e50:	5a7d                	li	s4,-1
    80001e52:	a859                	j	80001ee8 <fork+0x132>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e54:	00003097          	auipc	ra,0x3
    80001e58:	ca8080e7          	jalr	-856(ra) # 80004afc <filedup>
    80001e5c:	009987b3          	add	a5,s3,s1
    80001e60:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e62:	04a1                	addi	s1,s1,8
    80001e64:	01448763          	beq	s1,s4,80001e72 <fork+0xbc>
    if(p->ofile[i])
    80001e68:	009907b3          	add	a5,s2,s1
    80001e6c:	6388                	ld	a0,0(a5)
    80001e6e:	f17d                	bnez	a0,80001e54 <fork+0x9e>
    80001e70:	bfcd                	j	80001e62 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e72:	15093503          	ld	a0,336(s2)
    80001e76:	00002097          	auipc	ra,0x2
    80001e7a:	dfc080e7          	jalr	-516(ra) # 80003c72 <idup>
    80001e7e:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e82:	4641                	li	a2,16
    80001e84:	15890593          	addi	a1,s2,344
    80001e88:	15898513          	addi	a0,s3,344
    80001e8c:	fffff097          	auipc	ra,0xfffff
    80001e90:	fa6080e7          	jalr	-90(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e94:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e98:	854e                	mv	a0,s3
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	dfe080e7          	jalr	-514(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001ea2:	00008497          	auipc	s1,0x8
    80001ea6:	32648493          	addi	s1,s1,806 # 8000a1c8 <wait_lock>
    80001eaa:	8526                	mv	a0,s1
    80001eac:	fffff097          	auipc	ra,0xfffff
    80001eb0:	d38080e7          	jalr	-712(ra) # 80000be4 <acquire>
  np->parent = p;
    80001eb4:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001eb8:	8526                	mv	a0,s1
    80001eba:	fffff097          	auipc	ra,0xfffff
    80001ebe:	dde080e7          	jalr	-546(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001ec2:	854e                	mv	a0,s3
    80001ec4:	fffff097          	auipc	ra,0xfffff
    80001ec8:	d20080e7          	jalr	-736(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001ecc:	478d                	li	a5,3
    80001ece:	00f9ac23          	sw	a5,24(s3)
  np->last_runnable_time = ticks;
    80001ed2:	00007797          	auipc	a5,0x7
    80001ed6:	1867a783          	lw	a5,390(a5) # 80009058 <ticks>
    80001eda:	16f9aa23          	sw	a5,372(s3)
  release(&np->lock);
    80001ede:	854e                	mv	a0,s3
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	db8080e7          	jalr	-584(ra) # 80000c98 <release>
}
    80001ee8:	8552                	mv	a0,s4
    80001eea:	70a2                	ld	ra,40(sp)
    80001eec:	7402                	ld	s0,32(sp)
    80001eee:	64e2                	ld	s1,24(sp)
    80001ef0:	6942                	ld	s2,16(sp)
    80001ef2:	69a2                	ld	s3,8(sp)
    80001ef4:	6a02                	ld	s4,0(sp)
    80001ef6:	6145                	addi	sp,sp,48
    80001ef8:	8082                	ret
    return -1;
    80001efa:	5a7d                	li	s4,-1
    80001efc:	b7f5                	j	80001ee8 <fork+0x132>

0000000080001efe <round_robin>:
round_robin(){
    80001efe:	711d                	addi	sp,sp,-96
    80001f00:	ec86                	sd	ra,88(sp)
    80001f02:	e8a2                	sd	s0,80(sp)
    80001f04:	e4a6                	sd	s1,72(sp)
    80001f06:	e0ca                	sd	s2,64(sp)
    80001f08:	fc4e                	sd	s3,56(sp)
    80001f0a:	f852                	sd	s4,48(sp)
    80001f0c:	f456                	sd	s5,40(sp)
    80001f0e:	f05a                	sd	s6,32(sp)
    80001f10:	ec5e                	sd	s7,24(sp)
    80001f12:	e862                	sd	s8,16(sp)
    80001f14:	e466                	sd	s9,8(sp)
    80001f16:	1080                	addi	s0,sp,96
    printf("Round Robin Policy \n");
    80001f18:	00006517          	auipc	a0,0x6
    80001f1c:	30050513          	addi	a0,a0,768 # 80008218 <digits+0x1d8>
    80001f20:	ffffe097          	auipc	ra,0xffffe
    80001f24:	668080e7          	jalr	1640(ra) # 80000588 <printf>
    80001f28:	8792                	mv	a5,tp
  int id = r_tp();
    80001f2a:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f2c:	00779c93          	slli	s9,a5,0x7
    80001f30:	00008717          	auipc	a4,0x8
    80001f34:	28070713          	addi	a4,a4,640 # 8000a1b0 <pid_lock>
    80001f38:	9766                	add	a4,a4,s9
    80001f3a:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &p->context);
    80001f3e:	00008717          	auipc	a4,0x8
    80001f42:	2aa70713          	addi	a4,a4,682 # 8000a1e8 <cpus+0x8>
    80001f46:	9cba                	add	s9,s9,a4
          c->proc = p;
    80001f48:	079e                	slli	a5,a5,0x7
    80001f4a:	00008b17          	auipc	s6,0x8
    80001f4e:	266b0b13          	addi	s6,s6,614 # 8000a1b0 <pid_lock>
    80001f52:	9b3e                	add	s6,s6,a5
          p-> runnable_time += (ticks - p->last_runnable_time); 
    80001f54:	00007997          	auipc	s3,0x7
    80001f58:	10498993          	addi	s3,s3,260 # 80009058 <ticks>
          if(p->pid != 1 && p->pid != 2 && pause_time != 0){
    80001f5c:	00007b97          	auipc	s7,0x7
    80001f60:	0f0b8b93          	addi	s7,s7,240 # 8000904c <pause_time>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f6c:	10079073          	csrw	sstatus,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f70:	00008497          	auipc	s1,0x8
    80001f74:	2f048493          	addi	s1,s1,752 # 8000a260 <proc>
        if(p->state == RUNNABLE) {
    80001f78:	4a8d                	li	s5,3
          if(p->pid != 1 && p->pid != 2 && pause_time != 0){
    80001f7a:	4c05                	li	s8,1
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f7c:	0000ea17          	auipc	s4,0xe
    80001f80:	4e4a0a13          	addi	s4,s4,1252 # 80010460 <tickslock>
    80001f84:	a08d                	j	80001fe6 <round_robin+0xe8>
              pause_time = 0;
    80001f86:	000ba023          	sw	zero,0(s7)
          p->state = RUNNING; 
    80001f8a:	4791                	li	a5,4
    80001f8c:	cc9c                	sw	a5,24(s1)
          c->proc = p;
    80001f8e:	029b3823          	sd	s1,48(s6)
          p-> runnable_time += (ticks - p->last_runnable_time); 
    80001f92:	0009a703          	lw	a4,0(s3)
    80001f96:	17c4a783          	lw	a5,380(s1)
    80001f9a:	9fb9                	addw	a5,a5,a4
    80001f9c:	1744a683          	lw	a3,372(s1)
    80001fa0:	9f95                	subw	a5,a5,a3
    80001fa2:	16f4ae23          	sw	a5,380(s1)
          p->start_cpu_burst = ticks;
    80001fa6:	16e4a823          	sw	a4,368(s1)
          swtch(&c->context, &p->context);
    80001faa:	06090593          	addi	a1,s2,96
    80001fae:	8566                	mv	a0,s9
    80001fb0:	00001097          	auipc	ra,0x1
    80001fb4:	c38080e7          	jalr	-968(ra) # 80002be8 <swtch>
          p->last_ticks = ticks - p->start_cpu_burst;
    80001fb8:	0009a783          	lw	a5,0(s3)
    80001fbc:	1704a703          	lw	a4,368(s1)
    80001fc0:	9f99                	subw	a5,a5,a4
    80001fc2:	16f4a623          	sw	a5,364(s1)
          p->running_time = p->running_time + p->last_ticks;
    80001fc6:	1804a703          	lw	a4,384(s1)
    80001fca:	9fb9                	addw	a5,a5,a4
    80001fcc:	18f4a023          	sw	a5,384(s1)
          c->proc = 0;
    80001fd0:	020b3823          	sd	zero,48(s6)
        release(&p->lock);
    80001fd4:	8526                	mv	a0,s1
    80001fd6:	fffff097          	auipc	ra,0xfffff
    80001fda:	cc2080e7          	jalr	-830(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fde:	18848493          	addi	s1,s1,392
    80001fe2:	f94481e3          	beq	s1,s4,80001f64 <round_robin+0x66>
        acquire(&p->lock);
    80001fe6:	8926                	mv	s2,s1
    80001fe8:	8526                	mv	a0,s1
    80001fea:	fffff097          	auipc	ra,0xfffff
    80001fee:	bfa080e7          	jalr	-1030(ra) # 80000be4 <acquire>
        if(p->state == RUNNABLE) {
    80001ff2:	4c9c                	lw	a5,24(s1)
    80001ff4:	ff5790e3          	bne	a5,s5,80001fd4 <round_robin+0xd6>
          if(p->pid != 1 && p->pid != 2 && pause_time != 0){
    80001ff8:	589c                	lw	a5,48(s1)
    80001ffa:	37fd                	addiw	a5,a5,-1
    80001ffc:	f8fc77e3          	bgeu	s8,a5,80001f8a <round_robin+0x8c>
    80002000:	000ba783          	lw	a5,0(s7)
    80002004:	d3d9                	beqz	a5,80001f8a <round_robin+0x8c>
            if(ticks >= pause_time){
    80002006:	0009a703          	lw	a4,0(s3)
    8000200a:	f6f77ee3          	bgeu	a4,a5,80001f86 <round_robin+0x88>
              release(&p->lock);
    8000200e:	8526                	mv	a0,s1
    80002010:	fffff097          	auipc	ra,0xfffff
    80002014:	c88080e7          	jalr	-888(ra) # 80000c98 <release>
              continue;
    80002018:	b7d9                	j	80001fde <round_robin+0xe0>

000000008000201a <scheduler>:
{
    8000201a:	1141                	addi	sp,sp,-16
    8000201c:	e406                	sd	ra,8(sp)
    8000201e:	e022                	sd	s0,0(sp)
    80002020:	0800                	addi	s0,sp,16
    round_robin();
    80002022:	00000097          	auipc	ra,0x0
    80002026:	edc080e7          	jalr	-292(ra) # 80001efe <round_robin>

000000008000202a <sjf>:
sjf(void){
    8000202a:	7159                	addi	sp,sp,-112
    8000202c:	f486                	sd	ra,104(sp)
    8000202e:	f0a2                	sd	s0,96(sp)
    80002030:	eca6                	sd	s1,88(sp)
    80002032:	e8ca                	sd	s2,80(sp)
    80002034:	e4ce                	sd	s3,72(sp)
    80002036:	e0d2                	sd	s4,64(sp)
    80002038:	fc56                	sd	s5,56(sp)
    8000203a:	f85a                	sd	s6,48(sp)
    8000203c:	f45e                	sd	s7,40(sp)
    8000203e:	f062                	sd	s8,32(sp)
    80002040:	ec66                	sd	s9,24(sp)
    80002042:	e86a                	sd	s10,16(sp)
    80002044:	e46e                	sd	s11,8(sp)
    80002046:	1880                	addi	s0,sp,112
  printf("SJF Policy \n");
    80002048:	00006517          	auipc	a0,0x6
    8000204c:	1e850513          	addi	a0,a0,488 # 80008230 <digits+0x1f0>
    80002050:	ffffe097          	auipc	ra,0xffffe
    80002054:	538080e7          	jalr	1336(ra) # 80000588 <printf>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002058:	8792                	mv	a5,tp
  int id = r_tp();
    8000205a:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000205c:	00779693          	slli	a3,a5,0x7
    80002060:	00008717          	auipc	a4,0x8
    80002064:	15070713          	addi	a4,a4,336 # 8000a1b0 <pid_lock>
    80002068:	9736                	add	a4,a4,a3
    8000206a:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &min_proc->context);
    8000206e:	00008717          	auipc	a4,0x8
    80002072:	17a70713          	addi	a4,a4,378 # 8000a1e8 <cpus+0x8>
    80002076:	00e68db3          	add	s11,a3,a4
    int min = -1;
    8000207a:	5c7d                	li	s8,-1
         if(p->pid != 1 && p->pid != 2 && pause_time != 0){
    8000207c:	00007a17          	auipc	s4,0x7
    80002080:	fd0a0a13          	addi	s4,s4,-48 # 8000904c <pause_time>
          if(ticks >= pause_time){
    80002084:	00007b97          	auipc	s7,0x7
    80002088:	fd4b8b93          	addi	s7,s7,-44 # 80009058 <ticks>
          c->proc = min_proc;
    8000208c:	00008d17          	auipc	s10,0x8
    80002090:	124d0d13          	addi	s10,s10,292 # 8000a1b0 <pid_lock>
    80002094:	9d36                	add	s10,s10,a3
    80002096:	a095                	j	800020fa <sjf+0xd0>
           release(&p->lock);
    80002098:	8526                	mv	a0,s1
    8000209a:	fffff097          	auipc	ra,0xfffff
    8000209e:	bfe080e7          	jalr	-1026(ra) # 80000c98 <release>
           continue;
    800020a2:	a809                	j	800020b4 <sjf+0x8a>
      else if((p->state == RUNNABLE) && (min == -1 || p->mean_ticks < min)){
    800020a4:	4c9c                	lw	a5,24(s1)
    800020a6:	03578e63          	beq	a5,s5,800020e2 <sjf+0xb8>
        release(&p->lock);
    800020aa:	8526                	mv	a0,s1
    800020ac:	fffff097          	auipc	ra,0xfffff
    800020b0:	bec080e7          	jalr	-1044(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) { 
    800020b4:	18848493          	addi	s1,s1,392
    800020b8:	03248f63          	beq	s1,s2,800020f6 <sjf+0xcc>
      acquire(&p->lock);
    800020bc:	8526                	mv	a0,s1
    800020be:	fffff097          	auipc	ra,0xfffff
    800020c2:	b26080e7          	jalr	-1242(ra) # 80000be4 <acquire>
         if(p->pid != 1 && p->pid != 2 && pause_time != 0){
    800020c6:	589c                	lw	a5,48(s1)
    800020c8:	37fd                	addiw	a5,a5,-1
    800020ca:	fcf9fde3          	bgeu	s3,a5,800020a4 <sjf+0x7a>
    800020ce:	000a2783          	lw	a5,0(s4)
    800020d2:	dbe9                	beqz	a5,800020a4 <sjf+0x7a>
          if(ticks >= pause_time){
    800020d4:	000ba703          	lw	a4,0(s7)
    800020d8:	fcf760e3          	bltu	a4,a5,80002098 <sjf+0x6e>
            pause_time = 0;
    800020dc:	000a2023          	sw	zero,0(s4)
          if(ticks >= pause_time){
    800020e0:	b7e9                	j	800020aa <sjf+0x80>
      else if((p->state == RUNNABLE) && (min == -1 || p->mean_ticks < min)){
    800020e2:	018b0663          	beq	s6,s8,800020ee <sjf+0xc4>
    800020e6:	1684a783          	lw	a5,360(s1)
    800020ea:	fd67f0e3          	bgeu	a5,s6,800020aa <sjf+0x80>
              min = p->mean_ticks;
    800020ee:	1684ab03          	lw	s6,360(s1)
    800020f2:	8ca6                	mv	s9,s1
    800020f4:	bf5d                	j	800020aa <sjf+0x80>
    if(min == -1){
    800020f6:	038b1463          	bne	s6,s8,8000211e <sjf+0xf4>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020fa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020fe:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002102:	10079073          	csrw	sstatus,a5
    int min = -1;
    80002106:	8b62                	mv	s6,s8
    for(p = proc; p < &proc[NPROC]; p++) { 
    80002108:	00008497          	auipc	s1,0x8
    8000210c:	15848493          	addi	s1,s1,344 # 8000a260 <proc>
         if(p->pid != 1 && p->pid != 2 && pause_time != 0){
    80002110:	4985                	li	s3,1
      else if((p->state == RUNNABLE) && (min == -1 || p->mean_ticks < min)){
    80002112:	4a8d                	li	s5,3
    for(p = proc; p < &proc[NPROC]; p++) { 
    80002114:	0000e917          	auipc	s2,0xe
    80002118:	34c90913          	addi	s2,s2,844 # 80010460 <tickslock>
    8000211c:	b745                	j	800020bc <sjf+0x92>
      acquire(&min_proc->lock);
    8000211e:	84e6                	mv	s1,s9
    80002120:	8566                	mv	a0,s9
    80002122:	fffff097          	auipc	ra,0xfffff
    80002126:	ac2080e7          	jalr	-1342(ra) # 80000be4 <acquire>
         if(min_proc->state == RUNNABLE) {
    8000212a:	018ca703          	lw	a4,24(s9)
    8000212e:	478d                	li	a5,3
    80002130:	00f70863          	beq	a4,a5,80002140 <sjf+0x116>
        release(&min_proc->lock);
    80002134:	8526                	mv	a0,s1
    80002136:	fffff097          	auipc	ra,0xfffff
    8000213a:	b62080e7          	jalr	-1182(ra) # 80000c98 <release>
    8000213e:	bf75                	j	800020fa <sjf+0xd0>
          min_proc->state = RUNNING;
    80002140:	4791                	li	a5,4
    80002142:	00fcac23          	sw	a5,24(s9)
          c->proc = min_proc;
    80002146:	039d3823          	sd	s9,48(s10)
          min_proc->runnable_time += (ticks - min_proc->last_runnable_time); 
    8000214a:	000ba703          	lw	a4,0(s7)
    8000214e:	17cca783          	lw	a5,380(s9)
    80002152:	9fb9                	addw	a5,a5,a4
    80002154:	174ca683          	lw	a3,372(s9)
    80002158:	9f95                	subw	a5,a5,a3
    8000215a:	16fcae23          	sw	a5,380(s9)
          min_proc->start_cpu_burst = ticks;
    8000215e:	16eca823          	sw	a4,368(s9)
          swtch(&c->context, &min_proc->context);
    80002162:	060c8593          	addi	a1,s9,96
    80002166:	856e                	mv	a0,s11
    80002168:	00001097          	auipc	ra,0x1
    8000216c:	a80080e7          	jalr	-1408(ra) # 80002be8 <swtch>
          min_proc->last_ticks = ticks - min_proc->start_cpu_burst;
    80002170:	000ba783          	lw	a5,0(s7)
    80002174:	170ca703          	lw	a4,368(s9)
    80002178:	40e7873b          	subw	a4,a5,a4
    8000217c:	16eca623          	sw	a4,364(s9)
          min_proc->mean_ticks = ((10*rate)* min_proc->mean_ticks + min_proc->last_ticks*(rate)) / 10;
    80002180:	168ca683          	lw	a3,360(s9)
    80002184:	0026979b          	slliw	a5,a3,0x2
    80002188:	9fb5                	addw	a5,a5,a3
    8000218a:	0017979b          	slliw	a5,a5,0x1
    8000218e:	9fb9                	addw	a5,a5,a4
    80002190:	00006717          	auipc	a4,0x6
    80002194:	77472703          	lw	a4,1908(a4) # 80008904 <rate>
    80002198:	02e787bb          	mulw	a5,a5,a4
    8000219c:	4729                	li	a4,10
    8000219e:	02e7d7bb          	divuw	a5,a5,a4
    800021a2:	16fca423          	sw	a5,360(s9)
          c->proc = 0;
    800021a6:	020d3823          	sd	zero,48(s10)
    800021aa:	b769                	j	80002134 <sjf+0x10a>

00000000800021ac <fcfs>:
fcfs(void){
    800021ac:	7159                	addi	sp,sp,-112
    800021ae:	f486                	sd	ra,104(sp)
    800021b0:	f0a2                	sd	s0,96(sp)
    800021b2:	eca6                	sd	s1,88(sp)
    800021b4:	e8ca                	sd	s2,80(sp)
    800021b6:	e4ce                	sd	s3,72(sp)
    800021b8:	e0d2                	sd	s4,64(sp)
    800021ba:	fc56                	sd	s5,56(sp)
    800021bc:	f85a                	sd	s6,48(sp)
    800021be:	f45e                	sd	s7,40(sp)
    800021c0:	f062                	sd	s8,32(sp)
    800021c2:	ec66                	sd	s9,24(sp)
    800021c4:	e86a                	sd	s10,16(sp)
    800021c6:	e46e                	sd	s11,8(sp)
    800021c8:	1880                	addi	s0,sp,112
  printf("FCFS Policy \n");
    800021ca:	00006517          	auipc	a0,0x6
    800021ce:	07650513          	addi	a0,a0,118 # 80008240 <digits+0x200>
    800021d2:	ffffe097          	auipc	ra,0xffffe
    800021d6:	3b6080e7          	jalr	950(ra) # 80000588 <printf>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021da:	8792                	mv	a5,tp
  int id = r_tp();
    800021dc:	2781                	sext.w	a5,a5
  c->proc = 0;
    800021de:	00779693          	slli	a3,a5,0x7
    800021e2:	00008717          	auipc	a4,0x8
    800021e6:	fce70713          	addi	a4,a4,-50 # 8000a1b0 <pid_lock>
    800021ea:	9736                	add	a4,a4,a3
    800021ec:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &min_proc->context);
    800021f0:	00008717          	auipc	a4,0x8
    800021f4:	ff870713          	addi	a4,a4,-8 # 8000a1e8 <cpus+0x8>
    800021f8:	00e68db3          	add	s11,a3,a4
    int min = -1;
    800021fc:	5c7d                	li	s8,-1
         if(p->pid != 1 && p->pid != 2 && pause_time != 0){
    800021fe:	00007a17          	auipc	s4,0x7
    80002202:	e4ea0a13          	addi	s4,s4,-434 # 8000904c <pause_time>
          if(ticks >= pause_time){
    80002206:	00007b97          	auipc	s7,0x7
    8000220a:	e52b8b93          	addi	s7,s7,-430 # 80009058 <ticks>
          c->proc = min_proc;
    8000220e:	00008d17          	auipc	s10,0x8
    80002212:	fa2d0d13          	addi	s10,s10,-94 # 8000a1b0 <pid_lock>
    80002216:	9d36                	add	s10,s10,a3
    80002218:	a095                	j	8000227c <fcfs+0xd0>
           release(&p->lock);
    8000221a:	8526                	mv	a0,s1
    8000221c:	fffff097          	auipc	ra,0xfffff
    80002220:	a7c080e7          	jalr	-1412(ra) # 80000c98 <release>
           continue;
    80002224:	a809                	j	80002236 <fcfs+0x8a>
      else if((p->state == RUNNABLE) && (min == -1 || p->last_runnable_time < min)){
    80002226:	4c9c                	lw	a5,24(s1)
    80002228:	03578e63          	beq	a5,s5,80002264 <fcfs+0xb8>
        release(&p->lock);
    8000222c:	8526                	mv	a0,s1
    8000222e:	fffff097          	auipc	ra,0xfffff
    80002232:	a6a080e7          	jalr	-1430(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) { 
    80002236:	18848493          	addi	s1,s1,392
    8000223a:	03248f63          	beq	s1,s2,80002278 <fcfs+0xcc>
      acquire(&p->lock);
    8000223e:	8526                	mv	a0,s1
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	9a4080e7          	jalr	-1628(ra) # 80000be4 <acquire>
         if(p->pid != 1 && p->pid != 2 && pause_time != 0){
    80002248:	589c                	lw	a5,48(s1)
    8000224a:	37fd                	addiw	a5,a5,-1
    8000224c:	fcf9fde3          	bgeu	s3,a5,80002226 <fcfs+0x7a>
    80002250:	000a2783          	lw	a5,0(s4)
    80002254:	dbe9                	beqz	a5,80002226 <fcfs+0x7a>
          if(ticks >= pause_time){
    80002256:	000ba703          	lw	a4,0(s7)
    8000225a:	fcf760e3          	bltu	a4,a5,8000221a <fcfs+0x6e>
            pause_time = 0;
    8000225e:	000a2023          	sw	zero,0(s4)
          if(ticks >= pause_time){
    80002262:	b7e9                	j	8000222c <fcfs+0x80>
      else if((p->state == RUNNABLE) && (min == -1 || p->last_runnable_time < min)){
    80002264:	018b0663          	beq	s6,s8,80002270 <fcfs+0xc4>
    80002268:	1744a783          	lw	a5,372(s1)
    8000226c:	fd67f0e3          	bgeu	a5,s6,8000222c <fcfs+0x80>
              min = p->last_runnable_time;
    80002270:	1744ab03          	lw	s6,372(s1)
    80002274:	8ca6                	mv	s9,s1
    80002276:	bf5d                	j	8000222c <fcfs+0x80>
    if(min == -1){
    80002278:	038b1463          	bne	s6,s8,800022a0 <fcfs+0xf4>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000227c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002280:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002284:	10079073          	csrw	sstatus,a5
    int min = -1;
    80002288:	8b62                	mv	s6,s8
    for(p = proc; p < &proc[NPROC]; p++) { 
    8000228a:	00008497          	auipc	s1,0x8
    8000228e:	fd648493          	addi	s1,s1,-42 # 8000a260 <proc>
         if(p->pid != 1 && p->pid != 2 && pause_time != 0){
    80002292:	4985                	li	s3,1
      else if((p->state == RUNNABLE) && (min == -1 || p->last_runnable_time < min)){
    80002294:	4a8d                	li	s5,3
    for(p = proc; p < &proc[NPROC]; p++) { 
    80002296:	0000e917          	auipc	s2,0xe
    8000229a:	1ca90913          	addi	s2,s2,458 # 80010460 <tickslock>
    8000229e:	b745                	j	8000223e <fcfs+0x92>
      acquire(&min_proc->lock);
    800022a0:	84e6                	mv	s1,s9
    800022a2:	8566                	mv	a0,s9
    800022a4:	fffff097          	auipc	ra,0xfffff
    800022a8:	940080e7          	jalr	-1728(ra) # 80000be4 <acquire>
         if(min_proc->state == RUNNABLE) {
    800022ac:	018ca703          	lw	a4,24(s9)
    800022b0:	478d                	li	a5,3
    800022b2:	00f70863          	beq	a4,a5,800022c2 <fcfs+0x116>
        release(&min_proc->lock);
    800022b6:	8526                	mv	a0,s1
    800022b8:	fffff097          	auipc	ra,0xfffff
    800022bc:	9e0080e7          	jalr	-1568(ra) # 80000c98 <release>
    800022c0:	bf75                	j	8000227c <fcfs+0xd0>
          min_proc->state = RUNNING;
    800022c2:	4791                	li	a5,4
    800022c4:	00fcac23          	sw	a5,24(s9)
          c->proc = min_proc;
    800022c8:	039d3823          	sd	s9,48(s10)
          min_proc->runnable_time += (ticks - min_proc->last_runnable_time); 
    800022cc:	000ba703          	lw	a4,0(s7)
    800022d0:	17cca783          	lw	a5,380(s9)
    800022d4:	9fb9                	addw	a5,a5,a4
    800022d6:	174ca683          	lw	a3,372(s9)
    800022da:	9f95                	subw	a5,a5,a3
    800022dc:	16fcae23          	sw	a5,380(s9)
          min_proc->start_cpu_burst = ticks;
    800022e0:	16eca823          	sw	a4,368(s9)
          swtch(&c->context, &min_proc->context);
    800022e4:	060c8593          	addi	a1,s9,96
    800022e8:	856e                	mv	a0,s11
    800022ea:	00001097          	auipc	ra,0x1
    800022ee:	8fe080e7          	jalr	-1794(ra) # 80002be8 <swtch>
          min_proc->last_ticks = ticks - min_proc->start_cpu_burst;
    800022f2:	000ba783          	lw	a5,0(s7)
    800022f6:	170ca703          	lw	a4,368(s9)
    800022fa:	9f99                	subw	a5,a5,a4
    800022fc:	16fca623          	sw	a5,364(s9)
          c->proc = 0;
    80002300:	020d3823          	sd	zero,48(s10)
    80002304:	bf4d                	j	800022b6 <fcfs+0x10a>

0000000080002306 <sched>:
{
    80002306:	7179                	addi	sp,sp,-48
    80002308:	f406                	sd	ra,40(sp)
    8000230a:	f022                	sd	s0,32(sp)
    8000230c:	ec26                	sd	s1,24(sp)
    8000230e:	e84a                	sd	s2,16(sp)
    80002310:	e44e                	sd	s3,8(sp)
    80002312:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002314:	fffff097          	auipc	ra,0xfffff
    80002318:	6b4080e7          	jalr	1716(ra) # 800019c8 <myproc>
    8000231c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000231e:	fffff097          	auipc	ra,0xfffff
    80002322:	84c080e7          	jalr	-1972(ra) # 80000b6a <holding>
    80002326:	c93d                	beqz	a0,8000239c <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002328:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000232a:	2781                	sext.w	a5,a5
    8000232c:	079e                	slli	a5,a5,0x7
    8000232e:	00008717          	auipc	a4,0x8
    80002332:	e8270713          	addi	a4,a4,-382 # 8000a1b0 <pid_lock>
    80002336:	97ba                	add	a5,a5,a4
    80002338:	0a87a703          	lw	a4,168(a5)
    8000233c:	4785                	li	a5,1
    8000233e:	06f71763          	bne	a4,a5,800023ac <sched+0xa6>
  if(p->state == RUNNING)
    80002342:	4c98                	lw	a4,24(s1)
    80002344:	4791                	li	a5,4
    80002346:	06f70b63          	beq	a4,a5,800023bc <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000234a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000234e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002350:	efb5                	bnez	a5,800023cc <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002352:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002354:	00008917          	auipc	s2,0x8
    80002358:	e5c90913          	addi	s2,s2,-420 # 8000a1b0 <pid_lock>
    8000235c:	2781                	sext.w	a5,a5
    8000235e:	079e                	slli	a5,a5,0x7
    80002360:	97ca                	add	a5,a5,s2
    80002362:	0ac7a983          	lw	s3,172(a5)
    80002366:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002368:	2781                	sext.w	a5,a5
    8000236a:	079e                	slli	a5,a5,0x7
    8000236c:	00008597          	auipc	a1,0x8
    80002370:	e7c58593          	addi	a1,a1,-388 # 8000a1e8 <cpus+0x8>
    80002374:	95be                	add	a1,a1,a5
    80002376:	06048513          	addi	a0,s1,96
    8000237a:	00001097          	auipc	ra,0x1
    8000237e:	86e080e7          	jalr	-1938(ra) # 80002be8 <swtch>
    80002382:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002384:	2781                	sext.w	a5,a5
    80002386:	079e                	slli	a5,a5,0x7
    80002388:	97ca                	add	a5,a5,s2
    8000238a:	0b37a623          	sw	s3,172(a5)
}
    8000238e:	70a2                	ld	ra,40(sp)
    80002390:	7402                	ld	s0,32(sp)
    80002392:	64e2                	ld	s1,24(sp)
    80002394:	6942                	ld	s2,16(sp)
    80002396:	69a2                	ld	s3,8(sp)
    80002398:	6145                	addi	sp,sp,48
    8000239a:	8082                	ret
    panic("sched p->lock");
    8000239c:	00006517          	auipc	a0,0x6
    800023a0:	eb450513          	addi	a0,a0,-332 # 80008250 <digits+0x210>
    800023a4:	ffffe097          	auipc	ra,0xffffe
    800023a8:	19a080e7          	jalr	410(ra) # 8000053e <panic>
    panic("sched locks");
    800023ac:	00006517          	auipc	a0,0x6
    800023b0:	eb450513          	addi	a0,a0,-332 # 80008260 <digits+0x220>
    800023b4:	ffffe097          	auipc	ra,0xffffe
    800023b8:	18a080e7          	jalr	394(ra) # 8000053e <panic>
    panic("sched running");
    800023bc:	00006517          	auipc	a0,0x6
    800023c0:	eb450513          	addi	a0,a0,-332 # 80008270 <digits+0x230>
    800023c4:	ffffe097          	auipc	ra,0xffffe
    800023c8:	17a080e7          	jalr	378(ra) # 8000053e <panic>
    panic("sched interruptible");
    800023cc:	00006517          	auipc	a0,0x6
    800023d0:	eb450513          	addi	a0,a0,-332 # 80008280 <digits+0x240>
    800023d4:	ffffe097          	auipc	ra,0xffffe
    800023d8:	16a080e7          	jalr	362(ra) # 8000053e <panic>

00000000800023dc <yield>:
{
    800023dc:	1101                	addi	sp,sp,-32
    800023de:	ec06                	sd	ra,24(sp)
    800023e0:	e822                	sd	s0,16(sp)
    800023e2:	e426                	sd	s1,8(sp)
    800023e4:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800023e6:	fffff097          	auipc	ra,0xfffff
    800023ea:	5e2080e7          	jalr	1506(ra) # 800019c8 <myproc>
    800023ee:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800023f0:	ffffe097          	auipc	ra,0xffffe
    800023f4:	7f4080e7          	jalr	2036(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800023f8:	478d                	li	a5,3
    800023fa:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;  
    800023fc:	00007717          	auipc	a4,0x7
    80002400:	c5c72703          	lw	a4,-932(a4) # 80009058 <ticks>
    80002404:	16e4aa23          	sw	a4,372(s1)
  p->running_time += ticks - p->start_cpu_burst;   //IS IT GOOD WITH RR?
    80002408:	1804a783          	lw	a5,384(s1)
    8000240c:	9fb9                	addw	a5,a5,a4
    8000240e:	1704a703          	lw	a4,368(s1)
    80002412:	9f99                	subw	a5,a5,a4
    80002414:	18f4a023          	sw	a5,384(s1)
  sched();
    80002418:	00000097          	auipc	ra,0x0
    8000241c:	eee080e7          	jalr	-274(ra) # 80002306 <sched>
  release(&p->lock);
    80002420:	8526                	mv	a0,s1
    80002422:	fffff097          	auipc	ra,0xfffff
    80002426:	876080e7          	jalr	-1930(ra) # 80000c98 <release>
}
    8000242a:	60e2                	ld	ra,24(sp)
    8000242c:	6442                	ld	s0,16(sp)
    8000242e:	64a2                	ld	s1,8(sp)
    80002430:	6105                	addi	sp,sp,32
    80002432:	8082                	ret

0000000080002434 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002434:	7179                	addi	sp,sp,-48
    80002436:	f406                	sd	ra,40(sp)
    80002438:	f022                	sd	s0,32(sp)
    8000243a:	ec26                	sd	s1,24(sp)
    8000243c:	e84a                	sd	s2,16(sp)
    8000243e:	e44e                	sd	s3,8(sp)
    80002440:	1800                	addi	s0,sp,48
    80002442:	89aa                	mv	s3,a0
    80002444:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002446:	fffff097          	auipc	ra,0xfffff
    8000244a:	582080e7          	jalr	1410(ra) # 800019c8 <myproc>
    8000244e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002450:	ffffe097          	auipc	ra,0xffffe
    80002454:	794080e7          	jalr	1940(ra) # 80000be4 <acquire>
  release(lk);
    80002458:	854a                	mv	a0,s2
    8000245a:	fffff097          	auipc	ra,0xfffff
    8000245e:	83e080e7          	jalr	-1986(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002462:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002466:	4789                	li	a5,2
    80002468:	cc9c                	sw	a5,24(s1)
  p->start_sleeping = ticks;
    8000246a:	00007717          	auipc	a4,0x7
    8000246e:	bee72703          	lw	a4,-1042(a4) # 80009058 <ticks>
    80002472:	18e4a223          	sw	a4,388(s1)
  p->running_time += (ticks - p->start_cpu_burst);
    80002476:	1804a783          	lw	a5,384(s1)
    8000247a:	9fb9                	addw	a5,a5,a4
    8000247c:	1704a703          	lw	a4,368(s1)
    80002480:	9f99                	subw	a5,a5,a4
    80002482:	18f4a023          	sw	a5,384(s1)
  sched();
    80002486:	00000097          	auipc	ra,0x0
    8000248a:	e80080e7          	jalr	-384(ra) # 80002306 <sched>

  // Tidy up.
  p->chan = 0;
    8000248e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002492:	8526                	mv	a0,s1
    80002494:	fffff097          	auipc	ra,0xfffff
    80002498:	804080e7          	jalr	-2044(ra) # 80000c98 <release>
  acquire(lk);
    8000249c:	854a                	mv	a0,s2
    8000249e:	ffffe097          	auipc	ra,0xffffe
    800024a2:	746080e7          	jalr	1862(ra) # 80000be4 <acquire>
}
    800024a6:	70a2                	ld	ra,40(sp)
    800024a8:	7402                	ld	s0,32(sp)
    800024aa:	64e2                	ld	s1,24(sp)
    800024ac:	6942                	ld	s2,16(sp)
    800024ae:	69a2                	ld	s3,8(sp)
    800024b0:	6145                	addi	sp,sp,48
    800024b2:	8082                	ret

00000000800024b4 <wait>:
{
    800024b4:	715d                	addi	sp,sp,-80
    800024b6:	e486                	sd	ra,72(sp)
    800024b8:	e0a2                	sd	s0,64(sp)
    800024ba:	fc26                	sd	s1,56(sp)
    800024bc:	f84a                	sd	s2,48(sp)
    800024be:	f44e                	sd	s3,40(sp)
    800024c0:	f052                	sd	s4,32(sp)
    800024c2:	ec56                	sd	s5,24(sp)
    800024c4:	e85a                	sd	s6,16(sp)
    800024c6:	e45e                	sd	s7,8(sp)
    800024c8:	e062                	sd	s8,0(sp)
    800024ca:	0880                	addi	s0,sp,80
    800024cc:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800024ce:	fffff097          	auipc	ra,0xfffff
    800024d2:	4fa080e7          	jalr	1274(ra) # 800019c8 <myproc>
    800024d6:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800024d8:	00008517          	auipc	a0,0x8
    800024dc:	cf050513          	addi	a0,a0,-784 # 8000a1c8 <wait_lock>
    800024e0:	ffffe097          	auipc	ra,0xffffe
    800024e4:	704080e7          	jalr	1796(ra) # 80000be4 <acquire>
    havekids = 0;
    800024e8:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800024ea:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800024ec:	0000e997          	auipc	s3,0xe
    800024f0:	f7498993          	addi	s3,s3,-140 # 80010460 <tickslock>
        havekids = 1;
    800024f4:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024f6:	00008c17          	auipc	s8,0x8
    800024fa:	cd2c0c13          	addi	s8,s8,-814 # 8000a1c8 <wait_lock>
    havekids = 0;
    800024fe:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002500:	00008497          	auipc	s1,0x8
    80002504:	d6048493          	addi	s1,s1,-672 # 8000a260 <proc>
    80002508:	a0bd                	j	80002576 <wait+0xc2>
          pid = np->pid;
    8000250a:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000250e:	000b0e63          	beqz	s6,8000252a <wait+0x76>
    80002512:	4691                	li	a3,4
    80002514:	02c48613          	addi	a2,s1,44
    80002518:	85da                	mv	a1,s6
    8000251a:	05093503          	ld	a0,80(s2)
    8000251e:	fffff097          	auipc	ra,0xfffff
    80002522:	15c080e7          	jalr	348(ra) # 8000167a <copyout>
    80002526:	02054563          	bltz	a0,80002550 <wait+0x9c>
          freeproc(np);
    8000252a:	8526                	mv	a0,s1
    8000252c:	fffff097          	auipc	ra,0xfffff
    80002530:	64e080e7          	jalr	1614(ra) # 80001b7a <freeproc>
          release(&np->lock);
    80002534:	8526                	mv	a0,s1
    80002536:	ffffe097          	auipc	ra,0xffffe
    8000253a:	762080e7          	jalr	1890(ra) # 80000c98 <release>
          release(&wait_lock);
    8000253e:	00008517          	auipc	a0,0x8
    80002542:	c8a50513          	addi	a0,a0,-886 # 8000a1c8 <wait_lock>
    80002546:	ffffe097          	auipc	ra,0xffffe
    8000254a:	752080e7          	jalr	1874(ra) # 80000c98 <release>
          return pid;
    8000254e:	a09d                	j	800025b4 <wait+0x100>
            release(&np->lock);
    80002550:	8526                	mv	a0,s1
    80002552:	ffffe097          	auipc	ra,0xffffe
    80002556:	746080e7          	jalr	1862(ra) # 80000c98 <release>
            release(&wait_lock);
    8000255a:	00008517          	auipc	a0,0x8
    8000255e:	c6e50513          	addi	a0,a0,-914 # 8000a1c8 <wait_lock>
    80002562:	ffffe097          	auipc	ra,0xffffe
    80002566:	736080e7          	jalr	1846(ra) # 80000c98 <release>
            return -1;
    8000256a:	59fd                	li	s3,-1
    8000256c:	a0a1                	j	800025b4 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000256e:	18848493          	addi	s1,s1,392
    80002572:	03348463          	beq	s1,s3,8000259a <wait+0xe6>
      if(np->parent == p){
    80002576:	7c9c                	ld	a5,56(s1)
    80002578:	ff279be3          	bne	a5,s2,8000256e <wait+0xba>
        acquire(&np->lock);
    8000257c:	8526                	mv	a0,s1
    8000257e:	ffffe097          	auipc	ra,0xffffe
    80002582:	666080e7          	jalr	1638(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002586:	4c9c                	lw	a5,24(s1)
    80002588:	f94781e3          	beq	a5,s4,8000250a <wait+0x56>
        release(&np->lock);
    8000258c:	8526                	mv	a0,s1
    8000258e:	ffffe097          	auipc	ra,0xffffe
    80002592:	70a080e7          	jalr	1802(ra) # 80000c98 <release>
        havekids = 1;
    80002596:	8756                	mv	a4,s5
    80002598:	bfd9                	j	8000256e <wait+0xba>
    if(!havekids || p->killed){
    8000259a:	c701                	beqz	a4,800025a2 <wait+0xee>
    8000259c:	02892783          	lw	a5,40(s2)
    800025a0:	c79d                	beqz	a5,800025ce <wait+0x11a>
      release(&wait_lock);
    800025a2:	00008517          	auipc	a0,0x8
    800025a6:	c2650513          	addi	a0,a0,-986 # 8000a1c8 <wait_lock>
    800025aa:	ffffe097          	auipc	ra,0xffffe
    800025ae:	6ee080e7          	jalr	1774(ra) # 80000c98 <release>
      return -1;
    800025b2:	59fd                	li	s3,-1
}
    800025b4:	854e                	mv	a0,s3
    800025b6:	60a6                	ld	ra,72(sp)
    800025b8:	6406                	ld	s0,64(sp)
    800025ba:	74e2                	ld	s1,56(sp)
    800025bc:	7942                	ld	s2,48(sp)
    800025be:	79a2                	ld	s3,40(sp)
    800025c0:	7a02                	ld	s4,32(sp)
    800025c2:	6ae2                	ld	s5,24(sp)
    800025c4:	6b42                	ld	s6,16(sp)
    800025c6:	6ba2                	ld	s7,8(sp)
    800025c8:	6c02                	ld	s8,0(sp)
    800025ca:	6161                	addi	sp,sp,80
    800025cc:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800025ce:	85e2                	mv	a1,s8
    800025d0:	854a                	mv	a0,s2
    800025d2:	00000097          	auipc	ra,0x0
    800025d6:	e62080e7          	jalr	-414(ra) # 80002434 <sleep>
    havekids = 0;
    800025da:	b715                	j	800024fe <wait+0x4a>

00000000800025dc <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800025dc:	715d                	addi	sp,sp,-80
    800025de:	e486                	sd	ra,72(sp)
    800025e0:	e0a2                	sd	s0,64(sp)
    800025e2:	fc26                	sd	s1,56(sp)
    800025e4:	f84a                	sd	s2,48(sp)
    800025e6:	f44e                	sd	s3,40(sp)
    800025e8:	f052                	sd	s4,32(sp)
    800025ea:	ec56                	sd	s5,24(sp)
    800025ec:	e85a                	sd	s6,16(sp)
    800025ee:	e45e                	sd	s7,8(sp)
    800025f0:	0880                	addi	s0,sp,80
    800025f2:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800025f4:	00008497          	auipc	s1,0x8
    800025f8:	c6c48493          	addi	s1,s1,-916 # 8000a260 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800025fc:	4989                	li	s3,2
        p->state = RUNNABLE;
    800025fe:	4b8d                	li	s7,3
        p->last_runnable_time = ticks;
    80002600:	00007b17          	auipc	s6,0x7
    80002604:	a58b0b13          	addi	s6,s6,-1448 # 80009058 <ticks>
        // p->start_cpu_burst = ticks;
        p->sleeping_time += ticks - start_sleeping;
    80002608:	00007a97          	auipc	s5,0x7
    8000260c:	a30a8a93          	addi	s5,s5,-1488 # 80009038 <start_sleeping>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002610:	0000e917          	auipc	s2,0xe
    80002614:	e5090913          	addi	s2,s2,-432 # 80010460 <tickslock>
    80002618:	a805                	j	80002648 <wakeup+0x6c>
        p->state = RUNNABLE;
    8000261a:	0174ac23          	sw	s7,24(s1)
        p->last_runnable_time = ticks;
    8000261e:	000b2783          	lw	a5,0(s6)
    80002622:	16f4aa23          	sw	a5,372(s1)
        p->sleeping_time += ticks - start_sleeping;
    80002626:	000aa703          	lw	a4,0(s5)
    8000262a:	9f99                	subw	a5,a5,a4
    8000262c:	1784a703          	lw	a4,376(s1)
    80002630:	9fb9                	addw	a5,a5,a4
    80002632:	16f4ac23          	sw	a5,376(s1)
      }
      release(&p->lock);
    80002636:	8526                	mv	a0,s1
    80002638:	ffffe097          	auipc	ra,0xffffe
    8000263c:	660080e7          	jalr	1632(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002640:	18848493          	addi	s1,s1,392
    80002644:	03248463          	beq	s1,s2,8000266c <wakeup+0x90>
    if(p != myproc()){
    80002648:	fffff097          	auipc	ra,0xfffff
    8000264c:	380080e7          	jalr	896(ra) # 800019c8 <myproc>
    80002650:	fea488e3          	beq	s1,a0,80002640 <wakeup+0x64>
      acquire(&p->lock);
    80002654:	8526                	mv	a0,s1
    80002656:	ffffe097          	auipc	ra,0xffffe
    8000265a:	58e080e7          	jalr	1422(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000265e:	4c9c                	lw	a5,24(s1)
    80002660:	fd379be3          	bne	a5,s3,80002636 <wakeup+0x5a>
    80002664:	709c                	ld	a5,32(s1)
    80002666:	fd4798e3          	bne	a5,s4,80002636 <wakeup+0x5a>
    8000266a:	bf45                	j	8000261a <wakeup+0x3e>
    }
  }
}
    8000266c:	60a6                	ld	ra,72(sp)
    8000266e:	6406                	ld	s0,64(sp)
    80002670:	74e2                	ld	s1,56(sp)
    80002672:	7942                	ld	s2,48(sp)
    80002674:	79a2                	ld	s3,40(sp)
    80002676:	7a02                	ld	s4,32(sp)
    80002678:	6ae2                	ld	s5,24(sp)
    8000267a:	6b42                	ld	s6,16(sp)
    8000267c:	6ba2                	ld	s7,8(sp)
    8000267e:	6161                	addi	sp,sp,80
    80002680:	8082                	ret

0000000080002682 <reparent>:
{
    80002682:	7179                	addi	sp,sp,-48
    80002684:	f406                	sd	ra,40(sp)
    80002686:	f022                	sd	s0,32(sp)
    80002688:	ec26                	sd	s1,24(sp)
    8000268a:	e84a                	sd	s2,16(sp)
    8000268c:	e44e                	sd	s3,8(sp)
    8000268e:	e052                	sd	s4,0(sp)
    80002690:	1800                	addi	s0,sp,48
    80002692:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002694:	00008497          	auipc	s1,0x8
    80002698:	bcc48493          	addi	s1,s1,-1076 # 8000a260 <proc>
      pp->parent = initproc;
    8000269c:	00007a17          	auipc	s4,0x7
    800026a0:	9b4a0a13          	addi	s4,s4,-1612 # 80009050 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800026a4:	0000e997          	auipc	s3,0xe
    800026a8:	dbc98993          	addi	s3,s3,-580 # 80010460 <tickslock>
    800026ac:	a029                	j	800026b6 <reparent+0x34>
    800026ae:	18848493          	addi	s1,s1,392
    800026b2:	01348d63          	beq	s1,s3,800026cc <reparent+0x4a>
    if(pp->parent == p){
    800026b6:	7c9c                	ld	a5,56(s1)
    800026b8:	ff279be3          	bne	a5,s2,800026ae <reparent+0x2c>
      pp->parent = initproc;
    800026bc:	000a3503          	ld	a0,0(s4)
    800026c0:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800026c2:	00000097          	auipc	ra,0x0
    800026c6:	f1a080e7          	jalr	-230(ra) # 800025dc <wakeup>
    800026ca:	b7d5                	j	800026ae <reparent+0x2c>
}
    800026cc:	70a2                	ld	ra,40(sp)
    800026ce:	7402                	ld	s0,32(sp)
    800026d0:	64e2                	ld	s1,24(sp)
    800026d2:	6942                	ld	s2,16(sp)
    800026d4:	69a2                	ld	s3,8(sp)
    800026d6:	6a02                	ld	s4,0(sp)
    800026d8:	6145                	addi	sp,sp,48
    800026da:	8082                	ret

00000000800026dc <exit>:
{
    800026dc:	7179                	addi	sp,sp,-48
    800026de:	f406                	sd	ra,40(sp)
    800026e0:	f022                	sd	s0,32(sp)
    800026e2:	ec26                	sd	s1,24(sp)
    800026e4:	e84a                	sd	s2,16(sp)
    800026e6:	e44e                	sd	s3,8(sp)
    800026e8:	e052                	sd	s4,0(sp)
    800026ea:	1800                	addi	s0,sp,48
    800026ec:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800026ee:	fffff097          	auipc	ra,0xfffff
    800026f2:	2da080e7          	jalr	730(ra) # 800019c8 <myproc>
    800026f6:	892a                	mv	s2,a0
  if(p == initproc)
    800026f8:	00007797          	auipc	a5,0x7
    800026fc:	9587b783          	ld	a5,-1704(a5) # 80009050 <initproc>
    80002700:	0d050493          	addi	s1,a0,208
    80002704:	15050993          	addi	s3,a0,336
    80002708:	02a79363          	bne	a5,a0,8000272e <exit+0x52>
    panic("init exiting");
    8000270c:	00006517          	auipc	a0,0x6
    80002710:	b8c50513          	addi	a0,a0,-1140 # 80008298 <digits+0x258>
    80002714:	ffffe097          	auipc	ra,0xffffe
    80002718:	e2a080e7          	jalr	-470(ra) # 8000053e <panic>
      fileclose(f);
    8000271c:	00002097          	auipc	ra,0x2
    80002720:	432080e7          	jalr	1074(ra) # 80004b4e <fileclose>
      p->ofile[fd] = 0;
    80002724:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002728:	04a1                	addi	s1,s1,8
    8000272a:	01348563          	beq	s1,s3,80002734 <exit+0x58>
    if(p->ofile[fd]){
    8000272e:	6088                	ld	a0,0(s1)
    80002730:	f575                	bnez	a0,8000271c <exit+0x40>
    80002732:	bfdd                	j	80002728 <exit+0x4c>
  begin_op();
    80002734:	00002097          	auipc	ra,0x2
    80002738:	f4e080e7          	jalr	-178(ra) # 80004682 <begin_op>
  iput(p->cwd);
    8000273c:	15093503          	ld	a0,336(s2)
    80002740:	00001097          	auipc	ra,0x1
    80002744:	72a080e7          	jalr	1834(ra) # 80003e6a <iput>
  end_op();
    80002748:	00002097          	auipc	ra,0x2
    8000274c:	fba080e7          	jalr	-70(ra) # 80004702 <end_op>
  p->cwd = 0;
    80002750:	14093823          	sd	zero,336(s2)
  acquire(&wait_lock);
    80002754:	00008497          	auipc	s1,0x8
    80002758:	a7448493          	addi	s1,s1,-1420 # 8000a1c8 <wait_lock>
    8000275c:	8526                	mv	a0,s1
    8000275e:	ffffe097          	auipc	ra,0xffffe
    80002762:	486080e7          	jalr	1158(ra) # 80000be4 <acquire>
  reparent(p);
    80002766:	854a                	mv	a0,s2
    80002768:	00000097          	auipc	ra,0x0
    8000276c:	f1a080e7          	jalr	-230(ra) # 80002682 <reparent>
  wakeup(p->parent);
    80002770:	03893503          	ld	a0,56(s2)
    80002774:	00000097          	auipc	ra,0x0
    80002778:	e68080e7          	jalr	-408(ra) # 800025dc <wakeup>
  acquire(&p->lock);
    8000277c:	854a                	mv	a0,s2
    8000277e:	ffffe097          	auipc	ra,0xffffe
    80002782:	466080e7          	jalr	1126(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002786:	03492623          	sw	s4,44(s2)
  p->state = ZOMBIE;
    8000278a:	4795                	li	a5,5
    8000278c:	00f92c23          	sw	a5,24(s2)
  release(&wait_lock);
    80002790:	8526                	mv	a0,s1
    80002792:	ffffe097          	auipc	ra,0xffffe
    80002796:	506080e7          	jalr	1286(ra) # 80000c98 <release>
  num_processes++;
    8000279a:	00007717          	auipc	a4,0x7
    8000279e:	89a70713          	addi	a4,a4,-1894 # 80009034 <num_processes>
    800027a2:	431c                	lw	a5,0(a4)
    800027a4:	2785                	addiw	a5,a5,1
    800027a6:	c31c                	sw	a5,0(a4)
  p->running_time += (ticks - p->start_cpu_burst);
    800027a8:	00007617          	auipc	a2,0x7
    800027ac:	8b062603          	lw	a2,-1872(a2) # 80009058 <ticks>
    800027b0:	18092683          	lw	a3,384(s2)
    800027b4:	9eb1                	addw	a3,a3,a2
    800027b6:	17092703          	lw	a4,368(s2)
    800027ba:	9e99                	subw	a3,a3,a4
    800027bc:	18d92023          	sw	a3,384(s2)
  sleeping_processes_mean = ((sleeping_processes_mean * num_processes) + p->sleeping_time) / (num_processes);
    800027c0:	00007597          	auipc	a1,0x7
    800027c4:	88858593          	addi	a1,a1,-1912 # 80009048 <sleeping_processes_mean>
    800027c8:	4198                	lw	a4,0(a1)
    800027ca:	02f7073b          	mulw	a4,a4,a5
    800027ce:	17892503          	lw	a0,376(s2)
    800027d2:	9f29                	addw	a4,a4,a0
    800027d4:	02f7573b          	divuw	a4,a4,a5
    800027d8:	c198                	sw	a4,0(a1)
  running_processes_mean = (((running_processes_mean) * num_processes) + p->running_time) / (num_processes);
    800027da:	00007597          	auipc	a1,0x7
    800027de:	86a58593          	addi	a1,a1,-1942 # 80009044 <running_processes_mean>
    800027e2:	4198                	lw	a4,0(a1)
    800027e4:	02f7073b          	mulw	a4,a4,a5
    800027e8:	9f35                	addw	a4,a4,a3
    800027ea:	02f7573b          	divuw	a4,a4,a5
    800027ee:	c198                	sw	a4,0(a1)
  runnable_processes_mean = ((runnable_processes_mean * num_processes) + p->runnable_time) / (num_processes);
    800027f0:	00007597          	auipc	a1,0x7
    800027f4:	85058593          	addi	a1,a1,-1968 # 80009040 <runnable_processes_mean>
    800027f8:	4198                	lw	a4,0(a1)
    800027fa:	02f7073b          	mulw	a4,a4,a5
    800027fe:	17c92503          	lw	a0,380(s2)
    80002802:	9f29                	addw	a4,a4,a0
    80002804:	02f757bb          	divuw	a5,a4,a5
    80002808:	c19c                	sw	a5,0(a1)
  if(p->pid != 1 && p->pid != 2){
    8000280a:	03092783          	lw	a5,48(s2)
    8000280e:	37fd                	addiw	a5,a5,-1
    80002810:	4705                	li	a4,1
    80002812:	02f77863          	bgeu	a4,a5,80002842 <exit+0x166>
    program_time += p->running_time;
    80002816:	00007717          	auipc	a4,0x7
    8000281a:	81a70713          	addi	a4,a4,-2022 # 80009030 <program_time>
    8000281e:	431c                	lw	a5,0(a4)
    80002820:	9fb5                	addw	a5,a5,a3
    80002822:	c31c                	sw	a5,0(a4)
    cpu_utilization = (program_time * 100) / (ticks - start_time);
    80002824:	06400693          	li	a3,100
    80002828:	02f686bb          	mulw	a3,a3,a5
    8000282c:	00006797          	auipc	a5,0x6
    80002830:	7fc7a783          	lw	a5,2044(a5) # 80009028 <start_time>
    80002834:	9e1d                	subw	a2,a2,a5
    80002836:	02c6d63b          	divuw	a2,a3,a2
    8000283a:	00006797          	auipc	a5,0x6
    8000283e:	7ec7a923          	sw	a2,2034(a5) # 8000902c <cpu_utilization>
  sched();
    80002842:	00000097          	auipc	ra,0x0
    80002846:	ac4080e7          	jalr	-1340(ra) # 80002306 <sched>
  panic("zombie exit");
    8000284a:	00006517          	auipc	a0,0x6
    8000284e:	a5e50513          	addi	a0,a0,-1442 # 800082a8 <digits+0x268>
    80002852:	ffffe097          	auipc	ra,0xffffe
    80002856:	cec080e7          	jalr	-788(ra) # 8000053e <panic>

000000008000285a <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000285a:	7179                	addi	sp,sp,-48
    8000285c:	f406                	sd	ra,40(sp)
    8000285e:	f022                	sd	s0,32(sp)
    80002860:	ec26                	sd	s1,24(sp)
    80002862:	e84a                	sd	s2,16(sp)
    80002864:	e44e                	sd	s3,8(sp)
    80002866:	1800                	addi	s0,sp,48
    80002868:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000286a:	00008497          	auipc	s1,0x8
    8000286e:	9f648493          	addi	s1,s1,-1546 # 8000a260 <proc>
    80002872:	0000e997          	auipc	s3,0xe
    80002876:	bee98993          	addi	s3,s3,-1042 # 80010460 <tickslock>
    acquire(&p->lock);
    8000287a:	8526                	mv	a0,s1
    8000287c:	ffffe097          	auipc	ra,0xffffe
    80002880:	368080e7          	jalr	872(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002884:	589c                	lw	a5,48(s1)
    80002886:	01278d63          	beq	a5,s2,800028a0 <kill+0x46>
        p->sleeping_time +=  ticks - p->start_sleeping;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000288a:	8526                	mv	a0,s1
    8000288c:	ffffe097          	auipc	ra,0xffffe
    80002890:	40c080e7          	jalr	1036(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002894:	18848493          	addi	s1,s1,392
    80002898:	ff3491e3          	bne	s1,s3,8000287a <kill+0x20>
  }
  return -1;
    8000289c:	557d                	li	a0,-1
    8000289e:	a829                	j	800028b8 <kill+0x5e>
      p->killed = 1;
    800028a0:	4785                	li	a5,1
    800028a2:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800028a4:	4c98                	lw	a4,24(s1)
    800028a6:	4789                	li	a5,2
    800028a8:	00f70f63          	beq	a4,a5,800028c6 <kill+0x6c>
      release(&p->lock);
    800028ac:	8526                	mv	a0,s1
    800028ae:	ffffe097          	auipc	ra,0xffffe
    800028b2:	3ea080e7          	jalr	1002(ra) # 80000c98 <release>
      return 0;
    800028b6:	4501                	li	a0,0
}
    800028b8:	70a2                	ld	ra,40(sp)
    800028ba:	7402                	ld	s0,32(sp)
    800028bc:	64e2                	ld	s1,24(sp)
    800028be:	6942                	ld	s2,16(sp)
    800028c0:	69a2                	ld	s3,8(sp)
    800028c2:	6145                	addi	sp,sp,48
    800028c4:	8082                	ret
        p->state = RUNNABLE;
    800028c6:	478d                	li	a5,3
    800028c8:	cc9c                	sw	a5,24(s1)
        p->last_runnable_time = ticks;
    800028ca:	00006717          	auipc	a4,0x6
    800028ce:	78e72703          	lw	a4,1934(a4) # 80009058 <ticks>
    800028d2:	16e4aa23          	sw	a4,372(s1)
        p->sleeping_time +=  ticks - p->start_sleeping;
    800028d6:	1784a783          	lw	a5,376(s1)
    800028da:	9fb9                	addw	a5,a5,a4
    800028dc:	1844a703          	lw	a4,388(s1)
    800028e0:	9f99                	subw	a5,a5,a4
    800028e2:	16f4ac23          	sw	a5,376(s1)
    800028e6:	b7d9                	j	800028ac <kill+0x52>

00000000800028e8 <kill_system>:

int
kill_system()
{
    800028e8:	711d                	addi	sp,sp,-96
    800028ea:	ec86                	sd	ra,88(sp)
    800028ec:	e8a2                	sd	s0,80(sp)
    800028ee:	e4a6                	sd	s1,72(sp)
    800028f0:	e0ca                	sd	s2,64(sp)
    800028f2:	fc4e                	sd	s3,56(sp)
    800028f4:	f852                	sd	s4,48(sp)
    800028f6:	f456                	sd	s5,40(sp)
    800028f8:	f05a                	sd	s6,32(sp)
    800028fa:	ec5e                	sd	s7,24(sp)
    800028fc:	e862                	sd	s8,16(sp)
    800028fe:	e466                	sd	s9,8(sp)
    80002900:	1080                	addi	s0,sp,96
  struct proc *myp = myproc();
    80002902:	fffff097          	auipc	ra,0xfffff
    80002906:	0c6080e7          	jalr	198(ra) # 800019c8 <myproc>
    8000290a:	8caa                	mv	s9,a0
  int mypid = myp->pid;
    8000290c:	03052983          	lw	s3,48(a0)
  acquire(&myp->lock);
    80002910:	ffffe097          	auipc	ra,0xffffe
    80002914:	2d4080e7          	jalr	724(ra) # 80000be4 <acquire>
  struct proc *p;

  for(p = proc;p < &proc[NPROC]; p++){
    80002918:	00008497          	auipc	s1,0x8
    8000291c:	94848493          	addi	s1,s1,-1720 # 8000a260 <proc>
    if(p->pid != mypid){
      acquire(&p->lock);
      if(p->pid != 1 && p->pid != 2){
    80002920:	4a05                	li	s4,1
        p->killed = 1;
    80002922:	4b05                	li	s6,1
        if(p->state == SLEEPING){
    80002924:	4a89                	li	s5,2
          // Wake process from sleep().
          p->state = RUNNABLE;
    80002926:	4c0d                	li	s8,3
          p->last_runnable_time = ticks;
    80002928:	00006b97          	auipc	s7,0x6
    8000292c:	730b8b93          	addi	s7,s7,1840 # 80009058 <ticks>
  for(p = proc;p < &proc[NPROC]; p++){
    80002930:	0000e917          	auipc	s2,0xe
    80002934:	b3090913          	addi	s2,s2,-1232 # 80010460 <tickslock>
    80002938:	a811                	j	8000294c <kill_system+0x64>
          p->sleeping_time +=  ticks - p->start_sleeping;
        }
      }
      release(&p->lock);
    8000293a:	8526                	mv	a0,s1
    8000293c:	ffffe097          	auipc	ra,0xffffe
    80002940:	35c080e7          	jalr	860(ra) # 80000c98 <release>
  for(p = proc;p < &proc[NPROC]; p++){
    80002944:	18848493          	addi	s1,s1,392
    80002948:	05248263          	beq	s1,s2,8000298c <kill_system+0xa4>
    if(p->pid != mypid){
    8000294c:	589c                	lw	a5,48(s1)
    8000294e:	ff378be3          	beq	a5,s3,80002944 <kill_system+0x5c>
      acquire(&p->lock);
    80002952:	8526                	mv	a0,s1
    80002954:	ffffe097          	auipc	ra,0xffffe
    80002958:	290080e7          	jalr	656(ra) # 80000be4 <acquire>
      if(p->pid != 1 && p->pid != 2){
    8000295c:	589c                	lw	a5,48(s1)
    8000295e:	37fd                	addiw	a5,a5,-1
    80002960:	fcfa7de3          	bgeu	s4,a5,8000293a <kill_system+0x52>
        p->killed = 1;
    80002964:	0364a423          	sw	s6,40(s1)
        if(p->state == SLEEPING){
    80002968:	4c9c                	lw	a5,24(s1)
    8000296a:	fd5798e3          	bne	a5,s5,8000293a <kill_system+0x52>
          p->state = RUNNABLE;
    8000296e:	0184ac23          	sw	s8,24(s1)
          p->last_runnable_time = ticks;
    80002972:	000ba703          	lw	a4,0(s7)
    80002976:	16e4aa23          	sw	a4,372(s1)
          p->sleeping_time +=  ticks - p->start_sleeping;
    8000297a:	1784a783          	lw	a5,376(s1)
    8000297e:	9fb9                	addw	a5,a5,a4
    80002980:	1844a703          	lw	a4,388(s1)
    80002984:	9f99                	subw	a5,a5,a4
    80002986:	16f4ac23          	sw	a5,376(s1)
    8000298a:	bf45                	j	8000293a <kill_system+0x52>
    }
  }

  myp->killed = 1;
    8000298c:	4785                	li	a5,1
    8000298e:	02fca423          	sw	a5,40(s9)
  release(&myp->lock);
    80002992:	8566                	mv	a0,s9
    80002994:	ffffe097          	auipc	ra,0xffffe
    80002998:	304080e7          	jalr	772(ra) # 80000c98 <release>
  return 0;
}
    8000299c:	4501                	li	a0,0
    8000299e:	60e6                	ld	ra,88(sp)
    800029a0:	6446                	ld	s0,80(sp)
    800029a2:	64a6                	ld	s1,72(sp)
    800029a4:	6906                	ld	s2,64(sp)
    800029a6:	79e2                	ld	s3,56(sp)
    800029a8:	7a42                	ld	s4,48(sp)
    800029aa:	7aa2                	ld	s5,40(sp)
    800029ac:	7b02                	ld	s6,32(sp)
    800029ae:	6be2                	ld	s7,24(sp)
    800029b0:	6c42                	ld	s8,16(sp)
    800029b2:	6ca2                	ld	s9,8(sp)
    800029b4:	6125                	addi	sp,sp,96
    800029b6:	8082                	ret

00000000800029b8 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800029b8:	7179                	addi	sp,sp,-48
    800029ba:	f406                	sd	ra,40(sp)
    800029bc:	f022                	sd	s0,32(sp)
    800029be:	ec26                	sd	s1,24(sp)
    800029c0:	e84a                	sd	s2,16(sp)
    800029c2:	e44e                	sd	s3,8(sp)
    800029c4:	e052                	sd	s4,0(sp)
    800029c6:	1800                	addi	s0,sp,48
    800029c8:	84aa                	mv	s1,a0
    800029ca:	892e                	mv	s2,a1
    800029cc:	89b2                	mv	s3,a2
    800029ce:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800029d0:	fffff097          	auipc	ra,0xfffff
    800029d4:	ff8080e7          	jalr	-8(ra) # 800019c8 <myproc>
  if(user_dst){
    800029d8:	c08d                	beqz	s1,800029fa <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800029da:	86d2                	mv	a3,s4
    800029dc:	864e                	mv	a2,s3
    800029de:	85ca                	mv	a1,s2
    800029e0:	6928                	ld	a0,80(a0)
    800029e2:	fffff097          	auipc	ra,0xfffff
    800029e6:	c98080e7          	jalr	-872(ra) # 8000167a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800029ea:	70a2                	ld	ra,40(sp)
    800029ec:	7402                	ld	s0,32(sp)
    800029ee:	64e2                	ld	s1,24(sp)
    800029f0:	6942                	ld	s2,16(sp)
    800029f2:	69a2                	ld	s3,8(sp)
    800029f4:	6a02                	ld	s4,0(sp)
    800029f6:	6145                	addi	sp,sp,48
    800029f8:	8082                	ret
    memmove((char *)dst, src, len);
    800029fa:	000a061b          	sext.w	a2,s4
    800029fe:	85ce                	mv	a1,s3
    80002a00:	854a                	mv	a0,s2
    80002a02:	ffffe097          	auipc	ra,0xffffe
    80002a06:	33e080e7          	jalr	830(ra) # 80000d40 <memmove>
    return 0;
    80002a0a:	8526                	mv	a0,s1
    80002a0c:	bff9                	j	800029ea <either_copyout+0x32>

0000000080002a0e <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002a0e:	7179                	addi	sp,sp,-48
    80002a10:	f406                	sd	ra,40(sp)
    80002a12:	f022                	sd	s0,32(sp)
    80002a14:	ec26                	sd	s1,24(sp)
    80002a16:	e84a                	sd	s2,16(sp)
    80002a18:	e44e                	sd	s3,8(sp)
    80002a1a:	e052                	sd	s4,0(sp)
    80002a1c:	1800                	addi	s0,sp,48
    80002a1e:	892a                	mv	s2,a0
    80002a20:	84ae                	mv	s1,a1
    80002a22:	89b2                	mv	s3,a2
    80002a24:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a26:	fffff097          	auipc	ra,0xfffff
    80002a2a:	fa2080e7          	jalr	-94(ra) # 800019c8 <myproc>
  if(user_src){
    80002a2e:	c08d                	beqz	s1,80002a50 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002a30:	86d2                	mv	a3,s4
    80002a32:	864e                	mv	a2,s3
    80002a34:	85ca                	mv	a1,s2
    80002a36:	6928                	ld	a0,80(a0)
    80002a38:	fffff097          	auipc	ra,0xfffff
    80002a3c:	cce080e7          	jalr	-818(ra) # 80001706 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002a40:	70a2                	ld	ra,40(sp)
    80002a42:	7402                	ld	s0,32(sp)
    80002a44:	64e2                	ld	s1,24(sp)
    80002a46:	6942                	ld	s2,16(sp)
    80002a48:	69a2                	ld	s3,8(sp)
    80002a4a:	6a02                	ld	s4,0(sp)
    80002a4c:	6145                	addi	sp,sp,48
    80002a4e:	8082                	ret
    memmove(dst, (char*)src, len);
    80002a50:	000a061b          	sext.w	a2,s4
    80002a54:	85ce                	mv	a1,s3
    80002a56:	854a                	mv	a0,s2
    80002a58:	ffffe097          	auipc	ra,0xffffe
    80002a5c:	2e8080e7          	jalr	744(ra) # 80000d40 <memmove>
    return 0;
    80002a60:	8526                	mv	a0,s1
    80002a62:	bff9                	j	80002a40 <either_copyin+0x32>

0000000080002a64 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002a64:	715d                	addi	sp,sp,-80
    80002a66:	e486                	sd	ra,72(sp)
    80002a68:	e0a2                	sd	s0,64(sp)
    80002a6a:	fc26                	sd	s1,56(sp)
    80002a6c:	f84a                	sd	s2,48(sp)
    80002a6e:	f44e                	sd	s3,40(sp)
    80002a70:	f052                	sd	s4,32(sp)
    80002a72:	ec56                	sd	s5,24(sp)
    80002a74:	e85a                	sd	s6,16(sp)
    80002a76:	e45e                	sd	s7,8(sp)
    80002a78:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002a7a:	00006517          	auipc	a0,0x6
    80002a7e:	8e650513          	addi	a0,a0,-1818 # 80008360 <digits+0x320>
    80002a82:	ffffe097          	auipc	ra,0xffffe
    80002a86:	b06080e7          	jalr	-1274(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a8a:	00008497          	auipc	s1,0x8
    80002a8e:	92e48493          	addi	s1,s1,-1746 # 8000a3b8 <proc+0x158>
    80002a92:	0000e917          	auipc	s2,0xe
    80002a96:	b2690913          	addi	s2,s2,-1242 # 800105b8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a9a:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002a9c:	00006997          	auipc	s3,0x6
    80002aa0:	81c98993          	addi	s3,s3,-2020 # 800082b8 <digits+0x278>
    printf("%d %s %s", p->pid, state, p->name);
    80002aa4:	00006a97          	auipc	s5,0x6
    80002aa8:	81ca8a93          	addi	s5,s5,-2020 # 800082c0 <digits+0x280>
    printf("\n");
    80002aac:	00006a17          	auipc	s4,0x6
    80002ab0:	8b4a0a13          	addi	s4,s4,-1868 # 80008360 <digits+0x320>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ab4:	00006b97          	auipc	s7,0x6
    80002ab8:	8dcb8b93          	addi	s7,s7,-1828 # 80008390 <states.1871>
    80002abc:	a00d                	j	80002ade <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002abe:	ed86a583          	lw	a1,-296(a3)
    80002ac2:	8556                	mv	a0,s5
    80002ac4:	ffffe097          	auipc	ra,0xffffe
    80002ac8:	ac4080e7          	jalr	-1340(ra) # 80000588 <printf>
    printf("\n");
    80002acc:	8552                	mv	a0,s4
    80002ace:	ffffe097          	auipc	ra,0xffffe
    80002ad2:	aba080e7          	jalr	-1350(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002ad6:	18848493          	addi	s1,s1,392
    80002ada:	03248163          	beq	s1,s2,80002afc <procdump+0x98>
    if(p->state == UNUSED)
    80002ade:	86a6                	mv	a3,s1
    80002ae0:	ec04a783          	lw	a5,-320(s1)
    80002ae4:	dbed                	beqz	a5,80002ad6 <procdump+0x72>
      state = "???";
    80002ae6:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ae8:	fcfb6be3          	bltu	s6,a5,80002abe <procdump+0x5a>
    80002aec:	1782                	slli	a5,a5,0x20
    80002aee:	9381                	srli	a5,a5,0x20
    80002af0:	078e                	slli	a5,a5,0x3
    80002af2:	97de                	add	a5,a5,s7
    80002af4:	6390                	ld	a2,0(a5)
    80002af6:	f661                	bnez	a2,80002abe <procdump+0x5a>
      state = "???";
    80002af8:	864e                	mv	a2,s3
    80002afa:	b7d1                	j	80002abe <procdump+0x5a>
  }
}
    80002afc:	60a6                	ld	ra,72(sp)
    80002afe:	6406                	ld	s0,64(sp)
    80002b00:	74e2                	ld	s1,56(sp)
    80002b02:	7942                	ld	s2,48(sp)
    80002b04:	79a2                	ld	s3,40(sp)
    80002b06:	7a02                	ld	s4,32(sp)
    80002b08:	6ae2                	ld	s5,24(sp)
    80002b0a:	6b42                	ld	s6,16(sp)
    80002b0c:	6ba2                	ld	s7,8(sp)
    80002b0e:	6161                	addi	sp,sp,80
    80002b10:	8082                	ret

0000000080002b12 <pause_system>:

int
pause_system(int seconds)
{
    80002b12:	1141                	addi	sp,sp,-16
    80002b14:	e406                	sd	ra,8(sp)
    80002b16:	e022                	sd	s0,0(sp)
    80002b18:	0800                	addi	s0,sp,16
  pause_time = ticks + seconds*10;  
    80002b1a:	0025179b          	slliw	a5,a0,0x2
    80002b1e:	9fa9                	addw	a5,a5,a0
    80002b20:	0017979b          	slliw	a5,a5,0x1
    80002b24:	00006517          	auipc	a0,0x6
    80002b28:	53452503          	lw	a0,1332(a0) # 80009058 <ticks>
    80002b2c:	9fa9                	addw	a5,a5,a0
    80002b2e:	00006717          	auipc	a4,0x6
    80002b32:	50f72f23          	sw	a5,1310(a4) # 8000904c <pause_time>
  yield();
    80002b36:	00000097          	auipc	ra,0x0
    80002b3a:	8a6080e7          	jalr	-1882(ra) # 800023dc <yield>
  return 0;
}
    80002b3e:	4501                	li	a0,0
    80002b40:	60a2                	ld	ra,8(sp)
    80002b42:	6402                	ld	s0,0(sp)
    80002b44:	0141                	addi	sp,sp,16
    80002b46:	8082                	ret

0000000080002b48 <print_stats>:

void
print_stats(void){
    80002b48:	1141                	addi	sp,sp,-16
    80002b4a:	e406                	sd	ra,8(sp)
    80002b4c:	e022                	sd	s0,0(sp)
    80002b4e:	0800                	addi	s0,sp,16
    printf("Mean running time: %d\n", running_processes_mean);
    80002b50:	00006597          	auipc	a1,0x6
    80002b54:	4f45a583          	lw	a1,1268(a1) # 80009044 <running_processes_mean>
    80002b58:	00005517          	auipc	a0,0x5
    80002b5c:	77850513          	addi	a0,a0,1912 # 800082d0 <digits+0x290>
    80002b60:	ffffe097          	auipc	ra,0xffffe
    80002b64:	a28080e7          	jalr	-1496(ra) # 80000588 <printf>
    printf("Number of processes: %d\n", num_processes);
    80002b68:	00006597          	auipc	a1,0x6
    80002b6c:	4cc5a583          	lw	a1,1228(a1) # 80009034 <num_processes>
    80002b70:	00005517          	auipc	a0,0x5
    80002b74:	77850513          	addi	a0,a0,1912 # 800082e8 <digits+0x2a8>
    80002b78:	ffffe097          	auipc	ra,0xffffe
    80002b7c:	a10080e7          	jalr	-1520(ra) # 80000588 <printf>
    printf("Mean runnable time: %d\n", runnable_processes_mean);
    80002b80:	00006597          	auipc	a1,0x6
    80002b84:	4c05a583          	lw	a1,1216(a1) # 80009040 <runnable_processes_mean>
    80002b88:	00005517          	auipc	a0,0x5
    80002b8c:	78050513          	addi	a0,a0,1920 # 80008308 <digits+0x2c8>
    80002b90:	ffffe097          	auipc	ra,0xffffe
    80002b94:	9f8080e7          	jalr	-1544(ra) # 80000588 <printf>
    printf("Mean sleeping time: %d\n", sleeping_processes_mean);
    80002b98:	00006597          	auipc	a1,0x6
    80002b9c:	4b05a583          	lw	a1,1200(a1) # 80009048 <sleeping_processes_mean>
    80002ba0:	00005517          	auipc	a0,0x5
    80002ba4:	78050513          	addi	a0,a0,1920 # 80008320 <digits+0x2e0>
    80002ba8:	ffffe097          	auipc	ra,0xffffe
    80002bac:	9e0080e7          	jalr	-1568(ra) # 80000588 <printf>
    printf("CPU utilization: %d\n", cpu_utilization);
    80002bb0:	00006597          	auipc	a1,0x6
    80002bb4:	47c5a583          	lw	a1,1148(a1) # 8000902c <cpu_utilization>
    80002bb8:	00005517          	auipc	a0,0x5
    80002bbc:	78050513          	addi	a0,a0,1920 # 80008338 <digits+0x2f8>
    80002bc0:	ffffe097          	auipc	ra,0xffffe
    80002bc4:	9c8080e7          	jalr	-1592(ra) # 80000588 <printf>
    printf("Program time: %d\n", program_time);
    80002bc8:	00006597          	auipc	a1,0x6
    80002bcc:	4685a583          	lw	a1,1128(a1) # 80009030 <program_time>
    80002bd0:	00005517          	auipc	a0,0x5
    80002bd4:	78050513          	addi	a0,a0,1920 # 80008350 <digits+0x310>
    80002bd8:	ffffe097          	auipc	ra,0xffffe
    80002bdc:	9b0080e7          	jalr	-1616(ra) # 80000588 <printf>
}
    80002be0:	60a2                	ld	ra,8(sp)
    80002be2:	6402                	ld	s0,0(sp)
    80002be4:	0141                	addi	sp,sp,16
    80002be6:	8082                	ret

0000000080002be8 <swtch>:
    80002be8:	00153023          	sd	ra,0(a0)
    80002bec:	00253423          	sd	sp,8(a0)
    80002bf0:	e900                	sd	s0,16(a0)
    80002bf2:	ed04                	sd	s1,24(a0)
    80002bf4:	03253023          	sd	s2,32(a0)
    80002bf8:	03353423          	sd	s3,40(a0)
    80002bfc:	03453823          	sd	s4,48(a0)
    80002c00:	03553c23          	sd	s5,56(a0)
    80002c04:	05653023          	sd	s6,64(a0)
    80002c08:	05753423          	sd	s7,72(a0)
    80002c0c:	05853823          	sd	s8,80(a0)
    80002c10:	05953c23          	sd	s9,88(a0)
    80002c14:	07a53023          	sd	s10,96(a0)
    80002c18:	07b53423          	sd	s11,104(a0)
    80002c1c:	0005b083          	ld	ra,0(a1)
    80002c20:	0085b103          	ld	sp,8(a1)
    80002c24:	6980                	ld	s0,16(a1)
    80002c26:	6d84                	ld	s1,24(a1)
    80002c28:	0205b903          	ld	s2,32(a1)
    80002c2c:	0285b983          	ld	s3,40(a1)
    80002c30:	0305ba03          	ld	s4,48(a1)
    80002c34:	0385ba83          	ld	s5,56(a1)
    80002c38:	0405bb03          	ld	s6,64(a1)
    80002c3c:	0485bb83          	ld	s7,72(a1)
    80002c40:	0505bc03          	ld	s8,80(a1)
    80002c44:	0585bc83          	ld	s9,88(a1)
    80002c48:	0605bd03          	ld	s10,96(a1)
    80002c4c:	0685bd83          	ld	s11,104(a1)
    80002c50:	8082                	ret

0000000080002c52 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002c52:	1141                	addi	sp,sp,-16
    80002c54:	e406                	sd	ra,8(sp)
    80002c56:	e022                	sd	s0,0(sp)
    80002c58:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002c5a:	00005597          	auipc	a1,0x5
    80002c5e:	76658593          	addi	a1,a1,1894 # 800083c0 <states.1871+0x30>
    80002c62:	0000d517          	auipc	a0,0xd
    80002c66:	7fe50513          	addi	a0,a0,2046 # 80010460 <tickslock>
    80002c6a:	ffffe097          	auipc	ra,0xffffe
    80002c6e:	eea080e7          	jalr	-278(ra) # 80000b54 <initlock>
}
    80002c72:	60a2                	ld	ra,8(sp)
    80002c74:	6402                	ld	s0,0(sp)
    80002c76:	0141                	addi	sp,sp,16
    80002c78:	8082                	ret

0000000080002c7a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002c7a:	1141                	addi	sp,sp,-16
    80002c7c:	e422                	sd	s0,8(sp)
    80002c7e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c80:	00003797          	auipc	a5,0x3
    80002c84:	4f078793          	addi	a5,a5,1264 # 80006170 <kernelvec>
    80002c88:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002c8c:	6422                	ld	s0,8(sp)
    80002c8e:	0141                	addi	sp,sp,16
    80002c90:	8082                	ret

0000000080002c92 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002c92:	1141                	addi	sp,sp,-16
    80002c94:	e406                	sd	ra,8(sp)
    80002c96:	e022                	sd	s0,0(sp)
    80002c98:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002c9a:	fffff097          	auipc	ra,0xfffff
    80002c9e:	d2e080e7          	jalr	-722(ra) # 800019c8 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ca2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002ca6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ca8:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002cac:	00004617          	auipc	a2,0x4
    80002cb0:	35460613          	addi	a2,a2,852 # 80007000 <_trampoline>
    80002cb4:	00004697          	auipc	a3,0x4
    80002cb8:	34c68693          	addi	a3,a3,844 # 80007000 <_trampoline>
    80002cbc:	8e91                	sub	a3,a3,a2
    80002cbe:	040007b7          	lui	a5,0x4000
    80002cc2:	17fd                	addi	a5,a5,-1
    80002cc4:	07b2                	slli	a5,a5,0xc
    80002cc6:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cc8:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002ccc:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002cce:	180026f3          	csrr	a3,satp
    80002cd2:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002cd4:	6d38                	ld	a4,88(a0)
    80002cd6:	6134                	ld	a3,64(a0)
    80002cd8:	6585                	lui	a1,0x1
    80002cda:	96ae                	add	a3,a3,a1
    80002cdc:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002cde:	6d38                	ld	a4,88(a0)
    80002ce0:	00000697          	auipc	a3,0x0
    80002ce4:	13868693          	addi	a3,a3,312 # 80002e18 <usertrap>
    80002ce8:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002cea:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002cec:	8692                	mv	a3,tp
    80002cee:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cf0:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002cf4:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002cf8:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cfc:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002d00:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d02:	6f18                	ld	a4,24(a4)
    80002d04:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002d08:	692c                	ld	a1,80(a0)
    80002d0a:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002d0c:	00004717          	auipc	a4,0x4
    80002d10:	38470713          	addi	a4,a4,900 # 80007090 <userret>
    80002d14:	8f11                	sub	a4,a4,a2
    80002d16:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002d18:	577d                	li	a4,-1
    80002d1a:	177e                	slli	a4,a4,0x3f
    80002d1c:	8dd9                	or	a1,a1,a4
    80002d1e:	02000537          	lui	a0,0x2000
    80002d22:	157d                	addi	a0,a0,-1
    80002d24:	0536                	slli	a0,a0,0xd
    80002d26:	9782                	jalr	a5
}
    80002d28:	60a2                	ld	ra,8(sp)
    80002d2a:	6402                	ld	s0,0(sp)
    80002d2c:	0141                	addi	sp,sp,16
    80002d2e:	8082                	ret

0000000080002d30 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002d30:	1101                	addi	sp,sp,-32
    80002d32:	ec06                	sd	ra,24(sp)
    80002d34:	e822                	sd	s0,16(sp)
    80002d36:	e426                	sd	s1,8(sp)
    80002d38:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002d3a:	0000d497          	auipc	s1,0xd
    80002d3e:	72648493          	addi	s1,s1,1830 # 80010460 <tickslock>
    80002d42:	8526                	mv	a0,s1
    80002d44:	ffffe097          	auipc	ra,0xffffe
    80002d48:	ea0080e7          	jalr	-352(ra) # 80000be4 <acquire>
  ticks++;
    80002d4c:	00006517          	auipc	a0,0x6
    80002d50:	30c50513          	addi	a0,a0,780 # 80009058 <ticks>
    80002d54:	411c                	lw	a5,0(a0)
    80002d56:	2785                	addiw	a5,a5,1
    80002d58:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002d5a:	00000097          	auipc	ra,0x0
    80002d5e:	882080e7          	jalr	-1918(ra) # 800025dc <wakeup>
  release(&tickslock);
    80002d62:	8526                	mv	a0,s1
    80002d64:	ffffe097          	auipc	ra,0xffffe
    80002d68:	f34080e7          	jalr	-204(ra) # 80000c98 <release>
}
    80002d6c:	60e2                	ld	ra,24(sp)
    80002d6e:	6442                	ld	s0,16(sp)
    80002d70:	64a2                	ld	s1,8(sp)
    80002d72:	6105                	addi	sp,sp,32
    80002d74:	8082                	ret

0000000080002d76 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002d76:	1101                	addi	sp,sp,-32
    80002d78:	ec06                	sd	ra,24(sp)
    80002d7a:	e822                	sd	s0,16(sp)
    80002d7c:	e426                	sd	s1,8(sp)
    80002d7e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d80:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002d84:	00074d63          	bltz	a4,80002d9e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002d88:	57fd                	li	a5,-1
    80002d8a:	17fe                	slli	a5,a5,0x3f
    80002d8c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002d8e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002d90:	06f70363          	beq	a4,a5,80002df6 <devintr+0x80>
  }
}
    80002d94:	60e2                	ld	ra,24(sp)
    80002d96:	6442                	ld	s0,16(sp)
    80002d98:	64a2                	ld	s1,8(sp)
    80002d9a:	6105                	addi	sp,sp,32
    80002d9c:	8082                	ret
     (scause & 0xff) == 9){
    80002d9e:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002da2:	46a5                	li	a3,9
    80002da4:	fed792e3          	bne	a5,a3,80002d88 <devintr+0x12>
    int irq = plic_claim();
    80002da8:	00003097          	auipc	ra,0x3
    80002dac:	4d0080e7          	jalr	1232(ra) # 80006278 <plic_claim>
    80002db0:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002db2:	47a9                	li	a5,10
    80002db4:	02f50763          	beq	a0,a5,80002de2 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002db8:	4785                	li	a5,1
    80002dba:	02f50963          	beq	a0,a5,80002dec <devintr+0x76>
    return 1;
    80002dbe:	4505                	li	a0,1
    } else if(irq){
    80002dc0:	d8f1                	beqz	s1,80002d94 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002dc2:	85a6                	mv	a1,s1
    80002dc4:	00005517          	auipc	a0,0x5
    80002dc8:	60450513          	addi	a0,a0,1540 # 800083c8 <states.1871+0x38>
    80002dcc:	ffffd097          	auipc	ra,0xffffd
    80002dd0:	7bc080e7          	jalr	1980(ra) # 80000588 <printf>
      plic_complete(irq);
    80002dd4:	8526                	mv	a0,s1
    80002dd6:	00003097          	auipc	ra,0x3
    80002dda:	4c6080e7          	jalr	1222(ra) # 8000629c <plic_complete>
    return 1;
    80002dde:	4505                	li	a0,1
    80002de0:	bf55                	j	80002d94 <devintr+0x1e>
      uartintr();
    80002de2:	ffffe097          	auipc	ra,0xffffe
    80002de6:	bc6080e7          	jalr	-1082(ra) # 800009a8 <uartintr>
    80002dea:	b7ed                	j	80002dd4 <devintr+0x5e>
      virtio_disk_intr();
    80002dec:	00004097          	auipc	ra,0x4
    80002df0:	990080e7          	jalr	-1648(ra) # 8000677c <virtio_disk_intr>
    80002df4:	b7c5                	j	80002dd4 <devintr+0x5e>
    if(cpuid() == 0){
    80002df6:	fffff097          	auipc	ra,0xfffff
    80002dfa:	ba6080e7          	jalr	-1114(ra) # 8000199c <cpuid>
    80002dfe:	c901                	beqz	a0,80002e0e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002e00:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002e04:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002e06:	14479073          	csrw	sip,a5
    return 2;
    80002e0a:	4509                	li	a0,2
    80002e0c:	b761                	j	80002d94 <devintr+0x1e>
      clockintr();
    80002e0e:	00000097          	auipc	ra,0x0
    80002e12:	f22080e7          	jalr	-222(ra) # 80002d30 <clockintr>
    80002e16:	b7ed                	j	80002e00 <devintr+0x8a>

0000000080002e18 <usertrap>:
{
    80002e18:	1101                	addi	sp,sp,-32
    80002e1a:	ec06                	sd	ra,24(sp)
    80002e1c:	e822                	sd	s0,16(sp)
    80002e1e:	e426                	sd	s1,8(sp)
    80002e20:	e04a                	sd	s2,0(sp)
    80002e22:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e24:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002e28:	1007f793          	andi	a5,a5,256
    80002e2c:	e3ad                	bnez	a5,80002e8e <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e2e:	00003797          	auipc	a5,0x3
    80002e32:	34278793          	addi	a5,a5,834 # 80006170 <kernelvec>
    80002e36:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002e3a:	fffff097          	auipc	ra,0xfffff
    80002e3e:	b8e080e7          	jalr	-1138(ra) # 800019c8 <myproc>
    80002e42:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002e44:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e46:	14102773          	csrr	a4,sepc
    80002e4a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e4c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002e50:	47a1                	li	a5,8
    80002e52:	04f71c63          	bne	a4,a5,80002eaa <usertrap+0x92>
    if(p->killed)
    80002e56:	551c                	lw	a5,40(a0)
    80002e58:	e3b9                	bnez	a5,80002e9e <usertrap+0x86>
    p->trapframe->epc += 4;
    80002e5a:	6cb8                	ld	a4,88(s1)
    80002e5c:	6f1c                	ld	a5,24(a4)
    80002e5e:	0791                	addi	a5,a5,4
    80002e60:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e62:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002e66:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e6a:	10079073          	csrw	sstatus,a5
    syscall();
    80002e6e:	00000097          	auipc	ra,0x0
    80002e72:	2e0080e7          	jalr	736(ra) # 8000314e <syscall>
  if(p->killed)
    80002e76:	549c                	lw	a5,40(s1)
    80002e78:	ebc1                	bnez	a5,80002f08 <usertrap+0xf0>
  usertrapret();
    80002e7a:	00000097          	auipc	ra,0x0
    80002e7e:	e18080e7          	jalr	-488(ra) # 80002c92 <usertrapret>
}
    80002e82:	60e2                	ld	ra,24(sp)
    80002e84:	6442                	ld	s0,16(sp)
    80002e86:	64a2                	ld	s1,8(sp)
    80002e88:	6902                	ld	s2,0(sp)
    80002e8a:	6105                	addi	sp,sp,32
    80002e8c:	8082                	ret
    panic("usertrap: not from user mode");
    80002e8e:	00005517          	auipc	a0,0x5
    80002e92:	55a50513          	addi	a0,a0,1370 # 800083e8 <states.1871+0x58>
    80002e96:	ffffd097          	auipc	ra,0xffffd
    80002e9a:	6a8080e7          	jalr	1704(ra) # 8000053e <panic>
      exit(-1);
    80002e9e:	557d                	li	a0,-1
    80002ea0:	00000097          	auipc	ra,0x0
    80002ea4:	83c080e7          	jalr	-1988(ra) # 800026dc <exit>
    80002ea8:	bf4d                	j	80002e5a <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002eaa:	00000097          	auipc	ra,0x0
    80002eae:	ecc080e7          	jalr	-308(ra) # 80002d76 <devintr>
    80002eb2:	892a                	mv	s2,a0
    80002eb4:	c501                	beqz	a0,80002ebc <usertrap+0xa4>
  if(p->killed)
    80002eb6:	549c                	lw	a5,40(s1)
    80002eb8:	c3a1                	beqz	a5,80002ef8 <usertrap+0xe0>
    80002eba:	a815                	j	80002eee <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ebc:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002ec0:	5890                	lw	a2,48(s1)
    80002ec2:	00005517          	auipc	a0,0x5
    80002ec6:	54650513          	addi	a0,a0,1350 # 80008408 <states.1871+0x78>
    80002eca:	ffffd097          	auipc	ra,0xffffd
    80002ece:	6be080e7          	jalr	1726(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ed2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ed6:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002eda:	00005517          	auipc	a0,0x5
    80002ede:	55e50513          	addi	a0,a0,1374 # 80008438 <states.1871+0xa8>
    80002ee2:	ffffd097          	auipc	ra,0xffffd
    80002ee6:	6a6080e7          	jalr	1702(ra) # 80000588 <printf>
    p->killed = 1;
    80002eea:	4785                	li	a5,1
    80002eec:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002eee:	557d                	li	a0,-1
    80002ef0:	fffff097          	auipc	ra,0xfffff
    80002ef4:	7ec080e7          	jalr	2028(ra) # 800026dc <exit>
  if(which_dev == 2){
    80002ef8:	4789                	li	a5,2
    80002efa:	f8f910e3          	bne	s2,a5,80002e7a <usertrap+0x62>
       yield();
    80002efe:	fffff097          	auipc	ra,0xfffff
    80002f02:	4de080e7          	jalr	1246(ra) # 800023dc <yield>
    80002f06:	bf95                	j	80002e7a <usertrap+0x62>
  int which_dev = 0;
    80002f08:	4901                	li	s2,0
    80002f0a:	b7d5                	j	80002eee <usertrap+0xd6>

0000000080002f0c <kerneltrap>:
{
    80002f0c:	7179                	addi	sp,sp,-48
    80002f0e:	f406                	sd	ra,40(sp)
    80002f10:	f022                	sd	s0,32(sp)
    80002f12:	ec26                	sd	s1,24(sp)
    80002f14:	e84a                	sd	s2,16(sp)
    80002f16:	e44e                	sd	s3,8(sp)
    80002f18:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f1a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f1e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f22:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002f26:	1004f793          	andi	a5,s1,256
    80002f2a:	cb85                	beqz	a5,80002f5a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f2c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002f30:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002f32:	ef85                	bnez	a5,80002f6a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002f34:	00000097          	auipc	ra,0x0
    80002f38:	e42080e7          	jalr	-446(ra) # 80002d76 <devintr>
    80002f3c:	cd1d                	beqz	a0,80002f7a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80002f3e:	4789                	li	a5,2
    80002f40:	06f50a63          	beq	a0,a5,80002fb4 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f44:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f48:	10049073          	csrw	sstatus,s1
}
    80002f4c:	70a2                	ld	ra,40(sp)
    80002f4e:	7402                	ld	s0,32(sp)
    80002f50:	64e2                	ld	s1,24(sp)
    80002f52:	6942                	ld	s2,16(sp)
    80002f54:	69a2                	ld	s3,8(sp)
    80002f56:	6145                	addi	sp,sp,48
    80002f58:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002f5a:	00005517          	auipc	a0,0x5
    80002f5e:	4fe50513          	addi	a0,a0,1278 # 80008458 <states.1871+0xc8>
    80002f62:	ffffd097          	auipc	ra,0xffffd
    80002f66:	5dc080e7          	jalr	1500(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002f6a:	00005517          	auipc	a0,0x5
    80002f6e:	51650513          	addi	a0,a0,1302 # 80008480 <states.1871+0xf0>
    80002f72:	ffffd097          	auipc	ra,0xffffd
    80002f76:	5cc080e7          	jalr	1484(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002f7a:	85ce                	mv	a1,s3
    80002f7c:	00005517          	auipc	a0,0x5
    80002f80:	52450513          	addi	a0,a0,1316 # 800084a0 <states.1871+0x110>
    80002f84:	ffffd097          	auipc	ra,0xffffd
    80002f88:	604080e7          	jalr	1540(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f8c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f90:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f94:	00005517          	auipc	a0,0x5
    80002f98:	51c50513          	addi	a0,a0,1308 # 800084b0 <states.1871+0x120>
    80002f9c:	ffffd097          	auipc	ra,0xffffd
    80002fa0:	5ec080e7          	jalr	1516(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002fa4:	00005517          	auipc	a0,0x5
    80002fa8:	52450513          	addi	a0,a0,1316 # 800084c8 <states.1871+0x138>
    80002fac:	ffffd097          	auipc	ra,0xffffd
    80002fb0:	592080e7          	jalr	1426(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80002fb4:	fffff097          	auipc	ra,0xfffff
    80002fb8:	a14080e7          	jalr	-1516(ra) # 800019c8 <myproc>
    80002fbc:	d541                	beqz	a0,80002f44 <kerneltrap+0x38>
    80002fbe:	fffff097          	auipc	ra,0xfffff
    80002fc2:	a0a080e7          	jalr	-1526(ra) # 800019c8 <myproc>
    80002fc6:	4d18                	lw	a4,24(a0)
    80002fc8:	4791                	li	a5,4
    80002fca:	f6f71de3          	bne	a4,a5,80002f44 <kerneltrap+0x38>
       yield();
    80002fce:	fffff097          	auipc	ra,0xfffff
    80002fd2:	40e080e7          	jalr	1038(ra) # 800023dc <yield>
    80002fd6:	b7bd                	j	80002f44 <kerneltrap+0x38>

0000000080002fd8 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002fd8:	1101                	addi	sp,sp,-32
    80002fda:	ec06                	sd	ra,24(sp)
    80002fdc:	e822                	sd	s0,16(sp)
    80002fde:	e426                	sd	s1,8(sp)
    80002fe0:	1000                	addi	s0,sp,32
    80002fe2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002fe4:	fffff097          	auipc	ra,0xfffff
    80002fe8:	9e4080e7          	jalr	-1564(ra) # 800019c8 <myproc>
  switch (n) {
    80002fec:	4795                	li	a5,5
    80002fee:	0497e163          	bltu	a5,s1,80003030 <argraw+0x58>
    80002ff2:	048a                	slli	s1,s1,0x2
    80002ff4:	00005717          	auipc	a4,0x5
    80002ff8:	50c70713          	addi	a4,a4,1292 # 80008500 <states.1871+0x170>
    80002ffc:	94ba                	add	s1,s1,a4
    80002ffe:	409c                	lw	a5,0(s1)
    80003000:	97ba                	add	a5,a5,a4
    80003002:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003004:	6d3c                	ld	a5,88(a0)
    80003006:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003008:	60e2                	ld	ra,24(sp)
    8000300a:	6442                	ld	s0,16(sp)
    8000300c:	64a2                	ld	s1,8(sp)
    8000300e:	6105                	addi	sp,sp,32
    80003010:	8082                	ret
    return p->trapframe->a1;
    80003012:	6d3c                	ld	a5,88(a0)
    80003014:	7fa8                	ld	a0,120(a5)
    80003016:	bfcd                	j	80003008 <argraw+0x30>
    return p->trapframe->a2;
    80003018:	6d3c                	ld	a5,88(a0)
    8000301a:	63c8                	ld	a0,128(a5)
    8000301c:	b7f5                	j	80003008 <argraw+0x30>
    return p->trapframe->a3;
    8000301e:	6d3c                	ld	a5,88(a0)
    80003020:	67c8                	ld	a0,136(a5)
    80003022:	b7dd                	j	80003008 <argraw+0x30>
    return p->trapframe->a4;
    80003024:	6d3c                	ld	a5,88(a0)
    80003026:	6bc8                	ld	a0,144(a5)
    80003028:	b7c5                	j	80003008 <argraw+0x30>
    return p->trapframe->a5;
    8000302a:	6d3c                	ld	a5,88(a0)
    8000302c:	6fc8                	ld	a0,152(a5)
    8000302e:	bfe9                	j	80003008 <argraw+0x30>
  panic("argraw");
    80003030:	00005517          	auipc	a0,0x5
    80003034:	4a850513          	addi	a0,a0,1192 # 800084d8 <states.1871+0x148>
    80003038:	ffffd097          	auipc	ra,0xffffd
    8000303c:	506080e7          	jalr	1286(ra) # 8000053e <panic>

0000000080003040 <fetchaddr>:
{
    80003040:	1101                	addi	sp,sp,-32
    80003042:	ec06                	sd	ra,24(sp)
    80003044:	e822                	sd	s0,16(sp)
    80003046:	e426                	sd	s1,8(sp)
    80003048:	e04a                	sd	s2,0(sp)
    8000304a:	1000                	addi	s0,sp,32
    8000304c:	84aa                	mv	s1,a0
    8000304e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003050:	fffff097          	auipc	ra,0xfffff
    80003054:	978080e7          	jalr	-1672(ra) # 800019c8 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003058:	653c                	ld	a5,72(a0)
    8000305a:	02f4f863          	bgeu	s1,a5,8000308a <fetchaddr+0x4a>
    8000305e:	00848713          	addi	a4,s1,8
    80003062:	02e7e663          	bltu	a5,a4,8000308e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003066:	46a1                	li	a3,8
    80003068:	8626                	mv	a2,s1
    8000306a:	85ca                	mv	a1,s2
    8000306c:	6928                	ld	a0,80(a0)
    8000306e:	ffffe097          	auipc	ra,0xffffe
    80003072:	698080e7          	jalr	1688(ra) # 80001706 <copyin>
    80003076:	00a03533          	snez	a0,a0
    8000307a:	40a00533          	neg	a0,a0
}
    8000307e:	60e2                	ld	ra,24(sp)
    80003080:	6442                	ld	s0,16(sp)
    80003082:	64a2                	ld	s1,8(sp)
    80003084:	6902                	ld	s2,0(sp)
    80003086:	6105                	addi	sp,sp,32
    80003088:	8082                	ret
    return -1;
    8000308a:	557d                	li	a0,-1
    8000308c:	bfcd                	j	8000307e <fetchaddr+0x3e>
    8000308e:	557d                	li	a0,-1
    80003090:	b7fd                	j	8000307e <fetchaddr+0x3e>

0000000080003092 <fetchstr>:
{
    80003092:	7179                	addi	sp,sp,-48
    80003094:	f406                	sd	ra,40(sp)
    80003096:	f022                	sd	s0,32(sp)
    80003098:	ec26                	sd	s1,24(sp)
    8000309a:	e84a                	sd	s2,16(sp)
    8000309c:	e44e                	sd	s3,8(sp)
    8000309e:	1800                	addi	s0,sp,48
    800030a0:	892a                	mv	s2,a0
    800030a2:	84ae                	mv	s1,a1
    800030a4:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800030a6:	fffff097          	auipc	ra,0xfffff
    800030aa:	922080e7          	jalr	-1758(ra) # 800019c8 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    800030ae:	86ce                	mv	a3,s3
    800030b0:	864a                	mv	a2,s2
    800030b2:	85a6                	mv	a1,s1
    800030b4:	6928                	ld	a0,80(a0)
    800030b6:	ffffe097          	auipc	ra,0xffffe
    800030ba:	6dc080e7          	jalr	1756(ra) # 80001792 <copyinstr>
  if(err < 0)
    800030be:	00054763          	bltz	a0,800030cc <fetchstr+0x3a>
  return strlen(buf);
    800030c2:	8526                	mv	a0,s1
    800030c4:	ffffe097          	auipc	ra,0xffffe
    800030c8:	da0080e7          	jalr	-608(ra) # 80000e64 <strlen>
}
    800030cc:	70a2                	ld	ra,40(sp)
    800030ce:	7402                	ld	s0,32(sp)
    800030d0:	64e2                	ld	s1,24(sp)
    800030d2:	6942                	ld	s2,16(sp)
    800030d4:	69a2                	ld	s3,8(sp)
    800030d6:	6145                	addi	sp,sp,48
    800030d8:	8082                	ret

00000000800030da <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    800030da:	1101                	addi	sp,sp,-32
    800030dc:	ec06                	sd	ra,24(sp)
    800030de:	e822                	sd	s0,16(sp)
    800030e0:	e426                	sd	s1,8(sp)
    800030e2:	1000                	addi	s0,sp,32
    800030e4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800030e6:	00000097          	auipc	ra,0x0
    800030ea:	ef2080e7          	jalr	-270(ra) # 80002fd8 <argraw>
    800030ee:	c088                	sw	a0,0(s1)
  return 0;
}
    800030f0:	4501                	li	a0,0
    800030f2:	60e2                	ld	ra,24(sp)
    800030f4:	6442                	ld	s0,16(sp)
    800030f6:	64a2                	ld	s1,8(sp)
    800030f8:	6105                	addi	sp,sp,32
    800030fa:	8082                	ret

00000000800030fc <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800030fc:	1101                	addi	sp,sp,-32
    800030fe:	ec06                	sd	ra,24(sp)
    80003100:	e822                	sd	s0,16(sp)
    80003102:	e426                	sd	s1,8(sp)
    80003104:	1000                	addi	s0,sp,32
    80003106:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003108:	00000097          	auipc	ra,0x0
    8000310c:	ed0080e7          	jalr	-304(ra) # 80002fd8 <argraw>
    80003110:	e088                	sd	a0,0(s1)
  return 0;
}
    80003112:	4501                	li	a0,0
    80003114:	60e2                	ld	ra,24(sp)
    80003116:	6442                	ld	s0,16(sp)
    80003118:	64a2                	ld	s1,8(sp)
    8000311a:	6105                	addi	sp,sp,32
    8000311c:	8082                	ret

000000008000311e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    8000311e:	1101                	addi	sp,sp,-32
    80003120:	ec06                	sd	ra,24(sp)
    80003122:	e822                	sd	s0,16(sp)
    80003124:	e426                	sd	s1,8(sp)
    80003126:	e04a                	sd	s2,0(sp)
    80003128:	1000                	addi	s0,sp,32
    8000312a:	84ae                	mv	s1,a1
    8000312c:	8932                	mv	s2,a2
  *ip = argraw(n);
    8000312e:	00000097          	auipc	ra,0x0
    80003132:	eaa080e7          	jalr	-342(ra) # 80002fd8 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003136:	864a                	mv	a2,s2
    80003138:	85a6                	mv	a1,s1
    8000313a:	00000097          	auipc	ra,0x0
    8000313e:	f58080e7          	jalr	-168(ra) # 80003092 <fetchstr>
}
    80003142:	60e2                	ld	ra,24(sp)
    80003144:	6442                	ld	s0,16(sp)
    80003146:	64a2                	ld	s1,8(sp)
    80003148:	6902                	ld	s2,0(sp)
    8000314a:	6105                	addi	sp,sp,32
    8000314c:	8082                	ret

000000008000314e <syscall>:
[SYS_print_stats] sys_print_stats,
};

void
syscall(void)
{
    8000314e:	1101                	addi	sp,sp,-32
    80003150:	ec06                	sd	ra,24(sp)
    80003152:	e822                	sd	s0,16(sp)
    80003154:	e426                	sd	s1,8(sp)
    80003156:	e04a                	sd	s2,0(sp)
    80003158:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000315a:	fffff097          	auipc	ra,0xfffff
    8000315e:	86e080e7          	jalr	-1938(ra) # 800019c8 <myproc>
    80003162:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003164:	05853903          	ld	s2,88(a0)
    80003168:	0a893783          	ld	a5,168(s2)
    8000316c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003170:	37fd                	addiw	a5,a5,-1
    80003172:	475d                	li	a4,23
    80003174:	00f76f63          	bltu	a4,a5,80003192 <syscall+0x44>
    80003178:	00369713          	slli	a4,a3,0x3
    8000317c:	00005797          	auipc	a5,0x5
    80003180:	39c78793          	addi	a5,a5,924 # 80008518 <syscalls>
    80003184:	97ba                	add	a5,a5,a4
    80003186:	639c                	ld	a5,0(a5)
    80003188:	c789                	beqz	a5,80003192 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    8000318a:	9782                	jalr	a5
    8000318c:	06a93823          	sd	a0,112(s2)
    80003190:	a839                	j	800031ae <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003192:	15848613          	addi	a2,s1,344
    80003196:	588c                	lw	a1,48(s1)
    80003198:	00005517          	auipc	a0,0x5
    8000319c:	34850513          	addi	a0,a0,840 # 800084e0 <states.1871+0x150>
    800031a0:	ffffd097          	auipc	ra,0xffffd
    800031a4:	3e8080e7          	jalr	1000(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800031a8:	6cbc                	ld	a5,88(s1)
    800031aa:	577d                	li	a4,-1
    800031ac:	fbb8                	sd	a4,112(a5)
  }
}
    800031ae:	60e2                	ld	ra,24(sp)
    800031b0:	6442                	ld	s0,16(sp)
    800031b2:	64a2                	ld	s1,8(sp)
    800031b4:	6902                	ld	s2,0(sp)
    800031b6:	6105                	addi	sp,sp,32
    800031b8:	8082                	ret

00000000800031ba <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800031ba:	1101                	addi	sp,sp,-32
    800031bc:	ec06                	sd	ra,24(sp)
    800031be:	e822                	sd	s0,16(sp)
    800031c0:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800031c2:	fec40593          	addi	a1,s0,-20
    800031c6:	4501                	li	a0,0
    800031c8:	00000097          	auipc	ra,0x0
    800031cc:	f12080e7          	jalr	-238(ra) # 800030da <argint>
    return -1;
    800031d0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800031d2:	00054963          	bltz	a0,800031e4 <sys_exit+0x2a>
  exit(n);
    800031d6:	fec42503          	lw	a0,-20(s0)
    800031da:	fffff097          	auipc	ra,0xfffff
    800031de:	502080e7          	jalr	1282(ra) # 800026dc <exit>
  return 0;  // not reached
    800031e2:	4781                	li	a5,0
}
    800031e4:	853e                	mv	a0,a5
    800031e6:	60e2                	ld	ra,24(sp)
    800031e8:	6442                	ld	s0,16(sp)
    800031ea:	6105                	addi	sp,sp,32
    800031ec:	8082                	ret

00000000800031ee <sys_getpid>:

uint64
sys_getpid(void)
{
    800031ee:	1141                	addi	sp,sp,-16
    800031f0:	e406                	sd	ra,8(sp)
    800031f2:	e022                	sd	s0,0(sp)
    800031f4:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800031f6:	ffffe097          	auipc	ra,0xffffe
    800031fa:	7d2080e7          	jalr	2002(ra) # 800019c8 <myproc>
}
    800031fe:	5908                	lw	a0,48(a0)
    80003200:	60a2                	ld	ra,8(sp)
    80003202:	6402                	ld	s0,0(sp)
    80003204:	0141                	addi	sp,sp,16
    80003206:	8082                	ret

0000000080003208 <sys_fork>:

uint64
sys_fork(void)
{
    80003208:	1141                	addi	sp,sp,-16
    8000320a:	e406                	sd	ra,8(sp)
    8000320c:	e022                	sd	s0,0(sp)
    8000320e:	0800                	addi	s0,sp,16
  return fork();
    80003210:	fffff097          	auipc	ra,0xfffff
    80003214:	ba6080e7          	jalr	-1114(ra) # 80001db6 <fork>
}
    80003218:	60a2                	ld	ra,8(sp)
    8000321a:	6402                	ld	s0,0(sp)
    8000321c:	0141                	addi	sp,sp,16
    8000321e:	8082                	ret

0000000080003220 <sys_wait>:

uint64
sys_wait(void)
{
    80003220:	1101                	addi	sp,sp,-32
    80003222:	ec06                	sd	ra,24(sp)
    80003224:	e822                	sd	s0,16(sp)
    80003226:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003228:	fe840593          	addi	a1,s0,-24
    8000322c:	4501                	li	a0,0
    8000322e:	00000097          	auipc	ra,0x0
    80003232:	ece080e7          	jalr	-306(ra) # 800030fc <argaddr>
    80003236:	87aa                	mv	a5,a0
    return -1;
    80003238:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    8000323a:	0007c863          	bltz	a5,8000324a <sys_wait+0x2a>
  return wait(p);
    8000323e:	fe843503          	ld	a0,-24(s0)
    80003242:	fffff097          	auipc	ra,0xfffff
    80003246:	272080e7          	jalr	626(ra) # 800024b4 <wait>
}
    8000324a:	60e2                	ld	ra,24(sp)
    8000324c:	6442                	ld	s0,16(sp)
    8000324e:	6105                	addi	sp,sp,32
    80003250:	8082                	ret

0000000080003252 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003252:	7179                	addi	sp,sp,-48
    80003254:	f406                	sd	ra,40(sp)
    80003256:	f022                	sd	s0,32(sp)
    80003258:	ec26                	sd	s1,24(sp)
    8000325a:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    8000325c:	fdc40593          	addi	a1,s0,-36
    80003260:	4501                	li	a0,0
    80003262:	00000097          	auipc	ra,0x0
    80003266:	e78080e7          	jalr	-392(ra) # 800030da <argint>
    8000326a:	87aa                	mv	a5,a0
    return -1;
    8000326c:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    8000326e:	0207c063          	bltz	a5,8000328e <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003272:	ffffe097          	auipc	ra,0xffffe
    80003276:	756080e7          	jalr	1878(ra) # 800019c8 <myproc>
    8000327a:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    8000327c:	fdc42503          	lw	a0,-36(s0)
    80003280:	fffff097          	auipc	ra,0xfffff
    80003284:	ac2080e7          	jalr	-1342(ra) # 80001d42 <growproc>
    80003288:	00054863          	bltz	a0,80003298 <sys_sbrk+0x46>
    return -1;
  return addr;
    8000328c:	8526                	mv	a0,s1
}
    8000328e:	70a2                	ld	ra,40(sp)
    80003290:	7402                	ld	s0,32(sp)
    80003292:	64e2                	ld	s1,24(sp)
    80003294:	6145                	addi	sp,sp,48
    80003296:	8082                	ret
    return -1;
    80003298:	557d                	li	a0,-1
    8000329a:	bfd5                	j	8000328e <sys_sbrk+0x3c>

000000008000329c <sys_sleep>:

uint64
sys_sleep(void)
{
    8000329c:	7139                	addi	sp,sp,-64
    8000329e:	fc06                	sd	ra,56(sp)
    800032a0:	f822                	sd	s0,48(sp)
    800032a2:	f426                	sd	s1,40(sp)
    800032a4:	f04a                	sd	s2,32(sp)
    800032a6:	ec4e                	sd	s3,24(sp)
    800032a8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800032aa:	fcc40593          	addi	a1,s0,-52
    800032ae:	4501                	li	a0,0
    800032b0:	00000097          	auipc	ra,0x0
    800032b4:	e2a080e7          	jalr	-470(ra) # 800030da <argint>
    return -1;
    800032b8:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800032ba:	06054563          	bltz	a0,80003324 <sys_sleep+0x88>
  acquire(&tickslock);
    800032be:	0000d517          	auipc	a0,0xd
    800032c2:	1a250513          	addi	a0,a0,418 # 80010460 <tickslock>
    800032c6:	ffffe097          	auipc	ra,0xffffe
    800032ca:	91e080e7          	jalr	-1762(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    800032ce:	00006917          	auipc	s2,0x6
    800032d2:	d8a92903          	lw	s2,-630(s2) # 80009058 <ticks>
  while(ticks - ticks0 < n){
    800032d6:	fcc42783          	lw	a5,-52(s0)
    800032da:	cf85                	beqz	a5,80003312 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800032dc:	0000d997          	auipc	s3,0xd
    800032e0:	18498993          	addi	s3,s3,388 # 80010460 <tickslock>
    800032e4:	00006497          	auipc	s1,0x6
    800032e8:	d7448493          	addi	s1,s1,-652 # 80009058 <ticks>
    if(myproc()->killed){
    800032ec:	ffffe097          	auipc	ra,0xffffe
    800032f0:	6dc080e7          	jalr	1756(ra) # 800019c8 <myproc>
    800032f4:	551c                	lw	a5,40(a0)
    800032f6:	ef9d                	bnez	a5,80003334 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800032f8:	85ce                	mv	a1,s3
    800032fa:	8526                	mv	a0,s1
    800032fc:	fffff097          	auipc	ra,0xfffff
    80003300:	138080e7          	jalr	312(ra) # 80002434 <sleep>
  while(ticks - ticks0 < n){
    80003304:	409c                	lw	a5,0(s1)
    80003306:	412787bb          	subw	a5,a5,s2
    8000330a:	fcc42703          	lw	a4,-52(s0)
    8000330e:	fce7efe3          	bltu	a5,a4,800032ec <sys_sleep+0x50>
  }
  release(&tickslock);
    80003312:	0000d517          	auipc	a0,0xd
    80003316:	14e50513          	addi	a0,a0,334 # 80010460 <tickslock>
    8000331a:	ffffe097          	auipc	ra,0xffffe
    8000331e:	97e080e7          	jalr	-1666(ra) # 80000c98 <release>
  return 0;
    80003322:	4781                	li	a5,0
}
    80003324:	853e                	mv	a0,a5
    80003326:	70e2                	ld	ra,56(sp)
    80003328:	7442                	ld	s0,48(sp)
    8000332a:	74a2                	ld	s1,40(sp)
    8000332c:	7902                	ld	s2,32(sp)
    8000332e:	69e2                	ld	s3,24(sp)
    80003330:	6121                	addi	sp,sp,64
    80003332:	8082                	ret
      release(&tickslock);
    80003334:	0000d517          	auipc	a0,0xd
    80003338:	12c50513          	addi	a0,a0,300 # 80010460 <tickslock>
    8000333c:	ffffe097          	auipc	ra,0xffffe
    80003340:	95c080e7          	jalr	-1700(ra) # 80000c98 <release>
      return -1;
    80003344:	57fd                	li	a5,-1
    80003346:	bff9                	j	80003324 <sys_sleep+0x88>

0000000080003348 <sys_kill>:

uint64
sys_kill(void)
{
    80003348:	1101                	addi	sp,sp,-32
    8000334a:	ec06                	sd	ra,24(sp)
    8000334c:	e822                	sd	s0,16(sp)
    8000334e:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003350:	fec40593          	addi	a1,s0,-20
    80003354:	4501                	li	a0,0
    80003356:	00000097          	auipc	ra,0x0
    8000335a:	d84080e7          	jalr	-636(ra) # 800030da <argint>
    8000335e:	87aa                	mv	a5,a0
    return -1;
    80003360:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003362:	0007c863          	bltz	a5,80003372 <sys_kill+0x2a>
  return kill(pid);
    80003366:	fec42503          	lw	a0,-20(s0)
    8000336a:	fffff097          	auipc	ra,0xfffff
    8000336e:	4f0080e7          	jalr	1264(ra) # 8000285a <kill>
}
    80003372:	60e2                	ld	ra,24(sp)
    80003374:	6442                	ld	s0,16(sp)
    80003376:	6105                	addi	sp,sp,32
    80003378:	8082                	ret

000000008000337a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000337a:	1101                	addi	sp,sp,-32
    8000337c:	ec06                	sd	ra,24(sp)
    8000337e:	e822                	sd	s0,16(sp)
    80003380:	e426                	sd	s1,8(sp)
    80003382:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003384:	0000d517          	auipc	a0,0xd
    80003388:	0dc50513          	addi	a0,a0,220 # 80010460 <tickslock>
    8000338c:	ffffe097          	auipc	ra,0xffffe
    80003390:	858080e7          	jalr	-1960(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003394:	00006497          	auipc	s1,0x6
    80003398:	cc44a483          	lw	s1,-828(s1) # 80009058 <ticks>
  release(&tickslock);
    8000339c:	0000d517          	auipc	a0,0xd
    800033a0:	0c450513          	addi	a0,a0,196 # 80010460 <tickslock>
    800033a4:	ffffe097          	auipc	ra,0xffffe
    800033a8:	8f4080e7          	jalr	-1804(ra) # 80000c98 <release>
  return xticks;
}
    800033ac:	02049513          	slli	a0,s1,0x20
    800033b0:	9101                	srli	a0,a0,0x20
    800033b2:	60e2                	ld	ra,24(sp)
    800033b4:	6442                	ld	s0,16(sp)
    800033b6:	64a2                	ld	s1,8(sp)
    800033b8:	6105                	addi	sp,sp,32
    800033ba:	8082                	ret

00000000800033bc <sys_kill_system>:

uint64
sys_kill_system(void)
{
    800033bc:	1141                	addi	sp,sp,-16
    800033be:	e406                	sd	ra,8(sp)
    800033c0:	e022                	sd	s0,0(sp)
    800033c2:	0800                	addi	s0,sp,16
  return kill_system();
    800033c4:	fffff097          	auipc	ra,0xfffff
    800033c8:	524080e7          	jalr	1316(ra) # 800028e8 <kill_system>
}
    800033cc:	60a2                	ld	ra,8(sp)
    800033ce:	6402                	ld	s0,0(sp)
    800033d0:	0141                	addi	sp,sp,16
    800033d2:	8082                	ret

00000000800033d4 <sys_pause_system>:

uint64
sys_pause_system(void)
{
    800033d4:	1101                	addi	sp,sp,-32
    800033d6:	ec06                	sd	ra,24(sp)
    800033d8:	e822                	sd	s0,16(sp)
    800033da:	1000                	addi	s0,sp,32
  int seconds;

  if(argint(0, &seconds) < 0)
    800033dc:	fec40593          	addi	a1,s0,-20
    800033e0:	4501                	li	a0,0
    800033e2:	00000097          	auipc	ra,0x0
    800033e6:	cf8080e7          	jalr	-776(ra) # 800030da <argint>
    800033ea:	87aa                	mv	a5,a0
    return -1;
    800033ec:	557d                	li	a0,-1
  if(argint(0, &seconds) < 0)
    800033ee:	0007c863          	bltz	a5,800033fe <sys_pause_system+0x2a>
  return pause_system(seconds);
    800033f2:	fec42503          	lw	a0,-20(s0)
    800033f6:	fffff097          	auipc	ra,0xfffff
    800033fa:	71c080e7          	jalr	1820(ra) # 80002b12 <pause_system>
}
    800033fe:	60e2                	ld	ra,24(sp)
    80003400:	6442                	ld	s0,16(sp)
    80003402:	6105                	addi	sp,sp,32
    80003404:	8082                	ret

0000000080003406 <sys_print_stats>:

uint64
sys_print_stats(void)
{
    80003406:	1141                	addi	sp,sp,-16
    80003408:	e406                	sd	ra,8(sp)
    8000340a:	e022                	sd	s0,0(sp)
    8000340c:	0800                	addi	s0,sp,16
   print_stats();
    8000340e:	fffff097          	auipc	ra,0xfffff
    80003412:	73a080e7          	jalr	1850(ra) # 80002b48 <print_stats>
   return 0;
    80003416:	4501                	li	a0,0
    80003418:	60a2                	ld	ra,8(sp)
    8000341a:	6402                	ld	s0,0(sp)
    8000341c:	0141                	addi	sp,sp,16
    8000341e:	8082                	ret

0000000080003420 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003420:	7179                	addi	sp,sp,-48
    80003422:	f406                	sd	ra,40(sp)
    80003424:	f022                	sd	s0,32(sp)
    80003426:	ec26                	sd	s1,24(sp)
    80003428:	e84a                	sd	s2,16(sp)
    8000342a:	e44e                	sd	s3,8(sp)
    8000342c:	e052                	sd	s4,0(sp)
    8000342e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003430:	00005597          	auipc	a1,0x5
    80003434:	1b058593          	addi	a1,a1,432 # 800085e0 <syscalls+0xc8>
    80003438:	0000d517          	auipc	a0,0xd
    8000343c:	04050513          	addi	a0,a0,64 # 80010478 <bcache>
    80003440:	ffffd097          	auipc	ra,0xffffd
    80003444:	714080e7          	jalr	1812(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003448:	00015797          	auipc	a5,0x15
    8000344c:	03078793          	addi	a5,a5,48 # 80018478 <bcache+0x8000>
    80003450:	00015717          	auipc	a4,0x15
    80003454:	29070713          	addi	a4,a4,656 # 800186e0 <bcache+0x8268>
    80003458:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000345c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003460:	0000d497          	auipc	s1,0xd
    80003464:	03048493          	addi	s1,s1,48 # 80010490 <bcache+0x18>
    b->next = bcache.head.next;
    80003468:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000346a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000346c:	00005a17          	auipc	s4,0x5
    80003470:	17ca0a13          	addi	s4,s4,380 # 800085e8 <syscalls+0xd0>
    b->next = bcache.head.next;
    80003474:	2b893783          	ld	a5,696(s2)
    80003478:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000347a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000347e:	85d2                	mv	a1,s4
    80003480:	01048513          	addi	a0,s1,16
    80003484:	00001097          	auipc	ra,0x1
    80003488:	4bc080e7          	jalr	1212(ra) # 80004940 <initsleeplock>
    bcache.head.next->prev = b;
    8000348c:	2b893783          	ld	a5,696(s2)
    80003490:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003492:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003496:	45848493          	addi	s1,s1,1112
    8000349a:	fd349de3          	bne	s1,s3,80003474 <binit+0x54>
  }
}
    8000349e:	70a2                	ld	ra,40(sp)
    800034a0:	7402                	ld	s0,32(sp)
    800034a2:	64e2                	ld	s1,24(sp)
    800034a4:	6942                	ld	s2,16(sp)
    800034a6:	69a2                	ld	s3,8(sp)
    800034a8:	6a02                	ld	s4,0(sp)
    800034aa:	6145                	addi	sp,sp,48
    800034ac:	8082                	ret

00000000800034ae <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800034ae:	7179                	addi	sp,sp,-48
    800034b0:	f406                	sd	ra,40(sp)
    800034b2:	f022                	sd	s0,32(sp)
    800034b4:	ec26                	sd	s1,24(sp)
    800034b6:	e84a                	sd	s2,16(sp)
    800034b8:	e44e                	sd	s3,8(sp)
    800034ba:	1800                	addi	s0,sp,48
    800034bc:	89aa                	mv	s3,a0
    800034be:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800034c0:	0000d517          	auipc	a0,0xd
    800034c4:	fb850513          	addi	a0,a0,-72 # 80010478 <bcache>
    800034c8:	ffffd097          	auipc	ra,0xffffd
    800034cc:	71c080e7          	jalr	1820(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800034d0:	00015497          	auipc	s1,0x15
    800034d4:	2604b483          	ld	s1,608(s1) # 80018730 <bcache+0x82b8>
    800034d8:	00015797          	auipc	a5,0x15
    800034dc:	20878793          	addi	a5,a5,520 # 800186e0 <bcache+0x8268>
    800034e0:	02f48f63          	beq	s1,a5,8000351e <bread+0x70>
    800034e4:	873e                	mv	a4,a5
    800034e6:	a021                	j	800034ee <bread+0x40>
    800034e8:	68a4                	ld	s1,80(s1)
    800034ea:	02e48a63          	beq	s1,a4,8000351e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800034ee:	449c                	lw	a5,8(s1)
    800034f0:	ff379ce3          	bne	a5,s3,800034e8 <bread+0x3a>
    800034f4:	44dc                	lw	a5,12(s1)
    800034f6:	ff2799e3          	bne	a5,s2,800034e8 <bread+0x3a>
      b->refcnt++;
    800034fa:	40bc                	lw	a5,64(s1)
    800034fc:	2785                	addiw	a5,a5,1
    800034fe:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003500:	0000d517          	auipc	a0,0xd
    80003504:	f7850513          	addi	a0,a0,-136 # 80010478 <bcache>
    80003508:	ffffd097          	auipc	ra,0xffffd
    8000350c:	790080e7          	jalr	1936(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003510:	01048513          	addi	a0,s1,16
    80003514:	00001097          	auipc	ra,0x1
    80003518:	466080e7          	jalr	1126(ra) # 8000497a <acquiresleep>
      return b;
    8000351c:	a8b9                	j	8000357a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000351e:	00015497          	auipc	s1,0x15
    80003522:	20a4b483          	ld	s1,522(s1) # 80018728 <bcache+0x82b0>
    80003526:	00015797          	auipc	a5,0x15
    8000352a:	1ba78793          	addi	a5,a5,442 # 800186e0 <bcache+0x8268>
    8000352e:	00f48863          	beq	s1,a5,8000353e <bread+0x90>
    80003532:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003534:	40bc                	lw	a5,64(s1)
    80003536:	cf81                	beqz	a5,8000354e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003538:	64a4                	ld	s1,72(s1)
    8000353a:	fee49de3          	bne	s1,a4,80003534 <bread+0x86>
  panic("bget: no buffers");
    8000353e:	00005517          	auipc	a0,0x5
    80003542:	0b250513          	addi	a0,a0,178 # 800085f0 <syscalls+0xd8>
    80003546:	ffffd097          	auipc	ra,0xffffd
    8000354a:	ff8080e7          	jalr	-8(ra) # 8000053e <panic>
      b->dev = dev;
    8000354e:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003552:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003556:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000355a:	4785                	li	a5,1
    8000355c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000355e:	0000d517          	auipc	a0,0xd
    80003562:	f1a50513          	addi	a0,a0,-230 # 80010478 <bcache>
    80003566:	ffffd097          	auipc	ra,0xffffd
    8000356a:	732080e7          	jalr	1842(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000356e:	01048513          	addi	a0,s1,16
    80003572:	00001097          	auipc	ra,0x1
    80003576:	408080e7          	jalr	1032(ra) # 8000497a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000357a:	409c                	lw	a5,0(s1)
    8000357c:	cb89                	beqz	a5,8000358e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000357e:	8526                	mv	a0,s1
    80003580:	70a2                	ld	ra,40(sp)
    80003582:	7402                	ld	s0,32(sp)
    80003584:	64e2                	ld	s1,24(sp)
    80003586:	6942                	ld	s2,16(sp)
    80003588:	69a2                	ld	s3,8(sp)
    8000358a:	6145                	addi	sp,sp,48
    8000358c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000358e:	4581                	li	a1,0
    80003590:	8526                	mv	a0,s1
    80003592:	00003097          	auipc	ra,0x3
    80003596:	f14080e7          	jalr	-236(ra) # 800064a6 <virtio_disk_rw>
    b->valid = 1;
    8000359a:	4785                	li	a5,1
    8000359c:	c09c                	sw	a5,0(s1)
  return b;
    8000359e:	b7c5                	j	8000357e <bread+0xd0>

00000000800035a0 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800035a0:	1101                	addi	sp,sp,-32
    800035a2:	ec06                	sd	ra,24(sp)
    800035a4:	e822                	sd	s0,16(sp)
    800035a6:	e426                	sd	s1,8(sp)
    800035a8:	1000                	addi	s0,sp,32
    800035aa:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800035ac:	0541                	addi	a0,a0,16
    800035ae:	00001097          	auipc	ra,0x1
    800035b2:	466080e7          	jalr	1126(ra) # 80004a14 <holdingsleep>
    800035b6:	cd01                	beqz	a0,800035ce <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800035b8:	4585                	li	a1,1
    800035ba:	8526                	mv	a0,s1
    800035bc:	00003097          	auipc	ra,0x3
    800035c0:	eea080e7          	jalr	-278(ra) # 800064a6 <virtio_disk_rw>
}
    800035c4:	60e2                	ld	ra,24(sp)
    800035c6:	6442                	ld	s0,16(sp)
    800035c8:	64a2                	ld	s1,8(sp)
    800035ca:	6105                	addi	sp,sp,32
    800035cc:	8082                	ret
    panic("bwrite");
    800035ce:	00005517          	auipc	a0,0x5
    800035d2:	03a50513          	addi	a0,a0,58 # 80008608 <syscalls+0xf0>
    800035d6:	ffffd097          	auipc	ra,0xffffd
    800035da:	f68080e7          	jalr	-152(ra) # 8000053e <panic>

00000000800035de <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800035de:	1101                	addi	sp,sp,-32
    800035e0:	ec06                	sd	ra,24(sp)
    800035e2:	e822                	sd	s0,16(sp)
    800035e4:	e426                	sd	s1,8(sp)
    800035e6:	e04a                	sd	s2,0(sp)
    800035e8:	1000                	addi	s0,sp,32
    800035ea:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800035ec:	01050913          	addi	s2,a0,16
    800035f0:	854a                	mv	a0,s2
    800035f2:	00001097          	auipc	ra,0x1
    800035f6:	422080e7          	jalr	1058(ra) # 80004a14 <holdingsleep>
    800035fa:	c92d                	beqz	a0,8000366c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800035fc:	854a                	mv	a0,s2
    800035fe:	00001097          	auipc	ra,0x1
    80003602:	3d2080e7          	jalr	978(ra) # 800049d0 <releasesleep>

  acquire(&bcache.lock);
    80003606:	0000d517          	auipc	a0,0xd
    8000360a:	e7250513          	addi	a0,a0,-398 # 80010478 <bcache>
    8000360e:	ffffd097          	auipc	ra,0xffffd
    80003612:	5d6080e7          	jalr	1494(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003616:	40bc                	lw	a5,64(s1)
    80003618:	37fd                	addiw	a5,a5,-1
    8000361a:	0007871b          	sext.w	a4,a5
    8000361e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003620:	eb05                	bnez	a4,80003650 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003622:	68bc                	ld	a5,80(s1)
    80003624:	64b8                	ld	a4,72(s1)
    80003626:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003628:	64bc                	ld	a5,72(s1)
    8000362a:	68b8                	ld	a4,80(s1)
    8000362c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000362e:	00015797          	auipc	a5,0x15
    80003632:	e4a78793          	addi	a5,a5,-438 # 80018478 <bcache+0x8000>
    80003636:	2b87b703          	ld	a4,696(a5)
    8000363a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000363c:	00015717          	auipc	a4,0x15
    80003640:	0a470713          	addi	a4,a4,164 # 800186e0 <bcache+0x8268>
    80003644:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003646:	2b87b703          	ld	a4,696(a5)
    8000364a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000364c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003650:	0000d517          	auipc	a0,0xd
    80003654:	e2850513          	addi	a0,a0,-472 # 80010478 <bcache>
    80003658:	ffffd097          	auipc	ra,0xffffd
    8000365c:	640080e7          	jalr	1600(ra) # 80000c98 <release>
}
    80003660:	60e2                	ld	ra,24(sp)
    80003662:	6442                	ld	s0,16(sp)
    80003664:	64a2                	ld	s1,8(sp)
    80003666:	6902                	ld	s2,0(sp)
    80003668:	6105                	addi	sp,sp,32
    8000366a:	8082                	ret
    panic("brelse");
    8000366c:	00005517          	auipc	a0,0x5
    80003670:	fa450513          	addi	a0,a0,-92 # 80008610 <syscalls+0xf8>
    80003674:	ffffd097          	auipc	ra,0xffffd
    80003678:	eca080e7          	jalr	-310(ra) # 8000053e <panic>

000000008000367c <bpin>:

void
bpin(struct buf *b) {
    8000367c:	1101                	addi	sp,sp,-32
    8000367e:	ec06                	sd	ra,24(sp)
    80003680:	e822                	sd	s0,16(sp)
    80003682:	e426                	sd	s1,8(sp)
    80003684:	1000                	addi	s0,sp,32
    80003686:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003688:	0000d517          	auipc	a0,0xd
    8000368c:	df050513          	addi	a0,a0,-528 # 80010478 <bcache>
    80003690:	ffffd097          	auipc	ra,0xffffd
    80003694:	554080e7          	jalr	1364(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003698:	40bc                	lw	a5,64(s1)
    8000369a:	2785                	addiw	a5,a5,1
    8000369c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000369e:	0000d517          	auipc	a0,0xd
    800036a2:	dda50513          	addi	a0,a0,-550 # 80010478 <bcache>
    800036a6:	ffffd097          	auipc	ra,0xffffd
    800036aa:	5f2080e7          	jalr	1522(ra) # 80000c98 <release>
}
    800036ae:	60e2                	ld	ra,24(sp)
    800036b0:	6442                	ld	s0,16(sp)
    800036b2:	64a2                	ld	s1,8(sp)
    800036b4:	6105                	addi	sp,sp,32
    800036b6:	8082                	ret

00000000800036b8 <bunpin>:

void
bunpin(struct buf *b) {
    800036b8:	1101                	addi	sp,sp,-32
    800036ba:	ec06                	sd	ra,24(sp)
    800036bc:	e822                	sd	s0,16(sp)
    800036be:	e426                	sd	s1,8(sp)
    800036c0:	1000                	addi	s0,sp,32
    800036c2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036c4:	0000d517          	auipc	a0,0xd
    800036c8:	db450513          	addi	a0,a0,-588 # 80010478 <bcache>
    800036cc:	ffffd097          	auipc	ra,0xffffd
    800036d0:	518080e7          	jalr	1304(ra) # 80000be4 <acquire>
  b->refcnt--;
    800036d4:	40bc                	lw	a5,64(s1)
    800036d6:	37fd                	addiw	a5,a5,-1
    800036d8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036da:	0000d517          	auipc	a0,0xd
    800036de:	d9e50513          	addi	a0,a0,-610 # 80010478 <bcache>
    800036e2:	ffffd097          	auipc	ra,0xffffd
    800036e6:	5b6080e7          	jalr	1462(ra) # 80000c98 <release>
}
    800036ea:	60e2                	ld	ra,24(sp)
    800036ec:	6442                	ld	s0,16(sp)
    800036ee:	64a2                	ld	s1,8(sp)
    800036f0:	6105                	addi	sp,sp,32
    800036f2:	8082                	ret

00000000800036f4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800036f4:	1101                	addi	sp,sp,-32
    800036f6:	ec06                	sd	ra,24(sp)
    800036f8:	e822                	sd	s0,16(sp)
    800036fa:	e426                	sd	s1,8(sp)
    800036fc:	e04a                	sd	s2,0(sp)
    800036fe:	1000                	addi	s0,sp,32
    80003700:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003702:	00d5d59b          	srliw	a1,a1,0xd
    80003706:	00015797          	auipc	a5,0x15
    8000370a:	44e7a783          	lw	a5,1102(a5) # 80018b54 <sb+0x1c>
    8000370e:	9dbd                	addw	a1,a1,a5
    80003710:	00000097          	auipc	ra,0x0
    80003714:	d9e080e7          	jalr	-610(ra) # 800034ae <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003718:	0074f713          	andi	a4,s1,7
    8000371c:	4785                	li	a5,1
    8000371e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003722:	14ce                	slli	s1,s1,0x33
    80003724:	90d9                	srli	s1,s1,0x36
    80003726:	00950733          	add	a4,a0,s1
    8000372a:	05874703          	lbu	a4,88(a4)
    8000372e:	00e7f6b3          	and	a3,a5,a4
    80003732:	c69d                	beqz	a3,80003760 <bfree+0x6c>
    80003734:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003736:	94aa                	add	s1,s1,a0
    80003738:	fff7c793          	not	a5,a5
    8000373c:	8ff9                	and	a5,a5,a4
    8000373e:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003742:	00001097          	auipc	ra,0x1
    80003746:	118080e7          	jalr	280(ra) # 8000485a <log_write>
  brelse(bp);
    8000374a:	854a                	mv	a0,s2
    8000374c:	00000097          	auipc	ra,0x0
    80003750:	e92080e7          	jalr	-366(ra) # 800035de <brelse>
}
    80003754:	60e2                	ld	ra,24(sp)
    80003756:	6442                	ld	s0,16(sp)
    80003758:	64a2                	ld	s1,8(sp)
    8000375a:	6902                	ld	s2,0(sp)
    8000375c:	6105                	addi	sp,sp,32
    8000375e:	8082                	ret
    panic("freeing free block");
    80003760:	00005517          	auipc	a0,0x5
    80003764:	eb850513          	addi	a0,a0,-328 # 80008618 <syscalls+0x100>
    80003768:	ffffd097          	auipc	ra,0xffffd
    8000376c:	dd6080e7          	jalr	-554(ra) # 8000053e <panic>

0000000080003770 <balloc>:
{
    80003770:	711d                	addi	sp,sp,-96
    80003772:	ec86                	sd	ra,88(sp)
    80003774:	e8a2                	sd	s0,80(sp)
    80003776:	e4a6                	sd	s1,72(sp)
    80003778:	e0ca                	sd	s2,64(sp)
    8000377a:	fc4e                	sd	s3,56(sp)
    8000377c:	f852                	sd	s4,48(sp)
    8000377e:	f456                	sd	s5,40(sp)
    80003780:	f05a                	sd	s6,32(sp)
    80003782:	ec5e                	sd	s7,24(sp)
    80003784:	e862                	sd	s8,16(sp)
    80003786:	e466                	sd	s9,8(sp)
    80003788:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000378a:	00015797          	auipc	a5,0x15
    8000378e:	3b27a783          	lw	a5,946(a5) # 80018b3c <sb+0x4>
    80003792:	cbd1                	beqz	a5,80003826 <balloc+0xb6>
    80003794:	8baa                	mv	s7,a0
    80003796:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003798:	00015b17          	auipc	s6,0x15
    8000379c:	3a0b0b13          	addi	s6,s6,928 # 80018b38 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037a0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800037a2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037a4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800037a6:	6c89                	lui	s9,0x2
    800037a8:	a831                	j	800037c4 <balloc+0x54>
    brelse(bp);
    800037aa:	854a                	mv	a0,s2
    800037ac:	00000097          	auipc	ra,0x0
    800037b0:	e32080e7          	jalr	-462(ra) # 800035de <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800037b4:	015c87bb          	addw	a5,s9,s5
    800037b8:	00078a9b          	sext.w	s5,a5
    800037bc:	004b2703          	lw	a4,4(s6)
    800037c0:	06eaf363          	bgeu	s5,a4,80003826 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800037c4:	41fad79b          	sraiw	a5,s5,0x1f
    800037c8:	0137d79b          	srliw	a5,a5,0x13
    800037cc:	015787bb          	addw	a5,a5,s5
    800037d0:	40d7d79b          	sraiw	a5,a5,0xd
    800037d4:	01cb2583          	lw	a1,28(s6)
    800037d8:	9dbd                	addw	a1,a1,a5
    800037da:	855e                	mv	a0,s7
    800037dc:	00000097          	auipc	ra,0x0
    800037e0:	cd2080e7          	jalr	-814(ra) # 800034ae <bread>
    800037e4:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037e6:	004b2503          	lw	a0,4(s6)
    800037ea:	000a849b          	sext.w	s1,s5
    800037ee:	8662                	mv	a2,s8
    800037f0:	faa4fde3          	bgeu	s1,a0,800037aa <balloc+0x3a>
      m = 1 << (bi % 8);
    800037f4:	41f6579b          	sraiw	a5,a2,0x1f
    800037f8:	01d7d69b          	srliw	a3,a5,0x1d
    800037fc:	00c6873b          	addw	a4,a3,a2
    80003800:	00777793          	andi	a5,a4,7
    80003804:	9f95                	subw	a5,a5,a3
    80003806:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000380a:	4037571b          	sraiw	a4,a4,0x3
    8000380e:	00e906b3          	add	a3,s2,a4
    80003812:	0586c683          	lbu	a3,88(a3)
    80003816:	00d7f5b3          	and	a1,a5,a3
    8000381a:	cd91                	beqz	a1,80003836 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000381c:	2605                	addiw	a2,a2,1
    8000381e:	2485                	addiw	s1,s1,1
    80003820:	fd4618e3          	bne	a2,s4,800037f0 <balloc+0x80>
    80003824:	b759                	j	800037aa <balloc+0x3a>
  panic("balloc: out of blocks");
    80003826:	00005517          	auipc	a0,0x5
    8000382a:	e0a50513          	addi	a0,a0,-502 # 80008630 <syscalls+0x118>
    8000382e:	ffffd097          	auipc	ra,0xffffd
    80003832:	d10080e7          	jalr	-752(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003836:	974a                	add	a4,a4,s2
    80003838:	8fd5                	or	a5,a5,a3
    8000383a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000383e:	854a                	mv	a0,s2
    80003840:	00001097          	auipc	ra,0x1
    80003844:	01a080e7          	jalr	26(ra) # 8000485a <log_write>
        brelse(bp);
    80003848:	854a                	mv	a0,s2
    8000384a:	00000097          	auipc	ra,0x0
    8000384e:	d94080e7          	jalr	-620(ra) # 800035de <brelse>
  bp = bread(dev, bno);
    80003852:	85a6                	mv	a1,s1
    80003854:	855e                	mv	a0,s7
    80003856:	00000097          	auipc	ra,0x0
    8000385a:	c58080e7          	jalr	-936(ra) # 800034ae <bread>
    8000385e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003860:	40000613          	li	a2,1024
    80003864:	4581                	li	a1,0
    80003866:	05850513          	addi	a0,a0,88
    8000386a:	ffffd097          	auipc	ra,0xffffd
    8000386e:	476080e7          	jalr	1142(ra) # 80000ce0 <memset>
  log_write(bp);
    80003872:	854a                	mv	a0,s2
    80003874:	00001097          	auipc	ra,0x1
    80003878:	fe6080e7          	jalr	-26(ra) # 8000485a <log_write>
  brelse(bp);
    8000387c:	854a                	mv	a0,s2
    8000387e:	00000097          	auipc	ra,0x0
    80003882:	d60080e7          	jalr	-672(ra) # 800035de <brelse>
}
    80003886:	8526                	mv	a0,s1
    80003888:	60e6                	ld	ra,88(sp)
    8000388a:	6446                	ld	s0,80(sp)
    8000388c:	64a6                	ld	s1,72(sp)
    8000388e:	6906                	ld	s2,64(sp)
    80003890:	79e2                	ld	s3,56(sp)
    80003892:	7a42                	ld	s4,48(sp)
    80003894:	7aa2                	ld	s5,40(sp)
    80003896:	7b02                	ld	s6,32(sp)
    80003898:	6be2                	ld	s7,24(sp)
    8000389a:	6c42                	ld	s8,16(sp)
    8000389c:	6ca2                	ld	s9,8(sp)
    8000389e:	6125                	addi	sp,sp,96
    800038a0:	8082                	ret

00000000800038a2 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800038a2:	7179                	addi	sp,sp,-48
    800038a4:	f406                	sd	ra,40(sp)
    800038a6:	f022                	sd	s0,32(sp)
    800038a8:	ec26                	sd	s1,24(sp)
    800038aa:	e84a                	sd	s2,16(sp)
    800038ac:	e44e                	sd	s3,8(sp)
    800038ae:	e052                	sd	s4,0(sp)
    800038b0:	1800                	addi	s0,sp,48
    800038b2:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800038b4:	47ad                	li	a5,11
    800038b6:	04b7fe63          	bgeu	a5,a1,80003912 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800038ba:	ff45849b          	addiw	s1,a1,-12
    800038be:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800038c2:	0ff00793          	li	a5,255
    800038c6:	0ae7e363          	bltu	a5,a4,8000396c <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800038ca:	08052583          	lw	a1,128(a0)
    800038ce:	c5ad                	beqz	a1,80003938 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800038d0:	00092503          	lw	a0,0(s2)
    800038d4:	00000097          	auipc	ra,0x0
    800038d8:	bda080e7          	jalr	-1062(ra) # 800034ae <bread>
    800038dc:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800038de:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800038e2:	02049593          	slli	a1,s1,0x20
    800038e6:	9181                	srli	a1,a1,0x20
    800038e8:	058a                	slli	a1,a1,0x2
    800038ea:	00b784b3          	add	s1,a5,a1
    800038ee:	0004a983          	lw	s3,0(s1)
    800038f2:	04098d63          	beqz	s3,8000394c <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800038f6:	8552                	mv	a0,s4
    800038f8:	00000097          	auipc	ra,0x0
    800038fc:	ce6080e7          	jalr	-794(ra) # 800035de <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003900:	854e                	mv	a0,s3
    80003902:	70a2                	ld	ra,40(sp)
    80003904:	7402                	ld	s0,32(sp)
    80003906:	64e2                	ld	s1,24(sp)
    80003908:	6942                	ld	s2,16(sp)
    8000390a:	69a2                	ld	s3,8(sp)
    8000390c:	6a02                	ld	s4,0(sp)
    8000390e:	6145                	addi	sp,sp,48
    80003910:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003912:	02059493          	slli	s1,a1,0x20
    80003916:	9081                	srli	s1,s1,0x20
    80003918:	048a                	slli	s1,s1,0x2
    8000391a:	94aa                	add	s1,s1,a0
    8000391c:	0504a983          	lw	s3,80(s1)
    80003920:	fe0990e3          	bnez	s3,80003900 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003924:	4108                	lw	a0,0(a0)
    80003926:	00000097          	auipc	ra,0x0
    8000392a:	e4a080e7          	jalr	-438(ra) # 80003770 <balloc>
    8000392e:	0005099b          	sext.w	s3,a0
    80003932:	0534a823          	sw	s3,80(s1)
    80003936:	b7e9                	j	80003900 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003938:	4108                	lw	a0,0(a0)
    8000393a:	00000097          	auipc	ra,0x0
    8000393e:	e36080e7          	jalr	-458(ra) # 80003770 <balloc>
    80003942:	0005059b          	sext.w	a1,a0
    80003946:	08b92023          	sw	a1,128(s2)
    8000394a:	b759                	j	800038d0 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000394c:	00092503          	lw	a0,0(s2)
    80003950:	00000097          	auipc	ra,0x0
    80003954:	e20080e7          	jalr	-480(ra) # 80003770 <balloc>
    80003958:	0005099b          	sext.w	s3,a0
    8000395c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003960:	8552                	mv	a0,s4
    80003962:	00001097          	auipc	ra,0x1
    80003966:	ef8080e7          	jalr	-264(ra) # 8000485a <log_write>
    8000396a:	b771                	j	800038f6 <bmap+0x54>
  panic("bmap: out of range");
    8000396c:	00005517          	auipc	a0,0x5
    80003970:	cdc50513          	addi	a0,a0,-804 # 80008648 <syscalls+0x130>
    80003974:	ffffd097          	auipc	ra,0xffffd
    80003978:	bca080e7          	jalr	-1078(ra) # 8000053e <panic>

000000008000397c <iget>:
{
    8000397c:	7179                	addi	sp,sp,-48
    8000397e:	f406                	sd	ra,40(sp)
    80003980:	f022                	sd	s0,32(sp)
    80003982:	ec26                	sd	s1,24(sp)
    80003984:	e84a                	sd	s2,16(sp)
    80003986:	e44e                	sd	s3,8(sp)
    80003988:	e052                	sd	s4,0(sp)
    8000398a:	1800                	addi	s0,sp,48
    8000398c:	89aa                	mv	s3,a0
    8000398e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003990:	00015517          	auipc	a0,0x15
    80003994:	1c850513          	addi	a0,a0,456 # 80018b58 <itable>
    80003998:	ffffd097          	auipc	ra,0xffffd
    8000399c:	24c080e7          	jalr	588(ra) # 80000be4 <acquire>
  empty = 0;
    800039a0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800039a2:	00015497          	auipc	s1,0x15
    800039a6:	1ce48493          	addi	s1,s1,462 # 80018b70 <itable+0x18>
    800039aa:	00017697          	auipc	a3,0x17
    800039ae:	c5668693          	addi	a3,a3,-938 # 8001a600 <log>
    800039b2:	a039                	j	800039c0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800039b4:	02090b63          	beqz	s2,800039ea <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800039b8:	08848493          	addi	s1,s1,136
    800039bc:	02d48a63          	beq	s1,a3,800039f0 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800039c0:	449c                	lw	a5,8(s1)
    800039c2:	fef059e3          	blez	a5,800039b4 <iget+0x38>
    800039c6:	4098                	lw	a4,0(s1)
    800039c8:	ff3716e3          	bne	a4,s3,800039b4 <iget+0x38>
    800039cc:	40d8                	lw	a4,4(s1)
    800039ce:	ff4713e3          	bne	a4,s4,800039b4 <iget+0x38>
      ip->ref++;
    800039d2:	2785                	addiw	a5,a5,1
    800039d4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800039d6:	00015517          	auipc	a0,0x15
    800039da:	18250513          	addi	a0,a0,386 # 80018b58 <itable>
    800039de:	ffffd097          	auipc	ra,0xffffd
    800039e2:	2ba080e7          	jalr	698(ra) # 80000c98 <release>
      return ip;
    800039e6:	8926                	mv	s2,s1
    800039e8:	a03d                	j	80003a16 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800039ea:	f7f9                	bnez	a5,800039b8 <iget+0x3c>
    800039ec:	8926                	mv	s2,s1
    800039ee:	b7e9                	j	800039b8 <iget+0x3c>
  if(empty == 0)
    800039f0:	02090c63          	beqz	s2,80003a28 <iget+0xac>
  ip->dev = dev;
    800039f4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800039f8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800039fc:	4785                	li	a5,1
    800039fe:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003a02:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003a06:	00015517          	auipc	a0,0x15
    80003a0a:	15250513          	addi	a0,a0,338 # 80018b58 <itable>
    80003a0e:	ffffd097          	auipc	ra,0xffffd
    80003a12:	28a080e7          	jalr	650(ra) # 80000c98 <release>
}
    80003a16:	854a                	mv	a0,s2
    80003a18:	70a2                	ld	ra,40(sp)
    80003a1a:	7402                	ld	s0,32(sp)
    80003a1c:	64e2                	ld	s1,24(sp)
    80003a1e:	6942                	ld	s2,16(sp)
    80003a20:	69a2                	ld	s3,8(sp)
    80003a22:	6a02                	ld	s4,0(sp)
    80003a24:	6145                	addi	sp,sp,48
    80003a26:	8082                	ret
    panic("iget: no inodes");
    80003a28:	00005517          	auipc	a0,0x5
    80003a2c:	c3850513          	addi	a0,a0,-968 # 80008660 <syscalls+0x148>
    80003a30:	ffffd097          	auipc	ra,0xffffd
    80003a34:	b0e080e7          	jalr	-1266(ra) # 8000053e <panic>

0000000080003a38 <fsinit>:
fsinit(int dev) {
    80003a38:	7179                	addi	sp,sp,-48
    80003a3a:	f406                	sd	ra,40(sp)
    80003a3c:	f022                	sd	s0,32(sp)
    80003a3e:	ec26                	sd	s1,24(sp)
    80003a40:	e84a                	sd	s2,16(sp)
    80003a42:	e44e                	sd	s3,8(sp)
    80003a44:	1800                	addi	s0,sp,48
    80003a46:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003a48:	4585                	li	a1,1
    80003a4a:	00000097          	auipc	ra,0x0
    80003a4e:	a64080e7          	jalr	-1436(ra) # 800034ae <bread>
    80003a52:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003a54:	00015997          	auipc	s3,0x15
    80003a58:	0e498993          	addi	s3,s3,228 # 80018b38 <sb>
    80003a5c:	02000613          	li	a2,32
    80003a60:	05850593          	addi	a1,a0,88
    80003a64:	854e                	mv	a0,s3
    80003a66:	ffffd097          	auipc	ra,0xffffd
    80003a6a:	2da080e7          	jalr	730(ra) # 80000d40 <memmove>
  brelse(bp);
    80003a6e:	8526                	mv	a0,s1
    80003a70:	00000097          	auipc	ra,0x0
    80003a74:	b6e080e7          	jalr	-1170(ra) # 800035de <brelse>
  if(sb.magic != FSMAGIC)
    80003a78:	0009a703          	lw	a4,0(s3)
    80003a7c:	102037b7          	lui	a5,0x10203
    80003a80:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003a84:	02f71263          	bne	a4,a5,80003aa8 <fsinit+0x70>
  initlog(dev, &sb);
    80003a88:	00015597          	auipc	a1,0x15
    80003a8c:	0b058593          	addi	a1,a1,176 # 80018b38 <sb>
    80003a90:	854a                	mv	a0,s2
    80003a92:	00001097          	auipc	ra,0x1
    80003a96:	b4c080e7          	jalr	-1204(ra) # 800045de <initlog>
}
    80003a9a:	70a2                	ld	ra,40(sp)
    80003a9c:	7402                	ld	s0,32(sp)
    80003a9e:	64e2                	ld	s1,24(sp)
    80003aa0:	6942                	ld	s2,16(sp)
    80003aa2:	69a2                	ld	s3,8(sp)
    80003aa4:	6145                	addi	sp,sp,48
    80003aa6:	8082                	ret
    panic("invalid file system");
    80003aa8:	00005517          	auipc	a0,0x5
    80003aac:	bc850513          	addi	a0,a0,-1080 # 80008670 <syscalls+0x158>
    80003ab0:	ffffd097          	auipc	ra,0xffffd
    80003ab4:	a8e080e7          	jalr	-1394(ra) # 8000053e <panic>

0000000080003ab8 <iinit>:
{
    80003ab8:	7179                	addi	sp,sp,-48
    80003aba:	f406                	sd	ra,40(sp)
    80003abc:	f022                	sd	s0,32(sp)
    80003abe:	ec26                	sd	s1,24(sp)
    80003ac0:	e84a                	sd	s2,16(sp)
    80003ac2:	e44e                	sd	s3,8(sp)
    80003ac4:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003ac6:	00005597          	auipc	a1,0x5
    80003aca:	bc258593          	addi	a1,a1,-1086 # 80008688 <syscalls+0x170>
    80003ace:	00015517          	auipc	a0,0x15
    80003ad2:	08a50513          	addi	a0,a0,138 # 80018b58 <itable>
    80003ad6:	ffffd097          	auipc	ra,0xffffd
    80003ada:	07e080e7          	jalr	126(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003ade:	00015497          	auipc	s1,0x15
    80003ae2:	0a248493          	addi	s1,s1,162 # 80018b80 <itable+0x28>
    80003ae6:	00017997          	auipc	s3,0x17
    80003aea:	b2a98993          	addi	s3,s3,-1238 # 8001a610 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003aee:	00005917          	auipc	s2,0x5
    80003af2:	ba290913          	addi	s2,s2,-1118 # 80008690 <syscalls+0x178>
    80003af6:	85ca                	mv	a1,s2
    80003af8:	8526                	mv	a0,s1
    80003afa:	00001097          	auipc	ra,0x1
    80003afe:	e46080e7          	jalr	-442(ra) # 80004940 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003b02:	08848493          	addi	s1,s1,136
    80003b06:	ff3498e3          	bne	s1,s3,80003af6 <iinit+0x3e>
}
    80003b0a:	70a2                	ld	ra,40(sp)
    80003b0c:	7402                	ld	s0,32(sp)
    80003b0e:	64e2                	ld	s1,24(sp)
    80003b10:	6942                	ld	s2,16(sp)
    80003b12:	69a2                	ld	s3,8(sp)
    80003b14:	6145                	addi	sp,sp,48
    80003b16:	8082                	ret

0000000080003b18 <ialloc>:
{
    80003b18:	715d                	addi	sp,sp,-80
    80003b1a:	e486                	sd	ra,72(sp)
    80003b1c:	e0a2                	sd	s0,64(sp)
    80003b1e:	fc26                	sd	s1,56(sp)
    80003b20:	f84a                	sd	s2,48(sp)
    80003b22:	f44e                	sd	s3,40(sp)
    80003b24:	f052                	sd	s4,32(sp)
    80003b26:	ec56                	sd	s5,24(sp)
    80003b28:	e85a                	sd	s6,16(sp)
    80003b2a:	e45e                	sd	s7,8(sp)
    80003b2c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b2e:	00015717          	auipc	a4,0x15
    80003b32:	01672703          	lw	a4,22(a4) # 80018b44 <sb+0xc>
    80003b36:	4785                	li	a5,1
    80003b38:	04e7fa63          	bgeu	a5,a4,80003b8c <ialloc+0x74>
    80003b3c:	8aaa                	mv	s5,a0
    80003b3e:	8bae                	mv	s7,a1
    80003b40:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003b42:	00015a17          	auipc	s4,0x15
    80003b46:	ff6a0a13          	addi	s4,s4,-10 # 80018b38 <sb>
    80003b4a:	00048b1b          	sext.w	s6,s1
    80003b4e:	0044d593          	srli	a1,s1,0x4
    80003b52:	018a2783          	lw	a5,24(s4)
    80003b56:	9dbd                	addw	a1,a1,a5
    80003b58:	8556                	mv	a0,s5
    80003b5a:	00000097          	auipc	ra,0x0
    80003b5e:	954080e7          	jalr	-1708(ra) # 800034ae <bread>
    80003b62:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003b64:	05850993          	addi	s3,a0,88
    80003b68:	00f4f793          	andi	a5,s1,15
    80003b6c:	079a                	slli	a5,a5,0x6
    80003b6e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003b70:	00099783          	lh	a5,0(s3)
    80003b74:	c785                	beqz	a5,80003b9c <ialloc+0x84>
    brelse(bp);
    80003b76:	00000097          	auipc	ra,0x0
    80003b7a:	a68080e7          	jalr	-1432(ra) # 800035de <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b7e:	0485                	addi	s1,s1,1
    80003b80:	00ca2703          	lw	a4,12(s4)
    80003b84:	0004879b          	sext.w	a5,s1
    80003b88:	fce7e1e3          	bltu	a5,a4,80003b4a <ialloc+0x32>
  panic("ialloc: no inodes");
    80003b8c:	00005517          	auipc	a0,0x5
    80003b90:	b0c50513          	addi	a0,a0,-1268 # 80008698 <syscalls+0x180>
    80003b94:	ffffd097          	auipc	ra,0xffffd
    80003b98:	9aa080e7          	jalr	-1622(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003b9c:	04000613          	li	a2,64
    80003ba0:	4581                	li	a1,0
    80003ba2:	854e                	mv	a0,s3
    80003ba4:	ffffd097          	auipc	ra,0xffffd
    80003ba8:	13c080e7          	jalr	316(ra) # 80000ce0 <memset>
      dip->type = type;
    80003bac:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003bb0:	854a                	mv	a0,s2
    80003bb2:	00001097          	auipc	ra,0x1
    80003bb6:	ca8080e7          	jalr	-856(ra) # 8000485a <log_write>
      brelse(bp);
    80003bba:	854a                	mv	a0,s2
    80003bbc:	00000097          	auipc	ra,0x0
    80003bc0:	a22080e7          	jalr	-1502(ra) # 800035de <brelse>
      return iget(dev, inum);
    80003bc4:	85da                	mv	a1,s6
    80003bc6:	8556                	mv	a0,s5
    80003bc8:	00000097          	auipc	ra,0x0
    80003bcc:	db4080e7          	jalr	-588(ra) # 8000397c <iget>
}
    80003bd0:	60a6                	ld	ra,72(sp)
    80003bd2:	6406                	ld	s0,64(sp)
    80003bd4:	74e2                	ld	s1,56(sp)
    80003bd6:	7942                	ld	s2,48(sp)
    80003bd8:	79a2                	ld	s3,40(sp)
    80003bda:	7a02                	ld	s4,32(sp)
    80003bdc:	6ae2                	ld	s5,24(sp)
    80003bde:	6b42                	ld	s6,16(sp)
    80003be0:	6ba2                	ld	s7,8(sp)
    80003be2:	6161                	addi	sp,sp,80
    80003be4:	8082                	ret

0000000080003be6 <iupdate>:
{
    80003be6:	1101                	addi	sp,sp,-32
    80003be8:	ec06                	sd	ra,24(sp)
    80003bea:	e822                	sd	s0,16(sp)
    80003bec:	e426                	sd	s1,8(sp)
    80003bee:	e04a                	sd	s2,0(sp)
    80003bf0:	1000                	addi	s0,sp,32
    80003bf2:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003bf4:	415c                	lw	a5,4(a0)
    80003bf6:	0047d79b          	srliw	a5,a5,0x4
    80003bfa:	00015597          	auipc	a1,0x15
    80003bfe:	f565a583          	lw	a1,-170(a1) # 80018b50 <sb+0x18>
    80003c02:	9dbd                	addw	a1,a1,a5
    80003c04:	4108                	lw	a0,0(a0)
    80003c06:	00000097          	auipc	ra,0x0
    80003c0a:	8a8080e7          	jalr	-1880(ra) # 800034ae <bread>
    80003c0e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c10:	05850793          	addi	a5,a0,88
    80003c14:	40c8                	lw	a0,4(s1)
    80003c16:	893d                	andi	a0,a0,15
    80003c18:	051a                	slli	a0,a0,0x6
    80003c1a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003c1c:	04449703          	lh	a4,68(s1)
    80003c20:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003c24:	04649703          	lh	a4,70(s1)
    80003c28:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003c2c:	04849703          	lh	a4,72(s1)
    80003c30:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003c34:	04a49703          	lh	a4,74(s1)
    80003c38:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003c3c:	44f8                	lw	a4,76(s1)
    80003c3e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003c40:	03400613          	li	a2,52
    80003c44:	05048593          	addi	a1,s1,80
    80003c48:	0531                	addi	a0,a0,12
    80003c4a:	ffffd097          	auipc	ra,0xffffd
    80003c4e:	0f6080e7          	jalr	246(ra) # 80000d40 <memmove>
  log_write(bp);
    80003c52:	854a                	mv	a0,s2
    80003c54:	00001097          	auipc	ra,0x1
    80003c58:	c06080e7          	jalr	-1018(ra) # 8000485a <log_write>
  brelse(bp);
    80003c5c:	854a                	mv	a0,s2
    80003c5e:	00000097          	auipc	ra,0x0
    80003c62:	980080e7          	jalr	-1664(ra) # 800035de <brelse>
}
    80003c66:	60e2                	ld	ra,24(sp)
    80003c68:	6442                	ld	s0,16(sp)
    80003c6a:	64a2                	ld	s1,8(sp)
    80003c6c:	6902                	ld	s2,0(sp)
    80003c6e:	6105                	addi	sp,sp,32
    80003c70:	8082                	ret

0000000080003c72 <idup>:
{
    80003c72:	1101                	addi	sp,sp,-32
    80003c74:	ec06                	sd	ra,24(sp)
    80003c76:	e822                	sd	s0,16(sp)
    80003c78:	e426                	sd	s1,8(sp)
    80003c7a:	1000                	addi	s0,sp,32
    80003c7c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c7e:	00015517          	auipc	a0,0x15
    80003c82:	eda50513          	addi	a0,a0,-294 # 80018b58 <itable>
    80003c86:	ffffd097          	auipc	ra,0xffffd
    80003c8a:	f5e080e7          	jalr	-162(ra) # 80000be4 <acquire>
  ip->ref++;
    80003c8e:	449c                	lw	a5,8(s1)
    80003c90:	2785                	addiw	a5,a5,1
    80003c92:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c94:	00015517          	auipc	a0,0x15
    80003c98:	ec450513          	addi	a0,a0,-316 # 80018b58 <itable>
    80003c9c:	ffffd097          	auipc	ra,0xffffd
    80003ca0:	ffc080e7          	jalr	-4(ra) # 80000c98 <release>
}
    80003ca4:	8526                	mv	a0,s1
    80003ca6:	60e2                	ld	ra,24(sp)
    80003ca8:	6442                	ld	s0,16(sp)
    80003caa:	64a2                	ld	s1,8(sp)
    80003cac:	6105                	addi	sp,sp,32
    80003cae:	8082                	ret

0000000080003cb0 <ilock>:
{
    80003cb0:	1101                	addi	sp,sp,-32
    80003cb2:	ec06                	sd	ra,24(sp)
    80003cb4:	e822                	sd	s0,16(sp)
    80003cb6:	e426                	sd	s1,8(sp)
    80003cb8:	e04a                	sd	s2,0(sp)
    80003cba:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003cbc:	c115                	beqz	a0,80003ce0 <ilock+0x30>
    80003cbe:	84aa                	mv	s1,a0
    80003cc0:	451c                	lw	a5,8(a0)
    80003cc2:	00f05f63          	blez	a5,80003ce0 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003cc6:	0541                	addi	a0,a0,16
    80003cc8:	00001097          	auipc	ra,0x1
    80003ccc:	cb2080e7          	jalr	-846(ra) # 8000497a <acquiresleep>
  if(ip->valid == 0){
    80003cd0:	40bc                	lw	a5,64(s1)
    80003cd2:	cf99                	beqz	a5,80003cf0 <ilock+0x40>
}
    80003cd4:	60e2                	ld	ra,24(sp)
    80003cd6:	6442                	ld	s0,16(sp)
    80003cd8:	64a2                	ld	s1,8(sp)
    80003cda:	6902                	ld	s2,0(sp)
    80003cdc:	6105                	addi	sp,sp,32
    80003cde:	8082                	ret
    panic("ilock");
    80003ce0:	00005517          	auipc	a0,0x5
    80003ce4:	9d050513          	addi	a0,a0,-1584 # 800086b0 <syscalls+0x198>
    80003ce8:	ffffd097          	auipc	ra,0xffffd
    80003cec:	856080e7          	jalr	-1962(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003cf0:	40dc                	lw	a5,4(s1)
    80003cf2:	0047d79b          	srliw	a5,a5,0x4
    80003cf6:	00015597          	auipc	a1,0x15
    80003cfa:	e5a5a583          	lw	a1,-422(a1) # 80018b50 <sb+0x18>
    80003cfe:	9dbd                	addw	a1,a1,a5
    80003d00:	4088                	lw	a0,0(s1)
    80003d02:	fffff097          	auipc	ra,0xfffff
    80003d06:	7ac080e7          	jalr	1964(ra) # 800034ae <bread>
    80003d0a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d0c:	05850593          	addi	a1,a0,88
    80003d10:	40dc                	lw	a5,4(s1)
    80003d12:	8bbd                	andi	a5,a5,15
    80003d14:	079a                	slli	a5,a5,0x6
    80003d16:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003d18:	00059783          	lh	a5,0(a1)
    80003d1c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003d20:	00259783          	lh	a5,2(a1)
    80003d24:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003d28:	00459783          	lh	a5,4(a1)
    80003d2c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003d30:	00659783          	lh	a5,6(a1)
    80003d34:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003d38:	459c                	lw	a5,8(a1)
    80003d3a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003d3c:	03400613          	li	a2,52
    80003d40:	05b1                	addi	a1,a1,12
    80003d42:	05048513          	addi	a0,s1,80
    80003d46:	ffffd097          	auipc	ra,0xffffd
    80003d4a:	ffa080e7          	jalr	-6(ra) # 80000d40 <memmove>
    brelse(bp);
    80003d4e:	854a                	mv	a0,s2
    80003d50:	00000097          	auipc	ra,0x0
    80003d54:	88e080e7          	jalr	-1906(ra) # 800035de <brelse>
    ip->valid = 1;
    80003d58:	4785                	li	a5,1
    80003d5a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003d5c:	04449783          	lh	a5,68(s1)
    80003d60:	fbb5                	bnez	a5,80003cd4 <ilock+0x24>
      panic("ilock: no type");
    80003d62:	00005517          	auipc	a0,0x5
    80003d66:	95650513          	addi	a0,a0,-1706 # 800086b8 <syscalls+0x1a0>
    80003d6a:	ffffc097          	auipc	ra,0xffffc
    80003d6e:	7d4080e7          	jalr	2004(ra) # 8000053e <panic>

0000000080003d72 <iunlock>:
{
    80003d72:	1101                	addi	sp,sp,-32
    80003d74:	ec06                	sd	ra,24(sp)
    80003d76:	e822                	sd	s0,16(sp)
    80003d78:	e426                	sd	s1,8(sp)
    80003d7a:	e04a                	sd	s2,0(sp)
    80003d7c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003d7e:	c905                	beqz	a0,80003dae <iunlock+0x3c>
    80003d80:	84aa                	mv	s1,a0
    80003d82:	01050913          	addi	s2,a0,16
    80003d86:	854a                	mv	a0,s2
    80003d88:	00001097          	auipc	ra,0x1
    80003d8c:	c8c080e7          	jalr	-884(ra) # 80004a14 <holdingsleep>
    80003d90:	cd19                	beqz	a0,80003dae <iunlock+0x3c>
    80003d92:	449c                	lw	a5,8(s1)
    80003d94:	00f05d63          	blez	a5,80003dae <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003d98:	854a                	mv	a0,s2
    80003d9a:	00001097          	auipc	ra,0x1
    80003d9e:	c36080e7          	jalr	-970(ra) # 800049d0 <releasesleep>
}
    80003da2:	60e2                	ld	ra,24(sp)
    80003da4:	6442                	ld	s0,16(sp)
    80003da6:	64a2                	ld	s1,8(sp)
    80003da8:	6902                	ld	s2,0(sp)
    80003daa:	6105                	addi	sp,sp,32
    80003dac:	8082                	ret
    panic("iunlock");
    80003dae:	00005517          	auipc	a0,0x5
    80003db2:	91a50513          	addi	a0,a0,-1766 # 800086c8 <syscalls+0x1b0>
    80003db6:	ffffc097          	auipc	ra,0xffffc
    80003dba:	788080e7          	jalr	1928(ra) # 8000053e <panic>

0000000080003dbe <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003dbe:	7179                	addi	sp,sp,-48
    80003dc0:	f406                	sd	ra,40(sp)
    80003dc2:	f022                	sd	s0,32(sp)
    80003dc4:	ec26                	sd	s1,24(sp)
    80003dc6:	e84a                	sd	s2,16(sp)
    80003dc8:	e44e                	sd	s3,8(sp)
    80003dca:	e052                	sd	s4,0(sp)
    80003dcc:	1800                	addi	s0,sp,48
    80003dce:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003dd0:	05050493          	addi	s1,a0,80
    80003dd4:	08050913          	addi	s2,a0,128
    80003dd8:	a021                	j	80003de0 <itrunc+0x22>
    80003dda:	0491                	addi	s1,s1,4
    80003ddc:	01248d63          	beq	s1,s2,80003df6 <itrunc+0x38>
    if(ip->addrs[i]){
    80003de0:	408c                	lw	a1,0(s1)
    80003de2:	dde5                	beqz	a1,80003dda <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003de4:	0009a503          	lw	a0,0(s3)
    80003de8:	00000097          	auipc	ra,0x0
    80003dec:	90c080e7          	jalr	-1780(ra) # 800036f4 <bfree>
      ip->addrs[i] = 0;
    80003df0:	0004a023          	sw	zero,0(s1)
    80003df4:	b7dd                	j	80003dda <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003df6:	0809a583          	lw	a1,128(s3)
    80003dfa:	e185                	bnez	a1,80003e1a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003dfc:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003e00:	854e                	mv	a0,s3
    80003e02:	00000097          	auipc	ra,0x0
    80003e06:	de4080e7          	jalr	-540(ra) # 80003be6 <iupdate>
}
    80003e0a:	70a2                	ld	ra,40(sp)
    80003e0c:	7402                	ld	s0,32(sp)
    80003e0e:	64e2                	ld	s1,24(sp)
    80003e10:	6942                	ld	s2,16(sp)
    80003e12:	69a2                	ld	s3,8(sp)
    80003e14:	6a02                	ld	s4,0(sp)
    80003e16:	6145                	addi	sp,sp,48
    80003e18:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003e1a:	0009a503          	lw	a0,0(s3)
    80003e1e:	fffff097          	auipc	ra,0xfffff
    80003e22:	690080e7          	jalr	1680(ra) # 800034ae <bread>
    80003e26:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003e28:	05850493          	addi	s1,a0,88
    80003e2c:	45850913          	addi	s2,a0,1112
    80003e30:	a811                	j	80003e44 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003e32:	0009a503          	lw	a0,0(s3)
    80003e36:	00000097          	auipc	ra,0x0
    80003e3a:	8be080e7          	jalr	-1858(ra) # 800036f4 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003e3e:	0491                	addi	s1,s1,4
    80003e40:	01248563          	beq	s1,s2,80003e4a <itrunc+0x8c>
      if(a[j])
    80003e44:	408c                	lw	a1,0(s1)
    80003e46:	dde5                	beqz	a1,80003e3e <itrunc+0x80>
    80003e48:	b7ed                	j	80003e32 <itrunc+0x74>
    brelse(bp);
    80003e4a:	8552                	mv	a0,s4
    80003e4c:	fffff097          	auipc	ra,0xfffff
    80003e50:	792080e7          	jalr	1938(ra) # 800035de <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003e54:	0809a583          	lw	a1,128(s3)
    80003e58:	0009a503          	lw	a0,0(s3)
    80003e5c:	00000097          	auipc	ra,0x0
    80003e60:	898080e7          	jalr	-1896(ra) # 800036f4 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003e64:	0809a023          	sw	zero,128(s3)
    80003e68:	bf51                	j	80003dfc <itrunc+0x3e>

0000000080003e6a <iput>:
{
    80003e6a:	1101                	addi	sp,sp,-32
    80003e6c:	ec06                	sd	ra,24(sp)
    80003e6e:	e822                	sd	s0,16(sp)
    80003e70:	e426                	sd	s1,8(sp)
    80003e72:	e04a                	sd	s2,0(sp)
    80003e74:	1000                	addi	s0,sp,32
    80003e76:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e78:	00015517          	auipc	a0,0x15
    80003e7c:	ce050513          	addi	a0,a0,-800 # 80018b58 <itable>
    80003e80:	ffffd097          	auipc	ra,0xffffd
    80003e84:	d64080e7          	jalr	-668(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e88:	4498                	lw	a4,8(s1)
    80003e8a:	4785                	li	a5,1
    80003e8c:	02f70363          	beq	a4,a5,80003eb2 <iput+0x48>
  ip->ref--;
    80003e90:	449c                	lw	a5,8(s1)
    80003e92:	37fd                	addiw	a5,a5,-1
    80003e94:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e96:	00015517          	auipc	a0,0x15
    80003e9a:	cc250513          	addi	a0,a0,-830 # 80018b58 <itable>
    80003e9e:	ffffd097          	auipc	ra,0xffffd
    80003ea2:	dfa080e7          	jalr	-518(ra) # 80000c98 <release>
}
    80003ea6:	60e2                	ld	ra,24(sp)
    80003ea8:	6442                	ld	s0,16(sp)
    80003eaa:	64a2                	ld	s1,8(sp)
    80003eac:	6902                	ld	s2,0(sp)
    80003eae:	6105                	addi	sp,sp,32
    80003eb0:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003eb2:	40bc                	lw	a5,64(s1)
    80003eb4:	dff1                	beqz	a5,80003e90 <iput+0x26>
    80003eb6:	04a49783          	lh	a5,74(s1)
    80003eba:	fbf9                	bnez	a5,80003e90 <iput+0x26>
    acquiresleep(&ip->lock);
    80003ebc:	01048913          	addi	s2,s1,16
    80003ec0:	854a                	mv	a0,s2
    80003ec2:	00001097          	auipc	ra,0x1
    80003ec6:	ab8080e7          	jalr	-1352(ra) # 8000497a <acquiresleep>
    release(&itable.lock);
    80003eca:	00015517          	auipc	a0,0x15
    80003ece:	c8e50513          	addi	a0,a0,-882 # 80018b58 <itable>
    80003ed2:	ffffd097          	auipc	ra,0xffffd
    80003ed6:	dc6080e7          	jalr	-570(ra) # 80000c98 <release>
    itrunc(ip);
    80003eda:	8526                	mv	a0,s1
    80003edc:	00000097          	auipc	ra,0x0
    80003ee0:	ee2080e7          	jalr	-286(ra) # 80003dbe <itrunc>
    ip->type = 0;
    80003ee4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003ee8:	8526                	mv	a0,s1
    80003eea:	00000097          	auipc	ra,0x0
    80003eee:	cfc080e7          	jalr	-772(ra) # 80003be6 <iupdate>
    ip->valid = 0;
    80003ef2:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003ef6:	854a                	mv	a0,s2
    80003ef8:	00001097          	auipc	ra,0x1
    80003efc:	ad8080e7          	jalr	-1320(ra) # 800049d0 <releasesleep>
    acquire(&itable.lock);
    80003f00:	00015517          	auipc	a0,0x15
    80003f04:	c5850513          	addi	a0,a0,-936 # 80018b58 <itable>
    80003f08:	ffffd097          	auipc	ra,0xffffd
    80003f0c:	cdc080e7          	jalr	-804(ra) # 80000be4 <acquire>
    80003f10:	b741                	j	80003e90 <iput+0x26>

0000000080003f12 <iunlockput>:
{
    80003f12:	1101                	addi	sp,sp,-32
    80003f14:	ec06                	sd	ra,24(sp)
    80003f16:	e822                	sd	s0,16(sp)
    80003f18:	e426                	sd	s1,8(sp)
    80003f1a:	1000                	addi	s0,sp,32
    80003f1c:	84aa                	mv	s1,a0
  iunlock(ip);
    80003f1e:	00000097          	auipc	ra,0x0
    80003f22:	e54080e7          	jalr	-428(ra) # 80003d72 <iunlock>
  iput(ip);
    80003f26:	8526                	mv	a0,s1
    80003f28:	00000097          	auipc	ra,0x0
    80003f2c:	f42080e7          	jalr	-190(ra) # 80003e6a <iput>
}
    80003f30:	60e2                	ld	ra,24(sp)
    80003f32:	6442                	ld	s0,16(sp)
    80003f34:	64a2                	ld	s1,8(sp)
    80003f36:	6105                	addi	sp,sp,32
    80003f38:	8082                	ret

0000000080003f3a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003f3a:	1141                	addi	sp,sp,-16
    80003f3c:	e422                	sd	s0,8(sp)
    80003f3e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003f40:	411c                	lw	a5,0(a0)
    80003f42:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003f44:	415c                	lw	a5,4(a0)
    80003f46:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003f48:	04451783          	lh	a5,68(a0)
    80003f4c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003f50:	04a51783          	lh	a5,74(a0)
    80003f54:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003f58:	04c56783          	lwu	a5,76(a0)
    80003f5c:	e99c                	sd	a5,16(a1)
}
    80003f5e:	6422                	ld	s0,8(sp)
    80003f60:	0141                	addi	sp,sp,16
    80003f62:	8082                	ret

0000000080003f64 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f64:	457c                	lw	a5,76(a0)
    80003f66:	0ed7e963          	bltu	a5,a3,80004058 <readi+0xf4>
{
    80003f6a:	7159                	addi	sp,sp,-112
    80003f6c:	f486                	sd	ra,104(sp)
    80003f6e:	f0a2                	sd	s0,96(sp)
    80003f70:	eca6                	sd	s1,88(sp)
    80003f72:	e8ca                	sd	s2,80(sp)
    80003f74:	e4ce                	sd	s3,72(sp)
    80003f76:	e0d2                	sd	s4,64(sp)
    80003f78:	fc56                	sd	s5,56(sp)
    80003f7a:	f85a                	sd	s6,48(sp)
    80003f7c:	f45e                	sd	s7,40(sp)
    80003f7e:	f062                	sd	s8,32(sp)
    80003f80:	ec66                	sd	s9,24(sp)
    80003f82:	e86a                	sd	s10,16(sp)
    80003f84:	e46e                	sd	s11,8(sp)
    80003f86:	1880                	addi	s0,sp,112
    80003f88:	8baa                	mv	s7,a0
    80003f8a:	8c2e                	mv	s8,a1
    80003f8c:	8ab2                	mv	s5,a2
    80003f8e:	84b6                	mv	s1,a3
    80003f90:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003f92:	9f35                	addw	a4,a4,a3
    return 0;
    80003f94:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003f96:	0ad76063          	bltu	a4,a3,80004036 <readi+0xd2>
  if(off + n > ip->size)
    80003f9a:	00e7f463          	bgeu	a5,a4,80003fa2 <readi+0x3e>
    n = ip->size - off;
    80003f9e:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fa2:	0a0b0963          	beqz	s6,80004054 <readi+0xf0>
    80003fa6:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fa8:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003fac:	5cfd                	li	s9,-1
    80003fae:	a82d                	j	80003fe8 <readi+0x84>
    80003fb0:	020a1d93          	slli	s11,s4,0x20
    80003fb4:	020ddd93          	srli	s11,s11,0x20
    80003fb8:	05890613          	addi	a2,s2,88
    80003fbc:	86ee                	mv	a3,s11
    80003fbe:	963a                	add	a2,a2,a4
    80003fc0:	85d6                	mv	a1,s5
    80003fc2:	8562                	mv	a0,s8
    80003fc4:	fffff097          	auipc	ra,0xfffff
    80003fc8:	9f4080e7          	jalr	-1548(ra) # 800029b8 <either_copyout>
    80003fcc:	05950d63          	beq	a0,s9,80004026 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003fd0:	854a                	mv	a0,s2
    80003fd2:	fffff097          	auipc	ra,0xfffff
    80003fd6:	60c080e7          	jalr	1548(ra) # 800035de <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fda:	013a09bb          	addw	s3,s4,s3
    80003fde:	009a04bb          	addw	s1,s4,s1
    80003fe2:	9aee                	add	s5,s5,s11
    80003fe4:	0569f763          	bgeu	s3,s6,80004032 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003fe8:	000ba903          	lw	s2,0(s7)
    80003fec:	00a4d59b          	srliw	a1,s1,0xa
    80003ff0:	855e                	mv	a0,s7
    80003ff2:	00000097          	auipc	ra,0x0
    80003ff6:	8b0080e7          	jalr	-1872(ra) # 800038a2 <bmap>
    80003ffa:	0005059b          	sext.w	a1,a0
    80003ffe:	854a                	mv	a0,s2
    80004000:	fffff097          	auipc	ra,0xfffff
    80004004:	4ae080e7          	jalr	1198(ra) # 800034ae <bread>
    80004008:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000400a:	3ff4f713          	andi	a4,s1,1023
    8000400e:	40ed07bb          	subw	a5,s10,a4
    80004012:	413b06bb          	subw	a3,s6,s3
    80004016:	8a3e                	mv	s4,a5
    80004018:	2781                	sext.w	a5,a5
    8000401a:	0006861b          	sext.w	a2,a3
    8000401e:	f8f679e3          	bgeu	a2,a5,80003fb0 <readi+0x4c>
    80004022:	8a36                	mv	s4,a3
    80004024:	b771                	j	80003fb0 <readi+0x4c>
      brelse(bp);
    80004026:	854a                	mv	a0,s2
    80004028:	fffff097          	auipc	ra,0xfffff
    8000402c:	5b6080e7          	jalr	1462(ra) # 800035de <brelse>
      tot = -1;
    80004030:	59fd                	li	s3,-1
  }
  return tot;
    80004032:	0009851b          	sext.w	a0,s3
}
    80004036:	70a6                	ld	ra,104(sp)
    80004038:	7406                	ld	s0,96(sp)
    8000403a:	64e6                	ld	s1,88(sp)
    8000403c:	6946                	ld	s2,80(sp)
    8000403e:	69a6                	ld	s3,72(sp)
    80004040:	6a06                	ld	s4,64(sp)
    80004042:	7ae2                	ld	s5,56(sp)
    80004044:	7b42                	ld	s6,48(sp)
    80004046:	7ba2                	ld	s7,40(sp)
    80004048:	7c02                	ld	s8,32(sp)
    8000404a:	6ce2                	ld	s9,24(sp)
    8000404c:	6d42                	ld	s10,16(sp)
    8000404e:	6da2                	ld	s11,8(sp)
    80004050:	6165                	addi	sp,sp,112
    80004052:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004054:	89da                	mv	s3,s6
    80004056:	bff1                	j	80004032 <readi+0xce>
    return 0;
    80004058:	4501                	li	a0,0
}
    8000405a:	8082                	ret

000000008000405c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000405c:	457c                	lw	a5,76(a0)
    8000405e:	10d7e863          	bltu	a5,a3,8000416e <writei+0x112>
{
    80004062:	7159                	addi	sp,sp,-112
    80004064:	f486                	sd	ra,104(sp)
    80004066:	f0a2                	sd	s0,96(sp)
    80004068:	eca6                	sd	s1,88(sp)
    8000406a:	e8ca                	sd	s2,80(sp)
    8000406c:	e4ce                	sd	s3,72(sp)
    8000406e:	e0d2                	sd	s4,64(sp)
    80004070:	fc56                	sd	s5,56(sp)
    80004072:	f85a                	sd	s6,48(sp)
    80004074:	f45e                	sd	s7,40(sp)
    80004076:	f062                	sd	s8,32(sp)
    80004078:	ec66                	sd	s9,24(sp)
    8000407a:	e86a                	sd	s10,16(sp)
    8000407c:	e46e                	sd	s11,8(sp)
    8000407e:	1880                	addi	s0,sp,112
    80004080:	8b2a                	mv	s6,a0
    80004082:	8c2e                	mv	s8,a1
    80004084:	8ab2                	mv	s5,a2
    80004086:	8936                	mv	s2,a3
    80004088:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    8000408a:	00e687bb          	addw	a5,a3,a4
    8000408e:	0ed7e263          	bltu	a5,a3,80004172 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004092:	00043737          	lui	a4,0x43
    80004096:	0ef76063          	bltu	a4,a5,80004176 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000409a:	0c0b8863          	beqz	s7,8000416a <writei+0x10e>
    8000409e:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800040a0:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800040a4:	5cfd                	li	s9,-1
    800040a6:	a091                	j	800040ea <writei+0x8e>
    800040a8:	02099d93          	slli	s11,s3,0x20
    800040ac:	020ddd93          	srli	s11,s11,0x20
    800040b0:	05848513          	addi	a0,s1,88
    800040b4:	86ee                	mv	a3,s11
    800040b6:	8656                	mv	a2,s5
    800040b8:	85e2                	mv	a1,s8
    800040ba:	953a                	add	a0,a0,a4
    800040bc:	fffff097          	auipc	ra,0xfffff
    800040c0:	952080e7          	jalr	-1710(ra) # 80002a0e <either_copyin>
    800040c4:	07950263          	beq	a0,s9,80004128 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800040c8:	8526                	mv	a0,s1
    800040ca:	00000097          	auipc	ra,0x0
    800040ce:	790080e7          	jalr	1936(ra) # 8000485a <log_write>
    brelse(bp);
    800040d2:	8526                	mv	a0,s1
    800040d4:	fffff097          	auipc	ra,0xfffff
    800040d8:	50a080e7          	jalr	1290(ra) # 800035de <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040dc:	01498a3b          	addw	s4,s3,s4
    800040e0:	0129893b          	addw	s2,s3,s2
    800040e4:	9aee                	add	s5,s5,s11
    800040e6:	057a7663          	bgeu	s4,s7,80004132 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800040ea:	000b2483          	lw	s1,0(s6)
    800040ee:	00a9559b          	srliw	a1,s2,0xa
    800040f2:	855a                	mv	a0,s6
    800040f4:	fffff097          	auipc	ra,0xfffff
    800040f8:	7ae080e7          	jalr	1966(ra) # 800038a2 <bmap>
    800040fc:	0005059b          	sext.w	a1,a0
    80004100:	8526                	mv	a0,s1
    80004102:	fffff097          	auipc	ra,0xfffff
    80004106:	3ac080e7          	jalr	940(ra) # 800034ae <bread>
    8000410a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000410c:	3ff97713          	andi	a4,s2,1023
    80004110:	40ed07bb          	subw	a5,s10,a4
    80004114:	414b86bb          	subw	a3,s7,s4
    80004118:	89be                	mv	s3,a5
    8000411a:	2781                	sext.w	a5,a5
    8000411c:	0006861b          	sext.w	a2,a3
    80004120:	f8f674e3          	bgeu	a2,a5,800040a8 <writei+0x4c>
    80004124:	89b6                	mv	s3,a3
    80004126:	b749                	j	800040a8 <writei+0x4c>
      brelse(bp);
    80004128:	8526                	mv	a0,s1
    8000412a:	fffff097          	auipc	ra,0xfffff
    8000412e:	4b4080e7          	jalr	1204(ra) # 800035de <brelse>
  }

  if(off > ip->size)
    80004132:	04cb2783          	lw	a5,76(s6)
    80004136:	0127f463          	bgeu	a5,s2,8000413e <writei+0xe2>
    ip->size = off;
    8000413a:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000413e:	855a                	mv	a0,s6
    80004140:	00000097          	auipc	ra,0x0
    80004144:	aa6080e7          	jalr	-1370(ra) # 80003be6 <iupdate>

  return tot;
    80004148:	000a051b          	sext.w	a0,s4
}
    8000414c:	70a6                	ld	ra,104(sp)
    8000414e:	7406                	ld	s0,96(sp)
    80004150:	64e6                	ld	s1,88(sp)
    80004152:	6946                	ld	s2,80(sp)
    80004154:	69a6                	ld	s3,72(sp)
    80004156:	6a06                	ld	s4,64(sp)
    80004158:	7ae2                	ld	s5,56(sp)
    8000415a:	7b42                	ld	s6,48(sp)
    8000415c:	7ba2                	ld	s7,40(sp)
    8000415e:	7c02                	ld	s8,32(sp)
    80004160:	6ce2                	ld	s9,24(sp)
    80004162:	6d42                	ld	s10,16(sp)
    80004164:	6da2                	ld	s11,8(sp)
    80004166:	6165                	addi	sp,sp,112
    80004168:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000416a:	8a5e                	mv	s4,s7
    8000416c:	bfc9                	j	8000413e <writei+0xe2>
    return -1;
    8000416e:	557d                	li	a0,-1
}
    80004170:	8082                	ret
    return -1;
    80004172:	557d                	li	a0,-1
    80004174:	bfe1                	j	8000414c <writei+0xf0>
    return -1;
    80004176:	557d                	li	a0,-1
    80004178:	bfd1                	j	8000414c <writei+0xf0>

000000008000417a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000417a:	1141                	addi	sp,sp,-16
    8000417c:	e406                	sd	ra,8(sp)
    8000417e:	e022                	sd	s0,0(sp)
    80004180:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004182:	4639                	li	a2,14
    80004184:	ffffd097          	auipc	ra,0xffffd
    80004188:	c34080e7          	jalr	-972(ra) # 80000db8 <strncmp>
}
    8000418c:	60a2                	ld	ra,8(sp)
    8000418e:	6402                	ld	s0,0(sp)
    80004190:	0141                	addi	sp,sp,16
    80004192:	8082                	ret

0000000080004194 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004194:	7139                	addi	sp,sp,-64
    80004196:	fc06                	sd	ra,56(sp)
    80004198:	f822                	sd	s0,48(sp)
    8000419a:	f426                	sd	s1,40(sp)
    8000419c:	f04a                	sd	s2,32(sp)
    8000419e:	ec4e                	sd	s3,24(sp)
    800041a0:	e852                	sd	s4,16(sp)
    800041a2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800041a4:	04451703          	lh	a4,68(a0)
    800041a8:	4785                	li	a5,1
    800041aa:	00f71a63          	bne	a4,a5,800041be <dirlookup+0x2a>
    800041ae:	892a                	mv	s2,a0
    800041b0:	89ae                	mv	s3,a1
    800041b2:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800041b4:	457c                	lw	a5,76(a0)
    800041b6:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800041b8:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041ba:	e79d                	bnez	a5,800041e8 <dirlookup+0x54>
    800041bc:	a8a5                	j	80004234 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800041be:	00004517          	auipc	a0,0x4
    800041c2:	51250513          	addi	a0,a0,1298 # 800086d0 <syscalls+0x1b8>
    800041c6:	ffffc097          	auipc	ra,0xffffc
    800041ca:	378080e7          	jalr	888(ra) # 8000053e <panic>
      panic("dirlookup read");
    800041ce:	00004517          	auipc	a0,0x4
    800041d2:	51a50513          	addi	a0,a0,1306 # 800086e8 <syscalls+0x1d0>
    800041d6:	ffffc097          	auipc	ra,0xffffc
    800041da:	368080e7          	jalr	872(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041de:	24c1                	addiw	s1,s1,16
    800041e0:	04c92783          	lw	a5,76(s2)
    800041e4:	04f4f763          	bgeu	s1,a5,80004232 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041e8:	4741                	li	a4,16
    800041ea:	86a6                	mv	a3,s1
    800041ec:	fc040613          	addi	a2,s0,-64
    800041f0:	4581                	li	a1,0
    800041f2:	854a                	mv	a0,s2
    800041f4:	00000097          	auipc	ra,0x0
    800041f8:	d70080e7          	jalr	-656(ra) # 80003f64 <readi>
    800041fc:	47c1                	li	a5,16
    800041fe:	fcf518e3          	bne	a0,a5,800041ce <dirlookup+0x3a>
    if(de.inum == 0)
    80004202:	fc045783          	lhu	a5,-64(s0)
    80004206:	dfe1                	beqz	a5,800041de <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004208:	fc240593          	addi	a1,s0,-62
    8000420c:	854e                	mv	a0,s3
    8000420e:	00000097          	auipc	ra,0x0
    80004212:	f6c080e7          	jalr	-148(ra) # 8000417a <namecmp>
    80004216:	f561                	bnez	a0,800041de <dirlookup+0x4a>
      if(poff)
    80004218:	000a0463          	beqz	s4,80004220 <dirlookup+0x8c>
        *poff = off;
    8000421c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004220:	fc045583          	lhu	a1,-64(s0)
    80004224:	00092503          	lw	a0,0(s2)
    80004228:	fffff097          	auipc	ra,0xfffff
    8000422c:	754080e7          	jalr	1876(ra) # 8000397c <iget>
    80004230:	a011                	j	80004234 <dirlookup+0xa0>
  return 0;
    80004232:	4501                	li	a0,0
}
    80004234:	70e2                	ld	ra,56(sp)
    80004236:	7442                	ld	s0,48(sp)
    80004238:	74a2                	ld	s1,40(sp)
    8000423a:	7902                	ld	s2,32(sp)
    8000423c:	69e2                	ld	s3,24(sp)
    8000423e:	6a42                	ld	s4,16(sp)
    80004240:	6121                	addi	sp,sp,64
    80004242:	8082                	ret

0000000080004244 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004244:	711d                	addi	sp,sp,-96
    80004246:	ec86                	sd	ra,88(sp)
    80004248:	e8a2                	sd	s0,80(sp)
    8000424a:	e4a6                	sd	s1,72(sp)
    8000424c:	e0ca                	sd	s2,64(sp)
    8000424e:	fc4e                	sd	s3,56(sp)
    80004250:	f852                	sd	s4,48(sp)
    80004252:	f456                	sd	s5,40(sp)
    80004254:	f05a                	sd	s6,32(sp)
    80004256:	ec5e                	sd	s7,24(sp)
    80004258:	e862                	sd	s8,16(sp)
    8000425a:	e466                	sd	s9,8(sp)
    8000425c:	1080                	addi	s0,sp,96
    8000425e:	84aa                	mv	s1,a0
    80004260:	8b2e                	mv	s6,a1
    80004262:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004264:	00054703          	lbu	a4,0(a0)
    80004268:	02f00793          	li	a5,47
    8000426c:	02f70363          	beq	a4,a5,80004292 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004270:	ffffd097          	auipc	ra,0xffffd
    80004274:	758080e7          	jalr	1880(ra) # 800019c8 <myproc>
    80004278:	15053503          	ld	a0,336(a0)
    8000427c:	00000097          	auipc	ra,0x0
    80004280:	9f6080e7          	jalr	-1546(ra) # 80003c72 <idup>
    80004284:	89aa                	mv	s3,a0
  while(*path == '/')
    80004286:	02f00913          	li	s2,47
  len = path - s;
    8000428a:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    8000428c:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000428e:	4c05                	li	s8,1
    80004290:	a865                	j	80004348 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004292:	4585                	li	a1,1
    80004294:	4505                	li	a0,1
    80004296:	fffff097          	auipc	ra,0xfffff
    8000429a:	6e6080e7          	jalr	1766(ra) # 8000397c <iget>
    8000429e:	89aa                	mv	s3,a0
    800042a0:	b7dd                	j	80004286 <namex+0x42>
      iunlockput(ip);
    800042a2:	854e                	mv	a0,s3
    800042a4:	00000097          	auipc	ra,0x0
    800042a8:	c6e080e7          	jalr	-914(ra) # 80003f12 <iunlockput>
      return 0;
    800042ac:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800042ae:	854e                	mv	a0,s3
    800042b0:	60e6                	ld	ra,88(sp)
    800042b2:	6446                	ld	s0,80(sp)
    800042b4:	64a6                	ld	s1,72(sp)
    800042b6:	6906                	ld	s2,64(sp)
    800042b8:	79e2                	ld	s3,56(sp)
    800042ba:	7a42                	ld	s4,48(sp)
    800042bc:	7aa2                	ld	s5,40(sp)
    800042be:	7b02                	ld	s6,32(sp)
    800042c0:	6be2                	ld	s7,24(sp)
    800042c2:	6c42                	ld	s8,16(sp)
    800042c4:	6ca2                	ld	s9,8(sp)
    800042c6:	6125                	addi	sp,sp,96
    800042c8:	8082                	ret
      iunlock(ip);
    800042ca:	854e                	mv	a0,s3
    800042cc:	00000097          	auipc	ra,0x0
    800042d0:	aa6080e7          	jalr	-1370(ra) # 80003d72 <iunlock>
      return ip;
    800042d4:	bfe9                	j	800042ae <namex+0x6a>
      iunlockput(ip);
    800042d6:	854e                	mv	a0,s3
    800042d8:	00000097          	auipc	ra,0x0
    800042dc:	c3a080e7          	jalr	-966(ra) # 80003f12 <iunlockput>
      return 0;
    800042e0:	89d2                	mv	s3,s4
    800042e2:	b7f1                	j	800042ae <namex+0x6a>
  len = path - s;
    800042e4:	40b48633          	sub	a2,s1,a1
    800042e8:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800042ec:	094cd463          	bge	s9,s4,80004374 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800042f0:	4639                	li	a2,14
    800042f2:	8556                	mv	a0,s5
    800042f4:	ffffd097          	auipc	ra,0xffffd
    800042f8:	a4c080e7          	jalr	-1460(ra) # 80000d40 <memmove>
  while(*path == '/')
    800042fc:	0004c783          	lbu	a5,0(s1)
    80004300:	01279763          	bne	a5,s2,8000430e <namex+0xca>
    path++;
    80004304:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004306:	0004c783          	lbu	a5,0(s1)
    8000430a:	ff278de3          	beq	a5,s2,80004304 <namex+0xc0>
    ilock(ip);
    8000430e:	854e                	mv	a0,s3
    80004310:	00000097          	auipc	ra,0x0
    80004314:	9a0080e7          	jalr	-1632(ra) # 80003cb0 <ilock>
    if(ip->type != T_DIR){
    80004318:	04499783          	lh	a5,68(s3)
    8000431c:	f98793e3          	bne	a5,s8,800042a2 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004320:	000b0563          	beqz	s6,8000432a <namex+0xe6>
    80004324:	0004c783          	lbu	a5,0(s1)
    80004328:	d3cd                	beqz	a5,800042ca <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000432a:	865e                	mv	a2,s7
    8000432c:	85d6                	mv	a1,s5
    8000432e:	854e                	mv	a0,s3
    80004330:	00000097          	auipc	ra,0x0
    80004334:	e64080e7          	jalr	-412(ra) # 80004194 <dirlookup>
    80004338:	8a2a                	mv	s4,a0
    8000433a:	dd51                	beqz	a0,800042d6 <namex+0x92>
    iunlockput(ip);
    8000433c:	854e                	mv	a0,s3
    8000433e:	00000097          	auipc	ra,0x0
    80004342:	bd4080e7          	jalr	-1068(ra) # 80003f12 <iunlockput>
    ip = next;
    80004346:	89d2                	mv	s3,s4
  while(*path == '/')
    80004348:	0004c783          	lbu	a5,0(s1)
    8000434c:	05279763          	bne	a5,s2,8000439a <namex+0x156>
    path++;
    80004350:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004352:	0004c783          	lbu	a5,0(s1)
    80004356:	ff278de3          	beq	a5,s2,80004350 <namex+0x10c>
  if(*path == 0)
    8000435a:	c79d                	beqz	a5,80004388 <namex+0x144>
    path++;
    8000435c:	85a6                	mv	a1,s1
  len = path - s;
    8000435e:	8a5e                	mv	s4,s7
    80004360:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004362:	01278963          	beq	a5,s2,80004374 <namex+0x130>
    80004366:	dfbd                	beqz	a5,800042e4 <namex+0xa0>
    path++;
    80004368:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000436a:	0004c783          	lbu	a5,0(s1)
    8000436e:	ff279ce3          	bne	a5,s2,80004366 <namex+0x122>
    80004372:	bf8d                	j	800042e4 <namex+0xa0>
    memmove(name, s, len);
    80004374:	2601                	sext.w	a2,a2
    80004376:	8556                	mv	a0,s5
    80004378:	ffffd097          	auipc	ra,0xffffd
    8000437c:	9c8080e7          	jalr	-1592(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004380:	9a56                	add	s4,s4,s5
    80004382:	000a0023          	sb	zero,0(s4)
    80004386:	bf9d                	j	800042fc <namex+0xb8>
  if(nameiparent){
    80004388:	f20b03e3          	beqz	s6,800042ae <namex+0x6a>
    iput(ip);
    8000438c:	854e                	mv	a0,s3
    8000438e:	00000097          	auipc	ra,0x0
    80004392:	adc080e7          	jalr	-1316(ra) # 80003e6a <iput>
    return 0;
    80004396:	4981                	li	s3,0
    80004398:	bf19                	j	800042ae <namex+0x6a>
  if(*path == 0)
    8000439a:	d7fd                	beqz	a5,80004388 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000439c:	0004c783          	lbu	a5,0(s1)
    800043a0:	85a6                	mv	a1,s1
    800043a2:	b7d1                	j	80004366 <namex+0x122>

00000000800043a4 <dirlink>:
{
    800043a4:	7139                	addi	sp,sp,-64
    800043a6:	fc06                	sd	ra,56(sp)
    800043a8:	f822                	sd	s0,48(sp)
    800043aa:	f426                	sd	s1,40(sp)
    800043ac:	f04a                	sd	s2,32(sp)
    800043ae:	ec4e                	sd	s3,24(sp)
    800043b0:	e852                	sd	s4,16(sp)
    800043b2:	0080                	addi	s0,sp,64
    800043b4:	892a                	mv	s2,a0
    800043b6:	8a2e                	mv	s4,a1
    800043b8:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800043ba:	4601                	li	a2,0
    800043bc:	00000097          	auipc	ra,0x0
    800043c0:	dd8080e7          	jalr	-552(ra) # 80004194 <dirlookup>
    800043c4:	e93d                	bnez	a0,8000443a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043c6:	04c92483          	lw	s1,76(s2)
    800043ca:	c49d                	beqz	s1,800043f8 <dirlink+0x54>
    800043cc:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043ce:	4741                	li	a4,16
    800043d0:	86a6                	mv	a3,s1
    800043d2:	fc040613          	addi	a2,s0,-64
    800043d6:	4581                	li	a1,0
    800043d8:	854a                	mv	a0,s2
    800043da:	00000097          	auipc	ra,0x0
    800043de:	b8a080e7          	jalr	-1142(ra) # 80003f64 <readi>
    800043e2:	47c1                	li	a5,16
    800043e4:	06f51163          	bne	a0,a5,80004446 <dirlink+0xa2>
    if(de.inum == 0)
    800043e8:	fc045783          	lhu	a5,-64(s0)
    800043ec:	c791                	beqz	a5,800043f8 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043ee:	24c1                	addiw	s1,s1,16
    800043f0:	04c92783          	lw	a5,76(s2)
    800043f4:	fcf4ede3          	bltu	s1,a5,800043ce <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800043f8:	4639                	li	a2,14
    800043fa:	85d2                	mv	a1,s4
    800043fc:	fc240513          	addi	a0,s0,-62
    80004400:	ffffd097          	auipc	ra,0xffffd
    80004404:	9f4080e7          	jalr	-1548(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004408:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000440c:	4741                	li	a4,16
    8000440e:	86a6                	mv	a3,s1
    80004410:	fc040613          	addi	a2,s0,-64
    80004414:	4581                	li	a1,0
    80004416:	854a                	mv	a0,s2
    80004418:	00000097          	auipc	ra,0x0
    8000441c:	c44080e7          	jalr	-956(ra) # 8000405c <writei>
    80004420:	872a                	mv	a4,a0
    80004422:	47c1                	li	a5,16
  return 0;
    80004424:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004426:	02f71863          	bne	a4,a5,80004456 <dirlink+0xb2>
}
    8000442a:	70e2                	ld	ra,56(sp)
    8000442c:	7442                	ld	s0,48(sp)
    8000442e:	74a2                	ld	s1,40(sp)
    80004430:	7902                	ld	s2,32(sp)
    80004432:	69e2                	ld	s3,24(sp)
    80004434:	6a42                	ld	s4,16(sp)
    80004436:	6121                	addi	sp,sp,64
    80004438:	8082                	ret
    iput(ip);
    8000443a:	00000097          	auipc	ra,0x0
    8000443e:	a30080e7          	jalr	-1488(ra) # 80003e6a <iput>
    return -1;
    80004442:	557d                	li	a0,-1
    80004444:	b7dd                	j	8000442a <dirlink+0x86>
      panic("dirlink read");
    80004446:	00004517          	auipc	a0,0x4
    8000444a:	2b250513          	addi	a0,a0,690 # 800086f8 <syscalls+0x1e0>
    8000444e:	ffffc097          	auipc	ra,0xffffc
    80004452:	0f0080e7          	jalr	240(ra) # 8000053e <panic>
    panic("dirlink");
    80004456:	00004517          	auipc	a0,0x4
    8000445a:	3b250513          	addi	a0,a0,946 # 80008808 <syscalls+0x2f0>
    8000445e:	ffffc097          	auipc	ra,0xffffc
    80004462:	0e0080e7          	jalr	224(ra) # 8000053e <panic>

0000000080004466 <namei>:

struct inode*
namei(char *path)
{
    80004466:	1101                	addi	sp,sp,-32
    80004468:	ec06                	sd	ra,24(sp)
    8000446a:	e822                	sd	s0,16(sp)
    8000446c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000446e:	fe040613          	addi	a2,s0,-32
    80004472:	4581                	li	a1,0
    80004474:	00000097          	auipc	ra,0x0
    80004478:	dd0080e7          	jalr	-560(ra) # 80004244 <namex>
}
    8000447c:	60e2                	ld	ra,24(sp)
    8000447e:	6442                	ld	s0,16(sp)
    80004480:	6105                	addi	sp,sp,32
    80004482:	8082                	ret

0000000080004484 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004484:	1141                	addi	sp,sp,-16
    80004486:	e406                	sd	ra,8(sp)
    80004488:	e022                	sd	s0,0(sp)
    8000448a:	0800                	addi	s0,sp,16
    8000448c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000448e:	4585                	li	a1,1
    80004490:	00000097          	auipc	ra,0x0
    80004494:	db4080e7          	jalr	-588(ra) # 80004244 <namex>
}
    80004498:	60a2                	ld	ra,8(sp)
    8000449a:	6402                	ld	s0,0(sp)
    8000449c:	0141                	addi	sp,sp,16
    8000449e:	8082                	ret

00000000800044a0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800044a0:	1101                	addi	sp,sp,-32
    800044a2:	ec06                	sd	ra,24(sp)
    800044a4:	e822                	sd	s0,16(sp)
    800044a6:	e426                	sd	s1,8(sp)
    800044a8:	e04a                	sd	s2,0(sp)
    800044aa:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800044ac:	00016917          	auipc	s2,0x16
    800044b0:	15490913          	addi	s2,s2,340 # 8001a600 <log>
    800044b4:	01892583          	lw	a1,24(s2)
    800044b8:	02892503          	lw	a0,40(s2)
    800044bc:	fffff097          	auipc	ra,0xfffff
    800044c0:	ff2080e7          	jalr	-14(ra) # 800034ae <bread>
    800044c4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800044c6:	02c92683          	lw	a3,44(s2)
    800044ca:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800044cc:	02d05763          	blez	a3,800044fa <write_head+0x5a>
    800044d0:	00016797          	auipc	a5,0x16
    800044d4:	16078793          	addi	a5,a5,352 # 8001a630 <log+0x30>
    800044d8:	05c50713          	addi	a4,a0,92
    800044dc:	36fd                	addiw	a3,a3,-1
    800044de:	1682                	slli	a3,a3,0x20
    800044e0:	9281                	srli	a3,a3,0x20
    800044e2:	068a                	slli	a3,a3,0x2
    800044e4:	00016617          	auipc	a2,0x16
    800044e8:	15060613          	addi	a2,a2,336 # 8001a634 <log+0x34>
    800044ec:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800044ee:	4390                	lw	a2,0(a5)
    800044f0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800044f2:	0791                	addi	a5,a5,4
    800044f4:	0711                	addi	a4,a4,4
    800044f6:	fed79ce3          	bne	a5,a3,800044ee <write_head+0x4e>
  }
  bwrite(buf);
    800044fa:	8526                	mv	a0,s1
    800044fc:	fffff097          	auipc	ra,0xfffff
    80004500:	0a4080e7          	jalr	164(ra) # 800035a0 <bwrite>
  brelse(buf);
    80004504:	8526                	mv	a0,s1
    80004506:	fffff097          	auipc	ra,0xfffff
    8000450a:	0d8080e7          	jalr	216(ra) # 800035de <brelse>
}
    8000450e:	60e2                	ld	ra,24(sp)
    80004510:	6442                	ld	s0,16(sp)
    80004512:	64a2                	ld	s1,8(sp)
    80004514:	6902                	ld	s2,0(sp)
    80004516:	6105                	addi	sp,sp,32
    80004518:	8082                	ret

000000008000451a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000451a:	00016797          	auipc	a5,0x16
    8000451e:	1127a783          	lw	a5,274(a5) # 8001a62c <log+0x2c>
    80004522:	0af05d63          	blez	a5,800045dc <install_trans+0xc2>
{
    80004526:	7139                	addi	sp,sp,-64
    80004528:	fc06                	sd	ra,56(sp)
    8000452a:	f822                	sd	s0,48(sp)
    8000452c:	f426                	sd	s1,40(sp)
    8000452e:	f04a                	sd	s2,32(sp)
    80004530:	ec4e                	sd	s3,24(sp)
    80004532:	e852                	sd	s4,16(sp)
    80004534:	e456                	sd	s5,8(sp)
    80004536:	e05a                	sd	s6,0(sp)
    80004538:	0080                	addi	s0,sp,64
    8000453a:	8b2a                	mv	s6,a0
    8000453c:	00016a97          	auipc	s5,0x16
    80004540:	0f4a8a93          	addi	s5,s5,244 # 8001a630 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004544:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004546:	00016997          	auipc	s3,0x16
    8000454a:	0ba98993          	addi	s3,s3,186 # 8001a600 <log>
    8000454e:	a035                	j	8000457a <install_trans+0x60>
      bunpin(dbuf);
    80004550:	8526                	mv	a0,s1
    80004552:	fffff097          	auipc	ra,0xfffff
    80004556:	166080e7          	jalr	358(ra) # 800036b8 <bunpin>
    brelse(lbuf);
    8000455a:	854a                	mv	a0,s2
    8000455c:	fffff097          	auipc	ra,0xfffff
    80004560:	082080e7          	jalr	130(ra) # 800035de <brelse>
    brelse(dbuf);
    80004564:	8526                	mv	a0,s1
    80004566:	fffff097          	auipc	ra,0xfffff
    8000456a:	078080e7          	jalr	120(ra) # 800035de <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000456e:	2a05                	addiw	s4,s4,1
    80004570:	0a91                	addi	s5,s5,4
    80004572:	02c9a783          	lw	a5,44(s3)
    80004576:	04fa5963          	bge	s4,a5,800045c8 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000457a:	0189a583          	lw	a1,24(s3)
    8000457e:	014585bb          	addw	a1,a1,s4
    80004582:	2585                	addiw	a1,a1,1
    80004584:	0289a503          	lw	a0,40(s3)
    80004588:	fffff097          	auipc	ra,0xfffff
    8000458c:	f26080e7          	jalr	-218(ra) # 800034ae <bread>
    80004590:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004592:	000aa583          	lw	a1,0(s5)
    80004596:	0289a503          	lw	a0,40(s3)
    8000459a:	fffff097          	auipc	ra,0xfffff
    8000459e:	f14080e7          	jalr	-236(ra) # 800034ae <bread>
    800045a2:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800045a4:	40000613          	li	a2,1024
    800045a8:	05890593          	addi	a1,s2,88
    800045ac:	05850513          	addi	a0,a0,88
    800045b0:	ffffc097          	auipc	ra,0xffffc
    800045b4:	790080e7          	jalr	1936(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800045b8:	8526                	mv	a0,s1
    800045ba:	fffff097          	auipc	ra,0xfffff
    800045be:	fe6080e7          	jalr	-26(ra) # 800035a0 <bwrite>
    if(recovering == 0)
    800045c2:	f80b1ce3          	bnez	s6,8000455a <install_trans+0x40>
    800045c6:	b769                	j	80004550 <install_trans+0x36>
}
    800045c8:	70e2                	ld	ra,56(sp)
    800045ca:	7442                	ld	s0,48(sp)
    800045cc:	74a2                	ld	s1,40(sp)
    800045ce:	7902                	ld	s2,32(sp)
    800045d0:	69e2                	ld	s3,24(sp)
    800045d2:	6a42                	ld	s4,16(sp)
    800045d4:	6aa2                	ld	s5,8(sp)
    800045d6:	6b02                	ld	s6,0(sp)
    800045d8:	6121                	addi	sp,sp,64
    800045da:	8082                	ret
    800045dc:	8082                	ret

00000000800045de <initlog>:
{
    800045de:	7179                	addi	sp,sp,-48
    800045e0:	f406                	sd	ra,40(sp)
    800045e2:	f022                	sd	s0,32(sp)
    800045e4:	ec26                	sd	s1,24(sp)
    800045e6:	e84a                	sd	s2,16(sp)
    800045e8:	e44e                	sd	s3,8(sp)
    800045ea:	1800                	addi	s0,sp,48
    800045ec:	892a                	mv	s2,a0
    800045ee:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800045f0:	00016497          	auipc	s1,0x16
    800045f4:	01048493          	addi	s1,s1,16 # 8001a600 <log>
    800045f8:	00004597          	auipc	a1,0x4
    800045fc:	11058593          	addi	a1,a1,272 # 80008708 <syscalls+0x1f0>
    80004600:	8526                	mv	a0,s1
    80004602:	ffffc097          	auipc	ra,0xffffc
    80004606:	552080e7          	jalr	1362(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000460a:	0149a583          	lw	a1,20(s3)
    8000460e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004610:	0109a783          	lw	a5,16(s3)
    80004614:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004616:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000461a:	854a                	mv	a0,s2
    8000461c:	fffff097          	auipc	ra,0xfffff
    80004620:	e92080e7          	jalr	-366(ra) # 800034ae <bread>
  log.lh.n = lh->n;
    80004624:	4d3c                	lw	a5,88(a0)
    80004626:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004628:	02f05563          	blez	a5,80004652 <initlog+0x74>
    8000462c:	05c50713          	addi	a4,a0,92
    80004630:	00016697          	auipc	a3,0x16
    80004634:	00068693          	mv	a3,a3
    80004638:	37fd                	addiw	a5,a5,-1
    8000463a:	1782                	slli	a5,a5,0x20
    8000463c:	9381                	srli	a5,a5,0x20
    8000463e:	078a                	slli	a5,a5,0x2
    80004640:	06050613          	addi	a2,a0,96
    80004644:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004646:	4310                	lw	a2,0(a4)
    80004648:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000464a:	0711                	addi	a4,a4,4
    8000464c:	0691                	addi	a3,a3,4
    8000464e:	fef71ce3          	bne	a4,a5,80004646 <initlog+0x68>
  brelse(buf);
    80004652:	fffff097          	auipc	ra,0xfffff
    80004656:	f8c080e7          	jalr	-116(ra) # 800035de <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000465a:	4505                	li	a0,1
    8000465c:	00000097          	auipc	ra,0x0
    80004660:	ebe080e7          	jalr	-322(ra) # 8000451a <install_trans>
  log.lh.n = 0;
    80004664:	00016797          	auipc	a5,0x16
    80004668:	fc07a423          	sw	zero,-56(a5) # 8001a62c <log+0x2c>
  write_head(); // clear the log
    8000466c:	00000097          	auipc	ra,0x0
    80004670:	e34080e7          	jalr	-460(ra) # 800044a0 <write_head>
}
    80004674:	70a2                	ld	ra,40(sp)
    80004676:	7402                	ld	s0,32(sp)
    80004678:	64e2                	ld	s1,24(sp)
    8000467a:	6942                	ld	s2,16(sp)
    8000467c:	69a2                	ld	s3,8(sp)
    8000467e:	6145                	addi	sp,sp,48
    80004680:	8082                	ret

0000000080004682 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004682:	1101                	addi	sp,sp,-32
    80004684:	ec06                	sd	ra,24(sp)
    80004686:	e822                	sd	s0,16(sp)
    80004688:	e426                	sd	s1,8(sp)
    8000468a:	e04a                	sd	s2,0(sp)
    8000468c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000468e:	00016517          	auipc	a0,0x16
    80004692:	f7250513          	addi	a0,a0,-142 # 8001a600 <log>
    80004696:	ffffc097          	auipc	ra,0xffffc
    8000469a:	54e080e7          	jalr	1358(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    8000469e:	00016497          	auipc	s1,0x16
    800046a2:	f6248493          	addi	s1,s1,-158 # 8001a600 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800046a6:	4979                	li	s2,30
    800046a8:	a039                	j	800046b6 <begin_op+0x34>
      sleep(&log, &log.lock);
    800046aa:	85a6                	mv	a1,s1
    800046ac:	8526                	mv	a0,s1
    800046ae:	ffffe097          	auipc	ra,0xffffe
    800046b2:	d86080e7          	jalr	-634(ra) # 80002434 <sleep>
    if(log.committing){
    800046b6:	50dc                	lw	a5,36(s1)
    800046b8:	fbed                	bnez	a5,800046aa <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800046ba:	509c                	lw	a5,32(s1)
    800046bc:	0017871b          	addiw	a4,a5,1
    800046c0:	0007069b          	sext.w	a3,a4
    800046c4:	0027179b          	slliw	a5,a4,0x2
    800046c8:	9fb9                	addw	a5,a5,a4
    800046ca:	0017979b          	slliw	a5,a5,0x1
    800046ce:	54d8                	lw	a4,44(s1)
    800046d0:	9fb9                	addw	a5,a5,a4
    800046d2:	00f95963          	bge	s2,a5,800046e4 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800046d6:	85a6                	mv	a1,s1
    800046d8:	8526                	mv	a0,s1
    800046da:	ffffe097          	auipc	ra,0xffffe
    800046de:	d5a080e7          	jalr	-678(ra) # 80002434 <sleep>
    800046e2:	bfd1                	j	800046b6 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800046e4:	00016517          	auipc	a0,0x16
    800046e8:	f1c50513          	addi	a0,a0,-228 # 8001a600 <log>
    800046ec:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800046ee:	ffffc097          	auipc	ra,0xffffc
    800046f2:	5aa080e7          	jalr	1450(ra) # 80000c98 <release>
      break;
    }
  }
}
    800046f6:	60e2                	ld	ra,24(sp)
    800046f8:	6442                	ld	s0,16(sp)
    800046fa:	64a2                	ld	s1,8(sp)
    800046fc:	6902                	ld	s2,0(sp)
    800046fe:	6105                	addi	sp,sp,32
    80004700:	8082                	ret

0000000080004702 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004702:	7139                	addi	sp,sp,-64
    80004704:	fc06                	sd	ra,56(sp)
    80004706:	f822                	sd	s0,48(sp)
    80004708:	f426                	sd	s1,40(sp)
    8000470a:	f04a                	sd	s2,32(sp)
    8000470c:	ec4e                	sd	s3,24(sp)
    8000470e:	e852                	sd	s4,16(sp)
    80004710:	e456                	sd	s5,8(sp)
    80004712:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004714:	00016497          	auipc	s1,0x16
    80004718:	eec48493          	addi	s1,s1,-276 # 8001a600 <log>
    8000471c:	8526                	mv	a0,s1
    8000471e:	ffffc097          	auipc	ra,0xffffc
    80004722:	4c6080e7          	jalr	1222(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004726:	509c                	lw	a5,32(s1)
    80004728:	37fd                	addiw	a5,a5,-1
    8000472a:	0007891b          	sext.w	s2,a5
    8000472e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004730:	50dc                	lw	a5,36(s1)
    80004732:	efb9                	bnez	a5,80004790 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004734:	06091663          	bnez	s2,800047a0 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004738:	00016497          	auipc	s1,0x16
    8000473c:	ec848493          	addi	s1,s1,-312 # 8001a600 <log>
    80004740:	4785                	li	a5,1
    80004742:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004744:	8526                	mv	a0,s1
    80004746:	ffffc097          	auipc	ra,0xffffc
    8000474a:	552080e7          	jalr	1362(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000474e:	54dc                	lw	a5,44(s1)
    80004750:	06f04763          	bgtz	a5,800047be <end_op+0xbc>
    acquire(&log.lock);
    80004754:	00016497          	auipc	s1,0x16
    80004758:	eac48493          	addi	s1,s1,-340 # 8001a600 <log>
    8000475c:	8526                	mv	a0,s1
    8000475e:	ffffc097          	auipc	ra,0xffffc
    80004762:	486080e7          	jalr	1158(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004766:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000476a:	8526                	mv	a0,s1
    8000476c:	ffffe097          	auipc	ra,0xffffe
    80004770:	e70080e7          	jalr	-400(ra) # 800025dc <wakeup>
    release(&log.lock);
    80004774:	8526                	mv	a0,s1
    80004776:	ffffc097          	auipc	ra,0xffffc
    8000477a:	522080e7          	jalr	1314(ra) # 80000c98 <release>
}
    8000477e:	70e2                	ld	ra,56(sp)
    80004780:	7442                	ld	s0,48(sp)
    80004782:	74a2                	ld	s1,40(sp)
    80004784:	7902                	ld	s2,32(sp)
    80004786:	69e2                	ld	s3,24(sp)
    80004788:	6a42                	ld	s4,16(sp)
    8000478a:	6aa2                	ld	s5,8(sp)
    8000478c:	6121                	addi	sp,sp,64
    8000478e:	8082                	ret
    panic("log.committing");
    80004790:	00004517          	auipc	a0,0x4
    80004794:	f8050513          	addi	a0,a0,-128 # 80008710 <syscalls+0x1f8>
    80004798:	ffffc097          	auipc	ra,0xffffc
    8000479c:	da6080e7          	jalr	-602(ra) # 8000053e <panic>
    wakeup(&log);
    800047a0:	00016497          	auipc	s1,0x16
    800047a4:	e6048493          	addi	s1,s1,-416 # 8001a600 <log>
    800047a8:	8526                	mv	a0,s1
    800047aa:	ffffe097          	auipc	ra,0xffffe
    800047ae:	e32080e7          	jalr	-462(ra) # 800025dc <wakeup>
  release(&log.lock);
    800047b2:	8526                	mv	a0,s1
    800047b4:	ffffc097          	auipc	ra,0xffffc
    800047b8:	4e4080e7          	jalr	1252(ra) # 80000c98 <release>
  if(do_commit){
    800047bc:	b7c9                	j	8000477e <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047be:	00016a97          	auipc	s5,0x16
    800047c2:	e72a8a93          	addi	s5,s5,-398 # 8001a630 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800047c6:	00016a17          	auipc	s4,0x16
    800047ca:	e3aa0a13          	addi	s4,s4,-454 # 8001a600 <log>
    800047ce:	018a2583          	lw	a1,24(s4)
    800047d2:	012585bb          	addw	a1,a1,s2
    800047d6:	2585                	addiw	a1,a1,1
    800047d8:	028a2503          	lw	a0,40(s4)
    800047dc:	fffff097          	auipc	ra,0xfffff
    800047e0:	cd2080e7          	jalr	-814(ra) # 800034ae <bread>
    800047e4:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800047e6:	000aa583          	lw	a1,0(s5)
    800047ea:	028a2503          	lw	a0,40(s4)
    800047ee:	fffff097          	auipc	ra,0xfffff
    800047f2:	cc0080e7          	jalr	-832(ra) # 800034ae <bread>
    800047f6:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800047f8:	40000613          	li	a2,1024
    800047fc:	05850593          	addi	a1,a0,88
    80004800:	05848513          	addi	a0,s1,88
    80004804:	ffffc097          	auipc	ra,0xffffc
    80004808:	53c080e7          	jalr	1340(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    8000480c:	8526                	mv	a0,s1
    8000480e:	fffff097          	auipc	ra,0xfffff
    80004812:	d92080e7          	jalr	-622(ra) # 800035a0 <bwrite>
    brelse(from);
    80004816:	854e                	mv	a0,s3
    80004818:	fffff097          	auipc	ra,0xfffff
    8000481c:	dc6080e7          	jalr	-570(ra) # 800035de <brelse>
    brelse(to);
    80004820:	8526                	mv	a0,s1
    80004822:	fffff097          	auipc	ra,0xfffff
    80004826:	dbc080e7          	jalr	-580(ra) # 800035de <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000482a:	2905                	addiw	s2,s2,1
    8000482c:	0a91                	addi	s5,s5,4
    8000482e:	02ca2783          	lw	a5,44(s4)
    80004832:	f8f94ee3          	blt	s2,a5,800047ce <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004836:	00000097          	auipc	ra,0x0
    8000483a:	c6a080e7          	jalr	-918(ra) # 800044a0 <write_head>
    install_trans(0); // Now install writes to home locations
    8000483e:	4501                	li	a0,0
    80004840:	00000097          	auipc	ra,0x0
    80004844:	cda080e7          	jalr	-806(ra) # 8000451a <install_trans>
    log.lh.n = 0;
    80004848:	00016797          	auipc	a5,0x16
    8000484c:	de07a223          	sw	zero,-540(a5) # 8001a62c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004850:	00000097          	auipc	ra,0x0
    80004854:	c50080e7          	jalr	-944(ra) # 800044a0 <write_head>
    80004858:	bdf5                	j	80004754 <end_op+0x52>

000000008000485a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000485a:	1101                	addi	sp,sp,-32
    8000485c:	ec06                	sd	ra,24(sp)
    8000485e:	e822                	sd	s0,16(sp)
    80004860:	e426                	sd	s1,8(sp)
    80004862:	e04a                	sd	s2,0(sp)
    80004864:	1000                	addi	s0,sp,32
    80004866:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004868:	00016917          	auipc	s2,0x16
    8000486c:	d9890913          	addi	s2,s2,-616 # 8001a600 <log>
    80004870:	854a                	mv	a0,s2
    80004872:	ffffc097          	auipc	ra,0xffffc
    80004876:	372080e7          	jalr	882(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000487a:	02c92603          	lw	a2,44(s2)
    8000487e:	47f5                	li	a5,29
    80004880:	06c7c563          	blt	a5,a2,800048ea <log_write+0x90>
    80004884:	00016797          	auipc	a5,0x16
    80004888:	d987a783          	lw	a5,-616(a5) # 8001a61c <log+0x1c>
    8000488c:	37fd                	addiw	a5,a5,-1
    8000488e:	04f65e63          	bge	a2,a5,800048ea <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004892:	00016797          	auipc	a5,0x16
    80004896:	d8e7a783          	lw	a5,-626(a5) # 8001a620 <log+0x20>
    8000489a:	06f05063          	blez	a5,800048fa <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000489e:	4781                	li	a5,0
    800048a0:	06c05563          	blez	a2,8000490a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800048a4:	44cc                	lw	a1,12(s1)
    800048a6:	00016717          	auipc	a4,0x16
    800048aa:	d8a70713          	addi	a4,a4,-630 # 8001a630 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800048ae:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800048b0:	4314                	lw	a3,0(a4)
    800048b2:	04b68c63          	beq	a3,a1,8000490a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800048b6:	2785                	addiw	a5,a5,1
    800048b8:	0711                	addi	a4,a4,4
    800048ba:	fef61be3          	bne	a2,a5,800048b0 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800048be:	0621                	addi	a2,a2,8
    800048c0:	060a                	slli	a2,a2,0x2
    800048c2:	00016797          	auipc	a5,0x16
    800048c6:	d3e78793          	addi	a5,a5,-706 # 8001a600 <log>
    800048ca:	963e                	add	a2,a2,a5
    800048cc:	44dc                	lw	a5,12(s1)
    800048ce:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800048d0:	8526                	mv	a0,s1
    800048d2:	fffff097          	auipc	ra,0xfffff
    800048d6:	daa080e7          	jalr	-598(ra) # 8000367c <bpin>
    log.lh.n++;
    800048da:	00016717          	auipc	a4,0x16
    800048de:	d2670713          	addi	a4,a4,-730 # 8001a600 <log>
    800048e2:	575c                	lw	a5,44(a4)
    800048e4:	2785                	addiw	a5,a5,1
    800048e6:	d75c                	sw	a5,44(a4)
    800048e8:	a835                	j	80004924 <log_write+0xca>
    panic("too big a transaction");
    800048ea:	00004517          	auipc	a0,0x4
    800048ee:	e3650513          	addi	a0,a0,-458 # 80008720 <syscalls+0x208>
    800048f2:	ffffc097          	auipc	ra,0xffffc
    800048f6:	c4c080e7          	jalr	-948(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800048fa:	00004517          	auipc	a0,0x4
    800048fe:	e3e50513          	addi	a0,a0,-450 # 80008738 <syscalls+0x220>
    80004902:	ffffc097          	auipc	ra,0xffffc
    80004906:	c3c080e7          	jalr	-964(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000490a:	00878713          	addi	a4,a5,8
    8000490e:	00271693          	slli	a3,a4,0x2
    80004912:	00016717          	auipc	a4,0x16
    80004916:	cee70713          	addi	a4,a4,-786 # 8001a600 <log>
    8000491a:	9736                	add	a4,a4,a3
    8000491c:	44d4                	lw	a3,12(s1)
    8000491e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004920:	faf608e3          	beq	a2,a5,800048d0 <log_write+0x76>
  }
  release(&log.lock);
    80004924:	00016517          	auipc	a0,0x16
    80004928:	cdc50513          	addi	a0,a0,-804 # 8001a600 <log>
    8000492c:	ffffc097          	auipc	ra,0xffffc
    80004930:	36c080e7          	jalr	876(ra) # 80000c98 <release>
}
    80004934:	60e2                	ld	ra,24(sp)
    80004936:	6442                	ld	s0,16(sp)
    80004938:	64a2                	ld	s1,8(sp)
    8000493a:	6902                	ld	s2,0(sp)
    8000493c:	6105                	addi	sp,sp,32
    8000493e:	8082                	ret

0000000080004940 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004940:	1101                	addi	sp,sp,-32
    80004942:	ec06                	sd	ra,24(sp)
    80004944:	e822                	sd	s0,16(sp)
    80004946:	e426                	sd	s1,8(sp)
    80004948:	e04a                	sd	s2,0(sp)
    8000494a:	1000                	addi	s0,sp,32
    8000494c:	84aa                	mv	s1,a0
    8000494e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004950:	00004597          	auipc	a1,0x4
    80004954:	e0858593          	addi	a1,a1,-504 # 80008758 <syscalls+0x240>
    80004958:	0521                	addi	a0,a0,8
    8000495a:	ffffc097          	auipc	ra,0xffffc
    8000495e:	1fa080e7          	jalr	506(ra) # 80000b54 <initlock>
  lk->name = name;
    80004962:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004966:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000496a:	0204a423          	sw	zero,40(s1)
}
    8000496e:	60e2                	ld	ra,24(sp)
    80004970:	6442                	ld	s0,16(sp)
    80004972:	64a2                	ld	s1,8(sp)
    80004974:	6902                	ld	s2,0(sp)
    80004976:	6105                	addi	sp,sp,32
    80004978:	8082                	ret

000000008000497a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000497a:	1101                	addi	sp,sp,-32
    8000497c:	ec06                	sd	ra,24(sp)
    8000497e:	e822                	sd	s0,16(sp)
    80004980:	e426                	sd	s1,8(sp)
    80004982:	e04a                	sd	s2,0(sp)
    80004984:	1000                	addi	s0,sp,32
    80004986:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004988:	00850913          	addi	s2,a0,8
    8000498c:	854a                	mv	a0,s2
    8000498e:	ffffc097          	auipc	ra,0xffffc
    80004992:	256080e7          	jalr	598(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004996:	409c                	lw	a5,0(s1)
    80004998:	cb89                	beqz	a5,800049aa <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000499a:	85ca                	mv	a1,s2
    8000499c:	8526                	mv	a0,s1
    8000499e:	ffffe097          	auipc	ra,0xffffe
    800049a2:	a96080e7          	jalr	-1386(ra) # 80002434 <sleep>
  while (lk->locked) {
    800049a6:	409c                	lw	a5,0(s1)
    800049a8:	fbed                	bnez	a5,8000499a <acquiresleep+0x20>
  }
  lk->locked = 1;
    800049aa:	4785                	li	a5,1
    800049ac:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800049ae:	ffffd097          	auipc	ra,0xffffd
    800049b2:	01a080e7          	jalr	26(ra) # 800019c8 <myproc>
    800049b6:	591c                	lw	a5,48(a0)
    800049b8:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800049ba:	854a                	mv	a0,s2
    800049bc:	ffffc097          	auipc	ra,0xffffc
    800049c0:	2dc080e7          	jalr	732(ra) # 80000c98 <release>
}
    800049c4:	60e2                	ld	ra,24(sp)
    800049c6:	6442                	ld	s0,16(sp)
    800049c8:	64a2                	ld	s1,8(sp)
    800049ca:	6902                	ld	s2,0(sp)
    800049cc:	6105                	addi	sp,sp,32
    800049ce:	8082                	ret

00000000800049d0 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800049d0:	1101                	addi	sp,sp,-32
    800049d2:	ec06                	sd	ra,24(sp)
    800049d4:	e822                	sd	s0,16(sp)
    800049d6:	e426                	sd	s1,8(sp)
    800049d8:	e04a                	sd	s2,0(sp)
    800049da:	1000                	addi	s0,sp,32
    800049dc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049de:	00850913          	addi	s2,a0,8
    800049e2:	854a                	mv	a0,s2
    800049e4:	ffffc097          	auipc	ra,0xffffc
    800049e8:	200080e7          	jalr	512(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800049ec:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049f0:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800049f4:	8526                	mv	a0,s1
    800049f6:	ffffe097          	auipc	ra,0xffffe
    800049fa:	be6080e7          	jalr	-1050(ra) # 800025dc <wakeup>
  release(&lk->lk);
    800049fe:	854a                	mv	a0,s2
    80004a00:	ffffc097          	auipc	ra,0xffffc
    80004a04:	298080e7          	jalr	664(ra) # 80000c98 <release>
}
    80004a08:	60e2                	ld	ra,24(sp)
    80004a0a:	6442                	ld	s0,16(sp)
    80004a0c:	64a2                	ld	s1,8(sp)
    80004a0e:	6902                	ld	s2,0(sp)
    80004a10:	6105                	addi	sp,sp,32
    80004a12:	8082                	ret

0000000080004a14 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004a14:	7179                	addi	sp,sp,-48
    80004a16:	f406                	sd	ra,40(sp)
    80004a18:	f022                	sd	s0,32(sp)
    80004a1a:	ec26                	sd	s1,24(sp)
    80004a1c:	e84a                	sd	s2,16(sp)
    80004a1e:	e44e                	sd	s3,8(sp)
    80004a20:	1800                	addi	s0,sp,48
    80004a22:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004a24:	00850913          	addi	s2,a0,8
    80004a28:	854a                	mv	a0,s2
    80004a2a:	ffffc097          	auipc	ra,0xffffc
    80004a2e:	1ba080e7          	jalr	442(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a32:	409c                	lw	a5,0(s1)
    80004a34:	ef99                	bnez	a5,80004a52 <holdingsleep+0x3e>
    80004a36:	4481                	li	s1,0
  release(&lk->lk);
    80004a38:	854a                	mv	a0,s2
    80004a3a:	ffffc097          	auipc	ra,0xffffc
    80004a3e:	25e080e7          	jalr	606(ra) # 80000c98 <release>
  return r;
}
    80004a42:	8526                	mv	a0,s1
    80004a44:	70a2                	ld	ra,40(sp)
    80004a46:	7402                	ld	s0,32(sp)
    80004a48:	64e2                	ld	s1,24(sp)
    80004a4a:	6942                	ld	s2,16(sp)
    80004a4c:	69a2                	ld	s3,8(sp)
    80004a4e:	6145                	addi	sp,sp,48
    80004a50:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a52:	0284a983          	lw	s3,40(s1)
    80004a56:	ffffd097          	auipc	ra,0xffffd
    80004a5a:	f72080e7          	jalr	-142(ra) # 800019c8 <myproc>
    80004a5e:	5904                	lw	s1,48(a0)
    80004a60:	413484b3          	sub	s1,s1,s3
    80004a64:	0014b493          	seqz	s1,s1
    80004a68:	bfc1                	j	80004a38 <holdingsleep+0x24>

0000000080004a6a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004a6a:	1141                	addi	sp,sp,-16
    80004a6c:	e406                	sd	ra,8(sp)
    80004a6e:	e022                	sd	s0,0(sp)
    80004a70:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004a72:	00004597          	auipc	a1,0x4
    80004a76:	cf658593          	addi	a1,a1,-778 # 80008768 <syscalls+0x250>
    80004a7a:	00016517          	auipc	a0,0x16
    80004a7e:	cce50513          	addi	a0,a0,-818 # 8001a748 <ftable>
    80004a82:	ffffc097          	auipc	ra,0xffffc
    80004a86:	0d2080e7          	jalr	210(ra) # 80000b54 <initlock>
}
    80004a8a:	60a2                	ld	ra,8(sp)
    80004a8c:	6402                	ld	s0,0(sp)
    80004a8e:	0141                	addi	sp,sp,16
    80004a90:	8082                	ret

0000000080004a92 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004a92:	1101                	addi	sp,sp,-32
    80004a94:	ec06                	sd	ra,24(sp)
    80004a96:	e822                	sd	s0,16(sp)
    80004a98:	e426                	sd	s1,8(sp)
    80004a9a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004a9c:	00016517          	auipc	a0,0x16
    80004aa0:	cac50513          	addi	a0,a0,-852 # 8001a748 <ftable>
    80004aa4:	ffffc097          	auipc	ra,0xffffc
    80004aa8:	140080e7          	jalr	320(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004aac:	00016497          	auipc	s1,0x16
    80004ab0:	cb448493          	addi	s1,s1,-844 # 8001a760 <ftable+0x18>
    80004ab4:	00017717          	auipc	a4,0x17
    80004ab8:	c4c70713          	addi	a4,a4,-948 # 8001b700 <ftable+0xfb8>
    if(f->ref == 0){
    80004abc:	40dc                	lw	a5,4(s1)
    80004abe:	cf99                	beqz	a5,80004adc <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004ac0:	02848493          	addi	s1,s1,40
    80004ac4:	fee49ce3          	bne	s1,a4,80004abc <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004ac8:	00016517          	auipc	a0,0x16
    80004acc:	c8050513          	addi	a0,a0,-896 # 8001a748 <ftable>
    80004ad0:	ffffc097          	auipc	ra,0xffffc
    80004ad4:	1c8080e7          	jalr	456(ra) # 80000c98 <release>
  return 0;
    80004ad8:	4481                	li	s1,0
    80004ada:	a819                	j	80004af0 <filealloc+0x5e>
      f->ref = 1;
    80004adc:	4785                	li	a5,1
    80004ade:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004ae0:	00016517          	auipc	a0,0x16
    80004ae4:	c6850513          	addi	a0,a0,-920 # 8001a748 <ftable>
    80004ae8:	ffffc097          	auipc	ra,0xffffc
    80004aec:	1b0080e7          	jalr	432(ra) # 80000c98 <release>
}
    80004af0:	8526                	mv	a0,s1
    80004af2:	60e2                	ld	ra,24(sp)
    80004af4:	6442                	ld	s0,16(sp)
    80004af6:	64a2                	ld	s1,8(sp)
    80004af8:	6105                	addi	sp,sp,32
    80004afa:	8082                	ret

0000000080004afc <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004afc:	1101                	addi	sp,sp,-32
    80004afe:	ec06                	sd	ra,24(sp)
    80004b00:	e822                	sd	s0,16(sp)
    80004b02:	e426                	sd	s1,8(sp)
    80004b04:	1000                	addi	s0,sp,32
    80004b06:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004b08:	00016517          	auipc	a0,0x16
    80004b0c:	c4050513          	addi	a0,a0,-960 # 8001a748 <ftable>
    80004b10:	ffffc097          	auipc	ra,0xffffc
    80004b14:	0d4080e7          	jalr	212(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004b18:	40dc                	lw	a5,4(s1)
    80004b1a:	02f05263          	blez	a5,80004b3e <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004b1e:	2785                	addiw	a5,a5,1
    80004b20:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004b22:	00016517          	auipc	a0,0x16
    80004b26:	c2650513          	addi	a0,a0,-986 # 8001a748 <ftable>
    80004b2a:	ffffc097          	auipc	ra,0xffffc
    80004b2e:	16e080e7          	jalr	366(ra) # 80000c98 <release>
  return f;
}
    80004b32:	8526                	mv	a0,s1
    80004b34:	60e2                	ld	ra,24(sp)
    80004b36:	6442                	ld	s0,16(sp)
    80004b38:	64a2                	ld	s1,8(sp)
    80004b3a:	6105                	addi	sp,sp,32
    80004b3c:	8082                	ret
    panic("filedup");
    80004b3e:	00004517          	auipc	a0,0x4
    80004b42:	c3250513          	addi	a0,a0,-974 # 80008770 <syscalls+0x258>
    80004b46:	ffffc097          	auipc	ra,0xffffc
    80004b4a:	9f8080e7          	jalr	-1544(ra) # 8000053e <panic>

0000000080004b4e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004b4e:	7139                	addi	sp,sp,-64
    80004b50:	fc06                	sd	ra,56(sp)
    80004b52:	f822                	sd	s0,48(sp)
    80004b54:	f426                	sd	s1,40(sp)
    80004b56:	f04a                	sd	s2,32(sp)
    80004b58:	ec4e                	sd	s3,24(sp)
    80004b5a:	e852                	sd	s4,16(sp)
    80004b5c:	e456                	sd	s5,8(sp)
    80004b5e:	0080                	addi	s0,sp,64
    80004b60:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004b62:	00016517          	auipc	a0,0x16
    80004b66:	be650513          	addi	a0,a0,-1050 # 8001a748 <ftable>
    80004b6a:	ffffc097          	auipc	ra,0xffffc
    80004b6e:	07a080e7          	jalr	122(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004b72:	40dc                	lw	a5,4(s1)
    80004b74:	06f05163          	blez	a5,80004bd6 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004b78:	37fd                	addiw	a5,a5,-1
    80004b7a:	0007871b          	sext.w	a4,a5
    80004b7e:	c0dc                	sw	a5,4(s1)
    80004b80:	06e04363          	bgtz	a4,80004be6 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004b84:	0004a903          	lw	s2,0(s1)
    80004b88:	0094ca83          	lbu	s5,9(s1)
    80004b8c:	0104ba03          	ld	s4,16(s1)
    80004b90:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004b94:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004b98:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004b9c:	00016517          	auipc	a0,0x16
    80004ba0:	bac50513          	addi	a0,a0,-1108 # 8001a748 <ftable>
    80004ba4:	ffffc097          	auipc	ra,0xffffc
    80004ba8:	0f4080e7          	jalr	244(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004bac:	4785                	li	a5,1
    80004bae:	04f90d63          	beq	s2,a5,80004c08 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004bb2:	3979                	addiw	s2,s2,-2
    80004bb4:	4785                	li	a5,1
    80004bb6:	0527e063          	bltu	a5,s2,80004bf6 <fileclose+0xa8>
    begin_op();
    80004bba:	00000097          	auipc	ra,0x0
    80004bbe:	ac8080e7          	jalr	-1336(ra) # 80004682 <begin_op>
    iput(ff.ip);
    80004bc2:	854e                	mv	a0,s3
    80004bc4:	fffff097          	auipc	ra,0xfffff
    80004bc8:	2a6080e7          	jalr	678(ra) # 80003e6a <iput>
    end_op();
    80004bcc:	00000097          	auipc	ra,0x0
    80004bd0:	b36080e7          	jalr	-1226(ra) # 80004702 <end_op>
    80004bd4:	a00d                	j	80004bf6 <fileclose+0xa8>
    panic("fileclose");
    80004bd6:	00004517          	auipc	a0,0x4
    80004bda:	ba250513          	addi	a0,a0,-1118 # 80008778 <syscalls+0x260>
    80004bde:	ffffc097          	auipc	ra,0xffffc
    80004be2:	960080e7          	jalr	-1696(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004be6:	00016517          	auipc	a0,0x16
    80004bea:	b6250513          	addi	a0,a0,-1182 # 8001a748 <ftable>
    80004bee:	ffffc097          	auipc	ra,0xffffc
    80004bf2:	0aa080e7          	jalr	170(ra) # 80000c98 <release>
  }
}
    80004bf6:	70e2                	ld	ra,56(sp)
    80004bf8:	7442                	ld	s0,48(sp)
    80004bfa:	74a2                	ld	s1,40(sp)
    80004bfc:	7902                	ld	s2,32(sp)
    80004bfe:	69e2                	ld	s3,24(sp)
    80004c00:	6a42                	ld	s4,16(sp)
    80004c02:	6aa2                	ld	s5,8(sp)
    80004c04:	6121                	addi	sp,sp,64
    80004c06:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004c08:	85d6                	mv	a1,s5
    80004c0a:	8552                	mv	a0,s4
    80004c0c:	00000097          	auipc	ra,0x0
    80004c10:	34c080e7          	jalr	844(ra) # 80004f58 <pipeclose>
    80004c14:	b7cd                	j	80004bf6 <fileclose+0xa8>

0000000080004c16 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004c16:	715d                	addi	sp,sp,-80
    80004c18:	e486                	sd	ra,72(sp)
    80004c1a:	e0a2                	sd	s0,64(sp)
    80004c1c:	fc26                	sd	s1,56(sp)
    80004c1e:	f84a                	sd	s2,48(sp)
    80004c20:	f44e                	sd	s3,40(sp)
    80004c22:	0880                	addi	s0,sp,80
    80004c24:	84aa                	mv	s1,a0
    80004c26:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004c28:	ffffd097          	auipc	ra,0xffffd
    80004c2c:	da0080e7          	jalr	-608(ra) # 800019c8 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004c30:	409c                	lw	a5,0(s1)
    80004c32:	37f9                	addiw	a5,a5,-2
    80004c34:	4705                	li	a4,1
    80004c36:	04f76763          	bltu	a4,a5,80004c84 <filestat+0x6e>
    80004c3a:	892a                	mv	s2,a0
    ilock(f->ip);
    80004c3c:	6c88                	ld	a0,24(s1)
    80004c3e:	fffff097          	auipc	ra,0xfffff
    80004c42:	072080e7          	jalr	114(ra) # 80003cb0 <ilock>
    stati(f->ip, &st);
    80004c46:	fb840593          	addi	a1,s0,-72
    80004c4a:	6c88                	ld	a0,24(s1)
    80004c4c:	fffff097          	auipc	ra,0xfffff
    80004c50:	2ee080e7          	jalr	750(ra) # 80003f3a <stati>
    iunlock(f->ip);
    80004c54:	6c88                	ld	a0,24(s1)
    80004c56:	fffff097          	auipc	ra,0xfffff
    80004c5a:	11c080e7          	jalr	284(ra) # 80003d72 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004c5e:	46e1                	li	a3,24
    80004c60:	fb840613          	addi	a2,s0,-72
    80004c64:	85ce                	mv	a1,s3
    80004c66:	05093503          	ld	a0,80(s2)
    80004c6a:	ffffd097          	auipc	ra,0xffffd
    80004c6e:	a10080e7          	jalr	-1520(ra) # 8000167a <copyout>
    80004c72:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004c76:	60a6                	ld	ra,72(sp)
    80004c78:	6406                	ld	s0,64(sp)
    80004c7a:	74e2                	ld	s1,56(sp)
    80004c7c:	7942                	ld	s2,48(sp)
    80004c7e:	79a2                	ld	s3,40(sp)
    80004c80:	6161                	addi	sp,sp,80
    80004c82:	8082                	ret
  return -1;
    80004c84:	557d                	li	a0,-1
    80004c86:	bfc5                	j	80004c76 <filestat+0x60>

0000000080004c88 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004c88:	7179                	addi	sp,sp,-48
    80004c8a:	f406                	sd	ra,40(sp)
    80004c8c:	f022                	sd	s0,32(sp)
    80004c8e:	ec26                	sd	s1,24(sp)
    80004c90:	e84a                	sd	s2,16(sp)
    80004c92:	e44e                	sd	s3,8(sp)
    80004c94:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004c96:	00854783          	lbu	a5,8(a0)
    80004c9a:	c3d5                	beqz	a5,80004d3e <fileread+0xb6>
    80004c9c:	84aa                	mv	s1,a0
    80004c9e:	89ae                	mv	s3,a1
    80004ca0:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ca2:	411c                	lw	a5,0(a0)
    80004ca4:	4705                	li	a4,1
    80004ca6:	04e78963          	beq	a5,a4,80004cf8 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004caa:	470d                	li	a4,3
    80004cac:	04e78d63          	beq	a5,a4,80004d06 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004cb0:	4709                	li	a4,2
    80004cb2:	06e79e63          	bne	a5,a4,80004d2e <fileread+0xa6>
    ilock(f->ip);
    80004cb6:	6d08                	ld	a0,24(a0)
    80004cb8:	fffff097          	auipc	ra,0xfffff
    80004cbc:	ff8080e7          	jalr	-8(ra) # 80003cb0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004cc0:	874a                	mv	a4,s2
    80004cc2:	5094                	lw	a3,32(s1)
    80004cc4:	864e                	mv	a2,s3
    80004cc6:	4585                	li	a1,1
    80004cc8:	6c88                	ld	a0,24(s1)
    80004cca:	fffff097          	auipc	ra,0xfffff
    80004cce:	29a080e7          	jalr	666(ra) # 80003f64 <readi>
    80004cd2:	892a                	mv	s2,a0
    80004cd4:	00a05563          	blez	a0,80004cde <fileread+0x56>
      f->off += r;
    80004cd8:	509c                	lw	a5,32(s1)
    80004cda:	9fa9                	addw	a5,a5,a0
    80004cdc:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004cde:	6c88                	ld	a0,24(s1)
    80004ce0:	fffff097          	auipc	ra,0xfffff
    80004ce4:	092080e7          	jalr	146(ra) # 80003d72 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004ce8:	854a                	mv	a0,s2
    80004cea:	70a2                	ld	ra,40(sp)
    80004cec:	7402                	ld	s0,32(sp)
    80004cee:	64e2                	ld	s1,24(sp)
    80004cf0:	6942                	ld	s2,16(sp)
    80004cf2:	69a2                	ld	s3,8(sp)
    80004cf4:	6145                	addi	sp,sp,48
    80004cf6:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004cf8:	6908                	ld	a0,16(a0)
    80004cfa:	00000097          	auipc	ra,0x0
    80004cfe:	3c8080e7          	jalr	968(ra) # 800050c2 <piperead>
    80004d02:	892a                	mv	s2,a0
    80004d04:	b7d5                	j	80004ce8 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004d06:	02451783          	lh	a5,36(a0)
    80004d0a:	03079693          	slli	a3,a5,0x30
    80004d0e:	92c1                	srli	a3,a3,0x30
    80004d10:	4725                	li	a4,9
    80004d12:	02d76863          	bltu	a4,a3,80004d42 <fileread+0xba>
    80004d16:	0792                	slli	a5,a5,0x4
    80004d18:	00016717          	auipc	a4,0x16
    80004d1c:	99070713          	addi	a4,a4,-1648 # 8001a6a8 <devsw>
    80004d20:	97ba                	add	a5,a5,a4
    80004d22:	639c                	ld	a5,0(a5)
    80004d24:	c38d                	beqz	a5,80004d46 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004d26:	4505                	li	a0,1
    80004d28:	9782                	jalr	a5
    80004d2a:	892a                	mv	s2,a0
    80004d2c:	bf75                	j	80004ce8 <fileread+0x60>
    panic("fileread");
    80004d2e:	00004517          	auipc	a0,0x4
    80004d32:	a5a50513          	addi	a0,a0,-1446 # 80008788 <syscalls+0x270>
    80004d36:	ffffc097          	auipc	ra,0xffffc
    80004d3a:	808080e7          	jalr	-2040(ra) # 8000053e <panic>
    return -1;
    80004d3e:	597d                	li	s2,-1
    80004d40:	b765                	j	80004ce8 <fileread+0x60>
      return -1;
    80004d42:	597d                	li	s2,-1
    80004d44:	b755                	j	80004ce8 <fileread+0x60>
    80004d46:	597d                	li	s2,-1
    80004d48:	b745                	j	80004ce8 <fileread+0x60>

0000000080004d4a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004d4a:	715d                	addi	sp,sp,-80
    80004d4c:	e486                	sd	ra,72(sp)
    80004d4e:	e0a2                	sd	s0,64(sp)
    80004d50:	fc26                	sd	s1,56(sp)
    80004d52:	f84a                	sd	s2,48(sp)
    80004d54:	f44e                	sd	s3,40(sp)
    80004d56:	f052                	sd	s4,32(sp)
    80004d58:	ec56                	sd	s5,24(sp)
    80004d5a:	e85a                	sd	s6,16(sp)
    80004d5c:	e45e                	sd	s7,8(sp)
    80004d5e:	e062                	sd	s8,0(sp)
    80004d60:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004d62:	00954783          	lbu	a5,9(a0)
    80004d66:	10078663          	beqz	a5,80004e72 <filewrite+0x128>
    80004d6a:	892a                	mv	s2,a0
    80004d6c:	8aae                	mv	s5,a1
    80004d6e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d70:	411c                	lw	a5,0(a0)
    80004d72:	4705                	li	a4,1
    80004d74:	02e78263          	beq	a5,a4,80004d98 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d78:	470d                	li	a4,3
    80004d7a:	02e78663          	beq	a5,a4,80004da6 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d7e:	4709                	li	a4,2
    80004d80:	0ee79163          	bne	a5,a4,80004e62 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004d84:	0ac05d63          	blez	a2,80004e3e <filewrite+0xf4>
    int i = 0;
    80004d88:	4981                	li	s3,0
    80004d8a:	6b05                	lui	s6,0x1
    80004d8c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004d90:	6b85                	lui	s7,0x1
    80004d92:	c00b8b9b          	addiw	s7,s7,-1024
    80004d96:	a861                	j	80004e2e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004d98:	6908                	ld	a0,16(a0)
    80004d9a:	00000097          	auipc	ra,0x0
    80004d9e:	22e080e7          	jalr	558(ra) # 80004fc8 <pipewrite>
    80004da2:	8a2a                	mv	s4,a0
    80004da4:	a045                	j	80004e44 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004da6:	02451783          	lh	a5,36(a0)
    80004daa:	03079693          	slli	a3,a5,0x30
    80004dae:	92c1                	srli	a3,a3,0x30
    80004db0:	4725                	li	a4,9
    80004db2:	0cd76263          	bltu	a4,a3,80004e76 <filewrite+0x12c>
    80004db6:	0792                	slli	a5,a5,0x4
    80004db8:	00016717          	auipc	a4,0x16
    80004dbc:	8f070713          	addi	a4,a4,-1808 # 8001a6a8 <devsw>
    80004dc0:	97ba                	add	a5,a5,a4
    80004dc2:	679c                	ld	a5,8(a5)
    80004dc4:	cbdd                	beqz	a5,80004e7a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004dc6:	4505                	li	a0,1
    80004dc8:	9782                	jalr	a5
    80004dca:	8a2a                	mv	s4,a0
    80004dcc:	a8a5                	j	80004e44 <filewrite+0xfa>
    80004dce:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004dd2:	00000097          	auipc	ra,0x0
    80004dd6:	8b0080e7          	jalr	-1872(ra) # 80004682 <begin_op>
      ilock(f->ip);
    80004dda:	01893503          	ld	a0,24(s2)
    80004dde:	fffff097          	auipc	ra,0xfffff
    80004de2:	ed2080e7          	jalr	-302(ra) # 80003cb0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004de6:	8762                	mv	a4,s8
    80004de8:	02092683          	lw	a3,32(s2)
    80004dec:	01598633          	add	a2,s3,s5
    80004df0:	4585                	li	a1,1
    80004df2:	01893503          	ld	a0,24(s2)
    80004df6:	fffff097          	auipc	ra,0xfffff
    80004dfa:	266080e7          	jalr	614(ra) # 8000405c <writei>
    80004dfe:	84aa                	mv	s1,a0
    80004e00:	00a05763          	blez	a0,80004e0e <filewrite+0xc4>
        f->off += r;
    80004e04:	02092783          	lw	a5,32(s2)
    80004e08:	9fa9                	addw	a5,a5,a0
    80004e0a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004e0e:	01893503          	ld	a0,24(s2)
    80004e12:	fffff097          	auipc	ra,0xfffff
    80004e16:	f60080e7          	jalr	-160(ra) # 80003d72 <iunlock>
      end_op();
    80004e1a:	00000097          	auipc	ra,0x0
    80004e1e:	8e8080e7          	jalr	-1816(ra) # 80004702 <end_op>

      if(r != n1){
    80004e22:	009c1f63          	bne	s8,s1,80004e40 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004e26:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004e2a:	0149db63          	bge	s3,s4,80004e40 <filewrite+0xf6>
      int n1 = n - i;
    80004e2e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004e32:	84be                	mv	s1,a5
    80004e34:	2781                	sext.w	a5,a5
    80004e36:	f8fb5ce3          	bge	s6,a5,80004dce <filewrite+0x84>
    80004e3a:	84de                	mv	s1,s7
    80004e3c:	bf49                	j	80004dce <filewrite+0x84>
    int i = 0;
    80004e3e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004e40:	013a1f63          	bne	s4,s3,80004e5e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004e44:	8552                	mv	a0,s4
    80004e46:	60a6                	ld	ra,72(sp)
    80004e48:	6406                	ld	s0,64(sp)
    80004e4a:	74e2                	ld	s1,56(sp)
    80004e4c:	7942                	ld	s2,48(sp)
    80004e4e:	79a2                	ld	s3,40(sp)
    80004e50:	7a02                	ld	s4,32(sp)
    80004e52:	6ae2                	ld	s5,24(sp)
    80004e54:	6b42                	ld	s6,16(sp)
    80004e56:	6ba2                	ld	s7,8(sp)
    80004e58:	6c02                	ld	s8,0(sp)
    80004e5a:	6161                	addi	sp,sp,80
    80004e5c:	8082                	ret
    ret = (i == n ? n : -1);
    80004e5e:	5a7d                	li	s4,-1
    80004e60:	b7d5                	j	80004e44 <filewrite+0xfa>
    panic("filewrite");
    80004e62:	00004517          	auipc	a0,0x4
    80004e66:	93650513          	addi	a0,a0,-1738 # 80008798 <syscalls+0x280>
    80004e6a:	ffffb097          	auipc	ra,0xffffb
    80004e6e:	6d4080e7          	jalr	1748(ra) # 8000053e <panic>
    return -1;
    80004e72:	5a7d                	li	s4,-1
    80004e74:	bfc1                	j	80004e44 <filewrite+0xfa>
      return -1;
    80004e76:	5a7d                	li	s4,-1
    80004e78:	b7f1                	j	80004e44 <filewrite+0xfa>
    80004e7a:	5a7d                	li	s4,-1
    80004e7c:	b7e1                	j	80004e44 <filewrite+0xfa>

0000000080004e7e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004e7e:	7179                	addi	sp,sp,-48
    80004e80:	f406                	sd	ra,40(sp)
    80004e82:	f022                	sd	s0,32(sp)
    80004e84:	ec26                	sd	s1,24(sp)
    80004e86:	e84a                	sd	s2,16(sp)
    80004e88:	e44e                	sd	s3,8(sp)
    80004e8a:	e052                	sd	s4,0(sp)
    80004e8c:	1800                	addi	s0,sp,48
    80004e8e:	84aa                	mv	s1,a0
    80004e90:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004e92:	0005b023          	sd	zero,0(a1)
    80004e96:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004e9a:	00000097          	auipc	ra,0x0
    80004e9e:	bf8080e7          	jalr	-1032(ra) # 80004a92 <filealloc>
    80004ea2:	e088                	sd	a0,0(s1)
    80004ea4:	c551                	beqz	a0,80004f30 <pipealloc+0xb2>
    80004ea6:	00000097          	auipc	ra,0x0
    80004eaa:	bec080e7          	jalr	-1044(ra) # 80004a92 <filealloc>
    80004eae:	00aa3023          	sd	a0,0(s4)
    80004eb2:	c92d                	beqz	a0,80004f24 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004eb4:	ffffc097          	auipc	ra,0xffffc
    80004eb8:	c40080e7          	jalr	-960(ra) # 80000af4 <kalloc>
    80004ebc:	892a                	mv	s2,a0
    80004ebe:	c125                	beqz	a0,80004f1e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ec0:	4985                	li	s3,1
    80004ec2:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004ec6:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004eca:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004ece:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004ed2:	00004597          	auipc	a1,0x4
    80004ed6:	8d658593          	addi	a1,a1,-1834 # 800087a8 <syscalls+0x290>
    80004eda:	ffffc097          	auipc	ra,0xffffc
    80004ede:	c7a080e7          	jalr	-902(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004ee2:	609c                	ld	a5,0(s1)
    80004ee4:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004ee8:	609c                	ld	a5,0(s1)
    80004eea:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004eee:	609c                	ld	a5,0(s1)
    80004ef0:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004ef4:	609c                	ld	a5,0(s1)
    80004ef6:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004efa:	000a3783          	ld	a5,0(s4)
    80004efe:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004f02:	000a3783          	ld	a5,0(s4)
    80004f06:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004f0a:	000a3783          	ld	a5,0(s4)
    80004f0e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004f12:	000a3783          	ld	a5,0(s4)
    80004f16:	0127b823          	sd	s2,16(a5)
  return 0;
    80004f1a:	4501                	li	a0,0
    80004f1c:	a025                	j	80004f44 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004f1e:	6088                	ld	a0,0(s1)
    80004f20:	e501                	bnez	a0,80004f28 <pipealloc+0xaa>
    80004f22:	a039                	j	80004f30 <pipealloc+0xb2>
    80004f24:	6088                	ld	a0,0(s1)
    80004f26:	c51d                	beqz	a0,80004f54 <pipealloc+0xd6>
    fileclose(*f0);
    80004f28:	00000097          	auipc	ra,0x0
    80004f2c:	c26080e7          	jalr	-986(ra) # 80004b4e <fileclose>
  if(*f1)
    80004f30:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004f34:	557d                	li	a0,-1
  if(*f1)
    80004f36:	c799                	beqz	a5,80004f44 <pipealloc+0xc6>
    fileclose(*f1);
    80004f38:	853e                	mv	a0,a5
    80004f3a:	00000097          	auipc	ra,0x0
    80004f3e:	c14080e7          	jalr	-1004(ra) # 80004b4e <fileclose>
  return -1;
    80004f42:	557d                	li	a0,-1
}
    80004f44:	70a2                	ld	ra,40(sp)
    80004f46:	7402                	ld	s0,32(sp)
    80004f48:	64e2                	ld	s1,24(sp)
    80004f4a:	6942                	ld	s2,16(sp)
    80004f4c:	69a2                	ld	s3,8(sp)
    80004f4e:	6a02                	ld	s4,0(sp)
    80004f50:	6145                	addi	sp,sp,48
    80004f52:	8082                	ret
  return -1;
    80004f54:	557d                	li	a0,-1
    80004f56:	b7fd                	j	80004f44 <pipealloc+0xc6>

0000000080004f58 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004f58:	1101                	addi	sp,sp,-32
    80004f5a:	ec06                	sd	ra,24(sp)
    80004f5c:	e822                	sd	s0,16(sp)
    80004f5e:	e426                	sd	s1,8(sp)
    80004f60:	e04a                	sd	s2,0(sp)
    80004f62:	1000                	addi	s0,sp,32
    80004f64:	84aa                	mv	s1,a0
    80004f66:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004f68:	ffffc097          	auipc	ra,0xffffc
    80004f6c:	c7c080e7          	jalr	-900(ra) # 80000be4 <acquire>
  if(writable){
    80004f70:	02090d63          	beqz	s2,80004faa <pipeclose+0x52>
    pi->writeopen = 0;
    80004f74:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004f78:	21848513          	addi	a0,s1,536
    80004f7c:	ffffd097          	auipc	ra,0xffffd
    80004f80:	660080e7          	jalr	1632(ra) # 800025dc <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004f84:	2204b783          	ld	a5,544(s1)
    80004f88:	eb95                	bnez	a5,80004fbc <pipeclose+0x64>
    release(&pi->lock);
    80004f8a:	8526                	mv	a0,s1
    80004f8c:	ffffc097          	auipc	ra,0xffffc
    80004f90:	d0c080e7          	jalr	-756(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004f94:	8526                	mv	a0,s1
    80004f96:	ffffc097          	auipc	ra,0xffffc
    80004f9a:	a62080e7          	jalr	-1438(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004f9e:	60e2                	ld	ra,24(sp)
    80004fa0:	6442                	ld	s0,16(sp)
    80004fa2:	64a2                	ld	s1,8(sp)
    80004fa4:	6902                	ld	s2,0(sp)
    80004fa6:	6105                	addi	sp,sp,32
    80004fa8:	8082                	ret
    pi->readopen = 0;
    80004faa:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004fae:	21c48513          	addi	a0,s1,540
    80004fb2:	ffffd097          	auipc	ra,0xffffd
    80004fb6:	62a080e7          	jalr	1578(ra) # 800025dc <wakeup>
    80004fba:	b7e9                	j	80004f84 <pipeclose+0x2c>
    release(&pi->lock);
    80004fbc:	8526                	mv	a0,s1
    80004fbe:	ffffc097          	auipc	ra,0xffffc
    80004fc2:	cda080e7          	jalr	-806(ra) # 80000c98 <release>
}
    80004fc6:	bfe1                	j	80004f9e <pipeclose+0x46>

0000000080004fc8 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004fc8:	7159                	addi	sp,sp,-112
    80004fca:	f486                	sd	ra,104(sp)
    80004fcc:	f0a2                	sd	s0,96(sp)
    80004fce:	eca6                	sd	s1,88(sp)
    80004fd0:	e8ca                	sd	s2,80(sp)
    80004fd2:	e4ce                	sd	s3,72(sp)
    80004fd4:	e0d2                	sd	s4,64(sp)
    80004fd6:	fc56                	sd	s5,56(sp)
    80004fd8:	f85a                	sd	s6,48(sp)
    80004fda:	f45e                	sd	s7,40(sp)
    80004fdc:	f062                	sd	s8,32(sp)
    80004fde:	ec66                	sd	s9,24(sp)
    80004fe0:	1880                	addi	s0,sp,112
    80004fe2:	84aa                	mv	s1,a0
    80004fe4:	8aae                	mv	s5,a1
    80004fe6:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004fe8:	ffffd097          	auipc	ra,0xffffd
    80004fec:	9e0080e7          	jalr	-1568(ra) # 800019c8 <myproc>
    80004ff0:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ff2:	8526                	mv	a0,s1
    80004ff4:	ffffc097          	auipc	ra,0xffffc
    80004ff8:	bf0080e7          	jalr	-1040(ra) # 80000be4 <acquire>
  while(i < n){
    80004ffc:	0d405163          	blez	s4,800050be <pipewrite+0xf6>
    80005000:	8ba6                	mv	s7,s1
  int i = 0;
    80005002:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005004:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005006:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000500a:	21c48c13          	addi	s8,s1,540
    8000500e:	a08d                	j	80005070 <pipewrite+0xa8>
      release(&pi->lock);
    80005010:	8526                	mv	a0,s1
    80005012:	ffffc097          	auipc	ra,0xffffc
    80005016:	c86080e7          	jalr	-890(ra) # 80000c98 <release>
      return -1;
    8000501a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000501c:	854a                	mv	a0,s2
    8000501e:	70a6                	ld	ra,104(sp)
    80005020:	7406                	ld	s0,96(sp)
    80005022:	64e6                	ld	s1,88(sp)
    80005024:	6946                	ld	s2,80(sp)
    80005026:	69a6                	ld	s3,72(sp)
    80005028:	6a06                	ld	s4,64(sp)
    8000502a:	7ae2                	ld	s5,56(sp)
    8000502c:	7b42                	ld	s6,48(sp)
    8000502e:	7ba2                	ld	s7,40(sp)
    80005030:	7c02                	ld	s8,32(sp)
    80005032:	6ce2                	ld	s9,24(sp)
    80005034:	6165                	addi	sp,sp,112
    80005036:	8082                	ret
      wakeup(&pi->nread);
    80005038:	8566                	mv	a0,s9
    8000503a:	ffffd097          	auipc	ra,0xffffd
    8000503e:	5a2080e7          	jalr	1442(ra) # 800025dc <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005042:	85de                	mv	a1,s7
    80005044:	8562                	mv	a0,s8
    80005046:	ffffd097          	auipc	ra,0xffffd
    8000504a:	3ee080e7          	jalr	1006(ra) # 80002434 <sleep>
    8000504e:	a839                	j	8000506c <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005050:	21c4a783          	lw	a5,540(s1)
    80005054:	0017871b          	addiw	a4,a5,1
    80005058:	20e4ae23          	sw	a4,540(s1)
    8000505c:	1ff7f793          	andi	a5,a5,511
    80005060:	97a6                	add	a5,a5,s1
    80005062:	f9f44703          	lbu	a4,-97(s0)
    80005066:	00e78c23          	sb	a4,24(a5)
      i++;
    8000506a:	2905                	addiw	s2,s2,1
  while(i < n){
    8000506c:	03495d63          	bge	s2,s4,800050a6 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80005070:	2204a783          	lw	a5,544(s1)
    80005074:	dfd1                	beqz	a5,80005010 <pipewrite+0x48>
    80005076:	0289a783          	lw	a5,40(s3)
    8000507a:	fbd9                	bnez	a5,80005010 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000507c:	2184a783          	lw	a5,536(s1)
    80005080:	21c4a703          	lw	a4,540(s1)
    80005084:	2007879b          	addiw	a5,a5,512
    80005088:	faf708e3          	beq	a4,a5,80005038 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000508c:	4685                	li	a3,1
    8000508e:	01590633          	add	a2,s2,s5
    80005092:	f9f40593          	addi	a1,s0,-97
    80005096:	0509b503          	ld	a0,80(s3)
    8000509a:	ffffc097          	auipc	ra,0xffffc
    8000509e:	66c080e7          	jalr	1644(ra) # 80001706 <copyin>
    800050a2:	fb6517e3          	bne	a0,s6,80005050 <pipewrite+0x88>
  wakeup(&pi->nread);
    800050a6:	21848513          	addi	a0,s1,536
    800050aa:	ffffd097          	auipc	ra,0xffffd
    800050ae:	532080e7          	jalr	1330(ra) # 800025dc <wakeup>
  release(&pi->lock);
    800050b2:	8526                	mv	a0,s1
    800050b4:	ffffc097          	auipc	ra,0xffffc
    800050b8:	be4080e7          	jalr	-1052(ra) # 80000c98 <release>
  return i;
    800050bc:	b785                	j	8000501c <pipewrite+0x54>
  int i = 0;
    800050be:	4901                	li	s2,0
    800050c0:	b7dd                	j	800050a6 <pipewrite+0xde>

00000000800050c2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800050c2:	715d                	addi	sp,sp,-80
    800050c4:	e486                	sd	ra,72(sp)
    800050c6:	e0a2                	sd	s0,64(sp)
    800050c8:	fc26                	sd	s1,56(sp)
    800050ca:	f84a                	sd	s2,48(sp)
    800050cc:	f44e                	sd	s3,40(sp)
    800050ce:	f052                	sd	s4,32(sp)
    800050d0:	ec56                	sd	s5,24(sp)
    800050d2:	e85a                	sd	s6,16(sp)
    800050d4:	0880                	addi	s0,sp,80
    800050d6:	84aa                	mv	s1,a0
    800050d8:	892e                	mv	s2,a1
    800050da:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800050dc:	ffffd097          	auipc	ra,0xffffd
    800050e0:	8ec080e7          	jalr	-1812(ra) # 800019c8 <myproc>
    800050e4:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800050e6:	8b26                	mv	s6,s1
    800050e8:	8526                	mv	a0,s1
    800050ea:	ffffc097          	auipc	ra,0xffffc
    800050ee:	afa080e7          	jalr	-1286(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050f2:	2184a703          	lw	a4,536(s1)
    800050f6:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800050fa:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050fe:	02f71463          	bne	a4,a5,80005126 <piperead+0x64>
    80005102:	2244a783          	lw	a5,548(s1)
    80005106:	c385                	beqz	a5,80005126 <piperead+0x64>
    if(pr->killed){
    80005108:	028a2783          	lw	a5,40(s4)
    8000510c:	ebc1                	bnez	a5,8000519c <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000510e:	85da                	mv	a1,s6
    80005110:	854e                	mv	a0,s3
    80005112:	ffffd097          	auipc	ra,0xffffd
    80005116:	322080e7          	jalr	802(ra) # 80002434 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000511a:	2184a703          	lw	a4,536(s1)
    8000511e:	21c4a783          	lw	a5,540(s1)
    80005122:	fef700e3          	beq	a4,a5,80005102 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005126:	09505263          	blez	s5,800051aa <piperead+0xe8>
    8000512a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000512c:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    8000512e:	2184a783          	lw	a5,536(s1)
    80005132:	21c4a703          	lw	a4,540(s1)
    80005136:	02f70d63          	beq	a4,a5,80005170 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000513a:	0017871b          	addiw	a4,a5,1
    8000513e:	20e4ac23          	sw	a4,536(s1)
    80005142:	1ff7f793          	andi	a5,a5,511
    80005146:	97a6                	add	a5,a5,s1
    80005148:	0187c783          	lbu	a5,24(a5)
    8000514c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005150:	4685                	li	a3,1
    80005152:	fbf40613          	addi	a2,s0,-65
    80005156:	85ca                	mv	a1,s2
    80005158:	050a3503          	ld	a0,80(s4)
    8000515c:	ffffc097          	auipc	ra,0xffffc
    80005160:	51e080e7          	jalr	1310(ra) # 8000167a <copyout>
    80005164:	01650663          	beq	a0,s6,80005170 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005168:	2985                	addiw	s3,s3,1
    8000516a:	0905                	addi	s2,s2,1
    8000516c:	fd3a91e3          	bne	s5,s3,8000512e <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005170:	21c48513          	addi	a0,s1,540
    80005174:	ffffd097          	auipc	ra,0xffffd
    80005178:	468080e7          	jalr	1128(ra) # 800025dc <wakeup>
  release(&pi->lock);
    8000517c:	8526                	mv	a0,s1
    8000517e:	ffffc097          	auipc	ra,0xffffc
    80005182:	b1a080e7          	jalr	-1254(ra) # 80000c98 <release>
  return i;
}
    80005186:	854e                	mv	a0,s3
    80005188:	60a6                	ld	ra,72(sp)
    8000518a:	6406                	ld	s0,64(sp)
    8000518c:	74e2                	ld	s1,56(sp)
    8000518e:	7942                	ld	s2,48(sp)
    80005190:	79a2                	ld	s3,40(sp)
    80005192:	7a02                	ld	s4,32(sp)
    80005194:	6ae2                	ld	s5,24(sp)
    80005196:	6b42                	ld	s6,16(sp)
    80005198:	6161                	addi	sp,sp,80
    8000519a:	8082                	ret
      release(&pi->lock);
    8000519c:	8526                	mv	a0,s1
    8000519e:	ffffc097          	auipc	ra,0xffffc
    800051a2:	afa080e7          	jalr	-1286(ra) # 80000c98 <release>
      return -1;
    800051a6:	59fd                	li	s3,-1
    800051a8:	bff9                	j	80005186 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051aa:	4981                	li	s3,0
    800051ac:	b7d1                	j	80005170 <piperead+0xae>

00000000800051ae <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800051ae:	df010113          	addi	sp,sp,-528
    800051b2:	20113423          	sd	ra,520(sp)
    800051b6:	20813023          	sd	s0,512(sp)
    800051ba:	ffa6                	sd	s1,504(sp)
    800051bc:	fbca                	sd	s2,496(sp)
    800051be:	f7ce                	sd	s3,488(sp)
    800051c0:	f3d2                	sd	s4,480(sp)
    800051c2:	efd6                	sd	s5,472(sp)
    800051c4:	ebda                	sd	s6,464(sp)
    800051c6:	e7de                	sd	s7,456(sp)
    800051c8:	e3e2                	sd	s8,448(sp)
    800051ca:	ff66                	sd	s9,440(sp)
    800051cc:	fb6a                	sd	s10,432(sp)
    800051ce:	f76e                	sd	s11,424(sp)
    800051d0:	0c00                	addi	s0,sp,528
    800051d2:	84aa                	mv	s1,a0
    800051d4:	dea43c23          	sd	a0,-520(s0)
    800051d8:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800051dc:	ffffc097          	auipc	ra,0xffffc
    800051e0:	7ec080e7          	jalr	2028(ra) # 800019c8 <myproc>
    800051e4:	892a                	mv	s2,a0

  begin_op();
    800051e6:	fffff097          	auipc	ra,0xfffff
    800051ea:	49c080e7          	jalr	1180(ra) # 80004682 <begin_op>

  if((ip = namei(path)) == 0){
    800051ee:	8526                	mv	a0,s1
    800051f0:	fffff097          	auipc	ra,0xfffff
    800051f4:	276080e7          	jalr	630(ra) # 80004466 <namei>
    800051f8:	c92d                	beqz	a0,8000526a <exec+0xbc>
    800051fa:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800051fc:	fffff097          	auipc	ra,0xfffff
    80005200:	ab4080e7          	jalr	-1356(ra) # 80003cb0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005204:	04000713          	li	a4,64
    80005208:	4681                	li	a3,0
    8000520a:	e5040613          	addi	a2,s0,-432
    8000520e:	4581                	li	a1,0
    80005210:	8526                	mv	a0,s1
    80005212:	fffff097          	auipc	ra,0xfffff
    80005216:	d52080e7          	jalr	-686(ra) # 80003f64 <readi>
    8000521a:	04000793          	li	a5,64
    8000521e:	00f51a63          	bne	a0,a5,80005232 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005222:	e5042703          	lw	a4,-432(s0)
    80005226:	464c47b7          	lui	a5,0x464c4
    8000522a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000522e:	04f70463          	beq	a4,a5,80005276 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005232:	8526                	mv	a0,s1
    80005234:	fffff097          	auipc	ra,0xfffff
    80005238:	cde080e7          	jalr	-802(ra) # 80003f12 <iunlockput>
    end_op();
    8000523c:	fffff097          	auipc	ra,0xfffff
    80005240:	4c6080e7          	jalr	1222(ra) # 80004702 <end_op>
  }
  return -1;
    80005244:	557d                	li	a0,-1
}
    80005246:	20813083          	ld	ra,520(sp)
    8000524a:	20013403          	ld	s0,512(sp)
    8000524e:	74fe                	ld	s1,504(sp)
    80005250:	795e                	ld	s2,496(sp)
    80005252:	79be                	ld	s3,488(sp)
    80005254:	7a1e                	ld	s4,480(sp)
    80005256:	6afe                	ld	s5,472(sp)
    80005258:	6b5e                	ld	s6,464(sp)
    8000525a:	6bbe                	ld	s7,456(sp)
    8000525c:	6c1e                	ld	s8,448(sp)
    8000525e:	7cfa                	ld	s9,440(sp)
    80005260:	7d5a                	ld	s10,432(sp)
    80005262:	7dba                	ld	s11,424(sp)
    80005264:	21010113          	addi	sp,sp,528
    80005268:	8082                	ret
    end_op();
    8000526a:	fffff097          	auipc	ra,0xfffff
    8000526e:	498080e7          	jalr	1176(ra) # 80004702 <end_op>
    return -1;
    80005272:	557d                	li	a0,-1
    80005274:	bfc9                	j	80005246 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005276:	854a                	mv	a0,s2
    80005278:	ffffd097          	auipc	ra,0xffffd
    8000527c:	814080e7          	jalr	-2028(ra) # 80001a8c <proc_pagetable>
    80005280:	8baa                	mv	s7,a0
    80005282:	d945                	beqz	a0,80005232 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005284:	e7042983          	lw	s3,-400(s0)
    80005288:	e8845783          	lhu	a5,-376(s0)
    8000528c:	c7ad                	beqz	a5,800052f6 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000528e:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005290:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005292:	6c85                	lui	s9,0x1
    80005294:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005298:	def43823          	sd	a5,-528(s0)
    8000529c:	a42d                	j	800054c6 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000529e:	00003517          	auipc	a0,0x3
    800052a2:	51250513          	addi	a0,a0,1298 # 800087b0 <syscalls+0x298>
    800052a6:	ffffb097          	auipc	ra,0xffffb
    800052aa:	298080e7          	jalr	664(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800052ae:	8756                	mv	a4,s5
    800052b0:	012d86bb          	addw	a3,s11,s2
    800052b4:	4581                	li	a1,0
    800052b6:	8526                	mv	a0,s1
    800052b8:	fffff097          	auipc	ra,0xfffff
    800052bc:	cac080e7          	jalr	-852(ra) # 80003f64 <readi>
    800052c0:	2501                	sext.w	a0,a0
    800052c2:	1aaa9963          	bne	s5,a0,80005474 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800052c6:	6785                	lui	a5,0x1
    800052c8:	0127893b          	addw	s2,a5,s2
    800052cc:	77fd                	lui	a5,0xfffff
    800052ce:	01478a3b          	addw	s4,a5,s4
    800052d2:	1f897163          	bgeu	s2,s8,800054b4 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800052d6:	02091593          	slli	a1,s2,0x20
    800052da:	9181                	srli	a1,a1,0x20
    800052dc:	95ea                	add	a1,a1,s10
    800052de:	855e                	mv	a0,s7
    800052e0:	ffffc097          	auipc	ra,0xffffc
    800052e4:	d96080e7          	jalr	-618(ra) # 80001076 <walkaddr>
    800052e8:	862a                	mv	a2,a0
    if(pa == 0)
    800052ea:	d955                	beqz	a0,8000529e <exec+0xf0>
      n = PGSIZE;
    800052ec:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800052ee:	fd9a70e3          	bgeu	s4,s9,800052ae <exec+0x100>
      n = sz - i;
    800052f2:	8ad2                	mv	s5,s4
    800052f4:	bf6d                	j	800052ae <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800052f6:	4901                	li	s2,0
  iunlockput(ip);
    800052f8:	8526                	mv	a0,s1
    800052fa:	fffff097          	auipc	ra,0xfffff
    800052fe:	c18080e7          	jalr	-1000(ra) # 80003f12 <iunlockput>
  end_op();
    80005302:	fffff097          	auipc	ra,0xfffff
    80005306:	400080e7          	jalr	1024(ra) # 80004702 <end_op>
  p = myproc();
    8000530a:	ffffc097          	auipc	ra,0xffffc
    8000530e:	6be080e7          	jalr	1726(ra) # 800019c8 <myproc>
    80005312:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005314:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005318:	6785                	lui	a5,0x1
    8000531a:	17fd                	addi	a5,a5,-1
    8000531c:	993e                	add	s2,s2,a5
    8000531e:	757d                	lui	a0,0xfffff
    80005320:	00a977b3          	and	a5,s2,a0
    80005324:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005328:	6609                	lui	a2,0x2
    8000532a:	963e                	add	a2,a2,a5
    8000532c:	85be                	mv	a1,a5
    8000532e:	855e                	mv	a0,s7
    80005330:	ffffc097          	auipc	ra,0xffffc
    80005334:	0fa080e7          	jalr	250(ra) # 8000142a <uvmalloc>
    80005338:	8b2a                	mv	s6,a0
  ip = 0;
    8000533a:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000533c:	12050c63          	beqz	a0,80005474 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005340:	75f9                	lui	a1,0xffffe
    80005342:	95aa                	add	a1,a1,a0
    80005344:	855e                	mv	a0,s7
    80005346:	ffffc097          	auipc	ra,0xffffc
    8000534a:	302080e7          	jalr	770(ra) # 80001648 <uvmclear>
  stackbase = sp - PGSIZE;
    8000534e:	7c7d                	lui	s8,0xfffff
    80005350:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005352:	e0043783          	ld	a5,-512(s0)
    80005356:	6388                	ld	a0,0(a5)
    80005358:	c535                	beqz	a0,800053c4 <exec+0x216>
    8000535a:	e9040993          	addi	s3,s0,-368
    8000535e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005362:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005364:	ffffc097          	auipc	ra,0xffffc
    80005368:	b00080e7          	jalr	-1280(ra) # 80000e64 <strlen>
    8000536c:	2505                	addiw	a0,a0,1
    8000536e:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005372:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005376:	13896363          	bltu	s2,s8,8000549c <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000537a:	e0043d83          	ld	s11,-512(s0)
    8000537e:	000dba03          	ld	s4,0(s11)
    80005382:	8552                	mv	a0,s4
    80005384:	ffffc097          	auipc	ra,0xffffc
    80005388:	ae0080e7          	jalr	-1312(ra) # 80000e64 <strlen>
    8000538c:	0015069b          	addiw	a3,a0,1
    80005390:	8652                	mv	a2,s4
    80005392:	85ca                	mv	a1,s2
    80005394:	855e                	mv	a0,s7
    80005396:	ffffc097          	auipc	ra,0xffffc
    8000539a:	2e4080e7          	jalr	740(ra) # 8000167a <copyout>
    8000539e:	10054363          	bltz	a0,800054a4 <exec+0x2f6>
    ustack[argc] = sp;
    800053a2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800053a6:	0485                	addi	s1,s1,1
    800053a8:	008d8793          	addi	a5,s11,8
    800053ac:	e0f43023          	sd	a5,-512(s0)
    800053b0:	008db503          	ld	a0,8(s11)
    800053b4:	c911                	beqz	a0,800053c8 <exec+0x21a>
    if(argc >= MAXARG)
    800053b6:	09a1                	addi	s3,s3,8
    800053b8:	fb3c96e3          	bne	s9,s3,80005364 <exec+0x1b6>
  sz = sz1;
    800053bc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053c0:	4481                	li	s1,0
    800053c2:	a84d                	j	80005474 <exec+0x2c6>
  sp = sz;
    800053c4:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800053c6:	4481                	li	s1,0
  ustack[argc] = 0;
    800053c8:	00349793          	slli	a5,s1,0x3
    800053cc:	f9040713          	addi	a4,s0,-112
    800053d0:	97ba                	add	a5,a5,a4
    800053d2:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800053d6:	00148693          	addi	a3,s1,1
    800053da:	068e                	slli	a3,a3,0x3
    800053dc:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800053e0:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800053e4:	01897663          	bgeu	s2,s8,800053f0 <exec+0x242>
  sz = sz1;
    800053e8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053ec:	4481                	li	s1,0
    800053ee:	a059                	j	80005474 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800053f0:	e9040613          	addi	a2,s0,-368
    800053f4:	85ca                	mv	a1,s2
    800053f6:	855e                	mv	a0,s7
    800053f8:	ffffc097          	auipc	ra,0xffffc
    800053fc:	282080e7          	jalr	642(ra) # 8000167a <copyout>
    80005400:	0a054663          	bltz	a0,800054ac <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005404:	058ab783          	ld	a5,88(s5)
    80005408:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000540c:	df843783          	ld	a5,-520(s0)
    80005410:	0007c703          	lbu	a4,0(a5)
    80005414:	cf11                	beqz	a4,80005430 <exec+0x282>
    80005416:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005418:	02f00693          	li	a3,47
    8000541c:	a039                	j	8000542a <exec+0x27c>
      last = s+1;
    8000541e:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005422:	0785                	addi	a5,a5,1
    80005424:	fff7c703          	lbu	a4,-1(a5)
    80005428:	c701                	beqz	a4,80005430 <exec+0x282>
    if(*s == '/')
    8000542a:	fed71ce3          	bne	a4,a3,80005422 <exec+0x274>
    8000542e:	bfc5                	j	8000541e <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005430:	4641                	li	a2,16
    80005432:	df843583          	ld	a1,-520(s0)
    80005436:	158a8513          	addi	a0,s5,344
    8000543a:	ffffc097          	auipc	ra,0xffffc
    8000543e:	9f8080e7          	jalr	-1544(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005442:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005446:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    8000544a:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000544e:	058ab783          	ld	a5,88(s5)
    80005452:	e6843703          	ld	a4,-408(s0)
    80005456:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005458:	058ab783          	ld	a5,88(s5)
    8000545c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005460:	85ea                	mv	a1,s10
    80005462:	ffffc097          	auipc	ra,0xffffc
    80005466:	6c6080e7          	jalr	1734(ra) # 80001b28 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000546a:	0004851b          	sext.w	a0,s1
    8000546e:	bbe1                	j	80005246 <exec+0x98>
    80005470:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005474:	e0843583          	ld	a1,-504(s0)
    80005478:	855e                	mv	a0,s7
    8000547a:	ffffc097          	auipc	ra,0xffffc
    8000547e:	6ae080e7          	jalr	1710(ra) # 80001b28 <proc_freepagetable>
  if(ip){
    80005482:	da0498e3          	bnez	s1,80005232 <exec+0x84>
  return -1;
    80005486:	557d                	li	a0,-1
    80005488:	bb7d                	j	80005246 <exec+0x98>
    8000548a:	e1243423          	sd	s2,-504(s0)
    8000548e:	b7dd                	j	80005474 <exec+0x2c6>
    80005490:	e1243423          	sd	s2,-504(s0)
    80005494:	b7c5                	j	80005474 <exec+0x2c6>
    80005496:	e1243423          	sd	s2,-504(s0)
    8000549a:	bfe9                	j	80005474 <exec+0x2c6>
  sz = sz1;
    8000549c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800054a0:	4481                	li	s1,0
    800054a2:	bfc9                	j	80005474 <exec+0x2c6>
  sz = sz1;
    800054a4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800054a8:	4481                	li	s1,0
    800054aa:	b7e9                	j	80005474 <exec+0x2c6>
  sz = sz1;
    800054ac:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800054b0:	4481                	li	s1,0
    800054b2:	b7c9                	j	80005474 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800054b4:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800054b8:	2b05                	addiw	s6,s6,1
    800054ba:	0389899b          	addiw	s3,s3,56
    800054be:	e8845783          	lhu	a5,-376(s0)
    800054c2:	e2fb5be3          	bge	s6,a5,800052f8 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800054c6:	2981                	sext.w	s3,s3
    800054c8:	03800713          	li	a4,56
    800054cc:	86ce                	mv	a3,s3
    800054ce:	e1840613          	addi	a2,s0,-488
    800054d2:	4581                	li	a1,0
    800054d4:	8526                	mv	a0,s1
    800054d6:	fffff097          	auipc	ra,0xfffff
    800054da:	a8e080e7          	jalr	-1394(ra) # 80003f64 <readi>
    800054de:	03800793          	li	a5,56
    800054e2:	f8f517e3          	bne	a0,a5,80005470 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800054e6:	e1842783          	lw	a5,-488(s0)
    800054ea:	4705                	li	a4,1
    800054ec:	fce796e3          	bne	a5,a4,800054b8 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800054f0:	e4043603          	ld	a2,-448(s0)
    800054f4:	e3843783          	ld	a5,-456(s0)
    800054f8:	f8f669e3          	bltu	a2,a5,8000548a <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800054fc:	e2843783          	ld	a5,-472(s0)
    80005500:	963e                	add	a2,a2,a5
    80005502:	f8f667e3          	bltu	a2,a5,80005490 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005506:	85ca                	mv	a1,s2
    80005508:	855e                	mv	a0,s7
    8000550a:	ffffc097          	auipc	ra,0xffffc
    8000550e:	f20080e7          	jalr	-224(ra) # 8000142a <uvmalloc>
    80005512:	e0a43423          	sd	a0,-504(s0)
    80005516:	d141                	beqz	a0,80005496 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005518:	e2843d03          	ld	s10,-472(s0)
    8000551c:	df043783          	ld	a5,-528(s0)
    80005520:	00fd77b3          	and	a5,s10,a5
    80005524:	fba1                	bnez	a5,80005474 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005526:	e2042d83          	lw	s11,-480(s0)
    8000552a:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000552e:	f80c03e3          	beqz	s8,800054b4 <exec+0x306>
    80005532:	8a62                	mv	s4,s8
    80005534:	4901                	li	s2,0
    80005536:	b345                	j	800052d6 <exec+0x128>

0000000080005538 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005538:	7179                	addi	sp,sp,-48
    8000553a:	f406                	sd	ra,40(sp)
    8000553c:	f022                	sd	s0,32(sp)
    8000553e:	ec26                	sd	s1,24(sp)
    80005540:	e84a                	sd	s2,16(sp)
    80005542:	1800                	addi	s0,sp,48
    80005544:	892e                	mv	s2,a1
    80005546:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005548:	fdc40593          	addi	a1,s0,-36
    8000554c:	ffffe097          	auipc	ra,0xffffe
    80005550:	b8e080e7          	jalr	-1138(ra) # 800030da <argint>
    80005554:	04054063          	bltz	a0,80005594 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005558:	fdc42703          	lw	a4,-36(s0)
    8000555c:	47bd                	li	a5,15
    8000555e:	02e7ed63          	bltu	a5,a4,80005598 <argfd+0x60>
    80005562:	ffffc097          	auipc	ra,0xffffc
    80005566:	466080e7          	jalr	1126(ra) # 800019c8 <myproc>
    8000556a:	fdc42703          	lw	a4,-36(s0)
    8000556e:	01a70793          	addi	a5,a4,26
    80005572:	078e                	slli	a5,a5,0x3
    80005574:	953e                	add	a0,a0,a5
    80005576:	611c                	ld	a5,0(a0)
    80005578:	c395                	beqz	a5,8000559c <argfd+0x64>
    return -1;
  if(pfd)
    8000557a:	00090463          	beqz	s2,80005582 <argfd+0x4a>
    *pfd = fd;
    8000557e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005582:	4501                	li	a0,0
  if(pf)
    80005584:	c091                	beqz	s1,80005588 <argfd+0x50>
    *pf = f;
    80005586:	e09c                	sd	a5,0(s1)
}
    80005588:	70a2                	ld	ra,40(sp)
    8000558a:	7402                	ld	s0,32(sp)
    8000558c:	64e2                	ld	s1,24(sp)
    8000558e:	6942                	ld	s2,16(sp)
    80005590:	6145                	addi	sp,sp,48
    80005592:	8082                	ret
    return -1;
    80005594:	557d                	li	a0,-1
    80005596:	bfcd                	j	80005588 <argfd+0x50>
    return -1;
    80005598:	557d                	li	a0,-1
    8000559a:	b7fd                	j	80005588 <argfd+0x50>
    8000559c:	557d                	li	a0,-1
    8000559e:	b7ed                	j	80005588 <argfd+0x50>

00000000800055a0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800055a0:	1101                	addi	sp,sp,-32
    800055a2:	ec06                	sd	ra,24(sp)
    800055a4:	e822                	sd	s0,16(sp)
    800055a6:	e426                	sd	s1,8(sp)
    800055a8:	1000                	addi	s0,sp,32
    800055aa:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800055ac:	ffffc097          	auipc	ra,0xffffc
    800055b0:	41c080e7          	jalr	1052(ra) # 800019c8 <myproc>
    800055b4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800055b6:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffe00d0>
    800055ba:	4501                	li	a0,0
    800055bc:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800055be:	6398                	ld	a4,0(a5)
    800055c0:	cb19                	beqz	a4,800055d6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800055c2:	2505                	addiw	a0,a0,1
    800055c4:	07a1                	addi	a5,a5,8
    800055c6:	fed51ce3          	bne	a0,a3,800055be <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800055ca:	557d                	li	a0,-1
}
    800055cc:	60e2                	ld	ra,24(sp)
    800055ce:	6442                	ld	s0,16(sp)
    800055d0:	64a2                	ld	s1,8(sp)
    800055d2:	6105                	addi	sp,sp,32
    800055d4:	8082                	ret
      p->ofile[fd] = f;
    800055d6:	01a50793          	addi	a5,a0,26
    800055da:	078e                	slli	a5,a5,0x3
    800055dc:	963e                	add	a2,a2,a5
    800055de:	e204                	sd	s1,0(a2)
      return fd;
    800055e0:	b7f5                	j	800055cc <fdalloc+0x2c>

00000000800055e2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800055e2:	715d                	addi	sp,sp,-80
    800055e4:	e486                	sd	ra,72(sp)
    800055e6:	e0a2                	sd	s0,64(sp)
    800055e8:	fc26                	sd	s1,56(sp)
    800055ea:	f84a                	sd	s2,48(sp)
    800055ec:	f44e                	sd	s3,40(sp)
    800055ee:	f052                	sd	s4,32(sp)
    800055f0:	ec56                	sd	s5,24(sp)
    800055f2:	0880                	addi	s0,sp,80
    800055f4:	89ae                	mv	s3,a1
    800055f6:	8ab2                	mv	s5,a2
    800055f8:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800055fa:	fb040593          	addi	a1,s0,-80
    800055fe:	fffff097          	auipc	ra,0xfffff
    80005602:	e86080e7          	jalr	-378(ra) # 80004484 <nameiparent>
    80005606:	892a                	mv	s2,a0
    80005608:	12050f63          	beqz	a0,80005746 <create+0x164>
    return 0;

  ilock(dp);
    8000560c:	ffffe097          	auipc	ra,0xffffe
    80005610:	6a4080e7          	jalr	1700(ra) # 80003cb0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005614:	4601                	li	a2,0
    80005616:	fb040593          	addi	a1,s0,-80
    8000561a:	854a                	mv	a0,s2
    8000561c:	fffff097          	auipc	ra,0xfffff
    80005620:	b78080e7          	jalr	-1160(ra) # 80004194 <dirlookup>
    80005624:	84aa                	mv	s1,a0
    80005626:	c921                	beqz	a0,80005676 <create+0x94>
    iunlockput(dp);
    80005628:	854a                	mv	a0,s2
    8000562a:	fffff097          	auipc	ra,0xfffff
    8000562e:	8e8080e7          	jalr	-1816(ra) # 80003f12 <iunlockput>
    ilock(ip);
    80005632:	8526                	mv	a0,s1
    80005634:	ffffe097          	auipc	ra,0xffffe
    80005638:	67c080e7          	jalr	1660(ra) # 80003cb0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000563c:	2981                	sext.w	s3,s3
    8000563e:	4789                	li	a5,2
    80005640:	02f99463          	bne	s3,a5,80005668 <create+0x86>
    80005644:	0444d783          	lhu	a5,68(s1)
    80005648:	37f9                	addiw	a5,a5,-2
    8000564a:	17c2                	slli	a5,a5,0x30
    8000564c:	93c1                	srli	a5,a5,0x30
    8000564e:	4705                	li	a4,1
    80005650:	00f76c63          	bltu	a4,a5,80005668 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005654:	8526                	mv	a0,s1
    80005656:	60a6                	ld	ra,72(sp)
    80005658:	6406                	ld	s0,64(sp)
    8000565a:	74e2                	ld	s1,56(sp)
    8000565c:	7942                	ld	s2,48(sp)
    8000565e:	79a2                	ld	s3,40(sp)
    80005660:	7a02                	ld	s4,32(sp)
    80005662:	6ae2                	ld	s5,24(sp)
    80005664:	6161                	addi	sp,sp,80
    80005666:	8082                	ret
    iunlockput(ip);
    80005668:	8526                	mv	a0,s1
    8000566a:	fffff097          	auipc	ra,0xfffff
    8000566e:	8a8080e7          	jalr	-1880(ra) # 80003f12 <iunlockput>
    return 0;
    80005672:	4481                	li	s1,0
    80005674:	b7c5                	j	80005654 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005676:	85ce                	mv	a1,s3
    80005678:	00092503          	lw	a0,0(s2)
    8000567c:	ffffe097          	auipc	ra,0xffffe
    80005680:	49c080e7          	jalr	1180(ra) # 80003b18 <ialloc>
    80005684:	84aa                	mv	s1,a0
    80005686:	c529                	beqz	a0,800056d0 <create+0xee>
  ilock(ip);
    80005688:	ffffe097          	auipc	ra,0xffffe
    8000568c:	628080e7          	jalr	1576(ra) # 80003cb0 <ilock>
  ip->major = major;
    80005690:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005694:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005698:	4785                	li	a5,1
    8000569a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000569e:	8526                	mv	a0,s1
    800056a0:	ffffe097          	auipc	ra,0xffffe
    800056a4:	546080e7          	jalr	1350(ra) # 80003be6 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800056a8:	2981                	sext.w	s3,s3
    800056aa:	4785                	li	a5,1
    800056ac:	02f98a63          	beq	s3,a5,800056e0 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800056b0:	40d0                	lw	a2,4(s1)
    800056b2:	fb040593          	addi	a1,s0,-80
    800056b6:	854a                	mv	a0,s2
    800056b8:	fffff097          	auipc	ra,0xfffff
    800056bc:	cec080e7          	jalr	-788(ra) # 800043a4 <dirlink>
    800056c0:	06054b63          	bltz	a0,80005736 <create+0x154>
  iunlockput(dp);
    800056c4:	854a                	mv	a0,s2
    800056c6:	fffff097          	auipc	ra,0xfffff
    800056ca:	84c080e7          	jalr	-1972(ra) # 80003f12 <iunlockput>
  return ip;
    800056ce:	b759                	j	80005654 <create+0x72>
    panic("create: ialloc");
    800056d0:	00003517          	auipc	a0,0x3
    800056d4:	10050513          	addi	a0,a0,256 # 800087d0 <syscalls+0x2b8>
    800056d8:	ffffb097          	auipc	ra,0xffffb
    800056dc:	e66080e7          	jalr	-410(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800056e0:	04a95783          	lhu	a5,74(s2)
    800056e4:	2785                	addiw	a5,a5,1
    800056e6:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800056ea:	854a                	mv	a0,s2
    800056ec:	ffffe097          	auipc	ra,0xffffe
    800056f0:	4fa080e7          	jalr	1274(ra) # 80003be6 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800056f4:	40d0                	lw	a2,4(s1)
    800056f6:	00003597          	auipc	a1,0x3
    800056fa:	0ea58593          	addi	a1,a1,234 # 800087e0 <syscalls+0x2c8>
    800056fe:	8526                	mv	a0,s1
    80005700:	fffff097          	auipc	ra,0xfffff
    80005704:	ca4080e7          	jalr	-860(ra) # 800043a4 <dirlink>
    80005708:	00054f63          	bltz	a0,80005726 <create+0x144>
    8000570c:	00492603          	lw	a2,4(s2)
    80005710:	00003597          	auipc	a1,0x3
    80005714:	0d858593          	addi	a1,a1,216 # 800087e8 <syscalls+0x2d0>
    80005718:	8526                	mv	a0,s1
    8000571a:	fffff097          	auipc	ra,0xfffff
    8000571e:	c8a080e7          	jalr	-886(ra) # 800043a4 <dirlink>
    80005722:	f80557e3          	bgez	a0,800056b0 <create+0xce>
      panic("create dots");
    80005726:	00003517          	auipc	a0,0x3
    8000572a:	0ca50513          	addi	a0,a0,202 # 800087f0 <syscalls+0x2d8>
    8000572e:	ffffb097          	auipc	ra,0xffffb
    80005732:	e10080e7          	jalr	-496(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005736:	00003517          	auipc	a0,0x3
    8000573a:	0ca50513          	addi	a0,a0,202 # 80008800 <syscalls+0x2e8>
    8000573e:	ffffb097          	auipc	ra,0xffffb
    80005742:	e00080e7          	jalr	-512(ra) # 8000053e <panic>
    return 0;
    80005746:	84aa                	mv	s1,a0
    80005748:	b731                	j	80005654 <create+0x72>

000000008000574a <sys_dup>:
{
    8000574a:	7179                	addi	sp,sp,-48
    8000574c:	f406                	sd	ra,40(sp)
    8000574e:	f022                	sd	s0,32(sp)
    80005750:	ec26                	sd	s1,24(sp)
    80005752:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005754:	fd840613          	addi	a2,s0,-40
    80005758:	4581                	li	a1,0
    8000575a:	4501                	li	a0,0
    8000575c:	00000097          	auipc	ra,0x0
    80005760:	ddc080e7          	jalr	-548(ra) # 80005538 <argfd>
    return -1;
    80005764:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005766:	02054363          	bltz	a0,8000578c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000576a:	fd843503          	ld	a0,-40(s0)
    8000576e:	00000097          	auipc	ra,0x0
    80005772:	e32080e7          	jalr	-462(ra) # 800055a0 <fdalloc>
    80005776:	84aa                	mv	s1,a0
    return -1;
    80005778:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000577a:	00054963          	bltz	a0,8000578c <sys_dup+0x42>
  filedup(f);
    8000577e:	fd843503          	ld	a0,-40(s0)
    80005782:	fffff097          	auipc	ra,0xfffff
    80005786:	37a080e7          	jalr	890(ra) # 80004afc <filedup>
  return fd;
    8000578a:	87a6                	mv	a5,s1
}
    8000578c:	853e                	mv	a0,a5
    8000578e:	70a2                	ld	ra,40(sp)
    80005790:	7402                	ld	s0,32(sp)
    80005792:	64e2                	ld	s1,24(sp)
    80005794:	6145                	addi	sp,sp,48
    80005796:	8082                	ret

0000000080005798 <sys_read>:
{
    80005798:	7179                	addi	sp,sp,-48
    8000579a:	f406                	sd	ra,40(sp)
    8000579c:	f022                	sd	s0,32(sp)
    8000579e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057a0:	fe840613          	addi	a2,s0,-24
    800057a4:	4581                	li	a1,0
    800057a6:	4501                	li	a0,0
    800057a8:	00000097          	auipc	ra,0x0
    800057ac:	d90080e7          	jalr	-624(ra) # 80005538 <argfd>
    return -1;
    800057b0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057b2:	04054163          	bltz	a0,800057f4 <sys_read+0x5c>
    800057b6:	fe440593          	addi	a1,s0,-28
    800057ba:	4509                	li	a0,2
    800057bc:	ffffe097          	auipc	ra,0xffffe
    800057c0:	91e080e7          	jalr	-1762(ra) # 800030da <argint>
    return -1;
    800057c4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057c6:	02054763          	bltz	a0,800057f4 <sys_read+0x5c>
    800057ca:	fd840593          	addi	a1,s0,-40
    800057ce:	4505                	li	a0,1
    800057d0:	ffffe097          	auipc	ra,0xffffe
    800057d4:	92c080e7          	jalr	-1748(ra) # 800030fc <argaddr>
    return -1;
    800057d8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057da:	00054d63          	bltz	a0,800057f4 <sys_read+0x5c>
  return fileread(f, p, n);
    800057de:	fe442603          	lw	a2,-28(s0)
    800057e2:	fd843583          	ld	a1,-40(s0)
    800057e6:	fe843503          	ld	a0,-24(s0)
    800057ea:	fffff097          	auipc	ra,0xfffff
    800057ee:	49e080e7          	jalr	1182(ra) # 80004c88 <fileread>
    800057f2:	87aa                	mv	a5,a0
}
    800057f4:	853e                	mv	a0,a5
    800057f6:	70a2                	ld	ra,40(sp)
    800057f8:	7402                	ld	s0,32(sp)
    800057fa:	6145                	addi	sp,sp,48
    800057fc:	8082                	ret

00000000800057fe <sys_write>:
{
    800057fe:	7179                	addi	sp,sp,-48
    80005800:	f406                	sd	ra,40(sp)
    80005802:	f022                	sd	s0,32(sp)
    80005804:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005806:	fe840613          	addi	a2,s0,-24
    8000580a:	4581                	li	a1,0
    8000580c:	4501                	li	a0,0
    8000580e:	00000097          	auipc	ra,0x0
    80005812:	d2a080e7          	jalr	-726(ra) # 80005538 <argfd>
    return -1;
    80005816:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005818:	04054163          	bltz	a0,8000585a <sys_write+0x5c>
    8000581c:	fe440593          	addi	a1,s0,-28
    80005820:	4509                	li	a0,2
    80005822:	ffffe097          	auipc	ra,0xffffe
    80005826:	8b8080e7          	jalr	-1864(ra) # 800030da <argint>
    return -1;
    8000582a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000582c:	02054763          	bltz	a0,8000585a <sys_write+0x5c>
    80005830:	fd840593          	addi	a1,s0,-40
    80005834:	4505                	li	a0,1
    80005836:	ffffe097          	auipc	ra,0xffffe
    8000583a:	8c6080e7          	jalr	-1850(ra) # 800030fc <argaddr>
    return -1;
    8000583e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005840:	00054d63          	bltz	a0,8000585a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005844:	fe442603          	lw	a2,-28(s0)
    80005848:	fd843583          	ld	a1,-40(s0)
    8000584c:	fe843503          	ld	a0,-24(s0)
    80005850:	fffff097          	auipc	ra,0xfffff
    80005854:	4fa080e7          	jalr	1274(ra) # 80004d4a <filewrite>
    80005858:	87aa                	mv	a5,a0
}
    8000585a:	853e                	mv	a0,a5
    8000585c:	70a2                	ld	ra,40(sp)
    8000585e:	7402                	ld	s0,32(sp)
    80005860:	6145                	addi	sp,sp,48
    80005862:	8082                	ret

0000000080005864 <sys_close>:
{
    80005864:	1101                	addi	sp,sp,-32
    80005866:	ec06                	sd	ra,24(sp)
    80005868:	e822                	sd	s0,16(sp)
    8000586a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000586c:	fe040613          	addi	a2,s0,-32
    80005870:	fec40593          	addi	a1,s0,-20
    80005874:	4501                	li	a0,0
    80005876:	00000097          	auipc	ra,0x0
    8000587a:	cc2080e7          	jalr	-830(ra) # 80005538 <argfd>
    return -1;
    8000587e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005880:	02054463          	bltz	a0,800058a8 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005884:	ffffc097          	auipc	ra,0xffffc
    80005888:	144080e7          	jalr	324(ra) # 800019c8 <myproc>
    8000588c:	fec42783          	lw	a5,-20(s0)
    80005890:	07e9                	addi	a5,a5,26
    80005892:	078e                	slli	a5,a5,0x3
    80005894:	97aa                	add	a5,a5,a0
    80005896:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000589a:	fe043503          	ld	a0,-32(s0)
    8000589e:	fffff097          	auipc	ra,0xfffff
    800058a2:	2b0080e7          	jalr	688(ra) # 80004b4e <fileclose>
  return 0;
    800058a6:	4781                	li	a5,0
}
    800058a8:	853e                	mv	a0,a5
    800058aa:	60e2                	ld	ra,24(sp)
    800058ac:	6442                	ld	s0,16(sp)
    800058ae:	6105                	addi	sp,sp,32
    800058b0:	8082                	ret

00000000800058b2 <sys_fstat>:
{
    800058b2:	1101                	addi	sp,sp,-32
    800058b4:	ec06                	sd	ra,24(sp)
    800058b6:	e822                	sd	s0,16(sp)
    800058b8:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800058ba:	fe840613          	addi	a2,s0,-24
    800058be:	4581                	li	a1,0
    800058c0:	4501                	li	a0,0
    800058c2:	00000097          	auipc	ra,0x0
    800058c6:	c76080e7          	jalr	-906(ra) # 80005538 <argfd>
    return -1;
    800058ca:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800058cc:	02054563          	bltz	a0,800058f6 <sys_fstat+0x44>
    800058d0:	fe040593          	addi	a1,s0,-32
    800058d4:	4505                	li	a0,1
    800058d6:	ffffe097          	auipc	ra,0xffffe
    800058da:	826080e7          	jalr	-2010(ra) # 800030fc <argaddr>
    return -1;
    800058de:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800058e0:	00054b63          	bltz	a0,800058f6 <sys_fstat+0x44>
  return filestat(f, st);
    800058e4:	fe043583          	ld	a1,-32(s0)
    800058e8:	fe843503          	ld	a0,-24(s0)
    800058ec:	fffff097          	auipc	ra,0xfffff
    800058f0:	32a080e7          	jalr	810(ra) # 80004c16 <filestat>
    800058f4:	87aa                	mv	a5,a0
}
    800058f6:	853e                	mv	a0,a5
    800058f8:	60e2                	ld	ra,24(sp)
    800058fa:	6442                	ld	s0,16(sp)
    800058fc:	6105                	addi	sp,sp,32
    800058fe:	8082                	ret

0000000080005900 <sys_link>:
{
    80005900:	7169                	addi	sp,sp,-304
    80005902:	f606                	sd	ra,296(sp)
    80005904:	f222                	sd	s0,288(sp)
    80005906:	ee26                	sd	s1,280(sp)
    80005908:	ea4a                	sd	s2,272(sp)
    8000590a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000590c:	08000613          	li	a2,128
    80005910:	ed040593          	addi	a1,s0,-304
    80005914:	4501                	li	a0,0
    80005916:	ffffe097          	auipc	ra,0xffffe
    8000591a:	808080e7          	jalr	-2040(ra) # 8000311e <argstr>
    return -1;
    8000591e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005920:	10054e63          	bltz	a0,80005a3c <sys_link+0x13c>
    80005924:	08000613          	li	a2,128
    80005928:	f5040593          	addi	a1,s0,-176
    8000592c:	4505                	li	a0,1
    8000592e:	ffffd097          	auipc	ra,0xffffd
    80005932:	7f0080e7          	jalr	2032(ra) # 8000311e <argstr>
    return -1;
    80005936:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005938:	10054263          	bltz	a0,80005a3c <sys_link+0x13c>
  begin_op();
    8000593c:	fffff097          	auipc	ra,0xfffff
    80005940:	d46080e7          	jalr	-698(ra) # 80004682 <begin_op>
  if((ip = namei(old)) == 0){
    80005944:	ed040513          	addi	a0,s0,-304
    80005948:	fffff097          	auipc	ra,0xfffff
    8000594c:	b1e080e7          	jalr	-1250(ra) # 80004466 <namei>
    80005950:	84aa                	mv	s1,a0
    80005952:	c551                	beqz	a0,800059de <sys_link+0xde>
  ilock(ip);
    80005954:	ffffe097          	auipc	ra,0xffffe
    80005958:	35c080e7          	jalr	860(ra) # 80003cb0 <ilock>
  if(ip->type == T_DIR){
    8000595c:	04449703          	lh	a4,68(s1)
    80005960:	4785                	li	a5,1
    80005962:	08f70463          	beq	a4,a5,800059ea <sys_link+0xea>
  ip->nlink++;
    80005966:	04a4d783          	lhu	a5,74(s1)
    8000596a:	2785                	addiw	a5,a5,1
    8000596c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005970:	8526                	mv	a0,s1
    80005972:	ffffe097          	auipc	ra,0xffffe
    80005976:	274080e7          	jalr	628(ra) # 80003be6 <iupdate>
  iunlock(ip);
    8000597a:	8526                	mv	a0,s1
    8000597c:	ffffe097          	auipc	ra,0xffffe
    80005980:	3f6080e7          	jalr	1014(ra) # 80003d72 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005984:	fd040593          	addi	a1,s0,-48
    80005988:	f5040513          	addi	a0,s0,-176
    8000598c:	fffff097          	auipc	ra,0xfffff
    80005990:	af8080e7          	jalr	-1288(ra) # 80004484 <nameiparent>
    80005994:	892a                	mv	s2,a0
    80005996:	c935                	beqz	a0,80005a0a <sys_link+0x10a>
  ilock(dp);
    80005998:	ffffe097          	auipc	ra,0xffffe
    8000599c:	318080e7          	jalr	792(ra) # 80003cb0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800059a0:	00092703          	lw	a4,0(s2)
    800059a4:	409c                	lw	a5,0(s1)
    800059a6:	04f71d63          	bne	a4,a5,80005a00 <sys_link+0x100>
    800059aa:	40d0                	lw	a2,4(s1)
    800059ac:	fd040593          	addi	a1,s0,-48
    800059b0:	854a                	mv	a0,s2
    800059b2:	fffff097          	auipc	ra,0xfffff
    800059b6:	9f2080e7          	jalr	-1550(ra) # 800043a4 <dirlink>
    800059ba:	04054363          	bltz	a0,80005a00 <sys_link+0x100>
  iunlockput(dp);
    800059be:	854a                	mv	a0,s2
    800059c0:	ffffe097          	auipc	ra,0xffffe
    800059c4:	552080e7          	jalr	1362(ra) # 80003f12 <iunlockput>
  iput(ip);
    800059c8:	8526                	mv	a0,s1
    800059ca:	ffffe097          	auipc	ra,0xffffe
    800059ce:	4a0080e7          	jalr	1184(ra) # 80003e6a <iput>
  end_op();
    800059d2:	fffff097          	auipc	ra,0xfffff
    800059d6:	d30080e7          	jalr	-720(ra) # 80004702 <end_op>
  return 0;
    800059da:	4781                	li	a5,0
    800059dc:	a085                	j	80005a3c <sys_link+0x13c>
    end_op();
    800059de:	fffff097          	auipc	ra,0xfffff
    800059e2:	d24080e7          	jalr	-732(ra) # 80004702 <end_op>
    return -1;
    800059e6:	57fd                	li	a5,-1
    800059e8:	a891                	j	80005a3c <sys_link+0x13c>
    iunlockput(ip);
    800059ea:	8526                	mv	a0,s1
    800059ec:	ffffe097          	auipc	ra,0xffffe
    800059f0:	526080e7          	jalr	1318(ra) # 80003f12 <iunlockput>
    end_op();
    800059f4:	fffff097          	auipc	ra,0xfffff
    800059f8:	d0e080e7          	jalr	-754(ra) # 80004702 <end_op>
    return -1;
    800059fc:	57fd                	li	a5,-1
    800059fe:	a83d                	j	80005a3c <sys_link+0x13c>
    iunlockput(dp);
    80005a00:	854a                	mv	a0,s2
    80005a02:	ffffe097          	auipc	ra,0xffffe
    80005a06:	510080e7          	jalr	1296(ra) # 80003f12 <iunlockput>
  ilock(ip);
    80005a0a:	8526                	mv	a0,s1
    80005a0c:	ffffe097          	auipc	ra,0xffffe
    80005a10:	2a4080e7          	jalr	676(ra) # 80003cb0 <ilock>
  ip->nlink--;
    80005a14:	04a4d783          	lhu	a5,74(s1)
    80005a18:	37fd                	addiw	a5,a5,-1
    80005a1a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a1e:	8526                	mv	a0,s1
    80005a20:	ffffe097          	auipc	ra,0xffffe
    80005a24:	1c6080e7          	jalr	454(ra) # 80003be6 <iupdate>
  iunlockput(ip);
    80005a28:	8526                	mv	a0,s1
    80005a2a:	ffffe097          	auipc	ra,0xffffe
    80005a2e:	4e8080e7          	jalr	1256(ra) # 80003f12 <iunlockput>
  end_op();
    80005a32:	fffff097          	auipc	ra,0xfffff
    80005a36:	cd0080e7          	jalr	-816(ra) # 80004702 <end_op>
  return -1;
    80005a3a:	57fd                	li	a5,-1
}
    80005a3c:	853e                	mv	a0,a5
    80005a3e:	70b2                	ld	ra,296(sp)
    80005a40:	7412                	ld	s0,288(sp)
    80005a42:	64f2                	ld	s1,280(sp)
    80005a44:	6952                	ld	s2,272(sp)
    80005a46:	6155                	addi	sp,sp,304
    80005a48:	8082                	ret

0000000080005a4a <sys_unlink>:
{
    80005a4a:	7151                	addi	sp,sp,-240
    80005a4c:	f586                	sd	ra,232(sp)
    80005a4e:	f1a2                	sd	s0,224(sp)
    80005a50:	eda6                	sd	s1,216(sp)
    80005a52:	e9ca                	sd	s2,208(sp)
    80005a54:	e5ce                	sd	s3,200(sp)
    80005a56:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005a58:	08000613          	li	a2,128
    80005a5c:	f3040593          	addi	a1,s0,-208
    80005a60:	4501                	li	a0,0
    80005a62:	ffffd097          	auipc	ra,0xffffd
    80005a66:	6bc080e7          	jalr	1724(ra) # 8000311e <argstr>
    80005a6a:	18054163          	bltz	a0,80005bec <sys_unlink+0x1a2>
  begin_op();
    80005a6e:	fffff097          	auipc	ra,0xfffff
    80005a72:	c14080e7          	jalr	-1004(ra) # 80004682 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005a76:	fb040593          	addi	a1,s0,-80
    80005a7a:	f3040513          	addi	a0,s0,-208
    80005a7e:	fffff097          	auipc	ra,0xfffff
    80005a82:	a06080e7          	jalr	-1530(ra) # 80004484 <nameiparent>
    80005a86:	84aa                	mv	s1,a0
    80005a88:	c979                	beqz	a0,80005b5e <sys_unlink+0x114>
  ilock(dp);
    80005a8a:	ffffe097          	auipc	ra,0xffffe
    80005a8e:	226080e7          	jalr	550(ra) # 80003cb0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005a92:	00003597          	auipc	a1,0x3
    80005a96:	d4e58593          	addi	a1,a1,-690 # 800087e0 <syscalls+0x2c8>
    80005a9a:	fb040513          	addi	a0,s0,-80
    80005a9e:	ffffe097          	auipc	ra,0xffffe
    80005aa2:	6dc080e7          	jalr	1756(ra) # 8000417a <namecmp>
    80005aa6:	14050a63          	beqz	a0,80005bfa <sys_unlink+0x1b0>
    80005aaa:	00003597          	auipc	a1,0x3
    80005aae:	d3e58593          	addi	a1,a1,-706 # 800087e8 <syscalls+0x2d0>
    80005ab2:	fb040513          	addi	a0,s0,-80
    80005ab6:	ffffe097          	auipc	ra,0xffffe
    80005aba:	6c4080e7          	jalr	1732(ra) # 8000417a <namecmp>
    80005abe:	12050e63          	beqz	a0,80005bfa <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005ac2:	f2c40613          	addi	a2,s0,-212
    80005ac6:	fb040593          	addi	a1,s0,-80
    80005aca:	8526                	mv	a0,s1
    80005acc:	ffffe097          	auipc	ra,0xffffe
    80005ad0:	6c8080e7          	jalr	1736(ra) # 80004194 <dirlookup>
    80005ad4:	892a                	mv	s2,a0
    80005ad6:	12050263          	beqz	a0,80005bfa <sys_unlink+0x1b0>
  ilock(ip);
    80005ada:	ffffe097          	auipc	ra,0xffffe
    80005ade:	1d6080e7          	jalr	470(ra) # 80003cb0 <ilock>
  if(ip->nlink < 1)
    80005ae2:	04a91783          	lh	a5,74(s2)
    80005ae6:	08f05263          	blez	a5,80005b6a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005aea:	04491703          	lh	a4,68(s2)
    80005aee:	4785                	li	a5,1
    80005af0:	08f70563          	beq	a4,a5,80005b7a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005af4:	4641                	li	a2,16
    80005af6:	4581                	li	a1,0
    80005af8:	fc040513          	addi	a0,s0,-64
    80005afc:	ffffb097          	auipc	ra,0xffffb
    80005b00:	1e4080e7          	jalr	484(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b04:	4741                	li	a4,16
    80005b06:	f2c42683          	lw	a3,-212(s0)
    80005b0a:	fc040613          	addi	a2,s0,-64
    80005b0e:	4581                	li	a1,0
    80005b10:	8526                	mv	a0,s1
    80005b12:	ffffe097          	auipc	ra,0xffffe
    80005b16:	54a080e7          	jalr	1354(ra) # 8000405c <writei>
    80005b1a:	47c1                	li	a5,16
    80005b1c:	0af51563          	bne	a0,a5,80005bc6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005b20:	04491703          	lh	a4,68(s2)
    80005b24:	4785                	li	a5,1
    80005b26:	0af70863          	beq	a4,a5,80005bd6 <sys_unlink+0x18c>
  iunlockput(dp);
    80005b2a:	8526                	mv	a0,s1
    80005b2c:	ffffe097          	auipc	ra,0xffffe
    80005b30:	3e6080e7          	jalr	998(ra) # 80003f12 <iunlockput>
  ip->nlink--;
    80005b34:	04a95783          	lhu	a5,74(s2)
    80005b38:	37fd                	addiw	a5,a5,-1
    80005b3a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005b3e:	854a                	mv	a0,s2
    80005b40:	ffffe097          	auipc	ra,0xffffe
    80005b44:	0a6080e7          	jalr	166(ra) # 80003be6 <iupdate>
  iunlockput(ip);
    80005b48:	854a                	mv	a0,s2
    80005b4a:	ffffe097          	auipc	ra,0xffffe
    80005b4e:	3c8080e7          	jalr	968(ra) # 80003f12 <iunlockput>
  end_op();
    80005b52:	fffff097          	auipc	ra,0xfffff
    80005b56:	bb0080e7          	jalr	-1104(ra) # 80004702 <end_op>
  return 0;
    80005b5a:	4501                	li	a0,0
    80005b5c:	a84d                	j	80005c0e <sys_unlink+0x1c4>
    end_op();
    80005b5e:	fffff097          	auipc	ra,0xfffff
    80005b62:	ba4080e7          	jalr	-1116(ra) # 80004702 <end_op>
    return -1;
    80005b66:	557d                	li	a0,-1
    80005b68:	a05d                	j	80005c0e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005b6a:	00003517          	auipc	a0,0x3
    80005b6e:	ca650513          	addi	a0,a0,-858 # 80008810 <syscalls+0x2f8>
    80005b72:	ffffb097          	auipc	ra,0xffffb
    80005b76:	9cc080e7          	jalr	-1588(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b7a:	04c92703          	lw	a4,76(s2)
    80005b7e:	02000793          	li	a5,32
    80005b82:	f6e7f9e3          	bgeu	a5,a4,80005af4 <sys_unlink+0xaa>
    80005b86:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b8a:	4741                	li	a4,16
    80005b8c:	86ce                	mv	a3,s3
    80005b8e:	f1840613          	addi	a2,s0,-232
    80005b92:	4581                	li	a1,0
    80005b94:	854a                	mv	a0,s2
    80005b96:	ffffe097          	auipc	ra,0xffffe
    80005b9a:	3ce080e7          	jalr	974(ra) # 80003f64 <readi>
    80005b9e:	47c1                	li	a5,16
    80005ba0:	00f51b63          	bne	a0,a5,80005bb6 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005ba4:	f1845783          	lhu	a5,-232(s0)
    80005ba8:	e7a1                	bnez	a5,80005bf0 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005baa:	29c1                	addiw	s3,s3,16
    80005bac:	04c92783          	lw	a5,76(s2)
    80005bb0:	fcf9ede3          	bltu	s3,a5,80005b8a <sys_unlink+0x140>
    80005bb4:	b781                	j	80005af4 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005bb6:	00003517          	auipc	a0,0x3
    80005bba:	c7250513          	addi	a0,a0,-910 # 80008828 <syscalls+0x310>
    80005bbe:	ffffb097          	auipc	ra,0xffffb
    80005bc2:	980080e7          	jalr	-1664(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005bc6:	00003517          	auipc	a0,0x3
    80005bca:	c7a50513          	addi	a0,a0,-902 # 80008840 <syscalls+0x328>
    80005bce:	ffffb097          	auipc	ra,0xffffb
    80005bd2:	970080e7          	jalr	-1680(ra) # 8000053e <panic>
    dp->nlink--;
    80005bd6:	04a4d783          	lhu	a5,74(s1)
    80005bda:	37fd                	addiw	a5,a5,-1
    80005bdc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005be0:	8526                	mv	a0,s1
    80005be2:	ffffe097          	auipc	ra,0xffffe
    80005be6:	004080e7          	jalr	4(ra) # 80003be6 <iupdate>
    80005bea:	b781                	j	80005b2a <sys_unlink+0xe0>
    return -1;
    80005bec:	557d                	li	a0,-1
    80005bee:	a005                	j	80005c0e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005bf0:	854a                	mv	a0,s2
    80005bf2:	ffffe097          	auipc	ra,0xffffe
    80005bf6:	320080e7          	jalr	800(ra) # 80003f12 <iunlockput>
  iunlockput(dp);
    80005bfa:	8526                	mv	a0,s1
    80005bfc:	ffffe097          	auipc	ra,0xffffe
    80005c00:	316080e7          	jalr	790(ra) # 80003f12 <iunlockput>
  end_op();
    80005c04:	fffff097          	auipc	ra,0xfffff
    80005c08:	afe080e7          	jalr	-1282(ra) # 80004702 <end_op>
  return -1;
    80005c0c:	557d                	li	a0,-1
}
    80005c0e:	70ae                	ld	ra,232(sp)
    80005c10:	740e                	ld	s0,224(sp)
    80005c12:	64ee                	ld	s1,216(sp)
    80005c14:	694e                	ld	s2,208(sp)
    80005c16:	69ae                	ld	s3,200(sp)
    80005c18:	616d                	addi	sp,sp,240
    80005c1a:	8082                	ret

0000000080005c1c <sys_open>:

uint64
sys_open(void)
{
    80005c1c:	7131                	addi	sp,sp,-192
    80005c1e:	fd06                	sd	ra,184(sp)
    80005c20:	f922                	sd	s0,176(sp)
    80005c22:	f526                	sd	s1,168(sp)
    80005c24:	f14a                	sd	s2,160(sp)
    80005c26:	ed4e                	sd	s3,152(sp)
    80005c28:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c2a:	08000613          	li	a2,128
    80005c2e:	f5040593          	addi	a1,s0,-176
    80005c32:	4501                	li	a0,0
    80005c34:	ffffd097          	auipc	ra,0xffffd
    80005c38:	4ea080e7          	jalr	1258(ra) # 8000311e <argstr>
    return -1;
    80005c3c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c3e:	0c054163          	bltz	a0,80005d00 <sys_open+0xe4>
    80005c42:	f4c40593          	addi	a1,s0,-180
    80005c46:	4505                	li	a0,1
    80005c48:	ffffd097          	auipc	ra,0xffffd
    80005c4c:	492080e7          	jalr	1170(ra) # 800030da <argint>
    80005c50:	0a054863          	bltz	a0,80005d00 <sys_open+0xe4>

  begin_op();
    80005c54:	fffff097          	auipc	ra,0xfffff
    80005c58:	a2e080e7          	jalr	-1490(ra) # 80004682 <begin_op>

  if(omode & O_CREATE){
    80005c5c:	f4c42783          	lw	a5,-180(s0)
    80005c60:	2007f793          	andi	a5,a5,512
    80005c64:	cbdd                	beqz	a5,80005d1a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005c66:	4681                	li	a3,0
    80005c68:	4601                	li	a2,0
    80005c6a:	4589                	li	a1,2
    80005c6c:	f5040513          	addi	a0,s0,-176
    80005c70:	00000097          	auipc	ra,0x0
    80005c74:	972080e7          	jalr	-1678(ra) # 800055e2 <create>
    80005c78:	892a                	mv	s2,a0
    if(ip == 0){
    80005c7a:	c959                	beqz	a0,80005d10 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005c7c:	04491703          	lh	a4,68(s2)
    80005c80:	478d                	li	a5,3
    80005c82:	00f71763          	bne	a4,a5,80005c90 <sys_open+0x74>
    80005c86:	04695703          	lhu	a4,70(s2)
    80005c8a:	47a5                	li	a5,9
    80005c8c:	0ce7ec63          	bltu	a5,a4,80005d64 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005c90:	fffff097          	auipc	ra,0xfffff
    80005c94:	e02080e7          	jalr	-510(ra) # 80004a92 <filealloc>
    80005c98:	89aa                	mv	s3,a0
    80005c9a:	10050263          	beqz	a0,80005d9e <sys_open+0x182>
    80005c9e:	00000097          	auipc	ra,0x0
    80005ca2:	902080e7          	jalr	-1790(ra) # 800055a0 <fdalloc>
    80005ca6:	84aa                	mv	s1,a0
    80005ca8:	0e054663          	bltz	a0,80005d94 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005cac:	04491703          	lh	a4,68(s2)
    80005cb0:	478d                	li	a5,3
    80005cb2:	0cf70463          	beq	a4,a5,80005d7a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005cb6:	4789                	li	a5,2
    80005cb8:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005cbc:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005cc0:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005cc4:	f4c42783          	lw	a5,-180(s0)
    80005cc8:	0017c713          	xori	a4,a5,1
    80005ccc:	8b05                	andi	a4,a4,1
    80005cce:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005cd2:	0037f713          	andi	a4,a5,3
    80005cd6:	00e03733          	snez	a4,a4
    80005cda:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005cde:	4007f793          	andi	a5,a5,1024
    80005ce2:	c791                	beqz	a5,80005cee <sys_open+0xd2>
    80005ce4:	04491703          	lh	a4,68(s2)
    80005ce8:	4789                	li	a5,2
    80005cea:	08f70f63          	beq	a4,a5,80005d88 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005cee:	854a                	mv	a0,s2
    80005cf0:	ffffe097          	auipc	ra,0xffffe
    80005cf4:	082080e7          	jalr	130(ra) # 80003d72 <iunlock>
  end_op();
    80005cf8:	fffff097          	auipc	ra,0xfffff
    80005cfc:	a0a080e7          	jalr	-1526(ra) # 80004702 <end_op>

  return fd;
}
    80005d00:	8526                	mv	a0,s1
    80005d02:	70ea                	ld	ra,184(sp)
    80005d04:	744a                	ld	s0,176(sp)
    80005d06:	74aa                	ld	s1,168(sp)
    80005d08:	790a                	ld	s2,160(sp)
    80005d0a:	69ea                	ld	s3,152(sp)
    80005d0c:	6129                	addi	sp,sp,192
    80005d0e:	8082                	ret
      end_op();
    80005d10:	fffff097          	auipc	ra,0xfffff
    80005d14:	9f2080e7          	jalr	-1550(ra) # 80004702 <end_op>
      return -1;
    80005d18:	b7e5                	j	80005d00 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005d1a:	f5040513          	addi	a0,s0,-176
    80005d1e:	ffffe097          	auipc	ra,0xffffe
    80005d22:	748080e7          	jalr	1864(ra) # 80004466 <namei>
    80005d26:	892a                	mv	s2,a0
    80005d28:	c905                	beqz	a0,80005d58 <sys_open+0x13c>
    ilock(ip);
    80005d2a:	ffffe097          	auipc	ra,0xffffe
    80005d2e:	f86080e7          	jalr	-122(ra) # 80003cb0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005d32:	04491703          	lh	a4,68(s2)
    80005d36:	4785                	li	a5,1
    80005d38:	f4f712e3          	bne	a4,a5,80005c7c <sys_open+0x60>
    80005d3c:	f4c42783          	lw	a5,-180(s0)
    80005d40:	dba1                	beqz	a5,80005c90 <sys_open+0x74>
      iunlockput(ip);
    80005d42:	854a                	mv	a0,s2
    80005d44:	ffffe097          	auipc	ra,0xffffe
    80005d48:	1ce080e7          	jalr	462(ra) # 80003f12 <iunlockput>
      end_op();
    80005d4c:	fffff097          	auipc	ra,0xfffff
    80005d50:	9b6080e7          	jalr	-1610(ra) # 80004702 <end_op>
      return -1;
    80005d54:	54fd                	li	s1,-1
    80005d56:	b76d                	j	80005d00 <sys_open+0xe4>
      end_op();
    80005d58:	fffff097          	auipc	ra,0xfffff
    80005d5c:	9aa080e7          	jalr	-1622(ra) # 80004702 <end_op>
      return -1;
    80005d60:	54fd                	li	s1,-1
    80005d62:	bf79                	j	80005d00 <sys_open+0xe4>
    iunlockput(ip);
    80005d64:	854a                	mv	a0,s2
    80005d66:	ffffe097          	auipc	ra,0xffffe
    80005d6a:	1ac080e7          	jalr	428(ra) # 80003f12 <iunlockput>
    end_op();
    80005d6e:	fffff097          	auipc	ra,0xfffff
    80005d72:	994080e7          	jalr	-1644(ra) # 80004702 <end_op>
    return -1;
    80005d76:	54fd                	li	s1,-1
    80005d78:	b761                	j	80005d00 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005d7a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005d7e:	04691783          	lh	a5,70(s2)
    80005d82:	02f99223          	sh	a5,36(s3)
    80005d86:	bf2d                	j	80005cc0 <sys_open+0xa4>
    itrunc(ip);
    80005d88:	854a                	mv	a0,s2
    80005d8a:	ffffe097          	auipc	ra,0xffffe
    80005d8e:	034080e7          	jalr	52(ra) # 80003dbe <itrunc>
    80005d92:	bfb1                	j	80005cee <sys_open+0xd2>
      fileclose(f);
    80005d94:	854e                	mv	a0,s3
    80005d96:	fffff097          	auipc	ra,0xfffff
    80005d9a:	db8080e7          	jalr	-584(ra) # 80004b4e <fileclose>
    iunlockput(ip);
    80005d9e:	854a                	mv	a0,s2
    80005da0:	ffffe097          	auipc	ra,0xffffe
    80005da4:	172080e7          	jalr	370(ra) # 80003f12 <iunlockput>
    end_op();
    80005da8:	fffff097          	auipc	ra,0xfffff
    80005dac:	95a080e7          	jalr	-1702(ra) # 80004702 <end_op>
    return -1;
    80005db0:	54fd                	li	s1,-1
    80005db2:	b7b9                	j	80005d00 <sys_open+0xe4>

0000000080005db4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005db4:	7175                	addi	sp,sp,-144
    80005db6:	e506                	sd	ra,136(sp)
    80005db8:	e122                	sd	s0,128(sp)
    80005dba:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005dbc:	fffff097          	auipc	ra,0xfffff
    80005dc0:	8c6080e7          	jalr	-1850(ra) # 80004682 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005dc4:	08000613          	li	a2,128
    80005dc8:	f7040593          	addi	a1,s0,-144
    80005dcc:	4501                	li	a0,0
    80005dce:	ffffd097          	auipc	ra,0xffffd
    80005dd2:	350080e7          	jalr	848(ra) # 8000311e <argstr>
    80005dd6:	02054963          	bltz	a0,80005e08 <sys_mkdir+0x54>
    80005dda:	4681                	li	a3,0
    80005ddc:	4601                	li	a2,0
    80005dde:	4585                	li	a1,1
    80005de0:	f7040513          	addi	a0,s0,-144
    80005de4:	fffff097          	auipc	ra,0xfffff
    80005de8:	7fe080e7          	jalr	2046(ra) # 800055e2 <create>
    80005dec:	cd11                	beqz	a0,80005e08 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005dee:	ffffe097          	auipc	ra,0xffffe
    80005df2:	124080e7          	jalr	292(ra) # 80003f12 <iunlockput>
  end_op();
    80005df6:	fffff097          	auipc	ra,0xfffff
    80005dfa:	90c080e7          	jalr	-1780(ra) # 80004702 <end_op>
  return 0;
    80005dfe:	4501                	li	a0,0
}
    80005e00:	60aa                	ld	ra,136(sp)
    80005e02:	640a                	ld	s0,128(sp)
    80005e04:	6149                	addi	sp,sp,144
    80005e06:	8082                	ret
    end_op();
    80005e08:	fffff097          	auipc	ra,0xfffff
    80005e0c:	8fa080e7          	jalr	-1798(ra) # 80004702 <end_op>
    return -1;
    80005e10:	557d                	li	a0,-1
    80005e12:	b7fd                	j	80005e00 <sys_mkdir+0x4c>

0000000080005e14 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005e14:	7135                	addi	sp,sp,-160
    80005e16:	ed06                	sd	ra,152(sp)
    80005e18:	e922                	sd	s0,144(sp)
    80005e1a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005e1c:	fffff097          	auipc	ra,0xfffff
    80005e20:	866080e7          	jalr	-1946(ra) # 80004682 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e24:	08000613          	li	a2,128
    80005e28:	f7040593          	addi	a1,s0,-144
    80005e2c:	4501                	li	a0,0
    80005e2e:	ffffd097          	auipc	ra,0xffffd
    80005e32:	2f0080e7          	jalr	752(ra) # 8000311e <argstr>
    80005e36:	04054a63          	bltz	a0,80005e8a <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005e3a:	f6c40593          	addi	a1,s0,-148
    80005e3e:	4505                	li	a0,1
    80005e40:	ffffd097          	auipc	ra,0xffffd
    80005e44:	29a080e7          	jalr	666(ra) # 800030da <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e48:	04054163          	bltz	a0,80005e8a <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005e4c:	f6840593          	addi	a1,s0,-152
    80005e50:	4509                	li	a0,2
    80005e52:	ffffd097          	auipc	ra,0xffffd
    80005e56:	288080e7          	jalr	648(ra) # 800030da <argint>
     argint(1, &major) < 0 ||
    80005e5a:	02054863          	bltz	a0,80005e8a <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005e5e:	f6841683          	lh	a3,-152(s0)
    80005e62:	f6c41603          	lh	a2,-148(s0)
    80005e66:	458d                	li	a1,3
    80005e68:	f7040513          	addi	a0,s0,-144
    80005e6c:	fffff097          	auipc	ra,0xfffff
    80005e70:	776080e7          	jalr	1910(ra) # 800055e2 <create>
     argint(2, &minor) < 0 ||
    80005e74:	c919                	beqz	a0,80005e8a <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e76:	ffffe097          	auipc	ra,0xffffe
    80005e7a:	09c080e7          	jalr	156(ra) # 80003f12 <iunlockput>
  end_op();
    80005e7e:	fffff097          	auipc	ra,0xfffff
    80005e82:	884080e7          	jalr	-1916(ra) # 80004702 <end_op>
  return 0;
    80005e86:	4501                	li	a0,0
    80005e88:	a031                	j	80005e94 <sys_mknod+0x80>
    end_op();
    80005e8a:	fffff097          	auipc	ra,0xfffff
    80005e8e:	878080e7          	jalr	-1928(ra) # 80004702 <end_op>
    return -1;
    80005e92:	557d                	li	a0,-1
}
    80005e94:	60ea                	ld	ra,152(sp)
    80005e96:	644a                	ld	s0,144(sp)
    80005e98:	610d                	addi	sp,sp,160
    80005e9a:	8082                	ret

0000000080005e9c <sys_chdir>:

uint64
sys_chdir(void)
{
    80005e9c:	7135                	addi	sp,sp,-160
    80005e9e:	ed06                	sd	ra,152(sp)
    80005ea0:	e922                	sd	s0,144(sp)
    80005ea2:	e526                	sd	s1,136(sp)
    80005ea4:	e14a                	sd	s2,128(sp)
    80005ea6:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005ea8:	ffffc097          	auipc	ra,0xffffc
    80005eac:	b20080e7          	jalr	-1248(ra) # 800019c8 <myproc>
    80005eb0:	892a                	mv	s2,a0
  
  begin_op();
    80005eb2:	ffffe097          	auipc	ra,0xffffe
    80005eb6:	7d0080e7          	jalr	2000(ra) # 80004682 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005eba:	08000613          	li	a2,128
    80005ebe:	f6040593          	addi	a1,s0,-160
    80005ec2:	4501                	li	a0,0
    80005ec4:	ffffd097          	auipc	ra,0xffffd
    80005ec8:	25a080e7          	jalr	602(ra) # 8000311e <argstr>
    80005ecc:	04054b63          	bltz	a0,80005f22 <sys_chdir+0x86>
    80005ed0:	f6040513          	addi	a0,s0,-160
    80005ed4:	ffffe097          	auipc	ra,0xffffe
    80005ed8:	592080e7          	jalr	1426(ra) # 80004466 <namei>
    80005edc:	84aa                	mv	s1,a0
    80005ede:	c131                	beqz	a0,80005f22 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005ee0:	ffffe097          	auipc	ra,0xffffe
    80005ee4:	dd0080e7          	jalr	-560(ra) # 80003cb0 <ilock>
  if(ip->type != T_DIR){
    80005ee8:	04449703          	lh	a4,68(s1)
    80005eec:	4785                	li	a5,1
    80005eee:	04f71063          	bne	a4,a5,80005f2e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005ef2:	8526                	mv	a0,s1
    80005ef4:	ffffe097          	auipc	ra,0xffffe
    80005ef8:	e7e080e7          	jalr	-386(ra) # 80003d72 <iunlock>
  iput(p->cwd);
    80005efc:	15093503          	ld	a0,336(s2)
    80005f00:	ffffe097          	auipc	ra,0xffffe
    80005f04:	f6a080e7          	jalr	-150(ra) # 80003e6a <iput>
  end_op();
    80005f08:	ffffe097          	auipc	ra,0xffffe
    80005f0c:	7fa080e7          	jalr	2042(ra) # 80004702 <end_op>
  p->cwd = ip;
    80005f10:	14993823          	sd	s1,336(s2)
  return 0;
    80005f14:	4501                	li	a0,0
}
    80005f16:	60ea                	ld	ra,152(sp)
    80005f18:	644a                	ld	s0,144(sp)
    80005f1a:	64aa                	ld	s1,136(sp)
    80005f1c:	690a                	ld	s2,128(sp)
    80005f1e:	610d                	addi	sp,sp,160
    80005f20:	8082                	ret
    end_op();
    80005f22:	ffffe097          	auipc	ra,0xffffe
    80005f26:	7e0080e7          	jalr	2016(ra) # 80004702 <end_op>
    return -1;
    80005f2a:	557d                	li	a0,-1
    80005f2c:	b7ed                	j	80005f16 <sys_chdir+0x7a>
    iunlockput(ip);
    80005f2e:	8526                	mv	a0,s1
    80005f30:	ffffe097          	auipc	ra,0xffffe
    80005f34:	fe2080e7          	jalr	-30(ra) # 80003f12 <iunlockput>
    end_op();
    80005f38:	ffffe097          	auipc	ra,0xffffe
    80005f3c:	7ca080e7          	jalr	1994(ra) # 80004702 <end_op>
    return -1;
    80005f40:	557d                	li	a0,-1
    80005f42:	bfd1                	j	80005f16 <sys_chdir+0x7a>

0000000080005f44 <sys_exec>:

uint64
sys_exec(void)
{
    80005f44:	7145                	addi	sp,sp,-464
    80005f46:	e786                	sd	ra,456(sp)
    80005f48:	e3a2                	sd	s0,448(sp)
    80005f4a:	ff26                	sd	s1,440(sp)
    80005f4c:	fb4a                	sd	s2,432(sp)
    80005f4e:	f74e                	sd	s3,424(sp)
    80005f50:	f352                	sd	s4,416(sp)
    80005f52:	ef56                	sd	s5,408(sp)
    80005f54:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005f56:	08000613          	li	a2,128
    80005f5a:	f4040593          	addi	a1,s0,-192
    80005f5e:	4501                	li	a0,0
    80005f60:	ffffd097          	auipc	ra,0xffffd
    80005f64:	1be080e7          	jalr	446(ra) # 8000311e <argstr>
    return -1;
    80005f68:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005f6a:	0c054a63          	bltz	a0,8000603e <sys_exec+0xfa>
    80005f6e:	e3840593          	addi	a1,s0,-456
    80005f72:	4505                	li	a0,1
    80005f74:	ffffd097          	auipc	ra,0xffffd
    80005f78:	188080e7          	jalr	392(ra) # 800030fc <argaddr>
    80005f7c:	0c054163          	bltz	a0,8000603e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005f80:	10000613          	li	a2,256
    80005f84:	4581                	li	a1,0
    80005f86:	e4040513          	addi	a0,s0,-448
    80005f8a:	ffffb097          	auipc	ra,0xffffb
    80005f8e:	d56080e7          	jalr	-682(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005f92:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005f96:	89a6                	mv	s3,s1
    80005f98:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005f9a:	02000a13          	li	s4,32
    80005f9e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005fa2:	00391513          	slli	a0,s2,0x3
    80005fa6:	e3040593          	addi	a1,s0,-464
    80005faa:	e3843783          	ld	a5,-456(s0)
    80005fae:	953e                	add	a0,a0,a5
    80005fb0:	ffffd097          	auipc	ra,0xffffd
    80005fb4:	090080e7          	jalr	144(ra) # 80003040 <fetchaddr>
    80005fb8:	02054a63          	bltz	a0,80005fec <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005fbc:	e3043783          	ld	a5,-464(s0)
    80005fc0:	c3b9                	beqz	a5,80006006 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005fc2:	ffffb097          	auipc	ra,0xffffb
    80005fc6:	b32080e7          	jalr	-1230(ra) # 80000af4 <kalloc>
    80005fca:	85aa                	mv	a1,a0
    80005fcc:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005fd0:	cd11                	beqz	a0,80005fec <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005fd2:	6605                	lui	a2,0x1
    80005fd4:	e3043503          	ld	a0,-464(s0)
    80005fd8:	ffffd097          	auipc	ra,0xffffd
    80005fdc:	0ba080e7          	jalr	186(ra) # 80003092 <fetchstr>
    80005fe0:	00054663          	bltz	a0,80005fec <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005fe4:	0905                	addi	s2,s2,1
    80005fe6:	09a1                	addi	s3,s3,8
    80005fe8:	fb491be3          	bne	s2,s4,80005f9e <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fec:	10048913          	addi	s2,s1,256
    80005ff0:	6088                	ld	a0,0(s1)
    80005ff2:	c529                	beqz	a0,8000603c <sys_exec+0xf8>
    kfree(argv[i]);
    80005ff4:	ffffb097          	auipc	ra,0xffffb
    80005ff8:	a04080e7          	jalr	-1532(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ffc:	04a1                	addi	s1,s1,8
    80005ffe:	ff2499e3          	bne	s1,s2,80005ff0 <sys_exec+0xac>
  return -1;
    80006002:	597d                	li	s2,-1
    80006004:	a82d                	j	8000603e <sys_exec+0xfa>
      argv[i] = 0;
    80006006:	0a8e                	slli	s5,s5,0x3
    80006008:	fc040793          	addi	a5,s0,-64
    8000600c:	9abe                	add	s5,s5,a5
    8000600e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006012:	e4040593          	addi	a1,s0,-448
    80006016:	f4040513          	addi	a0,s0,-192
    8000601a:	fffff097          	auipc	ra,0xfffff
    8000601e:	194080e7          	jalr	404(ra) # 800051ae <exec>
    80006022:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006024:	10048993          	addi	s3,s1,256
    80006028:	6088                	ld	a0,0(s1)
    8000602a:	c911                	beqz	a0,8000603e <sys_exec+0xfa>
    kfree(argv[i]);
    8000602c:	ffffb097          	auipc	ra,0xffffb
    80006030:	9cc080e7          	jalr	-1588(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006034:	04a1                	addi	s1,s1,8
    80006036:	ff3499e3          	bne	s1,s3,80006028 <sys_exec+0xe4>
    8000603a:	a011                	j	8000603e <sys_exec+0xfa>
  return -1;
    8000603c:	597d                	li	s2,-1
}
    8000603e:	854a                	mv	a0,s2
    80006040:	60be                	ld	ra,456(sp)
    80006042:	641e                	ld	s0,448(sp)
    80006044:	74fa                	ld	s1,440(sp)
    80006046:	795a                	ld	s2,432(sp)
    80006048:	79ba                	ld	s3,424(sp)
    8000604a:	7a1a                	ld	s4,416(sp)
    8000604c:	6afa                	ld	s5,408(sp)
    8000604e:	6179                	addi	sp,sp,464
    80006050:	8082                	ret

0000000080006052 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006052:	7139                	addi	sp,sp,-64
    80006054:	fc06                	sd	ra,56(sp)
    80006056:	f822                	sd	s0,48(sp)
    80006058:	f426                	sd	s1,40(sp)
    8000605a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000605c:	ffffc097          	auipc	ra,0xffffc
    80006060:	96c080e7          	jalr	-1684(ra) # 800019c8 <myproc>
    80006064:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006066:	fd840593          	addi	a1,s0,-40
    8000606a:	4501                	li	a0,0
    8000606c:	ffffd097          	auipc	ra,0xffffd
    80006070:	090080e7          	jalr	144(ra) # 800030fc <argaddr>
    return -1;
    80006074:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006076:	0e054063          	bltz	a0,80006156 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    8000607a:	fc840593          	addi	a1,s0,-56
    8000607e:	fd040513          	addi	a0,s0,-48
    80006082:	fffff097          	auipc	ra,0xfffff
    80006086:	dfc080e7          	jalr	-516(ra) # 80004e7e <pipealloc>
    return -1;
    8000608a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000608c:	0c054563          	bltz	a0,80006156 <sys_pipe+0x104>
  fd0 = -1;
    80006090:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006094:	fd043503          	ld	a0,-48(s0)
    80006098:	fffff097          	auipc	ra,0xfffff
    8000609c:	508080e7          	jalr	1288(ra) # 800055a0 <fdalloc>
    800060a0:	fca42223          	sw	a0,-60(s0)
    800060a4:	08054c63          	bltz	a0,8000613c <sys_pipe+0xea>
    800060a8:	fc843503          	ld	a0,-56(s0)
    800060ac:	fffff097          	auipc	ra,0xfffff
    800060b0:	4f4080e7          	jalr	1268(ra) # 800055a0 <fdalloc>
    800060b4:	fca42023          	sw	a0,-64(s0)
    800060b8:	06054863          	bltz	a0,80006128 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800060bc:	4691                	li	a3,4
    800060be:	fc440613          	addi	a2,s0,-60
    800060c2:	fd843583          	ld	a1,-40(s0)
    800060c6:	68a8                	ld	a0,80(s1)
    800060c8:	ffffb097          	auipc	ra,0xffffb
    800060cc:	5b2080e7          	jalr	1458(ra) # 8000167a <copyout>
    800060d0:	02054063          	bltz	a0,800060f0 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800060d4:	4691                	li	a3,4
    800060d6:	fc040613          	addi	a2,s0,-64
    800060da:	fd843583          	ld	a1,-40(s0)
    800060de:	0591                	addi	a1,a1,4
    800060e0:	68a8                	ld	a0,80(s1)
    800060e2:	ffffb097          	auipc	ra,0xffffb
    800060e6:	598080e7          	jalr	1432(ra) # 8000167a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800060ea:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800060ec:	06055563          	bgez	a0,80006156 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    800060f0:	fc442783          	lw	a5,-60(s0)
    800060f4:	07e9                	addi	a5,a5,26
    800060f6:	078e                	slli	a5,a5,0x3
    800060f8:	97a6                	add	a5,a5,s1
    800060fa:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800060fe:	fc042503          	lw	a0,-64(s0)
    80006102:	0569                	addi	a0,a0,26
    80006104:	050e                	slli	a0,a0,0x3
    80006106:	9526                	add	a0,a0,s1
    80006108:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000610c:	fd043503          	ld	a0,-48(s0)
    80006110:	fffff097          	auipc	ra,0xfffff
    80006114:	a3e080e7          	jalr	-1474(ra) # 80004b4e <fileclose>
    fileclose(wf);
    80006118:	fc843503          	ld	a0,-56(s0)
    8000611c:	fffff097          	auipc	ra,0xfffff
    80006120:	a32080e7          	jalr	-1486(ra) # 80004b4e <fileclose>
    return -1;
    80006124:	57fd                	li	a5,-1
    80006126:	a805                	j	80006156 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006128:	fc442783          	lw	a5,-60(s0)
    8000612c:	0007c863          	bltz	a5,8000613c <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006130:	01a78513          	addi	a0,a5,26
    80006134:	050e                	slli	a0,a0,0x3
    80006136:	9526                	add	a0,a0,s1
    80006138:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000613c:	fd043503          	ld	a0,-48(s0)
    80006140:	fffff097          	auipc	ra,0xfffff
    80006144:	a0e080e7          	jalr	-1522(ra) # 80004b4e <fileclose>
    fileclose(wf);
    80006148:	fc843503          	ld	a0,-56(s0)
    8000614c:	fffff097          	auipc	ra,0xfffff
    80006150:	a02080e7          	jalr	-1534(ra) # 80004b4e <fileclose>
    return -1;
    80006154:	57fd                	li	a5,-1
}
    80006156:	853e                	mv	a0,a5
    80006158:	70e2                	ld	ra,56(sp)
    8000615a:	7442                	ld	s0,48(sp)
    8000615c:	74a2                	ld	s1,40(sp)
    8000615e:	6121                	addi	sp,sp,64
    80006160:	8082                	ret
	...

0000000080006170 <kernelvec>:
    80006170:	7111                	addi	sp,sp,-256
    80006172:	e006                	sd	ra,0(sp)
    80006174:	e40a                	sd	sp,8(sp)
    80006176:	e80e                	sd	gp,16(sp)
    80006178:	ec12                	sd	tp,24(sp)
    8000617a:	f016                	sd	t0,32(sp)
    8000617c:	f41a                	sd	t1,40(sp)
    8000617e:	f81e                	sd	t2,48(sp)
    80006180:	fc22                	sd	s0,56(sp)
    80006182:	e0a6                	sd	s1,64(sp)
    80006184:	e4aa                	sd	a0,72(sp)
    80006186:	e8ae                	sd	a1,80(sp)
    80006188:	ecb2                	sd	a2,88(sp)
    8000618a:	f0b6                	sd	a3,96(sp)
    8000618c:	f4ba                	sd	a4,104(sp)
    8000618e:	f8be                	sd	a5,112(sp)
    80006190:	fcc2                	sd	a6,120(sp)
    80006192:	e146                	sd	a7,128(sp)
    80006194:	e54a                	sd	s2,136(sp)
    80006196:	e94e                	sd	s3,144(sp)
    80006198:	ed52                	sd	s4,152(sp)
    8000619a:	f156                	sd	s5,160(sp)
    8000619c:	f55a                	sd	s6,168(sp)
    8000619e:	f95e                	sd	s7,176(sp)
    800061a0:	fd62                	sd	s8,184(sp)
    800061a2:	e1e6                	sd	s9,192(sp)
    800061a4:	e5ea                	sd	s10,200(sp)
    800061a6:	e9ee                	sd	s11,208(sp)
    800061a8:	edf2                	sd	t3,216(sp)
    800061aa:	f1f6                	sd	t4,224(sp)
    800061ac:	f5fa                	sd	t5,232(sp)
    800061ae:	f9fe                	sd	t6,240(sp)
    800061b0:	d5dfc0ef          	jal	ra,80002f0c <kerneltrap>
    800061b4:	6082                	ld	ra,0(sp)
    800061b6:	6122                	ld	sp,8(sp)
    800061b8:	61c2                	ld	gp,16(sp)
    800061ba:	7282                	ld	t0,32(sp)
    800061bc:	7322                	ld	t1,40(sp)
    800061be:	73c2                	ld	t2,48(sp)
    800061c0:	7462                	ld	s0,56(sp)
    800061c2:	6486                	ld	s1,64(sp)
    800061c4:	6526                	ld	a0,72(sp)
    800061c6:	65c6                	ld	a1,80(sp)
    800061c8:	6666                	ld	a2,88(sp)
    800061ca:	7686                	ld	a3,96(sp)
    800061cc:	7726                	ld	a4,104(sp)
    800061ce:	77c6                	ld	a5,112(sp)
    800061d0:	7866                	ld	a6,120(sp)
    800061d2:	688a                	ld	a7,128(sp)
    800061d4:	692a                	ld	s2,136(sp)
    800061d6:	69ca                	ld	s3,144(sp)
    800061d8:	6a6a                	ld	s4,152(sp)
    800061da:	7a8a                	ld	s5,160(sp)
    800061dc:	7b2a                	ld	s6,168(sp)
    800061de:	7bca                	ld	s7,176(sp)
    800061e0:	7c6a                	ld	s8,184(sp)
    800061e2:	6c8e                	ld	s9,192(sp)
    800061e4:	6d2e                	ld	s10,200(sp)
    800061e6:	6dce                	ld	s11,208(sp)
    800061e8:	6e6e                	ld	t3,216(sp)
    800061ea:	7e8e                	ld	t4,224(sp)
    800061ec:	7f2e                	ld	t5,232(sp)
    800061ee:	7fce                	ld	t6,240(sp)
    800061f0:	6111                	addi	sp,sp,256
    800061f2:	10200073          	sret
    800061f6:	00000013          	nop
    800061fa:	00000013          	nop
    800061fe:	0001                	nop

0000000080006200 <timervec>:
    80006200:	34051573          	csrrw	a0,mscratch,a0
    80006204:	e10c                	sd	a1,0(a0)
    80006206:	e510                	sd	a2,8(a0)
    80006208:	e914                	sd	a3,16(a0)
    8000620a:	6d0c                	ld	a1,24(a0)
    8000620c:	7110                	ld	a2,32(a0)
    8000620e:	6194                	ld	a3,0(a1)
    80006210:	96b2                	add	a3,a3,a2
    80006212:	e194                	sd	a3,0(a1)
    80006214:	4589                	li	a1,2
    80006216:	14459073          	csrw	sip,a1
    8000621a:	6914                	ld	a3,16(a0)
    8000621c:	6510                	ld	a2,8(a0)
    8000621e:	610c                	ld	a1,0(a0)
    80006220:	34051573          	csrrw	a0,mscratch,a0
    80006224:	30200073          	mret
	...

000000008000622a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000622a:	1141                	addi	sp,sp,-16
    8000622c:	e422                	sd	s0,8(sp)
    8000622e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006230:	0c0007b7          	lui	a5,0xc000
    80006234:	4705                	li	a4,1
    80006236:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006238:	c3d8                	sw	a4,4(a5)
}
    8000623a:	6422                	ld	s0,8(sp)
    8000623c:	0141                	addi	sp,sp,16
    8000623e:	8082                	ret

0000000080006240 <plicinithart>:

void
plicinithart(void)
{
    80006240:	1141                	addi	sp,sp,-16
    80006242:	e406                	sd	ra,8(sp)
    80006244:	e022                	sd	s0,0(sp)
    80006246:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006248:	ffffb097          	auipc	ra,0xffffb
    8000624c:	754080e7          	jalr	1876(ra) # 8000199c <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006250:	0085171b          	slliw	a4,a0,0x8
    80006254:	0c0027b7          	lui	a5,0xc002
    80006258:	97ba                	add	a5,a5,a4
    8000625a:	40200713          	li	a4,1026
    8000625e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006262:	00d5151b          	slliw	a0,a0,0xd
    80006266:	0c2017b7          	lui	a5,0xc201
    8000626a:	953e                	add	a0,a0,a5
    8000626c:	00052023          	sw	zero,0(a0)
}
    80006270:	60a2                	ld	ra,8(sp)
    80006272:	6402                	ld	s0,0(sp)
    80006274:	0141                	addi	sp,sp,16
    80006276:	8082                	ret

0000000080006278 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006278:	1141                	addi	sp,sp,-16
    8000627a:	e406                	sd	ra,8(sp)
    8000627c:	e022                	sd	s0,0(sp)
    8000627e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006280:	ffffb097          	auipc	ra,0xffffb
    80006284:	71c080e7          	jalr	1820(ra) # 8000199c <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006288:	00d5179b          	slliw	a5,a0,0xd
    8000628c:	0c201537          	lui	a0,0xc201
    80006290:	953e                	add	a0,a0,a5
  return irq;
}
    80006292:	4148                	lw	a0,4(a0)
    80006294:	60a2                	ld	ra,8(sp)
    80006296:	6402                	ld	s0,0(sp)
    80006298:	0141                	addi	sp,sp,16
    8000629a:	8082                	ret

000000008000629c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000629c:	1101                	addi	sp,sp,-32
    8000629e:	ec06                	sd	ra,24(sp)
    800062a0:	e822                	sd	s0,16(sp)
    800062a2:	e426                	sd	s1,8(sp)
    800062a4:	1000                	addi	s0,sp,32
    800062a6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800062a8:	ffffb097          	auipc	ra,0xffffb
    800062ac:	6f4080e7          	jalr	1780(ra) # 8000199c <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800062b0:	00d5151b          	slliw	a0,a0,0xd
    800062b4:	0c2017b7          	lui	a5,0xc201
    800062b8:	97aa                	add	a5,a5,a0
    800062ba:	c3c4                	sw	s1,4(a5)
}
    800062bc:	60e2                	ld	ra,24(sp)
    800062be:	6442                	ld	s0,16(sp)
    800062c0:	64a2                	ld	s1,8(sp)
    800062c2:	6105                	addi	sp,sp,32
    800062c4:	8082                	ret

00000000800062c6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800062c6:	1141                	addi	sp,sp,-16
    800062c8:	e406                	sd	ra,8(sp)
    800062ca:	e022                	sd	s0,0(sp)
    800062cc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800062ce:	479d                	li	a5,7
    800062d0:	06a7c963          	blt	a5,a0,80006342 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800062d4:	00016797          	auipc	a5,0x16
    800062d8:	d2c78793          	addi	a5,a5,-724 # 8001c000 <disk>
    800062dc:	00a78733          	add	a4,a5,a0
    800062e0:	6789                	lui	a5,0x2
    800062e2:	97ba                	add	a5,a5,a4
    800062e4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800062e8:	e7ad                	bnez	a5,80006352 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800062ea:	00451793          	slli	a5,a0,0x4
    800062ee:	00018717          	auipc	a4,0x18
    800062f2:	d1270713          	addi	a4,a4,-750 # 8001e000 <disk+0x2000>
    800062f6:	6314                	ld	a3,0(a4)
    800062f8:	96be                	add	a3,a3,a5
    800062fa:	0006b023          	sd	zero,0(a3) # 8001a630 <log+0x30>
  disk.desc[i].len = 0;
    800062fe:	6314                	ld	a3,0(a4)
    80006300:	96be                	add	a3,a3,a5
    80006302:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006306:	6314                	ld	a3,0(a4)
    80006308:	96be                	add	a3,a3,a5
    8000630a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000630e:	6318                	ld	a4,0(a4)
    80006310:	97ba                	add	a5,a5,a4
    80006312:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006316:	00016797          	auipc	a5,0x16
    8000631a:	cea78793          	addi	a5,a5,-790 # 8001c000 <disk>
    8000631e:	97aa                	add	a5,a5,a0
    80006320:	6509                	lui	a0,0x2
    80006322:	953e                	add	a0,a0,a5
    80006324:	4785                	li	a5,1
    80006326:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000632a:	00018517          	auipc	a0,0x18
    8000632e:	cee50513          	addi	a0,a0,-786 # 8001e018 <disk+0x2018>
    80006332:	ffffc097          	auipc	ra,0xffffc
    80006336:	2aa080e7          	jalr	682(ra) # 800025dc <wakeup>
}
    8000633a:	60a2                	ld	ra,8(sp)
    8000633c:	6402                	ld	s0,0(sp)
    8000633e:	0141                	addi	sp,sp,16
    80006340:	8082                	ret
    panic("free_desc 1");
    80006342:	00002517          	auipc	a0,0x2
    80006346:	50e50513          	addi	a0,a0,1294 # 80008850 <syscalls+0x338>
    8000634a:	ffffa097          	auipc	ra,0xffffa
    8000634e:	1f4080e7          	jalr	500(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006352:	00002517          	auipc	a0,0x2
    80006356:	50e50513          	addi	a0,a0,1294 # 80008860 <syscalls+0x348>
    8000635a:	ffffa097          	auipc	ra,0xffffa
    8000635e:	1e4080e7          	jalr	484(ra) # 8000053e <panic>

0000000080006362 <virtio_disk_init>:
{
    80006362:	1101                	addi	sp,sp,-32
    80006364:	ec06                	sd	ra,24(sp)
    80006366:	e822                	sd	s0,16(sp)
    80006368:	e426                	sd	s1,8(sp)
    8000636a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000636c:	00002597          	auipc	a1,0x2
    80006370:	50458593          	addi	a1,a1,1284 # 80008870 <syscalls+0x358>
    80006374:	00018517          	auipc	a0,0x18
    80006378:	db450513          	addi	a0,a0,-588 # 8001e128 <disk+0x2128>
    8000637c:	ffffa097          	auipc	ra,0xffffa
    80006380:	7d8080e7          	jalr	2008(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006384:	100017b7          	lui	a5,0x10001
    80006388:	4398                	lw	a4,0(a5)
    8000638a:	2701                	sext.w	a4,a4
    8000638c:	747277b7          	lui	a5,0x74727
    80006390:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006394:	0ef71163          	bne	a4,a5,80006476 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006398:	100017b7          	lui	a5,0x10001
    8000639c:	43dc                	lw	a5,4(a5)
    8000639e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800063a0:	4705                	li	a4,1
    800063a2:	0ce79a63          	bne	a5,a4,80006476 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800063a6:	100017b7          	lui	a5,0x10001
    800063aa:	479c                	lw	a5,8(a5)
    800063ac:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800063ae:	4709                	li	a4,2
    800063b0:	0ce79363          	bne	a5,a4,80006476 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800063b4:	100017b7          	lui	a5,0x10001
    800063b8:	47d8                	lw	a4,12(a5)
    800063ba:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800063bc:	554d47b7          	lui	a5,0x554d4
    800063c0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800063c4:	0af71963          	bne	a4,a5,80006476 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800063c8:	100017b7          	lui	a5,0x10001
    800063cc:	4705                	li	a4,1
    800063ce:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063d0:	470d                	li	a4,3
    800063d2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800063d4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800063d6:	c7ffe737          	lui	a4,0xc7ffe
    800063da:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdf75f>
    800063de:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800063e0:	2701                	sext.w	a4,a4
    800063e2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063e4:	472d                	li	a4,11
    800063e6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063e8:	473d                	li	a4,15
    800063ea:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800063ec:	6705                	lui	a4,0x1
    800063ee:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800063f0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800063f4:	5bdc                	lw	a5,52(a5)
    800063f6:	2781                	sext.w	a5,a5
  if(max == 0)
    800063f8:	c7d9                	beqz	a5,80006486 <virtio_disk_init+0x124>
  if(max < NUM)
    800063fa:	471d                	li	a4,7
    800063fc:	08f77d63          	bgeu	a4,a5,80006496 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006400:	100014b7          	lui	s1,0x10001
    80006404:	47a1                	li	a5,8
    80006406:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006408:	6609                	lui	a2,0x2
    8000640a:	4581                	li	a1,0
    8000640c:	00016517          	auipc	a0,0x16
    80006410:	bf450513          	addi	a0,a0,-1036 # 8001c000 <disk>
    80006414:	ffffb097          	auipc	ra,0xffffb
    80006418:	8cc080e7          	jalr	-1844(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000641c:	00016717          	auipc	a4,0x16
    80006420:	be470713          	addi	a4,a4,-1052 # 8001c000 <disk>
    80006424:	00c75793          	srli	a5,a4,0xc
    80006428:	2781                	sext.w	a5,a5
    8000642a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000642c:	00018797          	auipc	a5,0x18
    80006430:	bd478793          	addi	a5,a5,-1068 # 8001e000 <disk+0x2000>
    80006434:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006436:	00016717          	auipc	a4,0x16
    8000643a:	c4a70713          	addi	a4,a4,-950 # 8001c080 <disk+0x80>
    8000643e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006440:	00017717          	auipc	a4,0x17
    80006444:	bc070713          	addi	a4,a4,-1088 # 8001d000 <disk+0x1000>
    80006448:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000644a:	4705                	li	a4,1
    8000644c:	00e78c23          	sb	a4,24(a5)
    80006450:	00e78ca3          	sb	a4,25(a5)
    80006454:	00e78d23          	sb	a4,26(a5)
    80006458:	00e78da3          	sb	a4,27(a5)
    8000645c:	00e78e23          	sb	a4,28(a5)
    80006460:	00e78ea3          	sb	a4,29(a5)
    80006464:	00e78f23          	sb	a4,30(a5)
    80006468:	00e78fa3          	sb	a4,31(a5)
}
    8000646c:	60e2                	ld	ra,24(sp)
    8000646e:	6442                	ld	s0,16(sp)
    80006470:	64a2                	ld	s1,8(sp)
    80006472:	6105                	addi	sp,sp,32
    80006474:	8082                	ret
    panic("could not find virtio disk");
    80006476:	00002517          	auipc	a0,0x2
    8000647a:	40a50513          	addi	a0,a0,1034 # 80008880 <syscalls+0x368>
    8000647e:	ffffa097          	auipc	ra,0xffffa
    80006482:	0c0080e7          	jalr	192(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006486:	00002517          	auipc	a0,0x2
    8000648a:	41a50513          	addi	a0,a0,1050 # 800088a0 <syscalls+0x388>
    8000648e:	ffffa097          	auipc	ra,0xffffa
    80006492:	0b0080e7          	jalr	176(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006496:	00002517          	auipc	a0,0x2
    8000649a:	42a50513          	addi	a0,a0,1066 # 800088c0 <syscalls+0x3a8>
    8000649e:	ffffa097          	auipc	ra,0xffffa
    800064a2:	0a0080e7          	jalr	160(ra) # 8000053e <panic>

00000000800064a6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800064a6:	7159                	addi	sp,sp,-112
    800064a8:	f486                	sd	ra,104(sp)
    800064aa:	f0a2                	sd	s0,96(sp)
    800064ac:	eca6                	sd	s1,88(sp)
    800064ae:	e8ca                	sd	s2,80(sp)
    800064b0:	e4ce                	sd	s3,72(sp)
    800064b2:	e0d2                	sd	s4,64(sp)
    800064b4:	fc56                	sd	s5,56(sp)
    800064b6:	f85a                	sd	s6,48(sp)
    800064b8:	f45e                	sd	s7,40(sp)
    800064ba:	f062                	sd	s8,32(sp)
    800064bc:	ec66                	sd	s9,24(sp)
    800064be:	e86a                	sd	s10,16(sp)
    800064c0:	1880                	addi	s0,sp,112
    800064c2:	892a                	mv	s2,a0
    800064c4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800064c6:	00c52c83          	lw	s9,12(a0)
    800064ca:	001c9c9b          	slliw	s9,s9,0x1
    800064ce:	1c82                	slli	s9,s9,0x20
    800064d0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800064d4:	00018517          	auipc	a0,0x18
    800064d8:	c5450513          	addi	a0,a0,-940 # 8001e128 <disk+0x2128>
    800064dc:	ffffa097          	auipc	ra,0xffffa
    800064e0:	708080e7          	jalr	1800(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800064e4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800064e6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800064e8:	00016b97          	auipc	s7,0x16
    800064ec:	b18b8b93          	addi	s7,s7,-1256 # 8001c000 <disk>
    800064f0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800064f2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800064f4:	8a4e                	mv	s4,s3
    800064f6:	a051                	j	8000657a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800064f8:	00fb86b3          	add	a3,s7,a5
    800064fc:	96da                	add	a3,a3,s6
    800064fe:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006502:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006504:	0207c563          	bltz	a5,8000652e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006508:	2485                	addiw	s1,s1,1
    8000650a:	0711                	addi	a4,a4,4
    8000650c:	25548063          	beq	s1,s5,8000674c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006510:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006512:	00018697          	auipc	a3,0x18
    80006516:	b0668693          	addi	a3,a3,-1274 # 8001e018 <disk+0x2018>
    8000651a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000651c:	0006c583          	lbu	a1,0(a3)
    80006520:	fde1                	bnez	a1,800064f8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006522:	2785                	addiw	a5,a5,1
    80006524:	0685                	addi	a3,a3,1
    80006526:	ff879be3          	bne	a5,s8,8000651c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000652a:	57fd                	li	a5,-1
    8000652c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000652e:	02905a63          	blez	s1,80006562 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006532:	f9042503          	lw	a0,-112(s0)
    80006536:	00000097          	auipc	ra,0x0
    8000653a:	d90080e7          	jalr	-624(ra) # 800062c6 <free_desc>
      for(int j = 0; j < i; j++)
    8000653e:	4785                	li	a5,1
    80006540:	0297d163          	bge	a5,s1,80006562 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006544:	f9442503          	lw	a0,-108(s0)
    80006548:	00000097          	auipc	ra,0x0
    8000654c:	d7e080e7          	jalr	-642(ra) # 800062c6 <free_desc>
      for(int j = 0; j < i; j++)
    80006550:	4789                	li	a5,2
    80006552:	0097d863          	bge	a5,s1,80006562 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006556:	f9842503          	lw	a0,-104(s0)
    8000655a:	00000097          	auipc	ra,0x0
    8000655e:	d6c080e7          	jalr	-660(ra) # 800062c6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006562:	00018597          	auipc	a1,0x18
    80006566:	bc658593          	addi	a1,a1,-1082 # 8001e128 <disk+0x2128>
    8000656a:	00018517          	auipc	a0,0x18
    8000656e:	aae50513          	addi	a0,a0,-1362 # 8001e018 <disk+0x2018>
    80006572:	ffffc097          	auipc	ra,0xffffc
    80006576:	ec2080e7          	jalr	-318(ra) # 80002434 <sleep>
  for(int i = 0; i < 3; i++){
    8000657a:	f9040713          	addi	a4,s0,-112
    8000657e:	84ce                	mv	s1,s3
    80006580:	bf41                	j	80006510 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006582:	20058713          	addi	a4,a1,512
    80006586:	00471693          	slli	a3,a4,0x4
    8000658a:	00016717          	auipc	a4,0x16
    8000658e:	a7670713          	addi	a4,a4,-1418 # 8001c000 <disk>
    80006592:	9736                	add	a4,a4,a3
    80006594:	4685                	li	a3,1
    80006596:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000659a:	20058713          	addi	a4,a1,512
    8000659e:	00471693          	slli	a3,a4,0x4
    800065a2:	00016717          	auipc	a4,0x16
    800065a6:	a5e70713          	addi	a4,a4,-1442 # 8001c000 <disk>
    800065aa:	9736                	add	a4,a4,a3
    800065ac:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800065b0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800065b4:	7679                	lui	a2,0xffffe
    800065b6:	963e                	add	a2,a2,a5
    800065b8:	00018697          	auipc	a3,0x18
    800065bc:	a4868693          	addi	a3,a3,-1464 # 8001e000 <disk+0x2000>
    800065c0:	6298                	ld	a4,0(a3)
    800065c2:	9732                	add	a4,a4,a2
    800065c4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800065c6:	6298                	ld	a4,0(a3)
    800065c8:	9732                	add	a4,a4,a2
    800065ca:	4541                	li	a0,16
    800065cc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800065ce:	6298                	ld	a4,0(a3)
    800065d0:	9732                	add	a4,a4,a2
    800065d2:	4505                	li	a0,1
    800065d4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800065d8:	f9442703          	lw	a4,-108(s0)
    800065dc:	6288                	ld	a0,0(a3)
    800065de:	962a                	add	a2,a2,a0
    800065e0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffdf00e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800065e4:	0712                	slli	a4,a4,0x4
    800065e6:	6290                	ld	a2,0(a3)
    800065e8:	963a                	add	a2,a2,a4
    800065ea:	05890513          	addi	a0,s2,88
    800065ee:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800065f0:	6294                	ld	a3,0(a3)
    800065f2:	96ba                	add	a3,a3,a4
    800065f4:	40000613          	li	a2,1024
    800065f8:	c690                	sw	a2,8(a3)
  if(write)
    800065fa:	140d0063          	beqz	s10,8000673a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800065fe:	00018697          	auipc	a3,0x18
    80006602:	a026b683          	ld	a3,-1534(a3) # 8001e000 <disk+0x2000>
    80006606:	96ba                	add	a3,a3,a4
    80006608:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000660c:	00016817          	auipc	a6,0x16
    80006610:	9f480813          	addi	a6,a6,-1548 # 8001c000 <disk>
    80006614:	00018517          	auipc	a0,0x18
    80006618:	9ec50513          	addi	a0,a0,-1556 # 8001e000 <disk+0x2000>
    8000661c:	6114                	ld	a3,0(a0)
    8000661e:	96ba                	add	a3,a3,a4
    80006620:	00c6d603          	lhu	a2,12(a3)
    80006624:	00166613          	ori	a2,a2,1
    80006628:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000662c:	f9842683          	lw	a3,-104(s0)
    80006630:	6110                	ld	a2,0(a0)
    80006632:	9732                	add	a4,a4,a2
    80006634:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006638:	20058613          	addi	a2,a1,512
    8000663c:	0612                	slli	a2,a2,0x4
    8000663e:	9642                	add	a2,a2,a6
    80006640:	577d                	li	a4,-1
    80006642:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006646:	00469713          	slli	a4,a3,0x4
    8000664a:	6114                	ld	a3,0(a0)
    8000664c:	96ba                	add	a3,a3,a4
    8000664e:	03078793          	addi	a5,a5,48
    80006652:	97c2                	add	a5,a5,a6
    80006654:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006656:	611c                	ld	a5,0(a0)
    80006658:	97ba                	add	a5,a5,a4
    8000665a:	4685                	li	a3,1
    8000665c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000665e:	611c                	ld	a5,0(a0)
    80006660:	97ba                	add	a5,a5,a4
    80006662:	4809                	li	a6,2
    80006664:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006668:	611c                	ld	a5,0(a0)
    8000666a:	973e                	add	a4,a4,a5
    8000666c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006670:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006674:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006678:	6518                	ld	a4,8(a0)
    8000667a:	00275783          	lhu	a5,2(a4)
    8000667e:	8b9d                	andi	a5,a5,7
    80006680:	0786                	slli	a5,a5,0x1
    80006682:	97ba                	add	a5,a5,a4
    80006684:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006688:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000668c:	6518                	ld	a4,8(a0)
    8000668e:	00275783          	lhu	a5,2(a4)
    80006692:	2785                	addiw	a5,a5,1
    80006694:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006698:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000669c:	100017b7          	lui	a5,0x10001
    800066a0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800066a4:	00492703          	lw	a4,4(s2)
    800066a8:	4785                	li	a5,1
    800066aa:	02f71163          	bne	a4,a5,800066cc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800066ae:	00018997          	auipc	s3,0x18
    800066b2:	a7a98993          	addi	s3,s3,-1414 # 8001e128 <disk+0x2128>
  while(b->disk == 1) {
    800066b6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800066b8:	85ce                	mv	a1,s3
    800066ba:	854a                	mv	a0,s2
    800066bc:	ffffc097          	auipc	ra,0xffffc
    800066c0:	d78080e7          	jalr	-648(ra) # 80002434 <sleep>
  while(b->disk == 1) {
    800066c4:	00492783          	lw	a5,4(s2)
    800066c8:	fe9788e3          	beq	a5,s1,800066b8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800066cc:	f9042903          	lw	s2,-112(s0)
    800066d0:	20090793          	addi	a5,s2,512
    800066d4:	00479713          	slli	a4,a5,0x4
    800066d8:	00016797          	auipc	a5,0x16
    800066dc:	92878793          	addi	a5,a5,-1752 # 8001c000 <disk>
    800066e0:	97ba                	add	a5,a5,a4
    800066e2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800066e6:	00018997          	auipc	s3,0x18
    800066ea:	91a98993          	addi	s3,s3,-1766 # 8001e000 <disk+0x2000>
    800066ee:	00491713          	slli	a4,s2,0x4
    800066f2:	0009b783          	ld	a5,0(s3)
    800066f6:	97ba                	add	a5,a5,a4
    800066f8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800066fc:	854a                	mv	a0,s2
    800066fe:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006702:	00000097          	auipc	ra,0x0
    80006706:	bc4080e7          	jalr	-1084(ra) # 800062c6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000670a:	8885                	andi	s1,s1,1
    8000670c:	f0ed                	bnez	s1,800066ee <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000670e:	00018517          	auipc	a0,0x18
    80006712:	a1a50513          	addi	a0,a0,-1510 # 8001e128 <disk+0x2128>
    80006716:	ffffa097          	auipc	ra,0xffffa
    8000671a:	582080e7          	jalr	1410(ra) # 80000c98 <release>
}
    8000671e:	70a6                	ld	ra,104(sp)
    80006720:	7406                	ld	s0,96(sp)
    80006722:	64e6                	ld	s1,88(sp)
    80006724:	6946                	ld	s2,80(sp)
    80006726:	69a6                	ld	s3,72(sp)
    80006728:	6a06                	ld	s4,64(sp)
    8000672a:	7ae2                	ld	s5,56(sp)
    8000672c:	7b42                	ld	s6,48(sp)
    8000672e:	7ba2                	ld	s7,40(sp)
    80006730:	7c02                	ld	s8,32(sp)
    80006732:	6ce2                	ld	s9,24(sp)
    80006734:	6d42                	ld	s10,16(sp)
    80006736:	6165                	addi	sp,sp,112
    80006738:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000673a:	00018697          	auipc	a3,0x18
    8000673e:	8c66b683          	ld	a3,-1850(a3) # 8001e000 <disk+0x2000>
    80006742:	96ba                	add	a3,a3,a4
    80006744:	4609                	li	a2,2
    80006746:	00c69623          	sh	a2,12(a3)
    8000674a:	b5c9                	j	8000660c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000674c:	f9042583          	lw	a1,-112(s0)
    80006750:	20058793          	addi	a5,a1,512
    80006754:	0792                	slli	a5,a5,0x4
    80006756:	00016517          	auipc	a0,0x16
    8000675a:	95250513          	addi	a0,a0,-1710 # 8001c0a8 <disk+0xa8>
    8000675e:	953e                	add	a0,a0,a5
  if(write)
    80006760:	e20d11e3          	bnez	s10,80006582 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006764:	20058713          	addi	a4,a1,512
    80006768:	00471693          	slli	a3,a4,0x4
    8000676c:	00016717          	auipc	a4,0x16
    80006770:	89470713          	addi	a4,a4,-1900 # 8001c000 <disk>
    80006774:	9736                	add	a4,a4,a3
    80006776:	0a072423          	sw	zero,168(a4)
    8000677a:	b505                	j	8000659a <virtio_disk_rw+0xf4>

000000008000677c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000677c:	1101                	addi	sp,sp,-32
    8000677e:	ec06                	sd	ra,24(sp)
    80006780:	e822                	sd	s0,16(sp)
    80006782:	e426                	sd	s1,8(sp)
    80006784:	e04a                	sd	s2,0(sp)
    80006786:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006788:	00018517          	auipc	a0,0x18
    8000678c:	9a050513          	addi	a0,a0,-1632 # 8001e128 <disk+0x2128>
    80006790:	ffffa097          	auipc	ra,0xffffa
    80006794:	454080e7          	jalr	1108(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006798:	10001737          	lui	a4,0x10001
    8000679c:	533c                	lw	a5,96(a4)
    8000679e:	8b8d                	andi	a5,a5,3
    800067a0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800067a2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800067a6:	00018797          	auipc	a5,0x18
    800067aa:	85a78793          	addi	a5,a5,-1958 # 8001e000 <disk+0x2000>
    800067ae:	6b94                	ld	a3,16(a5)
    800067b0:	0207d703          	lhu	a4,32(a5)
    800067b4:	0026d783          	lhu	a5,2(a3)
    800067b8:	06f70163          	beq	a4,a5,8000681a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800067bc:	00016917          	auipc	s2,0x16
    800067c0:	84490913          	addi	s2,s2,-1980 # 8001c000 <disk>
    800067c4:	00018497          	auipc	s1,0x18
    800067c8:	83c48493          	addi	s1,s1,-1988 # 8001e000 <disk+0x2000>
    __sync_synchronize();
    800067cc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800067d0:	6898                	ld	a4,16(s1)
    800067d2:	0204d783          	lhu	a5,32(s1)
    800067d6:	8b9d                	andi	a5,a5,7
    800067d8:	078e                	slli	a5,a5,0x3
    800067da:	97ba                	add	a5,a5,a4
    800067dc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800067de:	20078713          	addi	a4,a5,512
    800067e2:	0712                	slli	a4,a4,0x4
    800067e4:	974a                	add	a4,a4,s2
    800067e6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800067ea:	e731                	bnez	a4,80006836 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800067ec:	20078793          	addi	a5,a5,512
    800067f0:	0792                	slli	a5,a5,0x4
    800067f2:	97ca                	add	a5,a5,s2
    800067f4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800067f6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800067fa:	ffffc097          	auipc	ra,0xffffc
    800067fe:	de2080e7          	jalr	-542(ra) # 800025dc <wakeup>

    disk.used_idx += 1;
    80006802:	0204d783          	lhu	a5,32(s1)
    80006806:	2785                	addiw	a5,a5,1
    80006808:	17c2                	slli	a5,a5,0x30
    8000680a:	93c1                	srli	a5,a5,0x30
    8000680c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006810:	6898                	ld	a4,16(s1)
    80006812:	00275703          	lhu	a4,2(a4)
    80006816:	faf71be3          	bne	a4,a5,800067cc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000681a:	00018517          	auipc	a0,0x18
    8000681e:	90e50513          	addi	a0,a0,-1778 # 8001e128 <disk+0x2128>
    80006822:	ffffa097          	auipc	ra,0xffffa
    80006826:	476080e7          	jalr	1142(ra) # 80000c98 <release>
}
    8000682a:	60e2                	ld	ra,24(sp)
    8000682c:	6442                	ld	s0,16(sp)
    8000682e:	64a2                	ld	s1,8(sp)
    80006830:	6902                	ld	s2,0(sp)
    80006832:	6105                	addi	sp,sp,32
    80006834:	8082                	ret
      panic("virtio_disk_intr status");
    80006836:	00002517          	auipc	a0,0x2
    8000683a:	0aa50513          	addi	a0,a0,170 # 800088e0 <syscalls+0x3c8>
    8000683e:	ffffa097          	auipc	ra,0xffffa
    80006842:	d00080e7          	jalr	-768(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
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
	...

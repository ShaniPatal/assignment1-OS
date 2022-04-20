
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8a013103          	ld	sp,-1888(sp) # 800088a0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
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
    80000068:	dbc78793          	addi	a5,a5,-580 # 80005e20 <timervec>
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
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	5ca080e7          	jalr	1482(ra) # 800026f6 <either_copyin>
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
    80000190:	ee450513          	addi	a0,a0,-284 # 8000a070 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	0000a497          	auipc	s1,0xa
    800001a0:	ed448493          	addi	s1,s1,-300 # 8000a070 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	0000a917          	auipc	s2,0xa
    800001aa:	f6290913          	addi	s2,s2,-158 # 8000a108 <cons+0x98>
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
    800001c4:	00001097          	auipc	ra,0x1
    800001c8:	7f4080e7          	jalr	2036(ra) # 800019b8 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	07c080e7          	jalr	124(ra) # 80002250 <sleep>
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
    80000214:	490080e7          	jalr	1168(ra) # 800026a0 <either_copyout>
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
    80000228:	e4c50513          	addi	a0,a0,-436 # 8000a070 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	0000a517          	auipc	a0,0xa
    8000023e:	e3650513          	addi	a0,a0,-458 # 8000a070 <cons>
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
    80000276:	e8f72b23          	sw	a5,-362(a4) # 8000a108 <cons+0x98>
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
    800002d0:	da450513          	addi	a0,a0,-604 # 8000a070 <cons>
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
    800002f6:	45a080e7          	jalr	1114(ra) # 8000274c <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	0000a517          	auipc	a0,0xa
    800002fe:	d7650513          	addi	a0,a0,-650 # 8000a070 <cons>
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
    80000322:	d5270713          	addi	a4,a4,-686 # 8000a070 <cons>
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
    8000034c:	d2878793          	addi	a5,a5,-728 # 8000a070 <cons>
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
    8000037a:	d927a783          	lw	a5,-622(a5) # 8000a108 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	0000a717          	auipc	a4,0xa
    8000038e:	ce670713          	addi	a4,a4,-794 # 8000a070 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	0000a497          	auipc	s1,0xa
    8000039e:	cd648493          	addi	s1,s1,-810 # 8000a070 <cons>
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
    800003da:	c9a70713          	addi	a4,a4,-870 # 8000a070 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	0000a717          	auipc	a4,0xa
    800003f0:	d2f72223          	sw	a5,-732(a4) # 8000a110 <cons+0xa0>
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
    80000416:	c5e78793          	addi	a5,a5,-930 # 8000a070 <cons>
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
    8000043a:	ccc7ab23          	sw	a2,-810(a5) # 8000a10c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	0000a517          	auipc	a0,0xa
    80000442:	cca50513          	addi	a0,a0,-822 # 8000a108 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	f96080e7          	jalr	-106(ra) # 800023dc <wakeup>
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
    80000464:	c1050513          	addi	a0,a0,-1008 # 8000a070 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	0001a797          	auipc	a5,0x1a
    8000047c:	01078793          	addi	a5,a5,16 # 8001a488 <devsw>
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
    8000054e:	be07a323          	sw	zero,-1050(a5) # 8000a130 <pr+0x18>
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
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
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
    800005be:	b76dad83          	lw	s11,-1162(s11) # 8000a130 <pr+0x18>
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
    800005fc:	b2050513          	addi	a0,a0,-1248 # 8000a118 <pr>
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
    80000760:	9bc50513          	addi	a0,a0,-1604 # 8000a118 <pr>
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
    8000077c:	9a048493          	addi	s1,s1,-1632 # 8000a118 <pr>
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
    800007dc:	96050513          	addi	a0,a0,-1696 # 8000a138 <uart_tx_lock>
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
    8000086e:	8cea0a13          	addi	s4,s4,-1842 # 8000a138 <uart_tx_lock>
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
    800008a4:	b3c080e7          	jalr	-1220(ra) # 800023dc <wakeup>
    
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
    800008e0:	85c50513          	addi	a0,a0,-1956 # 8000a138 <uart_tx_lock>
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
    80000914:	828a0a13          	addi	s4,s4,-2008 # 8000a138 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	924080e7          	jalr	-1756(ra) # 80002250 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00009497          	auipc	s1,0x9
    80000946:	7f648493          	addi	s1,s1,2038 # 8000a138 <uart_tx_lock>
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
    800009ce:	76e48493          	addi	s1,s1,1902 # 8000a138 <uart_tx_lock>
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
    80000a30:	74490913          	addi	s2,s2,1860 # 8000a170 <kmem>
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
    80000acc:	6a850513          	addi	a0,a0,1704 # 8000a170 <kmem>
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
    80000b02:	67248493          	addi	s1,s1,1650 # 8000a170 <kmem>
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
    80000b1a:	65a50513          	addi	a0,a0,1626 # 8000a170 <kmem>
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
    80000b46:	62e50513          	addi	a0,a0,1582 # 8000a170 <kmem>
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
    80000b82:	e1e080e7          	jalr	-482(ra) # 8000199c <mycpu>
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
    80000bb4:	dec080e7          	jalr	-532(ra) # 8000199c <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	de0080e7          	jalr	-544(ra) # 8000199c <mycpu>
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
    80000bd8:	dc8080e7          	jalr	-568(ra) # 8000199c <mycpu>
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
    80000c18:	d88080e7          	jalr	-632(ra) # 8000199c <mycpu>
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
    80000c44:	d5c080e7          	jalr	-676(ra) # 8000199c <mycpu>
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
    80000e9a:	af6080e7          	jalr	-1290(ra) # 8000198c <cpuid>
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
    80000eb6:	ada080e7          	jalr	-1318(ra) # 8000198c <cpuid>
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
    80000ed8:	9ee080e7          	jalr	-1554(ra) # 800028c2 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	f84080e7          	jalr	-124(ra) # 80005e60 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	20c080e7          	jalr	524(ra) # 800020f0 <scheduler>
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
    80000f08:	1c450513          	addi	a0,a0,452 # 800080c8 <digits+0x88>
    80000f0c:	fffff097          	auipc	ra,0xfffff
    80000f10:	67c080e7          	jalr	1660(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f14:	00007517          	auipc	a0,0x7
    80000f18:	18c50513          	addi	a0,a0,396 # 800080a0 <digits+0x60>
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	66c080e7          	jalr	1644(ra) # 80000588 <printf>
    printf("\n");
    80000f24:	00007517          	auipc	a0,0x7
    80000f28:	1a450513          	addi	a0,a0,420 # 800080c8 <digits+0x88>
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
    80000f58:	946080e7          	jalr	-1722(ra) # 8000289a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5c:	00002097          	auipc	ra,0x2
    80000f60:	966080e7          	jalr	-1690(ra) # 800028c2 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	ee6080e7          	jalr	-282(ra) # 80005e4a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6c:	00005097          	auipc	ra,0x5
    80000f70:	ef4080e7          	jalr	-268(ra) # 80005e60 <plicinithart>
    binit();         // buffer cache
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	0da080e7          	jalr	218(ra) # 8000304e <binit>
    iinit();         // inode table
    80000f7c:	00002097          	auipc	ra,0x2
    80000f80:	76a080e7          	jalr	1898(ra) # 800036e6 <iinit>
    fileinit();      // file table
    80000f84:	00003097          	auipc	ra,0x3
    80000f88:	714080e7          	jalr	1812(ra) # 80004698 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	ff6080e7          	jalr	-10(ra) # 80005f82 <virtio_disk_init>
    userinit();      // first user process
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	d08080e7          	jalr	-760(ra) # 80001c9c <userinit>
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
    80001860:	9e448493          	addi	s1,s1,-1564 # 8000a240 <proc>
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
    8000187a:	9caa0a13          	addi	s4,s4,-1590 # 80010240 <tickslock>
    char *pa = kalloc();
    8000187e:	fffff097          	auipc	ra,0xfffff
    80001882:	276080e7          	jalr	630(ra) # 80000af4 <kalloc>
    80001886:	862a                	mv	a2,a0
    if(pa == 0)
    80001888:	c131                	beqz	a0,800018cc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000188a:	416485b3          	sub	a1,s1,s6
    8000188e:	859d                	srai	a1,a1,0x7
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
    800018b0:	18048493          	addi	s1,s1,384
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
    800018fc:	89850513          	addi	a0,a0,-1896 # 8000a190 <pid_lock>
    80001900:	fffff097          	auipc	ra,0xfffff
    80001904:	254080e7          	jalr	596(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001908:	00007597          	auipc	a1,0x7
    8000190c:	8e058593          	addi	a1,a1,-1824 # 800081e8 <digits+0x1a8>
    80001910:	00009517          	auipc	a0,0x9
    80001914:	89850513          	addi	a0,a0,-1896 # 8000a1a8 <wait_lock>
    80001918:	fffff097          	auipc	ra,0xfffff
    8000191c:	23c080e7          	jalr	572(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001920:	00009497          	auipc	s1,0x9
    80001924:	92048493          	addi	s1,s1,-1760 # 8000a240 <proc>
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
    80001946:	8fe98993          	addi	s3,s3,-1794 # 80010240 <tickslock>
      initlock(&p->lock, "proc");
    8000194a:	85da                	mv	a1,s6
    8000194c:	8526                	mv	a0,s1
    8000194e:	fffff097          	auipc	ra,0xfffff
    80001952:	206080e7          	jalr	518(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001956:	415487b3          	sub	a5,s1,s5
    8000195a:	879d                	srai	a5,a5,0x7
    8000195c:	000a3703          	ld	a4,0(s4)
    80001960:	02e787b3          	mul	a5,a5,a4
    80001964:	2785                	addiw	a5,a5,1
    80001966:	00d7979b          	slliw	a5,a5,0xd
    8000196a:	40f907b3          	sub	a5,s2,a5
    8000196e:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001970:	18048493          	addi	s1,s1,384
    80001974:	fd349be3          	bne	s1,s3,8000194a <procinit+0x6e>
  }
}
    80001978:	70e2                	ld	ra,56(sp)
    8000197a:	7442                	ld	s0,48(sp)
    8000197c:	74a2                	ld	s1,40(sp)
    8000197e:	7902                	ld	s2,32(sp)
    80001980:	69e2                	ld	s3,24(sp)
    80001982:	6a42                	ld	s4,16(sp)
    80001984:	6aa2                	ld	s5,8(sp)
    80001986:	6b02                	ld	s6,0(sp)
    80001988:	6121                	addi	sp,sp,64
    8000198a:	8082                	ret

000000008000198c <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000198c:	1141                	addi	sp,sp,-16
    8000198e:	e422                	sd	s0,8(sp)
    80001990:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001992:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001994:	2501                	sext.w	a0,a0
    80001996:	6422                	ld	s0,8(sp)
    80001998:	0141                	addi	sp,sp,16
    8000199a:	8082                	ret

000000008000199c <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    8000199c:	1141                	addi	sp,sp,-16
    8000199e:	e422                	sd	s0,8(sp)
    800019a0:	0800                	addi	s0,sp,16
    800019a2:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019a4:	2781                	sext.w	a5,a5
    800019a6:	079e                	slli	a5,a5,0x7
  return c;
}
    800019a8:	00009517          	auipc	a0,0x9
    800019ac:	81850513          	addi	a0,a0,-2024 # 8000a1c0 <cpus>
    800019b0:	953e                	add	a0,a0,a5
    800019b2:	6422                	ld	s0,8(sp)
    800019b4:	0141                	addi	sp,sp,16
    800019b6:	8082                	ret

00000000800019b8 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019b8:	1101                	addi	sp,sp,-32
    800019ba:	ec06                	sd	ra,24(sp)
    800019bc:	e822                	sd	s0,16(sp)
    800019be:	e426                	sd	s1,8(sp)
    800019c0:	1000                	addi	s0,sp,32
  push_off();
    800019c2:	fffff097          	auipc	ra,0xfffff
    800019c6:	1d6080e7          	jalr	470(ra) # 80000b98 <push_off>
    800019ca:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019cc:	2781                	sext.w	a5,a5
    800019ce:	079e                	slli	a5,a5,0x7
    800019d0:	00008717          	auipc	a4,0x8
    800019d4:	7c070713          	addi	a4,a4,1984 # 8000a190 <pid_lock>
    800019d8:	97ba                	add	a5,a5,a4
    800019da:	7b84                	ld	s1,48(a5)
  pop_off();
    800019dc:	fffff097          	auipc	ra,0xfffff
    800019e0:	25c080e7          	jalr	604(ra) # 80000c38 <pop_off>
  return p;
}
    800019e4:	8526                	mv	a0,s1
    800019e6:	60e2                	ld	ra,24(sp)
    800019e8:	6442                	ld	s0,16(sp)
    800019ea:	64a2                	ld	s1,8(sp)
    800019ec:	6105                	addi	sp,sp,32
    800019ee:	8082                	ret

00000000800019f0 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019f0:	1141                	addi	sp,sp,-16
    800019f2:	e406                	sd	ra,8(sp)
    800019f4:	e022                	sd	s0,0(sp)
    800019f6:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019f8:	00000097          	auipc	ra,0x0
    800019fc:	fc0080e7          	jalr	-64(ra) # 800019b8 <myproc>
    80001a00:	fffff097          	auipc	ra,0xfffff
    80001a04:	298080e7          	jalr	664(ra) # 80000c98 <release>

  if (first) {
    80001a08:	00007797          	auipc	a5,0x7
    80001a0c:	e487a783          	lw	a5,-440(a5) # 80008850 <first.1702>
    80001a10:	eb89                	bnez	a5,80001a22 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a12:	00001097          	auipc	ra,0x1
    80001a16:	ec8080e7          	jalr	-312(ra) # 800028da <usertrapret>
}
    80001a1a:	60a2                	ld	ra,8(sp)
    80001a1c:	6402                	ld	s0,0(sp)
    80001a1e:	0141                	addi	sp,sp,16
    80001a20:	8082                	ret
    first = 0;
    80001a22:	00007797          	auipc	a5,0x7
    80001a26:	e207a723          	sw	zero,-466(a5) # 80008850 <first.1702>
    fsinit(ROOTDEV);
    80001a2a:	4505                	li	a0,1
    80001a2c:	00002097          	auipc	ra,0x2
    80001a30:	c3a080e7          	jalr	-966(ra) # 80003666 <fsinit>
    80001a34:	bff9                	j	80001a12 <forkret+0x22>

0000000080001a36 <allocpid>:
allocpid() {
    80001a36:	1101                	addi	sp,sp,-32
    80001a38:	ec06                	sd	ra,24(sp)
    80001a3a:	e822                	sd	s0,16(sp)
    80001a3c:	e426                	sd	s1,8(sp)
    80001a3e:	e04a                	sd	s2,0(sp)
    80001a40:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a42:	00008917          	auipc	s2,0x8
    80001a46:	74e90913          	addi	s2,s2,1870 # 8000a190 <pid_lock>
    80001a4a:	854a                	mv	a0,s2
    80001a4c:	fffff097          	auipc	ra,0xfffff
    80001a50:	198080e7          	jalr	408(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a54:	00007797          	auipc	a5,0x7
    80001a58:	e0478793          	addi	a5,a5,-508 # 80008858 <nextpid>
    80001a5c:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a5e:	0014871b          	addiw	a4,s1,1
    80001a62:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a64:	854a                	mv	a0,s2
    80001a66:	fffff097          	auipc	ra,0xfffff
    80001a6a:	232080e7          	jalr	562(ra) # 80000c98 <release>
}
    80001a6e:	8526                	mv	a0,s1
    80001a70:	60e2                	ld	ra,24(sp)
    80001a72:	6442                	ld	s0,16(sp)
    80001a74:	64a2                	ld	s1,8(sp)
    80001a76:	6902                	ld	s2,0(sp)
    80001a78:	6105                	addi	sp,sp,32
    80001a7a:	8082                	ret

0000000080001a7c <proc_pagetable>:
{
    80001a7c:	1101                	addi	sp,sp,-32
    80001a7e:	ec06                	sd	ra,24(sp)
    80001a80:	e822                	sd	s0,16(sp)
    80001a82:	e426                	sd	s1,8(sp)
    80001a84:	e04a                	sd	s2,0(sp)
    80001a86:	1000                	addi	s0,sp,32
    80001a88:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a8a:	00000097          	auipc	ra,0x0
    80001a8e:	8b8080e7          	jalr	-1864(ra) # 80001342 <uvmcreate>
    80001a92:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a94:	c121                	beqz	a0,80001ad4 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a96:	4729                	li	a4,10
    80001a98:	00005697          	auipc	a3,0x5
    80001a9c:	56868693          	addi	a3,a3,1384 # 80007000 <_trampoline>
    80001aa0:	6605                	lui	a2,0x1
    80001aa2:	040005b7          	lui	a1,0x4000
    80001aa6:	15fd                	addi	a1,a1,-1
    80001aa8:	05b2                	slli	a1,a1,0xc
    80001aaa:	fffff097          	auipc	ra,0xfffff
    80001aae:	60e080e7          	jalr	1550(ra) # 800010b8 <mappages>
    80001ab2:	02054863          	bltz	a0,80001ae2 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ab6:	4719                	li	a4,6
    80001ab8:	05893683          	ld	a3,88(s2)
    80001abc:	6605                	lui	a2,0x1
    80001abe:	020005b7          	lui	a1,0x2000
    80001ac2:	15fd                	addi	a1,a1,-1
    80001ac4:	05b6                	slli	a1,a1,0xd
    80001ac6:	8526                	mv	a0,s1
    80001ac8:	fffff097          	auipc	ra,0xfffff
    80001acc:	5f0080e7          	jalr	1520(ra) # 800010b8 <mappages>
    80001ad0:	02054163          	bltz	a0,80001af2 <proc_pagetable+0x76>
}
    80001ad4:	8526                	mv	a0,s1
    80001ad6:	60e2                	ld	ra,24(sp)
    80001ad8:	6442                	ld	s0,16(sp)
    80001ada:	64a2                	ld	s1,8(sp)
    80001adc:	6902                	ld	s2,0(sp)
    80001ade:	6105                	addi	sp,sp,32
    80001ae0:	8082                	ret
    uvmfree(pagetable, 0);
    80001ae2:	4581                	li	a1,0
    80001ae4:	8526                	mv	a0,s1
    80001ae6:	00000097          	auipc	ra,0x0
    80001aea:	a58080e7          	jalr	-1448(ra) # 8000153e <uvmfree>
    return 0;
    80001aee:	4481                	li	s1,0
    80001af0:	b7d5                	j	80001ad4 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001af2:	4681                	li	a3,0
    80001af4:	4605                	li	a2,1
    80001af6:	040005b7          	lui	a1,0x4000
    80001afa:	15fd                	addi	a1,a1,-1
    80001afc:	05b2                	slli	a1,a1,0xc
    80001afe:	8526                	mv	a0,s1
    80001b00:	fffff097          	auipc	ra,0xfffff
    80001b04:	77e080e7          	jalr	1918(ra) # 8000127e <uvmunmap>
    uvmfree(pagetable, 0);
    80001b08:	4581                	li	a1,0
    80001b0a:	8526                	mv	a0,s1
    80001b0c:	00000097          	auipc	ra,0x0
    80001b10:	a32080e7          	jalr	-1486(ra) # 8000153e <uvmfree>
    return 0;
    80001b14:	4481                	li	s1,0
    80001b16:	bf7d                	j	80001ad4 <proc_pagetable+0x58>

0000000080001b18 <proc_freepagetable>:
{
    80001b18:	1101                	addi	sp,sp,-32
    80001b1a:	ec06                	sd	ra,24(sp)
    80001b1c:	e822                	sd	s0,16(sp)
    80001b1e:	e426                	sd	s1,8(sp)
    80001b20:	e04a                	sd	s2,0(sp)
    80001b22:	1000                	addi	s0,sp,32
    80001b24:	84aa                	mv	s1,a0
    80001b26:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b28:	4681                	li	a3,0
    80001b2a:	4605                	li	a2,1
    80001b2c:	040005b7          	lui	a1,0x4000
    80001b30:	15fd                	addi	a1,a1,-1
    80001b32:	05b2                	slli	a1,a1,0xc
    80001b34:	fffff097          	auipc	ra,0xfffff
    80001b38:	74a080e7          	jalr	1866(ra) # 8000127e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b3c:	4681                	li	a3,0
    80001b3e:	4605                	li	a2,1
    80001b40:	020005b7          	lui	a1,0x2000
    80001b44:	15fd                	addi	a1,a1,-1
    80001b46:	05b6                	slli	a1,a1,0xd
    80001b48:	8526                	mv	a0,s1
    80001b4a:	fffff097          	auipc	ra,0xfffff
    80001b4e:	734080e7          	jalr	1844(ra) # 8000127e <uvmunmap>
  uvmfree(pagetable, sz);
    80001b52:	85ca                	mv	a1,s2
    80001b54:	8526                	mv	a0,s1
    80001b56:	00000097          	auipc	ra,0x0
    80001b5a:	9e8080e7          	jalr	-1560(ra) # 8000153e <uvmfree>
}
    80001b5e:	60e2                	ld	ra,24(sp)
    80001b60:	6442                	ld	s0,16(sp)
    80001b62:	64a2                	ld	s1,8(sp)
    80001b64:	6902                	ld	s2,0(sp)
    80001b66:	6105                	addi	sp,sp,32
    80001b68:	8082                	ret

0000000080001b6a <freeproc>:
{
    80001b6a:	1101                	addi	sp,sp,-32
    80001b6c:	ec06                	sd	ra,24(sp)
    80001b6e:	e822                	sd	s0,16(sp)
    80001b70:	e426                	sd	s1,8(sp)
    80001b72:	1000                	addi	s0,sp,32
    80001b74:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b76:	6d28                	ld	a0,88(a0)
    80001b78:	c509                	beqz	a0,80001b82 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b7a:	fffff097          	auipc	ra,0xfffff
    80001b7e:	e7e080e7          	jalr	-386(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b82:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b86:	68a8                	ld	a0,80(s1)
    80001b88:	c511                	beqz	a0,80001b94 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b8a:	64ac                	ld	a1,72(s1)
    80001b8c:	00000097          	auipc	ra,0x0
    80001b90:	f8c080e7          	jalr	-116(ra) # 80001b18 <proc_freepagetable>
  p->pagetable = 0;
    80001b94:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b98:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b9c:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001ba0:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001ba4:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ba8:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bac:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bb0:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bb4:	0004ac23          	sw	zero,24(s1)
}
    80001bb8:	60e2                	ld	ra,24(sp)
    80001bba:	6442                	ld	s0,16(sp)
    80001bbc:	64a2                	ld	s1,8(sp)
    80001bbe:	6105                	addi	sp,sp,32
    80001bc0:	8082                	ret

0000000080001bc2 <allocproc>:
{
    80001bc2:	1101                	addi	sp,sp,-32
    80001bc4:	ec06                	sd	ra,24(sp)
    80001bc6:	e822                	sd	s0,16(sp)
    80001bc8:	e426                	sd	s1,8(sp)
    80001bca:	e04a                	sd	s2,0(sp)
    80001bcc:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bce:	00008497          	auipc	s1,0x8
    80001bd2:	67248493          	addi	s1,s1,1650 # 8000a240 <proc>
    80001bd6:	0000e917          	auipc	s2,0xe
    80001bda:	66a90913          	addi	s2,s2,1642 # 80010240 <tickslock>
    acquire(&p->lock);
    80001bde:	8526                	mv	a0,s1
    80001be0:	fffff097          	auipc	ra,0xfffff
    80001be4:	004080e7          	jalr	4(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001be8:	4c9c                	lw	a5,24(s1)
    80001bea:	cf81                	beqz	a5,80001c02 <allocproc+0x40>
      release(&p->lock);
    80001bec:	8526                	mv	a0,s1
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	0aa080e7          	jalr	170(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bf6:	18048493          	addi	s1,s1,384
    80001bfa:	ff2492e3          	bne	s1,s2,80001bde <allocproc+0x1c>
  return 0;
    80001bfe:	4481                	li	s1,0
    80001c00:	a8b9                	j	80001c5e <allocproc+0x9c>
  p->pid = allocpid();
    80001c02:	00000097          	auipc	ra,0x0
    80001c06:	e34080e7          	jalr	-460(ra) # 80001a36 <allocpid>
    80001c0a:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c0c:	4785                	li	a5,1
    80001c0e:	cc9c                	sw	a5,24(s1)
  p->mean_ticks = 0;
    80001c10:	1604b423          	sd	zero,360(s1)
  p->last_ticks = 0;
    80001c14:	1604b823          	sd	zero,368(s1)
  p->start_cpu_burst = 0;
    80001c18:	1604bc23          	sd	zero,376(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c1c:	fffff097          	auipc	ra,0xfffff
    80001c20:	ed8080e7          	jalr	-296(ra) # 80000af4 <kalloc>
    80001c24:	892a                	mv	s2,a0
    80001c26:	eca8                	sd	a0,88(s1)
    80001c28:	c131                	beqz	a0,80001c6c <allocproc+0xaa>
  p->pagetable = proc_pagetable(p);
    80001c2a:	8526                	mv	a0,s1
    80001c2c:	00000097          	auipc	ra,0x0
    80001c30:	e50080e7          	jalr	-432(ra) # 80001a7c <proc_pagetable>
    80001c34:	892a                	mv	s2,a0
    80001c36:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c38:	c531                	beqz	a0,80001c84 <allocproc+0xc2>
  memset(&p->context, 0, sizeof(p->context));
    80001c3a:	07000613          	li	a2,112
    80001c3e:	4581                	li	a1,0
    80001c40:	06048513          	addi	a0,s1,96
    80001c44:	fffff097          	auipc	ra,0xfffff
    80001c48:	09c080e7          	jalr	156(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c4c:	00000797          	auipc	a5,0x0
    80001c50:	da478793          	addi	a5,a5,-604 # 800019f0 <forkret>
    80001c54:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c56:	60bc                	ld	a5,64(s1)
    80001c58:	6705                	lui	a4,0x1
    80001c5a:	97ba                	add	a5,a5,a4
    80001c5c:	f4bc                	sd	a5,104(s1)
}
    80001c5e:	8526                	mv	a0,s1
    80001c60:	60e2                	ld	ra,24(sp)
    80001c62:	6442                	ld	s0,16(sp)
    80001c64:	64a2                	ld	s1,8(sp)
    80001c66:	6902                	ld	s2,0(sp)
    80001c68:	6105                	addi	sp,sp,32
    80001c6a:	8082                	ret
    freeproc(p);
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	00000097          	auipc	ra,0x0
    80001c72:	efc080e7          	jalr	-260(ra) # 80001b6a <freeproc>
    release(&p->lock);
    80001c76:	8526                	mv	a0,s1
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	020080e7          	jalr	32(ra) # 80000c98 <release>
    return 0;
    80001c80:	84ca                	mv	s1,s2
    80001c82:	bff1                	j	80001c5e <allocproc+0x9c>
    freeproc(p);
    80001c84:	8526                	mv	a0,s1
    80001c86:	00000097          	auipc	ra,0x0
    80001c8a:	ee4080e7          	jalr	-284(ra) # 80001b6a <freeproc>
    release(&p->lock);
    80001c8e:	8526                	mv	a0,s1
    80001c90:	fffff097          	auipc	ra,0xfffff
    80001c94:	008080e7          	jalr	8(ra) # 80000c98 <release>
    return 0;
    80001c98:	84ca                	mv	s1,s2
    80001c9a:	b7d1                	j	80001c5e <allocproc+0x9c>

0000000080001c9c <userinit>:
{
    80001c9c:	1101                	addi	sp,sp,-32
    80001c9e:	ec06                	sd	ra,24(sp)
    80001ca0:	e822                	sd	s0,16(sp)
    80001ca2:	e426                	sd	s1,8(sp)
    80001ca4:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ca6:	00000097          	auipc	ra,0x0
    80001caa:	f1c080e7          	jalr	-228(ra) # 80001bc2 <allocproc>
    80001cae:	84aa                	mv	s1,a0
  initproc = p;
    80001cb0:	00007797          	auipc	a5,0x7
    80001cb4:	38a7b023          	sd	a0,896(a5) # 80009030 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cb8:	03400613          	li	a2,52
    80001cbc:	00007597          	auipc	a1,0x7
    80001cc0:	ba458593          	addi	a1,a1,-1116 # 80008860 <initcode>
    80001cc4:	6928                	ld	a0,80(a0)
    80001cc6:	fffff097          	auipc	ra,0xfffff
    80001cca:	6aa080e7          	jalr	1706(ra) # 80001370 <uvminit>
  p->sz = PGSIZE;
    80001cce:	6785                	lui	a5,0x1
    80001cd0:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cd2:	6cb8                	ld	a4,88(s1)
    80001cd4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cd8:	6cb8                	ld	a4,88(s1)
    80001cda:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cdc:	4641                	li	a2,16
    80001cde:	00006597          	auipc	a1,0x6
    80001ce2:	52258593          	addi	a1,a1,1314 # 80008200 <digits+0x1c0>
    80001ce6:	15848513          	addi	a0,s1,344
    80001cea:	fffff097          	auipc	ra,0xfffff
    80001cee:	148080e7          	jalr	328(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001cf2:	00006517          	auipc	a0,0x6
    80001cf6:	51e50513          	addi	a0,a0,1310 # 80008210 <digits+0x1d0>
    80001cfa:	00002097          	auipc	ra,0x2
    80001cfe:	39a080e7          	jalr	922(ra) # 80004094 <namei>
    80001d02:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d06:	478d                	li	a5,3
    80001d08:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d0a:	8526                	mv	a0,s1
    80001d0c:	fffff097          	auipc	ra,0xfffff
    80001d10:	f8c080e7          	jalr	-116(ra) # 80000c98 <release>
}
    80001d14:	60e2                	ld	ra,24(sp)
    80001d16:	6442                	ld	s0,16(sp)
    80001d18:	64a2                	ld	s1,8(sp)
    80001d1a:	6105                	addi	sp,sp,32
    80001d1c:	8082                	ret

0000000080001d1e <growproc>:
{
    80001d1e:	1101                	addi	sp,sp,-32
    80001d20:	ec06                	sd	ra,24(sp)
    80001d22:	e822                	sd	s0,16(sp)
    80001d24:	e426                	sd	s1,8(sp)
    80001d26:	e04a                	sd	s2,0(sp)
    80001d28:	1000                	addi	s0,sp,32
    80001d2a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d2c:	00000097          	auipc	ra,0x0
    80001d30:	c8c080e7          	jalr	-884(ra) # 800019b8 <myproc>
    80001d34:	892a                	mv	s2,a0
  sz = p->sz;
    80001d36:	652c                	ld	a1,72(a0)
    80001d38:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d3c:	00904f63          	bgtz	s1,80001d5a <growproc+0x3c>
  } else if(n < 0){
    80001d40:	0204cc63          	bltz	s1,80001d78 <growproc+0x5a>
  p->sz = sz;
    80001d44:	1602                	slli	a2,a2,0x20
    80001d46:	9201                	srli	a2,a2,0x20
    80001d48:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d4c:	4501                	li	a0,0
}
    80001d4e:	60e2                	ld	ra,24(sp)
    80001d50:	6442                	ld	s0,16(sp)
    80001d52:	64a2                	ld	s1,8(sp)
    80001d54:	6902                	ld	s2,0(sp)
    80001d56:	6105                	addi	sp,sp,32
    80001d58:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d5a:	9e25                	addw	a2,a2,s1
    80001d5c:	1602                	slli	a2,a2,0x20
    80001d5e:	9201                	srli	a2,a2,0x20
    80001d60:	1582                	slli	a1,a1,0x20
    80001d62:	9181                	srli	a1,a1,0x20
    80001d64:	6928                	ld	a0,80(a0)
    80001d66:	fffff097          	auipc	ra,0xfffff
    80001d6a:	6c4080e7          	jalr	1732(ra) # 8000142a <uvmalloc>
    80001d6e:	0005061b          	sext.w	a2,a0
    80001d72:	fa69                	bnez	a2,80001d44 <growproc+0x26>
      return -1;
    80001d74:	557d                	li	a0,-1
    80001d76:	bfe1                	j	80001d4e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d78:	9e25                	addw	a2,a2,s1
    80001d7a:	1602                	slli	a2,a2,0x20
    80001d7c:	9201                	srli	a2,a2,0x20
    80001d7e:	1582                	slli	a1,a1,0x20
    80001d80:	9181                	srli	a1,a1,0x20
    80001d82:	6928                	ld	a0,80(a0)
    80001d84:	fffff097          	auipc	ra,0xfffff
    80001d88:	65e080e7          	jalr	1630(ra) # 800013e2 <uvmdealloc>
    80001d8c:	0005061b          	sext.w	a2,a0
    80001d90:	bf55                	j	80001d44 <growproc+0x26>

0000000080001d92 <fork>:
{
    80001d92:	7179                	addi	sp,sp,-48
    80001d94:	f406                	sd	ra,40(sp)
    80001d96:	f022                	sd	s0,32(sp)
    80001d98:	ec26                	sd	s1,24(sp)
    80001d9a:	e84a                	sd	s2,16(sp)
    80001d9c:	e44e                	sd	s3,8(sp)
    80001d9e:	e052                	sd	s4,0(sp)
    80001da0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001da2:	00000097          	auipc	ra,0x0
    80001da6:	c16080e7          	jalr	-1002(ra) # 800019b8 <myproc>
    80001daa:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001dac:	00000097          	auipc	ra,0x0
    80001db0:	e16080e7          	jalr	-490(ra) # 80001bc2 <allocproc>
    80001db4:	10050b63          	beqz	a0,80001eca <fork+0x138>
    80001db8:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dba:	04893603          	ld	a2,72(s2)
    80001dbe:	692c                	ld	a1,80(a0)
    80001dc0:	05093503          	ld	a0,80(s2)
    80001dc4:	fffff097          	auipc	ra,0xfffff
    80001dc8:	7b2080e7          	jalr	1970(ra) # 80001576 <uvmcopy>
    80001dcc:	04054663          	bltz	a0,80001e18 <fork+0x86>
  np->sz = p->sz;
    80001dd0:	04893783          	ld	a5,72(s2)
    80001dd4:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dd8:	05893683          	ld	a3,88(s2)
    80001ddc:	87b6                	mv	a5,a3
    80001dde:	0589b703          	ld	a4,88(s3)
    80001de2:	12068693          	addi	a3,a3,288
    80001de6:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dea:	6788                	ld	a0,8(a5)
    80001dec:	6b8c                	ld	a1,16(a5)
    80001dee:	6f90                	ld	a2,24(a5)
    80001df0:	01073023          	sd	a6,0(a4)
    80001df4:	e708                	sd	a0,8(a4)
    80001df6:	eb0c                	sd	a1,16(a4)
    80001df8:	ef10                	sd	a2,24(a4)
    80001dfa:	02078793          	addi	a5,a5,32
    80001dfe:	02070713          	addi	a4,a4,32
    80001e02:	fed792e3          	bne	a5,a3,80001de6 <fork+0x54>
  np->trapframe->a0 = 0;
    80001e06:	0589b783          	ld	a5,88(s3)
    80001e0a:	0607b823          	sd	zero,112(a5)
    80001e0e:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e12:	15000a13          	li	s4,336
    80001e16:	a03d                	j	80001e44 <fork+0xb2>
    freeproc(np);
    80001e18:	854e                	mv	a0,s3
    80001e1a:	00000097          	auipc	ra,0x0
    80001e1e:	d50080e7          	jalr	-688(ra) # 80001b6a <freeproc>
    release(&np->lock);
    80001e22:	854e                	mv	a0,s3
    80001e24:	fffff097          	auipc	ra,0xfffff
    80001e28:	e74080e7          	jalr	-396(ra) # 80000c98 <release>
    return -1;
    80001e2c:	5a7d                	li	s4,-1
    80001e2e:	a069                	j	80001eb8 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e30:	00003097          	auipc	ra,0x3
    80001e34:	8fa080e7          	jalr	-1798(ra) # 8000472a <filedup>
    80001e38:	009987b3          	add	a5,s3,s1
    80001e3c:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e3e:	04a1                	addi	s1,s1,8
    80001e40:	01448763          	beq	s1,s4,80001e4e <fork+0xbc>
    if(p->ofile[i])
    80001e44:	009907b3          	add	a5,s2,s1
    80001e48:	6388                	ld	a0,0(a5)
    80001e4a:	f17d                	bnez	a0,80001e30 <fork+0x9e>
    80001e4c:	bfcd                	j	80001e3e <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e4e:	15093503          	ld	a0,336(s2)
    80001e52:	00002097          	auipc	ra,0x2
    80001e56:	a4e080e7          	jalr	-1458(ra) # 800038a0 <idup>
    80001e5a:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e5e:	4641                	li	a2,16
    80001e60:	15890593          	addi	a1,s2,344
    80001e64:	15898513          	addi	a0,s3,344
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	fca080e7          	jalr	-54(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e70:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e74:	854e                	mv	a0,s3
    80001e76:	fffff097          	auipc	ra,0xfffff
    80001e7a:	e22080e7          	jalr	-478(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001e7e:	00008497          	auipc	s1,0x8
    80001e82:	32a48493          	addi	s1,s1,810 # 8000a1a8 <wait_lock>
    80001e86:	8526                	mv	a0,s1
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	d5c080e7          	jalr	-676(ra) # 80000be4 <acquire>
  np->parent = p;
    80001e90:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001e94:	8526                	mv	a0,s1
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	e02080e7          	jalr	-510(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001e9e:	854e                	mv	a0,s3
    80001ea0:	fffff097          	auipc	ra,0xfffff
    80001ea4:	d44080e7          	jalr	-700(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001ea8:	478d                	li	a5,3
    80001eaa:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001eae:	854e                	mv	a0,s3
    80001eb0:	fffff097          	auipc	ra,0xfffff
    80001eb4:	de8080e7          	jalr	-536(ra) # 80000c98 <release>
}
    80001eb8:	8552                	mv	a0,s4
    80001eba:	70a2                	ld	ra,40(sp)
    80001ebc:	7402                	ld	s0,32(sp)
    80001ebe:	64e2                	ld	s1,24(sp)
    80001ec0:	6942                	ld	s2,16(sp)
    80001ec2:	69a2                	ld	s3,8(sp)
    80001ec4:	6a02                	ld	s4,0(sp)
    80001ec6:	6145                	addi	sp,sp,48
    80001ec8:	8082                	ret
    return -1;
    80001eca:	5a7d                	li	s4,-1
    80001ecc:	b7f5                	j	80001eb8 <fork+0x126>

0000000080001ece <round_robin>:
round_robin(){
    80001ece:	711d                	addi	sp,sp,-96
    80001ed0:	ec86                	sd	ra,88(sp)
    80001ed2:	e8a2                	sd	s0,80(sp)
    80001ed4:	e4a6                	sd	s1,72(sp)
    80001ed6:	e0ca                	sd	s2,64(sp)
    80001ed8:	fc4e                	sd	s3,56(sp)
    80001eda:	f852                	sd	s4,48(sp)
    80001edc:	f456                	sd	s5,40(sp)
    80001ede:	f05a                	sd	s6,32(sp)
    80001ee0:	ec5e                	sd	s7,24(sp)
    80001ee2:	e862                	sd	s8,16(sp)
    80001ee4:	e466                	sd	s9,8(sp)
    80001ee6:	1080                	addi	s0,sp,96
    printf("Round Robin Policy \n");
    80001ee8:	00006517          	auipc	a0,0x6
    80001eec:	33050513          	addi	a0,a0,816 # 80008218 <digits+0x1d8>
    80001ef0:	ffffe097          	auipc	ra,0xffffe
    80001ef4:	698080e7          	jalr	1688(ra) # 80000588 <printf>
    80001ef8:	8792                	mv	a5,tp
  int id = r_tp();
    80001efa:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001efc:	00779c13          	slli	s8,a5,0x7
    80001f00:	00008717          	auipc	a4,0x8
    80001f04:	29070713          	addi	a4,a4,656 # 8000a190 <pid_lock>
    80001f08:	9762                	add	a4,a4,s8
    80001f0a:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &p->context);
    80001f0e:	00008717          	auipc	a4,0x8
    80001f12:	2ba70713          	addi	a4,a4,698 # 8000a1c8 <cpus+0x8>
    80001f16:	9c3a                	add	s8,s8,a4
          c->proc = p;
    80001f18:	079e                	slli	a5,a5,0x7
    80001f1a:	00008a97          	auipc	s5,0x8
    80001f1e:	276a8a93          	addi	s5,s5,630 # 8000a190 <pid_lock>
    80001f22:	9abe                	add	s5,s5,a5
          if(p->pid != 1 && p->pid != 2 && pause_time != 0){
    80001f24:	00007b17          	auipc	s6,0x7
    80001f28:	104b0b13          	addi	s6,s6,260 # 80009028 <pause_time>
            if(ticks >= pause_time){
    80001f2c:	00007c97          	auipc	s9,0x7
    80001f30:	10cc8c93          	addi	s9,s9,268 # 80009038 <ticks>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f34:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f38:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f3c:	10079073          	csrw	sstatus,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f40:	00008497          	auipc	s1,0x8
    80001f44:	30048493          	addi	s1,s1,768 # 8000a240 <proc>
        if(p->state == RUNNABLE) {
    80001f48:	4a0d                	li	s4,3
          if(p->pid != 1 && p->pid != 2 && pause_time != 0){
    80001f4a:	4b85                	li	s7,1
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f4c:	0000e997          	auipc	s3,0xe
    80001f50:	2f498993          	addi	s3,s3,756 # 80010240 <tickslock>
    80001f54:	a80d                	j	80001f86 <round_robin+0xb8>
              pause_time = 0;
    80001f56:	000b2023          	sw	zero,0(s6)
          p->state = RUNNING;
    80001f5a:	4791                	li	a5,4
    80001f5c:	cc9c                	sw	a5,24(s1)
          c->proc = p;
    80001f5e:	029ab823          	sd	s1,48(s5)
          swtch(&c->context, &p->context);
    80001f62:	06090593          	addi	a1,s2,96
    80001f66:	8562                	mv	a0,s8
    80001f68:	00001097          	auipc	ra,0x1
    80001f6c:	8c8080e7          	jalr	-1848(ra) # 80002830 <swtch>
          c->proc = 0;
    80001f70:	020ab823          	sd	zero,48(s5)
        release(&p->lock);
    80001f74:	8526                	mv	a0,s1
    80001f76:	fffff097          	auipc	ra,0xfffff
    80001f7a:	d22080e7          	jalr	-734(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f7e:	18048493          	addi	s1,s1,384
    80001f82:	fb3489e3          	beq	s1,s3,80001f34 <round_robin+0x66>
        acquire(&p->lock);
    80001f86:	8926                	mv	s2,s1
    80001f88:	8526                	mv	a0,s1
    80001f8a:	fffff097          	auipc	ra,0xfffff
    80001f8e:	c5a080e7          	jalr	-934(ra) # 80000be4 <acquire>
        if(p->state == RUNNABLE) {
    80001f92:	4c9c                	lw	a5,24(s1)
    80001f94:	ff4790e3          	bne	a5,s4,80001f74 <round_robin+0xa6>
          if(p->pid != 1 && p->pid != 2 && pause_time != 0){
    80001f98:	589c                	lw	a5,48(s1)
    80001f9a:	37fd                	addiw	a5,a5,-1
    80001f9c:	fafbffe3          	bgeu	s7,a5,80001f5a <round_robin+0x8c>
    80001fa0:	000b2783          	lw	a5,0(s6)
    80001fa4:	dbdd                	beqz	a5,80001f5a <round_robin+0x8c>
            if(ticks >= pause_time){
    80001fa6:	000ca703          	lw	a4,0(s9)
    80001faa:	faf776e3          	bgeu	a4,a5,80001f56 <round_robin+0x88>
              release(&p->lock);
    80001fae:	8526                	mv	a0,s1
    80001fb0:	fffff097          	auipc	ra,0xfffff
    80001fb4:	ce8080e7          	jalr	-792(ra) # 80000c98 <release>
              continue;
    80001fb8:	b7d9                	j	80001f7e <round_robin+0xb0>

0000000080001fba <sjf>:
sjf(void){
    80001fba:	711d                	addi	sp,sp,-96
    80001fbc:	ec86                	sd	ra,88(sp)
    80001fbe:	e8a2                	sd	s0,80(sp)
    80001fc0:	e4a6                	sd	s1,72(sp)
    80001fc2:	e0ca                	sd	s2,64(sp)
    80001fc4:	fc4e                	sd	s3,56(sp)
    80001fc6:	f852                	sd	s4,48(sp)
    80001fc8:	f456                	sd	s5,40(sp)
    80001fca:	f05a                	sd	s6,32(sp)
    80001fcc:	ec5e                	sd	s7,24(sp)
    80001fce:	e862                	sd	s8,16(sp)
    80001fd0:	e466                	sd	s9,8(sp)
    80001fd2:	e06a                	sd	s10,0(sp)
    80001fd4:	1080                	addi	s0,sp,96
  printf("SJF Policy \n");
    80001fd6:	00006517          	auipc	a0,0x6
    80001fda:	25a50513          	addi	a0,a0,602 # 80008230 <digits+0x1f0>
    80001fde:	ffffe097          	auipc	ra,0xffffe
    80001fe2:	5aa080e7          	jalr	1450(ra) # 80000588 <printf>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fe6:	8792                	mv	a5,tp
  int id = r_tp();
    80001fe8:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fea:	00779d13          	slli	s10,a5,0x7
    80001fee:	00008717          	auipc	a4,0x8
    80001ff2:	1a270713          	addi	a4,a4,418 # 8000a190 <pid_lock>
    80001ff6:	976a                	add	a4,a4,s10
    80001ff8:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &p->context);
    80001ffc:	00008717          	auipc	a4,0x8
    80002000:	1cc70713          	addi	a4,a4,460 # 8000a1c8 <cpus+0x8>
    80002004:	9d3a                	add	s10,s10,a4
  struct proc *min_proc = proc;
    80002006:	00008a97          	auipc	s5,0x8
    8000200a:	23aa8a93          	addi	s5,s5,570 # 8000a240 <proc>
    int min = -1;
    8000200e:	5b7d                	li	s6,-1
      if(pause_time != 0){  
    80002010:	00007917          	auipc	s2,0x7
    80002014:	01890913          	addi	s2,s2,24 # 80009028 <pause_time>
          if(ticks >= pause_time){
    80002018:	00007c17          	auipc	s8,0x7
    8000201c:	020c0c13          	addi	s8,s8,32 # 80009038 <ticks>
          c->proc = min_proc;
    80002020:	079e                	slli	a5,a5,0x7
    80002022:	00008c97          	auipc	s9,0x8
    80002026:	16ec8c93          	addi	s9,s9,366 # 8000a190 <pid_lock>
    8000202a:	9cbe                	add	s9,s9,a5
    8000202c:	a04d                	j	800020ce <sjf+0x114>
           release(&p->lock);
    8000202e:	8526                	mv	a0,s1
    80002030:	fffff097          	auipc	ra,0xfffff
    80002034:	c68080e7          	jalr	-920(ra) # 80000c98 <release>
           continue;
    80002038:	a839                	j	80002056 <sjf+0x9c>
      else if(min == -1 || p->mean_ticks < min){
    8000203a:	01698663          	beq	s3,s6,80002046 <sjf+0x8c>
    8000203e:	1684b783          	ld	a5,360(s1)
    80002042:	0137f563          	bgeu	a5,s3,8000204c <sjf+0x92>
              min = p->mean_ticks;
    80002046:	1684a983          	lw	s3,360(s1)
    8000204a:	8aa6                	mv	s5,s1
        release(&p->lock);
    8000204c:	8526                	mv	a0,s1
    8000204e:	fffff097          	auipc	ra,0xfffff
    80002052:	c4a080e7          	jalr	-950(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) { 
    80002056:	18048493          	addi	s1,s1,384
    8000205a:	03448663          	beq	s1,s4,80002086 <sjf+0xcc>
      acquire(&p->lock);
    8000205e:	8526                	mv	a0,s1
    80002060:	fffff097          	auipc	ra,0xfffff
    80002064:	b84080e7          	jalr	-1148(ra) # 80000be4 <acquire>
      if(pause_time != 0){  
    80002068:	00092783          	lw	a5,0(s2)
    8000206c:	d7f9                	beqz	a5,8000203a <sjf+0x80>
         if(min_proc->pid != 1 && min_proc->pid != 2){
    8000206e:	030aa703          	lw	a4,48(s5)
    80002072:	377d                	addiw	a4,a4,-1
    80002074:	fcebfce3          	bgeu	s7,a4,8000204c <sjf+0x92>
          if(ticks >= pause_time){
    80002078:	000c2703          	lw	a4,0(s8)
    8000207c:	faf769e3          	bltu	a4,a5,8000202e <sjf+0x74>
            pause_time = 0;
    80002080:	00092023          	sw	zero,0(s2)
    80002084:	b7e1                	j	8000204c <sjf+0x92>
      acquire(&min_proc->lock);
    80002086:	84d6                	mv	s1,s5
    80002088:	8556                	mv	a0,s5
    8000208a:	fffff097          	auipc	ra,0xfffff
    8000208e:	b5a080e7          	jalr	-1190(ra) # 80000be4 <acquire>
        if(min_proc->state == RUNNABLE) {
    80002092:	018aa703          	lw	a4,24(s5)
    80002096:	478d                	li	a5,3
    80002098:	02f71663          	bne	a4,a5,800020c4 <sjf+0x10a>
          min_proc->state = RUNNING;
    8000209c:	4791                	li	a5,4
    8000209e:	00faac23          	sw	a5,24(s5)
          c->proc = min_proc;
    800020a2:	035cb823          	sd	s5,48(s9)
          min_proc->start_cpu_burst = ticks;
    800020a6:	000c6783          	lwu	a5,0(s8)
    800020aa:	16fabc23          	sd	a5,376(s5)
          swtch(&c->context, &p->context);
    800020ae:	0000e597          	auipc	a1,0xe
    800020b2:	1f258593          	addi	a1,a1,498 # 800102a0 <bcache+0x48>
    800020b6:	856a                	mv	a0,s10
    800020b8:	00000097          	auipc	ra,0x0
    800020bc:	778080e7          	jalr	1912(ra) # 80002830 <swtch>
          c->proc = 0;
    800020c0:	020cb823          	sd	zero,48(s9)
        release(&min_proc->lock);
    800020c4:	8526                	mv	a0,s1
    800020c6:	fffff097          	auipc	ra,0xfffff
    800020ca:	bd2080e7          	jalr	-1070(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020ce:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020d2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020d6:	10079073          	csrw	sstatus,a5
    int min = -1;
    800020da:	89da                	mv	s3,s6
    for(p = proc; p < &proc[NPROC]; p++) { 
    800020dc:	00008497          	auipc	s1,0x8
    800020e0:	16448493          	addi	s1,s1,356 # 8000a240 <proc>
         if(min_proc->pid != 1 && min_proc->pid != 2){
    800020e4:	4b85                	li	s7,1
    for(p = proc; p < &proc[NPROC]; p++) { 
    800020e6:	0000ea17          	auipc	s4,0xe
    800020ea:	15aa0a13          	addi	s4,s4,346 # 80010240 <tickslock>
    800020ee:	bf85                	j	8000205e <sjf+0xa4>

00000000800020f0 <scheduler>:
{
    800020f0:	1141                	addi	sp,sp,-16
    800020f2:	e406                	sd	ra,8(sp)
    800020f4:	e022                	sd	s0,0(sp)
    800020f6:	0800                	addi	s0,sp,16
    sjf();
    800020f8:	00000097          	auipc	ra,0x0
    800020fc:	ec2080e7          	jalr	-318(ra) # 80001fba <sjf>

0000000080002100 <sched>:
{
    80002100:	7179                	addi	sp,sp,-48
    80002102:	f406                	sd	ra,40(sp)
    80002104:	f022                	sd	s0,32(sp)
    80002106:	ec26                	sd	s1,24(sp)
    80002108:	e84a                	sd	s2,16(sp)
    8000210a:	e44e                	sd	s3,8(sp)
    8000210c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000210e:	00000097          	auipc	ra,0x0
    80002112:	8aa080e7          	jalr	-1878(ra) # 800019b8 <myproc>
    80002116:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002118:	fffff097          	auipc	ra,0xfffff
    8000211c:	a52080e7          	jalr	-1454(ra) # 80000b6a <holding>
    80002120:	c955                	beqz	a0,800021d4 <sched+0xd4>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002122:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002124:	2781                	sext.w	a5,a5
    80002126:	079e                	slli	a5,a5,0x7
    80002128:	00008717          	auipc	a4,0x8
    8000212c:	06870713          	addi	a4,a4,104 # 8000a190 <pid_lock>
    80002130:	97ba                	add	a5,a5,a4
    80002132:	0a87a703          	lw	a4,168(a5)
    80002136:	4785                	li	a5,1
    80002138:	0af71663          	bne	a4,a5,800021e4 <sched+0xe4>
  if(p->state == RUNNING)
    8000213c:	4c98                	lw	a4,24(s1)
    8000213e:	4791                	li	a5,4
    80002140:	0af70a63          	beq	a4,a5,800021f4 <sched+0xf4>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002144:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002148:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000214a:	efcd                	bnez	a5,80002204 <sched+0x104>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000214c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000214e:	00008917          	auipc	s2,0x8
    80002152:	04290913          	addi	s2,s2,66 # 8000a190 <pid_lock>
    80002156:	2781                	sext.w	a5,a5
    80002158:	079e                	slli	a5,a5,0x7
    8000215a:	97ca                	add	a5,a5,s2
    8000215c:	0ac7a983          	lw	s3,172(a5)
    80002160:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002162:	2781                	sext.w	a5,a5
    80002164:	079e                	slli	a5,a5,0x7
    80002166:	00008597          	auipc	a1,0x8
    8000216a:	06258593          	addi	a1,a1,98 # 8000a1c8 <cpus+0x8>
    8000216e:	95be                	add	a1,a1,a5
    80002170:	06048513          	addi	a0,s1,96
    80002174:	00000097          	auipc	ra,0x0
    80002178:	6bc080e7          	jalr	1724(ra) # 80002830 <swtch>
  p->last_ticks = ticks - p->start_cpu_burst;
    8000217c:	00007717          	auipc	a4,0x7
    80002180:	ebc76703          	lwu	a4,-324(a4) # 80009038 <ticks>
    80002184:	1784b683          	ld	a3,376(s1)
    80002188:	40d706b3          	sub	a3,a4,a3
    8000218c:	16d4b823          	sd	a3,368(s1)
  p->mean_ticks = ((10*rate)* p->mean_ticks + p->last_ticks*(rate))/10;
    80002190:	00006717          	auipc	a4,0x6
    80002194:	6c472703          	lw	a4,1732(a4) # 80008854 <rate>
    80002198:	0027179b          	slliw	a5,a4,0x2
    8000219c:	9fb9                	addw	a5,a5,a4
    8000219e:	0017979b          	slliw	a5,a5,0x1
    800021a2:	1684b603          	ld	a2,360(s1)
    800021a6:	02c787b3          	mul	a5,a5,a2
    800021aa:	02d70733          	mul	a4,a4,a3
    800021ae:	97ba                	add	a5,a5,a4
    800021b0:	4729                	li	a4,10
    800021b2:	02e7d7b3          	divu	a5,a5,a4
    800021b6:	16f4b423          	sd	a5,360(s1)
    800021ba:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800021bc:	2781                	sext.w	a5,a5
    800021be:	079e                	slli	a5,a5,0x7
    800021c0:	993e                	add	s2,s2,a5
    800021c2:	0b392623          	sw	s3,172(s2)
}
    800021c6:	70a2                	ld	ra,40(sp)
    800021c8:	7402                	ld	s0,32(sp)
    800021ca:	64e2                	ld	s1,24(sp)
    800021cc:	6942                	ld	s2,16(sp)
    800021ce:	69a2                	ld	s3,8(sp)
    800021d0:	6145                	addi	sp,sp,48
    800021d2:	8082                	ret
    panic("sched p->lock");
    800021d4:	00006517          	auipc	a0,0x6
    800021d8:	06c50513          	addi	a0,a0,108 # 80008240 <digits+0x200>
    800021dc:	ffffe097          	auipc	ra,0xffffe
    800021e0:	362080e7          	jalr	866(ra) # 8000053e <panic>
    panic("sched locks");
    800021e4:	00006517          	auipc	a0,0x6
    800021e8:	06c50513          	addi	a0,a0,108 # 80008250 <digits+0x210>
    800021ec:	ffffe097          	auipc	ra,0xffffe
    800021f0:	352080e7          	jalr	850(ra) # 8000053e <panic>
    panic("sched running");
    800021f4:	00006517          	auipc	a0,0x6
    800021f8:	06c50513          	addi	a0,a0,108 # 80008260 <digits+0x220>
    800021fc:	ffffe097          	auipc	ra,0xffffe
    80002200:	342080e7          	jalr	834(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002204:	00006517          	auipc	a0,0x6
    80002208:	06c50513          	addi	a0,a0,108 # 80008270 <digits+0x230>
    8000220c:	ffffe097          	auipc	ra,0xffffe
    80002210:	332080e7          	jalr	818(ra) # 8000053e <panic>

0000000080002214 <yield>:
{
    80002214:	1101                	addi	sp,sp,-32
    80002216:	ec06                	sd	ra,24(sp)
    80002218:	e822                	sd	s0,16(sp)
    8000221a:	e426                	sd	s1,8(sp)
    8000221c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000221e:	fffff097          	auipc	ra,0xfffff
    80002222:	79a080e7          	jalr	1946(ra) # 800019b8 <myproc>
    80002226:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002228:	fffff097          	auipc	ra,0xfffff
    8000222c:	9bc080e7          	jalr	-1604(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002230:	478d                	li	a5,3
    80002232:	cc9c                	sw	a5,24(s1)
  sched();
    80002234:	00000097          	auipc	ra,0x0
    80002238:	ecc080e7          	jalr	-308(ra) # 80002100 <sched>
  release(&p->lock);
    8000223c:	8526                	mv	a0,s1
    8000223e:	fffff097          	auipc	ra,0xfffff
    80002242:	a5a080e7          	jalr	-1446(ra) # 80000c98 <release>
}
    80002246:	60e2                	ld	ra,24(sp)
    80002248:	6442                	ld	s0,16(sp)
    8000224a:	64a2                	ld	s1,8(sp)
    8000224c:	6105                	addi	sp,sp,32
    8000224e:	8082                	ret

0000000080002250 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002250:	7179                	addi	sp,sp,-48
    80002252:	f406                	sd	ra,40(sp)
    80002254:	f022                	sd	s0,32(sp)
    80002256:	ec26                	sd	s1,24(sp)
    80002258:	e84a                	sd	s2,16(sp)
    8000225a:	e44e                	sd	s3,8(sp)
    8000225c:	1800                	addi	s0,sp,48
    8000225e:	89aa                	mv	s3,a0
    80002260:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002262:	fffff097          	auipc	ra,0xfffff
    80002266:	756080e7          	jalr	1878(ra) # 800019b8 <myproc>
    8000226a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000226c:	fffff097          	auipc	ra,0xfffff
    80002270:	978080e7          	jalr	-1672(ra) # 80000be4 <acquire>
  release(lk);
    80002274:	854a                	mv	a0,s2
    80002276:	fffff097          	auipc	ra,0xfffff
    8000227a:	a22080e7          	jalr	-1502(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    8000227e:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002282:	4789                	li	a5,2
    80002284:	cc9c                	sw	a5,24(s1)

  sched();
    80002286:	00000097          	auipc	ra,0x0
    8000228a:	e7a080e7          	jalr	-390(ra) # 80002100 <sched>

  // Tidy up.
  p->chan = 0;
    8000228e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002292:	8526                	mv	a0,s1
    80002294:	fffff097          	auipc	ra,0xfffff
    80002298:	a04080e7          	jalr	-1532(ra) # 80000c98 <release>
  acquire(lk);
    8000229c:	854a                	mv	a0,s2
    8000229e:	fffff097          	auipc	ra,0xfffff
    800022a2:	946080e7          	jalr	-1722(ra) # 80000be4 <acquire>
}
    800022a6:	70a2                	ld	ra,40(sp)
    800022a8:	7402                	ld	s0,32(sp)
    800022aa:	64e2                	ld	s1,24(sp)
    800022ac:	6942                	ld	s2,16(sp)
    800022ae:	69a2                	ld	s3,8(sp)
    800022b0:	6145                	addi	sp,sp,48
    800022b2:	8082                	ret

00000000800022b4 <wait>:
{
    800022b4:	715d                	addi	sp,sp,-80
    800022b6:	e486                	sd	ra,72(sp)
    800022b8:	e0a2                	sd	s0,64(sp)
    800022ba:	fc26                	sd	s1,56(sp)
    800022bc:	f84a                	sd	s2,48(sp)
    800022be:	f44e                	sd	s3,40(sp)
    800022c0:	f052                	sd	s4,32(sp)
    800022c2:	ec56                	sd	s5,24(sp)
    800022c4:	e85a                	sd	s6,16(sp)
    800022c6:	e45e                	sd	s7,8(sp)
    800022c8:	e062                	sd	s8,0(sp)
    800022ca:	0880                	addi	s0,sp,80
    800022cc:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022ce:	fffff097          	auipc	ra,0xfffff
    800022d2:	6ea080e7          	jalr	1770(ra) # 800019b8 <myproc>
    800022d6:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800022d8:	00008517          	auipc	a0,0x8
    800022dc:	ed050513          	addi	a0,a0,-304 # 8000a1a8 <wait_lock>
    800022e0:	fffff097          	auipc	ra,0xfffff
    800022e4:	904080e7          	jalr	-1788(ra) # 80000be4 <acquire>
    havekids = 0;
    800022e8:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022ea:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800022ec:	0000e997          	auipc	s3,0xe
    800022f0:	f5498993          	addi	s3,s3,-172 # 80010240 <tickslock>
        havekids = 1;
    800022f4:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022f6:	00008c17          	auipc	s8,0x8
    800022fa:	eb2c0c13          	addi	s8,s8,-334 # 8000a1a8 <wait_lock>
    havekids = 0;
    800022fe:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002300:	00008497          	auipc	s1,0x8
    80002304:	f4048493          	addi	s1,s1,-192 # 8000a240 <proc>
    80002308:	a0bd                	j	80002376 <wait+0xc2>
          pid = np->pid;
    8000230a:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000230e:	000b0e63          	beqz	s6,8000232a <wait+0x76>
    80002312:	4691                	li	a3,4
    80002314:	02c48613          	addi	a2,s1,44
    80002318:	85da                	mv	a1,s6
    8000231a:	05093503          	ld	a0,80(s2)
    8000231e:	fffff097          	auipc	ra,0xfffff
    80002322:	35c080e7          	jalr	860(ra) # 8000167a <copyout>
    80002326:	02054563          	bltz	a0,80002350 <wait+0x9c>
          freeproc(np);
    8000232a:	8526                	mv	a0,s1
    8000232c:	00000097          	auipc	ra,0x0
    80002330:	83e080e7          	jalr	-1986(ra) # 80001b6a <freeproc>
          release(&np->lock);
    80002334:	8526                	mv	a0,s1
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	962080e7          	jalr	-1694(ra) # 80000c98 <release>
          release(&wait_lock);
    8000233e:	00008517          	auipc	a0,0x8
    80002342:	e6a50513          	addi	a0,a0,-406 # 8000a1a8 <wait_lock>
    80002346:	fffff097          	auipc	ra,0xfffff
    8000234a:	952080e7          	jalr	-1710(ra) # 80000c98 <release>
          return pid;
    8000234e:	a09d                	j	800023b4 <wait+0x100>
            release(&np->lock);
    80002350:	8526                	mv	a0,s1
    80002352:	fffff097          	auipc	ra,0xfffff
    80002356:	946080e7          	jalr	-1722(ra) # 80000c98 <release>
            release(&wait_lock);
    8000235a:	00008517          	auipc	a0,0x8
    8000235e:	e4e50513          	addi	a0,a0,-434 # 8000a1a8 <wait_lock>
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	936080e7          	jalr	-1738(ra) # 80000c98 <release>
            return -1;
    8000236a:	59fd                	li	s3,-1
    8000236c:	a0a1                	j	800023b4 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000236e:	18048493          	addi	s1,s1,384
    80002372:	03348463          	beq	s1,s3,8000239a <wait+0xe6>
      if(np->parent == p){
    80002376:	7c9c                	ld	a5,56(s1)
    80002378:	ff279be3          	bne	a5,s2,8000236e <wait+0xba>
        acquire(&np->lock);
    8000237c:	8526                	mv	a0,s1
    8000237e:	fffff097          	auipc	ra,0xfffff
    80002382:	866080e7          	jalr	-1946(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002386:	4c9c                	lw	a5,24(s1)
    80002388:	f94781e3          	beq	a5,s4,8000230a <wait+0x56>
        release(&np->lock);
    8000238c:	8526                	mv	a0,s1
    8000238e:	fffff097          	auipc	ra,0xfffff
    80002392:	90a080e7          	jalr	-1782(ra) # 80000c98 <release>
        havekids = 1;
    80002396:	8756                	mv	a4,s5
    80002398:	bfd9                	j	8000236e <wait+0xba>
    if(!havekids || p->killed){
    8000239a:	c701                	beqz	a4,800023a2 <wait+0xee>
    8000239c:	02892783          	lw	a5,40(s2)
    800023a0:	c79d                	beqz	a5,800023ce <wait+0x11a>
      release(&wait_lock);
    800023a2:	00008517          	auipc	a0,0x8
    800023a6:	e0650513          	addi	a0,a0,-506 # 8000a1a8 <wait_lock>
    800023aa:	fffff097          	auipc	ra,0xfffff
    800023ae:	8ee080e7          	jalr	-1810(ra) # 80000c98 <release>
      return -1;
    800023b2:	59fd                	li	s3,-1
}
    800023b4:	854e                	mv	a0,s3
    800023b6:	60a6                	ld	ra,72(sp)
    800023b8:	6406                	ld	s0,64(sp)
    800023ba:	74e2                	ld	s1,56(sp)
    800023bc:	7942                	ld	s2,48(sp)
    800023be:	79a2                	ld	s3,40(sp)
    800023c0:	7a02                	ld	s4,32(sp)
    800023c2:	6ae2                	ld	s5,24(sp)
    800023c4:	6b42                	ld	s6,16(sp)
    800023c6:	6ba2                	ld	s7,8(sp)
    800023c8:	6c02                	ld	s8,0(sp)
    800023ca:	6161                	addi	sp,sp,80
    800023cc:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023ce:	85e2                	mv	a1,s8
    800023d0:	854a                	mv	a0,s2
    800023d2:	00000097          	auipc	ra,0x0
    800023d6:	e7e080e7          	jalr	-386(ra) # 80002250 <sleep>
    havekids = 0;
    800023da:	b715                	j	800022fe <wait+0x4a>

00000000800023dc <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800023dc:	7139                	addi	sp,sp,-64
    800023de:	fc06                	sd	ra,56(sp)
    800023e0:	f822                	sd	s0,48(sp)
    800023e2:	f426                	sd	s1,40(sp)
    800023e4:	f04a                	sd	s2,32(sp)
    800023e6:	ec4e                	sd	s3,24(sp)
    800023e8:	e852                	sd	s4,16(sp)
    800023ea:	e456                	sd	s5,8(sp)
    800023ec:	0080                	addi	s0,sp,64
    800023ee:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800023f0:	00008497          	auipc	s1,0x8
    800023f4:	e5048493          	addi	s1,s1,-432 # 8000a240 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800023f8:	4989                	li	s3,2
        p->state = RUNNABLE;
    800023fa:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800023fc:	0000e917          	auipc	s2,0xe
    80002400:	e4490913          	addi	s2,s2,-444 # 80010240 <tickslock>
    80002404:	a821                	j	8000241c <wakeup+0x40>
        p->state = RUNNABLE;
    80002406:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    8000240a:	8526                	mv	a0,s1
    8000240c:	fffff097          	auipc	ra,0xfffff
    80002410:	88c080e7          	jalr	-1908(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002414:	18048493          	addi	s1,s1,384
    80002418:	03248463          	beq	s1,s2,80002440 <wakeup+0x64>
    if(p != myproc()){
    8000241c:	fffff097          	auipc	ra,0xfffff
    80002420:	59c080e7          	jalr	1436(ra) # 800019b8 <myproc>
    80002424:	fea488e3          	beq	s1,a0,80002414 <wakeup+0x38>
      acquire(&p->lock);
    80002428:	8526                	mv	a0,s1
    8000242a:	ffffe097          	auipc	ra,0xffffe
    8000242e:	7ba080e7          	jalr	1978(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002432:	4c9c                	lw	a5,24(s1)
    80002434:	fd379be3          	bne	a5,s3,8000240a <wakeup+0x2e>
    80002438:	709c                	ld	a5,32(s1)
    8000243a:	fd4798e3          	bne	a5,s4,8000240a <wakeup+0x2e>
    8000243e:	b7e1                	j	80002406 <wakeup+0x2a>
    }
  }
}
    80002440:	70e2                	ld	ra,56(sp)
    80002442:	7442                	ld	s0,48(sp)
    80002444:	74a2                	ld	s1,40(sp)
    80002446:	7902                	ld	s2,32(sp)
    80002448:	69e2                	ld	s3,24(sp)
    8000244a:	6a42                	ld	s4,16(sp)
    8000244c:	6aa2                	ld	s5,8(sp)
    8000244e:	6121                	addi	sp,sp,64
    80002450:	8082                	ret

0000000080002452 <reparent>:
{
    80002452:	7179                	addi	sp,sp,-48
    80002454:	f406                	sd	ra,40(sp)
    80002456:	f022                	sd	s0,32(sp)
    80002458:	ec26                	sd	s1,24(sp)
    8000245a:	e84a                	sd	s2,16(sp)
    8000245c:	e44e                	sd	s3,8(sp)
    8000245e:	e052                	sd	s4,0(sp)
    80002460:	1800                	addi	s0,sp,48
    80002462:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002464:	00008497          	auipc	s1,0x8
    80002468:	ddc48493          	addi	s1,s1,-548 # 8000a240 <proc>
      pp->parent = initproc;
    8000246c:	00007a17          	auipc	s4,0x7
    80002470:	bc4a0a13          	addi	s4,s4,-1084 # 80009030 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002474:	0000e997          	auipc	s3,0xe
    80002478:	dcc98993          	addi	s3,s3,-564 # 80010240 <tickslock>
    8000247c:	a029                	j	80002486 <reparent+0x34>
    8000247e:	18048493          	addi	s1,s1,384
    80002482:	01348d63          	beq	s1,s3,8000249c <reparent+0x4a>
    if(pp->parent == p){
    80002486:	7c9c                	ld	a5,56(s1)
    80002488:	ff279be3          	bne	a5,s2,8000247e <reparent+0x2c>
      pp->parent = initproc;
    8000248c:	000a3503          	ld	a0,0(s4)
    80002490:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002492:	00000097          	auipc	ra,0x0
    80002496:	f4a080e7          	jalr	-182(ra) # 800023dc <wakeup>
    8000249a:	b7d5                	j	8000247e <reparent+0x2c>
}
    8000249c:	70a2                	ld	ra,40(sp)
    8000249e:	7402                	ld	s0,32(sp)
    800024a0:	64e2                	ld	s1,24(sp)
    800024a2:	6942                	ld	s2,16(sp)
    800024a4:	69a2                	ld	s3,8(sp)
    800024a6:	6a02                	ld	s4,0(sp)
    800024a8:	6145                	addi	sp,sp,48
    800024aa:	8082                	ret

00000000800024ac <exit>:
{
    800024ac:	7179                	addi	sp,sp,-48
    800024ae:	f406                	sd	ra,40(sp)
    800024b0:	f022                	sd	s0,32(sp)
    800024b2:	ec26                	sd	s1,24(sp)
    800024b4:	e84a                	sd	s2,16(sp)
    800024b6:	e44e                	sd	s3,8(sp)
    800024b8:	e052                	sd	s4,0(sp)
    800024ba:	1800                	addi	s0,sp,48
    800024bc:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800024be:	fffff097          	auipc	ra,0xfffff
    800024c2:	4fa080e7          	jalr	1274(ra) # 800019b8 <myproc>
    800024c6:	89aa                	mv	s3,a0
  if(p == initproc)
    800024c8:	00007797          	auipc	a5,0x7
    800024cc:	b687b783          	ld	a5,-1176(a5) # 80009030 <initproc>
    800024d0:	0d050493          	addi	s1,a0,208
    800024d4:	15050913          	addi	s2,a0,336
    800024d8:	02a79363          	bne	a5,a0,800024fe <exit+0x52>
    panic("init exiting");
    800024dc:	00006517          	auipc	a0,0x6
    800024e0:	dac50513          	addi	a0,a0,-596 # 80008288 <digits+0x248>
    800024e4:	ffffe097          	auipc	ra,0xffffe
    800024e8:	05a080e7          	jalr	90(ra) # 8000053e <panic>
      fileclose(f);
    800024ec:	00002097          	auipc	ra,0x2
    800024f0:	290080e7          	jalr	656(ra) # 8000477c <fileclose>
      p->ofile[fd] = 0;
    800024f4:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800024f8:	04a1                	addi	s1,s1,8
    800024fa:	01248563          	beq	s1,s2,80002504 <exit+0x58>
    if(p->ofile[fd]){
    800024fe:	6088                	ld	a0,0(s1)
    80002500:	f575                	bnez	a0,800024ec <exit+0x40>
    80002502:	bfdd                	j	800024f8 <exit+0x4c>
  begin_op();
    80002504:	00002097          	auipc	ra,0x2
    80002508:	dac080e7          	jalr	-596(ra) # 800042b0 <begin_op>
  iput(p->cwd);
    8000250c:	1509b503          	ld	a0,336(s3)
    80002510:	00001097          	auipc	ra,0x1
    80002514:	588080e7          	jalr	1416(ra) # 80003a98 <iput>
  end_op();
    80002518:	00002097          	auipc	ra,0x2
    8000251c:	e18080e7          	jalr	-488(ra) # 80004330 <end_op>
  p->cwd = 0;
    80002520:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002524:	00008497          	auipc	s1,0x8
    80002528:	c8448493          	addi	s1,s1,-892 # 8000a1a8 <wait_lock>
    8000252c:	8526                	mv	a0,s1
    8000252e:	ffffe097          	auipc	ra,0xffffe
    80002532:	6b6080e7          	jalr	1718(ra) # 80000be4 <acquire>
  reparent(p);
    80002536:	854e                	mv	a0,s3
    80002538:	00000097          	auipc	ra,0x0
    8000253c:	f1a080e7          	jalr	-230(ra) # 80002452 <reparent>
  wakeup(p->parent);
    80002540:	0389b503          	ld	a0,56(s3)
    80002544:	00000097          	auipc	ra,0x0
    80002548:	e98080e7          	jalr	-360(ra) # 800023dc <wakeup>
  acquire(&p->lock);
    8000254c:	854e                	mv	a0,s3
    8000254e:	ffffe097          	auipc	ra,0xffffe
    80002552:	696080e7          	jalr	1686(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002556:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000255a:	4795                	li	a5,5
    8000255c:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002560:	8526                	mv	a0,s1
    80002562:	ffffe097          	auipc	ra,0xffffe
    80002566:	736080e7          	jalr	1846(ra) # 80000c98 <release>
  sched();
    8000256a:	00000097          	auipc	ra,0x0
    8000256e:	b96080e7          	jalr	-1130(ra) # 80002100 <sched>
  panic("zombie exit");
    80002572:	00006517          	auipc	a0,0x6
    80002576:	d2650513          	addi	a0,a0,-730 # 80008298 <digits+0x258>
    8000257a:	ffffe097          	auipc	ra,0xffffe
    8000257e:	fc4080e7          	jalr	-60(ra) # 8000053e <panic>

0000000080002582 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002582:	7179                	addi	sp,sp,-48
    80002584:	f406                	sd	ra,40(sp)
    80002586:	f022                	sd	s0,32(sp)
    80002588:	ec26                	sd	s1,24(sp)
    8000258a:	e84a                	sd	s2,16(sp)
    8000258c:	e44e                	sd	s3,8(sp)
    8000258e:	1800                	addi	s0,sp,48
    80002590:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002592:	00008497          	auipc	s1,0x8
    80002596:	cae48493          	addi	s1,s1,-850 # 8000a240 <proc>
    8000259a:	0000e997          	auipc	s3,0xe
    8000259e:	ca698993          	addi	s3,s3,-858 # 80010240 <tickslock>
    acquire(&p->lock);
    800025a2:	8526                	mv	a0,s1
    800025a4:	ffffe097          	auipc	ra,0xffffe
    800025a8:	640080e7          	jalr	1600(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800025ac:	589c                	lw	a5,48(s1)
    800025ae:	01278d63          	beq	a5,s2,800025c8 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800025b2:	8526                	mv	a0,s1
    800025b4:	ffffe097          	auipc	ra,0xffffe
    800025b8:	6e4080e7          	jalr	1764(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800025bc:	18048493          	addi	s1,s1,384
    800025c0:	ff3491e3          	bne	s1,s3,800025a2 <kill+0x20>
  }
  return -1;
    800025c4:	557d                	li	a0,-1
    800025c6:	a829                	j	800025e0 <kill+0x5e>
      p->killed = 1;
    800025c8:	4785                	li	a5,1
    800025ca:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800025cc:	4c98                	lw	a4,24(s1)
    800025ce:	4789                	li	a5,2
    800025d0:	00f70f63          	beq	a4,a5,800025ee <kill+0x6c>
      release(&p->lock);
    800025d4:	8526                	mv	a0,s1
    800025d6:	ffffe097          	auipc	ra,0xffffe
    800025da:	6c2080e7          	jalr	1730(ra) # 80000c98 <release>
      return 0;
    800025de:	4501                	li	a0,0
}
    800025e0:	70a2                	ld	ra,40(sp)
    800025e2:	7402                	ld	s0,32(sp)
    800025e4:	64e2                	ld	s1,24(sp)
    800025e6:	6942                	ld	s2,16(sp)
    800025e8:	69a2                	ld	s3,8(sp)
    800025ea:	6145                	addi	sp,sp,48
    800025ec:	8082                	ret
        p->state = RUNNABLE;
    800025ee:	478d                	li	a5,3
    800025f0:	cc9c                	sw	a5,24(s1)
    800025f2:	b7cd                	j	800025d4 <kill+0x52>

00000000800025f4 <kill_system>:

int
kill_system()
{
    800025f4:	715d                	addi	sp,sp,-80
    800025f6:	e486                	sd	ra,72(sp)
    800025f8:	e0a2                	sd	s0,64(sp)
    800025fa:	fc26                	sd	s1,56(sp)
    800025fc:	f84a                	sd	s2,48(sp)
    800025fe:	f44e                	sd	s3,40(sp)
    80002600:	f052                	sd	s4,32(sp)
    80002602:	ec56                	sd	s5,24(sp)
    80002604:	e85a                	sd	s6,16(sp)
    80002606:	e45e                	sd	s7,8(sp)
    80002608:	e062                	sd	s8,0(sp)
    8000260a:	0880                	addi	s0,sp,80
  struct proc *myp = myproc();
    8000260c:	fffff097          	auipc	ra,0xfffff
    80002610:	3ac080e7          	jalr	940(ra) # 800019b8 <myproc>
    80002614:	8c2a                	mv	s8,a0
  int mypid = myp->pid;
    80002616:	03052983          	lw	s3,48(a0)
  acquire(&myp->lock);
    8000261a:	ffffe097          	auipc	ra,0xffffe
    8000261e:	5ca080e7          	jalr	1482(ra) # 80000be4 <acquire>
  struct proc *p;

  for(p = proc;p < &proc[NPROC]; p++){
    80002622:	00008497          	auipc	s1,0x8
    80002626:	c1e48493          	addi	s1,s1,-994 # 8000a240 <proc>
    if(p->pid != mypid){
      acquire(&p->lock);
      if(p->pid != 1 && p->pid != 2){
    8000262a:	4a05                	li	s4,1
        p->killed = 1;
    8000262c:	4b05                	li	s6,1
        if(p->state == SLEEPING){
    8000262e:	4a89                	li	s5,2
          // Wake process from sleep().
          p->state = RUNNABLE;
    80002630:	4b8d                	li	s7,3
  for(p = proc;p < &proc[NPROC]; p++){
    80002632:	0000e917          	auipc	s2,0xe
    80002636:	c0e90913          	addi	s2,s2,-1010 # 80010240 <tickslock>
    8000263a:	a811                	j	8000264e <kill_system+0x5a>
        }
      }
      release(&p->lock);
    8000263c:	8526                	mv	a0,s1
    8000263e:	ffffe097          	auipc	ra,0xffffe
    80002642:	65a080e7          	jalr	1626(ra) # 80000c98 <release>
  for(p = proc;p < &proc[NPROC]; p++){
    80002646:	18048493          	addi	s1,s1,384
    8000264a:	03248663          	beq	s1,s2,80002676 <kill_system+0x82>
    if(p->pid != mypid){
    8000264e:	589c                	lw	a5,48(s1)
    80002650:	ff378be3          	beq	a5,s3,80002646 <kill_system+0x52>
      acquire(&p->lock);
    80002654:	8526                	mv	a0,s1
    80002656:	ffffe097          	auipc	ra,0xffffe
    8000265a:	58e080e7          	jalr	1422(ra) # 80000be4 <acquire>
      if(p->pid != 1 && p->pid != 2){
    8000265e:	589c                	lw	a5,48(s1)
    80002660:	37fd                	addiw	a5,a5,-1
    80002662:	fcfa7de3          	bgeu	s4,a5,8000263c <kill_system+0x48>
        p->killed = 1;
    80002666:	0364a423          	sw	s6,40(s1)
        if(p->state == SLEEPING){
    8000266a:	4c9c                	lw	a5,24(s1)
    8000266c:	fd5798e3          	bne	a5,s5,8000263c <kill_system+0x48>
          p->state = RUNNABLE;
    80002670:	0174ac23          	sw	s7,24(s1)
    80002674:	b7e1                	j	8000263c <kill_system+0x48>
    }
  }

  myp->killed = 1;
    80002676:	4785                	li	a5,1
    80002678:	02fc2423          	sw	a5,40(s8)
  release(&myp->lock);
    8000267c:	8562                	mv	a0,s8
    8000267e:	ffffe097          	auipc	ra,0xffffe
    80002682:	61a080e7          	jalr	1562(ra) # 80000c98 <release>
  return 0;
}
    80002686:	4501                	li	a0,0
    80002688:	60a6                	ld	ra,72(sp)
    8000268a:	6406                	ld	s0,64(sp)
    8000268c:	74e2                	ld	s1,56(sp)
    8000268e:	7942                	ld	s2,48(sp)
    80002690:	79a2                	ld	s3,40(sp)
    80002692:	7a02                	ld	s4,32(sp)
    80002694:	6ae2                	ld	s5,24(sp)
    80002696:	6b42                	ld	s6,16(sp)
    80002698:	6ba2                	ld	s7,8(sp)
    8000269a:	6c02                	ld	s8,0(sp)
    8000269c:	6161                	addi	sp,sp,80
    8000269e:	8082                	ret

00000000800026a0 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800026a0:	7179                	addi	sp,sp,-48
    800026a2:	f406                	sd	ra,40(sp)
    800026a4:	f022                	sd	s0,32(sp)
    800026a6:	ec26                	sd	s1,24(sp)
    800026a8:	e84a                	sd	s2,16(sp)
    800026aa:	e44e                	sd	s3,8(sp)
    800026ac:	e052                	sd	s4,0(sp)
    800026ae:	1800                	addi	s0,sp,48
    800026b0:	84aa                	mv	s1,a0
    800026b2:	892e                	mv	s2,a1
    800026b4:	89b2                	mv	s3,a2
    800026b6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026b8:	fffff097          	auipc	ra,0xfffff
    800026bc:	300080e7          	jalr	768(ra) # 800019b8 <myproc>
  if(user_dst){
    800026c0:	c08d                	beqz	s1,800026e2 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800026c2:	86d2                	mv	a3,s4
    800026c4:	864e                	mv	a2,s3
    800026c6:	85ca                	mv	a1,s2
    800026c8:	6928                	ld	a0,80(a0)
    800026ca:	fffff097          	auipc	ra,0xfffff
    800026ce:	fb0080e7          	jalr	-80(ra) # 8000167a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800026d2:	70a2                	ld	ra,40(sp)
    800026d4:	7402                	ld	s0,32(sp)
    800026d6:	64e2                	ld	s1,24(sp)
    800026d8:	6942                	ld	s2,16(sp)
    800026da:	69a2                	ld	s3,8(sp)
    800026dc:	6a02                	ld	s4,0(sp)
    800026de:	6145                	addi	sp,sp,48
    800026e0:	8082                	ret
    memmove((char *)dst, src, len);
    800026e2:	000a061b          	sext.w	a2,s4
    800026e6:	85ce                	mv	a1,s3
    800026e8:	854a                	mv	a0,s2
    800026ea:	ffffe097          	auipc	ra,0xffffe
    800026ee:	656080e7          	jalr	1622(ra) # 80000d40 <memmove>
    return 0;
    800026f2:	8526                	mv	a0,s1
    800026f4:	bff9                	j	800026d2 <either_copyout+0x32>

00000000800026f6 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026f6:	7179                	addi	sp,sp,-48
    800026f8:	f406                	sd	ra,40(sp)
    800026fa:	f022                	sd	s0,32(sp)
    800026fc:	ec26                	sd	s1,24(sp)
    800026fe:	e84a                	sd	s2,16(sp)
    80002700:	e44e                	sd	s3,8(sp)
    80002702:	e052                	sd	s4,0(sp)
    80002704:	1800                	addi	s0,sp,48
    80002706:	892a                	mv	s2,a0
    80002708:	84ae                	mv	s1,a1
    8000270a:	89b2                	mv	s3,a2
    8000270c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000270e:	fffff097          	auipc	ra,0xfffff
    80002712:	2aa080e7          	jalr	682(ra) # 800019b8 <myproc>
  if(user_src){
    80002716:	c08d                	beqz	s1,80002738 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002718:	86d2                	mv	a3,s4
    8000271a:	864e                	mv	a2,s3
    8000271c:	85ca                	mv	a1,s2
    8000271e:	6928                	ld	a0,80(a0)
    80002720:	fffff097          	auipc	ra,0xfffff
    80002724:	fe6080e7          	jalr	-26(ra) # 80001706 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002728:	70a2                	ld	ra,40(sp)
    8000272a:	7402                	ld	s0,32(sp)
    8000272c:	64e2                	ld	s1,24(sp)
    8000272e:	6942                	ld	s2,16(sp)
    80002730:	69a2                	ld	s3,8(sp)
    80002732:	6a02                	ld	s4,0(sp)
    80002734:	6145                	addi	sp,sp,48
    80002736:	8082                	ret
    memmove(dst, (char*)src, len);
    80002738:	000a061b          	sext.w	a2,s4
    8000273c:	85ce                	mv	a1,s3
    8000273e:	854a                	mv	a0,s2
    80002740:	ffffe097          	auipc	ra,0xffffe
    80002744:	600080e7          	jalr	1536(ra) # 80000d40 <memmove>
    return 0;
    80002748:	8526                	mv	a0,s1
    8000274a:	bff9                	j	80002728 <either_copyin+0x32>

000000008000274c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000274c:	715d                	addi	sp,sp,-80
    8000274e:	e486                	sd	ra,72(sp)
    80002750:	e0a2                	sd	s0,64(sp)
    80002752:	fc26                	sd	s1,56(sp)
    80002754:	f84a                	sd	s2,48(sp)
    80002756:	f44e                	sd	s3,40(sp)
    80002758:	f052                	sd	s4,32(sp)
    8000275a:	ec56                	sd	s5,24(sp)
    8000275c:	e85a                	sd	s6,16(sp)
    8000275e:	e45e                	sd	s7,8(sp)
    80002760:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002762:	00006517          	auipc	a0,0x6
    80002766:	96650513          	addi	a0,a0,-1690 # 800080c8 <digits+0x88>
    8000276a:	ffffe097          	auipc	ra,0xffffe
    8000276e:	e1e080e7          	jalr	-482(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002772:	00008497          	auipc	s1,0x8
    80002776:	c2648493          	addi	s1,s1,-986 # 8000a398 <proc+0x158>
    8000277a:	0000e917          	auipc	s2,0xe
    8000277e:	c1e90913          	addi	s2,s2,-994 # 80010398 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002782:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002784:	00006997          	auipc	s3,0x6
    80002788:	b2498993          	addi	s3,s3,-1244 # 800082a8 <digits+0x268>
    printf("%d %s %s", p->pid, state, p->name);
    8000278c:	00006a97          	auipc	s5,0x6
    80002790:	b24a8a93          	addi	s5,s5,-1244 # 800082b0 <digits+0x270>
    printf("\n");
    80002794:	00006a17          	auipc	s4,0x6
    80002798:	934a0a13          	addi	s4,s4,-1740 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000279c:	00006b97          	auipc	s7,0x6
    800027a0:	b4cb8b93          	addi	s7,s7,-1204 # 800082e8 <states.1747>
    800027a4:	a00d                	j	800027c6 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800027a6:	ed86a583          	lw	a1,-296(a3)
    800027aa:	8556                	mv	a0,s5
    800027ac:	ffffe097          	auipc	ra,0xffffe
    800027b0:	ddc080e7          	jalr	-548(ra) # 80000588 <printf>
    printf("\n");
    800027b4:	8552                	mv	a0,s4
    800027b6:	ffffe097          	auipc	ra,0xffffe
    800027ba:	dd2080e7          	jalr	-558(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800027be:	18048493          	addi	s1,s1,384
    800027c2:	03248163          	beq	s1,s2,800027e4 <procdump+0x98>
    if(p->state == UNUSED)
    800027c6:	86a6                	mv	a3,s1
    800027c8:	ec04a783          	lw	a5,-320(s1)
    800027cc:	dbed                	beqz	a5,800027be <procdump+0x72>
      state = "???";
    800027ce:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027d0:	fcfb6be3          	bltu	s6,a5,800027a6 <procdump+0x5a>
    800027d4:	1782                	slli	a5,a5,0x20
    800027d6:	9381                	srli	a5,a5,0x20
    800027d8:	078e                	slli	a5,a5,0x3
    800027da:	97de                	add	a5,a5,s7
    800027dc:	6390                	ld	a2,0(a5)
    800027de:	f661                	bnez	a2,800027a6 <procdump+0x5a>
      state = "???";
    800027e0:	864e                	mv	a2,s3
    800027e2:	b7d1                	j	800027a6 <procdump+0x5a>
  }
}
    800027e4:	60a6                	ld	ra,72(sp)
    800027e6:	6406                	ld	s0,64(sp)
    800027e8:	74e2                	ld	s1,56(sp)
    800027ea:	7942                	ld	s2,48(sp)
    800027ec:	79a2                	ld	s3,40(sp)
    800027ee:	7a02                	ld	s4,32(sp)
    800027f0:	6ae2                	ld	s5,24(sp)
    800027f2:	6b42                	ld	s6,16(sp)
    800027f4:	6ba2                	ld	s7,8(sp)
    800027f6:	6161                	addi	sp,sp,80
    800027f8:	8082                	ret

00000000800027fa <pause_system>:

int
pause_system(int seconds)
{
    800027fa:	1141                	addi	sp,sp,-16
    800027fc:	e406                	sd	ra,8(sp)
    800027fe:	e022                	sd	s0,0(sp)
    80002800:	0800                	addi	s0,sp,16
  pause_time = ticks + seconds*10;  
    80002802:	0025179b          	slliw	a5,a0,0x2
    80002806:	9fa9                	addw	a5,a5,a0
    80002808:	0017979b          	slliw	a5,a5,0x1
    8000280c:	00007517          	auipc	a0,0x7
    80002810:	82c52503          	lw	a0,-2004(a0) # 80009038 <ticks>
    80002814:	9fa9                	addw	a5,a5,a0
    80002816:	00007717          	auipc	a4,0x7
    8000281a:	80f72923          	sw	a5,-2030(a4) # 80009028 <pause_time>
  yield();
    8000281e:	00000097          	auipc	ra,0x0
    80002822:	9f6080e7          	jalr	-1546(ra) # 80002214 <yield>
  return 0;
}
    80002826:	4501                	li	a0,0
    80002828:	60a2                	ld	ra,8(sp)
    8000282a:	6402                	ld	s0,0(sp)
    8000282c:	0141                	addi	sp,sp,16
    8000282e:	8082                	ret

0000000080002830 <swtch>:
    80002830:	00153023          	sd	ra,0(a0)
    80002834:	00253423          	sd	sp,8(a0)
    80002838:	e900                	sd	s0,16(a0)
    8000283a:	ed04                	sd	s1,24(a0)
    8000283c:	03253023          	sd	s2,32(a0)
    80002840:	03353423          	sd	s3,40(a0)
    80002844:	03453823          	sd	s4,48(a0)
    80002848:	03553c23          	sd	s5,56(a0)
    8000284c:	05653023          	sd	s6,64(a0)
    80002850:	05753423          	sd	s7,72(a0)
    80002854:	05853823          	sd	s8,80(a0)
    80002858:	05953c23          	sd	s9,88(a0)
    8000285c:	07a53023          	sd	s10,96(a0)
    80002860:	07b53423          	sd	s11,104(a0)
    80002864:	0005b083          	ld	ra,0(a1)
    80002868:	0085b103          	ld	sp,8(a1)
    8000286c:	6980                	ld	s0,16(a1)
    8000286e:	6d84                	ld	s1,24(a1)
    80002870:	0205b903          	ld	s2,32(a1)
    80002874:	0285b983          	ld	s3,40(a1)
    80002878:	0305ba03          	ld	s4,48(a1)
    8000287c:	0385ba83          	ld	s5,56(a1)
    80002880:	0405bb03          	ld	s6,64(a1)
    80002884:	0485bb83          	ld	s7,72(a1)
    80002888:	0505bc03          	ld	s8,80(a1)
    8000288c:	0585bc83          	ld	s9,88(a1)
    80002890:	0605bd03          	ld	s10,96(a1)
    80002894:	0685bd83          	ld	s11,104(a1)
    80002898:	8082                	ret

000000008000289a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000289a:	1141                	addi	sp,sp,-16
    8000289c:	e406                	sd	ra,8(sp)
    8000289e:	e022                	sd	s0,0(sp)
    800028a0:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800028a2:	00006597          	auipc	a1,0x6
    800028a6:	a7658593          	addi	a1,a1,-1418 # 80008318 <states.1747+0x30>
    800028aa:	0000e517          	auipc	a0,0xe
    800028ae:	99650513          	addi	a0,a0,-1642 # 80010240 <tickslock>
    800028b2:	ffffe097          	auipc	ra,0xffffe
    800028b6:	2a2080e7          	jalr	674(ra) # 80000b54 <initlock>
}
    800028ba:	60a2                	ld	ra,8(sp)
    800028bc:	6402                	ld	s0,0(sp)
    800028be:	0141                	addi	sp,sp,16
    800028c0:	8082                	ret

00000000800028c2 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800028c2:	1141                	addi	sp,sp,-16
    800028c4:	e422                	sd	s0,8(sp)
    800028c6:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028c8:	00003797          	auipc	a5,0x3
    800028cc:	4c878793          	addi	a5,a5,1224 # 80005d90 <kernelvec>
    800028d0:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800028d4:	6422                	ld	s0,8(sp)
    800028d6:	0141                	addi	sp,sp,16
    800028d8:	8082                	ret

00000000800028da <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800028da:	1141                	addi	sp,sp,-16
    800028dc:	e406                	sd	ra,8(sp)
    800028de:	e022                	sd	s0,0(sp)
    800028e0:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800028e2:	fffff097          	auipc	ra,0xfffff
    800028e6:	0d6080e7          	jalr	214(ra) # 800019b8 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ea:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800028ee:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028f0:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800028f4:	00004617          	auipc	a2,0x4
    800028f8:	70c60613          	addi	a2,a2,1804 # 80007000 <_trampoline>
    800028fc:	00004697          	auipc	a3,0x4
    80002900:	70468693          	addi	a3,a3,1796 # 80007000 <_trampoline>
    80002904:	8e91                	sub	a3,a3,a2
    80002906:	040007b7          	lui	a5,0x4000
    8000290a:	17fd                	addi	a5,a5,-1
    8000290c:	07b2                	slli	a5,a5,0xc
    8000290e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002910:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002914:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002916:	180026f3          	csrr	a3,satp
    8000291a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000291c:	6d38                	ld	a4,88(a0)
    8000291e:	6134                	ld	a3,64(a0)
    80002920:	6585                	lui	a1,0x1
    80002922:	96ae                	add	a3,a3,a1
    80002924:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002926:	6d38                	ld	a4,88(a0)
    80002928:	00000697          	auipc	a3,0x0
    8000292c:	13868693          	addi	a3,a3,312 # 80002a60 <usertrap>
    80002930:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002932:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002934:	8692                	mv	a3,tp
    80002936:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002938:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000293c:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002940:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002944:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002948:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000294a:	6f18                	ld	a4,24(a4)
    8000294c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002950:	692c                	ld	a1,80(a0)
    80002952:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002954:	00004717          	auipc	a4,0x4
    80002958:	73c70713          	addi	a4,a4,1852 # 80007090 <userret>
    8000295c:	8f11                	sub	a4,a4,a2
    8000295e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002960:	577d                	li	a4,-1
    80002962:	177e                	slli	a4,a4,0x3f
    80002964:	8dd9                	or	a1,a1,a4
    80002966:	02000537          	lui	a0,0x2000
    8000296a:	157d                	addi	a0,a0,-1
    8000296c:	0536                	slli	a0,a0,0xd
    8000296e:	9782                	jalr	a5
}
    80002970:	60a2                	ld	ra,8(sp)
    80002972:	6402                	ld	s0,0(sp)
    80002974:	0141                	addi	sp,sp,16
    80002976:	8082                	ret

0000000080002978 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002978:	1101                	addi	sp,sp,-32
    8000297a:	ec06                	sd	ra,24(sp)
    8000297c:	e822                	sd	s0,16(sp)
    8000297e:	e426                	sd	s1,8(sp)
    80002980:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002982:	0000e497          	auipc	s1,0xe
    80002986:	8be48493          	addi	s1,s1,-1858 # 80010240 <tickslock>
    8000298a:	8526                	mv	a0,s1
    8000298c:	ffffe097          	auipc	ra,0xffffe
    80002990:	258080e7          	jalr	600(ra) # 80000be4 <acquire>
  ticks++;
    80002994:	00006517          	auipc	a0,0x6
    80002998:	6a450513          	addi	a0,a0,1700 # 80009038 <ticks>
    8000299c:	411c                	lw	a5,0(a0)
    8000299e:	2785                	addiw	a5,a5,1
    800029a0:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800029a2:	00000097          	auipc	ra,0x0
    800029a6:	a3a080e7          	jalr	-1478(ra) # 800023dc <wakeup>
  release(&tickslock);
    800029aa:	8526                	mv	a0,s1
    800029ac:	ffffe097          	auipc	ra,0xffffe
    800029b0:	2ec080e7          	jalr	748(ra) # 80000c98 <release>
}
    800029b4:	60e2                	ld	ra,24(sp)
    800029b6:	6442                	ld	s0,16(sp)
    800029b8:	64a2                	ld	s1,8(sp)
    800029ba:	6105                	addi	sp,sp,32
    800029bc:	8082                	ret

00000000800029be <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800029be:	1101                	addi	sp,sp,-32
    800029c0:	ec06                	sd	ra,24(sp)
    800029c2:	e822                	sd	s0,16(sp)
    800029c4:	e426                	sd	s1,8(sp)
    800029c6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029c8:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800029cc:	00074d63          	bltz	a4,800029e6 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800029d0:	57fd                	li	a5,-1
    800029d2:	17fe                	slli	a5,a5,0x3f
    800029d4:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800029d6:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800029d8:	06f70363          	beq	a4,a5,80002a3e <devintr+0x80>
  }
}
    800029dc:	60e2                	ld	ra,24(sp)
    800029de:	6442                	ld	s0,16(sp)
    800029e0:	64a2                	ld	s1,8(sp)
    800029e2:	6105                	addi	sp,sp,32
    800029e4:	8082                	ret
     (scause & 0xff) == 9){
    800029e6:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800029ea:	46a5                	li	a3,9
    800029ec:	fed792e3          	bne	a5,a3,800029d0 <devintr+0x12>
    int irq = plic_claim();
    800029f0:	00003097          	auipc	ra,0x3
    800029f4:	4a8080e7          	jalr	1192(ra) # 80005e98 <plic_claim>
    800029f8:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800029fa:	47a9                	li	a5,10
    800029fc:	02f50763          	beq	a0,a5,80002a2a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a00:	4785                	li	a5,1
    80002a02:	02f50963          	beq	a0,a5,80002a34 <devintr+0x76>
    return 1;
    80002a06:	4505                	li	a0,1
    } else if(irq){
    80002a08:	d8f1                	beqz	s1,800029dc <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a0a:	85a6                	mv	a1,s1
    80002a0c:	00006517          	auipc	a0,0x6
    80002a10:	91450513          	addi	a0,a0,-1772 # 80008320 <states.1747+0x38>
    80002a14:	ffffe097          	auipc	ra,0xffffe
    80002a18:	b74080e7          	jalr	-1164(ra) # 80000588 <printf>
      plic_complete(irq);
    80002a1c:	8526                	mv	a0,s1
    80002a1e:	00003097          	auipc	ra,0x3
    80002a22:	49e080e7          	jalr	1182(ra) # 80005ebc <plic_complete>
    return 1;
    80002a26:	4505                	li	a0,1
    80002a28:	bf55                	j	800029dc <devintr+0x1e>
      uartintr();
    80002a2a:	ffffe097          	auipc	ra,0xffffe
    80002a2e:	f7e080e7          	jalr	-130(ra) # 800009a8 <uartintr>
    80002a32:	b7ed                	j	80002a1c <devintr+0x5e>
      virtio_disk_intr();
    80002a34:	00004097          	auipc	ra,0x4
    80002a38:	968080e7          	jalr	-1688(ra) # 8000639c <virtio_disk_intr>
    80002a3c:	b7c5                	j	80002a1c <devintr+0x5e>
    if(cpuid() == 0){
    80002a3e:	fffff097          	auipc	ra,0xfffff
    80002a42:	f4e080e7          	jalr	-178(ra) # 8000198c <cpuid>
    80002a46:	c901                	beqz	a0,80002a56 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a48:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a4c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a4e:	14479073          	csrw	sip,a5
    return 2;
    80002a52:	4509                	li	a0,2
    80002a54:	b761                	j	800029dc <devintr+0x1e>
      clockintr();
    80002a56:	00000097          	auipc	ra,0x0
    80002a5a:	f22080e7          	jalr	-222(ra) # 80002978 <clockintr>
    80002a5e:	b7ed                	j	80002a48 <devintr+0x8a>

0000000080002a60 <usertrap>:
{
    80002a60:	1101                	addi	sp,sp,-32
    80002a62:	ec06                	sd	ra,24(sp)
    80002a64:	e822                	sd	s0,16(sp)
    80002a66:	e426                	sd	s1,8(sp)
    80002a68:	e04a                	sd	s2,0(sp)
    80002a6a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a6c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a70:	1007f793          	andi	a5,a5,256
    80002a74:	e3ad                	bnez	a5,80002ad6 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a76:	00003797          	auipc	a5,0x3
    80002a7a:	31a78793          	addi	a5,a5,794 # 80005d90 <kernelvec>
    80002a7e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a82:	fffff097          	auipc	ra,0xfffff
    80002a86:	f36080e7          	jalr	-202(ra) # 800019b8 <myproc>
    80002a8a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a8c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a8e:	14102773          	csrr	a4,sepc
    80002a92:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a94:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a98:	47a1                	li	a5,8
    80002a9a:	04f71c63          	bne	a4,a5,80002af2 <usertrap+0x92>
    if(p->killed)
    80002a9e:	551c                	lw	a5,40(a0)
    80002aa0:	e3b9                	bnez	a5,80002ae6 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002aa2:	6cb8                	ld	a4,88(s1)
    80002aa4:	6f1c                	ld	a5,24(a4)
    80002aa6:	0791                	addi	a5,a5,4
    80002aa8:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aaa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002aae:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ab2:	10079073          	csrw	sstatus,a5
    syscall();
    80002ab6:	00000097          	auipc	ra,0x0
    80002aba:	2e0080e7          	jalr	736(ra) # 80002d96 <syscall>
  if(p->killed)
    80002abe:	549c                	lw	a5,40(s1)
    80002ac0:	ebc1                	bnez	a5,80002b50 <usertrap+0xf0>
  usertrapret();
    80002ac2:	00000097          	auipc	ra,0x0
    80002ac6:	e18080e7          	jalr	-488(ra) # 800028da <usertrapret>
}
    80002aca:	60e2                	ld	ra,24(sp)
    80002acc:	6442                	ld	s0,16(sp)
    80002ace:	64a2                	ld	s1,8(sp)
    80002ad0:	6902                	ld	s2,0(sp)
    80002ad2:	6105                	addi	sp,sp,32
    80002ad4:	8082                	ret
    panic("usertrap: not from user mode");
    80002ad6:	00006517          	auipc	a0,0x6
    80002ada:	86a50513          	addi	a0,a0,-1942 # 80008340 <states.1747+0x58>
    80002ade:	ffffe097          	auipc	ra,0xffffe
    80002ae2:	a60080e7          	jalr	-1440(ra) # 8000053e <panic>
      exit(-1);
    80002ae6:	557d                	li	a0,-1
    80002ae8:	00000097          	auipc	ra,0x0
    80002aec:	9c4080e7          	jalr	-1596(ra) # 800024ac <exit>
    80002af0:	bf4d                	j	80002aa2 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002af2:	00000097          	auipc	ra,0x0
    80002af6:	ecc080e7          	jalr	-308(ra) # 800029be <devintr>
    80002afa:	892a                	mv	s2,a0
    80002afc:	c501                	beqz	a0,80002b04 <usertrap+0xa4>
  if(p->killed)
    80002afe:	549c                	lw	a5,40(s1)
    80002b00:	c3a1                	beqz	a5,80002b40 <usertrap+0xe0>
    80002b02:	a815                	j	80002b36 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b04:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b08:	5890                	lw	a2,48(s1)
    80002b0a:	00006517          	auipc	a0,0x6
    80002b0e:	85650513          	addi	a0,a0,-1962 # 80008360 <states.1747+0x78>
    80002b12:	ffffe097          	auipc	ra,0xffffe
    80002b16:	a76080e7          	jalr	-1418(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b1a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b1e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b22:	00006517          	auipc	a0,0x6
    80002b26:	86e50513          	addi	a0,a0,-1938 # 80008390 <states.1747+0xa8>
    80002b2a:	ffffe097          	auipc	ra,0xffffe
    80002b2e:	a5e080e7          	jalr	-1442(ra) # 80000588 <printf>
    p->killed = 1;
    80002b32:	4785                	li	a5,1
    80002b34:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002b36:	557d                	li	a0,-1
    80002b38:	00000097          	auipc	ra,0x0
    80002b3c:	974080e7          	jalr	-1676(ra) # 800024ac <exit>
  if(which_dev == 2)
    80002b40:	4789                	li	a5,2
    80002b42:	f8f910e3          	bne	s2,a5,80002ac2 <usertrap+0x62>
    yield();
    80002b46:	fffff097          	auipc	ra,0xfffff
    80002b4a:	6ce080e7          	jalr	1742(ra) # 80002214 <yield>
    80002b4e:	bf95                	j	80002ac2 <usertrap+0x62>
  int which_dev = 0;
    80002b50:	4901                	li	s2,0
    80002b52:	b7d5                	j	80002b36 <usertrap+0xd6>

0000000080002b54 <kerneltrap>:
{
    80002b54:	7179                	addi	sp,sp,-48
    80002b56:	f406                	sd	ra,40(sp)
    80002b58:	f022                	sd	s0,32(sp)
    80002b5a:	ec26                	sd	s1,24(sp)
    80002b5c:	e84a                	sd	s2,16(sp)
    80002b5e:	e44e                	sd	s3,8(sp)
    80002b60:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b62:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b66:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b6a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b6e:	1004f793          	andi	a5,s1,256
    80002b72:	cb85                	beqz	a5,80002ba2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b74:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b78:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b7a:	ef85                	bnez	a5,80002bb2 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b7c:	00000097          	auipc	ra,0x0
    80002b80:	e42080e7          	jalr	-446(ra) # 800029be <devintr>
    80002b84:	cd1d                	beqz	a0,80002bc2 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b86:	4789                	li	a5,2
    80002b88:	06f50a63          	beq	a0,a5,80002bfc <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b8c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b90:	10049073          	csrw	sstatus,s1
}
    80002b94:	70a2                	ld	ra,40(sp)
    80002b96:	7402                	ld	s0,32(sp)
    80002b98:	64e2                	ld	s1,24(sp)
    80002b9a:	6942                	ld	s2,16(sp)
    80002b9c:	69a2                	ld	s3,8(sp)
    80002b9e:	6145                	addi	sp,sp,48
    80002ba0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ba2:	00006517          	auipc	a0,0x6
    80002ba6:	80e50513          	addi	a0,a0,-2034 # 800083b0 <states.1747+0xc8>
    80002baa:	ffffe097          	auipc	ra,0xffffe
    80002bae:	994080e7          	jalr	-1644(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002bb2:	00006517          	auipc	a0,0x6
    80002bb6:	82650513          	addi	a0,a0,-2010 # 800083d8 <states.1747+0xf0>
    80002bba:	ffffe097          	auipc	ra,0xffffe
    80002bbe:	984080e7          	jalr	-1660(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002bc2:	85ce                	mv	a1,s3
    80002bc4:	00006517          	auipc	a0,0x6
    80002bc8:	83450513          	addi	a0,a0,-1996 # 800083f8 <states.1747+0x110>
    80002bcc:	ffffe097          	auipc	ra,0xffffe
    80002bd0:	9bc080e7          	jalr	-1604(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bd4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bd8:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bdc:	00006517          	auipc	a0,0x6
    80002be0:	82c50513          	addi	a0,a0,-2004 # 80008408 <states.1747+0x120>
    80002be4:	ffffe097          	auipc	ra,0xffffe
    80002be8:	9a4080e7          	jalr	-1628(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002bec:	00006517          	auipc	a0,0x6
    80002bf0:	83450513          	addi	a0,a0,-1996 # 80008420 <states.1747+0x138>
    80002bf4:	ffffe097          	auipc	ra,0xffffe
    80002bf8:	94a080e7          	jalr	-1718(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bfc:	fffff097          	auipc	ra,0xfffff
    80002c00:	dbc080e7          	jalr	-580(ra) # 800019b8 <myproc>
    80002c04:	d541                	beqz	a0,80002b8c <kerneltrap+0x38>
    80002c06:	fffff097          	auipc	ra,0xfffff
    80002c0a:	db2080e7          	jalr	-590(ra) # 800019b8 <myproc>
    80002c0e:	4d18                	lw	a4,24(a0)
    80002c10:	4791                	li	a5,4
    80002c12:	f6f71de3          	bne	a4,a5,80002b8c <kerneltrap+0x38>
    yield();
    80002c16:	fffff097          	auipc	ra,0xfffff
    80002c1a:	5fe080e7          	jalr	1534(ra) # 80002214 <yield>
    80002c1e:	b7bd                	j	80002b8c <kerneltrap+0x38>

0000000080002c20 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c20:	1101                	addi	sp,sp,-32
    80002c22:	ec06                	sd	ra,24(sp)
    80002c24:	e822                	sd	s0,16(sp)
    80002c26:	e426                	sd	s1,8(sp)
    80002c28:	1000                	addi	s0,sp,32
    80002c2a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c2c:	fffff097          	auipc	ra,0xfffff
    80002c30:	d8c080e7          	jalr	-628(ra) # 800019b8 <myproc>
  switch (n) {
    80002c34:	4795                	li	a5,5
    80002c36:	0497e163          	bltu	a5,s1,80002c78 <argraw+0x58>
    80002c3a:	048a                	slli	s1,s1,0x2
    80002c3c:	00006717          	auipc	a4,0x6
    80002c40:	81c70713          	addi	a4,a4,-2020 # 80008458 <states.1747+0x170>
    80002c44:	94ba                	add	s1,s1,a4
    80002c46:	409c                	lw	a5,0(s1)
    80002c48:	97ba                	add	a5,a5,a4
    80002c4a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c4c:	6d3c                	ld	a5,88(a0)
    80002c4e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c50:	60e2                	ld	ra,24(sp)
    80002c52:	6442                	ld	s0,16(sp)
    80002c54:	64a2                	ld	s1,8(sp)
    80002c56:	6105                	addi	sp,sp,32
    80002c58:	8082                	ret
    return p->trapframe->a1;
    80002c5a:	6d3c                	ld	a5,88(a0)
    80002c5c:	7fa8                	ld	a0,120(a5)
    80002c5e:	bfcd                	j	80002c50 <argraw+0x30>
    return p->trapframe->a2;
    80002c60:	6d3c                	ld	a5,88(a0)
    80002c62:	63c8                	ld	a0,128(a5)
    80002c64:	b7f5                	j	80002c50 <argraw+0x30>
    return p->trapframe->a3;
    80002c66:	6d3c                	ld	a5,88(a0)
    80002c68:	67c8                	ld	a0,136(a5)
    80002c6a:	b7dd                	j	80002c50 <argraw+0x30>
    return p->trapframe->a4;
    80002c6c:	6d3c                	ld	a5,88(a0)
    80002c6e:	6bc8                	ld	a0,144(a5)
    80002c70:	b7c5                	j	80002c50 <argraw+0x30>
    return p->trapframe->a5;
    80002c72:	6d3c                	ld	a5,88(a0)
    80002c74:	6fc8                	ld	a0,152(a5)
    80002c76:	bfe9                	j	80002c50 <argraw+0x30>
  panic("argraw");
    80002c78:	00005517          	auipc	a0,0x5
    80002c7c:	7b850513          	addi	a0,a0,1976 # 80008430 <states.1747+0x148>
    80002c80:	ffffe097          	auipc	ra,0xffffe
    80002c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>

0000000080002c88 <fetchaddr>:
{
    80002c88:	1101                	addi	sp,sp,-32
    80002c8a:	ec06                	sd	ra,24(sp)
    80002c8c:	e822                	sd	s0,16(sp)
    80002c8e:	e426                	sd	s1,8(sp)
    80002c90:	e04a                	sd	s2,0(sp)
    80002c92:	1000                	addi	s0,sp,32
    80002c94:	84aa                	mv	s1,a0
    80002c96:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c98:	fffff097          	auipc	ra,0xfffff
    80002c9c:	d20080e7          	jalr	-736(ra) # 800019b8 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002ca0:	653c                	ld	a5,72(a0)
    80002ca2:	02f4f863          	bgeu	s1,a5,80002cd2 <fetchaddr+0x4a>
    80002ca6:	00848713          	addi	a4,s1,8
    80002caa:	02e7e663          	bltu	a5,a4,80002cd6 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002cae:	46a1                	li	a3,8
    80002cb0:	8626                	mv	a2,s1
    80002cb2:	85ca                	mv	a1,s2
    80002cb4:	6928                	ld	a0,80(a0)
    80002cb6:	fffff097          	auipc	ra,0xfffff
    80002cba:	a50080e7          	jalr	-1456(ra) # 80001706 <copyin>
    80002cbe:	00a03533          	snez	a0,a0
    80002cc2:	40a00533          	neg	a0,a0
}
    80002cc6:	60e2                	ld	ra,24(sp)
    80002cc8:	6442                	ld	s0,16(sp)
    80002cca:	64a2                	ld	s1,8(sp)
    80002ccc:	6902                	ld	s2,0(sp)
    80002cce:	6105                	addi	sp,sp,32
    80002cd0:	8082                	ret
    return -1;
    80002cd2:	557d                	li	a0,-1
    80002cd4:	bfcd                	j	80002cc6 <fetchaddr+0x3e>
    80002cd6:	557d                	li	a0,-1
    80002cd8:	b7fd                	j	80002cc6 <fetchaddr+0x3e>

0000000080002cda <fetchstr>:
{
    80002cda:	7179                	addi	sp,sp,-48
    80002cdc:	f406                	sd	ra,40(sp)
    80002cde:	f022                	sd	s0,32(sp)
    80002ce0:	ec26                	sd	s1,24(sp)
    80002ce2:	e84a                	sd	s2,16(sp)
    80002ce4:	e44e                	sd	s3,8(sp)
    80002ce6:	1800                	addi	s0,sp,48
    80002ce8:	892a                	mv	s2,a0
    80002cea:	84ae                	mv	s1,a1
    80002cec:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002cee:	fffff097          	auipc	ra,0xfffff
    80002cf2:	cca080e7          	jalr	-822(ra) # 800019b8 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002cf6:	86ce                	mv	a3,s3
    80002cf8:	864a                	mv	a2,s2
    80002cfa:	85a6                	mv	a1,s1
    80002cfc:	6928                	ld	a0,80(a0)
    80002cfe:	fffff097          	auipc	ra,0xfffff
    80002d02:	a94080e7          	jalr	-1388(ra) # 80001792 <copyinstr>
  if(err < 0)
    80002d06:	00054763          	bltz	a0,80002d14 <fetchstr+0x3a>
  return strlen(buf);
    80002d0a:	8526                	mv	a0,s1
    80002d0c:	ffffe097          	auipc	ra,0xffffe
    80002d10:	158080e7          	jalr	344(ra) # 80000e64 <strlen>
}
    80002d14:	70a2                	ld	ra,40(sp)
    80002d16:	7402                	ld	s0,32(sp)
    80002d18:	64e2                	ld	s1,24(sp)
    80002d1a:	6942                	ld	s2,16(sp)
    80002d1c:	69a2                	ld	s3,8(sp)
    80002d1e:	6145                	addi	sp,sp,48
    80002d20:	8082                	ret

0000000080002d22 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002d22:	1101                	addi	sp,sp,-32
    80002d24:	ec06                	sd	ra,24(sp)
    80002d26:	e822                	sd	s0,16(sp)
    80002d28:	e426                	sd	s1,8(sp)
    80002d2a:	1000                	addi	s0,sp,32
    80002d2c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d2e:	00000097          	auipc	ra,0x0
    80002d32:	ef2080e7          	jalr	-270(ra) # 80002c20 <argraw>
    80002d36:	c088                	sw	a0,0(s1)
  return 0;
}
    80002d38:	4501                	li	a0,0
    80002d3a:	60e2                	ld	ra,24(sp)
    80002d3c:	6442                	ld	s0,16(sp)
    80002d3e:	64a2                	ld	s1,8(sp)
    80002d40:	6105                	addi	sp,sp,32
    80002d42:	8082                	ret

0000000080002d44 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002d44:	1101                	addi	sp,sp,-32
    80002d46:	ec06                	sd	ra,24(sp)
    80002d48:	e822                	sd	s0,16(sp)
    80002d4a:	e426                	sd	s1,8(sp)
    80002d4c:	1000                	addi	s0,sp,32
    80002d4e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d50:	00000097          	auipc	ra,0x0
    80002d54:	ed0080e7          	jalr	-304(ra) # 80002c20 <argraw>
    80002d58:	e088                	sd	a0,0(s1)
  return 0;
}
    80002d5a:	4501                	li	a0,0
    80002d5c:	60e2                	ld	ra,24(sp)
    80002d5e:	6442                	ld	s0,16(sp)
    80002d60:	64a2                	ld	s1,8(sp)
    80002d62:	6105                	addi	sp,sp,32
    80002d64:	8082                	ret

0000000080002d66 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d66:	1101                	addi	sp,sp,-32
    80002d68:	ec06                	sd	ra,24(sp)
    80002d6a:	e822                	sd	s0,16(sp)
    80002d6c:	e426                	sd	s1,8(sp)
    80002d6e:	e04a                	sd	s2,0(sp)
    80002d70:	1000                	addi	s0,sp,32
    80002d72:	84ae                	mv	s1,a1
    80002d74:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002d76:	00000097          	auipc	ra,0x0
    80002d7a:	eaa080e7          	jalr	-342(ra) # 80002c20 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002d7e:	864a                	mv	a2,s2
    80002d80:	85a6                	mv	a1,s1
    80002d82:	00000097          	auipc	ra,0x0
    80002d86:	f58080e7          	jalr	-168(ra) # 80002cda <fetchstr>
}
    80002d8a:	60e2                	ld	ra,24(sp)
    80002d8c:	6442                	ld	s0,16(sp)
    80002d8e:	64a2                	ld	s1,8(sp)
    80002d90:	6902                	ld	s2,0(sp)
    80002d92:	6105                	addi	sp,sp,32
    80002d94:	8082                	ret

0000000080002d96 <syscall>:
[SYS_pause_system] sys_pause_system,
};

void
syscall(void)
{
    80002d96:	1101                	addi	sp,sp,-32
    80002d98:	ec06                	sd	ra,24(sp)
    80002d9a:	e822                	sd	s0,16(sp)
    80002d9c:	e426                	sd	s1,8(sp)
    80002d9e:	e04a                	sd	s2,0(sp)
    80002da0:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002da2:	fffff097          	auipc	ra,0xfffff
    80002da6:	c16080e7          	jalr	-1002(ra) # 800019b8 <myproc>
    80002daa:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002dac:	05853903          	ld	s2,88(a0)
    80002db0:	0a893783          	ld	a5,168(s2)
    80002db4:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002db8:	37fd                	addiw	a5,a5,-1
    80002dba:	4759                	li	a4,22
    80002dbc:	00f76f63          	bltu	a4,a5,80002dda <syscall+0x44>
    80002dc0:	00369713          	slli	a4,a3,0x3
    80002dc4:	00005797          	auipc	a5,0x5
    80002dc8:	6ac78793          	addi	a5,a5,1708 # 80008470 <syscalls>
    80002dcc:	97ba                	add	a5,a5,a4
    80002dce:	639c                	ld	a5,0(a5)
    80002dd0:	c789                	beqz	a5,80002dda <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002dd2:	9782                	jalr	a5
    80002dd4:	06a93823          	sd	a0,112(s2)
    80002dd8:	a839                	j	80002df6 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002dda:	15848613          	addi	a2,s1,344
    80002dde:	588c                	lw	a1,48(s1)
    80002de0:	00005517          	auipc	a0,0x5
    80002de4:	65850513          	addi	a0,a0,1624 # 80008438 <states.1747+0x150>
    80002de8:	ffffd097          	auipc	ra,0xffffd
    80002dec:	7a0080e7          	jalr	1952(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002df0:	6cbc                	ld	a5,88(s1)
    80002df2:	577d                	li	a4,-1
    80002df4:	fbb8                	sd	a4,112(a5)
  }
}
    80002df6:	60e2                	ld	ra,24(sp)
    80002df8:	6442                	ld	s0,16(sp)
    80002dfa:	64a2                	ld	s1,8(sp)
    80002dfc:	6902                	ld	s2,0(sp)
    80002dfe:	6105                	addi	sp,sp,32
    80002e00:	8082                	ret

0000000080002e02 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e02:	1101                	addi	sp,sp,-32
    80002e04:	ec06                	sd	ra,24(sp)
    80002e06:	e822                	sd	s0,16(sp)
    80002e08:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002e0a:	fec40593          	addi	a1,s0,-20
    80002e0e:	4501                	li	a0,0
    80002e10:	00000097          	auipc	ra,0x0
    80002e14:	f12080e7          	jalr	-238(ra) # 80002d22 <argint>
    return -1;
    80002e18:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e1a:	00054963          	bltz	a0,80002e2c <sys_exit+0x2a>
  exit(n);
    80002e1e:	fec42503          	lw	a0,-20(s0)
    80002e22:	fffff097          	auipc	ra,0xfffff
    80002e26:	68a080e7          	jalr	1674(ra) # 800024ac <exit>
  return 0;  // not reached
    80002e2a:	4781                	li	a5,0
}
    80002e2c:	853e                	mv	a0,a5
    80002e2e:	60e2                	ld	ra,24(sp)
    80002e30:	6442                	ld	s0,16(sp)
    80002e32:	6105                	addi	sp,sp,32
    80002e34:	8082                	ret

0000000080002e36 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e36:	1141                	addi	sp,sp,-16
    80002e38:	e406                	sd	ra,8(sp)
    80002e3a:	e022                	sd	s0,0(sp)
    80002e3c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e3e:	fffff097          	auipc	ra,0xfffff
    80002e42:	b7a080e7          	jalr	-1158(ra) # 800019b8 <myproc>
}
    80002e46:	5908                	lw	a0,48(a0)
    80002e48:	60a2                	ld	ra,8(sp)
    80002e4a:	6402                	ld	s0,0(sp)
    80002e4c:	0141                	addi	sp,sp,16
    80002e4e:	8082                	ret

0000000080002e50 <sys_fork>:

uint64
sys_fork(void)
{
    80002e50:	1141                	addi	sp,sp,-16
    80002e52:	e406                	sd	ra,8(sp)
    80002e54:	e022                	sd	s0,0(sp)
    80002e56:	0800                	addi	s0,sp,16
  return fork();
    80002e58:	fffff097          	auipc	ra,0xfffff
    80002e5c:	f3a080e7          	jalr	-198(ra) # 80001d92 <fork>
}
    80002e60:	60a2                	ld	ra,8(sp)
    80002e62:	6402                	ld	s0,0(sp)
    80002e64:	0141                	addi	sp,sp,16
    80002e66:	8082                	ret

0000000080002e68 <sys_wait>:

uint64
sys_wait(void)
{
    80002e68:	1101                	addi	sp,sp,-32
    80002e6a:	ec06                	sd	ra,24(sp)
    80002e6c:	e822                	sd	s0,16(sp)
    80002e6e:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002e70:	fe840593          	addi	a1,s0,-24
    80002e74:	4501                	li	a0,0
    80002e76:	00000097          	auipc	ra,0x0
    80002e7a:	ece080e7          	jalr	-306(ra) # 80002d44 <argaddr>
    80002e7e:	87aa                	mv	a5,a0
    return -1;
    80002e80:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002e82:	0007c863          	bltz	a5,80002e92 <sys_wait+0x2a>
  return wait(p);
    80002e86:	fe843503          	ld	a0,-24(s0)
    80002e8a:	fffff097          	auipc	ra,0xfffff
    80002e8e:	42a080e7          	jalr	1066(ra) # 800022b4 <wait>
}
    80002e92:	60e2                	ld	ra,24(sp)
    80002e94:	6442                	ld	s0,16(sp)
    80002e96:	6105                	addi	sp,sp,32
    80002e98:	8082                	ret

0000000080002e9a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e9a:	7179                	addi	sp,sp,-48
    80002e9c:	f406                	sd	ra,40(sp)
    80002e9e:	f022                	sd	s0,32(sp)
    80002ea0:	ec26                	sd	s1,24(sp)
    80002ea2:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002ea4:	fdc40593          	addi	a1,s0,-36
    80002ea8:	4501                	li	a0,0
    80002eaa:	00000097          	auipc	ra,0x0
    80002eae:	e78080e7          	jalr	-392(ra) # 80002d22 <argint>
    80002eb2:	87aa                	mv	a5,a0
    return -1;
    80002eb4:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002eb6:	0207c063          	bltz	a5,80002ed6 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002eba:	fffff097          	auipc	ra,0xfffff
    80002ebe:	afe080e7          	jalr	-1282(ra) # 800019b8 <myproc>
    80002ec2:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002ec4:	fdc42503          	lw	a0,-36(s0)
    80002ec8:	fffff097          	auipc	ra,0xfffff
    80002ecc:	e56080e7          	jalr	-426(ra) # 80001d1e <growproc>
    80002ed0:	00054863          	bltz	a0,80002ee0 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002ed4:	8526                	mv	a0,s1
}
    80002ed6:	70a2                	ld	ra,40(sp)
    80002ed8:	7402                	ld	s0,32(sp)
    80002eda:	64e2                	ld	s1,24(sp)
    80002edc:	6145                	addi	sp,sp,48
    80002ede:	8082                	ret
    return -1;
    80002ee0:	557d                	li	a0,-1
    80002ee2:	bfd5                	j	80002ed6 <sys_sbrk+0x3c>

0000000080002ee4 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002ee4:	7139                	addi	sp,sp,-64
    80002ee6:	fc06                	sd	ra,56(sp)
    80002ee8:	f822                	sd	s0,48(sp)
    80002eea:	f426                	sd	s1,40(sp)
    80002eec:	f04a                	sd	s2,32(sp)
    80002eee:	ec4e                	sd	s3,24(sp)
    80002ef0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002ef2:	fcc40593          	addi	a1,s0,-52
    80002ef6:	4501                	li	a0,0
    80002ef8:	00000097          	auipc	ra,0x0
    80002efc:	e2a080e7          	jalr	-470(ra) # 80002d22 <argint>
    return -1;
    80002f00:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f02:	06054563          	bltz	a0,80002f6c <sys_sleep+0x88>
  acquire(&tickslock);
    80002f06:	0000d517          	auipc	a0,0xd
    80002f0a:	33a50513          	addi	a0,a0,826 # 80010240 <tickslock>
    80002f0e:	ffffe097          	auipc	ra,0xffffe
    80002f12:	cd6080e7          	jalr	-810(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002f16:	00006917          	auipc	s2,0x6
    80002f1a:	12292903          	lw	s2,290(s2) # 80009038 <ticks>
  while(ticks - ticks0 < n){
    80002f1e:	fcc42783          	lw	a5,-52(s0)
    80002f22:	cf85                	beqz	a5,80002f5a <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f24:	0000d997          	auipc	s3,0xd
    80002f28:	31c98993          	addi	s3,s3,796 # 80010240 <tickslock>
    80002f2c:	00006497          	auipc	s1,0x6
    80002f30:	10c48493          	addi	s1,s1,268 # 80009038 <ticks>
    if(myproc()->killed){
    80002f34:	fffff097          	auipc	ra,0xfffff
    80002f38:	a84080e7          	jalr	-1404(ra) # 800019b8 <myproc>
    80002f3c:	551c                	lw	a5,40(a0)
    80002f3e:	ef9d                	bnez	a5,80002f7c <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002f40:	85ce                	mv	a1,s3
    80002f42:	8526                	mv	a0,s1
    80002f44:	fffff097          	auipc	ra,0xfffff
    80002f48:	30c080e7          	jalr	780(ra) # 80002250 <sleep>
  while(ticks - ticks0 < n){
    80002f4c:	409c                	lw	a5,0(s1)
    80002f4e:	412787bb          	subw	a5,a5,s2
    80002f52:	fcc42703          	lw	a4,-52(s0)
    80002f56:	fce7efe3          	bltu	a5,a4,80002f34 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002f5a:	0000d517          	auipc	a0,0xd
    80002f5e:	2e650513          	addi	a0,a0,742 # 80010240 <tickslock>
    80002f62:	ffffe097          	auipc	ra,0xffffe
    80002f66:	d36080e7          	jalr	-714(ra) # 80000c98 <release>
  return 0;
    80002f6a:	4781                	li	a5,0
}
    80002f6c:	853e                	mv	a0,a5
    80002f6e:	70e2                	ld	ra,56(sp)
    80002f70:	7442                	ld	s0,48(sp)
    80002f72:	74a2                	ld	s1,40(sp)
    80002f74:	7902                	ld	s2,32(sp)
    80002f76:	69e2                	ld	s3,24(sp)
    80002f78:	6121                	addi	sp,sp,64
    80002f7a:	8082                	ret
      release(&tickslock);
    80002f7c:	0000d517          	auipc	a0,0xd
    80002f80:	2c450513          	addi	a0,a0,708 # 80010240 <tickslock>
    80002f84:	ffffe097          	auipc	ra,0xffffe
    80002f88:	d14080e7          	jalr	-748(ra) # 80000c98 <release>
      return -1;
    80002f8c:	57fd                	li	a5,-1
    80002f8e:	bff9                	j	80002f6c <sys_sleep+0x88>

0000000080002f90 <sys_kill>:

uint64
sys_kill(void)
{
    80002f90:	1101                	addi	sp,sp,-32
    80002f92:	ec06                	sd	ra,24(sp)
    80002f94:	e822                	sd	s0,16(sp)
    80002f96:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002f98:	fec40593          	addi	a1,s0,-20
    80002f9c:	4501                	li	a0,0
    80002f9e:	00000097          	auipc	ra,0x0
    80002fa2:	d84080e7          	jalr	-636(ra) # 80002d22 <argint>
    80002fa6:	87aa                	mv	a5,a0
    return -1;
    80002fa8:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002faa:	0007c863          	bltz	a5,80002fba <sys_kill+0x2a>
  return kill(pid);
    80002fae:	fec42503          	lw	a0,-20(s0)
    80002fb2:	fffff097          	auipc	ra,0xfffff
    80002fb6:	5d0080e7          	jalr	1488(ra) # 80002582 <kill>
}
    80002fba:	60e2                	ld	ra,24(sp)
    80002fbc:	6442                	ld	s0,16(sp)
    80002fbe:	6105                	addi	sp,sp,32
    80002fc0:	8082                	ret

0000000080002fc2 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002fc2:	1101                	addi	sp,sp,-32
    80002fc4:	ec06                	sd	ra,24(sp)
    80002fc6:	e822                	sd	s0,16(sp)
    80002fc8:	e426                	sd	s1,8(sp)
    80002fca:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002fcc:	0000d517          	auipc	a0,0xd
    80002fd0:	27450513          	addi	a0,a0,628 # 80010240 <tickslock>
    80002fd4:	ffffe097          	auipc	ra,0xffffe
    80002fd8:	c10080e7          	jalr	-1008(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002fdc:	00006497          	auipc	s1,0x6
    80002fe0:	05c4a483          	lw	s1,92(s1) # 80009038 <ticks>
  release(&tickslock);
    80002fe4:	0000d517          	auipc	a0,0xd
    80002fe8:	25c50513          	addi	a0,a0,604 # 80010240 <tickslock>
    80002fec:	ffffe097          	auipc	ra,0xffffe
    80002ff0:	cac080e7          	jalr	-852(ra) # 80000c98 <release>
  return xticks;
}
    80002ff4:	02049513          	slli	a0,s1,0x20
    80002ff8:	9101                	srli	a0,a0,0x20
    80002ffa:	60e2                	ld	ra,24(sp)
    80002ffc:	6442                	ld	s0,16(sp)
    80002ffe:	64a2                	ld	s1,8(sp)
    80003000:	6105                	addi	sp,sp,32
    80003002:	8082                	ret

0000000080003004 <sys_kill_system>:

uint64
sys_kill_system(void)
{
    80003004:	1141                	addi	sp,sp,-16
    80003006:	e406                	sd	ra,8(sp)
    80003008:	e022                	sd	s0,0(sp)
    8000300a:	0800                	addi	s0,sp,16
  return kill_system();
    8000300c:	fffff097          	auipc	ra,0xfffff
    80003010:	5e8080e7          	jalr	1512(ra) # 800025f4 <kill_system>
}
    80003014:	60a2                	ld	ra,8(sp)
    80003016:	6402                	ld	s0,0(sp)
    80003018:	0141                	addi	sp,sp,16
    8000301a:	8082                	ret

000000008000301c <sys_pause_system>:

uint64
sys_pause_system(void)
{
    8000301c:	1101                	addi	sp,sp,-32
    8000301e:	ec06                	sd	ra,24(sp)
    80003020:	e822                	sd	s0,16(sp)
    80003022:	1000                	addi	s0,sp,32
  int seconds;

  if(argint(0, &seconds) < 0)
    80003024:	fec40593          	addi	a1,s0,-20
    80003028:	4501                	li	a0,0
    8000302a:	00000097          	auipc	ra,0x0
    8000302e:	cf8080e7          	jalr	-776(ra) # 80002d22 <argint>
    80003032:	87aa                	mv	a5,a0
    return -1;
    80003034:	557d                	li	a0,-1
  if(argint(0, &seconds) < 0)
    80003036:	0007c863          	bltz	a5,80003046 <sys_pause_system+0x2a>
  return pause_system(seconds);
    8000303a:	fec42503          	lw	a0,-20(s0)
    8000303e:	fffff097          	auipc	ra,0xfffff
    80003042:	7bc080e7          	jalr	1980(ra) # 800027fa <pause_system>
}
    80003046:	60e2                	ld	ra,24(sp)
    80003048:	6442                	ld	s0,16(sp)
    8000304a:	6105                	addi	sp,sp,32
    8000304c:	8082                	ret

000000008000304e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000304e:	7179                	addi	sp,sp,-48
    80003050:	f406                	sd	ra,40(sp)
    80003052:	f022                	sd	s0,32(sp)
    80003054:	ec26                	sd	s1,24(sp)
    80003056:	e84a                	sd	s2,16(sp)
    80003058:	e44e                	sd	s3,8(sp)
    8000305a:	e052                	sd	s4,0(sp)
    8000305c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000305e:	00005597          	auipc	a1,0x5
    80003062:	4d258593          	addi	a1,a1,1234 # 80008530 <syscalls+0xc0>
    80003066:	0000d517          	auipc	a0,0xd
    8000306a:	1f250513          	addi	a0,a0,498 # 80010258 <bcache>
    8000306e:	ffffe097          	auipc	ra,0xffffe
    80003072:	ae6080e7          	jalr	-1306(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003076:	00015797          	auipc	a5,0x15
    8000307a:	1e278793          	addi	a5,a5,482 # 80018258 <bcache+0x8000>
    8000307e:	00015717          	auipc	a4,0x15
    80003082:	44270713          	addi	a4,a4,1090 # 800184c0 <bcache+0x8268>
    80003086:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000308a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000308e:	0000d497          	auipc	s1,0xd
    80003092:	1e248493          	addi	s1,s1,482 # 80010270 <bcache+0x18>
    b->next = bcache.head.next;
    80003096:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003098:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000309a:	00005a17          	auipc	s4,0x5
    8000309e:	49ea0a13          	addi	s4,s4,1182 # 80008538 <syscalls+0xc8>
    b->next = bcache.head.next;
    800030a2:	2b893783          	ld	a5,696(s2)
    800030a6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800030a8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800030ac:	85d2                	mv	a1,s4
    800030ae:	01048513          	addi	a0,s1,16
    800030b2:	00001097          	auipc	ra,0x1
    800030b6:	4bc080e7          	jalr	1212(ra) # 8000456e <initsleeplock>
    bcache.head.next->prev = b;
    800030ba:	2b893783          	ld	a5,696(s2)
    800030be:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800030c0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030c4:	45848493          	addi	s1,s1,1112
    800030c8:	fd349de3          	bne	s1,s3,800030a2 <binit+0x54>
  }
}
    800030cc:	70a2                	ld	ra,40(sp)
    800030ce:	7402                	ld	s0,32(sp)
    800030d0:	64e2                	ld	s1,24(sp)
    800030d2:	6942                	ld	s2,16(sp)
    800030d4:	69a2                	ld	s3,8(sp)
    800030d6:	6a02                	ld	s4,0(sp)
    800030d8:	6145                	addi	sp,sp,48
    800030da:	8082                	ret

00000000800030dc <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800030dc:	7179                	addi	sp,sp,-48
    800030de:	f406                	sd	ra,40(sp)
    800030e0:	f022                	sd	s0,32(sp)
    800030e2:	ec26                	sd	s1,24(sp)
    800030e4:	e84a                	sd	s2,16(sp)
    800030e6:	e44e                	sd	s3,8(sp)
    800030e8:	1800                	addi	s0,sp,48
    800030ea:	89aa                	mv	s3,a0
    800030ec:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800030ee:	0000d517          	auipc	a0,0xd
    800030f2:	16a50513          	addi	a0,a0,362 # 80010258 <bcache>
    800030f6:	ffffe097          	auipc	ra,0xffffe
    800030fa:	aee080e7          	jalr	-1298(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800030fe:	00015497          	auipc	s1,0x15
    80003102:	4124b483          	ld	s1,1042(s1) # 80018510 <bcache+0x82b8>
    80003106:	00015797          	auipc	a5,0x15
    8000310a:	3ba78793          	addi	a5,a5,954 # 800184c0 <bcache+0x8268>
    8000310e:	02f48f63          	beq	s1,a5,8000314c <bread+0x70>
    80003112:	873e                	mv	a4,a5
    80003114:	a021                	j	8000311c <bread+0x40>
    80003116:	68a4                	ld	s1,80(s1)
    80003118:	02e48a63          	beq	s1,a4,8000314c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000311c:	449c                	lw	a5,8(s1)
    8000311e:	ff379ce3          	bne	a5,s3,80003116 <bread+0x3a>
    80003122:	44dc                	lw	a5,12(s1)
    80003124:	ff2799e3          	bne	a5,s2,80003116 <bread+0x3a>
      b->refcnt++;
    80003128:	40bc                	lw	a5,64(s1)
    8000312a:	2785                	addiw	a5,a5,1
    8000312c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000312e:	0000d517          	auipc	a0,0xd
    80003132:	12a50513          	addi	a0,a0,298 # 80010258 <bcache>
    80003136:	ffffe097          	auipc	ra,0xffffe
    8000313a:	b62080e7          	jalr	-1182(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000313e:	01048513          	addi	a0,s1,16
    80003142:	00001097          	auipc	ra,0x1
    80003146:	466080e7          	jalr	1126(ra) # 800045a8 <acquiresleep>
      return b;
    8000314a:	a8b9                	j	800031a8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000314c:	00015497          	auipc	s1,0x15
    80003150:	3bc4b483          	ld	s1,956(s1) # 80018508 <bcache+0x82b0>
    80003154:	00015797          	auipc	a5,0x15
    80003158:	36c78793          	addi	a5,a5,876 # 800184c0 <bcache+0x8268>
    8000315c:	00f48863          	beq	s1,a5,8000316c <bread+0x90>
    80003160:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003162:	40bc                	lw	a5,64(s1)
    80003164:	cf81                	beqz	a5,8000317c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003166:	64a4                	ld	s1,72(s1)
    80003168:	fee49de3          	bne	s1,a4,80003162 <bread+0x86>
  panic("bget: no buffers");
    8000316c:	00005517          	auipc	a0,0x5
    80003170:	3d450513          	addi	a0,a0,980 # 80008540 <syscalls+0xd0>
    80003174:	ffffd097          	auipc	ra,0xffffd
    80003178:	3ca080e7          	jalr	970(ra) # 8000053e <panic>
      b->dev = dev;
    8000317c:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003180:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003184:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003188:	4785                	li	a5,1
    8000318a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000318c:	0000d517          	auipc	a0,0xd
    80003190:	0cc50513          	addi	a0,a0,204 # 80010258 <bcache>
    80003194:	ffffe097          	auipc	ra,0xffffe
    80003198:	b04080e7          	jalr	-1276(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000319c:	01048513          	addi	a0,s1,16
    800031a0:	00001097          	auipc	ra,0x1
    800031a4:	408080e7          	jalr	1032(ra) # 800045a8 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800031a8:	409c                	lw	a5,0(s1)
    800031aa:	cb89                	beqz	a5,800031bc <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800031ac:	8526                	mv	a0,s1
    800031ae:	70a2                	ld	ra,40(sp)
    800031b0:	7402                	ld	s0,32(sp)
    800031b2:	64e2                	ld	s1,24(sp)
    800031b4:	6942                	ld	s2,16(sp)
    800031b6:	69a2                	ld	s3,8(sp)
    800031b8:	6145                	addi	sp,sp,48
    800031ba:	8082                	ret
    virtio_disk_rw(b, 0);
    800031bc:	4581                	li	a1,0
    800031be:	8526                	mv	a0,s1
    800031c0:	00003097          	auipc	ra,0x3
    800031c4:	f06080e7          	jalr	-250(ra) # 800060c6 <virtio_disk_rw>
    b->valid = 1;
    800031c8:	4785                	li	a5,1
    800031ca:	c09c                	sw	a5,0(s1)
  return b;
    800031cc:	b7c5                	j	800031ac <bread+0xd0>

00000000800031ce <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800031ce:	1101                	addi	sp,sp,-32
    800031d0:	ec06                	sd	ra,24(sp)
    800031d2:	e822                	sd	s0,16(sp)
    800031d4:	e426                	sd	s1,8(sp)
    800031d6:	1000                	addi	s0,sp,32
    800031d8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031da:	0541                	addi	a0,a0,16
    800031dc:	00001097          	auipc	ra,0x1
    800031e0:	466080e7          	jalr	1126(ra) # 80004642 <holdingsleep>
    800031e4:	cd01                	beqz	a0,800031fc <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031e6:	4585                	li	a1,1
    800031e8:	8526                	mv	a0,s1
    800031ea:	00003097          	auipc	ra,0x3
    800031ee:	edc080e7          	jalr	-292(ra) # 800060c6 <virtio_disk_rw>
}
    800031f2:	60e2                	ld	ra,24(sp)
    800031f4:	6442                	ld	s0,16(sp)
    800031f6:	64a2                	ld	s1,8(sp)
    800031f8:	6105                	addi	sp,sp,32
    800031fa:	8082                	ret
    panic("bwrite");
    800031fc:	00005517          	auipc	a0,0x5
    80003200:	35c50513          	addi	a0,a0,860 # 80008558 <syscalls+0xe8>
    80003204:	ffffd097          	auipc	ra,0xffffd
    80003208:	33a080e7          	jalr	826(ra) # 8000053e <panic>

000000008000320c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000320c:	1101                	addi	sp,sp,-32
    8000320e:	ec06                	sd	ra,24(sp)
    80003210:	e822                	sd	s0,16(sp)
    80003212:	e426                	sd	s1,8(sp)
    80003214:	e04a                	sd	s2,0(sp)
    80003216:	1000                	addi	s0,sp,32
    80003218:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000321a:	01050913          	addi	s2,a0,16
    8000321e:	854a                	mv	a0,s2
    80003220:	00001097          	auipc	ra,0x1
    80003224:	422080e7          	jalr	1058(ra) # 80004642 <holdingsleep>
    80003228:	c92d                	beqz	a0,8000329a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000322a:	854a                	mv	a0,s2
    8000322c:	00001097          	auipc	ra,0x1
    80003230:	3d2080e7          	jalr	978(ra) # 800045fe <releasesleep>

  acquire(&bcache.lock);
    80003234:	0000d517          	auipc	a0,0xd
    80003238:	02450513          	addi	a0,a0,36 # 80010258 <bcache>
    8000323c:	ffffe097          	auipc	ra,0xffffe
    80003240:	9a8080e7          	jalr	-1624(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003244:	40bc                	lw	a5,64(s1)
    80003246:	37fd                	addiw	a5,a5,-1
    80003248:	0007871b          	sext.w	a4,a5
    8000324c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000324e:	eb05                	bnez	a4,8000327e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003250:	68bc                	ld	a5,80(s1)
    80003252:	64b8                	ld	a4,72(s1)
    80003254:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003256:	64bc                	ld	a5,72(s1)
    80003258:	68b8                	ld	a4,80(s1)
    8000325a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000325c:	00015797          	auipc	a5,0x15
    80003260:	ffc78793          	addi	a5,a5,-4 # 80018258 <bcache+0x8000>
    80003264:	2b87b703          	ld	a4,696(a5)
    80003268:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000326a:	00015717          	auipc	a4,0x15
    8000326e:	25670713          	addi	a4,a4,598 # 800184c0 <bcache+0x8268>
    80003272:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003274:	2b87b703          	ld	a4,696(a5)
    80003278:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000327a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000327e:	0000d517          	auipc	a0,0xd
    80003282:	fda50513          	addi	a0,a0,-38 # 80010258 <bcache>
    80003286:	ffffe097          	auipc	ra,0xffffe
    8000328a:	a12080e7          	jalr	-1518(ra) # 80000c98 <release>
}
    8000328e:	60e2                	ld	ra,24(sp)
    80003290:	6442                	ld	s0,16(sp)
    80003292:	64a2                	ld	s1,8(sp)
    80003294:	6902                	ld	s2,0(sp)
    80003296:	6105                	addi	sp,sp,32
    80003298:	8082                	ret
    panic("brelse");
    8000329a:	00005517          	auipc	a0,0x5
    8000329e:	2c650513          	addi	a0,a0,710 # 80008560 <syscalls+0xf0>
    800032a2:	ffffd097          	auipc	ra,0xffffd
    800032a6:	29c080e7          	jalr	668(ra) # 8000053e <panic>

00000000800032aa <bpin>:

void
bpin(struct buf *b) {
    800032aa:	1101                	addi	sp,sp,-32
    800032ac:	ec06                	sd	ra,24(sp)
    800032ae:	e822                	sd	s0,16(sp)
    800032b0:	e426                	sd	s1,8(sp)
    800032b2:	1000                	addi	s0,sp,32
    800032b4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032b6:	0000d517          	auipc	a0,0xd
    800032ba:	fa250513          	addi	a0,a0,-94 # 80010258 <bcache>
    800032be:	ffffe097          	auipc	ra,0xffffe
    800032c2:	926080e7          	jalr	-1754(ra) # 80000be4 <acquire>
  b->refcnt++;
    800032c6:	40bc                	lw	a5,64(s1)
    800032c8:	2785                	addiw	a5,a5,1
    800032ca:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032cc:	0000d517          	auipc	a0,0xd
    800032d0:	f8c50513          	addi	a0,a0,-116 # 80010258 <bcache>
    800032d4:	ffffe097          	auipc	ra,0xffffe
    800032d8:	9c4080e7          	jalr	-1596(ra) # 80000c98 <release>
}
    800032dc:	60e2                	ld	ra,24(sp)
    800032de:	6442                	ld	s0,16(sp)
    800032e0:	64a2                	ld	s1,8(sp)
    800032e2:	6105                	addi	sp,sp,32
    800032e4:	8082                	ret

00000000800032e6 <bunpin>:

void
bunpin(struct buf *b) {
    800032e6:	1101                	addi	sp,sp,-32
    800032e8:	ec06                	sd	ra,24(sp)
    800032ea:	e822                	sd	s0,16(sp)
    800032ec:	e426                	sd	s1,8(sp)
    800032ee:	1000                	addi	s0,sp,32
    800032f0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032f2:	0000d517          	auipc	a0,0xd
    800032f6:	f6650513          	addi	a0,a0,-154 # 80010258 <bcache>
    800032fa:	ffffe097          	auipc	ra,0xffffe
    800032fe:	8ea080e7          	jalr	-1814(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003302:	40bc                	lw	a5,64(s1)
    80003304:	37fd                	addiw	a5,a5,-1
    80003306:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003308:	0000d517          	auipc	a0,0xd
    8000330c:	f5050513          	addi	a0,a0,-176 # 80010258 <bcache>
    80003310:	ffffe097          	auipc	ra,0xffffe
    80003314:	988080e7          	jalr	-1656(ra) # 80000c98 <release>
}
    80003318:	60e2                	ld	ra,24(sp)
    8000331a:	6442                	ld	s0,16(sp)
    8000331c:	64a2                	ld	s1,8(sp)
    8000331e:	6105                	addi	sp,sp,32
    80003320:	8082                	ret

0000000080003322 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003322:	1101                	addi	sp,sp,-32
    80003324:	ec06                	sd	ra,24(sp)
    80003326:	e822                	sd	s0,16(sp)
    80003328:	e426                	sd	s1,8(sp)
    8000332a:	e04a                	sd	s2,0(sp)
    8000332c:	1000                	addi	s0,sp,32
    8000332e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003330:	00d5d59b          	srliw	a1,a1,0xd
    80003334:	00015797          	auipc	a5,0x15
    80003338:	6007a783          	lw	a5,1536(a5) # 80018934 <sb+0x1c>
    8000333c:	9dbd                	addw	a1,a1,a5
    8000333e:	00000097          	auipc	ra,0x0
    80003342:	d9e080e7          	jalr	-610(ra) # 800030dc <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003346:	0074f713          	andi	a4,s1,7
    8000334a:	4785                	li	a5,1
    8000334c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003350:	14ce                	slli	s1,s1,0x33
    80003352:	90d9                	srli	s1,s1,0x36
    80003354:	00950733          	add	a4,a0,s1
    80003358:	05874703          	lbu	a4,88(a4)
    8000335c:	00e7f6b3          	and	a3,a5,a4
    80003360:	c69d                	beqz	a3,8000338e <bfree+0x6c>
    80003362:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003364:	94aa                	add	s1,s1,a0
    80003366:	fff7c793          	not	a5,a5
    8000336a:	8ff9                	and	a5,a5,a4
    8000336c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003370:	00001097          	auipc	ra,0x1
    80003374:	118080e7          	jalr	280(ra) # 80004488 <log_write>
  brelse(bp);
    80003378:	854a                	mv	a0,s2
    8000337a:	00000097          	auipc	ra,0x0
    8000337e:	e92080e7          	jalr	-366(ra) # 8000320c <brelse>
}
    80003382:	60e2                	ld	ra,24(sp)
    80003384:	6442                	ld	s0,16(sp)
    80003386:	64a2                	ld	s1,8(sp)
    80003388:	6902                	ld	s2,0(sp)
    8000338a:	6105                	addi	sp,sp,32
    8000338c:	8082                	ret
    panic("freeing free block");
    8000338e:	00005517          	auipc	a0,0x5
    80003392:	1da50513          	addi	a0,a0,474 # 80008568 <syscalls+0xf8>
    80003396:	ffffd097          	auipc	ra,0xffffd
    8000339a:	1a8080e7          	jalr	424(ra) # 8000053e <panic>

000000008000339e <balloc>:
{
    8000339e:	711d                	addi	sp,sp,-96
    800033a0:	ec86                	sd	ra,88(sp)
    800033a2:	e8a2                	sd	s0,80(sp)
    800033a4:	e4a6                	sd	s1,72(sp)
    800033a6:	e0ca                	sd	s2,64(sp)
    800033a8:	fc4e                	sd	s3,56(sp)
    800033aa:	f852                	sd	s4,48(sp)
    800033ac:	f456                	sd	s5,40(sp)
    800033ae:	f05a                	sd	s6,32(sp)
    800033b0:	ec5e                	sd	s7,24(sp)
    800033b2:	e862                	sd	s8,16(sp)
    800033b4:	e466                	sd	s9,8(sp)
    800033b6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800033b8:	00015797          	auipc	a5,0x15
    800033bc:	5647a783          	lw	a5,1380(a5) # 8001891c <sb+0x4>
    800033c0:	cbd1                	beqz	a5,80003454 <balloc+0xb6>
    800033c2:	8baa                	mv	s7,a0
    800033c4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800033c6:	00015b17          	auipc	s6,0x15
    800033ca:	552b0b13          	addi	s6,s6,1362 # 80018918 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033ce:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800033d0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033d2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800033d4:	6c89                	lui	s9,0x2
    800033d6:	a831                	j	800033f2 <balloc+0x54>
    brelse(bp);
    800033d8:	854a                	mv	a0,s2
    800033da:	00000097          	auipc	ra,0x0
    800033de:	e32080e7          	jalr	-462(ra) # 8000320c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800033e2:	015c87bb          	addw	a5,s9,s5
    800033e6:	00078a9b          	sext.w	s5,a5
    800033ea:	004b2703          	lw	a4,4(s6)
    800033ee:	06eaf363          	bgeu	s5,a4,80003454 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800033f2:	41fad79b          	sraiw	a5,s5,0x1f
    800033f6:	0137d79b          	srliw	a5,a5,0x13
    800033fa:	015787bb          	addw	a5,a5,s5
    800033fe:	40d7d79b          	sraiw	a5,a5,0xd
    80003402:	01cb2583          	lw	a1,28(s6)
    80003406:	9dbd                	addw	a1,a1,a5
    80003408:	855e                	mv	a0,s7
    8000340a:	00000097          	auipc	ra,0x0
    8000340e:	cd2080e7          	jalr	-814(ra) # 800030dc <bread>
    80003412:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003414:	004b2503          	lw	a0,4(s6)
    80003418:	000a849b          	sext.w	s1,s5
    8000341c:	8662                	mv	a2,s8
    8000341e:	faa4fde3          	bgeu	s1,a0,800033d8 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003422:	41f6579b          	sraiw	a5,a2,0x1f
    80003426:	01d7d69b          	srliw	a3,a5,0x1d
    8000342a:	00c6873b          	addw	a4,a3,a2
    8000342e:	00777793          	andi	a5,a4,7
    80003432:	9f95                	subw	a5,a5,a3
    80003434:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003438:	4037571b          	sraiw	a4,a4,0x3
    8000343c:	00e906b3          	add	a3,s2,a4
    80003440:	0586c683          	lbu	a3,88(a3)
    80003444:	00d7f5b3          	and	a1,a5,a3
    80003448:	cd91                	beqz	a1,80003464 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000344a:	2605                	addiw	a2,a2,1
    8000344c:	2485                	addiw	s1,s1,1
    8000344e:	fd4618e3          	bne	a2,s4,8000341e <balloc+0x80>
    80003452:	b759                	j	800033d8 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003454:	00005517          	auipc	a0,0x5
    80003458:	12c50513          	addi	a0,a0,300 # 80008580 <syscalls+0x110>
    8000345c:	ffffd097          	auipc	ra,0xffffd
    80003460:	0e2080e7          	jalr	226(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003464:	974a                	add	a4,a4,s2
    80003466:	8fd5                	or	a5,a5,a3
    80003468:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000346c:	854a                	mv	a0,s2
    8000346e:	00001097          	auipc	ra,0x1
    80003472:	01a080e7          	jalr	26(ra) # 80004488 <log_write>
        brelse(bp);
    80003476:	854a                	mv	a0,s2
    80003478:	00000097          	auipc	ra,0x0
    8000347c:	d94080e7          	jalr	-620(ra) # 8000320c <brelse>
  bp = bread(dev, bno);
    80003480:	85a6                	mv	a1,s1
    80003482:	855e                	mv	a0,s7
    80003484:	00000097          	auipc	ra,0x0
    80003488:	c58080e7          	jalr	-936(ra) # 800030dc <bread>
    8000348c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000348e:	40000613          	li	a2,1024
    80003492:	4581                	li	a1,0
    80003494:	05850513          	addi	a0,a0,88
    80003498:	ffffe097          	auipc	ra,0xffffe
    8000349c:	848080e7          	jalr	-1976(ra) # 80000ce0 <memset>
  log_write(bp);
    800034a0:	854a                	mv	a0,s2
    800034a2:	00001097          	auipc	ra,0x1
    800034a6:	fe6080e7          	jalr	-26(ra) # 80004488 <log_write>
  brelse(bp);
    800034aa:	854a                	mv	a0,s2
    800034ac:	00000097          	auipc	ra,0x0
    800034b0:	d60080e7          	jalr	-672(ra) # 8000320c <brelse>
}
    800034b4:	8526                	mv	a0,s1
    800034b6:	60e6                	ld	ra,88(sp)
    800034b8:	6446                	ld	s0,80(sp)
    800034ba:	64a6                	ld	s1,72(sp)
    800034bc:	6906                	ld	s2,64(sp)
    800034be:	79e2                	ld	s3,56(sp)
    800034c0:	7a42                	ld	s4,48(sp)
    800034c2:	7aa2                	ld	s5,40(sp)
    800034c4:	7b02                	ld	s6,32(sp)
    800034c6:	6be2                	ld	s7,24(sp)
    800034c8:	6c42                	ld	s8,16(sp)
    800034ca:	6ca2                	ld	s9,8(sp)
    800034cc:	6125                	addi	sp,sp,96
    800034ce:	8082                	ret

00000000800034d0 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800034d0:	7179                	addi	sp,sp,-48
    800034d2:	f406                	sd	ra,40(sp)
    800034d4:	f022                	sd	s0,32(sp)
    800034d6:	ec26                	sd	s1,24(sp)
    800034d8:	e84a                	sd	s2,16(sp)
    800034da:	e44e                	sd	s3,8(sp)
    800034dc:	e052                	sd	s4,0(sp)
    800034de:	1800                	addi	s0,sp,48
    800034e0:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034e2:	47ad                	li	a5,11
    800034e4:	04b7fe63          	bgeu	a5,a1,80003540 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800034e8:	ff45849b          	addiw	s1,a1,-12
    800034ec:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800034f0:	0ff00793          	li	a5,255
    800034f4:	0ae7e363          	bltu	a5,a4,8000359a <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800034f8:	08052583          	lw	a1,128(a0)
    800034fc:	c5ad                	beqz	a1,80003566 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800034fe:	00092503          	lw	a0,0(s2)
    80003502:	00000097          	auipc	ra,0x0
    80003506:	bda080e7          	jalr	-1062(ra) # 800030dc <bread>
    8000350a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000350c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003510:	02049593          	slli	a1,s1,0x20
    80003514:	9181                	srli	a1,a1,0x20
    80003516:	058a                	slli	a1,a1,0x2
    80003518:	00b784b3          	add	s1,a5,a1
    8000351c:	0004a983          	lw	s3,0(s1)
    80003520:	04098d63          	beqz	s3,8000357a <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003524:	8552                	mv	a0,s4
    80003526:	00000097          	auipc	ra,0x0
    8000352a:	ce6080e7          	jalr	-794(ra) # 8000320c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000352e:	854e                	mv	a0,s3
    80003530:	70a2                	ld	ra,40(sp)
    80003532:	7402                	ld	s0,32(sp)
    80003534:	64e2                	ld	s1,24(sp)
    80003536:	6942                	ld	s2,16(sp)
    80003538:	69a2                	ld	s3,8(sp)
    8000353a:	6a02                	ld	s4,0(sp)
    8000353c:	6145                	addi	sp,sp,48
    8000353e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003540:	02059493          	slli	s1,a1,0x20
    80003544:	9081                	srli	s1,s1,0x20
    80003546:	048a                	slli	s1,s1,0x2
    80003548:	94aa                	add	s1,s1,a0
    8000354a:	0504a983          	lw	s3,80(s1)
    8000354e:	fe0990e3          	bnez	s3,8000352e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003552:	4108                	lw	a0,0(a0)
    80003554:	00000097          	auipc	ra,0x0
    80003558:	e4a080e7          	jalr	-438(ra) # 8000339e <balloc>
    8000355c:	0005099b          	sext.w	s3,a0
    80003560:	0534a823          	sw	s3,80(s1)
    80003564:	b7e9                	j	8000352e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003566:	4108                	lw	a0,0(a0)
    80003568:	00000097          	auipc	ra,0x0
    8000356c:	e36080e7          	jalr	-458(ra) # 8000339e <balloc>
    80003570:	0005059b          	sext.w	a1,a0
    80003574:	08b92023          	sw	a1,128(s2)
    80003578:	b759                	j	800034fe <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000357a:	00092503          	lw	a0,0(s2)
    8000357e:	00000097          	auipc	ra,0x0
    80003582:	e20080e7          	jalr	-480(ra) # 8000339e <balloc>
    80003586:	0005099b          	sext.w	s3,a0
    8000358a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000358e:	8552                	mv	a0,s4
    80003590:	00001097          	auipc	ra,0x1
    80003594:	ef8080e7          	jalr	-264(ra) # 80004488 <log_write>
    80003598:	b771                	j	80003524 <bmap+0x54>
  panic("bmap: out of range");
    8000359a:	00005517          	auipc	a0,0x5
    8000359e:	ffe50513          	addi	a0,a0,-2 # 80008598 <syscalls+0x128>
    800035a2:	ffffd097          	auipc	ra,0xffffd
    800035a6:	f9c080e7          	jalr	-100(ra) # 8000053e <panic>

00000000800035aa <iget>:
{
    800035aa:	7179                	addi	sp,sp,-48
    800035ac:	f406                	sd	ra,40(sp)
    800035ae:	f022                	sd	s0,32(sp)
    800035b0:	ec26                	sd	s1,24(sp)
    800035b2:	e84a                	sd	s2,16(sp)
    800035b4:	e44e                	sd	s3,8(sp)
    800035b6:	e052                	sd	s4,0(sp)
    800035b8:	1800                	addi	s0,sp,48
    800035ba:	89aa                	mv	s3,a0
    800035bc:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800035be:	00015517          	auipc	a0,0x15
    800035c2:	37a50513          	addi	a0,a0,890 # 80018938 <itable>
    800035c6:	ffffd097          	auipc	ra,0xffffd
    800035ca:	61e080e7          	jalr	1566(ra) # 80000be4 <acquire>
  empty = 0;
    800035ce:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035d0:	00015497          	auipc	s1,0x15
    800035d4:	38048493          	addi	s1,s1,896 # 80018950 <itable+0x18>
    800035d8:	00017697          	auipc	a3,0x17
    800035dc:	e0868693          	addi	a3,a3,-504 # 8001a3e0 <log>
    800035e0:	a039                	j	800035ee <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035e2:	02090b63          	beqz	s2,80003618 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035e6:	08848493          	addi	s1,s1,136
    800035ea:	02d48a63          	beq	s1,a3,8000361e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800035ee:	449c                	lw	a5,8(s1)
    800035f0:	fef059e3          	blez	a5,800035e2 <iget+0x38>
    800035f4:	4098                	lw	a4,0(s1)
    800035f6:	ff3716e3          	bne	a4,s3,800035e2 <iget+0x38>
    800035fa:	40d8                	lw	a4,4(s1)
    800035fc:	ff4713e3          	bne	a4,s4,800035e2 <iget+0x38>
      ip->ref++;
    80003600:	2785                	addiw	a5,a5,1
    80003602:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003604:	00015517          	auipc	a0,0x15
    80003608:	33450513          	addi	a0,a0,820 # 80018938 <itable>
    8000360c:	ffffd097          	auipc	ra,0xffffd
    80003610:	68c080e7          	jalr	1676(ra) # 80000c98 <release>
      return ip;
    80003614:	8926                	mv	s2,s1
    80003616:	a03d                	j	80003644 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003618:	f7f9                	bnez	a5,800035e6 <iget+0x3c>
    8000361a:	8926                	mv	s2,s1
    8000361c:	b7e9                	j	800035e6 <iget+0x3c>
  if(empty == 0)
    8000361e:	02090c63          	beqz	s2,80003656 <iget+0xac>
  ip->dev = dev;
    80003622:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003626:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000362a:	4785                	li	a5,1
    8000362c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003630:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003634:	00015517          	auipc	a0,0x15
    80003638:	30450513          	addi	a0,a0,772 # 80018938 <itable>
    8000363c:	ffffd097          	auipc	ra,0xffffd
    80003640:	65c080e7          	jalr	1628(ra) # 80000c98 <release>
}
    80003644:	854a                	mv	a0,s2
    80003646:	70a2                	ld	ra,40(sp)
    80003648:	7402                	ld	s0,32(sp)
    8000364a:	64e2                	ld	s1,24(sp)
    8000364c:	6942                	ld	s2,16(sp)
    8000364e:	69a2                	ld	s3,8(sp)
    80003650:	6a02                	ld	s4,0(sp)
    80003652:	6145                	addi	sp,sp,48
    80003654:	8082                	ret
    panic("iget: no inodes");
    80003656:	00005517          	auipc	a0,0x5
    8000365a:	f5a50513          	addi	a0,a0,-166 # 800085b0 <syscalls+0x140>
    8000365e:	ffffd097          	auipc	ra,0xffffd
    80003662:	ee0080e7          	jalr	-288(ra) # 8000053e <panic>

0000000080003666 <fsinit>:
fsinit(int dev) {
    80003666:	7179                	addi	sp,sp,-48
    80003668:	f406                	sd	ra,40(sp)
    8000366a:	f022                	sd	s0,32(sp)
    8000366c:	ec26                	sd	s1,24(sp)
    8000366e:	e84a                	sd	s2,16(sp)
    80003670:	e44e                	sd	s3,8(sp)
    80003672:	1800                	addi	s0,sp,48
    80003674:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003676:	4585                	li	a1,1
    80003678:	00000097          	auipc	ra,0x0
    8000367c:	a64080e7          	jalr	-1436(ra) # 800030dc <bread>
    80003680:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003682:	00015997          	auipc	s3,0x15
    80003686:	29698993          	addi	s3,s3,662 # 80018918 <sb>
    8000368a:	02000613          	li	a2,32
    8000368e:	05850593          	addi	a1,a0,88
    80003692:	854e                	mv	a0,s3
    80003694:	ffffd097          	auipc	ra,0xffffd
    80003698:	6ac080e7          	jalr	1708(ra) # 80000d40 <memmove>
  brelse(bp);
    8000369c:	8526                	mv	a0,s1
    8000369e:	00000097          	auipc	ra,0x0
    800036a2:	b6e080e7          	jalr	-1170(ra) # 8000320c <brelse>
  if(sb.magic != FSMAGIC)
    800036a6:	0009a703          	lw	a4,0(s3)
    800036aa:	102037b7          	lui	a5,0x10203
    800036ae:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800036b2:	02f71263          	bne	a4,a5,800036d6 <fsinit+0x70>
  initlog(dev, &sb);
    800036b6:	00015597          	auipc	a1,0x15
    800036ba:	26258593          	addi	a1,a1,610 # 80018918 <sb>
    800036be:	854a                	mv	a0,s2
    800036c0:	00001097          	auipc	ra,0x1
    800036c4:	b4c080e7          	jalr	-1204(ra) # 8000420c <initlog>
}
    800036c8:	70a2                	ld	ra,40(sp)
    800036ca:	7402                	ld	s0,32(sp)
    800036cc:	64e2                	ld	s1,24(sp)
    800036ce:	6942                	ld	s2,16(sp)
    800036d0:	69a2                	ld	s3,8(sp)
    800036d2:	6145                	addi	sp,sp,48
    800036d4:	8082                	ret
    panic("invalid file system");
    800036d6:	00005517          	auipc	a0,0x5
    800036da:	eea50513          	addi	a0,a0,-278 # 800085c0 <syscalls+0x150>
    800036de:	ffffd097          	auipc	ra,0xffffd
    800036e2:	e60080e7          	jalr	-416(ra) # 8000053e <panic>

00000000800036e6 <iinit>:
{
    800036e6:	7179                	addi	sp,sp,-48
    800036e8:	f406                	sd	ra,40(sp)
    800036ea:	f022                	sd	s0,32(sp)
    800036ec:	ec26                	sd	s1,24(sp)
    800036ee:	e84a                	sd	s2,16(sp)
    800036f0:	e44e                	sd	s3,8(sp)
    800036f2:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800036f4:	00005597          	auipc	a1,0x5
    800036f8:	ee458593          	addi	a1,a1,-284 # 800085d8 <syscalls+0x168>
    800036fc:	00015517          	auipc	a0,0x15
    80003700:	23c50513          	addi	a0,a0,572 # 80018938 <itable>
    80003704:	ffffd097          	auipc	ra,0xffffd
    80003708:	450080e7          	jalr	1104(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000370c:	00015497          	auipc	s1,0x15
    80003710:	25448493          	addi	s1,s1,596 # 80018960 <itable+0x28>
    80003714:	00017997          	auipc	s3,0x17
    80003718:	cdc98993          	addi	s3,s3,-804 # 8001a3f0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000371c:	00005917          	auipc	s2,0x5
    80003720:	ec490913          	addi	s2,s2,-316 # 800085e0 <syscalls+0x170>
    80003724:	85ca                	mv	a1,s2
    80003726:	8526                	mv	a0,s1
    80003728:	00001097          	auipc	ra,0x1
    8000372c:	e46080e7          	jalr	-442(ra) # 8000456e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003730:	08848493          	addi	s1,s1,136
    80003734:	ff3498e3          	bne	s1,s3,80003724 <iinit+0x3e>
}
    80003738:	70a2                	ld	ra,40(sp)
    8000373a:	7402                	ld	s0,32(sp)
    8000373c:	64e2                	ld	s1,24(sp)
    8000373e:	6942                	ld	s2,16(sp)
    80003740:	69a2                	ld	s3,8(sp)
    80003742:	6145                	addi	sp,sp,48
    80003744:	8082                	ret

0000000080003746 <ialloc>:
{
    80003746:	715d                	addi	sp,sp,-80
    80003748:	e486                	sd	ra,72(sp)
    8000374a:	e0a2                	sd	s0,64(sp)
    8000374c:	fc26                	sd	s1,56(sp)
    8000374e:	f84a                	sd	s2,48(sp)
    80003750:	f44e                	sd	s3,40(sp)
    80003752:	f052                	sd	s4,32(sp)
    80003754:	ec56                	sd	s5,24(sp)
    80003756:	e85a                	sd	s6,16(sp)
    80003758:	e45e                	sd	s7,8(sp)
    8000375a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000375c:	00015717          	auipc	a4,0x15
    80003760:	1c872703          	lw	a4,456(a4) # 80018924 <sb+0xc>
    80003764:	4785                	li	a5,1
    80003766:	04e7fa63          	bgeu	a5,a4,800037ba <ialloc+0x74>
    8000376a:	8aaa                	mv	s5,a0
    8000376c:	8bae                	mv	s7,a1
    8000376e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003770:	00015a17          	auipc	s4,0x15
    80003774:	1a8a0a13          	addi	s4,s4,424 # 80018918 <sb>
    80003778:	00048b1b          	sext.w	s6,s1
    8000377c:	0044d593          	srli	a1,s1,0x4
    80003780:	018a2783          	lw	a5,24(s4)
    80003784:	9dbd                	addw	a1,a1,a5
    80003786:	8556                	mv	a0,s5
    80003788:	00000097          	auipc	ra,0x0
    8000378c:	954080e7          	jalr	-1708(ra) # 800030dc <bread>
    80003790:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003792:	05850993          	addi	s3,a0,88
    80003796:	00f4f793          	andi	a5,s1,15
    8000379a:	079a                	slli	a5,a5,0x6
    8000379c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000379e:	00099783          	lh	a5,0(s3)
    800037a2:	c785                	beqz	a5,800037ca <ialloc+0x84>
    brelse(bp);
    800037a4:	00000097          	auipc	ra,0x0
    800037a8:	a68080e7          	jalr	-1432(ra) # 8000320c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800037ac:	0485                	addi	s1,s1,1
    800037ae:	00ca2703          	lw	a4,12(s4)
    800037b2:	0004879b          	sext.w	a5,s1
    800037b6:	fce7e1e3          	bltu	a5,a4,80003778 <ialloc+0x32>
  panic("ialloc: no inodes");
    800037ba:	00005517          	auipc	a0,0x5
    800037be:	e2e50513          	addi	a0,a0,-466 # 800085e8 <syscalls+0x178>
    800037c2:	ffffd097          	auipc	ra,0xffffd
    800037c6:	d7c080e7          	jalr	-644(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800037ca:	04000613          	li	a2,64
    800037ce:	4581                	li	a1,0
    800037d0:	854e                	mv	a0,s3
    800037d2:	ffffd097          	auipc	ra,0xffffd
    800037d6:	50e080e7          	jalr	1294(ra) # 80000ce0 <memset>
      dip->type = type;
    800037da:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800037de:	854a                	mv	a0,s2
    800037e0:	00001097          	auipc	ra,0x1
    800037e4:	ca8080e7          	jalr	-856(ra) # 80004488 <log_write>
      brelse(bp);
    800037e8:	854a                	mv	a0,s2
    800037ea:	00000097          	auipc	ra,0x0
    800037ee:	a22080e7          	jalr	-1502(ra) # 8000320c <brelse>
      return iget(dev, inum);
    800037f2:	85da                	mv	a1,s6
    800037f4:	8556                	mv	a0,s5
    800037f6:	00000097          	auipc	ra,0x0
    800037fa:	db4080e7          	jalr	-588(ra) # 800035aa <iget>
}
    800037fe:	60a6                	ld	ra,72(sp)
    80003800:	6406                	ld	s0,64(sp)
    80003802:	74e2                	ld	s1,56(sp)
    80003804:	7942                	ld	s2,48(sp)
    80003806:	79a2                	ld	s3,40(sp)
    80003808:	7a02                	ld	s4,32(sp)
    8000380a:	6ae2                	ld	s5,24(sp)
    8000380c:	6b42                	ld	s6,16(sp)
    8000380e:	6ba2                	ld	s7,8(sp)
    80003810:	6161                	addi	sp,sp,80
    80003812:	8082                	ret

0000000080003814 <iupdate>:
{
    80003814:	1101                	addi	sp,sp,-32
    80003816:	ec06                	sd	ra,24(sp)
    80003818:	e822                	sd	s0,16(sp)
    8000381a:	e426                	sd	s1,8(sp)
    8000381c:	e04a                	sd	s2,0(sp)
    8000381e:	1000                	addi	s0,sp,32
    80003820:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003822:	415c                	lw	a5,4(a0)
    80003824:	0047d79b          	srliw	a5,a5,0x4
    80003828:	00015597          	auipc	a1,0x15
    8000382c:	1085a583          	lw	a1,264(a1) # 80018930 <sb+0x18>
    80003830:	9dbd                	addw	a1,a1,a5
    80003832:	4108                	lw	a0,0(a0)
    80003834:	00000097          	auipc	ra,0x0
    80003838:	8a8080e7          	jalr	-1880(ra) # 800030dc <bread>
    8000383c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000383e:	05850793          	addi	a5,a0,88
    80003842:	40c8                	lw	a0,4(s1)
    80003844:	893d                	andi	a0,a0,15
    80003846:	051a                	slli	a0,a0,0x6
    80003848:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000384a:	04449703          	lh	a4,68(s1)
    8000384e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003852:	04649703          	lh	a4,70(s1)
    80003856:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000385a:	04849703          	lh	a4,72(s1)
    8000385e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003862:	04a49703          	lh	a4,74(s1)
    80003866:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000386a:	44f8                	lw	a4,76(s1)
    8000386c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000386e:	03400613          	li	a2,52
    80003872:	05048593          	addi	a1,s1,80
    80003876:	0531                	addi	a0,a0,12
    80003878:	ffffd097          	auipc	ra,0xffffd
    8000387c:	4c8080e7          	jalr	1224(ra) # 80000d40 <memmove>
  log_write(bp);
    80003880:	854a                	mv	a0,s2
    80003882:	00001097          	auipc	ra,0x1
    80003886:	c06080e7          	jalr	-1018(ra) # 80004488 <log_write>
  brelse(bp);
    8000388a:	854a                	mv	a0,s2
    8000388c:	00000097          	auipc	ra,0x0
    80003890:	980080e7          	jalr	-1664(ra) # 8000320c <brelse>
}
    80003894:	60e2                	ld	ra,24(sp)
    80003896:	6442                	ld	s0,16(sp)
    80003898:	64a2                	ld	s1,8(sp)
    8000389a:	6902                	ld	s2,0(sp)
    8000389c:	6105                	addi	sp,sp,32
    8000389e:	8082                	ret

00000000800038a0 <idup>:
{
    800038a0:	1101                	addi	sp,sp,-32
    800038a2:	ec06                	sd	ra,24(sp)
    800038a4:	e822                	sd	s0,16(sp)
    800038a6:	e426                	sd	s1,8(sp)
    800038a8:	1000                	addi	s0,sp,32
    800038aa:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038ac:	00015517          	auipc	a0,0x15
    800038b0:	08c50513          	addi	a0,a0,140 # 80018938 <itable>
    800038b4:	ffffd097          	auipc	ra,0xffffd
    800038b8:	330080e7          	jalr	816(ra) # 80000be4 <acquire>
  ip->ref++;
    800038bc:	449c                	lw	a5,8(s1)
    800038be:	2785                	addiw	a5,a5,1
    800038c0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038c2:	00015517          	auipc	a0,0x15
    800038c6:	07650513          	addi	a0,a0,118 # 80018938 <itable>
    800038ca:	ffffd097          	auipc	ra,0xffffd
    800038ce:	3ce080e7          	jalr	974(ra) # 80000c98 <release>
}
    800038d2:	8526                	mv	a0,s1
    800038d4:	60e2                	ld	ra,24(sp)
    800038d6:	6442                	ld	s0,16(sp)
    800038d8:	64a2                	ld	s1,8(sp)
    800038da:	6105                	addi	sp,sp,32
    800038dc:	8082                	ret

00000000800038de <ilock>:
{
    800038de:	1101                	addi	sp,sp,-32
    800038e0:	ec06                	sd	ra,24(sp)
    800038e2:	e822                	sd	s0,16(sp)
    800038e4:	e426                	sd	s1,8(sp)
    800038e6:	e04a                	sd	s2,0(sp)
    800038e8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038ea:	c115                	beqz	a0,8000390e <ilock+0x30>
    800038ec:	84aa                	mv	s1,a0
    800038ee:	451c                	lw	a5,8(a0)
    800038f0:	00f05f63          	blez	a5,8000390e <ilock+0x30>
  acquiresleep(&ip->lock);
    800038f4:	0541                	addi	a0,a0,16
    800038f6:	00001097          	auipc	ra,0x1
    800038fa:	cb2080e7          	jalr	-846(ra) # 800045a8 <acquiresleep>
  if(ip->valid == 0){
    800038fe:	40bc                	lw	a5,64(s1)
    80003900:	cf99                	beqz	a5,8000391e <ilock+0x40>
}
    80003902:	60e2                	ld	ra,24(sp)
    80003904:	6442                	ld	s0,16(sp)
    80003906:	64a2                	ld	s1,8(sp)
    80003908:	6902                	ld	s2,0(sp)
    8000390a:	6105                	addi	sp,sp,32
    8000390c:	8082                	ret
    panic("ilock");
    8000390e:	00005517          	auipc	a0,0x5
    80003912:	cf250513          	addi	a0,a0,-782 # 80008600 <syscalls+0x190>
    80003916:	ffffd097          	auipc	ra,0xffffd
    8000391a:	c28080e7          	jalr	-984(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000391e:	40dc                	lw	a5,4(s1)
    80003920:	0047d79b          	srliw	a5,a5,0x4
    80003924:	00015597          	auipc	a1,0x15
    80003928:	00c5a583          	lw	a1,12(a1) # 80018930 <sb+0x18>
    8000392c:	9dbd                	addw	a1,a1,a5
    8000392e:	4088                	lw	a0,0(s1)
    80003930:	fffff097          	auipc	ra,0xfffff
    80003934:	7ac080e7          	jalr	1964(ra) # 800030dc <bread>
    80003938:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000393a:	05850593          	addi	a1,a0,88
    8000393e:	40dc                	lw	a5,4(s1)
    80003940:	8bbd                	andi	a5,a5,15
    80003942:	079a                	slli	a5,a5,0x6
    80003944:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003946:	00059783          	lh	a5,0(a1)
    8000394a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000394e:	00259783          	lh	a5,2(a1)
    80003952:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003956:	00459783          	lh	a5,4(a1)
    8000395a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000395e:	00659783          	lh	a5,6(a1)
    80003962:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003966:	459c                	lw	a5,8(a1)
    80003968:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000396a:	03400613          	li	a2,52
    8000396e:	05b1                	addi	a1,a1,12
    80003970:	05048513          	addi	a0,s1,80
    80003974:	ffffd097          	auipc	ra,0xffffd
    80003978:	3cc080e7          	jalr	972(ra) # 80000d40 <memmove>
    brelse(bp);
    8000397c:	854a                	mv	a0,s2
    8000397e:	00000097          	auipc	ra,0x0
    80003982:	88e080e7          	jalr	-1906(ra) # 8000320c <brelse>
    ip->valid = 1;
    80003986:	4785                	li	a5,1
    80003988:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000398a:	04449783          	lh	a5,68(s1)
    8000398e:	fbb5                	bnez	a5,80003902 <ilock+0x24>
      panic("ilock: no type");
    80003990:	00005517          	auipc	a0,0x5
    80003994:	c7850513          	addi	a0,a0,-904 # 80008608 <syscalls+0x198>
    80003998:	ffffd097          	auipc	ra,0xffffd
    8000399c:	ba6080e7          	jalr	-1114(ra) # 8000053e <panic>

00000000800039a0 <iunlock>:
{
    800039a0:	1101                	addi	sp,sp,-32
    800039a2:	ec06                	sd	ra,24(sp)
    800039a4:	e822                	sd	s0,16(sp)
    800039a6:	e426                	sd	s1,8(sp)
    800039a8:	e04a                	sd	s2,0(sp)
    800039aa:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800039ac:	c905                	beqz	a0,800039dc <iunlock+0x3c>
    800039ae:	84aa                	mv	s1,a0
    800039b0:	01050913          	addi	s2,a0,16
    800039b4:	854a                	mv	a0,s2
    800039b6:	00001097          	auipc	ra,0x1
    800039ba:	c8c080e7          	jalr	-884(ra) # 80004642 <holdingsleep>
    800039be:	cd19                	beqz	a0,800039dc <iunlock+0x3c>
    800039c0:	449c                	lw	a5,8(s1)
    800039c2:	00f05d63          	blez	a5,800039dc <iunlock+0x3c>
  releasesleep(&ip->lock);
    800039c6:	854a                	mv	a0,s2
    800039c8:	00001097          	auipc	ra,0x1
    800039cc:	c36080e7          	jalr	-970(ra) # 800045fe <releasesleep>
}
    800039d0:	60e2                	ld	ra,24(sp)
    800039d2:	6442                	ld	s0,16(sp)
    800039d4:	64a2                	ld	s1,8(sp)
    800039d6:	6902                	ld	s2,0(sp)
    800039d8:	6105                	addi	sp,sp,32
    800039da:	8082                	ret
    panic("iunlock");
    800039dc:	00005517          	auipc	a0,0x5
    800039e0:	c3c50513          	addi	a0,a0,-964 # 80008618 <syscalls+0x1a8>
    800039e4:	ffffd097          	auipc	ra,0xffffd
    800039e8:	b5a080e7          	jalr	-1190(ra) # 8000053e <panic>

00000000800039ec <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800039ec:	7179                	addi	sp,sp,-48
    800039ee:	f406                	sd	ra,40(sp)
    800039f0:	f022                	sd	s0,32(sp)
    800039f2:	ec26                	sd	s1,24(sp)
    800039f4:	e84a                	sd	s2,16(sp)
    800039f6:	e44e                	sd	s3,8(sp)
    800039f8:	e052                	sd	s4,0(sp)
    800039fa:	1800                	addi	s0,sp,48
    800039fc:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800039fe:	05050493          	addi	s1,a0,80
    80003a02:	08050913          	addi	s2,a0,128
    80003a06:	a021                	j	80003a0e <itrunc+0x22>
    80003a08:	0491                	addi	s1,s1,4
    80003a0a:	01248d63          	beq	s1,s2,80003a24 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a0e:	408c                	lw	a1,0(s1)
    80003a10:	dde5                	beqz	a1,80003a08 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a12:	0009a503          	lw	a0,0(s3)
    80003a16:	00000097          	auipc	ra,0x0
    80003a1a:	90c080e7          	jalr	-1780(ra) # 80003322 <bfree>
      ip->addrs[i] = 0;
    80003a1e:	0004a023          	sw	zero,0(s1)
    80003a22:	b7dd                	j	80003a08 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a24:	0809a583          	lw	a1,128(s3)
    80003a28:	e185                	bnez	a1,80003a48 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a2a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a2e:	854e                	mv	a0,s3
    80003a30:	00000097          	auipc	ra,0x0
    80003a34:	de4080e7          	jalr	-540(ra) # 80003814 <iupdate>
}
    80003a38:	70a2                	ld	ra,40(sp)
    80003a3a:	7402                	ld	s0,32(sp)
    80003a3c:	64e2                	ld	s1,24(sp)
    80003a3e:	6942                	ld	s2,16(sp)
    80003a40:	69a2                	ld	s3,8(sp)
    80003a42:	6a02                	ld	s4,0(sp)
    80003a44:	6145                	addi	sp,sp,48
    80003a46:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a48:	0009a503          	lw	a0,0(s3)
    80003a4c:	fffff097          	auipc	ra,0xfffff
    80003a50:	690080e7          	jalr	1680(ra) # 800030dc <bread>
    80003a54:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a56:	05850493          	addi	s1,a0,88
    80003a5a:	45850913          	addi	s2,a0,1112
    80003a5e:	a811                	j	80003a72 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003a60:	0009a503          	lw	a0,0(s3)
    80003a64:	00000097          	auipc	ra,0x0
    80003a68:	8be080e7          	jalr	-1858(ra) # 80003322 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003a6c:	0491                	addi	s1,s1,4
    80003a6e:	01248563          	beq	s1,s2,80003a78 <itrunc+0x8c>
      if(a[j])
    80003a72:	408c                	lw	a1,0(s1)
    80003a74:	dde5                	beqz	a1,80003a6c <itrunc+0x80>
    80003a76:	b7ed                	j	80003a60 <itrunc+0x74>
    brelse(bp);
    80003a78:	8552                	mv	a0,s4
    80003a7a:	fffff097          	auipc	ra,0xfffff
    80003a7e:	792080e7          	jalr	1938(ra) # 8000320c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a82:	0809a583          	lw	a1,128(s3)
    80003a86:	0009a503          	lw	a0,0(s3)
    80003a8a:	00000097          	auipc	ra,0x0
    80003a8e:	898080e7          	jalr	-1896(ra) # 80003322 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a92:	0809a023          	sw	zero,128(s3)
    80003a96:	bf51                	j	80003a2a <itrunc+0x3e>

0000000080003a98 <iput>:
{
    80003a98:	1101                	addi	sp,sp,-32
    80003a9a:	ec06                	sd	ra,24(sp)
    80003a9c:	e822                	sd	s0,16(sp)
    80003a9e:	e426                	sd	s1,8(sp)
    80003aa0:	e04a                	sd	s2,0(sp)
    80003aa2:	1000                	addi	s0,sp,32
    80003aa4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003aa6:	00015517          	auipc	a0,0x15
    80003aaa:	e9250513          	addi	a0,a0,-366 # 80018938 <itable>
    80003aae:	ffffd097          	auipc	ra,0xffffd
    80003ab2:	136080e7          	jalr	310(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ab6:	4498                	lw	a4,8(s1)
    80003ab8:	4785                	li	a5,1
    80003aba:	02f70363          	beq	a4,a5,80003ae0 <iput+0x48>
  ip->ref--;
    80003abe:	449c                	lw	a5,8(s1)
    80003ac0:	37fd                	addiw	a5,a5,-1
    80003ac2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ac4:	00015517          	auipc	a0,0x15
    80003ac8:	e7450513          	addi	a0,a0,-396 # 80018938 <itable>
    80003acc:	ffffd097          	auipc	ra,0xffffd
    80003ad0:	1cc080e7          	jalr	460(ra) # 80000c98 <release>
}
    80003ad4:	60e2                	ld	ra,24(sp)
    80003ad6:	6442                	ld	s0,16(sp)
    80003ad8:	64a2                	ld	s1,8(sp)
    80003ada:	6902                	ld	s2,0(sp)
    80003adc:	6105                	addi	sp,sp,32
    80003ade:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ae0:	40bc                	lw	a5,64(s1)
    80003ae2:	dff1                	beqz	a5,80003abe <iput+0x26>
    80003ae4:	04a49783          	lh	a5,74(s1)
    80003ae8:	fbf9                	bnez	a5,80003abe <iput+0x26>
    acquiresleep(&ip->lock);
    80003aea:	01048913          	addi	s2,s1,16
    80003aee:	854a                	mv	a0,s2
    80003af0:	00001097          	auipc	ra,0x1
    80003af4:	ab8080e7          	jalr	-1352(ra) # 800045a8 <acquiresleep>
    release(&itable.lock);
    80003af8:	00015517          	auipc	a0,0x15
    80003afc:	e4050513          	addi	a0,a0,-448 # 80018938 <itable>
    80003b00:	ffffd097          	auipc	ra,0xffffd
    80003b04:	198080e7          	jalr	408(ra) # 80000c98 <release>
    itrunc(ip);
    80003b08:	8526                	mv	a0,s1
    80003b0a:	00000097          	auipc	ra,0x0
    80003b0e:	ee2080e7          	jalr	-286(ra) # 800039ec <itrunc>
    ip->type = 0;
    80003b12:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b16:	8526                	mv	a0,s1
    80003b18:	00000097          	auipc	ra,0x0
    80003b1c:	cfc080e7          	jalr	-772(ra) # 80003814 <iupdate>
    ip->valid = 0;
    80003b20:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b24:	854a                	mv	a0,s2
    80003b26:	00001097          	auipc	ra,0x1
    80003b2a:	ad8080e7          	jalr	-1320(ra) # 800045fe <releasesleep>
    acquire(&itable.lock);
    80003b2e:	00015517          	auipc	a0,0x15
    80003b32:	e0a50513          	addi	a0,a0,-502 # 80018938 <itable>
    80003b36:	ffffd097          	auipc	ra,0xffffd
    80003b3a:	0ae080e7          	jalr	174(ra) # 80000be4 <acquire>
    80003b3e:	b741                	j	80003abe <iput+0x26>

0000000080003b40 <iunlockput>:
{
    80003b40:	1101                	addi	sp,sp,-32
    80003b42:	ec06                	sd	ra,24(sp)
    80003b44:	e822                	sd	s0,16(sp)
    80003b46:	e426                	sd	s1,8(sp)
    80003b48:	1000                	addi	s0,sp,32
    80003b4a:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b4c:	00000097          	auipc	ra,0x0
    80003b50:	e54080e7          	jalr	-428(ra) # 800039a0 <iunlock>
  iput(ip);
    80003b54:	8526                	mv	a0,s1
    80003b56:	00000097          	auipc	ra,0x0
    80003b5a:	f42080e7          	jalr	-190(ra) # 80003a98 <iput>
}
    80003b5e:	60e2                	ld	ra,24(sp)
    80003b60:	6442                	ld	s0,16(sp)
    80003b62:	64a2                	ld	s1,8(sp)
    80003b64:	6105                	addi	sp,sp,32
    80003b66:	8082                	ret

0000000080003b68 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b68:	1141                	addi	sp,sp,-16
    80003b6a:	e422                	sd	s0,8(sp)
    80003b6c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b6e:	411c                	lw	a5,0(a0)
    80003b70:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b72:	415c                	lw	a5,4(a0)
    80003b74:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b76:	04451783          	lh	a5,68(a0)
    80003b7a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b7e:	04a51783          	lh	a5,74(a0)
    80003b82:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b86:	04c56783          	lwu	a5,76(a0)
    80003b8a:	e99c                	sd	a5,16(a1)
}
    80003b8c:	6422                	ld	s0,8(sp)
    80003b8e:	0141                	addi	sp,sp,16
    80003b90:	8082                	ret

0000000080003b92 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b92:	457c                	lw	a5,76(a0)
    80003b94:	0ed7e963          	bltu	a5,a3,80003c86 <readi+0xf4>
{
    80003b98:	7159                	addi	sp,sp,-112
    80003b9a:	f486                	sd	ra,104(sp)
    80003b9c:	f0a2                	sd	s0,96(sp)
    80003b9e:	eca6                	sd	s1,88(sp)
    80003ba0:	e8ca                	sd	s2,80(sp)
    80003ba2:	e4ce                	sd	s3,72(sp)
    80003ba4:	e0d2                	sd	s4,64(sp)
    80003ba6:	fc56                	sd	s5,56(sp)
    80003ba8:	f85a                	sd	s6,48(sp)
    80003baa:	f45e                	sd	s7,40(sp)
    80003bac:	f062                	sd	s8,32(sp)
    80003bae:	ec66                	sd	s9,24(sp)
    80003bb0:	e86a                	sd	s10,16(sp)
    80003bb2:	e46e                	sd	s11,8(sp)
    80003bb4:	1880                	addi	s0,sp,112
    80003bb6:	8baa                	mv	s7,a0
    80003bb8:	8c2e                	mv	s8,a1
    80003bba:	8ab2                	mv	s5,a2
    80003bbc:	84b6                	mv	s1,a3
    80003bbe:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003bc0:	9f35                	addw	a4,a4,a3
    return 0;
    80003bc2:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003bc4:	0ad76063          	bltu	a4,a3,80003c64 <readi+0xd2>
  if(off + n > ip->size)
    80003bc8:	00e7f463          	bgeu	a5,a4,80003bd0 <readi+0x3e>
    n = ip->size - off;
    80003bcc:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bd0:	0a0b0963          	beqz	s6,80003c82 <readi+0xf0>
    80003bd4:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bd6:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003bda:	5cfd                	li	s9,-1
    80003bdc:	a82d                	j	80003c16 <readi+0x84>
    80003bde:	020a1d93          	slli	s11,s4,0x20
    80003be2:	020ddd93          	srli	s11,s11,0x20
    80003be6:	05890613          	addi	a2,s2,88
    80003bea:	86ee                	mv	a3,s11
    80003bec:	963a                	add	a2,a2,a4
    80003bee:	85d6                	mv	a1,s5
    80003bf0:	8562                	mv	a0,s8
    80003bf2:	fffff097          	auipc	ra,0xfffff
    80003bf6:	aae080e7          	jalr	-1362(ra) # 800026a0 <either_copyout>
    80003bfa:	05950d63          	beq	a0,s9,80003c54 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003bfe:	854a                	mv	a0,s2
    80003c00:	fffff097          	auipc	ra,0xfffff
    80003c04:	60c080e7          	jalr	1548(ra) # 8000320c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c08:	013a09bb          	addw	s3,s4,s3
    80003c0c:	009a04bb          	addw	s1,s4,s1
    80003c10:	9aee                	add	s5,s5,s11
    80003c12:	0569f763          	bgeu	s3,s6,80003c60 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c16:	000ba903          	lw	s2,0(s7)
    80003c1a:	00a4d59b          	srliw	a1,s1,0xa
    80003c1e:	855e                	mv	a0,s7
    80003c20:	00000097          	auipc	ra,0x0
    80003c24:	8b0080e7          	jalr	-1872(ra) # 800034d0 <bmap>
    80003c28:	0005059b          	sext.w	a1,a0
    80003c2c:	854a                	mv	a0,s2
    80003c2e:	fffff097          	auipc	ra,0xfffff
    80003c32:	4ae080e7          	jalr	1198(ra) # 800030dc <bread>
    80003c36:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c38:	3ff4f713          	andi	a4,s1,1023
    80003c3c:	40ed07bb          	subw	a5,s10,a4
    80003c40:	413b06bb          	subw	a3,s6,s3
    80003c44:	8a3e                	mv	s4,a5
    80003c46:	2781                	sext.w	a5,a5
    80003c48:	0006861b          	sext.w	a2,a3
    80003c4c:	f8f679e3          	bgeu	a2,a5,80003bde <readi+0x4c>
    80003c50:	8a36                	mv	s4,a3
    80003c52:	b771                	j	80003bde <readi+0x4c>
      brelse(bp);
    80003c54:	854a                	mv	a0,s2
    80003c56:	fffff097          	auipc	ra,0xfffff
    80003c5a:	5b6080e7          	jalr	1462(ra) # 8000320c <brelse>
      tot = -1;
    80003c5e:	59fd                	li	s3,-1
  }
  return tot;
    80003c60:	0009851b          	sext.w	a0,s3
}
    80003c64:	70a6                	ld	ra,104(sp)
    80003c66:	7406                	ld	s0,96(sp)
    80003c68:	64e6                	ld	s1,88(sp)
    80003c6a:	6946                	ld	s2,80(sp)
    80003c6c:	69a6                	ld	s3,72(sp)
    80003c6e:	6a06                	ld	s4,64(sp)
    80003c70:	7ae2                	ld	s5,56(sp)
    80003c72:	7b42                	ld	s6,48(sp)
    80003c74:	7ba2                	ld	s7,40(sp)
    80003c76:	7c02                	ld	s8,32(sp)
    80003c78:	6ce2                	ld	s9,24(sp)
    80003c7a:	6d42                	ld	s10,16(sp)
    80003c7c:	6da2                	ld	s11,8(sp)
    80003c7e:	6165                	addi	sp,sp,112
    80003c80:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c82:	89da                	mv	s3,s6
    80003c84:	bff1                	j	80003c60 <readi+0xce>
    return 0;
    80003c86:	4501                	li	a0,0
}
    80003c88:	8082                	ret

0000000080003c8a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c8a:	457c                	lw	a5,76(a0)
    80003c8c:	10d7e863          	bltu	a5,a3,80003d9c <writei+0x112>
{
    80003c90:	7159                	addi	sp,sp,-112
    80003c92:	f486                	sd	ra,104(sp)
    80003c94:	f0a2                	sd	s0,96(sp)
    80003c96:	eca6                	sd	s1,88(sp)
    80003c98:	e8ca                	sd	s2,80(sp)
    80003c9a:	e4ce                	sd	s3,72(sp)
    80003c9c:	e0d2                	sd	s4,64(sp)
    80003c9e:	fc56                	sd	s5,56(sp)
    80003ca0:	f85a                	sd	s6,48(sp)
    80003ca2:	f45e                	sd	s7,40(sp)
    80003ca4:	f062                	sd	s8,32(sp)
    80003ca6:	ec66                	sd	s9,24(sp)
    80003ca8:	e86a                	sd	s10,16(sp)
    80003caa:	e46e                	sd	s11,8(sp)
    80003cac:	1880                	addi	s0,sp,112
    80003cae:	8b2a                	mv	s6,a0
    80003cb0:	8c2e                	mv	s8,a1
    80003cb2:	8ab2                	mv	s5,a2
    80003cb4:	8936                	mv	s2,a3
    80003cb6:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003cb8:	00e687bb          	addw	a5,a3,a4
    80003cbc:	0ed7e263          	bltu	a5,a3,80003da0 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003cc0:	00043737          	lui	a4,0x43
    80003cc4:	0ef76063          	bltu	a4,a5,80003da4 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cc8:	0c0b8863          	beqz	s7,80003d98 <writei+0x10e>
    80003ccc:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cce:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003cd2:	5cfd                	li	s9,-1
    80003cd4:	a091                	j	80003d18 <writei+0x8e>
    80003cd6:	02099d93          	slli	s11,s3,0x20
    80003cda:	020ddd93          	srli	s11,s11,0x20
    80003cde:	05848513          	addi	a0,s1,88
    80003ce2:	86ee                	mv	a3,s11
    80003ce4:	8656                	mv	a2,s5
    80003ce6:	85e2                	mv	a1,s8
    80003ce8:	953a                	add	a0,a0,a4
    80003cea:	fffff097          	auipc	ra,0xfffff
    80003cee:	a0c080e7          	jalr	-1524(ra) # 800026f6 <either_copyin>
    80003cf2:	07950263          	beq	a0,s9,80003d56 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003cf6:	8526                	mv	a0,s1
    80003cf8:	00000097          	auipc	ra,0x0
    80003cfc:	790080e7          	jalr	1936(ra) # 80004488 <log_write>
    brelse(bp);
    80003d00:	8526                	mv	a0,s1
    80003d02:	fffff097          	auipc	ra,0xfffff
    80003d06:	50a080e7          	jalr	1290(ra) # 8000320c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d0a:	01498a3b          	addw	s4,s3,s4
    80003d0e:	0129893b          	addw	s2,s3,s2
    80003d12:	9aee                	add	s5,s5,s11
    80003d14:	057a7663          	bgeu	s4,s7,80003d60 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d18:	000b2483          	lw	s1,0(s6)
    80003d1c:	00a9559b          	srliw	a1,s2,0xa
    80003d20:	855a                	mv	a0,s6
    80003d22:	fffff097          	auipc	ra,0xfffff
    80003d26:	7ae080e7          	jalr	1966(ra) # 800034d0 <bmap>
    80003d2a:	0005059b          	sext.w	a1,a0
    80003d2e:	8526                	mv	a0,s1
    80003d30:	fffff097          	auipc	ra,0xfffff
    80003d34:	3ac080e7          	jalr	940(ra) # 800030dc <bread>
    80003d38:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d3a:	3ff97713          	andi	a4,s2,1023
    80003d3e:	40ed07bb          	subw	a5,s10,a4
    80003d42:	414b86bb          	subw	a3,s7,s4
    80003d46:	89be                	mv	s3,a5
    80003d48:	2781                	sext.w	a5,a5
    80003d4a:	0006861b          	sext.w	a2,a3
    80003d4e:	f8f674e3          	bgeu	a2,a5,80003cd6 <writei+0x4c>
    80003d52:	89b6                	mv	s3,a3
    80003d54:	b749                	j	80003cd6 <writei+0x4c>
      brelse(bp);
    80003d56:	8526                	mv	a0,s1
    80003d58:	fffff097          	auipc	ra,0xfffff
    80003d5c:	4b4080e7          	jalr	1204(ra) # 8000320c <brelse>
  }

  if(off > ip->size)
    80003d60:	04cb2783          	lw	a5,76(s6)
    80003d64:	0127f463          	bgeu	a5,s2,80003d6c <writei+0xe2>
    ip->size = off;
    80003d68:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d6c:	855a                	mv	a0,s6
    80003d6e:	00000097          	auipc	ra,0x0
    80003d72:	aa6080e7          	jalr	-1370(ra) # 80003814 <iupdate>

  return tot;
    80003d76:	000a051b          	sext.w	a0,s4
}
    80003d7a:	70a6                	ld	ra,104(sp)
    80003d7c:	7406                	ld	s0,96(sp)
    80003d7e:	64e6                	ld	s1,88(sp)
    80003d80:	6946                	ld	s2,80(sp)
    80003d82:	69a6                	ld	s3,72(sp)
    80003d84:	6a06                	ld	s4,64(sp)
    80003d86:	7ae2                	ld	s5,56(sp)
    80003d88:	7b42                	ld	s6,48(sp)
    80003d8a:	7ba2                	ld	s7,40(sp)
    80003d8c:	7c02                	ld	s8,32(sp)
    80003d8e:	6ce2                	ld	s9,24(sp)
    80003d90:	6d42                	ld	s10,16(sp)
    80003d92:	6da2                	ld	s11,8(sp)
    80003d94:	6165                	addi	sp,sp,112
    80003d96:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d98:	8a5e                	mv	s4,s7
    80003d9a:	bfc9                	j	80003d6c <writei+0xe2>
    return -1;
    80003d9c:	557d                	li	a0,-1
}
    80003d9e:	8082                	ret
    return -1;
    80003da0:	557d                	li	a0,-1
    80003da2:	bfe1                	j	80003d7a <writei+0xf0>
    return -1;
    80003da4:	557d                	li	a0,-1
    80003da6:	bfd1                	j	80003d7a <writei+0xf0>

0000000080003da8 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003da8:	1141                	addi	sp,sp,-16
    80003daa:	e406                	sd	ra,8(sp)
    80003dac:	e022                	sd	s0,0(sp)
    80003dae:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003db0:	4639                	li	a2,14
    80003db2:	ffffd097          	auipc	ra,0xffffd
    80003db6:	006080e7          	jalr	6(ra) # 80000db8 <strncmp>
}
    80003dba:	60a2                	ld	ra,8(sp)
    80003dbc:	6402                	ld	s0,0(sp)
    80003dbe:	0141                	addi	sp,sp,16
    80003dc0:	8082                	ret

0000000080003dc2 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003dc2:	7139                	addi	sp,sp,-64
    80003dc4:	fc06                	sd	ra,56(sp)
    80003dc6:	f822                	sd	s0,48(sp)
    80003dc8:	f426                	sd	s1,40(sp)
    80003dca:	f04a                	sd	s2,32(sp)
    80003dcc:	ec4e                	sd	s3,24(sp)
    80003dce:	e852                	sd	s4,16(sp)
    80003dd0:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003dd2:	04451703          	lh	a4,68(a0)
    80003dd6:	4785                	li	a5,1
    80003dd8:	00f71a63          	bne	a4,a5,80003dec <dirlookup+0x2a>
    80003ddc:	892a                	mv	s2,a0
    80003dde:	89ae                	mv	s3,a1
    80003de0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003de2:	457c                	lw	a5,76(a0)
    80003de4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003de6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003de8:	e79d                	bnez	a5,80003e16 <dirlookup+0x54>
    80003dea:	a8a5                	j	80003e62 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003dec:	00005517          	auipc	a0,0x5
    80003df0:	83450513          	addi	a0,a0,-1996 # 80008620 <syscalls+0x1b0>
    80003df4:	ffffc097          	auipc	ra,0xffffc
    80003df8:	74a080e7          	jalr	1866(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003dfc:	00005517          	auipc	a0,0x5
    80003e00:	83c50513          	addi	a0,a0,-1988 # 80008638 <syscalls+0x1c8>
    80003e04:	ffffc097          	auipc	ra,0xffffc
    80003e08:	73a080e7          	jalr	1850(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e0c:	24c1                	addiw	s1,s1,16
    80003e0e:	04c92783          	lw	a5,76(s2)
    80003e12:	04f4f763          	bgeu	s1,a5,80003e60 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e16:	4741                	li	a4,16
    80003e18:	86a6                	mv	a3,s1
    80003e1a:	fc040613          	addi	a2,s0,-64
    80003e1e:	4581                	li	a1,0
    80003e20:	854a                	mv	a0,s2
    80003e22:	00000097          	auipc	ra,0x0
    80003e26:	d70080e7          	jalr	-656(ra) # 80003b92 <readi>
    80003e2a:	47c1                	li	a5,16
    80003e2c:	fcf518e3          	bne	a0,a5,80003dfc <dirlookup+0x3a>
    if(de.inum == 0)
    80003e30:	fc045783          	lhu	a5,-64(s0)
    80003e34:	dfe1                	beqz	a5,80003e0c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e36:	fc240593          	addi	a1,s0,-62
    80003e3a:	854e                	mv	a0,s3
    80003e3c:	00000097          	auipc	ra,0x0
    80003e40:	f6c080e7          	jalr	-148(ra) # 80003da8 <namecmp>
    80003e44:	f561                	bnez	a0,80003e0c <dirlookup+0x4a>
      if(poff)
    80003e46:	000a0463          	beqz	s4,80003e4e <dirlookup+0x8c>
        *poff = off;
    80003e4a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e4e:	fc045583          	lhu	a1,-64(s0)
    80003e52:	00092503          	lw	a0,0(s2)
    80003e56:	fffff097          	auipc	ra,0xfffff
    80003e5a:	754080e7          	jalr	1876(ra) # 800035aa <iget>
    80003e5e:	a011                	j	80003e62 <dirlookup+0xa0>
  return 0;
    80003e60:	4501                	li	a0,0
}
    80003e62:	70e2                	ld	ra,56(sp)
    80003e64:	7442                	ld	s0,48(sp)
    80003e66:	74a2                	ld	s1,40(sp)
    80003e68:	7902                	ld	s2,32(sp)
    80003e6a:	69e2                	ld	s3,24(sp)
    80003e6c:	6a42                	ld	s4,16(sp)
    80003e6e:	6121                	addi	sp,sp,64
    80003e70:	8082                	ret

0000000080003e72 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e72:	711d                	addi	sp,sp,-96
    80003e74:	ec86                	sd	ra,88(sp)
    80003e76:	e8a2                	sd	s0,80(sp)
    80003e78:	e4a6                	sd	s1,72(sp)
    80003e7a:	e0ca                	sd	s2,64(sp)
    80003e7c:	fc4e                	sd	s3,56(sp)
    80003e7e:	f852                	sd	s4,48(sp)
    80003e80:	f456                	sd	s5,40(sp)
    80003e82:	f05a                	sd	s6,32(sp)
    80003e84:	ec5e                	sd	s7,24(sp)
    80003e86:	e862                	sd	s8,16(sp)
    80003e88:	e466                	sd	s9,8(sp)
    80003e8a:	1080                	addi	s0,sp,96
    80003e8c:	84aa                	mv	s1,a0
    80003e8e:	8b2e                	mv	s6,a1
    80003e90:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e92:	00054703          	lbu	a4,0(a0)
    80003e96:	02f00793          	li	a5,47
    80003e9a:	02f70363          	beq	a4,a5,80003ec0 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e9e:	ffffe097          	auipc	ra,0xffffe
    80003ea2:	b1a080e7          	jalr	-1254(ra) # 800019b8 <myproc>
    80003ea6:	15053503          	ld	a0,336(a0)
    80003eaa:	00000097          	auipc	ra,0x0
    80003eae:	9f6080e7          	jalr	-1546(ra) # 800038a0 <idup>
    80003eb2:	89aa                	mv	s3,a0
  while(*path == '/')
    80003eb4:	02f00913          	li	s2,47
  len = path - s;
    80003eb8:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003eba:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003ebc:	4c05                	li	s8,1
    80003ebe:	a865                	j	80003f76 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003ec0:	4585                	li	a1,1
    80003ec2:	4505                	li	a0,1
    80003ec4:	fffff097          	auipc	ra,0xfffff
    80003ec8:	6e6080e7          	jalr	1766(ra) # 800035aa <iget>
    80003ecc:	89aa                	mv	s3,a0
    80003ece:	b7dd                	j	80003eb4 <namex+0x42>
      iunlockput(ip);
    80003ed0:	854e                	mv	a0,s3
    80003ed2:	00000097          	auipc	ra,0x0
    80003ed6:	c6e080e7          	jalr	-914(ra) # 80003b40 <iunlockput>
      return 0;
    80003eda:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003edc:	854e                	mv	a0,s3
    80003ede:	60e6                	ld	ra,88(sp)
    80003ee0:	6446                	ld	s0,80(sp)
    80003ee2:	64a6                	ld	s1,72(sp)
    80003ee4:	6906                	ld	s2,64(sp)
    80003ee6:	79e2                	ld	s3,56(sp)
    80003ee8:	7a42                	ld	s4,48(sp)
    80003eea:	7aa2                	ld	s5,40(sp)
    80003eec:	7b02                	ld	s6,32(sp)
    80003eee:	6be2                	ld	s7,24(sp)
    80003ef0:	6c42                	ld	s8,16(sp)
    80003ef2:	6ca2                	ld	s9,8(sp)
    80003ef4:	6125                	addi	sp,sp,96
    80003ef6:	8082                	ret
      iunlock(ip);
    80003ef8:	854e                	mv	a0,s3
    80003efa:	00000097          	auipc	ra,0x0
    80003efe:	aa6080e7          	jalr	-1370(ra) # 800039a0 <iunlock>
      return ip;
    80003f02:	bfe9                	j	80003edc <namex+0x6a>
      iunlockput(ip);
    80003f04:	854e                	mv	a0,s3
    80003f06:	00000097          	auipc	ra,0x0
    80003f0a:	c3a080e7          	jalr	-966(ra) # 80003b40 <iunlockput>
      return 0;
    80003f0e:	89d2                	mv	s3,s4
    80003f10:	b7f1                	j	80003edc <namex+0x6a>
  len = path - s;
    80003f12:	40b48633          	sub	a2,s1,a1
    80003f16:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003f1a:	094cd463          	bge	s9,s4,80003fa2 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f1e:	4639                	li	a2,14
    80003f20:	8556                	mv	a0,s5
    80003f22:	ffffd097          	auipc	ra,0xffffd
    80003f26:	e1e080e7          	jalr	-482(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003f2a:	0004c783          	lbu	a5,0(s1)
    80003f2e:	01279763          	bne	a5,s2,80003f3c <namex+0xca>
    path++;
    80003f32:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f34:	0004c783          	lbu	a5,0(s1)
    80003f38:	ff278de3          	beq	a5,s2,80003f32 <namex+0xc0>
    ilock(ip);
    80003f3c:	854e                	mv	a0,s3
    80003f3e:	00000097          	auipc	ra,0x0
    80003f42:	9a0080e7          	jalr	-1632(ra) # 800038de <ilock>
    if(ip->type != T_DIR){
    80003f46:	04499783          	lh	a5,68(s3)
    80003f4a:	f98793e3          	bne	a5,s8,80003ed0 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f4e:	000b0563          	beqz	s6,80003f58 <namex+0xe6>
    80003f52:	0004c783          	lbu	a5,0(s1)
    80003f56:	d3cd                	beqz	a5,80003ef8 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f58:	865e                	mv	a2,s7
    80003f5a:	85d6                	mv	a1,s5
    80003f5c:	854e                	mv	a0,s3
    80003f5e:	00000097          	auipc	ra,0x0
    80003f62:	e64080e7          	jalr	-412(ra) # 80003dc2 <dirlookup>
    80003f66:	8a2a                	mv	s4,a0
    80003f68:	dd51                	beqz	a0,80003f04 <namex+0x92>
    iunlockput(ip);
    80003f6a:	854e                	mv	a0,s3
    80003f6c:	00000097          	auipc	ra,0x0
    80003f70:	bd4080e7          	jalr	-1068(ra) # 80003b40 <iunlockput>
    ip = next;
    80003f74:	89d2                	mv	s3,s4
  while(*path == '/')
    80003f76:	0004c783          	lbu	a5,0(s1)
    80003f7a:	05279763          	bne	a5,s2,80003fc8 <namex+0x156>
    path++;
    80003f7e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f80:	0004c783          	lbu	a5,0(s1)
    80003f84:	ff278de3          	beq	a5,s2,80003f7e <namex+0x10c>
  if(*path == 0)
    80003f88:	c79d                	beqz	a5,80003fb6 <namex+0x144>
    path++;
    80003f8a:	85a6                	mv	a1,s1
  len = path - s;
    80003f8c:	8a5e                	mv	s4,s7
    80003f8e:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003f90:	01278963          	beq	a5,s2,80003fa2 <namex+0x130>
    80003f94:	dfbd                	beqz	a5,80003f12 <namex+0xa0>
    path++;
    80003f96:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f98:	0004c783          	lbu	a5,0(s1)
    80003f9c:	ff279ce3          	bne	a5,s2,80003f94 <namex+0x122>
    80003fa0:	bf8d                	j	80003f12 <namex+0xa0>
    memmove(name, s, len);
    80003fa2:	2601                	sext.w	a2,a2
    80003fa4:	8556                	mv	a0,s5
    80003fa6:	ffffd097          	auipc	ra,0xffffd
    80003faa:	d9a080e7          	jalr	-614(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003fae:	9a56                	add	s4,s4,s5
    80003fb0:	000a0023          	sb	zero,0(s4)
    80003fb4:	bf9d                	j	80003f2a <namex+0xb8>
  if(nameiparent){
    80003fb6:	f20b03e3          	beqz	s6,80003edc <namex+0x6a>
    iput(ip);
    80003fba:	854e                	mv	a0,s3
    80003fbc:	00000097          	auipc	ra,0x0
    80003fc0:	adc080e7          	jalr	-1316(ra) # 80003a98 <iput>
    return 0;
    80003fc4:	4981                	li	s3,0
    80003fc6:	bf19                	j	80003edc <namex+0x6a>
  if(*path == 0)
    80003fc8:	d7fd                	beqz	a5,80003fb6 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003fca:	0004c783          	lbu	a5,0(s1)
    80003fce:	85a6                	mv	a1,s1
    80003fd0:	b7d1                	j	80003f94 <namex+0x122>

0000000080003fd2 <dirlink>:
{
    80003fd2:	7139                	addi	sp,sp,-64
    80003fd4:	fc06                	sd	ra,56(sp)
    80003fd6:	f822                	sd	s0,48(sp)
    80003fd8:	f426                	sd	s1,40(sp)
    80003fda:	f04a                	sd	s2,32(sp)
    80003fdc:	ec4e                	sd	s3,24(sp)
    80003fde:	e852                	sd	s4,16(sp)
    80003fe0:	0080                	addi	s0,sp,64
    80003fe2:	892a                	mv	s2,a0
    80003fe4:	8a2e                	mv	s4,a1
    80003fe6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003fe8:	4601                	li	a2,0
    80003fea:	00000097          	auipc	ra,0x0
    80003fee:	dd8080e7          	jalr	-552(ra) # 80003dc2 <dirlookup>
    80003ff2:	e93d                	bnez	a0,80004068 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ff4:	04c92483          	lw	s1,76(s2)
    80003ff8:	c49d                	beqz	s1,80004026 <dirlink+0x54>
    80003ffa:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ffc:	4741                	li	a4,16
    80003ffe:	86a6                	mv	a3,s1
    80004000:	fc040613          	addi	a2,s0,-64
    80004004:	4581                	li	a1,0
    80004006:	854a                	mv	a0,s2
    80004008:	00000097          	auipc	ra,0x0
    8000400c:	b8a080e7          	jalr	-1142(ra) # 80003b92 <readi>
    80004010:	47c1                	li	a5,16
    80004012:	06f51163          	bne	a0,a5,80004074 <dirlink+0xa2>
    if(de.inum == 0)
    80004016:	fc045783          	lhu	a5,-64(s0)
    8000401a:	c791                	beqz	a5,80004026 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000401c:	24c1                	addiw	s1,s1,16
    8000401e:	04c92783          	lw	a5,76(s2)
    80004022:	fcf4ede3          	bltu	s1,a5,80003ffc <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004026:	4639                	li	a2,14
    80004028:	85d2                	mv	a1,s4
    8000402a:	fc240513          	addi	a0,s0,-62
    8000402e:	ffffd097          	auipc	ra,0xffffd
    80004032:	dc6080e7          	jalr	-570(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004036:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000403a:	4741                	li	a4,16
    8000403c:	86a6                	mv	a3,s1
    8000403e:	fc040613          	addi	a2,s0,-64
    80004042:	4581                	li	a1,0
    80004044:	854a                	mv	a0,s2
    80004046:	00000097          	auipc	ra,0x0
    8000404a:	c44080e7          	jalr	-956(ra) # 80003c8a <writei>
    8000404e:	872a                	mv	a4,a0
    80004050:	47c1                	li	a5,16
  return 0;
    80004052:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004054:	02f71863          	bne	a4,a5,80004084 <dirlink+0xb2>
}
    80004058:	70e2                	ld	ra,56(sp)
    8000405a:	7442                	ld	s0,48(sp)
    8000405c:	74a2                	ld	s1,40(sp)
    8000405e:	7902                	ld	s2,32(sp)
    80004060:	69e2                	ld	s3,24(sp)
    80004062:	6a42                	ld	s4,16(sp)
    80004064:	6121                	addi	sp,sp,64
    80004066:	8082                	ret
    iput(ip);
    80004068:	00000097          	auipc	ra,0x0
    8000406c:	a30080e7          	jalr	-1488(ra) # 80003a98 <iput>
    return -1;
    80004070:	557d                	li	a0,-1
    80004072:	b7dd                	j	80004058 <dirlink+0x86>
      panic("dirlink read");
    80004074:	00004517          	auipc	a0,0x4
    80004078:	5d450513          	addi	a0,a0,1492 # 80008648 <syscalls+0x1d8>
    8000407c:	ffffc097          	auipc	ra,0xffffc
    80004080:	4c2080e7          	jalr	1218(ra) # 8000053e <panic>
    panic("dirlink");
    80004084:	00004517          	auipc	a0,0x4
    80004088:	6d450513          	addi	a0,a0,1748 # 80008758 <syscalls+0x2e8>
    8000408c:	ffffc097          	auipc	ra,0xffffc
    80004090:	4b2080e7          	jalr	1202(ra) # 8000053e <panic>

0000000080004094 <namei>:

struct inode*
namei(char *path)
{
    80004094:	1101                	addi	sp,sp,-32
    80004096:	ec06                	sd	ra,24(sp)
    80004098:	e822                	sd	s0,16(sp)
    8000409a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000409c:	fe040613          	addi	a2,s0,-32
    800040a0:	4581                	li	a1,0
    800040a2:	00000097          	auipc	ra,0x0
    800040a6:	dd0080e7          	jalr	-560(ra) # 80003e72 <namex>
}
    800040aa:	60e2                	ld	ra,24(sp)
    800040ac:	6442                	ld	s0,16(sp)
    800040ae:	6105                	addi	sp,sp,32
    800040b0:	8082                	ret

00000000800040b2 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800040b2:	1141                	addi	sp,sp,-16
    800040b4:	e406                	sd	ra,8(sp)
    800040b6:	e022                	sd	s0,0(sp)
    800040b8:	0800                	addi	s0,sp,16
    800040ba:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800040bc:	4585                	li	a1,1
    800040be:	00000097          	auipc	ra,0x0
    800040c2:	db4080e7          	jalr	-588(ra) # 80003e72 <namex>
}
    800040c6:	60a2                	ld	ra,8(sp)
    800040c8:	6402                	ld	s0,0(sp)
    800040ca:	0141                	addi	sp,sp,16
    800040cc:	8082                	ret

00000000800040ce <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800040ce:	1101                	addi	sp,sp,-32
    800040d0:	ec06                	sd	ra,24(sp)
    800040d2:	e822                	sd	s0,16(sp)
    800040d4:	e426                	sd	s1,8(sp)
    800040d6:	e04a                	sd	s2,0(sp)
    800040d8:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800040da:	00016917          	auipc	s2,0x16
    800040de:	30690913          	addi	s2,s2,774 # 8001a3e0 <log>
    800040e2:	01892583          	lw	a1,24(s2)
    800040e6:	02892503          	lw	a0,40(s2)
    800040ea:	fffff097          	auipc	ra,0xfffff
    800040ee:	ff2080e7          	jalr	-14(ra) # 800030dc <bread>
    800040f2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800040f4:	02c92683          	lw	a3,44(s2)
    800040f8:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800040fa:	02d05763          	blez	a3,80004128 <write_head+0x5a>
    800040fe:	00016797          	auipc	a5,0x16
    80004102:	31278793          	addi	a5,a5,786 # 8001a410 <log+0x30>
    80004106:	05c50713          	addi	a4,a0,92
    8000410a:	36fd                	addiw	a3,a3,-1
    8000410c:	1682                	slli	a3,a3,0x20
    8000410e:	9281                	srli	a3,a3,0x20
    80004110:	068a                	slli	a3,a3,0x2
    80004112:	00016617          	auipc	a2,0x16
    80004116:	30260613          	addi	a2,a2,770 # 8001a414 <log+0x34>
    8000411a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000411c:	4390                	lw	a2,0(a5)
    8000411e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004120:	0791                	addi	a5,a5,4
    80004122:	0711                	addi	a4,a4,4
    80004124:	fed79ce3          	bne	a5,a3,8000411c <write_head+0x4e>
  }
  bwrite(buf);
    80004128:	8526                	mv	a0,s1
    8000412a:	fffff097          	auipc	ra,0xfffff
    8000412e:	0a4080e7          	jalr	164(ra) # 800031ce <bwrite>
  brelse(buf);
    80004132:	8526                	mv	a0,s1
    80004134:	fffff097          	auipc	ra,0xfffff
    80004138:	0d8080e7          	jalr	216(ra) # 8000320c <brelse>
}
    8000413c:	60e2                	ld	ra,24(sp)
    8000413e:	6442                	ld	s0,16(sp)
    80004140:	64a2                	ld	s1,8(sp)
    80004142:	6902                	ld	s2,0(sp)
    80004144:	6105                	addi	sp,sp,32
    80004146:	8082                	ret

0000000080004148 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004148:	00016797          	auipc	a5,0x16
    8000414c:	2c47a783          	lw	a5,708(a5) # 8001a40c <log+0x2c>
    80004150:	0af05d63          	blez	a5,8000420a <install_trans+0xc2>
{
    80004154:	7139                	addi	sp,sp,-64
    80004156:	fc06                	sd	ra,56(sp)
    80004158:	f822                	sd	s0,48(sp)
    8000415a:	f426                	sd	s1,40(sp)
    8000415c:	f04a                	sd	s2,32(sp)
    8000415e:	ec4e                	sd	s3,24(sp)
    80004160:	e852                	sd	s4,16(sp)
    80004162:	e456                	sd	s5,8(sp)
    80004164:	e05a                	sd	s6,0(sp)
    80004166:	0080                	addi	s0,sp,64
    80004168:	8b2a                	mv	s6,a0
    8000416a:	00016a97          	auipc	s5,0x16
    8000416e:	2a6a8a93          	addi	s5,s5,678 # 8001a410 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004172:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004174:	00016997          	auipc	s3,0x16
    80004178:	26c98993          	addi	s3,s3,620 # 8001a3e0 <log>
    8000417c:	a035                	j	800041a8 <install_trans+0x60>
      bunpin(dbuf);
    8000417e:	8526                	mv	a0,s1
    80004180:	fffff097          	auipc	ra,0xfffff
    80004184:	166080e7          	jalr	358(ra) # 800032e6 <bunpin>
    brelse(lbuf);
    80004188:	854a                	mv	a0,s2
    8000418a:	fffff097          	auipc	ra,0xfffff
    8000418e:	082080e7          	jalr	130(ra) # 8000320c <brelse>
    brelse(dbuf);
    80004192:	8526                	mv	a0,s1
    80004194:	fffff097          	auipc	ra,0xfffff
    80004198:	078080e7          	jalr	120(ra) # 8000320c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000419c:	2a05                	addiw	s4,s4,1
    8000419e:	0a91                	addi	s5,s5,4
    800041a0:	02c9a783          	lw	a5,44(s3)
    800041a4:	04fa5963          	bge	s4,a5,800041f6 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041a8:	0189a583          	lw	a1,24(s3)
    800041ac:	014585bb          	addw	a1,a1,s4
    800041b0:	2585                	addiw	a1,a1,1
    800041b2:	0289a503          	lw	a0,40(s3)
    800041b6:	fffff097          	auipc	ra,0xfffff
    800041ba:	f26080e7          	jalr	-218(ra) # 800030dc <bread>
    800041be:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800041c0:	000aa583          	lw	a1,0(s5)
    800041c4:	0289a503          	lw	a0,40(s3)
    800041c8:	fffff097          	auipc	ra,0xfffff
    800041cc:	f14080e7          	jalr	-236(ra) # 800030dc <bread>
    800041d0:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800041d2:	40000613          	li	a2,1024
    800041d6:	05890593          	addi	a1,s2,88
    800041da:	05850513          	addi	a0,a0,88
    800041de:	ffffd097          	auipc	ra,0xffffd
    800041e2:	b62080e7          	jalr	-1182(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800041e6:	8526                	mv	a0,s1
    800041e8:	fffff097          	auipc	ra,0xfffff
    800041ec:	fe6080e7          	jalr	-26(ra) # 800031ce <bwrite>
    if(recovering == 0)
    800041f0:	f80b1ce3          	bnez	s6,80004188 <install_trans+0x40>
    800041f4:	b769                	j	8000417e <install_trans+0x36>
}
    800041f6:	70e2                	ld	ra,56(sp)
    800041f8:	7442                	ld	s0,48(sp)
    800041fa:	74a2                	ld	s1,40(sp)
    800041fc:	7902                	ld	s2,32(sp)
    800041fe:	69e2                	ld	s3,24(sp)
    80004200:	6a42                	ld	s4,16(sp)
    80004202:	6aa2                	ld	s5,8(sp)
    80004204:	6b02                	ld	s6,0(sp)
    80004206:	6121                	addi	sp,sp,64
    80004208:	8082                	ret
    8000420a:	8082                	ret

000000008000420c <initlog>:
{
    8000420c:	7179                	addi	sp,sp,-48
    8000420e:	f406                	sd	ra,40(sp)
    80004210:	f022                	sd	s0,32(sp)
    80004212:	ec26                	sd	s1,24(sp)
    80004214:	e84a                	sd	s2,16(sp)
    80004216:	e44e                	sd	s3,8(sp)
    80004218:	1800                	addi	s0,sp,48
    8000421a:	892a                	mv	s2,a0
    8000421c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000421e:	00016497          	auipc	s1,0x16
    80004222:	1c248493          	addi	s1,s1,450 # 8001a3e0 <log>
    80004226:	00004597          	auipc	a1,0x4
    8000422a:	43258593          	addi	a1,a1,1074 # 80008658 <syscalls+0x1e8>
    8000422e:	8526                	mv	a0,s1
    80004230:	ffffd097          	auipc	ra,0xffffd
    80004234:	924080e7          	jalr	-1756(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004238:	0149a583          	lw	a1,20(s3)
    8000423c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000423e:	0109a783          	lw	a5,16(s3)
    80004242:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004244:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004248:	854a                	mv	a0,s2
    8000424a:	fffff097          	auipc	ra,0xfffff
    8000424e:	e92080e7          	jalr	-366(ra) # 800030dc <bread>
  log.lh.n = lh->n;
    80004252:	4d3c                	lw	a5,88(a0)
    80004254:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004256:	02f05563          	blez	a5,80004280 <initlog+0x74>
    8000425a:	05c50713          	addi	a4,a0,92
    8000425e:	00016697          	auipc	a3,0x16
    80004262:	1b268693          	addi	a3,a3,434 # 8001a410 <log+0x30>
    80004266:	37fd                	addiw	a5,a5,-1
    80004268:	1782                	slli	a5,a5,0x20
    8000426a:	9381                	srli	a5,a5,0x20
    8000426c:	078a                	slli	a5,a5,0x2
    8000426e:	06050613          	addi	a2,a0,96
    80004272:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004274:	4310                	lw	a2,0(a4)
    80004276:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004278:	0711                	addi	a4,a4,4
    8000427a:	0691                	addi	a3,a3,4
    8000427c:	fef71ce3          	bne	a4,a5,80004274 <initlog+0x68>
  brelse(buf);
    80004280:	fffff097          	auipc	ra,0xfffff
    80004284:	f8c080e7          	jalr	-116(ra) # 8000320c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004288:	4505                	li	a0,1
    8000428a:	00000097          	auipc	ra,0x0
    8000428e:	ebe080e7          	jalr	-322(ra) # 80004148 <install_trans>
  log.lh.n = 0;
    80004292:	00016797          	auipc	a5,0x16
    80004296:	1607ad23          	sw	zero,378(a5) # 8001a40c <log+0x2c>
  write_head(); // clear the log
    8000429a:	00000097          	auipc	ra,0x0
    8000429e:	e34080e7          	jalr	-460(ra) # 800040ce <write_head>
}
    800042a2:	70a2                	ld	ra,40(sp)
    800042a4:	7402                	ld	s0,32(sp)
    800042a6:	64e2                	ld	s1,24(sp)
    800042a8:	6942                	ld	s2,16(sp)
    800042aa:	69a2                	ld	s3,8(sp)
    800042ac:	6145                	addi	sp,sp,48
    800042ae:	8082                	ret

00000000800042b0 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800042b0:	1101                	addi	sp,sp,-32
    800042b2:	ec06                	sd	ra,24(sp)
    800042b4:	e822                	sd	s0,16(sp)
    800042b6:	e426                	sd	s1,8(sp)
    800042b8:	e04a                	sd	s2,0(sp)
    800042ba:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800042bc:	00016517          	auipc	a0,0x16
    800042c0:	12450513          	addi	a0,a0,292 # 8001a3e0 <log>
    800042c4:	ffffd097          	auipc	ra,0xffffd
    800042c8:	920080e7          	jalr	-1760(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800042cc:	00016497          	auipc	s1,0x16
    800042d0:	11448493          	addi	s1,s1,276 # 8001a3e0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042d4:	4979                	li	s2,30
    800042d6:	a039                	j	800042e4 <begin_op+0x34>
      sleep(&log, &log.lock);
    800042d8:	85a6                	mv	a1,s1
    800042da:	8526                	mv	a0,s1
    800042dc:	ffffe097          	auipc	ra,0xffffe
    800042e0:	f74080e7          	jalr	-140(ra) # 80002250 <sleep>
    if(log.committing){
    800042e4:	50dc                	lw	a5,36(s1)
    800042e6:	fbed                	bnez	a5,800042d8 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042e8:	509c                	lw	a5,32(s1)
    800042ea:	0017871b          	addiw	a4,a5,1
    800042ee:	0007069b          	sext.w	a3,a4
    800042f2:	0027179b          	slliw	a5,a4,0x2
    800042f6:	9fb9                	addw	a5,a5,a4
    800042f8:	0017979b          	slliw	a5,a5,0x1
    800042fc:	54d8                	lw	a4,44(s1)
    800042fe:	9fb9                	addw	a5,a5,a4
    80004300:	00f95963          	bge	s2,a5,80004312 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004304:	85a6                	mv	a1,s1
    80004306:	8526                	mv	a0,s1
    80004308:	ffffe097          	auipc	ra,0xffffe
    8000430c:	f48080e7          	jalr	-184(ra) # 80002250 <sleep>
    80004310:	bfd1                	j	800042e4 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004312:	00016517          	auipc	a0,0x16
    80004316:	0ce50513          	addi	a0,a0,206 # 8001a3e0 <log>
    8000431a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000431c:	ffffd097          	auipc	ra,0xffffd
    80004320:	97c080e7          	jalr	-1668(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004324:	60e2                	ld	ra,24(sp)
    80004326:	6442                	ld	s0,16(sp)
    80004328:	64a2                	ld	s1,8(sp)
    8000432a:	6902                	ld	s2,0(sp)
    8000432c:	6105                	addi	sp,sp,32
    8000432e:	8082                	ret

0000000080004330 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004330:	7139                	addi	sp,sp,-64
    80004332:	fc06                	sd	ra,56(sp)
    80004334:	f822                	sd	s0,48(sp)
    80004336:	f426                	sd	s1,40(sp)
    80004338:	f04a                	sd	s2,32(sp)
    8000433a:	ec4e                	sd	s3,24(sp)
    8000433c:	e852                	sd	s4,16(sp)
    8000433e:	e456                	sd	s5,8(sp)
    80004340:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004342:	00016497          	auipc	s1,0x16
    80004346:	09e48493          	addi	s1,s1,158 # 8001a3e0 <log>
    8000434a:	8526                	mv	a0,s1
    8000434c:	ffffd097          	auipc	ra,0xffffd
    80004350:	898080e7          	jalr	-1896(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004354:	509c                	lw	a5,32(s1)
    80004356:	37fd                	addiw	a5,a5,-1
    80004358:	0007891b          	sext.w	s2,a5
    8000435c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000435e:	50dc                	lw	a5,36(s1)
    80004360:	efb9                	bnez	a5,800043be <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004362:	06091663          	bnez	s2,800043ce <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004366:	00016497          	auipc	s1,0x16
    8000436a:	07a48493          	addi	s1,s1,122 # 8001a3e0 <log>
    8000436e:	4785                	li	a5,1
    80004370:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004372:	8526                	mv	a0,s1
    80004374:	ffffd097          	auipc	ra,0xffffd
    80004378:	924080e7          	jalr	-1756(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000437c:	54dc                	lw	a5,44(s1)
    8000437e:	06f04763          	bgtz	a5,800043ec <end_op+0xbc>
    acquire(&log.lock);
    80004382:	00016497          	auipc	s1,0x16
    80004386:	05e48493          	addi	s1,s1,94 # 8001a3e0 <log>
    8000438a:	8526                	mv	a0,s1
    8000438c:	ffffd097          	auipc	ra,0xffffd
    80004390:	858080e7          	jalr	-1960(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004394:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004398:	8526                	mv	a0,s1
    8000439a:	ffffe097          	auipc	ra,0xffffe
    8000439e:	042080e7          	jalr	66(ra) # 800023dc <wakeup>
    release(&log.lock);
    800043a2:	8526                	mv	a0,s1
    800043a4:	ffffd097          	auipc	ra,0xffffd
    800043a8:	8f4080e7          	jalr	-1804(ra) # 80000c98 <release>
}
    800043ac:	70e2                	ld	ra,56(sp)
    800043ae:	7442                	ld	s0,48(sp)
    800043b0:	74a2                	ld	s1,40(sp)
    800043b2:	7902                	ld	s2,32(sp)
    800043b4:	69e2                	ld	s3,24(sp)
    800043b6:	6a42                	ld	s4,16(sp)
    800043b8:	6aa2                	ld	s5,8(sp)
    800043ba:	6121                	addi	sp,sp,64
    800043bc:	8082                	ret
    panic("log.committing");
    800043be:	00004517          	auipc	a0,0x4
    800043c2:	2a250513          	addi	a0,a0,674 # 80008660 <syscalls+0x1f0>
    800043c6:	ffffc097          	auipc	ra,0xffffc
    800043ca:	178080e7          	jalr	376(ra) # 8000053e <panic>
    wakeup(&log);
    800043ce:	00016497          	auipc	s1,0x16
    800043d2:	01248493          	addi	s1,s1,18 # 8001a3e0 <log>
    800043d6:	8526                	mv	a0,s1
    800043d8:	ffffe097          	auipc	ra,0xffffe
    800043dc:	004080e7          	jalr	4(ra) # 800023dc <wakeup>
  release(&log.lock);
    800043e0:	8526                	mv	a0,s1
    800043e2:	ffffd097          	auipc	ra,0xffffd
    800043e6:	8b6080e7          	jalr	-1866(ra) # 80000c98 <release>
  if(do_commit){
    800043ea:	b7c9                	j	800043ac <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043ec:	00016a97          	auipc	s5,0x16
    800043f0:	024a8a93          	addi	s5,s5,36 # 8001a410 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800043f4:	00016a17          	auipc	s4,0x16
    800043f8:	feca0a13          	addi	s4,s4,-20 # 8001a3e0 <log>
    800043fc:	018a2583          	lw	a1,24(s4)
    80004400:	012585bb          	addw	a1,a1,s2
    80004404:	2585                	addiw	a1,a1,1
    80004406:	028a2503          	lw	a0,40(s4)
    8000440a:	fffff097          	auipc	ra,0xfffff
    8000440e:	cd2080e7          	jalr	-814(ra) # 800030dc <bread>
    80004412:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004414:	000aa583          	lw	a1,0(s5)
    80004418:	028a2503          	lw	a0,40(s4)
    8000441c:	fffff097          	auipc	ra,0xfffff
    80004420:	cc0080e7          	jalr	-832(ra) # 800030dc <bread>
    80004424:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004426:	40000613          	li	a2,1024
    8000442a:	05850593          	addi	a1,a0,88
    8000442e:	05848513          	addi	a0,s1,88
    80004432:	ffffd097          	auipc	ra,0xffffd
    80004436:	90e080e7          	jalr	-1778(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    8000443a:	8526                	mv	a0,s1
    8000443c:	fffff097          	auipc	ra,0xfffff
    80004440:	d92080e7          	jalr	-622(ra) # 800031ce <bwrite>
    brelse(from);
    80004444:	854e                	mv	a0,s3
    80004446:	fffff097          	auipc	ra,0xfffff
    8000444a:	dc6080e7          	jalr	-570(ra) # 8000320c <brelse>
    brelse(to);
    8000444e:	8526                	mv	a0,s1
    80004450:	fffff097          	auipc	ra,0xfffff
    80004454:	dbc080e7          	jalr	-580(ra) # 8000320c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004458:	2905                	addiw	s2,s2,1
    8000445a:	0a91                	addi	s5,s5,4
    8000445c:	02ca2783          	lw	a5,44(s4)
    80004460:	f8f94ee3          	blt	s2,a5,800043fc <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004464:	00000097          	auipc	ra,0x0
    80004468:	c6a080e7          	jalr	-918(ra) # 800040ce <write_head>
    install_trans(0); // Now install writes to home locations
    8000446c:	4501                	li	a0,0
    8000446e:	00000097          	auipc	ra,0x0
    80004472:	cda080e7          	jalr	-806(ra) # 80004148 <install_trans>
    log.lh.n = 0;
    80004476:	00016797          	auipc	a5,0x16
    8000447a:	f807ab23          	sw	zero,-106(a5) # 8001a40c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000447e:	00000097          	auipc	ra,0x0
    80004482:	c50080e7          	jalr	-944(ra) # 800040ce <write_head>
    80004486:	bdf5                	j	80004382 <end_op+0x52>

0000000080004488 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004488:	1101                	addi	sp,sp,-32
    8000448a:	ec06                	sd	ra,24(sp)
    8000448c:	e822                	sd	s0,16(sp)
    8000448e:	e426                	sd	s1,8(sp)
    80004490:	e04a                	sd	s2,0(sp)
    80004492:	1000                	addi	s0,sp,32
    80004494:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004496:	00016917          	auipc	s2,0x16
    8000449a:	f4a90913          	addi	s2,s2,-182 # 8001a3e0 <log>
    8000449e:	854a                	mv	a0,s2
    800044a0:	ffffc097          	auipc	ra,0xffffc
    800044a4:	744080e7          	jalr	1860(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800044a8:	02c92603          	lw	a2,44(s2)
    800044ac:	47f5                	li	a5,29
    800044ae:	06c7c563          	blt	a5,a2,80004518 <log_write+0x90>
    800044b2:	00016797          	auipc	a5,0x16
    800044b6:	f4a7a783          	lw	a5,-182(a5) # 8001a3fc <log+0x1c>
    800044ba:	37fd                	addiw	a5,a5,-1
    800044bc:	04f65e63          	bge	a2,a5,80004518 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800044c0:	00016797          	auipc	a5,0x16
    800044c4:	f407a783          	lw	a5,-192(a5) # 8001a400 <log+0x20>
    800044c8:	06f05063          	blez	a5,80004528 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800044cc:	4781                	li	a5,0
    800044ce:	06c05563          	blez	a2,80004538 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044d2:	44cc                	lw	a1,12(s1)
    800044d4:	00016717          	auipc	a4,0x16
    800044d8:	f3c70713          	addi	a4,a4,-196 # 8001a410 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800044dc:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044de:	4314                	lw	a3,0(a4)
    800044e0:	04b68c63          	beq	a3,a1,80004538 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800044e4:	2785                	addiw	a5,a5,1
    800044e6:	0711                	addi	a4,a4,4
    800044e8:	fef61be3          	bne	a2,a5,800044de <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800044ec:	0621                	addi	a2,a2,8
    800044ee:	060a                	slli	a2,a2,0x2
    800044f0:	00016797          	auipc	a5,0x16
    800044f4:	ef078793          	addi	a5,a5,-272 # 8001a3e0 <log>
    800044f8:	963e                	add	a2,a2,a5
    800044fa:	44dc                	lw	a5,12(s1)
    800044fc:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800044fe:	8526                	mv	a0,s1
    80004500:	fffff097          	auipc	ra,0xfffff
    80004504:	daa080e7          	jalr	-598(ra) # 800032aa <bpin>
    log.lh.n++;
    80004508:	00016717          	auipc	a4,0x16
    8000450c:	ed870713          	addi	a4,a4,-296 # 8001a3e0 <log>
    80004510:	575c                	lw	a5,44(a4)
    80004512:	2785                	addiw	a5,a5,1
    80004514:	d75c                	sw	a5,44(a4)
    80004516:	a835                	j	80004552 <log_write+0xca>
    panic("too big a transaction");
    80004518:	00004517          	auipc	a0,0x4
    8000451c:	15850513          	addi	a0,a0,344 # 80008670 <syscalls+0x200>
    80004520:	ffffc097          	auipc	ra,0xffffc
    80004524:	01e080e7          	jalr	30(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004528:	00004517          	auipc	a0,0x4
    8000452c:	16050513          	addi	a0,a0,352 # 80008688 <syscalls+0x218>
    80004530:	ffffc097          	auipc	ra,0xffffc
    80004534:	00e080e7          	jalr	14(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004538:	00878713          	addi	a4,a5,8
    8000453c:	00271693          	slli	a3,a4,0x2
    80004540:	00016717          	auipc	a4,0x16
    80004544:	ea070713          	addi	a4,a4,-352 # 8001a3e0 <log>
    80004548:	9736                	add	a4,a4,a3
    8000454a:	44d4                	lw	a3,12(s1)
    8000454c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000454e:	faf608e3          	beq	a2,a5,800044fe <log_write+0x76>
  }
  release(&log.lock);
    80004552:	00016517          	auipc	a0,0x16
    80004556:	e8e50513          	addi	a0,a0,-370 # 8001a3e0 <log>
    8000455a:	ffffc097          	auipc	ra,0xffffc
    8000455e:	73e080e7          	jalr	1854(ra) # 80000c98 <release>
}
    80004562:	60e2                	ld	ra,24(sp)
    80004564:	6442                	ld	s0,16(sp)
    80004566:	64a2                	ld	s1,8(sp)
    80004568:	6902                	ld	s2,0(sp)
    8000456a:	6105                	addi	sp,sp,32
    8000456c:	8082                	ret

000000008000456e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000456e:	1101                	addi	sp,sp,-32
    80004570:	ec06                	sd	ra,24(sp)
    80004572:	e822                	sd	s0,16(sp)
    80004574:	e426                	sd	s1,8(sp)
    80004576:	e04a                	sd	s2,0(sp)
    80004578:	1000                	addi	s0,sp,32
    8000457a:	84aa                	mv	s1,a0
    8000457c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000457e:	00004597          	auipc	a1,0x4
    80004582:	12a58593          	addi	a1,a1,298 # 800086a8 <syscalls+0x238>
    80004586:	0521                	addi	a0,a0,8
    80004588:	ffffc097          	auipc	ra,0xffffc
    8000458c:	5cc080e7          	jalr	1484(ra) # 80000b54 <initlock>
  lk->name = name;
    80004590:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004594:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004598:	0204a423          	sw	zero,40(s1)
}
    8000459c:	60e2                	ld	ra,24(sp)
    8000459e:	6442                	ld	s0,16(sp)
    800045a0:	64a2                	ld	s1,8(sp)
    800045a2:	6902                	ld	s2,0(sp)
    800045a4:	6105                	addi	sp,sp,32
    800045a6:	8082                	ret

00000000800045a8 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800045a8:	1101                	addi	sp,sp,-32
    800045aa:	ec06                	sd	ra,24(sp)
    800045ac:	e822                	sd	s0,16(sp)
    800045ae:	e426                	sd	s1,8(sp)
    800045b0:	e04a                	sd	s2,0(sp)
    800045b2:	1000                	addi	s0,sp,32
    800045b4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045b6:	00850913          	addi	s2,a0,8
    800045ba:	854a                	mv	a0,s2
    800045bc:	ffffc097          	auipc	ra,0xffffc
    800045c0:	628080e7          	jalr	1576(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800045c4:	409c                	lw	a5,0(s1)
    800045c6:	cb89                	beqz	a5,800045d8 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800045c8:	85ca                	mv	a1,s2
    800045ca:	8526                	mv	a0,s1
    800045cc:	ffffe097          	auipc	ra,0xffffe
    800045d0:	c84080e7          	jalr	-892(ra) # 80002250 <sleep>
  while (lk->locked) {
    800045d4:	409c                	lw	a5,0(s1)
    800045d6:	fbed                	bnez	a5,800045c8 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800045d8:	4785                	li	a5,1
    800045da:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800045dc:	ffffd097          	auipc	ra,0xffffd
    800045e0:	3dc080e7          	jalr	988(ra) # 800019b8 <myproc>
    800045e4:	591c                	lw	a5,48(a0)
    800045e6:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800045e8:	854a                	mv	a0,s2
    800045ea:	ffffc097          	auipc	ra,0xffffc
    800045ee:	6ae080e7          	jalr	1710(ra) # 80000c98 <release>
}
    800045f2:	60e2                	ld	ra,24(sp)
    800045f4:	6442                	ld	s0,16(sp)
    800045f6:	64a2                	ld	s1,8(sp)
    800045f8:	6902                	ld	s2,0(sp)
    800045fa:	6105                	addi	sp,sp,32
    800045fc:	8082                	ret

00000000800045fe <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045fe:	1101                	addi	sp,sp,-32
    80004600:	ec06                	sd	ra,24(sp)
    80004602:	e822                	sd	s0,16(sp)
    80004604:	e426                	sd	s1,8(sp)
    80004606:	e04a                	sd	s2,0(sp)
    80004608:	1000                	addi	s0,sp,32
    8000460a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000460c:	00850913          	addi	s2,a0,8
    80004610:	854a                	mv	a0,s2
    80004612:	ffffc097          	auipc	ra,0xffffc
    80004616:	5d2080e7          	jalr	1490(ra) # 80000be4 <acquire>
  lk->locked = 0;
    8000461a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000461e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004622:	8526                	mv	a0,s1
    80004624:	ffffe097          	auipc	ra,0xffffe
    80004628:	db8080e7          	jalr	-584(ra) # 800023dc <wakeup>
  release(&lk->lk);
    8000462c:	854a                	mv	a0,s2
    8000462e:	ffffc097          	auipc	ra,0xffffc
    80004632:	66a080e7          	jalr	1642(ra) # 80000c98 <release>
}
    80004636:	60e2                	ld	ra,24(sp)
    80004638:	6442                	ld	s0,16(sp)
    8000463a:	64a2                	ld	s1,8(sp)
    8000463c:	6902                	ld	s2,0(sp)
    8000463e:	6105                	addi	sp,sp,32
    80004640:	8082                	ret

0000000080004642 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004642:	7179                	addi	sp,sp,-48
    80004644:	f406                	sd	ra,40(sp)
    80004646:	f022                	sd	s0,32(sp)
    80004648:	ec26                	sd	s1,24(sp)
    8000464a:	e84a                	sd	s2,16(sp)
    8000464c:	e44e                	sd	s3,8(sp)
    8000464e:	1800                	addi	s0,sp,48
    80004650:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004652:	00850913          	addi	s2,a0,8
    80004656:	854a                	mv	a0,s2
    80004658:	ffffc097          	auipc	ra,0xffffc
    8000465c:	58c080e7          	jalr	1420(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004660:	409c                	lw	a5,0(s1)
    80004662:	ef99                	bnez	a5,80004680 <holdingsleep+0x3e>
    80004664:	4481                	li	s1,0
  release(&lk->lk);
    80004666:	854a                	mv	a0,s2
    80004668:	ffffc097          	auipc	ra,0xffffc
    8000466c:	630080e7          	jalr	1584(ra) # 80000c98 <release>
  return r;
}
    80004670:	8526                	mv	a0,s1
    80004672:	70a2                	ld	ra,40(sp)
    80004674:	7402                	ld	s0,32(sp)
    80004676:	64e2                	ld	s1,24(sp)
    80004678:	6942                	ld	s2,16(sp)
    8000467a:	69a2                	ld	s3,8(sp)
    8000467c:	6145                	addi	sp,sp,48
    8000467e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004680:	0284a983          	lw	s3,40(s1)
    80004684:	ffffd097          	auipc	ra,0xffffd
    80004688:	334080e7          	jalr	820(ra) # 800019b8 <myproc>
    8000468c:	5904                	lw	s1,48(a0)
    8000468e:	413484b3          	sub	s1,s1,s3
    80004692:	0014b493          	seqz	s1,s1
    80004696:	bfc1                	j	80004666 <holdingsleep+0x24>

0000000080004698 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004698:	1141                	addi	sp,sp,-16
    8000469a:	e406                	sd	ra,8(sp)
    8000469c:	e022                	sd	s0,0(sp)
    8000469e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800046a0:	00004597          	auipc	a1,0x4
    800046a4:	01858593          	addi	a1,a1,24 # 800086b8 <syscalls+0x248>
    800046a8:	00016517          	auipc	a0,0x16
    800046ac:	e8050513          	addi	a0,a0,-384 # 8001a528 <ftable>
    800046b0:	ffffc097          	auipc	ra,0xffffc
    800046b4:	4a4080e7          	jalr	1188(ra) # 80000b54 <initlock>
}
    800046b8:	60a2                	ld	ra,8(sp)
    800046ba:	6402                	ld	s0,0(sp)
    800046bc:	0141                	addi	sp,sp,16
    800046be:	8082                	ret

00000000800046c0 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800046c0:	1101                	addi	sp,sp,-32
    800046c2:	ec06                	sd	ra,24(sp)
    800046c4:	e822                	sd	s0,16(sp)
    800046c6:	e426                	sd	s1,8(sp)
    800046c8:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800046ca:	00016517          	auipc	a0,0x16
    800046ce:	e5e50513          	addi	a0,a0,-418 # 8001a528 <ftable>
    800046d2:	ffffc097          	auipc	ra,0xffffc
    800046d6:	512080e7          	jalr	1298(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046da:	00016497          	auipc	s1,0x16
    800046de:	e6648493          	addi	s1,s1,-410 # 8001a540 <ftable+0x18>
    800046e2:	00017717          	auipc	a4,0x17
    800046e6:	dfe70713          	addi	a4,a4,-514 # 8001b4e0 <ftable+0xfb8>
    if(f->ref == 0){
    800046ea:	40dc                	lw	a5,4(s1)
    800046ec:	cf99                	beqz	a5,8000470a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046ee:	02848493          	addi	s1,s1,40
    800046f2:	fee49ce3          	bne	s1,a4,800046ea <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800046f6:	00016517          	auipc	a0,0x16
    800046fa:	e3250513          	addi	a0,a0,-462 # 8001a528 <ftable>
    800046fe:	ffffc097          	auipc	ra,0xffffc
    80004702:	59a080e7          	jalr	1434(ra) # 80000c98 <release>
  return 0;
    80004706:	4481                	li	s1,0
    80004708:	a819                	j	8000471e <filealloc+0x5e>
      f->ref = 1;
    8000470a:	4785                	li	a5,1
    8000470c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000470e:	00016517          	auipc	a0,0x16
    80004712:	e1a50513          	addi	a0,a0,-486 # 8001a528 <ftable>
    80004716:	ffffc097          	auipc	ra,0xffffc
    8000471a:	582080e7          	jalr	1410(ra) # 80000c98 <release>
}
    8000471e:	8526                	mv	a0,s1
    80004720:	60e2                	ld	ra,24(sp)
    80004722:	6442                	ld	s0,16(sp)
    80004724:	64a2                	ld	s1,8(sp)
    80004726:	6105                	addi	sp,sp,32
    80004728:	8082                	ret

000000008000472a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000472a:	1101                	addi	sp,sp,-32
    8000472c:	ec06                	sd	ra,24(sp)
    8000472e:	e822                	sd	s0,16(sp)
    80004730:	e426                	sd	s1,8(sp)
    80004732:	1000                	addi	s0,sp,32
    80004734:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004736:	00016517          	auipc	a0,0x16
    8000473a:	df250513          	addi	a0,a0,-526 # 8001a528 <ftable>
    8000473e:	ffffc097          	auipc	ra,0xffffc
    80004742:	4a6080e7          	jalr	1190(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004746:	40dc                	lw	a5,4(s1)
    80004748:	02f05263          	blez	a5,8000476c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000474c:	2785                	addiw	a5,a5,1
    8000474e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004750:	00016517          	auipc	a0,0x16
    80004754:	dd850513          	addi	a0,a0,-552 # 8001a528 <ftable>
    80004758:	ffffc097          	auipc	ra,0xffffc
    8000475c:	540080e7          	jalr	1344(ra) # 80000c98 <release>
  return f;
}
    80004760:	8526                	mv	a0,s1
    80004762:	60e2                	ld	ra,24(sp)
    80004764:	6442                	ld	s0,16(sp)
    80004766:	64a2                	ld	s1,8(sp)
    80004768:	6105                	addi	sp,sp,32
    8000476a:	8082                	ret
    panic("filedup");
    8000476c:	00004517          	auipc	a0,0x4
    80004770:	f5450513          	addi	a0,a0,-172 # 800086c0 <syscalls+0x250>
    80004774:	ffffc097          	auipc	ra,0xffffc
    80004778:	dca080e7          	jalr	-566(ra) # 8000053e <panic>

000000008000477c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000477c:	7139                	addi	sp,sp,-64
    8000477e:	fc06                	sd	ra,56(sp)
    80004780:	f822                	sd	s0,48(sp)
    80004782:	f426                	sd	s1,40(sp)
    80004784:	f04a                	sd	s2,32(sp)
    80004786:	ec4e                	sd	s3,24(sp)
    80004788:	e852                	sd	s4,16(sp)
    8000478a:	e456                	sd	s5,8(sp)
    8000478c:	0080                	addi	s0,sp,64
    8000478e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004790:	00016517          	auipc	a0,0x16
    80004794:	d9850513          	addi	a0,a0,-616 # 8001a528 <ftable>
    80004798:	ffffc097          	auipc	ra,0xffffc
    8000479c:	44c080e7          	jalr	1100(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800047a0:	40dc                	lw	a5,4(s1)
    800047a2:	06f05163          	blez	a5,80004804 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800047a6:	37fd                	addiw	a5,a5,-1
    800047a8:	0007871b          	sext.w	a4,a5
    800047ac:	c0dc                	sw	a5,4(s1)
    800047ae:	06e04363          	bgtz	a4,80004814 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800047b2:	0004a903          	lw	s2,0(s1)
    800047b6:	0094ca83          	lbu	s5,9(s1)
    800047ba:	0104ba03          	ld	s4,16(s1)
    800047be:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800047c2:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800047c6:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800047ca:	00016517          	auipc	a0,0x16
    800047ce:	d5e50513          	addi	a0,a0,-674 # 8001a528 <ftable>
    800047d2:	ffffc097          	auipc	ra,0xffffc
    800047d6:	4c6080e7          	jalr	1222(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    800047da:	4785                	li	a5,1
    800047dc:	04f90d63          	beq	s2,a5,80004836 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800047e0:	3979                	addiw	s2,s2,-2
    800047e2:	4785                	li	a5,1
    800047e4:	0527e063          	bltu	a5,s2,80004824 <fileclose+0xa8>
    begin_op();
    800047e8:	00000097          	auipc	ra,0x0
    800047ec:	ac8080e7          	jalr	-1336(ra) # 800042b0 <begin_op>
    iput(ff.ip);
    800047f0:	854e                	mv	a0,s3
    800047f2:	fffff097          	auipc	ra,0xfffff
    800047f6:	2a6080e7          	jalr	678(ra) # 80003a98 <iput>
    end_op();
    800047fa:	00000097          	auipc	ra,0x0
    800047fe:	b36080e7          	jalr	-1226(ra) # 80004330 <end_op>
    80004802:	a00d                	j	80004824 <fileclose+0xa8>
    panic("fileclose");
    80004804:	00004517          	auipc	a0,0x4
    80004808:	ec450513          	addi	a0,a0,-316 # 800086c8 <syscalls+0x258>
    8000480c:	ffffc097          	auipc	ra,0xffffc
    80004810:	d32080e7          	jalr	-718(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004814:	00016517          	auipc	a0,0x16
    80004818:	d1450513          	addi	a0,a0,-748 # 8001a528 <ftable>
    8000481c:	ffffc097          	auipc	ra,0xffffc
    80004820:	47c080e7          	jalr	1148(ra) # 80000c98 <release>
  }
}
    80004824:	70e2                	ld	ra,56(sp)
    80004826:	7442                	ld	s0,48(sp)
    80004828:	74a2                	ld	s1,40(sp)
    8000482a:	7902                	ld	s2,32(sp)
    8000482c:	69e2                	ld	s3,24(sp)
    8000482e:	6a42                	ld	s4,16(sp)
    80004830:	6aa2                	ld	s5,8(sp)
    80004832:	6121                	addi	sp,sp,64
    80004834:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004836:	85d6                	mv	a1,s5
    80004838:	8552                	mv	a0,s4
    8000483a:	00000097          	auipc	ra,0x0
    8000483e:	34c080e7          	jalr	844(ra) # 80004b86 <pipeclose>
    80004842:	b7cd                	j	80004824 <fileclose+0xa8>

0000000080004844 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004844:	715d                	addi	sp,sp,-80
    80004846:	e486                	sd	ra,72(sp)
    80004848:	e0a2                	sd	s0,64(sp)
    8000484a:	fc26                	sd	s1,56(sp)
    8000484c:	f84a                	sd	s2,48(sp)
    8000484e:	f44e                	sd	s3,40(sp)
    80004850:	0880                	addi	s0,sp,80
    80004852:	84aa                	mv	s1,a0
    80004854:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004856:	ffffd097          	auipc	ra,0xffffd
    8000485a:	162080e7          	jalr	354(ra) # 800019b8 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000485e:	409c                	lw	a5,0(s1)
    80004860:	37f9                	addiw	a5,a5,-2
    80004862:	4705                	li	a4,1
    80004864:	04f76763          	bltu	a4,a5,800048b2 <filestat+0x6e>
    80004868:	892a                	mv	s2,a0
    ilock(f->ip);
    8000486a:	6c88                	ld	a0,24(s1)
    8000486c:	fffff097          	auipc	ra,0xfffff
    80004870:	072080e7          	jalr	114(ra) # 800038de <ilock>
    stati(f->ip, &st);
    80004874:	fb840593          	addi	a1,s0,-72
    80004878:	6c88                	ld	a0,24(s1)
    8000487a:	fffff097          	auipc	ra,0xfffff
    8000487e:	2ee080e7          	jalr	750(ra) # 80003b68 <stati>
    iunlock(f->ip);
    80004882:	6c88                	ld	a0,24(s1)
    80004884:	fffff097          	auipc	ra,0xfffff
    80004888:	11c080e7          	jalr	284(ra) # 800039a0 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000488c:	46e1                	li	a3,24
    8000488e:	fb840613          	addi	a2,s0,-72
    80004892:	85ce                	mv	a1,s3
    80004894:	05093503          	ld	a0,80(s2)
    80004898:	ffffd097          	auipc	ra,0xffffd
    8000489c:	de2080e7          	jalr	-542(ra) # 8000167a <copyout>
    800048a0:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800048a4:	60a6                	ld	ra,72(sp)
    800048a6:	6406                	ld	s0,64(sp)
    800048a8:	74e2                	ld	s1,56(sp)
    800048aa:	7942                	ld	s2,48(sp)
    800048ac:	79a2                	ld	s3,40(sp)
    800048ae:	6161                	addi	sp,sp,80
    800048b0:	8082                	ret
  return -1;
    800048b2:	557d                	li	a0,-1
    800048b4:	bfc5                	j	800048a4 <filestat+0x60>

00000000800048b6 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800048b6:	7179                	addi	sp,sp,-48
    800048b8:	f406                	sd	ra,40(sp)
    800048ba:	f022                	sd	s0,32(sp)
    800048bc:	ec26                	sd	s1,24(sp)
    800048be:	e84a                	sd	s2,16(sp)
    800048c0:	e44e                	sd	s3,8(sp)
    800048c2:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800048c4:	00854783          	lbu	a5,8(a0)
    800048c8:	c3d5                	beqz	a5,8000496c <fileread+0xb6>
    800048ca:	84aa                	mv	s1,a0
    800048cc:	89ae                	mv	s3,a1
    800048ce:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800048d0:	411c                	lw	a5,0(a0)
    800048d2:	4705                	li	a4,1
    800048d4:	04e78963          	beq	a5,a4,80004926 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048d8:	470d                	li	a4,3
    800048da:	04e78d63          	beq	a5,a4,80004934 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800048de:	4709                	li	a4,2
    800048e0:	06e79e63          	bne	a5,a4,8000495c <fileread+0xa6>
    ilock(f->ip);
    800048e4:	6d08                	ld	a0,24(a0)
    800048e6:	fffff097          	auipc	ra,0xfffff
    800048ea:	ff8080e7          	jalr	-8(ra) # 800038de <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800048ee:	874a                	mv	a4,s2
    800048f0:	5094                	lw	a3,32(s1)
    800048f2:	864e                	mv	a2,s3
    800048f4:	4585                	li	a1,1
    800048f6:	6c88                	ld	a0,24(s1)
    800048f8:	fffff097          	auipc	ra,0xfffff
    800048fc:	29a080e7          	jalr	666(ra) # 80003b92 <readi>
    80004900:	892a                	mv	s2,a0
    80004902:	00a05563          	blez	a0,8000490c <fileread+0x56>
      f->off += r;
    80004906:	509c                	lw	a5,32(s1)
    80004908:	9fa9                	addw	a5,a5,a0
    8000490a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000490c:	6c88                	ld	a0,24(s1)
    8000490e:	fffff097          	auipc	ra,0xfffff
    80004912:	092080e7          	jalr	146(ra) # 800039a0 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004916:	854a                	mv	a0,s2
    80004918:	70a2                	ld	ra,40(sp)
    8000491a:	7402                	ld	s0,32(sp)
    8000491c:	64e2                	ld	s1,24(sp)
    8000491e:	6942                	ld	s2,16(sp)
    80004920:	69a2                	ld	s3,8(sp)
    80004922:	6145                	addi	sp,sp,48
    80004924:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004926:	6908                	ld	a0,16(a0)
    80004928:	00000097          	auipc	ra,0x0
    8000492c:	3c8080e7          	jalr	968(ra) # 80004cf0 <piperead>
    80004930:	892a                	mv	s2,a0
    80004932:	b7d5                	j	80004916 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004934:	02451783          	lh	a5,36(a0)
    80004938:	03079693          	slli	a3,a5,0x30
    8000493c:	92c1                	srli	a3,a3,0x30
    8000493e:	4725                	li	a4,9
    80004940:	02d76863          	bltu	a4,a3,80004970 <fileread+0xba>
    80004944:	0792                	slli	a5,a5,0x4
    80004946:	00016717          	auipc	a4,0x16
    8000494a:	b4270713          	addi	a4,a4,-1214 # 8001a488 <devsw>
    8000494e:	97ba                	add	a5,a5,a4
    80004950:	639c                	ld	a5,0(a5)
    80004952:	c38d                	beqz	a5,80004974 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004954:	4505                	li	a0,1
    80004956:	9782                	jalr	a5
    80004958:	892a                	mv	s2,a0
    8000495a:	bf75                	j	80004916 <fileread+0x60>
    panic("fileread");
    8000495c:	00004517          	auipc	a0,0x4
    80004960:	d7c50513          	addi	a0,a0,-644 # 800086d8 <syscalls+0x268>
    80004964:	ffffc097          	auipc	ra,0xffffc
    80004968:	bda080e7          	jalr	-1062(ra) # 8000053e <panic>
    return -1;
    8000496c:	597d                	li	s2,-1
    8000496e:	b765                	j	80004916 <fileread+0x60>
      return -1;
    80004970:	597d                	li	s2,-1
    80004972:	b755                	j	80004916 <fileread+0x60>
    80004974:	597d                	li	s2,-1
    80004976:	b745                	j	80004916 <fileread+0x60>

0000000080004978 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004978:	715d                	addi	sp,sp,-80
    8000497a:	e486                	sd	ra,72(sp)
    8000497c:	e0a2                	sd	s0,64(sp)
    8000497e:	fc26                	sd	s1,56(sp)
    80004980:	f84a                	sd	s2,48(sp)
    80004982:	f44e                	sd	s3,40(sp)
    80004984:	f052                	sd	s4,32(sp)
    80004986:	ec56                	sd	s5,24(sp)
    80004988:	e85a                	sd	s6,16(sp)
    8000498a:	e45e                	sd	s7,8(sp)
    8000498c:	e062                	sd	s8,0(sp)
    8000498e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004990:	00954783          	lbu	a5,9(a0)
    80004994:	10078663          	beqz	a5,80004aa0 <filewrite+0x128>
    80004998:	892a                	mv	s2,a0
    8000499a:	8aae                	mv	s5,a1
    8000499c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000499e:	411c                	lw	a5,0(a0)
    800049a0:	4705                	li	a4,1
    800049a2:	02e78263          	beq	a5,a4,800049c6 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049a6:	470d                	li	a4,3
    800049a8:	02e78663          	beq	a5,a4,800049d4 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800049ac:	4709                	li	a4,2
    800049ae:	0ee79163          	bne	a5,a4,80004a90 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800049b2:	0ac05d63          	blez	a2,80004a6c <filewrite+0xf4>
    int i = 0;
    800049b6:	4981                	li	s3,0
    800049b8:	6b05                	lui	s6,0x1
    800049ba:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800049be:	6b85                	lui	s7,0x1
    800049c0:	c00b8b9b          	addiw	s7,s7,-1024
    800049c4:	a861                	j	80004a5c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800049c6:	6908                	ld	a0,16(a0)
    800049c8:	00000097          	auipc	ra,0x0
    800049cc:	22e080e7          	jalr	558(ra) # 80004bf6 <pipewrite>
    800049d0:	8a2a                	mv	s4,a0
    800049d2:	a045                	j	80004a72 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800049d4:	02451783          	lh	a5,36(a0)
    800049d8:	03079693          	slli	a3,a5,0x30
    800049dc:	92c1                	srli	a3,a3,0x30
    800049de:	4725                	li	a4,9
    800049e0:	0cd76263          	bltu	a4,a3,80004aa4 <filewrite+0x12c>
    800049e4:	0792                	slli	a5,a5,0x4
    800049e6:	00016717          	auipc	a4,0x16
    800049ea:	aa270713          	addi	a4,a4,-1374 # 8001a488 <devsw>
    800049ee:	97ba                	add	a5,a5,a4
    800049f0:	679c                	ld	a5,8(a5)
    800049f2:	cbdd                	beqz	a5,80004aa8 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800049f4:	4505                	li	a0,1
    800049f6:	9782                	jalr	a5
    800049f8:	8a2a                	mv	s4,a0
    800049fa:	a8a5                	j	80004a72 <filewrite+0xfa>
    800049fc:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a00:	00000097          	auipc	ra,0x0
    80004a04:	8b0080e7          	jalr	-1872(ra) # 800042b0 <begin_op>
      ilock(f->ip);
    80004a08:	01893503          	ld	a0,24(s2)
    80004a0c:	fffff097          	auipc	ra,0xfffff
    80004a10:	ed2080e7          	jalr	-302(ra) # 800038de <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a14:	8762                	mv	a4,s8
    80004a16:	02092683          	lw	a3,32(s2)
    80004a1a:	01598633          	add	a2,s3,s5
    80004a1e:	4585                	li	a1,1
    80004a20:	01893503          	ld	a0,24(s2)
    80004a24:	fffff097          	auipc	ra,0xfffff
    80004a28:	266080e7          	jalr	614(ra) # 80003c8a <writei>
    80004a2c:	84aa                	mv	s1,a0
    80004a2e:	00a05763          	blez	a0,80004a3c <filewrite+0xc4>
        f->off += r;
    80004a32:	02092783          	lw	a5,32(s2)
    80004a36:	9fa9                	addw	a5,a5,a0
    80004a38:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a3c:	01893503          	ld	a0,24(s2)
    80004a40:	fffff097          	auipc	ra,0xfffff
    80004a44:	f60080e7          	jalr	-160(ra) # 800039a0 <iunlock>
      end_op();
    80004a48:	00000097          	auipc	ra,0x0
    80004a4c:	8e8080e7          	jalr	-1816(ra) # 80004330 <end_op>

      if(r != n1){
    80004a50:	009c1f63          	bne	s8,s1,80004a6e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004a54:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a58:	0149db63          	bge	s3,s4,80004a6e <filewrite+0xf6>
      int n1 = n - i;
    80004a5c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a60:	84be                	mv	s1,a5
    80004a62:	2781                	sext.w	a5,a5
    80004a64:	f8fb5ce3          	bge	s6,a5,800049fc <filewrite+0x84>
    80004a68:	84de                	mv	s1,s7
    80004a6a:	bf49                	j	800049fc <filewrite+0x84>
    int i = 0;
    80004a6c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a6e:	013a1f63          	bne	s4,s3,80004a8c <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a72:	8552                	mv	a0,s4
    80004a74:	60a6                	ld	ra,72(sp)
    80004a76:	6406                	ld	s0,64(sp)
    80004a78:	74e2                	ld	s1,56(sp)
    80004a7a:	7942                	ld	s2,48(sp)
    80004a7c:	79a2                	ld	s3,40(sp)
    80004a7e:	7a02                	ld	s4,32(sp)
    80004a80:	6ae2                	ld	s5,24(sp)
    80004a82:	6b42                	ld	s6,16(sp)
    80004a84:	6ba2                	ld	s7,8(sp)
    80004a86:	6c02                	ld	s8,0(sp)
    80004a88:	6161                	addi	sp,sp,80
    80004a8a:	8082                	ret
    ret = (i == n ? n : -1);
    80004a8c:	5a7d                	li	s4,-1
    80004a8e:	b7d5                	j	80004a72 <filewrite+0xfa>
    panic("filewrite");
    80004a90:	00004517          	auipc	a0,0x4
    80004a94:	c5850513          	addi	a0,a0,-936 # 800086e8 <syscalls+0x278>
    80004a98:	ffffc097          	auipc	ra,0xffffc
    80004a9c:	aa6080e7          	jalr	-1370(ra) # 8000053e <panic>
    return -1;
    80004aa0:	5a7d                	li	s4,-1
    80004aa2:	bfc1                	j	80004a72 <filewrite+0xfa>
      return -1;
    80004aa4:	5a7d                	li	s4,-1
    80004aa6:	b7f1                	j	80004a72 <filewrite+0xfa>
    80004aa8:	5a7d                	li	s4,-1
    80004aaa:	b7e1                	j	80004a72 <filewrite+0xfa>

0000000080004aac <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004aac:	7179                	addi	sp,sp,-48
    80004aae:	f406                	sd	ra,40(sp)
    80004ab0:	f022                	sd	s0,32(sp)
    80004ab2:	ec26                	sd	s1,24(sp)
    80004ab4:	e84a                	sd	s2,16(sp)
    80004ab6:	e44e                	sd	s3,8(sp)
    80004ab8:	e052                	sd	s4,0(sp)
    80004aba:	1800                	addi	s0,sp,48
    80004abc:	84aa                	mv	s1,a0
    80004abe:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004ac0:	0005b023          	sd	zero,0(a1)
    80004ac4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004ac8:	00000097          	auipc	ra,0x0
    80004acc:	bf8080e7          	jalr	-1032(ra) # 800046c0 <filealloc>
    80004ad0:	e088                	sd	a0,0(s1)
    80004ad2:	c551                	beqz	a0,80004b5e <pipealloc+0xb2>
    80004ad4:	00000097          	auipc	ra,0x0
    80004ad8:	bec080e7          	jalr	-1044(ra) # 800046c0 <filealloc>
    80004adc:	00aa3023          	sd	a0,0(s4)
    80004ae0:	c92d                	beqz	a0,80004b52 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004ae2:	ffffc097          	auipc	ra,0xffffc
    80004ae6:	012080e7          	jalr	18(ra) # 80000af4 <kalloc>
    80004aea:	892a                	mv	s2,a0
    80004aec:	c125                	beqz	a0,80004b4c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004aee:	4985                	li	s3,1
    80004af0:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004af4:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004af8:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004afc:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b00:	00004597          	auipc	a1,0x4
    80004b04:	bf858593          	addi	a1,a1,-1032 # 800086f8 <syscalls+0x288>
    80004b08:	ffffc097          	auipc	ra,0xffffc
    80004b0c:	04c080e7          	jalr	76(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004b10:	609c                	ld	a5,0(s1)
    80004b12:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b16:	609c                	ld	a5,0(s1)
    80004b18:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b1c:	609c                	ld	a5,0(s1)
    80004b1e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b22:	609c                	ld	a5,0(s1)
    80004b24:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b28:	000a3783          	ld	a5,0(s4)
    80004b2c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b30:	000a3783          	ld	a5,0(s4)
    80004b34:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b38:	000a3783          	ld	a5,0(s4)
    80004b3c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b40:	000a3783          	ld	a5,0(s4)
    80004b44:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b48:	4501                	li	a0,0
    80004b4a:	a025                	j	80004b72 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b4c:	6088                	ld	a0,0(s1)
    80004b4e:	e501                	bnez	a0,80004b56 <pipealloc+0xaa>
    80004b50:	a039                	j	80004b5e <pipealloc+0xb2>
    80004b52:	6088                	ld	a0,0(s1)
    80004b54:	c51d                	beqz	a0,80004b82 <pipealloc+0xd6>
    fileclose(*f0);
    80004b56:	00000097          	auipc	ra,0x0
    80004b5a:	c26080e7          	jalr	-986(ra) # 8000477c <fileclose>
  if(*f1)
    80004b5e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b62:	557d                	li	a0,-1
  if(*f1)
    80004b64:	c799                	beqz	a5,80004b72 <pipealloc+0xc6>
    fileclose(*f1);
    80004b66:	853e                	mv	a0,a5
    80004b68:	00000097          	auipc	ra,0x0
    80004b6c:	c14080e7          	jalr	-1004(ra) # 8000477c <fileclose>
  return -1;
    80004b70:	557d                	li	a0,-1
}
    80004b72:	70a2                	ld	ra,40(sp)
    80004b74:	7402                	ld	s0,32(sp)
    80004b76:	64e2                	ld	s1,24(sp)
    80004b78:	6942                	ld	s2,16(sp)
    80004b7a:	69a2                	ld	s3,8(sp)
    80004b7c:	6a02                	ld	s4,0(sp)
    80004b7e:	6145                	addi	sp,sp,48
    80004b80:	8082                	ret
  return -1;
    80004b82:	557d                	li	a0,-1
    80004b84:	b7fd                	j	80004b72 <pipealloc+0xc6>

0000000080004b86 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b86:	1101                	addi	sp,sp,-32
    80004b88:	ec06                	sd	ra,24(sp)
    80004b8a:	e822                	sd	s0,16(sp)
    80004b8c:	e426                	sd	s1,8(sp)
    80004b8e:	e04a                	sd	s2,0(sp)
    80004b90:	1000                	addi	s0,sp,32
    80004b92:	84aa                	mv	s1,a0
    80004b94:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b96:	ffffc097          	auipc	ra,0xffffc
    80004b9a:	04e080e7          	jalr	78(ra) # 80000be4 <acquire>
  if(writable){
    80004b9e:	02090d63          	beqz	s2,80004bd8 <pipeclose+0x52>
    pi->writeopen = 0;
    80004ba2:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ba6:	21848513          	addi	a0,s1,536
    80004baa:	ffffe097          	auipc	ra,0xffffe
    80004bae:	832080e7          	jalr	-1998(ra) # 800023dc <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004bb2:	2204b783          	ld	a5,544(s1)
    80004bb6:	eb95                	bnez	a5,80004bea <pipeclose+0x64>
    release(&pi->lock);
    80004bb8:	8526                	mv	a0,s1
    80004bba:	ffffc097          	auipc	ra,0xffffc
    80004bbe:	0de080e7          	jalr	222(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004bc2:	8526                	mv	a0,s1
    80004bc4:	ffffc097          	auipc	ra,0xffffc
    80004bc8:	e34080e7          	jalr	-460(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004bcc:	60e2                	ld	ra,24(sp)
    80004bce:	6442                	ld	s0,16(sp)
    80004bd0:	64a2                	ld	s1,8(sp)
    80004bd2:	6902                	ld	s2,0(sp)
    80004bd4:	6105                	addi	sp,sp,32
    80004bd6:	8082                	ret
    pi->readopen = 0;
    80004bd8:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004bdc:	21c48513          	addi	a0,s1,540
    80004be0:	ffffd097          	auipc	ra,0xffffd
    80004be4:	7fc080e7          	jalr	2044(ra) # 800023dc <wakeup>
    80004be8:	b7e9                	j	80004bb2 <pipeclose+0x2c>
    release(&pi->lock);
    80004bea:	8526                	mv	a0,s1
    80004bec:	ffffc097          	auipc	ra,0xffffc
    80004bf0:	0ac080e7          	jalr	172(ra) # 80000c98 <release>
}
    80004bf4:	bfe1                	j	80004bcc <pipeclose+0x46>

0000000080004bf6 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004bf6:	7159                	addi	sp,sp,-112
    80004bf8:	f486                	sd	ra,104(sp)
    80004bfa:	f0a2                	sd	s0,96(sp)
    80004bfc:	eca6                	sd	s1,88(sp)
    80004bfe:	e8ca                	sd	s2,80(sp)
    80004c00:	e4ce                	sd	s3,72(sp)
    80004c02:	e0d2                	sd	s4,64(sp)
    80004c04:	fc56                	sd	s5,56(sp)
    80004c06:	f85a                	sd	s6,48(sp)
    80004c08:	f45e                	sd	s7,40(sp)
    80004c0a:	f062                	sd	s8,32(sp)
    80004c0c:	ec66                	sd	s9,24(sp)
    80004c0e:	1880                	addi	s0,sp,112
    80004c10:	84aa                	mv	s1,a0
    80004c12:	8aae                	mv	s5,a1
    80004c14:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004c16:	ffffd097          	auipc	ra,0xffffd
    80004c1a:	da2080e7          	jalr	-606(ra) # 800019b8 <myproc>
    80004c1e:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004c20:	8526                	mv	a0,s1
    80004c22:	ffffc097          	auipc	ra,0xffffc
    80004c26:	fc2080e7          	jalr	-62(ra) # 80000be4 <acquire>
  while(i < n){
    80004c2a:	0d405163          	blez	s4,80004cec <pipewrite+0xf6>
    80004c2e:	8ba6                	mv	s7,s1
  int i = 0;
    80004c30:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c32:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004c34:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c38:	21c48c13          	addi	s8,s1,540
    80004c3c:	a08d                	j	80004c9e <pipewrite+0xa8>
      release(&pi->lock);
    80004c3e:	8526                	mv	a0,s1
    80004c40:	ffffc097          	auipc	ra,0xffffc
    80004c44:	058080e7          	jalr	88(ra) # 80000c98 <release>
      return -1;
    80004c48:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c4a:	854a                	mv	a0,s2
    80004c4c:	70a6                	ld	ra,104(sp)
    80004c4e:	7406                	ld	s0,96(sp)
    80004c50:	64e6                	ld	s1,88(sp)
    80004c52:	6946                	ld	s2,80(sp)
    80004c54:	69a6                	ld	s3,72(sp)
    80004c56:	6a06                	ld	s4,64(sp)
    80004c58:	7ae2                	ld	s5,56(sp)
    80004c5a:	7b42                	ld	s6,48(sp)
    80004c5c:	7ba2                	ld	s7,40(sp)
    80004c5e:	7c02                	ld	s8,32(sp)
    80004c60:	6ce2                	ld	s9,24(sp)
    80004c62:	6165                	addi	sp,sp,112
    80004c64:	8082                	ret
      wakeup(&pi->nread);
    80004c66:	8566                	mv	a0,s9
    80004c68:	ffffd097          	auipc	ra,0xffffd
    80004c6c:	774080e7          	jalr	1908(ra) # 800023dc <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c70:	85de                	mv	a1,s7
    80004c72:	8562                	mv	a0,s8
    80004c74:	ffffd097          	auipc	ra,0xffffd
    80004c78:	5dc080e7          	jalr	1500(ra) # 80002250 <sleep>
    80004c7c:	a839                	j	80004c9a <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c7e:	21c4a783          	lw	a5,540(s1)
    80004c82:	0017871b          	addiw	a4,a5,1
    80004c86:	20e4ae23          	sw	a4,540(s1)
    80004c8a:	1ff7f793          	andi	a5,a5,511
    80004c8e:	97a6                	add	a5,a5,s1
    80004c90:	f9f44703          	lbu	a4,-97(s0)
    80004c94:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c98:	2905                	addiw	s2,s2,1
  while(i < n){
    80004c9a:	03495d63          	bge	s2,s4,80004cd4 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004c9e:	2204a783          	lw	a5,544(s1)
    80004ca2:	dfd1                	beqz	a5,80004c3e <pipewrite+0x48>
    80004ca4:	0289a783          	lw	a5,40(s3)
    80004ca8:	fbd9                	bnez	a5,80004c3e <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004caa:	2184a783          	lw	a5,536(s1)
    80004cae:	21c4a703          	lw	a4,540(s1)
    80004cb2:	2007879b          	addiw	a5,a5,512
    80004cb6:	faf708e3          	beq	a4,a5,80004c66 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cba:	4685                	li	a3,1
    80004cbc:	01590633          	add	a2,s2,s5
    80004cc0:	f9f40593          	addi	a1,s0,-97
    80004cc4:	0509b503          	ld	a0,80(s3)
    80004cc8:	ffffd097          	auipc	ra,0xffffd
    80004ccc:	a3e080e7          	jalr	-1474(ra) # 80001706 <copyin>
    80004cd0:	fb6517e3          	bne	a0,s6,80004c7e <pipewrite+0x88>
  wakeup(&pi->nread);
    80004cd4:	21848513          	addi	a0,s1,536
    80004cd8:	ffffd097          	auipc	ra,0xffffd
    80004cdc:	704080e7          	jalr	1796(ra) # 800023dc <wakeup>
  release(&pi->lock);
    80004ce0:	8526                	mv	a0,s1
    80004ce2:	ffffc097          	auipc	ra,0xffffc
    80004ce6:	fb6080e7          	jalr	-74(ra) # 80000c98 <release>
  return i;
    80004cea:	b785                	j	80004c4a <pipewrite+0x54>
  int i = 0;
    80004cec:	4901                	li	s2,0
    80004cee:	b7dd                	j	80004cd4 <pipewrite+0xde>

0000000080004cf0 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004cf0:	715d                	addi	sp,sp,-80
    80004cf2:	e486                	sd	ra,72(sp)
    80004cf4:	e0a2                	sd	s0,64(sp)
    80004cf6:	fc26                	sd	s1,56(sp)
    80004cf8:	f84a                	sd	s2,48(sp)
    80004cfa:	f44e                	sd	s3,40(sp)
    80004cfc:	f052                	sd	s4,32(sp)
    80004cfe:	ec56                	sd	s5,24(sp)
    80004d00:	e85a                	sd	s6,16(sp)
    80004d02:	0880                	addi	s0,sp,80
    80004d04:	84aa                	mv	s1,a0
    80004d06:	892e                	mv	s2,a1
    80004d08:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d0a:	ffffd097          	auipc	ra,0xffffd
    80004d0e:	cae080e7          	jalr	-850(ra) # 800019b8 <myproc>
    80004d12:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d14:	8b26                	mv	s6,s1
    80004d16:	8526                	mv	a0,s1
    80004d18:	ffffc097          	auipc	ra,0xffffc
    80004d1c:	ecc080e7          	jalr	-308(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d20:	2184a703          	lw	a4,536(s1)
    80004d24:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d28:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d2c:	02f71463          	bne	a4,a5,80004d54 <piperead+0x64>
    80004d30:	2244a783          	lw	a5,548(s1)
    80004d34:	c385                	beqz	a5,80004d54 <piperead+0x64>
    if(pr->killed){
    80004d36:	028a2783          	lw	a5,40(s4)
    80004d3a:	ebc1                	bnez	a5,80004dca <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d3c:	85da                	mv	a1,s6
    80004d3e:	854e                	mv	a0,s3
    80004d40:	ffffd097          	auipc	ra,0xffffd
    80004d44:	510080e7          	jalr	1296(ra) # 80002250 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d48:	2184a703          	lw	a4,536(s1)
    80004d4c:	21c4a783          	lw	a5,540(s1)
    80004d50:	fef700e3          	beq	a4,a5,80004d30 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d54:	09505263          	blez	s5,80004dd8 <piperead+0xe8>
    80004d58:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d5a:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004d5c:	2184a783          	lw	a5,536(s1)
    80004d60:	21c4a703          	lw	a4,540(s1)
    80004d64:	02f70d63          	beq	a4,a5,80004d9e <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d68:	0017871b          	addiw	a4,a5,1
    80004d6c:	20e4ac23          	sw	a4,536(s1)
    80004d70:	1ff7f793          	andi	a5,a5,511
    80004d74:	97a6                	add	a5,a5,s1
    80004d76:	0187c783          	lbu	a5,24(a5)
    80004d7a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d7e:	4685                	li	a3,1
    80004d80:	fbf40613          	addi	a2,s0,-65
    80004d84:	85ca                	mv	a1,s2
    80004d86:	050a3503          	ld	a0,80(s4)
    80004d8a:	ffffd097          	auipc	ra,0xffffd
    80004d8e:	8f0080e7          	jalr	-1808(ra) # 8000167a <copyout>
    80004d92:	01650663          	beq	a0,s6,80004d9e <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d96:	2985                	addiw	s3,s3,1
    80004d98:	0905                	addi	s2,s2,1
    80004d9a:	fd3a91e3          	bne	s5,s3,80004d5c <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d9e:	21c48513          	addi	a0,s1,540
    80004da2:	ffffd097          	auipc	ra,0xffffd
    80004da6:	63a080e7          	jalr	1594(ra) # 800023dc <wakeup>
  release(&pi->lock);
    80004daa:	8526                	mv	a0,s1
    80004dac:	ffffc097          	auipc	ra,0xffffc
    80004db0:	eec080e7          	jalr	-276(ra) # 80000c98 <release>
  return i;
}
    80004db4:	854e                	mv	a0,s3
    80004db6:	60a6                	ld	ra,72(sp)
    80004db8:	6406                	ld	s0,64(sp)
    80004dba:	74e2                	ld	s1,56(sp)
    80004dbc:	7942                	ld	s2,48(sp)
    80004dbe:	79a2                	ld	s3,40(sp)
    80004dc0:	7a02                	ld	s4,32(sp)
    80004dc2:	6ae2                	ld	s5,24(sp)
    80004dc4:	6b42                	ld	s6,16(sp)
    80004dc6:	6161                	addi	sp,sp,80
    80004dc8:	8082                	ret
      release(&pi->lock);
    80004dca:	8526                	mv	a0,s1
    80004dcc:	ffffc097          	auipc	ra,0xffffc
    80004dd0:	ecc080e7          	jalr	-308(ra) # 80000c98 <release>
      return -1;
    80004dd4:	59fd                	li	s3,-1
    80004dd6:	bff9                	j	80004db4 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dd8:	4981                	li	s3,0
    80004dda:	b7d1                	j	80004d9e <piperead+0xae>

0000000080004ddc <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004ddc:	df010113          	addi	sp,sp,-528
    80004de0:	20113423          	sd	ra,520(sp)
    80004de4:	20813023          	sd	s0,512(sp)
    80004de8:	ffa6                	sd	s1,504(sp)
    80004dea:	fbca                	sd	s2,496(sp)
    80004dec:	f7ce                	sd	s3,488(sp)
    80004dee:	f3d2                	sd	s4,480(sp)
    80004df0:	efd6                	sd	s5,472(sp)
    80004df2:	ebda                	sd	s6,464(sp)
    80004df4:	e7de                	sd	s7,456(sp)
    80004df6:	e3e2                	sd	s8,448(sp)
    80004df8:	ff66                	sd	s9,440(sp)
    80004dfa:	fb6a                	sd	s10,432(sp)
    80004dfc:	f76e                	sd	s11,424(sp)
    80004dfe:	0c00                	addi	s0,sp,528
    80004e00:	84aa                	mv	s1,a0
    80004e02:	dea43c23          	sd	a0,-520(s0)
    80004e06:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e0a:	ffffd097          	auipc	ra,0xffffd
    80004e0e:	bae080e7          	jalr	-1106(ra) # 800019b8 <myproc>
    80004e12:	892a                	mv	s2,a0

  begin_op();
    80004e14:	fffff097          	auipc	ra,0xfffff
    80004e18:	49c080e7          	jalr	1180(ra) # 800042b0 <begin_op>

  if((ip = namei(path)) == 0){
    80004e1c:	8526                	mv	a0,s1
    80004e1e:	fffff097          	auipc	ra,0xfffff
    80004e22:	276080e7          	jalr	630(ra) # 80004094 <namei>
    80004e26:	c92d                	beqz	a0,80004e98 <exec+0xbc>
    80004e28:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e2a:	fffff097          	auipc	ra,0xfffff
    80004e2e:	ab4080e7          	jalr	-1356(ra) # 800038de <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e32:	04000713          	li	a4,64
    80004e36:	4681                	li	a3,0
    80004e38:	e5040613          	addi	a2,s0,-432
    80004e3c:	4581                	li	a1,0
    80004e3e:	8526                	mv	a0,s1
    80004e40:	fffff097          	auipc	ra,0xfffff
    80004e44:	d52080e7          	jalr	-686(ra) # 80003b92 <readi>
    80004e48:	04000793          	li	a5,64
    80004e4c:	00f51a63          	bne	a0,a5,80004e60 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e50:	e5042703          	lw	a4,-432(s0)
    80004e54:	464c47b7          	lui	a5,0x464c4
    80004e58:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e5c:	04f70463          	beq	a4,a5,80004ea4 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e60:	8526                	mv	a0,s1
    80004e62:	fffff097          	auipc	ra,0xfffff
    80004e66:	cde080e7          	jalr	-802(ra) # 80003b40 <iunlockput>
    end_op();
    80004e6a:	fffff097          	auipc	ra,0xfffff
    80004e6e:	4c6080e7          	jalr	1222(ra) # 80004330 <end_op>
  }
  return -1;
    80004e72:	557d                	li	a0,-1
}
    80004e74:	20813083          	ld	ra,520(sp)
    80004e78:	20013403          	ld	s0,512(sp)
    80004e7c:	74fe                	ld	s1,504(sp)
    80004e7e:	795e                	ld	s2,496(sp)
    80004e80:	79be                	ld	s3,488(sp)
    80004e82:	7a1e                	ld	s4,480(sp)
    80004e84:	6afe                	ld	s5,472(sp)
    80004e86:	6b5e                	ld	s6,464(sp)
    80004e88:	6bbe                	ld	s7,456(sp)
    80004e8a:	6c1e                	ld	s8,448(sp)
    80004e8c:	7cfa                	ld	s9,440(sp)
    80004e8e:	7d5a                	ld	s10,432(sp)
    80004e90:	7dba                	ld	s11,424(sp)
    80004e92:	21010113          	addi	sp,sp,528
    80004e96:	8082                	ret
    end_op();
    80004e98:	fffff097          	auipc	ra,0xfffff
    80004e9c:	498080e7          	jalr	1176(ra) # 80004330 <end_op>
    return -1;
    80004ea0:	557d                	li	a0,-1
    80004ea2:	bfc9                	j	80004e74 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004ea4:	854a                	mv	a0,s2
    80004ea6:	ffffd097          	auipc	ra,0xffffd
    80004eaa:	bd6080e7          	jalr	-1066(ra) # 80001a7c <proc_pagetable>
    80004eae:	8baa                	mv	s7,a0
    80004eb0:	d945                	beqz	a0,80004e60 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004eb2:	e7042983          	lw	s3,-400(s0)
    80004eb6:	e8845783          	lhu	a5,-376(s0)
    80004eba:	c7ad                	beqz	a5,80004f24 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004ebc:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ebe:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004ec0:	6c85                	lui	s9,0x1
    80004ec2:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004ec6:	def43823          	sd	a5,-528(s0)
    80004eca:	a42d                	j	800050f4 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004ecc:	00004517          	auipc	a0,0x4
    80004ed0:	83450513          	addi	a0,a0,-1996 # 80008700 <syscalls+0x290>
    80004ed4:	ffffb097          	auipc	ra,0xffffb
    80004ed8:	66a080e7          	jalr	1642(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004edc:	8756                	mv	a4,s5
    80004ede:	012d86bb          	addw	a3,s11,s2
    80004ee2:	4581                	li	a1,0
    80004ee4:	8526                	mv	a0,s1
    80004ee6:	fffff097          	auipc	ra,0xfffff
    80004eea:	cac080e7          	jalr	-852(ra) # 80003b92 <readi>
    80004eee:	2501                	sext.w	a0,a0
    80004ef0:	1aaa9963          	bne	s5,a0,800050a2 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004ef4:	6785                	lui	a5,0x1
    80004ef6:	0127893b          	addw	s2,a5,s2
    80004efa:	77fd                	lui	a5,0xfffff
    80004efc:	01478a3b          	addw	s4,a5,s4
    80004f00:	1f897163          	bgeu	s2,s8,800050e2 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004f04:	02091593          	slli	a1,s2,0x20
    80004f08:	9181                	srli	a1,a1,0x20
    80004f0a:	95ea                	add	a1,a1,s10
    80004f0c:	855e                	mv	a0,s7
    80004f0e:	ffffc097          	auipc	ra,0xffffc
    80004f12:	168080e7          	jalr	360(ra) # 80001076 <walkaddr>
    80004f16:	862a                	mv	a2,a0
    if(pa == 0)
    80004f18:	d955                	beqz	a0,80004ecc <exec+0xf0>
      n = PGSIZE;
    80004f1a:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004f1c:	fd9a70e3          	bgeu	s4,s9,80004edc <exec+0x100>
      n = sz - i;
    80004f20:	8ad2                	mv	s5,s4
    80004f22:	bf6d                	j	80004edc <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f24:	4901                	li	s2,0
  iunlockput(ip);
    80004f26:	8526                	mv	a0,s1
    80004f28:	fffff097          	auipc	ra,0xfffff
    80004f2c:	c18080e7          	jalr	-1000(ra) # 80003b40 <iunlockput>
  end_op();
    80004f30:	fffff097          	auipc	ra,0xfffff
    80004f34:	400080e7          	jalr	1024(ra) # 80004330 <end_op>
  p = myproc();
    80004f38:	ffffd097          	auipc	ra,0xffffd
    80004f3c:	a80080e7          	jalr	-1408(ra) # 800019b8 <myproc>
    80004f40:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004f42:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f46:	6785                	lui	a5,0x1
    80004f48:	17fd                	addi	a5,a5,-1
    80004f4a:	993e                	add	s2,s2,a5
    80004f4c:	757d                	lui	a0,0xfffff
    80004f4e:	00a977b3          	and	a5,s2,a0
    80004f52:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f56:	6609                	lui	a2,0x2
    80004f58:	963e                	add	a2,a2,a5
    80004f5a:	85be                	mv	a1,a5
    80004f5c:	855e                	mv	a0,s7
    80004f5e:	ffffc097          	auipc	ra,0xffffc
    80004f62:	4cc080e7          	jalr	1228(ra) # 8000142a <uvmalloc>
    80004f66:	8b2a                	mv	s6,a0
  ip = 0;
    80004f68:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f6a:	12050c63          	beqz	a0,800050a2 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f6e:	75f9                	lui	a1,0xffffe
    80004f70:	95aa                	add	a1,a1,a0
    80004f72:	855e                	mv	a0,s7
    80004f74:	ffffc097          	auipc	ra,0xffffc
    80004f78:	6d4080e7          	jalr	1748(ra) # 80001648 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f7c:	7c7d                	lui	s8,0xfffff
    80004f7e:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f80:	e0043783          	ld	a5,-512(s0)
    80004f84:	6388                	ld	a0,0(a5)
    80004f86:	c535                	beqz	a0,80004ff2 <exec+0x216>
    80004f88:	e9040993          	addi	s3,s0,-368
    80004f8c:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004f90:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004f92:	ffffc097          	auipc	ra,0xffffc
    80004f96:	ed2080e7          	jalr	-302(ra) # 80000e64 <strlen>
    80004f9a:	2505                	addiw	a0,a0,1
    80004f9c:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004fa0:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004fa4:	13896363          	bltu	s2,s8,800050ca <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004fa8:	e0043d83          	ld	s11,-512(s0)
    80004fac:	000dba03          	ld	s4,0(s11)
    80004fb0:	8552                	mv	a0,s4
    80004fb2:	ffffc097          	auipc	ra,0xffffc
    80004fb6:	eb2080e7          	jalr	-334(ra) # 80000e64 <strlen>
    80004fba:	0015069b          	addiw	a3,a0,1
    80004fbe:	8652                	mv	a2,s4
    80004fc0:	85ca                	mv	a1,s2
    80004fc2:	855e                	mv	a0,s7
    80004fc4:	ffffc097          	auipc	ra,0xffffc
    80004fc8:	6b6080e7          	jalr	1718(ra) # 8000167a <copyout>
    80004fcc:	10054363          	bltz	a0,800050d2 <exec+0x2f6>
    ustack[argc] = sp;
    80004fd0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004fd4:	0485                	addi	s1,s1,1
    80004fd6:	008d8793          	addi	a5,s11,8
    80004fda:	e0f43023          	sd	a5,-512(s0)
    80004fde:	008db503          	ld	a0,8(s11)
    80004fe2:	c911                	beqz	a0,80004ff6 <exec+0x21a>
    if(argc >= MAXARG)
    80004fe4:	09a1                	addi	s3,s3,8
    80004fe6:	fb3c96e3          	bne	s9,s3,80004f92 <exec+0x1b6>
  sz = sz1;
    80004fea:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fee:	4481                	li	s1,0
    80004ff0:	a84d                	j	800050a2 <exec+0x2c6>
  sp = sz;
    80004ff2:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ff4:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ff6:	00349793          	slli	a5,s1,0x3
    80004ffa:	f9040713          	addi	a4,s0,-112
    80004ffe:	97ba                	add	a5,a5,a4
    80005000:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005004:	00148693          	addi	a3,s1,1
    80005008:	068e                	slli	a3,a3,0x3
    8000500a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000500e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005012:	01897663          	bgeu	s2,s8,8000501e <exec+0x242>
  sz = sz1;
    80005016:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000501a:	4481                	li	s1,0
    8000501c:	a059                	j	800050a2 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000501e:	e9040613          	addi	a2,s0,-368
    80005022:	85ca                	mv	a1,s2
    80005024:	855e                	mv	a0,s7
    80005026:	ffffc097          	auipc	ra,0xffffc
    8000502a:	654080e7          	jalr	1620(ra) # 8000167a <copyout>
    8000502e:	0a054663          	bltz	a0,800050da <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005032:	058ab783          	ld	a5,88(s5)
    80005036:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000503a:	df843783          	ld	a5,-520(s0)
    8000503e:	0007c703          	lbu	a4,0(a5)
    80005042:	cf11                	beqz	a4,8000505e <exec+0x282>
    80005044:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005046:	02f00693          	li	a3,47
    8000504a:	a039                	j	80005058 <exec+0x27c>
      last = s+1;
    8000504c:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005050:	0785                	addi	a5,a5,1
    80005052:	fff7c703          	lbu	a4,-1(a5)
    80005056:	c701                	beqz	a4,8000505e <exec+0x282>
    if(*s == '/')
    80005058:	fed71ce3          	bne	a4,a3,80005050 <exec+0x274>
    8000505c:	bfc5                	j	8000504c <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    8000505e:	4641                	li	a2,16
    80005060:	df843583          	ld	a1,-520(s0)
    80005064:	158a8513          	addi	a0,s5,344
    80005068:	ffffc097          	auipc	ra,0xffffc
    8000506c:	dca080e7          	jalr	-566(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005070:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005074:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005078:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000507c:	058ab783          	ld	a5,88(s5)
    80005080:	e6843703          	ld	a4,-408(s0)
    80005084:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005086:	058ab783          	ld	a5,88(s5)
    8000508a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000508e:	85ea                	mv	a1,s10
    80005090:	ffffd097          	auipc	ra,0xffffd
    80005094:	a88080e7          	jalr	-1400(ra) # 80001b18 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005098:	0004851b          	sext.w	a0,s1
    8000509c:	bbe1                	j	80004e74 <exec+0x98>
    8000509e:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800050a2:	e0843583          	ld	a1,-504(s0)
    800050a6:	855e                	mv	a0,s7
    800050a8:	ffffd097          	auipc	ra,0xffffd
    800050ac:	a70080e7          	jalr	-1424(ra) # 80001b18 <proc_freepagetable>
  if(ip){
    800050b0:	da0498e3          	bnez	s1,80004e60 <exec+0x84>
  return -1;
    800050b4:	557d                	li	a0,-1
    800050b6:	bb7d                	j	80004e74 <exec+0x98>
    800050b8:	e1243423          	sd	s2,-504(s0)
    800050bc:	b7dd                	j	800050a2 <exec+0x2c6>
    800050be:	e1243423          	sd	s2,-504(s0)
    800050c2:	b7c5                	j	800050a2 <exec+0x2c6>
    800050c4:	e1243423          	sd	s2,-504(s0)
    800050c8:	bfe9                	j	800050a2 <exec+0x2c6>
  sz = sz1;
    800050ca:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050ce:	4481                	li	s1,0
    800050d0:	bfc9                	j	800050a2 <exec+0x2c6>
  sz = sz1;
    800050d2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050d6:	4481                	li	s1,0
    800050d8:	b7e9                	j	800050a2 <exec+0x2c6>
  sz = sz1;
    800050da:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050de:	4481                	li	s1,0
    800050e0:	b7c9                	j	800050a2 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050e2:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050e6:	2b05                	addiw	s6,s6,1
    800050e8:	0389899b          	addiw	s3,s3,56
    800050ec:	e8845783          	lhu	a5,-376(s0)
    800050f0:	e2fb5be3          	bge	s6,a5,80004f26 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800050f4:	2981                	sext.w	s3,s3
    800050f6:	03800713          	li	a4,56
    800050fa:	86ce                	mv	a3,s3
    800050fc:	e1840613          	addi	a2,s0,-488
    80005100:	4581                	li	a1,0
    80005102:	8526                	mv	a0,s1
    80005104:	fffff097          	auipc	ra,0xfffff
    80005108:	a8e080e7          	jalr	-1394(ra) # 80003b92 <readi>
    8000510c:	03800793          	li	a5,56
    80005110:	f8f517e3          	bne	a0,a5,8000509e <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005114:	e1842783          	lw	a5,-488(s0)
    80005118:	4705                	li	a4,1
    8000511a:	fce796e3          	bne	a5,a4,800050e6 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    8000511e:	e4043603          	ld	a2,-448(s0)
    80005122:	e3843783          	ld	a5,-456(s0)
    80005126:	f8f669e3          	bltu	a2,a5,800050b8 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000512a:	e2843783          	ld	a5,-472(s0)
    8000512e:	963e                	add	a2,a2,a5
    80005130:	f8f667e3          	bltu	a2,a5,800050be <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005134:	85ca                	mv	a1,s2
    80005136:	855e                	mv	a0,s7
    80005138:	ffffc097          	auipc	ra,0xffffc
    8000513c:	2f2080e7          	jalr	754(ra) # 8000142a <uvmalloc>
    80005140:	e0a43423          	sd	a0,-504(s0)
    80005144:	d141                	beqz	a0,800050c4 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005146:	e2843d03          	ld	s10,-472(s0)
    8000514a:	df043783          	ld	a5,-528(s0)
    8000514e:	00fd77b3          	and	a5,s10,a5
    80005152:	fba1                	bnez	a5,800050a2 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005154:	e2042d83          	lw	s11,-480(s0)
    80005158:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000515c:	f80c03e3          	beqz	s8,800050e2 <exec+0x306>
    80005160:	8a62                	mv	s4,s8
    80005162:	4901                	li	s2,0
    80005164:	b345                	j	80004f04 <exec+0x128>

0000000080005166 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005166:	7179                	addi	sp,sp,-48
    80005168:	f406                	sd	ra,40(sp)
    8000516a:	f022                	sd	s0,32(sp)
    8000516c:	ec26                	sd	s1,24(sp)
    8000516e:	e84a                	sd	s2,16(sp)
    80005170:	1800                	addi	s0,sp,48
    80005172:	892e                	mv	s2,a1
    80005174:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005176:	fdc40593          	addi	a1,s0,-36
    8000517a:	ffffe097          	auipc	ra,0xffffe
    8000517e:	ba8080e7          	jalr	-1112(ra) # 80002d22 <argint>
    80005182:	04054063          	bltz	a0,800051c2 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005186:	fdc42703          	lw	a4,-36(s0)
    8000518a:	47bd                	li	a5,15
    8000518c:	02e7ed63          	bltu	a5,a4,800051c6 <argfd+0x60>
    80005190:	ffffd097          	auipc	ra,0xffffd
    80005194:	828080e7          	jalr	-2008(ra) # 800019b8 <myproc>
    80005198:	fdc42703          	lw	a4,-36(s0)
    8000519c:	01a70793          	addi	a5,a4,26
    800051a0:	078e                	slli	a5,a5,0x3
    800051a2:	953e                	add	a0,a0,a5
    800051a4:	611c                	ld	a5,0(a0)
    800051a6:	c395                	beqz	a5,800051ca <argfd+0x64>
    return -1;
  if(pfd)
    800051a8:	00090463          	beqz	s2,800051b0 <argfd+0x4a>
    *pfd = fd;
    800051ac:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051b0:	4501                	li	a0,0
  if(pf)
    800051b2:	c091                	beqz	s1,800051b6 <argfd+0x50>
    *pf = f;
    800051b4:	e09c                	sd	a5,0(s1)
}
    800051b6:	70a2                	ld	ra,40(sp)
    800051b8:	7402                	ld	s0,32(sp)
    800051ba:	64e2                	ld	s1,24(sp)
    800051bc:	6942                	ld	s2,16(sp)
    800051be:	6145                	addi	sp,sp,48
    800051c0:	8082                	ret
    return -1;
    800051c2:	557d                	li	a0,-1
    800051c4:	bfcd                	j	800051b6 <argfd+0x50>
    return -1;
    800051c6:	557d                	li	a0,-1
    800051c8:	b7fd                	j	800051b6 <argfd+0x50>
    800051ca:	557d                	li	a0,-1
    800051cc:	b7ed                	j	800051b6 <argfd+0x50>

00000000800051ce <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800051ce:	1101                	addi	sp,sp,-32
    800051d0:	ec06                	sd	ra,24(sp)
    800051d2:	e822                	sd	s0,16(sp)
    800051d4:	e426                	sd	s1,8(sp)
    800051d6:	1000                	addi	s0,sp,32
    800051d8:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800051da:	ffffc097          	auipc	ra,0xffffc
    800051de:	7de080e7          	jalr	2014(ra) # 800019b8 <myproc>
    800051e2:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800051e4:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffe00d0>
    800051e8:	4501                	li	a0,0
    800051ea:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800051ec:	6398                	ld	a4,0(a5)
    800051ee:	cb19                	beqz	a4,80005204 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800051f0:	2505                	addiw	a0,a0,1
    800051f2:	07a1                	addi	a5,a5,8
    800051f4:	fed51ce3          	bne	a0,a3,800051ec <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800051f8:	557d                	li	a0,-1
}
    800051fa:	60e2                	ld	ra,24(sp)
    800051fc:	6442                	ld	s0,16(sp)
    800051fe:	64a2                	ld	s1,8(sp)
    80005200:	6105                	addi	sp,sp,32
    80005202:	8082                	ret
      p->ofile[fd] = f;
    80005204:	01a50793          	addi	a5,a0,26
    80005208:	078e                	slli	a5,a5,0x3
    8000520a:	963e                	add	a2,a2,a5
    8000520c:	e204                	sd	s1,0(a2)
      return fd;
    8000520e:	b7f5                	j	800051fa <fdalloc+0x2c>

0000000080005210 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005210:	715d                	addi	sp,sp,-80
    80005212:	e486                	sd	ra,72(sp)
    80005214:	e0a2                	sd	s0,64(sp)
    80005216:	fc26                	sd	s1,56(sp)
    80005218:	f84a                	sd	s2,48(sp)
    8000521a:	f44e                	sd	s3,40(sp)
    8000521c:	f052                	sd	s4,32(sp)
    8000521e:	ec56                	sd	s5,24(sp)
    80005220:	0880                	addi	s0,sp,80
    80005222:	89ae                	mv	s3,a1
    80005224:	8ab2                	mv	s5,a2
    80005226:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005228:	fb040593          	addi	a1,s0,-80
    8000522c:	fffff097          	auipc	ra,0xfffff
    80005230:	e86080e7          	jalr	-378(ra) # 800040b2 <nameiparent>
    80005234:	892a                	mv	s2,a0
    80005236:	12050f63          	beqz	a0,80005374 <create+0x164>
    return 0;

  ilock(dp);
    8000523a:	ffffe097          	auipc	ra,0xffffe
    8000523e:	6a4080e7          	jalr	1700(ra) # 800038de <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005242:	4601                	li	a2,0
    80005244:	fb040593          	addi	a1,s0,-80
    80005248:	854a                	mv	a0,s2
    8000524a:	fffff097          	auipc	ra,0xfffff
    8000524e:	b78080e7          	jalr	-1160(ra) # 80003dc2 <dirlookup>
    80005252:	84aa                	mv	s1,a0
    80005254:	c921                	beqz	a0,800052a4 <create+0x94>
    iunlockput(dp);
    80005256:	854a                	mv	a0,s2
    80005258:	fffff097          	auipc	ra,0xfffff
    8000525c:	8e8080e7          	jalr	-1816(ra) # 80003b40 <iunlockput>
    ilock(ip);
    80005260:	8526                	mv	a0,s1
    80005262:	ffffe097          	auipc	ra,0xffffe
    80005266:	67c080e7          	jalr	1660(ra) # 800038de <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000526a:	2981                	sext.w	s3,s3
    8000526c:	4789                	li	a5,2
    8000526e:	02f99463          	bne	s3,a5,80005296 <create+0x86>
    80005272:	0444d783          	lhu	a5,68(s1)
    80005276:	37f9                	addiw	a5,a5,-2
    80005278:	17c2                	slli	a5,a5,0x30
    8000527a:	93c1                	srli	a5,a5,0x30
    8000527c:	4705                	li	a4,1
    8000527e:	00f76c63          	bltu	a4,a5,80005296 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005282:	8526                	mv	a0,s1
    80005284:	60a6                	ld	ra,72(sp)
    80005286:	6406                	ld	s0,64(sp)
    80005288:	74e2                	ld	s1,56(sp)
    8000528a:	7942                	ld	s2,48(sp)
    8000528c:	79a2                	ld	s3,40(sp)
    8000528e:	7a02                	ld	s4,32(sp)
    80005290:	6ae2                	ld	s5,24(sp)
    80005292:	6161                	addi	sp,sp,80
    80005294:	8082                	ret
    iunlockput(ip);
    80005296:	8526                	mv	a0,s1
    80005298:	fffff097          	auipc	ra,0xfffff
    8000529c:	8a8080e7          	jalr	-1880(ra) # 80003b40 <iunlockput>
    return 0;
    800052a0:	4481                	li	s1,0
    800052a2:	b7c5                	j	80005282 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800052a4:	85ce                	mv	a1,s3
    800052a6:	00092503          	lw	a0,0(s2)
    800052aa:	ffffe097          	auipc	ra,0xffffe
    800052ae:	49c080e7          	jalr	1180(ra) # 80003746 <ialloc>
    800052b2:	84aa                	mv	s1,a0
    800052b4:	c529                	beqz	a0,800052fe <create+0xee>
  ilock(ip);
    800052b6:	ffffe097          	auipc	ra,0xffffe
    800052ba:	628080e7          	jalr	1576(ra) # 800038de <ilock>
  ip->major = major;
    800052be:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800052c2:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800052c6:	4785                	li	a5,1
    800052c8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800052cc:	8526                	mv	a0,s1
    800052ce:	ffffe097          	auipc	ra,0xffffe
    800052d2:	546080e7          	jalr	1350(ra) # 80003814 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800052d6:	2981                	sext.w	s3,s3
    800052d8:	4785                	li	a5,1
    800052da:	02f98a63          	beq	s3,a5,8000530e <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800052de:	40d0                	lw	a2,4(s1)
    800052e0:	fb040593          	addi	a1,s0,-80
    800052e4:	854a                	mv	a0,s2
    800052e6:	fffff097          	auipc	ra,0xfffff
    800052ea:	cec080e7          	jalr	-788(ra) # 80003fd2 <dirlink>
    800052ee:	06054b63          	bltz	a0,80005364 <create+0x154>
  iunlockput(dp);
    800052f2:	854a                	mv	a0,s2
    800052f4:	fffff097          	auipc	ra,0xfffff
    800052f8:	84c080e7          	jalr	-1972(ra) # 80003b40 <iunlockput>
  return ip;
    800052fc:	b759                	j	80005282 <create+0x72>
    panic("create: ialloc");
    800052fe:	00003517          	auipc	a0,0x3
    80005302:	42250513          	addi	a0,a0,1058 # 80008720 <syscalls+0x2b0>
    80005306:	ffffb097          	auipc	ra,0xffffb
    8000530a:	238080e7          	jalr	568(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    8000530e:	04a95783          	lhu	a5,74(s2)
    80005312:	2785                	addiw	a5,a5,1
    80005314:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005318:	854a                	mv	a0,s2
    8000531a:	ffffe097          	auipc	ra,0xffffe
    8000531e:	4fa080e7          	jalr	1274(ra) # 80003814 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005322:	40d0                	lw	a2,4(s1)
    80005324:	00003597          	auipc	a1,0x3
    80005328:	40c58593          	addi	a1,a1,1036 # 80008730 <syscalls+0x2c0>
    8000532c:	8526                	mv	a0,s1
    8000532e:	fffff097          	auipc	ra,0xfffff
    80005332:	ca4080e7          	jalr	-860(ra) # 80003fd2 <dirlink>
    80005336:	00054f63          	bltz	a0,80005354 <create+0x144>
    8000533a:	00492603          	lw	a2,4(s2)
    8000533e:	00003597          	auipc	a1,0x3
    80005342:	3fa58593          	addi	a1,a1,1018 # 80008738 <syscalls+0x2c8>
    80005346:	8526                	mv	a0,s1
    80005348:	fffff097          	auipc	ra,0xfffff
    8000534c:	c8a080e7          	jalr	-886(ra) # 80003fd2 <dirlink>
    80005350:	f80557e3          	bgez	a0,800052de <create+0xce>
      panic("create dots");
    80005354:	00003517          	auipc	a0,0x3
    80005358:	3ec50513          	addi	a0,a0,1004 # 80008740 <syscalls+0x2d0>
    8000535c:	ffffb097          	auipc	ra,0xffffb
    80005360:	1e2080e7          	jalr	482(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005364:	00003517          	auipc	a0,0x3
    80005368:	3ec50513          	addi	a0,a0,1004 # 80008750 <syscalls+0x2e0>
    8000536c:	ffffb097          	auipc	ra,0xffffb
    80005370:	1d2080e7          	jalr	466(ra) # 8000053e <panic>
    return 0;
    80005374:	84aa                	mv	s1,a0
    80005376:	b731                	j	80005282 <create+0x72>

0000000080005378 <sys_dup>:
{
    80005378:	7179                	addi	sp,sp,-48
    8000537a:	f406                	sd	ra,40(sp)
    8000537c:	f022                	sd	s0,32(sp)
    8000537e:	ec26                	sd	s1,24(sp)
    80005380:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005382:	fd840613          	addi	a2,s0,-40
    80005386:	4581                	li	a1,0
    80005388:	4501                	li	a0,0
    8000538a:	00000097          	auipc	ra,0x0
    8000538e:	ddc080e7          	jalr	-548(ra) # 80005166 <argfd>
    return -1;
    80005392:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005394:	02054363          	bltz	a0,800053ba <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005398:	fd843503          	ld	a0,-40(s0)
    8000539c:	00000097          	auipc	ra,0x0
    800053a0:	e32080e7          	jalr	-462(ra) # 800051ce <fdalloc>
    800053a4:	84aa                	mv	s1,a0
    return -1;
    800053a6:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800053a8:	00054963          	bltz	a0,800053ba <sys_dup+0x42>
  filedup(f);
    800053ac:	fd843503          	ld	a0,-40(s0)
    800053b0:	fffff097          	auipc	ra,0xfffff
    800053b4:	37a080e7          	jalr	890(ra) # 8000472a <filedup>
  return fd;
    800053b8:	87a6                	mv	a5,s1
}
    800053ba:	853e                	mv	a0,a5
    800053bc:	70a2                	ld	ra,40(sp)
    800053be:	7402                	ld	s0,32(sp)
    800053c0:	64e2                	ld	s1,24(sp)
    800053c2:	6145                	addi	sp,sp,48
    800053c4:	8082                	ret

00000000800053c6 <sys_read>:
{
    800053c6:	7179                	addi	sp,sp,-48
    800053c8:	f406                	sd	ra,40(sp)
    800053ca:	f022                	sd	s0,32(sp)
    800053cc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053ce:	fe840613          	addi	a2,s0,-24
    800053d2:	4581                	li	a1,0
    800053d4:	4501                	li	a0,0
    800053d6:	00000097          	auipc	ra,0x0
    800053da:	d90080e7          	jalr	-624(ra) # 80005166 <argfd>
    return -1;
    800053de:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053e0:	04054163          	bltz	a0,80005422 <sys_read+0x5c>
    800053e4:	fe440593          	addi	a1,s0,-28
    800053e8:	4509                	li	a0,2
    800053ea:	ffffe097          	auipc	ra,0xffffe
    800053ee:	938080e7          	jalr	-1736(ra) # 80002d22 <argint>
    return -1;
    800053f2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053f4:	02054763          	bltz	a0,80005422 <sys_read+0x5c>
    800053f8:	fd840593          	addi	a1,s0,-40
    800053fc:	4505                	li	a0,1
    800053fe:	ffffe097          	auipc	ra,0xffffe
    80005402:	946080e7          	jalr	-1722(ra) # 80002d44 <argaddr>
    return -1;
    80005406:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005408:	00054d63          	bltz	a0,80005422 <sys_read+0x5c>
  return fileread(f, p, n);
    8000540c:	fe442603          	lw	a2,-28(s0)
    80005410:	fd843583          	ld	a1,-40(s0)
    80005414:	fe843503          	ld	a0,-24(s0)
    80005418:	fffff097          	auipc	ra,0xfffff
    8000541c:	49e080e7          	jalr	1182(ra) # 800048b6 <fileread>
    80005420:	87aa                	mv	a5,a0
}
    80005422:	853e                	mv	a0,a5
    80005424:	70a2                	ld	ra,40(sp)
    80005426:	7402                	ld	s0,32(sp)
    80005428:	6145                	addi	sp,sp,48
    8000542a:	8082                	ret

000000008000542c <sys_write>:
{
    8000542c:	7179                	addi	sp,sp,-48
    8000542e:	f406                	sd	ra,40(sp)
    80005430:	f022                	sd	s0,32(sp)
    80005432:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005434:	fe840613          	addi	a2,s0,-24
    80005438:	4581                	li	a1,0
    8000543a:	4501                	li	a0,0
    8000543c:	00000097          	auipc	ra,0x0
    80005440:	d2a080e7          	jalr	-726(ra) # 80005166 <argfd>
    return -1;
    80005444:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005446:	04054163          	bltz	a0,80005488 <sys_write+0x5c>
    8000544a:	fe440593          	addi	a1,s0,-28
    8000544e:	4509                	li	a0,2
    80005450:	ffffe097          	auipc	ra,0xffffe
    80005454:	8d2080e7          	jalr	-1838(ra) # 80002d22 <argint>
    return -1;
    80005458:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000545a:	02054763          	bltz	a0,80005488 <sys_write+0x5c>
    8000545e:	fd840593          	addi	a1,s0,-40
    80005462:	4505                	li	a0,1
    80005464:	ffffe097          	auipc	ra,0xffffe
    80005468:	8e0080e7          	jalr	-1824(ra) # 80002d44 <argaddr>
    return -1;
    8000546c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000546e:	00054d63          	bltz	a0,80005488 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005472:	fe442603          	lw	a2,-28(s0)
    80005476:	fd843583          	ld	a1,-40(s0)
    8000547a:	fe843503          	ld	a0,-24(s0)
    8000547e:	fffff097          	auipc	ra,0xfffff
    80005482:	4fa080e7          	jalr	1274(ra) # 80004978 <filewrite>
    80005486:	87aa                	mv	a5,a0
}
    80005488:	853e                	mv	a0,a5
    8000548a:	70a2                	ld	ra,40(sp)
    8000548c:	7402                	ld	s0,32(sp)
    8000548e:	6145                	addi	sp,sp,48
    80005490:	8082                	ret

0000000080005492 <sys_close>:
{
    80005492:	1101                	addi	sp,sp,-32
    80005494:	ec06                	sd	ra,24(sp)
    80005496:	e822                	sd	s0,16(sp)
    80005498:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000549a:	fe040613          	addi	a2,s0,-32
    8000549e:	fec40593          	addi	a1,s0,-20
    800054a2:	4501                	li	a0,0
    800054a4:	00000097          	auipc	ra,0x0
    800054a8:	cc2080e7          	jalr	-830(ra) # 80005166 <argfd>
    return -1;
    800054ac:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800054ae:	02054463          	bltz	a0,800054d6 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800054b2:	ffffc097          	auipc	ra,0xffffc
    800054b6:	506080e7          	jalr	1286(ra) # 800019b8 <myproc>
    800054ba:	fec42783          	lw	a5,-20(s0)
    800054be:	07e9                	addi	a5,a5,26
    800054c0:	078e                	slli	a5,a5,0x3
    800054c2:	97aa                	add	a5,a5,a0
    800054c4:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800054c8:	fe043503          	ld	a0,-32(s0)
    800054cc:	fffff097          	auipc	ra,0xfffff
    800054d0:	2b0080e7          	jalr	688(ra) # 8000477c <fileclose>
  return 0;
    800054d4:	4781                	li	a5,0
}
    800054d6:	853e                	mv	a0,a5
    800054d8:	60e2                	ld	ra,24(sp)
    800054da:	6442                	ld	s0,16(sp)
    800054dc:	6105                	addi	sp,sp,32
    800054de:	8082                	ret

00000000800054e0 <sys_fstat>:
{
    800054e0:	1101                	addi	sp,sp,-32
    800054e2:	ec06                	sd	ra,24(sp)
    800054e4:	e822                	sd	s0,16(sp)
    800054e6:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054e8:	fe840613          	addi	a2,s0,-24
    800054ec:	4581                	li	a1,0
    800054ee:	4501                	li	a0,0
    800054f0:	00000097          	auipc	ra,0x0
    800054f4:	c76080e7          	jalr	-906(ra) # 80005166 <argfd>
    return -1;
    800054f8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054fa:	02054563          	bltz	a0,80005524 <sys_fstat+0x44>
    800054fe:	fe040593          	addi	a1,s0,-32
    80005502:	4505                	li	a0,1
    80005504:	ffffe097          	auipc	ra,0xffffe
    80005508:	840080e7          	jalr	-1984(ra) # 80002d44 <argaddr>
    return -1;
    8000550c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000550e:	00054b63          	bltz	a0,80005524 <sys_fstat+0x44>
  return filestat(f, st);
    80005512:	fe043583          	ld	a1,-32(s0)
    80005516:	fe843503          	ld	a0,-24(s0)
    8000551a:	fffff097          	auipc	ra,0xfffff
    8000551e:	32a080e7          	jalr	810(ra) # 80004844 <filestat>
    80005522:	87aa                	mv	a5,a0
}
    80005524:	853e                	mv	a0,a5
    80005526:	60e2                	ld	ra,24(sp)
    80005528:	6442                	ld	s0,16(sp)
    8000552a:	6105                	addi	sp,sp,32
    8000552c:	8082                	ret

000000008000552e <sys_link>:
{
    8000552e:	7169                	addi	sp,sp,-304
    80005530:	f606                	sd	ra,296(sp)
    80005532:	f222                	sd	s0,288(sp)
    80005534:	ee26                	sd	s1,280(sp)
    80005536:	ea4a                	sd	s2,272(sp)
    80005538:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000553a:	08000613          	li	a2,128
    8000553e:	ed040593          	addi	a1,s0,-304
    80005542:	4501                	li	a0,0
    80005544:	ffffe097          	auipc	ra,0xffffe
    80005548:	822080e7          	jalr	-2014(ra) # 80002d66 <argstr>
    return -1;
    8000554c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000554e:	10054e63          	bltz	a0,8000566a <sys_link+0x13c>
    80005552:	08000613          	li	a2,128
    80005556:	f5040593          	addi	a1,s0,-176
    8000555a:	4505                	li	a0,1
    8000555c:	ffffe097          	auipc	ra,0xffffe
    80005560:	80a080e7          	jalr	-2038(ra) # 80002d66 <argstr>
    return -1;
    80005564:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005566:	10054263          	bltz	a0,8000566a <sys_link+0x13c>
  begin_op();
    8000556a:	fffff097          	auipc	ra,0xfffff
    8000556e:	d46080e7          	jalr	-698(ra) # 800042b0 <begin_op>
  if((ip = namei(old)) == 0){
    80005572:	ed040513          	addi	a0,s0,-304
    80005576:	fffff097          	auipc	ra,0xfffff
    8000557a:	b1e080e7          	jalr	-1250(ra) # 80004094 <namei>
    8000557e:	84aa                	mv	s1,a0
    80005580:	c551                	beqz	a0,8000560c <sys_link+0xde>
  ilock(ip);
    80005582:	ffffe097          	auipc	ra,0xffffe
    80005586:	35c080e7          	jalr	860(ra) # 800038de <ilock>
  if(ip->type == T_DIR){
    8000558a:	04449703          	lh	a4,68(s1)
    8000558e:	4785                	li	a5,1
    80005590:	08f70463          	beq	a4,a5,80005618 <sys_link+0xea>
  ip->nlink++;
    80005594:	04a4d783          	lhu	a5,74(s1)
    80005598:	2785                	addiw	a5,a5,1
    8000559a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000559e:	8526                	mv	a0,s1
    800055a0:	ffffe097          	auipc	ra,0xffffe
    800055a4:	274080e7          	jalr	628(ra) # 80003814 <iupdate>
  iunlock(ip);
    800055a8:	8526                	mv	a0,s1
    800055aa:	ffffe097          	auipc	ra,0xffffe
    800055ae:	3f6080e7          	jalr	1014(ra) # 800039a0 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055b2:	fd040593          	addi	a1,s0,-48
    800055b6:	f5040513          	addi	a0,s0,-176
    800055ba:	fffff097          	auipc	ra,0xfffff
    800055be:	af8080e7          	jalr	-1288(ra) # 800040b2 <nameiparent>
    800055c2:	892a                	mv	s2,a0
    800055c4:	c935                	beqz	a0,80005638 <sys_link+0x10a>
  ilock(dp);
    800055c6:	ffffe097          	auipc	ra,0xffffe
    800055ca:	318080e7          	jalr	792(ra) # 800038de <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800055ce:	00092703          	lw	a4,0(s2)
    800055d2:	409c                	lw	a5,0(s1)
    800055d4:	04f71d63          	bne	a4,a5,8000562e <sys_link+0x100>
    800055d8:	40d0                	lw	a2,4(s1)
    800055da:	fd040593          	addi	a1,s0,-48
    800055de:	854a                	mv	a0,s2
    800055e0:	fffff097          	auipc	ra,0xfffff
    800055e4:	9f2080e7          	jalr	-1550(ra) # 80003fd2 <dirlink>
    800055e8:	04054363          	bltz	a0,8000562e <sys_link+0x100>
  iunlockput(dp);
    800055ec:	854a                	mv	a0,s2
    800055ee:	ffffe097          	auipc	ra,0xffffe
    800055f2:	552080e7          	jalr	1362(ra) # 80003b40 <iunlockput>
  iput(ip);
    800055f6:	8526                	mv	a0,s1
    800055f8:	ffffe097          	auipc	ra,0xffffe
    800055fc:	4a0080e7          	jalr	1184(ra) # 80003a98 <iput>
  end_op();
    80005600:	fffff097          	auipc	ra,0xfffff
    80005604:	d30080e7          	jalr	-720(ra) # 80004330 <end_op>
  return 0;
    80005608:	4781                	li	a5,0
    8000560a:	a085                	j	8000566a <sys_link+0x13c>
    end_op();
    8000560c:	fffff097          	auipc	ra,0xfffff
    80005610:	d24080e7          	jalr	-732(ra) # 80004330 <end_op>
    return -1;
    80005614:	57fd                	li	a5,-1
    80005616:	a891                	j	8000566a <sys_link+0x13c>
    iunlockput(ip);
    80005618:	8526                	mv	a0,s1
    8000561a:	ffffe097          	auipc	ra,0xffffe
    8000561e:	526080e7          	jalr	1318(ra) # 80003b40 <iunlockput>
    end_op();
    80005622:	fffff097          	auipc	ra,0xfffff
    80005626:	d0e080e7          	jalr	-754(ra) # 80004330 <end_op>
    return -1;
    8000562a:	57fd                	li	a5,-1
    8000562c:	a83d                	j	8000566a <sys_link+0x13c>
    iunlockput(dp);
    8000562e:	854a                	mv	a0,s2
    80005630:	ffffe097          	auipc	ra,0xffffe
    80005634:	510080e7          	jalr	1296(ra) # 80003b40 <iunlockput>
  ilock(ip);
    80005638:	8526                	mv	a0,s1
    8000563a:	ffffe097          	auipc	ra,0xffffe
    8000563e:	2a4080e7          	jalr	676(ra) # 800038de <ilock>
  ip->nlink--;
    80005642:	04a4d783          	lhu	a5,74(s1)
    80005646:	37fd                	addiw	a5,a5,-1
    80005648:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000564c:	8526                	mv	a0,s1
    8000564e:	ffffe097          	auipc	ra,0xffffe
    80005652:	1c6080e7          	jalr	454(ra) # 80003814 <iupdate>
  iunlockput(ip);
    80005656:	8526                	mv	a0,s1
    80005658:	ffffe097          	auipc	ra,0xffffe
    8000565c:	4e8080e7          	jalr	1256(ra) # 80003b40 <iunlockput>
  end_op();
    80005660:	fffff097          	auipc	ra,0xfffff
    80005664:	cd0080e7          	jalr	-816(ra) # 80004330 <end_op>
  return -1;
    80005668:	57fd                	li	a5,-1
}
    8000566a:	853e                	mv	a0,a5
    8000566c:	70b2                	ld	ra,296(sp)
    8000566e:	7412                	ld	s0,288(sp)
    80005670:	64f2                	ld	s1,280(sp)
    80005672:	6952                	ld	s2,272(sp)
    80005674:	6155                	addi	sp,sp,304
    80005676:	8082                	ret

0000000080005678 <sys_unlink>:
{
    80005678:	7151                	addi	sp,sp,-240
    8000567a:	f586                	sd	ra,232(sp)
    8000567c:	f1a2                	sd	s0,224(sp)
    8000567e:	eda6                	sd	s1,216(sp)
    80005680:	e9ca                	sd	s2,208(sp)
    80005682:	e5ce                	sd	s3,200(sp)
    80005684:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005686:	08000613          	li	a2,128
    8000568a:	f3040593          	addi	a1,s0,-208
    8000568e:	4501                	li	a0,0
    80005690:	ffffd097          	auipc	ra,0xffffd
    80005694:	6d6080e7          	jalr	1750(ra) # 80002d66 <argstr>
    80005698:	18054163          	bltz	a0,8000581a <sys_unlink+0x1a2>
  begin_op();
    8000569c:	fffff097          	auipc	ra,0xfffff
    800056a0:	c14080e7          	jalr	-1004(ra) # 800042b0 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800056a4:	fb040593          	addi	a1,s0,-80
    800056a8:	f3040513          	addi	a0,s0,-208
    800056ac:	fffff097          	auipc	ra,0xfffff
    800056b0:	a06080e7          	jalr	-1530(ra) # 800040b2 <nameiparent>
    800056b4:	84aa                	mv	s1,a0
    800056b6:	c979                	beqz	a0,8000578c <sys_unlink+0x114>
  ilock(dp);
    800056b8:	ffffe097          	auipc	ra,0xffffe
    800056bc:	226080e7          	jalr	550(ra) # 800038de <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800056c0:	00003597          	auipc	a1,0x3
    800056c4:	07058593          	addi	a1,a1,112 # 80008730 <syscalls+0x2c0>
    800056c8:	fb040513          	addi	a0,s0,-80
    800056cc:	ffffe097          	auipc	ra,0xffffe
    800056d0:	6dc080e7          	jalr	1756(ra) # 80003da8 <namecmp>
    800056d4:	14050a63          	beqz	a0,80005828 <sys_unlink+0x1b0>
    800056d8:	00003597          	auipc	a1,0x3
    800056dc:	06058593          	addi	a1,a1,96 # 80008738 <syscalls+0x2c8>
    800056e0:	fb040513          	addi	a0,s0,-80
    800056e4:	ffffe097          	auipc	ra,0xffffe
    800056e8:	6c4080e7          	jalr	1732(ra) # 80003da8 <namecmp>
    800056ec:	12050e63          	beqz	a0,80005828 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800056f0:	f2c40613          	addi	a2,s0,-212
    800056f4:	fb040593          	addi	a1,s0,-80
    800056f8:	8526                	mv	a0,s1
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	6c8080e7          	jalr	1736(ra) # 80003dc2 <dirlookup>
    80005702:	892a                	mv	s2,a0
    80005704:	12050263          	beqz	a0,80005828 <sys_unlink+0x1b0>
  ilock(ip);
    80005708:	ffffe097          	auipc	ra,0xffffe
    8000570c:	1d6080e7          	jalr	470(ra) # 800038de <ilock>
  if(ip->nlink < 1)
    80005710:	04a91783          	lh	a5,74(s2)
    80005714:	08f05263          	blez	a5,80005798 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005718:	04491703          	lh	a4,68(s2)
    8000571c:	4785                	li	a5,1
    8000571e:	08f70563          	beq	a4,a5,800057a8 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005722:	4641                	li	a2,16
    80005724:	4581                	li	a1,0
    80005726:	fc040513          	addi	a0,s0,-64
    8000572a:	ffffb097          	auipc	ra,0xffffb
    8000572e:	5b6080e7          	jalr	1462(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005732:	4741                	li	a4,16
    80005734:	f2c42683          	lw	a3,-212(s0)
    80005738:	fc040613          	addi	a2,s0,-64
    8000573c:	4581                	li	a1,0
    8000573e:	8526                	mv	a0,s1
    80005740:	ffffe097          	auipc	ra,0xffffe
    80005744:	54a080e7          	jalr	1354(ra) # 80003c8a <writei>
    80005748:	47c1                	li	a5,16
    8000574a:	0af51563          	bne	a0,a5,800057f4 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000574e:	04491703          	lh	a4,68(s2)
    80005752:	4785                	li	a5,1
    80005754:	0af70863          	beq	a4,a5,80005804 <sys_unlink+0x18c>
  iunlockput(dp);
    80005758:	8526                	mv	a0,s1
    8000575a:	ffffe097          	auipc	ra,0xffffe
    8000575e:	3e6080e7          	jalr	998(ra) # 80003b40 <iunlockput>
  ip->nlink--;
    80005762:	04a95783          	lhu	a5,74(s2)
    80005766:	37fd                	addiw	a5,a5,-1
    80005768:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000576c:	854a                	mv	a0,s2
    8000576e:	ffffe097          	auipc	ra,0xffffe
    80005772:	0a6080e7          	jalr	166(ra) # 80003814 <iupdate>
  iunlockput(ip);
    80005776:	854a                	mv	a0,s2
    80005778:	ffffe097          	auipc	ra,0xffffe
    8000577c:	3c8080e7          	jalr	968(ra) # 80003b40 <iunlockput>
  end_op();
    80005780:	fffff097          	auipc	ra,0xfffff
    80005784:	bb0080e7          	jalr	-1104(ra) # 80004330 <end_op>
  return 0;
    80005788:	4501                	li	a0,0
    8000578a:	a84d                	j	8000583c <sys_unlink+0x1c4>
    end_op();
    8000578c:	fffff097          	auipc	ra,0xfffff
    80005790:	ba4080e7          	jalr	-1116(ra) # 80004330 <end_op>
    return -1;
    80005794:	557d                	li	a0,-1
    80005796:	a05d                	j	8000583c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005798:	00003517          	auipc	a0,0x3
    8000579c:	fc850513          	addi	a0,a0,-56 # 80008760 <syscalls+0x2f0>
    800057a0:	ffffb097          	auipc	ra,0xffffb
    800057a4:	d9e080e7          	jalr	-610(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057a8:	04c92703          	lw	a4,76(s2)
    800057ac:	02000793          	li	a5,32
    800057b0:	f6e7f9e3          	bgeu	a5,a4,80005722 <sys_unlink+0xaa>
    800057b4:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057b8:	4741                	li	a4,16
    800057ba:	86ce                	mv	a3,s3
    800057bc:	f1840613          	addi	a2,s0,-232
    800057c0:	4581                	li	a1,0
    800057c2:	854a                	mv	a0,s2
    800057c4:	ffffe097          	auipc	ra,0xffffe
    800057c8:	3ce080e7          	jalr	974(ra) # 80003b92 <readi>
    800057cc:	47c1                	li	a5,16
    800057ce:	00f51b63          	bne	a0,a5,800057e4 <sys_unlink+0x16c>
    if(de.inum != 0)
    800057d2:	f1845783          	lhu	a5,-232(s0)
    800057d6:	e7a1                	bnez	a5,8000581e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057d8:	29c1                	addiw	s3,s3,16
    800057da:	04c92783          	lw	a5,76(s2)
    800057de:	fcf9ede3          	bltu	s3,a5,800057b8 <sys_unlink+0x140>
    800057e2:	b781                	j	80005722 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800057e4:	00003517          	auipc	a0,0x3
    800057e8:	f9450513          	addi	a0,a0,-108 # 80008778 <syscalls+0x308>
    800057ec:	ffffb097          	auipc	ra,0xffffb
    800057f0:	d52080e7          	jalr	-686(ra) # 8000053e <panic>
    panic("unlink: writei");
    800057f4:	00003517          	auipc	a0,0x3
    800057f8:	f9c50513          	addi	a0,a0,-100 # 80008790 <syscalls+0x320>
    800057fc:	ffffb097          	auipc	ra,0xffffb
    80005800:	d42080e7          	jalr	-702(ra) # 8000053e <panic>
    dp->nlink--;
    80005804:	04a4d783          	lhu	a5,74(s1)
    80005808:	37fd                	addiw	a5,a5,-1
    8000580a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000580e:	8526                	mv	a0,s1
    80005810:	ffffe097          	auipc	ra,0xffffe
    80005814:	004080e7          	jalr	4(ra) # 80003814 <iupdate>
    80005818:	b781                	j	80005758 <sys_unlink+0xe0>
    return -1;
    8000581a:	557d                	li	a0,-1
    8000581c:	a005                	j	8000583c <sys_unlink+0x1c4>
    iunlockput(ip);
    8000581e:	854a                	mv	a0,s2
    80005820:	ffffe097          	auipc	ra,0xffffe
    80005824:	320080e7          	jalr	800(ra) # 80003b40 <iunlockput>
  iunlockput(dp);
    80005828:	8526                	mv	a0,s1
    8000582a:	ffffe097          	auipc	ra,0xffffe
    8000582e:	316080e7          	jalr	790(ra) # 80003b40 <iunlockput>
  end_op();
    80005832:	fffff097          	auipc	ra,0xfffff
    80005836:	afe080e7          	jalr	-1282(ra) # 80004330 <end_op>
  return -1;
    8000583a:	557d                	li	a0,-1
}
    8000583c:	70ae                	ld	ra,232(sp)
    8000583e:	740e                	ld	s0,224(sp)
    80005840:	64ee                	ld	s1,216(sp)
    80005842:	694e                	ld	s2,208(sp)
    80005844:	69ae                	ld	s3,200(sp)
    80005846:	616d                	addi	sp,sp,240
    80005848:	8082                	ret

000000008000584a <sys_open>:

uint64
sys_open(void)
{
    8000584a:	7131                	addi	sp,sp,-192
    8000584c:	fd06                	sd	ra,184(sp)
    8000584e:	f922                	sd	s0,176(sp)
    80005850:	f526                	sd	s1,168(sp)
    80005852:	f14a                	sd	s2,160(sp)
    80005854:	ed4e                	sd	s3,152(sp)
    80005856:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005858:	08000613          	li	a2,128
    8000585c:	f5040593          	addi	a1,s0,-176
    80005860:	4501                	li	a0,0
    80005862:	ffffd097          	auipc	ra,0xffffd
    80005866:	504080e7          	jalr	1284(ra) # 80002d66 <argstr>
    return -1;
    8000586a:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000586c:	0c054163          	bltz	a0,8000592e <sys_open+0xe4>
    80005870:	f4c40593          	addi	a1,s0,-180
    80005874:	4505                	li	a0,1
    80005876:	ffffd097          	auipc	ra,0xffffd
    8000587a:	4ac080e7          	jalr	1196(ra) # 80002d22 <argint>
    8000587e:	0a054863          	bltz	a0,8000592e <sys_open+0xe4>

  begin_op();
    80005882:	fffff097          	auipc	ra,0xfffff
    80005886:	a2e080e7          	jalr	-1490(ra) # 800042b0 <begin_op>

  if(omode & O_CREATE){
    8000588a:	f4c42783          	lw	a5,-180(s0)
    8000588e:	2007f793          	andi	a5,a5,512
    80005892:	cbdd                	beqz	a5,80005948 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005894:	4681                	li	a3,0
    80005896:	4601                	li	a2,0
    80005898:	4589                	li	a1,2
    8000589a:	f5040513          	addi	a0,s0,-176
    8000589e:	00000097          	auipc	ra,0x0
    800058a2:	972080e7          	jalr	-1678(ra) # 80005210 <create>
    800058a6:	892a                	mv	s2,a0
    if(ip == 0){
    800058a8:	c959                	beqz	a0,8000593e <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800058aa:	04491703          	lh	a4,68(s2)
    800058ae:	478d                	li	a5,3
    800058b0:	00f71763          	bne	a4,a5,800058be <sys_open+0x74>
    800058b4:	04695703          	lhu	a4,70(s2)
    800058b8:	47a5                	li	a5,9
    800058ba:	0ce7ec63          	bltu	a5,a4,80005992 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800058be:	fffff097          	auipc	ra,0xfffff
    800058c2:	e02080e7          	jalr	-510(ra) # 800046c0 <filealloc>
    800058c6:	89aa                	mv	s3,a0
    800058c8:	10050263          	beqz	a0,800059cc <sys_open+0x182>
    800058cc:	00000097          	auipc	ra,0x0
    800058d0:	902080e7          	jalr	-1790(ra) # 800051ce <fdalloc>
    800058d4:	84aa                	mv	s1,a0
    800058d6:	0e054663          	bltz	a0,800059c2 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800058da:	04491703          	lh	a4,68(s2)
    800058de:	478d                	li	a5,3
    800058e0:	0cf70463          	beq	a4,a5,800059a8 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800058e4:	4789                	li	a5,2
    800058e6:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800058ea:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800058ee:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800058f2:	f4c42783          	lw	a5,-180(s0)
    800058f6:	0017c713          	xori	a4,a5,1
    800058fa:	8b05                	andi	a4,a4,1
    800058fc:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005900:	0037f713          	andi	a4,a5,3
    80005904:	00e03733          	snez	a4,a4
    80005908:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000590c:	4007f793          	andi	a5,a5,1024
    80005910:	c791                	beqz	a5,8000591c <sys_open+0xd2>
    80005912:	04491703          	lh	a4,68(s2)
    80005916:	4789                	li	a5,2
    80005918:	08f70f63          	beq	a4,a5,800059b6 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000591c:	854a                	mv	a0,s2
    8000591e:	ffffe097          	auipc	ra,0xffffe
    80005922:	082080e7          	jalr	130(ra) # 800039a0 <iunlock>
  end_op();
    80005926:	fffff097          	auipc	ra,0xfffff
    8000592a:	a0a080e7          	jalr	-1526(ra) # 80004330 <end_op>

  return fd;
}
    8000592e:	8526                	mv	a0,s1
    80005930:	70ea                	ld	ra,184(sp)
    80005932:	744a                	ld	s0,176(sp)
    80005934:	74aa                	ld	s1,168(sp)
    80005936:	790a                	ld	s2,160(sp)
    80005938:	69ea                	ld	s3,152(sp)
    8000593a:	6129                	addi	sp,sp,192
    8000593c:	8082                	ret
      end_op();
    8000593e:	fffff097          	auipc	ra,0xfffff
    80005942:	9f2080e7          	jalr	-1550(ra) # 80004330 <end_op>
      return -1;
    80005946:	b7e5                	j	8000592e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005948:	f5040513          	addi	a0,s0,-176
    8000594c:	ffffe097          	auipc	ra,0xffffe
    80005950:	748080e7          	jalr	1864(ra) # 80004094 <namei>
    80005954:	892a                	mv	s2,a0
    80005956:	c905                	beqz	a0,80005986 <sys_open+0x13c>
    ilock(ip);
    80005958:	ffffe097          	auipc	ra,0xffffe
    8000595c:	f86080e7          	jalr	-122(ra) # 800038de <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005960:	04491703          	lh	a4,68(s2)
    80005964:	4785                	li	a5,1
    80005966:	f4f712e3          	bne	a4,a5,800058aa <sys_open+0x60>
    8000596a:	f4c42783          	lw	a5,-180(s0)
    8000596e:	dba1                	beqz	a5,800058be <sys_open+0x74>
      iunlockput(ip);
    80005970:	854a                	mv	a0,s2
    80005972:	ffffe097          	auipc	ra,0xffffe
    80005976:	1ce080e7          	jalr	462(ra) # 80003b40 <iunlockput>
      end_op();
    8000597a:	fffff097          	auipc	ra,0xfffff
    8000597e:	9b6080e7          	jalr	-1610(ra) # 80004330 <end_op>
      return -1;
    80005982:	54fd                	li	s1,-1
    80005984:	b76d                	j	8000592e <sys_open+0xe4>
      end_op();
    80005986:	fffff097          	auipc	ra,0xfffff
    8000598a:	9aa080e7          	jalr	-1622(ra) # 80004330 <end_op>
      return -1;
    8000598e:	54fd                	li	s1,-1
    80005990:	bf79                	j	8000592e <sys_open+0xe4>
    iunlockput(ip);
    80005992:	854a                	mv	a0,s2
    80005994:	ffffe097          	auipc	ra,0xffffe
    80005998:	1ac080e7          	jalr	428(ra) # 80003b40 <iunlockput>
    end_op();
    8000599c:	fffff097          	auipc	ra,0xfffff
    800059a0:	994080e7          	jalr	-1644(ra) # 80004330 <end_op>
    return -1;
    800059a4:	54fd                	li	s1,-1
    800059a6:	b761                	j	8000592e <sys_open+0xe4>
    f->type = FD_DEVICE;
    800059a8:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800059ac:	04691783          	lh	a5,70(s2)
    800059b0:	02f99223          	sh	a5,36(s3)
    800059b4:	bf2d                	j	800058ee <sys_open+0xa4>
    itrunc(ip);
    800059b6:	854a                	mv	a0,s2
    800059b8:	ffffe097          	auipc	ra,0xffffe
    800059bc:	034080e7          	jalr	52(ra) # 800039ec <itrunc>
    800059c0:	bfb1                	j	8000591c <sys_open+0xd2>
      fileclose(f);
    800059c2:	854e                	mv	a0,s3
    800059c4:	fffff097          	auipc	ra,0xfffff
    800059c8:	db8080e7          	jalr	-584(ra) # 8000477c <fileclose>
    iunlockput(ip);
    800059cc:	854a                	mv	a0,s2
    800059ce:	ffffe097          	auipc	ra,0xffffe
    800059d2:	172080e7          	jalr	370(ra) # 80003b40 <iunlockput>
    end_op();
    800059d6:	fffff097          	auipc	ra,0xfffff
    800059da:	95a080e7          	jalr	-1702(ra) # 80004330 <end_op>
    return -1;
    800059de:	54fd                	li	s1,-1
    800059e0:	b7b9                	j	8000592e <sys_open+0xe4>

00000000800059e2 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800059e2:	7175                	addi	sp,sp,-144
    800059e4:	e506                	sd	ra,136(sp)
    800059e6:	e122                	sd	s0,128(sp)
    800059e8:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800059ea:	fffff097          	auipc	ra,0xfffff
    800059ee:	8c6080e7          	jalr	-1850(ra) # 800042b0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800059f2:	08000613          	li	a2,128
    800059f6:	f7040593          	addi	a1,s0,-144
    800059fa:	4501                	li	a0,0
    800059fc:	ffffd097          	auipc	ra,0xffffd
    80005a00:	36a080e7          	jalr	874(ra) # 80002d66 <argstr>
    80005a04:	02054963          	bltz	a0,80005a36 <sys_mkdir+0x54>
    80005a08:	4681                	li	a3,0
    80005a0a:	4601                	li	a2,0
    80005a0c:	4585                	li	a1,1
    80005a0e:	f7040513          	addi	a0,s0,-144
    80005a12:	fffff097          	auipc	ra,0xfffff
    80005a16:	7fe080e7          	jalr	2046(ra) # 80005210 <create>
    80005a1a:	cd11                	beqz	a0,80005a36 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a1c:	ffffe097          	auipc	ra,0xffffe
    80005a20:	124080e7          	jalr	292(ra) # 80003b40 <iunlockput>
  end_op();
    80005a24:	fffff097          	auipc	ra,0xfffff
    80005a28:	90c080e7          	jalr	-1780(ra) # 80004330 <end_op>
  return 0;
    80005a2c:	4501                	li	a0,0
}
    80005a2e:	60aa                	ld	ra,136(sp)
    80005a30:	640a                	ld	s0,128(sp)
    80005a32:	6149                	addi	sp,sp,144
    80005a34:	8082                	ret
    end_op();
    80005a36:	fffff097          	auipc	ra,0xfffff
    80005a3a:	8fa080e7          	jalr	-1798(ra) # 80004330 <end_op>
    return -1;
    80005a3e:	557d                	li	a0,-1
    80005a40:	b7fd                	j	80005a2e <sys_mkdir+0x4c>

0000000080005a42 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a42:	7135                	addi	sp,sp,-160
    80005a44:	ed06                	sd	ra,152(sp)
    80005a46:	e922                	sd	s0,144(sp)
    80005a48:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a4a:	fffff097          	auipc	ra,0xfffff
    80005a4e:	866080e7          	jalr	-1946(ra) # 800042b0 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a52:	08000613          	li	a2,128
    80005a56:	f7040593          	addi	a1,s0,-144
    80005a5a:	4501                	li	a0,0
    80005a5c:	ffffd097          	auipc	ra,0xffffd
    80005a60:	30a080e7          	jalr	778(ra) # 80002d66 <argstr>
    80005a64:	04054a63          	bltz	a0,80005ab8 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005a68:	f6c40593          	addi	a1,s0,-148
    80005a6c:	4505                	li	a0,1
    80005a6e:	ffffd097          	auipc	ra,0xffffd
    80005a72:	2b4080e7          	jalr	692(ra) # 80002d22 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a76:	04054163          	bltz	a0,80005ab8 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a7a:	f6840593          	addi	a1,s0,-152
    80005a7e:	4509                	li	a0,2
    80005a80:	ffffd097          	auipc	ra,0xffffd
    80005a84:	2a2080e7          	jalr	674(ra) # 80002d22 <argint>
     argint(1, &major) < 0 ||
    80005a88:	02054863          	bltz	a0,80005ab8 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a8c:	f6841683          	lh	a3,-152(s0)
    80005a90:	f6c41603          	lh	a2,-148(s0)
    80005a94:	458d                	li	a1,3
    80005a96:	f7040513          	addi	a0,s0,-144
    80005a9a:	fffff097          	auipc	ra,0xfffff
    80005a9e:	776080e7          	jalr	1910(ra) # 80005210 <create>
     argint(2, &minor) < 0 ||
    80005aa2:	c919                	beqz	a0,80005ab8 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005aa4:	ffffe097          	auipc	ra,0xffffe
    80005aa8:	09c080e7          	jalr	156(ra) # 80003b40 <iunlockput>
  end_op();
    80005aac:	fffff097          	auipc	ra,0xfffff
    80005ab0:	884080e7          	jalr	-1916(ra) # 80004330 <end_op>
  return 0;
    80005ab4:	4501                	li	a0,0
    80005ab6:	a031                	j	80005ac2 <sys_mknod+0x80>
    end_op();
    80005ab8:	fffff097          	auipc	ra,0xfffff
    80005abc:	878080e7          	jalr	-1928(ra) # 80004330 <end_op>
    return -1;
    80005ac0:	557d                	li	a0,-1
}
    80005ac2:	60ea                	ld	ra,152(sp)
    80005ac4:	644a                	ld	s0,144(sp)
    80005ac6:	610d                	addi	sp,sp,160
    80005ac8:	8082                	ret

0000000080005aca <sys_chdir>:

uint64
sys_chdir(void)
{
    80005aca:	7135                	addi	sp,sp,-160
    80005acc:	ed06                	sd	ra,152(sp)
    80005ace:	e922                	sd	s0,144(sp)
    80005ad0:	e526                	sd	s1,136(sp)
    80005ad2:	e14a                	sd	s2,128(sp)
    80005ad4:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005ad6:	ffffc097          	auipc	ra,0xffffc
    80005ada:	ee2080e7          	jalr	-286(ra) # 800019b8 <myproc>
    80005ade:	892a                	mv	s2,a0
  
  begin_op();
    80005ae0:	ffffe097          	auipc	ra,0xffffe
    80005ae4:	7d0080e7          	jalr	2000(ra) # 800042b0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ae8:	08000613          	li	a2,128
    80005aec:	f6040593          	addi	a1,s0,-160
    80005af0:	4501                	li	a0,0
    80005af2:	ffffd097          	auipc	ra,0xffffd
    80005af6:	274080e7          	jalr	628(ra) # 80002d66 <argstr>
    80005afa:	04054b63          	bltz	a0,80005b50 <sys_chdir+0x86>
    80005afe:	f6040513          	addi	a0,s0,-160
    80005b02:	ffffe097          	auipc	ra,0xffffe
    80005b06:	592080e7          	jalr	1426(ra) # 80004094 <namei>
    80005b0a:	84aa                	mv	s1,a0
    80005b0c:	c131                	beqz	a0,80005b50 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b0e:	ffffe097          	auipc	ra,0xffffe
    80005b12:	dd0080e7          	jalr	-560(ra) # 800038de <ilock>
  if(ip->type != T_DIR){
    80005b16:	04449703          	lh	a4,68(s1)
    80005b1a:	4785                	li	a5,1
    80005b1c:	04f71063          	bne	a4,a5,80005b5c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b20:	8526                	mv	a0,s1
    80005b22:	ffffe097          	auipc	ra,0xffffe
    80005b26:	e7e080e7          	jalr	-386(ra) # 800039a0 <iunlock>
  iput(p->cwd);
    80005b2a:	15093503          	ld	a0,336(s2)
    80005b2e:	ffffe097          	auipc	ra,0xffffe
    80005b32:	f6a080e7          	jalr	-150(ra) # 80003a98 <iput>
  end_op();
    80005b36:	ffffe097          	auipc	ra,0xffffe
    80005b3a:	7fa080e7          	jalr	2042(ra) # 80004330 <end_op>
  p->cwd = ip;
    80005b3e:	14993823          	sd	s1,336(s2)
  return 0;
    80005b42:	4501                	li	a0,0
}
    80005b44:	60ea                	ld	ra,152(sp)
    80005b46:	644a                	ld	s0,144(sp)
    80005b48:	64aa                	ld	s1,136(sp)
    80005b4a:	690a                	ld	s2,128(sp)
    80005b4c:	610d                	addi	sp,sp,160
    80005b4e:	8082                	ret
    end_op();
    80005b50:	ffffe097          	auipc	ra,0xffffe
    80005b54:	7e0080e7          	jalr	2016(ra) # 80004330 <end_op>
    return -1;
    80005b58:	557d                	li	a0,-1
    80005b5a:	b7ed                	j	80005b44 <sys_chdir+0x7a>
    iunlockput(ip);
    80005b5c:	8526                	mv	a0,s1
    80005b5e:	ffffe097          	auipc	ra,0xffffe
    80005b62:	fe2080e7          	jalr	-30(ra) # 80003b40 <iunlockput>
    end_op();
    80005b66:	ffffe097          	auipc	ra,0xffffe
    80005b6a:	7ca080e7          	jalr	1994(ra) # 80004330 <end_op>
    return -1;
    80005b6e:	557d                	li	a0,-1
    80005b70:	bfd1                	j	80005b44 <sys_chdir+0x7a>

0000000080005b72 <sys_exec>:

uint64
sys_exec(void)
{
    80005b72:	7145                	addi	sp,sp,-464
    80005b74:	e786                	sd	ra,456(sp)
    80005b76:	e3a2                	sd	s0,448(sp)
    80005b78:	ff26                	sd	s1,440(sp)
    80005b7a:	fb4a                	sd	s2,432(sp)
    80005b7c:	f74e                	sd	s3,424(sp)
    80005b7e:	f352                	sd	s4,416(sp)
    80005b80:	ef56                	sd	s5,408(sp)
    80005b82:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b84:	08000613          	li	a2,128
    80005b88:	f4040593          	addi	a1,s0,-192
    80005b8c:	4501                	li	a0,0
    80005b8e:	ffffd097          	auipc	ra,0xffffd
    80005b92:	1d8080e7          	jalr	472(ra) # 80002d66 <argstr>
    return -1;
    80005b96:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b98:	0c054a63          	bltz	a0,80005c6c <sys_exec+0xfa>
    80005b9c:	e3840593          	addi	a1,s0,-456
    80005ba0:	4505                	li	a0,1
    80005ba2:	ffffd097          	auipc	ra,0xffffd
    80005ba6:	1a2080e7          	jalr	418(ra) # 80002d44 <argaddr>
    80005baa:	0c054163          	bltz	a0,80005c6c <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005bae:	10000613          	li	a2,256
    80005bb2:	4581                	li	a1,0
    80005bb4:	e4040513          	addi	a0,s0,-448
    80005bb8:	ffffb097          	auipc	ra,0xffffb
    80005bbc:	128080e7          	jalr	296(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005bc0:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005bc4:	89a6                	mv	s3,s1
    80005bc6:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005bc8:	02000a13          	li	s4,32
    80005bcc:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005bd0:	00391513          	slli	a0,s2,0x3
    80005bd4:	e3040593          	addi	a1,s0,-464
    80005bd8:	e3843783          	ld	a5,-456(s0)
    80005bdc:	953e                	add	a0,a0,a5
    80005bde:	ffffd097          	auipc	ra,0xffffd
    80005be2:	0aa080e7          	jalr	170(ra) # 80002c88 <fetchaddr>
    80005be6:	02054a63          	bltz	a0,80005c1a <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005bea:	e3043783          	ld	a5,-464(s0)
    80005bee:	c3b9                	beqz	a5,80005c34 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005bf0:	ffffb097          	auipc	ra,0xffffb
    80005bf4:	f04080e7          	jalr	-252(ra) # 80000af4 <kalloc>
    80005bf8:	85aa                	mv	a1,a0
    80005bfa:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005bfe:	cd11                	beqz	a0,80005c1a <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c00:	6605                	lui	a2,0x1
    80005c02:	e3043503          	ld	a0,-464(s0)
    80005c06:	ffffd097          	auipc	ra,0xffffd
    80005c0a:	0d4080e7          	jalr	212(ra) # 80002cda <fetchstr>
    80005c0e:	00054663          	bltz	a0,80005c1a <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c12:	0905                	addi	s2,s2,1
    80005c14:	09a1                	addi	s3,s3,8
    80005c16:	fb491be3          	bne	s2,s4,80005bcc <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c1a:	10048913          	addi	s2,s1,256
    80005c1e:	6088                	ld	a0,0(s1)
    80005c20:	c529                	beqz	a0,80005c6a <sys_exec+0xf8>
    kfree(argv[i]);
    80005c22:	ffffb097          	auipc	ra,0xffffb
    80005c26:	dd6080e7          	jalr	-554(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c2a:	04a1                	addi	s1,s1,8
    80005c2c:	ff2499e3          	bne	s1,s2,80005c1e <sys_exec+0xac>
  return -1;
    80005c30:	597d                	li	s2,-1
    80005c32:	a82d                	j	80005c6c <sys_exec+0xfa>
      argv[i] = 0;
    80005c34:	0a8e                	slli	s5,s5,0x3
    80005c36:	fc040793          	addi	a5,s0,-64
    80005c3a:	9abe                	add	s5,s5,a5
    80005c3c:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c40:	e4040593          	addi	a1,s0,-448
    80005c44:	f4040513          	addi	a0,s0,-192
    80005c48:	fffff097          	auipc	ra,0xfffff
    80005c4c:	194080e7          	jalr	404(ra) # 80004ddc <exec>
    80005c50:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c52:	10048993          	addi	s3,s1,256
    80005c56:	6088                	ld	a0,0(s1)
    80005c58:	c911                	beqz	a0,80005c6c <sys_exec+0xfa>
    kfree(argv[i]);
    80005c5a:	ffffb097          	auipc	ra,0xffffb
    80005c5e:	d9e080e7          	jalr	-610(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c62:	04a1                	addi	s1,s1,8
    80005c64:	ff3499e3          	bne	s1,s3,80005c56 <sys_exec+0xe4>
    80005c68:	a011                	j	80005c6c <sys_exec+0xfa>
  return -1;
    80005c6a:	597d                	li	s2,-1
}
    80005c6c:	854a                	mv	a0,s2
    80005c6e:	60be                	ld	ra,456(sp)
    80005c70:	641e                	ld	s0,448(sp)
    80005c72:	74fa                	ld	s1,440(sp)
    80005c74:	795a                	ld	s2,432(sp)
    80005c76:	79ba                	ld	s3,424(sp)
    80005c78:	7a1a                	ld	s4,416(sp)
    80005c7a:	6afa                	ld	s5,408(sp)
    80005c7c:	6179                	addi	sp,sp,464
    80005c7e:	8082                	ret

0000000080005c80 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c80:	7139                	addi	sp,sp,-64
    80005c82:	fc06                	sd	ra,56(sp)
    80005c84:	f822                	sd	s0,48(sp)
    80005c86:	f426                	sd	s1,40(sp)
    80005c88:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c8a:	ffffc097          	auipc	ra,0xffffc
    80005c8e:	d2e080e7          	jalr	-722(ra) # 800019b8 <myproc>
    80005c92:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c94:	fd840593          	addi	a1,s0,-40
    80005c98:	4501                	li	a0,0
    80005c9a:	ffffd097          	auipc	ra,0xffffd
    80005c9e:	0aa080e7          	jalr	170(ra) # 80002d44 <argaddr>
    return -1;
    80005ca2:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005ca4:	0e054063          	bltz	a0,80005d84 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005ca8:	fc840593          	addi	a1,s0,-56
    80005cac:	fd040513          	addi	a0,s0,-48
    80005cb0:	fffff097          	auipc	ra,0xfffff
    80005cb4:	dfc080e7          	jalr	-516(ra) # 80004aac <pipealloc>
    return -1;
    80005cb8:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005cba:	0c054563          	bltz	a0,80005d84 <sys_pipe+0x104>
  fd0 = -1;
    80005cbe:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005cc2:	fd043503          	ld	a0,-48(s0)
    80005cc6:	fffff097          	auipc	ra,0xfffff
    80005cca:	508080e7          	jalr	1288(ra) # 800051ce <fdalloc>
    80005cce:	fca42223          	sw	a0,-60(s0)
    80005cd2:	08054c63          	bltz	a0,80005d6a <sys_pipe+0xea>
    80005cd6:	fc843503          	ld	a0,-56(s0)
    80005cda:	fffff097          	auipc	ra,0xfffff
    80005cde:	4f4080e7          	jalr	1268(ra) # 800051ce <fdalloc>
    80005ce2:	fca42023          	sw	a0,-64(s0)
    80005ce6:	06054863          	bltz	a0,80005d56 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cea:	4691                	li	a3,4
    80005cec:	fc440613          	addi	a2,s0,-60
    80005cf0:	fd843583          	ld	a1,-40(s0)
    80005cf4:	68a8                	ld	a0,80(s1)
    80005cf6:	ffffc097          	auipc	ra,0xffffc
    80005cfa:	984080e7          	jalr	-1660(ra) # 8000167a <copyout>
    80005cfe:	02054063          	bltz	a0,80005d1e <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d02:	4691                	li	a3,4
    80005d04:	fc040613          	addi	a2,s0,-64
    80005d08:	fd843583          	ld	a1,-40(s0)
    80005d0c:	0591                	addi	a1,a1,4
    80005d0e:	68a8                	ld	a0,80(s1)
    80005d10:	ffffc097          	auipc	ra,0xffffc
    80005d14:	96a080e7          	jalr	-1686(ra) # 8000167a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d18:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d1a:	06055563          	bgez	a0,80005d84 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005d1e:	fc442783          	lw	a5,-60(s0)
    80005d22:	07e9                	addi	a5,a5,26
    80005d24:	078e                	slli	a5,a5,0x3
    80005d26:	97a6                	add	a5,a5,s1
    80005d28:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d2c:	fc042503          	lw	a0,-64(s0)
    80005d30:	0569                	addi	a0,a0,26
    80005d32:	050e                	slli	a0,a0,0x3
    80005d34:	9526                	add	a0,a0,s1
    80005d36:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d3a:	fd043503          	ld	a0,-48(s0)
    80005d3e:	fffff097          	auipc	ra,0xfffff
    80005d42:	a3e080e7          	jalr	-1474(ra) # 8000477c <fileclose>
    fileclose(wf);
    80005d46:	fc843503          	ld	a0,-56(s0)
    80005d4a:	fffff097          	auipc	ra,0xfffff
    80005d4e:	a32080e7          	jalr	-1486(ra) # 8000477c <fileclose>
    return -1;
    80005d52:	57fd                	li	a5,-1
    80005d54:	a805                	j	80005d84 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005d56:	fc442783          	lw	a5,-60(s0)
    80005d5a:	0007c863          	bltz	a5,80005d6a <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005d5e:	01a78513          	addi	a0,a5,26
    80005d62:	050e                	slli	a0,a0,0x3
    80005d64:	9526                	add	a0,a0,s1
    80005d66:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d6a:	fd043503          	ld	a0,-48(s0)
    80005d6e:	fffff097          	auipc	ra,0xfffff
    80005d72:	a0e080e7          	jalr	-1522(ra) # 8000477c <fileclose>
    fileclose(wf);
    80005d76:	fc843503          	ld	a0,-56(s0)
    80005d7a:	fffff097          	auipc	ra,0xfffff
    80005d7e:	a02080e7          	jalr	-1534(ra) # 8000477c <fileclose>
    return -1;
    80005d82:	57fd                	li	a5,-1
}
    80005d84:	853e                	mv	a0,a5
    80005d86:	70e2                	ld	ra,56(sp)
    80005d88:	7442                	ld	s0,48(sp)
    80005d8a:	74a2                	ld	s1,40(sp)
    80005d8c:	6121                	addi	sp,sp,64
    80005d8e:	8082                	ret

0000000080005d90 <kernelvec>:
    80005d90:	7111                	addi	sp,sp,-256
    80005d92:	e006                	sd	ra,0(sp)
    80005d94:	e40a                	sd	sp,8(sp)
    80005d96:	e80e                	sd	gp,16(sp)
    80005d98:	ec12                	sd	tp,24(sp)
    80005d9a:	f016                	sd	t0,32(sp)
    80005d9c:	f41a                	sd	t1,40(sp)
    80005d9e:	f81e                	sd	t2,48(sp)
    80005da0:	fc22                	sd	s0,56(sp)
    80005da2:	e0a6                	sd	s1,64(sp)
    80005da4:	e4aa                	sd	a0,72(sp)
    80005da6:	e8ae                	sd	a1,80(sp)
    80005da8:	ecb2                	sd	a2,88(sp)
    80005daa:	f0b6                	sd	a3,96(sp)
    80005dac:	f4ba                	sd	a4,104(sp)
    80005dae:	f8be                	sd	a5,112(sp)
    80005db0:	fcc2                	sd	a6,120(sp)
    80005db2:	e146                	sd	a7,128(sp)
    80005db4:	e54a                	sd	s2,136(sp)
    80005db6:	e94e                	sd	s3,144(sp)
    80005db8:	ed52                	sd	s4,152(sp)
    80005dba:	f156                	sd	s5,160(sp)
    80005dbc:	f55a                	sd	s6,168(sp)
    80005dbe:	f95e                	sd	s7,176(sp)
    80005dc0:	fd62                	sd	s8,184(sp)
    80005dc2:	e1e6                	sd	s9,192(sp)
    80005dc4:	e5ea                	sd	s10,200(sp)
    80005dc6:	e9ee                	sd	s11,208(sp)
    80005dc8:	edf2                	sd	t3,216(sp)
    80005dca:	f1f6                	sd	t4,224(sp)
    80005dcc:	f5fa                	sd	t5,232(sp)
    80005dce:	f9fe                	sd	t6,240(sp)
    80005dd0:	d85fc0ef          	jal	ra,80002b54 <kerneltrap>
    80005dd4:	6082                	ld	ra,0(sp)
    80005dd6:	6122                	ld	sp,8(sp)
    80005dd8:	61c2                	ld	gp,16(sp)
    80005dda:	7282                	ld	t0,32(sp)
    80005ddc:	7322                	ld	t1,40(sp)
    80005dde:	73c2                	ld	t2,48(sp)
    80005de0:	7462                	ld	s0,56(sp)
    80005de2:	6486                	ld	s1,64(sp)
    80005de4:	6526                	ld	a0,72(sp)
    80005de6:	65c6                	ld	a1,80(sp)
    80005de8:	6666                	ld	a2,88(sp)
    80005dea:	7686                	ld	a3,96(sp)
    80005dec:	7726                	ld	a4,104(sp)
    80005dee:	77c6                	ld	a5,112(sp)
    80005df0:	7866                	ld	a6,120(sp)
    80005df2:	688a                	ld	a7,128(sp)
    80005df4:	692a                	ld	s2,136(sp)
    80005df6:	69ca                	ld	s3,144(sp)
    80005df8:	6a6a                	ld	s4,152(sp)
    80005dfa:	7a8a                	ld	s5,160(sp)
    80005dfc:	7b2a                	ld	s6,168(sp)
    80005dfe:	7bca                	ld	s7,176(sp)
    80005e00:	7c6a                	ld	s8,184(sp)
    80005e02:	6c8e                	ld	s9,192(sp)
    80005e04:	6d2e                	ld	s10,200(sp)
    80005e06:	6dce                	ld	s11,208(sp)
    80005e08:	6e6e                	ld	t3,216(sp)
    80005e0a:	7e8e                	ld	t4,224(sp)
    80005e0c:	7f2e                	ld	t5,232(sp)
    80005e0e:	7fce                	ld	t6,240(sp)
    80005e10:	6111                	addi	sp,sp,256
    80005e12:	10200073          	sret
    80005e16:	00000013          	nop
    80005e1a:	00000013          	nop
    80005e1e:	0001                	nop

0000000080005e20 <timervec>:
    80005e20:	34051573          	csrrw	a0,mscratch,a0
    80005e24:	e10c                	sd	a1,0(a0)
    80005e26:	e510                	sd	a2,8(a0)
    80005e28:	e914                	sd	a3,16(a0)
    80005e2a:	6d0c                	ld	a1,24(a0)
    80005e2c:	7110                	ld	a2,32(a0)
    80005e2e:	6194                	ld	a3,0(a1)
    80005e30:	96b2                	add	a3,a3,a2
    80005e32:	e194                	sd	a3,0(a1)
    80005e34:	4589                	li	a1,2
    80005e36:	14459073          	csrw	sip,a1
    80005e3a:	6914                	ld	a3,16(a0)
    80005e3c:	6510                	ld	a2,8(a0)
    80005e3e:	610c                	ld	a1,0(a0)
    80005e40:	34051573          	csrrw	a0,mscratch,a0
    80005e44:	30200073          	mret
	...

0000000080005e4a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e4a:	1141                	addi	sp,sp,-16
    80005e4c:	e422                	sd	s0,8(sp)
    80005e4e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e50:	0c0007b7          	lui	a5,0xc000
    80005e54:	4705                	li	a4,1
    80005e56:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e58:	c3d8                	sw	a4,4(a5)
}
    80005e5a:	6422                	ld	s0,8(sp)
    80005e5c:	0141                	addi	sp,sp,16
    80005e5e:	8082                	ret

0000000080005e60 <plicinithart>:

void
plicinithart(void)
{
    80005e60:	1141                	addi	sp,sp,-16
    80005e62:	e406                	sd	ra,8(sp)
    80005e64:	e022                	sd	s0,0(sp)
    80005e66:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e68:	ffffc097          	auipc	ra,0xffffc
    80005e6c:	b24080e7          	jalr	-1244(ra) # 8000198c <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e70:	0085171b          	slliw	a4,a0,0x8
    80005e74:	0c0027b7          	lui	a5,0xc002
    80005e78:	97ba                	add	a5,a5,a4
    80005e7a:	40200713          	li	a4,1026
    80005e7e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e82:	00d5151b          	slliw	a0,a0,0xd
    80005e86:	0c2017b7          	lui	a5,0xc201
    80005e8a:	953e                	add	a0,a0,a5
    80005e8c:	00052023          	sw	zero,0(a0)
}
    80005e90:	60a2                	ld	ra,8(sp)
    80005e92:	6402                	ld	s0,0(sp)
    80005e94:	0141                	addi	sp,sp,16
    80005e96:	8082                	ret

0000000080005e98 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e98:	1141                	addi	sp,sp,-16
    80005e9a:	e406                	sd	ra,8(sp)
    80005e9c:	e022                	sd	s0,0(sp)
    80005e9e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ea0:	ffffc097          	auipc	ra,0xffffc
    80005ea4:	aec080e7          	jalr	-1300(ra) # 8000198c <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ea8:	00d5179b          	slliw	a5,a0,0xd
    80005eac:	0c201537          	lui	a0,0xc201
    80005eb0:	953e                	add	a0,a0,a5
  return irq;
}
    80005eb2:	4148                	lw	a0,4(a0)
    80005eb4:	60a2                	ld	ra,8(sp)
    80005eb6:	6402                	ld	s0,0(sp)
    80005eb8:	0141                	addi	sp,sp,16
    80005eba:	8082                	ret

0000000080005ebc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005ebc:	1101                	addi	sp,sp,-32
    80005ebe:	ec06                	sd	ra,24(sp)
    80005ec0:	e822                	sd	s0,16(sp)
    80005ec2:	e426                	sd	s1,8(sp)
    80005ec4:	1000                	addi	s0,sp,32
    80005ec6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ec8:	ffffc097          	auipc	ra,0xffffc
    80005ecc:	ac4080e7          	jalr	-1340(ra) # 8000198c <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ed0:	00d5151b          	slliw	a0,a0,0xd
    80005ed4:	0c2017b7          	lui	a5,0xc201
    80005ed8:	97aa                	add	a5,a5,a0
    80005eda:	c3c4                	sw	s1,4(a5)
}
    80005edc:	60e2                	ld	ra,24(sp)
    80005ede:	6442                	ld	s0,16(sp)
    80005ee0:	64a2                	ld	s1,8(sp)
    80005ee2:	6105                	addi	sp,sp,32
    80005ee4:	8082                	ret

0000000080005ee6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ee6:	1141                	addi	sp,sp,-16
    80005ee8:	e406                	sd	ra,8(sp)
    80005eea:	e022                	sd	s0,0(sp)
    80005eec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005eee:	479d                	li	a5,7
    80005ef0:	06a7c963          	blt	a5,a0,80005f62 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005ef4:	00016797          	auipc	a5,0x16
    80005ef8:	10c78793          	addi	a5,a5,268 # 8001c000 <disk>
    80005efc:	00a78733          	add	a4,a5,a0
    80005f00:	6789                	lui	a5,0x2
    80005f02:	97ba                	add	a5,a5,a4
    80005f04:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f08:	e7ad                	bnez	a5,80005f72 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f0a:	00451793          	slli	a5,a0,0x4
    80005f0e:	00018717          	auipc	a4,0x18
    80005f12:	0f270713          	addi	a4,a4,242 # 8001e000 <disk+0x2000>
    80005f16:	6314                	ld	a3,0(a4)
    80005f18:	96be                	add	a3,a3,a5
    80005f1a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005f1e:	6314                	ld	a3,0(a4)
    80005f20:	96be                	add	a3,a3,a5
    80005f22:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005f26:	6314                	ld	a3,0(a4)
    80005f28:	96be                	add	a3,a3,a5
    80005f2a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005f2e:	6318                	ld	a4,0(a4)
    80005f30:	97ba                	add	a5,a5,a4
    80005f32:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005f36:	00016797          	auipc	a5,0x16
    80005f3a:	0ca78793          	addi	a5,a5,202 # 8001c000 <disk>
    80005f3e:	97aa                	add	a5,a5,a0
    80005f40:	6509                	lui	a0,0x2
    80005f42:	953e                	add	a0,a0,a5
    80005f44:	4785                	li	a5,1
    80005f46:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005f4a:	00018517          	auipc	a0,0x18
    80005f4e:	0ce50513          	addi	a0,a0,206 # 8001e018 <disk+0x2018>
    80005f52:	ffffc097          	auipc	ra,0xffffc
    80005f56:	48a080e7          	jalr	1162(ra) # 800023dc <wakeup>
}
    80005f5a:	60a2                	ld	ra,8(sp)
    80005f5c:	6402                	ld	s0,0(sp)
    80005f5e:	0141                	addi	sp,sp,16
    80005f60:	8082                	ret
    panic("free_desc 1");
    80005f62:	00003517          	auipc	a0,0x3
    80005f66:	83e50513          	addi	a0,a0,-1986 # 800087a0 <syscalls+0x330>
    80005f6a:	ffffa097          	auipc	ra,0xffffa
    80005f6e:	5d4080e7          	jalr	1492(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005f72:	00003517          	auipc	a0,0x3
    80005f76:	83e50513          	addi	a0,a0,-1986 # 800087b0 <syscalls+0x340>
    80005f7a:	ffffa097          	auipc	ra,0xffffa
    80005f7e:	5c4080e7          	jalr	1476(ra) # 8000053e <panic>

0000000080005f82 <virtio_disk_init>:
{
    80005f82:	1101                	addi	sp,sp,-32
    80005f84:	ec06                	sd	ra,24(sp)
    80005f86:	e822                	sd	s0,16(sp)
    80005f88:	e426                	sd	s1,8(sp)
    80005f8a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f8c:	00003597          	auipc	a1,0x3
    80005f90:	83458593          	addi	a1,a1,-1996 # 800087c0 <syscalls+0x350>
    80005f94:	00018517          	auipc	a0,0x18
    80005f98:	19450513          	addi	a0,a0,404 # 8001e128 <disk+0x2128>
    80005f9c:	ffffb097          	auipc	ra,0xffffb
    80005fa0:	bb8080e7          	jalr	-1096(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fa4:	100017b7          	lui	a5,0x10001
    80005fa8:	4398                	lw	a4,0(a5)
    80005faa:	2701                	sext.w	a4,a4
    80005fac:	747277b7          	lui	a5,0x74727
    80005fb0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005fb4:	0ef71163          	bne	a4,a5,80006096 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fb8:	100017b7          	lui	a5,0x10001
    80005fbc:	43dc                	lw	a5,4(a5)
    80005fbe:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fc0:	4705                	li	a4,1
    80005fc2:	0ce79a63          	bne	a5,a4,80006096 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fc6:	100017b7          	lui	a5,0x10001
    80005fca:	479c                	lw	a5,8(a5)
    80005fcc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fce:	4709                	li	a4,2
    80005fd0:	0ce79363          	bne	a5,a4,80006096 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005fd4:	100017b7          	lui	a5,0x10001
    80005fd8:	47d8                	lw	a4,12(a5)
    80005fda:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fdc:	554d47b7          	lui	a5,0x554d4
    80005fe0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005fe4:	0af71963          	bne	a4,a5,80006096 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fe8:	100017b7          	lui	a5,0x10001
    80005fec:	4705                	li	a4,1
    80005fee:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ff0:	470d                	li	a4,3
    80005ff2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005ff4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005ff6:	c7ffe737          	lui	a4,0xc7ffe
    80005ffa:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdf75f>
    80005ffe:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006000:	2701                	sext.w	a4,a4
    80006002:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006004:	472d                	li	a4,11
    80006006:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006008:	473d                	li	a4,15
    8000600a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000600c:	6705                	lui	a4,0x1
    8000600e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006010:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006014:	5bdc                	lw	a5,52(a5)
    80006016:	2781                	sext.w	a5,a5
  if(max == 0)
    80006018:	c7d9                	beqz	a5,800060a6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000601a:	471d                	li	a4,7
    8000601c:	08f77d63          	bgeu	a4,a5,800060b6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006020:	100014b7          	lui	s1,0x10001
    80006024:	47a1                	li	a5,8
    80006026:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006028:	6609                	lui	a2,0x2
    8000602a:	4581                	li	a1,0
    8000602c:	00016517          	auipc	a0,0x16
    80006030:	fd450513          	addi	a0,a0,-44 # 8001c000 <disk>
    80006034:	ffffb097          	auipc	ra,0xffffb
    80006038:	cac080e7          	jalr	-852(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000603c:	00016717          	auipc	a4,0x16
    80006040:	fc470713          	addi	a4,a4,-60 # 8001c000 <disk>
    80006044:	00c75793          	srli	a5,a4,0xc
    80006048:	2781                	sext.w	a5,a5
    8000604a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000604c:	00018797          	auipc	a5,0x18
    80006050:	fb478793          	addi	a5,a5,-76 # 8001e000 <disk+0x2000>
    80006054:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006056:	00016717          	auipc	a4,0x16
    8000605a:	02a70713          	addi	a4,a4,42 # 8001c080 <disk+0x80>
    8000605e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006060:	00017717          	auipc	a4,0x17
    80006064:	fa070713          	addi	a4,a4,-96 # 8001d000 <disk+0x1000>
    80006068:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000606a:	4705                	li	a4,1
    8000606c:	00e78c23          	sb	a4,24(a5)
    80006070:	00e78ca3          	sb	a4,25(a5)
    80006074:	00e78d23          	sb	a4,26(a5)
    80006078:	00e78da3          	sb	a4,27(a5)
    8000607c:	00e78e23          	sb	a4,28(a5)
    80006080:	00e78ea3          	sb	a4,29(a5)
    80006084:	00e78f23          	sb	a4,30(a5)
    80006088:	00e78fa3          	sb	a4,31(a5)
}
    8000608c:	60e2                	ld	ra,24(sp)
    8000608e:	6442                	ld	s0,16(sp)
    80006090:	64a2                	ld	s1,8(sp)
    80006092:	6105                	addi	sp,sp,32
    80006094:	8082                	ret
    panic("could not find virtio disk");
    80006096:	00002517          	auipc	a0,0x2
    8000609a:	73a50513          	addi	a0,a0,1850 # 800087d0 <syscalls+0x360>
    8000609e:	ffffa097          	auipc	ra,0xffffa
    800060a2:	4a0080e7          	jalr	1184(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800060a6:	00002517          	auipc	a0,0x2
    800060aa:	74a50513          	addi	a0,a0,1866 # 800087f0 <syscalls+0x380>
    800060ae:	ffffa097          	auipc	ra,0xffffa
    800060b2:	490080e7          	jalr	1168(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800060b6:	00002517          	auipc	a0,0x2
    800060ba:	75a50513          	addi	a0,a0,1882 # 80008810 <syscalls+0x3a0>
    800060be:	ffffa097          	auipc	ra,0xffffa
    800060c2:	480080e7          	jalr	1152(ra) # 8000053e <panic>

00000000800060c6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800060c6:	7159                	addi	sp,sp,-112
    800060c8:	f486                	sd	ra,104(sp)
    800060ca:	f0a2                	sd	s0,96(sp)
    800060cc:	eca6                	sd	s1,88(sp)
    800060ce:	e8ca                	sd	s2,80(sp)
    800060d0:	e4ce                	sd	s3,72(sp)
    800060d2:	e0d2                	sd	s4,64(sp)
    800060d4:	fc56                	sd	s5,56(sp)
    800060d6:	f85a                	sd	s6,48(sp)
    800060d8:	f45e                	sd	s7,40(sp)
    800060da:	f062                	sd	s8,32(sp)
    800060dc:	ec66                	sd	s9,24(sp)
    800060de:	e86a                	sd	s10,16(sp)
    800060e0:	1880                	addi	s0,sp,112
    800060e2:	892a                	mv	s2,a0
    800060e4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800060e6:	00c52c83          	lw	s9,12(a0)
    800060ea:	001c9c9b          	slliw	s9,s9,0x1
    800060ee:	1c82                	slli	s9,s9,0x20
    800060f0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800060f4:	00018517          	auipc	a0,0x18
    800060f8:	03450513          	addi	a0,a0,52 # 8001e128 <disk+0x2128>
    800060fc:	ffffb097          	auipc	ra,0xffffb
    80006100:	ae8080e7          	jalr	-1304(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006104:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006106:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006108:	00016b97          	auipc	s7,0x16
    8000610c:	ef8b8b93          	addi	s7,s7,-264 # 8001c000 <disk>
    80006110:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006112:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006114:	8a4e                	mv	s4,s3
    80006116:	a051                	j	8000619a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006118:	00fb86b3          	add	a3,s7,a5
    8000611c:	96da                	add	a3,a3,s6
    8000611e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006122:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006124:	0207c563          	bltz	a5,8000614e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006128:	2485                	addiw	s1,s1,1
    8000612a:	0711                	addi	a4,a4,4
    8000612c:	25548063          	beq	s1,s5,8000636c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006130:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006132:	00018697          	auipc	a3,0x18
    80006136:	ee668693          	addi	a3,a3,-282 # 8001e018 <disk+0x2018>
    8000613a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000613c:	0006c583          	lbu	a1,0(a3)
    80006140:	fde1                	bnez	a1,80006118 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006142:	2785                	addiw	a5,a5,1
    80006144:	0685                	addi	a3,a3,1
    80006146:	ff879be3          	bne	a5,s8,8000613c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000614a:	57fd                	li	a5,-1
    8000614c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000614e:	02905a63          	blez	s1,80006182 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006152:	f9042503          	lw	a0,-112(s0)
    80006156:	00000097          	auipc	ra,0x0
    8000615a:	d90080e7          	jalr	-624(ra) # 80005ee6 <free_desc>
      for(int j = 0; j < i; j++)
    8000615e:	4785                	li	a5,1
    80006160:	0297d163          	bge	a5,s1,80006182 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006164:	f9442503          	lw	a0,-108(s0)
    80006168:	00000097          	auipc	ra,0x0
    8000616c:	d7e080e7          	jalr	-642(ra) # 80005ee6 <free_desc>
      for(int j = 0; j < i; j++)
    80006170:	4789                	li	a5,2
    80006172:	0097d863          	bge	a5,s1,80006182 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006176:	f9842503          	lw	a0,-104(s0)
    8000617a:	00000097          	auipc	ra,0x0
    8000617e:	d6c080e7          	jalr	-660(ra) # 80005ee6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006182:	00018597          	auipc	a1,0x18
    80006186:	fa658593          	addi	a1,a1,-90 # 8001e128 <disk+0x2128>
    8000618a:	00018517          	auipc	a0,0x18
    8000618e:	e8e50513          	addi	a0,a0,-370 # 8001e018 <disk+0x2018>
    80006192:	ffffc097          	auipc	ra,0xffffc
    80006196:	0be080e7          	jalr	190(ra) # 80002250 <sleep>
  for(int i = 0; i < 3; i++){
    8000619a:	f9040713          	addi	a4,s0,-112
    8000619e:	84ce                	mv	s1,s3
    800061a0:	bf41                	j	80006130 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800061a2:	20058713          	addi	a4,a1,512
    800061a6:	00471693          	slli	a3,a4,0x4
    800061aa:	00016717          	auipc	a4,0x16
    800061ae:	e5670713          	addi	a4,a4,-426 # 8001c000 <disk>
    800061b2:	9736                	add	a4,a4,a3
    800061b4:	4685                	li	a3,1
    800061b6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800061ba:	20058713          	addi	a4,a1,512
    800061be:	00471693          	slli	a3,a4,0x4
    800061c2:	00016717          	auipc	a4,0x16
    800061c6:	e3e70713          	addi	a4,a4,-450 # 8001c000 <disk>
    800061ca:	9736                	add	a4,a4,a3
    800061cc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800061d0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800061d4:	7679                	lui	a2,0xffffe
    800061d6:	963e                	add	a2,a2,a5
    800061d8:	00018697          	auipc	a3,0x18
    800061dc:	e2868693          	addi	a3,a3,-472 # 8001e000 <disk+0x2000>
    800061e0:	6298                	ld	a4,0(a3)
    800061e2:	9732                	add	a4,a4,a2
    800061e4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800061e6:	6298                	ld	a4,0(a3)
    800061e8:	9732                	add	a4,a4,a2
    800061ea:	4541                	li	a0,16
    800061ec:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800061ee:	6298                	ld	a4,0(a3)
    800061f0:	9732                	add	a4,a4,a2
    800061f2:	4505                	li	a0,1
    800061f4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800061f8:	f9442703          	lw	a4,-108(s0)
    800061fc:	6288                	ld	a0,0(a3)
    800061fe:	962a                	add	a2,a2,a0
    80006200:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffdf00e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006204:	0712                	slli	a4,a4,0x4
    80006206:	6290                	ld	a2,0(a3)
    80006208:	963a                	add	a2,a2,a4
    8000620a:	05890513          	addi	a0,s2,88
    8000620e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006210:	6294                	ld	a3,0(a3)
    80006212:	96ba                	add	a3,a3,a4
    80006214:	40000613          	li	a2,1024
    80006218:	c690                	sw	a2,8(a3)
  if(write)
    8000621a:	140d0063          	beqz	s10,8000635a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000621e:	00018697          	auipc	a3,0x18
    80006222:	de26b683          	ld	a3,-542(a3) # 8001e000 <disk+0x2000>
    80006226:	96ba                	add	a3,a3,a4
    80006228:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000622c:	00016817          	auipc	a6,0x16
    80006230:	dd480813          	addi	a6,a6,-556 # 8001c000 <disk>
    80006234:	00018517          	auipc	a0,0x18
    80006238:	dcc50513          	addi	a0,a0,-564 # 8001e000 <disk+0x2000>
    8000623c:	6114                	ld	a3,0(a0)
    8000623e:	96ba                	add	a3,a3,a4
    80006240:	00c6d603          	lhu	a2,12(a3)
    80006244:	00166613          	ori	a2,a2,1
    80006248:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000624c:	f9842683          	lw	a3,-104(s0)
    80006250:	6110                	ld	a2,0(a0)
    80006252:	9732                	add	a4,a4,a2
    80006254:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006258:	20058613          	addi	a2,a1,512
    8000625c:	0612                	slli	a2,a2,0x4
    8000625e:	9642                	add	a2,a2,a6
    80006260:	577d                	li	a4,-1
    80006262:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006266:	00469713          	slli	a4,a3,0x4
    8000626a:	6114                	ld	a3,0(a0)
    8000626c:	96ba                	add	a3,a3,a4
    8000626e:	03078793          	addi	a5,a5,48
    80006272:	97c2                	add	a5,a5,a6
    80006274:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006276:	611c                	ld	a5,0(a0)
    80006278:	97ba                	add	a5,a5,a4
    8000627a:	4685                	li	a3,1
    8000627c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000627e:	611c                	ld	a5,0(a0)
    80006280:	97ba                	add	a5,a5,a4
    80006282:	4809                	li	a6,2
    80006284:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006288:	611c                	ld	a5,0(a0)
    8000628a:	973e                	add	a4,a4,a5
    8000628c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006290:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006294:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006298:	6518                	ld	a4,8(a0)
    8000629a:	00275783          	lhu	a5,2(a4)
    8000629e:	8b9d                	andi	a5,a5,7
    800062a0:	0786                	slli	a5,a5,0x1
    800062a2:	97ba                	add	a5,a5,a4
    800062a4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800062a8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800062ac:	6518                	ld	a4,8(a0)
    800062ae:	00275783          	lhu	a5,2(a4)
    800062b2:	2785                	addiw	a5,a5,1
    800062b4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800062b8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800062bc:	100017b7          	lui	a5,0x10001
    800062c0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800062c4:	00492703          	lw	a4,4(s2)
    800062c8:	4785                	li	a5,1
    800062ca:	02f71163          	bne	a4,a5,800062ec <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800062ce:	00018997          	auipc	s3,0x18
    800062d2:	e5a98993          	addi	s3,s3,-422 # 8001e128 <disk+0x2128>
  while(b->disk == 1) {
    800062d6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800062d8:	85ce                	mv	a1,s3
    800062da:	854a                	mv	a0,s2
    800062dc:	ffffc097          	auipc	ra,0xffffc
    800062e0:	f74080e7          	jalr	-140(ra) # 80002250 <sleep>
  while(b->disk == 1) {
    800062e4:	00492783          	lw	a5,4(s2)
    800062e8:	fe9788e3          	beq	a5,s1,800062d8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800062ec:	f9042903          	lw	s2,-112(s0)
    800062f0:	20090793          	addi	a5,s2,512
    800062f4:	00479713          	slli	a4,a5,0x4
    800062f8:	00016797          	auipc	a5,0x16
    800062fc:	d0878793          	addi	a5,a5,-760 # 8001c000 <disk>
    80006300:	97ba                	add	a5,a5,a4
    80006302:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006306:	00018997          	auipc	s3,0x18
    8000630a:	cfa98993          	addi	s3,s3,-774 # 8001e000 <disk+0x2000>
    8000630e:	00491713          	slli	a4,s2,0x4
    80006312:	0009b783          	ld	a5,0(s3)
    80006316:	97ba                	add	a5,a5,a4
    80006318:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000631c:	854a                	mv	a0,s2
    8000631e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006322:	00000097          	auipc	ra,0x0
    80006326:	bc4080e7          	jalr	-1084(ra) # 80005ee6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000632a:	8885                	andi	s1,s1,1
    8000632c:	f0ed                	bnez	s1,8000630e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000632e:	00018517          	auipc	a0,0x18
    80006332:	dfa50513          	addi	a0,a0,-518 # 8001e128 <disk+0x2128>
    80006336:	ffffb097          	auipc	ra,0xffffb
    8000633a:	962080e7          	jalr	-1694(ra) # 80000c98 <release>
}
    8000633e:	70a6                	ld	ra,104(sp)
    80006340:	7406                	ld	s0,96(sp)
    80006342:	64e6                	ld	s1,88(sp)
    80006344:	6946                	ld	s2,80(sp)
    80006346:	69a6                	ld	s3,72(sp)
    80006348:	6a06                	ld	s4,64(sp)
    8000634a:	7ae2                	ld	s5,56(sp)
    8000634c:	7b42                	ld	s6,48(sp)
    8000634e:	7ba2                	ld	s7,40(sp)
    80006350:	7c02                	ld	s8,32(sp)
    80006352:	6ce2                	ld	s9,24(sp)
    80006354:	6d42                	ld	s10,16(sp)
    80006356:	6165                	addi	sp,sp,112
    80006358:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000635a:	00018697          	auipc	a3,0x18
    8000635e:	ca66b683          	ld	a3,-858(a3) # 8001e000 <disk+0x2000>
    80006362:	96ba                	add	a3,a3,a4
    80006364:	4609                	li	a2,2
    80006366:	00c69623          	sh	a2,12(a3)
    8000636a:	b5c9                	j	8000622c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000636c:	f9042583          	lw	a1,-112(s0)
    80006370:	20058793          	addi	a5,a1,512
    80006374:	0792                	slli	a5,a5,0x4
    80006376:	00016517          	auipc	a0,0x16
    8000637a:	d3250513          	addi	a0,a0,-718 # 8001c0a8 <disk+0xa8>
    8000637e:	953e                	add	a0,a0,a5
  if(write)
    80006380:	e20d11e3          	bnez	s10,800061a2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006384:	20058713          	addi	a4,a1,512
    80006388:	00471693          	slli	a3,a4,0x4
    8000638c:	00016717          	auipc	a4,0x16
    80006390:	c7470713          	addi	a4,a4,-908 # 8001c000 <disk>
    80006394:	9736                	add	a4,a4,a3
    80006396:	0a072423          	sw	zero,168(a4)
    8000639a:	b505                	j	800061ba <virtio_disk_rw+0xf4>

000000008000639c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000639c:	1101                	addi	sp,sp,-32
    8000639e:	ec06                	sd	ra,24(sp)
    800063a0:	e822                	sd	s0,16(sp)
    800063a2:	e426                	sd	s1,8(sp)
    800063a4:	e04a                	sd	s2,0(sp)
    800063a6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800063a8:	00018517          	auipc	a0,0x18
    800063ac:	d8050513          	addi	a0,a0,-640 # 8001e128 <disk+0x2128>
    800063b0:	ffffb097          	auipc	ra,0xffffb
    800063b4:	834080e7          	jalr	-1996(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800063b8:	10001737          	lui	a4,0x10001
    800063bc:	533c                	lw	a5,96(a4)
    800063be:	8b8d                	andi	a5,a5,3
    800063c0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800063c2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800063c6:	00018797          	auipc	a5,0x18
    800063ca:	c3a78793          	addi	a5,a5,-966 # 8001e000 <disk+0x2000>
    800063ce:	6b94                	ld	a3,16(a5)
    800063d0:	0207d703          	lhu	a4,32(a5)
    800063d4:	0026d783          	lhu	a5,2(a3)
    800063d8:	06f70163          	beq	a4,a5,8000643a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063dc:	00016917          	auipc	s2,0x16
    800063e0:	c2490913          	addi	s2,s2,-988 # 8001c000 <disk>
    800063e4:	00018497          	auipc	s1,0x18
    800063e8:	c1c48493          	addi	s1,s1,-996 # 8001e000 <disk+0x2000>
    __sync_synchronize();
    800063ec:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063f0:	6898                	ld	a4,16(s1)
    800063f2:	0204d783          	lhu	a5,32(s1)
    800063f6:	8b9d                	andi	a5,a5,7
    800063f8:	078e                	slli	a5,a5,0x3
    800063fa:	97ba                	add	a5,a5,a4
    800063fc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800063fe:	20078713          	addi	a4,a5,512
    80006402:	0712                	slli	a4,a4,0x4
    80006404:	974a                	add	a4,a4,s2
    80006406:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000640a:	e731                	bnez	a4,80006456 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000640c:	20078793          	addi	a5,a5,512
    80006410:	0792                	slli	a5,a5,0x4
    80006412:	97ca                	add	a5,a5,s2
    80006414:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006416:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000641a:	ffffc097          	auipc	ra,0xffffc
    8000641e:	fc2080e7          	jalr	-62(ra) # 800023dc <wakeup>

    disk.used_idx += 1;
    80006422:	0204d783          	lhu	a5,32(s1)
    80006426:	2785                	addiw	a5,a5,1
    80006428:	17c2                	slli	a5,a5,0x30
    8000642a:	93c1                	srli	a5,a5,0x30
    8000642c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006430:	6898                	ld	a4,16(s1)
    80006432:	00275703          	lhu	a4,2(a4)
    80006436:	faf71be3          	bne	a4,a5,800063ec <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000643a:	00018517          	auipc	a0,0x18
    8000643e:	cee50513          	addi	a0,a0,-786 # 8001e128 <disk+0x2128>
    80006442:	ffffb097          	auipc	ra,0xffffb
    80006446:	856080e7          	jalr	-1962(ra) # 80000c98 <release>
}
    8000644a:	60e2                	ld	ra,24(sp)
    8000644c:	6442                	ld	s0,16(sp)
    8000644e:	64a2                	ld	s1,8(sp)
    80006450:	6902                	ld	s2,0(sp)
    80006452:	6105                	addi	sp,sp,32
    80006454:	8082                	ret
      panic("virtio_disk_intr status");
    80006456:	00002517          	auipc	a0,0x2
    8000645a:	3da50513          	addi	a0,a0,986 # 80008830 <syscalls+0x3c0>
    8000645e:	ffffa097          	auipc	ra,0xffffa
    80006462:	0e0080e7          	jalr	224(ra) # 8000053e <panic>
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

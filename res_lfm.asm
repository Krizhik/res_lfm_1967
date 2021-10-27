/*
 * res_lfm.asm
 *
 *  Created on: 21 окт. 2021 г.
 *      Author: MKrizhanovskiy
 */

/*
 план такой,мы имеем период отправки импульсов в прекрасное далеко
 этот период должен идеально помещаться в половинку буфера приема
 когда пол буфера заполняется, мы в прерывании сигналим что свершилось
 и указываем какой буфер готов (или мы просто можем это знать)
 далее переключаем кранник
 */
#include <defts201.h>
//задаем длительность импульсов
#define dlit_imp 10000
//задаем девиацию
#define dev_f 0.01
//шаг расчитывается исходя из приведенных выше данных
#define step_dev dev_f/dlit_imp
.SECTION /DOUBLE64 /CHAR32 .data;
.ALIGN 4;
//Буфер приема из двух частей
.var arrr[30000];
.var arrr1[30000];
.var arr2[10000];
.var buf[]={0,1,0};//буфер данных
.var task_R[4]={0,0,0,0};
.var task_R1[4]={0,0,0,0};
.var stack[100];
.var  sin_coef[5]={3.140625,0.02026367,-5.325196,0.5446778,1.800293};//масивчик с кэффициентами
.SECTION .program;
.ALIGN_CODE 4;
.GLOBAL _main;
.global dma10_interrupt;
.GLOBAL lfm_func;
.GLOBAL sin_func;
.global svertka;
_main:
SQCTL = 0x1204;;//переход в режим супервизора + глобальное разрешение прерываний
j0=stack;;//инициализируем стек на 100 мест
//генерим массив искомый
j4=arr2;;
xr1=0.0;NOP; NOP; NOP;;// начальное значение x
call lfm_func;NOP; NOP; NOP;;
//инициализируем прерывание по завершению работы dma10
j1=dma10_interrupt;;
ivdma10=j1;;
j10=0;;
j1=0x5f;;
FLAGREG=j1;;

//чистим буфер
j1=arrr;;
j2=arrr1;;
xr0=0;;
lc0 = 1024;;
wr_res:
[j1+=1]=xr0;;
[j2+=1]=xr0;;
if nlc0e, jump wr_res;;

//Разрешим прерывание DMA10 в регистре маскирования прерываний
j1=(1<<31);;
imaskl=j1;;
//выключим для начала линки
j1=0;;
LRCTL0=j1;;
LRCTL1=j1;;
LRCTL2=j1;;
LRCTL3=j1;;
LtCTL2=j1;;
//и их dma каналы
xr0=0;xr1=0;;
xr2=0;xr3=0;;
dc11=xr3:0;;
dc10=xr3:0;;
dc9 =xr3:0;;
dc8 =xr3:0;;
dc7=xr3:0;;
//Включаем линк приемника
j1=(1<<4);;//формат 4 бит
LRCTL2=j1;;
// стабильный клок
lc0 = 10;;
dly_p1: if nlc0e, jump dly_p1;nop;nop;;
j1=1+(1<<4);;
LRCTL2=j1;;
//настраиваем и включаем приемник
xr0 = arrr1;;
xr1=0x75300004;;
xr2=0;;
xr3=0x40000000/*выбираем внутреннюю память*/+(2<<19)/*выбираем номер порта линк и направление
*/ +(1<<24)/*разрешаем прерывание по завершению работы канала
*/ +(3<<25) /*ставим длинну данных*/ + (1<<22)/* разрешение след приема
*/ + (task_R/4);; //указатель на след цепочку выравненый по квадрословам
q[j31+task_R1]=xr3:0;;
xr0 = arrr;;
xr3=0x40000000/*выбираем внутреннюю память*/+(2<<19)/*выбираем номер порта линк и направление
*/ +(1<<24)/*разрешаем прерывание по завершению работы канала
*/ +(3<<25) /*ставим длинну данных*/ + (1<<22)/* разрешение след приема
*/ + (task_R1/4);; //указатель на след цепочку выравненый по квадрословам
q[j31+task_R]=xr3:0;;
dc10=xr3:0;;
_main_loop:
nop;nop;nop;;
nop;nop;nop;;
nop;nop;nop;;
nop;nop;nop;;
nop;nop;nop;;
nop;nop;nop;;
jump _main_loop;nop;;
_main.end:

dma10_interrupt:
NOP;NOP;NOP;;
[j0+=1]=j1;;
[j0+=1]=xr0;;
[j0+=1]=xr1;;
[j0+=1]=xr2;;
[j0+=1]=xr3;;/*
[j0+=1]=retib;;
//тут меняем флаг глядя на который внешний процессор понимает из какого массива брать актуальные обработаные данные
retib=[j0 + 0];;*/
xr3=j10;;
xr4 = inc r3;;
j10=xr4;;
j0=j0-1;;
xr3=[j0 + 0];;
j0=j0-1;;
xr2=[j0 + 0];;
j0=j0-1;;
xr1=[j0 + 0];;
j0=j0-1;;
xr0=[j0 + 0];;
j0=j0-1;;
j1=[j0 + 0];;
RTI(np);;
dma10_interrupt.end:


//*******************************************************************************************
//функция выдает массив значений лчм сигнала\
выведенные данные складируются по адресу [j4+0]\

//*******************************************************************************************
lfm_func:
	//пушим в стек
	[j0+=1]=cjmp;;
	[j0+=1]=lc1;;
	[j0+=1]=xr16;;
	[j0+=1]=xr17;;
	[j0+=1]=xr18;;
	[j0+=1]=xr5;;
	[j0+=1]=xr6;;
	[j0+=1]=xr9;;
	xr16=0.000001;;	//здесь задаем частоту стартовую
	lc1=dlit_imp-1;; //задаем кол-во итераций (диапазон изменения входных значений)
	m:
		xr17=step_dev;; //0.000001;;//множитель в уравнении y=kx для лчм
		xr18=dev_f;;//2;;	//0.01;;//dev_f;;//задаем пиковую частоту
		xr5=lc1;;//x
		xr6=dlit_imp/2;;///2;;//10000;;//dlit_imp/2;;//задаем длительность половины импульса ЛЧМ
		xfr6=float r6;;//переводим в плав точку
		xfr5=float r5;;//переводим в плав точку
		xfr16=r5*r17;;//x*k
		xfcomp(r5,r6);;//сравнение x и длительности импульса
		if xalt, jump k;;
		//если  x>длительности_импульса/2
		xfr16=r5*r17;;//x*k
		xfr16=r18-r16;;//dev_f-x*k
		xr6=0.000001;;
		k:
		xr17=1;;//просто нолик шоб было с чем сравнивать
		xr18=[j5+0];;//жрем данные из буфера
		xcomp(r18,r17);;//жуем
		if xaeq,jump mk;;//делаем выводы о вкусовых качествах
			xr16=0;;//start_f;;
			xr9=0;;NOP; NOP; NOP;;
			jump collect;;
		mk:
		Xfr1=r1+r16;;//изменяем х на единицу
		call sin_func;NOP; NOP; NOP;;//переход по метке
		collect:
		[J4+=1]= xr9;;//складируем все это ОНИМЭ
	if NLC1E, jump m;NOP; NOP; NOP;;
	//отпушиваем стек
	j0=j0-1;;
	xr9=[j0 + 0];;
	j0=j0-1;;
	xr6=[j0 + 0];;
	j0=j0-1;;
	xr5=[j0 + 0];;
	j0=j0-1;;
	xr18=[j0 + 0];;
	j0=j0-1;;
	xr17=[j0 + 0];;
	j0=j0-1;;
	xr16=[j0 + 0];;
	j0=j0-1;;
	lc1=[j0 + 0];;
	j0=j0-1;;
	cjmp=[j0 + 0];;
	cjmp(abs);;
lfm_func.end:

//*******************************************************************************************
//нижже функция синуса которая понимает числа от 0 до 1.84\
число пи соответствует значению 0.92\
выходное значение подается через xr9\
входное значение подается через xr1
//*******************************************************************************************
sin_func:
//пушим в стек
	[j0+=1]=j3;;
	[j0+=1]=xr15;;
	[j0+=1]=xr10;;
	[j0+=1]=xr5;;
	[j0+=1]=xr2;;
	[j0+=1]=xr6;;
	[j0+=1]=xr3;;//
	[j0+=1]=cjmp;;
	[j0+=1]=lc0;;
	j3=sin_coef;;
	beg:
	xr15=0.46;;
	xfcomp(r1,r15);;
	if xalt,jump m1;;//x<0,46
	xr10=0.92;;//x>0,46
	xfr5=r10-r1;;
	xfcomp(r1,r10);;
	if xalt,jump m3;;//x<0,92
	xfr5=r1-r10;;//x>0,96
	xr10=1.38;;
	xfcomp(r1,r10);;
	if xalt,jump m3;;//x<1.38
	xr10=1.84;;
	xfr5=r10-r1;;//x>1.38
	xfcomp(r1,r10);;//r1<1.84
	if xalt,jump m3;;
	xfr1=r1-r10;;//если значение больше 2*пи\
	отнимаем от него пи пока это не изменится
	jump beg;NOP; NOP; NOP;;
	jump m3;NOP; NOP; NOP;;
	m1:
	xr5= xr1;;
	m3:
	xr2=[j3+=1];; //c1
	xr6=xr5;
	xfr3=r5*r2;;//c1*x
	lc0=3;;//стартуем еще цикл
	m2:
	xr2=[j3+=1];;//c2,c3,c4
	xfr5=r5*r6;;//x^2,x^3,x^4
	xfr7=r5*r2;;//c2*x^2,c3*x^3,c4*x^5
	xfr3=r3+r7;;
	if NLC0E, jump m2;;
	xr10=1000.0;;
	xfr3=r3*r10;;//масштабируем результат перед переводом в тип с фиксированой точкой
	xr9=fix xfr3;;//округляем конечный результат чтоб матлаб не подавился странным форматом плавающей точки
	//работа со знаком отменена в виду того что матлаб странно пережевывает числа с отрицательным знаком
	//работа со знаком
	xr10=0.92;;
	xfcomp(r1,r10);;
	if xalt,jump m5;;//x<0.92
	xr10=0;;
	xr9=r10-r9;;
	//jump m6;;
	m5:
	//xr9=r9+r10;;
	m6:
	//пушим из стека
	j0=j0-1;;
	lc0=[j0 + 0];;
	j0=j0-1;;
	cjmp=[j0 + 0];;
	j0=j0-1;;
	xr3=[j0 + 0];;
	j0=j0-1;;
	xr6=[j0 + 0];;
	j0=j0-1;;
	xr2=[j0 + 0];;
	j0=j0-1;;
	xr5=[j0 + 0];;
	j0=j0-1;;
	xr10=[j0 + 0];;
	j0=j0-1;;
	xr15=[j0 + 0];;
	j0=j0-1;;
	j3=[j0 + 0];;
	cjmp(abs);;
sin_func.end:

//*******************************************************************************************
//функция свертки двух массивов\
первый массив (больший) подается через j5\
его длительность xr7\
меньший масссив подается через j2\
его длительность xr6\
выходной результат лежит по адресу j6
//*******************************************************************************************
svertka:
	[j0+=1]=cjmp;;
	[j0+=1]=lc1;;
	[j0+=1]=lc0;;
	[j0+=1]=j5;;
	[j0+=1]=j3;;
	[j0+=1]=j6;;
	[j0+=1]=xr5;;
	[j0+=1]=xr2;;
	[j0+=1]=xr1;;
	[j0+=1]=xr4;;

	lc1=xr7;;
	s1:
	j4=j2;;
	j5=j5+1;;
	xr5=0;;//для хранения сумм
	lc0=xr6;;
	j3=0;;
	s0:
	xr2=lc0;;
	j3=j3+1;;//работа с индексом для малого массива
	xr1=[j4+j3];NOP;;//тут перебираются значения arr2
	xr4=[j5+j3];NOP; NOP; NOP;;//тут перебираются значения sin_arr
	xr1=r1*r4(i);;//arr2(i)*sin_arr(j+i)
	xr5=r5+r1;NOP;;//
	if NLC0E, jump s0;NOP; NOP; NOP;;
	[j6+0]=xr5;;
	j6=j6+1;;//передвигаем счетчик массива свертки
	if NLC1E, jump s1;NOP; NOP; NOP;;
	j0=j0-1;;
	xr4=[j0 + 0];;
	j0=j0-1;;
	xr1=[j0 + 0];;
	j0=j0-1;;
	xr2=[j0 + 0];;
	j0=j0-1;;
	xr5=[j0 + 0];;
	j0=j0-1;;
	j6=[j0 + 0];;
	j0=j0-1;;
	j3=[j0 + 0];;
	j0=j0-1;;
	j5=[j0 + 0];;
	j0=j0-1;;
	lc0=[j0 + 0];;
	j0=j0-1;;
	lc1=[j0 + 0];;
	j0=j0-1;;
	cjmp=[j0 + 0];nop;nop;;
	cjmp(abs);;
svertka.end:

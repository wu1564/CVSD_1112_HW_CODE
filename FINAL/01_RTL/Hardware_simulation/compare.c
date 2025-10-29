#include <stdlib.h>
#include <stdio.h> 
#include <math.h>



#define DATA_W 20

static long long int maskNum(int bit) {
	long long int num = 0;
	for (int i = 0; i < bit; ++i) {
		num |= 1 << i;
	}
	return num;
}


static long long int SignedShift(long long int target, int shift_num) {
    long long int sign_bit = (target & (1 << (DATA_W-1))) >> (DATA_W-1);
    long long int mask = maskNum(shift_num);
    

    if(sign_bit) {
        return (target >> shift_num) | (mask << (DATA_W - shift_num));
    } else {
        return target >> shift_num;
    }
}



int main(void){
    FILE *myLLR, *sim;
    int myBuff[1000];
    int simBuff[1000];
    int index = 0;
    int error = 0;

    // myLLR = fopen("./myLLR.txt", "r");
    // sim  = fopen("./LLR_bit.txt", "r");
    // if(myLLR == NULL || sim == NULL) {
    //     printf("Cannot Open File");
    //     return 0;
    // }

    // while ((fscanf(myLLR, "%x", &myBuff[index])) == 1) index++;
    // index = 0;
    // while ((fscanf(sim, "%x", &simBuff[index])) == 1) index++;

    // for(int i = 0; i < 1000; i++) {
    //     if(myBuff[i] != simBuff[i]) {
    //         error += 1;
    //         printf("%d -> %x, %x\n", i, myBuff[i], simBuff[i]);
    //     }
    // }
    // if(error == 0) {
    //     printf("Congrats, ALL DATA PASS\n");
    // }

    // int a = 1;
    // double result = 0;
    // double actual_result = 0;
    // double diff = 0.0;
    // // goal = 0.707....
    // // 1011 0101 0000 0101 
    // int shift[5];
    // actual_result = (double)sqrt(2.0) / 2;
    // shift[0] = 1;
    // shift[1] = 3;
    // shift[2] = 4;
    // shift[3] = 6;
    // shift[4] = 8;

    // for(int i = 0; i < 2; i++) {
    //     result = result + 1.0 /(a << shift[i]);
    // }
    // diff = actual_result - result;

    // printf("shift_add:%lf actual:%lf, Diff:%lf, per:%lf\n", result, actual_result, diff, diff/actual_result*100);


    // diff
    long long int diff;
    // input
    long long int matrixR = 0xf85c6;
    long long int a = 0xf4abf; // -0.707
    long long int b = 0xb505;  //  0.707
    long long int shifted = 0;
    // output
    long long int int_a = 0;
    long long int shift_a = 0;

    long long int int_b = 0;
    long long int shift_b = 0;
    double double_b;


    // shifted = SignedShift(matrixR, 4);
    // printf("shifted: %x\n", shifted);
    // matrixR = 0x085c6;
    // shifted = SignedShift(matrixR, 1);
    // printf("shifted: %x\n", shifted);




    // shift
    int shift[5];
    shift[0] = 1;
    shift[1] = 3;
    shift[2] = 4;
    shift[3] = 6;
    shift[4] = 8;

    for(int i = 0; i < 5; i++) {
        shift_a = (shift_a + SignedShift(matrixR, shift[i])) & maskNum(20);
    }
    shift_a = (~shift_a + 1) & maskNum(20);
    printf("shift_a: %x\n", shift_a);



    for(int i = 0; i < 5; i++) {
        shift_b = (shift_b + SignedShift(matrixR, shift[i])) & maskNum(20);
    }
    printf("shift_b: %x\n", shift_b);
    
    return 0;
}

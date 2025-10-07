#include "stdio.h"
#include "stdlib.h"
#include "math.h"
#include "string.h"

const int FRAC_W = 6;
const int INT_W = 3;

int main() {
    char buf[10];
    int isOne = 0, isNegative = 0;
    double output = 0, factor = 1;
    while(1) {
        isOne = 0;
        output = 0;
        factor = 1;
        memset(buf, '\0', sizeof(buf));
        scanf("%s", buf);
        if(buf[0] == '1') {
            isNegative = 1;
            for(int i = 9; i >= 0; --i) {
                if(isOne) {
                    buf[i] = (buf[i] == '1') ? '0' : '1';
                } else if(buf[i] == '1') {
                    isOne = 1;
                }
            }   
        }       
        for(int i = INT_W; i < FRAC_W + INT_W; ++i) {
            factor /= 2;
            output += factor * (double)(buf[i] - '0');
        }
        if(isNegative) {
            output = -output;
        } 
        printf("%f\n", output);
    }
}

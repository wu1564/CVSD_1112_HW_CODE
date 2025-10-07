#include "Complex.h"


Complex::Complex(LLI real, LLI imag) {
	this->real = real;
	this->imag = imag;
}

Complex::Complex() {
	this->real = 0;
	this->imag = 0;
}

Complex::Complex(const Complex& input) {
	this->real = input.real;
	this->imag = input.imag;
}

void Complex::operator=(const Complex& input) {
	this->real = input.real;
	this->imag = input.imag;
}


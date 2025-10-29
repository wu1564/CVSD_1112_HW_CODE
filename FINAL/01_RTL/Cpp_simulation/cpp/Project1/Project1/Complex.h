#pragma once

typedef long long int LLI;

class Complex {
	public:	
		Complex(LLI real, LLI imag);
		Complex();
		Complex(const Complex& input);
		void operator=(const Complex &input);
		LLI real;
		LLI imag;
};


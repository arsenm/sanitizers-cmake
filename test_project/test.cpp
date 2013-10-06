
#include <cstdio>
#include <cstdlib>
#include <iostream>

class BarB
{
public:
    float y;
    /* Include something that uses a virtual function. The symbols
       that are broken on current OS X libc++ involve this */
    virtual int arst(int o)
    {
        return 4 + o;
    }
};

static void print_array(const int* a)
{
    for (int i = 0; i < 4; ++i)
    {
        std::cout << a[i] << ", ";
    }

    std::cout << '\n';
}

/* Just include something that ubsan will need to check */
int main(int argc, const char* argv[])
{
    BarB* b = new BarB();
    if (argc > 1)
    {
        int uninitialized[4];
        //int* uninitialized = new int[4];
        print_array(uninitialized);
        //delete[] uninitialized;

        int x = atoi(argv[1]);
        std::cout << (4 / x) << '\n';

        fputs(argv[x], stdout);
        std::cout << b->arst(x) << '\n';
    }

    delete b;
    return 0;
}

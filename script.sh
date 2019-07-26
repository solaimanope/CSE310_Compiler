bison -d -y -v parser.y
echo '1'
g++ -std=c++11 -w -c -o y.o y.tab.c   
echo '2'
flex scanner.l
echo '3'
g++ -std=c++11 -w -c -o l.o lex.yy.c
# if the above command doesn't work try g++ -fpermissive -w -c -o l.o lex.yy.c
echo '4'
g++ -std=c++11 -o a.out y.o l.o -lfl -ly
echo '5'
./a.out	input2.txt	# you will need to provide proper input files with ./a.out command as instructed in assignment specification

#include <stdio.h>
#include <stdlib.h>

int main (int argc, char** argv){
	
	FILE* filein;
	FILE* filekey;
	FILE* fileout;
	int i, j;
	int tmp, open;
	int key[256];
	int S[256];

	if (argc == 4){
		filein = fopen(argv[1],"r");
		filekey = fopen(argv[2],"r");
		fileout = fopen(argv[3], "w");
		
		for (i = 0; i < 256; i++){
			if ((tmp = fgetc(filekey)) == EOF){
				fseek(filekey, 0, SEEK_SET);
				tmp = fgetc(filekey);
			}
			key[i] = tmp;
		}
		j = 0;
		for (i = 0; i < 256; i++){
			S[i] = i;
		}
		for (i = 0; i < 256; i++){
			j = (j + S[i] + key[i]) % 256;
			S[i] ^= S[j];
			S[j] ^= S[i];
			S[i] ^= S[j];
		}

		i = -1;
		j = 0;
		while ((open = fgetc(filein)) != EOF){
			i = (i++) % 256;
			j = (j + S[i]) % 256;
			S[i] ^= S[j];
			S[j] ^= S[i];
			S[i] ^= S[j];
			open ^= S[(S[i] + S[j]) % 256];
			fputc(open, fileout);
		}

		fclose(filein);
		fclose(fileout);
		fclose(filekey);
	}
	return 0;
}

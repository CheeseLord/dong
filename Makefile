
dong: src/hello.d
	dmd -odobj -ofdong $+

clean:
	rm -f dong

.PHONY: clean


if make; then
	./zpuramgen ./SDBootstrap.bin ./SDBootstrap_ROM.vhd
	rm -r ./zpu_obj
	echo "COMPILACION TERMINADA"
else
	echo "COMPILACION FALLIDA"
fi


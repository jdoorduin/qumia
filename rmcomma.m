function textstring = rmcomma(textstring)
idx = findstr(textstring,',');
textstring(idx) ='.';

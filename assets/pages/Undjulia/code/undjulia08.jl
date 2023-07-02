# This file was generated, do not modify it. # hide
function g(x,y)
  a = 4
  b = 2
  c = f(x,a)
  d = f(b,c)
  f(d,y)
end

@code_warntype g(2,5.0)
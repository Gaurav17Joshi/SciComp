# This file was generated, do not modify it. # hide
# Code for Fast matrix add along the column
A = rand(100,100)
B = rand(100,100)
C = rand(100,100)
using BenchmarkTools
function faster_matrix_add!(C,A,B)
  for j in 1:100, i in 1:100
    C[i,j] = A[i,j] + B[i,j]
  end
end
@btime faster_matrix_add!(C,A,B)
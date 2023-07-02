# This file was generated, do not modify it. # hide
D = similar(A)
fused!(D,A,B) = (D .= A .+ B )
@btime fused!(D,A,B);
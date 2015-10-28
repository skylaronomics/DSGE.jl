using HDF5, Base.Test
import DSGE: kalcvf2NaN
include("../util.jl")

path = dirname(@__FILE__)


# Initialize arguments
# These come from the first call to the Kalman filter in gibb (line 37) -> objfcndsge (15)
#   -> dsgelh (136) -> kalcvf2NaN
# See kalcvf2NaN/test_kalcvf2NaN.m


h5 = h5open("$path/../reference/kalcvf2NaN_args.h5")
for arg in ["data", "lead", "a", "F", "b", "H", "var", "z0", "vz0"]
    eval(parse("$arg = read(h5, \"$arg\")"))
end
for arg in ["a", "b", "z0"]
    eval(parse("$arg = reshape(read(h5, \"$arg\"), length($arg), 1)"))
end

lead = round(Int,lead)


# Method with all arguments provided (9)
L, zend, Pend, pred, vpred, yprederror, ystdprederror, rmse, rmsd, filt, vfilt =
    kalcvf2NaN(data, lead, a, F, b, H, var, z0, vz0; allout=true)

L, zend, Pend = kalcvf2NaN(data, lead, a, F, b, H, var, z0, vz0)


h5 = h5open("$path/../reference/kalcvf2NaN_out9.h5")
for out in ["L", "zend", "Pend", "pred", "vpred", "yprederror", "ystdprederror", "rmse",
            "rmsd", "filt", "vfilt" ]
    eval(parse("$(out)_expected = read(h5, \"$out\")"))

    if out == "L"
        @test_approx_eq L_expected L
    elseif out == "zend"
        # Not sure why this has to be enclosed in eval(parse()) to run
        eval(parse("zend_expected = reshape(zend_expected, length(zend_expected), 1)"))
        @test test_matrix_eq(zend_expected, zend)
    else
        eval(parse("test_matrix_eq($(out)_expected, $out)"))
    end
end
close(h5)



# Method with optional arguments omitted (7)
L, zend, Pend, pred, vpred, yprederror, ystdprederror, rmse, rmsd, filt, vfilt =
    kalcvf2NaN(data, lead, a, F, b, H, var; allout=true)

L, zend, Pend = kalcvf2NaN(data, lead, a, F, b, H, var)


h5 = h5open("$path/../reference/kalcvf2NaN_out7.h5")
for out in ["L", "zend", "Pend", "pred", "vpred", "yprederror", "ystdprederror", "rmse",
            "rmsd", "filt", "vfilt" ]
    eval(parse("$(out)_expected = read(h5, \"$out\")"))

    if out == "L"
        @test_approx_eq_eps L_expected L 1e-4
    elseif out == "zend"
        zend_expected = reshape(zend_expected, length(zend_expected), 1)
        @test test_matrix_eq(zend_expected, zend)
    elseif out ∈ ["Pend", "vpred", "vfilt"]
        # These matrix entries are especially large, averaging 1e5, so we allow greater ϵ
        eval(parse("@test test_matrix_eq($(out)_expected, $out; ϵ=0.1)"))
    else
        eval(parse("@test test_matrix_eq($(out)_expected, $out)"))
    end
end
close(h5)


#println("### kalcvf2NaN tests passed\n")

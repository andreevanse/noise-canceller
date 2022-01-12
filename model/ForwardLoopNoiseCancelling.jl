using Plots, Random, FFTW, DSP, LinearAlgebra, FixedPointNumbers, DelimitedFiles
plotly()

abstract type Modulation end

struct BPSK <: Modulation
    f0
    ϕ
    Fsym
end

struct QPSK <: Modulation
    f0
    ϕ
    Fsym
end

struct OPSK <: Modulation
    f0
    ϕ
    Fsym
end

struct QAM16 <: Modulation
    f0
    ϕ
    Fsym
end

struct RandomAM <: Modulation
    f0
    ϕ
    band
    M # modulation index
end


function CodeToConstellation(m::Modulation, code)
    N = length(code)
    if isa(m, BPSK)
        cnst = [-1.0 + 0.0im, 1.0 + 0.0im]
        symb = cnst[code .+ 1]
    elseif isa(m, QPSK)
        code = [code; zeros(Int, N % 2)] #concat zeros for even code size
        cnst = [0.0 + 1.0im, -1.0 + 0.0im, 1.0 + 0.0im, 0.0 - 1.0im]
        c = 1:div(N,2)
        symb = cnst[2*code[2*c] .+ code[2*c .- 1] .+ 1]
    elseif isa(m, OPSK)
        code = [code; zeros(Int, N % 3)]
        cnst = [0.0 + 1.0im, -1.0 + 0.0im, 1.0 + 0.0im, 0.0 - 1.0im,
                     (-1.0 + 1.0im)/√2, (1.0 + 1.0im)/√2, (-1.0 - 1.0im)/√2, (1.0 - 1.0im)/√2]
        c = 1:div(N,3)
        symb = cnst[4*code[3*c] .+ 2*code[3*c.-1] .+ code[3*c.-2] .+ 1]
    elseif isa(m, QAM16)
        code = [code; zeros(Int, N % 4)]
        c = 1:div(N,4)
        cnst = [-3.0 + 3.0im, -1.0 + 3.0im, 1.0 + 3.0im, 3.0 + 3.0im,
                -3.0 + 1.0im, -1.0 + 1.0im, 1.0 + 1.0im, 3.0 + 1.0im,
                -3.0 - 1.0im, -1.0 - 1.0im, 1.0 - 1.0im, 3.0 - 1.0im,
                -3.0 - 3.0im, -1.0 - 3.0im, 1.0 - 3.0im, 3.0 - 3.0im]./3.0
        symb = cnst[8*code[4*c] .+ 4*code[4*c.-1] .+ 2*code[4*c.-2] .+ code[4*c.-3] .+ 1]
    end
    return symb
end

function GenWave(m::Modulation, fs, code)
    s = Int(round(fs/m.Fsym)) # number of samples per symbol
    symb = CodeToConstellation(m, code)
    N = length(symb)
    i = 0:floor(N*s-1)
    symbIdx = div.(i,s) .% N .+ 1
    wave = @. exp(im * (2π * m.f0/fs * i + m.ϕ)) * symb[symbIdx]
    return wave
end

function GenWave(m::RandomAM, fs, T)
    filtparam = digitalfilter(Lowpass(2*m.band/fs), Butterworth(10))
    t = 0:1/fs:T
    N = length(t) # number of samples per wave
    whitenoise = randn(ComplexF64, N)
    bandnoise = filt(filtparam, whitenoise)
    normcoeff = 3*sqrt(sum(abs2.(bandnoise))/(N-1))/2 # 3σ amplitude for normal complex distribution
    if m.f0 == 0.0
        return bandnoise./normcoeff
    end
    return (1 .+ m.M .* bandnoise./normcoeff) .* exp.(im * 2π * m.f0 * t .+ m.ϕ)
end


bpsk = BPSK(0.0, 0.0, 1.0)
qpsk = QPSK(0.0, π/3, 1.0)
opsk = OPSK(0.0, π/6, 1.0)
qam16 = QAM16(5.0, 0.0, 1.0)
am = RandomAM(0.0, 0.0, 3.0, 1.0)

fs = 100.0
code = bitrand(6000)

# wave = GenWave(bpsk, fs, code)
wave = GenWave(qpsk, fs, code)
# wave = GenWave(opsk, fs, code)
# wave = GenWave(qam16, fs, code)

noise = GenWave(am, fs, 1000.0)

minlen = min(length(wave), length(noise))

channel = noise[1:minlen] + wave[1:minlen] #+ 0.1randn(ComplexF64, minlen) # exp.(im * π .* sin.(2*π*(0:minlen-1)./1000))
# noise[1:minlen] += 0.1randn(ComplexF64, minlen)
# noise[1:minlen] += 0.0*wave[1:minlen]
# limiter(x) = complex(2atan(real(x))/π, 2atan(imag(x))/π)

# noise[1:minlen] = limiter.(noise[1:minlen])

plot([real.(channel) imag.(channel)], size = (1800, 700), label = ["Ich" "Qch"])
plot!([real.(noise) imag.(noise)], label = ["Ins" "Qns"])
gui()

Nw = length(wave)
Nn = length(noise)

fb = fs/Nw.*[0:Nw-1]
fn = fs/Nn.*[0:Nn-1]

# noise canceling
δN = 1
mainchannel(n::Int) = n >= 1 ? channel[n] : ComplexF64(0.0)
noisechannel(n::Int) = length(noise) >= n + δN >= 1 ? noise[n + δN] : ComplexF64(1.0)

f = open("channels.txt","w")
writedlm(f, [real.(channel[1:minlen])*2^9 imag.(channel[1:minlen])*2^9  real.(noise[1:minlen])*2^9 imag.(noise[1:minlen])*2^9], ',')
close(f)

N = 1000
corr = zeros(ComplexF64, minlen)
disp = zeros(minlen)
invR = zeros(ComplexF64, minlen)
fil = zeros(ComplexF64, minlen)
out = zeros(ComplexF64, minlen)
err = zeros(ComplexF64, minlen)
for i = 1:minlen-N
    corr[i] = (mainchannel.(i-N+1:i) ⋅ noisechannel.(i-N+1:i))/N
    disp[i] = sum(abs2.(noisechannel.(i-N+1:i)))/N
    invR[i] = conj(corr[i])/disp[i]
    fil[i] = invR[i]*noisechannel(i)
    out[i] = mainchannel(i) - fil[i]
    err[i] = wave[i] - out[i]
end

plot([real.(corr) imag.(corr)], size = (1800, 700), label = ["corrI" "corrQ"])
gui()
plot([real.(disp) imag.(disp)], size = (1800, 700), label = ["dispI" "dispQ"])
gui()
plot([real.(invR) imag.(invR)], size = (1800, 700), label = ["invRI" "invRQ"])
gui()
plot([real.(fil) imag.(fil)], size = (1800, 700), label = ["filI" "filQ"])
plot!([real.(noise) imag.(noise)], size = (1800, 700), label = ["noiseI" "noiseQ"])
gui()
plot([real.(out) imag.(out)], size = (1800, 700), label = ["outI" "outQ"])
gui()
plot([real.(err) imag.(err)], size = (1800, 700), label = ["errI" "errQ"])
gui()


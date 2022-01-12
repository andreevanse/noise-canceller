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
qpsk = QPSK(0.0, π/3, 3.0)
opsk = OPSK(0.0, π/6, 1.0)
qam16 = QAM16(0.0, 0.0, 1.0)
am = RandomAM(3.0, 0.0, 1.0, 1.0)

fs = 50.0
code = bitrand(60000)

# wave = 0*GenWave(bpsk, fs, code)
wave = GenWave(qpsk, fs, code)
# wave = GenWave(opsk, fs, code)
# wave = GenWave(qam16, fs, code)
noise_main = GenWave(am, fs, 2000.0)

noise_phase_shifted = [sum(noise_main[i])  for i in 1:length(noise_main)]

minlen = min(length(wave), length(noise_main))

noise = noise_main
channel = 1.5noise[1:minlen] + wave[1:minlen] #+ 0.1randn(ComplexF64, minlen) # exp.(im * π .* sin.(2*π*(0:minlen-1)./1000))

noise = noise_phase_shifted
# noise[1:minlen] += 0.1randn(ComplexF64, minlen)
noise[1:minlen] += 0.1*wave[1:minlen]

# limiter(x) = complex(2atan(real(x))/π, 2atan(imag(x))/π)
# noise[1:minlen] = limiter.(noise[1:minlen])

plot([real.(channel) imag.(channel)], size = (1800, 700), label = ["Ich" "Qch"])
plot!([real.(noise) imag.(noise)], label = ["Ins" "Qns"])
gui()

δN = 1 # delay
mainchannel(n::Int) = n >= 1 ? channel[n] : ComplexF64(0.0)
noisechannel(n::Int) = length(noise) >= n + δN >= 1 ? noise[n + δN] : ComplexF64(1.0)

f = open("./channels.txt","w")
writedlm(f, [real.(channel[1:minlen])*2^9 imag.(channel[1:minlen])*2^9  real.(noise[1:minlen])*2^9 imag.(noise[1:minlen])*2^9], ',')
close(f)

# noise canceling
W = zeros(ComplexF64, 3) # 3 coefficients are enough, but there can be more
μ = 2e-4

y(i) = sum(noisechannel.(i-length(W)+1:i) .* conj(W))
e(i) = mainchannel(i) - y(i)

filtered = zeros(ComplexF64, size(channel))
out = zeros(ComplexF64, size(channel))
Warr1 = zeros(ComplexF64, size(channel))
Warr2 = zeros(ComplexF64, size(channel))
Warr3 = zeros(ComplexF64, size(channel))
for i = 1:length(channel)
    filtered[i] = y(i)
    out[i] = e(i)
    Warr1[i] = W[1]
    Warr2[i] = W[2]
    Warr3[i] = W[3]
    W .+= μ * conj(out[i]) .* noisechannel.(i-length(W)+1:i)
end

plot([real.(filtered) imag.(filtered)], size = (1800, 700), label = ["filtI" "filtQ"])
plot!([real.(noise_main) imag.(noise_main)], size = (1800, 700), label = ["noiseI" "noiseQ"])
gui()
plot([real.(out) imag.(out)], size = (1800, 700), label = ["outI" "outQ"])
gui()
plot([real.(Warr1) imag.(Warr1)], size = (1800, 700), label = ["Wr[1]" "Wi[1]"])
plot!([real.(Warr2) imag.(Warr2)], label = ["Wr[2]" "Wi[2]"])
plot!([real.(Warr3) imag.(Warr3)], label = ["Wr[3]" "Wi[3]"])
gui()

########################### spectrum comparison
spec_wave = fft(wave)
spec_noise = fft(noise)

Nw = length(spec_wave)
Nn = length(spec_noise)

fw = fs/Nw.*[0:Nw-1]
fn = fs/Nn.*[0:Nn-1]

fcoeff = fs/minlen * [0:minlen-1]
plot(fcoeff, abs.(fft([W; zeros(ComplexF64, minlen - length(W))])), size = (1800, 700), label = "freqz")
plot!(fw, abs.(spec_wave)/maximum(abs.(spec_wave)), size = (1800, 700), label = "SIG")
plot!(fn, abs.(spec_noise)/maximum(abs.(spec_noise)), label = "NOISE")
gui()
###############################################

# spectrum before and after
spec_sig = fft(channel[end-10000:end])
spec_out = fft(out[end-10000:end])
mx = maximum(abs.(spec_sig))
plot(20log10.(abs.(spec_sig)/mx), size = (1800, 700), label = "before")
plot!(20log10.(abs.(spec_out)/mx), label = "after")
gui()
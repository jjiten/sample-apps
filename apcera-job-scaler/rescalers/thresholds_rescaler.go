package rescalers

type ThresholdsRescaler struct {
	upper    float64
	lower    float64
	size     int
	inverted bool
}

type ThresholdsRescalerConfig struct {
	Upper    float64
	Lower    float64
	Size     int
	Inverted bool
}

func NewThresholdsRescaler(config *ThresholdsRescalerConfig) *ThresholdsRescaler {
	return &ThresholdsRescaler{upper: config.Upper, lower: config.Lower, size: config.Size, inverted: config.Inverted}
}

func (t *ThresholdsRescaler) Rescale(actual float64) int {
	if actual > t.upper || (t.inverted && actual < t.lower) {
		return t.size
	}
	if actual < t.lower || (t.inverted && actual > t.upper) {
		return -t.size
	}
	return 0
}

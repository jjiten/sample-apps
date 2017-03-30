package rescalers

type ThresholdsRescaler struct {
	upper    float64
	lower    float64
	size     int
	inverted bool
}

func NewThresholdsRescaler(upper, lower float64, size int, inverted bool) *ThresholdsRescaler {
	return &ThresholdsRescaler{upper: upper, lower: lower, size: size}
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

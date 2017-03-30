package rescalers

type Rescaler interface {
	Rescale(actual float64) int
}

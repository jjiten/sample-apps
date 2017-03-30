package rescalers

import (
	"math"
	"time"
)

type FeedbackRescaler struct {
	setpoint float64

	kp float64

	ki float64
	i  float64

	kd float64
	d  float64

	lastE float64
	lastT int64

	inverted bool
}

type FeedbackRescalerConfig struct {
	Setpoint float64
	KP       float64
	KI       float64
	KD       float64
	Inverted bool
}

func NewFeedbackRescaler(config *FeedbackRescalerConfig) *FeedbackRescaler {
	return &FeedbackRescaler{kp: config.KP, ki: config.KI, kd: config.KD, lastT: time.Now().Unix(), inverted: config.Inverted}
}

func (f *FeedbackRescaler) Rescale(actual float64) int {
	now := time.Now().Unix()
	dt := float64(now - f.lastT)
	e := f.setpoint - actual
	if f.inverted {
		e = -e
	}
	f.i += e * dt
	f.d = (e - f.lastE) / dt
	f.lastE = e
	f.lastT = now

	return int(math.Ceil(f.kp*e + f.ki*f.i + f.kd*f.d))
}

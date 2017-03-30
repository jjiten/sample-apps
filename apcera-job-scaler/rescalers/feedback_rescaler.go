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

func NewFeedbackRescaler(kp, ki, kd float64, inverted bool) *FeedbackRescaler {
	return &FeedbackRescaler{kp: kp, ki: ki, kd: kd, lastT: time.Now().Unix(), inverted: inverted}
}

func (f *FeedbackRescaler) Rescale(actual float64) int {
	now := time.Now().Unix()
	dt := float64(now - f.lastT)
	e := f.setpoint - actual
	f.i += e * dt
	f.d = (e - f.lastE) / dt
	f.lastE = e
	f.lastT = now

	return int(math.Ceil(f.kp*e + f.ki*f.i + f.kd*f.d))
}

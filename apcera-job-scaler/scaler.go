// Copyright 2016 Apcera Inc. All right reserved.

package main

import (
	"encoding/json"
	"strconv"
	"sync"
	"time"

	"math"

	"github.com/apcera/sample-apps/apcera-job-scaler/metrics"
	"github.com/apcera/sample-apps/apcera-job-scaler/monitor"
	"github.com/apcera/sample-apps/apcera-job-scaler/rescalers"
	"github.com/apcera/sample-apps/apcera-job-scaler/sink"
	"github.com/apcera/sample-apps/apcera-job-scaler/util"
	"github.com/op/go-logging"
)

var log = logging.MustGetLogger("Job Scaler")

// ScalingJobConfig is the set of configurations associated with the
// job being scaled by the defaultJobScaler
type ScalingJobConfig struct {
	// jobFQN is the FQN of the job to be scaled
	jobFQN string
	// scalingFrequency is how often to scale the job
	scalingFrequency time.Duration
	// maxInstances is the max no. of instances the job can be scaled up to
	maxInstances int
	// minInstances is the min no. of intsances the job can be scaled down to
	minInstances int
	rescaler     rescalers.Rescaler
}

// JobScaler is built using Job Monitor and Job Metric services/objects.
// It scales jobs based on the defaultScalingJobConfig data model.
type JobScaler struct {
	lock sync.RWMutex
	// jobsBeingScaled is the map to track jobs being scaled by the Job Scaler
	jobsBeingScaled map[string]chan bool
	// jobSink is the store being used to track metric stats
	jobSink sink.JobSink
	// jobMonitor subscribes to events on FQNs on which auto-scaling has been requested.
	jobMonitor monitor.JobMonitor
	// jobMetricCal provides with generic resource metric algorithms.
	jobMetricCalc  metrics.JobMetricCalc
	verboseLogging bool
}

// NewJobScaler prototypes a possible Job Auto Scaler behavior.
func NewJobScaler() *JobScaler {
	js := &JobScaler{}
	js.jobsBeingScaled = make(map[string]chan bool)

	js.jobSink = sink.NewDefaultJobSink()
	js.jobMonitor = monitor.NewDefaultJobMonitor(js.jobSink)
	js.jobMetricCalc = metrics.NewDefaultJobMetricCalc(js.jobSink)

	return js
}

// EnableAutoScale queues in the job for monitoring and concurrently tracks
// for scaling triggers.
func (js *JobScaler) EnableAutoScale(config ScalingJobConfig) error {
	log.Infof("Enabling %v for auto scaling", config.jobFQN)
	err := js.jobMonitor.MonitorJob(config.jobFQN)
	if err != nil {
		return err
	}

	js.lock.Lock()
	js.jobsBeingScaled[config.jobFQN] = make(chan bool)
	js.lock.Unlock()
	go js.AutoScale(config, js.jobsBeingScaled[config.jobFQN])

	return nil
}

// DisableAutoScale dequeues the job from monitoring and stops tracking
// associated scaling triggers.
func (js *JobScaler) DisableAutoScale(jobFQN string) error {
	log.Infof("Disabling %v from auto scaling", jobFQN)
	err := js.jobMonitor.UnmonitorJob(jobFQN)
	if err != nil {
		return err
	}

	close(js.jobsBeingScaled[jobFQN])
	js.lock.Lock()
	delete(js.jobsBeingScaled, jobFQN)
	js.lock.Unlock()

	return nil
}

// AutoScale is the default algorithm being used to trigger scaling behaviour.
// It is mainly based around the ScalingJobConfig data model.
func (js *JobScaler) AutoScale(config ScalingJobConfig, done chan bool) {
	jobFQN := config.jobFQN
	scalingTicker := time.NewTicker(config.scalingFrequency).C
	for {
		select {
		// For now scaling just based on CPU Utilization.
		// This should be again configurable through parameters
		// in ScalingJobConfig.
		case <-scalingTicker:
			cpuUtil, err := js.jobMetricCalc.CPUUtilization(jobFQN)
			// Resetting job sink window of metrics
			js.jobSink.ResetStore()
			if err != nil {
				log.Error(err)
				continue
			}
			js.rescale(config, config.rescaler.Rescale(cpuUtil))
		case <-done:
			return
		}
	}
}

func (js *JobScaler) rescale(sj ScalingJobConfig, size int) {
	if size == 0 {
		if js.verboseLogging {
			log.Info("No need to rescale job")
		}
		return
	}
	job, err := util.GetJob(sj.jobFQN)
	if err != nil {
		log.Errorf("Failed to rescale job %v. %v", sj.jobFQN, err)
		return
	}
	n := job["num_instances"].(json.Number)
	curCount, _ := strconv.Atoi(string(n))
	newCount := curCount + size
	newCount = int(math.Min(math.Max(float64(newCount), float64(sj.minInstances)), float64(sj.maxInstances)))

	job["num_instances"] = newCount
	err = util.SetJob(job)
	if err != nil {
		log.Errorf("Failed rescaling job %v from %d to %d. %v", sj.jobFQN, curCount, newCount, err)
		return
	}
	log.Infof("Rescaled job instances from %v to %v", curCount, newCount)
}

// Inactive if the Job Monitor being used by the Job Scaler is down.
func (js *JobScaler) Inactive() chan bool {
	return js.jobMonitor.MonitorDown()
}

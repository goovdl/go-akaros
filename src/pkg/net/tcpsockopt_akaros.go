// Copyright 2014 The Go Authors.  All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// TCP socket options for akaros

package net

import (
	"time"
)

// Set keep alive period.
func setKeepAlivePeriod(fd *netFD, d time.Duration) error {
	cmd := "keepalive " + string(int64(d/time.Millisecond))
	_, e := fd.ctl.WriteAt([]byte(cmd), 0)
	return e
}

package demo

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/suite"
)

type DemoTestSuite struct {
	suite.Suite
}

func TestDemoTestSuite(t *testing.T) {
	suite.Run(t, new(DemoTestSuite))
}

func (suite *DemoTestSuite) TestAdd() {
	type testcase struct {
		name     string
		a        int
		b        int
		expected int
	}
	testcases := []testcase{
		{
			name:     "1+1",
			a:        1,
			b:        1,
			expected: 2,
		},
		{
			name:     "1+0",
			a:        1,
			b:        0,
			expected: 1,
		},
		{
			name:     "0+1",
			a:        0,
			b:        1,
			expected: 1,
		},
	}
	for _, tt := range testcases {
		suite.Run(tt.name, func() {
			assert.Equal(suite.T(), tt.expected, Add(tt.a, tt.b))
		})
	}
}

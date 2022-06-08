/*
Copyright The Kubernetes Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

// Code generated by client-gen. DO NOT EDIT.

package fake

import (
	"context"

	v1beta1 "github.com/tektoncd/pipeline/pkg/apis/pipeline/v1beta1"
	v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	labels "k8s.io/apimachinery/pkg/labels"
	schema "k8s.io/apimachinery/pkg/runtime/schema"
	types "k8s.io/apimachinery/pkg/types"
	watch "k8s.io/apimachinery/pkg/watch"
	testing "k8s.io/client-go/testing"
)

// FakeRuns implements RunInterface
type FakeRuns struct {
	Fake *FakeTektonv1beta1
	ns   string
}

var runsResource = schema.GroupVersionResource{Group: "tekton.dev", Version: "v1beta1", Resource: "runs"}

var runsKind = schema.GroupVersionKind{Group: "tekton.dev", Version: "v1beta1", Kind: "Run"}

// Get takes name of the run, and returns the corresponding run object, and an error if there is any.
func (c *FakeRuns) Get(ctx context.Context, name string, options v1.GetOptions) (result *v1beta1.Run, err error) {
	obj, err := c.Fake.
		Invokes(testing.NewGetAction(runsResource, c.ns, name), &v1beta1.Run{})

	if obj == nil {
		return nil, err
	}
	return obj.(*v1beta1.Run), err
}

// List takes label and field selectors, and returns the list of Runs that match those selectors.
func (c *FakeRuns) List(ctx context.Context, opts v1.ListOptions) (result *v1beta1.RunList, err error) {
	obj, err := c.Fake.
		Invokes(testing.NewListAction(runsResource, runsKind, c.ns, opts), &v1beta1.RunList{})

	if obj == nil {
		return nil, err
	}

	label, _, _ := testing.ExtractFromListOptions(opts)
	if label == nil {
		label = labels.Everything()
	}
	list := &v1beta1.RunList{ListMeta: obj.(*v1beta1.RunList).ListMeta}
	for _, item := range obj.(*v1beta1.RunList).Items {
		if label.Matches(labels.Set(item.Labels)) {
			list.Items = append(list.Items, item)
		}
	}
	return list, err
}

// Watch returns a watch.Interface that watches the requested runs.
func (c *FakeRuns) Watch(ctx context.Context, opts v1.ListOptions) (watch.Interface, error) {
	return c.Fake.
		InvokesWatch(testing.NewWatchAction(runsResource, c.ns, opts))

}

// Create takes the representation of a run and creates it.  Returns the server's representation of the run, and an error, if there is any.
func (c *FakeRuns) Create(ctx context.Context, run *v1beta1.Run, opts v1.CreateOptions) (result *v1beta1.Run, err error) {
	obj, err := c.Fake.
		Invokes(testing.NewCreateAction(runsResource, c.ns, run), &v1beta1.Run{})

	if obj == nil {
		return nil, err
	}
	return obj.(*v1beta1.Run), err
}

// Update takes the representation of a run and updates it. Returns the server's representation of the run, and an error, if there is any.
func (c *FakeRuns) Update(ctx context.Context, run *v1beta1.Run, opts v1.UpdateOptions) (result *v1beta1.Run, err error) {
	obj, err := c.Fake.
		Invokes(testing.NewUpdateAction(runsResource, c.ns, run), &v1beta1.Run{})

	if obj == nil {
		return nil, err
	}
	return obj.(*v1beta1.Run), err
}

// UpdateStatus was generated because the type contains a Status member.
// Add a +genclient:noStatus comment above the type to avoid generating UpdateStatus().
func (c *FakeRuns) UpdateStatus(ctx context.Context, run *v1beta1.Run, opts v1.UpdateOptions) (*v1beta1.Run, error) {
	obj, err := c.Fake.
		Invokes(testing.NewUpdateSubresourceAction(runsResource, "status", c.ns, run), &v1beta1.Run{})

	if obj == nil {
		return nil, err
	}
	return obj.(*v1beta1.Run), err
}

// Delete takes name of the run and deletes it. Returns an error if one occurs.
func (c *FakeRuns) Delete(ctx context.Context, name string, opts v1.DeleteOptions) error {
	_, err := c.Fake.
		Invokes(testing.NewDeleteAction(runsResource, c.ns, name), &v1beta1.Run{})

	return err
}

// DeleteCollection deletes a collection of objects.
func (c *FakeRuns) DeleteCollection(ctx context.Context, opts v1.DeleteOptions, listOpts v1.ListOptions) error {
	action := testing.NewDeleteCollectionAction(runsResource, c.ns, listOpts)

	_, err := c.Fake.Invokes(action, &v1beta1.RunList{})
	return err
}

// Patch applies the patch and returns the patched run.
func (c *FakeRuns) Patch(ctx context.Context, name string, pt types.PatchType, data []byte, opts v1.PatchOptions, subresources ...string) (result *v1beta1.Run, err error) {
	obj, err := c.Fake.
		Invokes(testing.NewPatchSubresourceAction(runsResource, c.ns, name, pt, data, subresources...), &v1beta1.Run{})

	if obj == nil {
		return nil, err
	}
	return obj.(*v1beta1.Run), err
}

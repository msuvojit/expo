/**
 * Copyright (c) 2015-present, Facebook, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @providesModule StyleSheetPropType
 * @flow
 */
'use strict';

var createStrictShapeTypeChecker = require('../Utilities/createStrictShapeTypeChecker');
var flattenStyle = require('./flattenStyle');

function StyleSheetPropType(
  shape: {[key: string]: ReactPropsCheckType}
): ReactPropsCheckType {
  var shapePropType = createStrictShapeTypeChecker(shape);
  return function(props, propName, componentName, location?, ...rest) {
    var newProps = props;
    if (props[propName]) {
      // Just make a dummy prop object with only the flattened style
      newProps = {};
      newProps[propName] = flattenStyle(props[propName]);
    }
    return shapePropType(newProps, propName, componentName, location, ...rest);
  };
}

module.exports = StyleSheetPropType;

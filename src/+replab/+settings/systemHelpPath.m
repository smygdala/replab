function value = systemHelpPath(newValue)
% Get/set the folder containing MATLAB/Octave ``help.m``
%
% If called without argument, returns the stored value.
%
% The call with one argument changes the stored value; it should only be called
% as part of ``replab_init``.
%
% The stored value survives ``clear all`` as this function is locked.
%
% Args:
%   newValue (charstring, optional): Sets the stored value
%
% Returns:
%   charstring: Path of the folder containing the original ``help.m`` without trailing file separator
    mlock
    persistent storedValue
    if nargin == 1
        storedValue = newValue;
    end
    value = storedValue;
end

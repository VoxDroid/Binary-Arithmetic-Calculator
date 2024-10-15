classdef BinaryArithmeticCalculator < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure               matlab.ui.Figure
        TabGroup               matlab.ui.container.TabGroup
        CalculatorTab          matlab.ui.container.Tab
        Input1EditField        matlab.ui.control.EditField
        Input1EditFieldLabel   matlab.ui.control.Label
        Input2EditField        matlab.ui.control.EditField
        Input2EditFieldLabel   matlab.ui.control.Label
        OperationDropDown      matlab.ui.control.DropDown
        OperationDropDownLabel matlab.ui.control.Label
        CalculateButton        matlab.ui.control.Button
        ResultLabel            matlab.ui.control.Label
        HistoryListBox         matlab.ui.control.ListBox
        HistoryLabel           matlab.ui.control.Label
        ClearHistoryButton     matlab.ui.control.Button
        BinaryLengthSlider     matlab.ui.control.Slider
        BinaryLengthLabel      matlab.ui.control.Label
        TwosComplementSwitch   matlab.ui.control.Switch
        TwosComplementLabel    matlab.ui.control.Label
        TutorialTab            matlab.ui.container.Tab
        TutorialTextArea       matlab.ui.control.TextArea
        AboutMeTab             matlab.ui.container.Tab
        AboutMeTextArea        matlab.ui.control.TextArea
        VisualizationTab       matlab.ui.container.Tab
        UIAxes                 matlab.ui.control.UIAxes
        DecimalResultLabel     matlab.ui.control.Label
        CopyResultButton       matlab.ui.control.Button
        AutoCalculateCheckBox  matlab.ui.control.CheckBox
        BaseSystemDropDown     matlab.ui.control.DropDown
        BaseSystemLabel        matlab.ui.control.Label
        SignedModeSwitch       matlab.ui.control.Switch
        SignedModeLabel        matlab.ui.control.Label
        FloatingPointSwitch    matlab.ui.control.Switch
        FloatingPointLabel     matlab.ui.control.Label
        PrecisionEditField     matlab.ui.control.NumericEditField
        PrecisionLabel         matlab.ui.control.Label
        ConversionHistoryTab   matlab.ui.container.Tab
        ConversionHistoryTable matlab.ui.control.Table
        BitRepresentationLabel matlab.ui.control.Label
    end

    properties (Access = private)
        History = {}
        BinaryLength = 8
        UseTwosComplement = false
        AutoCalculate = false
        BaseSystem = 2
        SignedMode = false
        FloatingPointMode = false
        Precision = 3
        ConversionHistory = table('Size',[0 4], 'VariableTypes',{'string','string','string','string'}, 'VariableNames',{'From','To','Input','Result'})
    end

    methods (Access = private)

        function result = convertToDecimal(app, input)
            if app.FloatingPointMode
                result = str2double(input);
            else
                result = base2dec(input, app.BaseSystem);
                if app.SignedMode && result >= 2^(app.BinaryLength-1)
                    result = result - 2^app.BinaryLength;
                end
            end
        end

        function result = convertFromDecimal(app, decimal)
            if app.FloatingPointMode
                result = num2str(decimal, ['%.' num2str(app.Precision) 'f']);
            else
                if app.SignedMode && decimal < 0
                    decimal = decimal + 2^app.BinaryLength;
                end
                result = dec2base(decimal, app.BaseSystem, app.BinaryLength);
            end
        end

        function result = performOperation(app, a, b, operation)
            decimalA = app.convertToDecimal(a);
            decimalB = app.convertToDecimal(b);

            switch operation
                case 'Addition'
                    decimalResult = decimalA + decimalB;
                case 'Subtraction'
                    decimalResult = decimalA - decimalB;
                case 'Multiplication'
                    decimalResult = decimalA * decimalB;
                case 'Division'
                    if decimalB == 0
                        result = 'Error: Division by zero';
                        return;
                    end
                    decimalResult = decimalA / decimalB;
                case 'AND'
                    decimalResult = bitand(decimalA, decimalB);
                case 'OR'
                    decimalResult = bitor(decimalA, decimalB);
                case 'XOR'
                    decimalResult = bitxor(decimalA, decimalB);
                case 'NOT'
                    decimalResult = bitcmp(decimalA, app.BinaryLength);
                case 'Left Shift'
                    decimalResult = bitshift(decimalA, decimalB);
                case 'Right Shift'
                    decimalResult = bitshift(decimalA, -decimalB);
                case 'Modulo'
                    decimalResult = mod(decimalA, decimalB);
                case 'Power'
                    decimalResult = decimalA ^ decimalB;
                case 'Square Root'
                    decimalResult = sqrt(decimalA);
                case 'Logarithm'
                    if decimalA <= 0
                        result = 'Error: Invalid input for logarithm';
                        return;
                    end
                    decimalResult = log(decimalA);
            end

            result = app.convertFromDecimal(decimalResult);
        end

        function isValid = validateInput(app, input)
            if app.FloatingPointMode
                isValid = ~isnan(str2double(input));
            else
                validChars = ['0':'9' 'A':'Z'];
                isValid = all(ismember(upper(input), validChars(1:app.BaseSystem))) && (length(input) <= app.BinaryLength);
            end
        end

        function updateHistory(app, operation, input1, input2, result)
            operationSymbol = app.getOperationSymbol(operation);
            historyEntry = sprintf('%s %s %s = %s', input1, operationSymbol, input2, result);
            app.History = [{historyEntry}, app.History];
            if length(app.History) > 10
                app.History(end) = [];
            end
            app.HistoryListBox.Items = app.History;
        end

        function symbol = getOperationSymbol(~, operation)
            switch operation
                case 'Addition'
                    symbol = '+';
                case 'Subtraction'
                    symbol = '-';
                case 'Multiplication'
                    symbol = '*';
                case 'Division'
                    symbol = '/';
                case 'AND'
                    symbol = '&';
                case 'OR'
                    symbol = '|';
                case 'XOR'
                    symbol = '^';
                case 'NOT'
                    symbol = '~';
                case 'Left Shift'
                    symbol = '<<';
                case 'Right Shift'
                    symbol = '>>';
                case 'Modulo'
                    symbol = '%';
                case 'Power'
                    symbol = '^';
                case 'Square Root'
                    symbol = '√';
                case 'Logarithm'
                    symbol = 'log';
                otherwise
                    symbol = operation;
            end
        end

        function visualizeResult(app, result)
            cla(app.UIAxes);
            if app.FloatingPointMode
                % Visualize floating-point number
                floatVal = str2double(result);
                [mantissa, exponent] = log2(abs(floatVal));
                bar(app.UIAxes, [mantissa, exponent]);
                app.UIAxes.XTickLabel = {'Mantissa', 'Exponent'};
                title(app.UIAxes, 'Floating-Point Representation');
            else
                % Visualize integer
                bits = double(result) - double('0');
                bar(app.UIAxes, bits);
                app.UIAxes.XLim = [0 app.BinaryLength+1];
                app.UIAxes.YLim = [0 1];
                app.UIAxes.XTick = 1:app.BinaryLength;
                app.UIAxes.XTickLabel = num2cell(app.BinaryLength:-1:1);
                app.UIAxes.YTick = [0 1];
                app.UIAxes.YTickLabel = {'0', '1'};
                title(app.UIAxes, 'Binary Representation');
            end
            xlabel(app.UIAxes, 'Bit Position');
            ylabel(app.UIAxes, 'Bit Value');
        end

        function updateConversionHistory(app, fromBase, toBase, input, result)
            newRow = {fromBase, toBase, input, result};
            app.ConversionHistory = [newRow; app.ConversionHistory];
            if height(app.ConversionHistory) > 10
                app.ConversionHistory(end,:) = [];
            end
            app.ConversionHistoryTable.Data = app.ConversionHistory;
        end

        function updateBitRepresentation(app, input)
            if ~app.FloatingPointMode
                binStr = dec2bin(hex2dec(input), app.BinaryLength);
                app.BitRepresentationLabel.Text = ['Bit Representation: ' binStr];
            else
                app.BitRepresentationLabel.Text = 'Bit Representation: N/A for floating-point';
            end
        end
    end

    methods (Access = private)

        function CalculateButtonPushed(app, ~)
            input1 = app.Input1EditField.Value;
            input2 = app.Input2EditField.Value;
            operation = app.OperationDropDown.Value;

            if ~app.validateInput(input1) || (~strcmp(operation, 'NOT') && ~strcmp(operation, 'Square Root') && ~strcmp(operation, 'Logarithm') && ~app.validateInput(input2))
                app.ResultLabel.Text = 'Error: Invalid input';
                return;
            end

            if ~app.FloatingPointMode
                input1 = pad(input1, app.BinaryLength, 'left', '0');
                input2 = pad(input2, app.BinaryLength, 'left', '0');
            end

            result = app.performOperation(input1, input2, operation);

            app.ResultLabel.Text = ['Result: ', result];
            app.DecimalResultLabel.Text = ['Decimal: ', num2str(app.convertToDecimal(result))];
            app.updateHistory(operation, input1, input2, result);
            app.visualizeResult(result);
            app.updateConversionHistory(num2str(app.BaseSystem), 'Result', input1, result);
            app.updateBitRepresentation(result);
        end

        function BinaryLengthSliderValueChanged(app, ~)
            app.BinaryLength = round(app.BinaryLengthSlider.Value);
            app.BinaryLengthLabel.Text = sprintf('Binary Length: %d', app.BinaryLength);
            if app.AutoCalculate
                app.CalculateButtonPushed();
            end
        end

        function TwosComplementSwitchValueChanged(app, ~)
            app.UseTwosComplement = app.TwosComplementSwitch.Value;
            if app.AutoCalculate
                app.CalculateButtonPushed();
            end
        end

        function ClearHistoryButtonPushed(app, ~)
            app.History = {};
            app.HistoryListBox.Items = {};
        end

        function CopyResultButtonPushed(app, ~)
            result = app.ResultLabel.Text;
            clipboard('copy', result);
        end

        function AutoCalculateCheckBoxValueChanged(app, ~)
            app.AutoCalculate = app.AutoCalculateCheckBox.Value;
            if app.AutoCalculate
                app.CalculateButtonPushed();
            end
        end

        function BaseSystemDropDownValueChanged(app, ~)
            app.BaseSystem = str2double(app.BaseSystemDropDown.Value);
            if app.AutoCalculate
                app.CalculateButtonPushed();
            end
        end

        function SignedModeSwitchValueChanged(app, ~)
            app.SignedMode = app.SignedModeSwitch.Value;
            if app.AutoCalculate
                app.CalculateButtonPushed();
            end
        end

        function FloatingPointSwitchValueChanged(app, ~)
            app.FloatingPointMode = app.FloatingPointSwitch.Value;
            app.PrecisionEditField.Visible = app.FloatingPointMode;
            app.PrecisionLabel.Visible = app.FloatingPointMode;
            if app.AutoCalculate
                app.CalculateButtonPushed();
            end
        end

        function PrecisionEditFieldValueChanged(app, ~)
            app.Precision = app.PrecisionEditField.Value;
            if app.AutoCalculate
                app.CalculateButtonPushed();
            end
        end

        function InputValueChanged(app, ~)
            if app.AutoCalculate
                app.CalculateButtonPushed();
            end
        end
    end

    methods (Access = private)

        function createComponents(app)

            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 800 600];
            app.UIFigure.Name = 'Simple Binary Arithmetic Calculator';
            app.UIFigure.Color = [0.9412 0.9412 0.9412];

            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.Position = [1 1 800 600];

            app.CalculatorTab = uitab(app.TabGroup);
            app.CalculatorTab.Title = 'Calculator';
            app.CalculatorTab.BackgroundColor = [0.9412 0.9412 0.9412];

            app.Input1EditFieldLabel = uilabel(app.CalculatorTab);
            app.Input1EditFieldLabel.HorizontalAlignment = 'right';
            app.Input1EditFieldLabel.Position = [20 540 47 22];
            app.Input1EditFieldLabel.Text = 'Input 1';

            app.Input1EditField = uieditfield(app.CalculatorTab, 'text');
            app.Input1EditField.ValueChangedFcn = createCallbackFcn(app, @InputValueChanged, true);
            app.Input1EditField.Position = [82 540 140 22];

            app.Input2EditFieldLabel = uilabel(app.CalculatorTab);
            app.Input2EditFieldLabel.HorizontalAlignment = 'right';
            
            app.Input2EditFieldLabel.Position = [20 510 47 22];
            app.Input2EditFieldLabel.Text = 'Input 2';

            app.Input2EditField = uieditfield(app.CalculatorTab, 'text');
            app.Input2EditField.ValueChangedFcn = createCallbackFcn(app, @InputValueChanged, true);
            app.Input2EditField.Position = [82 510 140 22];

            app.OperationDropDownLabel = uilabel(app.CalculatorTab);
            app.OperationDropDownLabel.HorizontalAlignment = 'right';
            app.OperationDropDownLabel.Position = [5 480 62 22];
            app.OperationDropDownLabel.Text = 'Operation';

            app.OperationDropDown = uidropdown(app.CalculatorTab);
            app.OperationDropDown.Items = {'Addition', 'Subtraction', 'Multiplication', 'Division', 'AND', 'OR', 'XOR', 'NOT', 'Left Shift', 'Right Shift', 'Modulo', 'Power', 'Square Root', 'Logarithm'};
            app.OperationDropDown.ValueChangedFcn = createCallbackFcn(app, @InputValueChanged, true);
            app.OperationDropDown.Position = [82 480 140 22];
            app.OperationDropDown.Value = 'Addition';

            app.CalculateButton = uibutton(app.CalculatorTab, 'push');
            app.CalculateButton.ButtonPushedFcn = createCallbackFcn(app, @CalculateButtonPushed, true);
            app.CalculateButton.Position = [82 450 100 22];
            app.CalculateButton.Text = 'Calculate';

            app.ResultLabel = uilabel(app.CalculatorTab);
            app.ResultLabel.Position = [82 420 300 22];
            app.ResultLabel.Text = 'Result: ';

            app.DecimalResultLabel = uilabel(app.CalculatorTab);
            app.DecimalResultLabel.Position = [82 390 300 22];
            app.DecimalResultLabel.Text = 'Decimal: ';

            app.BitRepresentationLabel = uilabel(app.CalculatorTab);
            app.BitRepresentationLabel.Position = [82 360 300 22];
            app.BitRepresentationLabel.Text = 'Bit Representation: ';

            app.CopyResultButton = uibutton(app.CalculatorTab, 'push');
            app.CopyResultButton.ButtonPushedFcn = createCallbackFcn(app, @CopyResultButtonPushed, true);
            app.CopyResultButton.Position = [82 330 100 22];
            app.CopyResultButton.Text = 'Copy Result';

            app.HistoryLabel = uilabel(app.CalculatorTab);
            app.HistoryLabel.Position = [20 300 100 22];
            app.HistoryLabel.Text = 'Operation History';

            app.HistoryListBox = uilistbox(app.CalculatorTab);
            app.HistoryListBox.Position = [20 100 300 200];

            app.ClearHistoryButton = uibutton(app.CalculatorTab, 'push');
            app.ClearHistoryButton.ButtonPushedFcn = createCallbackFcn(app, @ClearHistoryButtonPushed, true);
            app.ClearHistoryButton.Position = [20 70 100 22];
            app.ClearHistoryButton.Text = 'Clear History';

            app.BinaryLengthLabel = uilabel(app.CalculatorTab);
            app.BinaryLengthLabel.Position = [350 540 140 22];
            app.BinaryLengthLabel.Text = 'Binary Length: 8';

            app.BinaryLengthSlider = uislider(app.CalculatorTab);
            app.BinaryLengthSlider.Limits = [4 32];
            app.BinaryLengthSlider.MajorTicks = [4 8 16 24 32];
            app.BinaryLengthSlider.MinorTicks = [];
            app.BinaryLengthSlider.ValueChangedFcn = createCallbackFcn(app, @BinaryLengthSliderValueChanged, true);
            app.BinaryLengthSlider.Position = [350 530 200 3];
            app.BinaryLengthSlider.Value = 8;

            app.TwosComplementLabel = uilabel(app.CalculatorTab);
            app.TwosComplementLabel.Position = [430 469 140 22];
            app.TwosComplementLabel.Text = 'Use Two''s Complement';

            app.TwosComplementSwitch = uiswitch(app.CalculatorTab, 'slider');
            app.TwosComplementSwitch.ValueChangedFcn = createCallbackFcn(app, @TwosComplementSwitchValueChanged, true);
            app.TwosComplementSwitch.Position = [350 470 45 20];

            app.AutoCalculateCheckBox = uicheckbox(app.CalculatorTab);
            app.AutoCalculateCheckBox.ValueChangedFcn = createCallbackFcn(app, @AutoCalculateCheckBoxValueChanged, true);
            app.AutoCalculateCheckBox.Text = 'Auto Calculate';
            app.AutoCalculateCheckBox.Position = [350 440 120 22];

            app.BaseSystemLabel = uilabel(app.CalculatorTab);
            app.BaseSystemLabel.HorizontalAlignment = 'right';
            app.BaseSystemLabel.Position = [350 410 80 22];
            app.BaseSystemLabel.Text = 'Base System';

            app.BaseSystemDropDown = uidropdown(app.CalculatorTab);
            app.BaseSystemDropDown.Items = {'2', '8', '10', '16'};
            app.BaseSystemDropDown.ValueChangedFcn = createCallbackFcn(app, @BaseSystemDropDownValueChanged, true);
            app.BaseSystemDropDown.Position = [440 410 60 22];
            app.BaseSystemDropDown.Value = '2';

            app.SignedModeLabel = uilabel(app.CalculatorTab);
            app.SignedModeLabel.Position = [350 380 80 22];
            app.SignedModeLabel.Text = 'Signed Mode';

            app.SignedModeSwitch = uiswitch(app.CalculatorTab, 'slider');
            app.SignedModeSwitch.ValueChangedFcn = createCallbackFcn(app, @SignedModeSwitchValueChanged, true);
            app.SignedModeSwitch.Position = [350 350 45 20];

            app.FloatingPointLabel = uilabel(app.CalculatorTab);
            app.FloatingPointLabel.Position = [350 320 100 22];
            app.FloatingPointLabel.Text = 'Floating Point';

            app.FloatingPointSwitch = uiswitch(app.CalculatorTab, 'slider');
            app.FloatingPointSwitch.ValueChangedFcn = createCallbackFcn(app, @FloatingPointSwitchValueChanged, true);
            app.FloatingPointSwitch.Position = [350 290 45 20];

            app.PrecisionLabel = uilabel(app.CalculatorTab);
            app.PrecisionLabel.Position = [350 260 100 22];
            app.PrecisionLabel.Text = 'Precision';

            app.PrecisionEditField = uieditfield(app.CalculatorTab, 'numeric');
            app.PrecisionEditField.Limits = [1 10];
            app.PrecisionEditField.ValueChangedFcn = createCallbackFcn(app, @PrecisionEditFieldValueChanged, true);
            app.PrecisionEditField.Position = [350 230 50 22];
            app.PrecisionEditField.Value = 3;

            app.TutorialTab = uitab(app.TabGroup);
            app.TutorialTab.Title = 'Tutorial';
            app.TutorialTab.BackgroundColor = [0.9412 0.9412 0.9412];

            app.TutorialTextArea = uitextarea(app.TutorialTab);
            app.TutorialTextArea.Position = [10 10 780 560];
            app.TutorialTextArea.Value = {'Simple Binary Arithmetic Calculator Tutorial'; ''; '1. Input: Enter numbers in Input 1 and Input 2 fields according to the selected base system.'; '2. Base System: Choose between Binary (2), Octal (8), Decimal (10), or Hexadecimal (16).'; '3. Operation: Select the desired operation from the dropdown menu.'; '4. Calculate: Click the Calculate button or enable Auto Calculate for instant results.'; '5. Result: The result in the selected base system and its decimal equivalent will be displayed.'; '6. Bit Representation: Shows the binary representation of the result.'; '7. Copy Result: Click to copy the result to clipboard.'; '8. History: View recent operations in the History list box.'; '9. Binary Length: Adjust the slider to set the desired length (4-32 bits).'; '10. Two''s Complement: Toggle the switch to use two''s complement for signed numbers.'; '11. Signed Mode: Toggle the switch to enable signed number representation.'; '12. Floating Point: Toggle the switch to enable floating-point mode.'; '13. Precision: Set the number of decimal places for floating-point results (1-10).'; '14. Visualization: The result is visualized in the Visualization tab.'; '15. Conversion History: View recent number system conversions in the Conversion History tab.'; ''; 'Supported Operations:'; '- Addition (+): Adds two numbers'; '- Subtraction (-): Subtracts the second number from the first'; '- Multiplication (*): Multiplies two numbers'; '- Division (/): Divides the first number by the second'; '- AND (&): Performs bitwise AND operation'; '- OR (|): Performs bitwise OR operation'; '- XOR (^): Performs bitwise XOR operation'; '- NOT (~): Performs bitwise NOT operation on Input 1'; '- Left Shift (<<): Shifts Input 1 left by the number of positions specified in Input 2'; '- Right Shift (>>): Shifts Input 1 right by the number of positions specified in Input 2'; '- Modulo (%): Calculates the remainder of division of Input 1 by Input 2'; '- Power (^): Raises Input 1 to the power of Input 2'; '- Square Root (√): Calculates the square root of Input 1'; '- Logarithm (log): Calculates the natural logarithm of Input 1'; ''; 'Note: For NOT, Square Root, and Logarithm operations, only Input 1 is used.'};
            app.TutorialTextArea.Editable = 'off';

            app.AboutMeTab = uitab(app.TabGroup);
            app.AboutMeTab.Title = 'About Me';
            app.AboutMeTab.BackgroundColor = [0.9412 0.9412 0.9412];

            app.AboutMeTextArea = uitextarea(app.AboutMeTab);
            app.AboutMeTextArea.Position = [10 10 780 560];
            app.AboutMeTextArea.Value = {'About the Simple Binary Arithmetic Calculator'; ''; 'Version: 6.0'; 'Developer: Mhar Andrei Macapallag'; ''; 'This Simple Binary Arithmetic Calculator is a sophisticated MATLAB application designed to perform various arithmetic operations in different number systems with additional features for enhanced functionality and user experience.'; ''; 'Features:'; '- Support for Binary, Octal, Decimal, and Hexadecimal number systems'; '- Basic arithmetic operations (addition, subtraction, multiplication, division)'; '- Bitwise operations (AND, OR, XOR, NOT)'; '- Shift operations (left shift, right shift)'; '- Advanced mathematical operations (modulo, power, square root, logarithm)'; '- Adjustable number length (4-32 bits)'; '- Two''s complement support for signed numbers'; '- Signed mode for negative number representation'; '- Floating-point mode with adjustable precision'; '- Auto-calculate functionality'; '- Operation history tracking with simplified symbols'; '- Number visualization for both integer and floating-point representations'; '- Decimal result display'; '- Bit representation display'; '- Copy result to clipboard functionality'; '- Comprehensive input validation'; '- User-friendly interface with tooltips and instructions'; '- Conversion history tracking'; ''; 'The calculator uses MATLAB''s built-in functions for number system conversions and bitwise operations, ensuring accurate results. It also includes error handling for invalid inputs and edge cases like division by zero.'; ''; 'This simple tool is ideal for students, educators, and professionals working with different number systems, digital logic, computer architecture, or any field that involves binary, octal, decimal, or hexadecimal arithmetic.'; ''; 'For any questions, suggestions, or bug reports, please contact: me via github @VoxDroid'};
            app.AboutMeTextArea.Editable = 'off';

            app.VisualizationTab = uitab(app.TabGroup);
            app.VisualizationTab.Title = 'Visualization';
            app.VisualizationTab.BackgroundColor = [0.9412 0.9412 0.9412];

            app.UIAxes = uiaxes(app.VisualizationTab);
            title(app.UIAxes, 'Result Visualization')
            xlabel(app.UIAxes, 'Bit Position')
            ylabel(app.UIAxes, 'Bit Value')
            app.UIAxes.Position = [10 10 780 560];

            app.ConversionHistoryTab = uitab(app.TabGroup);
            app.ConversionHistoryTab.Title = 'Conversion History';
            app.ConversionHistoryTab.BackgroundColor = [0.9412 0.9412 0.9412];

            app.ConversionHistoryTable = uitable(app.ConversionHistoryTab);
            app.ConversionHistoryTable.ColumnName = {'From Base'; 'To Base'; 'Input'; 'Result'};
            app.ConversionHistoryTable.RowName = {};
            app.ConversionHistoryTable.Position = [10 10 780 560];

            app.UIFigure.Visible = 'on';
        end
    end

    methods (Access = public)

        function app = BinaryArithmeticCalculator

            createComponents(app)

            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        function delete(app)

            delete(app.UIFigure)
        end
    end
end
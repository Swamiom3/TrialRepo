/**
 * Base functionality used by TL*Range classes.
 * Stores and compares range values internally as Decimals, and provides comparison methods for implementing sub-classes
 * 
 * @author Grant Adamson, Traction on Demand
 * @date 2019-03-13
 */
public abstract class TLNumberRange {
    public static final String NULL_VALUE_ERROR = 'Invalid Range: ranges cannot contain null values';
    public static final String STRING_MUST_BE_SINGLE_CHAR_ERROR =
            'Invalid Range: string ranges must be defined using single character strings';
    public static final String INVALID_RANGE_ERROR =
            'Invalid Range: lower value must be less than or equal to upper value';

    private Decimal lower;
    private Decimal upper;

    /**
     * @description Initialize a TLNumberRange with the Decimal values provided. An integer constructor is not provided
     * as Integers will be automatically cast to Decimal
     *
     * @param lower lower bound of the number range
     * @param upper upper bound of the number range
     */
    public TLNumberRange(Decimal lower, Decimal upper) {
        validateRange(lower, upper);

        this.lower = lower;
        this.upper = upper;
    }

    /**
     * @description Initialize a TLNumberRange with the String values provided. Because there is no native Char type in
     * Apex, this enforces single character strings via validation
     *
     * @param lower lower bound of the character range, defined as a single character string
     * @param upper upper bound of the character range, defined as a single character string
     */
    public TLNumberRange(String lower, String upper) {
        validateRange(lower, upper);

        this.lower = toCharCode(lower);
        this.upper = toCharCode(upper);
    }

    /**
     * @description Determines if the provided character value is contained in the range
     *
     * @param value character, defined as a single character string
     *
     * @return True if value is contained in the range, otherwise false. Throws TLRangeException on invalid input
     *
     * @example
     * TLCharRange charRange = new TLCharRange('b', 'c');
     * charRange.contains('a'); // FALSE
     * charRange.contains('b'); // TRUE
     */
    public Boolean contains(String value) {
        return contains(toCharCode(value));
    }

    /**
     * @description Determines if the provided decimal value is contained in the range
     *
     * @param value decimal
     *
     * @return True if value is contained in the range, otherwise false. Throws TLRangeException on invalid input
     *
     * @example
     * TLIntegerRange intRange = new TLIntegerRange('2, 5);
     * intRange.contains(1); // FALSE
     * intRange.contains(5); // TRUE
     */
    public Boolean contains(Decimal value) {
        return !isBelow(value) && !isAbove(value);
    }

    /**
     * @description Determines if all items in the provided list are contained in the range
     *
     * @param values List of characters, defined as single character strings
     *
     * @return True if all values in the list are contained in the range, otherwise false. Throws TLRangeException on invalid input
     *
     * @example
     * TLCharRange charRange = new TLCharRange('b', 'c');
     * charRange.contains(new String[]{ 'a', 'b', 'c' }); // FALSE
     * charRange.contains(new String[]{ 'b', 'c' }); // TRUE
     */
    public Boolean contains(List<String> values) {
        validateNotNull(values);

        for(String value : values) {
            if(!contains(value)) {
                return false;
            }
        }

        return true;
    }

    /**
     * @description Determines if all items in the provided list are contained in the range. Provided for convenience to
     * avoid the need to cast all values to decimals
     *
     * @param values List of Integers
     *
     * @return True if all values in the list are contained in the range, otherwise false. Throws TLRangeException on invalid input
     *
     * @example
     * TLIntegerRange intRange = new TLIntegerRange(2, 5);
     * intRange.contains(new Integer[]{ 1, 2 }); // FALSE
     * intRange.contains(new Integer[]{ 2, 5 }); // TRUE
     */
    public Boolean contains(List<Integer> values) {
        validateNotNull(values);

        for(Integer value : values) {
            if(!contains(value)) {
                return false;
            }
        }

        return true;
    }

    /**
     * @description Determines if all items in the provided list are contained in the range
     *
     * @param values List of Decimals
     *
     * @return True if all values in the list are contained in the range, otherwise false. Throws TLRangeException on invalid input
     *
     * @example
     * TLDecimalRange decRange = new TLDecimalRange(2.5, 5.2);
     * decRange.contains(new Decimal[]{ 2.4, 5.0 }); // FALSE
     * decRange.contains(new Decimal[]{ 2.5, 3.5 }); // TRUE
     */
    public Boolean contains(List<Decimal> values) {
        validateNotNull(values);

        for(Decimal value : values) {
            if(!contains(value)) {
                return false;
            }
        }

        return true;
    }

    private void validateRange(String lower, String upper) {
        validateNotNull(lower);
        validateNotNull(upper);

        validateRange(toCharCode(lower), toCharCode(upper));
    }

    private void validateRange(Decimal lower, Decimal upper) {
        validateNotNull(lower);
        validateNotNull(upper);

        if( lower > upper ) {
            throw new TLRangeException(INVALID_RANGE_ERROR);
        }
    }

    private void validateNotNull(Object obj) {
        if(obj == null) {
            throw new TLRangeException(NULL_VALUE_ERROR);
        }
    }

    /**
     * @descriptions Determines if the current value is below the range
     *
     * @param value Character, defined as a single character string
     *
     * @return True if value is below the range, otherwise false. Throws TLRangeException on invalid input
     *
     * @example
     * TLCharRange charRange = new TLCharRange('b', 'c');
     * charRange.isBelow('a'); // TRUE
     * charRange.isBelow('b'); // FALSE
     * charRange.isBelow('d'); // FALSE
     */
    public Boolean isBelow(String value) {
        return isBelow(toCharCode(value));
    }

    /**
     * @descriptions Determines if the current value is below the range
     *
     * @param value Decimal
     *
     * @return True if value is below the range, otherwise false. Throws TLRangeException on invalid input
     *
     * @example
     * TLDecimalRange decRange = new TLDecimalRange(2.5, 5.2);
     * decRange.isBelow(2.4); // TRUE
     * decRange.isBelow(2.5); // FALSE
     * decRange.isBelow(5.3); // FALSE
     */
    public Boolean isBelow(Decimal value) {
        return value < lower;
    }

    /**
     * @descriptions Determines if the current value is above the range
     *
     * @param value Character, defined as a single character string
     *
     * @return True if value is above the range, otherwise false. Throws TLRangeException on invalid input
     *
     * @example
     * TLCharRange charRange = new TLCharRange('b', 'c');
     * charRange.isAbove('a'); // FALSE
     * charRange.isAbove('b'); // FALSE
     * charRange.isAbove('d'); // TRUE
     */
    public Boolean isAbove(String value) {
        return isAbove(toCharCode(value));
    }

    /**
     * @descriptions Determines if the current value is above the range
     *
     * @param value Decimal
     *
     * @return True if value is below the range, otherwise false. Throws TLRangeException on invalid input
     *
     * @example
     * TLDecimalRange decRange = new TLDecimalRange(2.5, 5.2);
     * decRange.isAbove(2.4); // FALSE
     * decRange.isAbove(2.5); // FALSE
     * decRange.isAbove(5.3); // TRUE
     */
    public Boolean isAbove(Decimal value) {
        return value > upper;
    }

    private Integer toCharCode(String str) {
        if(str.length() != 1) {
            throw new TLRangeException(STRING_MUST_BE_SINGLE_CHAR_ERROR);
        }
        return str.getChars()[0];
    }

    /**
     * @description Subclasses should override toString to a reasonable value to aid with debugging
     */

    public abstract override String toString();
    /**
     * @description Subclasses should override equals to a reasonable implementation to allow comparing ranges
     */
    public abstract Boolean equals(Object obj);

    /**
     * @description thrown by TLNumberRange or subclasses when invalid input or other errors are encountered
     */
    public class TLRangeException extends Exception {}
}
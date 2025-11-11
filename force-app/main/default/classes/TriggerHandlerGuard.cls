/**
 * @description Utility class to prevent trigger recursion.
 * This class holds a static boolean that all triggers can check.
 */
public class TriggerHandlerGuard {
    // Static boolean to track if the trigger is already running
	public static boolean hasRun = false;
}
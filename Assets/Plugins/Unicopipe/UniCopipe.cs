using UnityEngine;
using System.Collections;
using System.Runtime.InteropServices;

public static class UniCopipe
{

	#if (!UNITY_EDITOR && UNITY_IOS)
	[DllImport("__Internal")]
	private static extern void _SetClipboard(string value);

	[DllImport("__Internal")]
	private static extern string _GetClipboard();
	#endif

	public static string Value {
		get {
			#if UNITY_IOS && !UNITY_EDITOR
			return _GetClipboard();
			#elif UNITY_ANDROID && !UNITY_EDITOR
			string result = System.String.Empty;

			using (AndroidJavaClass jc = new AndroidJavaClass ("com.unity3d.player.UnityPlayer")) {
			using (AndroidJavaObject activity = jc.GetStatic<AndroidJavaObject> ("currentActivity")) {
			using (AndroidJavaObject clipboardManager = activity.Call<AndroidJavaObject> ("getSystemService", "clipboard")) {
			using (AndroidJavaObject clipData = clipboardManager.Call<AndroidJavaObject> ("getPrimaryClip")) {
			using (AndroidJavaObject item = clipData.Call<AndroidJavaObject> ("getItemAt", 0)) {
			if (item != null) {
			result = item.Call<string> ("getText");
			}
			}
			}
			}
			}
			}

			return result;
			#else
			return GUIUtility.systemCopyBuffer;
			#endif
		}
		set {
			#if UNITY_IOS && !UNITY_EDITOR
			_SetClipboard(value);
			#elif UNITY_ANDROID && !UNITY_EDITOR
			AndroidJavaClass jc = new AndroidJavaClass ("com.unity3d.player.UnityPlayer");
			AndroidJavaObject activity = jc.GetStatic<AndroidJavaObject> ("currentActivity");
			activity.Call ("runOnUiThread", new AndroidJavaRunnable (() => {
				AndroidJavaObject clipboardManager = activity.Call<AndroidJavaObject> ("getSystemService", "clipboard");
				AndroidJavaClass clipDataClass = new AndroidJavaClass ("android.content.ClipData");
				AndroidJavaObject clipData = clipDataClass.CallStatic<AndroidJavaObject> ("newPlainText", "clipboard", value);
				clipboardManager.Call ("setPrimaryClip", clipData);

				clipData.Dispose ();
				clipDataClass.Dispose ();
				clipboardManager.Dispose ();
				activity.Dispose ();
				jc.Dispose ();
			}));
			#else
			GUIUtility.systemCopyBuffer = value;
			#endif
		}
	}
}
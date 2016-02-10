using UnityEngine;
using System.Collections;

public class Test : MonoBehaviour
{
	string inputTxt = "test";
	string copyText = "";

	private Vector2 scale = new Vector2 (1, 1);
	private Vector2 pivotPoint;

	void OnGUI ()
	{
		pivotPoint = new Vector2 (Screen.width / 2, Screen.height / 2);
		GUIUtility.ScaleAroundPivot (scale, pivotPoint);

		inputTxt = GUI.TextField (new Rect (10, 10, 100, 20), inputTxt, 25);

		if (GUI.Button (new Rect (20, 40, 100, 60), "Copy")) {
			UniCopipe.Value = inputTxt;
		}

		if (GUI.Button (new Rect (20, 120, 100, 60), "Paste")) {
			copyText = UniCopipe.Value;
		}

		GUI.Label (new Rect (20, 200, 100, 30), "Clipboard Text : ");
		GUI.Label (new Rect (120, 200, 100, 30), copyText);
	}
}

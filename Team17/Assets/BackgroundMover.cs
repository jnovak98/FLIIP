using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BackgroundMover : MonoBehaviour {
	public float speed = 4.933334f;
	public float endX = -145f;

	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
		transform.Translate (-speed * Time.deltaTime, 0, 0);
		if(transform.position.x < endX)
			transform.Translate (400, 0, 0);
	}
}

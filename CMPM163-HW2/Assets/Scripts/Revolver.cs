using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class Revolver : MonoBehaviour
{
    float revolve;
    public Transform target;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        revolve = Input.GetAxis("Horizontal") * 5f;
        transform.RotateAround(Vector3.zero, Vector3.up, revolve);
        transform.LookAt(target);

        if(Input.GetKeyDown(KeyCode.Space))
        {
            SceneManager.LoadScene("PartB");
        }
    }
}

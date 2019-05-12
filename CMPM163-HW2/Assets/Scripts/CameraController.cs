using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class CameraController : MonoBehaviour
{
    float minFov = 15f;
    float maxFov = 90f;
    float sensitivity = 20f;

    Vector2 mouseLook;
    Vector2 smoothV;
    public float lookSensitivity = 2.0f;
    public float smoothing = 2.0f;

    GameObject sphere;

    // Start is called before the first frame update
    void Start()
    {
        sphere = this.transform.parent.gameObject;
    }

    // Update is called once per frame
    void Update()
    {
        float move = Input.GetAxis("Horizontal") * 5f;
        sphere.transform.position = new Vector3(sphere.transform.position.x + move, sphere.transform.position.y, sphere.transform.position.z);

        if(sphere.transform.position.x < 0)
            sphere.transform.position = new Vector3(0, sphere.transform.position.y, sphere.transform.position.z);
        else if (sphere.transform.position.x > 256)
            sphere.transform.position = new Vector3(256, sphere.transform.position.y, sphere.transform.position.z);

        float fov = Camera.main.fieldOfView;
        fov -= Input.GetAxis("Mouse ScrollWheel") * sensitivity;
        fov = Mathf.Clamp(fov, minFov, maxFov);
        Camera.main.fieldOfView = fov;

        var md = new Vector2(Input.GetAxisRaw("Mouse X"), Input.GetAxisRaw("Mouse Y"));

        md = Vector2.Scale(md, new Vector2(lookSensitivity * smoothing, lookSensitivity * smoothing));
        smoothV.x = Mathf.Lerp(smoothV.x, md.x, 1f / smoothing);
        smoothV.y = Mathf.Lerp(smoothV.y, md.y, 1f / smoothing);
        mouseLook += smoothV;
        mouseLook.y = Mathf.Clamp(mouseLook.y, -90f, 90f);

        transform.localRotation = Quaternion.AngleAxis(-mouseLook.y, Vector3.right);
        sphere.transform.localRotation = Quaternion.AngleAxis(mouseLook.x, sphere.transform.up);

        if (Input.GetKeyDown(KeyCode.Space))
            SceneManager.LoadScene("PartA");
    }
}
